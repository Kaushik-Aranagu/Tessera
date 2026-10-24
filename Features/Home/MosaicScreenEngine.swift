import CoreGraphics
import Foundation
import TesseraCore

// The screen mosaic's engine (Design 202): the screen's own pixels, a living core that eases and breathes, the field's
// intensity, a dither, the changeovers (wave, fall, wipe, dissolve, gather, melt and the new flip) and the finger's
// lean and ripple anywhere on Home. It keeps scene colours only for the region the field can ever touch (the largest
// core plus 28 tiles and a breath) and draws only those, over a cached layer of the screen's own pixels.

/// How one picture becomes another.
enum MosaicChangeoverKind: Equatable {
    case standard(MosaicTransition)
    case melt
    /// The departure board in pixels: each tile flips about its middle.
    case flip
    /// The same flip, row by row from the top (a reopen after a while).
    case flipRows
    /// A hard swap sweeping across the columns, left to right or back (a page's wipe).
    case wipeColumns(reverse: Bool)
}

/// What the view draws for one tile.
struct MosaicScreenTile {
    var colour: MosaicTriple
    /// Side as a multiple of the 3.2 pt tile, and the vertical squash of a flip.
    var scale: CGFloat
    var scaleY: CGFloat
    var offset: CGPoint
    /// A melting old tile drips away over the new one.
    var ghost: (colour: MosaicTriple, offset: CGPoint, scale: CGFloat)?
}

@MainActor
final class MosaicScreenEngine {
    private(set) var grid: MosaicScreenGrid
    var reduceMotion = false
    private(set) var clock: TimeInterval = 0
    private var random = SplitMix(seed: 0x7E55E2A)
    var ground: MosaicTriple = (1, 1, 1)
    private(set) var dark = false

    // The window: the core's target size, eased and breathing.
    private(set) var windowTarget: (columns: Int, rows: Int) = (50, 28)
    private var windowColumns = 50.0
    private var windowRows = 28.0
    private(set) var visibleColumns = 50
    private(set) var visibleRows = 28

    // Scene colours for the region, and the changeover between two pictures.
    private(set) var region: MosaicTileRect
    private var from: [MosaicTriple]
    private var to: [MosaicTriple]
    private var delays: [TimeInterval]
    private var lengths: [TimeInterval]
    private var doubles: [Bool]
    private(set) var changeover: MosaicChangeoverKind = .standard(.wave)
    private var morphStart: TimeInterval = -10
    /// During an announcement the rim samples the background, never the words.
    var rimSamplesLight = true

    // The moving light and a moment's sway and swell, in absolute tile coordinates.
    var overlay: ((_ column: Int, _ row: Int, _ time: TimeInterval, _ colour: MosaicTriple) -> MosaicTriple)?
    var scaleHook: ((_ column: Int, _ row: Int, _ time: TimeInterval) -> Double)?
    var offsetHook: ((_ column: Int, _ row: Int, _ time: TimeInterval) -> CGPoint)?

    /// The tiles under text, padded by one tile.
    var shield: [Int: Double] = [:]

    // The finger.
    private(set) var touchPoint: CGPoint?
    private var lean: [CGPoint]
    private var leanVelocity: [CGPoint]
    private var leaning = false
    private(set) var pops: [Int: TimeInterval] = [:]
    private var nextPop: TimeInterval = 0.7

    // Laid tiles and a flight.
    private(set) var laid: [MosaicScreenLaid] = []
    private var laidIndexes: Set<Int> = []
    private(set) var flight: MosaicScreenFlight?

    // Sheet 213: the sign the mosaic lends its tiles to, and the old one collapsing where it stood.
    private(set) var signRequest: MosaicSignRequest?
    private(set) var signLend: MosaicSignLend?
    private(set) var signOld: (tiles: [MosaicSignTile], start: TimeInterval)?
    private var lentTiles: [Int: Int] = [:]
    private(set) var landings = 0
    /// Home 236: a built sign tile (index into the lend's tiles) trading places with a mosaic tile.
    private(set) var signTrade: (index: Int, start: TimeInterval)?
    private var nextTrade: TimeInterval = 0

    static let rippleRadius: CGFloat = 140
    static let leanRadius: CGFloat = 36
    static let leanMax: CGFloat = 5

    init(size: CGSize, coreTop: CGFloat) {
        grid = MosaicScreenGrid(size: size, coreTop: coreTop)
        region = grid.region
        let count = region.width * region.height
        from = Array(repeating: (0.5, 0.5, 0.5), count: count)
        to = from
        delays = Array(repeating: 0, count: count)
        lengths = Array(repeating: 0.3, count: count)
        doubles = Array(repeating: false, count: count)
        lean = Array(repeating: .zero, count: count)
        leanVelocity = Array(repeating: .zero, count: count)
    }

    /// A new size or core top rebuilds the region (a rotation, a layout change); nothing else does.
    func configure(size: CGSize, coreTop: CGFloat, dark: Bool, ground: MosaicTriple) {
        let next = MosaicScreenGrid(size: size, coreTop: coreTop)
        self.dark = dark
        self.ground = ground
        guard next != grid else { return }
        grid = next
        region = next.region
        let count = region.width * region.height
        from = Array(repeating: ground, count: count)
        to = from
        delays = Array(repeating: 0, count: count)
        lengths = Array(repeating: 0.3, count: count)
        doubles = Array(repeating: false, count: count)
        lean = Array(repeating: .zero, count: count)
        leanVelocity = Array(repeating: .zero, count: count)
        morphStart = -10
        shield = [:]
        laid = []
        laidIndexes = []
        flight = nil
        pops = [:]
    }

    // MARK: Region helpers

    func regionIndex(column: Int, row: Int) -> Int? {
        guard region.contains(column: column, row: row) else { return nil }
        return (column - region.left) * region.height + (row - region.top)
    }

    /// The core now (eased and breathing) and the target core the scene's colours are drawn for.
    var core: MosaicTileRect {
        grid.core(columns: visibleColumns, rows: visibleRows)
    }

    var targetCore: MosaicTileRect {
        grid.core(columns: windowTarget.columns, rows: windowTarget.rows)
    }

    /// A tile's coordinates in the target window (what the mood fields are drawn in).
    func local(column: Int, row: Int) -> (column: Int, row: Int) {
        (column - targetCore.left, row - targetCore.top)
    }

    var windowConfig: MosaicConfig {
        var window = MosaicConfig.moods
        window.columns = windowTarget.columns
        window.rows = windowTarget.rows
        return window
    }

    /// The column "now" falls in, in absolute columns, or nil before the first hour.
    func nowColumn(_ date: Date) -> Int? {
        MosaicReadout.nowColumn(date, config: windowConfig).map { targetCore.left + $0 }
    }

    // MARK: Window

    func setWindow(columns: Int, rows: Int) {
        windowTarget = (min(max(columns, 1), MosaicScreenGrid.maxCore.columns),
                        min(max(rows, 1), MosaicScreenGrid.maxCore.rows))
    }

    func snapWindow() {
        windowColumns = Double(windowTarget.columns)
        windowRows = Double(windowTarget.rows)
        visibleColumns = windowTarget.columns
        visibleRows = windowTarget.rows
    }

    private func easeWindow(dt: TimeInterval) {
        let targetColumns = Double(windowTarget.columns), targetRows = Double(windowTarget.rows)
        var breathColumns = 0.0, breathRows = 0.0
        if reduceMotion {
            windowColumns = targetColumns
            windowRows = targetRows
        } else {
            let ease = 1 - pow(1 - 0.06, dt * 60)
            windowColumns += (targetColumns - windowColumns) * ease
            windowRows += (targetRows - windowRows) * ease
            breathColumns = 1.4 * sin(2 * Double.pi * clock / 27)
            breathRows = 1.2 * sin(2 * Double.pi * clock / 37)
        }
        visibleColumns = min(max(Int((windowColumns + breathColumns).rounded()), 1), MosaicScreenGrid.maxCore.columns)
        visibleRows = min(max(Int((windowRows + breathRows).rounded()), 1), MosaicScreenGrid.maxCore.rows)
    }

    // MARK: Time

    func step(to time: TimeInterval) {
        let dt = min(max(time - clock, 0), 0.1)
        clock = time
        for (index, start) in pops where time - start >= 0.38 {
            pops[index] = nil
        }
        if !reduceMotion, time >= nextPop {
            let column = region.left + random.int(region.width), row = region.top + random.int(region.height)
            if grid.contains(column: column, row: row) {
                pop(grid.index(column: column, row: row), after: 0)
            }
            nextPop = time + 0.7
        }
        easeWindow(dt: dt)
        liveCore = core
        springLean(dt: dt)
        if let flight, time - flight.start >= 0.7 {
            land(flight, at: time)
            self.flight = nil
        }
        stepTrade(at: time)
    }

    var isBusy: Bool {
        !pops.isEmpty || flight != nil || touchPoint != nil || leaning || clock - morphStart < morphDuration + 1
            || signIsMoving
    }

    private var morphDuration: TimeInterval {
        (lengths.max() ?? 0.3) + (delays.max() ?? 0)
    }

    func consumeLandings() -> Int {
        defer { landings = 0 }
        return landings
    }

    private func pop(_ index: Int, after delay: TimeInterval) {
        guard pops[index] == nil, !laidIndexes.contains(index) else { return }
        pops[index] = clock + delay
    }

    func popProgress(_ index: Int) -> Double? {
        guard let start = pops[index] else { return nil }
        let progress = (clock - start) / 0.38
        return progress >= 0 && progress < 1 ? progress : nil
    }

    // MARK: Changeovers

    /// Sets every region tile's colour at once (the first frame).
    func settle(colourAt: (_ column: Int, _ row: Int) -> MosaicTriple) {
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                let colour = colourAt(column + region.left, row + region.top)
                let index = column * region.height + row
                from[index] = colour
                to[index] = colour
            }
        }
        morphStart = -10
    }

    /// Changes the region to a new picture with a changeover. Under Reduce Motion it is one 150 ms crossfade.
    func morph(
        _ kind: MosaicChangeoverKind,
        origin: (column: Int, row: Int),
        total: TimeInterval? = nil,
        after: TimeInterval = 0,
        from start: ((_ column: Int, _ row: Int) -> MosaicTriple)? = nil,
        colourAt: (_ column: Int, _ row: Int) -> MosaicTriple
    ) {
        let count = region.width * region.height
        for index in 0 ..< count {
            from[index] = MosaicColour.mix(from[index], to[index], settledMix(index))
        }
        if let start {
            for column in 0 ..< region.width {
                for row in 0 ..< region.height {
                    from[column * region.height + row] = start(column + region.left, row + region.top)
                }
            }
        }
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                to[column * region.height + row] = colourAt(column + region.left, row + region.top)
            }
        }
        morphStart = clock + after
        if reduceMotion {
            changeover = .standard(.wave)
            delays = Array(repeating: 0, count: count)
            lengths = Array(repeating: 0.15, count: count)
            doubles = Array(repeating: false, count: count)
            return
        }
        changeover = kind
        doubles = Array(repeating: false, count: count)
        switch kind {
        case let .standard(transition):
            let plan = transition.plan(
                geometry: planGeometry,
                origin: (origin.column - region.left, origin.row - region.top),
                wave: 0.020
            )
            delays = plan.delays
            lengths = plan.lengths
        case .melt:
            planMelt()
        case .flip:
            planFlip()
        case .flipRows:
            planFlipRows()
        case let .wipeColumns(reverse):
            planWipeColumns(reverse: reverse)
        }
        if let total {
            stretch(to: total)
        }
    }

    /// Stretches or squeezes the delays so the whole changeover takes `total` seconds (the last tile ends then).
    private func stretch(to total: TimeInterval) {
        let longest = lengths.max() ?? 0
        let latest = delays.max() ?? 0
        guard latest > 0 else { return }
        let factor = max(total - longest, 0) / latest
        delays = delays.map { $0 * factor }
    }

    /// Row by row from the top: a tile flips in 300 ms, 30% of them twice.
    private func planFlipRows() {
        let count = region.width * region.height
        var nextDelays = [TimeInterval](repeating: 0, count: count)
        var nextLengths = [TimeInterval](repeating: 0.3, count: count)
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                let index = column * region.height + row
                let absolute = grid.index(column: column + region.left, row: row + region.top)
                nextDelays[index] = Double(row) / Double(region.height) + MosaicColour.unit(absolute, salt: 129) * 0.05
                if MosaicColour.unit(absolute, salt: 123) < 0.3 {
                    doubles[index] = true
                    nextLengths[index] = 0.6
                }
            }
        }
        delays = nextDelays
        lengths = nextLengths
    }

    /// A hard swap sweeping across the columns, with a little hash so the front is not a ruler.
    private func planWipeColumns(reverse: Bool) {
        let count = region.width * region.height
        var nextDelays = [TimeInterval](repeating: 0, count: count)
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                let index = column * region.height + row
                let absolute = grid.index(column: column + region.left, row: row + region.top)
                let across = Double(reverse ? region.width - 1 - column : column) / Double(region.width)
                nextDelays[index] = across + MosaicColour.unit(absolute, salt: 131) * 0.03
            }
        }
        delays = nextDelays
        lengths = Array(repeating: 0.05, count: count)
    }

    private var planGeometry: MosaicGeometry {
        var config = MosaicConfig.moods
        config.columns = region.width
        config.rows = region.height
        return MosaicGeometry(config: config, width: 0)
    }

    private func planMelt() {
        var nextDelays = [TimeInterval](repeating: 0, count: region.width * region.height)
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                let local = max(row + region.top - grid.coreTop, 0)
                nextDelays[column * region.height + row] = MosaicColour.unit(column + region.left, salt: 91) * 0.42
                    + 0.018 * Double(local)
            }
        }
        delays = nextDelays
        lengths = Array(repeating: 0.52, count: nextDelays.count)
    }

    /// The departure board in pixels: delay = (column + 28) x 14 ms + row x 3 ms + hash x 80 ms from the core's left; a
    /// tile flips in 300 ms and 30% of them flip twice.
    private func planFlip() {
        let count = region.width * region.height
        var nextDelays = [TimeInterval](repeating: 0, count: count)
        var nextLengths = [TimeInterval](repeating: 0.3, count: count)
        let left = targetCore.left
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                let index = column * region.height + row
                let absolute = grid.index(column: column + region.left, row: row + region.top)
                let localColumn = max(column + region.left - left + 28, 0)
                let localRow = max(row + region.top - grid.coreTop, 0)
                nextDelays[index] = Double(localColumn) * 0.014 + Double(localRow) * 0.003
                    + MosaicColour.unit(absolute, salt: 121) * 0.08
                if MosaicColour.unit(absolute, salt: 123) < 0.3 {
                    doubles[index] = true
                    nextLengths[index] = 0.6
                }
            }
        }
        delays = nextDelays
        lengths = nextLengths
    }

    func progress(_ index: Int) -> Double {
        min(max((clock - morphStart - delays[index]) / max(lengths[index], 0.0001), 0), 1)
    }

    /// How far the old picture has given way to the new at a tile, for a morph that is mid-flight.
    private func settledMix(_ index: Int) -> Double {
        let phase = progress(index)
        if reduceMotion {
            return phase
        }
        switch changeover {
        case .melt, .flip, .flipRows: return phase > 0 ? (phase >= 1 ? 1 : (phase < 0.5 ? 0 : 1)) : 0
        case .wipeColumns: return phase > 0 ? 1 : 0
        case let .standard(transition):
            if transition == .wave {
                return 1 - pow(1 - phase, 3)
            }
            return phase > 0 ? 1 : 0
        }
    }

    /// The tile's scene colour now, and the squash of a flip (1 otherwise).
    func sceneColour(_ index: Int, absolute: Int) -> (colour: MosaicTriple, scaleY: CGFloat) {
        let phase = progress(index)
        if reduceMotion {
            return (MosaicColour.mix(from[index], to[index], phase), 1)
        }
        switch changeover {
        case .flip, .flipRows:
            guard phase > 0, phase < 1 else { return (phase >= 1 ? to[index] : from[index], 1) }
            let flips = doubles[index] ? 2.0 : 1.0
            let unit = phase * flips
            let stage = min(Int(unit), Int(flips) - 1)
            let fraction = unit - Double(stage)
            let middle = MosaicColour.lightened(MosaicColour.mix(from[index], to[index], 0.5),
                                                by: (MosaicColour.unit(absolute, salt: 127) * 2 - 1) * 0.08)
            let stages = doubles[index] ? [from[index], middle, to[index]] : [from[index], to[index]]
            let colour = fraction < 0.5 ? stages[stage] : stages[stage + 1]
            return (colour, CGFloat(max(abs(cos(Double.pi * fraction)), 0.08)))
        case .melt, .wipeColumns:
            return (phase > 0 ? to[index] : from[index], 1)
        case let .standard(transition):
            if transition == .wave {
                return (MosaicColour.mix(from[index], to[index], 1 - pow(1 - phase, 3)), 1)
            }
            return (phase > 0 ? to[index] : from[index], 1)
        }
    }

    // MARK: Per-tile reads

    /// The core as of this frame (eased and breathing), kept so a frame reads it once.
    private(set) var liveCore = MosaicTileRect(left: 0, top: 0, width: 1, height: 1)

    /// A tile outside the window read from its mirror across the window's edge (never clamped).
    func mirrored(column: Int, row: Int, core: MosaicTileRect) -> (column: Int, row: Int) {
        (core.left + MosaicRim.mirror(column - core.left, count: core.width),
         core.top + MosaicRim.mirror(row - core.top, count: core.height))
    }

    /// What to draw for a tile of the window or its rim, or nil when nothing is there (outside the rim, or a rim tile
    /// still at the page's own level). Every tile is full size and one solid colour.
    func tile(column: Int, row: Int, nowColumn: Int?, ignoringGap: Bool = false) -> MosaicScreenTile? {
        let core = liveCore
        let sd = MosaicRim.signedDistance(column: column, row: row, core: core)
        guard sd < Double(MosaicRim.reach), let ownIndex = regionIndex(column: column, row: row) else { return nil }
        let rimLevel = MosaicRim.level(signedDistance: sd, column: column, row: row)
        guard rimLevel > 0 else { return nil }
        // A tile beyond the window's edge reads the scene mirrored across it; one inside (a rounded corner's cut) its
        // own.
        let source = core.contains(column: column, row: row) ? (column: column, row: row)
            : mirrored(column: column, row: row, core: core)
        guard let sourceIndex = regionIndex(column: source.column, row: source.row) else { return nil }
        let own = grid.index(column: column, row: row)
        let sourceAbsolute = grid.index(column: source.column, row: source.row)
        var (scene, scaleY) = sceneColour(sourceIndex, absolute: sourceAbsolute)
        let isRim = sd > 0
        if let overlay, !isRim || rimSamplesLight {
            scene = overlay(source.column, source.row, clock, scene)
        }
        if source.column == nowColumn, !reduceMotion {
            scene = MosaicColour.lightened(scene, by: sin(clock / 0.7 + Double(source.row) * 0.5) * 0.08)
        }
        if let progress = popProgress(own) {
            scene = MosaicColour.scaled(scene, 1 - 0.1 * sin(Double.pi * progress))
        }
        // The page's colour rises into the scene's across the edge, in whole solid tiles.
        if rimLevel < 1 {
            scene = MosaicColour.mix(ground, scene, rimLevel)
        }
        // Under words the mosaic keeps a fifth of itself, feathering back over 5 tiles: the words always read.
        if let kept = shield[own] {
            scene = MosaicColour.mix(ground, scene, kept)
        }
        if !ignoringGap, let gap = signGap(at: own) {
            scene = MosaicColour.mix(scene, ground, gap)
        }
        var scale = 1.0
        var offset = leaning ? lean[ownIndex] : .zero
        if !reduceMotion {
            let phase = 0.8 * Double(column) / Double(grid.columns) + 0.2 * Double(row) / Double(grid.rows)
            let wave = 0.5 + 0.5 * sin(2 * Double.pi * (clock / 7 - phase))
            scale += 0.22 * wave * wave * wave
            if let progress = popProgress(own) {
                scale += 0.5 * sin(Double.pi * progress)
            }
            if let scaleHook {
                scale *= scaleHook(source.column, source.row, clock)
            }
            if let sway = offsetHook?(source.column, source.row, clock) {
                offset.x += sway.x
                offset.y += sway.y
            }
            offset = movement(regionIndex: sourceIndex, row: source.row, offset: offset)
            if case .melt = changeover {
                let phase = progress(sourceIndex)
                if phase > 0, phase < 1 {
                    scale *= phase
                }
            }
        }
        var tile = MosaicScreenTile(colour: scene, scale: CGFloat(max(scale, 1)), scaleY: scaleY, offset: offset,
                                    ghost: nil)
        if !reduceMotion, case .melt = changeover {
            let phase = progress(sourceIndex)
            if phase > 0, phase < 1 {
                let local = max(source.row - grid.coreTop, 0)
                let drop = phase * phase * Double(max(windowTarget.rows - local + 4, 4)) *
                    Double(MosaicScreenGrid.step) * 0.5
                tile.ghost = (from[sourceIndex], CGPoint(x: 0, y: drop), CGFloat(1 - 0.7 * phase))
            }
        }
        return tile
    }

    /// A fall's drop and a gather's scatter.
    private func movement(regionIndex: Int, row _: Int, offset: CGPoint) -> CGPoint {
        guard case let .standard(transition) = changeover else { return offset }
        let phase = progress(regionIndex)
        var point = offset
        switch transition {
        case .fall where phase > 0 && phase < 1:
            point.y -= CGFloat((1 - phase * phase) * 48)
        case .gather where phase < 1:
            let ease = 1 - pow(1 - phase, 3)
            point.x += CGFloat((MosaicColour.unit(regionIndex, salt: 3) - 0.5) * 80 * (1 - ease))
            point.y += CGFloat((MosaicColour.unit(regionIndex, salt: 5) - 0.5) * 80 * (1 - ease))
        default: break
        }
        return point
    }
}

// MARK: - Touch

extension MosaicScreenEngine {
    /// The finger is at `point` (screen points). Returns true when it just came down.
    @discardableResult
    func touch(at point: CGPoint) -> Bool {
        let isDown = touchPoint == nil
        touchPoint = point
        if isDown, !reduceMotion {
            ripple(from: point)
        }
        return isDown
    }

    func endTouch() {
        touchPoint = nil
    }

    /// Seconds a tile at `center` waits before it pops: distance x 2.6 ms within 140 pt, nil beyond.
    static func rippleDelay(center: CGPoint, from point: CGPoint) -> TimeInterval? {
        let distance = hypot(center.x - point.x, center.y - point.y)
        guard distance <= rippleRadius else { return nil }
        return TimeInterval(distance) * 0.0026
    }

    private func ripple(from point: CGPoint) {
        let first = grid.tile(at: CGPoint(x: point.x - Self.rippleRadius, y: point.y - Self.rippleRadius))
        let last = grid.tile(at: CGPoint(x: point.x + Self.rippleRadius, y: point.y + Self.rippleRadius))
        for column in max(first.column, 0) ... min(last.column, grid.columns - 1) {
            for row in max(first.row, 0) ... min(last.row, grid.rows - 1) {
                guard let delay = Self.rippleDelay(center: grid.center(column: column, row: row), from: point) else {
                    continue
                }
                let index = grid.index(column: column, row: row)
                if pops[index] == nil {
                    pop(index, after: delay)
                }
            }
        }
    }

    /// A reopen's ripple from the middle of the mosaic: tiles pop outward over `seconds`.
    func rippleFromCentre(seconds: TimeInterval) {
        guard !reduceMotion else { return }
        let target = targetCore
        let centre = grid.center(column: target.left + target.width / 2, row: target.top + target.height / 2)
        let radius = CGFloat(max(target.width, target.height)) * MosaicScreenGrid.step / 2 + 24
        let travel = max(seconds - 0.38, 0.05)
        for column in region.left ... region.right {
            for row in region.top ... region.bottom where grid.contains(column: column, row: row) {
                let distance = hypot(grid.center(column: column, row: row).x - centre.x,
                                     grid.center(column: column, row: row).y - centre.y)
                guard distance <= radius else { continue }
                let index = grid.index(column: column, row: row)
                if pops[index] == nil {
                    pop(index, after: TimeInterval(distance / radius) * travel)
                }
            }
        }
    }

    /// The lean target of a tile for a finger at `point`: away, up to 5 pt, none past 36 pt.
    static func leanTarget(center: CGPoint, from point: CGPoint) -> CGPoint {
        let dx = center.x - point.x, dy = center.y - point.y
        let distance = hypot(dx, dy)
        guard distance < leanRadius else { return .zero }
        let push = leanMax * (1 - distance / leanRadius)
        guard distance > 0.001 else { return CGPoint(x: push, y: 0) }
        return CGPoint(x: dx / distance * push, y: dy / distance * push)
    }

    private func springLean(dt: TimeInterval) {
        guard !reduceMotion else {
            if leaning {
                lean = lean.map { _ in .zero }
                leaning = false
            }
            return
        }
        guard dt > 0 else { return }
        guard touchPoint != nil || leaning else { return }
        let frames = CGFloat(dt * 60)
        let keep = pow(0.72, frames)
        var any = false
        for column in 0 ..< region.width {
            for row in 0 ..< region.height {
                let index = column * region.height + row
                let target = touchPoint.map {
                    Self.leanTarget(center: grid.center(column: column + region.left, row: row + region.top), from: $0)
                } ?? .zero
                var position = lean[index]
                var velocity = leanVelocity[index]
                if touchPoint == nil, abs(position.x) < 0.01, abs(position.y) < 0.01, abs(velocity.x) < 0.01,
                   abs(velocity.y) < 0.01
                {
                    lean[index] = .zero
                    leanVelocity[index] = .zero
                    continue
                }
                velocity.x = (velocity.x + (target.x - position.x) * 0.22 * frames) * keep
                velocity.y = (velocity.y + (target.y - position.y) * 0.22 * frames) * keep
                position.x += velocity.x * frames
                position.y += velocity.y * frames
                lean[index] = position
                leanVelocity[index] = velocity
                any = true
            }
        }
        leaning = any || touchPoint != nil
    }
}

// MARK: - Laying

extension MosaicScreenEngine {
    func isLaid(_ index: Int) -> Bool {
        laidIndexes.contains(index) || flight.map { $0.index(in: grid) } == index
    }

    func restore(column: Int, row: Int, tone: MosaicTone) {
        let index = grid.index(column: column, row: row)
        guard grid.contains(column: column, row: row), !isLaid(index) else { return }
        laid.append(MosaicScreenLaid(column: column, row: row, tone: tone, at: -10))
        laidIndexes.insert(index)
    }

    /// A free tile in the band of the target core's column `column` (local rows 20% to 80% of the window).
    func freeRow(inColumn column: Int) -> Int? {
        let rows = windowTarget.rows
        let band = (grid.coreTop + Int(Double(rows) * 0.2)) ... (grid.coreTop + Int(Double(rows) * 0.8))
        let free = band
            .filter { grid.contains(column: column, row: $0) && !isLaid(grid.index(column: column, row: $0)) }
        guard !free.isEmpty else { return nil }
        return free[random.int(free.count)]
    }

    /// A tile flies from `point` (screen points) to a tile in `column` (a given row, or a free one in the band) and is
    /// laid there. Under Reduce Motion it is laid at once and fades in over 150 ms.
    @discardableResult
    func lay(from point: CGPoint, side: CGFloat, column: Int, tone: MosaicTone, row wanted: Int? = nil) -> Bool {
        guard flight == nil else { return false }
        guard let row = wanted ?? freeRow(inColumn: column),
              grid.contains(column: column, row: row) else { return false }
        let index = grid.index(column: column, row: row)
        guard !isLaid(index) else { return false }
        if reduceMotion {
            laid.append(MosaicScreenLaid(column: column, row: row, tone: tone, at: clock))
            laidIndexes.insert(index)
            landings += 1
            return true
        }
        flight = MosaicScreenFlight(from: point, side: side, column: column, row: row, tone: tone, start: clock)
        return true
    }

    private func land(_ flight: MosaicScreenFlight, at time: TimeInterval) {
        laid.append(MosaicScreenLaid(column: flight.column, row: flight.row, tone: flight.tone, at: time))
        laidIndexes.insert(flight.index(in: grid))
        landings += 1
        let centre = grid.center(column: flight.column, row: flight.row)
        ripple(from: centre)
    }

    func flightState() -> (center: CGPoint, side: CGFloat, angle: Double)? {
        guard let flight else { return nil }
        let fraction = min(max((clock - flight.start) / 0.7, 0), 1)
        let eased = MosaicEngine.houseSpring(fraction)
        let target = grid.center(column: flight.column, row: flight.row)
        let center = CGPoint(x: flight.from.x + (target.x - flight.from.x) * eased,
                             y: flight.from.y + (target.y - flight.from.y) * eased)
        let side = flight.side + (MosaicScreenGrid.side - flight.side) * eased
        return (center, side, Double.pi * eased)
    }

    func laidOpacity(_ item: MosaicScreenLaid) -> Double {
        guard reduceMotion else { return 1 }
        return min(max((clock - item.at) / 0.15, 0), 1)
    }

    func reset() {
        signRequest = nil
        signLend = nil
        signOld = nil
        lentTiles = [:]
        laid = []
        laidIndexes = []
        flight = nil
        pops = [:]
    }
}

struct MosaicScreenLaid: Equatable {
    let column: Int
    let row: Int
    let tone: MosaicTone
    let at: TimeInterval
}

struct MosaicScreenFlight: Equatable {
    let from: CGPoint
    let side: CGFloat
    let column: Int
    let row: Int
    let tone: MosaicTone
    let start: TimeInterval

    func index(in grid: MosaicScreenGrid) -> Int {
        grid.index(column: column, row: row)
    }
}

// MARK: - The sign

/// What Home asks the mosaic to build: the kind of sign, where its top-left tile sits on the screen grid, and its
/// colours. Only the share and the kind are data; a sign never carries an amount or a name.
struct MosaicSignRequest: Equatable {
    var kind: ThingSignKind
    var share: Double = 0.5
    var column: Int
    var row: Int
    var accent: MosaicTriple
    var alt: MosaicTriple?
    /// Which thing this is: a new one collapses the old sign and lends again, even of the same kind.
    var token = ""

    /// The same sign: where it sits may move with the scroll without lending again.
    func isSameSign(as other: Self) -> Bool {
        kind == other.kind && share == other.share && token == other.token
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isSameSign(as: rhs) && lhs.column == rhs.column && lhs.row == rhs.row
    }
}

extension MosaicScreenEngine {
    /// A new request collapses the old sign where it stands, then 140 ms later lends the mosaic's tiles to the new one.
    /// Under Reduce Motion the sign is simply there.
    func showSign(_ request: MosaicSignRequest?) {
        guard request != signRequest else { return }
        if let request, let current = signRequest, request.isSameSign(as: current), let lend = signLend {
            // Only its place moved (a scroll): the same sign again at once, no flight.
            signRequest = request
            let core = liveCore
            let tiles = MosaicSignLend.lend(
                cells: ThingSignArt.cells(request.kind, elapsed: 0, share: request.share, still: true),
                originColumn: request.column, originRow: request.row, core: (
                    core.left,
                    core.top,
                    core.width,
                    core.height
                )
            )
            let landed = clock >= lend.landedAt
            signLend = MosaicSignLend(tiles: tiles, start: landed ? clock - 10 : lend.start, kind: request.kind,
                                      share: request.share)
            return
        }
        let old = signLend
        signRequest = request
        lentTiles = [:]
        guard let request else {
            signLend = nil
            signOld = nil
            return
        }
        let cells = ThingSignArt.cells(request.kind, elapsed: 0, share: request.share, still: true)
        let core = liveCore
        let tiles = MosaicSignLend.lend(
            cells: cells, originColumn: request.column, originRow: request.row,
            core: (core.left, core.top, core.width, core.height)
        )
        if reduceMotion {
            signOld = nil
            signLend = MosaicSignLend(tiles: tiles, start: clock - 10, kind: request.kind, share: request.share)
            return
        }
        var start = clock
        if let old, !old.tiles.isEmpty {
            signOld = (old.tiles, clock)
            start = clock + MosaicSignLend.feedDelay
        } else {
            signOld = nil
        }
        signLend = MosaicSignLend(tiles: tiles, start: start, kind: request.kind, share: request.share)
        for (index, tile) in tiles.enumerated() {
            lentTiles[grid.index(column: tile.sourceColumn, row: tile.sourceRow)] = index
        }
    }

    /// Once the sign has landed, a tile trades with the mosaic every 4 to 7 s. None under Reduce Motion.
    private func stepTrade(at time: TimeInterval) {
        guard !reduceMotion, let lend = signLend, !lend.tiles.isEmpty, time >= lend.landedAt else {
            signTrade = nil
            nextTrade = 0
            return
        }
        let range = MosaicSignLend.tradeRange
        func gap() -> TimeInterval {
            range.lowerBound + Double(random.int(1001)) / 1000 * (range.upperBound - range.lowerBound)
        }
        if let trade = signTrade, time - trade.start >= MosaicSignLend.flightSeconds {
            signTrade = nil
        }
        if nextTrade <= lend.landedAt, signTrade == nil {
            nextTrade = lend.landedAt + gap()
        } else if signTrade == nil, time >= nextTrade {
            signTrade = (random.int(lend.tiles.count), time)
            nextTrade = time + MosaicSignLend.flightSeconds + gap()
        }
    }

    var signIsMoving: Bool {
        !reduceMotion && signLend != nil
    }

    /// How far toward the page a lent mosaic tile is right now, or nil when it is not lent.
    func signGap(at absoluteIndex: Int) -> Double? {
        guard let signLend, let index = lentTiles[absoluteIndex] else { return nil }
        if let trade = signTrade, trade.index == index {
            let gap = MosaicSignLend.tradeGap(elapsed: clock - trade.start)
            return gap > 0.001 ? gap : nil
        }
        let gap = signLend.gap(sourceIndex: absoluteIndex, tile: index, at: clock)
        return gap > 0.001 ? gap : nil
    }

    /// The old sign's tiles that are still on the screen, with how far each has collapsed.
    func collapsingSign() -> [(tile: MosaicSignTile, scale: CGFloat, sink: CGFloat)] {
        guard let signOld else { return [] }
        let elapsed = clock - signOld.start
        guard elapsed < MosaicSignLend.collapseTotal else { return [] }
        return signOld.tiles.compactMap { tile in
            let state = MosaicSignLend.collapse(cell: tile.cell, elapsed: elapsed)
            return state.scale > 0 ? (tile, state.scale, state.sink) : nil
        }
    }
}

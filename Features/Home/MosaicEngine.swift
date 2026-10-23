import CoreGraphics
import Foundation
import TesseraCore

// The mosaic's engine (Design 199, numbers from the coordinator's sheet): pure logic for a grid of flat tiles that
// swell, pop, lean from a finger, morph between scenes and take a laid tile. No drawing and no SwiftUI, so it is
// tested without a screen and the Canvas is only a reader. Design will add more expressive modes: a mode is a
// `MosaicConfig`, a scene and a palette, not a fork of this file.

typealias MosaicTriple = (red: Double, green: Double, blue: Double)

/// The numbers one mosaic runs on.
struct MosaicConfig: Equatable {
    var columns = 34
    var rows = 25
    /// The day shown: 6 am to midnight, so a column covers 18/34 of an hour block.
    var firstHour = 6
    var hours = 18
    var gap: CGFloat = 2
    var corner: CGFloat = 1.6
    /// Fixed per-tile lightness jitter (±), from the tile's index.
    var jitter = 0.10
    /// Future columns are mixed this far toward the page ground.
    var futureMix = 0.58
    /// The now column's lightness swings this much: sin(t / 0.7 s + row * 0.5).
    var breatheAmplitude = 0.08
    var breatheSeconds: TimeInterval = 0.7
    /// Swell: +0.22 travels across the grid, one pass per 7 s.
    var swell = 0.22
    var swellSeconds: TimeInterval = 7
    /// Pop: every 0.7 s one random tile scales 1 → 1.5 → 1 over 380 ms, colour x 0.9 at the peak.
    var popInterval: TimeInterval = 0.7
    var popDuration: TimeInterval = 0.38
    var popScale = 0.5
    var popShade = 0.9
    /// A touch pops every tile within this radius, delayed by distance x 2.6 ms.
    var rippleRadius: CGFloat = 150
    var rippleSecondsPerPoint: TimeInterval = 0.0026
    /// While held, tiles within this radius lean away, up to `leanMax` points.
    var leanRadius: CGFloat = 46
    var leanMax: CGFloat = 7
    /// A scene morph: each tile eases its colour over 520 ms, delayed by grid distance x 22 ms from the origin.
    var morphDuration: TimeInterval = 0.52
    var morphDelayPerTile: TimeInterval = 0.022
    var morphBump = 0.45
    /// A laid tile flies 700 ms and rotates 180°, on the house spring.
    var flightDuration: TimeInterval = 0.7
    var glaze = 0.52
    /// The rows a laid tile may land in (the middle of the now column).
    var layRows = 4 ... 20

    static let home = MosaicConfig()

    var count: Int { columns * rows }
}

/// Where tiles sit for a width: the side, the tile rects and the column a point falls in.
struct MosaicGeometry: Equatable {
    let config: MosaicConfig
    let width: CGFloat

    /// floor((width - 33 x 2) / 34): about 8 pt on a phone.
    var side: CGFloat {
        max(1, ((width - config.gap * CGFloat(config.columns - 1)) / CGFloat(config.columns)).rounded(.down))
    }

    var pitch: CGFloat { side + config.gap }

    /// The grid is centred in the width the tiles leave over.
    var gridWidth: CGFloat { pitch * CGFloat(config.columns) - config.gap }
    var inset: CGFloat { max(0, (width - gridWidth) / 2) }
    var height: CGFloat { pitch * CGFloat(config.rows) - config.gap }

    func index(column: Int, row: Int) -> Int { column * config.rows + row }

    func rect(column: Int, row: Int) -> CGRect {
        CGRect(x: inset + CGFloat(column) * pitch, y: CGFloat(row) * pitch, width: side, height: side)
    }

    func center(column: Int, row: Int) -> CGPoint {
        let tile = rect(column: column, row: row)
        return CGPoint(x: tile.midX, y: tile.midY)
    }

    func column(at x: CGFloat) -> Int {
        min(max(Int(((x - inset) / pitch).rounded(.down)), 0), config.columns - 1)
    }

    /// Column c covers 6 am + (c + 0.5) / 34 x 18 h.
    func hour(ofColumn column: Int) -> Double {
        Double(config.firstHour) + (Double(column) + 0.5) / Double(config.columns) * Double(config.hours)
    }

    /// The column an hour of day (6 to 24) falls in.
    func column(ofHour hour: Double) -> Int {
        min(max(Int(((hour - Double(config.firstHour)) / Double(config.hours) * Double(config.columns)).rounded(.down)),
                0), config.columns - 1)
    }
}

struct MosaicLaid: Equatable {
    let index: Int
    let tone: MosaicTone
    let column: Int
    /// When it landed, in the engine's clock, for the short fade-in; negative for tiles restored at launch.
    let at: TimeInterval
}

struct MosaicFlight: Equatable {
    let from: CGPoint
    let fromSide: CGFloat
    let to: Int
    let tone: MosaicTone
    let start: TimeInterval
}

/// The state and the clock of one mosaic. A class so the drawing closure can advance it each frame without publishing.
@MainActor
final class MosaicEngine {
    let config: MosaicConfig
    private(set) var geometry: MosaicGeometry
    /// Reduce Motion: nothing swells, pops, leans or flies; a morph or a laid tile is a 150 ms crossfade.
    var reduceMotion = false

    private var clock: TimeInterval = 0
    private var random: SplitMix
    private var nextPop: TimeInterval

    /// Pops in progress: tile index → start time (a future start waits at its first frame).
    private(set) var pops: [Int: TimeInterval] = [:]
    private(set) var laid: [MosaicLaid] = []
    private var laidIndexes: Set<Int> = []
    private(set) var flight: MosaicFlight?
    /// Landings waiting for the host's soft haptic.
    private(set) var landings = 0

    // The morph: from-colours (the display when it began), to-colours (the scene), a delay per tile.
    private var from: [MosaicTriple]
    private var to: [MosaicTriple]
    private var delays: [TimeInterval]
    private var morphStart: TimeInterval = -10
    private var morphLength: TimeInterval

    // The finger.
    private(set) var touchPoint: CGPoint?
    private(set) var touchedColumn: Int?
    private var lean: [CGPoint]
    private var leanVelocity: [CGPoint]
    private var leaning = false

    init(config: MosaicConfig = .home, width: CGFloat = 340, seed: UInt64 = 0x7E55_E2A) {
        self.config = config
        geometry = MosaicGeometry(config: config, width: width)
        random = SplitMix(seed: seed)
        nextPop = config.popInterval
        let rest = Array(repeating: MosaicTriple(0.5, 0.5, 0.5), count: config.count)
        from = rest
        to = rest
        delays = Array(repeating: 0, count: config.count)
        morphLength = config.morphDuration
        lean = Array(repeating: .zero, count: config.count)
        leanVelocity = Array(repeating: .zero, count: config.count)
    }

    func resize(width: CGFloat) {
        guard width != geometry.width else { return }
        geometry = MosaicGeometry(config: config, width: width)
    }

    var currentClock: TimeInterval { clock }

    // MARK: - Time

    /// Advances to `time` (seconds on any steady clock): pops one tile now and then, springs the lean, lands a flight.
    func step(to time: TimeInterval) {
        let dt = min(max(time - clock, 0), 0.1)
        clock = time
        for (index, start) in pops where time - start >= config.popDuration {
            pops[index] = nil
        }
        if !reduceMotion, time >= nextPop {
            pop(random.int(config.count))
            nextPop = time + config.popInterval
        }
        springLean(dt: dt)
        if let flight, time - flight.start >= config.flightDuration {
            land(flight, at: time)
            self.flight = nil
        }
    }

    /// True while anything is moving that the slow breathing and swell don't cover.
    var isBusy: Bool {
        !pops.isEmpty || flight != nil || touchPoint != nil || leaning || clock - morphStart < morphLength + 1
    }

    func consumeLandings() -> Int {
        defer { landings = 0 }
        return landings
    }

    private func pop(_ index: Int, after delay: TimeInterval = 0) {
        guard pops[index] == nil, !laidIndexes.contains(index) else { return }
        pops[index] = clock + delay
    }

    // MARK: - Per-tile reads

    /// The tile's scale: the travelling swell, a pop, and the bump while its colour changes.
    func scale(column: Int, row: Int) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let index = geometry.index(column: column, row: row)
        var value = 1.0
        let phase = 0.8 * Double(column) / Double(config.columns) + 0.2 * Double(row) / Double(config.rows)
        let wave = 0.5 + 0.5 * sin(2 * Double.pi * (clock / config.swellSeconds - phase))
        value += config.swell * wave * wave * wave
        if let progress = popProgress(index) {
            value += config.popScale * sin(Double.pi * progress)
        }
        if let progress = morphProgress(index), progress > 0, progress < 1 {
            value += config.morphBump * sin(Double.pi * progress)
        }
        return CGFloat(value)
    }

    func popProgress(_ index: Int) -> Double? {
        guard let start = pops[index] else { return nil }
        let progress = (clock - start) / config.popDuration
        return progress >= 0 && progress < 1 ? progress : nil
    }

    func offset(column: Int, row: Int) -> CGPoint {
        leaning ? lean[geometry.index(column: column, row: row)] : .zero
    }

    /// The tile's colour now: its morph, jittered, the now column's breath and the pop's shade.
    func colour(column: Int, row: Int, nowColumn: Int?) -> MosaicTriple {
        let index = geometry.index(column: column, row: row)
        var rgb = MosaicColour.mix(from[index], to[index], morphEased(index))
        if column == nowColumn, !reduceMotion {
            let breath = sin(clock / config.breatheSeconds + Double(row) * 0.5) * config.breatheAmplitude
            rgb = MosaicColour.lightened(rgb, by: breath)
        }
        if let progress = popProgress(index) {
            rgb = MosaicColour.scaled(rgb, 1 - (1 - config.popShade) * sin(Double.pi * progress))
        }
        return rgb
    }

    func morphProgress(_ index: Int) -> Double? {
        let progress = (clock - morphStart - delays[index]) / morphLength
        return min(max(progress, 0), 1)
    }

    private func morphEased(_ index: Int) -> Double {
        guard let progress = morphProgress(index) else { return 1 }
        if reduceMotion { return progress }
        return 1 - pow(1 - progress, 3)
    }

    // MARK: - Scenes

    /// Eases every tile to `targets`, each starting after its grid distance from `origin` x 22 ms. Under Reduce Motion it
    /// is one 150 ms crossfade with no delay.
    func morph(to targets: [MosaicTriple], origin: (column: Int, row: Int)) {
        guard targets.count == config.count else { return }
        let nowColour = (0 ..< config.count).map { MosaicColour.mix(from[$0], to[$0], morphEased($0)) }
        from = nowColour
        to = targets
        morphStart = clock
        if reduceMotion {
            morphLength = 0.15
            delays = Array(repeating: 0, count: config.count)
            return
        }
        morphLength = config.morphDuration
        for column in 0 ..< config.columns {
            for row in 0 ..< config.rows {
                let distance = hypot(Double(column - origin.column), Double(row - origin.row))
                delays[geometry.index(column: column, row: row)] = distance * config.morphDelayPerTile
            }
        }
    }

    /// Sets the colours with no morph (the first frame, a resize of the day).
    func settle(to targets: [MosaicTriple]) {
        guard targets.count == config.count else { return }
        from = targets
        to = targets
        morphStart = -10
    }

    // MARK: - Touch

    /// The result of a finger arriving or moving.
    struct TouchResult: Equatable {
        /// The finger just came down: a ripple left it and the host plays one soft tick.
        var down = false
        /// The finger crossed into another two-column span: the host plays a tick.
        var spanChanged = false
    }

    @discardableResult
    func touch(at point: CGPoint) -> TouchResult {
        var result = TouchResult()
        let column = geometry.column(at: point.x)
        let isDown = touchPoint == nil
        if isDown {
            result.down = true
            if !reduceMotion { ripple(from: point) }
        }
        if touchedColumn.map({ $0 / 2 }) != column / 2 { result.spanChanged = !isDown }
        touchedColumn = column
        touchPoint = point
        return result
    }

    func endTouch() {
        touchPoint = nil
        touchedColumn = nil
    }

    /// The seconds after a touch a tile at `center` waits before it pops, or nil outside the radius.
    func rippleDelay(center: CGPoint, from point: CGPoint) -> TimeInterval? {
        let distance = hypot(center.x - point.x, center.y - point.y)
        guard distance <= config.rippleRadius else { return nil }
        return TimeInterval(distance) * config.rippleSecondsPerPoint
    }

    private func ripple(from point: CGPoint) {
        for column in 0 ..< config.columns {
            for row in 0 ..< config.rows {
                let center = geometry.center(column: column, row: row)
                guard let delay = rippleDelay(center: center, from: point) else { continue }
                let index = geometry.index(column: column, row: row)
                if pops[index] == nil { pop(index, after: delay) }
            }
        }
    }

    /// The lean target of one tile for a finger at `point`: away from it, up to `leanMax`, none past the radius.
    func leanTarget(center: CGPoint, from point: CGPoint) -> CGPoint {
        let dx = center.x - point.x
        let dy = center.y - point.y
        let distance = hypot(dx, dy)
        guard distance < config.leanRadius else { return .zero }
        let push = config.leanMax * (1 - distance / config.leanRadius)
        guard distance > 0.001 else { return CGPoint(x: push, y: 0) }
        return CGPoint(x: dx / distance * push, y: dy / distance * push)
    }

    /// Springs every tile toward its lean target: stiffness 0.22 and damping 0.28 per 60 Hz frame.
    private func springLean(dt: TimeInterval) {
        guard !reduceMotion else {
            if leaning { lean = lean.map { _ in .zero }; leaning = false }
            return
        }
        guard dt > 0 else { return }
        let frames = CGFloat(dt * 60)
        let keep = pow(0.72, frames)
        var any = false
        for column in 0 ..< config.columns {
            for row in 0 ..< config.rows {
                let index = geometry.index(column: column, row: row)
                let target = touchPoint.map { leanTarget(center: geometry.center(column: column, row: row), from: $0) }
                    ?? .zero
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

    // MARK: - Laying

    func isLaid(_ index: Int) -> Bool { laidIndexes.contains(index) || flight?.to == index }

    /// A free tile in the now column's middle rows, chosen with the engine's seeded random so a day lays the same way.
    func freeTile(inColumn column: Int) -> Int? {
        let free = config.layRows.map { geometry.index(column: column, row: $0) }.filter { !isLaid($0) }
        guard !free.isEmpty else { return nil }
        return free[random.int(free.count)]
    }

    /// A thing finished earlier today, restored at launch with no flight.
    func restore(column: Int, tone: MosaicTone) {
        guard let index = freeTile(inColumn: column) else { return }
        laid.append(MosaicLaid(index: index, tone: tone, column: column, at: -10))
        laidIndexes.insert(index)
    }

    /// A tile flies from `point` (the struck row, in the mosaic's space) to a free tile in `column`: translate and
    /// rotate 180° over 700 ms on the house spring. Under Reduce Motion it is laid at once and fades in.
    @discardableResult
    func lay(from point: CGPoint, side: CGFloat, column: Int, tone: MosaicTone) -> Bool {
        guard flight == nil, let index = freeTile(inColumn: column) else { return false }
        if reduceMotion {
            laid.append(MosaicLaid(index: index, tone: tone, column: column, at: clock))
            laidIndexes.insert(index)
            landings += 1
            return true
        }
        flight = MosaicFlight(from: point, fromSide: side, to: index, tone: tone, start: clock)
        return true
    }

    private func land(_ flight: MosaicFlight, at time: TimeInterval) {
        let column = flight.to / config.rows
        laid.append(MosaicLaid(index: flight.to, tone: flight.tone, column: column, at: time))
        laidIndexes.insert(flight.to)
        pops[flight.to] = nil
        landings += 1
        // A ripple from where it landed.
        ripple(from: geometry.center(column: column, row: flight.to % config.rows))
    }

    /// The flying tile now: its centre, side and rotation. The house spring, stretched to the flight's 700 ms.
    func flightState() -> (center: CGPoint, side: CGFloat, angle: Double)? {
        guard let flight else { return nil }
        let t = min(max((clock - flight.start) / config.flightDuration, 0), 1)
        let eased = Self.houseSpring(t)
        let column = flight.to / config.rows
        let target = geometry.center(column: column, row: flight.to % config.rows)
        let center = CGPoint(x: flight.from.x + (target.x - flight.from.x) * eased,
                             y: flight.from.y + (target.y - flight.from.y) * eased)
        let side = flight.fromSide + (geometry.side - flight.fromSide) * eased
        return (center, side, Double.pi * eased)
    }

    /// The house spring's step response (a little bounce) for t in 0 to 1 of its duration.
    static func houseSpring(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        guard t < 1 else { return 1 }
        let zeta = 0.78
        let omega = 2 * Double.pi * 1.3
        let damped = omega * sqrt(1 - zeta * zeta)
        let decay = exp(-zeta * omega * t)
        return 1 - decay * (cos(damped * t) + zeta * omega / damped * sin(damped * t))
    }

    func laidOpacity(_ item: MosaicLaid) -> Double {
        min(max((clock - item.at) / 0.15, 0), 1)
    }

    /// The mosaic resets at midnight: nothing laid carries into the next day.
    func reset() {
        laid = []
        laidIndexes = []
        flight = nil
        pops = [:]
    }
}

// MARK: - Colour

enum MosaicColour {
    static func mix(_ a: MosaicTriple, _ b: MosaicTriple, _ t: Double) -> MosaicTriple {
        (a.red + (b.red - a.red) * t, a.green + (b.green - a.green) * t, a.blue + (b.blue - a.blue) * t)
    }

    static func scaled(_ a: MosaicTriple, _ factor: Double) -> MosaicTriple {
        (min(a.red * factor, 1), min(a.green * factor, 1), min(a.blue * factor, 1))
    }

    /// Lightness pushed toward white (positive) or black (negative) by `amount`.
    static func lightened(_ a: MosaicTriple, by amount: Double) -> MosaicTriple {
        amount >= 0 ? mix(a, (1, 1, 1), amount) : mix(a, (0, 0, 0), -amount)
    }

    /// A tile's fixed jitter, -1 to 1, from its index: the same tile every frame, so nothing shimmers.
    static func jitter(index: Int) -> Double {
        var hash = UInt64(truncatingIfNeeded: index) &* 0x9E37_79B9_7F4A_7C15
        hash = (hash ^ (hash >> 29)) &* 0xBF58_476D_1CE4_E5B9
        hash ^= hash >> 32
        return Double(hash & 0xFFFF) / 32767.5 - 1
    }

    /// Core's sky colour (0 to 255 a channel) as unit floats; a dark look takes the same hues at 72% so the sky does not
    /// glare on a dark page.
    static func triple(_ sky: MosaicRGB, dark: Bool) -> MosaicTriple {
        let scale = dark ? 0.72 : 1
        return (Double(sky.red) / 255 * scale, Double(sky.green) / 255 * scale, Double(sky.blue) / 255 * scale)
    }

    static func hex(_ value: UInt32) -> MosaicTriple {
        (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }
}

// MARK: - Words

enum MosaicReadout {
    /// "1:00 pm to 2:00 pm." for the two-column span a finger is over, with what is there if anything is.
    static func text(column: Int, config: MosaicConfig, event: String? = nil) -> String {
        let hour = config.firstHour + Int((Double(column / 2 * 2) * Double(config.hours) / Double(config.columns)).rounded())
        let from = HouseTime.clock(minuteOfDay: (hour % 24) * 60)
        let to = HouseTime.clock(minuteOfDay: ((hour + 1) % 24) * 60)
        guard let event, !event.isEmpty else { return "\(from) to \(to)." }
        return "\(from) to \(to), \(event)."
    }

    /// The column "now" falls in, or nil before the first hour (the whole day is still ahead).
    static func nowColumn(_ date: Date, config: MosaicConfig, calendar: Calendar = .current) -> Int? {
        let minutes = Double(calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date))
        let from = Double(config.firstHour * 60)
        guard minutes >= from else { return nil }
        let column = Int((minutes - from) / Double(config.hours * 60) * Double(config.columns))
        return min(column, config.columns - 1)
    }
}

/// A small steady random source, so the same seed pops and lays the same tiles.
struct SplitMix {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func int(_ bound: Int) -> Int {
        Int(next() % UInt64(max(bound, 1)))
    }
}

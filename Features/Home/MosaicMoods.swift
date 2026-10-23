import Foundation
import TesseraCore

// The departure mosaic (Design 200, behind homeMosaicMoods, default Off, needs homeMosaic): the same grid in nine
// moods, each a field of flat tiles and a little moving light, and five ways one mood becomes another. Pure, so a
// mood's colours and a transition's timing are tested without drawing. Core's `MosaicMoodPicker` chooses the mood.

// MARK: - Transitions

/// How one picture becomes another (Core's `MosaicTransition`): wave eases outward from an origin; the rest swap tile
/// by tile. The timings are the view's.
extension MosaicTransition {
    struct Plan {
        let delays: [TimeInterval]
        let lengths: [TimeInterval]
    }

    /// Each tile's delay and length, indexed `column * rows + row`.
    func plan(geometry: MosaicGeometry, origin: (column: Int, row: Int), wave waveDelay: TimeInterval = 0.020) -> Plan {
        let config = geometry.config
        var delays = [TimeInterval](repeating: 0, count: config.count)
        var lengths = [TimeInterval](repeating: 0.5, count: config.count)
        let maxDiagonal = Double(config.columns + config.rows - 2)
        for column in 0 ..< config.columns {
            for row in 0 ..< config.rows {
                let index = geometry.index(column: column, row: row)
                switch self {
                case .wave:
                    // Distance x 20 ms, 520 ms ease-out cubic, bump sin(p·π) x 0.45.
                    delays[index] = hypot(Double(column - origin.column), Double(row - origin.row)) * waveDelay
                    lengths[index] = 0.52
                case .fall:
                    // A column's offset (hash x 380 ms) plus 26 ms per row from the bottom; 360 ms, ease-in.
                    delays[index] = MosaicColour.unit(column, salt: 11) * 0.38 + 0.026 * Double(config.rows - 1 - row)
                    lengths[index] = 0.36
                case .wipe:
                    // A stair diagonal in 3-tile steps over 1 s with a dithered front.
                    let step = Double((column + row) / 3) * 3
                    delays[index] = step / maxDiagonal * 1.0 + MosaicColour.unit(index, salt: 13) * 0.06
                    lengths[index] = 0.05
                case .dissolve:
                    // A hard per-tile swap at hash x 900 ms.
                    delays[index] = MosaicColour.unit(index, salt: 17) * 0.9
                    lengths[index] = 0.01
                case .gather:
                    // Hash x 700 ms, then 500 ms.
                    delays[index] = MosaicColour.unit(index, salt: 19) * 0.7
                    lengths[index] = 0.5
                }
            }
        }
        return Plan(delays: delays, lengths: lengths)
    }

    /// The seconds until the last tile has finished.
    func total(geometry: MosaicGeometry, origin: (column: Int, row: Int)) -> TimeInterval {
        let plan = plan(geometry: geometry, origin: origin)
        return zip(plan.delays, plan.lengths).map { $0 + $1 }.max() ?? 0
    }
}

// MARK: - Moods

extension MosaicMood {
    /// Each mood's own way in (sheet 200), from Core's table.
    var transition: MosaicTransition {
        MosaicTransition.standard(for: self)
    }

    /// What VoiceOver says of the picture.
    var spoken: String {
        switch self {
        case .morning: "Morning"
        case .day: "Day"
        case .golden: "Golden hour"
        case .running: "A workout is running"
        case .rest: "Rest"
        case .back: "Back home"
        case .done: "Everything is done"
        case .rain: "Rain"
        case .night: "Night"
        }
    }
}

extension MosaicMood {
    /// The window of the 62 x 40 grid the mood shows (sheet 200): columns x rows, anchored top-right.
    var window: (columns: Int, rows: Int) {
        switch self {
        case .morning: (50, 28)
        case .day: (48, 24)
        case .golden: (60, 30)
        case .running: (40, 28)
        case .rest: (62, 20)
        case .back: (36, 22)
        case .done: (56, 36)
        case .rain: (50, 30)
        case .night: (62, 38)
        }
    }
}

enum MosaicWindows {
    /// The window while a scene (the time, the sky, the next thing, done) shows instead of a mood.
    static let scene: (columns: Int, rows: Int) = (50, 28)

    /// A window-local field laid into the whole grid, anchored top-right; tiles beyond the window take the nearest
    /// local tile so a window that eases wider has colour to show.
    static func expand(
        _ local: [MosaicTriple],
        window: (columns: Int, rows: Int),
        config: MosaicConfig
    ) -> [MosaicTriple] {
        guard local.count == window.columns * window.rows else { return [] }
        let left = config.columns - window.columns
        var full = [MosaicTriple](repeating: (0, 0, 0), count: config.count)
        for column in 0 ..< config.columns {
            let localColumn = min(max(column - left, 0), window.columns - 1)
            for row in 0 ..< config.rows {
                let localRow = min(row, window.rows - 1)
                full[column * config.rows + row] = local[localColumn * window.rows + localRow]
            }
        }
        return full
    }
}

/// What a mood draws from beyond the clock: the finished apps' accents (one pixel firework each), the workout's sets,
/// and how many things are done today.
struct MosaicMoodContext {
    var nowColumn: Int?
    var dark = false
    /// One accent per finished app, in the order they finished.
    var doneAccents: [MosaicTriple] = []
    var doneSets = 0
    var remainingSets = 0
    var doneCount = 0
    var trainingAccent: MosaicTriple = (0.77, 0.28, 0.16)
    /// Ink, Tess's cobalt and each app's accent, for the moments (the view fills them from the theme).
    var ink: MosaicTriple = (0.07, 0.07, 0.09)
    var tess: MosaicTriple = (0.18, 0.43, 0.64)
    var accents: [AppID: MosaicTriple] = [:]
}

enum MosaicMoodField {
    private typealias RGB = MosaicTriple

    private static func hex(_ value: UInt32) -> RGB {
        MosaicColour.hex(value)
    }

    /// A vertical blend from `top` to `bottom` over rows 0 ... `until`.
    private static func vertical(_ row: Int, _ until: Int, _ top: RGB, _ bottom: RGB) -> RGB {
        MosaicColour.mix(top, bottom, min(max(Double(row) / Double(max(until, 1)), 0), 1))
    }

    /// The still colours of a mood: sky above the horizon, water or ground below, sun and moon discs.
    static func base(
        _ mood: MosaicMood,
        geometry: MosaicGeometry,
        input: MosaicSceneInput,
        ground: MosaicTriple,
        context: MosaicMoodContext
    ) -> [MosaicTriple] {
        let config = geometry.config
        var colours = [MosaicTriple](repeating: ground, count: config.count)
        let rows = config.rows, columns = config.columns
        for column in 0 ..< columns {
            for row in 0 ..< rows {
                let index = geometry.index(column: column, row: row)
                let jitter = MosaicColour.jitter(index: index) * 0.05
                let colour: RGB = switch mood {
                case .morning: morning(column, row, geometry)
                case .day: dayField(column, row, geometry, input, ground, context)
                case .golden: golden(column, row, geometry)
                case .running: dayField(column, row, geometry, input, ground, context)
                case .rest: rest(column, row, geometry)
                case .back: dusty(column, row, geometry)
                case .done: evening(column, row, geometry)
                case .rain: rainy(column, row, geometry)
                case .night: night(column, row, geometry, context)
                }
                colours[index] = MosaicColour.lightened(colour, by: jitter)
            }
        }
        return colours
    }

    // MARK: Fields

    private static func disc(_ column: Int, _ row: Int, centre: (Double, Double), radius: Double) -> Double {
        hypot(Double(column) + 0.5 - centre.0, Double(row) + 0.5 - centre.1) - radius
    }

    /// Lilac to peach sky, horizon at 66%, a gold pixel sun (radius 4.6) that rises, water below.
    private static func morning(_ column: Int, _ row: Int, _ geometry: MosaicGeometry) -> MosaicTriple {
        let rows = geometry.config.rows
        let horizon = Int(Double(rows) * 0.66)
        let lilac = hex(0xC9B8E4), peach = hex(0xF8CBAA)
        if row < horizon {
            let sky = vertical(row, horizon, lilac, peach)
            let sun = disc(
                column,
                row,
                centre: (Double(geometry.config.columns) * 0.5, Double(horizon) - 6),
                radius: 3.2
            )
            return sun <= 0 ? hex(0xF2C14E) : sky
        }
        return MosaicColour.mix(peach, hex(0x8E86B8), Double(row - horizon) / Double(max(rows - horizon, 1)))
    }

    /// The 199 field: the day's sky by hour, past set, the hours ahead pale.
    private static func dayField(
        _ column: Int, _: Int, _ geometry: MosaicGeometry, _ input: MosaicSceneInput, _ ground: MosaicTriple,
        _ context: MosaicMoodContext
    ) -> MosaicTriple {
        let sky = input.sky(geometry.hour(ofColumn: column))
        let isFuture = context.nowColumn.map { column > $0 } ?? true
        return isFuture ? MosaicColour.mix(sky, ground, geometry.config.futureMix) : sky
    }

    /// Amber to rose to plum, a sun of radius 5.2 at 78% across and 62% down.
    private static func golden(_ column: Int, _ row: Int, _ geometry: MosaicGeometry) -> MosaicTriple {
        let config = geometry.config
        let amber = hex(0xF2A65A), rose = hex(0xD9758B), plum = hex(0x5E3A63)
        let fraction = Double(row) / Double(config.rows - 1)
        let sky = fraction < 0.62 ? MosaicColour.mix(plum, rose, fraction / 0.62)
            : MosaicColour.mix(rose, amber, (fraction - 0.62) / 0.38)
        let sun = disc(column, row, centre: (Double(config.columns) * 0.78, Double(config.rows) * 0.62), radius: 5.2)
        return sun <= 0 ? hex(0xFFD27A) : sky
    }

    /// Still water: a pale sky, horizon at 55%, the water darker (the shimmer is the overlay's).
    private static func rest(_: Int, _ row: Int, _ geometry: MosaicGeometry) -> MosaicTriple {
        let rows = geometry.config.rows
        let horizon = Int(Double(rows) * 0.55)
        let sky = vertical(row, horizon, hex(0xCFE0EA), hex(0xE9EEF0))
        guard row >= horizon else { return sky }
        return MosaicColour.mix(hex(0xA9C1CF), hex(0x6F8CA0), Double(row - horizon) / Double(max(rows - horizon, 1)))
    }

    /// Dusty: a warm sand-grey, a little lighter toward the top.
    private static func dusty(_: Int, _ row: Int, _ geometry: MosaicGeometry) -> MosaicTriple {
        vertical(row, geometry.config.rows, hex(0xCDBFAE), hex(0xA89886))
    }

    /// An evening field for the fireworks.
    private static func evening(_: Int, _ row: Int, _ geometry: MosaicGeometry) -> MosaicTriple {
        vertical(row, geometry.config.rows, hex(0x3C2F63), hex(0xB5667A))
    }

    private static func rainy(_: Int, _ row: Int, _ geometry: MosaicGeometry) -> MosaicTriple {
        vertical(row, geometry.config.rows, hex(0x6E7F8F), hex(0x93A3B0))
    }

    /// Deep indigo, a crescent moon of radius 4.8 cut by a disc of radius 4.5.
    private static func night(_ column: Int, _ row: Int, _ geometry: MosaicGeometry,
                              _: MosaicMoodContext) -> MosaicTriple
    {
        let config = geometry.config
        let sky = vertical(row, config.rows, hex(0x1B1F4D), hex(0x0B0E2A))
        let centre = (Double(config.columns) * 0.82, Double(config.rows) * 0.18)
        let moon = disc(column, row, centre: centre, radius: 4.8)
        // The crescent: the moon's disc minus a second disc (radius 4.5) nudged right and up.
        let bite = disc(column, row, centre: (centre.0 + 2.3, centre.1 - 1.4), radius: 4.5)
        return moon <= 0 && bite > 0 ? hex(0xF1ECD0) : sky
    }

    // MARK: Moving light

    typealias Overlay = (_ column: Int, _ row: Int, _ time: TimeInterval, _ colour: MosaicTriple) -> MosaicTriple

    /// The mood's moving light, applied per tile per frame to the colour so far.
    static func overlay(
        _ mood: MosaicMood,
        geometry: MosaicGeometry,
        context: MosaicMoodContext,
        reduceMotion: Bool
    ) -> Overlay? {
        guard !reduceMotion else { return nil }
        let rows = geometry.config.rows, columns = geometry.config.columns
        switch mood {
        case .morning: return morningLight(rows: rows)
        case .golden: return goldenLight(rows: rows, columns: columns)
        case .running: return runningLight(rows: rows, columns: columns, context: context)
        case .rest: return restLight(rows: rows)
        case .done: return fireworks(rows: rows, columns: columns, accents: context.doneAccents)
        case .rain: return rainLight(rows: rows)
        case .night: return nightLight(rows: rows, columns: columns, context: context)
        case .day, .back: return nil
        }
    }

    private static func morningLight(rows: Int) -> Overlay {
        let horizon = Int(Double(rows) * 0.66)
        return { column, row, time, colour in
            // Sparkle on the water: a tile now and then catches the light.
            guard row >= horizon else { return colour }
            let index = column * rows + row
            let phase = (MosaicColour.unit(index, salt: 23) + time * 0.45).truncatingRemainder(dividingBy: 1)
            return phase < 0.03 ? MosaicColour.lightened(colour, by: 0.35) : colour
        }
    }

    private static func goldenLight(rows: Int, columns: Int) -> Overlay {
        let sunRow = Double(rows) * 0.62
        return { column, row, time, colour in
            // A slow horizontal light streak through the sun's row.
            guard abs(Double(row) + 0.5 - sunRow) <= 1.2 else { return colour }
            let head = (time * 3).truncatingRemainder(dividingBy: Double(columns + 14)) - 7
            let distance = abs(Double(column) - head)
            return distance < 7 ? MosaicColour.lightened(colour, by: 0.16 * (1 - distance / 7)) : colour
        }
    }

    private static func runningLight(rows: Int, columns: Int, context: MosaicMoodContext) -> Overlay {
        let target = Double(context.nowColumn ?? columns / 2)
        return { column, row, time, colour in
            // A current toward the now column every 2.2 s.
            let phase = (time / 2.2).truncatingRemainder(dividingBy: 1)
            let from = Double(column) < target ? 0.0 : Double(columns - 1)
            let head = from + (target - from) * phase
            let distance = abs(Double(column) - head)
            var result = distance < 2.2 ? MosaicColour.lightened(colour, by: 0.12 * (1 - distance / 2.2)) : colour
            // Done sets are Training-accent tiles in the now column, from the bottom; the rest are ink rings.
            if Int(target) == column, row >= rows - 8, row < rows - 3 {
                let slot = rows - 4 - row
                if slot >= 0, slot < context.doneSets {
                    result = context.trainingAccent
                }
            }
            return result
        }
    }

    private static func restLight(rows: Int) -> Overlay {
        let horizon = Int(Double(rows) * 0.55)
        return { column, row, time, colour in
            // The reflection shimmers ±1.5 columns.
            guard row >= horizon else { return colour }
            let sway = sin(time * 0.9 + Double(row) * 0.8) * 1.5
            return MosaicColour.lightened(colour, by: 0.07 * sin(Double(column) * 0.6 + sway))
        }
    }

    private static func fireworks(rows: Int, columns: Int, accents: [MosaicTriple]) -> Overlay {
        { column, row, time, colour in
            // One pixel firework per finished app, staggered 700 ms, repeating every 5.2 s, each fading after 2.2
            // s.
            var result = colour
            for (number, accent) in accents.enumerated() {
                let age = (time - Double(number) * 0.7).truncatingRemainder(dividingBy: 5.2)
                guard age >= 0, age < 2.2 else { continue }
                let centre = (Double(columns) * (0.2 + 0.6 * MosaicColour.unit(number, salt: 29)),
                              Double(rows) * (0.25 + 0.3 * MosaicColour.unit(number, salt: 31)))
                let radius = 1 + 12 * (age / 2.2)
                let distance = hypot(Double(column) + 0.5 - centre.0, Double(row) + 0.5 - centre.1)
                if abs(distance - radius) < 0.9 {
                    result = MosaicColour.mix(result, accent, 1 - age / 2.2)
                }
            }
            return result
        }
    }

    private static func rainLight(rows: Int) -> Overlay {
        { column, row, time, colour in
            // Drops down the columns.
            let speed = 8 + MosaicColour.unit(column, salt: 37) * 6
            let start = MosaicColour.unit(column, salt: 41) * Double(rows + 8)
            let head = (start + time * speed).truncatingRemainder(dividingBy: Double(rows + 8))
            let behind = head - Double(row)
            return behind >= 0 && behind < 3 ? MosaicColour.lightened(colour, by: 0.3 - behind * 0.08) : colour
        }
    }

    private static func nightLight(rows: Int, columns: Int, context: MosaicMoodContext) -> Overlay {
        let nowColumn = context.nowColumn
        return { column, row, time, colour in
            let index = column * rows + row
            var result = colour
            // A faint aurora band, rows 8 to 14, drifting.
            let band = Double(rows) * 0.34 + sin(Double(column) * 0.22 + time * 0.35) * 2.5
            let offset = abs(Double(row) - band)
            if offset < 3 {
                result = MosaicColour.mix(result, hex(0x3FD0B0), 0.16 * (1 - offset / 3))
            }
            // About 4% of tiles are stars that twinkle.
            if MosaicColour.unit(index, salt: 43) < 0.04 {
                let twinkle = 0.5 + 0.5 * sin(time * 2 + MosaicColour.unit(index, salt: 47) * 40)
                result = MosaicColour.mix(result, (1, 1, 0.92), 0.25 + 0.6 * twinkle)
            }
            // A shooting star every 7 s.
            let age = time.truncatingRemainder(dividingBy: 7)
            if age < 0.9 {
                let head = age / 0.9 * Double(columns) * 0.6
                let line = Double(column) - (Double(columns) * 0.1 + head)
                if abs(line - Double(row) * 1.0) < 0.7, line > -4, line < 0 {
                    result = hex(0xFFFFFF)
                }
            }
            // Today's done tiles glow low in the now column.
            if let nowColumn, column == nowColumn, row >= rows - 2 - context.doneCount, row < rows - 1 {
                result = MosaicColour.mix(result, hex(0xFFC46B), 0.55)
            }
            return result
        }
    }
}

/// Settings › Review › "Mosaic moods" (default Off), the one switch sheet 200 shares with the departure board on the
/// three lines (Builder B's #1304 defines the row); it needs Mosaic itself to be On.
enum MosaicMoodsSwitch {
    nonisolated static let choiceID = "homeMosaicMoods"

    @MainActor static var isOn: Bool {
        HomeMosaic.isOn && ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// Settings › Review › "Mosaic moments" (default Off); it needs Mosaic moods On.
enum MosaicMomentsSwitch {
    nonisolated static let choiceID = "homeMosaicMoments"

    @MainActor static var isOn: Bool {
        MosaicMoodsSwitch.isOn && ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

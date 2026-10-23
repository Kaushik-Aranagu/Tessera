import Foundation
import TesseraCore

// What the mosaic can say (Design 199): the day, the time in tiles, the sky, the minutes to the next thing, and a day
// that is done. A scene is a set of target colours for the grid; the engine morphs between them. Pure, so each scene
// is tested by reading its colours, not by looking at it.

/// What Core knows that the mosaic draws: the sky for an hour, what finished today, the next timed thing. Core fills
/// this from sunrise and sunset, the day's story and the plan; until then `MosaicFacts.sample` stands in.
struct MosaicFacts {
    struct Finished: Equatable {
        let hour: Double
        let tone: MosaicTone
    }

    var now: Date = AppClock.now
    /// The sky's colours at an hour of day (6 to 24), for a light and a dark look.
    var sky: MosaicSky = .standard
    var finishedToday: [Finished] = []
    /// The next timed thing: its title and the minutes until it starts.
    var nextTimed: (title: String, minutes: Int)?
    var freeMinutes: Int?
    /// Minutes until sunset, when it is known.
    var minutesToSunset: Int?
    /// Things on the day by column pair's start hour, for the caption while a finger drags.
    var events: [Int: String] = [:]

    static let sample = MosaicFacts()

    /// The line under the mosaic for a scene (the day's rest caption is the free time and what is next).
    func caption(for scene: MosaicScene) -> String {
        switch scene {
        case .day:
            guard let freeMinutes, let next = nextTimed else { return "Nothing on the clock." }
            return "Free for \(HouseTime.minutes(freeMinutes)), then \(next.title)."
        case .time: return HouseTime.clock(now) + "."
        case .sky:
            guard let minutesToSunset, minutesToSunset >= 0 else { return "The sun is down." }
            return "Sunset in \(HouseTime.minutes(minutesToSunset))."
        case .next:
            guard let next = nextTimed else { return "Nothing on the clock." }
            return "\(next.title) in \(HouseTime.minutes(next.minutes))."
        case .done: return "Everything is done."
        }
    }
}

enum MosaicScenes {
    /// The sun's own colour in the sky scene.
    static let sun: MosaicRGB = MosaicColour.hex(0xEE965C)
    static let duskGround: MosaicRGB = MosaicColour.hex(0x5A4650)

    /// The target colours, indexed `column * rows + row`.
    static func targets(
        _ scene: MosaicScene,
        geometry: MosaicGeometry,
        facts: MosaicFacts,
        dark: Bool,
        ground: MosaicRGB
    ) -> [MosaicRGB] {
        let config = geometry.config
        let nowColumn = MosaicReadout.nowColumn(facts.now, config: config)
        var colours = [MosaicRGB](repeating: ground, count: config.count)
        let digits = digitTiles(for: scene, facts: facts, geometry: geometry)
        for column in 0 ..< config.columns {
            let skyColour = facts.sky.rgb(atHour: geometry.hour(ofColumn: column), dark: dark)
            for row in 0 ..< config.rows {
                let index = geometry.index(column: column, row: row)
                let jittered = MosaicColour.lightened(skyColour, by: MosaicColour.jitter(index: index) * config.jitter)
                let isFuture = nowColumn.map { column > $0 } ?? true
                let day = isFuture ? MosaicColour.mix(jittered, ground, config.futureMix) : jittered
                switch scene {
                case .day:
                    colours[index] = day
                case .time, .next:
                    colours[index] = digits.contains(index)
                        ? MosaicColour.scaled(jittered, 0.42)
                        : MosaicColour.mix(jittered, ground, 0.55)
                case .sky:
                    colours[index] = skyScene(column: column, row: row, sky: jittered, geometry: geometry)
                case .done:
                    colours[index] = MosaicColour.mix(jittered, ground, 0.78)
                }
            }
        }
        return colours
    }

    /// Where a scene's morph starts: the now column for the day, the left for the time, the sun for the sky, the right
    /// for the next thing, the first laid tile for done.
    static func origin(
        _ scene: MosaicScene,
        geometry: MosaicGeometry,
        facts: MosaicFacts,
        firstLaid: Int?
    ) -> (column: Int, row: Int) {
        let config = geometry.config
        switch scene {
        case .day:
            return (MosaicReadout.nowColumn(facts.now, config: config) ?? 0, config.rows / 2)
        case .time: return (0, config.rows / 2)
        case .sky: return (Int(0.71 * Double(config.columns)), Int(0.58 * Double(config.rows)))
        case .next: return (config.columns - 1, config.rows / 2)
        case .done:
            guard let firstLaid else { return (config.columns / 2, config.rows / 2) }
            return (firstLaid / config.rows, firstLaid % config.rows)
        }
    }

    // MARK: - Sky

    /// The sun as a disc of radius 4.2 tiles at (0.71 W, 0.58 H), a 1.8-tile ring blending into the sky, and dusk ground
    /// below 72% of the height: the sky mixed 55% to #5A4650, x 0.9.
    static func skyScene(column: Int, row: Int, sky: MosaicRGB, geometry: MosaicGeometry) -> MosaicRGB {
        let config = geometry.config
        let sunColumn = 0.71 * Double(config.columns)
        let sunRow = 0.58 * Double(config.rows)
        let distance = hypot(Double(column) + 0.5 - sunColumn, Double(row) + 0.5 - sunRow)
        var colour = sky
        if Double(row) >= 0.72 * Double(config.rows) {
            colour = MosaicColour.scaled(MosaicColour.mix(sky, duskGround, 0.55), 0.9)
        }
        if distance <= 4.2 { return sun }
        if distance <= 6.0 {
            let t = (distance - 4.2) / 1.8
            let eased = t * t * (3 - 2 * t)
            return MosaicColour.mix(sun, colour, eased)
        }
        return colour
    }

    // MARK: - Numerals

    /// A 3 x 5 face for 0 to 9, a row per string.
    static let faces: [Character: [String]] = [
        "0": ["111", "101", "101", "101", "111"],
        "1": ["010", "110", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"],
        "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"],
        "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"],
        "7": ["111", "001", "001", "001", "001"],
        "8": ["111", "101", "111", "101", "111"],
        "9": ["111", "101", "111", "001", "111"],
    ]

    /// The text a scene draws in tiles: "5:42" for the time, the minutes for the next thing, nothing otherwise.
    static func text(for scene: MosaicScene, facts: MosaicFacts, calendar: Calendar = .current) -> String? {
        switch scene {
        case .time:
            let hour = calendar.component(.hour, from: facts.now) % 12
            let minute = calendar.component(.minute, from: facts.now)
            return "\(hour == 0 ? 12 : hour):" + String(format: "%02d", minute)
        case .next:
            return facts.nextTimed.map { String(min(max($0.minutes, 0), 999)) }
        default:
            return nil
        }
    }

    /// The tiles a text covers: the face drawn at 2x (a digit is 6 x 10 tiles, a colon 2 wide), digits 2 apart, the line
    /// centred in the grid.
    static func digitTiles(for scene: MosaicScene, facts: MosaicFacts, geometry: MosaicGeometry) -> Set<Int> {
        guard let text = text(for: scene, facts: facts) else { return [] }
        return numeral(text, geometry: geometry)
    }

    static func numeral(_ text: String, geometry: MosaicGeometry) -> Set<Int> {
        let config = geometry.config
        let widths = text.map { $0 == ":" ? 2 : 6 }
        let total = widths.reduce(0, +) + max(text.count - 1, 0) * 2
        var x = (config.columns - total) / 2
        let top = (config.rows - 10) / 2
        var tiles: Set<Int> = []
        for (character, width) in zip(text, widths) {
            if character == ":" {
                for dy in [2, 3, 6, 7] {
                    for dx in 0 ..< 2 { tiles.insert(geometry.index(column: x + dx, row: top + dy)) }
                }
            } else if let face = faces[character] {
                for (rowIndex, line) in face.enumerated() {
                    for (columnIndex, cell) in line.enumerated() where cell == "1" {
                        for dy in 0 ..< 2 {
                            for dx in 0 ..< 2 {
                                let column = x + columnIndex * 2 + dx
                                let row = top + rowIndex * 2 + dy
                                guard (0 ..< config.columns).contains(column) else { continue }
                                tiles.insert(geometry.index(column: column, row: row))
                            }
                        }
                    }
                }
            }
            x += width + 2
        }
        return tiles
    }
}

import Foundation
import TesseraCore

// The mosaic as a widget (sheet 209, part C): a swipe across it turns to another page, with a 0.5 s wipe in the swipe's
// direction and a caption that changes with the page. Pages: the mood (the default), the weather (sample until Apple
// weather, coarse place only, in memory only: never stored, logged or backed up), the next thing, and the week. The
// rim blend mirrors a page's ground only, never its sign. Money, health, body, calories and calendar titles never
// appear on a page.

enum MosaicPage: Int, CaseIterable, Equatable {
    case mood, weather, next, week

    /// How many pages B's pager has. Only the mood until sheet 213's one-thing pages replace these: the weather,
    /// next and week pages stay built but unreachable (no made-up weather, no empty Next).
    static let count = 1

    /// The wipe between pages: 0.5 s, in the swipe's direction.
    static let wipeSeconds: TimeInterval = 0.5
}

/// The weather page's sample (never stored, logged or backed up: in memory only) until Apple weather is entitled.
enum MosaicWeatherSample {
    static let temperature = 58
}

extension MosaicPage {
    /// The caption under the mosaic for a page (Core's own words where it has them).
    func caption(facts: MosaicFacts?, page pageFacts: MosaicPageFacts?) -> String {
        switch self {
        case .mood: facts?.caption(for: .day) ?? ""
        case .weather: "Weather, sample until Apple weather"
        case .next: pageFacts?.nextCaption ?? "Nothing timed next."
        case .week: pageFacts?.weekCaption ?? "No training days planned this week."
        }
    }
}

enum MosaicPageField {
    /// 3 x 5 letters for the week page.
    static let letters: [Character: [String]] = [
        "M": ["101", "111", "111", "101", "101"],
        "T": ["111", "010", "010", "010", "010"],
        "W": ["101", "101", "111", "111", "101"],
        "F": ["111", "100", "110", "100", "100"],
        "S": ["011", "100", "010", "001", "110"],
    ]
    static let weekLetters: [Character] = ["M", "T", "W", "T", "F", "S", "S"]

    /// The week page's tiles: each day's letter (a 3 x 5 on a 6-column step, centred), with a 3-tile Training mark
    /// under
    /// every done day. Returns, per tile, which day it belongs to and whether it is a mark.
    static func weekTiles(cols: Int, rows: Int) -> [Int: (day: Int, isMark: Bool)] {
        var tiles: [Int: (Int, Bool)] = [:]
        let left = cols / 2 - 21 + 1, top = rows / 2 - 3
        for (day, letter) in weekLetters.enumerated() {
            guard let bitmap = letters[letter] else { continue }
            for (row, line) in bitmap.enumerated() {
                for (column, cell) in line.enumerated() where cell == "1" {
                    let x = left + day * 6 + column, y = top + row
                    if x >= 0, x < cols, y >= 0, y < rows {
                        tiles[x * rows + y] = (day, false)
                    }
                }
            }
            for column in 0 ..< 3 {
                let x = left + day * 6 + column, y = top + 7
                if x >= 0, x < cols, y >= 0, y < rows {
                    tiles[x * rows + y] = (day, true)
                }
            }
        }
        return tiles
    }

    /// The pixel sun: a disc with rays that turn (0.5 rad/s).
    static func sunTiles(cols: Int, rows: Int, elapsed: TimeInterval) -> Set<Int> {
        var tiles = Set<Int>()
        let centreColumn = cols / 2 - 8, centreRow = rows / 2
        for column in centreColumn - 5 ... centreColumn + 5 {
            for row in centreRow - 5 ... centreRow + 5
                where hypot(Double(column - centreColumn), Double(row - centreRow)) <= 3.2
            {
                if column >= 0, column < cols, row >= 0, row < rows {
                    tiles.insert(column * rows + row)
                }
            }
        }
        for ray in 0 ..< 8 {
            let angle = elapsed * 0.5 + Double(ray) * Double.pi / 4
            for radius in [5.2, 6.4] {
                let column = centreColumn + Int((radius * cos(angle)).rounded())
                let row = centreRow + Int((radius * sin(angle)).rounded())
                if column >= 0, column < cols, row >= 0, row < rows {
                    tiles.insert(column * rows + row)
                }
            }
        }
        return tiles
    }

    /// The next page's colour: the app's accent stepping toward the ground as the minute counts down, in eight whole
    /// steps.
    static func nextStep(secondsIntoMinute: Double) -> Double {
        min(max((secondsIntoMinute / 60 * 8).rounded(.down) / 8, 0), 7.0 / 8)
    }

    /// The page's sign as an overlay in the window's own coordinates (nil for the mood page).
    static func light(
        _ page: MosaicPage,
        cols: Int,
        rows: Int,
        start: TimeInterval,
        ground: MosaicTriple,
        context: MosaicMoodContext,
        facts: MosaicPageFacts?,
        now: @escaping () -> Date = { AppClock.now },
        still: Bool
    ) -> MosaicMoodField.Overlay? {
        switch page {
        case .mood:
            return nil
        case .weather:
            let warm: MosaicTriple = (1, 0.72, 0.35)
            let text = MosaicText.raster(
                text: "\(MosaicWeatherSample.temperature)°",
                family: "Outfit",
                weight: -0.2,
                size: 12.5
            )
            let left = cols / 2 + 2, top = rows / 2 - MosaicText.rows / 2
            return { column, row, time, colour in
                if MosaicPageField.sunTiles(cols: cols, rows: rows, elapsed: still ? 0 : time - start)
                    .contains(column * rows + row)
                {
                    return warm
                }
                let x = column - left, y = row - top
                if x >= 0, x < text.width, y >= 0, y < MosaicText.rows, text.on(x, y) {
                    return context.ink
                }
                return colour
            }
        case .next:
            guard let digits = facts?.nextClock else { return nil }
            var config = MosaicConfig.moods
            config.columns = cols
            config.rows = rows
            let tiles = MosaicScenes.numeral(digits, geometry: MosaicGeometry(config: config, width: 0))
            let accent = facts?.nextApp.flatMap { context.accents[$0] } ?? context.ink
            return { column, row, _, colour in
                guard tiles.contains(column * rows + row) else { return colour }
                let seconds = Double(Calendar.current.component(.second, from: now()))
                let step = still ? 0 : nextStep(secondsIntoMinute: seconds)
                return MosaicColour.mix(accent, ground, step)
            }
        case .week:
            let tiles = weekTiles(cols: cols, rows: rows)
            let marks = facts?.weekMarks ?? []
            let training = context.accents[.training] ?? context.ink
            return { column, row, _, colour in
                guard let tile = tiles[column * rows + row] else { return colour }
                let mark = marks.indices.contains(tile.day) ? marks[tile.day] : .rest
                if tile.isMark {
                    return mark == .done ? training : colour
                }
                // Done days and today in full ink; the others 42% toward the ground, in a solid colour.
                return mark == .done || mark == .today ? context.ink : MosaicColour.mix(context.ink, ground, 0.42)
            }
        }
    }
}

import Foundation
import TesseraCore
import UIKit

// Mosaic moments (Design 201, behind homeMosaicMoments, default Off, needs homeMosaicMoods): weather, an announcement,
// Tess, an app's event. A moment interrupts the mood: it takes the window at its own size, runs, then hands back with a
// dissolve (a fall after an announcement). The field and its moving light are pure so each is tested by its pixels.
// Core's `MosaicMomentSource` decides when one plays; nothing here leaves the phone.

/// One word of an announcement: its text and the app whose accent it takes (nil is ink).
struct MosaicAnnounceWord: Equatable {
    let text: String
    let app: AppID?
}

enum MosaicMoment: Equatable {
    case snow, fog, wind, storm, heat
    case announce(words: [MosaicAnnounceWord])
    case tess
    case timer
    case finished(tone: MosaicTone)
    /// A new best: seven Training steps and a blinking star.
    case best
    /// A reminder knocks: the window shakes three times and the right edge lights in the app's accent.
    case reminder(app: AppID?)
    /// A parcel at the door (Kitchen for groceries).
    case delivery(app: AppID?)
    /// A quiet glance at an app, from the apps dial (sheet 206): its own sign in its own colour.
    case glance(app: HomeApp)
}

/// A moment the host asks for. A new event replaces a running one; a mood change cancels it.
struct MosaicMomentEvent: Equatable, Identifiable {
    let id: UUID
    let moment: MosaicMoment

    init(_ moment: MosaicMoment, id: UUID = UUID()) {
        self.id = id
        self.moment = moment
    }
}

extension MosaicMoment {
    /// The window the moment takes (columns x rows); nil keeps the mood's (finished).
    var window: (columns: Int, rows: Int)? {
        switch self {
        case .snow: (50, 32)
        case .fog: (56, 24)
        case .wind: (62, 22)
        case .storm: (56, 34)
        case .heat: (50, 26)
        case .announce: (62, 22)
        case .tess: (40, 24)
        case .timer: (32, 32)
        case .finished, .reminder: nil
        case .best: (44, 30)
        case .delivery: (50, 26)
        case .glance: (44, 24)
        }
    }

    /// How it comes in.
    var transition: MosaicTransition {
        switch self {
        case .snow, .storm: .fall
        case .fog: .dissolve
        case .wind, .announce: .wipe
        case .heat, .timer, .best, .delivery: .wave
        case .glance: .gather
        case .tess: .gather
        case .finished: .wave
        case .reminder: .dissolve
        }
    }

    /// How the mood comes back: snow, storm and an announcement melt (the old tiles drip into the mood), fog and the
    /// timer and finished dissolve, heat waves back, Tess gathers back.
    var returnChangeover: MosaicChangeover {
        switch self {
        case .snow, .storm, .announce, .best: .melt
        case .heat: .transition(.wave)
        case .tess: .transition(.gather)
        case .fog, .wind, .timer, .finished, .reminder, .delivery, .glance: .transition(.dissolve)
        }
    }

    /// Seconds it runs; an announcement runs until its text has crossed.
    var duration: TimeInterval {
        switch self {
        case .snow: 9
        case .fog: 8
        case .wind: 7
        case .storm: 8
        case .heat: 7
        case let .announce(words):
            MosaicText.crawlSeconds(words: words, columns: 62)
        case .tess: 6.5
        case .timer: 4.2
        case .finished: 3.2
        case .best: 4.6
        case .reminder: 3
        case .delivery: 4.4
        case .glance: 3.4
        }
    }

    /// Whether the mood is stepped back under the moment, and by how much.
    var stepBack: Double {
        switch self {
        case .announce: 0.55
        case .tess: 0.50
        case .timer: 0.50
        case .best: 0.40
        default: 0
        }
    }

    /// The moment's field is its own (snow, storm) rather than the mood seen through it.
    var ownField: Bool {
        switch self {
        case .snow, .storm: true
        default: false
        }
    }
}

/// How a hand-back changes over: one of the standard transitions, or the melt of sheet 201.
enum MosaicChangeover: Equatable {
    case transition(MosaicTransition)
    case melt
}

/// What a moment draws: its window, how it comes and goes, the still field and the moving light.
struct MosaicMomentPlan {
    var window: (columns: Int, rows: Int)
    var transition: MosaicTransition
    var returnChangeover: MosaicChangeover
    var duration: TimeInterval
    /// The window-local field; nil keeps the mood's (finished).
    var base: [MosaicTriple]?
    var overlay: MosaicMoodField.Overlay?
    var scale: ((_ column: Int, _ row: Int, _ time: TimeInterval) -> Double)?
    var offset: ((_ column: Int, _ row: Int, _ time: TimeInterval) -> CGPoint)?
}

enum MosaicMomentField {
    private static func hex(_ value: UInt32) -> MosaicTriple {
        MosaicColour.hex(value)
    }

    private static func gradient(_ row: Int, _ rows: Int, _ top: MosaicTriple, _ bottom: MosaicTriple) -> MosaicTriple {
        MosaicColour.mix(top, bottom, min(max(Double(row) / Double(max(rows - 1, 1)), 0), 1))
    }

    /// The plan for a moment. `under` is the mood's field in the moment's window (what fog, wind, an announcement,
    /// Tess and the timer step back from or show through).
    static func plan(
        _ moment: MosaicMoment,
        under: [MosaicTriple],
        window: (columns: Int, rows: Int),
        ground: MosaicTriple,
        context: MosaicMoodContext,
        start: TimeInterval,
        reduceMotion: Bool
    ) -> MosaicMomentPlan {
        let cols = window.columns, rows = window.rows
        var plan = MosaicMomentPlan(window: window, transition: moment.transition,
                                    returnChangeover: moment.returnChangeover, duration: moment.duration)
        var base = under
        if moment.ownField {
            base = ownField(moment, cols: cols, rows: rows)
        } else if moment.stepBack > 0 {
            base = under.map { MosaicColour.mix($0, ground, moment.stepBack) }
        }
        plan.base = base
        if case .finished = moment {
            plan.base = nil
        }
        guard !reduceMotion else {
            // A still frame: the field, the held centre of the timer, Tess's open eyes; no crawl, sway or flash.
            plan.overlay = stillOverlay(moment, cols: cols, rows: rows, context: context)
            return plan
        }
        switch moment {
        case .snow:
            plan.overlay = snowLight(cols: cols, rows: rows, start: start)
        case .fog:
            plan.overlay = fogLight(start: start)
            plan.scale = { column, row, time in
                1 - 0.15 * fogLevel(column: column, row: row, time: time - start)
            }
        case .wind:
            plan.overlay = windLight(cols: cols, rows: rows, start: start)
            plan.offset = { column, row, time in
                let elapsed = time - start
                let gust = 0.65 + 0.35 * sin(elapsed / 1.7 + 1)
                return CGPoint(x: sin(elapsed / 0.26 + Double(column) * 0.5 - Double(row) * 0.25) * 1.8 * gust, y: 0)
            }
        case .storm:
            plan.overlay = stormLight(cols: cols, rows: rows, start: start)
        case .heat:
            plan.overlay = heatLight(base: base, rows: rows, start: start)
            plan.offset = { _, row, time in
                CGPoint(x: 0, y: 0.9 * sin((time - start) / 0.24 + Double(row) * 0.7))
            }
        case let .announce(words):
            plan.overlay = announceLight(words: words, cols: cols, rows: rows, start: start, context: context)
        case .tess:
            plan.overlay = tessLight(cols: cols, rows: rows, start: start, context: context)
        case .timer:
            plan.overlay = timerLight(cols: cols, rows: rows, start: start, context: context)
        case .finished:
            break
        case .best:
            plan.overlay = bestLight(cols: cols, rows: rows, start: start, context: context, still: false)
        case let .reminder(app):
            plan.overlay = reminderLight(cols: cols, start: start, accent: accent(app, context), still: false)
            plan.offset = { _, _, time in CGPoint(x: reminderShake(time: time - start), y: 0) }
        case let .delivery(app):
            plan.overlay = deliveryLight(cols: cols, rows: rows, start: start, ground: ground,
                                         accent: accent(app, context), still: false)
        case let .glance(app):
            plan.overlay = glanceLight(app, cols: cols, rows: rows, start: start, ground: ground, context: context,
                                       still: false)
        }
        return plan
    }

    // MARK: Fields

    private static func ownField(_ moment: MosaicMoment, cols: Int, rows: Int) -> [MosaicTriple] {
        var field = [MosaicTriple](repeating: (0.5, 0.5, 0.5), count: cols * rows)
        for column in 0 ..< cols {
            for row in 0 ..< rows {
                let jitter = MosaicColour.jitter(index: column * rows + row) * 0.03
                let colour: MosaicTriple = if case .snow = moment {
                    gradient(row, rows, hex(0xD8E2EC), hex(0xBBC9D6))
                } else {
                    gradient(row, rows, hex(0x2F3A47), hex(0x1C222B))
                }
                field[column * rows + row] = MosaicColour.lightened(colour, by: jitter)
            }
        }
        return field
    }

    // MARK: Weather

    /// Two flakes a column, each drifting ±0.8 column; a drift builds one row every 1.5 s up to 5.
    private static func snowLight(cols: Int, rows: Int, start: TimeInterval) -> MosaicMoodField.Overlay {
        let white: MosaicTriple = (0.97, 0.98, 1)
        return { column, row, time, colour in
            let elapsed = time - start
            if row >= rows - min(5, Int(elapsed / 1.5)) {
                return MosaicColour.mix(colour, white, 0.9)
            }
            for neighbour in max(column - 1, 0) ... max(min(column + 1, cols - 1), max(column - 1, 0)) {
                for flake in 0 ..< 2 {
                    let seed = neighbour * 2 + flake
                    let x = Double(neighbour) + 0.8 * sin(elapsed * 0.9 + MosaicColour.unit(seed, salt: 51) * 6.28)
                    let speed = 2.5 + MosaicColour.unit(seed, salt: 53) * 2
                    let y = (MosaicColour.unit(seed, salt: 55) * Double(rows) + elapsed * speed)
                        .truncatingRemainder(dividingBy: Double(rows))
                    if Int(x.rounded()) == column, Int(y) == row {
                        return MosaicColour.mix(colour, white, 0.95)
                    }
                }
            }
            return colour
        }
    }

    /// The mist's level at a tile: 0.55 + 0.35 sin(j·0.13 + elapsed/1.8 + i·0.35), in four 0.25 steps.
    static func fogLevel(column: Int, row: Int, time: TimeInterval) -> Double {
        let raw = 0.55 + 0.35 * sin(Double(row) * 0.13 + time / 1.8 + Double(column) * 0.35)
        return (raw / 0.25).rounded() * 0.25
    }

    private static func fogLight(start: TimeInterval) -> MosaicMoodField.Overlay {
        let mist = hex(0xDDE2E7)
        return { column, row, time, colour in
            MosaicColour.mix(colour, mist, fogLevel(column: column, row: row, time: time - start))
        }
    }

    /// 7-tile light streaks run across about a third of the rows.
    private static func windLight(cols: Int, rows _: Int, start: TimeInterval) -> MosaicMoodField.Overlay {
        { column, row, time, colour in
            guard MosaicColour.unit(row, salt: 71) < 0.34 else { return colour }
            let elapsed = time - start
            let head = (elapsed * (12 + MosaicColour.unit(row, salt: 73) * 8) + MosaicColour.unit(row, salt: 75) * 90)
                .truncatingRemainder(dividingBy: Double(cols + 14)) - 7
            let behind = head - Double(column)
            return behind >= 0 && behind < 7 ? MosaicColour.lightened(colour, by: 0.28 * (1 - behind / 7)) : colour
        }
    }

    /// The bolt's column in a row: a random walk of ±1.2 a row from a column at 25 to 75% across.
    static func boltColumn(cycle: Int, row: Int, cols: Int) -> Int {
        var x = Double(cols) * (0.25 + 0.5 * MosaicColour.unit(cycle, salt: 61))
        for step in 0 ... max(row, 0) {
            x += (MosaicColour.unit(cycle * 100 + step, salt: 63) - 0.5) * 2.4
        }
        return Int(x.rounded())
    }

    /// Dark rain; every 3 s a pixel bolt for 260 ms and a 90 ms flash of the field at 0.55.
    private static func stormLight(cols: Int, rows: Int, start: TimeInterval) -> MosaicMoodField.Overlay {
        { column, row, time, colour in
            let elapsed = time - start
            var result = colour
            let speed = 9 + MosaicColour.unit(column, salt: 81) * 6
            let head = (MosaicColour.unit(column, salt: 83) * Double(rows + 6) + elapsed * speed)
                .truncatingRemainder(dividingBy: Double(rows + 6))
            let behind = head - Double(row)
            if behind >= 0, behind < 3 {
                result = MosaicColour.lightened(result, by: 0.2 - behind * 0.05)
            }
            let cycle = Int(elapsed / 3)
            let phase = elapsed - Double(cycle) * 3
            if phase < 0.09 {
                result = MosaicColour.mix(result, (1, 1, 1), 0.55)
            }
            if phase < 0.26, row < Int(Double(rows) * 0.9), column == boltColumn(cycle: cycle, row: row, cols: cols) {
                result = (1, 0.98, 0.85)
            }
            return result
        }
    }

    /// Rows sampled ±0.8 by sin(elapsed/240 ms + j·0.7), a warm 18% tint.
    private static func heatLight(base: [MosaicTriple], rows: Int, start: TimeInterval) -> MosaicMoodField.Overlay {
        let warm = hex(0xF2A65A)
        return { column, row, time, colour in
            let elapsed = time - start
            let sampled = min(
                max(Int((Double(row) + 0.8 * sin(elapsed / 0.24 + Double(row) * 0.7)).rounded()), 0),
                rows - 1
            )
            let index = column * rows + sampled
            let shimmered = index < base.count ? MosaicColour.mix(colour, base[index], min(elapsed / 0.6, 1)) : colour
            return MosaicColour.mix(shimmered, warm, 0.18)
        }
    }

    // MARK: Announcements, Tess, the timer

    /// The words crawl right to left at 15 tiles a second, the app word in its accent and the rest in ink.
    private static func announceLight(
        words: [MosaicAnnounceWord],
        cols: Int,
        rows: Int,
        start: TimeInterval,
        context: MosaicMoodContext
    ) -> MosaicMoodField.Overlay {
        let raster = MosaicText.raster(words: words)
        let top = (rows - MosaicText.rows) / 2
        let accents = words.map { $0.app.flatMap { context.accents[$0] } ?? context.ink }
        return { column, row, time, colour in
            let x = Int((Double(cols) - (time - start) * 15).rounded(.down))
            let textColumn = column - x
            let textRow = row - top
            guard textRow >= 0, textRow < MosaicText.rows, textColumn >= 0, textColumn < raster.width,
                  raster.on(textColumn, textRow) else { return colour }
            return accents[raster.word(at: textColumn)]
        }
    }

    /// Two eyes of 2 x 5 tiles at 40% and 60% of the width, looking ±1 column and blinking to one row for 150 ms every
    /// 2.9 s. Eyes only.
    static func eyeTiles(cols: Int, rows: Int, time: TimeInterval) -> Set<Int> {
        let look = Int(sin(time * 0.6).rounded())
        let blink = time.truncatingRemainder(dividingBy: 2.9) < 0.15
        let middle = rows / 2
        var tiles: Set<Int> = []
        for centre in [Int(Double(cols) * 0.4), Int(Double(cols) * 0.6)] {
            for dx in 0 ..< 2 {
                for dy in -2 ... 2 where !blink || dy == 0 {
                    tiles.insert((centre - 1 + dx + look) * rows + middle + dy)
                }
            }
        }
        return tiles
    }

    private static func tessLight(
        cols: Int,
        rows: Int,
        start: TimeInterval,
        context: MosaicMoodContext
    ) -> MosaicMoodField.Overlay {
        { column, row, time, colour in
            eyeTiles(cols: cols, rows: rows, time: time - start).contains(column * rows + row) ? context.tess : colour
        }
    }

    /// Three square (Chebyshev) pulses 480 ms apart in Kitchen, the centre 3 x 3 held in Kitchen.
    static func timerStrength(column: Int, row: Int, cols: Int, rows: Int, time: TimeInterval) -> Double {
        let centreColumn = Double(cols - 1) / 2, centreRow = Double(rows - 1) / 2
        let distance = max(abs(Double(column) - centreColumn), abs(Double(row) - centreRow))
        if distance <= 1.5 {
            return 1
        }
        var strongest = 0.0
        for pulse in 0 ..< 3 {
            let age = time - Double(pulse) * 0.48
            guard age >= 0, age < 1.2 else { continue }
            let radius = age / 1.2 * Double(min(cols, rows)) / 2
            if abs(distance - radius) < 0.9 {
                strongest = max(strongest, 1 - age / 1.2)
            }
        }
        return strongest
    }

    private static func timerLight(
        cols: Int,
        rows: Int,
        start: TimeInterval,
        context: MosaicMoodContext
    ) -> MosaicMoodField.Overlay {
        let kitchen = context.accents[.kitchen] ?? context.ink
        return { column, row, time, colour in
            let strength = timerStrength(column: column, row: row, cols: cols, rows: rows, time: time - start)
            return strength > 0 ? MosaicColour.mix(colour, kitchen, strength) : colour
        }
    }

    private static func stillOverlay(
        _ moment: MosaicMoment,
        cols: Int,
        rows: Int,
        context: MosaicMoodContext
    ) -> MosaicMoodField.Overlay? {
        switch moment {
        case .timer:
            let kitchen = context.accents[.kitchen] ?? context.ink
            return { column, row, _, colour in
                timerStrength(column: column, row: row, cols: cols, rows: rows, time: 10) > 0
                    ? MosaicColour.mix(colour, kitchen, 1) : colour
            }
        case .tess:
            let tiles = eyeTiles(cols: cols, rows: rows, time: 1.0)
            return { column, row, _, colour in tiles.contains(column * rows + row) ? context.tess : colour }
        case .best:
            return bestLight(cols: cols, rows: rows, start: 0, context: context, still: true)
        case let .reminder(app):
            return reminderLight(cols: cols, start: 0, accent: accent(app, context), still: true)
        case let .delivery(app):
            return deliveryLight(cols: cols, rows: rows, start: 0, ground: (1, 1, 1), accent: accent(app, context),
                                 still: true)
        case let .glance(app):
            return glanceLight(app, cols: cols, rows: rows, start: 0, ground: (1, 1, 1), context: context, still: true)
        default:
            return nil
        }
    }

    /// The sparkle around a finished tile: square rings (Chebyshev distance 1, 2, 3) in its colour, growing from
    /// `landing` 700 ms after the moment starts and fading as they spread.
    static func sparkleLight(
        landing: (column: Int, row: Int),
        colour accent: MosaicTriple,
        start: TimeInterval
    ) -> MosaicMoodField.Overlay {
        { column, row, time, colour in
            let age = time - start - 0.7
            let ring = sparkleRing(age: age)
            guard ring > 0, age < 1.0 else { return colour }
            let distance = max(abs(column - landing.column), abs(row - landing.row))
            guard distance >= 1, distance <= ring else { return colour }
            return MosaicColour.mix(colour, accent, 0.7 * (1 - Double(distance - 1) / 4) * max(0, 1 - age / 1.0))
        }
    }

    /// The square sparkle after a finished tile lands: rings of Chebyshev distance grow one per 90 ms up to 3.
    static func sparkleRing(age: TimeInterval) -> Int {
        guard age >= 0 else { return 0 }
        return min(3, Int(age / 0.09) + 1)
    }
}

// MARK: - Text in tiles

/// An announcement's words drawn in Figtree 600 at 12.5 pt into 14 tile rows, a pixel to a tile (alpha above 0.47).
enum MosaicText {
    static let rows = 14
    static let alphaCut: UInt8 = 120

    struct Raster {
        let width: Int
        private let pixels: [UInt8]
        private let wordStarts: [Int]

        init(width: Int, pixels: [UInt8], wordStarts: [Int]) {
            self.width = width
            self.pixels = pixels
            self.wordStarts = wordStarts
        }

        func on(_ column: Int, _ row: Int) -> Bool {
            pixels[row * width + column] > MosaicText.alphaCut
        }

        /// The word a column of the text belongs to.
        func word(at column: Int) -> Int {
            max(wordStarts.lastIndex { $0 <= column } ?? 0, 0)
        }
    }

    private static func font() -> UIFont {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Figtree",
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight(0.3)],
        ])
        return UIFont(descriptor: descriptor, size: 12.5)
    }

    /// One piece of text in any face, for a page's own words (the weather's temperature in Outfit).
    static func raster(text: String, family: String, weight: CGFloat, size: CGFloat = 12.5) -> Raster {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight(weight)],
        ])
        return raster(
            words: [MosaicAnnounceWord(text: text, app: nil)],
            font: UIFont(descriptor: descriptor, size: size)
        )
    }

    static func raster(words: [MosaicAnnounceWord], font fontOverride: UIFont? = nil) -> Raster {
        let font = fontOverride ?? font()
        var starts: [Int] = []
        var attributed = NSMutableAttributedString()
        var cursor: CGFloat = 0
        for (index, word) in words.enumerated() {
            let piece = (index > 0 ? " " : "") + word.text
            starts
                .append(Int(cursor.rounded(.up)) + (index > 0 ? Int(" ".size(withAttributes: [.font: font]).width) : 0))
            let part = NSAttributedString(string: piece, attributes: [.font: font, .foregroundColor: UIColor.black])
            attributed.append(part)
            cursor += part.size().width
        }
        let width = max(Int(cursor.rounded(.up)) + 1, 1)
        if attributed.length == 0 {
            attributed = NSMutableAttributedString(string: " ")
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: rows), format: format).image { _ in
            let height = attributed.size().height
            attributed.draw(at: CGPoint(x: 0, y: (CGFloat(rows) - height) / 2))
        }
        var bytes = [UInt8](repeating: 0, count: width * rows)
        if let cgImage = image.cgImage, let context = CGContext(
            data: &bytes, width: width, height: rows, bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
        ) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: rows))
        }
        return Raster(width: width, pixels: bytes, wordStarts: starts)
    }

    /// Seconds for the text to cross a window `columns` wide at 15 tiles a second, and a breath.
    static func crawlSeconds(words: [MosaicAnnounceWord], columns: Int) -> TimeInterval {
        let width = raster(words: words).width
        return Double(width + columns) / 15 + 0.4
    }
}

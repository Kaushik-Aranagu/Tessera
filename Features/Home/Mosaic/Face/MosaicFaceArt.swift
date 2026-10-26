import Foundation
import TesseraCore

// The faces' pixels (Home 236 v2.1). A face is drawn in whole tiles of a window `columns` x `rows`, left-based: tile
// (0, 0) is the window's top-left. Pure functions of (tile, animation seconds, the clock), so every face is tested by
// reading its colours. A scene is still except for one slow life; under Reduce Motion and Low Power the host passes
// animation 0.

/// The accents a face may use as triples, matched to the look. Nothing here is decoration: each colour is its app's.
struct MosaicFacePalette {
    var training: MosaicTriple
    var kitchen: MosaicTriple
    var lists: MosaicTriple
    var routines: MosaicTriple
    var sky: MosaicTriple
    var rain: MosaicTriple

    /// The rain token (557A93 light, 9DBACE dark), as the accent tokens carry it.
    static func rainTriple(dark: Bool) -> MosaicTriple {
        MosaicColour.hex(dark ? 0x9DBACE : 0x557A93)
    }

    static func make(accents: [AppID: MosaicTriple], dark: Bool, fallback: MosaicTriple) -> MosaicFacePalette {
        MosaicFacePalette(
            training: accents[.training] ?? fallback, kitchen: accents[.kitchen] ?? fallback,
            lists: accents[.lists] ?? fallback, routines: accents[.routines] ?? fallback,
            sky: MosaicColour.hex(dark ? 0xE8A06A : 0xC9772E), rain: rainTriple(dark: dark)
        )
    }
}

struct MosaicFaceArt {
    let face: MosaicFace
    let columns: Int
    let rows: Int
    let palette: MosaicFacePalette
    /// The clock the numbers were read at (the bake); a ticking face is drawn again at the live clock.
    let now: Date

    static let paper: MosaicTriple = (0.96, 0.94, 0.88)
    static let rowsDefault = 28

    // MARK: Colour

    /// The face's colour at a tile: its backdrop under any plate and ink, untinted.
    func colour(column: Int, row: Int, animation: Double, now: Date) -> MosaicTriple {
        let back = backdrop(column: column, row: row, animation: animation, now: now)
        let layout = layout(now: now)
        let key = column * 1000 + row
        if layout.ink.contains(key) {
            return Self.paper
        }
        if layout.plate.contains(key) {
            return MosaicColour.scaled(back, 0.42)
        }
        return back
    }

    func backdrop(column: Int, row: Int, animation: Double, now: Date) -> MosaicTriple {
        switch face.kind {
        case .gallery:
            guard let scenery = face.scenery else { return palette.rain }
            return MosaicSceneArt.colour(scenery, column: column, row: row, columns: columns, rows: rows,
                                         time: animation)
        case .weather:
            return MosaicSceneArt.colour(Self.weatherScene(face.weather, now: now), column: column, row: row,
                                         columns: columns, rows: rows, time: animation)
        case .workout:
            return workoutBack(column: column, row: row, animation: animation, now: now)
        case .now:
            return nowBack(column: column, row: row, animation: animation)
        }
    }

    /// The scene that sits behind the weather's numbers.
    static func weatherScene(_ reading: MosaicWeatherReading?, now: Date, calendar: Calendar = .current)
        -> MosaicScenery
    {
        guard let reading else { return .mountainsAndLake }
        switch reading.condition {
        case .rain: return .rainOnWindow
        case .snow: return .snow
        case .clear:
            let hour = calendar.component(.hour, from: now)
            if hour < 6 || hour >= 20 {
                return .nightSky
            }
            let celsius = reading.fahrenheit ? Int((Double(reading.temperature - 32) * 5 / 9).rounded())
                : reading.temperature
            return celsius >= 22 ? .beach : .mountainsAndLake
        }
    }

    // MARK: Ink layout

    /// Window-local tile keys (column * 1000 + row) for ink and for the plate behind it.
    struct Layout {
        var ink: Set<Int> = []
        var plate: Set<Int> = []
    }

    /// The layouts of the last few seconds: the bake and the live clock are asked for alternately, tile by tile.
    private final class Cache: @unchecked Sendable {
        var layouts: [Int: Layout] = [:]
    }

    private let cache = Cache()

    /// The ink at `now`, rebuilt once a second.
    func layout(now: Date) -> Layout {
        let second = Int(now.timeIntervalSinceReferenceDate)
        if let found = cache.layouts[second] {
            return found
        }
        var placed = Layout()
        for tile in inkTiles(now: now) where tile.column >= 0 && tile.column < columns && tile.row >= 0
            && tile.row < rows
        {
            placed.ink.insert(tile.column * 1000 + tile.row)
        }
        for key in placed.ink {
            let column = key / 1000, row = key % 1000
            for dx in -1 ... 1 {
                for dy in -1 ... 1 {
                    let next = (column + dx) * 1000 + row + dy
                    if !placed.ink.contains(next), column + dx >= 0, column + dx < columns, row + dy >= 0,
                       row + dy < rows
                    {
                        placed.plate.insert(next)
                    }
                }
            }
        }
        if cache.layouts.count > 3 {
            cache.layouts.removeAll()
        }
        cache.layouts[second] = placed
        return placed
    }

    /// The tiles the face's numbers and words cover. Gallery and Now carry none (they are pictures).
    func inkTiles(now: Date) -> [(column: Int, row: Int)] {
        switch face.kind {
        case .gallery, .now: []
        case .weather: weatherInk()
        case .workout: workoutInk(now: now)
        }
    }

    private func weatherInk() -> [(column: Int, row: Int)] {
        guard let reading = face.weather else { return [] }
        var out: [(column: Int, row: Int)] = []
        let temperature = String(abs(reading.temperature))
        let sign = reading.temperature < 0 ? "-" : ""
        let text = sign + temperature
        let left = 5
        out += MosaicPixelFont.tiles(text, left: left, top: 4, scale: 2)
        // The degree mark: a 2 x 2 ring corner after the numerals.
        let after = left + MosaicPixelFont.width(of: text, scale: 2) + 2
        for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)] {
            out.append((after + dx, 4 + dy))
        }
        if let change = reading.next {
            let words = "\(change.word) \(change.hour)"
            out += MosaicPixelFont.tiles(MosaicPixelFont.fitted(words, columns: 34, scale: 1), left: left, top: 18,
                                         scale: 1)
        }
        // The week's seven highs as bars in the room beyond the numbers.
        if columns >= 80, reading.week.count == 7 {
            let low = reading.week.min() ?? 0, high = reading.week.max() ?? 1
            let span = max(high - low, 1)
            let right = columns - 5
            for (index, value) in reading.week.enumerated() {
                let height = 3 + Int((Double(value - low) / Double(span) * 11).rounded())
                let x = right - (7 - index) * 5 + 1
                for dx in 0 ..< 3 {
                    for dy in 0 ..< height {
                        out.append((x + dx, 22 - dy))
                    }
                }
                if index == 0 {
                    for dx in 0 ..< 3 {
                        out.append((x + dx, 24))
                    }
                }
            }
        }
        return out
    }

    private func workoutInk(now: Date) -> [(column: Int, row: Int)] {
        guard let workout = face.workout else { return [] }
        var out: [(column: Int, row: Int)] = []
        if let left = workout.restLeft(at: now) {
            let text = String(format: "%d:%02d", left / 60, left % 60)
            let start = (columns - MosaicPixelFont.width(of: text, scale: 2)) / 2
            out += MosaicPixelFont.tiles(text, left: start, top: 5, scale: 2)
            // The rest draining: a two-tile bar across the width.
            let span = columns - 12
            let share = workout.restTotal > 0 ? min(max(Double(left) / workout.restTotal, 0), 1) : 0
            let filled = Int((Double(span) * share).rounded())
            for column in 0 ..< filled {
                out.append((6 + column, 20))
                out.append((6 + column, 21))
            }
        } else {
            let minutes = workout.minutes(at: now)
            let text = MosaicPixelFont.fitted("\(minutes) MIN", columns: columns - 12, scale: 1)
            out += MosaicPixelFont.tiles(text, left: 6, top: 21, scale: 1)
        }
        return out
    }

    // MARK: Workout

    private func workoutBack(column: Int, row: Int, animation: Double, now: Date) -> MosaicTriple {
        let base = Self.gradient(palette.training, column: column, row: row, rows: rows, low: 0.24, high: 0.40)
        guard let workout = face.workout, workout.restLeft(at: now) == nil else { return base }
        let shape = Self.barbell(column: column, row: row, columns: columns, rows: rows, time: animation)
        return shape.map { MosaicColour.mix(base, MosaicColour.lightened(palette.training, by: 0.35), $0) } ?? base
    }

    /// A barbell that lifts one to three rows and sets down every 1.4 s, drawn across the window; the strength is how
    /// far toward the accent a tile goes.
    static func barbell(column: Int, row: Int, columns: Int, rows: Int, time: Double) -> Double? {
        let lift = Int((2 * (1 - cos(2 * Double.pi * time / 1.4))).rounded())
        let middle = rows / 2 - lift
        let outer = 12, inner = 15
        let right = columns - 1 - outer
        if (inner ... columns - 1 - inner).contains(column), row == middle || row == middle + 1 {
            return 1
        }
        if (outer ... outer + 1).contains(column) || (right - 1 ... right).contains(column),
           (middle - 6 ... middle + 7).contains(row)
        {
            return 1
        }
        if (outer + 2 ... outer + 3).contains(column) || (right - 3 ... right - 2).contains(column),
           (middle - 4 ... middle + 5).contains(row)
        {
            return 0.7
        }
        return nil
    }

    // MARK: Now

    private func nowBack(column: Int, row: Int, animation: Double) -> MosaicTriple {
        guard let reading = face.now else { return palette.rain }
        let accent: MosaicTriple = switch reading.kind {
        case .rain: palette.rain
        case .sun: palette.sky
        case .bag: palette.kitchen
        case .barbell: palette.training
        case .suitcase: palette.lists
        case .clock: palette.routines
        }
        let base = Self.gradient(accent, column: column, row: row, rows: rows, low: 0.26, high: 0.42)
        guard let strength = Self.nowShape(reading.kind, column: column, row: row, columns: columns, rows: rows,
                                           time: animation) else { return base }
        let lit = reading.kind == .rain ? MosaicColour.lightened(accent, by: 0.55) : MosaicColour.lightened(
            accent, by: 0.4
        )
        return MosaicColour.mix(base, lit, strength)
    }

    /// The drawing of an announcement: nil is nothing, otherwise how far toward the light colour the tile goes.
    static func nowShape(_ kind: MosaicNowKind, column: Int, row: Int, columns: Int, rows: Int, time: Double)
        -> Double?
    {
        switch kind {
        case .rain: rain(column: column, row: row, columns: columns, rows: rows, time: time)
        case .sun: sun(column: column, row: row, columns: columns, rows: rows, time: time)
        case .bag: bag(column: column, row: row, columns: columns, rows: rows, time: time)
        case .barbell: barbell(column: column, row: row, columns: columns, rows: rows, time: time)
        case .suitcase: suitcase(column: column, row: row, columns: columns, time: time)
        case .clock: clock(column: column, row: row, columns: columns, rows: rows, time: time)
        }
    }

    /// A cloud along the top and streaks that fall, a tile column each, on a slant.
    private static func rain(column: Int, row: Int, columns _: Int, rows: Int, time: Double) -> Double? {
        let cloudEdge = 3 + Int((MosaicSceneArt.hash(column / 3, 71) * 4).rounded())
        if row < cloudEdge {
            return row < cloudEdge - 1 ? 0.55 : 0.3
        }
        // A streak: this column's own speed and offset; each has a head and a three-tile tail.
        let slant = row / 4
        let source = column + slant
        guard MosaicSceneArt.hash(source, 72) < 0.22 else {
            // A ring where a drop lands.
            if row == rows - 2, MosaicSceneArt.hash(column, 73) > 0.93 {
                return Int(time * 6 + Double(column)) % 3 == 0 ? 0.5 : nil
            }
            return nil
        }
        let speed = 9 + MosaicSceneArt.hash(source, 74) * 8
        let head = Int(time * speed + MosaicSceneArt.hash(source, 75) * Double(rows + 8)) % (rows + 8)
        let tail = head - row
        return tail >= 0 && tail < 4 ? 0.9 - Double(tail) * 0.18 : nil
    }

    /// A disc of sun with eight rays turning, and a warm halo of lone ray tiles beyond.
    private static func sun(column: Int, row: Int, columns: Int, rows: Int, time: Double) -> Double? {
        let centre = (x: Double(columns) - 22, y: Double(rows) / 2 - 0.5)
        let dx = Double(column) + 0.5 - centre.x, dy = Double(row) + 0.5 - centre.y
        let distance = hypot(dx, dy)
        if distance <= 5.2 {
            return 1
        }
        guard distance <= 13 else { return nil }
        let angle = atan2(dy, dx) - time * 0.5
        let ray = cos(angle * 8)
        return distance > 7 && ray > 0.82 ? 0.75 - (distance - 7) * 0.05 : nil
    }

    /// A paper bag with three items bobbing out, and more items drifting across the room to its left.
    private static func bag(column: Int, row: Int, columns: Int, rows: Int, time: Double) -> Double? {
        let left = columns - 34, top = 10
        if (left ... left + 17).contains(column), (top ... top + 14).contains(row) {
            return row == top ? 0.6 : 1
        }
        for index in 0 ..< 3 {
            let bob = Int((sin(time * 4 + Double(index) * 2.1) * 1.2).rounded())
            let base = left + 2 + index * 6
            if (base ... base + 3).contains(column), (top - 6 + bob ... top - 2 + bob).contains(row) {
                return 0.85
            }
        }
        // Drifting items: a slow row of small blocks on a belt.
        let belt = Int(time * 3) % 12
        if row == rows - 4, (column + belt) % 12 < 3, column < left - 4 {
            return 0.55
        }
        return nil
    }

    /// A case: outline, handle, and a fill that stands at a share.
    private static func suitcase(column: Int, row: Int, columns: Int, time: Double) -> Double? {
        let left = columns - 38, top = 7, width = 28, height = 18
        if (left + 9 ... left + 18).contains(column), row == top - 3 || row == top - 2 {
            return 0.7
        }
        if (left + 9 ... left + 10).contains(column) || (left + 17 ... left + 18).contains(column),
           (top - 3 ... top - 1).contains(row)
        {
            return 0.7
        }
        guard (left ... left + width - 1).contains(column), (top ... top + height - 1).contains(row) else {
            return nil
        }
        let edge = column == left || column == left + width - 1 || row == top || row == top + height - 1
        if edge {
            return 1
        }
        // A band of light climbs the fill, a row at a time, as things go in.
        let climb = top + height - 2 - Int(time * 5) % (height - 2)
        if row == climb {
            return 0.7
        }
        return row > top + height * 2 / 5 ? 0.45 : 0.18
    }

    /// A ring and one hand sweeping.
    private static func clock(column: Int, row: Int, columns: Int, rows: Int, time: Double) -> Double? {
        let centre = (x: Double(columns) - 24, y: Double(rows) / 2 - 0.5)
        let dx = Double(column) + 0.5 - centre.x, dy = Double(row) + 0.5 - centre.y
        let distance = hypot(dx, dy)
        if distance > 10.5, distance < 12 {
            return 1
        }
        let angle = time * 1.7 - Double.pi / 2
        let along = dx * cos(angle) + dy * sin(angle)
        let across = abs(-dx * sin(angle) + dy * cos(angle))
        if along > 0, along < 9, across < 0.8 {
            return 1
        }
        return distance < 1.2 ? 1 : nil
    }

    // MARK: Pieces

    /// A dark ground in the accent, a little lighter toward the bottom, each tile jittered so it reads as a mosaic.
    static func gradient(_ accent: MosaicTriple, column: Int, row: Int, rows: Int, low: Double, high: Double)
        -> MosaicTriple
    {
        let unit = Double(row) / Double(max(rows - 1, 1))
        let jitter = (MosaicSceneArt.hash(column, row, 61) - 0.5) * 0.08
        return MosaicColour.scaled(accent, low + (high - low) * unit + jitter)
    }
}

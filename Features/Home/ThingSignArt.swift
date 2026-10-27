import Foundation

// Sheet 213, Home 236: the pixel sign for the one thing Home shows. 20 x 20 tiles (80 pt) at the top right of the
// space, drawn in
// the thing's accent, stepped toward the page, with a little motion. A sign is a fixed drawing: it carries no data
// beyond a share (the list's done share), never an amount, a number or a name.

enum ThingSignKind: CaseIterable, Equatable {
    case training, groceries, birthday, task, list, weather, routine
}

struct ThingSignCell: Hashable {
    let column: Int
    let row: Int
    /// 1 is the full accent; less is stepped toward the page in eighths.
    let strength: Double
    /// The second tone (the birthday's lighter rose).
    let alt: Bool

    init(_ column: Int, _ row: Int, strength: Double = 1, alt: Bool = false) {
        self.column = column
        self.row = row
        self.strength = strength
        self.alt = alt
    }
}

enum ThingSignArt {
    static let side = 20

    /// The cells of a sign at `elapsed` seconds. `share` (0...1) is only read by the list's suitcase. `still` gives the
    /// resting drawing (Reduce Motion).
    static func cells(_ kind: ThingSignKind, elapsed: TimeInterval, share: Double = 0.5,
                      still: Bool = false) -> [ThingSignCell]
    {
        var bitmap = Bitmap()
        let time = still ? 0 : elapsed
        switch kind {
        case .training: training(&bitmap, time: time)
        case .groceries: groceries(&bitmap, time: time)
        case .birthday: birthday(&bitmap, time: time, still: still)
        case .task: task(&bitmap, time: time, still: still)
        case .list: list(&bitmap, share: share)
        case .weather: weather(&bitmap, time: time)
        case .routine: routine(&bitmap, time: time)
        }
        return bitmap.sorted
    }

    /// Whole eighths, as the page steps a colour toward it.
    static func stepped(_ strength: Double) -> Double {
        (min(max(strength, 0), 1) * 8).rounded() / 8
    }

    // MARK: Drawing

    struct Bitmap {
        private(set) var cells: [Int: ThingSignCell] = [:]

        mutating func set(_ column: Int, _ row: Int, strength: Double = 1, alt: Bool = false) {
            guard column >= 0, column < ThingSignArt.side, row >= 0, row < ThingSignArt.side else { return }
            cells[row * ThingSignArt.side + column] = ThingSignCell(column, row, strength: strength, alt: alt)
        }

        mutating func fill(_ columns: ClosedRange<Int>, _ rows: ClosedRange<Int>, strength: Double = 1,
                           alt: Bool = false)
        {
            for column in columns {
                for row in rows {
                    set(column, row, strength: strength, alt: alt)
                }
            }
        }

        mutating func line(from start: (Double, Double), to end: (Double, Double), strength: Double = 1) {
            let steps = max(Int((hypot(end.0 - start.0, end.1 - start.1) * 2).rounded(.up)), 1)
            for step in 0 ... steps {
                let unit = Double(step) / Double(steps)
                set(Int((start.0 + (end.0 - start.0) * unit).rounded()),
                    Int((start.1 + (end.1 - start.1) * unit).rounded()), strength: strength)
            }
        }

        mutating func disc(centre: (Double, Double), radius: Double, strength: Double = 1) {
            let reach = Int(radius.rounded(.up))
            for column in Int(centre.0) - reach ... Int(centre.0) + reach {
                for row in Int(centre.1) - reach ... Int(centre.1) + reach
                    where hypot(Double(column) - centre.0, Double(row) - centre.1) <= radius
                {
                    set(column, row, strength: strength)
                }
            }
        }

        var sorted: [ThingSignCell] {
            cells.values.sorted { ($0.row, $0.column) < ($1.row, $1.column) }
        }
    }

    // MARK: Signs (Home 236: new drawings on the 20 x 20)

    /// A barbell with three plates a side that lifts one to three rows and sets down every 1.4 s, a puff of chalk on
    /// the set-down.
    private static func training(_ bitmap: inout Bitmap, time: TimeInterval) {
        let phase = time.truncatingRemainder(dividingBy: 1.4) / 1.4
        let lift = Int((2 * (1 - cos(2 * Double.pi * phase)) * 0.75).rounded())
        let middle = 9 - lift
        bitmap.fill(1 ... 18, middle ... (middle + 1))
        for (index, half) in [(2, 3), (4, 5), (6, 7)].enumerated() {
            let reach = 6 - index * 2
            bitmap.fill(half.0 ... half.1, (middle - reach + 1) ... (middle + reach), strength: index == 2 ? 0.7 : 1)
            bitmap.fill((19 - half.1) ... (19 - half.0), (middle - reach + 1) ... (middle + reach),
                        strength: index == 2 ? 0.7 : 1)
        }
        bitmap.fill(0 ... 0, (middle - 1) ... (middle + 2), strength: 0.55)
        bitmap.fill(19 ... 19, (middle - 1) ... (middle + 2), strength: 0.55)
        if lift == 0 {
            // Chalk on the floor beneath.
            for column in [4, 9, 10, 15] {
                bitmap.set(column, 17, strength: 0.4)
            }
        }
    }

    /// A paper bag with handles, and a loaf, an apple and a carton bobbing out of it.
    private static func groceries(_ bitmap: inout Bitmap, time: TimeInterval) {
        bitmap.fill(3 ... 16, 9 ... 18)
        bitmap.fill(3 ... 16, 9 ... 9, strength: 0.7)
        bitmap.fill(9 ... 10, 11 ... 14, strength: 0.7)
        bitmap.fill(7 ... 7, 6 ... 8, strength: 0.55)
        bitmap.fill(12 ... 12, 6 ... 8, strength: 0.55)
        bitmap.fill(7 ... 12, 5 ... 5, strength: 0.55)
        let bobs = (0 ..< 3).map { Int((sin(time * 4 + Double($0) * 2.1) * 0.9).rounded()) }
        // The loaf, leaning.
        for step in 0 ..< 5 {
            bitmap.fill(
                (4 + step) ... (5 + step),
                (6 - step / 2 + bobs[0]) ... (7 - step / 2 + bobs[0]),
                strength: 0.85
            )
        }
        // The apple.
        bitmap.disc(centre: (10.5, 6.5 + Double(bobs[1])), radius: 1.9, strength: 0.9)
        // The carton.
        bitmap.fill(13 ... 15, (3 + bobs[2]) ... (8 + bobs[2]), strength: 0.8)
    }

    /// A cake with three candles that flicker, and confetti falling in two roses.
    private static func birthday(_ bitmap: inout Bitmap, time: TimeInterval, still: Bool) {
        bitmap.fill(3 ... 16, 13 ... 18)
        bitmap.fill(3 ... 16, 13 ... 13, strength: 0.7)
        bitmap.fill(5 ... 14, 9 ... 12, strength: 0.9, alt: true)
        for (index, column) in [6, 9, 12].enumerated() {
            bitmap.fill(column ... column, 6 ... 8, strength: 0.6)
            let flame = still || Int(time * 5 + Double(index)) % 2 == 0
            bitmap.set(column, flame ? 4 : 5, alt: true)
            if flame {
                bitmap.set(column, 5, alt: true)
            }
        }
        for index in 0 ..< 10 {
            let column = (index * 7 + 1) % side
            let speed = 3.0 + Double(index % 4)
            let row = still ? (index * 5) % side : Int(time * speed + Double(index * 5)) % side
            guard row < 3 || column < 2 || column > 17 else { continue }
            bitmap.set(column, row, strength: index % 3 == 0 ? 0.8 : 1, alt: index % 2 == 1)
        }
    }

    /// A sheet with three lines and a tick that draws itself.
    private static func task(_ bitmap: inout Bitmap, time: TimeInterval, still: Bool) {
        bitmap.fill(4 ... 15, 1 ... 18, strength: 0.3)
        bitmap.fill(4 ... 15, 1 ... 1, strength: 0.7)
        bitmap.fill(4 ... 4, 1 ... 18, strength: 0.7)
        bitmap.fill(15 ... 15, 1 ... 18, strength: 0.7)
        bitmap.fill(4 ... 15, 18 ... 18, strength: 0.7)
        for row in [6, 10, 14] {
            bitmap.fill(9 ... 13, row ... row, strength: 0.8)
        }
        let cycle = 2.4
        let length = still ? 4 : min(Int(time.truncatingRemainder(dividingBy: cycle) / 1.6 * 5), 5)
        let tick = [(5, 13), (6, 14), (7, 13), (8, 12), (9, 11)]
        for (column, row) in tick.prefix(length) {
            bitmap.set(column, row)
        }
    }

    /// A case with straps that fills from the bottom to the done share.
    private static func list(_ bitmap: inout Bitmap, share: Double) {
        bitmap.fill(3 ... 16, 6 ... 17, strength: 0.28)
        bitmap.fill(8 ... 8, 2 ... 5, strength: 0.55)
        bitmap.fill(11 ... 11, 2 ... 5, strength: 0.55)
        bitmap.fill(8 ... 11, 2 ... 2, strength: 0.55)
        bitmap.fill(6 ... 6, 6 ... 17, strength: 0.45)
        bitmap.fill(13 ... 13, 6 ... 17, strength: 0.45)
        let filled = Int((min(max(share, 0), 1) * 12).rounded())
        if filled > 0 {
            bitmap.fill(3 ... 16, (18 - filled) ... 17)
        }
    }

    /// A sun with eight rays turning slowly, and a small cloud passing in front.
    private static func weather(_ bitmap: inout Bitmap, time: TimeInterval) {
        let centre = (9.5, 9.5)
        bitmap.disc(centre: centre, radius: 3.8)
        for ray in 0 ..< 8 {
            let angle = Double(ray) * Double.pi / 4 + time * 0.6
            bitmap.line(
                from: (centre.0 + cos(angle) * 5.8, centre.1 + sin(angle) * 5.8),
                to: (centre.0 + cos(angle) * 8.6, centre.1 + sin(angle) * 8.6)
            )
        }
        let drift = Int((time * 1.2).truncatingRemainder(dividingBy: 6))
        bitmap.fill((10 + drift / 2) ... (15 + drift / 2), 14 ... 15, strength: 0.5)
        bitmap.fill((11 + drift / 2) ... (13 + drift / 2), 13 ... 13, strength: 0.5)
    }

    /// A clock: a ring of twelve ticks and one hand sweeping, a centre tile.
    private static func routine(_ bitmap: inout Bitmap, time: TimeInterval) {
        for tick in 0 ..< 12 {
            let angle = Double(tick) * Double.pi / 6
            bitmap.set(Int((9.5 + cos(angle) * 8.6).rounded()), Int((9.5 + sin(angle) * 8.6).rounded()),
                       strength: tick % 3 == 0 ? 1 : 0.55)
        }
        let angle = time * 1.7 - Double.pi / 2
        bitmap.line(from: (9.5, 9.5), to: (9.5 + cos(angle) * 6.5, 9.5 + sin(angle) * 6.5))
        bitmap.set(9, 9)
        bitmap.set(10, 10)
    }
}

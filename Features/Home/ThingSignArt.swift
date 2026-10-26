import Foundation

// Sheet 213: the pixel sign for the one thing Home shows. 18 x 18 tiles (72 pt) at the top right of the space, drawn in
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
    static let side = 18

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

        mutating func fill(_ columns: ClosedRange<Int>, _ rows: ClosedRange<Int>, strength: Double = 1) {
            for column in columns {
                for row in rows {
                    set(column, row, strength: strength)
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

    // MARK: Signs

    /// A barbell that lifts one to three rows and sets down, every 1.4 s.
    private static func training(_ bitmap: inout Bitmap, time: TimeInterval) {
        let lift = Int((1.5 * (1 - cos(2 * Double.pi * time / 1.4))).rounded())
        let middle = 11 - lift
        bitmap.fill(4 ... 13, middle ... middle)
        bitmap.fill(2 ... 3, (middle - 4) ... (middle + 4))
        bitmap.fill(14 ... 15, (middle - 4) ... (middle + 4))
        bitmap.fill(4 ... 4, (middle - 2) ... (middle + 2), strength: 0.7)
        bitmap.fill(13 ... 13, (middle - 2) ... (middle + 2), strength: 0.7)
    }

    /// A bag with three items bobbing out of it.
    private static func groceries(_ bitmap: inout Bitmap, time: TimeInterval) {
        bitmap.fill(4 ... 13, 8 ... 16)
        bitmap.fill(4 ... 13, 8 ... 8, strength: 0.7)
        bitmap.fill(6 ... 6, 5 ... 7, strength: 0.55)
        bitmap.fill(11 ... 11, 5 ... 7, strength: 0.55)
        bitmap.fill(6 ... 11, 4 ... 4, strength: 0.55)
        for (index, column) in [5, 8, 11].enumerated() {
            let bob = Int((sin(time * 4 + Double(index) * 2.1) * 0.9).rounded())
            bitmap.fill(column ... (column + 1), (5 + bob) ... (6 + bob), strength: 0.85)
        }
    }

    /// Confetti falling in two roses.
    private static func birthday(_ bitmap: inout Bitmap, time: TimeInterval, still: Bool) {
        for index in 0 ..< 16 {
            let column = (index * 7 + 3) % side
            let speed = 3.0 + Double(index % 4)
            let row = still ? (index * 5) % side : Int(time * speed + Double(index * 5)) % side
            bitmap.set(column, row, strength: index % 3 == 0 ? 0.8 : 1, alt: index % 2 == 1)
        }
    }

    /// A pen line that writes itself left to right, the pen at its end.
    private static func task(_ bitmap: inout Bitmap, time: TimeInterval, still: Bool) {
        let cycle = 2.4
        let length = still ? 12 : min(Int(time.truncatingRemainder(dividingBy: cycle) / 1.6 * 13), 13)
        if length > 0 {
            bitmap.fill(2 ... (2 + length - 1), 12 ... 12)
        }
        let tip = 2 + length
        bitmap.set(tip, 11)
        for step in 1 ... 4 {
            bitmap.set(tip + step, 11 - step, strength: 0.6)
        }
    }

    /// A suitcase that fills from the bottom to the done share.
    private static func list(_ bitmap: inout Bitmap, share: Double) {
        bitmap.fill(3 ... 14, 6 ... 15, strength: 0.28)
        bitmap.fill(7 ... 7, 3 ... 5, strength: 0.55)
        bitmap.fill(10 ... 10, 3 ... 5, strength: 0.55)
        bitmap.fill(7 ... 10, 3 ... 3, strength: 0.55)
        let filled = Int((min(max(share, 0), 1) * 10).rounded())
        if filled > 0 {
            bitmap.fill(3 ... 14, (16 - filled) ... 15)
        }
    }

    /// A sun with eight rays turning slowly.
    private static func weather(_ bitmap: inout Bitmap, time: TimeInterval) {
        let centre = (8.5, 8.5)
        bitmap.disc(centre: centre, radius: 3.4)
        for ray in 0 ..< 8 {
            let angle = Double(ray) * Double.pi / 4 + time * 0.6
            bitmap.line(
                from: (centre.0 + cos(angle) * 5.4, centre.1 + sin(angle) * 5.4),
                to: (centre.0 + cos(angle) * 7.6, centre.1 + sin(angle) * 7.6)
            )
        }
    }

    /// One clock hand sweeping, a centre tile and no ring.
    private static func routine(_ bitmap: inout Bitmap, time: TimeInterval) {
        let angle = time * 1.7 - Double.pi / 2
        bitmap.line(from: (8.5, 8.5), to: (8.5 + cos(angle) * 7, 8.5 + sin(angle) * 7))
        bitmap.set(8, 8)
        bitmap.set(9, 9)
    }
}

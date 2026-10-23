import Foundation
import TesseraCore

// An app's glance (sheet 206): when the apps dial settles on an app, the mosaic plays a quiet moment of that app's own
// sign in its own colour: 44 x 24, in by gather, out by dissolve after 3.4 s, the mood behind washed 18% toward the
// accent (the rim samples that washed mood, never the sign). Motifs are fixed pixel drawings: they carry no data, and
// Money shows pools with no numbers and no bars. Reduce Motion: the sign is shown still.

extension MosaicMomentField {
    /// The accent a glance takes: the app's, ink for Tasks.
    static func glanceAccent(_ app: HomeApp, _ context: MosaicMoodContext) -> MosaicTriple {
        AppID.allCases.first { $0.name == app.rawValue }.flatMap { context.accents[$0] } ?? context.ink
    }

    /// The 18% wash toward the accent that the mood behind a glance takes.
    static let glanceWash = 0.18

    // MARK: Pixel signs

    /// The tiles a motif lights at `elapsed` seconds, each as (column, row) in the window's own coordinates.
    static func glanceTiles(_ app: HomeApp, cols: Int, rows: Int, elapsed: TimeInterval) -> Set<Int> {
        let centreColumn = cols / 2, centreRow = rows / 2
        var tiles = Set<Int>()
        func add(_ column: Int, _ row: Int) {
            guard column >= 0, column < cols, row >= 0, row < rows else { return }
            tiles.insert(column * rows + row)
        }
        switch app {
        case .training:
            // An 11 x 5 barbell that lifts one row every 700 ms.
            let lift = min(3, Int(elapsed / 0.7))
            let left = centreColumn - 5, top = centreRow - 2 - lift
            for column in 1 ... 9 {
                add(left + column, top + 2)
            }
            for row in 0 ... 4 {
                add(left + 1, top + row); add(left + 9, top + row)
            }
            for row in 1 ... 3 {
                add(left + 2, top + row); add(left + 8, top + row)
            }
        case .kitchen:
            // An 11 x 5 pot with three steam pixels rising.
            let left = centreColumn - 5, top = centreRow - 1
            for column in 0 ... 10 {
                add(left + column, top)
            }
            for row in 1 ... 4 {
                for column in 1 ... 9 {
                    add(left + column, top + row)
                }
            }
            add(left, top + 2)
            add(left + 10, top + 2)
            for (number, column) in [3, 5, 7].enumerated() {
                let rise = (elapsed * 1.6 + Double(number) * 0.9).truncatingRemainder(dividingBy: 4)
                add(left + column, top - 1 - Int(rise))
            }
        case .routines:
            // One clock hand on bare pixels going round (650 ms a radian), with a centre pixel and no ring.
            let angle = elapsed / 0.65
            add(centreColumn, centreRow)
            for step in 1 ... 6 {
                add(centreColumn + Int((Double(step) * cos(angle)).rounded()),
                    centreRow + Int((Double(step) * sin(angle)).rounded()))
            }
        case .tasks:
            // A check mark drawing itself, a step every 90 ms.
            let path = [(0, 3), (1, 4), (2, 5), (3, 4), (4, 3), (5, 2), (6, 1), (7, 0)]
            for (column, row) in path.prefix(min(path.count, Int(elapsed / 0.09) + 1)) {
                add(centreColumn - 4 + column, centreRow - 3 + row)
            }
        case .notes:
            // Three lines being written, with a cursor blinking on the last.
            let lengths = [16, 12, 9]
            for (line, length) in lengths.enumerated() {
                let row = centreRow - 4 + line * 4
                for index in 0 ..< length where elapsed >= Double(line) * 1.0 + Double(index) * 0.05 {
                    add(centreColumn - 8 + index, row)
                }
            }
            if Int(elapsed / 0.4) % 2 == 0 {
                add(centreColumn - 8 + lengths[2], centreRow + 4 - 1)
                add(centreColumn - 8 + lengths[2], centreRow + 4)
            }
        case .lists:
            // Three rows whose lines tick to done one after another (the box fills, the line goes on).
            for line in 0 ..< 3 {
                let row = centreRow - 4 + line * 4
                let done = elapsed >= 0.6 + Double(line) * 0.7
                for column in 0 ... 1 {
                    for dy in 0 ... 1 where done || (column + dy) % 2 == 0 {
                        add(
                            centreColumn - 9 + column,
                            row + dy
                        )
                    }
                }
                for column in 0 ..< 14 {
                    add(centreColumn - 5 + column, row)
                }
            }
        case .money:
            // Three filled pixel discs, each filling from the bottom to a different level; nothing else.
            for (disc, _) in [0.35, 0.7, 0.5].enumerated() {
                let centre = centreColumn + (disc - 1) * 9
                for column in centre - 4 ... centre + 4 {
                    for row in centreRow - 4 ... centreRow + 4 {
                        let distance = hypot(Double(column - centre), Double(row - centreRow))
                        guard distance <= 3.4 else { continue }
                        add(column, row)
                    }
                }
            }
        }
        return tiles
    }

    /// Money's discs: how full each is at `elapsed` (0 to 1), from the bottom.
    static func poolFill(disc: Int, elapsed: TimeInterval) -> Double {
        let level = [0.35, 0.7, 0.5][min(max(disc, 0), 2)]
        return min(level, level * elapsed / 1.2)
    }

    static func glanceLight(
        _ app: HomeApp,
        cols: Int,
        rows: Int,
        start: TimeInterval,
        ground: MosaicTriple,
        context: MosaicMoodContext,
        still: Bool
    ) -> MosaicMoodField.Overlay {
        let accent = glanceAccent(app, context)
        let ink = context.ink
        let centreRow = rows / 2, centreColumn = cols / 2
        let pale = MosaicColour.mix(accent, ground, 0.7)
        return { column, row, time, colour in
            let elapsed = still ? 99 : time - start
            let lit = glanceTiles(app, cols: cols, rows: rows, elapsed: still ? stillGlance(app) : elapsed)
            guard lit.contains(column * rows + row) else { return colour }
            switch app {
            case .tasks: return ink
            case .money:
                // Which disc this tile is in, and whether the fill has reached its row from the bottom.
                let disc = min(max(Int(floor(Double(column - centreColumn + 13) / 9 + 0.5 / 9)), 0), 2)
                let fill = poolFill(disc: disc, elapsed: elapsed)
                let bottom = centreRow + 4
                let height = 8.0
                return Double(bottom - row) <= fill * height + 0.5 ? accent : pale
            default: return accent
            }
        }
    }

    /// Where a glance rests when it is shown still (Reduce Motion): the sign complete, no lift, steam or turning.
    static func stillGlance(_ app: HomeApp) -> TimeInterval {
        switch app {
        case .training, .kitchen, .routines: 0
        case .tasks, .notes, .lists, .money: 99
        }
    }
}

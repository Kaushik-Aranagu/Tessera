import SwiftUI
import TesseraCore

// Sheet 210: the Training room's lintel. The Home mosaic comes through the doorway and settles as a full-width pixel
// strip, 176 pt tall: twelve weeks of the lift's best as a pixel ridge (a smooth-stepped landscape, never bars or a
// chart). The ridge's top row is the Training accent in full; below it the fill starts 42% toward the page and fades
// down in whole-tile steps; a few pale tiles float above. The bottom 9 rows blend into the page in 1/16 Bayer steps.
// On arrival the best week's column glints once toward ink (700 ms). Picking another lift re-forms the ridge column by
// column from the left, tiles shrinking and regrowing as they flip (9 ms between columns, 260 ms a flip). No axes, no
// gridlines, no labels. Reduce Motion: the ridge swaps plainly.

enum LintelRidge {
    static let height: CGFloat = 176
    static let step: CGFloat = 4
    static let tile: CGFloat = 3.3
    static let rows = Int(height / step)
    static let edgeRows = 9
    static let columnDelay = 0.009
    static let flipSeconds = 0.26
    static let glintSeconds = 0.7
    /// The fill starts this far toward the page.
    static let fillStart = 0.42

    /// The week values with the gaps filled from their neighbours (a week with no set holds the last known level).
    static func filled(_ bests: [Double?]) -> [Double] {
        guard let first = bests.compactMap(\.self).first else { return Array(repeating: 0, count: bests.count) }
        var result: [Double] = []
        var last = first
        for value in bests {
            if let value {
                last = value
            }
            result.append(last)
        }
        return result
    }

    /// The top row of the ridge in each of `columns` columns: the twelve weeks smooth-stepped across the width, the
    /// highest week highest. With no history the ridge is a level line.
    static func tops(_ bests: [Double?], columns: Int) -> [Int] {
        guard columns > 0 else { return [] }
        let values = filled(bests)
        guard values.count > 1, let low = values.min(), let high = values.max() else {
            return Array(repeating: rows * 6 / 10, count: columns)
        }
        let span = high - low
        return (0 ..< columns).map { column in
            let position = Double(column) / Double(max(columns - 1, 1)) * Double(values.count - 1)
            let first = min(Int(position), values.count - 2)
            let local = position - Double(first)
            let eased = local * local * (3 - 2 * local)
            let value = values[first] * (1 - eased) + values[first + 1] * eased
            let fraction = span > 0 ? 0.25 + 0.55 * (value - low) / span : 0.45
            return min(max(rows - Int((fraction * Double(rows)).rounded()), 2), rows - 3)
        }
    }

    /// The columns of one week (where its glint falls).
    static func weekColumns(_ index: Int, columns: Int, weeks: Int = WeeklyBests.weeks) -> Range<Int> {
        let centre = Double(index) / Double(max(weeks - 1, 1)) * Double(max(columns - 1, 0))
        let half = Double(columns) / Double(weeks) / 2
        let low = max(Int((centre - half).rounded()), 0), high = min(Int((centre + half).rounded()), columns)
        return low ..< max(high, low + 1)
    }

    /// How far toward the page a ridge tile is: whole 1/12 steps from the top row's none, below the fill's start.
    static func towardPage(row: Int, top: Int) -> Double {
        guard row > top else { return 0 }
        let depth = Double(row - top) / Double(max(rows - top, 1))
        return ((fillStart + (1 - fillStart) * 0.55 * depth) * 12).rounded() / 12
    }

    /// Whether a bottom-edge tile is drawn: its rows from the bottom set the keep level, tested against a 4 x 4 Bayer.
    static func keepsEdgeTile(column: Int, row: Int) -> Bool {
        let fromBottom = rows - 1 - row
        guard fromBottom < edgeRows else { return true }
        let level = Double(fromBottom + 1) / Double(edgeRows + 1)
        let bayer = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
        // The lower the row, the fewer tiles stay.
        return level * 16 > Double(bayer[row & 3][column & 3]) + 0.5
    }

    /// A tile's hash for the pale tiles floating above the ridge.
    static func floats(column: Int, row: Int) -> Bool {
        MosaicSceneArt.hash(column, row, 77) < 0.012
    }

    /// A column's flip at `time` (seconds after the re-form began): its scale (1 to 0 to 1) and whether it already
    /// shows
    /// the new ridge (past its middle).
    static func flip(column: Int, time: Double) -> (scale: Double, isNew: Bool) {
        let unit = (time - Double(column) * columnDelay) / flipSeconds
        if unit <= 0 {
            return (1, false)
        }
        if unit >= 1 {
            return (1, true)
        }
        return (abs(cos(Double.pi * unit)), unit >= 0.5)
    }

    static func totalSeconds(columns: Int) -> Double {
        Double(columns) * columnDelay + flipSeconds
    }
}

struct TrainingLintel: View {
    /// The twelve weeks' best e1RM, oldest first (nil: no set that week), and the best week.
    let bests: [Double?]
    let bestIndex: Int?
    var accent: Color
    /// Changes when the lift changes: the ridge re-forms.
    var key: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var from: [Int] = []
    @State private var shown: [Int] = []
    @State private var started = Date.distantPast
    @State private var glintAt = Date()
    @State private var lastKey: String?

    var body: some View {
        GeometryReader { geometry in
            let columns = max(Int(geometry.size.width / LintelRidge.step), 1)
            let tops = LintelRidge.tops(bests, columns: columns)
            TimelineView(.animation(paused: reduceMotion && lastKey == key)) { context in
                Canvas { canvas, _ in
                    draw(&canvas, tops: tops, columns: columns, now: context.date)
                }
            }
            .onChange(of: key, initial: true) { _, new in
                if lastKey != nil, !reduceMotion {
                    from = shown.count == columns ? shown : tops
                    started = Date()
                }
                shown = tops
                glintAt = Date()
                    .addingTimeInterval(reduceMotion || lastKey == nil ? 0 : LintelRidge.totalSeconds(columns: columns))
                lastKey = new
            }
        }
        .frame(height: LintelRidge.height)
        .accessibilityHidden(true)
    }

    private func draw(_ canvas: inout GraphicsContext, tops: [Int], columns: Int, now: Date) {
        let ground = Theme.Colors.paper
        let sinceStart = now.timeIntervalSince(started)
        let morphing = !reduceMotion && sinceStart < LintelRidge.totalSeconds(columns: columns)
        let glintTime = now.timeIntervalSince(glintAt)
        let glintColumns = bestIndex.map { LintelRidge.weekColumns($0, columns: columns) }
        let glint = !reduceMotion && glintTime >= 0 && glintTime < LintelRidge.glintSeconds
            ? sin(Double.pi * glintTime / LintelRidge.glintSeconds) * 0.8 : 0
        for column in 0 ..< min(columns, tops.count) {
            var top = tops[column]
            var scale = 1.0
            if morphing, from.count == columns {
                let flip = LintelRidge.flip(column: column, time: sinceStart)
                top = flip.isNew ? tops[column] : from[column]
                scale = flip.scale
            }
            for row in 0 ..< LintelRidge.rows {
                guard LintelRidge.keepsEdgeTile(column: column, row: row) else { continue }
                var colour: Color
                if row >= top {
                    colour = accent.mix(with: ground, by: LintelRidge.towardPage(row: row, top: top))
                    if let glintColumns, glintColumns.contains(column), glint > 0 {
                        colour = colour.mix(with: Theme.Colors.ink, by: glint)
                    }
                } else if row >= top - 6, LintelRidge.floats(column: column, row: row) {
                    colour = accent.mix(with: ground, by: 0.82)
                } else {
                    continue
                }
                let side = LintelRidge.tile * CGFloat(scale)
                let cell = CGRect(x: CGFloat(column) * LintelRidge.step, y: CGFloat(row) * LintelRidge.step,
                                  width: LintelRidge.step, height: LintelRidge.step)
                canvas.fill(Path(CGRect(x: cell.midX - LintelRidge.tile / 2, y: cell.midY - side / 2,
                                        width: LintelRidge.tile, height: side)), with: .color(colour))
            }
        }
    }
}

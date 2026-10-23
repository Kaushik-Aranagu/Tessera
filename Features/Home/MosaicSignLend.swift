import CoreGraphics
import Foundation

// Sheet 213: the mosaic lends its pixels to the sign. When a thing arrives, one fully shown mosaic tile flies out for
// each sign tile (7 ms apart, 560 ms on an eased arc, 26 pt lift, swelling to 1.5x, its colour mixing from the
// mosaic's to the sign's). Each lent tile becomes a gap (88% toward the page) that refills over about 1.1 s, starting
// 450 ms later. The sign draws for real once every tile has landed. On the next swipe the old sign never moves: its
// tiles collapse where they stand, edges inward, each shrinking to nothing with a 4 pt sink over 0.3 s, and 140 ms
// later the mosaic feeds in the new sign. Reduce Motion: no flights, the sign is simply there.

/// One tile of a sign on the screen grid, and the mosaic tile it was lent by.
struct MosaicSignTile: Equatable {
    let cell: ThingSignCell
    let column: Int
    let row: Int
    let sourceColumn: Int
    let sourceRow: Int
}

struct MosaicSignLend: Equatable {
    static let stagger: TimeInterval = 0.007
    static let flightSeconds: TimeInterval = 0.56
    static let lift: CGFloat = 26
    static let swell: CGFloat = 1.5
    static let gapAmount = 0.88
    static let gapDelay: TimeInterval = 0.45
    static let gapRefill: TimeInterval = 1.1
    static let collapseSeconds: TimeInterval = 0.3
    static let collapseSink: CGFloat = 4
    static let feedDelay: TimeInterval = 0.14

    let tiles: [MosaicSignTile]
    let start: TimeInterval
    let kind: ThingSignKind
    let share: Double

    /// Launch time of tile `index`.
    func launch(_ index: Int) -> TimeInterval {
        start + Double(index) * Self.stagger
    }

    /// When the last tile has landed and the real sign takes over.
    var landedAt: TimeInterval {
        launch(max(tiles.count - 1, 0)) + Self.flightSeconds
    }

    static func ease(_ value: Double) -> Double {
        let unit = min(max(value, 0), 1)
        return unit * unit * (3 - 2 * unit)
    }

    /// 0 before launch, 1 once landed.
    func progress(_ index: Int, at time: TimeInterval) -> Double {
        Self.ease((time - launch(index)) / Self.flightSeconds)
    }

    /// The arc's extra height (0 at both ends, 26 pt mid-flight) and swell (1 to 1.5 to 1).
    static func arc(_ progress: Double) -> (lift: CGFloat, scale: CGFloat) {
        let bump = sin(Double.pi * progress)
        return (lift * CGFloat(bump), 1 + (swell - 1) * CGFloat(bump))
    }

    /// How far toward the page a lent source tile is: 0.88 from launch, refilling after 450 ms over 1.1 s.
    func gap(sourceIndex _: Int, tile index: Int, at time: TimeInterval) -> Double {
        let launched = launch(index)
        guard time >= launched else { return 0 }
        let refill = Self.ease((time - launched - Self.gapDelay) / Self.gapRefill)
        return Self.gapAmount * (1 - refill)
    }

    /// Whether any gap is still refilling.
    func isRefilling(at time: TimeInterval) -> Bool {
        time < launch(max(tiles.count - 1, 0)) + Self.gapDelay + Self.gapRefill
    }

    /// For each cell of a sign (screen tiles), the nearest free mosaic tiles, nearest first, one each, deterministic.
    static func lend(cells: [ThingSignCell], originColumn: Int, originRow: Int,
                     core: (left: Int, top: Int, width: Int, height: Int)) -> [MosaicSignTile]
    {
        guard core.width > 0, core.height > 0 else { return [] }
        let centre = (x: Double(originColumn) + Double(ThingSignArt.side) / 2,
                      y: Double(originRow) + Double(ThingSignArt.side) / 2)
        var candidates: [(column: Int, row: Int, distance: Double)] = []
        for column in core.left ..< core.left + core.width {
            for row in core.top ..< core.top + core.height {
                candidates.append((column, row, hypot(Double(column) - centre.x, Double(row) - centre.y)))
            }
        }
        candidates.sort { ($0.distance, $0.column, $0.row) < ($1.distance, $1.column, $1.row) }
        // The launch order is the sign's own, nearest the mosaic first, so the sign builds outward from it.
        let ordered = cells.sorted {
            let first = hypot(Double(originColumn + $0.column) - centre.x, Double(originRow + $0.row) - centre.y)
            let second = hypot(Double(originColumn + $1.column) - centre.x, Double(originRow + $1.row) - centre.y)
            return (first, $0.row, $0.column) < (second, $1.row, $1.column)
        }
        return ordered.enumerated().compactMap { index, cell in
            guard index < candidates.count else { return nil }
            let source = candidates[index]
            return MosaicSignTile(cell: cell, column: originColumn + cell.column, row: originRow + cell.row,
                                  sourceColumn: source.column, sourceRow: source.row)
        }
    }

    // MARK: Collapse

    /// How an old sign's tile has gone: its scale 1...0 and its sink, `delay` after the collapse began, edges first.
    static func collapse(cell: ThingSignCell, elapsed: TimeInterval) -> (scale: CGFloat, sink: CGFloat) {
        let depth = min(cell.column, cell.row, ThingSignArt.side - 1 - cell.column, ThingSignArt.side - 1 - cell.row)
        let delay = Double(depth) * 0.012
        let unit = ease((elapsed - delay) / collapseSeconds)
        return (CGFloat(1 - unit), collapseSink * CGFloat(unit))
    }

    /// When a collapse has finished entirely.
    static let collapseTotal: TimeInterval = collapseSeconds + 0.012 * 9
}

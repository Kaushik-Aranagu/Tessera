import CoreGraphics
import Foundation

// Home is the mosaic (Design 202, Revision 2, the skin edge): a grid of 3.2 pt square tiles on a 4 pt step covers the
// screen edge to edge, but only the mosaic's own space is drawn: its core is the living window, its right edge on the
// right margin, and a rim of 12 tiles around it is solved so the window comes out of the page's own skin. This file is
// the
// pure geometry: the grid, the core, the region and the text shield.

struct MosaicTileRect: Equatable {
    var left: Int
    var top: Int
    var width: Int
    var height: Int

    var right: Int {
        left + width - 1
    }

    var bottom: Int {
        top + height - 1
    }

    func contains(column: Int, row: Int) -> Bool {
        column >= left && column <= right && row >= top && row <= bottom
    }
}

struct MosaicScreenGrid: Equatable {
    /// The 4 pt step and the 3.2 pt square tile (corner 0).
    static let step: CGFloat = 4
    static let side: CGFloat = 3.2
    /// The rim's width: the tiles around the window the skin edge is solved over (Revision 2).
    static let reach = MosaicRim.reach
    /// The most tiles the core can ever span (the largest mood window), and the margin the region keeps around it.
    static let maxCore = (columns: 88, rows: 40)
    /// The right margin in tiles (24 pt): a face grows left from here (Home 236 v2.1).
    static let gutterTiles = 6
    static let margin = reach + 2

    let columns: Int
    let rows: Int
    /// The row the core's top sits on (the old block's top).
    let coreTop: Int

    init(size: CGSize, coreTop points: CGFloat) {
        columns = max(Int((size.width / Self.step).rounded(.up)), 1)
        rows = max(Int((size.height / Self.step).rounded(.up)), 1)
        coreTop = max(Int((points / Self.step).rounded()), 0)
    }

    var count: Int {
        columns * rows
    }

    func index(column: Int, row: Int) -> Int {
        column * rows + row
    }

    func contains(column: Int, row: Int) -> Bool {
        column >= 0 && column < columns && row >= 0 && row < rows
    }

    /// The tile's square, centred in its 4 pt cell.
    func rect(column: Int, row: Int) -> CGRect {
        let inset = (Self.step - Self.side) / 2
        return CGRect(x: CGFloat(column) * Self.step + inset, y: CGFloat(row) * Self.step + inset, width: Self.side,
                      height: Self.side)
    }

    func center(column: Int, row: Int) -> CGPoint {
        CGPoint(x: (CGFloat(column) + 0.5) * Self.step, y: (CGFloat(row) + 0.5) * Self.step)
    }

    func tile(at point: CGPoint) -> (column: Int, row: Int) {
        (Int((point.x / Self.step).rounded(.down)), Int((point.y / Self.step).rounded(.down)))
    }

    /// The core's right edge: its last column sits on the page's right margin.
    var rightEdge: Int {
        columns - 1 - Self.gutterTiles
    }

    /// The centre column of the widest face, for a changeover's origin.
    var centreColumn: Int {
        rightEdge - Self.maxCore.columns / 2 + 1
    }

    /// The core for a window of `columns` x `rows`: it grows left from the right margin, its top on the old block's
    /// top.
    func core(columns width: Int, rows height: Int) -> MosaicTileRect {
        MosaicTileRect(left: max(rightEdge - width + 1, 0), top: coreTop, width: width, height: height)
    }

    /// The fixed box of tiles the mosaic can ever touch: the largest core plus the rim and a breath around it. The
    /// engine keeps scene colours only for these tiles and draws only these.
    var region: MosaicTileRect {
        // From the widest core's left edge less the margin to the screen's right edge (the rim runs off the page).
        let left = max(rightEdge - Self.maxCore.columns + 1 - Self.margin, 0)
        let height = Self.maxCore.rows + 2 * Self.margin
        return MosaicTileRect(left: left, top: coreTop - Self.margin, width: columns - left, height: height)
    }

    // MARK: Text shield

    static let shieldCap = 0.22
    static let shieldFeather = 5

    /// The tiles under the sentence, the caption and the Next rows, padded by one tile, mapped to how much of the
    /// mosaic they keep: a fifth under the words, feathering back to all of it over 5 tiles, so the words always read
    /// and the shield has no edge.
    func shield(for rects: [CGRect]) -> [Int: Double] {
        var levels: [Int: Double] = [:]
        let feather = Self.shieldFeather
        for rect in rects where !rect.isEmpty {
            let first = tile(at: CGPoint(x: rect.minX, y: rect.minY))
            let last = tile(at: CGPoint(x: rect.maxX, y: rect.maxY))
            let left = first.column - 1, right = last.column + 1, top = first.row - 1, bottom = last.row + 1
            for column in max(left - feather, 0) ... min(right + feather, columns - 1) {
                for row in max(top - feather, 0) ... min(bottom + feather, rows - 1) {
                    let dx = max(left - column, 0, column - right), dy = max(top - row, 0, row - bottom)
                    let distance = max(dx, dy)
                    guard distance < feather else { continue }
                    let level = Self.shieldCap + (1 - Self.shieldCap) * MosaicRim
                        .smootherstep(Double(distance) / Double(feather))
                    let tile = index(column: column, row: row)
                    levels[tile] = min(levels[tile] ?? 1, level)
                }
            }
        }
        return levels
    }
}

import CoreGraphics
import Foundation

// Home is the mosaic (Design 202): the whole screen, edge to edge and under the safe areas, is a grid of 3.2 pt square
// tiles on a 4 pt step. At rest every tile is the page ground a shade off (the screen's own pixels). The mood's field
// has no frame: its core is the living window, centred at 56% of the width, and its intensity falls away outward
// until, 28 tiles out, nothing is left. This file is the pure geometry: the grid, the core, the intensity, the dither
// and the text shield.

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
    /// Tiles the field reaches beyond the core before nothing is left.
    static let reach = 28
    /// The most tiles the core can ever span (the largest mood window), and the margin the region keeps around it.
    static let maxCore = (columns: 62, rows: 40)
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

    /// The core's centre column: 56% of the width.
    var centreColumn: Int {
        Int((0.56 * Double(columns)).rounded())
    }

    /// The core for a window of `columns` x `rows`: centred at 56% across, its top on the old block's top.
    func core(columns width: Int, rows height: Int) -> MosaicTileRect {
        MosaicTileRect(left: centreColumn - width / 2, top: coreTop, width: width, height: height)
    }

    /// The fixed box of tiles the field can ever touch: the largest core plus the reach and a breath around it. The
    /// engine keeps scene colours only for these tiles and draws only these (and a touch's pops).
    var region: MosaicTileRect {
        let width = Self.maxCore.columns + 2 * Self.margin
        let height = Self.maxCore.rows + 2 * Self.margin
        return MosaicTileRect(left: centreColumn - width / 2, top: coreTop - Self.margin, width: width, height: height)
    }

    // MARK: Intensity

    /// Intensity I of the field at a tile: 0.62 rising to 1.0 over the 7 tiles in from the core's edge; outside,
    /// 0.62 x (1 - d/28)^1.35 where d is the tile distance from the core, and nothing at 28.
    func intensity(column: Int, row: Int, core: MosaicTileRect) -> Double {
        if core.contains(column: column, row: row) {
            let depth = min(column - core.left, core.right - column, row - core.top, core.bottom - row)
            return 0.62 + 0.38 * min(Double(depth) / 7, 1)
        }
        let dx = max(core.left - column, 0, column - core.right)
        let dy = max(core.top - row, 0, row - core.bottom)
        let distance = hypot(Double(dx), Double(dy))
        guard distance < Double(Self.reach) else { return 0 }
        return 0.62 * pow(1 - distance / Double(Self.reach), 1.35)
    }

    /// Outside the core a tile is drawn only when its hash is under I x 1.9: a dither, never an alpha fade or a blur.
    static func shows(intensity: Double, hash: Double, insideCore: Bool) -> Bool {
        insideCore || hash < intensity * 1.9
    }

    /// Scale 0.55 + 0.45 I.
    static func scale(intensity: Double) -> Double {
        0.55 + 0.45 * intensity
    }

    // MARK: Text shield

    /// The tiles under the sentence, the caption and the Next rows, padded by one tile: there the field is capped at
    /// I x 0.22 so the words always read.
    func shield(for rects: [CGRect]) -> Set<Int> {
        var tiles: Set<Int> = []
        for rect in rects where !rect.isEmpty {
            let first = tile(at: CGPoint(x: rect.minX, y: rect.minY))
            let last = tile(at: CGPoint(x: rect.maxX, y: rect.maxY))
            for column in max(first.column - 1, 0) ... min(last.column + 1, columns - 1) {
                for row in max(first.row - 1, 0) ... min(last.row + 1, rows - 1) {
                    tiles.insert(index(column: column, row: row))
                }
            }
        }
        return tiles
    }

    static let shieldCap = 0.22

    /// The screen's own pixels: a shade off the ground, light looks a touch darker (-4) and dark looks a touch lighter
    /// (+5), with ±1.5 of jitter fixed by hash. In unit floats (0 to 1).
    static func screenDelta(index: Int, dark: Bool) -> Double {
        let base = dark ? 5.0 : -4.0
        let jitter = (MosaicColour.unit(index, salt: 101) * 2 - 1) * 1.5
        return (base + jitter) / 255
    }
}

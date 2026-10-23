import Foundation

// The mosaic's edge (Design 202, Revision 3, "rounded, rising from the page"): the window has superellipse corners,
// between a circle and a square, and a rim of 12 tiles around it rises from the page's own colour to the scene's.
// Each rim tile is full size and one solid colour; the climb is in eighths with a Bayer offset, so it goes in whole
// tiles and never in an alpha ramp. Pure, so the shape and the steps are tested without drawing.

enum MosaicRim {
    /// The ramp runs 16 tiles out from the shape's edge and starts 8 tiles inside it (24 tiles in all).
    static let reach = 16
    static let inner = 8
    static let steps = 24.0
    /// A corner's radius is at most 6 tiles, so a 248 x 160 frame never reads as a rounded card.
    static let maxCornerRadius = 6.0

    /// The Bayer 4 x 4 thresholds, (0.5 to 15.5) over 16.
    static let bayer: [[Double]] = [
        [0, 8, 2, 10],
        [12, 4, 14, 6],
        [3, 11, 1, 9],
        [15, 7, 13, 5],
    ].map { $0.map { ($0 + 0.5) / 16 } }

    static func threshold(column: Int, row: Int) -> Double {
        bayer[row & 3][column & 3]
    }

    /// R = min(6, rows/2, cols/2) tiles.
    static func cornerRadius(columns: Int, rows: Int) -> Double {
        min(maxCornerRadius, Double(rows) / 2, Double(columns) / 2)
    }

    /// The signed distance, in tiles, from the window's superellipse-cornered shape, measured at a tile's centre:
    /// negative inside, positive outside. q is the distance past the inner rectangle (the window inset by R on each
    /// axis) and sd = cbrt(qx^3 + qy^3) - R.
    static func signedDistance(column: Int, row: Int, core: MosaicTileRect) -> Double {
        let halfWidth = Double(core.width) / 2, halfHeight = Double(core.height) / 2
        let x = Double(column) + 0.5 - (Double(core.left) + halfWidth)
        let y = Double(row) + 0.5 - (Double(core.top) + halfHeight)
        let radius = cornerRadius(columns: core.width, rows: core.height)
        let qx = max(abs(x) - (halfWidth - radius), 0)
        let qy = max(abs(y) - (halfHeight - radius), 0)
        if qx == 0, qy == 0 {
            // Inside the inner rectangle the formula would stay at -R; the ramp starts 8 tiles in, so it is the depth
            // to the window's straight edge there (which the formula agrees with in the edge bands).
            return -min(halfWidth - abs(x), halfHeight - abs(y))
        }
        return cbrt(qx * qx * qx + qy * qy * qy) - radius
    }

    static func smoothstep(_ value: Double) -> Double {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    static func smootherstep(_ value: Double) -> Double {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * clamped * (clamped * (clamped * 6 - 15) + 10)
    }

    /// A tile's level: smootherstep(clamp((16 - sd) / 24)), quantised to 24ths with a Bayer 4 x 4 offset, floor(l x 24
    /// +
    /// bayer) / 24. 1 means the scene's colour, 0 the page's (and nothing is drawn).
    static func level(signedDistance sd: Double, column: Int, row: Int) -> Double {
        let smooth = smootherstep((Double(reach) - sd) / (Double(reach) + Double(inner)))
        return min(max(floor(smooth * steps + threshold(column: column, row: row)) / steps, 0), 1)
    }

    /// A tile outside the window read mirrored across its edge: i < 0 reads -i-1, i > n-1 reads 2n-1-i, never clamped,
    /// so texture continues instead of streaking. A very narrow window folds again rather than running off.
    static func mirror(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var folded = index
        for _ in 0 ..< 4 {
            if folded < 0 {
                folded = -folded - 1
            } else if folded > count - 1 {
                folded = 2 * count - 1 - folded
            } else {
                break
            }
        }
        return min(max(folded, 0), count - 1)
    }
}

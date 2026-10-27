import SwiftUI

/// The flip between Bridge's mosaic and a room's keystone (sheet 283 v4). The slot is cut into 16 x 8 tiles; each
/// tile of the old keystone turns away by cos(pi/2 * p), darkening toward 28%, then the same tile of the new keystone
/// turns in. Tiles start 0 to 380 ms apart in the room's order, plus up to 40 ms of jitter; the whole flip ends in
/// 0.98 s. Lookout's mosaic blows apart like cloud instead, with a warm glint across the slot.
enum TileFlipTransition {
    static let columns = 16
    static let rows = 8
    /// One half of a tile's turn (away, then in).
    static let turn = 0.28
    static let spread = 0.38
    static let jitter = 0.04
    static var whole: Double {
        spread + jitter + 2 * turn
    }

    static func make(_ flip: KeystoneFlip) -> AnyTransition {
        if flip == .cloud {
            return .asymmetric(
                insertion: .modifier(active: CloudArrive(time: 0), identity: CloudArrive(time: 1))
                    .animation(.linear(duration: whole)),
                removal: .modifier(active: CloudDrift(time: 1), identity: CloudDrift(time: 0))
                    .animation(.timingCurve(0.33, 1, 0.68, 1, duration: 0.7))
            )
        }
        return .asymmetric(
            insertion: .modifier(active: TileFlip(time: 0, flip: flip, entering: true),
                                 identity: TileFlip(time: 1, flip: flip, entering: true))
                .animation(.linear(duration: whole)),
            removal: .modifier(active: TileFlip(time: 1, flip: flip, entering: false),
                               identity: TileFlip(time: 0, flip: flip, entering: false))
                .animation(.linear(duration: whole))
        )
    }

    /// When a tile starts, 0 to 1 across the spread, in the room's order.
    static func order(column: Int, row: Int, flip: KeystoneFlip) -> Double {
        let cols = Double(columns - 1), rowsMax = Double(rows - 1)
        let c = Double(column), r = Double(row)
        switch flip {
        case .rows: return (r * Double(columns) + c) / (Double(columns * rows) - 1)
        case .sweep: return (c + r * 0.4) / (cols + rowsMax * 0.4)
        case .columns: return c / cols
        case .groundUp: return (rowsMax - r) / rowsMax
        case .leftToRight: return (c * Double(rows) + r) / (Double(columns * rows) - 1)
        case .cloud:
            // From the middle out.
            let dx = (c - cols / 2) / (cols / 2), dy = (r - rowsMax / 2) / (rowsMax / 2)
            return min(1, (dx * dx + dy * dy).squareRoot() / 1.42)
        }
    }

    /// A small fixed jitter per tile, 0 to 1.
    static func jitterFor(column: Int, row: Int) -> Double {
        let seed = (column * 73 + row * 151) % 97
        return Double(seed) / 96
    }

    /// How far a tile has turned, 0 to 1, at `time` (0 to 1 of the whole flip).
    static func progress(column: Int, row: Int, flip: KeystoneFlip, time: Double, entering: Bool) -> Double {
        let start = (order(column: column, row: row, flip: flip) * spread
            + jitterFor(column: column, row: row) * jitter) / whole
        let length = turn / whole
        let begin = entering ? start + length : start
        return min(1, max(0, (time - begin) / length))
    }
}

/// One side of the tile flip at `time`: the keystone shows through a mask of tiles at their turned heights, with
/// the darkening laid over the turning tiles.
private struct TileFlip: ViewModifier, Animatable {
    var time: Double
    let flip: KeystoneFlip
    let entering: Bool

    nonisolated var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask {
                Canvas { context, size in
                    forEachTile(size) { rect, open, _ in
                        let height = rect.height * open
                        context.fill(Path(CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width,
                                                 height: height)), with: .color(.black))
                    }
                }
            }
            .overlay {
                Canvas { context, size in
                    forEachTile(size) { rect, open, dark in
                        guard dark > 0.01 else { return }
                        let height = rect.height * open
                        context.fill(Path(CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width,
                                                 height: height)), with: .color(.black.opacity(0.72 * dark)))
                    }
                }
                .allowsHitTesting(false)
            }
    }

    /// Each tile's rect, how open it is (1 flat, 0 edge-on) and how dark (0 to 1).
    private func forEachTile(_ size: CGSize, _ body: (CGRect, Double, Double) -> Void) {
        let width = size.width / CGFloat(TileFlipTransition.columns)
        let height = size.height / CGFloat(TileFlipTransition.rows)
        for row in 0 ..< TileFlipTransition.rows {
            for column in 0 ..< TileFlipTransition.columns {
                let p = TileFlipTransition.progress(column: column, row: row, flip: flip, time: time,
                                                    entering: entering)
                let open = entering ? sin(.pi / 2 * p) : cos(.pi / 2 * p)
                let dark = entering ? (p > 0 ? 1 - p : 0) : p
                body(CGRect(x: CGFloat(column) * width, y: CGFloat(row) * height, width: width + 0.5,
                            height: height + 0.5), open, dark)
            }
        }
    }
}

/// Lookout: the old keystone blows apart like cloud. From the middle out the tiles thin away while the whole drifts
/// with the wind (up to 110 pt right, 22 pt up), grows to 1.35x, turns up to 10°, blurs to 6 pt and fades.
private struct CloudDrift: ViewModifier, Animatable {
    var time: Double

    nonisolated var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask {
                Canvas { context, size in
                    let width = size.width / CGFloat(TileFlipTransition.columns)
                    let height = size.height / CGFloat(TileFlipTransition.rows)
                    for row in 0 ..< TileFlipTransition.rows {
                        for column in 0 ..< TileFlipTransition.columns {
                            let start = TileFlipTransition.order(column: column, row: row, flip: .cloud) * 0.5
                            let p = min(1, max(0, (time - start) / 0.5))
                            let scale = 1 - p
                            let rect = CGRect(x: CGFloat(column) * width, y: CGFloat(row) * height, width: width,
                                              height: height)
                            context.fill(Path(rect.insetBy(dx: rect.width * (1 - scale) / 2,
                                                           dy: rect.height * (1 - scale) / 2)),
                                         with: .color(.black))
                        }
                    }
                }
            }
            .scaleEffect(1 + 0.35 * time)
            .rotationEffect(.degrees(10 * time))
            .offset(x: 110 * time, y: -22 * time)
            .blur(radius: 6 * time)
            .opacity(1 - time)
    }
}

/// Lookout's keystone settles in as the cloud clears, with a soft warm glint (32% at its peak) sweeping across the
/// slot from 120 to 1100 ms of the change.
private struct CloudArrive: ViewModifier, Animatable {
    var time: Double

    nonisolated var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    func body(content: Content) -> some View {
        let seconds = time * TileFlipTransition.whole
        let reveal = min(1, max(0, (seconds - 0.25) / 0.6))
        let glint = min(1, max(0, (seconds - 0.12) / 0.86))
        content
            .opacity(reveal)
            .blur(radius: 4 * (1 - reveal))
            .overlay {
                GeometryReader { proxy in
                    let band = proxy.size.width * 0.5
                    LinearGradient(colors: [.clear, Color(light: 0xF6C98A, dark: 0xF0B070).opacity(0.32), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: band)
                        .offset(x: -band + (proxy.size.width + band) * glint)
                        .opacity(glint > 0 && glint < 1 ? 1 : 0)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

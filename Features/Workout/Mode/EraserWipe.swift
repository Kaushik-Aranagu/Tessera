import SwiftUI

/// The eraser (sheets 338 and 352): a slanted band wipes the board off over 460 ms, ease in-out, with a 66 pt haze at
/// 7%
/// white trailing it that fades in the last fifth. The next board is already written behind, so the wipe reveals it. At
/// the end of a rest it runs left to right; changing lift in the lift phase runs it with the swipe or the tap: a swipe
/// LEFT sweeps right to left (the new lift comes in from the right), a swipe RIGHT left to right. This is the pure
/// geometry; `EraserWipeOverlay` draws it.
enum EraserBand {
    static let duration = 0.46
    /// How far the band leans: its top is this much ahead of its bottom.
    static let slant: CGFloat = 28
    static let hazeWidth: CGFloat = 66
    static let hazeAlpha = 0.07

    enum Direction: Equatable, Sendable {
        case leftToRight
        case rightToLeft

        /// A swipe LEFT (negative `dx`) sweeps the eraser right to left; a swipe RIGHT, left to right.
        static func forSwipe(dx: CGFloat) -> Direction {
            dx < 0 ? .rightToLeft : .leftToRight
        }

        /// Tapping a lift later in the list wipes forward (the left-swipe direction); an earlier one wipes back.
        static func forTap(from current: Int, to target: Int) -> Direction {
            target > current ? .rightToLeft : .leftToRight
        }
    }

    /// Ease in-out (smoothstep) of the linear time 0 to 1.
    static func eased(_ time: Double) -> Double {
        let clamped = min(max(time, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    /// The band's leading edge at the top and the bottom of a board `width` wide, for linear time `time`. Everything
    /// behind the line (to its left going right, to its right going left) is erased. At 0 nothing is erased; at 1 all
    /// of
    /// it is.
    static func edge(time: Double, width: CGFloat,
                     direction: Direction = .leftToRight) -> (top: CGFloat, bottom: CGFloat)
    {
        let bottom = -slant + CGFloat(eased(time)) * (width + slant)
        let line = (top: bottom + slant, bottom: bottom)
        switch direction {
        case .leftToRight: return line
        case .rightToLeft: return (width - line.top, width - line.bottom)
        }
    }

    /// The haze's opacity: 7% white all the way, fading to nothing over the last fifth.
    static func hazeOpacity(time: Double) -> Double {
        let clamped = min(max(time, 0), 1)
        return clamped < 0.8 ? hazeAlpha : hazeAlpha * (1 - clamped) / 0.2
    }

    /// The part of the old board still showing: ahead of the slanted line.
    static func remaining(time: Double, size: CGSize, direction: Direction = .leftToRight) -> Path {
        let line = edge(time: time, width: size.width, direction: .leftToRight)
        var path = Path()
        path.move(to: CGPoint(x: line.top, y: 0))
        path.addLine(to: CGPoint(x: size.width + slant, y: 0))
        path.addLine(to: CGPoint(x: size.width + slant, y: size.height))
        path.addLine(to: CGPoint(x: line.bottom, y: size.height))
        path.closeSubpath()
        guard direction == .rightToLeft else { return path }
        // Mirrored across the board: the same shape, swept the other way.
        return path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: size.width, ty: 0))
    }
}

/// Lays the snapshot of the old board over the live board and wipes it off. The snapshot is a flat image, masked by the
/// slanted line: a hard clip, never a blur or material over a clip edge. The haze is a flat gradient inside the erased
/// area.
struct EraserWipeOverlay: View {
    let snapshot: Image
    var time: Double
    var direction: EraserBand.Direction = .leftToRight

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let line = EraserBand.edge(time: time, width: size.width, direction: direction)
            // The haze lies on the erased side, behind the line as it travels.
            let behind: CGFloat = direction == .leftToRight ? -1 : 1
            ZStack(alignment: .topLeading) {
                snapshot
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .mask {
                        Canvas { context, _ in
                            context.fill(
                                EraserBand.remaining(time: time, size: size, direction: direction),
                                with: .color(.black)
                            )
                        }
                    }
                Canvas { context, _ in
                    var haze = Path()
                    haze.move(to: CGPoint(x: line.top + behind * EraserBand.hazeWidth, y: 0))
                    haze.addLine(to: CGPoint(x: line.top, y: 0))
                    haze.addLine(to: CGPoint(x: line.bottom, y: size.height))
                    haze.addLine(to: CGPoint(x: line.bottom + behind * EraserBand.hazeWidth, y: size.height))
                    haze.closeSubpath()
                    context.fill(haze, with: .linearGradient(
                        Gradient(colors: [.white.opacity(0), .white.opacity(EraserBand.hazeOpacity(time: time))]),
                        startPoint: CGPoint(x: line.top + behind * EraserBand.hazeWidth, y: 0),
                        endPoint: CGPoint(x: line.top, y: 0)
                    ))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// An `EraserWipeOverlay` whose time SwiftUI animates, so the band moves every frame.
struct AnimatedEraserWipe: View, @preconcurrency Animatable {
    let snapshot: Image
    var time: Double
    var direction: EraserBand.Direction = .leftToRight

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    var body: some View {
        EraserWipeOverlay(snapshot: snapshot, time: time, direction: direction)
    }
}

import SwiftUI

/// The eraser at the end of a rest (sheet 338): a slanted band wipes the rest board off from left to right over 460 ms,
/// ease in-out, with a 66 pt haze at 7% white trailing it that fades in the last fifth. The next lift is already
/// written
/// behind, so the wipe reveals it. This is the pure geometry; `EraserWipeOverlay` draws it.
enum EraserBand {
    static let duration = 0.46
    /// How far the band leans: its top is this much ahead of its bottom.
    static let slant: CGFloat = 28
    static let hazeWidth: CGFloat = 66
    static let hazeAlpha = 0.07

    /// Ease in-out (smoothstep) of the linear time 0 to 1.
    static func eased(_ time: Double) -> Double {
        let clamped = min(max(time, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    /// The band's leading edge at the top and the bottom of a board `width` wide, for linear time `time`. Everything
    /// left of the line is erased. At 0 nothing is erased (the whole slant is off the left edge); at 1 all of it is.
    static func edge(time: Double, width: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        let bottom = -slant + CGFloat(eased(time)) * (width + slant)
        return (bottom + slant, bottom)
    }

    /// The haze's opacity: 7% white all the way, fading to nothing over the last fifth.
    static func hazeOpacity(time: Double) -> Double {
        let clamped = min(max(time, 0), 1)
        return clamped < 0.8 ? hazeAlpha : hazeAlpha * (1 - clamped) / 0.2
    }

    /// The part of the old board still showing: right of the slanted line.
    static func remaining(time: Double, size: CGSize) -> Path {
        let line = edge(time: time, width: size.width)
        var path = Path()
        path.move(to: CGPoint(x: line.top, y: 0))
        path.addLine(to: CGPoint(x: size.width + slant, y: 0))
        path.addLine(to: CGPoint(x: size.width + slant, y: size.height))
        path.addLine(to: CGPoint(x: line.bottom, y: size.height))
        path.closeSubpath()
        return path
    }
}

/// Lays the snapshot of the rest board over the live board and wipes it off. The snapshot is a flat image, masked by
/// the slanted line: a hard clip, never a blur or material over a clip edge. The haze is a flat gradient inside the
/// erased area.
struct EraserWipeOverlay: View {
    let snapshot: Image
    var time: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let line = EraserBand.edge(time: time, width: size.width)
            ZStack(alignment: .topLeading) {
                snapshot
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .mask { Canvas { context, _ in context.fill(
                        EraserBand.remaining(time: time, size: size),
                        with: .color(.black)
                    ) } }
                // The haze trails the line on the erased side.
                Canvas { context, _ in
                    var haze = Path()
                    haze.move(to: CGPoint(x: line.top - EraserBand.hazeWidth, y: 0))
                    haze.addLine(to: CGPoint(x: line.top, y: 0))
                    haze.addLine(to: CGPoint(x: line.bottom, y: size.height))
                    haze.addLine(to: CGPoint(x: line.bottom - EraserBand.hazeWidth, y: size.height))
                    haze.closeSubpath()
                    context.fill(haze, with: .linearGradient(
                        Gradient(colors: [.white.opacity(0), .white.opacity(EraserBand.hazeOpacity(time: time))]),
                        startPoint: CGPoint(x: line.top - EraserBand.hazeWidth, y: 0),
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

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    var body: some View {
        EraserWipeOverlay(snapshot: snapshot, time: time)
    }
}

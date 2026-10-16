import SwiftUI

/// Tess's living mark: three dabs of wet paint (vermilion, cobalt, cadmium) and three satellites, mixing by
/// multiply on light grounds and screen on dark. How they move says what Tess is doing.
///
/// Each mode is one row of `SoulParameters.table`; a change of mode blends the old row into the new over 0.4 s
/// (`SoulBlend`). One `Canvas` draws the frame and `.drawingGroup()` composites it on the GPU; slow modes (idle,
/// resting) tick at 30 fps, the rest at 60. Reduce Motion: static dabs, the mode shown by size,
/// grade and opacity only.
struct TessSoul: View {
    enum Mode: Equatable {
        /// A calm "needs you": one dab lifts at a time. Drawn small.
        case idle
        /// The bloom.
        case listening
        /// The per-dab pulse. Also covers Tess doing things.
        case thinking
        /// One-shot (1.8 s): pour, swell, splash, relax. Plays a success haptic.
        case done
        case needsYou
        /// One dab flies to `target` (offset from the soul's centre, in points), spreads into a wash and fades.
        case handOff(target: CGPoint)
        /// Night and focus: desaturated, smaller, very slow.
        case resting

        var isOneShot: Bool {
            SoulParameters.table(self).isOneShot
        }
    }

    var mode: Mode
    /// Loops one-shot modes (for galleries); in the app they play once.
    var loopsOneShots = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.onWorkoutGround) private var onWorkoutGround
    @State private var layers: [SoulLayer] = []
    @State private var doneCount = 0

    var body: some View {
        let slow = SoulParameters.table(mode).isSlow
        let size = canvasSize
        // By the look, not the colour scheme (themes.md addendum); the workout is always its own dark palette.
        let store = ThemeStore.shared
        let palette = onWorkoutGround
            ? SoulPalette.look(store.workoutLook)
            : SoulPalette.look(colorScheme == .dark ? store.pair.night : store.pair.day)
        TimelineView(.animation(minimumInterval: slow ? 1 / 30 : 1 / 60, paused: reduceMotion)) { context in
            let frame = reduceMotion
                ? SoulFrame.sample(mode, time: 0, elapsed: 0, still: true)
                : SoulBlend.frame(layers, at: context.date, loops: loopsOneShots)
                ?? SoulFrame.sample(mode, time: context.date.timeIntervalSinceReferenceDate, elapsed: 0)
            Canvas(rendersAsynchronously: true) { context, canvasSize in
                SoulRenderer.draw(frame, in: &context, size: canvasSize, palette: palette)
            }
            .saturation(frame.look.saturation)
            .contrast(frame.look.contrast)
            .brightness(frame.look.brightness)
            .opacity(frame.look.opacity)
            // Flattened by Metal: without this the Canvas is rasterised by Core Graphics on the CPU every frame.
            .drawingGroup()
        }
        .frame(width: size.width, height: size.height)
        .frame(width: 96, height: 96)
        .onChange(of: mode, initial: true) { _, new in
            layers = SoulBlend.push(new, onto: layers, at: .now)
            if new == .done {
                doneCount += 1
            }
        }
        .sensoryFeedback(.success, trigger: doneCount)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .allowsHitTesting(false)
    }

    /// Room for the done ring at 2.6× and, for a hand-off, the flight to the target.
    private var canvasSize: CGSize {
        if case let .handOff(target) = mode {
            let reach = max(abs(target.x), abs(target.y)) * 2 + 200
            return CGSize(width: max(reach, 240), height: max(reach, 240))
        }
        return CGSize(width: 240, height: 240)
    }

    private var accessibilityText: String {
        switch mode {
        case .idle: "Tess"
        case .listening: "Tess is listening"
        case .thinking: "Tess is thinking"
        case .done: "Tess is done"
        case .needsYou: "Tess needs you"
        case .handOff: "Tess made a change"
        case .resting: "Tess is resting"
        }
    }

    /// Phase (0…1) of a looping animation with a CSS-style (negative) delay.
    static func phase(_ time: Double, period: Double, delay: Double = 0) -> Double {
        let value = (time - delay).truncatingRemainder(dividingBy: period) / period
        return value < 0 ? value + 1 : value
    }
}

// MARK: - Paint

/// The soul's colours for a ground. On dark grounds the paint glows (screen) instead of staining (multiply).
struct SoulPalette {
    var blend: GraphicsContext.BlendMode
    /// A soft radial wash per paint (vermilion, cobalt, cadmium): alpha .8 at the centre, .6 at 40%, 0 at the edge.
    var washes: [Gradient]
    var halo: Gradient
    var ring: Gradient

    /// The look's live, tess and now; halo from live and context, the ring in context at 60%. Multiply on light
    /// looks, screen (and a fuller halo) on dark ones.
    static func look(_ look: Look) -> SoulPalette {
        let glow = look.isDark
        // Only on Porcelain and Celadon's pale grounds: three multiplied washes at 0.8 burn to a dark hole, so
        // lighter stops and a fainter halo leave the warm mixing he knows from Plein. Every other look is unchanged.
        let pale = look.field == .pigmentBloom || look.field == .glaze
        return SoulPalette(
            blend: glow ? .screen : .multiply,
            washes: [look.live, look.tess, look.now].map { pale ? wash($0, core: 0.58, mid: 0.42) : wash($0) },
            halo: halo(Color(hex: look.live).opacity(glow ? 0.22 : pale ? 0.08 : 0.16),
                       Color(hex: look.context).opacity(glow ? 0.14 : pale ? 0.05 : 0.10)),
            ring: ring(Color(hex: look.context).opacity(0.6))
        )
    }

    private static func wash(_ hex: UInt32, core: Double = 0.8, mid: Double = 0.6) -> Gradient {
        let color = Color(hex: hex)
        return Gradient(stops: [
            .init(color: color.opacity(core), location: 0),
            .init(color: color.opacity(mid), location: 0.4),
            .init(color: color.opacity(0), location: 1),
        ])
    }

    private static func halo(_ inner: Color, _ outer: Color) -> Gradient {
        Gradient(stops: [
            .init(color: inner, location: 0),
            .init(color: outer, location: 0.55),
            .init(color: outer.opacity(0), location: 1),
        ])
    }

    /// A soft band peaking at 72% of the radius (CSS `.ring`).
    private static func ring(_ color: Color) -> Gradient {
        Gradient(stops: [
            .init(color: color.opacity(0), location: 0.52),
            .init(color: color.opacity(0.5), location: 0.72),
            .init(color: color.opacity(0), location: 1),
        ])
    }
}

/// Draws a `SoulFrame`: halo and ring in normal blend, then the dabs mixing by multiply or screen, each with its
/// own live blur. The group grade (saturation, contrast) is applied by the view around the canvas.
enum SoulRenderer {
    static func draw(_ frame: SoulFrame, in context: inout GraphicsContext, size: CGSize, palette: SoulPalette) {
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.scaleBy(x: frame.look.scale, y: frame.look.scale)

        if frame.halo.opacity > 0.01 {
            var halo = context
            halo.opacity = frame.halo.opacity
            halo.scaleBy(x: frame.halo.scaleX, y: frame.halo.scaleX * 70 / 75)
            halo.fill(Path(ellipseIn: CGRect(x: -75, y: -75, width: 150, height: 150)),
                      with: .radialGradient(palette.halo, center: .zero, startRadius: 0, endRadius: 75))
        }
        if frame.ring.opacity > 0.01 {
            let radius = SoulDab.ringDiameter / 2 * frame.ring.scaleX
            var ring = context
            ring.opacity = frame.ring.opacity
            ring.fill(Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)),
                      with: .radialGradient(palette.ring, center: .zero, startRadius: 0, endRadius: radius))
        }

        context.blendMode = palette.blend
        for (index, pose) in frame.dabs.enumerated() {
            let opacity = index < 3 ? 1 : frame.look.satellites
            dab(pose, SoulDab.all[index], opacity: opacity, in: &context, palette: palette)
        }
        dab(frame.drip, SoulDab.drip, opacity: 1, in: &context, palette: palette)
    }

    private static func dab(_ pose: SoulPose, _ dab: SoulDab, opacity: CGFloat, in context: inout GraphicsContext,
                            palette: SoulPalette)
    {
        let alpha = pose.opacity * opacity
        guard alpha > 0.01, pose.scaleX > 0.01, pose.scaleY > 0.01 else { return }
        context.drawLayer { layer in
            layer.opacity = alpha
            layer.addFilter(.blur(radius: pose.blur))
            layer.translateBy(x: pose.x, y: pose.y)
            layer.scaleBy(x: dab.size.width / 2 * pose.scaleX, y: dab.size.height / 2 * pose.scaleY)
            layer.fill(shapes[dab.paint], with: .radialGradient(
                palette.washes[dab.paint], center: .zero, startRadius: 0, endRadius: 1
            ))
        }
    }

    /// Each paint's irregular corners (CSS border-radius, horizontal / vertical, TL TR BR BL), in a 2×2 box.
    static let shapes: [Path] = [
        shape(horizontal: [52, 48, 60, 40], vertical: [55, 45, 55, 45]),
        shape(horizontal: [45, 55, 40, 60], vertical: [50, 60, 40, 50]),
        shape(horizontal: [60, 40, 55, 45], vertical: [45, 55, 45, 55]),
    ]

    static func shape(horizontal: [CGFloat], vertical: [CGFloat]) -> Path {
        // Radii as fractions of the 2-unit box; each corner is a quarter ellipse.
        let radiiX = horizontal.map { $0 / 50 }, radiiY = vertical.map { $0 / 50 }
        let kappa: CGFloat = 0.5523
        var path = Path()
        path.move(to: CGPoint(x: -1 + radiiX[0], y: -1))
        path.addLine(to: CGPoint(x: 1 - radiiX[1], y: -1))
        path.addCurve(to: CGPoint(x: 1, y: -1 + radiiY[1]),
                      control1: CGPoint(x: 1 - radiiX[1] * (1 - kappa), y: -1),
                      control2: CGPoint(x: 1, y: -1 + radiiY[1] * (1 - kappa)))
        path.addLine(to: CGPoint(x: 1, y: 1 - radiiY[2]))
        path.addCurve(to: CGPoint(x: 1 - radiiX[2], y: 1),
                      control1: CGPoint(x: 1, y: 1 - radiiY[2] * (1 - kappa)),
                      control2: CGPoint(x: 1 - radiiX[2] * (1 - kappa), y: 1))
        path.addLine(to: CGPoint(x: -1 + radiiX[3], y: 1))
        path.addCurve(to: CGPoint(x: -1, y: 1 - radiiY[3]),
                      control1: CGPoint(x: -1 + radiiX[3] * (1 - kappa), y: 1),
                      control2: CGPoint(x: -1, y: 1 - radiiY[3] * (1 - kappa)))
        path.addLine(to: CGPoint(x: -1, y: -1 + radiiY[0]))
        path.addCurve(to: CGPoint(x: -1 + radiiX[0], y: -1),
                      control1: CGPoint(x: -1, y: -1 + radiiY[0] * (1 - kappa)),
                      control2: CGPoint(x: -1 + radiiX[0] * (1 - kappa), y: -1))
        path.closeSubpath()
        return path
    }
}

// MARK: - Travel

/// Moves the soul to a point with different easings on x and y, so the path arcs (~0.76 s).
struct SoulTravel: ViewModifier {
    let position: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(x: position.x)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : .timingCurve(0.55, 0, 0.15, 1, duration: 0.76),
                value: position.x
            )
            .offset(y: position.y)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : .timingCurve(0.3, 0, 0.25, 1, duration: 0.76),
                value: position.y
            )
    }
}

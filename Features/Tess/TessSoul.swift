import SwiftUI

/// Tess's living mark: three paint dabs (vermilion, cobalt, cadmium), multiply-blended with a light blur.
/// How they move says what Tess is doing. Independent of the app's theme concept.
///
/// Rendered as one `Canvas` driven by a `TimelineView`; slow modes (idle, resting) tick at 30 fps,
/// active modes at the display rate. Reduce Motion: static dabs, the mode shown by colour and opacity only.
struct TessSoul: View {
    enum Mode: Equatable {
        case idle
        case listening
        case thinking
        case working
        /// One-shot (~1.6 s): merge, pop, splash, relax. Plays a success haptic.
        case done
        case needsYou
        /// One dab flies to `target` (offset from the soul's centre, in points), smears into a wash and fades.
        case handOff(target: CGPoint)
        /// Night and focus: desaturated, smaller, very slow.
        case resting

        var isOneShot: Bool {
            switch self {
            case .done, .handOff: true
            default: false
            }
        }
    }

    var mode: Mode
    /// Loops one-shot modes (for galleries); in the app they play once.
    var loopsOneShots = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var modeStart = Date()
    @State private var doneCount = 0

    var body: some View {
        let slow = mode == .idle || mode == .resting
        TimelineView(.animation(minimumInterval: slow ? 1 / 30 : nil, paused: reduceMotion)) { context in
            let elapsed = context.date.timeIntervalSince(modeStart)
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                draw(in: &canvas, size: size, time: time, elapsed: elapsed)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .frame(width: 96, height: 96)
        .saturation(mode == .resting ? 0.3 : 1)
        .brightness(mode == .resting ? 0.08 : 0)
        .opacity(mode == .resting ? 0.75 : 1)
        .onChange(of: mode, initial: true) { _, new in
            modeStart = Date()
            if new == .done {
                doneCount += 1
            }
        }
        .sensoryFeedback(.success, trigger: doneCount)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .allowsHitTesting(false)
    }

    // MARK: Drawing

    private var canvasSize: CGSize {
        if case let .handOff(target) = mode {
            let reach = max(abs(target.x), abs(target.y)) * 2 + 200
            return CGSize(width: reach, height: reach)
        }
        return CGSize(width: 200, height: 200)
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize, time: Double, elapsed: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        canvas.translateBy(x: center.x, y: center.y)
        let poses = Self.poses(for: mode, time: time, elapsed: elapsed, loop: loopsOneShots, still: reduceMotion)

        if let rotation = poses.rotation {
            canvas.rotate(by: .radians(rotation))
        }

        if let ring = poses.ring, ring.opacity > 0.001 {
            let diameter = 90 * ring.scale
            let rect = CGRect(x: -diameter / 2, y: -diameter / 2, width: diameter, height: diameter)
            canvas.stroke(Path(ellipseIn: rect), with: .color(Self.ringColor.opacity(ring.opacity)), lineWidth: 3)
        }

        // Layers composite onto the canvas with the canvas's blend mode, so overlaps mix like paint.
        canvas.blendMode = .multiply
        for (index, dab) in Self.dabs.enumerated() {
            let pose = poses.dabs[index]
            guard pose.opacity > 0.001 else { continue }
            canvas.drawLayer { layer in
                layer.opacity = pose.opacity
                layer.addFilter(.blur(radius: pose.blur))
                layer.translateBy(x: pose.x, y: pose.y)
                layer.scaleBy(x: pose.sx, y: pose.sy)
                layer.fill(dab.path, with: .color(dab.color))
            }
        }
        if let drip = poses.drip, drip.opacity > 0.001 {
            canvas.drawLayer { layer in
                layer.opacity = drip.opacity
                layer.addFilter(.blur(radius: 1.5))
                layer.translateBy(x: drip.x, y: drip.y)
                layer.scaleBy(x: drip.sx * 22 / 64, y: drip.sy * 20 / 58)
                layer.fill(Self.dabs[0].path, with: .color(Self.dabs[0].color))
            }
        }
    }

    private var accessibilityText: String {
        switch mode {
        case .idle: "Tess"
        case .listening: "Tess is listening"
        case .thinking: "Tess is thinking"
        case .working: "Tess is working"
        case .done: "Tess is done"
        case .needsYou: "Tess needs you"
        case .handOff: "Tess made a change"
        case .resting: "Tess is resting"
        }
    }
}

// MARK: - Dabs

extension TessSoul {
    struct Dab {
        let color: Color
        /// Resting offset from the soul's centre.
        let base: CGPoint
        /// Where it blooms to while thinking.
        let bloom: CGPoint
        let path: Path
    }

    static let ringColor = Color(hex: 0x7A4A3A)

    /// Vermilion, cobalt, cadmium. Each has slightly different irregular corners (CSS-style elliptical radii, in %).
    static let dabs: [Dab] = [
        Dab(color: Color(hex: 0xC8452F), base: CGPoint(x: -13, y: -7), bloom: CGPoint(x: 18, y: -10),
            path: dabPath(horizontal: [52, 48, 60, 40], vertical: [55, 45, 55, 45])),
        Dab(color: Color(hex: 0x2E6DA4), base: CGPoint(x: 13, y: -7), bloom: CGPoint(x: -16, y: -12),
            path: dabPath(horizontal: [45, 55, 40, 60], vertical: [50, 60, 40, 50])),
        Dab(color: Color(hex: 0xE0B341), base: CGPoint(x: 0, y: 12), bloom: CGPoint(x: 0, y: 18),
            path: dabPath(horizontal: [60, 40, 55, 45], vertical: [45, 55, 45, 55])),
    ]

    /// A 64×58 blob centred on the origin. Radii per corner (top-left, top-right, bottom-right, bottom-left) in %.
    static func dabPath(horizontal h: [CGFloat], vertical v: [CGFloat], width: CGFloat = 64,
                        height: CGFloat = 58) -> Path
    {
        let rx = h.map { $0 / 100 * width }, ry = v.map { $0 / 100 * height }
        let k: CGFloat = 0.5523
        var path = Path()
        let ox = -width / 2, oy = -height / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: ox + x, y: oy + y)
        }
        path.move(to: p(rx[0], 0))
        path.addLine(to: p(width - rx[1], 0))
        path.addCurve(
            to: p(width, ry[1]),
            control1: p(width - rx[1] + rx[1] * k, 0),
            control2: p(width, ry[1] - ry[1] * k)
        )
        path.addLine(to: p(width, height - ry[2]))
        path.addCurve(to: p(width - rx[2], height), control1: p(width, height - ry[2] + ry[2] * k),
                      control2: p(width - rx[2] + rx[2] * k, height))
        path.addLine(to: p(rx[3], height))
        path.addCurve(
            to: p(0, height - ry[3]),
            control1: p(rx[3] - rx[3] * k, height),
            control2: p(0, height - ry[3] + ry[3] * k)
        )
        path.addLine(to: p(0, ry[0]))
        path.addCurve(to: p(rx[0], 0), control1: p(0, ry[0] - ry[0] * k), control2: p(rx[0] - rx[0] * k, 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Choreography

extension TessSoul {
    struct Pose {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var sx: CGFloat = 0.8
        var sy: CGFloat = 0.8
        var blur: CGFloat = 1.5
        var opacity: CGFloat = 1
    }

    struct Ring {
        var scale: CGFloat
        var opacity: CGFloat
    }

    struct Poses {
        var dabs: [Pose]
        var rotation: Double?
        var ring: Ring?
        var drip: Pose?
    }

    /// A keyframe: time (0…1) and a pose. The curve eases each segment, like CSS `animation-timing-function`.
    struct Frame {
        let t: Double
        let pose: Pose
    }

    static func sample(_ frames: [Frame], at progress: Double, curve: UnitCurve = .easeInOut) -> Pose {
        let p = min(max(progress, 0), 1)
        guard let next = frames.firstIndex(where: { $0.t >= p }) else { return frames.last?.pose ?? Pose() }
        guard next > 0 else { return frames[0].pose }
        let a = frames[next - 1], b = frames[next]
        let local = b.t == a.t ? 1 : (p - a.t) / (b.t - a.t)
        let e = CGFloat(curve.value(at: local))
        func mix(_ u: CGFloat, _ v: CGFloat) -> CGFloat {
            u + (v - u) * e
        }
        return Pose(x: mix(a.pose.x, b.pose.x), y: mix(a.pose.y, b.pose.y), sx: mix(a.pose.sx, b.pose.sx),
                    sy: mix(a.pose.sy, b.pose.sy), blur: mix(a.pose.blur, b.pose.blur),
                    opacity: mix(a.pose.opacity, b.pose.opacity))
    }

    /// Phase (0…1) of a looping animation with a CSS-style (negative) delay.
    static func phase(_ time: Double, period: Double, delay: Double = 0) -> Double {
        let value = (time - delay).truncatingRemainder(dividingBy: period) / period
        return value < 0 ? value + 1 : value
    }

    static func uniform(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, blur: CGFloat = 1.5, opacity: CGFloat = 1) -> Pose {
        Pose(x: x, y: y, sx: s, sy: s, blur: blur, opacity: opacity)
    }

    static func idleFrames(_ dab: Dab) -> [Frame] {
        let b = dab.base
        return [
            Frame(t: 0, pose: uniform(b.x, b.y, 0.8)),
            Frame(t: 0.5, pose: uniform(b.x * 1.18, b.y * 1.18, 0.88)),
            Frame(t: 1, pose: uniform(b.x, b.y, 0.8)),
        ]
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    static func poses(for mode: Mode, time: Double, elapsed: Double, loop: Bool, still: Bool) -> Poses {
        let delays: [Double] = [0, -2, -4]
        func idle(_ i: Int, delay: Double? = nil) -> Pose {
            if still {
                return uniform(dabs[i].base.x, dabs[i].base.y, 0.8)
            }
            return sample(idleFrames(dabs[i]), at: phase(time, period: 6, delay: delay ?? delays[i]))
        }
        // One-shots: loop in galleries, play once in the app.
        func oneShot(_ duration: Double) -> Double {
            loop ? phase(elapsed, period: duration + 0.6) * (duration + 0.6) / duration : elapsed / duration
        }

        switch mode {
        case .idle:
            return Poses(dabs: (0 ..< 3).map { idle($0) })

        case .listening:
            if still {
                return Poses(dabs: (0 ..< 3).map { uniform(dabs[$0].base.x * 1.15, dabs[$0].base.y * 1.15, 0.9) })
            }
            let periods = [0.9, 0.72, 1.1], ds = [0, -0.3, -0.5]
            return Poses(dabs: (0 ..< 3).map { i in
                let b = dabs[i].base
                return sample([
                    Frame(t: 0, pose: uniform(b.x, b.y, 0.78)),
                    Frame(t: 0.25, pose: uniform(b.x * 1.3, b.y * 1.3, 1.02)),
                    Frame(t: 0.55, pose: uniform(b.x, b.y, 0.84)),
                    Frame(t: 0.8, pose: uniform(b.x * 1.2, b.y * 1.2, 0.96)),
                    Frame(t: 1, pose: uniform(b.x, b.y, 0.78)),
                ], at: phase(time, period: periods[i], delay: ds[i]))
            })

        case .thinking:
            if still {
                return Poses(dabs: (0 ..< 3).map { uniform(
                    dabs[$0].bloom.x * 0.5,
                    dabs[$0].bloom.y * 0.5,
                    0.95,
                    blur: 4
                ) })
            }
            return Poses(dabs: (0 ..< 3).map { i in
                let m = dabs[i].bloom
                return sample([
                    Frame(t: 0, pose: uniform(0, 0, 0.55, blur: 2)),
                    Frame(t: 0.4, pose: uniform(m.x, m.y, 1.15, blur: 6)),
                    Frame(t: 0.7, pose: uniform(0, 0, 0.9, blur: 3)),
                    Frame(t: 1, pose: uniform(0, 0, 0.55, blur: 2)),
                ], at: phase(time, period: 2.4, delay: -0.8 * Double(i)))
            })

        case .working:
            if still {
                return Poses(dabs: (0 ..< 3).map { Pose(
                    x: dabs[$0].base.x,
                    y: dabs[$0].base.y,
                    sx: 0.9,
                    sy: 0.72,
                    blur: 3
                ) })
            }
            return Poses(dabs: (0 ..< 3).map { i in
                let b = dabs[i].base
                return sample([
                    Frame(t: 0, pose: Pose(x: b.x, y: b.y, sx: 0.8, sy: 0.74, blur: 3)),
                    Frame(t: 0.5, pose: Pose(x: b.x * 1.4, y: b.y * 1.4, sx: 1, sy: 0.7, blur: 3)),
                    Frame(t: 1, pose: Pose(x: b.x, y: b.y, sx: 0.8, sy: 0.74, blur: 3)),
                ], at: phase(time, period: 0.8, delay: -0.27 * Double(i)))
            }, rotation: phase(time, period: 1.6) * 2 * .pi)

        case .done:
            if still {
                return Poses(dabs: (0 ..< 3).map { _ in uniform(0, 0, 0.95) })
            }
            let progress = oneShot(1.6)
            let curve = UnitCurve.bezier(
                startControlPoint: UnitPoint(x: 0.4, y: 0),
                endControlPoint: UnitPoint(x: 0.2, y: 1)
            )
            let dabPoses = (0 ..< 3).map { i in
                let b = dabs[i].base
                return sample([
                    Frame(t: 0, pose: uniform(b.x, b.y, 0.8)),
                    Frame(t: 0.3, pose: uniform(0, 0, 0.85)),
                    Frame(t: 0.42, pose: uniform(0, 0, 1.15)),
                    Frame(t: 0.55, pose: uniform(0, 0, 0.95)),
                    Frame(t: 0.7, pose: uniform(0, 0, 0.95)),
                    Frame(t: 1, pose: uniform(b.x, b.y, 0.8)),
                ], at: progress, curve: curve)
            }
            let ringPose = sample([
                Frame(t: 0, pose: uniform(0, 0, 0.4, opacity: 0)),
                Frame(t: 0.3, pose: uniform(0, 0, 0.4, opacity: 0)),
                Frame(t: 0.38, pose: uniform(0, 0, 0.6, opacity: 0.6)),
                Frame(t: 0.8, pose: uniform(0, 0, 2.8, opacity: 0)),
                Frame(t: 1, pose: uniform(0, 0, 2.8, opacity: 0)),
            ], at: progress, curve: .easeOut)
            return Poses(dabs: dabPoses, ring: Ring(scale: ringPose.sx, opacity: ringPose.opacity))

        case .needsYou:
            let b = dabs[0].base
            if still {
                return Poses(dabs: [uniform(b.x + 10, b.y - 16, 0.92), idle(1), idle(2)])
            }
            let red = sample([
                Frame(t: 0, pose: uniform(b.x, b.y, 0.8)),
                Frame(t: 0.3, pose: uniform(b.x + 10, b.y - 16, 0.92)),
                Frame(t: 0.45, pose: uniform(b.x + 14, b.y - 12, 0.9)),
                Frame(t: 0.6, pose: uniform(b.x + 10, b.y - 16, 0.92)),
                Frame(t: 1, pose: uniform(b.x, b.y, 0.8)),
            ], at: phase(time, period: 2.4))
            let drip = sample([
                Frame(t: 0, pose: uniform(-4, -14, 0.2, opacity: 0)),
                Frame(t: 0.4, pose: uniform(-4, -14, 0.2, opacity: 0)),
                Frame(t: 0.5, pose: uniform(-2, -6, 0.35, opacity: 0.9)),
                Frame(t: 0.9, pose: uniform(-2, 30, 0.15, opacity: 0)),
                Frame(t: 1, pose: uniform(-2, 30, 0.15, opacity: 0)),
            ], at: phase(time, period: 2.4), curve: .easeIn)
            return Poses(dabs: [red, idle(1, delay: 0), idle(2, delay: -3)], drip: drip)

        case let .handOff(target):
            let b = dabs[1].base
            if still {
                return Poses(dabs: [idle(0), uniform(b.x, b.y, 0.8, opacity: 0.5), idle(2)])
            }
            let curve = UnitCurve.bezier(
                startControlPoint: UnitPoint(x: 0.5, y: 0),
                endControlPoint: UnitPoint(x: 0.2, y: 1)
            )
            let blue = sample([
                Frame(t: 0, pose: uniform(b.x, b.y, 0.8)),
                Frame(t: 0.08, pose: uniform(b.x, b.y, 0.8)),
                Frame(t: 0.38, pose: uniform(target.x, target.y, 0.55)),
                Frame(t: 0.48, pose: Pose(x: target.x, y: target.y, sx: 2.6, sy: 0.7, blur: 3, opacity: 0.55)),
                Frame(t: 0.78, pose: Pose(x: target.x, y: target.y, sx: 2.6, sy: 0.7, blur: 3, opacity: 0.4)),
                Frame(t: 0.88, pose: uniform(b.x, b.y, 0.3, opacity: 0)),
                Frame(t: 1, pose: uniform(b.x, b.y, 0.8)),
            ], at: oneShot(3.4), curve: curve)
            return Poses(dabs: [idle(0, delay: 0), blue, idle(2, delay: -3)])

        case .resting:
            if still {
                return Poses(dabs: (0 ..< 3).map { uniform(dabs[$0].base.x * 0.7, dabs[$0].base.y * 0.7, 0.66) })
            }
            return Poses(dabs: (0 ..< 3).map { i in
                let b = dabs[i].base
                return sample([
                    Frame(t: 0, pose: uniform(b.x * 0.7, b.y * 0.7, 0.66)),
                    Frame(t: 0.5, pose: uniform(b.x * 0.8, b.y * 0.8, 0.7)),
                    Frame(t: 1, pose: uniform(b.x * 0.7, b.y * 0.7, 0.66)),
                ], at: phase(time, period: 9, delay: -3 * Double(i)))
            })
        }
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

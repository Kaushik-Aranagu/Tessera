import SwiftUI

/// The set mark's drawing (Design sheet 108, section 1; Motion lab's v6 study): one calligraphic brush circle per
/// logged set, and the five ink drops that move like liquid while the reps are done. Drawing only: the shapes and the
/// words are `SetMarkSpec` (Features/Workout/SetMarkModel.swift).
enum BrushCircleArt {
    /// The stage radius in points (the 390 pt stage the sheet was drawn on) and the room the strokes and rays need.
    static let radius = 48.0
    static let extent = 74.0

    static let inkRGB = (r: 20.0, g: 24.0, b: 31.0)
    static let wetRGB = (r: 216.0, g: 67.0, b: 42.0)
    static let flareRGB = (r: 229.0, g: 72.0, b: 44.0)

    /// Degrees the brush sweeps: a full turn closed, short by the gap when open, past a turn when overlapping.
    static func sweep(_ shape: SetMarkSpec.Shape) -> Double {
        switch shape {
        case .closed, .flare: 360
        case let .open(gap): 360 * (1 - min(max(gap, 0.08), 0.9))
        case let .overlap(extra): 360 * (1 + 0.55 * min(max(extra, 0.1), 1))
        }
    }

    /// Stroke width along the stroke (0 head to 1 tail): a quick swell from the tip, a long taper to the tail.
    static func taper(_ t: Double) -> Double {
        let head = min(1, 0.3 + 3.2 * t)
        let tail = t > 0.72 ? 1 - 0.86 * ((t - 0.72) / 0.28) : 1
        return max(0.12, head * tail)
    }

    /// Colour along the stroke: wet at the tip, drying to ink over `SetMarkClock.dry`.
    static func colour(at t: Double, age: Double, ink _: Color, dark: Bool) -> Color {
        let drying = 1 - min(max(age / SetMarkClock.dry, 0), 1)
        let wet = drying * (0.35 + 0.65 * t)
        let base = dark ? (r: 236.0, g: 236.0, b: 232.0) : inkRGB
        return Color(red: (base.r + (wetRGB.r - base.r) * wet) / 255, green: (base.g + (wetRGB.g - base.g) * wet) / 255,
                     blue: (base.b + (wetRGB.b - base.b) * wet) / 255)
    }

    /// Draws one circle centred in `size`. `drawn` is how much of the stroke is down (0 to 1); `age` is seconds since
    /// it finished, for the drying ink.
    static func draw(_ context: inout GraphicsContext, size: CGSize, spec: SetMarkSpec, drawn: Double, age: Double,
                     dark: Bool, minimumWidth: Double = 1.4)
    {
        let scale = min(size.width, size.height) / (extent * 2)
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let total = sweep(spec.shape)
        let segments = max(Int(total / 3), 24)
        let start = -112.0
        let thickness = spec.thickness
        let shown = Int(Double(segments) * min(max(drawn, 0), 1))
        guard shown > 0 else { return }
        for index in 0 ..< shown {
            let t0 = Double(index) / Double(segments), t1 = Double(index + 1) / Double(segments)
            let a0 = (start + total * t0) * .pi / 180, a1 = (start + total * t1) * .pi / 180
            // An overlapping circle spirals out a little where it passes itself.
            let r0 = radius * (1 + 0.07 * max(0, total - 360) / 200 * t0), r1 = radius * (1 + 0.07 * max(
                0,
                total - 360
            ) / 200 * t1)
            var path = Path()
            path.move(to: CGPoint(x: centre.x + cos(a0) * r0 * scale, y: centre.y + sin(a0) * r0 * scale))
            path.addLine(to: CGPoint(x: centre.x + cos(a1) * r1 * scale, y: centre.y + sin(a1) * r1 * scale))
            let width = max(thickness * taper((t0 + t1) / 2) * scale, minimumWidth)
            context.stroke(path, with: .color(colour(at: (t0 + t1) / 2, age: age, ink: .black, dark: dark)),
                           style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        if case .flare = spec.shape, drawn >= 1 {
            drawFlare(&context, centre: centre, scale: scale, spec: spec, age: age)
        }
    }

    /// Nine rays and a few splatter drops, in the flare colour (a best; never called a record).
    private static func drawFlare(_ context: inout GraphicsContext, centre: CGPoint, scale: Double, spec: SetMarkSpec,
                                  age _: Double)
    {
        let flare = Color(red: flareRGB.r / 255, green: flareRGB.g / 255, blue: flareRGB.b / 255)
        var seed = UInt64(truncatingIfNeeded: spec.id.hashValue) | 1
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 33) / Double(1 << 31)
        }
        for ray in 0 ..< 9 {
            let angle = (Double(ray) / 9 * 360 - 100 + next() * 10) * .pi / 180
            let inner = radius + spec.thickness * 0.8 + 5, outer = inner + 9 + next() * 11
            var path = Path()
            path.move(to: CGPoint(x: centre.x + cos(angle) * inner * scale, y: centre.y + sin(angle) * inner * scale))
            path.addLine(to: CGPoint(
                x: centre.x + cos(angle) * outer * scale,
                y: centre.y + sin(angle) * outer * scale
            ))
            context.stroke(
                path,
                with: .color(flare),
                style: StrokeStyle(lineWidth: max(2.4 * scale, 1), lineCap: .round)
            )
        }
        for _ in 0 ..< 4 {
            let angle = next() * 2 * .pi, distance = radius + 22 + next() * 14, size = (1.6 + next() * 1.8) * scale
            let point = CGPoint(
                x: centre.x + cos(angle) * distance * scale,
                y: centre.y + sin(angle) * distance * scale
            )
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2)),
                with: .color(flare)
            )
        }
    }
}

/// A finished brush circle at any size (22 pt in a row, about 96 on the stage). No fill, no inside drop, no wash.
struct SetMarkCircle: View {
    let spec: SetMarkSpec
    var side: CGFloat = 22
    /// 0 to 1: how much of the stroke is drawn.
    var drawn: Double = 1
    /// Seconds since the circle finished, for the drying ink.
    var age: Double = 99
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            BrushCircleArt.draw(&context, size: size, spec: spec, drawn: drawn, age: age, dark: scheme == .dark)
        }
        .frame(width: side, height: side)
    }
}

// MARK: - The ink drops

/// Five drops that behave as liquid on springs (Design: natural frequency 11 to 16 rad/s, damping 0.34 to 0.54, each
/// with its own noise). Idle they drift about 13 pt around their homes; a rep is a soft pull together and a quicker
/// release with overshoot; the last two reps tremble.
@MainActor
final class InkDropSwarm {
    struct Drop {
        var position: CGPoint
        var velocity = CGVector.zero
        let home: CGPoint
        let omega: Double
        let zeta: Double
        let radius: Double
        let phase: Double
        let noise: (Double, Double, Double)
    }

    private(set) var drops: [Drop]
    private var last: Date?

    init(seed: UInt64 = 7) {
        var state = seed | 1
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 33) / Double(1 << 31)
        }
        drops = (0 ..< 5).map { index in
            let angle = Double(index) / 5 * 2 * .pi + next() * 0.6
            let home = CGPoint(x: cos(angle) * (9 + next() * 7), y: sin(angle) * (9 + next() * 7))
            return Drop(position: home, home: home, omega: 11 + next() * 5, zeta: 0.34 + next() * 0.2,
                        radius: 3.5 + next() * 1.5, phase: next() * 100, noise: (
                            0.7 + next() * 0.6,
                            1.1 + next() * 0.7,
                            0.4 + next()
                        ))
        }
    }

    /// Smooth noise in -1...1 from a sum of sines (each drop has its own).
    private static func noise(_ t: Double, _ drop: Drop) -> CGPoint {
        let (a, b, c) = drop.noise
        let x = sin(t * a + drop.phase) * 0.5 + sin(t * b * 1.7 + drop.phase * 2.1) * 0.3 +
            sin(t * c * 2.9 + drop.phase * 0.7) * 0.2
        let y = cos(t * b + drop.phase * 1.3) * 0.5 + sin(t * c * 1.9 + drop.phase * 3.1) * 0.3 +
            cos(t * a * 2.7 + drop.phase) * 0.2
        return CGPoint(x: x, y: y)
    }

    /// Steps the springs to `now`. `pull` (0 to 1) draws the drops together; `tremble` shakes them (the last two reps).
    func step(now: Date, pull: Double, tremble: Bool) {
        let dt = min(now.timeIntervalSince(last ?? now), 1.0 / 30)
        last = now
        let time = now.timeIntervalSinceReferenceDate
        for index in drops.indices {
            let drop = drops[index]
            let drift = Self.noise(time, drop)
            var target = CGPoint(x: drop.home.x * (1 - 0.8 * pull) + drift.x * 13 * (1 - 0.7 * pull),
                                 y: drop.home.y * (1 - 0.8 * pull) + drift.y * 13 * (1 - 0.7 * pull))
            if tremble {
                let shake = 1.9 * sin(time * 2 * .pi * 22 + drop.phase)
                target.x += shake
                target.y += 1.9 * cos(time * 2 * .pi * 22 * 0.93 + drop.phase * 1.7)
            }
            let ax = drop.omega * drop.omega * (target.x - drop.position.x) - 2 * drop.zeta * drop.omega * drop.velocity
                .dx
            let ay = drop.omega * drop.omega * (target.y - drop.position.y) - 2 * drop.zeta * drop.omega * drop.velocity
                .dy
            drops[index].velocity.dx += ax * dt
            drops[index].velocity.dy += ay * dt
            drops[index].position.x += drops[index].velocity.dx * dt
            drops[index].position.y += drops[index].velocity.dy * dt
        }
    }
}

/// The swarm drawn as one liquid: the drops are blurred together and cut at a threshold, so they merge and part with
/// crisp edges. The drop in motion is warmer (wet ink) and dries to ink.
struct InkDropView: View {
    let swarm: InkDropSwarm
    /// 0 to 1, how hard the drops are pulled together, and whether they tremble.
    var pull: Double = 0
    var tremble = false
    var warmth: Double = 0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation) { timeline in
            let _ = swarm.step(now: timeline.date, pull: pull, tremble: tremble)
            Canvas { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                let dark = scheme == .dark
                let base = dark ? (236.0, 236.0, 232.0) : (
                    BrushCircleArt.inkRGB.r,
                    BrushCircleArt.inkRGB.g,
                    BrushCircleArt.inkRGB.b
                )
                let wet = BrushCircleArt.wetRGB
                let mix = min(max(warmth, 0), 1)
                let colour = Color(
                    red: (base.0 + (wet.r - base.0) * mix) / 255,
                    green: (base.1 + (wet.g - base.1) * mix) / 255,
                    blue: (base.2 + (wet.b - base.2) * mix) / 255
                )
                context.addFilter(.alphaThreshold(min: 0.5, color: colour))
                context.addFilter(.blur(radius: 3.2))
                context.drawLayer { layer in
                    for drop in swarm.drops {
                        let rect = CGRect(
                            x: centre.x + drop.position.x - drop.radius,
                            y: centre.y + drop.position.y - drop.radius,
                            width: drop.radius * 2,
                            height: drop.radius * 2
                        )
                        layer.fill(Path(ellipseIn: rect), with: .color(.black))
                    }
                }
            }
        }
    }
}

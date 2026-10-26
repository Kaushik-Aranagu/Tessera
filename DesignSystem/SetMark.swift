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
    static func taper(_ along: Double) -> Double {
        let head = min(1, 0.3 + 3.2 * along)
        let tail = along > 0.72 ? 1 - 0.86 * ((along - 0.72) / 0.28) : 1
        return max(0.12, head * tail)
    }

    /// Colour along the stroke: wet at the tip, drying to ink over `SetMarkClock.dry`.
    static func colour(at along: Double, age: Double, ink _: Color, dark: Bool) -> Color {
        let drying = 1 - min(max(age / SetMarkClock.dry, 0), 1)
        let wet = drying * (0.35 + 0.65 * along)
        let base = dark ? (r: 236.0, g: 236.0, b: 232.0) : inkRGB
        return Color(red: (base.r + (wetRGB.r - base.r) * wet) / 255, green: (base.g + (wetRGB.g - base.g) * wet) / 255,
                     blue: (base.b + (wetRGB.b - base.b) * wet) / 255)
    }

    /// The plain ink a private ring is drawn in (light on a dark ground).
    static func plainInk(dark: Bool) -> Color {
        dark ? Color(red: 236 / 255, green: 236 / 255, blue: 232 / 255)
            : Color(red: inkRGB.r / 255, green: inkRGB.g / 255, blue: inkRGB.b / 255)
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
        // A private set is one uniform ring: fixed width, plain ink, no taper, no wet colour.
        let uniform = spec.isPrivate
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
            let width = max(thickness * (uniform ? 1 : taper((t0 + t1) / 2)) * scale, minimumWidth)
            let stroke = uniform ? plainInk(dark: dark) : colour(at: (t0 + t1) / 2, age: age, ink: .black, dark: dark)
            context.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        if case .flare = spec.shape, drawn >= 1 {
            drawFlare(&context, centre: centre, scale: scale, spec: spec, age: age)
        }
    }

    /// A seed that is the same on every launch (`hashValue` is not): FNV-1a over the id's bytes.
    static func stableSeed(_ id: UUID) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        withUnsafeBytes(of: id.uuid) { bytes in
            for byte in bytes {
                hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
            }
        }
        return hash
    }

    /// Nine rays and a few splatter drops, in the flare colour (a best; never called a record).
    private static func drawFlare(_ context: inout GraphicsContext, centre: CGPoint, scale: Double, spec: SetMarkSpec,
                                  age _: Double)
    {
        let flare = Color(red: flareRGB.r / 255, green: flareRGB.g / 255, blue: flareRGB.b / 255)
        var seed = stableSeed(spec.id) | 1
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

/// What the swarm is doing: the rep under way (its index and how far through it, 0 to 1) out of `reps`, or none.
struct SwarmRep: Equatable {
    let index: Int
    let phase: Double
    let reps: Int
}

/// Five drops that behave as liquid on springs (Design, from Motion lab's v6 study: idle natural frequency 11 + 5r,
/// damping 0.34 + 0.2r, drift 13 pt; during a rep the springs stiffen, w x 1.35 and z x 0.9). Each rep is a pull
/// together (a smoothstep in over the first 58%, a full release over the last 42%), with its own amplitude, start
/// delay and length per drop; the last two reps tremble with smooth noise under a sine envelope.
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
        /// This drop's own lift in a rep (0 to 1): its place in the 13 pt rise.
        let lift: Double
        /// How much of the drop's size is lost at full pull (12%).
        var shrink = 0.0
    }

    private(set) var drops: [Drop]
    private var last: Date?
    private let seed: UInt64

    init(seed: UInt64 = 7) {
        self.seed = seed
        var state = seed | 1
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 33) / Double(1 << 31)
        }
        drops = (0 ..< 5).map { _ in
            let angle = next() * 2 * .pi
            let home = CGPoint(x: cos(angle) * (9 + next() * 7), y: sin(angle) * (9 + next() * 7))
            let spread = next()
            return Drop(position: home, home: home, omega: 11 + 5 * spread, zeta: 0.34 + 0.2 * next(),
                        radius: 3.5 + next() * 1.5, phase: next() * 100,
                        noise: (0.7 + next() * 0.6, 1.1 + next() * 0.7, 0.4 + next()), lift: 0.55 + 0.45 * next())
        }
    }

    /// Smooth noise in -1...1 from a sum of sines (each drop has its own).
    private static func noise(_ time: Double, _ drop: Drop) -> CGPoint {
        let (fa, fb, fc) = drop.noise
        let x = sin(time * fa + drop.phase) * 0.5 + sin(time * fb * 1.7 + drop.phase * 2.1) * 0.3
            + sin(time * fc * 2.9 + drop.phase * 0.7) * 0.2
        let y = cos(time * fb + drop.phase * 1.3) * 0.5 + sin(time * fc * 1.9 + drop.phase * 3.1) * 0.3
            + cos(time * fa * 2.7 + drop.phase) * 0.2
        return CGPoint(x: x, y: y)
    }

    static func smoothstep(_ x: Double) -> Double {
        let clamped = min(max(x, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    /// The pull (0 to 1) of a rep at `phase`: in over the first 58%, fully out over the last 42%.
    static func pull(phase along: Double) -> Double {
        along < 0.58 ? smoothstep(along / 0.58) : 1 - smoothstep((along - 0.58) / 0.42)
    }

    /// Per rep and drop: its amplitude, start delay (seconds) and length scale, from a seeded hash so a rep is the same
    /// every time it is played.
    func variation(rep: Int, drop: Int, reps: Int) -> (amplitude: Double, delay: Double, length: Double) {
        var state = (seed &+ UInt64(rep) &* 7919 &+ UInt64(drop) &* 104_729) | 1
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 33) / Double(1 << 31)
        }
        let lastTwo = rep >= max(reps - 2, 0)
        return ((0.70 + 0.25 * next()) * (lastTwo ? 1.1 : 1), next() * 0.09 + Double(drop) * 0.012, 0.9 + next() * 0.2)
    }

    /// Steps the springs to `now` for the rep under way (nil = idle drift).
    func step(now: Date, rep: SwarmRep?) {
        let dt = min(now.timeIntervalSince(last ?? now), 1.0 / 30)
        last = now
        let time = now.timeIntervalSinceReferenceDate
        let repLength = rep.map { SetMarkClock.repDurations(reps: $0.reps)[min($0.index, $0.reps - 1)] } ?? 0
        for index in drops.indices {
            let drop = drops[index]
            let drift = Self.noise(time, drop)
            var pull = 0.0, amplitude = 1.0
            var trembling = 0.0
            if let rep {
                let vary = variation(rep: rep.index, drop: index, reps: rep.reps)
                // This drop's own clock inside the rep: it starts a little late and runs a little long.
                let own = (rep.phase * repLength - vary.delay) / (repLength * vary.length)
                let along = min(max(own, 0), 1)
                pull = Self.pull(phase: along)
                amplitude = vary.amplitude
                if SetMarkClock.trembles(index: rep.index, reps: rep.reps) {
                    trembling = sin(.pi * along)
                }
            }
            let pulled = pull * amplitude
            var target = CGPoint(
                x: (drop.home.x + drift.x * 13 * 0.8) * (1 - 0.3 * pulled) - pulled * drop.home.x * 0.18,
                y: (drop.home.y + drift.y * 13) * (1 - 0.3 * pulled) - 13 * pulled * drop.lift
            )
            if trembling > 0 {
                // Smooth noise near 23 Hz across and 21 Hz up, under a sine envelope.
                let wobbleX = sin(2 * .pi * 23 * time + drop.phase) * 0.7 + sin(
                    2 * .pi * 31 * time + drop.phase * 1.9
                ) *
                    0.3
                let wobbleY = sin(2 * .pi * 21 * time + drop.phase * 1.4) * 0.7 +
                    sin(2 * .pi * 29 * time + drop.phase * 0.8) * 0.3
                target.x += 1.9 * wobbleX * trembling
                target.y += 1.9 * wobbleY * trembling
            }
            let stiff = rep == nil ? 1.0 : 1.35, damp = rep == nil ? 1.0 : 0.9
            let omega = drop.omega * stiff, zeta = drop.zeta * damp
            let ax = omega * omega * (target.x - drop.position.x) - 2 * zeta * omega * drop.velocity.dx
            let ay = omega * omega * (target.y - drop.position.y) - 2 * zeta * omega * drop.velocity.dy
            drops[index].velocity.dx += ax * dt
            drops[index].velocity.dy += ay * dt
            drops[index].position.x += drops[index].velocity.dx * dt
            drops[index].position.y += drops[index].velocity.dy * dt
            drops[index].shrink = 0.12 * pulled
        }
    }
}

/// The swarm drawn as one liquid: the drops are blurred together and cut at a threshold, so they merge and part with
/// crisp edges. The drop in motion is warmer (wet ink) and dries to ink.
struct InkDropView: View {
    let swarm: InkDropSwarm
    var rep: SwarmRep?
    var warmth: Double = 0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LiveClock(LiveFeatures.inkDrops, minimumInterval: nil) { timeline in
            let _ = swarm.step(now: timeline.date, rep: rep)
            Canvas { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                let dark = scheme == .dark
                let base = dark ? (236.0, 236.0, 232.0)
                    : (BrushCircleArt.inkRGB.r, BrushCircleArt.inkRGB.g, BrushCircleArt.inkRGB.b)
                let wet = BrushCircleArt.wetRGB
                let mix = min(max(warmth, 0), 1)
                let colour = Color(red: (base.0 + (wet.r - base.0) * mix) / 255,
                                   green: (base.1 + (wet.g - base.1) * mix) / 255,
                                   blue: (base.2 + (wet.b - base.2) * mix) / 255)
                context.addFilter(.alphaThreshold(min: 0.41, color: colour))
                context.addFilter(.blur(radius: 3.4))
                context.drawLayer { layer in
                    for drop in swarm.drops {
                        let radius = drop.radius * (1 - drop.shrink)
                        let rect = CGRect(
                            x: centre.x + drop.position.x - radius,
                            y: centre.y + drop.position.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        layer.fill(Path(ellipseIn: rect), with: .color(.black))
                    }
                }
            }
        }
    }
}

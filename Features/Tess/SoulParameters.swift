import SwiftUI

// The soul is data: every mode is one row of `SoulParameters.table`, built from the keyframes in `SoulMotion`
// (a straight transcription of `soul.css` in docs/design/mockups/TessSoul3.dc.html). The renderer samples the
// row for each mode that is on screen and blends the results, so changing a mode is a table edit.

/// One keyframe of a dab, as in the CSS reference. Position is a mix of the dab's home offset, its bloom target
/// and the hand-off target, plus a nudge in points.
struct SoulKey: Equatable {
    var time: Double
    var home: CGFloat
    var bloom: CGFloat
    var target: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat
    var blur: CGFloat
    var opacity: CGFloat

    init(
        _ time: Double, home: CGFloat = 1, bloom: CGFloat = 0, target: CGFloat = 0, dx: CGFloat = 0, dy: CGFloat = 0,
        scale: CGFloat, scaleY: CGFloat? = nil, blur: CGFloat = 4, opacity: CGFloat = 1
    ) {
        self.time = time
        self.home = home
        self.bloom = bloom
        self.target = target
        self.dx = dx
        self.dy = dy
        scaleX = scale
        self.scaleY = scaleY ?? scale
        self.blur = blur
        self.opacity = opacity
    }

    static func mix(_ start: Self, _ end: Self, _ amount: CGFloat) -> Self {
        func lerp(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
            lhs * (1 - amount) + rhs * amount
        }
        return SoulKey(
            start.time + (end.time - start.time) * Double(amount),
            home: lerp(start.home, end.home), bloom: lerp(start.bloom, end.bloom), target: lerp(
                start.target,
                end.target
            ),
            dx: lerp(start.dx, end.dx), dy: lerp(start.dy, end.dy), scale: lerp(start.scaleX, end.scaleX),
            scaleY: lerp(start.scaleY, end.scaleY), blur: lerp(start.blur, end.blur), opacity: lerp(
                start.opacity,
                end.opacity
            )
        )
    }
}

/// One dab's motion in one mode: keyframes, period and CSS-style delay (negative = starts part-way through).
/// For one-shot modes `period` is the duration and a positive `delay` is a lag.
struct SoulTrack {
    var keys: [SoulKey]
    var period: Double
    var delay: Double = 0
    var curve: UnitCurve = .easeInOut

    /// The interpolated keyframe at `progress` (0…1). Each segment is eased, like `animation-timing-function`.
    func key(at progress: Double) -> SoulKey {
        let clamped = min(max(progress, 0), 1)
        guard let next = keys.firstIndex(where: { $0.time >= clamped }) else { return keys[keys.count - 1] }
        guard next > 0 else { return keys[0] }
        let start = keys[next - 1], end = keys[next]
        let local = end.time == start.time ? 1 : (clamped - start.time) / (end.time - start.time)
        return SoulKey.mix(start, end, CGFloat(curve.value(at: local)))
    }
}

/// Whole-soul grade and size: what CSS puts on `.soul` (scale) and `.soulmix` (saturate, contrast).
struct SoulLook: Equatable {
    var scale: CGFloat = 1
    var saturation: CGFloat = 1.45
    var contrast: CGFloat = 1.04
    var brightness: CGFloat = 0
    var opacity: CGFloat = 1
    /// 0 hides the three satellite dabs.
    var satellites: CGFloat = 1

    static func mix(_ start: Self, _ end: Self, _ amount: CGFloat) -> Self {
        func lerp(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
            lhs * (1 - amount) + rhs * amount
        }
        return SoulLook(
            scale: lerp(start.scale, end.scale), saturation: lerp(start.saturation, end.saturation),
            contrast: lerp(start.contrast, end.contrast), brightness: lerp(start.brightness, end.brightness),
            opacity: lerp(start.opacity, end.opacity), satellites: lerp(start.satellites, end.satellites)
        )
    }
}

/// One mode's row in the table.
struct SoulParameters {
    var look: SoulLook
    /// Vermilion, cobalt, cadmium main dabs.
    var mains: [SoulTrack]
    /// The satellites, in the same colour order.
    var satellites: [SoulTrack]
    /// The little vermilion drip (needs you).
    var drip: SoulTrack?
    /// The splash ring (done).
    var ring: SoulTrack?
    /// Plays once over this many seconds, then holds its last frame (done, hand-off).
    var oneShot: Double?
    /// Reduce Motion shows every track frozen at this point.
    var stillPhase: Double = 0
    /// Ticks at 30 fps instead of the display rate.
    var isSlow = false

    var isOneShot: Bool {
        oneShot != nil
    }
}

extension SoulParameters {
    static func table(_ mode: TessSoul.Mode) -> SoulParameters {
        typealias Motion = SoulMotion
        switch mode {
        case .idle, .working, .gathering:
            // A calm "needs you": one main dab lifts at a time; satellites drift. No drip. Small.
            return SoulParameters(
                look: SoulLook(scale: 0.62),
                mains: [0, -6, -3].map { SoulTrack(keys: Motion.lift, period: 9, delay: $0) },
                satellites: [(9, -4), (11, -1), (7.5, -5)].map { SoulTrack(keys: Motion.drift, period: $0, delay: $1) },
                // Working is an overlay on her at rest (§5, `SoulWork`): idle's dabs underneath, at full rate.
                isSlow: mode == .idle
            )
        case .listening:
            // The bloom: from near the centre out to each bloom target and back, staggered by thirds.
            return SoulParameters(
                look: SoulLook(),
                mains: [0, -0.8, -1.6].map { SoulTrack(keys: Motion.bloom, period: 2.4, delay: $0) },
                satellites: [-1.2, -2, -0.4].map { SoulTrack(keys: Motion.bloom, period: 2.4, delay: $0) },
                stillPhase: 0.4
            )
        case .thinking:
            // The pulse: each dab swells outward at its own rate. Also covers Tess doing things.
            return SoulParameters(
                look: SoulLook(scale: 0.8),
                mains: [(0.9, 0), (0.72, -0.3), (1.1, -0.5)]
                    .map { SoulTrack(keys: Motion.pulse, period: $0, delay: $1) },
                satellites: [(0.8, -0.2), (1, -0.6), (0.66, -0.1)]
                    .map { SoulTrack(keys: Motion.pulse, period: $0, delay: $1) },
                stillPhase: 0.3
            )
        case .done:
            // Kaushik: perfect, keep exactly. Pour into the centre, swell, splash a ring, relax.
            let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.4, y: 0),
                                         endControlPoint: UnitPoint(x: 0.2, y: 1))
            return SoulParameters(
                look: SoulLook(),
                mains: [0, 0, 0].map { SoulTrack(keys: Motion.merge, period: 1.8, delay: $0, curve: curve) },
                satellites: [0.08, 0.16, 0.24]
                    .map { SoulTrack(keys: Motion.merge, period: 1.8, delay: $0, curve: curve) },
                ring: SoulTrack(keys: Motion.splash, period: 1.8, curve: .easeOut),
                oneShot: 1.8,
                stillPhase: 0.6
            )
        case .needsYou:
            // Vermilion lifts and taps twice with a small drip; the others drift.
            return SoulParameters(
                look: SoulLook(scale: 0.85),
                mains: [
                    SoulTrack(keys: Motion.nudge, period: 2.4),
                    SoulTrack(keys: Motion.drift, period: 8.5),
                    SoulTrack(keys: Motion.drift, period: 10, delay: -4),
                ],
                satellites: [
                    SoulTrack(keys: Motion.nudge, period: 2.4, delay: -0.15),
                    SoulTrack(keys: Motion.drift, period: 11, delay: -2),
                    SoulTrack(keys: Motion.drift, period: 7.5, delay: -5),
                ],
                drip: SoulTrack(keys: Motion.drip, period: 2.4, curve: .easeIn),
                stillPhase: 0.35
            )
        case .handOff:
            // Cobalt and its satellite fly to the target, spread into a wash, fade and reform at home.
            let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.5, y: 0),
                                         endControlPoint: UnitPoint(x: 0.2, y: 1))
            return SoulParameters(
                look: SoulLook(scale: 0.85),
                mains: [
                    SoulTrack(keys: Motion.drift, period: 7),
                    SoulTrack(keys: Motion.carry, period: 3.4, curve: curve),
                    SoulTrack(keys: Motion.drift, period: 10, delay: -4),
                ],
                satellites: [
                    SoulTrack(keys: Motion.drift, period: 9, delay: -2),
                    SoulTrack(keys: Motion.carry, period: 3.4, delay: 0.07, curve: curve),
                    SoulTrack(keys: Motion.drift, period: 7.5, delay: -5),
                ],
                oneShot: 3.4,
                stillPhase: 0.6
            )
        case .resting:
            // The paint dries: muted, out of focus, barely moving.
            return SoulParameters(
                look: SoulLook(saturation: 0.35, contrast: 1, brightness: 0.05, opacity: 0.8),
                mains: [0, -4, -8].map { SoulTrack(keys: Motion.rest, period: 12, delay: $0) },
                satellites: [(14, -2), (13, -7), (15, -10)].map { SoulTrack(keys: Motion.rest, period: $0, delay: $1) },
                isSlow: true
            )
        }
    }
}

/// The keyframes from `soul.css`, one list per CSS `@keyframes` (names noted where they differ).
enum SoulMotion {
    /// CSS `idle`: a slow drift round the home offset.
    static let drift = [
        SoulKey(0, dy: -6, scale: 0.78, blur: 3),
        SoulKey(0.25, dx: 6, scale: 0.9, blur: 5),
        SoulKey(0.5, dy: 6, scale: 0.8, blur: 4),
        SoulKey(0.75, dx: -6, scale: 0.92, blur: 6),
        SoulKey(1, dy: -6, scale: 0.78, blur: 3),
    ]

    /// CSS `lift`: lean out (+5, −10), tap once, settle; then rest for the remaining 62%.
    static let lift = [
        SoulKey(0, scale: 0.78, blur: 4),
        SoulKey(0.1, dx: 5, dy: -10, scale: 0.92, blur: 5.5),
        SoulKey(0.17, dx: 7, dy: -7, scale: 0.86, blur: 4.5),
        SoulKey(0.24, dx: 5, dy: -10, scale: 0.92, blur: 5.5),
        SoulKey(0.38, scale: 0.78, blur: 4),
        SoulKey(1, scale: 0.78, blur: 4),
    ]

    /// CSS `listen` (now thinking): swell outward ×0.6 → ×1.3.
    static let pulse = [
        SoulKey(0, home: 0.6, scale: 0.72, blur: 3, opacity: 0.85),
        SoulKey(0.3, home: 1.3, scale: 1.06, blur: 7),
        SoulKey(0.6, home: 0.9, scale: 0.84, blur: 4, opacity: 0.92),
        SoulKey(1, home: 0.6, scale: 0.72, blur: 3, opacity: 0.85),
    ]

    /// CSS `bloomS` (now listening): from ×0.45 out to the bloom target and back.
    static let bloom = [
        SoulKey(0, home: 0.45, scale: 0.6, blur: 3),
        SoulKey(0.4, home: 0, bloom: 1, scale: 1.15, blur: 6),
        SoulKey(0.7, home: 0.6, scale: 0.9, blur: 4),
        SoulKey(1, home: 0.45, scale: 0.6, blur: 3),
    ]

    /// CSS `merge` (done).
    static let merge = [
        SoulKey(0, scale: 0.8, blur: 4),
        SoulKey(0.3, home: 0, scale: 0.9, blur: 5),
        SoulKey(0.45, home: 0, scale: 1.35, blur: 9),
        SoulKey(0.6, home: 0, scale: 1, blur: 6),
        SoulKey(0.72, home: 0, scale: 1, blur: 6),
        SoulKey(1, scale: 0.8, blur: 4),
    ]

    /// CSS `splash`: the done ring, out to 2.6×.
    static let splash = [
        SoulKey(0, home: 0, scale: 0.4, opacity: 0),
        SoulKey(0.3, home: 0, scale: 0.4, opacity: 0),
        SoulKey(0.42, home: 0, scale: 0.75, opacity: 1),
        SoulKey(0.88, home: 0, scale: 2.6, opacity: 0),
        SoulKey(1, home: 0, scale: 2.6, opacity: 0),
    ]

    /// CSS `nudge`: lift (+12, −16) and tap twice.
    static let nudge = [
        SoulKey(0, scale: 0.85, blur: 4),
        SoulKey(0.35, dx: 12, dy: -16, scale: 1.06, blur: 7),
        SoulKey(0.5, dx: 15, dy: -12, scale: 0.98, blur: 5),
        SoulKey(0.65, dx: 12, dy: -16, scale: 1.06, blur: 7),
        SoulKey(1, scale: 0.85, blur: 4),
    ]

    /// CSS `drip`: falls 34pt and fades. Positions are absolute.
    static let drip = [
        SoulKey(0, home: 0, dx: -2, dy: -12, scale: 0.2, blur: 2, opacity: 0),
        SoulKey(0.4, home: 0, dx: -2, dy: -12, scale: 0.2, blur: 2, opacity: 0),
        SoulKey(0.52, home: 0, dy: -4, scale: 0.38, blur: 2, opacity: 0.85),
        SoulKey(0.92, home: 0, dy: 34, scale: 0.16, blur: 2, opacity: 0),
        SoulKey(1, home: 0, dy: 34, scale: 0.16, blur: 2, opacity: 0),
    ]

    /// CSS `carry` (hand-off): fly to the target, spread into a wash, fade, reform at home.
    static let carry = [
        SoulKey(0, scale: 0.8, blur: 4),
        SoulKey(0.08, scale: 0.8, blur: 4),
        SoulKey(0.38, home: 0, target: 1, scale: 0.55, blur: 5),
        SoulKey(0.5, home: 0, target: 1, scale: 2.8, scaleY: 0.75, blur: 10, opacity: 0.6),
        SoulKey(0.78, home: 0, target: 1, scale: 2.8, scaleY: 0.75, blur: 12, opacity: 0.45),
        SoulKey(0.9, scale: 0.3, blur: 4, opacity: 0),
        SoulKey(1, scale: 0.8, blur: 4),
    ]

    /// CSS `rest`: smaller, softer, barely moving.
    static let rest = [
        SoulKey(0, home: 0.7, dy: -3, scale: 0.62, blur: 6),
        SoulKey(0.5, home: 0.8, dx: 3, scale: 0.68, blur: 8),
        SoulKey(1, home: 0.7, dy: -3, scale: 0.62, blur: 6),
    ]
}

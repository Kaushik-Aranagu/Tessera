import SwiftUI

/// The single place that decides how motion is rendered. With Reduce Motion or Low Power on, every animation
/// becomes a short cross-fade so nothing slides, scales or bounces (ruling G317/G318: Low Power = Reduce Motion,
/// one 150 ms crossfade). The soul keeps her own Low Power form and reads both flags itself.
enum MotionPolicy {
    static let reducedMotionFade = Animation.easeOut(duration: 0.15)

    /// Whether decorative motion is off: Reduce Motion or Low Power. The one rule behind `\.motionReduced`.
    static func isReduced(reduceMotion: Bool, lowPower: Bool) -> Bool {
        reduceMotion || lowPower
    }

    /// `reduceMotion` is the view's `\.motionReduced` (Reduce Motion or Low Power already folded in); pass
    /// `lowPower` too when only the system Reduce Motion flag is at hand.
    static func resolve(_ animation: Animation, reduceMotion: Bool, lowPower: Bool = false) -> Animation {
        isReduced(reduceMotion: reduceMotion, lowPower: lowPower) ? reducedMotionFade : animation
    }
}

extension EnvironmentValues {
    /// Reduce Motion or Low Power. Fed once at the root (`RootView`) from the system flag and `PowerState`; every
    /// view that used to read `\.accessibilityReduceMotion` for decorative motion reads this instead, so Low Power
    /// behaves like Reduce Motion everywhere. Only the soul and the few places that tell the two apart read the
    /// system flag directly.
    @Entry var motionReduced = false
}

private struct TesseraAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.motionReduced) private var reduceMotion
    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        content.animation(MotionPolicy.resolve(animation, reduceMotion: reduceMotion), value: value)
    }
}

extension View {
    /// Use instead of `.animation(_:value:)` so Reduce Motion and Low Power are always respected.
    func tesseraAnimation(_ animation: Animation = Theme.Motion.house, value: some Equatable) -> some View {
        modifier(TesseraAnimationModifier(animation: animation, value: value))
    }
}

/// Use instead of `withAnimation`. Pass the view's `@Environment(\.motionReduced)` value.
@MainActor
func withTesseraAnimation<Result>(
    _ animation: Animation = Theme.Motion.house,
    reduceMotion: Bool,
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(MotionPolicy.resolve(animation, reduceMotion: reduceMotion), body)
}

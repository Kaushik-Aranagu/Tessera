import SwiftUI

/// The single place that decides how motion is rendered. With Reduce Motion on, every animation
/// becomes a short cross-fade so nothing slides, scales or bounces.
enum MotionPolicy {
    static let reducedMotionFade = Animation.easeOut(duration: 0.15)

    static func resolve(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? reducedMotionFade : animation
    }
}

private struct PilotAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        content.animation(MotionPolicy.resolve(animation, reduceMotion: reduceMotion), value: value)
    }
}

extension View {
    /// Use instead of `.animation(_:value:)` so Reduce Motion is always respected.
    func pilotAnimation(_ animation: Animation = Theme.Motion.house, value: some Equatable) -> some View {
        modifier(PilotAnimationModifier(animation: animation, value: value))
    }
}

/// Use instead of `withAnimation`. Pass the view's `@Environment(\.accessibilityReduceMotion)` value.
@MainActor
func withPilotAnimation<Result>(
    _ animation: Animation = Theme.Motion.house,
    reduceMotion: Bool,
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(MotionPolicy.resolve(animation, reduceMotion: reduceMotion), body)
}

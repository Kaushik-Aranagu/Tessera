import SwiftUI

/// A structural rule (under headers). Row separators use `RowSeparator`, which follows the concept.
struct Hairline: View {
    var color: Color = Theme.Colors.hairline
    var body: some View {
        Rectangle().fill(color).frame(height: Theme.Stroke.hairline)
    }
}

/// Mono caps label ("NOW", "17:45 – 18:40") at the label size.
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.Colors.inkSecondary
    var body: some View {
        Text(text.uppercased())
            .textRole(.label)
            .tracking(1.2)
            .foregroundStyle(color)
    }
}

/// Press-and-hold to confirm. A fill sweeps across while held; letting go early (or scrolling away) rewinds.
/// The fill waits 120 ms so taps and scrolls never flash it. Fires `action` with a success haptic on completion.
struct HoldToConfirm<Label: View>: View {
    var duration: Double = Theme.Motion.holdDuration
    var tint: Color = Theme.Colors.ink
    var fill: Color = Theme.Colors.ink.opacity(0.12)
    let action: () -> Void
    @ViewBuilder var label: () -> Label

    /// Resets automatically when the gesture ends or is cancelled (e.g. a scroll takes over).
    @GestureState private var isPressing = false
    @State private var progress: CGFloat = 0
    @State private var completions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let visualDelay = 0.12

    var body: some View {
        label()
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.l)
            .frame(maxWidth: .infinity)
            .background(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule().fill(fill).frame(width: max(proxy.size.height, proxy.size.width * progress))
                        .opacity(progress > 0 ? 1 : 0)
                }
            }
            .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(isPressing && !reduceMotion ? 0.98 : 1)
            .animation(Theme.Motion.snappy, value: isPressing)
            // Simultaneous, so a scroll that starts on the control still scrolls (and cancels the hold).
            .simultaneousGesture(
                LongPressGesture(minimumDuration: duration + visualDelay, maximumDistance: 24)
                    .updating($isPressing) { current, state, _ in state = current }
                    .onEnded { _ in complete() }
            )
            .onChange(of: isPressing) { _, pressing in
                if pressing {
                    withAnimation(.linear(duration: duration).delay(visualDelay)) { progress = 1 }
                } else {
                    withAnimation(MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion)) { progress = 0 }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: isPressing) { _, new in new }
            .sensoryFeedback(.success, trigger: completions)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { complete() }
    }

    private func complete() {
        completions += 1
        action()
        withAnimation(MotionPolicy.resolve(Theme.Motion.house, reduceMotion: reduceMotion)) { progress = 0 }
    }
}

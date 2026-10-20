import SwiftUI

/// A list row's left swipe (lists-acceptance 13.6): REMOVE rises in the live colour from 60 pt and commits past 96.
/// Never a hold, a red row, a confirm or a trash can. VoiceOver gets the same thing as the Remove action.
struct SwipeToRemove: ViewModifier {
    /// Removes the row; true when it went. The list page plays the haptic, since the row is gone by then (QA on #786).
    let onRemove: () -> Bool
    /// The word that rises: "Remove" on a list, "Forget" on What Tess knows.
    var word = "Remove"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull: CGFloat = 0
    /// The house "swipe is armed" tick, once as the pull crosses 96 pt (Design on #786).
    @State private var armed = false

    static let rises: CGFloat = 60
    static let commits: CGFloat = 96

    /// How much of REMOVE shows at a pull: nothing before 60 pt, all of it at 96.
    static func reveal(_ pull: CGFloat) -> Double {
        Double(min(max((abs(pull) - rises) / (commits - rises), 0), 1))
    }

    func body(content: Content) -> some View {
        content
            .accessibilityAction(named: Text(word)) { _ = remove() }
            .offset(x: pull)
            .background(alignment: .trailing) {
                Text(word)
                    .textRole(.labelStrong)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.live)
                    .opacity(Self.reveal(pull))
                    .offset(y: reduceMotion ? 0 : 6 * (1 - Self.reveal(pull)))
                    .accessibilityHidden(true)
            }
            .tesseraFeedback(trigger: armed) { _, isArmed in isArmed ? .selection : nil }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { value in
                        guard value.translation.width < 0,
                              abs(value.translation.width) > abs(value.translation.height) else { return }
                        pull = max(value.translation.width, -(Self.commits + 24))
                        armed = abs(pull) >= Self.commits
                    }
                    .onEnded { _ in
                        let went = abs(pull) >= Self.commits && remove()
                        armed = false
                        if !went {
                            withTesseraAnimation(reduceMotion: reduceMotion) { pull = 0 }
                        }
                    }
            )
    }

    private func remove() -> Bool {
        guard onRemove() else { return false }
        pull = 0
        return true
    }
}

extension View {
    func swipeToRemove(word: String = "Remove", _ onRemove: @escaping () -> Bool) -> some View {
        modifier(SwipeToRemove(onRemove: onRemove, word: word))
    }
}

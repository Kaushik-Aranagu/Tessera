import SwiftUI

/// The foot's one action word (contract §6): tap does the action; drag left or right for options. The word leans up
/// to 18 pt; past 56 pt it rolls to the option's name with a selection tick; release commits with a receipt.
struct LandingFootAction {
    struct Option {
        let name: String
        let run: () -> Void
    }

    let word: String
    var hint = ""
    var left: Option?
    var right: Option?
    let run: () -> Void
}

struct LandingActionWord: View {
    let action: LandingFootAction
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull: CGFloat = 0
    @State private var cue = HapticCue()
    @State private var armed: Int = 0

    private var option: LandingFootAction.Option? {
        pull > 0 ? action.right : (pull < 0 ? action.left : nil)
    }

    var body: some View {
        let shown = armed != 0 ? (armed > 0 ? action.right?.name : action.left?.name) ?? action.word : action.word
        Text(shown)
            .font(.custom("Figtree", size: 20, relativeTo: .body).weight(.semibold))
            .foregroundStyle(accent)
            .lineLimit(1)
            .contentTransition(.interpolate)
            .offset(x: lean)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { action.run() }
            .gesture(drag)
            .tesseraFeedback(cue)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(action.word)
            .accessibilityHint(action.hint)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action.run() }
            .modifier(OptionActions(action: action))
    }

    private var lean: CGFloat {
        let limit: CGFloat = 18
        guard option != nil else { return max(-6, min(6, pull / 8)) }
        return max(-limit, min(limit, pull / 3))
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                pull = value.translation.width
                let now = option != nil && abs(pull) >= 56 ? (pull > 0 ? 1 : -1) : 0
                if now != armed {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { armed = now }
                    if now != 0 { cue.play(.selection) }
                }
            }
            .onEnded { _ in
                if armed > 0 { action.right?.run() } else if armed < 0 { action.left?.run() }
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
                    pull = 0
                    armed = 0
                }
            }
    }
}

/// VoiceOver gets each drag option as its own action.
private struct OptionActions: ViewModifier {
    let action: LandingFootAction

    func body(content: Content) -> some View {
        content
            .accessibilityActions {
                if let left = action.left { Button(left.name, action: left.run) }
                if let right = action.right { Button(right.name, action: right.run) }
            }
    }
}

import SwiftUI
import TesseraCore

/// An option an action word offers when it is dragged: its name, and what committing does. Left is stop or remove,
/// right is again (sheet 230). Every option is also an accessibility action and, for Switch Control, a plain tap on
/// `ActionOptionWords` below the word when the caller shows them.
struct ActionOption {
    let name: String
    let perform: () -> Void
}

/// The action word of a room (the one word at the foot): a tap does the action; dragging left or right offers other
/// options, with no menus. The word leans 18 pt at most; past 56 pt it rolls over to the option's name with a
/// selection tick; letting go past that commits (medium impact; the caller owns the 10 s Undo), else it springs back.
/// A touch must start at least 28 pt from the left edge, so the system back swipe still works.
struct ActionWord: View {
    let word: String
    var left: ActionOption?
    var right: ActionOption?
    var color: Color = Theme.Colors.Accent.training
    var action: () -> Void
    /// The widest this word and its options ever get: the slot is sized for it, so nothing moves as it rolls.
    var slotWords: [String] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var travel: CGFloat = 0
    @State private var rolled: ActionWordRoll = .rest
    @State private var cue = HapticCue()
    @State private var committed = 0

    var body: some View {
        let shown = rolledName ?? word
        ZStack(alignment: .leading) {
            // The slot: invisible copies of every word it can show, so the longest decides the width.
            ForEach(
                Array(([word] + slotWords + [left?.name, right?.name].compactMap(\.self)).enumerated()),
                id: \.offset
            ) { item in
                label(item.element).hidden()
            }
            label(shown)
                .id(shown)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .offset(y: 10).combined(with: .opacity),
                    removal: .offset(y: -10).combined(with: .opacity)
                ))
                .offset(x: leanOffset)
        }
        .frame(minHeight: 36, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            cue.play(.selection)
            action()
        }
        .simultaneousGesture(drag)
        .tesseraFeedback(cue)
        .tesseraFeedback(.pickedUp, trigger: committed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
        .modifier(OptionActions(left: left, right: right))
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.Training.words(22, weight: .semibold, relativeTo: .title3))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
    }

    private var rolledName: String? {
        switch rolled {
        case .left: left?.name
        case .right: right?.name
        case .rest: nil
        }
    }

    /// The word leans toward the option, up to `actionLean`, then stays while it rolls.
    private var leanOffset: CGFloat {
        let lean = CGFloat(GestureTuning.actionLean)
        let magnitude = min(abs(travel), lean)
        return travel < 0 ? -magnitude : magnitude
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart), coordinateSpace: .global)
            .onChanged { value in
                // A touch that starts in the back-edge zone is the system's.
                guard GestureTuning.clearsBackEdge(startX: Double(value.startLocation.x)) else { return }
                guard GestureTuning.axis(dx: Double(value.translation.width),
                                         dy: Double(value.translation.height)) == .horizontal else { return }
                let dx = value.translation.width
                let side: ActionWordRoll = dx < 0 ? .left : .right
                guard (side == .left ? left : right) != nil else { return }
                travel = dx
                let stage = GestureTuning.actionWordStage(travel: Double(abs(dx)))
                let next: ActionWordRoll = stage == .rolled ? side : .rest
                if next != rolled {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { rolled = next }
                    cue.play(.selection)
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let toward = dx < 0 ? -1.0 : 1.0
                let commits = rolled != .rest
                    && GestureTuning.actionWordCommits(
                        travel: Double(abs(dx)),
                        velocity: Double(value.velocity.width) * toward
                    )
                let option = rolled == .left ? left : right
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                    travel = 0
                    rolled = .rest
                }
                if commits, let option {
                    committed += 1
                    option.perform()
                }
            }
    }
}

enum ActionWordRoll: Equatable {
    case rest, left, right
}

/// Each option is also an accessibility action.
private struct OptionActions: ViewModifier {
    let left: ActionOption?
    let right: ActionOption?

    func body(content: Content) -> some View {
        content
            .accessibilityActions {
                if let left {
                    Button(left.name, action: left.perform)
                }
                if let right {
                    Button(right.name, action: right.perform)
                }
            }
    }
}

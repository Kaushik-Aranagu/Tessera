import SwiftUI
import TesseraCore

/// A task line that finishes on a right swipe (the strike follows the finger, in ink) and says "not now" on a left
/// swipe, as Home's queue does. A tap opens the task. VoiceOver gets Done and Not now as actions.
struct TasksSwipeRow<Content: View>: View {
    let line: TasksFront.Line
    let onOpen: () -> Void
    @ViewBuilder let content: Content

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull: CGFloat = 0
    @State private var handled = false
    @State private var struck = false
    @State private var cue = HapticCue()

    var body: some View {
        Button {
            guard !handled else { return }
            onOpen()
        } label: {
            content
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .overlay(alignment: .leading) {
                    // The strike: a 2 pt ink line that draws with the finger, then holds across the line.
                    Rectangle()
                        .fill(Theme.Colors.ink)
                        .frame(width: struck ? nil : max(min(pull, TasksSwipe.span), 0), height: 2)
                        .frame(maxWidth: struck ? .infinity : nil, alignment: .leading)
                        .allowsHitTesting(false)
                }
                .environment(\.tasksStruck, struck)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .offset(x: pull < 0 ? max(pull, -150) : 0)
        .rowSwipe(.both, limit: TasksSwipe.span, onEvent: swiped)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Done") { finish() }
        .accessibilityAction(named: "Not now") { TasksActions.notNow(line, model: model) }
    }

    /// Right is Done (the strike follows the finger), left is Not now. Both go through the one gesture policy.
    private func swiped(_ event: RowSwipeEvent) {
        switch event {
        case let .pulled(value):
            guard !struck else { return }
            handled = true
            pull = value
        case let .committed(side):
            if side == .leading {
                finish()
            } else {
                notNow()
            }
        case .cancelled:
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
        case .ended:
            // After the button has seen the lift, a tap opens the row again.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                handled = false
            }
        case .armed, .disarmed:
            break
        }
    }

    private func notNow() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = -420 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 300))
            if !TasksActions.notNow(line, model: model) {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
            } else {
                pull = 0
            }
        }
    }

    /// The strike runs out across the line on the house spring and lands with one soft tap (sheet 175); then the op.
    /// A finish that fails restores the row, and Tess says nothing about "done" (QA on #1267).
    private func finish() {
        guard !struck else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            struck = true
            pull = 0
        }
        cue.play(.done)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 500))
            if !TasksActions.finish(line, model: model) {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { struck = false }
            }
        }
    }
}

private enum TasksSwipe {
    static let span: CGFloat = 250
}

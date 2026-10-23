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
    @State private var armed = false
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
                .opacity(struck ? 0.5 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .offset(x: pull < 0 ? max(pull, -150) : 0)
        .simultaneousGesture(swipe)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Done") { finish() }
        .accessibilityAction(named: "Not now") { TasksActions.notNow(line, model: model) }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height), !struck else { return }
                handled = true
                pull = value.translation.width
                let isArmed = abs(pull) >= TasksSwipe.arm
                if isArmed, !armed {
                    cue.play(.selection)
                }
                armed = isArmed
            }
            .onEnded { _ in
                let distance = pull
                armed = false
                if distance >= TasksSwipe.arm {
                    finish()
                } else if -distance >= TasksSwipe.arm {
                    withTesseraAnimation(.easeIn(duration: 0.2), reduceMotion: reduceMotion) { pull = -420 }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        TasksActions.notNow(line, model: model)
                        pull = 0
                    }
                } else {
                    withTesseraAnimation(.easeOut(duration: 0.22), reduceMotion: reduceMotion) { pull = 0 }
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    handled = false
                }
            }
    }

    /// The strike runs out across the line, a soft tap, then the op lands and the page closes up.
    private func finish() {
        guard !struck else { return }
        cue.play(.selection)
        withTesseraAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.35), reduceMotion: reduceMotion) {
            struck = true
            pull = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 600))
            TasksActions.finish(line, model: model)
        }
    }
}

private enum TasksSwipe {
    static let span: CGFloat = 250
    static let arm: CGFloat = 120
}

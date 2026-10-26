import SwiftUI

/// The foot's action (sheet 283 v3): a verb (Figtree 600 24/32, room color) over its object (500 13/18 ink 2) at
/// x 24, bottom 22, 220 x 64. Never "Start Push A": the verb is "Start", the object is "Push A". Tap does it.
/// Swiping across past 56 pt moves to the room's next action (`alternates`): the letters stream in leaning from the
/// swipe side, 480 ms, 22 ms apart, and the object rises in. A start (`hold`) needs a 500 ms hold that fills the
/// verb with color from left to right; a tap shows "Hold to start." Reduce Motion: a plain swap.
struct LandingFootAction {
    /// One of the room's actions: Log has Write, Speak, List; Deck has Start, Log, Rest; and so on.
    struct Step {
        let verb: String
        var object = ""
        /// A start: needs a 500 ms hold that fills the verb with color.
        var hold = false
        let run: () -> Void
    }

    /// The old drag option (a name and what it does), kept so a drag can still reach a side action.
    struct Option {
        let name: String
        let run: () -> Void
    }

    let word: String
    var object = ""
    var hold = false
    var hint = ""
    var alternates: [Step] = []
    var left: Option?
    var right: Option?
    let run: () -> Void

    /// The room's actions in swipe order: the primary first.
    var steps: [Step] {
        [Step(verb: word, object: object, hold: hold, run: run)] + alternates
    }
}

struct LandingActionWord: View {
    let action: LandingFootAction
    let accent: Color
    /// The shell's move (sheet 283 v4): when set, the verb's letters stream in from the left after this many
    /// seconds, 24 ms apart, 460 ms. Nil (the scaffold) shows the word at once.
    var arrival: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false
    @State private var current = 0
    @State private var direction = 1
    @State private var pull: CGFloat = 0
    @State private var fill: CGFloat = 0
    @State private var holdHint = false
    @State private var cue = HapticCue()

    private var step: LandingFootAction.Step {
        let steps = action.steps
        return steps[min(current, steps.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .leading) {
                letters(
                    holdHint ? "Hold to \(step.verb.lowercased())." : step.verb,
                    color: accent.opacity(step.hold ? 0.35 : 1)
                )
                if step.hold {
                    letters(step.verb, color: accent)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: 220 * fill)
                        }
                }
            }
            .frame(height: 32, alignment: .leading)
            if !step.object.isEmpty {
                Text(step.object)
                    .font(.custom("Figtree", size: 13, relativeTo: .caption).weight(.medium))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .frame(height: 18, alignment: .leading)
                    .id("object-\(current)")
                    .transition(.offset(y: reduceMotion ? 0 : 6))
            }
        }
        .frame(width: 220, height: 64, alignment: .topLeading)
        .offset(x: max(-18, min(18, pull / 3)))
        .contentShape(Rectangle())
        .onTapGesture { tapped() }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            guard step.hold else { return }
            withAnimation(pressing ? .linear(duration: 0.5) : .easeOut(duration: 0.2)) { fill = pressing ? 1 : 0 }
        }, perform: {
            guard step.hold else { return }
            cue.play(.done)
            step.run()
            withAnimation(.easeOut(duration: 0.2)) { fill = 0 }
        })
        .simultaneousGesture(swipe)
        .tesseraFeedback(cue)
        .onAppear { arrived = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.object.isEmpty ? step.verb : "\(step.verb), \(step.object)")
        .accessibilityHint(action.hint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { step.run() }
        .accessibilityActions {
            if let left = action.left {
                Button(left.name, action: left.run)
            }
            if let right = action.right {
                Button(right.name, action: right.run)
            }
            ForEach(Array(action.alternates.enumerated()), id: \.offset) { _, alternate in
                Button(alternate.verb, action: alternate.run)
            }
        }
    }

    /// The verb's letters; on a change they stream in from the swipe side, leaning, 22 ms apart.
    private func letters(_ text: String, color: Color) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { position, letter in
                Text(String(letter))
                    .font(.custom("Figtree", size: 24, relativeTo: .title2).weight(.semibold))
                    .foregroundStyle(color)
                    .offset(x: arrived || arrival == nil ? 0 : -28)
                    .opacity(arrived || arrival == nil ? 1 : 0)
                    .animation(arrival.map { MotionPolicy.resolve(.spring(duration: 0.46, bounce: 0.15)
                            .delay($0 + Double(position) * 0.024), reduceMotion: reduceMotion) }, value: arrived)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .offset(x: 28 * CGFloat(direction), y: 0).combined(with: .opacity)
                            .animation(.spring(duration: 0.48, bounce: 0.15).delay(Double(position) * 0.022)),
                        removal: .opacity.animation(.easeIn(duration: 0.15))
                    ))
            }
        }
        .id("\(current)-\(text)")
    }

    private func tapped() {
        if step.hold {
            holdHint = true
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                holdHint = false
            }
            return
        }
        step.run()
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                pull = value.translation.width
            }
            .onEnded { value in
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { pull = 0 }
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if abs(value.translation.width) > 56, action.steps.count > 1 {
                    direction = value.translation.width < 0 ? 1 : -1
                    let count = action.steps.count
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                        current = (current + direction + count) % count
                    }
                    cue.play(.selection)
                } else if abs(value.translation.width) > 56 {
                    // No other action: the old drag options still answer.
                    if value.translation.width > 0 {
                        action.right?.run()
                    } else {
                        action.left?.run()
                    }
                }
            }
    }
}

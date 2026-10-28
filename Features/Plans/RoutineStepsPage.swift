import SwiftUI
import TesseraCore

/// A routine's steps (sheets 313 and 379): the line above them counts what is left ("5 steps, about 10 min left"),
/// each step is checked off with a tap, and checking the last one tends the routine for the day. Opened from another
/// object's page the back word names it, and the word that names it inside a step ("orchid" in "Mist the orchid") is
/// in its colour; it is not a link, so a tap on the row still checks the step.
struct RoutineStepsPage: View {
    let routine: ObjectRecord
    var from: PageSource?
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var cue = HapticCue()
    /// The step whose pen stroke is drawing now, and how far across it is.
    @State private var penned: UUID?
    @State private var penProgress: CGFloat = 0

    var body: some View {
        let _ = model.revision
        let steps = RoutineSteps(store: model.store, classes: model.classes).steps(of: routine)
        let done = RestBook(store: model.store, classes: model.classes).stepsDone(of: routine.id, on: AppClock.now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ \(from?.name ?? "Watch")")
                        .textRole(.keyWord)
                        .textCase(.uppercase)
                        .foregroundStyle(from?.color ?? Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to \(from?.name ?? "Watch")")
                Text(routine.title)
                    .textRole(.title)
                    .wordFit(routine.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                countLine(steps: steps, done: done)
                    .padding(.top, Theme.Spacing.s)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(steps) { step in
                        row(step, done: done.contains(step.id))
                    }
                }
                .padding(.top, Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .tesseraFeedback(cue)
    }

    // MARK: The count

    /// Minutes still to do, to the nearest minute.
    static func minutesLeft(_ steps: [RoutineStep], done: Set<UUID>) -> Int {
        let seconds = steps.filter { !done.contains($0.id) }.reduce(0) { $0 + $1.seconds }
        return Int((Double(seconds) / 60).rounded())
    }

    /// "5 steps, about 10 min left": only the numbers move, like a counter (sheet 313); "All 5 steps done" when the
    /// last is checked.
    @ViewBuilder private func countLine(steps: [RoutineStep], done: Set<UUID>) -> some View {
        let left = steps.filter { !done.contains($0.id) }.count
        let minutes = Self.minutesLeft(steps, done: done)
        Group {
            if steps.isEmpty {
                Text("No steps yet")
            } else if left == 0 {
                Text("All \(steps.count) steps done")
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)))
            } else {
                HStack(spacing: 0) {
                    Text("\(left)").contentTransition(.numericText(countsDown: true))
                    Text(left == 1 ? " step, about " : " steps, about ")
                    Text("\(max(minutes, 1))").contentTransition(.numericText(countsDown: true))
                    Text(" min left")
                }
                .monospacedDigit()
            }
        }
        .font(Theme.voice(size: 21))
        .foregroundStyle(Theme.Colors.context)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(steps.isEmpty ? "No steps yet" : left == 0 ? "All \(steps.count) steps done"
            : "\(left) \(left == 1 ? "step" : "steps"), about \(max(minutes, 1)) minutes left")
    }

    // MARK: A step

    private func row(_ step: RoutineStep, done: Bool) -> some View {
        Button { toggle(step, done: done) } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                label(step.title)
                    .textRole(.body)
                    .foregroundStyle(done ? Theme.Colors.inkSecondary : Theme.Colors.ink)
                    .lineLimit(2)
                    .overlay {
                        if done {
                            if penned == step.id {
                                GalleyPenStroke(progress: penProgress)
                                    .stroke(
                                        Theme.Colors.inkSecondary,
                                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                                    )
                            } else {
                                Rectangle().frame(height: 1).foregroundStyle(Theme.Colors.inkSecondary)
                            }
                        }
                    }
                Spacer(minLength: Theme.Spacing.s)
                Text("\(max(step.seconds / 60, 1)) min")
                    .textRole(.body)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel(step.title + ", \(max(step.seconds / 60, 1)) minutes")
        .accessibilityValue(done ? "Done" : "")
        .accessibilityAddTraits(.isToggle)
    }

    /// The step's words, with the word that names the page he came from in that page's colour (sheet 379).
    private func label(_ title: String) -> Text {
        guard let from, let range = title.range(of: from.name, options: [.caseInsensitive, .diacriticInsensitive])
        else { return Text(title) }
        // "Mist the orchid" names the Orchid: the word is matched whole, never inside another word.
        let before = title[..<range.lowerBound]
        let after = title[range.upperBound...]
        let wholeBefore = before.last.map { !$0.isLetter } ?? true
        let wholeAfter = after.first.map { !$0.isLetter } ?? true
        guard wholeBefore, wholeAfter else { return Text(title) }
        return Text(before) + Text(title[range]).foregroundStyle(from.color) + Text(after)
    }

    // MARK: Doing

    /// Checks a step, or takes the check back; the count follows and a receipt carries Undo (10 s).
    private func toggle(_ step: RoutineStep, done: Bool) {
        let checking = !done
        guard let result = try? model.engine.perform(
            TendRoutineStep(step: step.id, at: AppClock.now, done: checking), by: .user
        ) else { return }
        if checking, !reduceMotion {
            penned = step.id
            penProgress = 0
            withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.32).delay(0.1)) { penProgress = 1 }
        } else {
            penned = nil
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        cue.play(checking ? .done : .selection)
        if checking {
            TessVoice.shared.say("\(step.title), done", undo: result.record, holds: .seconds(10))
        }
    }
}

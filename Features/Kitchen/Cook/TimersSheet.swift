import SwiftUI
import TesseraCore

/// Every timer of the cook in one sheet, the parallel-steps list: step timers and the ones he started, soonest first,
/// each on its own labelled line with what is left and when it ends, a Stop word, and the quick words that start a new
/// one. A sheet on the dark ground, no cards, no pills: ink words, no lines.
struct TimersSheet: View {
    let session: CookClockSession
    let calm: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var label = ""
    @FocusState private var focused: Bool

    var body: some View {
        let lines = session.timers
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Timers")
                        .textRole(.title)
                        .wordFit("Timers")
                        .foregroundStyle(Theme.Colors.Workout.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(.labelWord(Theme.Colors.Workout.inkSecondary))
                        .frame(minHeight: 44)
                }
                .padding(.top, Theme.Spacing.xl)
                if lines.isEmpty {
                    Text("Nothing running")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.Workout.inkSecondary)
                        .padding(.top, Theme.Spacing.l)
                } else {
                    ForEach(lines) { line in
                        row(line)
                            .padding(.bottom, Theme.Spacing.m)
                    }
                }
                Text("Start one")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.Workout.inkSecondary)
                    .padding(.top, Theme.Spacing.xl)
                TextField("Name, like bread", text: $label)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.Workout.ink)
                    .focused($focused)
                    .submitLabel(.done)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Timer name")
                HStack(spacing: Theme.Spacing.xl) {
                    ForEach([5.0, 10, 15, 20], id: \.self) { minutes in
                        Button("\(Int(minutes)) min") {
                            let name = label.trimmingCharacters(in: .whitespaces)
                            session.startSpoken(
                                label: name.isEmpty ? nil : name.prefix(1).uppercased() + name.dropFirst(),
                                minutes: minutes
                            )
                            label = ""
                            focused = false
                        }
                        .buttonStyle(.labelWord(Theme.Colors.Workout.ink))
                        .frame(minHeight: CookModeCopy.minTarget(accessibilitySize: typeSize.isAccessibilitySize))
                        .accessibilityLabel("Start \(Int(minutes)) minutes")
                        .accessibilityHint(CookClockCopy.startTimerHint)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
        }
        .scrollIndicators(.hidden)
        .environment(\.onWorkoutGround, true)
    }

    private func row(_ line: CookClockSession.Line) -> some View {
        ClockTick(ends: [line.endsAt], calm: calm, active: scenePhase == .active) { now in
            let done = line.isDone(at: now)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(CookClockCopy.line(line.label))
                        .textRole(.body)
                        .foregroundStyle(done ? Theme.Colors.Workout.signal : Theme.Colors.Workout.ink)
                    Spacer()
                    if done {
                        Text("done").textRole(.label).foregroundStyle(Theme.Colors.Workout.signal)
                    } else {
                        Text(timerInterval: Date() ... max(Date(), line.realEnd),
                             pauseTime: nil, countsDown: true, showsHours: false)
                            .textRole(.titleNumber)
                            .monospacedDigit()
                            .foregroundStyle(Theme.Colors.Workout.ink)
                            .accessibilityHidden(true)
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(line.step.map { "Step \($0 + 1)" } ?? "Yours")
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    Text(CookUnits.endsLine(line.endsAt))
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.Workout.inkTertiary)
                    Spacer()
                    Button(CookClockCopy.stop) { session.stop(line) }
                        .buttonStyle(.labelWord(Theme.Colors.Workout.ink))
                        .frame(minHeight: 44)
                }
            }
            .padding(.vertical, Theme.Spacing.s)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(CookClockCopy.line(line.label)) timer")
            .accessibilityValue(CookClockCopy.spokenTimer(remaining: line.remaining(at: now), endsAt: line.endsAt))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text(CookClockCopy.stop)) { session.stop(line) }
        }
    }
}

import SwiftUI
import TesseraCore

/// A ready workout (Design 129, 2): a plain page, no rail. Title, subtitle, one hint line, the exercises with their
/// sets and reps, what "Try today" does to today, and the two actions. Nothing here writes the Plan.
struct ReadyWorkoutPage: View {
    let workout: ReadyWorkout
    /// Closes the whole library once today's workout is set, so Training is what he sees.
    var leave: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var saved = false
    @State private var haptic = HapticCue()

    var body: some View {
        let _ = model.revision
        let place = TrainingPlace.current()
        let lacking = place.reason(for: workout)
        let todays = model.todaysRoutine()?.title ?? model.tonightWorkout()?.title
        let canTry = model.canTryToday()
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ Library")
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to Library")
                .padding(.bottom, Theme.Spacing.m)
                Text(workout.title)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, Theme.Spacing.s)
                    .entrance(0, hero: true)
                Text(workout.subtitle)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.bottom, Theme.Spacing.s)
                    .entrance(1)
                Text(workout.about)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Theme.Spacing.xl)
                    .entrance(1)

                if let lacking {
                    Text(lacking)
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, Theme.Spacing.l)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(workout.slots.enumerated()), id: \.offset) { _, slot in
                        HStack(alignment: .firstTextBaseline) {
                            Text(slot.exercise)
                                .font(Theme.voice(size: 21).weight(.medium))
                                .foregroundStyle(Theme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Theme.Spacing.s)
                            Text(workout.setsWord(slot))
                                .numeral(21, weight: .regular)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                        }
                        .frame(minHeight: 50)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.bottom, Theme.Spacing.xl)

                if canTry {
                    // What the move does, in words, so "Try today" is never a surprise (rolling plan rule).
                    Text(todays.map { "Instead of today's \($0)" } ?? "Today")
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.bottom, Theme.Spacing.xs)
                        .accessibilityAddTraits(.isHeader)
                    Text(insteadLine(todays))
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, Theme.Spacing.l)
                }

                HStack(spacing: Theme.Spacing.xl) {
                    if canTry {
                        Button("Try today") {
                            haptic.play(.selection)
                            if model.tryToday(workout) {
                                leave()
                            }
                        }
                        .buttonStyle(HotWordStyle())
                        .accessibilityHint("Puts this in today's place; the Plan is not changed")
                    }
                    Button(saved ? "Saved" : "Save") {
                        guard !saved else { return }
                        haptic.play(.selection)
                        saved = model.saveReadyWorkout(workout)
                    }
                    .buttonStyle(QuietWordStyle())
                    .accessibilityHint("Copies it into your routines")
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, 180)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    /// "Push A stays on the Plan; it moves to Thursday." The Plan is never rewritten (the rolling plan rule); the day
    /// it
    /// moves to is the next day.
    private func insteadLine(_ todays: String?) -> String {
        guard let todays else { return "Nothing was planned for today, so this is today's workout." }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: AppClock.now) ?? AppClock.now
        let weekday = tomorrow.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "en_US")))
        return "\(todays) stays on the Plan; it moves to \(weekday)."
    }
}

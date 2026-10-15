import SwiftUI

/// TRAINING: a context line, today's workout as the hero, its exercises as plain 50 pt rows, one ink key to start or
/// resume, and one line from Tess.
struct TrainingPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        if let workout = model.tonightWorkout() {
            WorkoutPlan(workout: workout)
        } else if let session = model.session {
            // A workout from another day is still running: it is today's training.
            WorkoutPlan(workout: session.workout)
        } else {
            EmptyTraining()
        }
    }
}

private struct WorkoutPlan: View {
    let workout: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        let entries = workout.orderedChildren
        let isRunning = model.session != nil

        VStack(alignment: .leading, spacing: 0) {
            Text(context)
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .padding(.bottom, Theme.Spacing.m)
                .entrance(0)

            Button {
                model.open(.object(workout.id))
            } label: {
                HeroText(text: workout.title) { $0 }
                    .foregroundStyle(Theme.Colors.ink)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .modifier(ZoomSource(id: Route.object(workout.id), namespace: namespace))
            .accessibilityHint("Opens \(workout.title)")
            .siblingParallax()
            .entrance(1, hero: true)
            .padding(.bottom, Theme.Spacing.xl)

            VStack(spacing: 0) {
                ForEach(entries.prefix(5)) { entry in
                    EntryRow(entry: entry)
                        .frame(height: 50)
                }
            }
            .accessibilityElement(children: .contain)
            .entrance(2)

            Spacer(minLength: Theme.Spacing.xl)

            PaintKey(isTap: true, action: {
                if isRunning {
                    model.isWorkoutPresented = true
                } else {
                    model.startWorkout(workout)
                }
            }, label: { _ in
                Text(isRunning ? "Resume workout" : "Start workout")
                    .textRole(.bodyStrong)
            })
            .entrance(3)

            if let line = tessLine(entries.first) {
                Text(line)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.tess)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.l)
                    .entrance(4)
            }
        }
    }

    /// "this evening at six"
    private var context: String {
        guard case let .date(date)? = model.store.value("scheduledFor", of: workout) else { return "today" }
        return SpokenTime.when(date, now: AppClock.now)
    }

    /// "Bench Press is ready for 82.5 today."
    private func tessLine(_ entry: ObjectRecord?) -> String? {
        guard let entry, let exercise = model.store.linkedClass("exercise", of: entry),
              let weight = model.store.number("targetWeight", of: entry), weight > 0 else { return nil }
        return "\(exercise.name) is ready for \(Format.kilograms(weight)) today."
    }
}

private struct EntryRow: View {
    let entry: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        if let exercise = model.store.linkedClass("exercise", of: entry) {
            ObjectRow(title: exercise.name, route: .classDef(exercise.id), showsArrow: false) {
                Text(TrainingPage.target(
                    sets: model.store.number("targetSets", of: entry),
                    reps: model.store.number("targetReps", of: entry)
                ))
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .monospacedDigit()
            }
        }
    }
}

extension TrainingPage {
    /// "4 × 8"; with a weight, "4 × 8 · 82.5".
    static func target(sets: Double?, reps: Double?, weight: Double? = nil) -> String {
        let scheme = "\(Int(sets ?? 0)) × \(Int(reps ?? 0))"
        guard let weight, weight > 0 else { return scheme }
        return "\(scheme) · \(Format.kilograms(weight))"
    }
}

/// One specific line and one way forward.
private struct EmptyTraining: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text("nothing on the plan today")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
            Text("A rest day. It counts too.")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .siblingParallax()
            if let exercise = model.classDef(.exercise) {
                Button {
                    model.open(.classDef(exercise.id), .jump)
                } label: {
                    Text("Browse exercises →")
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI
import TesseraCore

// The finished workout's page (Design 150, behind the `pagesV2` Review switch, default Off): one sentence, then each
// exercise as its set marks (the best set ringed in Training's accent) and one line of numbers in Outfit 300, then his
// notes, then calories when his calories switch is on, then one action. A private workout reads "Private workout".

enum PagesV2Switch {
    nonisolated static let choiceID = "pagesV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// The words of the page, pure so they are tested without drawing.
enum FinishedWorkoutWords {
    /// "Oct 21, 52 min, 18 sets. Bench was your best." The best sentence only when the session set one.
    static func sentence(date: Date?, minutes: Int?, sets: Int, best: String?) -> String {
        var parts: [String] = []
        if let date {
            parts.append(date.formatted(.dateTime.month(.abbreviated).day()))
        }
        if let minutes, minutes > 0 {
            parts.append(HouseTime.minutes(minutes))
        }
        parts.append("\(sets) \(sets == 1 ? "set" : "sets")")
        var text = parts.joined(separator: ", ") + "."
        if let best {
            text += " \(best) was your best."
        }
        return text
    }

    /// "80 for 8, 80 for 8, 82.5 for 6": the weight in the display unit without its symbol.
    static func dataLine(_ sets: [(weightKg: Double, reps: Int)], unit: MassUnit) -> String {
        sets.map { "\(trimmed(StatsMass.inDisplay($0.weightKg, unit))) for \($0.reps)" }
            .joined(separator: ", ")
    }

    /// 80 for 80.0, 82.5 for 82.5.
    static func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%g", value)
    }

    /// The set with the highest estimated max (Epley), or nil with no sets.
    static func bestIndex(_ sets: [(weightKg: Double, reps: Int)]) -> Int? {
        sets.indices.max { lhs, rhs in
            sets[lhs].weightKg * (1 + Double(sets[lhs].reps) / 30) < sets[rhs]
                .weightKg * (1 + Double(sets[rhs].reps) / 30)
        }
    }
}

struct FinishedWorkoutPage: View {
    let workout: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let summary = model.ledger.summary(of: workout)
        let isPrivate = ObjectPrivacy.routineTitle(summary.title, in: model.store) == ObjectPrivacy.routineLabel
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ Back")
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .buttonStyle(HandleButtonStyle())
                Text(isPrivate ? ObjectPrivacy.routineLabel : summary.title)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(sentence(summary, isPrivate: isPrivate))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.xs)
                if !isPrivate {
                    ForEach(workout.orderedChildren.filter { !$0.isDeleted }, id: \.id) { entry in
                        ExerciseBlock(entry: entry, bestExercises: Set(summary.records.map(\.exercise)))
                            .padding(.top, Theme.Spacing.xl)
                    }
                    notes
                    if let calories = CaloriesBurned.line(
                        forWorkout: workout, store: model.store, classes: model.classes,
                        options: CaloriesOptions(on: ReviewChoices.shared.value(of: "caloriesBurned") == "On")
                    ) {
                        Text(calories)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.xl)
                    }
                    repeatAction
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }

    private func sentence(_ summary: WorkoutSummary, isPrivate: Bool) -> String {
        if isPrivate {
            return summary.endedAt?.formatted(.dateTime.month(.abbreviated).day()) ?? ""
        }
        let minutes = summary.duration.map { Int($0 / 60) }
        return FinishedWorkoutWords.sentence(date: summary.endedAt, minutes: minutes, sets: summary.sets,
                                             best: summary.records.first?.exercise)
    }

    @ViewBuilder
    private var notes: some View {
        if let text = model.store.value("notes", of: workout)?.stringValue,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            Text(text)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.xl)
        }
    }

    /// "Repeat this": starts today's workout from the same routine, when the workout came from one.
    @ViewBuilder
    private var repeatAction: some View {
        if let routine = model.store.linkedObjects("routine", of: workout).first, model.session == nil,
           model.canStart(routine)
        {
            Button("Repeat this") { model.startRoutine(routine) }
                .buttonStyle(HotWordStyle())
                .padding(.top, Theme.Spacing.xl)
        }
    }
}

/// One exercise: its name, its set marks with the best ringed, and one line of numbers.
private struct ExerciseBlock: View {
    let entry: ObjectRecord
    let bestExercises: Set<String>
    @Environment(AppModel.self) private var model

    var body: some View {
        let exercise = model.store.linkedClass("exercise", of: entry)
        let rows = sets
        if let exercise, !rows.isEmpty {
            let best = FinishedWorkoutWords.bestIndex(rows.map { (weightKg: $0.weight, reps: $0.reps) })
            let target = Int(model.store.number("targetReps", of: entry) ?? 8)
            let heaviest = rows.map(\.weight).max() ?? 0
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Button { model.open(.classDef(exercise.id)) } label: {
                    Text(exercise.name)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .buttonStyle(HandleButtonStyle())
                HStack(spacing: 8) {
                    ForEach(rows.indices, id: \.self) { index in
                        SetMarkCircle(
                            spec: SetMarkSpec(id: rows[index].id, number: index + 1, reps: rows[index].reps,
                                              target: target, weight: rows[index].weight, heaviest: heaviest,
                                              isBest: false),
                            side: 22
                        )
                        .overlay {
                            if index == best, bestExercises.contains(exercise.name) {
                                Circle().stroke(Theme.Colors.Accent.training, lineWidth: 1.6).frame(
                                    width: 28,
                                    height: 28
                                )
                            }
                        }
                    }
                }
                .accessibilityHidden(true)
                Text(FinishedWorkoutWords.dataLine(rows.map { (weightKg: $0.weight, reps: $0.reps) },
                                                   unit: Format.unit))
                    .font(Theme.Typography.number(Theme.concept.scale.body, weight: .light))
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var sets: [(id: UUID, weight: Double, reps: Int)] {
        entry.orderedChildren.compactMap { set in
            guard let weight = model.store.number("weight", of: set), let reps = model.store.number("reps", of: set)
            else { return nil }
            return (set.id, weight, Int(reps.rounded()))
        }
    }
}

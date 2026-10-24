import SwiftUI
import TesseraCore

/// The sets block on a lift page, above Best (sheet 230): "Today's sets" inside a workout, "Usual sets" otherwise.
/// Three rows, Sets, Reps and Weight, each a scrolling number. Sets can't go below the sets already done. In a workout
/// the line "Also the usual: No/Yes" says whether a change also becomes the usual. The wheels update live.
struct LiftSetsBlock: View {
    let exercise: ClassDef

    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var alsoUsual = false
    @State private var cue = HapticCue()
    /// Bumped on every change so the block re-reads what it wrote.
    @State private var tick = 0

    /// The running workout's entry for this lift, when there is one.
    private var entry: (session: WorkoutSession, entry: ObjectRecord)? {
        guard let session = model.session, session.finishedAt == nil,
              let entry = session.entries.first(where: { session.exerciseClass(of: $0)?.id == exercise.id })
        else { return nil }
        return (session, entry)
    }

    var body: some View {
        let _ = tick
        let live = entry
        let values = values(live)
        VStack(alignment: .leading, spacing: 0) {
            Text(live == nil ? "Usual sets" : "Today's sets")
                .font(Theme.Training.words(15, weight: .semibold, relativeTo: .footnote))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            row("Sets", number: ScrollingNumber(
                value: Binding(get: { Double(values.sets) }, set: { setSets(Int($0), live) }),
                step: 1, range: Double(max(values.done, 1)) ... 20, format: { String(Int($0)) }, name: "Sets",
                spokenUnit: nil, font: numberFont, color: Theme.Colors.Accent.training, width: 120, alignment: .trailing
            ))
            row("Reps", number: ScrollingNumber(
                value: Binding(get: { Double(values.reps) }, set: { setReps(Int($0), live) }),
                step: 1, range: 1 ... 50, format: { String(Int($0)) }, name: "Reps", spokenUnit: nil, font: numberFont,
                color: Theme.Colors.Accent.training, width: 120, alignment: .trailing
            ))
            row("Weight", number: ScrollingNumber(
                value: Binding(get: { Format.unit.fromKilograms(values.weight) }, set: { setWeight($0, live) }),
                step: NumberScroll.weightStep(poundsUnit: Format.unit == .pounds),
                range: 0 ... (Format.unit == .pounds ? 1000 : 450),
                format: { $0.rounded() == $0 ? String(Int($0)) : String(format: "%g", $0) }, name: "Weight",
                spokenUnit: Format.unit == .pounds ? "pounds" : "kilograms", dialUnit: Format.unit.symbol,
                font: numberFont,
                color: Theme.Colors.Accent.training, width: 120, alignment: .trailing
            ), unit: Format.unit.symbol)
            if live != nil {
                alsoLine
            }
        }
        .padding(.bottom, Theme.Spacing.xl)
        .tesseraFeedback(cue)
        .onAppear { alsoUsual = Self.alsoUsualStored(exercise.id) }
    }

    private var numberFont: Font {
        Theme.Training.number(34, weight: .light)
    }

    private func row(_ name: String, number: ScrollingNumber, unit: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            Text(name)
                .font(Theme.Training.words(17, weight: .medium))
                .foregroundStyle(Theme.Colors.ink)
            Spacer(minLength: Theme.Spacing.m)
            number
            Text(unit ?? "")
                .font(Theme.Training.words(MeasureLine.unitSize(for: 34)))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(width: 34, alignment: .leading)
        }
        .frame(minHeight: 48)
    }

    /// "Also the usual: No" / "Yes": a word, tapped to turn.
    private var alsoLine: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text("Also the usual:")
                .font(Theme.Training.words(17))
                .foregroundStyle(Theme.Colors.inkSecondary)
            Button {
                alsoUsual.toggle()
                Self.setAlsoUsual(alsoUsual, exercise.id)
                cue.play(.selection)
            } label: {
                Text(alsoUsual ? "Yes" : "No")
                    .font(Theme.Training.words(17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.Accent.training)
                    .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .contentTransition(.interpolate)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Also the usual, \(alsoUsual ? "yes" : "no")")
            .accessibilityHint("Turns whether a change here also becomes the usual sets")
        }
    }

    // MARK: Values

    private struct Values {
        var sets: Int
        var reps: Int
        var weight: Double
        var done: Int
    }

    /// Today's from the workout entry; the usual from what he last did (kept as he changes it).
    private func values(_ live: (session: WorkoutSession, entry: ObjectRecord)?) -> Values {
        if let live {
            let done = live.session.setRows(of: live.entry).count
            let weight = live.session.setRows(of: live.entry).last?.weight
                ?? (live.entry.id == live.session.currentEntry?.id ? live.session.weight
                    : live.session.targetWeight(of: live.entry) ?? 0)
            return Values(sets: live.session.targetSets(of: live.entry),
                          reps: Int(live.session.targetReps(of: live.entry)), weight: weight, done: done)
        }
        let usual = Self.usual(for: exercise, model: model)
        return Values(sets: usual.sets, reps: usual.reps, weight: usual.weight, done: 0)
    }

    private func setSets(_ sets: Int, _ live: (session: WorkoutSession, entry: ObjectRecord)?) {
        if let live {
            live.session.setToday(entry: live.entry, sets: sets)
        }
        if live == nil || alsoUsual {
            Self.keepUsual(exercise.id, sets: sets)
        }
        tick += 1
    }

    private func setReps(_ reps: Int, _ live: (session: WorkoutSession, entry: ObjectRecord)?) {
        if let live {
            live.session.setToday(entry: live.entry, reps: reps)
        }
        if live == nil || alsoUsual {
            Self.keepUsual(exercise.id, reps: reps)
        }
        tick += 1
    }

    private func setWeight(_ display: Double, _ live: (session: WorkoutSession, entry: ObjectRecord)?) {
        let kilograms = Format.unit.toKilograms(display)
        if let live {
            live.session.setToday(entry: live.entry, weight: kilograms)
        }
        if live == nil || alsoUsual {
            Self.keepUsual(exercise.id, weight: kilograms)
        }
        tick += 1
    }

    // MARK: The usual (kept on this phone until Core has a plan field for it)

    struct Usual {
        var sets: Int
        var reps: Int
        var weight: Double
    }

    private static func key(_ id: UUID, _ part: String) -> String {
        "usualSets.\(id.uuidString).\(part)"
    }

    static func usual(for exercise: ClassDef, model: AppModel) -> Usual {
        let defaults = UserDefaults.standard
        let last = model.ledger.sessions(of: exercise, excludingWorkout: nil).first?.sets ?? []
        let sets = defaults.object(forKey: key(exercise.id, "sets")) as? Int ?? max(last.count, 3)
        let reps = defaults.object(forKey: key(exercise.id, "reps")) as? Int ?? Int(last.first?.reps ?? 8)
        let weight = defaults.object(forKey: key(exercise.id, "weight")) as? Double
            ?? last.map(\.weight).max() ?? 0
        return Usual(sets: sets, reps: reps, weight: weight)
    }

    static func keepUsual(_ id: UUID, sets: Int? = nil, reps: Int? = nil, weight: Double? = nil) {
        let defaults = UserDefaults.standard
        if let sets {
            defaults.set(sets, forKey: key(id, "sets"))
        }
        if let reps {
            defaults.set(reps, forKey: key(id, "reps"))
        }
        if let weight {
            defaults.set(weight, forKey: key(id, "weight"))
        }
    }

    static func alsoUsualStored(_ id: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: key(id, "also"))
    }

    static func setAlsoUsual(_ on: Bool, _ id: UUID) {
        UserDefaults.standard.set(on, forKey: key(id, "also"))
    }
}

/// The foot of a lift page opened inside a workout, for a lift not done and not the one under way: "Do it now" brings
/// it in front. Receipt: "Dips now, bench press after." with 10 s of Undo.
struct DoItNowFoot: View {
    let exercise: ClassDef
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private var target: (flow: WorkoutFlow, entry: ObjectRecord)? {
        guard let session = model.session, session.finishedAt == nil,
              let entry = session.entries.first(where: { session.exerciseClass(of: $0)?.id == exercise.id }),
              !session.isFinished(entry), entry.id != session.currentEntry?.id
        else { return nil }
        return (WorkoutFlows.flow(for: session), entry)
    }

    var body: some View {
        if let target {
            HStack {
                ActionWord(word: "Do it now") {
                    let current = target.flow.session.currentExercise?.name ?? "That lift"
                    if let undo = target.flow.doItNow(target.entry.id) {
                        target.flow.say(TrainingWords.swappedIn(now: exercise.name, after: current), undo: undo)
                    }
                    dismiss()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.bottom, Theme.Spacing.m)
            .padding(.top, Theme.Spacing.s)
            .background(Theme.Colors.paper.opacity(0.94))
        }
    }
}

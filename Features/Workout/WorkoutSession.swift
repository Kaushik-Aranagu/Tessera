import Foundation
import Observation

/// A live workout: the "process" running while you train. Reads targets and rest times through the object
/// model (rest comes from the exercise class's inherited `restSeconds`, e.g. 3:00 for any barbell lift).
@MainActor
@Observable
final class WorkoutSession {
    let workout: ObjectRecord
    private unowned let model: AppModel

    private(set) var currentIndex = 0
    var weight: Double = 20
    var reps: Double = 8
    private(set) var restEndsAt: Date?
    private(set) var restTotal: TimeInterval = 0
    /// Increments on every logged set (drives the stamp + haptic).
    private(set) var loggedCount = 0

    init(workout: ObjectRecord, model: AppModel) {
        self.workout = workout
        self.model = model
        currentIndex = entries.firstIndex { loggedSets(of: $0).count < targetSets(of: $0) } ?? 0
        loadDefaults()
    }

    var startedAt: Date {
        if case let .date(date)? = model.store.value("startedAt", of: workout) {
            return date
        }
        return AppClock.now
    }

    var entries: [ObjectRecord] {
        _ = loggedCount
        return workout.orderedChildren
    }

    var currentEntry: ObjectRecord? {
        entries.indices.contains(currentIndex) ? entries[currentIndex] : nil
    }

    func exerciseClass(of entry: ObjectRecord) -> ClassDef? {
        model.store.linkedClass("exercise", of: entry)
    }

    var currentExercise: ClassDef? {
        currentEntry.flatMap(exerciseClass(of:))
    }

    func targetSets(of entry: ObjectRecord) -> Int {
        Int(model.store.number("targetSets", of: entry) ?? 3)
    }

    func targetReps(of entry: ObjectRecord) -> Double {
        model.store.number("targetReps", of: entry) ?? 8
    }

    func targetWeight(of entry: ObjectRecord) -> Double? {
        model.store.number("targetWeight", of: entry)
    }

    func loggedSets(of entry: ObjectRecord) -> [AppModel.LoggedSet] {
        _ = loggedCount
        return entry.orderedChildren.compactMap { set in
            guard let weight = model.store.number("weight", of: set), let reps = model.store.number("reps", of: set),
                  let e1RM = model.store.number("e1rm", of: set) else { return nil }
            return AppModel.LoggedSet(weight: weight, reps: reps, e1RM: e1RM)
        }
    }

    var restSeconds: TimeInterval {
        guard let exercise = currentExercise else { return 120 }
        let prototypeValue = model.prototype(of: exercise).flatMap { model.store.number("restSeconds", of: $0) }
        let inherited = ClassResolver.field("restSeconds", of: exercise)?.defaultValue?.numericValue
        return prototypeValue ?? inherited ?? 120
    }

    // MARK: Personal records

    var previewE1RM: Double? {
        model.previewE1RM(weight: weight, reps: reps)
    }

    /// Best set before this workout, for the PR hint.
    var previousBest: AppModel.LoggedSet? {
        currentExercise.flatMap { model.bestSet(of: $0, excludingWorkout: workout.id) }
    }

    var isPersonalRecord: Bool {
        guard let preview = previewE1RM, let best = previousBest else { return false }
        return preview > best.e1RM + 0.05
    }

    /// Reps needed at the current weight to beat the previous best e1RM.
    var repsForRecord: Int? {
        guard let best = previousBest, weight > 0 else { return nil }
        let needed = (best.e1RM / weight - 1) * 30
        return max(Int(needed.rounded(.down)) + 1, 1)
    }

    // MARK: Actions

    func adjustWeight(by delta: Double) {
        weight = max(0, min(400, weight + delta))
    }

    func adjustReps(by delta: Double) {
        reps = max(1, min(50, reps + delta))
    }

    func logSet() {
        guard let entry = currentEntry, let setClass = model.classDef(.set) else { return }
        let set = model.store.create(setClass, parent: entry)
        try? model.store.set("weight", to: .mass(weight), on: set)
        try? model.store.set("reps", to: .number(reps), on: set)
        restTotal = restSeconds
        restEndsAt = AppClock.now.addingTimeInterval(restTotal)
        loggedCount += 1
        model.touch()
    }

    func skipRest() {
        restEndsAt = nil
    }

    func select(entryAt index: Int) {
        guard entries.indices.contains(index) else { return }
        currentIndex = index
        loadDefaults()
    }

    var nextEntryIndex: Int? {
        let next = currentIndex + 1
        return entries.indices.contains(next) ? next : nil
    }

    private func loadDefaults() {
        guard let entry = currentEntry else { return }
        let last = loggedSets(of: entry).last
        weight = last?.weight ?? targetWeight(of: entry) ?? 20
        reps = last?.reps ?? targetReps(of: entry)
    }
}

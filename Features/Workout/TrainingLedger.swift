import Foundation

/// Stand-in for Core engine's `TrainingLedger` (branch core/object-model), with the same method names so the
/// workout UI can switch to the real one by deleting this file and importing `TesseraCore`.
/// Reads and writes only through `ObjectStore`.
@MainActor
struct TrainingLedger {
    let model: AppModel

    enum RecordKind: Equatable {
        /// Beats the best estimated one-rep max.
        case e1RM
        /// Heaviest weight ever lifted for this many reps (or more).
        case weightAtReps
    }

    func bestSet(of exercise: ClassDef, excludingWorkout workoutID: UUID? = nil) -> AppModel.LoggedSet? {
        model.bestSet(of: exercise, excludingWorkout: workoutID)
    }

    func e1RM(weight: Double, reps: Double) -> Double? {
        model.previewE1RM(weight: weight, reps: reps)
    }

    func recordsBeaten(weight: Double, reps: Double, for exercise: ClassDef,
                       excludingWorkout workoutID: UUID? = nil) -> [RecordKind]
    {
        let history = model.history(of: exercise).filter { $0.workout.id != workoutID }.flatMap(\.sets)
        guard !history.isEmpty, reps > 0, weight > 0 else { return [] }
        var kinds: [RecordKind] = []
        if let value = e1RM(weight: weight, reps: reps), let best = history.map(\.e1RM).max(), value > best + 0.05 {
            kinds.append(.e1RM)
        }
        let heaviestAtReps = history.filter { $0.reps >= reps }.map(\.weight).max() ?? 0
        if weight > heaviestAtReps, heaviestAtReps > 0 {
            kinds.append(.weightAtReps)
        }
        return kinds
    }

    /// Reps needed at `weight` to beat the best e1RM (Epley: e1RM = w × (1 + r / 30)).
    func repsToBeatBestE1RM(weight: Double, for exercise: ClassDef, excludingWorkout workoutID: UUID? = nil) -> Int? {
        guard let best = bestSet(of: exercise, excludingWorkout: workoutID), weight > 0 else { return nil }
        let needed = (best.e1RM / weight - 1) * 30
        return max(Int(needed.rounded(.down)) + 1, 1)
    }

    @discardableResult
    func logSet(weight: Double, reps: Double, rpe: Double?, in entry: ObjectRecord) -> ObjectRecord? {
        guard let setClass = model.classDef(.set) else { return nil }
        let set = model.store.create(setClass, parent: entry)
        try? model.store.set("weight", to: .mass(weight), on: set)
        try? model.store.set("reps", to: .number(reps), on: set)
        if let rpe {
            try? model.store.set("rpe", to: .number(rpe), on: set)
        }
        return set
    }
}

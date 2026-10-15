import Foundation

/// The quiet hint beside a set that would beat a record, and whether logging it earns the one celebration.
public struct RecordHint: Hashable, Sendable {
    public let kinds: [TrainingLedger.RecordKind]
    /// "beats 5RM", "best e1RM": short, lowercase, sits beside the set.
    public let text: String
    /// The record being beaten, for "was 80 × 5".
    public let previous: String?
}

@MainActor
public extension TrainingLedger {
    /// A hint for the set about to be logged in `entry` at `weight` × `reps`, or nil if it beats nothing.
    /// Records compare against history before this workout, so the hint is honest mid-session too.
    func recordHint(for entry: ObjectRecord, weight: Double, reps: Double, rpe: Double? = nil) -> RecordHint? {
        guard let exercise = store.linkedClass("exercise", of: entry) else { return nil }
        let workoutID = classes[.workout].flatMap { store.ancestor(of: entry, ofClass: $0) }?.id
        let kinds = recordsBeaten(weight: weight, reps: reps, rpe: rpe, for: exercise, excludingWorkout: workoutID)
        guard !kinds.isEmpty else { return nil }
        let records = records(for: exercise, excludingWorkout: workoutID)
        let repMax = kinds.compactMap { kind -> Int? in
            if case let .repMax(count) = kind {
                return count
            }
            return nil
        }.first
        if let repMax {
            let before = records.bestWeightByReps[repMax].map { "was \(WorkoutProgress.format($0)) × \(repMax)" }
            return RecordHint(kinds: kinds, text: "beats \(repMax)RM", previous: before)
        }
        let before = records.bestE1RM
            .map { "was \(WorkoutProgress.format($0.weight)) × \(WorkoutProgress.format($0.reps))" }
        return RecordHint(kinds: kinds, text: "best e1RM", previous: before)
    }

    /// The hint for the entry's prefilled next set (what the dial opens at).
    func nextSetHint(for entry: ObjectRecord) -> RecordHint? {
        let prefill = prefill(for: entry)
        guard let weight = prefill.weight else { return nil }
        return recordHint(for: entry, weight: weight, reps: Double(prefill.reps))
    }

    /// Whether a just-logged set earns the celebration: it beat a record and no earlier set of this exercise in
    /// this session already did (one celebration per exercise per session).
    func shouldCelebrate(_ set: ObjectRecord) -> Bool {
        guard let entry = set.parent, let logged = loggedSet(set) else { return false }
        let workoutID = classes[.workout].flatMap { store.ancestor(of: entry, ofClass: $0) }?.id
        guard let exercise = store.linkedClass("exercise", of: entry) else { return false }
        let beats = { (candidate: LoggedSet) in
            !self.recordsBeaten(weight: candidate.weight, reps: candidate.reps, rpe: candidate.rpe, for: exercise,
                                excludingWorkout: workoutID).isEmpty
        }
        guard beats(logged) else { return false }
        let earlier = entry.orderedChildren.prefix { $0.id != set.id }.compactMap(loggedSet)
        return !earlier.contains(where: beats)
    }
}

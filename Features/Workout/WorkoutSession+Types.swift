import Foundation
import TesseraCore

/// The live workout's value types and its finish summary, kept apart from the session's state machine.
extension WorkoutSession {
    struct Seated: Equatable {
        let setID: UUID
        let entryID: UUID
        /// 1-based number of the set within its exercise.
        let number: Int
        let records: [TrainingLedger.RecordKind]
        let e1RM: Double?
        var weight: Double = 0
        var reps: Double = 0
    }

    struct Undoable {
        let record: OpRecord
        let entryID: UUID
        let setID: UUID
        let weight: Double
        let reps: Double
        let rpe: Double?
    }

    struct TopSetCheck: Equatable {
        let entryID: UUID
        let suggested: Double
        /// The sets it would apply to, e.g. 2 to 4.
        let fromSet: Int
        let toSet: Int
        var isAccepted = false
    }

    /// One row of the sets stack.
    struct SetRow: Identifiable, Equatable {
        let id: UUID
        let number: Int
        let weight: Double
        let reps: Double
        let rpe: Double?
        let e1RM: Double
    }

    struct Summary: Equatable {
        let exercises: Int
        let sets: Int
        let volume: Double
        let duration: TimeInterval
        let best: Seated?

        /// Tess's one line: "6 exercises, 22 sets. New best: 85 × 5."
        var line: String {
            let head = "\(exercises) \(exercises == 1 ? "exercise" : "exercises"), \(sets) \(sets == 1 ? "set" : "sets")."
            guard let best else { return head }
            return head + " New best: \(Format.kilograms(best.weight)) × \(Int(best.reps))"
        }
    }

    var summary: Summary {
        let done = entries.map(setRows(of:))
        let sets = done.flatMap(\.self)
        let end = finishedAt ?? AppClock.now
        return Summary(
            exercises: done.count { !$0.isEmpty },
            sets: sets.count,
            volume: sets.reduce(0) { $0 + $1.weight * $1.reps },
            duration: end.timeIntervalSince(startedAt),
            best: bests.max { ($0.e1RM ?? 0) < ($1.e1RM ?? 0) }
        )
    }
}

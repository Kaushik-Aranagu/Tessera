import Foundation
import TesseraCore

/// Where the dialled set came from (Core's prefill), in words, and whether one hold can log it as is.
extension WorkoutSession {
    /// Why the dial opened where it did, in Tess's words.
    static func reason(for prefill: SetPrefill) -> String? {
        if prefill.isFirstTime, prefill.source != .thisSession {
            return "First time. Start light, \(prefill.reps) reps"
        }
        return switch prefill.source {
        // The detail line already says last time; the same again is silence (56 addendum).
        case .lastTime: nil
        case .thisSession: nil
        case .target: "From the plan"
        case .none: nil
        }
    }

    /// The dial still holds the prefill exactly, so Core's LogNextSet can log it as is.
    var isAtPrefill: Bool {
        guard let entry = currentEntry, rpe == nil, Format.unit == .kilograms else { return false }
        let prefill = model.ledger.prefill(for: entry)
        guard let weight = prefill.weight else { return false }
        return abs(weight - self.weight) < 0.001 && prefill.reps == Int(reps)
    }

    // MARK: Personal records

    /// Reps of last time's top set for this exercise (the drum's ghost before today's first set).
    var lastTimeReps: Double? {
        guard let exercise = currentExercise,
              let last = ledger.sessions(of: exercise, excludingWorkout: workout.id).first else { return nil }
        return last.sets.max { $0.weight < $1.weight }?.reps
    }

    var previewE1RM: Double? {
        ledger.e1RM(weight: weight, reps: reps, rpe: rpe)
    }

    /// Best set before this workout, for the PR hint.
    var previousBest: AppModel.LoggedSet? {
        currentExercise.flatMap { ledger.bestSet(of: $0, excludingWorkout: workout.id) }
            .map { AppModel.LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) }
    }

    /// Core's quiet hint for the dialled set ("beats 5RM", "was 80 × 5"), RPE included; nil when it beats nothing.
    var recordHint: RecordHint? {
        currentEntry.flatMap { ledger.recordHint(for: $0, weight: weight, reps: reps, rpe: rpe) }
    }

    var isPersonalRecord: Bool {
        recordHint != nil
    }

    /// Reps needed at the current weight to beat the previous best e1RM.
    var repsForRecord: Int? {
        currentExercise.flatMap { ledger.repsToBeatBestE1RM(weight: weight, for: $0, excludingWorkout: workout.id) }
    }
}

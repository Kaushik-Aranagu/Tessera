import Foundation
import TesseraCore

// MARK: Training stats

/// Out of `AppModel`'s body so the class stays inside swiftlint's type_body_length (the release build needs it clean).
extension AppModel {
    struct LoggedSet {
        let weight: Double
        let reps: Double
        let e1RM: Double
    }

    struct SessionSummary: Identifiable {
        let id: UUID
        let workout: ObjectRecord
        let date: Date
        let sets: [LoggedSet]
    }

    /// Completed sessions for an exercise class (and its subclasses), newest first.
    /// Completed sessions for an exercise class (and its subclasses), newest first. Reads Core's training index
    /// (milliseconds even with years of history) instead of walking backlinks.
    func history(of exercise: ClassDef) -> [SessionSummary] {
        _ = revision
        return ledger.sessions(of: exercise).map { session in
            SessionSummary(id: session.id, workout: session.workout, date: session.date,
                           sets: session.sets.map { LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) })
        }
    }

    func bestSet(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> LoggedSet? {
        _ = revision
        return ledger.bestSet(of: exercise, excludingWorkout: excludedID)
            .map { LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) }
    }

    /// Evaluates the Set class's own `e1rm` expression for values that aren't logged yet.
    func previewE1RM(weight: Double, reps: Double) -> Double? {
        guard let setClass = classes[.set], let source = ClassResolver.field("e1rm", of: setClass)?.expression,
              let expression = try? Formula.parse(source) else { return nil }
        return expression.evaluate { ["weight": weight, "reps": reps][$0] }
    }
}

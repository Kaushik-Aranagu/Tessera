import Foundation

/// The exercise page in one call: best set, best e1RM, rep maxes, recent sessions and the 90-day trend.
public struct ExerciseOverview {
    public let exercise: ClassDef
    /// The heaviest weight × reps by e1RM.
    public let bestSet: TrainingLedger.LoggedSet?
    public var bestE1RM: Double? {
        bestSet?.e1RM
    }

    /// Heaviest weight at 1…10 reps.
    public let repMaxes: [Int: Double]
    /// Newest first.
    public let recentSessions: [TrainingLedger.Session]
    public let sessionCount: Int
    /// Oldest first, last 90 days.
    public let trend: [TrainingLedger.TrendPoint]
}

@MainActor
public extension TrainingLedger {
    func overview(of exercise: ClassDef, recent: Int = 5, now: Date = .now) -> ExerciseOverview {
        let all = sessions(of: exercise)
        let records = records(for: exercise)
        return ExerciseOverview(
            exercise: exercise, bestSet: records.bestE1RM, repMaxes: records.bestWeightByReps,
            recentSessions: Array(all.prefix(recent)), sessionCount: all.count, trend: trend(of: exercise, now: now)
        )
    }
}

/// Swaps the exercise of an entry in the session in progress ("bench taken"); the routine stays as it is.
public struct SwapEntryExercise: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "swapEntryExercise",
        summary: "Swap an exercise for this session only",
        parameters: [
            .init("entry", .object, "The exercise entry in the workout"),
            .init("exercise", .classRef, "The exercise to do instead"),
        ]
    )

    public var entry: UUID
    public var exercise: UUID

    public init(entry: UUID, exercise: UUID) {
        self.entry = entry
        self.exercise = exercise
    }

    public func apply(_ transaction: inout Transaction) throws {
        let entry = try transaction.object(entry, is: .exerciseEntry)
        let replacement = try transaction.exerciseClass(exercise)
        try transaction.setClassLink("exercise", on: entry, to: replacement)
        // The old exercise's weight doesn't carry over; the new one opens at its own last time.
        try transaction.set("targetWeight", to: nil, on: entry)
        if let workout = try transaction.store.ancestor(of: entry, ofClass: transaction.classDef(.workout)) {
            try transaction.touchWorkoutProcess(workout, at: .now)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "Swapped to \(store.classDef(id: exercise)?.name ?? "another exercise") for today"
    }
}

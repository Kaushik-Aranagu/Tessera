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

/// Swaps an exercise entry for today only ("bench taken"): the routine's slot, scheme and rule stay as they are.
/// - Nothing logged yet: the entry is relinked to the new exercise, with an optional starting weight.
/// - Some sets logged: those stay with the old exercise (its entry now plans only what's done) and a new entry
///   carries the remaining sets, linked to the same slot.
/// Returns the id of the entry that now carries the new exercise.
public struct SwapEntryExercise: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "swapExercise",
        summary: "Swap an exercise for this session only",
        parameters: [
            .init("entry", .object, "The exercise entry in the workout"),
            .init("exercise", .classRef, "The exercise to do instead"),
            .init("targetWeight", .number, "Starting weight in kilograms", required: false),
        ]
    )

    public var entry: UUID
    public var exercise: UUID
    public var targetWeight: Double?

    public init(entry: UUID, exercise: UUID, targetWeight: Double? = nil) {
        self.entry = entry
        self.exercise = exercise
        self.targetWeight = targetWeight
    }

    public func apply(_ transaction: inout Transaction) throws -> UUID {
        let entry = try transaction.object(entry, is: .exerciseEntry)
        let replacement = try transaction.exerciseClass(exercise)
        let store = transaction.store
        let logged = entry.orderedChildren.count
        let carrier: ObjectRecord
        if logged == 0 {
            try transaction.setClassLink("exercise", on: entry, to: replacement)
            try transaction.set("targetWeight", to: targetWeight.map(FieldValue.mass), on: entry)
            carrier = entry
        } else {
            guard let workout = entry.parent else { throw ActionError.objectNotFound(self.entry) }
            let planned = store.number("targetSets", of: entry) ?? Double(logged)
            carrier = try transaction.create(transaction.classDef(.exerciseEntry), parent: workout)
            try transaction.setClassLink("exercise", on: carrier, to: replacement)
            try transaction.set("targetSets", to: .number(max(planned - Double(logged), 1)), on: carrier)
            try transaction.set("targetReps", to: store.value("targetReps", of: entry), on: carrier)
            try transaction.set("targetWeight", to: targetWeight.map(FieldValue.mass), on: carrier)
            let slot = store.linkedObjects("slot", of: entry)
            if !slot.isEmpty {
                try transaction.setLinks("slot", on: carrier, to: slot)
            }
            try transaction.set("targetSets", to: .number(Double(logged)), on: entry)
        }
        if let workout = try store.ancestor(of: carrier, ofClass: transaction.classDef(.workout)) {
            try transaction.touchWorkoutProcess(workout, at: .now)
        }
        return carrier.id
    }

    public func summary(in store: ObjectStore) -> String {
        "Swapped to \(store.classDef(id: exercise)?.name.lowercased() ?? "another exercise") for today"
    }
}

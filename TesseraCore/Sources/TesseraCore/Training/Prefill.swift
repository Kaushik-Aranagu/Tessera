import Foundation

/// What the next set opens at, so most sets need nothing but a hold.
public struct SetPrefill: Hashable, Sendable {
    public enum Source: String, Sendable {
        /// Last time's set at this position.
        case lastTime
        /// The previous set in this session (weight carries forward).
        case thisSession
        /// The entry's planned target (from the routine slot).
        case target
        /// Nothing to go on: the rep range's bottom and an empty weight.
        case none
    }

    public var weight: Double?
    public var reps: Int
    public var source: Source
    /// No history for this exercise: the weight, if any, is a light starting weight, not something earned.
    public var isFirstTime = false
}

@MainActor
public extension TrainingLedger {
    /// The next set for an entry: set 1 opens at last time's set 1; later sets keep this session's weight with
    /// last time's reps for that position; with no history, the entry's targets.
    func prefill(for entry: ObjectRecord) -> SetPrefill {
        let logged = entry.orderedChildren.compactMap(loggedSet)
        let index = logged.count
        let exercise = store.linkedClass("exercise", of: entry)
        let workoutID = classes[.workout].flatMap { store.ancestor(of: entry, ofClass: $0) }?.id
        let lastTime = exercise.flatMap { sessions(of: $0, excludingWorkout: workoutID).first }?.sets ?? []
        let previousTime = index < lastTime.count ? lastTime[index] : lastTime.last
        let targetReps = store.number("targetReps", of: entry).map(Int.init)
        let targetWeight = store.number("targetWeight", of: entry)

        if let previous = logged.last {
            let reps = previousTime.map { Int($0.reps.rounded()) } ?? Int(previous.reps.rounded())
            return SetPrefill(weight: previous.weight, reps: reps, source: .thisSession)
        }
        if let previousTime {
            return SetPrefill(weight: previousTime.weight, reps: Int(previousTime.reps.rounded()), source: .lastTime)
        }
        if targetWeight != nil || targetReps != nil {
            return SetPrefill(
                weight: targetWeight,
                reps: targetReps ?? 8,
                source: .target,
                isFirstTime: lastTime.isEmpty
            )
        }
        let slot = store.linkedObjects("slot", of: entry).first ?? exercise.flatMap { store.planSlot(for: $0) }
        let low = slot.flatMap { store.number("repMin", of: $0) }.map(Int.init)
            ?? exercise.flatMap { store.classValue("repMin", of: $0)?.numericValue }.map(Int.init) ?? 8
        return SetPrefill(weight: exercise.flatMap { store.startingWeight(for: $0) }, reps: low, source: .none,
                          isFirstTime: true)
    }
}

/// Logs the next set exactly as prefilled: the hold in live mode, and the Lock Screen's Done.
public struct LogNextSet: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logNextSet",
        summary: "Log the next set as prefilled",
        parameters: [
            .init("entry", .object, "The exercise entry"),
            .init("source", .string, "hold, lockScreen, tess or intent", required: false),
        ]
    )

    public var entry: UUID
    public var source: SetSource?

    public init(entry: UUID, source: SetSource? = .hold) {
        self.entry = entry
        self.source = source
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let entry = try transaction.object(entry, is: .exerciseEntry)
        let prefill = TrainingLedger(store: transaction.store, classes: transaction.classes).prefill(for: entry)
        guard let weight = prefill.weight else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "no weight to log yet")
        }
        return try LogSet(entry: entry.id, weight: weight, reps: Double(prefill.reps), source: source)
            .apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        guard let set = store.object(id: entry)?.orderedChildren.last,
              let weight = store.number("weight", of: set), let reps = store.number("reps", of: set)
        else { return "Logged a set" }
        return "Logged \(WorkoutProgress.format(weight)) × \(WorkoutProgress.format(reps))"
    }
}

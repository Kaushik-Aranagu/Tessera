import Foundation

/// "Repeat this" on a finished workout: today's workout with the same entries and targets, started now. Each entry
/// keeps its exercise, planned sets, reps and weight (a logged entry with no plan takes them from what was done: its
/// number of working sets, and the last working set's reps and weight). Nothing logged is copied. The routine link and
/// the title stay, so a workout that is private by its title or its routine is private when repeated.
public struct RepeatWorkout: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "repeatWorkout", summary: "Do a finished workout again",
        parameters: [
            .init("workout", .object, "The finished workout to repeat"),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var workout: UUID
    public var time: Date?

    public init(workout: UUID, time: Date? = nil) {
        self.workout = workout
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let source = try transaction.object(workout, is: .workout)
        let store = transaction.store
        guard store.value("endedAt", of: source) != nil else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that workout is not finished")
        }
        let ledger = TrainingLedger(store: store, classes: transaction.classes)
        let entries = source.orderedChildren.filter {
            !$0.isDeleted && $0.classDef?.id == transaction.classes[.exerciseEntry]?.id
                && store.value("skipped", of: $0) != .bool(true)
        }
        guard !entries.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that workout has no exercises")
        }
        let copy = try transaction.create(transaction.classDef(.workout), title: source.title)
        if let routine = store.linkedObjects("routine", of: source).first {
            try transaction.setLinks("routine", on: copy, to: [routine])
        }
        for entry in entries {
            guard let exercise = store.linkedClass("exercise", of: entry) else { continue }
            let done = entry.orderedChildren.compactMap(ledger.loggedSet)
            let made = try AddExercise(
                workout: copy.id, exercise: exercise.id,
                targetSets: store.number("targetSets", of: entry) ?? (done.isEmpty ? nil : Double(done.count)),
                targetReps: store.number("targetReps", of: entry) ?? done.last?.reps,
                targetWeight: store.number("targetWeight", of: entry) ?? done.last?.weight
            ).apply(&transaction)
            if let slot = store.linkedObjects("slot", of: entry).first {
                try transaction.setLinks("slot", on: made, to: [slot])
            }
        }
        try StartWorkout(workout: copy.id, time: time).apply(&transaction)
        return copy
    }

    /// A workout's name wherever a line says it: "Private workout" when it is private by title or routine.
    @MainActor
    private func name(of object: ObjectRecord, in store: ObjectStore,
                      classes: [SystemCatalog.Key: ClassDef]) -> String
    {
        ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) ?? object.title
    }

    public func summary(in _: ObjectStore) -> String {
        "Repeated a workout"
    }

    public func receipt(in store: ObjectStore, output copy: ObjectRecord) -> String? {
        let classes = PrivateWords.systemClasses(in: store.context)
        return "\(name(of: copy, in: store, classes: classes)), started"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

public extension ActionEngine {
    /// Starts today's workout from a finished one (the finished-workout page's "Repeat this"). A running workout is
    /// set aside the way any new workout sets it aside.
    @discardableResult
    func repeatWorkout(id: UUID, at time: Date? = nil, by actor: Actor = .user) throws -> ObjectRecord {
        try perform(RepeatWorkout(workout: id, time: time), by: actor).output
    }
}

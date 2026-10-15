import Foundation

// Routines, slots and plans.

public struct CreateRoutine: EngineAction {
    public static let descriptor = ActionDescriptor(name: "createRoutine", summary: "Create a routine", parameters: [
        .init("title", .string, "e.g. Push Day A"),
    ])

    public var title: String

    public init(title: String) {
        self.title = title
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "title is empty")
        }
        return try transaction.create(transaction.classDef(.routine), title: trimmed)
    }

    public func summary(in _: ObjectStore) -> String {
        "Created \(title)"
    }
}

/// Adds an exercise slot to the end of a routine.
public struct AddSlot: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addSlot",
        summary: "Add an exercise to a routine",
        parameters: [
            .init("routine", .object, "The routine"),
            .init("exercise", .classRef, "The exercise class"),
            .init("sets", .integer, "Working sets; defaults to 3", required: false),
            .init("repMin", .integer, "Bottom of the rep range", required: false),
            .init("repMax", .integer, "Top of the rep range", required: false),
            .init("targetRPE", .number, "Target RPE", required: false),
            .init("restSeconds", .integer, "Rest between sets", required: false),
            .init("progression", .string, "Rule such as dp(+2.5, 8, 12)", required: false),
        ]
    )

    public var routine: UUID
    public var exercise: UUID
    public var sets: Double?
    public var repMin: Double?
    public var repMax: Double?
    public var targetRPE: Double?
    public var restSeconds: Double?
    public var progression: String?

    public init(routine: UUID, exercise: UUID, sets: Double? = nil, repMin: Double? = nil, repMax: Double? = nil,
                targetRPE: Double? = nil, restSeconds: Double? = nil, progression: String? = nil)
    {
        self.routine = routine
        self.exercise = exercise
        self.sets = sets
        self.repMin = repMin
        self.repMax = repMax
        self.targetRPE = targetRPE
        self.restSeconds = restSeconds
        self.progression = progression
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = Self.descriptor.name
        if let progression, ProgressionRule(parsing: progression) == nil {
            throw ActionError.invalidArguments(action: name, reason: "progression must look like dp(+2.5, 8, 12)")
        }
        if let repMin, let repMax, repMin > repMax {
            throw ActionError.invalidArguments(action: name, reason: "repMin is above repMax")
        }
        if let sets, !(1 ... 20).contains(sets) {
            throw ActionError.invalidArguments(action: name, reason: "sets must be 1 to 20")
        }
        let routine = try transaction.object(routine, is: .routine)
        let exerciseClass = try transaction.exerciseClass(exercise)
        let slot = try transaction.create(transaction.classDef(.slot), parent: routine)
        try transaction.setClassLink("exercise", on: slot, to: exerciseClass)
        try transaction.set("sets", to: sets.map(FieldValue.number), on: slot)
        try transaction.set("repMin", to: repMin.map(FieldValue.number), on: slot)
        try transaction.set("repMax", to: repMax.map(FieldValue.number), on: slot)
        try transaction.set("targetRPE", to: targetRPE.map(FieldValue.number), on: slot)
        try transaction.set("restSeconds", to: restSeconds.map(FieldValue.duration), on: slot)
        try transaction.set("progression", to: progression.map(FieldValue.text), on: slot)
        return slot
    }

    public func summary(in store: ObjectStore) -> String {
        "Added \(store.classDef(id: exercise)?.name.lowercased() ?? "an exercise") to the routine"
    }
}

/// Starts today's workout from a routine: one entry per slot, prefilled with each slot's next target.
public struct StartRoutine: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "startRoutine",
        summary: "Start a workout from a routine",
        parameters: [
            .init("routine", .object, "The routine, e.g. Push Day A"),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var routine: UUID
    public var time: Date?

    public init(routine: UUID, time: Date? = nil) {
        self.routine = routine
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let routine = try transaction.object(routine, is: .routine)
        let ledger = TrainingLedger(store: transaction.store, classes: transaction.classes)
        let workout = try transaction.create(transaction.classDef(.workout), title: routine.title)
        try transaction.setLinks("routine", on: workout, to: [routine])
        for slot in routine.orderedChildren {
            guard let exercise = transaction.store.linkedClass("exercise", of: slot) else { continue }
            let target = ledger.nextTarget(for: exercise, slot: slot)
            let entry = try AddExercise(
                workout: workout.id, exercise: exercise.id,
                targetSets: transaction.store.number("sets", of: slot) ?? 3,
                targetReps: Double(target.reps), targetWeight: target.weight
            ).apply(&transaction)
            try transaction.setLinks("slot", on: entry, to: [slot])
        }
        try StartWorkout(workout: workout.id, time: time).apply(&transaction)
        return workout
    }

    public func summary(in store: ObjectStore) -> String {
        "Started \(store.object(id: routine)?.title ?? "the routine")"
    }
}

public struct CreatePlan: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "createPlan",
        summary: "Create a plan that cycles routines",
        parameters: [
            .init("title", .string, "e.g. Push Pull Legs"),
            .init("routines", .json, "Routine ids in cycle order"),
            .init("startsOn", .date, "First day", required: false),
        ]
    )

    public var title: String
    public var routines: [UUID]
    public var startsOn: Date?

    public init(title: String, routines: [UUID], startsOn: Date? = nil) {
        self.title = title
        self.routines = routines
        self.startsOn = startsOn
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        guard !routines.isEmpty else {
            throw ActionError.invalidArguments(
                action: Self.descriptor.name,
                reason: "a plan needs at least one routine"
            )
        }
        let objects = try routines.map { try transaction.object($0, is: .routine) }
        let plan = try transaction.create(transaction.classDef(.plan), title: title)
        try transaction.setLinks("routines", on: plan, to: objects)
        try transaction.set("startsOn", to: startsOn.map(FieldValue.date), on: plan)
        return plan
    }

    public func summary(in _: ObjectStore) -> String {
        "Created \(title)"
    }
}

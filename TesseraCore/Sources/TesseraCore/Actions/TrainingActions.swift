import Foundation

// Built-in actions for v1: workouts, sets and tasks. UI, Tess and App Intents all call these.

private func kilograms(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
}

private func count(_ value: Double) -> String {
    kilograms(value)
}

/// Logs one set into an exercise entry.
public struct LogSet: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logSet",
        summary: "Log one set in an exercise entry",
        parameters: [
            .init("entry", .object, "The exercise entry inside a workout"),
            .init("weight", .number, "Weight in kilograms"),
            .init("reps", .integer, "Repetitions"),
            .init("rpe", .number, "Rate of perceived exertion, 1 to 10", required: false),
            .init("isWarmup", .boolean, "A warm-up set, left out of records", required: false),
            .init("kind", .string, "warmup, working, drop or failure; defaults to working", required: false),
            .init("source", .string, "hold, dial, lockScreen, tess, manual or intent", required: false),
            .init("unit", .string, "kg or lb; the weight's unit, defaults to kg", required: false),
        ]
    )

    public var entry: UUID
    public var weight: Double
    public var reps: Double
    public var rpe: Double?
    public var isWarmup: Bool?
    public var kind: SetKind?
    public var source: SetSource?
    /// The unit `weight` is in; stored as kilograms either way.
    public var unit: MassUnit?
    /// When it was done, for a set logged into a past day's workout; now when nil. Off the descriptor.
    public var time: Date?

    public init(entry: UUID, weight: Double, reps: Double, rpe: Double? = nil, isWarmup: Bool? = nil,
                kind: SetKind? = nil, source: SetSource? = nil, unit: MassUnit? = nil, time: Date? = nil)
    {
        self.time = time
        self.entry = entry
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.kind = kind
        self.source = source
        self.unit = unit
    }

    var weightInKilograms: Double {
        (unit ?? .kilograms).toKilograms(weight)
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        try validateSet(weight: weightInKilograms, reps: reps, rpe: rpe, action: Self.descriptor.name)
        let entry = try transaction.object(entry, is: .exerciseEntry)
        let setKind = isWarmup == true ? .warmup : kind ?? .working
        let workout = try transaction.store.ancestor(of: entry, ofClass: transaction.classDef(.workout))
        // A record at the time it was logged (against history before this workout), kept on the set for good.
        let beatsRecord = setKind == .working && transaction.store.linkedClass("exercise", of: entry).map { exercise in
            !TrainingLedger(store: transaction.store, classes: transaction.classes)
                .recordsBeaten(weight: weightInKilograms, reps: reps, rpe: rpe, for: exercise,
                               excludingWorkout: workout?.id).isEmpty
        } ?? false
        let set = try transaction.create(transaction.classDef(.set), parent: entry)
        try transaction.set("weight", to: .mass(weightInKilograms), on: set)
        if let unit, unit != .kilograms {
            try transaction.set("enteredUnit", to: .choice(unit.rawValue), on: set)
        }
        try transaction.set("reps", to: .number(reps), on: set)
        try transaction.set("rpe", to: rpe.map(FieldValue.number), on: set)
        try transaction.set("loggedAt", to: .date(time ?? .now), on: set)
        if setKind != .working {
            try transaction.set("kind", to: .choice(setKind.rawValue), on: set)
        }
        if beatsRecord {
            try transaction.set("wasRecord", to: .bool(true), on: set)
        }
        try transaction.set("source", to: source.map { .choice($0.rawValue) }, on: set)
        if let workout {
            try transaction.touchWorkoutProcess(workout, at: time ?? .now)
        }
        return set
    }

    public func summary(in store: ObjectStore) -> String {
        let name = store.object(id: entry).flatMap { store.linkedClass("exercise", of: $0)?.name.lowercased() } ?? "set"
        let shown = unit.map { "\(kilograms(weight)) \($0.symbol)" } ?? kilograms(weight)
        return "Logged \(name) \(shown) × \(count(reps))"
    }
}

/// Changes a logged set. Nil arguments stay as they are; `clearRPE` removes the RPE.
public struct EditSet: EngineAction {
    public static let descriptor = ActionDescriptor(name: "editSet", summary: "Change a logged set", parameters: [
        .init("set", .object, "The set to change"),
        .init("weight", .number, "New weight in kilograms", required: false),
        .init("reps", .integer, "New repetitions", required: false),
        .init("rpe", .number, "New RPE", required: false),
        .init("clearRPE", .boolean, "True to remove the RPE", required: false),
    ])

    public var set: UUID
    public var weight: Double?
    public var reps: Double?
    public var rpe: Double?
    public var clearRPE: Bool?

    public init(set: UUID, weight: Double? = nil, reps: Double? = nil, rpe: Double? = nil, clearRPE: Bool? = nil) {
        self.set = set
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.clearRPE = clearRPE
    }

    public func apply(_ transaction: inout Transaction) throws {
        if clearRPE == true, rpe != nil {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "rpe and clearRPE together")
        }
        try validateSet(weight: weight ?? 0, reps: reps ?? 1, rpe: rpe, action: Self.descriptor.name)
        let set = try transaction.object(set, is: .set)
        if let weight {
            try transaction.set("weight", to: .mass(weight), on: set)
        }
        if let reps {
            try transaction.set("reps", to: .number(reps), on: set)
        }
        if clearRPE == true {
            try transaction.set("rpe", to: nil, on: set)
        } else if let rpe {
            try transaction.set("rpe", to: .number(rpe), on: set)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        guard let object = store.object(id: set), let weight = store.number("weight", of: object),
              let reps = store.number("reps", of: object) else { return "Changed a set" }
        return "Changed the set to \(kilograms(weight)) × \(count(reps))"
    }
}

/// Adds an exercise to a workout, with optional targets.
public struct AddExercise: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addExercise",
        summary: "Add an exercise to a workout",
        parameters: [
            .init("workout", .object, "The workout"),
            .init("exercise", .classRef, "The exercise class, e.g. Bench Press"),
            .init("targetSets", .integer, "Planned sets", required: false),
            .init("targetReps", .integer, "Planned reps per set", required: false),
            .init("targetWeight", .number, "Planned weight in kilograms", required: false),
        ]
    )

    public var workout: UUID
    public var exercise: UUID
    public var targetSets: Double?
    public var targetReps: Double?
    public var targetWeight: Double?

    public init(workout: UUID, exercise: UUID, targetSets: Double? = nil, targetReps: Double? = nil,
                targetWeight: Double? = nil)
    {
        self.workout = workout
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let workout = try transaction.object(workout, is: .workout)
        let exerciseClass = try transaction.exerciseClass(exercise)
        let entry = try transaction.create(transaction.classDef(.exerciseEntry), parent: workout)
        try transaction.setClassLink("exercise", on: entry, to: exerciseClass)
        try transaction.set("targetSets", to: targetSets.map(FieldValue.number), on: entry)
        try transaction.set("targetReps", to: targetReps.map(FieldValue.number), on: entry)
        try transaction.set("targetWeight", to: targetWeight.map(FieldValue.mass), on: entry)
        return entry
    }

    public func summary(in store: ObjectStore) -> String {
        "Added \(store.classDef(id: exercise)?.name.lowercased() ?? "an exercise")"
    }
}

/// Starts a workout (or resumes the clock on one already started).
public struct StartWorkout: EngineAction {
    public static let descriptor = ActionDescriptor(name: "startWorkout", summary: "Start a workout", parameters: [
        .init("workout", .object, "The workout to start"),
        .init("time", .date, "When it started; defaults to now", required: false),
    ])

    public var workout: UUID
    public var time: Date?

    public init(workout: UUID, time: Date? = nil) {
        self.workout = workout
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let workout = try transaction.object(workout, is: .workout)
        let now = time ?? .now
        if transaction.store.value("startedAt", of: workout) == nil {
            try transaction.set("startedAt", to: .date(now), on: workout)
        }
        let progress = WorkoutProgress(of: workout, store: transaction.store)
        _ = try StartProcess(subject: workout.id, ownerApp: "Workouts", nextStep: progress.nextStep,
                             resumePoint: progress.resumePoint, time: now).apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "Started \(store.object(id: workout).map { store.displayTitle(of: $0) } ?? "the workout")"
    }
}

public struct FinishWorkout: EngineAction {
    public static let descriptor = ActionDescriptor(name: "finishWorkout", summary: "Finish a workout", parameters: [
        .init("workout", .object, "The workout to finish"),
        .init("time", .date, "When it ended; defaults to now", required: false),
    ])

    public var workout: UUID
    public var time: Date?

    public init(workout: UUID, time: Date? = nil) {
        self.workout = workout
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let workout = try transaction.object(workout, is: .workout)
        let end = time ?? .now
        if transaction.store.value("startedAt", of: workout) == nil {
            try transaction.set("startedAt", to: .date(end), on: workout)
        }
        try transaction.set("endedAt", to: .date(end), on: workout)
        if let process = transaction.openProcess(for: workout) {
            try transaction.end(process, reason: .done, at: end)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "Finished \(store.object(id: workout).map { store.displayTitle(of: $0) } ?? "the workout")"
    }
}

/// Finishes a workout early: entries with no logged sets are marked skipped (kept, so the plan stays visible),
/// then it finishes as usual. One undo restores both.
public struct FinishWorkoutEarly: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "finishWorkoutEarly",
        summary: "Finish a workout now, skipping the exercises not started",
        parameters: [
            .init("workout", .object, "The workout to finish"),
            .init("time", .date, "When it ended; defaults to now", required: false),
        ]
    )

    public var workout: UUID
    public var time: Date?

    public init(workout: UUID, time: Date? = nil) {
        self.workout = workout
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> [UUID] {
        let workout = try transaction.object(workout, is: .workout)
        let ledger = TrainingLedger(store: transaction.store, classes: transaction.classes)
        var skipped: [UUID] = []
        for entry in workout.orderedChildren where entry.orderedChildren.compactMap(ledger.loggedSet).isEmpty {
            try transaction.set("skipped", to: .bool(true), on: entry)
            skipped.append(entry.id)
        }
        try FinishWorkout(workout: workout.id, time: time).apply(&transaction)
        return skipped
    }

    public func summary(in store: ObjectStore) -> String {
        "Finished \(store.object(id: workout).map { store.displayTitle(of: $0) } ?? "the workout") early"
    }
}

/// Quick Capture for training ("3x10 bench 80"): logs sets into the workout in progress, creating what's missing.
public struct LogExercise: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logExercise",
        summary: "Log sets of an exercise into the workout in progress, starting one if needed",
        parameters: [
            .init("exercise", .classRef, "The exercise class, e.g. Bench Press"),
            .init("weight", .number, "Weight in kilograms"),
            .init("reps", .integer, "Repetitions per set"),
            .init("sets", .integer, "How many sets; defaults to 1", required: false),
            .init("unit", .string, "kg or lb; defaults to kg", required: false),
        ]
    )

    public var exercise: UUID
    public var weight: Double
    public var reps: Double
    public var sets: Int?
    public var unit: MassUnit?
    /// A past day ("bench 80x8 mon"): the sets go into that day's finished workout, made if there is none. Kept off
    /// the descriptor, so the model's tool stays today-only.
    public var on: Date?

    public init(exercise: UUID, weight: Double, reps: Double, sets: Int? = nil, unit: MassUnit? = nil,
                on: Date? = nil)
    {
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.unit = unit
        self.on = on
    }

    public func apply(_ transaction: inout Transaction) throws -> [ObjectRecord] {
        let count = sets ?? 1
        guard (1 ... 20).contains(count) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "sets must be 1 to 20")
        }
        try validateSet(weight: (unit ?? .kilograms).toKilograms(weight), reps: reps, rpe: nil,
                        action: Self.descriptor.name)
        let exerciseClass = try transaction.exerciseClass(exercise)
        let workout = try on.map { try pastWorkout(on: $0, &transaction) } ?? activeWorkout(&transaction)
        let entry = try workout.orderedChildren
            .last { transaction.store.linkedClass("exercise", of: $0)?.id == exercise }
            ?? AddExercise(workout: workout.id, exercise: exerciseClass.id).apply(&transaction)
        // A past day's sets are stamped on that day (QA D2): at the workout's end, so they never sit before an evening
        // session's start (QA P2).
        let store = transaction.store
        let stamp = on.map { store.value("endedAt", of: workout)?.dateValue ?? store.value("startedAt", of: workout)?
            .dateValue ?? $0
        }
        return try (0 ..< count).map { _ in
            try LogSet(entry: entry.id, weight: weight, reps: reps, unit: unit, time: stamp).apply(&transaction)
        }
    }

    /// That day's workout (by his 4 AM day), or a new one started and ended at `day` (Tess passes noon), with
    /// no process.
    @MainActor private func pastWorkout(on day: Date, _ transaction: inout Transaction) throws -> ObjectRecord {
        let store = transaction.store
        let workoutClass = try transaction.classDef(.workout)
        let tessera = TesseraDay(calendar: .current)
        let key = tessera.day(of: day)
        // Finished or not (one left open that day is matched too, QA D1); of two that day, the one that already has
        // this exercise (QA P1).
        let sameDay = store.objects(of: workoutClass).filter {
            guard let started = store.value("startedAt", of: $0)?.dateValue else { return false }
            return tessera.day(of: started) == key
        }
        let withExercise = sameDay.last { workout in
            workout.orderedChildren.contains { store.linkedClass("exercise", of: $0)?.id == exercise }
        }
        if let found = withExercise ?? sameDay.last {
            return found
        }
        let workout = transaction.create(workoutClass, title: "Workout")
        try transaction.set("startedAt", to: .date(day), on: workout)
        try transaction.set("endedAt", to: .date(day), on: workout)
        return workout
    }

    @MainActor private func activeWorkout(_ transaction: inout Transaction) throws -> ObjectRecord {
        let store = transaction.store
        let workoutClass = try transaction.classDef(.workout)
        let inProgress = store.objects(of: workoutClass).last {
            store.value("startedAt", of: $0) != nil && store.value("endedAt", of: $0) == nil
        }
        if let inProgress {
            return inProgress
        }
        let workout = transaction.create(workoutClass, title: "Workout")
        try StartWorkout(workout: workout.id).apply(&transaction)
        return workout
    }

    public func summary(in store: ObjectStore) -> String {
        let name = store.classDef(id: exercise)?.name.lowercased() ?? "exercise"
        return "Logged \(name) \(sets ?? 1)×\(count(reps)) at \(kilograms(weight)) \((unit ?? .kilograms).symbol)"
    }
}

// MARK: Tasks

public struct CreateTask: EngineAction {
    public static let descriptor = ActionDescriptor(name: "createTask", summary: "Create a task", parameters: [
        .init("title", .string, "What to do"),
        .init("startsAt", .date, "When to do it", required: false),
        .init("minutes", .integer, "How long it takes", required: false),
        .init("due", .date, "Deadline", required: false),
        // `about` (ids, e.g. a recipe) stays off the descriptor so the model's createTask tool keeps a flat schema.
    ])

    public var title: String
    public var startsAt: Date?
    public var minutes: Double?
    public var due: Date?
    public var about: [UUID]?

    public init(title: String, startsAt: Date? = nil, minutes: Double? = nil, due: Date? = nil, about: [UUID]? = nil) {
        self.title = title
        self.startsAt = startsAt
        self.minutes = minutes
        self.due = due
        self.about = about
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "title is empty")
        }
        if let minutes, minutes <= 0 {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "minutes must be positive")
        }
        let task = try transaction.create(transaction.classDef(.task), title: trimmed)
        try transaction.set("startsAt", to: startsAt.map(FieldValue.date), on: task)
        try transaction.set("length", to: minutes.map { .duration($0 * 60) }, on: task)
        try transaction.set("due", to: due.map(FieldValue.date), on: task)
        if let about, !about.isEmpty {
            try transaction.setLinks("about", on: task, to: about.map { try transaction.object($0) })
        }
        return task
    }

    public func summary(in _: ObjectStore) -> String {
        "Added “\(title.trimmingCharacters(in: .whitespacesAndNewlines))”"
    }
}

public struct SetTaskDone: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setTaskDone",
        summary: "Finish a task, or reopen it",
        parameters: [
            .init("task", .object, "The task"),
            .init("done", .boolean, "True to finish, false to reopen", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var task: UUID
    public var done: Bool?
    /// When it was done; the app passes its clock (so `-demoTime` and fixtures hold).
    public var time: Date?

    public init(task: UUID, done: Bool? = true, time: Date? = nil) {
        self.time = time
        self.task = task
        self.done = done
    }

    public func apply(_ transaction: inout Transaction) throws {
        let task = try transaction.object(task, is: .task)
        let isDone = done ?? true
        try transaction.set("isDone", to: .bool(isDone), on: task)
        try transaction.set("doneAt", to: isDone ? .date(time ?? .now) : nil, on: task)
        try transaction.endTaskProcess(task, done: isDone)
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: task)?.title ?? "the task"
        return done ?? true ? "Done: \(title)" : "Reopened \(title)"
    }
}

// MARK: Generic

public struct RenameObject: EngineAction {
    public static let descriptor = ActionDescriptor(name: "renameObject", summary: "Rename an object", parameters: [
        .init("object", .object, "The object"),
        .init("title", .string, "The new name"),
    ])

    public var object: UUID
    public var title: String

    public init(object: UUID, title: String) {
        self.object = object
        self.title = title
    }

    public func apply(_ transaction: inout Transaction) throws {
        try transaction.setTitle(title, on: transaction.object(object))
    }

    public func summary(in _: ObjectStore) -> String {
        "Renamed to “\(title)”"
    }
}

/// Deletes an object and everything inside it. Recoverable with undo.
public struct DeleteObject: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "deleteObject",
        summary: "Delete an object and everything inside it",
        parameters: [.init("object", .object, "The object to delete")],
        isDestructive: true
    )

    public var object: UUID

    public init(object: UUID) {
        self.object = object
    }

    public func apply(_ transaction: inout Transaction) throws {
        try transaction.delete(transaction.object(object))
    }

    public func summary(in store: ObjectStore) -> String {
        "Deleted \(store.object(id: object).map { store.displayTitle(of: $0) } ?? "it")"
    }
}

// MARK: Helpers

private func validateSet(weight: Double, reps: Double, rpe: Double?, action: String) throws {
    guard weight >= 0, weight <= 1000 else {
        throw ActionError.invalidArguments(action: action, reason: "weight must be 0 to 1000 kg")
    }
    guard reps >= 1, reps <= 100, reps.rounded() == reps else {
        throw ActionError.invalidArguments(action: action, reason: "reps must be a whole number from 1 to 100")
    }
    if let rpe, !(1 ... 10).contains(rpe) {
        throw ActionError.invalidArguments(action: action, reason: "rpe must be 1 to 10")
    }
}

extension Transaction {
    /// An exercise class (Bench Press or any other subclass of Exercise).
    func exerciseClass(_ id: UUID) throws -> ClassDef {
        guard let classDef = store.classDef(id: id) else { throw ActionError.objectNotFound(id) }
        guard try ClassResolver.isSubclass(classDef, of: self.classDef(.exercise)) else {
            throw ActionError.wrongClass(id, expected: SystemCatalog.Key.exercise.rawValue)
        }
        return classDef
    }
}

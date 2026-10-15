import Foundation

// Routine editing (ship list slice 10): reorder, change, remove and swap slots. Add uses `AddSlot`, rename uses
// `RenameObject`. All undoable.

/// Moves a slot to a new position in its routine (0-based); the others close up around it.
public struct MoveSlot: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "moveSlot",
        summary: "Move an exercise within a routine",
        parameters: [
            .init("slot", .object, "The slot"),
            .init("toIndex", .integer, "New position, starting at 0"),
        ]
    )

    public var slot: UUID
    public var toIndex: Int

    public init(slot: UUID, toIndex: Int) {
        self.slot = slot
        self.toIndex = toIndex
    }

    public func apply(_ transaction: inout Transaction) throws {
        let slot = try transaction.object(slot, is: .slot)
        guard let routine = slot.parent else { return }
        var order = routine.orderedChildren.filter { $0.id != slot.id }
        order.insert(slot, at: min(max(toIndex, 0), order.count))
        for (index, sibling) in order.enumerated() {
            transaction.setSortIndex(index, on: sibling)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        let name = store.object(id: slot).flatMap { store.linkedClass("exercise", of: $0)?.name } ?? "Exercise"
        return "Moved \(name) to \(toIndex + 1)"
    }
}

/// Changes a slot's sets, rep range, rest or progression. Nil arguments stay as they are.
public struct EditSlot: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "editSlot",
        summary: "Change an exercise's sets and reps in a routine",
        parameters: [
            .init("slot", .object, "The slot"),
            .init("sets", .integer, "Working sets", required: false),
            .init("repMin", .integer, "Bottom of the rep range", required: false),
            .init("repMax", .integer, "Top of the rep range", required: false),
            .init("restSeconds", .integer, "Rest between sets", required: false),
            .init("progression", .string, "Rule such as dp(+2.5, 8, 12)", required: false),
        ]
    )

    public var slot: UUID
    public var sets: Double?
    public var repMin: Double?
    public var repMax: Double?
    public var restSeconds: Double?
    public var progression: String?

    public init(slot: UUID, sets: Double? = nil, repMin: Double? = nil, repMax: Double? = nil,
                restSeconds: Double? = nil, progression: String? = nil)
    {
        self.slot = slot
        self.sets = sets
        self.repMin = repMin
        self.repMax = repMax
        self.restSeconds = restSeconds
        self.progression = progression
    }

    public func apply(_ transaction: inout Transaction) throws {
        let name = Self.descriptor.name
        let slot = try transaction.object(slot, is: .slot)
        let low = repMin ?? transaction.store.number("repMin", of: slot)
        let high = repMax ?? transaction.store.number("repMax", of: slot)
        if let low, let high, low > high {
            throw ActionError.invalidArguments(action: name, reason: "repMin is above repMax")
        }
        if let sets, !(1 ... 20).contains(sets) {
            throw ActionError.invalidArguments(action: name, reason: "sets must be 1 to 20")
        }
        if let progression, ProgressionRule(parsing: progression) == nil {
            throw ActionError.invalidArguments(action: name, reason: "progression must look like dp(+2.5, 8, 12)")
        }
        if let sets {
            try transaction.set("sets", to: .number(sets), on: slot)
        }
        if let repMin {
            try transaction.set("repMin", to: .number(repMin), on: slot)
        }
        if let repMax {
            try transaction.set("repMax", to: .number(repMax), on: slot)
        }
        if let restSeconds {
            try transaction.set("restSeconds", to: .duration(restSeconds), on: slot)
        }
        if let progression {
            try transaction.set("progression", to: .text(progression), on: slot)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        guard let object = store.object(id: slot) else { return "Changed the routine" }
        let name = store.linkedClass("exercise", of: object)?.name ?? "Exercise"
        let sets = store.number("sets", of: object).map(WorkoutProgress.format) ?? "3"
        let low = store.number("repMin", of: object).map(WorkoutProgress.format)
        let high = store.number("repMax", of: object).map(WorkoutProgress.format)
        let reps = [low, high].compactMap(\.self).joined(separator: "–")
        return reps.isEmpty ? "\(name): \(sets) sets" : "\(name): \(sets) × \(reps)"
    }
}

/// Removes a slot from its routine; the others close up. Past workouts keep their sets. Undo puts it back in place.
public struct RemoveSlot: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "removeSlot",
        summary: "Remove an exercise from a routine",
        parameters: [.init("slot", .object, "The slot")],
        isDestructive: true
    )

    public var slot: UUID

    public init(slot: UUID) {
        self.slot = slot
    }

    public func apply(_ transaction: inout Transaction) throws {
        let slot = try transaction.object(slot, is: .slot)
        let siblings = slot.parent?.orderedChildren.filter { $0.id != slot.id } ?? []
        transaction.delete(slot)
        for (index, sibling) in siblings.enumerated() {
            transaction.setSortIndex(index, on: sibling)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        let name = store.object(id: slot).flatMap { store.linkedClass("exercise", of: $0)?.name } ?? "the exercise"
        return "Removed \(name)"
    }
}

/// Replaces a slot's exercise (keeps its sets, reps and rule).
public struct SwapSlotExercise: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "swapSlotExercise",
        summary: "Swap the exercise in a routine slot",
        parameters: [
            .init("slot", .object, "The slot"),
            .init("exercise", .classRef, "The new exercise"),
        ]
    )

    public var slot: UUID
    public var exercise: UUID

    public init(slot: UUID, exercise: UUID) {
        self.slot = slot
        self.exercise = exercise
    }

    public func apply(_ transaction: inout Transaction) throws {
        let slot = try transaction.object(slot, is: .slot)
        try transaction.setClassLink("exercise", on: slot, to: transaction.exerciseClass(exercise))
    }

    public func summary(in store: ObjectStore) -> String {
        "Swapped in \(store.classDef(id: exercise)?.name ?? "an exercise")"
    }
}

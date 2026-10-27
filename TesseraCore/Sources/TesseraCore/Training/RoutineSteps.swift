import Foundation

/// The steps of a routine mode (sheets 323 and 329: "Evening": Tidy, Stretch, Read, Journal, Lights). A step is a child
/// of its routine, with minutes; a move is a child of its step, with seconds, a one-line cue and, if wanted, a breath
/// in
/// words ("in", "out", "in/out", never a pace). The words a screen shows are the routine's own, so a private routine
/// shows none of them. This file reads; `AddRoutineStep` and `EditRoutineStep` write.
public struct RoutineMove: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let move: String
    public let seconds: Int
    public let cue: String?
    public let breath: String?
}

public struct RoutineStep: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let minutes: Int
    public let moves: [RoutineMove]
    public let cue: String?
    public let breath: String?

    /// The step's time in seconds: its moves added up when it has them, else its minutes.
    public var seconds: Int {
        moves.isEmpty ? minutes * 60 : moves.reduce(0) { $0 + $1.seconds }
    }
}

@MainActor
public struct RoutineSteps {
    public static let minutesRange = 1 ... 120
    public static let secondsRange = 5 ... 3600
    public static let wordLimit = 40
    public static let cueLimit = 100

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// The routine's steps in order, or none for a private routine (it shows as "Private workout").
    public func steps(of routine: ObjectRecord) -> [RoutineStep] {
        guard ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) == nil,
              let stepClass = classes[.routineStep] else { return [] }
        func isStep(_ object: ObjectRecord) -> Bool {
            !object.isDeleted && object.classDef?.id == stepClass.id
        }
        return routine.orderedChildren.filter(isStep).map { step in
            let moves = step.orderedChildren.filter(isStep).map { move in
                RoutineMove(id: move.id, move: text("move", move) ?? move.title,
                            seconds: store.number("seconds", of: move).map { Int($0) } ?? 0,
                            cue: text("cue", move), breath: text("breath", move))
            }
            return RoutineStep(id: step.id, title: step.title,
                               minutes: store.number("minutes", of: step).map { Int($0) } ?? 0, moves: moves,
                               cue: text("cue", step), breath: text("breath", step))
        }
    }

    /// The whole routine in minutes, to the nearest minute ("about 32 min to bed").
    public func totalMinutes(of routine: ObjectRecord) -> Int {
        let seconds = steps(of: routine).reduce(0) { $0 + $1.seconds }
        return Int((Double(seconds) / 60).rounded())
    }

    /// How dark the dusk is after `tended` of `total` steps: 0 at the start, 1 once the last is tended ("by Lights it's
    /// night"). A step left for tomorrow does not darken it.
    public static func dusk(tended: Int, of total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(max(Double(tended) / Double(total), 0), 1)
    }

    private func text(_ key: String, _ object: ObjectRecord) -> String? {
        let value = store.value(key, of: object)?.stringValue?.trimmingCharacters(in: .whitespaces)
        return value?.isEmpty == false ? value : nil
    }
}

/// Adds a step to a routine, or a move to a step. Words are checked the way a warm-up's are: nothing that holds a
/// secret
/// word, a body fact or a key.
public struct AddRoutineStep: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addRoutineStep", summary: "Add a step to a routine, or a move to a step",
        parameters: [
            .init("parent", .object, "The routine, or the step a move belongs to"),
            .init("title", .string, "e.g. Stretch, or Hips for a move"),
            .init("minutes", .integer, "A step's minutes, 1 to 120", required: false),
            .init("seconds", .integer, "A move's seconds, 5 to 3600", required: false),
            .init("cue", .string, "One line in Tess's voice", required: false),
            .init("breath", .string, "in, out or in/out", required: false),
        ], isOfferedToModel: false
    )

    public var parent: UUID
    public var title: String
    public var minutes: Int?
    public var seconds: Int?
    public var cue: String?
    public var breath: String?

    public init(parent: UUID, title: String, minutes: Int? = nil, seconds: Int? = nil, cue: String? = nil,
                breath: String? = nil)
    {
        self.parent = parent
        self.title = title
        self.minutes = minutes
        self.seconds = seconds
        self.cue = cue
        self.breath = breath
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let owner = try transaction.object(parent)
        let stepClass = try transaction.classDef(.routineStep)
        let isRoutine = owner.classDef.map { classDef in
            transaction.classes[.routine].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        } ?? false
        let isStep = owner.classDef?.id == stepClass.id
        guard isRoutine || isStep else {
            throw ActionError.wrongClass(parent, expected: "routine or step")
        }
        let object = transaction.create(stepClass, title: "", parent: owner)
        try EditRoutineStep.write(title: title, minutes: minutes, seconds: seconds, cue: cue, breath: breath,
                                  on: object, in: &transaction, action: Self.descriptor.name, isMove: isStep)
        return object
    }

    public func summary(in _: ObjectStore) -> String {
        "Added \(title)"
    }

    public func receipt(in _: ObjectStore, output step: ObjectRecord) -> String? {
        "\(step.title) added"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Changes a step or a move: a field left out stays; an empty cue or breath takes it off.
public struct EditRoutineStep: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "editRoutineStep", summary: "Change a step or a move",
        parameters: [
            .init("step", .object, "The step or move"),
            .init("title", .string, "A new name", required: false),
            .init("minutes", .integer, "1 to 120", required: false),
            .init("seconds", .integer, "5 to 3600", required: false),
            .init("cue", .string, "One line; empty takes it off", required: false),
            .init("breath", .string, "in, out or in/out; empty takes it off", required: false),
        ], isOfferedToModel: false
    )

    public var step: UUID
    public var title: String?
    public var minutes: Int?
    public var seconds: Int?
    public var cue: String?
    public var breath: String?

    public init(step: UUID, title: String? = nil, minutes: Int? = nil, seconds: Int? = nil, cue: String? = nil,
                breath: String? = nil)
    {
        self.step = step
        self.title = title
        self.minutes = minutes
        self.seconds = seconds
        self.cue = cue
        self.breath = breath
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(step, is: .routineStep)
        let isMove = object.parent?.classDef?.id == transaction.classes[.routineStep]?.id
        try Self.write(title: title, minutes: minutes, seconds: seconds, cue: cue, breath: breath, on: object,
                       in: &transaction, action: Self.descriptor.name, isMove: isMove)
    }

    public func summary(in store: ObjectStore) -> String {
        "Changed \(store.object(id: step)?.title ?? "a step")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: step).map { "\($0.title) changed" }
    }

    /// The one writer, with the checks. Nil leaves a field alone.
    @MainActor
    static func write(title: String?, minutes: Int?, seconds: Int?, cue: String?, breath: String?,
                      on object: ObjectRecord, in transaction: inout Transaction, action: String, isMove: Bool) throws
    {
        func refuse(_ reason: String) -> ActionError {
            .invalidArguments(action: action, reason: "refused: \(reason)")
        }
        let last = BodyWeight.lastKg(in: transaction.store)
        func clean(_ text: String?, limit: Int) throws -> String? {
            guard let text else { return nil }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= limit, !looksLikeClaudeKey(trimmed),
                  !ObjectPrivacy.isPrivateTitle(trimmed, lastWeightKg: last) else { throw refuse("words") }
            return trimmed
        }
        if let title {
            let name = try clean(title, limit: RoutineSteps.wordLimit) ?? ""
            guard !name.isEmpty else { throw refuse("title") }
            transaction.setTitle(name, on: object)
        }
        if let minutes {
            guard !isMove, RoutineSteps.minutesRange.contains(minutes) else { throw refuse("minutes") }
            try transaction.set("minutes", to: .number(Double(minutes)), on: object)
        }
        if let seconds {
            guard isMove, RoutineSteps.secondsRange.contains(seconds) else { throw refuse("seconds") }
            try transaction.set("seconds", to: .number(Double(seconds)), on: object)
        }
        if let cue {
            let line = try clean(cue, limit: RoutineSteps.cueLimit) ?? ""
            try transaction.set("cue", to: line.isEmpty ? nil : .text(line), on: object)
        }
        if let breath {
            let word = breath.trimmingCharacters(in: .whitespaces).lowercased()
            guard word.isEmpty || ["in", "out", "in/out"].contains(word) else { throw refuse("breath") }
            try transaction.set("breath", to: word.isEmpty ? nil : .choice(word), on: object)
        }
    }
}

/// A sample evening for Sample data and the tests (sheet 323): five steps, the stretch with three moves.
@MainActor
public enum RoutineSample {
    @discardableResult
    public static func evening(in engine: ActionEngine, by actor: Actor = .system) throws -> ObjectRecord {
        let routine = try engine.perform(CreateRoutine(title: "Evening"), by: actor).output
        func step(_ title: String, _ minutes: Int, cue: String? = nil) throws -> ObjectRecord {
            try engine.perform(AddRoutineStep(parent: routine.id, title: title, minutes: minutes, cue: cue),
                               by: actor).output
        }
        try step("Tidy", 5, cue: "Only what is in your way")
        let stretch = try step("Stretch", 6)
        for (move, seconds, cue, breath) in [("Hips", 120, "Knee over ankle, breathe out", "out"),
                                             ("Shoulders", 120, "Let them drop on the out breath", "in/out"),
                                             ("Neck", 120, "Slow, no pushing", "in")]
        {
            try engine.perform(AddRoutineStep(parent: stretch.id, title: move, seconds: seconds, cue: cue,
                                              breath: breath), by: actor)
        }
        try step("Read", 15, cue: "A few pages, nothing for work")
        try step("Journal", 5, cue: "Three lines is plenty")
        try step("Lights", 1, cue: "Phone across the room")
        return routine
    }
}

import Foundation

// Process lifecycle actions. All of them go through the op log, so context saves sync and can be undone.

/// Starts (or resumes) the process for a subject. Any other running process is suspended: one thing is Now.
public struct StartProcess: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "startProcess",
        summary: "Start working on something",
        parameters: [
            .init("subject", .object, "The object being worked on"),
            .init("ownerApp", .string, "The app it belongs to", required: false),
            .init("nextStep", .string, "One line, verb first", required: false),
            .init("resumePoint", .json, "Where to land on resume", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var subject: UUID
    public var ownerApp: String?
    public var nextStep: String?
    public var resumePoint: ResumePoint?
    public var time: Date?

    public init(subject: UUID, ownerApp: String? = nil, nextStep: String? = nil, resumePoint: ResumePoint? = nil,
                time: Date? = nil)
    {
        self.subject = subject
        self.ownerApp = ownerApp
        self.nextStep = nextStep
        self.resumePoint = resumePoint
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let subject = try transaction.object(subject)
        let now = time ?? .now
        let existing = transaction.openProcess(for: subject)
        try transaction.refuseWhileWorkoutRuns(except: existing?.id, action: Self.descriptor.name)
        if let existing {
            try transaction.makeRunning(existing, at: now)
            try transaction.saveContext(existing, resumePoint: resumePoint, nextStep: nextStep, at: now)
            return existing
        }
        try transaction.suspendRunning(except: nil, at: now)
        let process = try transaction.create(transaction.classDef(.process), title: subject.title)
        try transaction.setLinks("subject", on: process, to: [subject])
        try transaction.set("ownerApp", to: ownerApp.map(FieldValue.text), on: process)
        try transaction.set("state", to: .choice(ProcessState.running.rawValue), on: process)
        try transaction.set("startedAt", to: .date(now), on: process)
        try transaction.saveContext(process, resumePoint: resumePoint, nextStep: nextStep, at: now)
        return process
    }

    public func summary(in store: ObjectStore) -> String {
        "Started \(store.object(id: subject).map { store.displayTitle(of: $0) } ?? "it")"
    }
}

/// Saves where you are without changing state (called on every context switch).
public struct SaveContext: EngineAction {
    public static let descriptor = ActionDescriptor(name: "saveContext", summary: "Save where you are", parameters: [
        .init("process", .object, "The process"),
        .init("resumePoint", .json, "Where to land on resume", required: false),
        .init("nextStep", .string, "One line, verb first", required: false),
        .init("time", .date, "Defaults to now", required: false),
    ])

    public var process: UUID
    public var resumePoint: ResumePoint?
    public var nextStep: String?
    public var time: Date?

    public init(process: UUID, resumePoint: ResumePoint? = nil, nextStep: String? = nil, time: Date? = nil) {
        self.process = process
        self.resumePoint = resumePoint
        self.nextStep = nextStep
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let process = try transaction.object(process, is: .process)
        try transaction.saveContext(process, resumePoint: resumePoint, nextStep: nextStep, at: time ?? .now)
    }

    public func summary(in _: ObjectStore) -> String {
        "Saved your place"
    }
}

/// Leaves a process mid-way; it stays one tap from resuming.
public struct SuspendProcess: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "suspendProcess",
        summary: "Pause something mid-way",
        parameters: [
            .init("process", .object, "The process"),
            .init("resumePoint", .json, "Where to land on resume", required: false),
            .init("nextStep", .string, "One line, verb first", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var process: UUID
    public var resumePoint: ResumePoint?
    public var nextStep: String?
    public var time: Date?

    public init(process: UUID, resumePoint: ResumePoint? = nil, nextStep: String? = nil, time: Date? = nil) {
        self.process = process
        self.resumePoint = resumePoint
        self.nextStep = nextStep
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let process = try transaction.object(process, is: .process)
        let now = time ?? .now
        try transaction.saveContext(process, resumePoint: resumePoint, nextStep: nextStep, at: now)
        try transaction.set("state", to: .choice(ProcessState.suspended.rawValue), on: process)
    }

    public func summary(in store: ObjectStore) -> String {
        "Paused \(store.object(id: process)?.title ?? "it")"
    }
}

/// Picks a suspended, waiting or put-away process back up. Whatever was running is suspended.
public struct ResumeProcess: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "resumeProcess",
        summary: "Pick something back up",
        parameters: [
            .init("process", .object, "The process"),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var process: UUID
    public var time: Date?

    public init(process: UUID, time: Date? = nil) {
        self.process = process
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let process = try transaction.object(process, is: .process)
        let now = time ?? .now
        try transaction.refuseWhileWorkoutRuns(except: process.id, action: Self.descriptor.name)
        try transaction.makeRunning(process, at: now)
        try transaction.set("lastTouchedAt", to: .date(now), on: process)
    }

    public func summary(in store: ObjectStore) -> String {
        "Back to \(store.object(id: process)?.title ?? "it")"
    }
}

/// Ends a process: finished, closed by hand, put away to Later, or wrapped up.
public struct EndProcess: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "endProcess",
        summary: "Finish or put away something",
        parameters: [
            .init("process", .object, "The process"),
            .init("reason", .string, "done, closed, putAway or wrappedUp"),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var process: UUID
    public var reason: ProcessEndReason
    public var time: Date?

    public init(process: UUID, reason: ProcessEndReason, time: Date? = nil) {
        self.process = process
        self.reason = reason
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let process = try transaction.object(process, is: .process)
        try transaction.end(process, reason: reason, at: time ?? .now)
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: process)?.title ?? "it"
        return switch reason {
        case .done, .wrappedUp: "Finished \(title)"
        case .closed: "Closed \(title)"
        case .putAway: "Put \(title) away"
        }
    }
}

/// The empty wrap-up as one step (QA P1): the process ends and the workout with no sets goes, in one op record, so
/// UNDO brings both back. Undoing only the delete left an open workout with no process that caught later sets unseen.
public struct DiscardEmptyWorkout: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "discardEmptyWorkout",
        summary: "Close a workout with no sets without saving it",
        parameters: [
            .init("process", .object, "The workout's process"),
            .init("workout", .object, "The workout"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isDestructive: true
    )

    public var process: UUID
    public var workout: UUID
    public var time: Date?

    public init(process: UUID, workout: UUID, time: Date? = nil) {
        self.process = process
        self.workout = workout
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        try EndProcess(process: process, reason: .wrappedUp, time: time).apply(&transaction)
        try DeleteObject(object: workout).apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: workout).map { store.displayTitle(of: $0) } ?? "Workout"), no sets, not saved"
    }
}

// MARK: Transaction helpers

extension Transaction {
    func processState(_ process: ObjectRecord) -> ProcessState {
        store.value("state", of: process)?.stringValue.flatMap(ProcessState.init(rawValue:)) ?? .running
    }

    func openProcess(for subject: ObjectRecord) -> ObjectRecord? {
        store.backlinks(to: subject).last { source in
            source.classDef?.id == classes[.process]?.id && processState(source).isOpen
        }
    }

    /// A running workout is never suspended by starting or resuming anything else (gap hunt G56, QA on #783): refuse
    /// with the Cook key's line, and write nothing.
    func refuseWhileWorkoutRuns(except keep: UUID?, action: String) throws {
        guard let workoutClass = classes[.workout], let processClass = classes[.process] else { return }
        let running = store.objects(of: processClass).contains { process in
            process.id != keep && processState(process) == .running
                && store.linkedObjects("subject", of: process).first?.classDef
                .map { ClassResolver.isSubclass($0, of: workoutClass) } == true
        }
        if running {
            throw ActionError.invalidArguments(action: action, reason: StartCooking.workoutRunningReason)
        }
    }

    mutating func suspendRunning(except keep: UUID?, at now: Date) throws {
        guard let processClass = classes[.process] else { return }
        for process in store.objects(of: processClass)
            where process.id != keep && processState(process) == .running
        {
            try set("state", to: .choice(ProcessState.suspended.rawValue), on: process)
            try set("lastTouchedAt", to: .date(now), on: process)
        }
    }

    mutating func makeRunning(_ process: ObjectRecord, at now: Date) throws {
        try suspendRunning(except: process.id, at: now)
        try set("state", to: .choice(ProcessState.running.rawValue), on: process)
        try set("endedAt", to: nil, on: process)
        try set("endReason", to: nil, on: process)
    }

    mutating func saveContext(_ process: ObjectRecord, resumePoint: ResumePoint?, nextStep: String?,
                              at now: Date) throws
    {
        if let resumePoint {
            try set("resumePoint", to: resumePoint.encoded.map(FieldValue.text), on: process)
        }
        if let nextStep {
            try set("nextStep", to: .text(nextStep), on: process)
        }
        try set("lastTouchedAt", to: .date(now), on: process)
    }

    mutating func end(_ process: ObjectRecord, reason: ProcessEndReason, at now: Date) throws {
        let state: ProcessState = switch reason {
        case .done, .wrappedUp: .done
        case .closed: .closed
        case .putAway: .putAway
        }
        try set("state", to: .choice(state.rawValue), on: process)
        try set("endedAt", to: .date(now), on: process)
        try set("endReason", to: .choice(reason.rawValue), on: process)
    }
}

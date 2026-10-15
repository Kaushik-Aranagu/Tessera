import Foundation

// Tasks as processes (M2 slice 3): starting a task makes it the running process, so it becomes Now; leaving it
// mid-way suspends it with a next step; a task waiting on someone has a check-at time.

/// Starts working on a task: it becomes the running process (anything else running is suspended).
public struct StartTask: EngineAction {
    public static let descriptor = ActionDescriptor(name: "startTask", summary: "Start working on a task", parameters: [
        .init("task", .object, "The task"),
        .init("nextStep", .string, "First step, verb first", required: false),
    ])

    public var task: UUID
    public var nextStep: String?

    public init(task: UUID, nextStep: String? = nil) {
        self.task = task
        self.nextStep = nextStep
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let task = try transaction.object(task, is: .task)
        return try StartProcess(subject: task.id, ownerApp: "Tasks", nextStep: nextStep ?? task.title)
            .apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "Started \(store.object(id: task)?.title ?? "the task")"
    }
}

/// Marks a task as waiting on someone or something until `checkAt`, when it comes back as suspended.
public struct WaitOnTask: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "waitOnTask",
        summary: "Wait on someone for a task",
        parameters: [
            .init("task", .object, "The task"),
            .init("waitingOn", .string, "Who or what, e.g. Arjun's reply"),
            .init("checkAt", .date, "When to bring it back"),
        ]
    )

    public var task: UUID
    public var waitingOn: String
    public var checkAt: Date

    public init(task: UUID, waitingOn: String, checkAt: Date) {
        self.task = task
        self.waitingOn = waitingOn
        self.checkAt = checkAt
    }

    public func apply(_ transaction: inout Transaction) throws {
        let task = try transaction.object(task, is: .task)
        let process = try transaction.openProcess(for: task)
            ?? StartProcess(subject: task.id, ownerApp: "Tasks", nextStep: task.title).apply(&transaction)
        try transaction.set("state", to: .choice(ProcessState.waiting.rawValue), on: process)
        try transaction.set("waitingOn", to: .text(waitingOn), on: process)
        try transaction.set("checkAt", to: .date(checkAt), on: process)
        try transaction.set("lastTouchedAt", to: .date(.now), on: process)
    }

    public func summary(in _: ObjectStore) -> String {
        "Waiting on \(waitingOn)"
    }
}

extension Transaction {
    /// Finishing a task ends its process, if it has one.
    mutating func endTaskProcess(_ task: ObjectRecord, done: Bool) throws {
        guard let process = openProcess(for: task) else { return }
        if done {
            try end(process, reason: .done, at: .now)
        }
    }
}

@MainActor
public extension ProcessTable {
    /// Waiting processes whose check-at time has come back become suspended (they can be Now again).
    /// Call alongside `tidy`.
    @discardableResult
    func wakeWaiting(now: Date = .now) -> [ProcessSnapshot] {
        let due = all().filter { $0.state == .waiting && ($0.checkAt.map { $0 <= now } ?? false) }
        for process in due {
            _ = try? engine.perform(SuspendProcess(process: process.id, time: now), by: .system)
        }
        return due
    }
}

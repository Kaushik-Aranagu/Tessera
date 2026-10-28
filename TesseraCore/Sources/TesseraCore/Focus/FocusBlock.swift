import Foundation

/// A focus block on any task (M4 slice 8): the task becomes a process owned by "Focus", Tess checks in once at
/// halfway, and gives a one-line wrap-up at the end. Quiet by design: the check-in is a line, never a sound.
public struct StartFocusBlock: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "startFocusBlock", summary: "Start a focus block on a task",
        parameters: [
            .init("task", .object, "The task"),
            .init("minutes", .integer, "How long, default 25", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public static let defaultMinutes = 25
    public static let bounds = 5 ... 180

    public var task: UUID
    public var minutes: Int?
    public var time: Date?

    public init(task: UUID, minutes: Int? = nil, time: Date? = nil) {
        self.task = task
        self.minutes = minutes
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let task = try transaction.object(task, is: .task)
        let length = min(max(minutes ?? Self.defaultMinutes, Self.bounds.lowerBound), Self.bounds.upperBound)
        return try StartProcess(subject: task.id, ownerApp: FocusBlock.ownerApp, nextStep: task.title,
                                resumePoint: ResumePoint(extras: ["focusMinutes": "\(length)"]), time: time)
            .apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: task)?.title ?? "it"
        let hidden = ObjectPrivacy.isPrivateTitle(title, lastWeightKg: BodyWeight.lastKg(in: store))
        return "Focus on \(hidden ? ObjectPrivacy.taskLabel : title)"
    }
}

/// What a running focus block is doing now.
public struct FocusBlock: Equatable, Sendable {
    public static let ownerApp = "Focus"

    public enum Phase: Equatable, Sendable {
        case running(minutesLeft: Int)
        /// Halfway and not asked yet: one quiet check-in.
        case checkInDue
        case over
    }

    public let minutes: Int
    public let startedAt: Date
    public let checkedIn: Bool
    public let title: String

    @MainActor
    public init?(_ process: ProcessSnapshot, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        guard process.ownerApp == Self.ownerApp, let started = process.startedAt,
              let minutes = process.resumePoint?.extras["focusMinutes"].flatMap(Int.init) else { return nil }
        self.minutes = minutes
        startedAt = started
        checkedIn = process.resumePoint?.extras["checkedIn"] == "1"
        let task = process.subject
        title = task.map { ObjectPrivacy.label(of: $0, in: store, classes: classes) ?? $0.title } ?? "it"
    }

    public func phase(at now: Date) -> Phase {
        let elapsed = now.timeIntervalSince(startedAt) / 60
        if elapsed >= Double(minutes) {
            return .over
        }
        if elapsed >= Double(minutes) / 2, !checkedIn {
            return .checkInDue
        }
        return .running(minutesLeft: Int((Double(minutes) - elapsed).rounded(.up)))
    }

    /// The one quiet check-in at halfway.
    public var checkInLine: String {
        "Halfway on \(title). Still with it?"
    }

    /// The wrap-up, counts only: "Focus done. 25 minutes on Reply to the landlord."
    public func wrapUpLine(endedAt: Date) -> String {
        let spent = min(max(Int((endedAt.timeIntervalSince(startedAt) / 60).rounded()), 1), minutes)
        return "Focus done. \(spent) \(spent == 1 ? "minute" : "minutes") on \(title)"
    }
}

/// The one check-in, recorded so it never repeats.
public struct FocusCheckIn: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "focusCheckIn", summary: "Check in on a focus block",
        parameters: [.init("process", .object, "The focus block")], isOfferedToModel: false
    )

    public var process: UUID
    public var time: Date?

    public init(process: UUID, time: Date? = nil) {
        self.process = process
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(process, is: .process)
        var point = ProcessSnapshot(object, store: transaction.store).resumePoint ?? ResumePoint()
        point.extras["checkedIn"] = "1"
        try SaveContext(process: process, resumePoint: point, time: time).apply(&transaction)
    }

    public var logsWhenEmpty: Bool {
        false
    }

    public func summary(in _: ObjectStore) -> String {
        "Focus check-in"
    }
}

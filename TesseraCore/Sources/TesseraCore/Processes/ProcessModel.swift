import Foundation

/// Open loops, tracked the way an OS tracks processes. Only one process runs at a time, and it is Now.
public enum ProcessState: String, Codable, Sendable, CaseIterable {
    case running
    case suspended
    /// Blocked on someone or something until `checkAt` (M2).
    case waiting
    case done
    /// Put away by hand; kept in history.
    case closed
    /// Moved to Later by the stale rules; fully restorable.
    case putAway

    public var isOpen: Bool {
        self == .running || self == .suspended || self == .waiting
    }
}

public enum ProcessEndReason: String, Codable, Sendable, CaseIterable {
    case done, closed, putAway
    /// A workout left suspended for 6 hours, saved with the sets already logged.
    case wrappedUp
}

/// Exactly where to land on resume. The engine writes it on every context switch; nobody types it.
public struct ResumePoint: Codable, Hashable, Sendable {
    /// The child object in focus, e.g. the exercise entry.
    public var focus: UUID?
    /// Position inside it, e.g. the set index.
    public var index: Int?
    /// A dial or input value to preset, e.g. 80 kg.
    public var weight: Double?
    public var reps: Double?
    /// Free-form view state: scroll anchor, draft text.
    public var extras: [String: String]

    public init(focus: UUID? = nil, index: Int? = nil, weight: Double? = nil, reps: Double? = nil,
                extras: [String: String] = [:])
    {
        self.focus = focus
        self.index = index
        self.weight = weight
        self.reps = reps
        self.extras = extras
    }

    var encoded: String? {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
    }

    init?(encoded: String?) {
        guard let data = encoded?.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ResumePoint.self, from: data) else { return nil }
        self = decoded
    }
}

/// A read-only view of a Process object for Home and the process page.
public struct ProcessSnapshot: Identifiable {
    public let id: UUID
    public let object: ObjectRecord
    public let subject: ObjectRecord?
    public let state: ProcessState
    public let ownerApp: String?
    public let nextStep: String?
    public let resumePoint: ResumePoint?
    public let startedAt: Date?
    public let lastTouchedAt: Date?
    public let checkAt: Date?

    @MainActor
    init(_ object: ObjectRecord, store: ObjectStore) {
        id = object.id
        self.object = object
        subject = store.linkedObjects("subject", of: object).first
        state = store.value("state", of: object)?.stringValue.flatMap(ProcessState.init(rawValue:)) ?? .running
        ownerApp = store.value("ownerApp", of: object)?.stringValue
        nextStep = store.value("nextStep", of: object)?.stringValue
        resumePoint = ResumePoint(encoded: store.value("resumePoint", of: object)?.stringValue)
        startedAt = store.value("startedAt", of: object)?.dateValue
        lastTouchedAt = store.value("lastTouchedAt", of: object)?.dateValue
        checkAt = store.value("checkAt", of: object)?.dateValue
    }

    /// "Left at set 3 of 5, 40 min ago" style copy is built by the UI from these; time, never judgement.
    public func idle(at now: Date) -> TimeInterval {
        now.timeIntervalSince(lastTouchedAt ?? startedAt ?? now)
    }
}

import Foundation

/// Quiet interrupts (M4 slice 4, docs/research/quiet-interrupts.md): while a workout, cook or focus block runs,
/// Tessera's own low and normal notifications wait in the engine, and one digest goes out at the next context
/// switch. Timers are never held. Pure engine: the app asks `shouldHold` before scheduling, and posts the digest.
public enum NoticePriority: String, Codable, Sendable {
    case timer, normal, low
}

@MainActor
public struct QuietInterrupts {
    /// The safety net: a digest fires this long after the block's expected end, never later than 3 hours in.
    public static let fallbackGrace: TimeInterval = 30 * 60
    public static let fallbackCap: TimeInterval = 3 * 3600

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// A workout, a cook or a focus block is running.
    public func maskActive() -> Bool {
        guard let running = ProcessTable(engine: ActionEngine(store: store, classes: classes)).running() else {
            return false
        }
        if running.ownerApp == FocusBlock.ownerApp {
            return true
        }
        guard let classDef = running.subject?.classDef else { return false }
        return [SystemCatalog.Key.workout, .cook].contains { key in
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
    }

    /// Timers always go out; everything else waits while the mask is on.
    public func shouldHold(_ priority: NoticePriority) -> Bool {
        priority != .timer && maskActive()
    }

    public func held() -> [ObjectRecord] {
        guard let heldClass = classes[.heldNotice] else { return [] }
        return store.objects(of: heldClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    /// "Quiet: 2 waiting" for the running Live Activity.
    public var waitingCount: Int {
        held().count
    }

    /// One line for the digest: "3 things waited: a, b, c". Private words never ride in it.
    public func digestLine() -> String? {
        let titles = held().map { notice -> String in
            ObjectPrivacy.isPrivateTitle(notice.title, lastWeightKg: BodyWeight.lastKg(in: store))
                ? "something private" : notice.title
        }
        guard !titles.isEmpty else { return nil }
        let shown = titles.prefix(3).joined(separator: ", ")
        let more = titles.count > 3 ? ", and \(titles.count - 3) more" : ""
        return "\(titles.count) \(titles.count == 1 ? "thing" : "things") waited: \(shown)\(more)."
    }

    /// When the safety-net digest fires if the app never releases it.
    public static func fallbackTime(blockStart: Date, expectedEnd: Date) -> Date {
        min(expectedEnd.addingTimeInterval(fallbackGrace), blockStart.addingTimeInterval(fallbackCap))
    }
}

/// Holds one notification (the full content, so releasing loses nothing).
public struct HoldNotice: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "holdNotice", summary: "Hold a notification", parameters: [], isOfferedToModel: false
    )

    public var title: String
    public var priority: NoticePriority
    public var dueAt: Date?

    public init(title: String, priority: NoticePriority = .normal, dueAt: Date? = nil) {
        self.title = title
        self.priority = priority
        self.dueAt = dueAt
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let notice = try transaction.create(transaction.classDef(.heldNotice), title: title)
        try transaction.set("priority", to: .text(priority.rawValue), on: notice)
        try transaction.set("dueAt", to: dueAt.map(FieldValue.date), on: notice)
        return notice
    }

    public var recordsOps: Bool {
        false
    }

    public func summary(in _: ObjectStore) -> String {
        "Held a notification"
    }
}

/// The context switch: everything held goes into one digest line and is cleared.
public struct ReleaseHeldNotices: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "releaseHeldNotices", summary: "Release held notifications", parameters: [], isOfferedToModel: false
    )

    public init() {}

    public func apply(_ transaction: inout Transaction) throws -> String? {
        let quiet = QuietInterrupts(store: transaction.store, classes: transaction.classes)
        let line = quiet.digestLine()
        for notice in quiet.held() {
            transaction.delete(notice)
        }
        return line
    }

    public var logsWhenEmpty: Bool {
        false
    }

    public var recordsOps: Bool {
        false
    }

    public func summary(in _: ObjectStore) -> String {
        "Released held notifications"
    }
}

import Foundation

/// Run a list (ship list slice 5): any list can be the running process, like the groceries shop. Now reads
/// "Packing, 6 left", another process suspends it into the ledger, and finishing ends it. It reuses the shop's pattern:
/// `StartProcess`, the ledger, `ProcessTable.Limits.idleShop` and the same line refresh on every check.
public extension ListContents {
    /// Now's line for a run: "Packing, 6 left", or "Packing, nothing left" when everything is struck. Counts only; an
    /// item's words never go into it.
    static func runLine(of list: ObjectRecord, in store: ObjectStore) -> String {
        let left = list.orderedChildren.count { store.value("isDone", of: $0) != .bool(true) }
        return left == 0 ? "\(list.title), nothing left" : "\(list.title), \(left) left"
    }

    func runLine(of list: ObjectRecord) -> String {
        Self.runLine(of: list, in: store)
    }

    /// The list's run in progress (running, or suspended in the ledger or past it), if any.
    func run(of list: ObjectRecord, in engine: ActionEngine) -> ProcessSnapshot? {
        ProcessTable(engine: engine).all().first { $0.subject?.id == list.id && $0.state.isOpen }
    }
}

/// Starts (or resumes) a run of a list: the list becomes the running process. Whatever was running is suspended into
/// the ledger. Groceries runs as the shop (`StartShop`), so it is refused here. A running workout is never suspended
/// by a run (as `StartCooking`, G56): "Workout running.", nothing written.
public struct StartListRun: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "startListRun",
        summary: "Run a list: start going through it",
        parameters: [
            .init("list", .object, "The list"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isOfferedToModel: false
    )

    public var list: UUID
    public var time: Date?

    public init(list: UUID, time: Date? = nil) {
        self.list = list
        self.time = time
    }

    /// The run's process.
    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let list = try transaction.object(list, is: .list)
        guard list.id != Groceries.listID else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "Groceries runs as the shop")
        }
        guard !transaction.hasRunningWorkout() else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: StartCooking.workoutRunningReason)
        }
        let line = ListContents.runLine(of: list, in: transaction.store)
        return try StartProcess(subject: list.id, ownerApp: "Lists", nextStep: line, time: time).apply(&transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "Started \(store.object(id: list)?.title ?? "the list")"
    }

    /// Thing first, the same words as Now's line: "Packing, 6 left".
    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: list).map { ListContents.runLine(of: $0, in: store) }
    }
}

/// Finishes a run: the process ends. A plain list loses what was checked (the basket is cleared, as `FinishShop`); a
/// reusable list keeps every strike, because resetting is its own action behind the hold (Product, lists-screens
/// 10.11).
public struct FinishListRun: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "finishListRun",
        summary: "Finish going through a list",
        parameters: [
            .init("list", .object, "The list"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isOfferedToModel: false
    )

    /// What finishing did, for the screen's next move ("done" on a reusable list asks about a reset).
    public struct Outcome: Equatable, Sendable {
        /// Checked items taken off a plain list.
        public let cleared: Int
        /// Items still open.
        public let left: Int
        public let wasReusable: Bool
    }

    public var list: UUID
    public var time: Date?

    public init(list: UUID, time: Date? = nil) {
        self.list = list
        self.time = time
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Outcome {
        let list = try transaction.object(list, is: .list)
        guard list.id != Groceries.listID else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "Groceries finishes as the shop")
        }
        guard let process = transaction.openProcess(for: list) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "\(list.title) isn't running")
        }
        let reusable = ListNoteTags.isReusable(list, in: transaction.store)
        let cleared = reusable ? 0 : try transaction.clearDone(in: list)
        try transaction.end(process, reason: .done, at: time ?? .now)
        let left = list.orderedChildren.count { transaction.store.value("isDone", of: $0) != .bool(true) }
        return Outcome(cleared: cleared, left: left, wasReusable: reusable)
    }

    public func summary(in store: ObjectStore) -> String {
        "Finished \(store.object(id: list)?.title ?? "the list")"
    }

    /// "Packing, done", or "Packing, Lisbon, done. 3 left" with items open (Product, Oct 16 12:38 PM).
    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: list) else { return nil }
        let left = object.orderedChildren.count { store.value("isDone", of: $0) != .bool(true) }
        return left > 0 ? "\(object.title), done. \(left) left" : "\(object.title), done"
    }
}

extension Transaction {
    /// Whether a workout is the running process (a run never suspends it).
    func hasRunningWorkout() -> Bool {
        guard let workoutClass = classes[.workout], let processClass = classes[.process] else { return false }
        return store.objects(of: processClass).contains { process in
            processState(process) == .running
                && store.linkedObjects("subject", of: process).first?.classDef
                .map { ClassResolver.isSubclass($0, of: workoutClass) } == true
        }
    }

    /// While a list runs, any change to it keeps Now's line current ("Packing, 5 left") and counts as a touch (the
    /// shop's idle clock, G44). Groceries keeps its own shop line.
    mutating func refreshRunLine(of list: ObjectRecord, at now: Date = .now) throws {
        if list.id == Groceries.listID {
            try refreshShopLine(at: now)
            return
        }
        guard let process = openProcess(for: list) else { return }
        let touched = max(store.value("lastTouchedAt", of: process)?.dateValue ?? now, now)
        try saveContext(process, resumePoint: nil, nextStep: ListContents.runLine(of: list, in: store), at: touched)
    }
}

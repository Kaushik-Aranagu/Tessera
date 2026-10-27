import Foundation

/// Run a list (ship list slice 5): any list can be the running process, like the groceries shop. Now reads
/// "Packing, 6 left", another process suspends it into the ledger, and finishing ends it. It reuses the shop's pattern:
/// `StartProcess`, the ledger, `ProcessTable.Limits.idleShop` and the same line refresh on every check.
public extension ListContents {
    /// Now's line for a run: "Packing, 6 left", or "Packing, nothing left" when everything is struck. Counts only; an
    /// item's words never go into it.
    static func runLine(of list: ObjectRecord, in store: ObjectStore) -> String {
        let left = list.orderedChildren.count { store.value("isDone", of: $0) != .bool(true) }
        let name = shownName(of: list, in: store)
        return left == 0 ? "\(name), nothing left" : "\(name), \(left) left"
    }

    /// A list's name wherever a run shows it (Now, Home, a Live Activity, the ledger): "Private list" for a walled
    /// name (QA on #801, as the put-away note).
    static let privateListLabel = "Private list"

    static func shownName(of list: ObjectRecord, in store: ObjectStore) -> String {
        ObjectPrivacy.isPrivateWord(list.title, in: store) ? privateListLabel : list.title
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
        // A put-away list comes back by running it again: the same process leaves Later, rows and all.
        let process: ObjectRecord
        if transaction.openProcess(for: list) == nil, let away = transaction.putAwayProcess(for: list) {
            let now = time ?? .now
            try transaction.makeRunning(away, at: now)
            try transaction.saveContext(away, resumePoint: nil, nextStep: line, at: now)
            process = away
        } else {
            process = try StartProcess(subject: list.id, ownerApp: "Lists", nextStep: line, time: time)
                .apply(&transaction)
        }
        // The ledger row reads the process's title: a walled list's name never lands there.
        let shown = ListContents.shownName(of: list, in: transaction.store)
        if process.title != shown {
            transaction.setTitle(shown, on: process)
        }
        return process
    }

    public func summary(in store: ObjectStore) -> String {
        "Started \(store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list")"
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
        /// A plain list with everything done is put away, rows kept, rather than cleared (G9).
        public let putAway: Bool
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
            throw ActionError.invalidArguments(action: Self.descriptor.name,
                                               reason: Self.notRunningLine(list, in: transaction.store))
        }
        let reusable = ListNoteTags.isReusable(list, in: transaction.store)
        // A finished trip list is put away whole, so bringing it back brings every item with it (G9).
        if Self.putsAway(list, in: transaction.store) {
            try transaction.end(process, reason: .putAway, at: time ?? .now)
            return Outcome(cleared: 0, left: 0, wasReusable: false, putAway: true)
        }
        let cleared = reusable ? 0 : try transaction.clearDone(in: list)
        try transaction.end(process, reason: .done, at: time ?? .now)
        let left = list.orderedChildren.count { transaction.store.value("isDone", of: $0) != .bool(true) }
        return Outcome(cleared: cleared, left: left, wasReusable: reusable, putAway: false)
    }

    /// Finishing puts a list away when it is plain, has items and has nothing open (Product, lists-screens G9).
    @MainActor static func putsAway(_ list: ObjectRecord, in store: ObjectStore) -> Bool {
        !ListNoteTags.isReusable(list, in: store) && !list.orderedChildren.isEmpty
            && list.orderedChildren.allSatisfy { store.value("isDone", of: $0) == .bool(true) }
    }

    /// Done on a list that isn't running (Product 9:45 AM PT, ruling 3): "Packing isn't running."
    @MainActor
    public static func notRunningLine(_ list: ObjectRecord, in store: ObjectStore) -> String {
        "\(ListContents.shownName(of: list, in: store)) isn't running"
    }

    public func summary(in store: ObjectStore) -> String {
        guard let object = store.object(id: list) else { return "Finished the list" }
        let name = ListContents.shownName(of: object, in: store)
        return Self.putsAway(object, in: store) ? "Put \(name) away" : "Finished \(name)"
    }

    /// "Packing, done", "Packing, Lisbon, done. 3 left" with items open (Product, Oct 16 12:38 PM), and "Packing,
    /// Lisbon put away" for a finished trip list (G9).
    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: list) else { return nil }
        if Self.putsAway(object, in: store) {
            return "\(ListContents.shownName(of: object, in: store)) put away"
        }
        let left = object.orderedChildren.count { store.value("isDone", of: $0) != .bool(true) }
        let name = ListContents.shownName(of: object, in: store)
        return left > 0 ? "\(name), done. \(left) left" : "\(name), done"
    }
}

extension Transaction {
    /// The list's newest process that was put away to Later, if it has no open one.
    func putAwayProcess(for list: ObjectRecord) -> ObjectRecord? {
        store.backlinks(to: list)
            .filter { $0.classDef?.id == classes[.process]?.id && processState($0) == .putAway }
            .max { endedAt($0) < endedAt($1) }
    }

    private func endedAt(_ process: ObjectRecord) -> Date {
        store.value("endedAt", of: process)?.dateValue ?? .distantPast
    }

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

/// Sets a list's run aside to Later without finishing it: the run leaves Now (or the ledger) and the list keeps its
/// items and its strikes, the basket. Running the list again brings it back. Groceries is put away only by the idle
/// rule (a shop), never by hand here. One undo returns the run to what it was.
public struct PutAwayListRun: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "putAwayListRun",
        summary: "Put a list's run away to Later",
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

    /// How many checked items are in the basket that went to Later.
    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Int {
        let list = try transaction.object(list, is: .list)
        guard list.id != Groceries.listID else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "Groceries can't be put away")
        }
        guard let process = transaction.openProcess(for: list) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name,
                                               reason: FinishListRun.notRunningLine(list, in: transaction.store))
        }
        try transaction.end(process, reason: .putAway, at: time ?? .now)
        return ListContents.basketCount(of: list, in: transaction.store)
    }

    public func summary(in store: ObjectStore) -> String {
        "Put \(store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list") away"
    }

    /// Thing first, with the basket when there is one: "Packing put away. 3 in the basket".
    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: list) else { return nil }
        let basket = ListContents.basketCount(of: object, in: store)
        let name = ListContents.shownName(of: object, in: store)
        return basket > 0 ? "\(name) put away. \(basket) in the basket" : "\(name) put away"
    }
}

public extension ListContents {
    /// The checked items on a list: the basket that goes with a run to Later. A count only.
    static func basketCount(of list: ObjectRecord, in store: ObjectStore) -> Int {
        list.orderedChildren.count { store.value("isDone", of: $0) == .bool(true) }
    }

    /// Lists put away (Later), newest first: a run was set aside and nothing has run since. Groceries never is.
    func putAway() -> [ObjectRecord] {
        guard let processClass = classes[.process], let listClass = classes[.list] else { return [] }
        let processes = store.objects(of: processClass).map { ProcessSnapshot($0, store: store) }
        let running = Set(processes.filter(\.state.isOpen).compactMap { $0.subject?.id })
        var seen: Set<UUID> = []
        var away: [ObjectRecord] = []
        for process in processes.filter({ $0.state == .putAway }).sorted(by: { endedAt($0) > endedAt($1) }) {
            guard let list = process.subject, !list.isDeleted, list.id != Groceries.listID,
                  !running.contains(list.id), let classDef = list.classDef,
                  ClassResolver.isSubclass(classDef, of: listClass), seen.insert(list.id).inserted else { continue }
            away.append(list)
        }
        return away
    }

    /// The lists on the shelf: every list that isn't put away, oldest first.
    func shelf() -> [ObjectRecord] {
        let away = Set(putAway().map(\.id))
        return lists().filter { !away.contains($0.id) }
    }

    private func endedAt(_ process: ProcessSnapshot) -> Date {
        store.value("endedAt", of: process.object)?.dateValue ?? .distantPast
    }
}

import Foundation

/// Shopping as a process (kitchen slice 8): the groceries list runs on Now ("Shopping, 9 left"), items come in
/// aisle order, leaving suspends it in the ledger (the existing SuspendProcess), and finishing clears what's in the
/// basket.
public extension Groceries {
    /// Open items in walking order (aisle by aisle, list order within an aisle).
    func shoppingOrder() -> [ListContents.Item] {
        aisles().flatMap(\.items)
    }

    /// "Shopping, 9 left" / "Shopping, all in the basket".
    func shoppingLine() -> String {
        let left = shoppingOrder().count
        return left == 0 ? "Shopping, all in the basket" : "Shopping, \(left) left"
    }

    /// The shop in progress (running or suspended), if any.
    func shop(in engine: ActionEngine) -> ProcessSnapshot? {
        guard let list else { return nil }
        let table = ProcessTable(engine: engine)
        return ([table.running()].compactMap(\.self) + table.ledger()).first { $0.subject?.id == list.id }
    }
}

/// Starts (or resumes) the shop: the groceries list becomes the running process.
public struct StartShop: EngineAction {
    public static let descriptor = ActionDescriptor(name: "startShop", summary: "Start shopping the groceries list",
                                                    parameters: [])

    public var time: Date?

    public init(time: Date? = nil) {
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let list = try transaction.groceriesList()
        let groceries = Groceries(store: transaction.store, classes: transaction.classes)
        return try StartProcess(subject: list.id, ownerApp: "Kitchen", nextStep: groceries.shoppingLine(), time: time)
            .apply(&transaction)
    }

    public func summary(in _: ObjectStore) -> String {
        "Shopping"
    }
}

/// Finishes the shop: the basket (checked items) is cleared and the process ends.
public struct FinishShop: EngineAction {
    public static let descriptor = ActionDescriptor(name: "finishShop", summary: "Finish shopping", parameters: [])

    public var time: Date?

    public init(time: Date? = nil) {
        self.time = time
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Int {
        // No groceries list means no shop: fail and write nothing (never make a list just to finish on it).
        guard let list = transaction.store.object(id: Groceries.listID), !list.isDeleted else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "there is no shop to finish")
        }
        let cleared = try transaction.clearDone(in: list)
        if let process = transaction.openProcess(for: list) {
            try transaction.end(process, reason: .done, at: time ?? .now)
        }
        return cleared
    }

    public func summary(in _: ObjectStore) -> String {
        "Finished shopping"
    }

    /// What Tess says for it; one UNDO brings the checked rows and the running shop back.
    public func receipt(in _: ObjectStore) -> String? {
        "Shopping, finished"
    }
}

extension Transaction {
    /// While shopping, any change to the list keeps Now's line current ("Shopping, 8 left").
    mutating func refreshShopLine(for item: ObjectRecord, at now: Date = .now) throws {
        guard let list = item.parent, list.id == Groceries.listID else { return }
        try refreshShopLine(at: now)
    }

    /// `now` is the touch: checking a row at a given time resets the shop's idle clock to that time (G44).
    mutating func refreshShopLine(at now: Date = .now) throws {
        guard let list = store.object(id: Groceries.listID), let process = openProcess(for: list) else { return }
        let line = Groceries(store: store, classes: classes).shoppingLine()
        try saveContext(process, resumePoint: nil, nextStep: line, at: now)
    }
}

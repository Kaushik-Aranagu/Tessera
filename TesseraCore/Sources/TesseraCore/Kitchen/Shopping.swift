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

/// One thing put away when the shop ends: an ingredient, the place it goes and the section inside it.
public struct ShopPutAway: Codable, Equatable, Hashable, Sendable {
    public var item: UUID
    public var place: UUID?
    public var section: String?

    public init(item: UUID, place: UUID?, section: String? = nil) {
        self.item = item
        self.place = place
        self.section = section
    }
}

/// Finishes the shop: the basket (checked items) is cleared and the process ends. With `putAway`, the places of what
/// was bought are set in the same transaction: one OpRecord, so one UNDO takes back both, and a finish that fails sets
/// no place (the engine reverses a failed action whole).
public struct FinishShop: EngineAction {
    public static let descriptor = ActionDescriptor(name: "finishShop", summary: "Finish shopping", parameters: [])

    public var time: Date?
    /// Only the app passes this, in process. It is not a tool parameter and never decodes from a tool call, so Claude
    /// and Tess cannot set pantry places through the finish (SetItemPlace is kept from the model on purpose).
    public var putAway: [ShopPutAway]?

    private enum CodingKeys: String, CodingKey {
        case time
    }

    public init(time: Date? = nil, putAway: [ShopPutAway]? = nil) {
        self.time = time
        self.putAway = putAway
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Int {
        // No groceries list means no shop: fail and write nothing (never make a list just to finish on it).
        guard let list = transaction.store.object(id: Groceries.listID), !list.isDeleted else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "there is no shop to finish")
        }
        // The last entry for an item wins, so one item is never placed twice.
        var seen = Set<UUID>()
        for entry in (putAway ?? []).reversed() where seen.insert(entry.item).inserted {
            try SetItemPlace(item: entry.item, place: entry.place, section: entry.section).apply(&transaction)
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

    /// What Tess says for it; one UNDO brings the checked rows, the places and the running shop back.
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
        // A backdated check never moves the idle clock back (QA on #771): the later of the last touch and now.
        let touched = max(store.value("lastTouchedAt", of: process)?.dateValue ?? now, now)
        try saveContext(process, resumePoint: nil, nextStep: line, at: touched)
    }
}

import Foundation

/// Reusable lists (ship list slice 4): a packing list, a gym bag, "leaving the house" never loses its items. The flag
/// is an option on the list, off by default, and the word is always "reusable". Reset unchecks everything and keeps
/// every item; it is its own action, never `ClearDoneItems`, which deletes.
public extension ListContents {
    /// Whether the list is flagged reusable.
    func isReusable(_ list: ObjectRecord) -> Bool {
        ListNoteTags.isReusable(list, in: store)
    }
}

/// Turns the reusable option on or off. Groceries can't be reusable (it has recurring items instead).
public struct SetListReusable: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setListReusable",
        summary: "Make a list reusable, or not",
        parameters: [
            .init("list", .object, "The list"),
            .init("reusable", .boolean, "False to turn it off", required: false),
        ],
        isOfferedToModel: false
    )

    public var list: UUID
    public var reusable: Bool?

    public init(list: UUID, reusable: Bool? = true) {
        self.list = list
        self.reusable = reusable
    }

    public func apply(_ transaction: inout Transaction) throws {
        let list = try transaction.object(list, is: .list)
        guard list.id != Groceries.listID else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "Groceries can't be reusable")
        }
        let isOn = reusable ?? true
        let notes = transaction.store.value("notes", of: list)?.stringValue
        guard ListNoteTags.has(ListNoteTags.reusable, in: notes) != isOn else {
            throw ActionError.invalidArguments(
                action: Self.descriptor.name,
                reason: "\(list.title) is already \(isOn ? "reusable" : "not reusable")"
            )
        }
        let updated = ListNoteTags.setting(ListNoteTags.reusable, to: isOn, in: notes)
        try transaction.set("notes", to: updated.map(FieldValue.richText), on: list)
    }

    public func summary(in store: ObjectStore) -> String {
        "Made \(store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list") "
            + (reusable ?? true ? "reusable" : "not reusable")
    }

    public func receipt(in store: ObjectStore) -> String? {
        "\(store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "The list"), "
            + (reusable ?? true ? "reusable" : "not reusable")
    }
}

/// Unchecks every item on a list in one action; the items stay, in order. Works on any list ("reset packing" on a
/// list that isn't reusable is uncheck all). One undo checks them again with their `checkedAt`. With nothing checked
/// it is a quiet no-op: nothing written, so no UNDO, and "Packing, nothing to reset." (Product 9:45 AM PT, ruling 2).
public struct ResetList: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "resetList",
        summary: "Uncheck everything on a list, keeping the items",
        parameters: [.init("list", .object, "The list")],
        isOfferedToModel: false
    )

    public var list: UUID
    /// When it was reset; the app passes its clock.
    public var time: Date?

    public init(list: UUID, time: Date? = nil) {
        self.list = list
        self.time = time
    }

    /// How many items were unchecked.
    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Int {
        let list = try transaction.object(list, is: .list)
        let done = list.orderedChildren.filter { transaction.store.value("isDone", of: $0) == .bool(true) }
        guard !done.isEmpty else { return 0 }
        for item in done {
            try transaction.set("isDone", to: .bool(false), on: item)
            try transaction.set("checkedAt", to: nil, on: item)
        }
        try transaction.refreshRunLine(of: list, at: time ?? .now)
        return done.count
    }

    public func summary(in store: ObjectStore) -> String {
        "Reset \(store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list")"
    }

    /// "Packing, nothing to reset." when nothing was checked (Product ruling 2), from this run's own count.
    public func summary(in store: ObjectStore, output: Int) -> String {
        output == 0 ? Self.receipt(for: list, unchecked: 0, in: store) : summary(in: store)
    }

    /// Thing first (Product, screens 10.11): "Packing, reset".
    public func receipt(in store: ObjectStore) -> String? {
        Self.receipt(for: list, unchecked: 1, in: store)
    }

    public func receipt(in store: ObjectStore, output: Int) -> String? {
        Self.receipt(for: list, unchecked: output, in: store)
    }

    @MainActor
    static func receipt(for list: UUID, unchecked: Int, in store: ObjectStore) -> String {
        let name = store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "The list"
        return unchecked == 0 ? "\(name), nothing to reset." : "\(name), reset"
    }
}

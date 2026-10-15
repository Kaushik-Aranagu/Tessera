import Foundation

/// The actionable list block (kitchen slice 1): a `List` whose children are `List Item`s (text, optional quantity,
/// done, optional section, links to anything). Checked items stay, with `checkedAt`, until "clear done".
/// Groceries, packing lists and M3's List template are all this class.
@MainActor
public struct ListContents {
    public struct Item: Identifiable, Equatable {
        public let id: UUID
        public let object: ObjectRecord
        public let text: String
        public let quantity: String?
        public let section: String?
        public let isDone: Bool
        public let checkedAt: Date?
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Every list, oldest first.
    public func lists() -> [ObjectRecord] {
        guard let listClass = classes[.list] else { return [] }
        return store.objects(of: listClass).sorted { $0.createdAt < $1.createdAt }
    }

    /// The list's items in order (open and done together).
    public func items(of list: ObjectRecord) -> [Item] {
        list.orderedChildren.map(item)
    }

    public func open(in list: ObjectRecord) -> [Item] {
        items(of: list).filter { !$0.isDone }
    }

    /// Checked items, most recently checked first.
    public func done(in list: ObjectRecord) -> [Item] {
        items(of: list).filter(\.isDone).sorted { ($0.checkedAt ?? .distantPast) > ($1.checkedAt ?? .distantPast) }
    }

    /// Section names in the order they first appear; items with no section are under nil.
    public func sections(of list: ObjectRecord) -> [(name: String?, items: [Item])] {
        var order: [String?] = []
        var grouped: [String?: [Item]] = [:]
        for item in items(of: list) {
            if grouped[item.section] == nil {
                order.append(item.section)
            }
            grouped[item.section, default: []].append(item)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    func item(_ object: ObjectRecord) -> Item {
        Item(
            id: object.id, object: object, text: object.title,
            quantity: store.value("quantity", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 },
            section: store.value("section", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 },
            isDone: store.value("isDone", of: object) == .bool(true),
            checkedAt: store.value("checkedAt", of: object)?.dateValue
        )
    }
}

// MARK: - Actions

/// Makes a new list.
public struct CreateList: EngineAction {
    public static let descriptor = ActionDescriptor(name: "createList", summary: "Make a new list", parameters: [
        .init("name", .string, "What the list is, e.g. Packing"),
    ])

    public var name: String

    public init(name: String) {
        self.name = name
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "the list needs a name")
        }
        return try transaction.create(transaction.classDef(.list), title: name)
    }

    public func summary(in _: ObjectStore) -> String {
        "New list: \(name)"
    }
}

/// Adds an item at the end of a list (or of its section).
public struct AddListItem: EngineAction {
    public static let descriptor = ActionDescriptor(name: "addListItem", summary: "Add an item to a list", parameters: [
        .init("list", .object, "The list"),
        .init("text", .string, "The item, e.g. milk"),
        .init("quantity", .string, "e.g. 2, 500 g", required: false),
        .init("section", .string, "A section, e.g. Dairy", required: false),
        .init("about", .json, "Ids of things it's for, e.g. a recipe", required: false),
    ])

    public var list: UUID
    public var text: String
    public var quantity: String?
    public var section: String?
    public var about: [UUID]?

    public init(list: UUID, text: String, quantity: String? = nil, section: String? = nil, about: [UUID]? = nil) {
        self.list = list
        self.text = text
        self.quantity = quantity
        self.section = section
        self.about = about
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let list = try transaction.object(list, is: .list)
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "the item is empty")
        }
        let last = list.orderedChildren.last?.sortIndex ?? -1
        let item = try transaction.create(transaction.classDef(.listItem), title: text, parent: list)
        transaction.setSortIndex(last + 1, on: item)
        if let quantity, !quantity.isEmpty {
            try transaction.set("quantity", to: .text(quantity), on: item)
        }
        if let section, !section.isEmpty {
            try transaction.set("section", to: .text(section), on: item)
        }
        if let about, !about.isEmpty {
            try transaction.setLinks("about", on: item, to: about.map { try transaction.object($0) })
        }
        return item
    }

    public func summary(in _: ObjectStore) -> String {
        "Added \(text)"
    }
}

/// Checks an item (or unchecks it). Checked items stay on the list until "clear done".
public struct CheckListItem: EngineAction {
    public static let descriptor = ActionDescriptor(name: "checkListItem", summary: "Check or uncheck a list item",
                                                    parameters: [
                                                        .init("item", .object, "The item"),
                                                        .init("done", .boolean, "False to uncheck", required: false),
                                                    ])

    public var item: UUID
    public var done: Bool?

    public init(item: UUID, done: Bool? = true) {
        self.item = item
        self.done = done
    }

    public func apply(_ transaction: inout Transaction) throws {
        let item = try transaction.object(item, is: .listItem)
        let isDone = done ?? true
        try transaction.set("isDone", to: .bool(isDone), on: item)
        try transaction.set("checkedAt", to: isDone ? .date(.now) : nil, on: item)
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: item)?.title ?? "it"
        return done ?? true ? "Got \(title)" : "Back on the list: \(title)"
    }
}

/// Moves an item to another section and/or position within its list (0 = first).
public struct MoveListItem: EngineAction {
    public static let descriptor = ActionDescriptor(name: "moveListItem", summary: "Move a list item", parameters: [
        .init("item", .object, "The item"),
        .init("section", .string, "The section to move it to; empty for none", required: false),
        .init("index", .integer, "Its new position in the list, 0 first", required: false),
    ])

    public var item: UUID
    public var section: String?
    public var index: Int?

    public init(item: UUID, section: String? = nil, index: Int? = nil) {
        self.item = item
        self.section = section
        self.index = index
    }

    public func apply(_ transaction: inout Transaction) throws {
        let item = try transaction.object(item, is: .listItem)
        if let section {
            try transaction.set("section", to: section.isEmpty ? nil : .text(section), on: item)
        }
        guard let index, let list = item.parent else { return }
        var siblings = list.orderedChildren.filter { $0.id != item.id }
        siblings.insert(item, at: max(0, min(index, siblings.count)))
        for (position, sibling) in siblings.enumerated() {
            transaction.setSortIndex(position, on: sibling)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "Moved \(store.object(id: item)?.title ?? "it")"
    }
}

/// Renames a section on every item of a list that's in it.
public struct RenameListSection: EngineAction {
    public static let descriptor = ActionDescriptor(name: "renameListSection", summary: "Rename a section of a list",
                                                    parameters: [
                                                        .init("list", .object, "The list"),
                                                        .init("from", .string, "The section's name now"),
                                                        .init("to", .string, "Its new name"),
                                                    ])

    public var list: UUID
    public var from: String
    public var to: String // swiftlint:disable:this identifier_name

    public init(list: UUID, from: String, to: String) {
        self.list = list
        self.from = from
        self.to = to
    }

    public func apply(_ transaction: inout Transaction) throws {
        let list = try transaction.object(list, is: .list)
        let name = to.trimmingCharacters(in: .whitespacesAndNewlines)
        for item in list.orderedChildren where transaction.store.value("section", of: item)?.stringValue == from {
            try transaction.set("section", to: name.isEmpty ? nil : .text(name), on: item)
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Renamed \(from) to \(to)"
    }
}

/// Takes the checked items off a list (soft delete; undo puts them back).
public struct ClearDoneItems: EngineAction {
    public static let descriptor = ActionDescriptor(name: "clearDoneItems", summary: "Clear checked items off a list",
                                                    parameters: [.init("list", .object, "The list")])

    public var list: UUID

    public init(list: UUID) {
        self.list = list
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> Int {
        let list = try transaction.object(list, is: .list)
        let done = list.orderedChildren.filter { transaction.store.value("isDone", of: $0) == .bool(true) }
        for item in done {
            transaction.delete(item)
        }
        return done.count
    }

    public func summary(in store: ObjectStore) -> String {
        "Cleared \(store.object(id: list)?.title ?? "the list")"
    }
}

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

/// Makes a new list. A name that is already a list (case and spaces aside) opens that list instead of making a second
/// (G40): no `.create` op, and the receipt says it was already there. Deleted lists don't count, and "Groceries" is
/// the built-in.
public struct CreateList: EngineAction {
    public static let descriptor = ActionDescriptor(name: "createList", summary: "Make a new list", parameters: [
        .init("name", .string, "What the list is, e.g. Packing"),
    ])

    public var name: String

    /// Whether the last `apply` found the list already there. Not part of the action's encoding.
    private let outcome = Outcome()

    private final class Outcome: @unchecked Sendable {
        var wasRepeat = false
    }

    private enum CodingKeys: String, CodingKey {
        case name
    }

    public init(name: String) {
        self.name = name
    }

    /// The live list with this name (case and spaces aside), oldest first; nil when there is none.
    @MainActor
    public static func existing(named name: String, in store: ObjectStore,
                                classes: [SystemCatalog.Key: ClassDef]) -> ObjectRecord?
    {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        if key == "groceries", let built = store.object(id: Groceries.listID), !built.isDeleted {
            return built
        }
        return ListContents(store: store, classes: classes).lists()
            .first { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }
    }

    /// Whether a record from `CreateList` found its list already there (it made nothing).
    @MainActor
    public static func wasRepeat(_ record: OpRecord) -> Bool {
        guard record.action == descriptor.name else { return false }
        let made = record.ops.contains {
            if case .create = $0 {
                true
            } else {
                false
            }
        }
        return !made
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "the list needs a name")
        }
        // A name with a secret word in it, or a key, is never a list name (G77): it would sit on screen and in the log.
        guard !looksLikeClaudeKey(name), !SecretWords.mentions(name) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that can't be a list name")
        }
        outcome.wasRepeat = false
        if let existing = Self.existing(named: name, in: transaction.store, classes: transaction.classes) {
            outcome.wasRepeat = true
            return existing
        }
        if name.lowercased() == "groceries" {
            return try transaction.groceriesList()
        }
        return try transaction.create(transaction.classDef(.list), title: name)
    }

    /// A walled name never lands in the op log or the receipt (QA on #826): "Private list".
    @MainActor
    private func shownName(in store: ObjectStore) -> String {
        let shown = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return ObjectPrivacy.isPrivateWord(shown, in: store) ? ListContents.privateListLabel : shown
    }

    public func summary(in store: ObjectStore) -> String {
        "New list: \(shownName(in: store))"
    }

    public func receipt(in store: ObjectStore) -> String? {
        let shown = shownName(in: store)
        return outcome.wasRepeat ? "\(shown), already a list" : "\(shown), made"
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
        let given = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !given.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "the item is empty")
        }
        // The engine wall (board 0ai, Kitchen 2:09 PM PT): a price comes off and the item stays ("milk $4" is milk); a
        // line that was only money, holds a secret or is his weight is a private note instead, by CreateNote's rule.
        // A medicine or body fact stays on his list in his words but is never said or logged (Product 8:13 PM PT).
        guard let text = Self.kept(given, store: transaction.store) else {
            return try CreateNote(body: given, isPrivate: true).apply(&transaction)
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
        if list.id != Groceries.listID {
            try transaction.refreshRunLine(of: list)
        }
        return item
    }

    /// What the wall keeps as the item: nil when the line becomes a private note.
    @MainActor public static func kept(_ given: String, store: ObjectStore) -> String? {
        guard !looksLikeClaudeKey(given) else { return nil }
        let bare = EngineWall.withoutPrice(given)
        let last = BodyWeight.lastKg(in: store)
        // A measure is never money: "1.25 cups flour" (a cooking unit right after two places; never kg or lb).
        let measured = bare.replacing(
            #/
            (?i) \b \d+ [.,] \d{2} \s*
            (?: cups? | tbsps? | tablespoons? | tsps? | teaspoons? | g | grams? | ml | cl | dl | l | liters? | litres?
              | oz | ounces? | pints? | pt | quarts? | qt | gallons? | gal | sticks? )
            \s+ (?! (?: at | for | from | on ) \b ) [a-z]
            /#,
            // Only with the thing after it (QA on #776): "1.25 cups flour" is a measure; "milk 3.49 gallon" is a price.
            with: "1 x"
        )
        // A unit then a thing is an amount to buy, not money or his weight: "1.50 lb apples" (QA on #763).
        let amount = isAmountOfAThing(bare)
        let isNote = bare.isEmpty || SecretWords.isSecretListLine(given)
            || (!amount && PrivateFacts.isMoneyShaped(measured))
            || (!amount && PrivateFacts.isBareWeight(bare.lowercased(), lastWeightKg: last)) || isSumOnly(
                given,
                bare: bare
            )
        return isNote ? nil : bare
    }

    /// "1.50 lb apples", "2 kg rice": a number, a unit, then a word that isn't a day or body word.
    static func isAmountOfAThing(_ line: String) -> Bool {
        let lower = line.lowercased()
        guard let match = lower
            .firstMatch(of: /\b\d+(?:[.,]\d+)?\s*(?:kg|kgs|lb|lbs|pound|pounds|kilo|kilos|g|oz|ml|l)\s+([a-z]+)/)
        else {
            return false
        }
        let word = String(match.output.1)
        // Words that read as a weigh-in, never a food (QA on #770): "82.4 kg fasted", "after run", "lighter".
        let neverFood: Set = [
            "after",
            "before",
            "fasted",
            "post",
            "pre",
            "up",
            "down",
            "lighter",
            "heavier",
            "at",
            "for",
            "from",
            "on",
        ]
        return !PrivateFacts.dayWords.contains(word) && !PrivateFacts.bodyWords.contains(word)
            && !PrivateFacts.weighWords.contains(word) && !neverFood.contains(word)
    }

    /// A line that was only a sum, judged on what was typed (Kitchen on #759): "$40 at costco" strips to "at costco",
    /// which names no thing to buy.
    static func isSumOnly(_ given: String, bare: String) -> Bool {
        guard PrivateFacts.isMoneyShaped(given) || bare != given.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        let filler: Set = ["at", "for", "from", "in", "on", "to", "the", "a", "an", "and", "of"]
        let words = PrivateFacts.words(bare.lowercased()).filter { word in
            !filler.contains(word) && !TessMemoryScreen.placeWords.contains(word)
                && !TessMemoryScreen.moneyWords.contains(word)
        }
        return words.isEmpty
    }

    /// A kept item that is a medicine or a body fact: his list shows it, nothing else names it.
    @MainActor static func isPrivateItem(_ kept: String, store: ObjectStore) -> Bool {
        ObjectPrivacy.isPrivateWord(kept, in: store)
    }

    public func summary(in store: ObjectStore) -> String {
        guard let kept = Self.kept(text.trimmingCharacters(in: .whitespacesAndNewlines), store: store) else {
            return SecretWords.title
        }
        // Thing first, the list by name (Product 10:06 PM PT lists copy sweep): "Rice, on Packing".
        let listTitle = store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list"
        let thing = Self.isPrivateItem(kept, store: store) ? Self.privateItemLabel : kept.prefix(1).uppercased() + kept
            .dropFirst()
        return "\(thing), on \(listTitle)"
    }

    public func receipt(in store: ObjectStore) -> String? {
        let listTitle = store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list"
        guard let kept = Self.kept(text.trimmingCharacters(in: .whitespacesAndNewlines), store: store) else {
            return "\(SecretWords.title), kept"
        }
        if Self.isPrivateItem(kept, store: store) {
            return "\(Self.privateItemLabel), on \(listTitle)"
        }
        return "\(kept.prefix(1).uppercased() + kept.dropFirst()), on \(listTitle)"
    }

    static let privateItemLabel = "Private item"

    /// An item's title as a receipt may print it: "Private item" for a medicine or body fact (G41).
    @MainActor static func shownTitle(_ title: String, store: ObjectStore) -> String {
        isPrivateItem(title, store: store) ? privateItemLabel : title
    }
}

/// Checks an item (or unchecks it). Checked items stay on the list until "clear done".
public struct CheckListItem: EngineAction {
    public static let descriptor = ActionDescriptor(name: "checkListItem", summary: "Check or uncheck a list item",
                                                    parameters: [
                                                        .init("item", .object, "The item"),
                                                        .init("done", .boolean, "False to uncheck", required: false),
                                                        .init("time", .date, "Defaults to now", required: false),
                                                    ])

    public var item: UUID
    public var done: Bool?
    /// When it was checked; the app passes its clock (so `-demoTime` and fixtures hold).
    public var time: Date?

    public init(item: UUID, done: Bool? = true, time: Date? = nil) {
        self.item = item
        self.done = done
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let item = try transaction.object(item, is: .listItem)
        let isDone = done ?? true
        try transaction.set("isDone", to: .bool(isDone), on: item)
        try transaction.set("checkedAt", to: isDone ? .date(time ?? .now) : nil, on: item)
        try transaction.refreshShopLine(for: item, at: time ?? .now)
        if let list = item.parent, list.id != Groceries.listID {
            try transaction.refreshRunLine(of: list, at: time ?? .now)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: item).map { AddListItem.shownTitle($0.title, store: store) } ?? "it"
        return done ?? true ? "Got \(title)" : "Back on the list: \(title)"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        // A medicine's words print only where he added it (G41): checked off, it is "Private item".
        let shown = AddListItem.shownTitle(object.title, store: store)
        let title = shown.prefix(1).uppercased() + shown.dropFirst()
        return done ?? true ? "\(title), got" : "\(title), back on \(object.parent.map { ListContents.shownName(of: $0, in: store) } ?? "the list")"
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
            // On the groceries list, moving an item to another aisle teaches its ingredient (kitchen slice 7).
            if item.parent?.id == Groceries.listID, !section.isEmpty,
               let ingredient = Groceries(store: transaction.store, classes: transaction.classes).ingredient(of: item)
            {
                try transaction.set("aisle", to: .text(section), on: ingredient)
            }
        }
        guard let index, let list = item.parent else { return }
        var siblings = list.orderedChildren.filter { $0.id != item.id }
        siblings.insert(item, at: max(0, min(index, siblings.count)))
        for (position, sibling) in siblings.enumerated() {
            transaction.setSortIndex(position, on: sibling)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "Moved \(store.object(id: item).map { AddListItem.shownTitle($0.title, store: store) } ?? "it")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let title = store.object(id: item).map({ AddListItem.shownTitle($0.title, store: store) })
        else { return nil }
        let name = title.prefix(1).uppercased() + title.dropFirst()
        return section.map { $0.isEmpty ? "\(name), moved" : "\(name), moved to \($0)" } ?? "\(name), moved"
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

    public func receipt(in _: ObjectStore) -> String? {
        "\(from), now \(to)"
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
        // A reusable list never loses an item: clearing what is done unchecks it instead (slice 4).
        if ListContents(store: transaction.store, classes: transaction.classes).isReusable(list) {
            return try ResetList(list: list.id).apply(&transaction)
        }
        // Nothing checked: nothing to clear, so no op and no receipt (G15). Like AddGroceries with nothing to add, it
        // throws, and `perform` rolls back and logs nothing.
        let cleared = try transaction.clearDone(in: list)
        guard cleared > 0 else {
            throw ActionError.invalidArguments(
                action: Self.descriptor.name,
                reason: "nothing checked on \(ListContents.shownName(of: list, in: transaction.store))"
            )
        }
        return cleared
    }

    public func summary(in store: ObjectStore) -> String {
        "Cleared \(store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        receipt(in: store, output: 1)
    }

    /// From this run's own count (QA on #826): a reusable list was reset, not cleared, and its items are all still
    /// there; with nothing checked it says so.
    public func receipt(in store: ObjectStore, output: Int) -> String? {
        if let object = store.object(id: list), ListNoteTags.isReusable(object, in: store) {
            return ResetList.receipt(for: list, unchecked: output, in: store)
        }
        let title = store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "The list"
        return "\(title), done items cleared"
    }
}

extension Transaction {
    /// Soft-deletes the checked items of a list and returns how many; writes nothing when there are none.
    mutating func clearDone(in list: ObjectRecord) throws -> Int {
        let done = list.orderedChildren.filter { store.value("isDone", of: $0) == .bool(true) }
        for item in done {
            delete(item)
        }
        if !done.isEmpty, list.id == Groceries.listID {
            try refreshShopLine()
        }
        return done.count
    }
}

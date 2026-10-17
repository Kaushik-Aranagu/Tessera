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
                reason: "\(ListContents.shownName(of: list, in: transaction.store)) is already \(isOn ? "reusable" : "not reusable")"
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

/// Copies a list under a new name: the same sections and items, all open, in one op; the original is untouched. Nothing
/// in the API or the copy says "template" (lists-acceptance.md 4c, decisions: "Lisbon, copied from Packing.").
public struct CopyList: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "copyList",
        summary: "Copy a list under a new name, all items open",
        parameters: [
            .init("list", .object, "The list to copy"),
            .init("name", .string, "The new list's name"),
        ],
        isOfferedToModel: false
    )

    public var list: UUID
    public var name: String

    /// Whether the last `apply` found the name already a list (it made nothing). Not part of the encoding.
    private let outcome = Outcome()

    private final class Outcome: @unchecked Sendable {
        var wasRepeat = false
    }

    private enum CodingKeys: String, CodingKey {
        case list, name
    }

    public init(list: UUID, name: String) {
        self.list = list
        self.name = name
    }

    /// Whether a copy's record found its name already a list (it made nothing), for the screen.
    @MainActor
    public static func wasRepeat(_ record: OpRecord) -> Bool {
        guard record.action == descriptor.name else { return false }
        return !record.ops.contains {
            if case .create = $0 {
                true
            } else {
                false
            }
        }
    }

    /// An item's notes without the list flags and the pick stamp: those do not copy.
    private static func plainNotes(_ text: String?) -> String? {
        let kept = ListNoteTags.lines(text).filter { line in
            ![ListNoteTags.reusable, ListNoteTags.pickOne].contains(line)
                && ListNoteTags.stampDate(ListNoteTags.pickedPrefix, line: line) == nil
        }
        return kept.isEmpty ? nil : kept.joined(separator: "\n")
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        outcome.wasRepeat = false
        let source = try transaction.object(list, is: .list)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = Self.descriptor.name
        guard !name.isEmpty else {
            throw ActionError.invalidArguments(action: action, reason: "the copy needs a name")
        }
        // A name with a secret word in it, or a key, is never a list name: it would sit on screen and in the log.
        guard !looksLikeClaudeKey(name), !SecretWords.mentions(name) else {
            throw ActionError.invalidArguments(action: action, reason: "that can't be a list name")
        }
        guard source.id != Groceries.listID, name.lowercased() != "groceries" else {
            throw ActionError.invalidArguments(action: action, reason: "Groceries can't be copied")
        }
        // A name that is already a list opens that list, as CreateList does: nothing is copied (13.2, FG5).
        if let existing = CreateList.existing(named: name, in: transaction.store, classes: transaction.classes) {
            outcome.wasRepeat = true
            return existing
        }
        let copy = try transaction.create(transaction.classDef(.list), title: name)
        // Only a reusable source keeps its flag; #pick-one and "picked:" never copy.
        if ListNoteTags.isReusable(source, in: transaction.store) {
            try transaction.set("notes", to: .richText(ListNoteTags.reusable), on: copy)
        }
        var index = 0
        for item in source.orderedChildren {
            let row = try transaction.create(transaction.classDef(.listItem), title: item.title, parent: copy)
            transaction.setSortIndex(index, on: row)
            index += 1
            for key in ["quantity", "section"] {
                if let value = transaction.store.value(key, of: item), transaction.store.hasOwnValue(key, on: item) {
                    try transaction.set(key, to: value, on: row)
                }
            }
            if let notes = Self.plainNotes(transaction.store.value("notes", of: item)?.stringValue) {
                try transaction.set("notes", to: .richText(notes), on: row)
            }
        }
        return copy
    }

    /// A walled name never lands in the log or the line: "Private list".
    @MainActor
    private func shown(_ text: String, in store: ObjectStore) -> String {
        ObjectPrivacy.isPrivateWord(text, in: store) ? ListContents.privateListLabel : text
    }

    @MainActor
    private func sourceName(in store: ObjectStore) -> String {
        store.object(id: list).map { ListContents.shownName(of: $0, in: store) } ?? "the list"
    }

    public func summary(in store: ObjectStore) -> String {
        "Copied \(sourceName(in: store)) to \(shown(name.trimmingCharacters(in: .whitespacesAndNewlines), in: store))"
    }

    public func receipt(in store: ObjectStore) -> String? {
        let shown = shown(name.trimmingCharacters(in: .whitespacesAndNewlines), in: store)
        return outcome.wasRepeat ? "\(shown), already a list" : "\(shown), copied from \(sourceName(in: store))"
    }

    /// From the run's own list: a repeat prints the existing list's title, not the typed name (Design on #866).
    public func receipt(in store: ObjectStore, output: ObjectRecord) -> String? {
        let shown = ListContents.shownName(of: output, in: store)
        return outcome.wasRepeat ? "\(shown), already a list" : "\(shown), copied from \(sourceName(in: store))"
    }
}

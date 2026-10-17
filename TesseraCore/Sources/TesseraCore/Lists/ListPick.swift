import Foundation

/// Pick one (ship list slice 7): choose one open item for "what to watch", "what to cook", "which chore first".
/// Picking is a read: it never checks an item and writes nothing. Accepting a pick (opening it) stamps `pickedAt`; a
/// skip stamps nothing. The stamp is a `picked:` line in the item's existing `notes` (the catalog is frozen at v9).
public extension ListContents {
    /// An item picked within this long is passed over while others are left (Product, ship list: 7 days).
    static let pickWindow: TimeInterval = 7 * 86400

    /// Whether the list has the Pick one option on.
    func isPickOne(_ list: ObjectRecord) -> Bool {
        ListNoteTags.has(ListNoteTags.pickOne, in: store.value("notes", of: list)?.stringValue)
    }

    /// When the item was last picked and accepted, if ever.
    func pickedAt(_ item: ObjectRecord) -> Date? {
        ListNoteTags.stamp(ListNoteTags.pickedPrefix, in: store.value("notes", of: item)?.stringValue)
    }

    /// One open item, chosen at random among those not picked in the last 7 days; when every one of them was, among
    /// all that are open. `excluding` holds the ones already skipped this round: with none left it is nil (the pick
    /// moment's "That's all of them"). Nil too for an empty or finished list.
    func pick(from list: ObjectRecord, excluding skipped: Set<UUID> = [], now: Date = .now,
              using generator: inout some RandomNumberGenerator) -> Item?
    {
        let candidates = open(in: list).filter { !skipped.contains($0.id) }
        let fresh = candidates.filter { item in
            pickedAt(item.object).map { now.timeIntervalSince($0) >= Self.pickWindow } ?? true
        }
        return (fresh.isEmpty ? candidates : fresh).randomElement(using: &generator)
    }

    /// `pick(from:)` with the system's random numbers.
    func pick(from list: ObjectRecord, excluding skipped: Set<UUID> = [], now: Date = .now) -> Item? {
        var generator = SystemRandomNumberGenerator()
        return pick(from: list, excluding: skipped, now: now, using: &generator)
    }
}

/// Turns the Pick one option on or off for a list.
public struct SetListPickOne: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setListPickOne",
        summary: "Turn Pick one on or off for a list",
        parameters: [
            .init("list", .object, "The list"),
            .init("on", .boolean, "False to turn it off", required: false),
        ],
        isOfferedToModel: false
    )

    public var list: UUID
    public var on: Bool? // swiftlint:disable:this identifier_name

    public init(list: UUID, on: Bool? = true) { // swiftlint:disable:this identifier_name
        self.list = list
        self.on = on
    }

    public func apply(_ transaction: inout Transaction) throws {
        let list = try transaction.object(list, is: .list)
        let isOn = on ?? true
        let notes = transaction.store.value("notes", of: list)?.stringValue
        guard ListNoteTags.has(ListNoteTags.pickOne, in: notes) != isOn else {
            throw ActionError.invalidArguments(
                action: Self.descriptor.name,
                reason: "Pick one is already \(isOn ? "on" : "off") for \(list.title)"
            )
        }
        let updated = ListNoteTags.setting(ListNoteTags.pickOne, to: isOn, in: notes)
        try transaction.set("notes", to: updated.map(FieldValue.richText), on: list)
    }

    public func summary(in store: ObjectStore) -> String {
        "Turned Pick one \(on ?? true ? "on" : "off") for \(store.object(id: list)?.title ?? "the list")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        "\(store.object(id: list)?.title ?? "The list"), pick one \(on ?? true ? "on" : "off")"
    }
}

/// Accepts a pick: the item was opened, so it is stamped `pickedAt` and passed over for the next 7 days. It is never
/// checked. A skip is not an action at all. Undo restores the stamp it had.
public struct AcceptPick: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "acceptPick",
        summary: "Take a pick: open the item that was picked",
        parameters: [
            .init("item", .object, "The item that was picked"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isOfferedToModel: false
    )

    public var item: UUID
    public var time: Date?

    public init(item: UUID, time: Date? = nil) {
        self.item = item
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let item = try transaction.object(item, is: .listItem)
        let notes = transaction.store.value("notes", of: item)?.stringValue
        let updated = ListNoteTags.setting(stamp: ListNoteTags.pickedPrefix, to: time ?? .now, in: notes)
        try transaction.set("notes", to: updated.map(FieldValue.richText), on: item)
    }

    public func summary(in store: ObjectStore) -> String {
        guard let object = store.object(id: item) else { return "Picked an item" }
        return "Picked \(AddListItem.shownTitle(object.title, store: store)) from \(object.parent?.title ?? "the list")"
    }

    /// Thing first, the list by name: "Heat, from Films". A medicine or body fact reads "Private item".
    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        let shown = AddListItem.shownTitle(object.title, store: store)
        return "\(shown.prefix(1).uppercased() + shown.dropFirst()), from \(object.parent?.title ?? "the list")"
    }
}

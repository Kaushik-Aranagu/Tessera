import Foundation

// Taking a room down (Design sheet 371): a room is only a view over his things, so taking it down never deletes them.
// It sets `archivedAt` on the room in one op group: the room leaves the dial, its history goes with it, and its grants
// stop (a taken-down room has none). Nothing it binds to is touched. Undo, or "Bring back my plant room", reverts it.

public struct TakeDownRoom: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "takeDownRoom", summary: "Take a room down",
        parameters: [.init("room", .object, "The room")], isOfferedToModel: false
    )

    public var room: UUID

    public init(room: UUID) {
        self.room = room
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(room, is: .room)
        let book = RoomBook(store: transaction.store, classes: transaction.classes)
        guard !book.isTakenDown(object) else { return }
        // A change still waiting for his Allow keeps the room up: it would be a grant with no room to hold it.
        if RoomReach.isWaiting(object, in: transaction.store) {
            throw ActionError.invalidArguments(action: Self.descriptor.name,
                                               reason: "This room is waiting for your Allow, so it stays up")
        }
        try transaction.set("archivedAt", to: .date(transaction.now), on: object)
    }

    public func summary(in store: ObjectStore) -> String {
        "Took down \(store.object(id: room)?.title ?? "a room")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        "\(store.object(id: room)?.title ?? "Room"), taken down"
    }
}

/// "Bring back my plant room": the room, its history and its grants come back as they were.
public struct BringBackRoom: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "bringBackRoom", summary: "Bring a room back",
        parameters: [.init("room", .object, "The room")], isOfferedToModel: false
    )

    public var room: UUID

    public init(room: UUID) {
        self.room = room
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(room, is: .room)
        let book = RoomBook(store: transaction.store, classes: transaction.classes)
        guard book.isTakenDown(object) else { return }
        if book.room(named: object.title) != nil {
            throw ActionError.invalidArguments(action: Self.descriptor.name,
                                               reason: "There is already a \(object.title) up")
        }
        try transaction.set("archivedAt", to: nil, on: object)
    }

    public func summary(in store: ObjectStore) -> String {
        "Brought back \(store.object(id: room)?.title ?? "a room")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        "\(store.object(id: room)?.title ?? "Room"), back"
    }
}

public extension RoomBook {
    /// The taken-down room with this name that he most recently took down.
    func takenDownRoom(named name: String) -> ObjectRecord? {
        takenDownRooms()
            .filter { $0.title.caseInsensitiveCompare(name) == .orderedSame }
            .max { (store.value("archivedAt", of: $0)?.dateValue ?? .distantPast)
                < (store.value("archivedAt", of: $1)?.dateValue ?? .distantPast)
            }
    }
}

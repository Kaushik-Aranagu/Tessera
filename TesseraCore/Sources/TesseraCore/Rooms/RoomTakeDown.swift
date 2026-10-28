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
        try transaction.set("restoredAt", to: .date(transaction.now), on: object)
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

/// The first open of a room that was brought back clears the mark that a replay is owed (a marker only; the replay
/// itself writes nothing).
public struct MarkRoomOpened: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "markRoomOpened", summary: "Note that a restored room was opened",
        parameters: [.init("room", .object, "The room")], isOfferedToModel: false
    )

    public var room: UUID

    public init(room: UUID) {
        self.room = room
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(room, is: .room)
        try transaction.set("restoredAt", to: nil, on: object)
    }

    public func summary(in _: ObjectStore) -> String {
        "Opened a restored room"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// A room coming back the way it was made (Design sheet 372): the sentences that changed it, in order, each with the
/// room as it stood after it. Builder A plays them against today's data; the replay is display only and writes nothing.
@MainActor
public enum RoomReplay {
    public struct Step: Equatable, Sendable {
        /// What he said.
        public let note: String
        public let at: Date
        /// The room right after this sentence.
        public let document: RoomDocument
    }

    /// Whether a replay is owed: the room was brought back and not opened since.
    public static func isOwed(_ room: ObjectRecord, in store: ObjectStore) -> Bool {
        store.value("restoredAt", of: room)?.dateValue != nil
    }

    /// The patches that changed the room, oldest first. A sentence that left the room as it was (a refusal, a repeat)
    /// is not a step.
    public static func steps(of room: String, engine: ActionEngine) throws -> [Step] {
        let entries = RoomHistory.entries(of: room, engine: engine).sorted { $0.at < $1.at }
        let fork = try engine.store.fork()
        let classes = try SystemCatalog.seed(in: fork.context)
        let copy = ActionEngine(store: fork, classes: classes)
        let records = entries.compactMap { entry in
            fork.context.all(OpRecord.self).first { $0.id == entry.record }
        }
        for record in records.reversed() {
            copy.undo(record)
        }
        let book = RoomBook(store: fork, classes: classes)
        var previous: RoomDocument?
        var steps: [Step] = []
        for (entry, record) in zip(entries, records) {
            copy.redo(record)
            guard let object = book.room(named: room) else { continue }
            let document = book.document(of: object)
            if document != previous {
                steps.append(Step(note: entry.note, at: entry.at, document: document))
            }
            previous = document
        }
        return steps
    }
}

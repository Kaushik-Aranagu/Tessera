import Foundation

// The room remembers every sentence (Design sheet 362, R1 spec): the history is the room's op log filtered to its patch
// groups, each with the sentence as its note. Going back writes one op group (the room as it was), through the same
// write the patch uses, so it is one Undo and nothing is ever lost: going back is itself a change in the history.

@MainActor
public enum RoomHistory {
    public struct Entry: Equatable, Sendable {
        public let record: UUID
        /// What he said (or "Back to 1:18 pm", "Ring, queued").
        public let note: String
        public let at: Date
        public let state: OpState
    }

    static func note(room: String, sentence: String) -> String {
        "Told \(room): \(sentence)"
    }

    private static let actions: Set<String> = [PatchRoom.descriptor.name, GoBackRoom.descriptor.name,
                                               QueueRoomPart.descriptor.name]

    /// Every sentence said to a room, newest first: groups that are applied (committed or still drying), not undone.
    public static func entries(of room: String, engine: ActionEngine) -> [Entry] {
        let prefix = "Told \(room): "
        return engine.store.context.all(OpRecord.self)
            .filter { actions.contains($0.action) && $0.summary.hasPrefix(prefix) && $0.state != .undone }
            .sorted { $0.createdAt > $1.createdAt }
            .map { Entry(record: $0.id, note: String($0.summary.dropFirst(prefix.count)), at: $0.createdAt,
                         state: $0.state) }
    }

    /// The room as it stood right after one entry: the later groups undone on a copy, so nothing real is touched.
    public static func version(of room: String, after entry: Entry, engine: ActionEngine) throws -> RoomDocument? {
        let fork = try engine.store.fork()
        let classes = try SystemCatalog.seed(in: fork.context)
        let copy = ActionEngine(store: fork, classes: classes)
        let later = entries(of: room, engine: engine).filter { $0.at > entry.at }.sorted { $0.at > $1.at }
        for item in later {
            if let record = fork.context.all(OpRecord.self).first(where: { $0.id == item.record }) {
                copy.undo(record)
            }
        }
        let book = RoomBook(store: fork, classes: classes)
        return book.room(named: room).map(book.document(of:))
    }

    /// "Go back": one new op group that sets the room to how it was after `entry`.
    @discardableResult
    public static func goBack(room: String, to entry: Entry, label: String, engine: ActionEngine,
                              by actor: Actor = .user) throws -> OpRecord?
    {
        guard let document = try version(of: room, after: entry, engine: engine),
              let object = RoomBook(store: engine.store, classes: engine.classes).room(named: room) else { return nil }
        return try engine.perform(GoBackRoom(room: object.id, to: document, label: label), by: actor).record
    }
}

/// Sets a room to a document it had before, as one op group.
public struct GoBackRoom: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "goBackRoom", summary: "Put a room back how it was",
        parameters: [.init("room", .object, "The room"), .init("to", .json, "The room as it was")],
        isOfferedToModel: false
    )

    public var room: UUID
    public var to: RoomDocument
    /// "Back to 1:18 pm"
    public var label: String

    public init(room: UUID, to: RoomDocument, label: String) {
        self.room = room
        self.to = to
        self.label = label
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(room, is: .room)
        let book = RoomBook(store: transaction.store, classes: transaction.classes)
        try PatchRoom.write(to, over: book.document(of: object), on: object, in: &transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        RoomHistory.note(room: store.object(id: room).map(\.title) ?? "room", sentence: label)
    }

    public func receipt(in _: ObjectStore) -> String? {
        label
    }
}

/// Puts a part the kit lacks on the room's install queue (or takes it off): an undoable list in the room's settings
/// that the install notes read. R5's Mac part builder works through it.
public struct QueueRoomPart: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "queueRoomPart", summary: "Queue a part for the next install",
        parameters: [.init("room", .string, "The room's name"), .init("part", .string, "The part, as he said it")],
        isOfferedToModel: false
    )

    public var room: String
    public var part: String

    public init(room: String, part: String) {
        self.room = room
        self.part = part
    }

    public func apply(_ transaction: inout Transaction) throws {
        let book = RoomBook(store: transaction.store, classes: transaction.classes)
        let object = try book.room(named: room) ?? transaction.create(transaction.classDef(.room), title: room)
        let current = transaction.store.value("queue", of: object)?.stringValue
            .flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) } ?? []
        let name = part.trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.isEmpty, !current.contains(name) else { return }
        try transaction.set("queue", to: .text(RoomDocument.text(current + [name])), on: object)
    }

    public func summary(in _: ObjectStore) -> String {
        RoomHistory.note(room: room, sentence: "\(part.capitalized), queued")
    }

    public func receipt(in _: ObjectStore) -> String? {
        "\(part.capitalized), queued for your next install"
    }
}

public extension RoomBook {
    /// The parts he asked for that the kit does not have yet, for the install notes.
    func queue(of room: ObjectRecord) -> [String] {
        store.value("queue", of: room)?.stringValue
            .flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) } ?? []
    }
}

/// What a sentence's patch turned into: written (a ghost), or refused with Tess's words and maybe an offer.
@MainActor
public enum RoomPatcher {
    public enum Outcome {
        case applied(OpRecord, PatchRoom.Output)
        /// Nothing changed, or only the install queue did (`queued` is its record, for Undo).
        case refused(RoomRefusal, queued: OpRecord?)
    }

    /// Runs a patch the way the room does: house rules first, then one pending op group as Tess. `picked` is the place
    /// he has picked for 30 s, which the patch must stay inside.
    public static func apply(_ patch: RoomPatch, sentence: String, picked: String? = nil, engine: ActionEngine,
                             pending: Bool = true) throws -> Outcome
    {
        let book = RoomBook(store: engine.store, classes: engine.classes)
        let current = book.room(named: patch.room).map(book.document(of:)) ?? RoomDocument(name: patch.room)
        if let refusal = RoomRefusals.refusal(for: patch, against: current, store: engine.store,
                                              classes: engine.classes, picked: picked)
        {
            var queued: OpRecord?
            if let part = refusal.queue {
                queued = try engine.perform(QueueRoomPart(room: patch.room, part: part), by: .tess, pending: pending)
                    .record
            }
            return .refused(refusal, queued: queued)
        }
        let result = try engine.perform(PatchRoom(patch: patch, sentence: sentence), by: .tess, pending: pending)
        return .applied(result.record, result.output)
    }
}

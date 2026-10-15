import Foundation

/// Notes (M2 slice 5): plain text with @ links to any object. "@Bench Press felt heavy" links the note to Bench
/// Press, so it shows in Bench Press's backlinks. Brackets take any name: "@[Push Day A]".
@MainActor
public struct NoteList {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Newest edit first.
    public func recent(limit: Int = 50) -> [ObjectRecord] {
        guard let noteClass = classes[.note] else { return [] }
        return Array(store.objects(of: noteClass).sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }

    /// Notes that link to an object, or to a class (through its class object), newest first.
    public func notes(about object: ObjectRecord) -> [ObjectRecord] {
        guard let noteClass = classes[.note] else { return [] }
        return store.backlinks(to: object)
            .filter { $0.classDef.map { store.isSubclass($0, ofClassID: noteClass.id) } == true }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func notes(about classDef: ClassDef) -> [ObjectRecord] {
        store.classObject(of: classDef).map(notes(about:)) ?? []
    }

    /// Objects an @ mention can name: every titled object (not soft-deleted) and every concrete class. A class
    /// with no class object yet gets one from `classObject` (the transaction's, so it's in the op log); reading
    /// without one links only class objects that exist.
    func resolve(_ name: String, classObject: ((ClassDef) -> ObjectRecord?)? = nil) -> ObjectRecord? {
        let needle = name.lowercased()
        if let classDef = store.allClasses().first(where: { $0.name.lowercased() == needle }) {
            return classObject?(classDef) ?? store.classObject(of: classDef)
        }
        return store.context.all(ObjectRecord.self)
            .filter { !$0.isDeleted && !$0.isClassObject && $0.title.lowercased() == needle }
            .min { $0.createdAt < $1.createdAt }
    }

    /// The objects a body mentions, in order, without repeats. "@[Long Name]" or "@Name", trying the longest
    /// run of up to four words first so "@Bench Press felt heavy" finds Bench Press.
    public func mentions(in body: String) -> [ObjectRecord] {
        mentions(in: body, classObject: nil)
    }

    func mentions(in body: String, classObject: ((ClassDef) -> ObjectRecord?)?) -> [ObjectRecord] {
        var found: [ObjectRecord] = []
        var seen = Set<UUID>()
        func add(_ object: ObjectRecord?) {
            if let object, seen.insert(object.id).inserted {
                found.append(object)
            }
        }
        for match in body.matches(of: /@\[([^\]]+)\]/) {
            add(resolve(String(match.1), classObject: classObject))
        }
        for match in body.matches(of: /@([^\s@\[][^@\n]*)/) {
            // Trim punctuation from the candidate's ends only, so "@Mac & Cheese was great" finds "Mac & Cheese".
            let words = match.1.split(separator: " ").map(String.init)
            for count in stride(from: min(4, words.count), through: 1, by: -1) {
                let candidate = words.prefix(count).joined(separator: " ")
                    .trimmingCharacters(in: .punctuationCharacters)
                if let object = resolve(candidate, classObject: classObject) {
                    add(object)
                    break
                }
            }
        }
        return found
    }
}

/// Writes a note; its @ mentions become links (and backlinks on what it mentions).
public struct CreateNote: EngineAction {
    public static let descriptor = ActionDescriptor(name: "createNote", summary: "Write a note", parameters: [
        .init("body", .string, "The text; @Name links to things"),
        .init("title", .string, "Defaults to the first line", required: false),
    ])

    public var body: String
    public var title: String?

    public init(body: String, title: String? = nil) {
        self.body = body
        self.title = title
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "the note is empty")
        }
        let note = try transaction.create(transaction.classDef(.note), title: title ?? Self.firstLine(text))
        try transaction.set("body", to: .text(text), on: note)
        try transaction.linkMentions(of: note, body: text)
        return note
    }

    static func firstLine(_ text: String) -> String {
        let line = text.split(separator: "\n").first.map(String.init) ?? text
        return line.count > 60 ? String(line.prefix(59)) + "…" : line
    }

    public func summary(in _: ObjectStore) -> String {
        "Noted"
    }
}

/// Changes a note's text (and so its links) or title.
public struct EditNote: EngineAction {
    public static let descriptor = ActionDescriptor(name: "editNote", summary: "Change a note", parameters: [
        .init("note", .object, "The note"),
        .init("body", .string, "New text", required: false),
        .init("title", .string, "New title", required: false),
    ])

    public var note: UUID
    public var body: String?
    public var title: String?

    public init(note: UUID, body: String? = nil, title: String? = nil) {
        self.note = note
        self.body = body
        self.title = title
    }

    public func apply(_ transaction: inout Transaction) throws {
        let note = try transaction.object(note, is: .note)
        if let body {
            try transaction.set("body", to: .text(body), on: note)
            try transaction.linkMentions(of: note, body: body)
        }
        if let title {
            transaction.setTitle(title, on: note)
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Note updated"
    }
}

extension Transaction {
    mutating func linkMentions(of note: ObjectRecord, body: String) throws {
        var created: [ClassDef] = []
        let store = store
        // First pass: which classes need a class object; create those through this transaction, then link.
        _ = NoteList(store: store, classes: classes).mentions(in: body) { classDef in
            if store.classObject(of: classDef) == nil {
                created.append(classDef)
            }
            return nil
        }
        for classDef in created {
            ensureClassObject(of: classDef)
        }
        let mentioned = NoteList(store: store, classes: classes).mentions(in: body)
        try setLinks("about", on: note, to: mentioned)
    }

    /// A class's class object, created in this transaction (so undo removes it) when it's missing.
    @discardableResult
    mutating func ensureClassObject(of classDef: ClassDef) -> ObjectRecord {
        if let existing = store.classObject(of: classDef) {
            return existing
        }
        let object = create(classDef, title: classDef.name)
        object.isClassObject = true
        store.invalidateCaches()
        return object
    }
}

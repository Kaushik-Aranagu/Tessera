import Foundation

// Together piece 6, Make a kind (product sheet 135; switch makeAKind, app-side, default Off). When one word keeps
// coming up in his notes, Tess offers once to make it a kind of thing ("Things you write about a lot can be a kind
// of thing"). Engine only, all on the phone: no word, note or field name ever goes to a model. A private or walled
// note never counts, and a walled word is never offered, made or titled.

/// The one word worth offering a kind for today: at least 4 of his plain notes in the last 30 days name it.
public struct KindOffer: Equatable, Sendable {
    public static let minimumNotes = 4
    public static let windowDays = 30

    /// The word as he writes it (the thing's title).
    public let word: String
    /// The notes that name it in the window, newest first. Never a private note.
    public let noteIDs: [UUID]

    /// At most one offer. Counts the notes linked to a thing (the "things" of the Notes landing) made in the last
    /// 30 days; skips private notes, walled words, class objects and a word that already names a class. The busiest
    /// word wins, ties go to the one written about most recently.
    @MainActor
    public static func today(engine: ActionEngine, now: Date = .now, calendar: Calendar = .current) -> KindOffer? {
        let store = engine.store
        let landing = NotesLanding(store: store, classes: engine.classes)
        guard let start = calendar.date(byAdding: .day, value: -windowDays, to: now) else { return nil }
        let taken = Set(store.allClasses().map { $0.name.lowercased() })
        let noteClassID = engine.classes[.note]?.id
        struct Tally {
            var word: String
            var notes: [ObjectRecord] = []
        }
        var tallies: [String: Tally] = [:]
        for note in landing.notes() where note.createdAt >= start && note.createdAt <= now && !landing.isPrivate(note) {
            for object in landing.linked(note) {
                guard !object.isClassObject, object.classDef?.id != noteClassID else { continue }
                let word = object.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let key = word.lowercased()
                guard !word.isEmpty, !taken.contains(key), !KindRules.isWalled(word, in: store),
                      ObjectPrivacy.label(of: object, in: store, classes: engine.classes) == nil
                else { continue }
                var tally = tallies[key] ?? Tally(word: word)
                if !tally.notes.contains(where: { $0.id == note.id }) {
                    tally.notes.append(note)
                }
                tallies[key] = tally
            }
        }
        func newest(_ tally: Tally) -> Date {
            tally.notes.map(\.createdAt).max() ?? .distantPast
        }
        let best = tallies.values.filter { $0.notes.count >= minimumNotes }.max { left, right in
            left.notes.count != right.notes.count ? left.notes.count < right.notes.count : newest(left) < newest(right)
        }
        return best.map { tally in
            KindOffer(word: tally.word,
                      noteIDs: tally.notes.sorted { $0.createdAt > $1.createdAt }.map(\.id))
        }
    }
}

enum KindRules {
    static let maxFields = 6
    static let maxFieldNameLength = 40
    /// The reference field every new kind carries, pointing at the note an object was kept from.
    static let sourceNoteKey = "sourceNote"

    /// A word or field name that is a secret, money, a body fact or a key: it never becomes a name.
    @MainActor
    static func isWalled(_ text: String, in store: ObjectStore) -> Bool {
        ObjectPrivacy.isPrivateWord(text, in: store) || SecretWords.mentions(text) || looksLikeClaudeKey(text)
    }

    /// "Bench press" for "bench press": the first letter up, the rest as he typed it.
    static func capitalized(_ word: String) -> String {
        word.prefix(1).uppercased() + word.dropFirst()
    }

    /// A field key from its name: "Due date" is "dueDate"; empty when no letter or digit is left.
    static func key(for name: String) -> String {
        let parts = name.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        guard let first = parts.first else { return "" }
        return first.lowercased() + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined()
    }

    /// A note that is private by its flag, its title or its words, or one that is gone.
    @MainActor
    static func isPrivate(_ note: ObjectRecord, in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> Bool {
        NotesLanding(store: store, classes: classes).isPrivate(note)
    }

    @MainActor
    static func firstTextField(of classDef: ClassDef, in _: ObjectStore) -> String? {
        let own = (classDef.ownFields ?? []).filter { $0.kind == .text && $0.overridesFieldID == nil }
            .min { $0.sortIndex < $1.sortIndex }
        return own?.key ?? ClassResolver.effectiveFields(of: classDef).first { $0.kind == .text }?.key
    }
}

/// Makes a word a kind of thing: a class under Thing named after it, with the plain text fields he named. One op,
/// one UNDO (undo removes the class and its fields). Not offered to Tess or the model.
public struct MakeKind: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "makeKind",
        summary: "Make a word a kind of thing",
        parameters: [
            .init("word", .string, "The word, e.g. Landlord"),
            .init("fields", .json, "Up to 6 text field names", required: false),
        ],
        isOfferedToModel: false
    )

    public var word: String
    public var fields: [String]

    public init(word: String, fields: [String] = []) {
        self.word = word
        self.fields = fields
    }

    public func apply(_ transaction: inout Transaction) throws -> ClassDef {
        let name = KindRules.capitalized(word.trimmingCharacters(in: .whitespacesAndNewlines))
        func refuse(_ reason: String) -> ActionError {
            .invalidArguments(action: Self.descriptor.name, reason: reason)
        }
        let store = transaction.store
        guard !name.isEmpty else { throw refuse("a kind needs a word") }
        guard !KindRules.isWalled(name, in: store) else { throw refuse("that can't be a kind") }
        guard !store.allClasses().contains(where: { $0.name.lowercased() == name.lowercased() }) else {
            throw refuse("that is already a kind")
        }
        var names: [String] = []
        for raw in fields {
            let field = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !field.isEmpty else { throw refuse("a field needs a name") }
            guard field.count <= KindRules.maxFieldNameLength, !KindRules.isWalled(field, in: store),
                  !KindRules.key(for: field).isEmpty, KindRules.key(for: field) != KindRules.sourceNoteKey
            else { throw refuse("that can't be a field") }
            if !names.contains(where: { $0.lowercased() == field.lowercased() }) {
                names.append(field)
            }
        }
        guard names.count <= KindRules.maxFields else { throw refuse("a kind holds up to 6 fields") }
        let thing = try transaction.classDef(.thing)
        let classDef = transaction.createClass(name: name, parent: thing, symbolName: thing.symbolName,
                                               colorRole: thing.colorRole)
        var taken = Set(ClassResolver.effectiveFields(of: classDef).map(\.key))
        for (index, field) in names.enumerated() {
            var key = KindRules.key(for: field)
            var suffix = 2
            while taken.contains(key) {
                key = KindRules.key(for: field) + String(suffix)
                suffix += 1
            }
            taken.insert(key)
            let def = FieldDef(name: field, key: key, kind: .text, sortIndex: index)
            def.owner = classDef
            store.context.insert(def)
        }
        // Additive, outside the 6-field limit: where an object kept from a note points back to it.
        let source = FieldDef(name: "Source note", key: KindRules.sourceNoteKey, kind: .ref, sortIndex: names.count)
        source.targetClassID = try transaction.classDef(.note).id
        source.owner = classDef
        store.context.insert(source)
        store.invalidateCaches()
        return classDef
    }

    /// Generic: the op log holds no word and no field name.
    public func summary(in _: ObjectStore) -> String {
        "Kind made"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output kind: ClassDef) -> String? {
        KindRules.isWalled(kind.name, in: store) ? "Private kind" : "\(kind.name), made."
    }
}

/// Turns one note into an object of a kind: titled from its first line, its text in the kind's first text field, and
/// pointing back at the note through its `sourceNote` field. The note is not touched at all. Refuses a private
/// or deleted note.
public struct KeepNoteAsObject: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "keepNoteAsObject",
        summary: "Keep a note as an object of a kind",
        parameters: [
            .init("note", .object, "The note"),
            .init("kind", .classRef, "The kind"),
        ],
        isOfferedToModel: false
    )

    public var note: UUID
    public var kind: UUID

    public init(note: UUID, kind: UUID) {
        self.note = note
        self.kind = kind
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        guard let classDef = transaction.store.classDef(id: kind) else { throw ActionError.objectNotFound(kind) }
        let record = try transaction.object(note, is: .note)
        guard !KindRules.isPrivate(record, in: transaction.store, classes: transaction.classes) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that note is private")
        }
        return try Self.keep(record, as: classDef, in: &transaction)
    }

    @MainActor
    static func keep(_ record: ObjectRecord, as classDef: ClassDef, in transaction: inout Transaction) throws
        -> ObjectRecord
    {
        let store = transaction.store
        let text = store.value("body", of: record)?.stringValue ?? record.title
        let object = transaction.create(classDef, title: CreateNote.firstLine(text))
        if let field = KindRules.firstTextField(of: classDef, in: store) {
            try transaction.set(field, to: .text(text), on: object)
        }
        // The object points at its note; the note is never edited. A kind made before `sourceNote` existed has no
        // such field, and then nothing is linked at all (the object is still made).
        if ClassResolver.field(KindRules.sourceNoteKey, of: classDef) != nil {
            try transaction.setLinks(KindRules.sourceNoteKey, on: object, to: [record])
        }
        return object
    }

    public func summary(in _: ObjectStore) -> String {
        "Note kept"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output object: ObjectRecord) -> String? {
        guard let name = object.classDef?.name, !KindRules.isWalled(name, in: store) else { return "Kept." }
        return "Kept as \(name)."
    }
}

/// Keeps every given note as an object of the kind: one op, one UNDO. A private or deleted note is skipped, not an
/// error; the output is how many were kept.
public struct KeepAllNotes: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "keepAllNotes",
        summary: "Keep notes as objects of a kind",
        parameters: [
            .init("notes", .json, "The notes' ids"),
            .init("kind", .classRef, "The kind"),
        ],
        isOfferedToModel: false
    )

    public var notes: [UUID]
    public var kind: UUID

    public init(notes: [UUID], kind: UUID) {
        self.notes = notes
        self.kind = kind
    }

    public func apply(_ transaction: inout Transaction) throws -> Int {
        guard let classDef = transaction.store.classDef(id: kind) else { throw ActionError.objectNotFound(kind) }
        var kept = 0
        var seen = Set<UUID>()
        for id in notes where seen.insert(id).inserted {
            guard let record = try? transaction.object(id, is: .note),
                  !KindRules.isPrivate(record, in: transaction.store, classes: transaction.classes)
            else { continue }
            _ = try KeepNoteAsObject.keep(record, as: classDef, in: &transaction)
            kept += 1
        }
        return kept
    }

    public func summary(in _: ObjectStore) -> String {
        "Notes kept"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in _: ObjectStore, output kept: Int) -> String? {
        "\(kept) kept."
    }
}

/// What an object made from a note says about where it came from. Read on every look: a note that has turned private
/// since reads "Private note", never its title.
@MainActor
public enum KindSource {
    public static func line(of object: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef])
        -> String?
    {
        guard let source = store.linkedObjects(KindRules.sourceNoteKey, of: object).first, !source.isDeleted else {
            return nil
        }
        return ObjectPrivacy.shownLabel(of: source, in: store, classes: classes) ?? source.title
    }
}

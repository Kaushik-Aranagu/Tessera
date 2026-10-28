import Foundation

// An object's plain page and the layers over it (Design sheets 375 to 378). Nobody designed a page for a plant, so it
// gets the class's plain page: title, one line from its two most recent fields, its first number in the keystone slot,
// its notes. That page is generated, not stored, until he changes it. A change said on a plant's page is a change to
// the class's page (every plant gets it); "just for the orchid" is a layer over that one object. Both layers are
// objects
// whose parts are `roomPart` children, so a patch is the same four ops and Undo is free. A write from the object's own
// page is his own op and goes through no room grant.

/// What a page change reached: the whole class (with how many pages that is) or one object.
public enum PageScope: Equatable, Sendable {
    case klass(name: String, count: Int)
    case object(id: UUID, title: String)

    /// The receipt: "Every plant's page, set", "The orchid's page, set".
    public func receipt(thing _: String) -> String {
        switch self {
        case let .klass(name, _): "Every \(name.lowercased())'s page, set"
        case let .object(_, title): "The \(title.lowercased())'s page, set"
        }
    }

    /// What Tess says, built from the scope and never from a fixed string.
    public func line(openedOn title: String) -> String {
        switch self {
        case let .klass(name, _): "Every \(name.lowercased())'s page has it now, not just the \(title.lowercased())'s"
        case let .object(_, name): "Only the \(name.lowercased())'s page, the others don't get it"
        }
    }
}

public enum PageTarget: Codable, Equatable, Sendable {
    /// Every page of a class, by class name.
    case klass(String)
    /// One object's own page.
    case object(UUID)
}

@MainActor
public struct PageBook {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    func layers() -> [ObjectRecord] {
        guard let layerClass = classes[.pageLayer] else { return [] }
        return store.objects(of: layerClass)
    }

    public func layer(forClass classDef: ClassDef) -> ObjectRecord? {
        layers().first { store.value("forClass", of: $0)?.stringValue == classDef.id.uuidString }
    }

    public func layer(forObject id: UUID) -> ObjectRecord? {
        layers().first { store.value("forObject", of: $0)?.stringValue == id.uuidString }
    }

    /// The parts of a layer, in order.
    func parts(of layer: ObjectRecord?) -> [RoomPart] {
        guard let layer else { return [] }
        return RoomBook(store: store, classes: classes).document(of: layer).parts
    }

    /// The plain page every object has until he says how it should look: generated, never stored.
    public func generated(for classDef: ClassDef) -> [RoomPart] {
        let fields = ClassResolver.effectiveFields(of: classDef)
            .filter { !["notes", "notTwins"].contains($0.key) && !$0.key.hasPrefix("_") }
        var parts = [RoomPart(id: "title", kind: "title", place: "title", props: ["text": .string("{title}")])]
        let line = fields.prefix(2).map { "{\($0.key)}" }.joined(separator: ", ")
        if !line.isEmpty {
            parts.append(RoomPart(id: "line", kind: "line", place: "caption", props: ["text": .string(line)]))
        }
        if let number = fields.first(where: { $0.kind == .number }) {
            parts.append(RoomPart(id: "number", kind: "number", place: "keystone",
                                  props: ["label": .string(number.name.lowercased()), "field": .string(number.key),
                                          "agg": .string("latest")]))
        }
        parts.append(RoomPart(
            id: "notes",
            kind: "lines",
            place: "page",
            props: ["lines": .array([.string("{notes}")])]
        ))
        return parts
    }

    /// The page an object shows: the class's page (stored if he changed it, else generated) with the object's own
    /// layer over it (a part with the same id replaces, any other is added after).
    public func page(for object: ObjectRecord) -> [RoomPart] {
        guard let classDef = object.classDef else { return [] }
        let base = layer(forClass: classDef).map { parts(of: $0) } ?? generated(for: classDef)
        var result = base
        for part in parts(of: layer(forObject: object.id)) {
            if let index = result.firstIndex(where: { $0.id == part.id }) {
                result[index] = part
            } else {
                result.append(part)
            }
        }
        return result
    }

    /// True for a part that belongs to the object's own layer, so the page can say "the misting is the orchid's own".
    public func isOwn(_ part: RoomPart, of object: ObjectRecord) -> Bool {
        parts(of: layer(forObject: object.id)).contains { $0.id == part.id }
    }

    /// What a part says on this object's page: tokens filled from the object itself.
    ///  {title}, {field}; {recent(field,3)} the last values of a date field, newest first ("Oct 25, Oct 21 and Oct
    /// 15");
    ///  {@link.title}, {@link.parent.title} through a ref field.
    public func text(_ template: String, for object: ObjectRecord, engine: ActionEngine? = nil,
                     calendar: Calendar = .current) -> String
    {
        var out = template.replacingOccurrences(of: "{title}", with: object.title)
        for field in object.classDef.map({ ClassResolver.effectiveFields(of: $0) }) ?? [] {
            let token = "{\(field.key)}"
            guard out.contains(token) else { continue }
            out = out.replacingOccurrences(of: token, with: shown(store.value(field.key, of: object), calendar))
        }
        out = fillRecent(out, for: object, engine: engine, calendar: calendar)
        out = fillLinks(out, for: object)
        return out
    }

    private func shown(_ value: FieldValue?, _ calendar: Calendar) -> String {
        switch value {
        case let .number(number)?: number.rounded() == number ? String(Int(number)) : String(number)
        case let .text(text)?, let .choice(text)?, let .richText(text)?: text
        case let .date(date)?: Self.day(date, calendar)
        default: ""
        }
    }

    static func day(_ date: Date, _ calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    /// "{recent(lastWatered,3)}": the last values the field held, newest first, from the object's own history.
    private func fillRecent(_ text: String, for object: ObjectRecord, engine: ActionEngine?, calendar: Calendar)
        -> String
    {
        var out = text
        while let open = out.range(of: "{recent("), let close = out[open.upperBound...].firstIndex(of: "}") {
            let inner = out[open.upperBound ..< out.index(before: close)]
            let args = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            var dates: [Date] = []
            if args.count == 2, let count = Int(args[1]), let engine,
               let field = object.classDef.flatMap({ store.field(args[0], of: $0) })
            {
                for record in engine.history(of: object.id, limit: 400) where record.state != .undone {
                    for case let .setValue(id, fieldID, _, new) in record.ops
                        where id == object.id && fieldID == field.id
                    {
                        if let date = new?.dateValue {
                            dates.append(date)
                        }
                    }
                }
                dates = Array(Array(Set(dates)).sorted(by: >).prefix(count))
            }
            let words = dates.map { Self.day($0, calendar) }
            let joined = words.count > 1 ? words.dropLast().joined(separator: ", ") + " and " + words[words.count - 1]
                : words.first ?? ""
            out.replaceSubrange(open.lowerBound ... close, with: joined)
        }
        return out
    }

    /// "{@field.title}" and "{@field.parent.title}": the object a ref field points to, and its parent.
    private func fillLinks(_ text: String, for object: ObjectRecord) -> String {
        var out = text
        while let open = out.range(of: "{@"), let close = out[open.upperBound...].firstIndex(of: "}") {
            let path = out[open.upperBound ..< close].split(separator: ".").map(String.init)
            var shown = ""
            if let key = path.first, let target = store.linkedObjects(key, of: object).first {
                var node: ObjectRecord? = target
                for step in path.dropFirst() {
                    if step == "parent" {
                        node = node?.parent
                    }
                    if step == "title" {
                        shown = node?.title ?? ""; break
                    }
                }
            }
            out.replaceSubrange(open.lowerBound ... close, with: shown)
        }
        return out
    }

    /// One door per object of the bound class, ranked like the part's own sort; each door opens its object. A door's
    /// summary is the field the part names (or empty).
    public func doors(for part: RoomPart, rows: RoomBind) -> [Door] {
        guard part.kind == "doors" else { return [] }
        let ranked = rows.rows(for: part)
        let field = part.text("summary")
        return ranked.map { row in
            let object = store.object(id: row.id)
            let summary = field.flatMap { key in
                object.map { shown(store.value(key, of: $0), rows.calendar) }
            } ?? ""
            return Door(object: row.id, title: row.title, summary: summary)
        }
    }

    public struct Door: Equatable, Sendable {
        /// The door's destination: the object's own page.
        public let object: UUID
        public let title: String
        public let summary: String
    }
}

/// A change said on an object's page: every page of its class, or its own only.
public struct PatchPage: EngineAction {
    public struct Output: Equatable, Sendable {
        public let scope: PageScope
        public let say: String
        /// The receipt ("Every plant's page, set") and Tess's line, built from the scope.
        public let receipt: String
        public let line: String
    }

    public static let descriptor = ActionDescriptor(
        name: "patchPage", summary: "Change an object's page",
        parameters: [.init("object", .object, "The object whose page he is on"), .init("patch", .json, "The change"),
                     .init("only", .boolean, "Just this object, not its class", required: false)],
        isOfferedToModel: false
    )

    public var object: UUID
    public var patch: RoomPatch
    /// "Just for the orchid": the change goes on this object alone.
    public var only: Bool
    public var sentence: String?

    public init(object: UUID, patch: RoomPatch, only: Bool = false, sentence: String? = nil) {
        self.object = object
        self.patch = patch
        self.only = only
        self.sentence = sentence
    }

    public func apply(_ transaction: inout Transaction) throws -> Output {
        let store = transaction.store
        let target = try transaction.object(object)
        guard let classDef = target.classDef else { throw ActionError.wrongClass(object, expected: "an object") }
        let pages = PageBook(store: store, classes: transaction.classes)
        let existing = only ? pages.layer(forObject: object) : pages.layer(forClass: classDef)
        // A class page that is only generated becomes a stored page at its first change.
        let base = existing.map { pages.parts(of: $0) } ?? (only ? [] : pages.generated(for: classDef))
        let layerName = only ? "\(target.title) page" : "\(classDef.name) page"
        let current = RoomDocument(name: layerName, parts: base)
        var validator = RoomPatchValidator(store: store, classes: transaction.classes)
        validator.page = true
        switch validator.validate(RoomPatch(room: layerName, say: patch.say, ops: patch.ops), against: current) {
        case let .refused(reason):
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: reason)
        case let .ok(document, _):
            var layer = existing
            if layer == nil {
                let made = try transaction.create(transaction.classDef(.pageLayer), title: layerName)
                try transaction.set(only ? "forObject" : "forClass",
                                    to: .text(only ? object.uuidString : classDef.id.uuidString), on: made)
                layer = made
            }
            guard let layer else { throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "no page") }
            // An override that holds no parts is deleted: the object falls back to the class's page.
            if only, document.parts.isEmpty {
                transaction.delete(layer)
            } else {
                try PatchRoom.write(document, over: current, on: layer, in: &transaction)
            }
            let count = store.objects(of: classDef).count
            let scope: PageScope = only ? .object(id: object, title: target.title)
                : .klass(name: classDef.name, count: count)
            return Output(scope: scope, say: RoomPatchValidator.stripped(patch.say),
                          receipt: scope.receipt(thing: classDef.name), line: scope.line(openedOn: target.title))
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "Changed \(store.object(id: object)?.title ?? "a") page"
    }

    public func receipt(in _: ObjectStore, output: Output) -> String? {
        output.receipt
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

public extension RoomReach {
    /// Where a write comes from. A room Tess built needs a grant; he marking his own plant on its own page does not.
    enum WriteOrigin: Sendable {
        case room(String)
        case objectPage
    }

    /// Whether a write ("write Plant.lastWatered") may go ahead from where it was asked.
    static func permits(_ grant: String, from origin: WriteOrigin, book: RoomBook) -> Bool {
        switch origin {
        case .objectPage: true
        case let .room(name): book.room(named: name).map { book.grants(of: $0).contains(grant) } ?? false
        }
    }
}

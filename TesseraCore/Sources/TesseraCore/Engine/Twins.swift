import Foundation

/// A quiet offer to join two things that look the same (Together round 13, switch twinsV2): two tasks, recipes, lists
/// or
/// notes in the same place with the same name (and, for notes, the same words). Derived on every read, never stored.
/// Never offered for a private or walled thing, a money thing, a body, health or calorie thing, or a thing with
/// children. The sentence names the thing only when its name is plain.
public struct TwinOffer: Equatable, Sendable {
    /// The older of the two: the one that stays.
    public let keep: UUID
    public let other: UUID
    public let sentence: String
}

@MainActor
public enum Twins {
    static let kinds: [SystemCatalog.Key] = [.task, .recipe, .list, .note]

    /// The pairs that look the same, oldest first. A pair he said "not the same" to is skipped.
    public static func offers(engine: ActionEngine) -> [TwinOffer] {
        let store = engine.store, classes = engine.classes
        var found: [TwinOffer] = []
        for key in kinds {
            guard let classDef = classes[key] else { continue }
            var groups: [String: [ObjectRecord]] = [:]
            for object in store.objects(of: classDef, includingSubclasses: false)
                where isOffered(object, store: store, classes: classes)
            {
                groups[signature(of: object, store: store), default: []].append(object)
            }
            for group in groups.values where group.count > 1 {
                let ordered = group.sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
                let keep = ordered[0]
                for other in ordered.dropFirst() where !passed(keep, other, store: store) {
                    found.append(TwinOffer(keep: keep.id, other: other.id, sentence: sentence(for: keep, key: key)))
                }
            }
        }
        return found.sorted { ($0.sentence, $0.keep.uuidString) < ($1.sentence, $1.keep.uuidString) }
    }

    /// One at a time: the first pair, or nil.
    public static func next(engine: ActionEngine) -> TwinOffer? {
        offers(engine: engine).first
    }

    static func isOffered(_ object: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> Bool {
        // The flag counts for every kind, even one whose class does not declare it yet: shownLabel reads title words
        // only for recipes and lists.
        guard !object.isDeleted, object.orderedChildren.isEmpty, !normalized(object.title).isEmpty,
              store.value("isPrivate", of: object) != .bool(true),
              ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) == nil,
              !ObjectPrivacy.isPrivateWord(object.title, in: store) else { return false }
        return true
    }

    static func normalized(_ text: String) -> String {
        String(text.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    static func signature(of object: ObjectRecord, store: ObjectStore) -> String {
        let body = store.value("body", of: object)?.stringValue ?? ""
        return normalized(object.title) + "|" + normalized(body)
    }

    static func passed(_ first: ObjectRecord, _ second: ObjectRecord, store: ObjectStore) -> Bool {
        store.linkedObjects("notTwins", of: first).contains { $0.id == second.id }
            || store.linkedObjects("notTwins", of: second).contains { $0.id == first.id }
    }

    private static func sentence(for object: ObjectRecord, key: SystemCatalog.Key) -> String {
        let kind = switch key {
        case .task: "tasks"
        case .recipe: "recipes"
        case .list: "lists"
        default: "notes"
        }
        // A note's title can be its first line, so a note is never named.
        return key == .note ? "Two notes say the same." : "Two \(kind) called \(object.title)."
    }
}

/// Joins two things that look the same into the older one. The newer one's links move to the older, any field the older
/// lacks is filled from the newer, and the newer is deleted: one UNDO puts it all back. Refused for a private or walled
/// thing, a thing with children, or two things of different classes.
public struct JoinTwins: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "joinTwins", summary: "Join two things that look the same",
        parameters: [
            .init("keep", .object, "The thing that stays"),
            .init("other", .object, "The thing that joins it"),
        ], isOfferedToModel: false
    )

    public var keep: UUID
    public var other: UUID

    public init(keep: UUID, other: UUID) {
        self.keep = keep
        self.other = other
    }

    public func apply(_ transaction: inout Transaction) throws {
        let name = Self.descriptor.name
        let kept = try transaction.object(keep), joined = try transaction.object(other)
        let store = transaction.store, classes = transaction.classes
        guard keep != other, !kept.isDeleted, !joined.isDeleted, let classDef = kept.classDef,
              classDef.id == joined.classDef?.id,
              Twins.isOffered(kept, store: store, classes: classes),
              Twins.isOffered(joined, store: store, classes: classes),
              Twins.signature(of: kept, store: store) == Twins.signature(of: joined, store: store)
        else {
            throw ActionError.invalidArguments(action: name, reason: "those two can't be joined")
        }
        let fields = ClassResolver.effectiveFields(of: classDef)
        // Links that pointed at the newer now point at the older.
        for link in joined.incomingLinks ?? [] {
            guard let source = link.from, !source.isDeleted, let sourceClass = source.classDef,
                  let field = ClassResolver.effectiveFields(of: sourceClass).first(where: { $0.id == link.fieldID })
            else { continue }
            var targets = store.linkedObjects(field.key, of: source).map { $0.id == other ? kept : $0 }
            var seen = Set<UUID>()
            targets = targets.filter { seen.insert($0.id).inserted }
            try transaction.setLinks(field.key, on: source, to: targets)
        }
        // What the older lacks comes from the newer.
        for field in fields where field.key != "notTwins" {
            switch field.kind {
            case .ref, .refList:
                if store.linkedObjects(field.key, of: kept).isEmpty {
                    let targets = store.linkedObjects(field.key, of: joined)
                    if !targets.isEmpty {
                        try transaction.setLinks(field.key, on: kept, to: targets)
                    }
                }
            default:
                if !store.hasOwnValue(field.key, on: kept), store.hasOwnValue(field.key, on: joined),
                   let value = store.value(field.key, of: joined)
                {
                    try transaction.set(field.key, to: value, on: kept)
                }
            }
        }
        transaction.delete(joined)
    }

    public func summary(in _: ObjectStore) -> String {
        "Joined two things"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "Joined."
    }
}

/// "Not the same": the pair is never offered again. One UNDO takes it back.
public struct KeepTwinsApart: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "keepTwinsApart", summary: "Say two things are not the same",
        parameters: [
            .init("first", .object, "One thing"),
            .init("second", .object, "The other"),
        ], isOfferedToModel: false
    )

    public var first: UUID
    public var second: UUID

    public init(first: UUID, second: UUID) {
        self.first = first
        self.second = second
    }

    public func apply(_ transaction: inout Transaction) throws {
        let one = try transaction.object(first), two = try transaction.object(second)
        guard first != second else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that is one thing")
        }
        let current = transaction.store.linkedObjects("notTwins", of: one)
        if !current.contains(where: { $0.id == two.id }) {
            try transaction.setLinks("notTwins", on: one, to: current + [two])
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Kept two things apart"
    }
}

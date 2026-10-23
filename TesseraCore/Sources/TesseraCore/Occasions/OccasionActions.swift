import Foundation

// Together, piece 4: Occasions. An occasion is a titled span of days with links to things of any app. Every action
// is one op with one UNDO and none is offered to the model. Summaries and receipts are generic: no link's name, pool
// or amount ever lands in the op log.

enum OccasionRules {
    /// A title that is plain: not empty, not a key, not a walled word, and never a pool's name (a pool name or an
    /// amount lives on the Occasion page only, never in a title).
    @MainActor
    static func plainTitle(_ raw: String, in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> String? {
        let title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !looksLikeClaudeKey(title), !SecretWords.mentions(title),
              !ObjectPrivacy.isPrivateWord(title, in: store),
              title != ObjectPrivacy.poolLabel else { return nil }
        let pools = PoolBook(store: store, classes: classes).pools()
        let lower = title.lowercased()
        if pools.contains(where: { !$0.title.isEmpty && lower.contains($0.title.lowercased()) }) {
            return nil
        }
        return title
    }

    @MainActor
    static func occasion(_ id: UUID, in transaction: Transaction, action: String) throws -> ObjectRecord {
        do {
            return try transaction.object(id, is: .occasion)
        } catch ActionError.wrongClass {
            throw ActionError.invalidArguments(action: action, reason: "that isn't an occasion")
        }
    }

    @MainActor
    static func targets(_ ids: [UUID], for occasion: ObjectRecord, in transaction: Transaction, action: String) throws
        -> [ObjectRecord]
    {
        var seen = Set<UUID>()
        return try ids.compactMap { id in
            guard id != occasion.id, seen.insert(id).inserted else { return nil }
            let target = try transaction.object(id)
            guard !target.isDeleted else {
                throw ActionError.invalidArguments(action: action, reason: "that thing is gone")
            }
            return target
        }
    }
}

/// Starts an occasion: a title, a first and last day, and the things it links.
public struct CreateOccasion: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "createOccasion", summary: "Start an occasion",
        parameters: [
            .init("title", .string, "What it is, e.g. Lisbon trip"),
            .init("start", .date, "First day"),
            .init("end", .date, "Last day"),
            .init("links", .json, "Ids of the things it links", required: false),
        ], isOfferedToModel: false
    )

    public var title: String
    public var start: Date
    public var end: Date
    public var links: [UUID]

    public init(title: String, start: Date, end: Date, links: [UUID] = []) {
        self.title = title
        self.start = start
        self.end = end
        self.links = links
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = Self.descriptor.name
        guard let title = OccasionRules.plainTitle(title, in: transaction.store, classes: transaction.classes) else {
            throw ActionError.invalidArguments(action: name, reason: "that can't be an occasion's name")
        }
        guard end >= start else {
            throw ActionError.invalidArguments(action: name, reason: "it can't end before it starts")
        }
        let occasion = try transaction.create(transaction.classDef(.occasion), title: title)
        try transaction.set("start", to: .date(start), on: occasion)
        try transaction.set("end", to: .date(end), on: occasion)
        let targets = try OccasionRules.targets(links, for: occasion, in: transaction, action: name)
        if !targets.isEmpty {
            try transaction.setLinks("links", on: occasion, to: targets)
        }
        return occasion
    }

    public func summary(in _: ObjectStore) -> String {
        "New occasion"
    }

    public func receipt(in _: ObjectStore, output occasion: ObjectRecord) -> String? {
        "\(occasion.title), started."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Adds a thing to an occasion's links (already there is no change).
public struct LinkToOccasion: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "linkToOccasion", summary: "Link a thing to an occasion",
        parameters: [
            .init("occasion", .object, "The occasion"),
            .init("thing", .object, "The thing to link"),
        ], isOfferedToModel: false
    )

    public var occasion: UUID
    public var thing: UUID

    public init(occasion: UUID, thing: UUID) {
        self.occasion = occasion
        self.thing = thing
    }

    public func apply(_ transaction: inout Transaction) throws {
        let name = Self.descriptor.name
        let record = try OccasionRules.occasion(occasion, in: transaction, action: name)
        let current = transaction.store.linkedObjects("links", of: record)
        let added = try OccasionRules.targets([thing], for: record, in: transaction, action: name)
        try transaction.setLinks("links", on: record, to: current + added.filter { new in
            !current.contains { $0.id == new.id }
        })
    }

    public func summary(in _: ObjectStore) -> String {
        "Linked to an occasion"
    }
}

/// Takes a thing off an occasion's links.
public struct UnlinkFromOccasion: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "unlinkFromOccasion", summary: "Unlink a thing from an occasion",
        parameters: [
            .init("occasion", .object, "The occasion"),
            .init("thing", .object, "The thing to unlink"),
        ], isOfferedToModel: false
    )

    public var occasion: UUID
    public var thing: UUID

    public init(occasion: UUID, thing: UUID) {
        self.occasion = occasion
        self.thing = thing
    }

    public func apply(_ transaction: inout Transaction) throws {
        let record = try OccasionRules.occasion(occasion, in: transaction, action: Self.descriptor.name)
        let current = transaction.store.linkedObjects("links", of: record)
        try transaction.setLinks("links", on: record, to: current.filter { $0.id != thing })
    }

    public func summary(in _: ObjectStore) -> String {
        "Unlinked from an occasion"
    }
}

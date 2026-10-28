import Foundation

/// What Tess believes about him (docs/ai/harness/memory-context-m0-m6.md, M1). A belief is a typed, dated, sourced
/// claim with the evidence behind it. It is closed when it changes (a new belief replaces it, linked back) and deleted
/// only by his forget gesture. The words are the object's title: 80 characters, second person; a told belief keeps
/// his own.
public struct TessBelief: Identifiable, Equatable, Sendable {
    public enum Key: String, Codable, Sendable, CaseIterable {
        case usualTime, cadence, prefers, avoids, goal, limit, pattern, alias, fact
    }

    public enum Source: String, Codable, Sendable, CaseIterable {
        /// He said it.
        case told
        /// Counted on the phone from the ledger.
        case noticed
        /// Guessed from the record; a maybe until it is confirmed twice or he keeps it.
        case inferred
        /// Learned from how he uses the app (a correction, a skip).
        case learned
    }

    /// Who or what it is about: him, a class (every set), or one object.
    public enum Subject: Equatable, Sendable {
        case you
        case classDef(UUID)
        case object(UUID)
    }

    public static let usesKept = 50
    /// An inferred belief becomes a fact when the record says it again this many times.
    public static let confirmationsForFact = 2

    public let id: UUID
    public let subject: Subject
    public let key: Key
    /// Typed JSON; `{"text": ...}` when it is only words.
    public let value: String
    public let confidence: Double
    public let source: Source
    public let evidence: [UUID]
    public let evidenceOps: [UUID]
    public let validFrom: Date
    public let validUntil: Date?
    public let supersedes: UUID?
    public let uses: [Date]
    public let confirmations: Int
    public let kept: Bool
    public let words: String
    public let isPrivate: Bool

    /// Closed beliefs are history: kept for "what changed", never packed as current.
    public var isOpen: Bool {
        validUntil == nil
    }

    /// A maybe: inferred, not confirmed twice, not kept by him.
    public var isMaybe: Bool {
        source == .inferred && confirmations < Self.confirmationsForFact && !kept
    }

    /// The line as she shows or says it: a maybe starts "I think".
    public var spoken: String {
        guard isMaybe else { return words }
        let lowered = words.prefix(1).lowercased() + words.dropFirst()
        return "I think \(lowered)"
    }

    /// Whether it was current at `date`.
    public func isValid(at date: Date) -> Bool {
        validFrom <= date && (validUntil.map { date < $0 } ?? true)
    }
}

// MARK: - Actions

/// Why a belief was refused, from the error an action threw.
public enum BeliefRefusal {
    public static let noEvidence = "refused: noEvidence"
    public static let alreadyClosed = "refused: alreadyClosed"
    /// A merge may not close what he told or kept: his words win until he says otherwise.
    public static let hisOwn = "refused: hisOwn"

    public static func line(_ error: any Error) -> String? {
        guard case let ActionError.invalidArguments(_, reason) = error else { return nil }
        switch reason {
        case noEvidence: return "I need something to go on for that"
        case alreadyClosed: return "That one is already closed"
        case hisOwn: return "You told me that one, so it stays until you change it"
        default: return RememberFact.refusalLine(error)
        }
    }
}

@MainActor
enum BeliefWrites {
    /// The wall every belief passes, told or not: money, places, passwords, a key and a measured body value are never
    /// kept, a health word keeps it on this phone. Returns whether it must stay on this phone.
    static func screen(_ phrase: String, value: String, isPrivate: Bool?, action: String,
                       store: ObjectStore) throws -> Bool
    {
        // A body fact of his ("left shoulder") stays on this phone, as a told line does (RememberFact).
        let words = Set(phrase.lowercased().split { !$0.isLetter }.map(String.init))
        let bodyWords: Set = [
            "shoulder",
            "shoulders",
            "knee",
            "knees",
            "hip",
            "hips",
            "elbow",
            "wrist",
            "ankle",
            "neck",
        ]
        let soreWords: Set = ["sore", "hurts", "hurt", "ache", "aches", "pain", "tight"]
        let bodyFact = !words
            .isDisjoint(with: bodyWords) || (words.contains("back") && !words.isDisjoint(with: soreWords))
        var keepsPrivate = isPrivate ?? bodyFact
        for text in [phrase, value] where !text.isEmpty {
            let tokens = text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
            if let word = tokens.first(where: TessMemoryScreen.healthValueWords.contains) {
                throw ActionError.invalidArguments(action: action, reason: "refused: health(\"\(word)\")")
            }
            if let refusal = TessMemoryScreen.refusal(for: text, numbers: Set(HomeLines.digits(in: text))) {
                switch refusal {
                case .health, .unlicensedNumber: keepsPrivate = true
                default: throw ActionError.invalidArguments(action: action, reason: "refused: \(refusal)")
                }
            }
            if PrivateFacts.isBareWeight(text.lowercased(), lastWeightKg: BodyWeight.lastKg(in: store)) {
                throw ActionError.invalidArguments(action: action, reason: "refused: health(\"walled\")")
            }
        }
        return keepsPrivate
    }

    static func objectIDs(_ ids: [String]) -> [UUID] {
        ids.compactMap(UUID.init(uuidString:))
    }

    static func encode(_ ids: [UUID]) -> String {
        (try? JSONEncoder().encode(ids.map(\.uuidString))).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }
}

/// Writes a belief. Refused without evidence: at least one object or one op behind it.
public struct RecordBelief: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "recordBelief", summary: "Keep a belief about him",
        parameters: [
            .init("words", .string, "The belief in 80 characters, second person"),
            .init("key", .string, "usualTime, cadence, prefers, avoids, goal, limit, pattern, alias or fact"),
            .init("source", .string, "told, noticed, inferred or learned"),
            .init("value", .string, "Typed JSON; defaults to the words", required: false),
            .init("confidence", .number, "0 to 1", required: false),
            .init("subject", .object, "The object it is about; none means him", required: false),
            .init("subjectClass", .object, "The class it is about", required: false),
            .init("evidence", .json, "Object ids behind it", required: false),
            .init("evidenceOps", .json, "Op ids behind it", required: false),
            .init("isPrivate", .boolean, "Never leaves the phone", required: false),
        ]
    )

    public var words: String
    public var key: TessBelief.Key
    public var source: TessBelief.Source
    public var value: String?
    public var confidence: Double?
    public var subject: UUID?
    public var subjectClass: UUID?
    public var evidence: [UUID]
    public var evidenceOps: [UUID]
    public var isPrivate: Bool?
    /// When it starts holding; now when nil.
    public var validFrom: Date?

    public init(words: String, key: TessBelief.Key, source: TessBelief.Source, value: String? = nil,
                confidence: Double? = nil, subject: UUID? = nil, subjectClass: UUID? = nil, evidence: [UUID] = [],
                evidenceOps: [UUID] = [], isPrivate: Bool? = nil, validFrom: Date? = nil)
    {
        self.words = words
        self.key = key
        self.source = source
        self.value = value
        self.confidence = confidence
        self.subject = subject
        self.subjectClass = subjectClass
        self.evidence = evidence
        self.evidenceOps = evidenceOps
        self.isPrivate = isPrivate
        self.validFrom = validFrom
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        try Self.write(self, supersedes: nil, in: &transaction)
    }

    @MainActor static func write(
        _ action: Self,
        supersedes old: ObjectRecord?,
        in transaction: inout Transaction
    ) throws
        -> ObjectRecord
    {
        let name = descriptor.name
        let trimmed = action.words.trimmingCharacters(in: .whitespacesAndNewlines)
        let evidenceObjects = action.evidence.compactMap { transaction.store.object(id: $0) }
        guard !evidenceObjects.isEmpty || !action.evidenceOps.isEmpty else {
            throw ActionError.invalidArguments(action: name, reason: BeliefRefusal.noEvidence)
        }
        let stored = action.source == .told ? trimmed : TessMemoryStore.secondPerson(trimmed)
        let value = action.value ?? jsonText(stored)
        let keepsPrivate = try BeliefWrites.screen(stored, value: action.value ?? "", isPrivate: action.isPrivate,
                                                   action: name, store: transaction.store)
        let belief = try transaction.create(transaction.classDef(.belief), title: stored)
        try transaction.set("key", to: .choice(action.key.rawValue), on: belief)
        try transaction.set("source", to: .choice(action.source.rawValue), on: belief)
        try transaction.set("value", to: .text(value), on: belief)
        try transaction.set("confidence", to: .number(min(1, max(0, action.confidence ?? 1))), on: belief)
        try transaction.set("validFrom", to: .date(action.validFrom ?? .now), on: belief)
        try transaction.set("isPrivate", to: .bool(keepsPrivate), on: belief)
        if !action.evidenceOps.isEmpty {
            try transaction.set("evidenceOps", to: .text(BeliefWrites.encode(action.evidenceOps)), on: belief)
        }
        try transaction.setLinks("evidence", on: belief, to: evidenceObjects)
        if let id = action.subject, let target = transaction.store.object(id: id) {
            try transaction.setLinks("subject", on: belief, to: [target])
        } else if let id = action.subjectClass, let target = transaction.store.classDef(id: id) {
            try transaction.setClassLink("subjectClass", on: belief, to: target)
        }
        if let old {
            try transaction.setLinks("supersedes", on: belief, to: [old])
        }
        return belief
    }

    static func jsonText(_ text: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: ["text": text], options: [.sortedKeys])
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    public func summary(in _: ObjectStore) -> String {
        "Kept a belief. \(TessMemoryStore.secondPerson(words))"
    }
}

/// A belief changed: the old one is closed (never deleted) and the new one links back to it.
public struct ReviseBelief: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "reviseBelief", summary: "Change a belief about him",
        parameters: [
            .init("belief", .object, "The belief that changed"),
            .init("words", .string, "The new belief in 80 characters, second person"),
            .init("value", .string, "Typed JSON; defaults to the words", required: false),
            .init("evidence", .json, "Object ids behind the change", required: false),
            .init("evidenceOps", .json, "Op ids behind the change", required: false),
            .init("source", .string, "told, noticed, inferred or learned; the old source when left out",
                  required: false),
        ]
    )

    public var belief: UUID
    public var words: String
    public var value: String?
    public var evidence: [UUID]
    public var evidenceOps: [UUID]
    public var source: TessBelief.Source?
    /// When the change takes hold; now when nil.
    public var at: Date?

    public init(belief: UUID, words: String, value: String? = nil, evidence: [UUID] = [], evidenceOps: [UUID] = [],
                source: TessBelief.Source? = nil, at: Date? = nil)
    {
        self.belief = belief
        self.words = words
        self.value = value
        self.evidence = evidence
        self.evidenceOps = evidenceOps
        self.source = source
        self.at = at
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let old = try transaction.object(belief, is: .belief)
        let name = Self.descriptor.name
        guard transaction.store.value("validUntil", of: old) == nil else {
            throw ActionError.invalidArguments(action: name, reason: BeliefRefusal.alreadyClosed)
        }
        let when = at ?? .now
        let store = transaction.store
        let oldSource = store.value("source", of: old)?.stringValue.flatMap(TessBelief.Source.init(rawValue:))
        let key = store.value("key", of: old)?.stringValue.flatMap(TessBelief.Key.init(rawValue:)) ?? .fact
        // The new belief rests on the new evidence, or on what the old one rested on.
        let objects = evidence.isEmpty && evidenceOps.isEmpty ? store.linkedObjects("evidence", of: old).map(\.id)
            : evidence
        let ops = evidenceOps.isEmpty && evidence.isEmpty ? Self.ops(of: old, store: store) : evidenceOps
        let write = RecordBelief(
            words: words, key: key, source: source ?? oldSource ?? .told, value: value,
            confidence: store.number("confidence", of: old), subject: store.linkedObjects("subject", of: old).first?.id,
            subjectClass: store.linkedClass("subjectClass", of: old)?.id, evidence: objects, evidenceOps: ops,
            isPrivate: store.value("isPrivate", of: old) == .bool(true) ? true : nil, validFrom: when
        )
        let made = try RecordBelief.write(write, supersedes: old, in: &transaction)
        try transaction.set("validUntil", to: .date(when), on: old)
        return made
    }

    @MainActor static func ops(of belief: ObjectRecord, store: ObjectStore) -> [UUID] {
        guard let text = store.value("evidenceOps", of: belief)?.stringValue, let data = text.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return BeliefWrites.objectIDs(ids)
    }

    public func summary(in _: ObjectStore) -> String {
        "Changed a belief. \(TessMemoryStore.secondPerson(words))"
    }
}

/// The record said it again (an inferred belief toward a fact), or he kept it.
public struct ConfirmBelief: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "confirmBelief", summary: "Confirm a belief",
        parameters: [
            .init("belief", .object, "The belief"),
            .init("keep", .boolean, "He keeps it: it is a fact now", required: false),
        ]
    )

    public var belief: UUID
    public var keep: Bool?

    public init(belief: UUID, keep: Bool? = nil) {
        self.belief = belief
        self.keep = keep
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(belief, is: .belief)
        if keep == true {
            try transaction.set("kept", to: .bool(true), on: object)
        } else {
            let count = Int(transaction.store.number("confirmations", of: object) ?? 0) + 1
            try transaction.set("confirmations", to: .number(Double(count)), on: object)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        let words = store.object(id: belief)?.title ?? "That"
        return keep == true ? "Kept. \(words)" : "Confirmed. \(words)"
    }
}

/// The night pass (M5) found two open beliefs that say the same thing, or two usual times that disagree: `close` ends
/// now and `keep` holds on, resting on what both rested on plus `close` itself. Because `close` is in `keep`'s
/// evidence, a forget of either takes both (ForgetBelief follows belief evidence like `supersedes`).
public struct MergeBelief: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "mergeBelief", summary: "Merge two beliefs",
        parameters: [
            .init("keep", .object, "The belief that holds on"),
            .init("close", .object, "The belief that ends"),
        ]
    )

    public var keep: UUID
    public var close: UUID
    /// When `close` ends; now when nil.
    public var at: Date?

    public init(keep: UUID, close: UUID, at: Date? = nil) {
        self.keep = keep
        self.close = close
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws {
        let kept = try transaction.object(keep, is: .belief)
        let closed = try transaction.object(close, is: .belief)
        let store = transaction.store
        guard keep != close, store.value("validUntil", of: kept) == nil, store.value("validUntil", of: closed) == nil
        else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: BeliefRefusal.alreadyClosed)
        }
        // The planner never asks for it; this is the second guard. A belief with no source reads as told.
        let source: TessBelief.Source = store.value("source", of: closed)?.stringValue
            .flatMap(TessBelief.Source.init(rawValue:)) ?? .told
        guard source != .told, store.value("kept", of: closed) != .bool(true) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: BeliefRefusal.hisOwn)
        }
        var evidence = store.linkedObjects("evidence", of: kept)
        for object in store.linkedObjects("evidence", of: closed) + [closed]
            where !evidence.contains(where: { $0.id == object.id })
        {
            evidence.append(object)
        }
        try transaction.setLinks("evidence", on: kept, to: evidence)
        try transaction.set("validUntil", to: .date(at ?? .now), on: closed)
    }

    public func summary(in store: ObjectStore) -> String {
        "Merged. \(store.object(id: keep)?.title ?? "That")"
    }
}

/// His forget gesture: the whole chain the belief is part of (what it replaced, what replaced it, and what was merged
/// into it or it into) and the memory line it was made from are deleted (not closed), so nothing is left linked to a
/// deleted row and nothing is left to bring it back. After the UNDO window `TessBeliefStore.redact` scrubs the words
/// from every field and op.
public struct ForgetBelief: EngineAction {
    public static let descriptor = ActionDescriptor(name: "forgetBelief", summary: "Forget a belief",
                                                    parameters: [.init("belief", .object, "The belief")])

    public var belief: UUID

    public init(belief: UUID) {
        self.belief = belief
    }

    /// Every belief a forget of `start` deletes: what it replaced, what replaced it, and what was merged into it or it
    /// into, transitively. The forget path hands these ids to `MemoryEvalRecord.forget(beliefs:)` before it applies.
    @MainActor
    public static func chain(of start: ObjectRecord, in store: ObjectStore,
                             classes: [SystemCatalog.Key: ClassDef]) -> [ObjectRecord]
    {
        var chain: [ObjectRecord] = []
        var seen = Set<UUID>()
        var queue = [start]
        while let object = queue.popLast() {
            guard seen.insert(object.id).inserted else { continue }
            chain.append(object)
            queue += store.linkedObjects("supersedes", of: object)
            if let beliefClass = classes[.belief] {
                // A merged belief sits in the evidence of the one that kept on (MergeBelief), both ways.
                queue += store.linkedObjects("evidence", of: object).filter { $0.classDef?.id == beliefClass.id }
                queue += store.objects(of: beliefClass).filter { other in
                    !other.isDeleted && (store.linkedObjects("supersedes", of: other).contains { $0.id == object.id }
                        || store.linkedObjects("evidence", of: other).contains { $0.id == object.id })
                }
            }
        }
        return chain
    }

    public func apply(_ transaction: inout Transaction) throws {
        let start = try transaction.object(belief, is: .belief)
        let store = transaction.store
        for object in Self.chain(of: start, in: store, classes: transaction.classes) {
            // The memory line a belief was made from goes with it, or the next sync would make it again.
            if let rule = store.value("rule", of: object)?.stringValue, rule.hasPrefix("memory:"),
               let id = UUID(uuidString: String(rule.dropFirst("memory:".count))),
               let line = store.object(id: id), !line.isDeleted
            {
                transaction.delete(line)
            }
            transaction.delete(object)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: belief).map { TessMemoryStore.receiptThing(of: $0.title) } ?? "That"), forgotten"
    }
}

import Foundation

/// Reads and tends beliefs (M1). Writes that are his or Tess's go through the actions in TessBelief.swift; the
/// migration and the sync from memory lines write without ops, like the counted lines (they are weather, not
/// something he did).
@MainActor
public struct TessBeliefStore {
    public let engine: ActionEngine
    public var memory: TessMemoryStore

    public init(engine: ActionEngine, memory: TessMemoryStore? = nil) {
        self.engine = engine
        self.memory = memory ?? TessMemoryStore(engine: engine)
    }

    var store: ObjectStore {
        engine.store
    }

    // MARK: Reading

    func records() -> [ObjectRecord] {
        guard let beliefClass = engine.classes[.belief] else { return [] }
        return store.objects(of: beliefClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    func read(_ object: ObjectRecord) -> TessBelief {
        let subject: TessBelief.Subject = if let target = store.linkedObjects("subject", of: object).first {
            .object(target.id)
        } else if let target = store.linkedClass("subjectClass", of: object) {
            .classDef(target.id)
        } else {
            .you
        }
        let uses = (store.value("uses", of: object)?.stringValue.flatMap { $0.data(using: .utf8) })
            .flatMap { try? JSONDecoder().decode([Date].self, from: $0) } ?? []
        return TessBelief(
            id: object.id, subject: subject,
            key: store.value("key", of: object)?.stringValue.flatMap(TessBelief.Key.init(rawValue:)) ?? .fact,
            value: store.value("value", of: object)?.stringValue ?? "",
            confidence: store.number("confidence", of: object) ?? 1,
            source: store.value("source", of: object)?.stringValue.flatMap(TessBelief.Source.init(rawValue:)) ?? .told,
            evidence: store.linkedObjects("evidence", of: object).map(\.id),
            evidenceOps: ReviseBelief.ops(of: object, store: store),
            validFrom: store.value("validFrom", of: object)?.dateValue ?? object.createdAt,
            validUntil: store.value("validUntil", of: object)?.dateValue,
            supersedes: store.linkedObjects("supersedes", of: object).first?.id,
            uses: uses, confirmations: Int(store.number("confirmations", of: object) ?? 0),
            kept: store.value("kept", of: object) == .bool(true), words: object.title,
            isPrivate: store.value("isPrivate", of: object) == .bool(true)
        )
    }

    /// Every belief, open and closed, oldest first.
    public func all() -> [TessBelief] {
        records().map(read)
    }

    /// The ones holding now.
    public func open() -> [TessBelief] {
        all().filter(\.isOpen)
    }

    public func belief(_ id: UUID) -> TessBelief? {
        store.object(id: id).flatMap { $0.isDeleted ? nil : read($0) }
    }

    /// The beliefs about one subject, open first; `date` asks what held then.
    public func about(_ subject: TessBelief.Subject, key: TessBelief.Key? = nil, at date: Date? = nil) -> [TessBelief] {
        all().filter { belief in
            belief.subject == subject && (key == nil || belief.key == key)
                && (date.map { belief.isValid(at: $0) } ?? belief.isOpen)
        }
    }

    /// The belief this one replaced, and so on back: what changed.
    public func history(of id: UUID) -> [TessBelief] {
        var chain: [TessBelief] = []
        var next = belief(id)
        while let current = next, !chain.contains(where: { $0.id == current.id }) {
            chain.append(current)
            next = current.supersedes.flatMap(belief)
        }
        return chain
    }

    // MARK: Use

    /// Marks beliefs as used now; the last 50 uses are kept (recall's activation, M2).
    public func markUsed(_ ids: [UUID], at now: Date = .now) {
        for id in ids {
            guard let object = store.object(id: id), !object.isDeleted else { continue }
            var uses = read(object).uses
            uses.append(now)
            uses = Array(uses.suffix(TessBelief.usesKept))
            if let data = try? JSONEncoder().encode(uses), let text = String(data: data, encoding: .utf8) {
                try? store.set("uses", to: .text(text), on: object)
            }
        }
    }

    /// Every belief (open or closed) made from one memory line.
    static func beliefs(madeFrom memory: UUID, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef])
        -> [ObjectRecord]
    {
        guard let beliefClass = classes[.belief] else { return [] }
        let rule = Self.rule(for: memory)
        return store.objects(of: beliefClass).filter {
            !$0.isDeleted && store.value("rule", of: $0)?.stringValue == rule
        }
    }

    // MARK: Memory lines become beliefs

    static func rule(for memory: UUID) -> String {
        "memory:\(memory.uuidString)"
    }

    /// Today's told and noticed memory lines as beliefs: one belief per line, his words kept as they are, the line
    /// itself as evidence. Idempotent. A line whose words changed (a noticed line recomputed in place) closes its
    /// belief and opens the new one linked back; a line that is gone (the noticed rule no longer holds) closes it.
    /// Forgetting a line deletes its belief with it (`ForgetMemory`), so a closed belief is never the way out.
    @discardableResult
    public func syncFromMemory(now: Date = .now) -> Int {
        guard let beliefClass = engine.classes[.belief] else { return 0 }
        // A line whose words he forgot never comes back as a belief, whatever a restore or a recompute did.
        let forgotten = memory.forgottenHashes()
        let lines = memory.all().filter {
            ($0.kind == .told || $0.kind == .noticed) && !forgotten.contains(TessMemoryStore.hash($0.text))
        }
        var byRule: [String: ObjectRecord] = [:]
        for object in records() where store.value("validUntil", of: object) == nil {
            if let rule = store.value("rule", of: object)?.stringValue, rule.hasPrefix("memory:") {
                byRule[rule] = object
            }
        }
        var changed = 0
        for line in lines {
            let rule = Self.rule(for: line.id)
            if let existing = byRule.removeValue(forKey: rule) {
                guard existing.title != line.text else { continue }
                close(existing, at: now)
                create(from: line, rule: rule, replacing: existing, in: beliefClass, now: now)
            } else {
                create(from: line, rule: rule, replacing: nil, in: beliefClass, now: now)
            }
            changed += 1
        }
        // What is left in `byRule` has no line behind it any more.
        for (_, object) in byRule {
            close(object, at: now)
            changed += 1
        }
        return changed
    }

    private func close(_ object: ObjectRecord, at date: Date) {
        try? store.set("validUntil", to: .date(date), on: object)
    }

    private func create(from line: TessMemory, rule: String, replacing old: ObjectRecord?, in beliefClass: ClassDef,
                        now: Date)
    {
        let belief = store.create(beliefClass, title: line.text)
        let told = line.kind == .told
        try? store.set("key", to: .choice((told ? TessBelief.Key.fact : .pattern).rawValue), on: belief)
        try? store.set("source", to: .choice((told ? TessBelief.Source.told : .noticed).rawValue), on: belief)
        try? store.set("value", to: .text(RecordBelief.jsonText(line.text)), on: belief)
        try? store.set("confidence", to: .number(told ? 1 : 0.8), on: belief)
        try? store.set("validFrom", to: .date(old == nil ? line.createdAt : now), on: belief)
        try? store.set("rule", to: .text(rule), on: belief)
        try? store.set("isPrivate", to: .bool(line.isPrivate), on: belief)
        var evidence = line.evidence.compactMap { store.object(id: $0) }
        if let source = store.object(id: line.id) {
            evidence.insert(source, at: 0)
        }
        try? store.setLinks("evidence", on: belief, to: evidence)
        if let old {
            try? store.setLinks("supersedes", on: belief, to: [old])
        }
    }

    // MARK: Forgetting

    /// After the UNDO window: scrubs the words of every belief deleted more than 10 s ago, from the object and from the
    /// op history, and logs their hash so a restored backup forgets them again.
    @discardableResult
    public func sweepForgotten(now: Date = .now) -> Int {
        guard let beliefClass = engine.classes[.belief] else { return 0 }
        let due = (beliefClass.objects ?? []).filter { object in
            guard let deletedAt = object.deletedAt, now.timeIntervalSince(deletedAt) > 10 else { return false }
            // Done once: title and value both scrubbed.
            return object.title != TessMemoryStore.redacted || store.value("value", of: object)?.stringValue != "{}"
        }
        for object in due {
            redact(object.id, now: now)
        }
        return due.count
    }

    /// Scrubs a forgotten belief everywhere its words live: the title and the typed value on the object (the value
    /// holds the words as JSON), the create, rename and value ops, and every receipt that said them. Idempotent.
    public func redact(_ id: UUID, now: Date = .now) {
        guard let object = store.object(id: id) else { return }
        let words = object.title
        let value = store.value("value", of: object)?.stringValue ?? ""
        let secondPerson = String(TessMemoryStore.secondPerson(words).dropLast())
        // The words as they sit in the value JSON ("text":"..."), and as plain text.
        let spoken = Set([words, value, secondPerson]
            .filter { !$0.isEmpty && $0 != TessMemoryStore.redacted && $0 != "{}" })
        // Title, hash log, create/rename ops and summaries: the memory line's redaction does exactly this.
        memory.redact(id, now: now)
        for record in store.context.operations.values where record.objectIDs.contains(id) {
            var changed = false
            let ops = record.ops.map { op -> Op in
                guard case let .setValue(target, field, old, new) = op, target == id else { return op }
                func scrubbed(_ value: FieldValue?) -> FieldValue? {
                    guard case let .text(text)? = value, spoken.contains(where: text.contains) else { return value }
                    changed = true
                    return .text("{}")
                }
                return .setValue(object: target, field: field, old: scrubbed(old), new: scrubbed(new))
            }
            if changed {
                record.opsData = try? JSONEncoder().encode(ops)
            }
            for form in spoken where record.summary.contains(form) {
                record.summary = record.summary.replacingOccurrences(of: form, with: TessMemoryStore.redacted)
            }
            if let receipt = record.receipt, spoken.contains(where: receipt.contains) {
                record.receipt = TessMemoryStore.redacted
            }
        }
        if !value.isEmpty, value != "{}" {
            try? store.set("value", to: .text("{}"), on: object)
        }
    }

    /// Forgets again every belief whose words he forgot after it was written (what a restored backup brings back).
    @discardableResult
    public func reapplyForgets() -> Int {
        let when = memory.forgottenAt()
        guard !when.isEmpty else { return 0 }
        let back = all().filter { belief in
            guard let created = store.object(id: belief.id)?.createdAt else { return false }
            return when[TessMemoryStore.hash(belief.words)].map { created < $0 } ?? false
        }
        for belief in back {
            redact(belief.id)
        }
        return back.count
    }
}

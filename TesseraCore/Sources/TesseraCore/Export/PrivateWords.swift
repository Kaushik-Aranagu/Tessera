import Foundation
import GRDB

/// Which objects hold private words, for the two files that leave his phone's own store (G28, Product's ruling):
/// - A shared EXPORT masks them: the object reads "Private note", "Private item" or "Private recipe" and keeps no
///   words (`TesseraExport(context:maskingPrivate:)`).
/// - The iCloud folder copy leaves them out (`TesseraBackup.write(... leavingOutPrivate:)`).
/// - The local Backup on the phone keeps every word, as ruled earlier (Q1). No key is ever in it.
///
/// Private is the one rule the rest of Tessera uses: a note, task or memory by `ObjectPrivacy`; any other object by its
/// private flag, a secret word, money or a body fact (`PrivateFacts.isWalled` with his last weight) in its title or
/// text, or a title that already is a private label. What is inside a private object, and anything else that carries
/// its title (a cook of a private recipe), is private with it. No opt-in in v1.
@MainActor
enum PrivateWords {
    static let labels: Set<String> = [
        "Private note", "Private task", "Private item", "Private recipe", "Private memory",
        ObjectPrivacy.noteLabel, ObjectPrivacy.taskLabel, ObjectPrivacy.memoryLabel, ObjectPrivacy.keptNoteLabel,
    ]

    /// Claude's own bookkeeping stays on the phone: the receipts (`tessCall`: what was asked, when, what it cost) and
    /// the phrases waiting for Claude (`tessWaiting`) are in the local copy only, never in the iCloud copy or the
    /// shared export (Research, Claude-layer gap hunt).
    static let localOnlyClassKeys: Set<String> = [
        SystemCatalog.Key.tessCall.systemKey,
        SystemCatalog.Key.tessWaiting.systemKey,
        SystemCatalog.Key.tessSent.systemKey,
    ]

    /// The family, not the exact class: a subclass of Tess Call, Tess Waiting or Tess Sent is local-only too.
    static func isLocalOnly(_ record: ObjectRecord) -> Bool {
        var current = record.classDef
        var depth = 0
        while let classDef = current, depth < 12 {
            if let key = classDef.systemKey, localOnlyClassKeys.contains(key) { return true }
            current = classDef.parent
            depth += 1
        }
        return false
    }

    static func localOnlyIDs(in context: TesseraContext) -> Set<UUID> {
        Set(context.all(ObjectRecord.self).filter(isLocalOnly).map(\.id))
    }

    static func isPrivateText(_ text: String, lastWeightKg: Double?) -> Bool {
        labels.contains(text.trimmingCharacters(in: .whitespacesAndNewlines))
            || ObjectPrivacy.isPrivateText(text, lastWeightKg: lastWeightKg)
    }

    /// Medical and care words that make a bare title private even with no number (Product: money and body titles are
    /// private in an export). Not the Home pack's rules for what goes to Claude (loose numbers, places, people).
    static let titleWords: Set<String> = ObjectPrivacy.titleWords

    /// A title is private by the usual rule, or when it holds a money or health word.
    /// ObjectPrivacy.isPrivateTitle asks this: the one check (G105).
    static func isPrivateTitle(_ title: String, lastWeightKg: Double?) -> Bool {
        labels.contains(title.trimmingCharacters(in: .whitespacesAndNewlines))
            || ObjectPrivacy.isPrivateTitle(title, lastWeightKg: lastWeightKg)
    }

    /// A list of numbers ("25, 20, 15, 1.25": the plates an equipment object holds) is not a spend or a weigh-in.
    static func isNumberList(_ text: String) -> Bool {
        text.allSatisfy { "0123456789,. /x".contains($0) }
    }

    static func systemClasses(in context: TesseraContext) -> [SystemCatalog.Key: ClassDef] {
        var classes: [SystemCatalog.Key: ClassDef] = [:]
        for classDef in context.all(ClassDef.self) {
            if let key = SystemCatalog.Key.allCases.first(where: { $0.systemKey == classDef.systemKey }) {
                classes[key] = classDef
            }
        }
        return classes
    }

    static func genericLabel(_ object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> String {
        guard let classDef = object.classDef else { return SecretWords.title }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        if isA(.listItem) || isA(.ingredient) {
            return "Private item"
        }
        if isA(.list) {
            return "Private list"
        }
        if isA(.routine) || isA(.workout) {
            return ObjectPrivacy.routineLabel
        }
        if isA(.recipe) || isA(.recipeLine) || isA(.recipeStep) || isA(.cook) {
            return "Private recipe"
        }
        if isA(.task) {
            return ObjectPrivacy.taskLabel
        }
        if isA(.tessMemory) {
            return ObjectPrivacy.memoryLabel
        }
        return SecretWords.title
    }

    /// Objects that were private at any point in the op history but are plain now (a note made private and later
    /// plain, a title edited): their old words still sit in the op log, so the ops are masked or dropped with the
    /// rest. Marked by an isPrivate set to true, or a private word, label or walled title in a create, rename or
    /// text value. Only ones not already in `current`.
    static func historyLabels(in context: TesseraContext, current: [UUID: String]) -> [UUID: String] {
        if let cache = context.pastPrivateCache, cache.revision == context.revision {
            return cache.labels
        }
        let result = computeHistoryLabels(in: context, current: current)
        context.pastPrivateCache = (context.revision, result)
        return result
    }

    /// An op record's ops, decoded once (the JSON decode dominates the walk) and kept while its data is unchanged.
    private static func ops(of record: OpRecord, in context: TesseraContext) -> [Op] {
        guard let data = record.opsData else { return [] }
        if let hit = context.decodedOps[record.id], hit.data == data {
            return hit.ops
        }
        let ops = record.ops
        context.decodedOps[record.id] = (data, ops)
        return ops
    }

    private static func computeHistoryLabels(in context: TesseraContext, current: [UUID: String]) -> [UUID: String] {
        let classes = systemClasses(in: context)
        let last = BodyWeight.lastKg(in: ObjectStore(context: context))
        let flagFields = Set(context.all(FieldDef.self).filter { $0.key == "isPrivate" }.map(\.id))
        func wordy(_ text: String) -> Bool {
            !isNumberList(text) && isPrivateText(text, lastWeightKg: last)
        }
        func wordyTitle(_ title: String) -> Bool {
            !isNumberList(title) && isPrivateTitle(title, lastWeightKg: last)
        }
        var found = Set<UUID>()
        for record in context.all(OpRecord.self) {
            for op in ops(of: record, in: context) where current[op.objectID] == nil {
                switch op {
                case let .create(object, _, _, title): if wordyTitle(title) {
                        found.insert(object)
                    }
                case let .setTitle(object, old, new): if wordyTitle(old) || wordyTitle(new) {
                        found.insert(object)
                    }
                case let .setValue(object, field, old, new):
                    if flagFields.contains(field), old == .bool(true) || new == .bool(true) {
                        found.insert(object)
                    }
                    for value in [old, new] {
                        switch value {
                        case let .text(text), let .richText(text): if wordy(text) {
                                found.insert(object)
                            }
                        default: break
                        }
                    }
                default: break
                }
            }
        }
        return Dictionary(uniqueKeysWithValues: found.map { id in
            (id, context.objects[id].map { genericLabel($0, classes: classes) } ?? SecretWords.title)
        })
    }

    /// Private object id → the label it shows as.
    static func labels(in context: TesseraContext) -> [UUID: String] {
        if let cache = context.privateLabelsCache, cache.revision == context.revision {
            return cache.labels
        }
        let result = computeLabels(in: context)
        context.privateLabelsCache = (context.revision, result)
        return result
    }

    private static func computeLabels(in context: TesseraContext) -> [UUID: String] {
        let store = ObjectStore(context: context)
        let classes = systemClasses(in: context)
        let last = BodyWeight.lastKg(in: store)
        let records = context.all(ObjectRecord.self).filter { !$0.isClassObject }

        func genericLabel(_ object: ObjectRecord) -> String {
            Self.genericLabel(object, classes: classes)
        }
        let processClass = classes[.process]
        func words(_ object: ObjectRecord) -> [String] {
            // A process keeps its resume point as JSON ({"weight":20,"reps":5}): not words, and it must not make a
            // plain running workout, or the routine it came from, private. Every other text it holds (`nextStep`,
            // `waitingOn`) is words and counts.
            if let processClass, let classDef = object.classDef, classDef.id == processClass.id {
                let texts = ClassResolver.effectiveFields(of: classDef).filter { $0.key != "resumePoint" }.compactMap {
                    store.value($0.key, of: object)?.stringValue
                }
                return [object.title] + texts
            }
            return [object.title] + object.values.storage.values.compactMap { value in
                switch value {
                case let .text(text), let .richText(text): text
                default: nil
                }
            }
        }

        var result: [UUID: String] = [:]
        for object in records {
            if let label = ObjectPrivacy.label(of: object, in: store, classes: classes) {
                result[object.id] = label
            } else if store.value("isPrivate", of: object) == .bool(true)
                || isPrivateTitle(object.title, lastWeightKg: last)
                || words(object).contains(where: { !isNumberList($0) && isPrivateText($0, lastWeightKg: last) })
            {
                result[object.id] = genericLabel(object)
            }
        }
        // What is inside a private object, and what carries its title, is private with it.
        var titles = Set(records.filter { result[$0.id] != nil }.map { $0.title.lowercased() })
            .subtracting(labels.map { $0.lowercased() })
        titles.remove("")
        var changed = true
        while changed {
            changed = false
            for object in records where result[object.id] == nil {
                if let parent = object.parent, let label = result[parent.id] {
                    result[object.id] = label
                    changed = true
                } else if titles.contains(object.title.lowercased()) {
                    result[object.id] = genericLabel(object)
                    changed = true
                } else if let ingredientClass = classes[.ingredient], object.classDef?.id == ingredientClass.id,
                          Self.onlyPrivateUse(of: object, private: result)
                {
                    // An ingredient only private recipes or items use gives their words away (G37).
                    result[object.id] = genericLabel(object)
                    changed = true
                }
            }
        }
        return result
    }

    /// Whether something links to the ingredient and every object that does is private (deleted ones count).
    private static func onlyPrivateUse(of ingredient: ObjectRecord, private result: [UUID: String]) -> Bool {
        let users = (ingredient.incomingLinks ?? []).compactMap(\.from)
        return !users.isEmpty && users.allSatisfy { result[$0.id] != nil }
    }

    /// An op summary or any line of text that holds a private word.
    static func summaryIsPrivate(_ text: String, context: TesseraContext) -> Bool {
        isPrivateText(text, lastWeightKg: BodyWeight.lastKg(in: ObjectStore(context: context)))
    }

    /// Only structure survives a masked object: done flags and dates.
    static func structural(_ value: FieldValue) -> Bool {
        switch value {
        case .bool, .date: true
        default: false
        }
    }
}

@MainActor
extension TesseraBackup {
    /// Removes private objects, their links and the ops that touched them from a copy that is leaving the phone.
    static func leaveOutPrivate(_ ids: [UUID: String], from copy: DatabaseQueue, context: TesseraContext) throws {
        // Objects that were private once but are plain now stay; their ops, which hold the old words, go.
        // Accepted for now (Product, QA on #707): ops of anything that ever hit the Home wall are over-dropped from the
        // iCloud copy, even when the object was never really private. Losing a plain history line is cheaper than
        // keeping an old private word.
        let past = PrivateWords.historyLabels(in: context, current: ids)
        let lastKg = BodyWeight.lastKg(in: ObjectStore(context: context))
        // Deleted rows must not linger in free pages: overwrite on delete, then rebuild the file below.
        try copy.writeWithoutTransaction { try $0.execute(sql: "PRAGMA secure_delete = ON") }
        try copy.write { db in
            for id in PrivateWords.localOnlyIDs(in: context).map(\.uuidString) {
                try db.execute(sql: "DELETE FROM object WHERE id = ?", arguments: [id])
                try db.execute(sql: "DELETE FROM link WHERE fromID = ? OR toObjectID = ?", arguments: [id, id])
                try db.execute(sql: "DELETE FROM op WHERE instr(objectIDs, ?) > 0", arguments: [id])
            }
            for id in ids.keys.map(\.uuidString) {
                try db.execute(sql: "DELETE FROM object WHERE id = ?", arguments: [id])
                try db.execute(sql: "DELETE FROM link WHERE fromID = ? OR toObjectID = ?", arguments: [id, id])
                try db.execute(sql: "DELETE FROM op WHERE instr(objectIDs, ?) > 0", arguments: [id])
            }
            for id in past.keys.map(\.uuidString) {
                try db.execute(sql: "DELETE FROM op WHERE instr(objectIDs, ?) > 0", arguments: [id])
            }
            // An action whose own summary holds a private word goes too ("Pay Dr Lee 120").
            let summaries = try Row.fetchAll(db, sql: "SELECT id, summary FROM op")
            // Summaries repeat ("Logged bench press 82.5 × 8"): each distinct line is judged once.
            var judged: [String: Bool] = [:]
            for row in summaries {
                let summary: String = row["summary"]
                let isPrivate = judged[summary] ?? PrivateWords.isPrivateText(summary, lastWeightKg: lastKg)
                judged[summary] = isPrivate
                if isPrivate {
                    try db.execute(sql: "DELETE FROM op WHERE id = ?", arguments: [row["id"] as String])
                }
            }
        }
        try copy.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
            try db.execute(sql: "VACUUM")
        }
    }
}

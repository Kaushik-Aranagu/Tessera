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

    static func isPrivateText(_ text: String, lastWeightKg: Double?) -> Bool {
        labels.contains(text.trimmingCharacters(in: .whitespacesAndNewlines))
            || ObjectPrivacy.isPrivateText(text, lastWeightKg: lastWeightKg)
    }

    /// Private object id → the label it shows as.
    static func labels(in context: TesseraContext) -> [UUID: String] {
        let store = ObjectStore(context: context)
        var classes: [SystemCatalog.Key: ClassDef] = [:]
        for classDef in context.all(ClassDef.self) {
            if let key = SystemCatalog.Key.allCases.first(where: { $0.systemKey == classDef.systemKey }) {
                classes[key] = classDef
            }
        }
        let last = BodyWeight.lastKg(in: store)
        let records = context.all(ObjectRecord.self).filter { !$0.isClassObject }

        func genericLabel(_ object: ObjectRecord) -> String {
            guard let classDef = object.classDef else { return SecretWords.title }
            func isA(_ key: SystemCatalog.Key) -> Bool {
                classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
            }
            if isA(.listItem) { return "Private item" }
            if isA(.recipe) || isA(.recipeLine) || isA(.recipeStep) || isA(.cook) { return "Private recipe" }
            if isA(.task) { return ObjectPrivacy.taskLabel }
            if isA(.tessMemory) { return ObjectPrivacy.memoryLabel }
            return SecretWords.title
        }
        func words(_ object: ObjectRecord) -> [String] {
            [object.title] + object.values.storage.values.compactMap { value in
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
                || words(object).contains(where: { isPrivateText($0, lastWeightKg: last) })
                // A title also goes by the wider Home wall: money, health, places and people ("Pay Dr Lee").
                || HomeDonePack.isWalled(object.title, lastWeightKg: last)
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
                }
            }
        }
        return result
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
        let lastKg = BodyWeight.lastKg(in: ObjectStore(context: context))
        // Deleted rows must not linger in free pages: overwrite on delete, then rebuild the file below.
        try copy.writeWithoutTransaction { try $0.execute(sql: "PRAGMA secure_delete = ON") }
        try copy.write { db in
            for id in ids.keys.map(\.uuidString) {
                try db.execute(sql: "DELETE FROM object WHERE id = ?", arguments: [id])
                try db.execute(sql: "DELETE FROM link WHERE fromID = ? OR toObjectID = ?", arguments: [id, id])
                try db.execute(sql: "DELETE FROM op WHERE instr(objectIDs, ?) > 0", arguments: [id])
            }
            // An action whose own summary holds a private word goes too ("Pay Dr Lee 120").
            let summaries = try Row.fetchAll(db, sql: "SELECT id, summary FROM op")
            for row in summaries {
                let summary: String = row["summary"]
                if PrivateWords.isPrivateText(summary, lastWeightKg: lastKg) {
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

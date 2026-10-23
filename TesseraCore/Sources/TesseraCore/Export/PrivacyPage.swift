import Foundation

/// "What stays on this phone" (Together round 12, 179, switch walledPageV2): Settings > Privacy as plain sentences
/// that tell the truth from the store. Counts only, read live from ObjectPrivacy; a name is never listed. Nothing here
/// can turn a wall off: it is a read, and Tess asks Claude is the one control, as now.
@MainActor
public enum PrivacyPage {
    public struct Count: Equatable, Sendable {
        public let noun: String
        public let count: Int
    }

    public struct Facts: Equatable, Sendable {
        public let total: Int
        public let counts: [Count]
    }

    /// Classes counted, with their plain nouns, in reading order. A pool is always private by label.
    private static let kinds: [(SystemCatalog.Key, singular: String, plural: String)] = [
        (.routine, "routine", "routines"), (.workout, "workout", "workouts"), (.note, "note", "notes"),
        (.task, "task", "tasks"), (.recipe, "recipe", "recipes"), (.list, "list", "lists"),
        (.listItem, "item", "items"), (.pool, "pool", "pools"), (.tessMemory, "memory", "memories"),
        (.book, "book", "books"), (.spend, "spend", "spends"), (.inflow, "deposit", "deposits"),
        (.poolMove, "move", "moves"), (.rateNote, "rate", "rates"), (.cookSession, "cook", "cooks"),
        (.cookDish, "dish", "dishes"), (.place, "place", "places"),
    ]

    public static func facts(engine: ActionEngine) -> Facts {
        let store = engine.store, classes = engine.classes
        var counts: [Count] = []
        var counted = Set<UUID>()
        for (key, singular, plural) in kinds {
            guard let classDef = classes[key] else { continue }
            // Subclasses count too, and a thing is counted once, under the first kind that claims it.
            let count = store.objects(of: classDef, includingSubclasses: true).count {
                !$0.isDeleted && ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) != nil
                    && counted.insert($0.id).inserted
            }
            if count > 0 {
                counts.append(Count(noun: count == 1 ? singular : plural, count: count))
            }
        }
        return Facts(total: counts.reduce(0) { $0 + $1.count }, counts: counts)
    }

    /// "4 private things. 2 routines, 1 workout, 1 note. They show as Private everywhere."
    public static func countsLine(_ facts: Facts) -> String {
        guard facts.total > 0 else { return "No private things yet. Anything private shows as Private everywhere." }
        let head = "\(facts.total) private \(facts.total == 1 ? "thing" : "things")."
        let parts = facts.counts.map { "\($0.count) \($0.noun)" }.joined(separator: ", ")
        return "\(head) \(parts). They show as Private everywhere."
    }

    public static let neverLeaves = "Never leaves this phone: health, calendar, body, calories, money amounts."

    /// What Claude is sent varies by job, so the page claims no more than the switch itself.
    public static func askClaudeLine(on: Bool) -> String {
        on ? "Tess asks Claude: On." : "Tess asks Claude: Off."
    }

    /// The whole page, top to bottom. `backupLine` comes from `BackupWords.lastLine`.
    public static func lines(engine: ActionEngine, claudeOn: Bool, backupLine: String) -> [String] {
        [countsLine(facts(engine: engine)), neverLeaves, askClaudeLine(on: claudeOn), backupLine]
    }
}

import Foundation

/// Find (design sheet 158, search): one query over the local objects, grouped by app. Engine only, local only: it
/// reads the in-memory graph, never the network, and Claude's code (TesseraTess) never calls it.
///
/// Private things are walled. An object whose `ObjectPrivacy.shownLabel` is set is never a hit and never matched by
/// its words in a way the caller can see; the result only carries how many such objects would have matched
/// (`privateCount`). A query that is itself walled returns nothing and a count of 0, so it never reveals that
/// something matched. Money (spends, pools, inflows, moves, rates), body, health and calendar objects are not
/// searched at all, and are not counted.
public enum Find {
    public struct Hit: Equatable, Sendable {
        public let id: UUID
        public let title: String
        /// The class name ("Note", "Recipe", "Bench Press").
        public let kind: String
        /// 4 exact title, 3 title starts with the query, 2 every word starts a title word, 1 found in a note's body.
        public let score: Int
    }

    public struct Group: Equatable, Sendable {
        /// Nil for the "everything else" group (tasks, books).
        public let app: AppID?
        public let hits: [Hit]
    }

    public struct Result: Equatable, Sendable {
        public let groups: [Group]
        /// How many private objects would have matched. Never says which.
        public let privateCount: Int
        public var isEmpty: Bool {
            groups.isEmpty
        }
    }

    static let bodyPrefixLength = 200

    /// Classes searched by name. Everything else (money, health, body, calendar, sets, entries) is skipped entirely.
    private static let searchable: [SystemCatalog.Key] = [
        .note, .task, .list, .listItem, .recipe, .ingredient, .workout, .routine, .exercise, .plan, .book,
    ]

    @MainActor
    public static func query(_ text: String, engine: ActionEngine, limit: Int = 5) -> Result {
        let store = engine.store
        let classes = engine.classes
        let words = tokens(text)
        guard !words.isEmpty, limit > 0 else { return Result(groups: [], privateCount: 0) }
        // A walled query matches nothing and says nothing.
        if ObjectPrivacy.isPrivateWord(text, in: store) {
            return Result(groups: [], privateCount: 0)
        }
        let whole = words.joined(separator: " ")
        let noteClass = classes[.note]
        let exerciseClass = classes[.exercise]
        let roots = searchable.compactMap { classes[$0] }

        var allowed: [UUID: Bool] = [:]
        func isSearchable(_ classDef: ClassDef) -> Bool {
            if let known = allowed[classDef.id] {
                return known
            }
            let result = roots.contains { ClassResolver.isSubclass(classDef, of: $0) }
            allowed[classDef.id] = result
            return result
        }

        var byApp: [AppID?: [(hit: Hit, updated: Date)]] = [:]
        var privateCount = 0
        for object in store.context.all(ObjectRecord.self) where !object.isDeleted {
            guard let classDef = object.classDef, isSearchable(classDef) else { continue }
            // A class object is a class's own record: searchable only for exercises (Bench Press under Training).
            if object.isClassObject {
                guard let exerciseClass, ClassResolver.isSubclass(classDef, of: exerciseClass) else { continue }
            }
            let titleWords = tokens(object.title)
            let titleText = titleWords.joined(separator: " ")
            var score = 0
            if !titleWords.isEmpty, matches(words, in: titleWords) {
                score = titleText == whole ? 4 : (titleText.hasPrefix(whole) ? 3 : 2)
            } else if let noteClass, ClassResolver.isSubclass(classDef, of: noteClass) {
                let body = store.value("body", of: object)?.stringValue ?? ""
                if matches(words, in: titleWords + tokens(String(body.prefix(bodyPrefixLength)))) {
                    score = 1
                }
            }
            guard score > 0 else { continue }
            if ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) != nil {
                privateCount += 1
                continue
            }
            let hit = Hit(id: object.id, title: object.title, kind: classDef.name, score: score)
            byApp[ClassResolver.app(for: classDef), default: []].append((hit, object.updatedAt))
        }

        let order: [AppID?] = AppID.allCases.map { Optional($0) } + [nil]
        let groups: [Group] = order.compactMap { app in
            guard let found = byApp[app], !found.isEmpty else { return nil }
            let ranked = found.sorted {
                $0.hit.score != $1.hit.score ? $0.hit.score > $1.hit.score : $0.updated > $1.updated
            }
            return Group(app: app, hits: ranked.prefix(limit).map(\.hit))
        }
        return Result(groups: groups, privateCount: privateCount)
    }

    /// Lowercase, diacritic-free words (letters and digits).
    static func tokens(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    /// Every query word starts some word of the text.
    private static func matches(_ query: [String], in words: [String]) -> Bool {
        query.allSatisfy { q in words.contains { $0.hasPrefix(q) } }
    }
}

import Foundation
import TesseraCore

/// The shared memory one agent may see, addressed by path (spec M2): his objects (`/activity/routine/push-a`) and the
/// beliefs (`/beliefs/you-train-after-work`). Built for one run from the store and the agent's `MemoryScope`, so a
/// path the scope doesn't read resolves to nothing, whatever the model asks for.
///
/// Walls, by construction:
/// - A private object's path and text use its shown label ("Private note"), never its title.
/// - A belief that stays on the phone is not in the index.
/// - Untitled records (sets, entries) are left to the `query` tool, which counts them on the phone.
@MainActor
public struct MemoryIndex {
    public enum Kind: String, Sendable {
        case object, belief
    }

    public struct Entry: Sendable, Equatable {
        public var path: String
        public var id: UUID
        public var kind: Kind
        /// The one line the model reads: the shown sentence, or the belief as she would say it.
        public var digest: String
        public var candidate: RecallCandidate
        /// Lowercased words the ask is matched against (the shown text only).
        var words: Set<String>
    }

    public let scope: MemoryScope
    public private(set) var entries: [String: Entry] = [:]
    public private(set) var graph = RecallGraph()
    private var pathByID: [UUID: String] = [:]

    public init(engine: ActionEngine, scope: MemoryScope, calendar: Calendar = .current) {
        self.scope = scope
        let store = engine.store, classes = engine.classes
        guard let thing = classes[.thing] else { return }
        let beliefClass = classes[.belief]
        func isBelief(_ record: ObjectRecord) -> Bool {
            guard let beliefClass, let classDef = record.classDef else { return false }
            return ClassResolver.isSubclass(classDef, of: beliefClass)
        }
        // Beliefs come in below, as beliefs; here only his things. Under strict, nothing the pack would taint
        // phone-only (money, health, body, calendar) enters: a tool result carries no taint for the Door to act on.
        let objects = store.objects(of: thing).filter { record in
            !record.isDeleted && !record.isClassObject && !isBelief(record)
                && scope.reads(record.classDef, classes: classes)
                && !(scope.policy == .strict && TessAskRouter.isUnnameable(record, classes: classes))
        }
        .sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }

        for record in objects where !record.title.isEmpty {
            // Under lab a private thing is indexed by its own words (his Oct 27 call: Claude sees everything).
            let label = ClaudeSees.label(of: record, in: store, classes: classes, strict: scope.policy == .strict)
            let shown = label ?? TessAskRouter.shownSentence(record, in: store, classes: classes, calendar: calendar)
                ?? record.title
            let base = Self.path(of: record, label: label, store: store)
            add(Entry(path: base, id: record.id, kind: .object, digest: shown,
                      candidate: RecallCandidate(path: base), words: Self.words(shown)))
        }

        let beliefs = TessBeliefStore(engine: engine)
        for belief in beliefs.open() where !belief.isPrivate && Self.inScope(belief, scope: scope, engine: engine) {
            let base = "/beliefs/" + ObjectPath.Segment(target: .object(belief.id), title: belief.words).slug
            let importance: RecallImportance = switch belief.source {
            case .told: belief.kept ? .correction : .told
            case .learned: .correction
            case .noticed: .noticed
            case .inferred: belief.isMaybe ? .inferred : .noticed
            }
            add(Entry(path: base, id: belief.id, kind: .belief, digest: belief.spoken,
                      candidate: RecallCandidate(path: base, uses: belief.uses, importance: importance,
                                                 confidence: belief.confidence),
                      words: Self.words(belief.words)))
        }

        // Links both ways between things in the slice: an object's links, a belief's subject and evidence.
        for (id, path) in pathByID {
            guard let record = store.object(id: id) else { continue }
            for link in record.outgoingLinks ?? [] {
                if let target = link.toObject, let other = pathByID[target.id] {
                    graph.link(path, other)
                }
            }
            if let parent = record.parent, let other = pathByID[parent.id] {
                graph.link(path, other)
            }
        }
    }

    /// Adds an entry; a second thing with the same path gets "-2", "-3" (oldest keeps the plain path).
    private mutating func add(_ entry: Entry) {
        var entry = entry
        var path = entry.path
        var count = 1
        while entries[path] != nil {
            count += 1
            path = "\(entry.path)-\(count)"
        }
        entry.path = path
        entry.candidate.path = path
        entries[path] = entry
        pathByID[entry.id] = path
    }

    /// Whether a belief belongs to this slice: about him (every agent), or about a class or an object it reads.
    static func inScope(_ belief: TessBelief, scope: MemoryScope, engine: ActionEngine) -> Bool {
        let store = engine.store, classes = engine.classes
        switch belief.subject {
        case .you:
            // A belief about him built only from things this slice can't read (his spending) stays out.
            let evidence = belief.evidence.compactMap { store.object(id: $0) }
            return evidence.isEmpty || evidence.contains { scope.reads($0.classDef, classes: classes) }
        case let .classDef(id):
            return store.classDef(id: id).map { scope.reads($0, classes: classes) } ?? false
        case let .object(id):
            return store.object(id: id).map { scope.reads($0.classDef, classes: classes) } ?? false
        }
    }

    /// An object's path: its class path, then its title or, when private, its shown label.
    static func path(of record: ObjectRecord, label: String?, store: ObjectStore) -> String {
        guard let label else { return store.path(of: record).description }
        let base = record.classDef.map(ClassResolver.path(of:)) ?? ObjectPath(segments: [])
        return base.appending(.init(target: .object(record.id), title: label)).description
    }

    static func words(_ text: String) -> Set<String> {
        let all = text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        return Set(all.filter { !stopWords.contains($0) })
    }

    static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "of", "to", "in", "on", "at", "for", "with", "my", "me", "i", "you", "your",
        "is", "it", "do", "did", "what", "when", "how", "about", "this", "that",
    ]

    // MARK: Reading

    public func entry(_ path: String) -> Entry? {
        entries[MemoryScope.normalize(path)] ?? entries[path]
    }

    public func path(of id: UUID) -> String? {
        pathByID[id]
    }

    /// How well the ask's words fit an entry's shown words: the share of the ask's words it holds, 0...1.
    func fit(_ ask: Set<String>, _ entry: Entry) -> Double {
        guard !ask.isEmpty else { return 0 }
        let hits = ask.filter { word in
            entry.words.contains(word) || entry.words.contains { $0.hasPrefix(word) && word.count >= 4 }
        }
        return Double(hits.count) / Double(ask.count)
    }

    /// Recall (spec M2): what scores above the floor for an ask, best first. Seeds are the things the ask is about
    /// (on screen, in the pack); words fit free text. `kinds` narrows to objects or beliefs.
    public func recall(_ text: String, seeds: [UUID], kinds: Set<Kind>? = nil, limit: Int = 10,
                       floor: Double = BudgetDefaults.recallFloor, now: Date = .now) -> [(entry: Entry, score: Double)]
    {
        let ask = Self.words(text)
        var seedPaths = seeds.compactMap { pathByID[$0] }
        // A thing his words name exactly is a seed too: "bench press" spreads to what links to it.
        let named = entries.values.filter { fit(ask, $0) >= 0.99 && $0.kind == .object }.map(\.path)
        seedPaths += named
        let candidates = entries.values.filter { kinds?.contains($0.kind) ?? true }.map { entry in
            var candidate = entry.candidate
            candidate.fit = fit(ask, entry)
            return candidate
        }
        let ranked = Recall(graph: graph, now: now).rank(candidates, seeds: seedPaths)
        return ranked.filter { $0.total >= floor }.prefix(max(1, min(limit, 20))).compactMap { score in
            entries[score.path].map { (entry: $0, score: score.total) }
        }
    }

    /// An entry's neighbors in the slice, nearest first by path.
    public func links(of path: String) -> [Entry] {
        guard let start = entry(path) else { return [] }
        return (graph.neighbors[start.path] ?? []).sorted().compactMap { entries[$0] }
    }
}

/// The shipped recall floor, from the budgets (spec M3), for callers outside a pack.
public enum BudgetDefaults {
    public static var recallFloor: Double {
        BudgetRow.defaults(for: .haiku).recallFloor
    }
}

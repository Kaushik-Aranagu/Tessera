import Foundation
import TesseraCore

/// M2's fetch tools (docs/ai/harness/memory-scopes.md): how an agent pages in more of its memory than the pack holds.
/// Each reads only the agent's `MemoryIndex`, so a path outside its scope is "nothing there", and each answer carries
/// paths the model can follow or cite.
/// - `recall(query, kinds, limit)`: what scores above the floor, best first.
/// - `links(path)`: what a thing links to and what links to it.
/// - `history(path)`: what changed. A belief's chain of versions, or the actions that touched a thing (their names
///   and times, never their titles).
/// - `remember(words, key, about, evidence)`: keeps an inferred belief, pending as a ghost row he keeps or dismisses.
///
/// `open` stays the read for one thing: it takes these paths as well as the pack's handles.
@MainActor
public enum TessRecallTools {
    public static let recall = "recall"
    public static let links = "links"
    public static let history = "history"
    public static let remember = "remember"
    public static let names: Set<String> = [recall, links, history, remember]
    /// The most one answer holds.
    public static let maxCharacters = 2400
    /// The most actions `history` lists.
    public static let maxHistory = 30
    /// A belief she keeps on her own starts as a maybe.
    static let inferredConfidence = 0.6

    /// What a call returns: the text the model reads, and the ghost rows a write left.
    public struct Result: Sendable, Equatable {
        public var text: String
        public var isError: Bool
        public var ghosts: [UUID]
    }

    // MARK: Specs

    public static var specs: [ToolSpec] {
        [
            spec(recall, "Search your memory: his things and what you know about him. Returns paths, best first; "
                + "follow one with open, links or history. Use it before saying you don't know.", [
                    "type": "object", "additionalProperties": false, "required": ["query", "kinds", "limit"],
                    "properties": [
                        "query": ["type": "string", "description": "What to look for, in his words."],
                        "kinds": ["type": "string", "enum": ["all", "things", "beliefs"],
                                  "description": "things are his objects, beliefs what you know about him."],
                        "limit": ["type": "integer", "description": "How many, 1 to 20."],
                    ],
                ]),
            spec(links, "What a thing in your memory links to, and what links to it; read only.", pathSchema),
            spec(history, "What changed: a belief's earlier versions, or when a thing was changed and by whom.",
                 pathSchema),
            spec(remember, "Keep something you learned about him, as a maybe he can keep or dismiss. Name the "
                + "things that show it; never keep money, health or anything he said is private.", [
                    "type": "object", "additionalProperties": false,
                    "required": ["words", "key", "about", "evidence"],
                    "properties": [
                        "words": ["type": "string", "description": "One line, second person, at most 80 characters."],
                        "key": ["type": "string", "enum": TessBelief.Key.allCases.map(\.rawValue)],
                        "about": ["type": ["string", "null"],
                                  "description": "The path of the thing it is about; null when it is about him."],
                        "evidence": ["type": "array", "items": ["type": "string"],
                                     "description": "Paths of the things that show it, 1 to 5."],
                    ],
                ]),
        ]
    }

    static let pathSchema: [String: Any] = [
        "type": "object", "additionalProperties": false, "required": ["path"],
        "properties": ["path": ["type": "string", "description": "A path from recall or the pack."]],
    ]

    static func spec(_ name: String, _ description: String, _ schema: [String: Any]) -> ToolSpec {
        ToolSpec(name: name, description: description,
                 schema: (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys]))
                     ?? Data("{}".utf8))
    }

    // MARK: Running

    /// Runs one call against the agent's slice. `seeds` are the things the ask is about (the pack's handles). Never
    /// throws: a failure is the text the model reads.
    public static func run(_ name: String, arguments: Data, index: MemoryIndex, engine: ActionEngine,
                           seeds: [UUID] = [], now: Date = .now, calendar: Calendar = .current) -> Result
    {
        guard let args = (try? JSONSerialization.jsonObject(with: arguments)) as? [String: Any] else {
            return Result(text: "Unreadable arguments.", isError: true, ghosts: [])
        }
        switch name {
        case recall:
            return runRecall(args, index: index, seeds: seeds, now: now)
        case links:
            guard let path = args["path"] as? String, index.entry(path) != nil else { return nothingThere }
            let lines = index.links(of: path).map { "\($0.path): \($0.digest)" }
            return answer(lines.isEmpty ? ["Nothing links to it."] : lines)
        case history:
            guard let path = args["path"] as? String, let entry = index.entry(path) else { return nothingThere }
            return answer(historyLines(entry, engine: engine, calendar: calendar))
        case remember:
            return runRemember(args, index: index, engine: engine, now: now)
        default:
            return Result(text: "That isn't a call I can make here.", isError: true, ghosts: [])
        }
    }

    static let nothingThere = Result(text: "Nothing there.", isError: true, ghosts: [])

    static func answer(_ lines: [String]) -> Result {
        var text = lines.joined(separator: "\n")
        if text.count > maxCharacters {
            text = String(text.prefix(maxCharacters - 1)) + "…"
        }
        return Result(text: text, isError: false, ghosts: [])
    }

    static func runRecall(_ args: [String: Any], index: MemoryIndex, seeds: [UUID], now: Date) -> Result {
        guard let query = args["query"] as? String, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return Result(text: "Say what to look for.", isError: true, ghosts: [])
        }
        let kinds: Set<MemoryIndex.Kind>? = switch args["kinds"] as? String {
        case "things": [.object]
        case "beliefs": [.belief]
        default: nil
        }
        let limit = (args["limit"] as? Int) ?? 10
        let hits = index.recall(query, seeds: seeds, kinds: kinds, limit: limit, now: now)
        guard !hits.isEmpty else { return answer([ContextPacker.nothingKeptLine]) }
        return answer(hits.map { hit in
            "\(hit.entry.path): \(hit.entry.digest) (\(String(format: "%.2f", hit.score)))"
        })
    }

    static func historyLines(_ entry: MemoryIndex.Entry, engine: ActionEngine, calendar: Calendar) -> [String] {
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Locale(identifier: "en_US"),
                                      calendar: calendar, timeZone: calendar.timeZone)
        switch entry.kind {
        case .belief:
            let chain = TessBeliefStore(engine: engine).history(of: entry.id).filter { !$0.isPrivate }
            return chain.map { belief in
                let span = belief.validUntil.map { "until \($0.formatted(format))" } ?? "now"
                return "\(belief.validFrom.formatted(format)), \(span): \(belief.spoken)"
            }
        case .object:
            let ops = engine.history(of: entry.id, limit: maxHistory).filter { $0.state != .pending }
            guard !ops.isEmpty else { return ["No changes kept."] }
            return ops.map { op in
                let who = op.actorRaw == "tess" ? "Tess" : "he"
                let undone = op.state == .undone ? " (undone)" : ""
                return "\(op.createdAt.formatted(format)), \(who): \(op.action)\(undone)"
            }
        }
    }

    static func runRemember(_ args: [String: Any], index: MemoryIndex, engine: ActionEngine, now: Date) -> Result {
        guard let words = (args["words"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !words.isEmpty,
              words.count <= 80
        else {
            return Result(text: "Keep it to one line of at most 80 characters.", isError: true, ghosts: [])
        }
        guard let key = (args["key"] as? String).flatMap(TessBelief.Key.init(rawValue:)) else {
            return Result(text: "Pick a key from the list.", isError: true, ghosts: [])
        }
        let evidence = ((args["evidence"] as? [String]) ?? []).prefix(5).compactMap { index.entry($0) }.filter {
            $0.kind == .object
        }
        guard !evidence.isEmpty else {
            return Result(text: "Name at least one thing from recall that shows it.", isError: true, ghosts: [])
        }
        var subject: UUID?
        if let about = args["about"] as? String {
            guard let entry = index.entry(about), entry.kind == .object else { return nothingThere }
            subject = entry.id
        }
        let store = engine.store, classes = engine.classes
        // Built from a private thing, it stays on the phone too.
        let touchesPrivate = (evidence.map(\.id) + [subject].compactMap { $0 }).contains { id in
            store.object(id: id).map { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) != nil } ?? false
        }
        let action = RecordBelief(words: words, key: key, source: .inferred, confidence: inferredConfidence,
                                  subject: subject, evidence: evidence.map(\.id),
                                  isPrivate: touchesPrivate ? true : nil,
                                  validFrom: now)
        do {
            let record = try engine.perform(action, by: .tess, pending: true).record
            return Result(text: "Kept as a maybe; he keeps or dismisses it.", isError: false, ghosts: [record.id])
        } catch {
            let line = BeliefRefusal.line(error) ?? "That can't be kept."
            return Result(text: line, isError: true, ghosts: [])
        }
    }
}

import Foundation
import TesseraCore

/// An agent's own notebook (docs/ai/harness/agents.md): pages under `/memories/<agent>/` that it keeps for itself
/// between runs (how he likes his warm-ups, which store has the good bread). Only that agent reads or writes it; the
/// path and the page's agent both have to match. Pages are written without ops and stay on the phone, in no copy.
///
/// Walls:
/// - Nothing key-shaped, no secret word and no word of a private thing is ever written.
/// - A page written under lab may hold health or calendar facts, so it is never read under strict.
/// - At most 40 pages, each at most 4,000 characters.
@MainActor
public struct AgentNotebook {
    public static let name = "notebook"
    public static let maxCharacters = 4000
    public static let maxPages = 40

    public let engine: ActionEngine
    public let scope: MemoryScope
    public var now: Date

    public init(engine: ActionEngine, scope: MemoryScope, now: Date = .now) {
        self.engine = engine
        self.scope = scope
        self.now = now
    }

    var store: ObjectStore {
        engine.store
    }

    // MARK: Pages

    /// This agent's pages it may read under the policy, by path.
    func pages() -> [ObjectRecord] {
        guard let pageClass = engine.classes[.notebookPage] else { return [] }
        return store.objects(of: pageClass).filter { page in
            !page.isDeleted && store.value("agentName", of: page)?.stringValue == scope.agent
                && scope.owns(path(of: page))
                && (scope.policy == .lab || store.value("lab", of: page) != .bool(true))
        }
        .sorted { path(of: $0) < path(of: $1) }
    }

    func path(of page: ObjectRecord) -> String {
        store.value("path", of: page)?.stringValue ?? ""
    }

    func body(of page: ObjectRecord) -> String {
        store.value("body", of: page)?.stringValue ?? ""
    }

    func page(_ path: String) -> ObjectRecord? {
        let wanted = MemoryScope.normalize(path)
        return pages().first { self.path(of: $0) == wanted }
    }

    /// Every page this agent may read: path and first line, for its context.
    public func index() -> [(path: String, firstLine: String)] {
        pages().map { page in
            (path: path(of: page), firstLine: body(of: page).split(separator: "\n").first.map(String.init) ?? "")
        }
    }

    // MARK: Writing

    public enum Refusal: String, Error, Sendable {
        case notYours = "That page isn't in your notebook."
        case walled = "That can't be kept: it holds a private word or a key."
        case tooLong = "A page holds at most 4,000 characters."
        case full = "The notebook holds at most 40 pages; delete one first."
        case missing = "No page there."
        case exists = "A page is already there."
        case notFound = "That text isn't on the page."
    }

    /// Whether text may be kept at all: never a key, a secret word or a word of a private thing.
    func isWalled(_ text: String) -> Bool {
        !Wall.judge(text, in: store).isDisjoint(with: [.key, .secret, .privateWord])
    }

    func write(_ path: String, body text: String, to existing: ObjectRecord? = nil) throws {
        let normalized = MemoryScope.normalize(path)
        guard scope.owns(normalized) else { throw Refusal.notYours }
        guard text.count <= Self.maxCharacters else { throw Refusal.tooLong }
        guard !isWalled(text), !isWalled(normalized) else { throw Refusal.walled }
        let target: ObjectRecord
        if let existing {
            target = existing
        } else {
            guard let pageClass = engine.classes[.notebookPage] else { throw Refusal.missing }
            guard allPagesCount() < Self.maxPages else { throw Refusal.full }
            target = try store.create(pageClass, title: "")
            try store.set("agentName", to: .text(scope.agent), on: target)
        }
        try store.set("path", to: .text(normalized), on: target)
        try store.set("body", to: .text(text), on: target)
        try store.set("updatedAt", to: .date(now), on: target)
        // Lab once means lab for good: a page that ever held lab words is never read under strict.
        if scope.policy == .lab {
            try store.set("lab", to: .bool(true), on: target)
        }
        store.save()
    }

    /// Every page the agent has, under either policy (the cap counts them all).
    func allPages() -> [ObjectRecord] {
        guard let pageClass = engine.classes[.notebookPage] else { return [] }
        return store.objects(of: pageClass).filter {
            !$0.isDeleted && store.value("agentName", of: $0)?.stringValue == scope.agent
        }
    }

    func allPagesCount() -> Int {
        allPages().count
    }

    /// Whether a page holds the path under either policy, so strict never writes a twin of a lab page.
    func isTaken(_ path: String) -> Bool {
        let wanted = MemoryScope.normalize(path)
        return allPages().contains { self.path(of: $0) == wanted }
    }

    public func create(_ path: String, text: String) throws {
        guard !isTaken(path) else { throw Refusal.exists }
        try write(path, body: text)
    }

    public func replace(_ path: String, old: String, new: String) throws {
        guard let page = page(path) else { throw Refusal.missing }
        let text = body(of: page)
        guard let range = text.range(of: old) else { throw Refusal.notFound }
        try write(path, body: text.replacingCharacters(in: range, with: new), to: page)
    }

    /// Inserts a line after line `line` (0 puts it first).
    public func insert(_ path: String, line: Int, text: String) throws {
        guard let page = page(path) else { throw Refusal.missing }
        var lines = body(of: page).isEmpty ? [] : body(of: page).components(separatedBy: "\n")
        lines.insert(text, at: min(max(line, 0), lines.count))
        try write(path, body: lines.joined(separator: "\n"), to: page)
    }

    public func remove(_ path: String) throws {
        guard let page = page(path) else { throw Refusal.missing }
        store.context.delete(page)
        store.save()
        store.context.scrubLog()
    }

    public func rename(_ path: String, to newPath: String) throws {
        guard let page = page(path) else { throw Refusal.missing }
        guard !isTaken(newPath) else { throw Refusal.exists }
        try write(newPath, body: body(of: page), to: page)
    }

    /// A page with line numbers, or the folder's pages when `path` is the folder (or nil).
    public func view(_ path: String?) -> String {
        if let path, let page = page(path) {
            let lines = body(of: page).components(separatedBy: "\n")
            return lines.enumerated().map { "\($0.offset + 1)\t\($0.element)" }.joined(separator: "\n")
        }
        let listed = index()
        guard !listed.isEmpty else { return "Your notebook is empty." }
        return listed.map { "\($0.path): \($0.firstLine)" }.joined(separator: "\n")
    }

    // MARK: The tool

    public static var spec: ToolSpec {
        let nullableString: [String: Any] = ["type": ["string", "null"]]
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false,
            "required": ["command", "path", "text", "old", "line", "newPath"],
            "properties": [
                "command": ["type": "string", "enum": ["view", "create", "str_replace", "insert", "delete", "rename"]],
                "path": ["type": "string", "description": "A page or the folder, under your /memories/ folder."],
                "text": nullableString,
                "old": nullableString,
                "line": ["type": ["integer", "null"]],
                "newPath": nullableString,
            ],
        ]
        return ToolSpec(name: name, description: "Your own notebook: pages you keep for yourself between runs, under "
            + "your /memories/ folder. Keep what helps next time (how he likes things), never what is in his record.",
            schema: (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8))
    }

    /// Runs one notebook command. Never throws: a refusal is the text the model reads.
    public func run(arguments: Data) -> (text: String, isError: Bool) {
        guard let args = (try? JSONSerialization.jsonObject(with: arguments)) as? [String: Any],
              let command = args["command"] as? String, let path = args["path"] as? String
        else {
            return ("Unreadable arguments.", true)
        }
        let text = args["text"] as? String ?? ""
        do {
            switch command {
            case "view":
                return (view(scope.owns(path) ? path : nil), false)
            case "create":
                try create(path, text: text)
            case "str_replace":
                try replace(path, old: args["old"] as? String ?? "", new: text)
            case "insert":
                try insert(path, line: args["line"] as? Int ?? 0, text: text)
            case "delete":
                try remove(path)
            case "rename":
                try rename(path, to: args["newPath"] as? String ?? "")
            default:
                return ("Unknown command.", true)
            }
            return ("Saved.", false)
        } catch let refusal as Refusal {
            return (refusal.rawValue, true)
        } catch {
            return ("That didn't save.", true)
        }
    }
}

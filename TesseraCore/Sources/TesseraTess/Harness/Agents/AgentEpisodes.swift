import Foundation
import TesseraCore

/// What each agent was asked and what it reported (docs/ai/harness/agents.md): its episodes. The next run starts
/// from the last few, so the Deck that answers today knows what it said on Tuesday. Written without ops, kept 90 days,
/// on the phone only, in no copy.
///
/// Walls, as her turns have them:
/// - A key-shaped line, a secret word or a word of a private thing is stored as a placeholder and held back.
/// - Anything about a money, health, body or calendar thing is held back under strict.
/// - An exchange under lab is read only under lab.
@MainActor
public struct AgentEpisodes {
    public static let keepDays = 90
    /// The most a run starts from.
    public static let recentLimit = 8
    /// The most characters an ask or a report keeps.
    public static let maxCharacters = 600

    public struct Episode: Sendable, Equatable {
        public var at: Date
        public var ask: String
        public var report: String
    }

    public let engine: ActionEngine

    public init(engine: ActionEngine) {
        self.engine = engine
    }

    var store: ObjectStore {
        engine.store
    }

    func rows(of agent: String) -> [ObjectRecord] {
        guard let episodeClass = engine.classes[.agentEpisode] else { return [] }
        return store.objects(of: episodeClass)
            .filter { !$0.isDeleted && store.value("agentName", of: $0)?.stringValue == agent }
            .sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    }

    /// The words as they may be kept: a walled line becomes the placeholder.
    func kept(_ text: String) -> (text: String, walled: Bool) {
        let trimmed = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxCharacters))
        let walled = looksLikeClaudeKey(trimmed) || SecretWords.mentions(trimmed)
            || ObjectPrivacy.containsPrivateWord(trimmed, in: store)
        return walled ? (TessConversation.placeholder, true) : (trimmed, false)
    }

    /// Keeps one exchange. `lab` is the policy it ran under.
    @discardableResult
    public func append(agent: String, ask: String, report: String, about: [ObjectRecord] = [], lab: Bool,
                       at date: Date = .now) -> ObjectRecord?
    {
        guard let episodeClass = engine.classes[.agentEpisode] else { return nil }
        expire(now: date)
        let asked = kept(ask), said = kept(report)
        let classes = engine.classes
        let sensitive = about.contains { TessAskRouter.isUnnameable($0, classes: classes) }
        let held = asked.walled || said.walled || (sensitive && !lab)
        guard let row = try? store.create(episodeClass, title: "") else { return nil }
        row.createdAt = date
        try? store.set("agentName", to: .text(agent), on: row)
        try? store.set("at", to: .date(date), on: row)
        try? store.set("ask", to: .text(asked.text), on: row)
        try? store.set("report", to: .text(said.text), on: row)
        try? store.set("lab", to: .bool(lab || sensitive), on: row)
        try? store.set("held", to: .bool(held), on: row)
        let named = about.filter { !$0.isDeleted }
        if !named.isEmpty {
            try? store.setLinks("about", on: row, to: named)
        }
        store.save()
        return row
    }

    /// The last few exchanges a run may start from, oldest first. Never a held one; a lab one only under lab.
    public func recent(agent: String, policy: DoorPolicy, limit: Int = AgentEpisodes.recentLimit,
                       now: Date = .now) -> [Episode]
    {
        let cutoff = now.addingTimeInterval(-Double(Self.keepDays) * 86400)
        let readable = rows(of: agent).filter { row in
            row.createdAt >= cutoff && store.value("held", of: row) != .bool(true)
                && (policy == .lab || store.value("lab", of: row) != .bool(true))
        }
        return readable.suffix(limit).map { row in
            Episode(at: store.value("at", of: row)?.dateValue ?? row.createdAt,
                    ask: store.value("ask", of: row)?.stringValue ?? "",
                    report: store.value("report", of: row)?.stringValue ?? "")
        }
    }

    /// Removes exchanges older than 90 days, for good.
    @discardableResult
    public func expire(now: Date = .now) -> Int {
        guard let episodeClass = engine.classes[.agentEpisode] else { return 0 }
        let old = store.objects(of: episodeClass).filter {
            !$0.isDeleted && now.timeIntervalSince($0.createdAt) > Double(Self.keepDays) * 86400
        }
        for row in old {
            store.context.delete(row)
        }
        if !old.isEmpty {
            store.save()
            store.context.scrubLog()
        }
        return old.count
    }
}

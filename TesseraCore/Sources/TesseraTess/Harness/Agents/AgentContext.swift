import Foundation
import TesseraCore

/// Where every run of an agent starts (docs/ai/harness/agents.md), so it is the same one every time: its personality
/// and its memory, never a growing transcript.
/// - First block (cached for an hour): who it is, its room, the scope rule, its tools' house rules.
/// - Second block (cached for five minutes): what it keeps (its notebook's pages), the beliefs about its room, and what
///   it said lately (its last episodes).
/// Every line is read through the agent's walls: its own scope, and the policy for lab pages and episodes.
@MainActor
public enum AgentContext {
    /// The most beliefs the second block lists; recall pages in more.
    public static let maxBeliefs = 20

    public static func blocks(for spec: AgentSpec, engine: ActionEngine, policy: DoorPolicy, now: Date = .now,
                              calendar: Calendar = .current) -> [TextBlock]
    {
        [TextBlock(identity(spec)), TextBlock(memory(for: spec, engine: engine, policy: policy, now: now,
                                                     calendar: calendar))]
    }

    /// Who it is. Fixed per agent, so the prefix caches.
    static func identity(_ spec: AgentSpec) -> String {
        let role = spec.room == AgentSpec.tess.room
            ? "He talks to you. Ask a room's agent when its room knows more, then answer him yourself."
            : "You work for Tess, not for him directly: she asks, you report back in a line or two, in your own "
            + "character, and she answers him."
        return """
        \(spec.persona)
        \(role)
        Your memory: what the record and the beliefs in your room hold (search it with recall), and your own notebook \
        under \(spec.notebook)/, which only you read. Never invent his data; say you don't know. You never move or \
        record money.
        """
    }

    /// What it keeps and what it said lately.
    static func memory(for spec: AgentSpec, engine: ActionEngine, policy: DoorPolicy, now: Date,
                       calendar: Calendar) -> String
    {
        let scope = MemoryScope(spec, policy: policy)
        var parts: [String] = []

        let pages = AgentNotebook(engine: engine, scope: scope, now: now).index()
        parts.append(pages.isEmpty ? "Your notebook is empty."
            : "Your notebook:\n" + pages.map { "\($0.path): \($0.firstLine)" }.joined(separator: "\n"))

        let index = MemoryIndex(engine: engine, scope: scope, calendar: calendar)
        let beliefs = index.entries.values.filter { $0.kind == .belief }
            .sorted { ($0.candidate.importance.weight, $0.path) > ($1.candidate.importance.weight, $1.path) }
            .prefix(maxBeliefs)
        if !beliefs.isEmpty {
            parts.append("What you know about him:\n" + beliefs.map { "\($0.path): \($0.digest)" }
                .joined(separator: "\n"))
        }

        let lately = AgentEpisodes(engine: engine).recent(agent: spec.name, policy: policy, now: now)
        if !lately.isEmpty {
            let format = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Locale(identifier: "en_US"),
                                          calendar: calendar, timeZone: calendar.timeZone)
            parts.append("Lately with Tess:\n" + lately.map { episode in
                "\(episode.at.formatted(format)). Asked: \(episode.ask) You said: \(episode.report)"
            }.joined(separator: "\n"))
        }
        return parts.joined(separator: "\n\n")
    }
}

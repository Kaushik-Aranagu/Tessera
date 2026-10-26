import Foundation
import TesseraCore

/// The 4 am reflection (docs/ai/harness/night-pass.md, `reflect(agent:)`): each active room agent looks back at the
/// closing day in its room and keeps what it learned about him, as itself. It runs like any of its runs (its
/// personality, notebook, beliefs and last episodes; its own scope and tools), on its open ladder, and may keep at
/// most `cap` maybes through `remember`, each with the paths that show it. He keeps or dismisses them in the morning.
/// What it said is kept as its episode, so the next run knows what it noticed.
public struct ReflectResult: Sendable, Equatable {
    public var agent: String
    /// The ghost rows `remember` left (inferred beliefs waiting for him).
    public var kept: [UUID]
    public var report: String
    public var failed: Bool
}

extension TessRun {
    /// The most maybes one night keeps across every agent (the caller passes what is left to each).
    public static let reflectCap = 5
    /// The fewest things a room's day needs before its agent reflects on it.
    public static let reflectMinItems = 3

    /// One agent's reflection on the closing day. `items` are that day's things in its room (`NightRun.dayItems`),
    /// already by shown name. Nothing to look at means no call.
    public func reflect(_ spec: AgentSpec, items: [NightPass.DayItem], cap: Int = TessRun.reflectCap) async
        -> ReflectResult
    {
        let policy = door.policy()
        let none = ReflectResult(agent: spec.name, kept: [], report: "", failed: false)
        // Tess's AI flag off, or Claude closed by the Door: no 4 am call at all. A lab-only room (Purse, Body) never
        // reflects under strict, whatever its items say.
        guard flagOn(), door.asksClaude(), !spec.labOnly || policy == .lab, cap > 0 else { return none }
        let shown = NightPass.allowed(items, under: policy)
        // Pace: a quiet room has little to learn from, so it waits for a fuller day.
        guard shown.count >= Self.reflectMinItems else { return none }
        let question = Self.reflectQuestion(shown, cap: cap, calendar: calendar)
        // Its open ladder at the ladder's own effort; high effort waits until the memory eval shows reflection helps.
        let answer = await runAgent(spec, question: question, handles: [:], onDevice: false, plan: spec.open,
                                    remembers: cap)
        if !answer.failed {
            AgentEpisodes(engine: engine).append(agent: spec.name, ask: "Night: the closing day in your room.",
                                                 report: answer.report, lab: policy == .lab, at: now())
        }
        return ReflectResult(agent: spec.name, kept: answer.ghosts, report: answer.report, failed: answer.failed)
    }

    static func reflectQuestion(_ items: [NightPass.DayItem], cap: Int, calendar: Calendar) -> String {
        let format = Date.FormatStyle(date: .omitted, time: .shortened, locale: Locale(identifier: "en_US"),
                                      calendar: calendar, timeZone: calendar.timeZone)
        let lines = items.sorted { $0.at < $1.at }.prefix(60).map { item in
            "- \(item.kind)\(item.name.isEmpty ? "" : ": \(item.name)"), \(item.at.formatted(format))"
        }
        return """
        It's 4 am. This is what happened in your room on the day that just closed:
        \(lines.joined(separator: "\n"))

        What did you learn about him that will help next time: a usual time, a preference, a pattern, a goal? Look \
        things up with recall first, and keep at most \(cap) through remember, each with the paths that show it. Keep \
        nothing you already know, nothing about money or health, and nothing you are unsure of. Update your notebook \
        if it helps you. Then say in one line what you kept.
        """
    }
}

extension NightRun {
    /// The closing day's things for one agent's room, by shown name (Tess reads every room). The host's reflect
    /// closure passes these to `TessRun.reflect`.
    public func dayItems(for spec: AgentSpec) -> [NightPass.DayItem] {
        let start = pass.dayStart
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        let all = items(from: start, to: end)
        return spec.room == AgentSpec.tess.room ? all : all.filter { $0.room == spec.room }
    }
}

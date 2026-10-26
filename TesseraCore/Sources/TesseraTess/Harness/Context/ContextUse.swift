import Foundation

/// What one call really used (spec M3, the meter). Numbers, section names and paths only: never his words, a prompt
/// or a reply. Kept beside the run's trace spans, excluded from backups, never sent.
public struct ContextUse: Codable, Sendable, Equatable {
    public var runID: UUID
    public var agent: String
    public var model: String
    public var at: Date
    /// Estimated tokens per section, from the packer.
    public var sectionTokens: [ContextSection: Int]
    /// What the API reported.
    public var inputTokens: Int
    public var cacheReadTokens: Int
    public var cacheWriteTokens: Int
    public var outputTokens: Int
    /// Output spent on thinking: output minus the visible text's tokens.
    public var thinkingTokens: Int
    /// Paths the agent opened with a tool during the run (a page fault: the pack didn't hold it).
    public var opens: [String]
    /// How many times it called recall during the run.
    public var recalls: Int
    /// Paths its reply or report cited.
    public var cited: [String]
    /// Sections holding at least one cited or opened path.
    public var hitSections: [ContextSection]
    public var ttftMs: Int?

    public init(runID: UUID, agent: String, model: String, at: Date = .now, sectionTokens: [ContextSection: Int],
                inputTokens: Int = 0, cacheReadTokens: Int = 0, cacheWriteTokens: Int = 0, outputTokens: Int = 0,
                thinkingTokens: Int = 0, opens: [String] = [], recalls: Int = 0, cited: [String] = [],
                hitSections: [ContextSection] = [], ttftMs: Int? = nil)
    {
        self.runID = runID
        self.agent = agent
        self.model = model
        self.at = at
        self.sectionTokens = sectionTokens
        self.inputTokens = inputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.outputTokens = outputTokens
        self.thinkingTokens = thinkingTokens
        self.opens = opens
        self.recalls = recalls
        self.cited = cited
        self.hitSections = hitSections
        self.ttftMs = ttftMs
    }

    /// The meter's record for a call built from `pack`. An opened path that was already in the pack isn't a fault,
    /// so it doesn't count among `opens`; `hitSections` names the sections whose paths were cited or opened.
    public init(runID: UUID, agent: String, model: String, at: Date = .now, pack: ContextPack, usage: BrainUsage,
                visibleTextTokens: Int, opened: [String], recalls: Int, cited: [String], ttftMs: Int? = nil)
    {
        let packed = Set(pack.included.values.flatMap { $0 })
        let touched = Set(cited + opened)
        let hits = ContextSection.allCases.filter { section in
            (pack.included[section] ?? []).contains { touched.contains($0) }
        }
        self.init(runID: runID, agent: agent, model: model, at: at, sectionTokens: pack.sectionTokens,
                  inputTokens: usage.inTokens, cacheReadTokens: usage.cacheReadTokens,
                  cacheWriteTokens: usage.cacheWriteTokens, outputTokens: usage.outTokens,
                  thinkingTokens: max(0, usage.outTokens - visibleTextTokens),
                  opens: opened.filter { !packed.contains($0) }, recalls: recalls, cited: cited,
                  hitSections: hits, ttftMs: ttftMs)
    }
}

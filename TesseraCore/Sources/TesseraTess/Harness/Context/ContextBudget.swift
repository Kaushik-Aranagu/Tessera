import Foundation

// The context budget (memory spec M3). Every call is rebuilt from memory, section by section, never from a growing
// transcript. A section's size is a starting point it always keeps, never a cost ceiling: Kaushik, Oct 23, "I want us
// to be functionally accurate... Forget about cost." The only hard limit is the model's window.

/// The parts of a pack that carry text, in the order they are sent. Stable parts come first so the prefix caches:
/// rules, expertise and core change rarely, recall changes per ask, episodic and working change every call. Tool
/// definitions are not a section: the API sends them before the system text, and the packer only counts them.
public enum ContextSection: String, Codable, Sendable, CaseIterable, CodingKeyRepresentable {
    case rules, expertise, core, recall, episodic, working

    /// Where a section goes in the request: the first four are system blocks, the last two are the user message.
    public var isSystem: Bool {
        switch self {
        case .rules, .expertise, .core, .recall: true
        case .episodic, .working: false
        }
    }
}

/// How long Anthropic keeps a cached prefix warm. The 1-hour marks must come before the 5-minute marks in a request.
public enum CacheTTL: String, Codable, Sendable {
    case fiveMinutes = "5m"
    case oneHour = "1h"
}

/// A cache breakpoint after the block at `index` (counted over the pack's blocks, in order).
public struct CacheMark: Sendable, Equatable {
    public var index: Int
    public var ttl: CacheTTL

    public init(index: Int, ttl: CacheTTL) {
        self.index = index
        self.ttl = ttl
    }
}

/// One agent's sizes on one model. `starts` is what each section always keeps when it has content: overflow never
/// trims a section below its start until every section above its start is trimmed. Expertise is never trimmed.
public struct BudgetRow: Codable, Sendable, Equatable {
    public var starts: [ContextSection: Int]
    /// Recall keeps every candidate whose score is at or above this.
    public var recallFloor: Double
    /// `max_tokens`, thinking included. Nothing else may borrow it.
    public var outputTokens: Int

    public init(starts: [ContextSection: Int], recallFloor: Double, outputTokens: Int) {
        self.starts = starts
        self.recallFloor = recallFloor
        self.outputTokens = outputTokens
    }

    public func start(_ section: ContextSection) -> Int {
        starts[section] ?? 0
    }

    /// The shipped starts (spec M3). The same for Haiku and Sonnet; only the answer room differs. The floor is 0.4 on
    /// the recall mean (0...1): a thing two links from the ask, with nothing else going for it, just makes it.
    public static func defaults(for model: BrainID) -> BudgetRow {
        BudgetRow(
            starts: [.rules: 2000, .expertise: 0, .core: 6000, .recall: 36000, .episodic: 12000, .working: 8000],
            recallFloor: 0.4,
            outputTokens: model == .sonnet ? 32000 : 16000
        )
    }
}

/// Every agent's rows, kept in `Application Support/Tessera/context-budgets.json` (excluded from backups). A missing
/// row reads as the defaults, so the file only ever holds what the tuner changed.
public struct BudgetTable: Codable, Sendable, Equatable {
    public static let fileName = "context-budgets.json"

    public var rows: [String: BudgetRow]

    public init(rows: [String: BudgetRow] = [:]) {
        self.rows = rows
    }

    public static func key(agent: String, model: BrainID) -> String {
        "\(agent)/\(model.rawValue)"
    }

    public func row(agent: String, model: BrainID) -> BudgetRow {
        rows[Self.key(agent: agent, model: model)] ?? .defaults(for: model)
    }

    public mutating func set(_ row: BudgetRow, agent: String, model: BrainID) {
        rows[Self.key(agent: agent, model: model)] = row
    }

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    /// The stored table, or an empty one (all defaults) when there is no file or it can't be read.
    public static func load(from url: URL? = defaultURL) -> BudgetTable {
        guard let url, let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode(BudgetTable.self, from: data) else { return BudgetTable() }
        return table
    }

    public func save(to url: URL? = BudgetTable.defaultURL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let url, let data = try? encoder.encode(self) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #if os(iOS)
            try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
            try? data.write(to: url, options: [.atomic])
        #endif
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }
}

/// Characters per token for each section, corrected once a week against `count_tokens` (spec M3, calibration).
/// Text estimates run high on purpose: 3.6 characters a token undercounts nothing in English prose.
public struct TokenRatio: Codable, Sendable, Equatable {
    public static let initial = 3.6

    public var charsPerToken: [ContextSection: Double]

    public init(charsPerToken: [ContextSection: Double] = [:]) {
        self.charsPerToken = charsPerToken
    }

    public func ratio(_ section: ContextSection) -> Double {
        charsPerToken[section] ?? Self.initial
    }

    public func tokens(_ text: String, in section: ContextSection) -> Int {
        guard !text.isEmpty else { return 0 }
        return Int((Double(text.count) / ratio(section)).rounded(.up))
    }

    /// Takes a measured pair (the section's characters and the tokens `count_tokens` reported for it). A measurement
    /// that can't be right (no characters, no tokens) is ignored.
    public mutating func calibrate(_ section: ContextSection, characters: Int, tokens: Int) {
        guard characters > 0, tokens > 0 else { return }
        charsPerToken[section] = Double(characters) / Double(tokens)
    }
}

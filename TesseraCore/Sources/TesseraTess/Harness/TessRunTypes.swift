import Foundation

// H3 types: what a Tess run says to the layer, which rung an ask takes, and the checkpoints a run leaves.

public enum TessRunEvent: Sendable, Equatable {
    /// At once, so the layer can show her hearing or thinking state.
    case waiting
    /// A text delta, as it arrives.
    case words(String)
    /// A pending row a tool made (an op id).
    case ghost(UUID)
    /// Her whole reply.
    case finished(String)
    /// A line made on the phone, never a raw error.
    case failed(String)

    var isTerminal: Bool {
        switch self {
        case .finished, .failed: true
        default: false
        }
    }
}

/// The rung an ask takes: one function, so a typed net can replace it later. No Opus.
public struct RungPlan: Equatable, Sendable {
    public var ladder: [BrainID]
    public var effort: Effort
    public var maxTokens: Int
    public var hedge: Bool
    public var toolChoice: ToolChoice

    /// With the flag Off or Tess asks Claude Off: the phone's own model, no tools.
    public static let deviceOnly = RungPlan(ladder: [.appleOnDevice], effort: .low, maxTokens: 300, hedge: false,
                                            toolChoice: .none)

    public static let open = RungPlan(ladder: [.sonnet, .haiku, .appleOnDevice], effort: .low, maxTokens: 400,
                                      hedge: true, toolChoice: .auto)
    public static let plain = RungPlan(ladder: [.haiku, .appleOnDevice], effort: .low, maxTokens: 300, hedge: false,
                                       toolChoice: .auto)

    /// An open question (why, should, plan, how am I, compare, what do you think, or over 18 words) goes to Sonnet
    /// with Haiku hedged in; everything else (lookups, counts, small actions) goes to Haiku.
    public static func pick(_ text: String) -> RungPlan {
        let lowered = text.lowercased()
        let openWords = [#"\bwhy\b"#, #"\bshould\b"#, #"\bplan\b"#, #"\bhow am i\b"#, #"\bcompare\b"#,
                         #"\bwhat do you think\b"#]
        let words = lowered.split { $0.isWhitespace }.count
        if words > 18 || openWords.contains(where: { lowered.range(of: $0, options: .regularExpression) != nil }) {
            return .open
        }
        return .plain
    }
}

public func pickRung(_ text: String) -> RungPlan {
    RungPlan.pick(text)
}

// MARK: Brain messages as JSON

extension BrainRole: Codable {}

extension BrainContent: Codable {
    private enum Kind: String, Codable {
        case text, toolUse, toolResult
    }

    private enum Key: String, CodingKey {
        case kind, text, id, name, input, content, isError
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .text:
            self = try .text(container.decode(String.self, forKey: .text))
        case .toolUse:
            self = try .toolUse(id: container.decode(String.self, forKey: .id),
                                name: container.decode(String.self, forKey: .name),
                                input: container.decode(Data.self, forKey: .input))
        case .toolResult:
            self = try .toolResult(id: container.decode(String.self, forKey: .id),
                                   content: container.decode(String.self, forKey: .content),
                                   isError: container.decode(Bool.self, forKey: .isError))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case let .text(text):
            try container.encode(Kind.text, forKey: .kind)
            try container.encode(text, forKey: .text)
        case let .toolUse(id, name, input):
            try container.encode(Kind.toolUse, forKey: .kind)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        case let .toolResult(id, content, isError):
            try container.encode(Kind.toolResult, forKey: .kind)
            try container.encode(id, forKey: .id)
            try container.encode(content, forKey: .content)
            try container.encode(isError, forKey: .isError)
        }
    }
}

extension BrainMessage: Codable {
    private enum Key: String, CodingKey {
        case role, content
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        try self.init(container.decode(BrainRole.self, forKey: .role),
                      container.decode([BrainContent].self, forKey: .content))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

// MARK: Checkpoints

/// One run's checkpoint: what was sent as messages (never the live fragments), the tools that finished, and where it
/// stopped. `tess-runs.json` keeps the last 20, nothing older than a day, out of backups.
public struct TessRunState: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable {
        case running, finished, failed, dropped
    }

    public var id: UUID
    public var startedAt: Date
    public var round: Int
    public var messages: [BrainMessage]
    public var doneToolIDs: [String]
    public var status: Status
    /// The ask's words, to pick the same rung on a resume.
    public var askText: String
    /// What she named (object ids), for the turn a resumed run stores.
    public var aboutIDs: [UUID]
    /// Results of the tools that finished, by tool id.
    public var toolResults: [String: String]
    /// Words streamed so far, over all rounds.
    public var words: String

    public init(id: UUID = UUID(), startedAt: Date, askText: String, aboutIDs: [UUID], messages: [BrainMessage]) {
        self.id = id
        self.startedAt = startedAt
        round = 1
        self.messages = messages
        doneToolIDs = []
        status = .running
        self.askText = askText
        self.aboutIDs = aboutIDs
        toolResults = [:]
        words = ""
    }
}

public struct TessRunStore: Sendable {
    public static let fileName = "tess-runs.json"
    public static let keepRuns = 20
    public static let maxAge: TimeInterval = 86400

    public let url: URL?

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    public init(url: URL? = TessRunStore.defaultURL) {
        self.url = url
    }

    public func all(now: Date = .now) -> [TessRunState] {
        guard let url, let data = try? Data(contentsOf: url),
              let runs = try? JSONDecoder().decode([TessRunState].self, from: data) else { return [] }
        return runs.filter { now.timeIntervalSince($0.startedAt) <= Self.maxAge }
    }

    public func save(_ state: TessRunState, now: Date = .now) {
        guard let url else { return }
        var runs = all(now: now).filter { $0.id != state.id }
        runs.append(state)
        if runs.count > Self.keepRuns {
            runs.removeFirst(runs.count - Self.keepRuns)
        }
        guard let data = try? JSONEncoder().encode(runs) else { return }
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

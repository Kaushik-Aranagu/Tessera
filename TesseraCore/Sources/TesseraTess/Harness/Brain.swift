import Foundation

// The Brain seam (harness H1a). A Brain is anything that can answer a request as a stream of events: the Claude API,
// the on-device Apple model, later a Mac or a small typed net. Callers say what they need; the router (H1b) picks the
// rung. Nothing in a request or an event ever holds the Claude key.

public enum BrainID: String, Sendable, CaseIterable {
    case rules, typedNet, appleOnDevice, mlx, mac, haiku, sonnet
    /// An escalation rung only: a ladder never starts with it (the Door refuses a ladder that does).
    case opus
}

/// How a Claude call ended, in the words the rest of the app already uses (`ClaudeKeyCheck.Outcome`).
public enum ClaudeOutcome: String, Sendable {
    case works, badKey, notAllowed, offline, timeout, capReached, busy, accountPaused, refused, cancelled, other

    init(_ outcome: ClaudeKeyCheck.Outcome) {
        switch outcome {
        case .works: self = .works
        case .badKey, .notAKey, .notSaved: self = .badKey
        case .notAllowed: self = .notAllowed
        case .offline: self = .offline
        case .timeout: self = .timeout
        case .capReached: self = .capReached
        case .busy: self = .busy
        case .accountPaused: self = .accountPaused
        case .other: self = .other
        }
    }
}

public struct TextBlock: Sendable, Equatable {
    public var text: String

    public init(_ text: String) {
        self.text = text
    }
}

public enum BrainRole: String, Sendable {
    case user, assistant
}

public enum BrainContent: Sendable, Equatable {
    /// One content block as the API sent it (text, tool_use, thinking with its signature, redacted thinking, server
    /// tool use and results). An assistant message is replayed from these, never rebuilt from text deltas, so thinking
    /// stays valid, encrypted search results stay valid and the cache stays warm. Byte for byte holds for a block that
    /// arrives whole (a search or fetch result with its encrypted content). A block that streams in pieces (text,
    /// thinking, tool_use) is rebuilt from them with sorted keys and its citations kept: it is the same content, but a
    /// tool_use input is re-encoded, so its bytes are not the API's.
    case raw(Data)
    case text(String)
    case toolUse(id: String, name: String, input: Data)
    case toolResult(id: String, content: String, isError: Bool)
}

public struct BrainMessage: Sendable, Equatable {
    public var role: BrainRole
    public var content: [BrainContent]

    public init(_ role: BrainRole, _ content: [BrainContent]) {
        self.role = role
        self.content = content
    }

    public init(_ role: BrainRole, text: String) {
        self.init(role, [.text(text)])
    }
}

public struct ToolSpec: Sendable, Equatable {
    public var name: String
    public var description: String
    /// A JSON Schema object, as JSON.
    public var schema: Data
    /// Arguments are guaranteed to match the schema.
    public var strict: Bool

    public init(name: String, description: String, schema: Data, strict: Bool = true) {
        self.name = name
        self.description = description
        self.schema = schema
        self.strict = strict
    }
}

public enum ToolChoice: Sendable, Equatable {
    case auto, any, tool(String), none
}

public enum Effort: String, Sendable {
    case low, medium, high
}

public enum CacheTTL: String, Sendable, Equatable {
    case fiveMinutes = "5m"
    case oneHour = "1h"
}

/// A cache breakpoint after a block (counted over the system blocks, then the text blocks of the messages), with its
/// lifetime. The 1-hour marks must come before the 5-minute ones, and there are at most four marks.
public struct CacheMark: Sendable, Equatable, ExpressibleByIntegerLiteral {
    public var index: Int
    public var ttl: CacheTTL

    public init(_ index: Int, _ ttl: CacheTTL = .fiveMinutes) {
        self.index = index
        self.ttl = ttl
    }

    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

public enum BrainRequestError: Error, Equatable {
    case cacheOrder
    case tooManyBreakpoints
}

public struct BrainRequest: Sendable {
    public var system: [TextBlock]
    public var messages: [BrainMessage]
    public var tools: [ToolSpec]
    public var toolChoice: ToolChoice
    public var maxTokens: Int
    public var effort: Effort?
    /// Indexes that get a cache breakpoint, counted over the system blocks and then the text blocks of the messages,
    /// in order.
    public var cacheAfter: [CacheMark]
    /// Adaptive thinking, on by default for accuracy. A call that forces a tool sends it off (a forced tool and
    /// thinking don't mix); Sonnet and Opus never get a forced tool, so they think.
    public var thinking: Bool
    public var deadline: Duration

    public init(system: [TextBlock] = [], messages: [BrainMessage], tools: [ToolSpec] = [],
                toolChoice: ToolChoice = .auto, maxTokens: Int = 1024, effort: Effort? = nil,
                cacheAfter: [CacheMark] = [], thinking: Bool = true, deadline: Duration = .seconds(30))
    {
        self.system = system
        self.messages = messages
        self.tools = tools
        self.toolChoice = toolChoice
        self.maxTokens = maxTokens
        self.effort = effort
        self.cacheAfter = cacheAfter
        self.thinking = thinking
        self.deadline = deadline
    }
}

public struct BrainUsage: Sendable, Equatable {
    public var inTokens: Int
    public var outTokens: Int
    public var cacheReadTokens: Int
    public var cacheWriteTokens: Int
    public var costNano: Int64
    /// The part of `cacheWriteTokens` written with the 1-hour lifetime (2x the input price).
    public var cacheWrite1hTokens: Int = 0
    /// Web searches the server ran for this call ($0.01 each, in `costNano`).
    public var webSearches: Int

    public init(inTokens: Int = 0, outTokens: Int = 0, cacheReadTokens: Int = 0, cacheWriteTokens: Int = 0,
                costNano: Int64 = 0, webSearches: Int = 0)
    {
        self.webSearches = webSearches
        self.inTokens = inTokens
        self.outTokens = outTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.costNano = costNano
    }
}

public enum BrainEvent: Sendable {
    /// The HTTP status of a Claude reply, as soon as the headers arrive. Other brains never send it.
    case status(Int)
    case text(String)
    /// The whole assistant message as the API sent it: every content block, verbatim, in order. It comes before
    /// `.done`; the loop appends it unchanged before the next round.
    case assistant([Data])
    /// A tool call whose content block has closed: the input is valid JSON. Start the tool now.
    case toolUse(id: String, name: String, input: Data)
    case done(BrainUsage, stop: String)
    case failed(ClaudeOutcome)
}

/// What a warm-up did: the status it got and the `max_tokens` that worked (0, or 1 when the API refused 0).
public struct BrainWarm: Sendable, Equatable {
    public var status: Int
    public var maxTokens: Int
    public var usage: BrainUsage
}

public protocol Brain: Sendable {
    var id: BrainID { get }
    var isAvailable: Bool { get async }
    func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error>
    /// Loads whatever makes the next call fast (a cached prefix, a loaded model). Never throws, never bills more
    /// than a few tokens; what it cost comes back so the caller can put it through the ledger. Nil when nothing was
    /// sent.
    func warm(_ prefix: BrainRequest) async -> BrainWarm?
}

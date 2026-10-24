import Foundation

/// What may go to Claude (harness H1b).
public enum Taint: Sendable, Equatable {
    /// Fine for Claude under either policy.
    case claudeSafe
    /// Health, body, calendar, calories, money or a private thing: on the phone (or the Mac) only under `strict`.
    case deviceOnly
}

/// A piece of the context pack and what it may do.
public struct PackFragment: Sendable, Equatable {
    public var text: String
    public var taint: Taint

    public init(_ text: String, taint: Taint = .claudeSafe) {
        self.text = text
        self.taint = taint
    }
}

/// Lab mode (Kaushik's call, Oct 23) is on his own phone: Claude may see health, body, calendar, calories and money,
/// never the key. Strict is today's walls. The flag `tessLabPolicy` picks it and ships On.
public enum DoorPolicy: Sendable, Equatable {
    case lab, strict

    /// The fragments a rung may carry: lab sends everything to Claude, strict keeps `deviceOnly` off Claude rungs.
    public func allows(_ fragment: PackFragment, onClaude: Bool) -> Bool {
        guard onClaude else { return true }
        return self == .lab || fragment.taint == .claudeSafe
    }

    /// The policy for the flag's state (On = lab).
    public init(labFlagIsOn: Bool) {
        self = labFlagIsOn ? .lab : .strict
    }
}

/// One job through the Door.
public struct DoorJob: Sendable {
    public var name: String
    /// Rungs in order. The first available one that is allowed answers; a failure before any word falls to the next.
    public var ladder: [BrainID]
    public var request: BrainRequest
    public var fragments: [PackFragment]
    public var estimateNano: Int64
    /// Sonnet first, and no first token after the router's wait: Haiku is started too and the first streamer wins.
    public var hedge: Bool
    /// Judges a tool call's input; a call it refuses is a failure of that rung.
    public var validator: @Sendable (Data) -> Bool

    public init(name: String, ladder: [BrainID], request: BrainRequest, fragments: [PackFragment] = [],
                estimateNano: Int64 = 0, hedge: Bool = false,
                validator: @escaping @Sendable (Data) -> Bool = { _ in true })
    {
        self.name = name
        self.ladder = ladder
        self.request = request
        self.fragments = fragments
        self.estimateNano = estimateNano
        self.hedge = hedge
        self.validator = validator
    }
}

/// Which brains exist and which of them can answer now. Claude rungs are skipped when "Tess asks Claude" is off.
public struct BrainRouter: Sendable {
    public typealias Provider = @Sendable (BrainID) -> (any Brain)?

    public var provider: Provider
    /// How long Sonnet gets to produce a first token before Haiku is started too.
    public var hedgeAfter: Duration
    /// The wait before a hedge. A test passes its own, so no real clock decides which rung streams first.
    public var sleep: @Sendable (Duration) async -> Void

    public init(hedgeAfter: Duration = .milliseconds(1500),
                sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) },
                provider: @escaping Provider)
    {
        self.hedgeAfter = hedgeAfter
        self.sleep = sleep
        self.provider = provider
    }

    public static func isClaude(_ id: BrainID) -> Bool {
        id == .haiku || id == .sonnet || id == .opus
    }

    /// The rungs of a ladder that exist, are available, and are allowed, in order.
    public func candidates(for ladder: [BrainID], asksClaude: Bool) async -> [any Brain] {
        var found: [any Brain] = []
        for id in ladder {
            guard let brain = provider(id) else { continue }
            if Self.isClaude(id), !asksClaude {
                continue
            }
            if await brain.isAvailable {
                found.append(brain)
            }
        }
        return found
    }
}

import Foundation
import TesseraCore

// Taint and provenance that follow the text (input-hygiene H4, docs/ai/harness/input-hygiene.md rules 4 to 8): what a
// model makes carries the highest taint of what it read and every source it came from, and nothing made after
// reading a page may teach Tess about him.

public extension Taint {
    /// The highest of several: one device-only input makes the whole thing device-only.
    static func highest(_ taints: some Sequence<Taint>) -> Taint {
        taints.contains(.deviceOnly) ? .deviceOnly : .claudeSafe
    }
}

/// Text a model made for a job, with what it was made from. A gist of a page is still the page's.
public struct Derived: Sendable, Equatable {
    public var text: String
    public var taint: Taint
    public var sources: Set<Provenance>

    public init(_ text: String, job: String, from inputs: [PackFragment]) {
        self.text = text
        taint = .highest(inputs.map(\.taint))
        sources = Set(inputs.map(\.source)).union([.model(job: job)])
    }

    /// Its least-trusted source.
    public var trust: Provenance.Trust {
        sources.map(\.trust).min() ?? .exact
    }

    /// Whether it may teach: become a belief, a notebook line, an episode or a router signal. Never from a page.
    public var mayTeach: Bool {
        trust > .untrusted
    }
}

/// What one Tess run has read so far. A run starts from his words and its pack; a server tool's result, a page
/// fragment or an untrusted tool result lowers it, and from then on the run may still write (as ghost rows he keeps
/// or not) but may not teach.
public struct RunProvenance: Sendable, Equatable {
    public private(set) var sources: Set<Provenance> = [.author]
    public private(set) var taint: Taint = .claudeSafe

    public init(fragments: [PackFragment] = []) {
        read(fragments)
    }

    public mutating func read(_ fragments: [PackFragment]) {
        sources.formUnion(fragments.map(\.source))
        taint = .highest([taint] + fragments.map(\.taint))
    }

    /// What another run read: a room asked after a page has read that page too.
    public mutating func read(_ run: RunProvenance) {
        sources.formUnion(run.sources)
        taint = .highest([taint, run.taint])
    }

    public mutating func read(_ untrusted: Untrusted) {
        sources.insert(untrusted.source)
    }

    /// An assistant message's blocks, as the API sent them: a web search or fetch result is a page read.
    public mutating func read(blocks: [Data]) {
        sources.formUnion(blocks.compactMap(Provenance.ofServerBlock))
    }

    /// A tool's result. `engineOnly` when it holds only engine values (counts, a set, a handle's fields).
    public mutating func read(tool name: String, engineOnly: Bool) {
        sources.insert(engineOnly ? .app : .tool(name: name))
    }

    /// Whether the run has read third-party text.
    public var hasUntrusted: Bool {
        sources.contains { $0.trust == .untrusted }
    }

    /// Whether a call may run now. Every call may, except the ones that teach once a page is in the run: `remember`
    /// and any notebook command but `view`.
    @MainActor
    public func allows(_ tool: String, input: Data) -> Bool {
        guard hasUntrusted else { return true }
        if tool == TessRecallTools.remember {
            return false
        }
        if tool == AgentNotebook.name {
            let command = ((try? JSONSerialization.jsonObject(with: input)) as? [String: Any])?["command"] as? String
            return command == "view"
        }
        return true
    }

    /// What the model reads when a teaching call is refused.
    public static let refusal = "Not kept: this came after reading a page, and a page can't teach me about him."

    /// What the run's words are, for whatever keeps them.
    public func derive(_ text: String, job: String) -> Derived {
        var derived = Derived(text, job: job, from: [])
        derived.sources.formUnion(sources)
        derived.taint = taint
        return derived
    }
}

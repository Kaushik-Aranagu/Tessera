import Foundation
import TesseraCore

/// One Tess run as memory (input-hygiene H6, docs/ai/harness/input-hygiene.md): what she did, never what she thought.
/// It is built from the run's trace spans, so it holds only what they hold: job and tool names, outcomes, times and
/// tokens. Her reasoning, her reply, his words and anything a page said never enter it, and neither does what the run
/// cost (a tuner never reads cost). That is what makes it safe to keep as a leaf and to learn from.
public struct RunDigest: Sendable, Equatable, Codable {
    public struct Step: Sendable, Equatable, Codable {
        public var tool: String
        public var ok: Bool
        public var ms: Int
    }

    /// What the run read, as the run knew it. Unknown is the strictest reading: device-only and untrusted.
    public struct Reading: Sendable, Equatable, Codable {
        /// It read health, body, money, calendar or a private thing: its leaf stays on the phone under strict.
        public var deviceOnly: Bool
        /// It read a page or an untrusted tool result: kept, never learned from.
        public var untrusted: Bool

        public init(deviceOnly: Bool, untrusted: Bool) {
            self.deviceOnly = deviceOnly
            self.untrusted = untrusted
        }

        public static let unknown = Reading(deviceOnly: true, untrusted: true)
    }

    public var runID: UUID
    /// When its first span closed.
    public var at: Date
    /// The brain job ("tess-turn"), or "none" when no brain was asked.
    public var job: String
    /// The brains tried, in order.
    public var brains: [String]
    public var steps: [Step]
    /// A brain finished its answer.
    public var answered: Bool
    /// The last brain outcome when none answered ("timeout", "refused", "keyShape"); nil when one did.
    public var failure: String?
    /// From the first span's start to the last span's end.
    public var totalMs: Int
    public var inTokens: Int
    public var outTokens: Int
    public var reading: Reading

    /// The name a tool step is kept under when it isn't a tool Tess has: a span carries the name the model chose, so a
    /// steered or made-up name never becomes a path, a leaf or a hint (QA on #1474).
    public static let unknownTool = "unknown"

    /// Every tool a run can call: the Tess tools, the harness's (open, recall, remember, notebook, ask_agent, web) and
    /// the shell calls.
    @MainActor
    public static var knownTools: Set<String> {
        AgentSpec.knownTools.union(TessRecallTools.names).union(ElementCatalog.shellCalls)
            .union(TessRun.shellSpecs().map(\.name))
            .union([TessOpenTool.name, AgentNotebook.name, TessRun.askAgent])
    }

    /// The digest of one run, or nil when the trace holds none of its spans.
    @MainActor
    public static func make(runID: UUID, spans: [TraceSpan], reading: Reading = .unknown) -> RunDigest? {
        make(runID: runID, spans: spans, reading: reading, known: knownTools)
    }

    static func make(runID: UUID, spans: [TraceSpan], reading: Reading, known: Set<String>) -> RunDigest? {
        let own = spans.filter { $0.runID == runID }.sorted { $0.at < $1.at }
        guard let first = own.first, let last = own.last else { return nil }
        let brains = own.filter { $0.kind == .brain }
        // A brain span's outcome may carry its HTTP status after a space ("works 200").
        func outcome(_ span: TraceSpan) -> String {
            span.outcome.split(separator: " ").first.map(String.init) ?? ""
        }
        let answered = brains.contains { outcome($0) == ClaudeOutcome.works.rawValue }
        let started = own.map { $0.at.addingTimeInterval(-Double($0.totalMs) / 1000) }.min() ?? first.at
        return RunDigest(
            runID: runID, at: first.at, job: brains.first?.name ?? "none", brains: brains.compactMap(\.brain),
            steps: own.filter { $0.kind == .tool }.map { span in
                Step(tool: known.contains(span.name) ? span.name : unknownTool, ok: span.outcome != "error",
                     ms: span.totalMs)
            },
            answered: answered, failure: answered ? nil : brains.last.map(outcome) ?? "none",
            totalMs: max(0, Int((last.at.timeIntervalSince(started) * 1000).rounded())),
            inTokens: own.reduce(0) { $0 + $1.inTokens }, outTokens: own.reduce(0) { $0 + $1.outTokens },
            reading: reading
        )
    }

    /// Every run the trace holds, oldest first. A run whose reading is not given is read as `.unknown`.
    @MainActor
    public static func all(from spans: [TraceSpan], readings: [UUID: Reading] = [:]) -> [RunDigest] {
        let ids = Set(spans.compactMap(\.runID)), known = knownTools
        return ids.compactMap { make(runID: $0, spans: spans, reading: readings[$0] ?? .unknown, known: known) }
            .sorted { ($0.at, $0.runID.uuidString) < ($1.at, $1.runID.uuidString) }
    }

    /// The tools in call order, a tool called again straight after itself counted once.
    public var path: [String] {
        steps.map(\.tool).reduce(into: []) { path, tool in
            if path.last != tool {
                path.append(tool)
            }
        }
    }

    /// As a pyramid leaf: names and counts only, so a day's node totals how Tess did that day.
    public var leaf: PyramidLeaf {
        let failed = steps.count(where: { !$0.ok })
        var text = answered ? "Tess answered" : "Tess couldn't answer (\(failure ?? "none"))"
        if !path.isEmpty {
            text += " using \(path.joined(separator: ", "))"
        }
        if failed > 0 {
            text += ", \(failed) failed \(failed == 1 ? "call" : "calls")"
        }
        return PyramidLeaf(id: "run-\(runID.uuidString)", at: at, kind: "run", text: text,
                           taint: reading.deviceOnly ? .deviceOnly : .claudeSafe,
                           stats: ["runs": 1, "toolCalls": Double(steps.count), "failedCalls": Double(failed),
                                   "unanswered": answered ? 0 : 1])
    }
}

public extension MemoryPyramid {
    /// Tess's own runs as leaves, before `now`.
    static func leaves(runs: [RunDigest], now: Date) -> [PyramidLeaf] {
        runs.filter { $0.at < now }.map(\.leaf)
    }
}

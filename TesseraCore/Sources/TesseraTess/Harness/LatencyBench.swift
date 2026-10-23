import Foundation
import TesseraCore

/// H0: the latency bench (Developer mode, "Run latency bench"). Five repeats of each case, p50 and p95 of the time to
/// first token and of the total, written as a plain table into the trace file. Every prompt is fixed filler text: no
/// words of his leave the phone. Claude spend goes through `TessUsageLedger` (reserved before, a row after), and a
/// run that does not fit under the cap is skipped, not sent.
@MainActor
public struct LatencyBench {
    public static let repeats = 5
    public static let promptWords = 220 // about 300 tokens
    public static let prefixWords = 2200 // about 3,000 tokens
    public static let outTokens = 50

    public struct Row: Sendable, Equatable {
        public var label: String
        public var runs: Int
        public var ttftP50: Int?
        public var ttftP95: Int?
        public var totalP50: Int?
        public var totalP95: Int?
        public var note: String?
    }

    /// Makes the brain for a case: `fresh` means a new URLSession (a cold connection).
    public typealias BrainFactory = @MainActor @Sendable (_ model: ClaudeBrain.Model, _ fresh: Bool) -> any Brain

    public let ledger: TessUsageLedger
    public let trace: RunTrace
    public let claude: BrainFactory
    public let apple: (any Brain)?
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current

    public init(ledger: TessUsageLedger, trace: RunTrace, claude: @escaping BrainFactory, apple: (any Brain)?) {
        self.ledger = ledger
        self.trace = trace
        self.claude = claude
        self.apple = apple
    }

    // MARK: Run

    public func run() async -> [Row] {
        var rows: [Row] = []
        for (model, name, effort) in [(ClaudeBrain.Model.haiku, "Haiku 5.5", Effort.low),
                                      (.sonnet, "Sonnet 5.5, effort low", .low)]
        {
            await rows.append(claudeCase("\(name), cold", model: model, effort: effort, prefix: false, warm: false,
                                         fresh: true))
            await rows.append(claudeCase("\(name), warm", model: model, effort: effort, prefix: false, warm: false,
                                         fresh: false))
            await rows.append(claudeCase("\(name), cached prefix, cold", model: model, effort: effort, prefix: true,
                                         warm: true, fresh: true))
            await rows.append(claudeCase("\(name), cached prefix, warm", model: model, effort: effort, prefix: true,
                                         warm: true, fresh: false))
        }
        await rows.append(appleCase())
        rows.append(Row(label: "Mac on Wi-Fi", runs: 0, note: "not set up"))
        let table = Self.table(rows)
        await trace.setBenchTable(table)
        return rows
    }

    private func request(effort: Effort, prefix: Bool) -> BrainRequest {
        var system = [TextBlock("You are a latency probe. Answer in about forty words.")]
        var cache: [Int] = []
        if prefix {
            system.append(TextBlock(Self.filler(words: Self.prefixWords, seed: 7)))
            cache = [1]
        }
        return BrainRequest(system: system,
                            messages: [BrainMessage(.user, text: Self.filler(words: Self.promptWords, seed: 3))],
                            maxTokens: Self.outTokens, effort: effort, cacheAfter: cache, deadline: .seconds(30))
    }

    private func claudeCase(_ label: String, model: ClaudeBrain.Model, effort: Effort, prefix: Bool, warm: Bool,
                            fresh: Bool) async -> Row
    {
        var ttft: [Int] = [], total: [Int] = []
        let shared = fresh ? nil : claude(model, false)
        if !fresh, let shared {
            // A warm connection: one throwaway call so the connection is open before the timed ones.
            await shared.warm(request(effort: effort, prefix: prefix))
        }
        for _ in 0 ..< Self.repeats {
            let brain = shared ?? claude(model, true)
            if warm, fresh {
                await brain.warm(request(effort: effort, prefix: prefix))
            }
            let req = request(effort: effort, prefix: prefix)
            let estimate = TessUsageLedger.estimate(
                text: (req.system.map(\.text) + [Self.filler(words: Self.promptWords,
                                                             seed: 3)])
                    .joined(),
                maxTokens: req.maxTokens,
                model: model.rawValue
            )
            guard let reservation = ledger.reserve(estimate, now: now(), calendar: calendar) else {
                return Row(label: label, runs: ttft.count, note: "stopped at the cap")
            }
            let measured = await time(brain, req)
            ledger.settle(reservation)
            ledger.record(use: .bench, model: model.rawValue, input: measured.usage.inTokens,
                          output: measured.usage.outTokens, costNano: measured.usage.costNano,
                          latency: Double(measured.totalMs) / 1000, outcome: measured.outcome.rawValue,
                          requestID: nil, at: now())
            await trace.record(TraceSpan(kind: .brain, name: "latency-bench", brain: brain.id.rawValue,
                                         model: model.rawValue, at: now(), ttftMs: measured.ttftMs,
                                         totalMs: measured.totalMs, usage: measured.usage,
                                         outcome: measured.outcome.rawValue))
            if measured.outcome == .works, let first = measured.ttftMs {
                ttft.append(first)
                total.append(measured.totalMs)
            } else if measured.outcome == .badKey || measured.outcome == .capReached || measured.outcome == .offline {
                return Row(label: label, runs: ttft.count, note: measured.outcome.rawValue)
            }
        }
        return Self.row(label, ttft: ttft, total: total)
    }

    private func appleCase() async -> Row {
        guard let apple, await apple.isAvailable else {
            return Row(label: "Apple on-device model", runs: 0, note: "not available on this phone")
        }
        var ttft: [Int] = [], total: [Int] = []
        for _ in 0 ..< Self.repeats {
            let req = BrainRequest(system: [TextBlock("Answer in about forty words.")],
                                   messages: [BrainMessage(.user, text: Self.filler(words: Self.promptWords, seed: 3))],
                                   maxTokens: Self.outTokens, deadline: .seconds(30))
            let measured = await time(apple, req)
            await trace.record(TraceSpan(kind: .brain, name: "latency-bench", brain: apple.id.rawValue, at: now(),
                                         ttftMs: measured.ttftMs, totalMs: measured.totalMs,
                                         outcome: measured.outcome.rawValue))
            if measured.outcome == .works, let first = measured.ttftMs {
                ttft.append(first)
                total.append(measured.totalMs)
            }
        }
        return Self.row("Apple on-device model", ttft: ttft, total: total)
    }

    private struct Measured {
        var ttftMs: Int?
        var totalMs: Int
        var usage = BrainUsage()
        var outcome: ClaudeOutcome
    }

    private func time(_ brain: any Brain, _ request: BrainRequest) async -> Measured {
        let clock = ContinuousClock()
        let start = clock.now
        var measured = Measured(ttftMs: nil, totalMs: 0, outcome: .works)
        do {
            for try await event in brain.stream(request) {
                switch event {
                case .text, .toolUse:
                    if measured.ttftMs == nil {
                        measured.ttftMs = Self.ms(clock.now - start)
                    }
                case let .done(usage, _):
                    measured.usage = usage
                case let .failed(outcome):
                    measured.outcome = outcome
                }
            }
        } catch {
            measured.outcome = .other
        }
        measured.totalMs = Self.ms(clock.now - start)
        return measured
    }

    // MARK: Numbers

    static func ms(_ duration: Duration) -> Int {
        Int((Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15).rounded())
    }

    /// Nearest-rank percentile of a list of milliseconds.
    static func percentile(_ values: [Int], _ p: Double) -> Int? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let rank = Int((p / 100 * Double(sorted.count)).rounded(.up))
        return sorted[min(max(rank, 1), sorted.count) - 1]
    }

    static func row(_ label: String, ttft: [Int], total: [Int]) -> Row {
        Row(label: label, runs: total.count, ttftP50: percentile(ttft, 50), ttftP95: percentile(ttft, 95),
            totalP50: percentile(total, 50), totalP95: percentile(total, 95),
            note: total.isEmpty ? "no run finished" : nil)
    }

    /// The plain table Developer mode shows.
    public static func table(_ rows: [Row]) -> String {
        func cell(_ value: Int?) -> String {
            value.map { "\($0) ms" } ?? "-"
        }
        return (["Latency bench (\(repeats) runs each): time to first token, then total"] + rows.map { row in
            if let note = row.note, row.runs == 0 {
                return "\(row.label): \(note)"
            }
            let tail = row.note.map { " (\($0))" } ?? ""
            return "\(row.label): first token p50 \(cell(row.ttftP50)), p95 \(cell(row.ttftP95)); "
                + "total p50 \(cell(row.totalP50)), p95 \(cell(row.totalP95))\(tail)"
        }).joined(separator: "\n")
    }

    /// Fixed filler text of about `words` words, the same every run, so nothing of his is ever in a bench prompt.
    static func filler(words: Int, seed: Int) -> String {
        let vocabulary = ["river", "lantern", "orchard", "copper", "window", "harbor", "meadow", "pencil", "marble",
                          "violin", "thunder", "garden", "paper", "silver", "ladder", "compass", "pebble", "ribbon"]
        return (0 ..< words).map { vocabulary[($0 * 7 + seed) % vocabulary.count] }.joined(separator: " ")
    }
}

import Foundation
import TesseraCore

/// H0: the latency bench (Developer mode, "Run latency bench", behind "Tess asks Claude" and Developer mode). Five
/// repeats of each case, p50 and p95 of the time to first token and of the total, written as a plain table into the
/// trace file. Every Claude call goes through the Door: the cap, the ledger, the span and the exact words in "What was
/// sent" all apply. The prompts are fixed filler text: no words of his. Each case also reports the HTTP status it got,
/// and the warm-up's status and `max_tokens`, so the first run on the phone confirms the API shape.
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

    public let door: Door
    public let claude: BrainFactory
    public let apple: (any Brain)?

    public init(door: Door, claude: @escaping BrainFactory, apple: (any Brain)?) {
        self.door = door
        self.claude = claude
        self.apple = apple
    }

    // MARK: Run

    public func run() async -> [Row] {
        let original = door.router
        defer { door.router = original }
        var rows: [Row] = []
        for (model, name) in [(ClaudeBrain.Model.haiku, "Haiku 5.5"), (.sonnet, "Sonnet 5.5, effort low")] {
            for (suffix, prefix, fresh) in [("cold", false, true), ("warm", false, false),
                                            ("cached prefix, cold", true, true), ("cached prefix, warm", true, false)]
            {
                await rows.append(claudeCase("\(name), \(suffix)", model: model, prefix: prefix, fresh: fresh))
            }
        }
        await rows.append(appleCase())
        rows.append(Row(label: "Mac on Wi-Fi", runs: 0, note: "not set up"))
        await door.trace.setBenchTable(Self.table(rows))
        return rows
    }

    private func request(prefix: Bool) -> BrainRequest {
        var system = [TextBlock("You are a latency probe. Answer in about forty words.")]
        var cache: [CacheMark] = []
        if prefix {
            system.append(TextBlock(Self.filler(words: Self.prefixWords, seed: 7)))
            cache = [1]
        }
        return BrainRequest(system: system,
                            messages: [BrainMessage(.user, text: Self.filler(words: Self.promptWords, seed: 3))],
                            maxTokens: Self.outTokens, effort: .low, cacheAfter: cache, thinking: false,
                            deadline: .seconds(30))
    }

    private func claudeCase(_ label: String, model: ClaudeBrain.Model, prefix: Bool, fresh: Bool) async -> Row {
        let id: BrainID = model == .haiku ? .haiku : .sonnet
        let shared = fresh ? nil : claude(model, false)
        let make: @MainActor @Sendable () -> any Brain = { shared ?? claude(model, fresh) }
        var notes: [String] = []
        // A cached prefix is warmed first (through the Door, so the cap and the ledger see it); a warm connection is
        // opened by that call, or by one throwaway warm-up when there is no prefix.
        if prefix || !fresh {
            let warmer = make()
            door.router = BrainRouter { _ in warmer }
            if let warmed = await door.warm(id, request(prefix: prefix), name: "latency-bench-warm") {
                notes.append("warm-up HTTP \(warmed.status), max_tokens \(warmed.maxTokens)")
            }
        }
        var ttft: [Int] = [], total: [Int] = []
        var statuses: [Int] = []
        for _ in 0 ..< Self.repeats {
            let brain = make()
            door.router = BrainRouter { _ in brain }
            let job = DoorJob(name: "latency-bench", ladder: [id], request: request(prefix: prefix),
                              estimateNano: TessUsageLedger.estimate(
                                  text: Door.words(request(prefix: prefix)), maxTokens: Self.outTokens,
                                  model: model.rawValue
                              ))
            let measured = await time(job)
            if let status = measured.status {
                statuses.append(status)
            }
            if measured.outcome == .works, let first = measured.ttftMs {
                ttft.append(first)
                total.append(measured.totalMs)
            } else if [.notAllowed, .badKey, .capReached, .offline, .refused].contains(measured.outcome) {
                notes.append(measured.outcome == .notAllowed ? "Tess asks Claude is off" : measured.outcome.rawValue)
                return Row(label: label, runs: total.count, note: notes.joined(separator: "; "))
            } else if measured.outcome != .works {
                notes.append("failed: \(measured.outcome.rawValue)")
            }
        }
        if let status = statuses.first {
            notes.append("HTTP \(status)")
        }
        var row = Self.row(label, ttft: ttft, total: total)
        row.note = notes.isEmpty ? nil : notes.joined(separator: "; ")
        return row
    }

    private func appleCase() async -> Row {
        guard let apple, await apple.isAvailable else {
            return Row(label: "Apple on-device model", runs: 0, note: "not available on this phone")
        }
        door.router = BrainRouter { _ in apple }
        var ttft: [Int] = [], total: [Int] = []
        for _ in 0 ..< Self.repeats {
            let job = DoorJob(name: "latency-bench", ladder: [.appleOnDevice],
                              request: BrainRequest(system: [TextBlock("Answer in about forty words.")],
                                                    messages: [BrainMessage(.user, text: Self.filler(
                                                        words: Self.promptWords, seed: 3
                                                    ))],
                                                    maxTokens: Self.outTokens, deadline: .seconds(30)))
            let measured = await time(job)
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
        var status: Int?
        var outcome: ClaudeOutcome
    }

    private func time(_ job: DoorJob) async -> Measured {
        let clock = ContinuousClock()
        let start = clock.now
        var measured = Measured(ttftMs: nil, totalMs: 0, outcome: .works)
        do {
            for try await event in door.run(job) {
                switch event {
                case let .status(code):
                    measured.status = code
                case .text, .toolUse:
                    if measured.ttftMs == nil {
                        measured.ttftMs = Self.ms(clock.now - start)
                    }
                case .done, .assistant:
                    break
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

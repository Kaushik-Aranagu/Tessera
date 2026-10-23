import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// A scripted brain: answers after a fixed delay, so the bench's numbers are known.
final class FakeBrain: Brain, @unchecked Sendable {
    let id: BrainID
    var available = true
    var outcome: ClaudeOutcome = .works
    private let lock = NSLock()
    private var streamed = 0
    private var warmed = 0

    init(_ id: BrainID = .haiku) {
        self.id = id
    }

    var isAvailable: Bool {
        get async { available }
    }

    var streamCount: Int {
        lock.withLock { streamed }
    }

    var warmCount: Int {
        lock.withLock { warmed }
    }

    func stream(_: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
        lock.withLock { streamed += 1 }
        let outcome = outcome
        return AsyncThrowingStream { continuation in
            if outcome != .works {
                continuation.yield(.failed(outcome))
            } else {
                continuation.yield(.text("ok"))
                continuation.yield(.done(BrainUsage(inTokens: 300, outTokens: 50, costNano: 40000), stop: "end_turn"))
            }
            continuation.finish()
        }
    }

    func warm(_: BrainRequest) async {
        lock.withLock { warmed += 1 }
    }
}

@MainActor
struct LatencyBenchTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]

    init() throws {
        classes = try store.prepareCatalog()
    }

    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    @Test func percentilesAreNearestRank() {
        #expect(LatencyBench.percentile([], 50) == nil)
        #expect(LatencyBench.percentile([10, 50, 20, 40, 30], 50) == 30)
        #expect(LatencyBench.percentile([10, 50, 20, 40, 30], 95) == 50)
        #expect(LatencyBench.percentile([7], 95) == 7)
    }

    @Test func aRunMakesTheTableAndWritesLedgerRowsAndSpans() async throws {
        let trace = RunTrace(url: nil)
        let claude = FakeBrain(.haiku), apple = FakeBrain(.appleOnDevice)
        let bench = LatencyBench(ledger: ledger, trace: trace, claude: { _, _ in claude }, apple: apple)
        let rows = await bench.run()
        // Haiku and Sonnet, four cases each, then Apple and the Mac line.
        #expect(rows.count == 10 && rows.last?.note == "not set up")
        #expect(rows.prefix(8).allSatisfy { $0.runs == LatencyBench.repeats })
        // Every Claude call is one ledger row (the warm calls are free), and every call is one span.
        #expect(claude.streamCount == 40 && ledger.calls().count == 40)
        #expect(await trace.all().count == 45)
        let table = try #require(await trace.bench())
        #expect(table.contains("Haiku 5.5, cold") && table.contains("Sonnet 5.5, effort low, cached prefix, warm"))
        #expect(table.contains("Apple on-device model") && table.contains("Mac on Wi-Fi: not set up"))
    }

    @Test func spansAndTheTableCarryNoPromptWords() async throws {
        let trace = RunTrace(url: nil)
        let bench = LatencyBench(ledger: ledger, trace: trace, claude: { _, _ in FakeBrain() }, apple: nil)
        _ = await bench.run()
        let json = try await String(decoding: JSONEncoder().encode(trace.all()), as: UTF8.self)
        let table = await trace.bench() ?? ""
        for word in ["lantern", "orchard", "latency probe", "sk-ant"] {
            #expect(!json.contains(word) && !table.contains(word), "\(word)")
        }
        #expect(table.contains("Apple on-device model: not available on this phone"))
    }

    @Test func aRunStopsWhenTheKeyIsBadAndNeverRetries() async {
        let trace = RunTrace(url: nil)
        let brain = FakeBrain()
        brain.outcome = .badKey
        let bench = LatencyBench(ledger: ledger, trace: trace, claude: { _, _ in brain }, apple: nil)
        let rows = await bench.run()
        #expect(rows.first?.note == "badKey" && rows.first?.runs == 0)
    }

    @Test func theTraceKeepsTheLast2000SpansOnDiskOutOfBackups() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent(RunTrace.fileName)
        let trace = RunTrace(url: url)
        for index in 0 ..< 2005 {
            await trace.record(TraceSpan(kind: .tool, name: "t\(index)", totalMs: index, outcome: "works"))
        }
        let spans = await trace.all()
        #expect(spans.count == 2000 && spans.first?.name == "t5" && spans.last?.name == "t2004")
        let again = RunTrace(url: url)
        #expect(await again.all().count == 2000)
        let excluded = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        #expect(excluded == true)
        #expect(try !(String(data: Data(contentsOf: url), encoding: .utf8) ?? "").contains("sk-ant"))
    }
}

import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

@MainActor
struct LatencyBenchTests {
    @Test func percentilesAreNearestRank() {
        #expect(LatencyBench.percentile([], 50) == nil)
        #expect(LatencyBench.percentile([10, 50, 20, 40, 30], 50) == 30)
        #expect(LatencyBench.percentile([10, 50, 20, 40, 30], 95) == 50)
        #expect(LatencyBench.percentile([7], 95) == 7)
    }

    @Test func aRunMakesTheTableAndGoesThroughTheDoor() async throws {
        let claude = FakeBrain(.haiku), apple = FakeBrain(.appleOnDevice)
        let rig = try DoorRig(brains: [:])
        let bench = LatencyBench(door: rig.door, claude: { _, _ in claude }, apple: apple)
        let rows = await bench.run()
        // Haiku and Sonnet, four cases each, then Apple and the Mac line.
        #expect(rows.count == 10 && rows.last?.note == "not set up")
        #expect(rows.prefix(8).allSatisfy { $0.runs == LatencyBench.repeats })
        // Every Claude call is a ledger row and a sent-log row; so is each warm-up (6) in the ledger and the trace.
        #expect(claude.streamCount == 40 && rig.ledger.calls().count == 46)
        #expect(rig.sent.entries().count == 40)
        #expect(await rig.trace.all().count == 40 + 6 + 5)
        let table = try #require(await rig.trace.bench())
        #expect(table.contains("Haiku 5.5, cold") && table.contains("Sonnet 5.5, effort low, cached prefix, warm"))
        #expect(table.contains("Apple on-device model") && table.contains("Mac on Wi-Fi: not set up"))
        // The first run reports the API shape it got.
        #expect(table.contains("HTTP 200") && table.contains("warm-up HTTP 200, max_tokens 0"))
    }

    @Test func spansAndTheTableCarryNoPromptWords() async throws {
        let rig = try DoorRig(brains: [:])
        let bench = LatencyBench(door: rig.door, claude: { _, _ in FakeBrain() }, apple: nil)
        _ = await bench.run()
        let json = try await String(decoding: JSONEncoder().encode(rig.trace.all()), as: UTF8.self)
        let table = await rig.trace.bench() ?? ""
        for word in ["lantern", "orchard", "latency probe", "sk-ant"] {
            #expect(!json.contains(word) && !table.contains(word), "\(word)")
        }
        #expect(table.contains("Apple on-device model: not available on this phone"))
    }

    @Test func withTessAsksClaudeOffTheBenchSendsNothing() async throws {
        let claude = FakeBrain()
        let rig = try DoorRig(brains: [:], asks: false)
        let bench = LatencyBench(door: rig.door, claude: { _, _ in claude }, apple: nil)
        let rows = await bench.run()
        #expect(claude.streamCount == 0 && claude.warmCount == 0)
        #expect(rows.first?.note == "Tess asks Claude is off")
    }

    @Test func aRunStopsWhenTheKeyIsBadAndNeverRetries() async throws {
        let brain = FakeBrain()
        brain.outcome = .badKey
        let rig = try DoorRig(brains: [:])
        let bench = LatencyBench(door: rig.door, claude: { _, _ in brain }, apple: nil)
        let rows = await bench.run()
        #expect(rows.first?.note?.contains("badKey") == true && rows.first?.runs == 0)
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

import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Input hygiene H6 (docs/ai/harness/input-hygiene.md): a run is kept as its steps, never its thoughts or words, and
/// procedural memory learns which tool paths answered, only from clean runs.
@MainActor
struct RunDigestTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0, _ second: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute,
                                           second: second)) ?? .distantPast
    }

    static let clean = RunDigest.Reading(deviceOnly: false, untrusted: false)

    /// A run that asked recall then open, then answered on Sonnet after Haiku was cancelled.
    func spans(_ run: UUID, day: Int = 23, answered: Bool = true, failedTool: Bool = false) -> [TraceSpan] {
        [
            TraceSpan(kind: .tool, name: "recall", at: at(day, 12, 0, 1), totalMs: 200, outcome: "works", runID: run),
            TraceSpan(kind: .tool, name: "recall", at: at(day, 12, 0, 2), totalMs: 100, outcome: "works", runID: run),
            TraceSpan(kind: .tool, name: "open", at: at(day, 12, 0, 3), totalMs: 300,
                      outcome: failedTool ? "error" : "works", runID: run),
            TraceSpan(kind: .brain, name: "tess-turn", brain: "haiku", at: at(day, 12, 0, 4), totalMs: 1000,
                      usage: BrainUsage(inTokens: 900, outTokens: 0), outcome: "cancelled", runID: run),
            TraceSpan(kind: .brain, name: "tess-turn", brain: "sonnet", at: at(day, 12, 0, 6), totalMs: 6000,
                      usage: BrainUsage(inTokens: 1200, outTokens: 80),
                      outcome: answered ? "works 200" : "refused", runID: run),
        ]
    }

    @Test func aRunIsItsStepsInOrder() throws {
        let id = UUID()
        let other = TraceSpan(kind: .tool, name: "query", at: at(23, 12), totalMs: 5, outcome: "works", runID: UUID())
        let digest = try #require(RunDigest.make(runID: id, spans: spans(id) + [other], reading: Self.clean))
        #expect(digest.job == "tess-turn")
        #expect(digest.brains == ["haiku", "sonnet"])
        #expect(digest.steps.map(\.tool) == ["recall", "recall", "open"])
        #expect(digest.path == ["recall", "open"])
        #expect(digest.answered && digest.failure == nil)
        #expect(digest.inTokens == 2100 && digest.outTokens == 80)
        // From the first span's start (the Sonnet call began at 12:00:00) to the last one's end.
        #expect(digest.totalMs == 6000)
        #expect(RunDigest.make(runID: UUID(), spans: spans(id)) == nil)
    }

    @Test func aRunThatDidNotAnswerSaysWhy() throws {
        let id = UUID()
        let digest = try #require(RunDigest.make(runID: id, spans: spans(id, answered: false, failedTool: true)))
        #expect(!digest.answered && digest.failure == "refused")
        #expect(digest.leaf.text == "Tess couldn't answer (refused) using recall, open, 1 failed call")
        #expect(digest.leaf.stats["unanswered"] == 1 && digest.leaf.stats["failedCalls"] == 1)
        let walled = TraceSpan(kind: .brain, name: "tess-turn", at: at(23, 9), totalMs: 0, outcome: "keyShape",
                               runID: id)
        #expect(RunDigest.make(runID: id, spans: [walled])?.failure == "keyShape")
    }

    @Test func aRunLeafHoldsNamesAndCountsOnly() throws {
        let id = UUID()
        let digest = try #require(RunDigest.make(runID: id, spans: spans(id), reading: Self.clean))
        let leaf = digest.leaf
        #expect(leaf.kind == "run" && leaf.taint == .claudeSafe)
        #expect(leaf.text == "Tess answered using recall, open")
        #expect(leaf.stats == ["runs": 1, "toolCalls": 3, "failedCalls": 0, "unanswered": 0])
        // Nothing about cost reaches memory.
        #expect(!leaf.stats.keys.contains { $0.lowercased().contains("cost") })
        // A run whose reading isn't known is read the strict way: device-only, and never learned from.
        let unknown = try #require(RunDigest.make(runID: id, spans: spans(id)))
        #expect(unknown.leaf.taint == .deviceOnly)
        var book = ProcedureBook()
        let learned = book.learn(unknown)
        #expect(!learned)
    }

    @Test func runsAddUpOnTheirDayAndStrictSkipsDeviceOnlyOnes() {
        let ids = [UUID(), UUID(), UUID()]
        var readings = [ids[0]: Self.clean, ids[1]: Self.clean]
        readings[ids[2]] = RunDigest.Reading(deviceOnly: true, untrusted: false)
        let all = RunDigest.all(from: ids.flatMap { spans($0) }, readings: readings)
        #expect(all.count == 3)
        let leaves = MemoryPyramid.leaves(runs: all, now: at(24, 4))
        #expect(MemoryPyramid.leaves(runs: all, now: at(23, 11)).isEmpty)
        let pyramid = MemoryPyramid(leaves: leaves, calendar: calendar)
        let day = pyramid.nodes["/time/2026/10/23"]
        #expect(day?.stats["runs"] == 3 && day?.stats["toolCalls"] == 9)
        #expect(day?.safeLeaves == 2)
    }

    @Test func procedureMemoryLearnsOnlyFromCleanSignals() throws {
        var book = ProcedureBook()
        func digest(answered: Bool = true, reading: RunDigest.Reading = Self.clean) throws -> RunDigest {
            let id = UUID()
            return try #require(RunDigest.make(runID: id, spans: spans(id, answered: answered), reading: reading))
        }
        // A page in the run: kept as a leaf, never learned.
        let paged = try book.learn(digest(reading: RunDigest.Reading(deviceOnly: false, untrusted: true)))
        #expect(!paged)
        // Endings the path didn't cause say nothing about it.
        for outcome in ["timeout", "busy", "offline", "capReached", "cancelled", "keyShape", "moneyAction"] {
            let id = UUID()
            let span = TraceSpan(kind: .brain, name: "tess-turn", at: at(23, 12), totalMs: 10, outcome: outcome,
                                 runID: id)
            let run = try #require(RunDigest.make(runID: id, spans: [span], reading: Self.clean))
            let learned = book.learn(run)
            #expect(!learned, "\(outcome)")
        }
        #expect(book.records.isEmpty)
        let missed = try book.learn(digest(answered: false))
        #expect(missed)
        #expect(book.hint(for: "tess-turn") == nil)
        for _ in 0 ..< 3 {
            let learned = try book.learn(digest())
            #expect(learned)
        }
        let record = try #require(book.best(for: "tess-turn").first)
        #expect(record.path == ["recall", "open"] && record.tries == 4 && record.answered == 3)
        #expect(book.hint(for: "tess-turn") == "Tool paths that answered before: recall then open (3 of 4).")
    }

    @Test func aSteadyPathOutranksALuckyOne() {
        var book = ProcedureBook()
        func run(_ path: [String], answered: Bool, ms: Int = 100) -> RunDigest {
            RunDigest(runID: UUID(), at: at(23, 12), job: "tess-turn", brains: ["sonnet"],
                      steps: path.map { RunDigest.Step(tool: $0, ok: true, ms: ms) }, answered: answered,
                      failure: answered ? nil : "refused", totalMs: ms, inTokens: 0, outTokens: 0, reading: Self.clean)
        }
        for index in 0 ..< 10 {
            book.learn(run(["query"], answered: index != 0))
        }
        for _ in 0 ..< 3 {
            book.learn(run(["recall", "open"], answered: true, ms: 50))
        }
        // 9 of 10 (about 0.83) beats 3 of 3 (0.8) despite being slower.
        #expect(book.best(for: "tess-turn").map(\.path) == [["query"], ["recall", "open"]])
        #expect(book.best(for: "other-job").isEmpty)
        book.expire(before: at(24, 0))
        #expect(book.records.isEmpty)
    }

    @Test func theBookKeepsItsSizeByDroppingTheLeastRecent() {
        var book = ProcedureBook()
        for index in 0 ... ProcedureBook.maxPaths {
            book.learn(RunDigest(runID: UUID(), at: at(1, 0).addingTimeInterval(Double(index) * 60), job: "j",
                                 brains: [], steps: [RunDigest.Step(tool: "t\(index)", ok: true, ms: 1)],
                                 answered: true, failure: nil, totalMs: 1, inTokens: 0, outTokens: 0,
                                 reading: Self.clean))
        }
        #expect(book.records.count == ProcedureBook.maxPaths)
        #expect(book.records[ProcedureBook.key(job: "j", path: ["t0"])] == nil)
        #expect(book.records[ProcedureBook.key(job: "j", path: ["t1"])] != nil)
    }

    @Test func theNightTeachesTheBookFromTheClosingDayOnly() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let night = NightRun(engine: ActionEngine(store: store, classes: classes), calendar: calendar,
                             now: at(24, 4, 5), policy: .strict)
        let today = UUID(), before = UUID()
        let runs = RunDigest.all(from: spans(today) + spans(before, day: 22),
                                 readings: [today: Self.clean, before: Self.clean])
        var record = NightRecord()
        var eval = MemoryEvalRecord()
        _ = await night.run(record: &record, eval: &eval, runs: runs) { _, _ in nil }
        let book = try #require(record.procedures)
        #expect(book.records.values.map(\.tries) == [1])
        let saved = try JSONDecoder().decode(NightRecord.self, from: JSONEncoder().encode(record))
        #expect(saved.procedures == book)
        // A file from before the book still reads.
        let old = try JSONDecoder().decode(NightRecord.self, from: Data(#"{"packHashes":{},"summaries":{}}"#.utf8))
        #expect(old.procedures == nil)
    }
}

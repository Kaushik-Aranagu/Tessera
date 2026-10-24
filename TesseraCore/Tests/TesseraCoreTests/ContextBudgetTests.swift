import Foundation
@testable import TesseraTess
import Testing

/// Memory spec M2 and M3: the packer, the tuner and recall. Accuracy first (Kaushik, Oct 23): sizes are starting
/// points, never cost ceilings, and only the window trims.
struct ContextBudgetTests {
    let row = BudgetRow.defaults(for: .haiku)

    func item(_ path: String, _ text: String, score: Double = 1, at: Date? = nil) -> ContextItem {
        ContextItem(path: path, text: text, score: score, at: at)
    }

    // MARK: The packer

    @Test func recallKeepsEverythingAboveTheFloorBestFirst() {
        let pack = ContextPacker(row: row).pack([
            .recall: [item("/b", "bench", score: 0.6), item("/a", "squat", score: 0.9), item("/c", "row", score: 0.2)],
        ])
        #expect(pack.included[.recall] == ["/a", "/b"])
        #expect(pack.block(.recall) == "/a\nsquat\n\n/b\nbench")
        #expect(!pack.nothingKept && pack.dropped.isEmpty)
    }

    @Test func nothingAboveTheFloorSaysSo() {
        let pack = ContextPacker(row: row).pack([.recall: [item("/c", "row", score: 0.1)]])
        #expect(pack.nothingKept && pack.block(.recall) == ContextPacker.nothingKeptLine)
        let none = ContextPacker(row: row).pack([.recall: []])
        #expect(none.nothingKept)
        let notAsked = ContextPacker(row: row).pack([.rules: [item("", "Be brief.")]])
        #expect(!notAsked.nothingKept && notAsked.block(.recall) == nil)
    }

    @Test func aBigPackIsSentWholeWhenItFitsTheWindow() {
        // 200K tokens of recall: past Haiku's 100K price step, and still sent. Cost never trims.
        let big = (0 ..< 200).map { item("/r/\($0)", String(repeating: "x", count: 3600), score: 0.9) }
        let pack = ContextPacker(row: row).pack([.recall: big])
        #expect(pack.dropped.isEmpty && pack.inputTokens > 100_000)
        #expect(pack.growthTokens == ContextPacker.inputCeiling - pack.inputTokens)
    }

    @Test func overflowDropsTheLowestRecallFirstAndSaysMoreIsKept() {
        let recall = (0 ..< 10).map {
            item("/r/\($0)", String(repeating: "x", count: 360), score: 0.9 - Double($0) / 100)
        }
        var small = row
        small.starts[.recall] = 300
        let pack = ContextPacker(row: small, ceiling: 700).pack([.recall: recall, .rules: [item("", "Rules.")]])
        #expect(pack.dropped.first == "/r/9")
        #expect(pack.included[.recall]?.first == "/r/0")
        #expect(pack.block(.recall)?.hasSuffix(ContextPacker.moreKeptLine) == true)
        #expect(pack.block(.rules) == "Rules.")
    }

    @Test func expertiseAndWorkingAreNeverTrimmed() {
        let expertise = item("", String(repeating: "e", count: 3600))
        let working = item("/screen", String(repeating: "w", count: 360))
        let pack = ContextPacker(row: row, ceiling: 500).pack([
            .expertise: [expertise], .working: [working], .recall: [item("/r", "x", score: 0.9)],
        ])
        #expect(pack.block(.expertise) != nil && pack.block(.working) != nil)
        #expect(pack.dropped == ["/r"])
    }

    @Test func overflowDropsTheOldestTurnFirst() {
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        let turns = (0 ..< 5).map {
            item("/turns/\($0)", String(repeating: "t", count: 360), at: day.addingTimeInterval(Double($0)))
        }
        var small = row
        small.starts[.episodic] = 0
        let pack = ContextPacker(row: small, ceiling: 300).pack([.episodic: turns.reversed()])
        #expect(pack.dropped.first == "/turns/0")
        #expect(pack.included[.episodic]?.last == "/turns/4")
    }

    @Test func theSameItemsGiveTheSameBytes() {
        let items: [ContextSection: [ContextItem]] = [
            .rules: [item("", "Rules.")], .core: [item("/beliefs/you", "Trains at 6.")],
            .recall: [item("/b", "b", score: 0.7), item("/a", "a", score: 0.7)],
        ]
        let one = ContextPacker(row: row).pack(items), two = ContextPacker(row: row).pack(items)
        #expect(one == two && one.included[.recall] == ["/a", "/b"])
    }

    @Test func cacheMarksPutTheHourBeforeTheFiveMinutes() {
        let pack = ContextPacker(row: row).pack([
            .rules: [item("", "Rules.")], .expertise: [item("", "Exercises.")], .core: [item("/me", "Me.")],
            .recall: [item("/r", "r", score: 0.9)], .working: [item("/ask", "Ask.")],
        ])
        #expect(pack.cacheMarks == [CacheMark(index: 1, ttl: .oneHour), CacheMark(index: 2, ttl: .oneHour),
                                    CacheMark(index: 3, ttl: .fiveMinutes)])
        #expect(pack.blocks.map(\.section) == [.rules, .expertise, .core, .recall, .working])
    }

    @Test func theTableRoundTripsAndMissingRowsAreTheDefaults() {
        var table = BudgetTable()
        var tuned = row
        tuned.starts[.recall] = 54000
        table.set(tuned, agent: "training", model: .haiku)
        let url = FileManager.default.temporaryDirectory.appending(path: "budgets-\(UUID().uuidString).json")
        table.save(to: url)
        let loaded = BudgetTable.load(from: url)
        #expect(loaded == table && loaded.row(agent: "training", model: .haiku).start(.recall) == 54000)
        #expect(loaded.row(agent: "kitchen", model: .sonnet) == .defaults(for: .sonnet))
        try? FileManager.default.removeItem(at: url)
    }

    @Test func calibrationMovesTheEstimate() {
        var ratio = TokenRatio()
        #expect(ratio.tokens(String(repeating: "x", count: 36), in: .recall) == 10)
        ratio.calibrate(.recall, characters: 4000, tokens: 1000)
        #expect(ratio.tokens(String(repeating: "x", count: 36), in: .recall) == 9)
        ratio.calibrate(.recall, characters: 0, tokens: 5)
        #expect(ratio.ratio(.recall) == 4)
    }

    // MARK: The meter

    @Test func anOpenOfSomethingAlreadyPackedIsNotAFault() {
        let pack = ContextPacker(row: row).pack([.recall: [item("/a", "a", score: 0.9)]])
        let use = ContextUse(runID: UUID(), agent: "tess", model: "haiku", pack: pack,
                             usage: BrainUsage(inTokens: 900, outTokens: 300), visibleTextTokens: 100,
                             opened: ["/a", "/b"], recalls: 1, cited: ["/a"])
        #expect(use.opens == ["/b"] && use.thinkingTokens == 200 && use.hitSections == [.recall])
    }

    // MARK: The tuner

    func uses(_ count: Int, opens: Int, agent: String = "training") -> [ContextUse] {
        (0 ..< count).map { _ in
            ContextUse(runID: UUID(), agent: agent, model: "haiku", sectionTokens: [:],
                       opens: (0 ..< opens).map { "/x/\($0)" })
        }
    }

    @Test func faultsGrowRecallAndLowerTheFloor() {
        let (table, changes) = BudgetTuner().tune(BudgetTable(), uses: uses(10, opens: 1))
        let tuned = table.row(agent: "training", model: .haiku)
        #expect(tuned.start(.recall) == 54000 && tuned.recallFloor == 0.35)
        #expect(changes.count == 2)
    }

    @Test func aQuietAgentKeepsItsSizes() {
        let (table, changes) = BudgetTuner().tune(BudgetTable(), uses: uses(10, opens: 0))
        #expect(table == BudgetTable() && changes.isEmpty)
        let (few, _) = BudgetTuner().tune(BudgetTable(), uses: uses(3, opens: 5))
        #expect(few == BudgetTable())
    }

    @Test func theFloorNeverGoesUnderPointThree() {
        var table = BudgetTable()
        var low = row
        low.recallFloor = 0.32
        table.set(low, agent: "training", model: .haiku)
        let (tuned, _) = BudgetTuner().tune(table, uses: uses(10, opens: 2))
        #expect(tuned.row(agent: "training", model: .haiku).recallFloor == 0.3)
    }

    @Test func aMissGrowsTheSectionThatLackedIt() {
        let (table, _) = BudgetTuner().tune(BudgetTable(), uses: [],
                                            misses: [EvalMiss(agent: "kitchen", model: .sonnet, section: .episodic),
                                                     EvalMiss(agent: "kitchen", model: .sonnet, section: .expertise)])
        let tuned = table.row(agent: "kitchen", model: .sonnet)
        #expect(tuned.start(.episodic) == 18000 && tuned.start(.expertise) == 0)
    }

    @Test func theSweepShrinksOnlyOnAnEqualScore() {
        let sweep = [SweepResult(agent: "tess", model: .haiku, recallStart: 36000, score: 92),
                     SweepResult(agent: "tess", model: .haiku, recallStart: 72000, score: 92),
                     SweepResult(agent: "tess", model: .haiku, recallStart: 18000, score: 91.5)]
        let (table, _) = BudgetTuner().tune(BudgetTable(), uses: uses(10, opens: 3, agent: "tess"), sweeps: sweep)
        #expect(table.row(agent: "tess", model: .haiku).start(.recall) == 36000)
        let better = [SweepResult(agent: "tess", model: .haiku, recallStart: 144_000, score: 95)] + sweep
        let (grown, _) = BudgetTuner().tune(BudgetTable(), uses: [], sweeps: better)
        #expect(grown.row(agent: "tess", model: .haiku).start(.recall) == 144_000)
    }

    // MARK: Recall

    var graph: RecallGraph {
        var graph = RecallGraph()
        graph.link("/training/exercises/bench-press", "/training/routines/push-a")
        graph.link("/training/routines/push-a", "/beliefs/you/push-day")
        graph.link("/kitchen/recipes/chili", "/beliefs/you/likes-spicy")
        return graph
    }

    @Test func aLinkedThingRanksAboveAnUnlinkedOne() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let recall = Recall(graph: graph, now: now)
        let ranked = recall.rank([RecallCandidate(path: "/beliefs/you/push-day", importance: .noticed),
                                  RecallCandidate(path: "/beliefs/you/likes-spicy", importance: .noticed)],
                                 seeds: ["/training/exercises/bench-press"])
        #expect(ranked.map(\.path) == ["/beliefs/you/push-day"])
        #expect(ranked.first.map { $0.nearness > 0 } == true)
    }

    @Test func nearerMeansHigher() {
        let near = graph.nearness(from: ["/training/exercises/bench-press"])
        let one = near["/training/routines/push-a"] ?? 0, two = near["/beliefs/you/push-day"] ?? 0
        #expect(near["/training/exercises/bench-press"] == 1 && one > two && two > 0)
        #expect(near["/kitchen/recipes/chili"] == nil)
        #expect(graph.nearness(from: ["/training/exercises/bench-press"], hops: 1)["/beliefs/you/push-day"] == nil)
    }

    @Test func recentUseBeatsOldUse() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let fresh = try #require(Recall.activation(uses: [now.addingTimeInterval(-3600)], now: now))
        let stale = try #require(Recall.activation(uses: [now.addingTimeInterval(-30 * 86400)], now: now))
        let often = try #require(Recall.activation(uses: Array(repeating: now.addingTimeInterval(-30 * 86400),
                                                                count: 5), now: now))
        #expect(fresh > stale && often > stale)
        #expect(Recall.activation(uses: [], now: now) == nil)
    }

    @Test func wordsAloneCanBringFreeTextIn() {
        let recall = Recall(graph: graph)
        let ranked = recall.rank([RecallCandidate(path: "/docs/chili-note", fit: 0.8)], seeds: ["/nowhere"])
        #expect(ranked.map(\.path) == ["/docs/chili-note"])
    }

    @Test func recallAndThePackerAgreeOnTheFloor() {
        let recall = Recall(graph: graph, now: Date(timeIntervalSince1970: 1_800_000_000))
        let items = recall.items([RecallCandidate(path: "/training/routines/push-a", importance: .told),
                                  RecallCandidate(path: "/beliefs/you/likes-spicy", importance: .told)],
                                 seeds: ["/training/exercises/bench-press"], text: { "text of \($0)" })
        let pack = ContextPacker(row: row).pack([.recall: items])
        #expect(pack.included[.recall] == ["/training/routines/push-a"])
    }
}

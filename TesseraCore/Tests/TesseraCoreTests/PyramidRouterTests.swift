import Foundation
@testable import TesseraTess
import Testing

/// P3b of the memory pyramid (docs/ai/harness/memory-pyramid.md): asks with their dates resolved first, a router
/// that starts from words alone, learns only the residual from cited answers, keeps confidence per node, and never
/// learns through a wall.
@MainActor
struct PyramidRouterTests {
    let calendar = EvalWorld.calendar

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    /// Friday, Oct 23 2026, mid-morning.
    var now: Date {
        date(2026, 10, 23, 10)
    }

    func normalized(_ text: String) -> String {
        PyramidAsk.normalize(text, now: now, calendar: calendar)
    }

    func ask(_ text: String) -> [String] {
        PyramidAsk.terms(text, now: now, calendar: calendar)
    }

    /// One workout leaf on each of these days, and one walled leaf alone on Sep 12.
    func makePyramid() -> MemoryPyramid {
        let days = [(2025, 11, 10), (2026, 8, 3), (2026, 8, 15), (2026, 9, 5), (2026, 9, 20), (2026, 10, 2),
                    (2026, 10, 5), (2026, 10, 20), (2026, 10, 22)]
        var leaves = days.map { year, month, day in
            PyramidLeaf(id: "w-\(year)-\(month)-\(day)", at: date(year, month, day, 18), kind: "workout",
                        text: "Push Day", stats: ["sets": 12])
        }
        leaves.append(PyramidLeaf(id: "weigh-in", at: date(2026, 9, 12, 7), kind: "body", text: "Weighed in",
                                  taint: .deviceOnly))
        return MemoryPyramid(leaves: leaves, calendar: calendar)
    }

    func leaf(on day: String, in pyramid: MemoryPyramid) throws -> String {
        try #require(pyramid.nodes[day]?.children.first)
    }

    // MARK: Asks

    @Test(arguments: [
        ("how many sets last month", "how many sets last month September 2026"),
        ("what did I do yesterday", "what did I do yesterday Thu, Oct 22, 2026 October"),
        ("last Tuesday's workout", "last Tuesday's workout Tue, Oct 20, 2026 October"),
        ("3 days ago", "3 days ago Tue, Oct 20, 2026 October"),
        ("today", "today Fri, Oct 23, 2026 October"),
        ("this month so far", "this month so far October 2026"),
        ("3 months ago", "3 months ago July 2026"),
        ("what about Nov", "what about Nov November 2025"),
        ("on 2 Oct", "on 2 Oct Fri, Oct 2, 2026 October"),
        ("3 sets on Oct 5", "3 sets on Oct 5 Mon, Oct 5, 2026 October"),
        ("Oct 5 2025", "Oct 5 2025 Sun, Oct 5, 2025 October"),
        ("May 4", "May 4 Mon, May 4, 2026 May"),
        ("may I ask how the week went", "may I ask how the week went"),
        ("how was the trip", "how was the trip"),
    ])
    func anAskHasItsDateResolved(text: String, expected: String) {
        #expect(normalized(text) == expected)
    }

    @Test func wordsAreLowercasedRunsOfLettersAndDigits() {
        #expect(PyramidAsk.words("Fri, Oct 23, 2026") == ["fri", "oct", "23", "2026"])
        // The router reads the terms: the date resolved, the words that say nothing about where to look gone.
        #expect(ask("how was the trip") == ["trip"])
        #expect(ask("what did I do yesterday") == ["yesterday", "thu", "oct", "22", "2026", "october"])
    }

    // MARK: Firing

    @Test func wordsAloneRouteADatedAsk() {
        let router = PyramidRouter()
        let steps = router.guess(ask("what did I do yesterday"), to: .day, in: makePyramid(), policy: .lab)
        #expect(steps.map(\.path) == ["/time/2026", "/time/2026/10", "/time/2026/10/22"])
        #expect(steps.allSatisfy { $0.probability > 0.5 })
        // Right, but not sure enough to skip the walk before anything is learned.
        #expect(!router.isSure(steps))
    }

    @Test func aTieGoesToTheNewest() {
        let steps = PyramidRouter().guess(["hello"], to: .month, in: makePyramid(), policy: .lab)
        #expect(steps.map(\.path) == ["/time/2026", "/time/2026/10"])
    }

    @Test func probabilitiesSumToOne() {
        let pyramid = makePyramid()
        let ranked = PyramidRouter().ranked(ask("last month"), at: "/time/2026", in: pyramid, policy: .lab)
        #expect(ranked.first?.path == "/time/2026/09")
        #expect(abs(ranked.reduce(0) { $0 + $1.probability } - 1) < 1e-9)
    }

    @Test func aGuessThatCannotReachTheLevelIsEmpty() {
        let empty = MemoryPyramid(leaves: [], calendar: calendar)
        #expect(PyramidRouter().guess(["oct"], to: .day, in: empty, policy: .lab).isEmpty)
    }

    // MARK: Learning

    @Test func theTruePathRunsFromTheRootsChildDown() {
        #expect(PyramidRouter.truePath(to: "/time/2026/10/22/leaf-0a") == ["/time/2026", "/time/2026/10",
                                                                         "/time/2026/10/22",
                                                                         "/time/2026/10/22/leaf-0a"])
        #expect(PyramidRouter.truePath(to: "/summaries/day/2026-10-22").isEmpty)
    }

    @Test func aPersonalPhraseIsLearnedFromCitedAnswers() {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        let trip = ask("how was the trip")
        let before = router.guess(trip, to: .month, in: pyramid, policy: .lab)
        #expect(before.last?.path == "/time/2026/10")
        for _ in 0 ..< 60 {
            router.learn(trip, cited: "/time/2026/08", in: pyramid, policy: .lab)
        }
        let after = router.guess(trip, to: .month, in: pyramid, policy: .lab)
        #expect(after.map(\.path) == ["/time/2026", "/time/2026/08"])
        #expect(router.isSure(after))
        // What it learned is about "trip", not about everything: a dated ask still goes where its date says.
        let lastMonth = router.guess(ask("how many sets last month"), to: .month, in: pyramid, policy: .lab)
        #expect(lastMonth.last?.path == "/time/2026/09")
    }

    @Test func aStepTheWordsAlreadyGetRightAndSureTrainsNothing() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter(sure: 0.5)
        let cited = try leaf(on: "/time/2026/10/22", in: pyramid)
        let trained = router.learn(ask("what did I do yesterday"), cited: cited, in: pyramid, policy: .lab)
        #expect(trained == 0)
        #expect(router.weights.isEmpty)
    }

    @Test func anUnsureRightStepStillTrainsTowardSure() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        let yesterday = ask("what did I do yesterday")
        let cited = try leaf(on: "/time/2026/10/22", in: pyramid)
        #expect(router.learn(yesterday, cited: cited, in: pyramid, policy: .lab) > 0)
        for _ in 0 ..< 40 {
            router.learn(yesterday, cited: cited, in: pyramid, policy: .lab)
        }
        let steps = router.guess(yesterday, to: .day, in: pyramid, policy: .lab)
        #expect(steps.last?.path == "/time/2026/10/22")
        #expect(router.isSure(steps))
        // Once sure, the same answer trains nothing more.
        #expect(router.learn(yesterday, cited: cited, in: pyramid, policy: .lab) == 0)
    }

    @Test func aCiteOffTheTreeTrainsNothing() {
        var router = PyramidRouter()
        #expect(router.learn(["trip"], cited: "/time/2031/01", in: makePyramid(), policy: .lab) == 0)
        #expect(router.learn(["trip"], cited: "/summaries/day/2026-10-22", in: makePyramid(), policy: .lab) == 0)
        #expect(router.weights.isEmpty)
    }

    // MARK: Walls

    @Test func strictNeverOffersOrLearnsAWalledNode() throws {
        let pyramid = makePyramid()
        let walled = try leaf(on: "/time/2026/09/12", in: pyramid)
        let strictDays = PyramidRouter.options(of: "/time/2026/09", in: pyramid, policy: .strict).map(\.path)
        #expect(strictDays == ["/time/2026/09/20", "/time/2026/09/05"])
        let labDays = PyramidRouter.options(of: "/time/2026/09", in: pyramid, policy: .lab).map(\.path)
        #expect(labDays.contains("/time/2026/09/12"))

        var strict = PyramidRouter()
        #expect(strict.learn(["scale"], cited: walled, in: pyramid, policy: .strict) == 0)
        #expect(strict.weights.isEmpty)
        var lab = PyramidRouter()
        #expect(lab.learn(["scale"], cited: walled, in: pyramid, policy: .lab) > 0)
    }

    // MARK: Confidence

    @Test func confidenceCountsCheckedAnswers() {
        var router = PyramidRouter()
        #expect(router.confidence("/time/2026/10") == 0.5)
        router.record("/time/2026/10", right: true)
        router.record("/time/2026/10", right: true)
        router.record("/time/2026/10", right: false)
        #expect(router.counts["/time/2026/10"] == PyramidRouter.Counts(right: 2, wrong: 1))
        #expect(abs(router.confidence("/time/2026/10") - 0.6) < 1e-9)
    }

    // MARK: Night

    @Test func aYearPairIsOneWhoseFeatureIsAYear() {
        #expect(PyramidRouter.isYearPair("nov|2025"))
        #expect(!PyramidRouter.isYearPair("nov|rank0"))
        #expect(!PyramidRouter.isYearPair("same"))
        #expect(!PyramidRouter.isYearPair("2025"))
    }

    @Test func theNightFadesYearPairsAndDropsGoneNodes() {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        router.learn(ask("what about Nov"), cited: "/time/2025/11", in: pyramid, policy: .lab)
        router.record("/time/1999/01", right: true)
        router.record("/time/2026/10", right: true)
        let before = router.weights
        let yearPairs = before.keys.filter { PyramidRouter.isYearPair($0) }
        #expect(!yearPairs.isEmpty)
        router.night(in: pyramid)
        for (pair, weight) in before {
            let expected = PyramidRouter.isYearPair(pair) ? weight * 0.98 : weight
            #expect(abs((router.weights[pair] ?? .nan) - expected) < 1e-12, "\(pair)")
        }
        #expect(router.counts["/time/1999/01"] == nil)
        #expect(router.counts["/time/2026/10"] != nil)
    }

    @Test func pruningKeepsThePairsThatMovedFurthest() {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        for _ in 0 ..< 5 {
            router.learn(ask("how was the trip"), cited: "/time/2026/08", in: pyramid, policy: .lab)
        }
        let before = router.weights
        #expect(before.count > 5)
        router.night(in: pyramid, yearDecay: 1, cap: 5)
        #expect(router.weights.count == 5)
        let moved = { (pair: String, weight: Double) in abs(weight - PyramidRouter.start(pair)) }
        let keptLeast = router.weights.map { moved($0.key, $0.value) }.min() ?? 0
        let droppedMost = before.filter { router.weights[$0.key] == nil }.map { moved($0.key, $0.value) }.max() ?? 0
        #expect(keptLeast >= droppedMost)
    }

    @Test func theRouterSurvivesTheFile() throws {
        var router = PyramidRouter(rate: 0.2, sure: 0.8)
        router.learn(ask("how was the trip"), cited: "/time/2026/08", in: makePyramid(), policy: .lab)
        router.record("/time/2026/08", right: true)
        let saved = try JSONDecoder().decode(PyramidRouter.self, from: JSONEncoder().encode(router))
        #expect(saved == router)
    }
}

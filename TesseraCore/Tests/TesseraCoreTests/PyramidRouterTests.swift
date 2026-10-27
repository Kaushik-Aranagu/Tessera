import Foundation
import TesseraCore
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

    /// A test wall: "lexapro" and "rehab" are private.
    static func isWalled(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("lexapro") || lower.contains("rehab")
    }

    /// An ask's terms through the wall, as `learn` takes them.
    func taught(_ text: String) throws -> PyramidTerms {
        try #require(PyramidTerms.walled(text, now: now, calendar: calendar, isWalled: Self.isWalled))
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
        #expect(ask("what did I do yesterday") == ["thu", "oct", "22", "2026", "october"])
        // A date word stays when nothing was resolved from it.
        #expect(ask("the last set") == ["last", "set"])
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

    @Test func aPersonalPhraseIsLearnedFromCitedAnswers() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        let trip = ask("how was the trip")
        let before = router.guess(trip, to: .month, in: pyramid, policy: .lab)
        #expect(before.last?.path == "/time/2026/10")
        let terms = try taught("how was the trip")
        for _ in 0 ..< 60 {
            router.learn(terms, cited: "/time/2026/08", in: pyramid, policy: .lab)
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
        let trained = try router.learn(taught("what did I do yesterday"), cited: cited, in: pyramid, policy: .lab)
        #expect(trained == 0)
        #expect(router.weights.isEmpty)
    }

    @Test func anUnsureRightStepStillTrainsTowardSure() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        let yesterday = try taught("what did I do yesterday")
        let cited = try leaf(on: "/time/2026/10/22", in: pyramid)
        let first = router.learn(yesterday, cited: cited, in: pyramid, policy: .lab)
        #expect(first > 0)
        for _ in 0 ..< 40 {
            router.learn(yesterday, cited: cited, in: pyramid, policy: .lab)
        }
        let steps = router.guess(yesterday.words, to: .day, in: pyramid, policy: .lab)
        #expect(steps.last?.path == "/time/2026/10/22")
        #expect(router.isSure(steps))
        // Once sure, the same answer trains nothing more.
        let again = router.learn(yesterday, cited: cited, in: pyramid, policy: .lab)
        #expect(again == 0)
    }

    @Test func aCiteOffTheTreeTrainsNothing() throws {
        var router = PyramidRouter()
        let trip = try taught("trip")
        let missing = router.learn(trip, cited: "/time/2031/01", in: makePyramid(), policy: .lab)
        let offTree = router.learn(trip, cited: "/summaries/day/2026-10-22", in: makePyramid(), policy: .lab)
        #expect(missing == 0 && offTree == 0)
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

        let scale = try taught("scale")
        var strict = PyramidRouter()
        let strictTrained = strict.learn(scale, cited: walled, in: pyramid, policy: .strict)
        #expect(strictTrained == 0)
        #expect(strict.weights.isEmpty)
        var lab = PyramidRouter()
        let labTrained = lab.learn(scale, cited: walled, in: pyramid, policy: .lab)
        #expect(labTrained > 0)
    }

    @Test func aWalledAskTeachesNothing() {
        func terms(_ text: String) -> [String]? {
            PyramidTerms.walled(text, now: now, calendar: calendar, isWalled: Self.isWalled)?.words
        }
        #expect(terms("how was my Lexapro week") == nil)
        #expect(terms("knee rehab last month") == nil)
        // A key is walled whatever the wall says; a key-shaped piece is dropped from an ask that is otherwise plain.
        #expect(terms("my " + "sk" + "-" + "ant" + "-api03-AbCdEf123") == nil)
        #expect(terms("the trip a1b2c3d4e5f6") == ["trip"])
        #expect(terms("the trip") == ["trip"])
    }

    @Test func theStoreWallsHisPrivateWords() {
        let store = ObjectStore.open(inMemory: true)
        func terms(_ text: String) -> [String]? {
            PyramidTerms.walled(text, now: now, calendar: calendar, store: store)?.words
        }
        #expect(terms("how was my lexapro week") == nil)
        #expect(terms("therapy ideas last month") == nil)
        #expect(terms("how was the trip") == ["trip"])
        #expect(terms("Weeknight dal") == ["weeknight", "dal"])
    }

    @Test func aWordWalledLaterIsForgottenAtNight() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        try router.learn(taught("the trip"), cited: "/time/2026/08", in: pyramid, policy: .lab)
        #expect(router.weights.keys.contains { $0.hasPrefix("trip|") })
        router.night(in: pyramid) { $0 == "trip" }
        #expect(!router.weights.keys.contains { $0.hasPrefix("trip|") })
    }

    // MARK: Residual

    @Test func aTieIsNotRight() throws {
        // Two years tie on words alone at 0.5 each; with sure at 0.5 a tie-break would call the newest right and
        // sure and train nothing (QA on #1478). A tie is not right, so it trains.
        var router = PyramidRouter(sure: 0.5)
        let trained = try router.learn(taught("hello"), cited: "/time/2026", in: makePyramid(), policy: .lab)
        #expect(trained == 1)
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
        #expect(!PyramidRouter.isYearPair("nov|rank0@month"))
        #expect(!PyramidRouter.isYearPair("same"))
        #expect(!PyramidRouter.isYearPair("2025"))
        // Four digits that are no year don't fade.
        #expect(!PyramidRouter.isYearPair("pin|1234") && !PyramidRouter.isYearPair("pin|9999"))
    }

    @Test func theNightFadesYearPairsAndDropsGoneNodes() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        try router.learn(taught("what about Nov"), cited: "/time/2025/11", in: pyramid, policy: .lab)
        router.record("/time/1999/01", right: true)
        router.record("/time/2026/10", right: true)
        let before = router.weights
        let yearPairs = before.keys.filter { PyramidRouter.isYearPair($0) }
        #expect(!yearPairs.isEmpty)
        router.night(in: pyramid) { _ in false }
        for (pair, weight) in before {
            let expected = PyramidRouter.isYearPair(pair) ? weight * 0.98 : weight
            #expect(abs((router.weights[pair] ?? .nan) - expected) < 1e-12, "\(pair)")
        }
        #expect(router.counts["/time/1999/01"] == nil)
        #expect(router.counts["/time/2026/10"] != nil)
    }

    @Test func pruningKeepsThePairsThatMovedFurthest() throws {
        let pyramid = makePyramid()
        var router = PyramidRouter()
        let trip = try taught("how was the trip")
        for _ in 0 ..< 5 {
            router.learn(trip, cited: "/time/2026/08", in: pyramid, policy: .lab)
        }
        let before = router.weights
        #expect(before.count > 5)
        router.night(in: pyramid, yearDecay: 1, cap: 5) { _ in false }
        #expect(router.weights.count == 5)
        let moved = { (pair: String, weight: Double) in abs(weight - PyramidRouter.start(pair)) }
        let keptLeast = router.weights.map { moved($0.key, $0.value) }.min() ?? 0
        let droppedMost = before.filter { router.weights[$0.key] == nil }.map { moved($0.key, $0.value) }.max() ?? 0
        #expect(keptLeast >= droppedMost)
    }

    // MARK: File

    @Test func theRouterSurvivesTheFileOutOfBackups() throws {
        var router = PyramidRouter(rate: 0.2, sure: 0.8)
        try router.learn(taught("how was the trip"), cited: "/time/2026/08", in: makePyramid(), policy: .lab)
        router.record("/time/2026/08", right: true)
        let url = FileManager.default.temporaryDirectory
            .appending(path: "router-\(UUID().uuidString)/\(PyramidRouter.fileName)")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        router.save(to: url)
        #expect(PyramidRouter.load(from: url) == router)
        let excluded = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        #expect(excluded == true)
        // No file reads as a new router.
        #expect(PyramidRouter.load(from: url.appending(path: "missing")) == PyramidRouter())
    }
}

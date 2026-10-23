import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Together piece 5: write anywhere. The router reads on the phone only; walled lines are classified first.
@MainActor
struct WriteRouterTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let router: WriteRouter
    let context = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar)

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        router = WriteRouter(engine: engine)
    }

    func one(_ line: String) -> WriteRouter.Candidate? {
        if case let .one(candidate) = router.route(line, context: context) {
            return candidate
        }
        return nil
    }

    func fake(_ app: AppID, _ confidence: Double) -> WriteRouter.Candidate {
        WriteRouter.Candidate(
            app: app,
            action: "x",
            receipt: "r",
            confidence: confidence,
            isWalled: false,
            parse: .shop
        )
    }

    // MARK: One reading

    @Test(arguments: [
        ("buy milk", AppID.kitchen, "addGroceries"), ("bench 80x8", .training, "logExercise"),
        ("list: packing", .lists, "createList"), ("timer pasta 10", .kitchen, "startKitchenTimer"),
        ("note: call the landlord", .notes, "createNote"),
    ])
    func oneAppReadsItAndItIsDone(_ line: String, _ app: AppID, _ action: String) {
        let candidate = one(line)
        #expect(candidate?.app == app && candidate?.action == action, "\(line)")
        #expect(candidate?.isWalled == false)
    }

    @Test func aLineNoAppReadsIsNothing() {
        for line in ["call mum", "", "   ", "sk-ant-api03-abcdefghijklmnopqrstuvwxyz"] {
            if case .nothing = router.route(line, context: context) {} else {
                Issue.record("\(line) should be nothing")
            }
        }
    }

    // MARK: Ties

    @Test func twoAppsAtTheTopScoreAreATieInAppOrderAndALowerScoreLoses() {
        if case let .tie(candidates) = WriteRouter.resolve([
            fake(.lists, 0.7),
            fake(.training, 0.7),
            fake(.kitchen, 0.4),
        ]) {
            #expect(candidates.map(\.app) == [.training, .lists])
        } else {
            Issue.record("expected a tie")
        }
        if case let .one(candidate) = WriteRouter.resolve([fake(.lists, 0.7), fake(.training, 0.9)]) {
            #expect(candidate.app == .training)
        } else {
            Issue.record("expected one")
        }
        // Two readings from one app are one reading.
        if case let .one(candidate) = WriteRouter.resolve([fake(.kitchen, 0.9), fake(.kitchen, 0.9)]) {
            #expect(candidate.app == .kitchen)
        } else {
            Issue.record("expected one")
        }
        if case .nothing = WriteRouter.resolve([]) {} else {
            Issue.record("expected nothing")
        }
    }

    // MARK: Walls

    @Test(arguments: ["spent 12.40 lunch", "paid rent 1200", "6.50 cab", "took advil 400mg", "slept 6 hours",
                      "weighed 82.5 kg", "my password is hunter2"])
    func aWalledLineHasOneDeterministicReadingAndAReceiptWithNoAmount(_ line: String) {
        guard case let .one(candidate) = router.route(line, context: context) else {
            Issue.record("\(line) should have one reading")
            return
        }
        #expect(candidate.isWalled && candidate.confidence == 1)
        #expect(candidate.receipt.allSatisfy { !$0.isNumber } && !candidate.receipt.contains("$"))
        #expect(["logSpend", "createNote"].contains(candidate.action))
    }

    @Test func aWalledLineIsNeverATie() {
        for line in [
            "spent 12.40 lunch",
            "bench 80 for 8 kg and took advil 400mg",
            "list: advil 400mg",
            "buy advil 400mg",
        ] {
            if case .tie = router.route(line, context: context) {
                Issue.record("\(line) must never tie")
            }
        }
    }

    @Test func aWalledSpendWithAHealthWordSaysOnlySpendLogged() throws {
        for line in ["paid ozempic 80", "spent 80 on insulin", "paid 40 for lexapro", "paid dr lin 120"] {
            let candidate = try #require(one(line))
            #expect(candidate.receipt == "Spend, logged.")
            #expect(candidate.isWalled && !candidate.receipt.lowercased().contains("ozempic"))
        }
        // A plain word keeps its name.
        #expect(one("spent 12.40 lunch")?.receipt == "Lunch, logged.")
    }

    @Test func aWalledLineWithNoReadingGoesToAPrivateNoteNeverNothing() {
        // Secret words and body facts the other rules would not read as a write.
        for line in [
            "is my password hunter2 right?",
            "my blood pressure 120 over 80",
            "calories 2400 today",
            "I feel dizzy",
        ] {
            guard case let .one(candidate) = router.route(line, context: context) else {
                Issue.record("\(line) must have a reading")
                continue
            }
            #expect(candidate.isWalled && (candidate.app == .notes || candidate.app == .money))
            #expect(candidate.receipt == "Private note, kept." || candidate.receipt.hasSuffix("logged."))
        }
        if case .nothing = router.route("my blood pressure 120 over 80", context: context) {
            Issue.record("a walled line is never nothing")
        }
    }

    @Test func aReceiptOnHomeNeverCarriesAnAmount() throws {
        let capture = TessCaptureEngine(engine: engine)
        let candidate = try #require(one("spent 12.40 lunch"))
        let done = router.perform(candidate, with: capture, context: context)
        #expect(done.records.count == 1 && done.line == "Lunch, logged.")
        // The amount is in Money, where it was logged.
        let spendClass = try #require(engine.classes[.spend])
        let spend = try #require(engine.store.objects(of: spendClass).first)
        #expect(engine.store.value("typed", of: spend)?.stringValue == "12.40")
    }

    // MARK: Doing it

    @Test func doingItWritesOneGhostRowWithUndo() throws {
        let capture = TessCaptureEngine(engine: engine)
        let candidate = try #require(one("buy milk"))
        let done = router.perform(candidate, with: capture, context: context)
        #expect(done.records.count == 1 && done.records[0].state == .pending && done.line == "On Groceries.")
        #expect(done.source == .grammar)
    }

    @Test func theRouterNeverTouchesAModel() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess/WriteRouter.swift")
        let text = try String(contentsOf: sources, encoding: .utf8)
        for word in ["ClaudeTessModel", "FoundationModels", "LanguageModel", "URLSession", "TessRouter", "router.run"] {
            #expect(!text.contains(word))
        }
    }

    @Test(arguments: [
        "calories 2400 today",
        "burned 400 kcal",
        "ate 600 calories",
        "2400 calories",
        "calories: 1800",
        "calories were 2400",
        "calories was 2100",
    ])
    func aCalorieLineThatLogsOneIsWalled(_ line: String) {
        #expect(WriteRouter.isCalorieShaped(line), "\(line)")
    }

    @Test(arguments: [
        "low calorie yogurt",
        "add calories to the recipe",
        "buy low calorie bread",
        "calorie counter app",
        "check the calories on the label"
    ])
    func anOrdinaryCalorieWordIsNotWalled(_ line: String) {
        #expect(!WriteRouter.isCalorieShaped(line), "\(line)")
    }

    @Test func poolPhrasesAreReadOnlyWhenThePoolsSwitchIsOn() throws {
        try engine.perform(CreatePool(name: "US checking"), by: .user)
        let on = TessContext(now: context.now, calendar: context.calendar, moneyPools: true)
        guard case let .one(candidate) = router.route("got 3200 paycheck", context: on) else {
            Issue.record("expected one reading")
            return
        }
        #expect(candidate.app == .money && candidate.action == "logInflow" && candidate.isWalled)
        #expect(candidate.receipt == "Money in, logged." && candidate.receipt.allSatisfy { !$0.isNumber })
        // Off, the same words are only a private note: nothing logs money.
        let readOff = one("got 3200 paycheck")
        #expect(readOff?.action == "createNote")
    }
}

import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// MU2 (Research 129, Product 999df84), amended by his tap "All but the key" (Oct 17 2:32 AM PT, confirmed 12:32 PM):
/// a capture the grammar cannot read goes whole to Claude, money and body included; only a key stays. What the grammar
/// claimed with a question or a refusal, and the inbox, stay on the phone.
@MainActor
@Suite(.oldWalls)
struct MoneyWallTests {
    final class Spy: TessModel {
        var heard: [String] = []
        let route: OpRoute

        init(route: OpRoute) {
            self.route = route
        }

        var modelName: String? {
            "spy"
        }

        func isAvailable(for _: TessUse) -> Bool {
            true
        }

        func run(_ request: TessRequest, engine _: ActionEngine) async -> TessResult {
            heard.append(request.text)
            return .missed
        }
    }

    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test(arguments: [
        "costco 212.37", "uber 23.40", "coffee 6.25", "coffee 6.25 today", "trader joe's 38.20 sat",
        "spent 12.40 lunch", "$4.99/lb", "2 for $5", "£12.50 lunch", "paid rent 650", "450 rs auto",
        "lunch with sam was 23 quid", "refund 19.99 amazon", "12,40 lunch",
    ])
    func aMoneyMissReachesClaudeWhole(_ phrase: String) async {
        #expect(PrivateFacts.isMoneyShaped(phrase), "\(phrase)")
        let device = Spy(route: .onDevice), claude = Spy(route: .claude)
        let router = TessRouter(engine: engine, models: [GrammarTessModel(capture: TessCaptureEngine(engine: engine)),
                                                         device, claude])
        _ = await router.run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        // One rule for both wall tests: what the grammar answers stays on the phone; what it cannot read goes whole.
        let claimed = TessCaptureEngine(engine: engine).grammarCapture(phrase, context: TessContext()) != nil
        #expect(claude.heard == (claimed ? [] : [phrase]), "\(phrase)")
    }

    @Test(arguments: ["80 x5", "bench 82.50 x 8", "80 for 8", "5 reps", "call mom", "pay the apple card bill mon",
                      "ring the gym about chalk", "pick up 2 lemons"])
    func everythingElseStillReachesClaude(_ phrase: String) async {
        #expect(!PrivateFacts.isMoneyShaped(phrase), "\(phrase)")
        let claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [claude]).run(TessRequest(text: phrase, context: TessContext(),
                                                                               use: .capture))
        #expect(claude.heard == [phrase])
    }

    /// Research 138 (docs/research/fixtures/money-body-wall.md), the wall rows MB1 to MB23 a person types.
    @Test(arguments: [
        "$212.37 at Costco", "costco 212.37", "paid rent 2100", "rent 2100", "venmo sam 25 for pizza", "venmo'd sam 25",
        "checking is at 3,412", "got paid 4k", "my salary is 142k", "remember my rent is 2100", "coffee 6.25 today",
        "pay rent 2100 friday", "buy a $5 card", "$38.20 trader joe's", "182.4 this morning", "182.4 lb this morning",
        "weighed in at 83 kg", "bp 128/82", "resting hr 58", "slept 5 hours", "took 2 advil", "10mg lexapro",
        "migraine since noon",
    ])
    func aMoneyOrBodyMissReachesClaudeWhole(_ phrase: String) async {
        #expect(PrivateFacts.isWalled(phrase, lastWeightKg: nil), "\(phrase)")
        let device = Spy(route: .onDevice), claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [GrammarTessModel(capture: TessCaptureEngine(engine: engine)),
                                                      device, claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        let claimed = TessCaptureEngine(engine: engine).grammarCapture(phrase, context: TessContext()) != nil
        #expect(claude.heard == (claimed ? [] : [phrase]), "\(phrase)")
    }

    /// The pass rows MB31 to MB40: lifts, food, distance, plans and money or body words with no amount.
    @Test(arguments: [
        "bench 80 x 8", "new best on deadlift 180 kg", "rice 2 lb", "weigh the flour 500 g", "Costco run saturday",
        "pay rent friday", "call mom about money", "budget meeting 3pm", "sleep by 11", "5k run", "Push A at 6",
        "Tacos at 7", "dune page 140",
    ])
    func passRowsStillReachClaude(_ phrase: String) async {
        #expect(!PrivateFacts.isWalled(phrase, lastWeightKg: nil), "\(phrase)")
        let claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard == [phrase])
    }

    /// A key-shaped run, built from pieces so no key-shaped text sits in the source.
    nonisolated static func fakeKey(_ unit: String, _ count: Int) -> String {
        let marker = ["sk", "ant", "api03", ""].joined(separator: "-")
        return marker + String(repeating: unit, count: count)
    }

    nonisolated static let keyPhrases: [String] = [
        fakeKey("Ab3x", 8),
        "my key is " + fakeKey("Ab3x", 4),
        "please save this\n" + fakeKey("Qw7z", 8) + "\nthanks",
        "key:  " + fakeKey("Mn4p", 8) + "  for later",
    ]

    @Test(arguments: keyPhrases)
    func aKeyStillNeverLeaves(_ phrase: String) async {
        let device = Spy(route: .onDevice), claude = Spy(route: .claude)
        let result = await TessRouter(engine: engine, models: [device, claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard.isEmpty && device.heard.isEmpty && result.line == TessRouter.keyLine)
    }

    @Test func theInboxNeverHoldsMoney() {
        let inbox = TessInbox(store: store, classes: engine.classes)
        #expect(inbox.add("costco 212.37", at: .now) == nil)
        #expect(inbox.add("ring the gym about chalk", at: .now) != nil)
        #expect(inbox.waiting().map(\.title) == ["ring the gym about chalk"])
    }

    @Test(arguments: [
        "set a timer for the pasta ten minutes",
        "how long on the pasta timer",
        "timer",
        "both timers are done"
    ])
    func aCookTimerPhraseNeverReachesClaude(_ phrase: String) async {
        let claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard.isEmpty, "\(phrase)")
    }

    @Test func aClockIsNotMoneyAndStoneIsABodyFact() {
        #expect(!PrivateFacts.isMoneyShaped("dinner at 7.30") && !PrivateFacts.isWalled(
            "dinner at 7.30",
            lastWeightKg: nil
        ))
        #expect(PrivateFacts.isMoneyShaped("coffee 7.30 today")) // not "at": still a price
        #expect(PrivateFacts.isMoneyShaped("rent at 7.30")) // a money word keeps it money
        for phrase in ["Eleven stone four", "eleven stone", "12 st 3", "I'm 11 stone 4"] {
            #expect(PrivateFacts.isWalled(phrase, lastWeightKg: nil), "\(phrase)")
        }
        #expect(!PrivateFacts.isWalled("bring a stone for the wall", lastWeightKg: nil))
    }

    @Test(arguments: ["8 mins", "pasta 10", "finished cooking", "how long left", "stop the rice", "step 3"])
    func whileACookRunsItsPhrasesNeverReachClaude(_ phrase: String) async throws {
        let recipe = try engine.perform(
            CreateRecipe(text: "Rice\nIngredients\n1 cup rice\nMethod\n1. Rinse.\n2. Simmer 15 minutes.\n3. Rest."),
            by: .user
        ).output
        try engine.perform(StartCooking(recipe: recipe.id), by: .user)
        let claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard.isEmpty, "\(phrase)")
        // And once the cook is done, the same phrase is an ordinary miss.
        let cook = try #require(ProcessTable(engine: engine).running()?.subject)
        try engine.perform(FinishCooking(cook: cook.id), by: .user)
        let after = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [after])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(after.heard == [phrase], "\(phrase)")
    }

    @Test func aTaskLessMoveIsAPlainMiss() async {
        let tess = TessCaptureEngine(engine: engine)
        let said = await tess.capture("move dentist to 7", context: TessContext())
        // No move was made: the phrase is only kept as a note to sort later.
        #expect(said.keptToSort && said.line == "move dentist to 7, kept to sort later.", "\(said.line)")
        #expect(said.records.map(\.action) == [CreateNote.descriptor.name])
    }
}

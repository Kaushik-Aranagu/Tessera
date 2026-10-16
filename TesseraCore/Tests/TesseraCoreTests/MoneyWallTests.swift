import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// MU2 (Research 129, Product 999df84): money stays on the phone. Money-shaped phrases never reach Claude, from the
/// router, from Claude's own route or from the inbox.
@MainActor
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
    func moneyNeverReachesClaude(_ phrase: String) async {
        #expect(PrivateFacts.isMoneyShaped(phrase), "\(phrase)")
        let device = Spy(route: .onDevice), claude = Spy(route: .claude)
        let router = TessRouter(engine: engine, models: [device, claude])
        _ = await router.run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard.isEmpty)
        #expect(device.heard == [phrase]) // the phone's own model may still read it
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
    func moneyAndBodyRowsNeverReachClaude(_ phrase: String) async {
        #expect(PrivateFacts.isWalled(phrase), "\(phrase)")
        let device = Spy(route: .onDevice), claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [device, claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard.isEmpty && device.heard == [phrase])
    }

    /// The pass rows MB31 to MB40: lifts, food, distance, plans and money or body words with no amount.
    @Test(arguments: [
        "bench 80 x 8", "new best on deadlift 180 kg", "rice 2 lb", "weigh the flour 500 g", "Costco run saturday",
        "pay rent friday", "call mom about money", "budget meeting 3pm", "sleep by 11", "5k run", "Push A at 6",
        "Tacos at 7", "dune page 140",
    ])
    func passRowsStillReachClaude(_ phrase: String) async {
        #expect(!PrivateFacts.isWalled(phrase), "\(phrase)")
        let claude = Spy(route: .claude)
        _ = await TessRouter(engine: engine, models: [claude])
            .run(TessRequest(text: phrase, context: TessContext(), use: .capture))
        #expect(claude.heard == [phrase])
    }

    @Test func theInboxNeverHoldsMoney() {
        let inbox = TessInbox(store: store, classes: engine.classes)
        #expect(inbox.add("costco 212.37", at: .now) == nil)
        #expect(inbox.add("ring the gym about chalk", at: .now) != nil)
        #expect(inbox.waiting().map(\.title) == ["ring the gym about chalk"])
    }
}

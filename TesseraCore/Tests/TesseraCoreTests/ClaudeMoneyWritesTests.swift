import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// His pick on the card (Oct 27 12:28 PM PT, "Claude can write money too"): a money call goes to Claude like any other
/// and lands pending, as a ghost row with Undo. The old rule, money on the phone's own rungs only, is still held under
/// `.oldWalls`.
@MainActor
struct ClaudeMoneyWritesTests {
    let helper = TessRunTests()

    func purse() -> TessFrame {
        let today = ElementItem(kind: "spend", name: "Today", taint: .deviceOnly,
                                facts: [ElementFact("86", taint: .deviceOnly)])
        return TessRunElementsTests().frame("purse", items: [today])
    }

    @Test func claudesToolListHasMoneyButNeverTheRehearsal() {
        #expect(ClaudeSees.moneyWrites)
        let names = Set(TessTools.claudeTools.map(\.name))
        #expect(names.contains("logSpend") && !names.contains(RehearseFlags.tool))
        ClaudeSees.$moneyWrites.withValue(false) {
            #expect(!TessTools.claudeTools.contains { $0.name == "logSpend" })
            #expect(ClaudeSees.keepsOnPhone(true) && !ClaudeSees.keepsOnPhone(false))
        }
        #expect(!ClaudeSees.keepsOnPhone(true))
    }

    @Test func aSpendAskOnThePurseGoesToClaudeWithItsCall() {
        let spend = ToolPicker.pick("I spent 12 on lunch", frame: purse())
        #expect(spend.tools.first == "logSpend" && spend.bound == nil, "\(spend.tools)")
        #expect(spend.plan.ladder != [.appleOnDevice], "\(spend.plan.ladder)")
        ClaudeSees.$moneyWrites.withValue(false) {
            let kept = ToolPicker.pick("I spent 12 on lunch", frame: purse())
            #expect(kept.tools == ["logSpend"] && kept.plan.ladder == [.appleOnDevice])
        }
    }

    @Test func herClaudeRungLogsASpendAsAGhostRow() async throws {
        let frame = purse()
        let ask = "I spent 12 on lunch"
        let pick = ToolPicker.pick(ask, frame: frame)
        let use = helper.use("t1", "logSpend", #"{"amount":12,"note":"lunch"}"#)
        var brains: [BrainID: any Brain] = [:]
        for id in pick.plan.ladder {
            brains[id] = ScriptedBrain(id, rounds: [[use], [.text("Logged 12 for lunch")]])
        }
        let r = try helper.rig(brains)
        let spends = try r.engine.store.objects(of: #require(r.engine.classes[.spend])).count
        let events = await helper.collect(r.run.ask(ask, frame: frame))
        let ghosts = events.compactMap { event -> UUID? in
            if case let .ghost(id) = event {
                id
            } else {
                nil
            }
        }
        #expect(ghosts.count == 1, "\(events)")
        #expect(try r.engine.store.objects(of: #require(r.engine.classes[.spend])).count == spends + 1)
        let record = try #require(r.engine.history(limit: 1).first)
        #expect(record.state == .pending && record.id == ghosts.first)
    }
}

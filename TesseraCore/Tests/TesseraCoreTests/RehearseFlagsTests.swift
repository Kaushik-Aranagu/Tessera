import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/ai/harness/rehearsal.md section 2: a bulk or structural ask is rehearsed on a copy first; a small one and a
/// bound command never are. And the test world scores "rehearsed, then acted correctly".
@MainActor
struct RehearseFlagsTests {
    @Test func bulkAndStructuralAsksAreFlaggedAndSmallOnesAreNot() {
        for ask in ["Move all my chores to tomorrow", "move everything to tomorrow",
                    "Log 5 sets of 100 kg for 5 on bench", "log six sets of squats", "pause each of my routines",
                    "push the rest of my tasks to Monday"]
        {
            #expect(RehearseFlags.reason(ask) == .bulk, "\(ask)")
        }
        for ask in ["Swap bench for incline in my plan", "add a section for snacks to my groceries list",
                    "reorder my list"]
        {
            #expect(RehearseFlags.reason(ask) == .structural, "\(ask)")
        }
        for ask in ["Log 100 kg for 5 on bench", "remind me in 5 days to call the dentist",
                    "plant a routine to journal every day", "Add eggs and oats to the groceries list",
                    "Move taking out the trash to tomorrow", "log 3 sets of rows"]
        {
            #expect(RehearseFlags.reason(ask) == nil, "\(ask)")
        }
        #expect(RehearseFlags.count("move my 5 tasks to tomorrow") == 5)
        #expect(RehearseFlags.count("log six sets") == 6)
        #expect(RehearseFlags.count("Log 100 kg for 5 on bench") == nil)
    }

    @Test func theRehearsalLeadsAnOpenBulkPickAndNeverABoundOrLookOne() throws {
        let looks = ElementLooksTests()
        let bulk = ToolPicker.pick("could you move my 5 tasks over to tomorrow please", frame: looks.deckFrame())
        #expect(bulk.bound == nil && bulk.rehearse == .bulk && bulk.count == 5)
        #expect(bulk.tools.first == RehearseFlags.tool)
        let look = ToolPicker.pick("I don't like this dial, what would be better here", frame: looks.deckFrame())
        #expect(look.rehearse == nil && !look.tools.contains(RehearseFlags.tool))
        let small = ToolPicker.pick("could you tell me something nice about my training please",
                                    frame: looks.deckFrame())
        #expect(small.rehearse == nil && small.count == nil)
    }

    @Test func theRehearseLineRidesOnlyWhenThePhoneHasTheTool() throws {
        let helper = TessRunTests()
        let r = try helper.rig([:])
        let frame = ElementLooksTests().deckFrame()
        let pick = ToolPicker.pick("could you move all my tasks over to tomorrow please", frame: frame)
        let pack = r.run.pack(about: [], screen: nil, withTools: true, frame: frame, pick: pick)
        let hasTool = pack.tools.contains { $0.name == RehearseFlags.tool }
        #expect(pack.fragments.contains { $0.text.contains("Rehearse first") } == hasTool)
        #expect(RehearseFlags.line(.bulk, count: 5).contains("He named 5"))
    }

    @Test func theWorldScoresTheRehearsalBeforeTheWrite() throws {
        let key = EvalWorldKey(EvalWorld.make())
        let chores = try #require(key.questions().first { $0.id == "rehearse/all-chores" })
        #expect(key.score(chores, reply: "Moved", toolsCalled: ["rehearse", "rescheduleTask"]).passed)
        // Wrote first, then rehearsed: not rehearsed first.
        #expect(!key.score(chores, reply: "Moved", toolsCalled: ["rescheduleTask", "rehearse"]).passed)
        #expect(!key.score(chores, reply: "Moved", toolsCalled: ["rescheduleTask"]).passed)
        // A failed count writes nothing; a small ask is never rehearsed.
        let miscount = try #require(key.questions().first { $0.id == "rehearse/miscount" })
        #expect(miscount.turns == ["Move my 6 chores to tomorrow"])
        #expect(!key.score(miscount, reply: "Moved", toolsCalled: ["rehearse", "rescheduleTask"]).passed)
        let one = try #require(key.questions().first { $0.id == "rehearse/one-chore" })
        #expect(!key.score(one, reply: "Moved", toolsCalled: ["rehearse", "rescheduleTask"]).passed)
        // Every rehearse case's ask is flagged by the picker's words, except the one that must not be.
        for question in key.questions() where question.kind == .rehearse {
            let flagged = RehearseFlags.reason(question.turns.last ?? "") != nil
            #expect(flagged == !question.neverTools.contains(RehearseFlags.tool), "\(question.id)")
        }
        #expect(EvalWorldKey.inOrder(["a", "b"], ["a", "x", "b"]) && !EvalWorldKey.inOrder(["a", "b"], ["b", "a"]))
    }
}

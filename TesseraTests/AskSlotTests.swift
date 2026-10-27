import Foundation
@testable import Tessera
import Testing

/// Kitchen hunt 26 and QA on #995: a reply's UNDO takes back only the capture that reply reported.
struct AskSlotTests {
    let first = UUID(), second = UUID()

    @Test func aFirstCaptureCanBeUndoneWetOrDry() {
        #expect(AskSlot.captureUndo(reply: first, pending: first, last: nil) == .discard)
        #expect(AskSlot.captureUndo(reply: first, pending: nil, last: first) == .undo)
    }

    @Test func backToBackCapturesNeverReachTheEarlierOne() {
        // The second reply is up while the first has just dried: UNDO drops the second's ghost, never the first.
        #expect(AskSlot.captureUndo(reply: second, pending: second, last: first) == .discard)
        #expect(AskSlot.captureUndo(reply: second, pending: nil, last: first) == nil)
    }

    @Test func aQuestionsAnswerAndAGoneCaptureHaveNoUndo() {
        #expect(AskSlot.captureUndo(reply: nil, pending: nil, last: first) == nil)
        #expect(AskSlot.captureUndo(reply: first, pending: nil, last: nil) == nil)
    }

    @Test func theAnswerPathsCarryTheirOwnCapture() {
        // A set-count or dated-lift answer lands like a capture; its line carries that capture's id.
        #expect(AskSlot.captureUndo(reply: second, pending: second, last: nil) == .discard)
    }

    /// Design on #995: a capture's UNDO says what it took back, from that reply's own words.
    @Test func aCapturesUndoSaysTakenBack() {
        #expect(UndoCopy.takenBack(after: "Call Mum, Thursday 7 pm") == "Call Mum, taken back")
        #expect(UndoCopy.takenBack(after: "Milk, on Groceries") == "Milk, taken back")
    }
}

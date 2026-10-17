@testable import Tessera
import TesseraCore
import Testing

/// K86.12 and K86.13: the Lists context line and a run's state word.
@MainActor
struct ListsCopyTests {
    @Test func theContextLineIsACountWithNoRun() {
        #expect(ListsCopy.context(lists: 2) == "2 lists")
        #expect(ListsCopy.context(lists: 1) == "1 list")
        #expect(!ListsCopy.context(lists: 2).contains("running"))
    }

    @Test func runningAppearsOnlyWhileARunIsOpen() {
        #expect(ListsCopy.context(lists: 2, running: 1) == "2 lists, 1 running")
    }

    @Test func theStateWordUsesAComma() {
        #expect(ListsCopy.runState(left: 2) == "RUNNING, 2 LEFT")
        #expect(!ListsCopy.runState(left: 2).contains("·") && !ListsCopy.runState(left: 2).contains("."))
    }

    @Test func tessSaysWhatsLeft() {
        #expect(ListsCopy.tess(list: "Packing", left: 2) == "Packing has 2 left.")
        #expect(ListsCopy.tess(list: "Packing", left: 1) == "Packing has 1 left.")
        #expect(ListsCopy.tess(list: "Packing", left: 0) == "Packing, nothing left.")
    }

    @Test func theAddReceiptNamesTheThingFirst() {
        #expect(ListsCopy.added("Rice", to: "Packing") == "Rice, on Packing.")
        #expect(ListsCopy.added("Private item", to: "Packing") == "Private item, on Packing.")
        #expect(ListsCopy.cleared(3) == "3 done, cleared.")
    }

    @Test func aKeyClearsTheFieldAndIsNeverWritten() {
        let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)
        var wrote = false
        let attempt = ListsCopy.add(fake) { _ in wrote = true; return nil }
        #expect(!wrote && attempt.draft.isEmpty && attempt.line == claudeKeyLine && attempt.record == nil)
    }

    @Test func anotherFailureKeepsTheTypedText() {
        let attempt = ListsCopy.add("rice ") { _ in nil }
        #expect(attempt.draft == "rice " && attempt.line == "Didn't save that. Try again.")
    }

    @Test func aBlankDraftClears() {
        var wrote = false
        let attempt = ListsCopy.add("   \n") { _ in wrote = true; return nil }
        #expect(!wrote && attempt.draft.isEmpty && attempt.line == nil)
    }

    @Test func aRemoveNamesTheThingFirstAndUndoSaysWhereItWent() {
        #expect(ListsCopy.removed("Rice") == "Rice, removed.")
        #expect(ListsCopy.backOn("Rice", list: "Packing") == "Rice, back on Packing.")
        #expect(ListsCopy.removed(ShopTrip.privateLabel) == "Private item, removed.")
        // Stored text is often lowercase; the line still leads with a capital (Kitchen 10.9 on #786).
        #expect(ListsCopy.removed("rice") == "Rice, removed.")
        #expect(ListsCopy.backOn("rice", list: "Packing") == "Rice, back on Packing.")
    }

    @Test func removeRisesFrom60AndIsWholeAt96() {
        #expect(SwipeToRemove.reveal(-40) == 0)
        #expect(SwipeToRemove.reveal(-60) == 0)
        #expect(SwipeToRemove.reveal(-78) == 0.5)
        #expect(SwipeToRemove.reveal(-96) == 1 && SwipeToRemove.reveal(-120) == 1)
    }
}

@testable import Tessera
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
}

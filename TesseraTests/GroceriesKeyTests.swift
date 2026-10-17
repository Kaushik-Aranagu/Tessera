@testable import Tessera
import Testing

/// Design on #700: a planned cook's GROCERIES key shows only while something is left to buy.
@MainActor
struct GroceriesKeyTests {
    @Test func showsWhileThereIsSomethingToBuy() {
        #expect(NowPage.showsGroceriesKey(toBuy: 2))
    }

    @Test func hiddenAtNothingToBuy() {
        #expect(!NowPage.showsGroceriesKey(toBuy: 0))
        #expect(!NowPage.showsGroceriesKey(toBuy: nil))
    }
}

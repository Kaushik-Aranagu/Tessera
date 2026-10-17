@testable import Tessera
import Testing

/// A planned cook's key on Home: GROCERIES while something is left to buy (Design on #700); at zero COOK (K87, C8,
/// B6), held back while cook mode isn't built (G55).
@MainActor
struct GroceriesKeyTests {
    @Test func groceriesWhileThereIsSomethingToBuy() {
        #expect(NowPage.cookKey(toBuy: 2, cookModeReady: true) == .groceries)
        #expect(NowPage.cookKey(toBuy: 2, cookModeReady: false) == .groceries)
    }

    @Test func cookAtNothingToBuy() {
        #expect(NowPage.cookKey(toBuy: 0, cookModeReady: true) == .cook)
        #expect(NowPage.cookKey(toBuy: nil, cookModeReady: true) == .cook)
    }

    @Test func noKeyAtZeroUntilCookModeLands() {
        #expect(NowPage.cookKey(toBuy: 0, cookModeReady: false) == .none)
    }
}

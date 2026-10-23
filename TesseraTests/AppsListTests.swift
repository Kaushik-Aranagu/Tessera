import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct AppsListTests {
    @Test func everyAppFromCoreInItsOrder() {
        #expect(AppSummaryApp.allCases.map(AppsListRows.home) == [.training, .kitchen, .routines, .tasks, .notes,
                                                                  .lists, .money])
    }

    @Test func theListWrapsRoundInBothDirections() {
        #expect(AppsListRows.wrapped(0, -1, count: 6) == 5)
        #expect(AppsListRows.wrapped(5, 1, count: 6) == 0)
        #expect(AppsListRows.wrapped(2, 0, count: 6) == 2)
        #expect(AppsListRows.wrapped(1, -8, count: 6) == 5)
    }

    @Test func theAppsListShipsOn() {
        #expect(FeatureFlagStore.shippedOff.contains("homeAppsList") == false)
    }
}

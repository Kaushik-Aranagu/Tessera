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

    @Test func aLongFactIsCutAtAWordEdgeWithNoEllipsis() {
        let cut = AppsListRows.fit("Push A at 6:15 pm, bench first, then rows and curls", limit: 30)
        #expect(!cut.contains("…") && !cut.hasSuffix("..."))
        #expect(cut.count <= 30 && "Push A at 6:15 pm, bench first, then rows".hasPrefix(cut))
        #expect(AppsListRows.fit("Rent is due Friday") == "Rent is due Friday")
    }

    @Test func aRowKeepsItsPlaceInTheRingAsTheMiddleMoves() {
        #expect(AppsListRows.relative(3, middle: 3, count: 7) == 0)
        #expect(AppsListRows.relative(4, middle: 3, count: 7) == 1)
        #expect(AppsListRows.relative(2, middle: 3, count: 7) == -1)
        #expect(AppsListRows.relative(0, middle: 6, count: 7) == 1)
        #expect(AppsListRows.relative(6, middle: 0, count: 7) == -1)
    }
}

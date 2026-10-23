import Foundation
@testable import Tessera
import Testing
import TesseraCore

@MainActor
struct AppsListTests {
    @Test func everyAppInEdgeOrderWithAQuietLineWhenItHasNothing() {
        let rows = AppsListRows.make(HomeSentence.Inputs())
        #expect(rows.map(\.app) == AppEdges.order)
        #expect(rows.allSatisfy { $0.summary == AppsListRows.quiet })
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

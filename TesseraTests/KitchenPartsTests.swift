import Foundation
@testable import Tessera
import Testing

@MainActor
struct KitchenPartsTests {
    @Test func aDialLoopsTheNearerWayRound() {
        #expect(KitchenLoop.relative(0, focus: 4, count: 5) == 1)
        #expect(KitchenLoop.relative(4, focus: 0, count: 5) == -1)
        #expect(KitchenLoop.wrapped(4, 1, count: 5) == 0)
        #expect(KitchenLoop.wrapped(0, -1, count: 5) == 4)
    }

    @Test func aFlickMovesExactlyOnePlace() {
        // Up and fast: one place on; down and fast: one back; a short slow lift settles where it is.
        #expect(KitchenLoop.landing(rest: -20, step: 64, velocity: -900, turned: 0, travel: -20) == 1)
        #expect(KitchenLoop.landing(rest: 20, step: 64, velocity: 900, turned: 0, travel: 20) == -1)
        #expect(KitchenLoop.landing(rest: -10, step: 64, velocity: -50, turned: 0, travel: -10) == 0)
        // A slow drag past half a place goes to the nearest.
        #expect(KitchenLoop.landing(rest: -40, step: 64, velocity: -50, turned: 2, travel: -168) == 1)
    }

    @Test func theWheelEndsOnARowBoundary() {
        #expect(FocusWheel<TestItem, EmptyView>.height(others: 4) == 202)
        #expect(FocusWheel<TestItem, EmptyView>.height(others: 9) == 392)
        // Rows tile: a row's top plus its height is the next row's top.
        for place in stride(from: CGFloat(-1), through: 3, by: 0.25) {
            let end = FocusWheel<TestItem, EmptyView>.y(place) + FocusWheel<TestItem, EmptyView>.height(at: place)
            #expect(abs(end - FocusWheel<TestItem, EmptyView>.y(place + 1)) < 0.001)
        }
    }

    @Test func aPlaceIsSpokenWithItsCount() {
        #expect(KitchenLoop.spoken("Fridge", count: 8) == "Fridge, 8 things")
        #expect(KitchenLoop.spoken("Shelf", count: 1) == "Shelf, 1 thing")
    }

    @Test func aReceiptLastsAndTheNewestReplaces() {
        let receipts = KitchenReceipts()
        var undone = 0
        receipts.say("Milk, used up. On To get.") { undone += 1 }
        receipts.say("Eggs, running low.") { undone += 10 }
        #expect(receipts.line?.text == "Eggs, running low.")
        receipts.undo()
        #expect(undone == 10 && receipts.line == nil)
    }

    @Test func caloriesStayHiddenUntilCoreHasATable() {
        #expect(KitchenCalories.isAvailable == false)
    }

    private struct TestItem: Identifiable {
        let id: Int
    }
}

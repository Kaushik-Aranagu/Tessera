import Foundation
import SwiftUI
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

@MainActor
struct PantryRoomCopyTests {
    @Test func theBriefNamesWhatIsLow() {
        #expect(PantryRoomCopy.brief(low: []) == "All good in here.")
        #expect(PantryRoomCopy.brief(low: ["Milk"]) == "Low on milk.")
        #expect(PantryRoomCopy.brief(low: ["Milk", "Eggs"]) == "Low on milk and eggs.")
        #expect(PantryRoomCopy.brief(low: ["Milk", "Eggs", "Feta", "Rice"]) == "Low on milk, eggs and feta.")
        #expect(PantryRoomCopy.toGetBrief(["Milk", "Eggs", "Feta", "Rice", "Oil"]) == "Milk and eggs, and 3 more.")
        #expect(PantryRoomCopy.toGetBrief([]) == "Nothing to get.")
    }

    @Test func theSectionLineAndPagesAreCounted() {
        #expect(PantryRoomCopy.section(low: 2, toUse: 1) == "2 low, 1 to use soon")
        #expect(PantryRoomCopy.section(low: 0, toUse: 0) == "Nothing low")
        #expect(PantryRoomCopy.pageCount(0) == 1)
        #expect(PantryRoomCopy.pageCount(5) == 1)
        #expect(PantryRoomCopy.pageCount(6) == 2)
        #expect(PantryRoomCopy.toGetWord(5) == "5 to get")
    }

    @Test func pinsComeFirstThenLow() {
        let a = UUID(), b = UUID(), c = UUID()
        func item(_ id: UUID, low: Bool, pinned: Bool) -> PantryRoomItem {
            PantryRoomItem(id: id, name: "x", isLow: low, isPinned: pinned, amount: nil, source: .added)
        }
        let out = PantryRoomCopy.ordered([item(a, low: false, pinned: false), item(b, low: true, pinned: false),
                                          item(c, low: false, pinned: true)], pinOrder: [c])
        #expect(out.map(\.id) == [c, b, a])
    }
}

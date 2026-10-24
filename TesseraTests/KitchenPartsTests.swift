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
        for focus in [CGFloat(50), 80] {
            for place in stride(from: CGFloat(-1), through: 3, by: 0.25) {
                let end = FocusWheel<TestItem, EmptyView>.y(place, focusHeight: focus)
                    + FocusWheel<TestItem, EmptyView>.height(at: place, focusHeight: focus)
                #expect(abs(end - FocusWheel<TestItem, EmptyView>.y(place + 1, focusHeight: focus)) < 0.001)
            }
        }
        #expect(FocusWheel<TestItem, EmptyView>.height(others: 4, focusHeight: 80) == 232)
        #expect(FocusWheel<TestItem, EmptyView>.height(others: 9, focusHeight: 80) == 422)
    }

    @Test func theWheelBlursByDistanceAndNeverOnTheFocus() {
        typealias Wheel = FocusWheel<TestItem, EmptyView>
        #expect(Wheel.blurRadius(at: 0) == 0)
        #expect(abs(Wheel.blurRadius(at: 1) - 0.65) < 0.001)
        #expect(abs(Wheel.blurRadius(at: -1) - 0.65) < 0.001)
        #expect(Wheel.blurRadius(at: 2) == 1 && Wheel.blurRadius(at: 5) == 1)
        #expect(Wheel.blurs(switchOn: true, reduceMotion: false, reduceTransparency: false, lowPower: false))
        #expect(!Wheel.blurs(switchOn: false, reduceMotion: false, reduceTransparency: false, lowPower: false))
        #expect(!Wheel.blurs(switchOn: true, reduceMotion: true, reduceTransparency: false, lowPower: false))
        #expect(!Wheel.blurs(switchOn: true, reduceMotion: false, reduceTransparency: true, lowPower: false))
        #expect(!Wheel.blurs(switchOn: true, reduceMotion: false, reduceTransparency: false, lowPower: true))
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
        let plainID = UUID(), lowID = UUID(), pinnedID = UUID()
        func item(_ id: UUID, low: Bool, pinned: Bool) -> PantryRoomItem {
            PantryRoomItem(id: id, name: "x", shown: "x", isLow: low, isPinned: pinned, amount: nil, source: .added)
        }
        let out = PantryRoomCopy.ordered(
            [item(plainID, low: false, pinned: false), item(lowID, low: true, pinned: false),
             item(pinnedID, low: false, pinned: true)],
            pinOrder: [pinnedID]
        )
        #expect(out.map(\.id) == [pinnedID, lowID, plainID])
    }
}

@MainActor
struct KitchenTextTests {
    @Test func aLongNameShortensWithoutAnEllipsis() {
        let name = "Extra virgin cold pressed olive oil from the south"
        let short = KitchenText.short(name)
        #expect(short.count <= 20 && !short.contains("…") && !short.contains("..."))
        #expect(KitchenText.short("Milk") == "Milk")
        #expect(KitchenText.short("Supercalifragilisticexpialidocious", limit: 12).count == 12)
    }

    @Test func theBriefNeverNamesAPrivateThing() {
        // The brief is built from shown labels, so a walled name reads as the label.
        #expect(PantryRoomCopy.brief(low: ["Private item"]) == "Low on private item.")
    }
}

@MainActor
struct RecipesRoomBoardTests {
    private func item(_ name: String, minutes: Int?, shorts: [String] = [], lows: [String] = [],
                      pinned: Bool = false) -> RecipesRoomBoard.Item
    {
        RecipesRoomBoard.Item(id: UUID(), name: name, shown: name, isPrivate: false, minutes: minutes,
                              isPinned: pinned, shorts: shorts, lows: lows, uses: ["a", "b", "c", "d", "e", "f"],
                              plannedFor: nil)
    }

    @Test func quickestFirstPinsOnTopNoTimeLast() {
        let slow = item("Stew", minutes: 90), quick = item("Rice", minutes: 20), none = item("Toast", minutes: nil)
        let pinned = item("Dal", minutes: 45)
        let out = RecipesRoomBoard.ordered([slow, none, quick, pinned], pinOrder: [pinned.id])
        #expect(out.map(\.name) == ["Dal", "Rice", "Stew", "Toast"])
    }

    @Test func theSecondDetailLineSaysWhatItNeedsFirst() {
        #expect(RecipesRoomBoard.detail(shorts: ["feta"], lows: ["milk"], uses: []) == "needs feta")
        #expect(RecipesRoomBoard.detail(shorts: ["feta", "oil"], lows: [], uses: []) == "needs feta and oil")
        #expect(RecipesRoomBoard.detail(shorts: ["a", "b", "c"], lows: [], uses: []) == "needs a and 2 more")
        #expect(RecipesRoomBoard.detail(shorts: [], lows: ["milk"], uses: ["x"]) == "milk low")
        #expect(RecipesRoomBoard
            .detail(shorts: [], lows: [], uses: ["a", "b", "c", "d", "e", "f"]) == "a, b and 4 more")
    }

    @Test func aPrivateRecipeIsNeverNamedInTheBrief() {
        let rice = item("Fried rice", minutes: 20)
        let secret = RecipesRoomBoard.Item(id: UUID(), name: "Melatonin tea", shown: "Private recipe", isPrivate: true,
                                           minutes: 30, isPinned: false, shorts: [], lows: ["honey"], uses: [],
                                           plannedFor: nil)
        let lines = RecipesRoomBoard.brief([rice, secret])
        #expect(!lines.first.contains("Melatonin") && !lines.second.contains("Melatonin"))
        #expect(lines.second == "")
    }

    @Test func theFootFollowsTheFocus() {
        #expect(RecipesRoomBoard.footWord(shorts: 0) == "Cook now")
        #expect(RecipesRoomBoard.footWord(shorts: 1) == "Get it")
        #expect(RecipesRoomBoard.footWord(shorts: 2) == "Get 2 things")
        #expect(RecipesRoomBoard.getReceipt(["feta", "mascarpone"]) == "Feta and mascarpone, on To get.")
    }

    @Test func aBriefOfOnlyPrivateRecipesNamesNone() {
        let secret = RecipesRoomBoard.Item(id: UUID(), name: "Melatonin tea", shown: "Private recipe", isPrivate: true,
                                           minutes: 30, isPinned: false, shorts: [], lows: ["honey"], uses: [],
                                           plannedFor: nil)
        let lines = RecipesRoomBoard.brief([secret, secret])
        #expect(lines.first == "Nothing is ready yet." && lines.second == "")
    }

    @Test func theBriefNamesTheQuickestAndWhatUsesTheLow() {
        let rice = item("Fried rice", minutes: 20)
        let pasta = item("Lemon pasta", minutes: 25, lows: ["lemons"])
        let lines = RecipesRoomBoard.brief([rice, pasta])
        #expect(lines.first == "Fried rice is the quickest, 20 min.")
        #expect(lines.second == "Lemon pasta uses the lemons.")
        #expect(RecipesRoomBoard.sectionLine(.ready, count: 7) == "7 you can make now, quickest first")
    }

    @Test func anUntimedPublicRecipeWinsOverThePrivateFallback() {
        let secret = RecipesRoomBoard.Item(id: UUID(), name: "Melatonin tea", shown: "Private recipe", isPrivate: true,
                                           minutes: 5, isPinned: true, shorts: [], lows: ["honey"], uses: [],
                                           plannedFor: nil)
        let lines = RecipesRoomBoard.brief([secret, item("Toast", minutes: nil)])
        #expect(lines.first == "Toast is ready.")
        #expect(lines.second.isEmpty)
    }

    @Test func privateLowIngredientsDoNotReplaceThePublicSecondLine() {
        let secret = RecipesRoomBoard.Item(id: UUID(), name: "Melatonin tea", shown: "Private recipe", isPrivate: true,
                                           minutes: nil, isPinned: true, shorts: [], lows: ["honey"], uses: [],
                                           plannedFor: nil)
        let lines = RecipesRoomBoard.brief([secret, item("Rice", minutes: 20),
                                            item("Pasta", minutes: 25, lows: ["lemons"])])
        #expect(lines.first == "Rice is the quickest, 20 min.")
        #expect(lines.second == "Pasta uses the lemons.")
        let empty = RecipesRoomBoard.brief([])
        #expect(empty.first == "Nothing is ready yet." && empty.second.isEmpty)
    }
}

@MainActor
struct PantryPackerTests {
    private func sections(_ rows: [Int], urgent: [Int]? = nil, height: CGFloat = 34) -> [PantryPacker.Section] {
        rows.enumerated().map { index, count in
            PantryPacker.Section(title: "S\(index)", rows: count, height: height, urgent: urgent?[index] ?? 0)
        }
    }

    @Test func aColumnHoldsWholeSectionsThatFitWithTheirGap() {
        // 26 + 6 x 34 = 230 fits a column; the next section does not fit beside it.
        let packer = PantryPacker(sections: sections([6, 1, 2]))
        #expect(packer.columns[0].map(\.section) == [0])
        // 26 + 34 = 60, a gap of 18 and 26 + 68 = 94: 172 in all.
        #expect(packer.columns[1].map(\.section) == [1, 2])
        #expect(packer.columns[1].reduce(0) { $0 + $1.height } + PantryPacker.gap == 172)
    }

    @Test func twoSectionsAlwaysTakeBothColumns() {
        let packer = PantryPacker(sections: sections([1, 1]))
        #expect(packer.columns[0].map(\.section) == [0])
        #expect(packer.columns[1].map(\.section) == [1])
        let single = PantryPacker(sections: sections([1, 1]), columnCount: 1)
        #expect(single.columns.count == 1 && single.columns[0].map(\.section) == [0, 1])
    }

    @Test func aSectionTooBigForAColumnSplitsWithAMoreRow() {
        // Header 26 + the "more" row 26 leaves 180: five rows of 34 (170) fit.
        let packer = PantryPacker(sections: sections([20]))
        let block = packer.columns[0][0]
        #expect(block.count == 5 && block.more == 15 && block.height == 26 + 5 * 34 + 26)
        #expect(packer.nextLine == "Next: the rest of S0")
    }

    @Test func rowsOfDifferentHeightsAreAddedUp() {
        // 28 pt rows hold more of them than 34 pt rows do.
        let tall = PantryPacker(sections: sections([20], height: 34)).columns[0][0].count
        let short = PantryPacker(sections: sections([20], height: 28)).columns[0][0].count
        #expect(short > tall)
    }

    @Test func theEntrySectionIsTheFirstLowOne() {
        let packer = PantryPacker(sections: sections([2, 2, 2], urgent: [0, 1, 0]))
        #expect(packer.columns[0][0].section == 1)
    }

    @Test func swipingContinuesASplitThenPacksOnAndStopsWhenNothingIsLeft() {
        var packer = PantryPacker(sections: sections([20, 2]))
        let first = packer.columns[0][0].count
        let moved = packer.advance()
        #expect(moved)
        #expect(packer.columns[0][0].start == first)
        var moves = 0
        while packer.advance() {
            moves += 1; if moves > 30 {
                break
            }
        }
        #expect(moves < 30)
        let stuck = packer.advance()
        #expect(stuck == false)
    }

    @Test func backGoesUpToSixSteps() {
        var packer = PantryPacker(sections: sections([60]))
        for _ in 0 ..< 8 {
            packer.advance()
        }
        var back = 0
        while packer.back() {
            back += 1
        }
        #expect(back == 6)
    }

    @Test func aHeaderIsSpokenWithItsCountAndLow() {
        let packer = PantryPacker(sections: [.init(title: "Dairy and eggs", rows: 5, height: 34, urgent: 2)])
        #expect(packer.spokenHeader(packer.columns[0][0]) == "Dairy and eggs, 5, 2 low")
    }
}

@MainActor
struct PantryRowLayoutTests {
    @Test func aShortValueSitsBesideTheNameAtTheDefaultSize() {
        let fit = PantryRowLayout.fit(name: "Eggs", value: "half", column: 170)
        #expect(fit.beside && fit.height == 28)
    }

    @Test func aLongValueDropsBelowAndTheRowGrowsToThirtyFour() {
        let fit = PantryRowLayout.fit(name: "Spinach leaves", value: "2 left, by Sunday evening", column: 120)
        #expect(!fit.beside && fit.height == 34)
    }

    @Test func aRowWithNoValueIsTwentyEight() {
        #expect(PantryRowLayout.fit(name: "Milk", value: nil, column: 170).height == 28)
    }

    @Test func rowsGrowWithTheTextSize() {
        let base = PantryRowLayout.fit(name: "Spinach leaves", value: "2 left, by Sunday", column: 120)
        let ax1 = PantryRowLayout.fit(name: "Spinach leaves", value: "2 left, by Sunday", column: 120, scale: 1.6,
                                      large: true)
        let ax3 = PantryRowLayout.fit(name: "Spinach leaves", value: "2 left, by Sunday", column: 120, scale: 2.2,
                                      large: true)
        #expect(ax1.height > base.height && ax3.height > ax1.height)
    }

    @Test func aTurnedLowThingOffersTheNudge() {
        let receipts = KitchenReceipts()
        var asked = 0
        receipts.say("Butter, low.", undo: nil, action: ("Add to To get", { asked += 1 }))
        receipts.line?.action?.run()
        #expect(asked == 1 && receipts.line?.action?.title == "Add to To get")
    }
}

@MainActor
struct PantryTouchTests {
    private let bounds = CGRect(x: 0, y: 0, width: 160, height: 232)

    @Test func physicalTapOwnershipStopsAtEveryTargetEdge() {
        let size = CGSize(width: 169, height: 28)
        #expect(PantryTouch.accepts(CGPoint(x: 0, y: 0), in: size))
        #expect(PantryTouch.accepts(CGPoint(x: 168.9, y: 27.9), in: size))
        for point in [CGPoint(x: -2, y: 14), CGPoint(x: 171, y: 14),
                      CGPoint(x: 80, y: -1), CGPoint(x: 80, y: 28)]
        {
            #expect(!PantryTouch.accepts(point, in: size))
        }
        #expect(!PantryTouch.accepts(.zero, in: .zero))
    }

    @Test(arguments: [CGFloat(28), 34])
    func overlappingCompactTargetsBothUseTheFallback(_ height: CGFloat) {
        let rows = [CGRect(x: 0, y: 30, width: 160, height: height),
                    CGRect(x: 0, y: 30 + height, width: 160, height: height)]
        #expect(PantryTouch.target(for: 0, rows: rows, protected: [], bounds: bounds) == nil)
        #expect(PantryTouch.target(for: 1, rows: rows, protected: [], bounds: bounds) == nil)
    }

    @Test func anIsolatedTargetReachesExactlyFortyFourWithoutCrossingControls() {
        let rows = [CGRect(x: 0, y: 40, width: 160, height: 28)]
        let target = PantryTouch.target(for: 0, rows: rows, protected: [], bounds: bounds)
        #expect(target == CGRect(x: 0, y: 32, width: 160, height: 44))
        let header = CGRect(x: 0, y: 14, width: 160, height: 26)
        #expect(PantryTouch.target(for: 0, rows: rows, protected: [header], bounds: bounds) == nil)
        let more = CGRect(x: 0, y: 68, width: 160, height: 26)
        #expect(PantryTouch.target(for: 0, rows: rows, protected: [more], bounds: bounds) == nil)
    }

    @Test func theColumnClipCannotTruncateAReachTarget() {
        for y in [CGFloat(0), 204] {
            let rows = [CGRect(x: 0, y: y, width: 160, height: 28)]
            #expect(PantryTouch.target(for: 0, rows: rows, protected: [], bounds: bounds) == nil)
        }
    }

    @Test func fullSizedRowsKeepExactSharedBoundaries() {
        let rows = [CGRect(x: 0, y: 26, width: 160, height: 44),
                    CGRect(x: 0, y: 70, width: 160, height: 44)]
        #expect(PantryTouch.target(for: 0, rows: rows, protected: [], bounds: bounds) == rows[0])
        #expect(PantryTouch.target(for: 1, rows: rows, protected: [], bounds: bounds) == rows[1])
    }
}

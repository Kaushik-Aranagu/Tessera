import Foundation
@testable import Tessera
import Testing

struct MosaicPagerTests {
    private let mosaic = CGRect(x: 100, y: 200, width: 248, height: 160)

    @Test func aSwipeFromTheMosaicOrNearItChangesThePage() {
        #expect(MosaicPager.accepts(start: CGPoint(x: 200, y: 280), translation: CGSize(width: -60, height: 5),
                                    mosaic: mosaic))
        // Within 30 pt of its edge counts; further out does not.
        #expect(MosaicPager.accepts(start: CGPoint(x: 75, y: 280), translation: CGSize(width: 60, height: 0),
                                    mosaic: mosaic))
        #expect(!MosaicPager.accepts(start: CGPoint(x: 60, y: 280), translation: CGSize(width: 60, height: 0),
                                     mosaic: mosaic))
    }

    @Test func aShortOrMostlyVerticalDragIsNotASwipe() {
        #expect(!MosaicPager.accepts(start: CGPoint(x: 200, y: 280), translation: CGSize(width: 40, height: 0),
                                     mosaic: mosaic))
        #expect(!MosaicPager.accepts(start: CGPoint(x: 200, y: 280), translation: CGSize(width: 50, height: 80),
                                     mosaic: mosaic))
    }

    @Test func leftIsNextRightIsPreviousAndItWrapsRound() {
        var pager = MosaicPager(count: 3)
        #expect(pager.swipe(dx: -60) && pager.index == 1)
        #expect(pager.swipe(dx: -60) && pager.index == 2)
        #expect(pager.swipe(dx: -60) && pager.index == 0)
        #expect(pager.swipe(dx: 60) && pager.index == 2)
    }

    @Test func withOnePageNothingChanges() {
        var pager = MosaicPager()
        #expect(!pager.swipe(dx: -80) && pager.index == 0)
    }

    @Test func twoMinutesAwayPutsItBackOnTheMoodPage() {
        var pager = MosaicPager(count: 3)
        pager.swipe(dx: -60)
        let start = Date()
        pager.leave(at: start)
        pager.returned(at: start.addingTimeInterval(60))
        #expect(pager.index == 1)
        pager.leave(at: start)
        pager.returned(at: start.addingTimeInterval(121))
        #expect(pager.index == 0)
    }
}

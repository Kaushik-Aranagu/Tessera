import CoreGraphics
@testable import Tessera
import Testing

struct OneThingSwipeTests {
    @Test func theOldCardIsTheOneThatLeaves() throws {
        // Next (left): card 1 leaves, card 2 comes in; the widget is never left holding nothing.
        let next = try #require(OneThingSwipe.step(index: 1, count: 4, dx: -80))
        #expect(next.leaving == 1)
        #expect(next.entering == 2)
        let previous = try #require(OneThingSwipe.step(index: 1, count: 4, dx: 80))
        #expect(previous.leaving == 1)
        #expect(previous.entering == 0)
    }

    @Test func theWidgetIsNeverEmptyAcrossManySwipes() {
        var index = 0
        let count = 3
        for swipe in 0 ..< 20 {
            let dx: CGFloat = swipe.isMultiple(of: 3) ? 90 : -90
            guard let step = OneThingSwipe.step(index: index, count: count, dx: dx) else { continue }
            #expect(step.leaving == index)
            #expect(step.entering != step.leaving)
            #expect((0 ..< count).contains(step.entering))
            index = step.entering
        }
    }

    @Test func wrapsAndIgnoresTwitches() throws {
        let wrapNext = try #require(OneThingSwipe.step(index: 2, count: 3, dx: -60))
        #expect(wrapNext.entering == 0)
        let wrapBack = try #require(OneThingSwipe.step(index: 0, count: 3, dx: 60))
        #expect(wrapBack.entering == 2)
        #expect(OneThingSwipe.step(index: 0, count: 3, dx: -30) == nil)
        #expect(OneThingSwipe.step(index: 0, count: 1, dx: -90) == nil)
    }
}

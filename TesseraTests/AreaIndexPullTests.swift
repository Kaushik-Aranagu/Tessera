import Foundation
@testable import Tessera
import Testing

/// Kaushik, release 21: pulling down opened the index but let go on whatever row was under the finger (Kitchen from a
/// low start, Today from a high one), and dragging back up closed it. The selection now follows the finger's travel
/// from where the index formed.
struct AreaIndexPullTests {
    @Test func theIndexFormsOverTheFirstNinetyPointsAndStaysOpen() {
        var pull = AreaIndexPull()
        #expect(pull.progress(translation: 10) == 0)
        #expect(pull.progress(translation: 55) == 0.5)
        #expect(!pull.isFormed)
        #expect(pull.picked(translation: 55, current: 1, count: 4) == nil)
        #expect(pull.progress(translation: 95) == 1)
        #expect(pull.isFormed)
        // Dragging back toward the start no longer un-forms it.
        #expect(pull.progress(translation: 30) == 1)
        #expect(pull.progress(translation: -200) == 1)
    }

    @Test func theAreaYouAreInIsUnderTheFingerWhenItForms() {
        var pull = AreaIndexPull()
        _ = pull.progress(translation: 120)
        // A flick that first reports 120 still anchors at 90: 30 pt on is half a row, which stays put.
        #expect(pull.picked(translation: 90, current: 1, count: 4) == 1)
        #expect(pull.picked(translation: 90, current: 3, count: 4) == 3)
        #expect(pull.picked(translation: 119, current: 1, count: 4) == 1)
    }

    @Test func anyRowIsReachableFromAnyStartingHeight() {
        var pull = AreaIndexPull()
        _ = pull.progress(translation: 100)
        // In Today (1), anchored at 90: down two rows is Kitchen, up one is Review, and travel past the ends stops
        // there.
        #expect(pull.picked(translation: 210, current: 1, count: 4) == 3)
        #expect(pull.picked(translation: 30, current: 1, count: 4) == 0)
        #expect(pull.picked(translation: 900, current: 1, count: 4) == 3)
        #expect(pull.picked(translation: -900, current: 1, count: 4) == 0)
        // Training from Today: one row down.
        #expect(pull.picked(translation: 150, current: 1, count: 4) == 2)
    }

    @Test func aNewPullStartsFresh() {
        var pull = AreaIndexPull()
        _ = pull.progress(translation: 100)
        pull = AreaIndexPull()
        #expect(!pull.isFormed)
        #expect(pull.progress(translation: 0) == 0)
    }
}

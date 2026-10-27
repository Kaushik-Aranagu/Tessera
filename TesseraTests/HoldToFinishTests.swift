import CoreGraphics
@testable import Tessera
import Testing

@Suite("Workout mode: hold to finish")
struct HoldToFinishTests {
    @Test("The hold is 600 ms and the clip widens linearly across it")
    func fraction() {
        #expect(HoldToFinish.duration == 0.6)
        #expect(HoldToFinish.fraction(elapsed: 0) == 0)
        #expect(abs(HoldToFinish.fraction(elapsed: 0.3) - 0.5) < 1e-9)
        #expect(HoldToFinish.fraction(elapsed: 0.6) == 1)
        #expect(HoldToFinish.fraction(elapsed: 2) == 1)
        #expect(HoldToFinish.fraction(elapsed: -1) == 0)
    }

    @Test("It completes only after the whole 600 ms")
    func completes() {
        #expect(!HoldToFinish.isComplete(elapsed: 0.59))
        #expect(HoldToFinish.isComplete(elapsed: 0.6))
    }

    @Test("Moving more than 10 pt cancels; 10 pt or less does not")
    func cancels() {
        #expect(!HoldToFinish.shouldCancel(moved: 0))
        #expect(!HoldToFinish.shouldCancel(moved: 10))
        #expect(HoldToFinish.shouldCancel(moved: 10.5))
    }
}

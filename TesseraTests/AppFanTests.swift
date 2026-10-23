@testable import Tessera
import Testing

@MainActor
struct AppFanTests {
    @Test func opensOnlyPastTwentyFourPoints() {
        #expect(!FanMath.isOpen(pull: 0))
        #expect(!FanMath.isOpen(pull: 24))
        #expect(FanMath.isOpen(pull: 24.5))
    }

    @Test func releaseBelowTheFirstTitleCloses() {
        #expect(FanMath.release(pull: 10, count: 4) == nil)
        #expect(FanMath.release(pull: 24, count: 4) == nil)
        #expect(FanMath.release(pull: 30, count: 4) == 3)
    }

    @Test func titleUnderFingerRisesWithThePull() {
        let step = FanMath.step
        #expect(FanMath.index(under: 25, count: 4) == 3)
        #expect(FanMath.index(under: 24 + step + 1, count: 4) == 2)
        #expect(FanMath.index(under: 24 + 3 * step + 1, count: 4) == 0)
        #expect(FanMath.index(under: 5000, count: 4) == 0)
        #expect(FanMath.index(under: 100, count: 0) == nil)
    }

    @Test func dragMustBeginInTheBottomForty() {
        #expect(FanMath.begins(atDistanceFromBottom: 0))
        #expect(FanMath.begins(atDistanceFromBottom: 40))
        #expect(!FanMath.begins(atDistanceFromBottom: 41))
    }

    @Test func staggerIsThirtyFiveMilliseconds() {
        #expect(FanMath.delay(row: 3, count: 4) == 0)
        #expect(abs(FanMath.delay(row: 2, count: 4) - 0.035) < 1e-9)
    }

    @Test func switchDefaultsOff() {
        let choice = ReviewChoices.all.first { $0.id == "homeV2" }
        #expect(choice == nil || choice?.defaultValue == "Off")
        #expect(!FanSwitch.isOn)
    }
}

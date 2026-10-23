import Foundation
@testable import Tessera
import Testing

struct ThingEntranceTests {
    @Test func tiersAreStaggeredAndSettleByHalfASecondPlusTheirDelay() {
        #expect(ThingEntrance.tier(0, elapsed: 0) == 0)
        #expect(ThingEntrance.tier(2, elapsed: 0.16) == 0)
        #expect(ThingEntrance.tier(0, elapsed: 0.5) == 1)
        #expect(ThingEntrance.tier(2, elapsed: 0.66) == 1)
        #expect(ThingEntrance.tierOffset(1, elapsed: 0) == 10)
        #expect(ThingEntrance.tierOffset(1, elapsed: 1) == 0)
    }

    @Test func boardDigitsTurnOverOneAfterAnother() {
        #expect(ThingEntrance.flipScale(0, elapsed: 0) == 0.08)
        #expect(ThingEntrance.flipScale(0, elapsed: 0.15) == 0.08)
        #expect(ThingEntrance.flipScale(0, elapsed: 0.3) == 1)
        #expect(ThingEntrance.flipScale(3, elapsed: 0.2) == 0.08)
        #expect(ThingEntrance.flipScale(3, elapsed: 0.8) == 1)
    }

    @Test func groceryItemsDropOneTenthOfASecondApartAndOvershootOnce() throws {
        #expect(!ThingEntrance.dropVisible(2, elapsed: 0.2))
        #expect(ThingEntrance.dropVisible(2, elapsed: 0.22))
        #expect(ThingEntrance.dropOffset(0, elapsed: 1) == 0)
        let samples = stride(from: 0.0, through: 0.32, by: 0.01).map { ThingEntrance.dropOffset(0, elapsed: $0) }
        #expect(samples.contains { $0 > 0 }, "a small overshoot below its place")
        #expect(try #require(samples.max()) < 3)
    }

    @Test func aTaskTitleWritesInSteps() {
        #expect(ThingEntrance.written(elapsed: 0) == 0)
        #expect(ThingEntrance.written(elapsed: 0.9) == 1)
        let share = ThingEntrance.written(elapsed: 0.45)
        #expect(share == 0.5)
        #expect((share * 24).truncatingRemainder(dividingBy: 1) == 0)
    }

    @Test func aCountTicksUpFromZero() {
        #expect(ThingEntrance.count(to: 8, elapsed: 0) == 0)
        #expect(ThingEntrance.count(to: 8, elapsed: 0.8) == 8)
        #expect(ThingEntrance.count(to: 8, elapsed: 0.2) < 8)
        #expect(ThingEntrance.signOffset(elapsed: 0) == 12)
        #expect(ThingEntrance.signOffset(elapsed: 1) == 0)
    }
}

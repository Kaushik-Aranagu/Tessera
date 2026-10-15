@testable import Tessera
import Testing

struct PlateMathTests {
    @Test func eightyTwoPointFiveLoads25And5And1Point25() {
        #expect(PlateMath.perSide(82.5) == [25, 5, 1.25])
    }

    @Test func barAloneNeedsNoPlates() {
        #expect(PlateMath.perSide(20).isEmpty)
        #expect(PlateMath.perSide(0).isEmpty)
    }

    @Test(arguments: [
        (60.0, [20.0]),
        (100.0, [25.0, 15.0]),
        (142.5, [25.0, 25.0, 10.0, 1.25]),
        (182.5, [25.0, 25.0, 25.0, 5.0, 1.25]),
    ])
    func perSideIsHeaviestFirst(weight: Double, expected: [Double]) {
        #expect(PlateMath.perSide(weight) == expected)
    }

    @Test func differentBarShiftsTheLoad() {
        #expect(PlateMath.perSide(35, bar: 15) == [10])
    }

    @Test func unloadableWeightDropsTheRemainder() {
        // 61.25 → 20.625 per side: 20 fits, 0.625 does not.
        #expect(PlateMath.perSide(61.25) == [20])
    }

    @Test(arguments: [
        (61.25, 62.5),
        (61.0, 60.0),
        (82.5, 82.5),
        (83.0, 82.5),
        (84.0, 85.0),
        (10.0, 20.0),
        (20.0, 20.0),
    ])
    func nearestLoadableWeight(weight: Double, expected: Double) {
        #expect(PlateMath.nearestLoadable(weight) == expected)
    }

    @Test func nearestLoadableIsMadeExactlyByThePlates() {
        for tenth in stride(from: 200, through: 3000, by: 7) {
            let loadable = PlateMath.nearestLoadable(Double(tenth) / 10)
            let total = 20 + 2 * PlateMath.perSide(loadable).reduce(0, +)
            #expect(abs(total - loadable) < 1e-9)
        }
    }
}

import Foundation
import Testing

struct LoadFactorTests {
    @Test func theLoadFactorIsMeasuredAndWithinItsBounds() {
        let raw = LoadFactor.measuredMilliseconds()
        let factor = LoadFactor.current()
        // The raw figure is printed so the idle baseline can be checked on a quiet Mac: factor ~ 1 when idle.
        print("LOAD FACTOR raw=\(raw)ms idle=\(LoadFactor.idleMilliseconds)ms factor=\(factor)")
        #expect(raw > 0 && factor >= 1 && factor <= LoadFactor.cap)
    }
}

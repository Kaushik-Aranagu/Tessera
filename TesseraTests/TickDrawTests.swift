import Foundation
@testable import Tessera
import Testing

@Suite("Workout mode: the drawn tick")
struct TickDrawTests {
    @Test("The tick takes 260 ms and starts 380 ms after the rest ends")
    func timing() {
        #expect(TickDraw.duration == 0.26)
        #expect(TickDraw.delay == 0.38)
        #expect(TickDraw.progress(elapsed: 0) == 0)
        #expect(TickDraw.progress(elapsed: 0.38) == 0)
        #expect(abs(TickDraw.progress(elapsed: 0.51) - 0.5) < 1e-9)
        #expect(TickDraw.progress(elapsed: 0.64) == 1)
        #expect(TickDraw.progress(elapsed: 5) == 1)
    }

    @Test("The short stroke takes the first third and the long stroke the rest")
    func split() {
        #expect(TickDraw.short(at: 0) == 0 && TickDraw.long(at: 0) == 0)
        #expect(abs(TickDraw.short(at: 1.0 / 6.0) - 0.5) < 1e-9)
        #expect(TickDraw.short(at: 1.0 / 3.0) == 1)
        #expect(TickDraw.long(at: 1.0 / 3.0) == 0)
        #expect(abs(TickDraw.long(at: 2.0 / 3.0) - 0.5) < 1e-9)
        #expect(TickDraw.short(at: 1) == 1 && TickDraw.long(at: 1) == 1)
    }

    @Test("The drawn tick's short stroke is about a third of its length")
    func geometry() {
        #expect(abs(TickDraw.drawnShortShare - TickDraw.shortShare) < 0.03)
    }

    @Test("The long stroke only starts once the short one is whole")
    func order() {
        for step in 0 ... 100 {
            let progress = Double(step) / 100
            if TickDraw.long(at: progress) > 0 {
                #expect(TickDraw.short(at: progress) == 1)
            }
        }
    }
}

import CoreGraphics
@testable import Tessera
import Testing

/// Polish batch 1: sheet 302 (the back pull resists), sheet 299 (ink goes last timing) and sheet 298 (held-back
/// arrivals).
struct PolishOneTests {
    @Test func theBackPullAnswersFullyUpTo72() {
        for pull in stride(from: CGFloat(0), through: 72, by: 4) {
            #expect(ShellBack.resisted(pull) == pull)
        }
    }

    @Test func between72And80ThePageAnswersAt70Percent() {
        // 4 pt of finger moves the page 2.8 pt.
        #expect(abs((ShellBack.resisted(76) - ShellBack.resisted(72)) - 2.8) < 1e-9)
        #expect(abs((ShellBack.resisted(80) - ShellBack.resisted(72)) - 5.6) < 1e-9)
    }

    @Test func pastTheCommitItFollowsTheFingerAgain24Behind() {
        #expect(abs(ShellBack.resisted(80) - 77.6) < 1e-9)
        #expect(abs((ShellBack.resisted(100) - ShellBack.resisted(90)) - 10) < 1e-9)
        #expect(abs(ShellBack.resisted(120) - 117.6) < 1e-9)
    }

    @Test func theResistanceNeverMovesTheCommitPoint() {
        #expect(!ShellBack.commits(CGSize(width: 80, height: 0)))
        #expect(ShellBack.commits(CGSize(width: 80.5, height: 0)))
        #expect(!ShellBack.commits(CGSize(width: 79, height: 0)))
    }

    @Test func inkGoesLast() {
        // The ground is gone by 200 ms; the ink has not started to go until 60 ms and is gone by 280 ms.
        #expect(LookInk.groundAlpha(at: 0) == 1)
        #expect(LookInk.groundAlpha(at: 0.2) == 0)
        #expect(LookInk.inkAlpha(at: 0.06) == 1)
        #expect(LookInk.inkAlpha(at: 0.05) == 1)
        #expect(LookInk.inkAlpha(at: 0.28) == 0)
        #expect(LookInk.groundAlpha(at: 0.1) < LookInk.inkAlpha(at: 0.1))
        #expect(LookInk.groundAlpha(at: 0.15) < LookInk.inkAlpha(at: 0.15))
        // All done by 320 ms.
        #expect(LookInk.whole >= LookInk.inkDelay + LookInk.inkFade)
        #expect(LookInk.whole == 0.32)
    }

    @Test func anArrivingThingIsHeldBackUntilItsArrivalStarts() {
        let held = EdgeRollPass(overflow: 1, arriving: true)
        let seen = EdgeRollPass(overflow: 1, arriving: false)
        #expect(held.arriving)
        #expect(!seen.arriving)
    }
}

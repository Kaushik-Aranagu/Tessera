import CoreGraphics
@testable import Tessera
import Testing

@Suite("Workout mode: the eraser band")
struct EraserBandTests {
    @Test("The wipe is 460 ms and the haze is 66 pt at 7% white")
    func constants() {
        #expect(EraserBand.duration == 0.46)
        #expect(EraserBand.hazeWidth == 66)
        #expect(EraserBand.hazeAlpha == 0.07)
    }

    @Test("Ease in-out starts at 0, ends at 1, is half at the middle and slow at both ends")
    func easing() {
        #expect(EraserBand.eased(0) == 0)
        #expect(EraserBand.eased(1) == 1)
        #expect(abs(EraserBand.eased(0.5) - 0.5) < 1e-9)
        #expect(EraserBand.eased(0.1) < 0.1)
        #expect(EraserBand.eased(0.9) > 0.9)
        #expect(EraserBand.eased(-1) == 0 && EraserBand.eased(2) == 1)
    }

    @Test("At the start nothing is erased; at the end all of it is, slant included")
    func edges() {
        let start = EraserBand.edge(time: 0, width: 400)
        #expect(start.top == 0 && start.bottom == -EraserBand.slant)
        let end = EraserBand.edge(time: 1, width: 400)
        #expect(end.bottom == 400 && end.top == 400 + EraserBand.slant)
    }

    @Test("The band only moves right, and leans (top ahead of bottom)")
    func moves() {
        var last = -CGFloat.infinity
        for step in 0 ... 20 {
            let edge = EraserBand.edge(time: Double(step) / 20, width: 400)
            #expect(edge.bottom >= last)
            #expect(edge.top - edge.bottom == EraserBand.slant)
            last = edge.bottom
        }
    }

    @Test("The haze holds 7% for four fifths, then fades to nothing")
    func haze() {
        #expect(EraserBand.hazeOpacity(time: 0) == 0.07)
        #expect(EraserBand.hazeOpacity(time: 0.79) == 0.07)
        #expect(abs(EraserBand.hazeOpacity(time: 0.9) - 0.035) < 1e-9)
        #expect(EraserBand.hazeOpacity(time: 1) == 0)
    }

    @Test("What remains of the old board is right of the line, and empty at the end")
    func remaining() {
        let size = CGSize(width: 400, height: 300)
        let whole = EraserBand.remaining(time: 0, size: size).boundingRect
        #expect(whole.minX <= 0 && whole.maxX >= 400)
        let none = EraserBand.remaining(time: 1, size: size).boundingRect
        #expect(none.minX >= 400)
    }
}

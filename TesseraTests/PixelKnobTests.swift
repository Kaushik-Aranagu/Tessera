import Foundation
@testable import Tessera
import Testing

/// The Settings knob (sheet 203): nine pixels in sixteen points, a notch that goes round a quarter at a time.
struct PixelKnobTests {
    @Test func theKnobIsNinePixelsInsideSixteenPoints() {
        #expect(PixelKnobShape.pixels.count == 9)
        #expect(PixelKnobShape.frame == 16)
        for pixel in PixelKnobShape.pixels {
            let corner = PixelKnobShape.origin(column: pixel.column, row: pixel.row)
            #expect(corner.x >= 0 && corner.y >= 0)
            #expect(corner.x + PixelKnobShape.side <= 16 + 1e-9 && corner.y + PixelKnobShape.side <= 16 + 1e-9)
        }
        // Squares of 3.2 pt on the 4 pt step, three across: twelve points of dial in sixteen.
        #expect(PixelKnobShape.side == 3.2 && PixelKnobShape.step == 4)
        let first = PixelKnobShape.origin(column: 0, row: 0), last = PixelKnobShape.origin(column: 2, row: 2)
        #expect(abs((last.x - first.x) - 8) < 1e-9)
    }

    @Test func theNotchGoesRoundAQuarterAtATime() {
        let spots = (0 ..< 5).map { PixelKnobShape.notch(turns: $0) }
        #expect(spots[0] == (1, 0) && spots[1] == (2, 1) && spots[2] == (1, 2) && spots[3] == (0, 1))
        #expect(spots[4] == spots[0])
        #expect(PixelKnobShape.notch(turns: -1) == (0, 1))
        // Always an edge pixel of the ring, never the centre.
        for turns in 0 ..< 8 {
            let spot = PixelKnobShape.notch(turns: turns)
            #expect(!(spot.column == 1 && spot.row == 1))
        }
    }

    @Test func itTurnsOnItsOwnOnceAMinute() {
        #expect(PixelKnobShape.selfTurnSeconds == 60)
    }
}

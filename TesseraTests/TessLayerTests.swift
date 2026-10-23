import Foundation
@testable import Tessera
import Testing

/// Tess on her own layer (sheet 209): where she sits, how long she pools, how her thoughts advance.
struct TessLayerTests {
    @Test func sheSitsInTheBottomRightCornerInA96PointCanvasWithNoStandingLine() {
        #expect(TessLayerShape.canvas == 96 && TessLayerShape.roomHeight == 80)
        #expect(TessLayerShape.trailing == 14 && TessLayerShape.bottom == 14)
        let origin = TessLayerShape.origin(screenWidth: 402, screenHeight: 874)
        #expect(origin.x == 402 - 14 - 96 && origin.y == 874 - 14 - 96)
        // A line stays up six seconds and goes back in.
        #expect(TessLayerShape.lineSeconds == 6)
    }

    @Test func aTapPoolsHerOverOnePointEightSecondsAndMovesToTheNextThought() {
        #expect(TessLayerShape.poolSeconds == 1.8)
        #expect(TessLayerShape.next(after: 0, count: 3) == 1)
        #expect(TessLayerShape.next(after: 2, count: 3) == 0)
        #expect(TessLayerShape.next(after: 0, count: 0) == 0)
    }
}

import Foundation
@testable import Tessera
import Testing

/// Tess on her own layer (sheet 209): where she sits, how long she pools, how her thoughts advance.
struct TessLayerTests {
    @Test func sheDrawsInA96PointCanvasAtTheTopOfAnEightyPointRoomTwentyTwoFromTheEdge() {
        #expect(TessLayerShape.canvas == 96 && TessLayerShape.roomHeight == 80 && TessLayerShape.leading == 22)
        let origin = TessLayerShape.origin(screenHeight: 874, bottomInset: 34)
        #expect(origin.x == 22 && origin.y == 874 - 34 - 80)
    }

    @Test func aTapPoolsHerOverOnePointEightSecondsAndMovesToTheNextThought() {
        #expect(TessLayerShape.poolSeconds == 1.8)
        #expect(TessLayerShape.next(after: 0, count: 3) == 1)
        #expect(TessLayerShape.next(after: 2, count: 3) == 0)
        #expect(TessLayerShape.next(after: 0, count: 0) == 0)
    }
}

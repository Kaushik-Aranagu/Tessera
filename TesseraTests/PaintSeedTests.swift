import CoreGraphics
@testable import Tessera
import Testing

/// Paint marks take any seed, hash values included (a negative seed once indexed a jitter array below zero).
struct PaintSeedTests {
    @Test(arguments: [0, 3, -1, -7, Int.min, Int.max])
    func anySeedDrawsAMark(seed: Int) {
        let rect = CGRect(x: 0, y: 0, width: 18, height: 15)
        #expect(!DabShape(seed: seed).path(in: rect).isEmpty)
        #expect(!InkStroke(seed: seed).path(in: rect).isEmpty)
    }
}

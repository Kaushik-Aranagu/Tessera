import CoreGraphics
@testable import Tessera
import Testing

struct WrapsWithinTests {
    @Test func aLabelWiderThanTheColumnTakesTheColumn() {
        #expect(WrapsWithinFit.width(natural: 520, column: 358) == 358)
    }

    @Test func aLabelThatFitsKeepsItsOwnWidth() {
        #expect(WrapsWithinFit.width(natural: 200, column: 358) == nil)
        #expect(WrapsWithinFit.width(natural: 520, column: nil) == nil)
    }

    @Test func theWriteVeilRisesOnlyUnderTheField() {
        #expect(CommandVeil.paperOpacity(writing: true) == 0.94)
        #expect(CommandVeil.paperOpacity(writing: false) == 0.5)
    }
}

@testable import Tessera
import Testing

/// decisions 5:57: an empty cell that must show something says "none", never a lone dash.
struct EmptyCellTests {
    @Test func anEmptyCellSaysNone() {
        #expect(ObjectCopy.cell(nil) == "none")
        #expect(ObjectCopy.cell("82.5") == "82.5")
        #expect(!ObjectCopy.none.contains("\u{2014}") && !ObjectCopy.none.contains("\u{2013}"))
    }
}

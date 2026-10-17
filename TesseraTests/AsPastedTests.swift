@testable import Tessera
import Testing

/// Kitchen gap hunt G4: AS PASTED shows only when there is text he pasted.
@MainActor
struct AsPastedTests {
    @Test func hiddenWithNoSource() {
        #expect(RecipeCopy.pasted(nil) == nil)
        #expect(RecipeCopy.pasted("") == nil)
        #expect(RecipeCopy.pasted("  \n ") == nil)
    }

    @Test func shownWithPastedText() {
        #expect(RecipeCopy.pasted("2 eggs\nwhisk") == "2 eggs\nwhisk")
    }
}

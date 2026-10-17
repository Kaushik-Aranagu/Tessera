@testable import Tessera
import TesseraCore
import Testing

/// #86 R3: tap-to-fix always cycles ingredient → step → ignore → ingredient, even for a line that won't read as an
/// ingredient, and never touches the title.
struct PasteCycleTests {
    @Test func aLineThatWontParseStillReachesStep() {
        // "Serve hot" marked ingredient reads back as ignored (it won't parse), but the next tap is still step.
        #expect(PasteCopy.nextReading(after: "ingredient", current: .ignored) == "step")
        #expect(PasteCopy.nextReading(after: "step", current: .step(text: "x", timers: [])) == "ignore")
        #expect(PasteCopy.nextReading(after: "ignore", current: .ignored) == "ingredient")
        #expect(PasteCopy.nextReading(after: nil, current: .ignored) == "ingredient")
        #expect(PasteCopy.nextReading(after: nil, current: .title) == nil)
        #expect(PasteCopy.nextReading(after: nil, current: .heading) == nil)
    }

    /// G54: a bare link reads as nothing to keep, so Save isn't drawn; a read recipe can be saved.
    @Test func saveIsDrawnOnlyWhenSomethingWasRead() {
        #expect(!PasteCopy.canSave(CreateRecipe.lines(of: "https://example.com/shakshuka", corrections: [:])))
        #expect(PasteCopy.canSave(CreateRecipe.lines(of: "Dal\n1 cup lentils\nSimmer 20 minutes", corrections: [:])))
        #expect(PasteCopy.didntSave == "Didn't save that. Try again.")
    }
}

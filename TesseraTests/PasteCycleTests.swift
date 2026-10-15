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
}

@testable import Tessera
import TesseraCore
import Testing

/// K87.11 (Product 8:20 AM): a key-shaped string in a paste is cut out and the rest of the recipe kept; it's never
/// echoed, and the line says Review.
@MainActor
struct PasteKeyTests {
    /// Made up here, so nothing key-shaped sits in the file.
    private let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)

    @Test func theKeyGoesAndTheRecipeStays() {
        let paste = "Weeknight dal\n2 cups lentils \(fake)\n\(fake)\n\nSimmer 20 minutes."
        let kept = PasteCopy.withoutKeys(paste)
        #expect(!looksLikeClaudeKey(kept) && !kept.contains("xxxxxxxx"))
        #expect(kept.contains("Weeknight dal") && kept.contains("2 cups lentils") && kept
            .contains("Simmer 20 minutes"))
    }

    @Test func aKeyAloneLeavesNothing() {
        #expect(PasteCopy.withoutKeys(fake) == "")
    }

    @Test func theLineSaysSettings() {
        #expect(claudeKeyLine.contains("Settings"))
    }

    /// The cut's own change keeps the key line up and reads the kept recipe (QA on #767).
    @Test func theKeyLineSurvivesTheCutsOwnChange() {
        var filter = PasteKeyFilter()
        let paste = "Weeknight dal\n2 cups lentils\n\(fake)\n\nSimmer 20 minutes."
        guard case let .cut(kept) = filter.change(old: "", new: paste) else {
            Issue.record("expected a cut")
            return
        }
        #expect(filter.change(old: paste, new: kept) == .keptAfterCut(read: true))
        // The next ordinary edit is plain again.
        #expect(filter.change(old: kept, new: kept + " ") == .plain(read: false))
    }

    @Test func aKeyWrappedAcrossALineComesOutWhole() {
        // A made-up key whose second half wrapped onto the next line, as a long key does in a paste.
        let wrapped = "Dal\n" + "sk-" + "ant-" + "x1x1x1x1x1x1x1x1\nx2x2x2x2x2x2x2x2\nSimmer."
        let kept = PasteCopy.withoutKeys(wrapped)
        #expect(!looksLikeClaudeKey(kept) && !kept.contains("x1x1") && !kept.contains("x2x2"))
        #expect(kept.contains("Dal") && kept.contains("Simmer"))
    }
}

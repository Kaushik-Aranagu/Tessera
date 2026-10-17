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
        #expect(kept == "Weeknight dal\n2 cups lentils\n\nSimmer 20 minutes.")
    }

    @Test func aKeyAloneLeavesNothing() {
        #expect(PasteCopy.withoutKeys(fake) == "")
    }

    @Test func theLineSaysReview() {
        #expect(claudeKeyLine.contains("Review"))
    }
}

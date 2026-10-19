@testable import Tessera
import Testing

/// Product ruling: offline, a capture the walls stopped keeps his words in the Ask for the retry.
struct AskCopyTests {
    @Test func theOfflineLineKeepsTheDraft() {
        #expect(AskCopy.keepsDraft("Couldn't read that offline. Try again online."))
        #expect(!AskCopy.keepsDraft("Milk, on Groceries."))
    }
}

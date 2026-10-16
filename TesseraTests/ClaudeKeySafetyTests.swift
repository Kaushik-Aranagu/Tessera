@testable import Tessera
import Testing

/// A Claude key never becomes a task or a recipe (Research, master 4518c48).
struct ClaudeKeySafetyTests {
    @Test func askRecognisesAKeyInAnyCaseAndPosition() {
        #expect(BottomChrome.looksLikeClaudeKey("sk-ant-api03-FAKE-a1B2"))
        #expect(BottomChrome.looksLikeClaudeKey("best SK-ANT-api03-FAKE?"))
        #expect(!BottomChrome.looksLikeClaudeKey("bench best?"))
    }

    @Test func keyWordsReadTheStatus() {
        #expect(ClaudeKeyWords.status("works") == "works")
        #expect(ClaudeKeyWords.status("capReached") == "works")
        #expect(ClaudeKeyWords.status("notAllowed") == "not allowed")
        #expect(ClaudeKeyWords.status("accountPaused") == "account paused")
        #expect(ClaudeKeyWords.status(nil) == "not checked")
        #expect(ClaudeKeyWords.dollars(1_200_000_000) == "$1.20")
        #expect(ClaudeKeyWords.dollars(1) == "$0.01")
    }
}

import Foundation
@testable import Tessera
import TesseraTess
import Testing

/// G647: Remove is two steps, "Remove the Claude key?" then Remove or Keep it. Remove deletes at once and nothing
/// keeps a copy, so there is no UNDO.
@MainActor
struct KeyRemoveTests {
    /// A made-up key, built here so nothing key-shaped sits in the file.
    private let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)

    @Test func removeKeyIsTwoStepAndHoldsNothing() {
        #expect(KeyRemove.question == "Remove the Claude key?")
        #expect(KeyRemove.removeWord == "Remove")
        #expect(KeyRemove.keepWord == "Keep it")
        let keys = InMemoryKeychain(fake)
        let line = KeyRemove.remove(from: keys)
        #expect(line == "Claude key removed. Everything stays on this phone.")
        #expect(keys.read() == nil, "a call right after Remove would still find the key")
        #expect(!line.contains("sk-"))
    }

    /// A Keychain that won't let go: the line says so, never the receipt.
    @Test func aKeyThatStaysSaysSo() {
        let keys = StuckKeychain(fake)
        #expect(KeyRemove.remove(from: keys) == "I couldn't remove the key. Try again?")
    }

    @Test func removingWithNoKeyIsStillTheReceipt() {
        #expect(KeyRemove.remove(from: InMemoryKeychain(nil)) == KeyRemove.receipt)
    }

    /// Product 3:58 PM: with no key, Settings says "No Claude key yet."; no part of a key shows either way.
    @Test func theNoKeyLineIsPlain() {
        #expect(ClaudeKeyWords.noKey == "No Claude key yet.")
        #expect(!ClaudeKeyWords.noKey.contains("Paste"))
    }
}

private struct StuckKeychain: TessKeychain {
    let key: String
    init(_ key: String) {
        self.key = key
    }

    func read() -> String? {
        key
    }

    func save(_: String) -> Bool {
        true
    }

    func delete() {}
}

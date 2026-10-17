import Foundation
@testable import Tessera
import TesseraTess
import Testing

/// Kitchen gap hunt G10: once REMOVE is tapped, no Claude job may find the key, even inside UNDO's 10 s.
@MainActor
struct KeyRemovalTests {
    /// A made-up key, built here so nothing key-shaped sits in the file.
    private let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)

    @Test func removeTakesTheKeyOutAtOnce() {
        let keys = InMemoryKeychain(fake)
        let held = KeyRemoval.take(from: keys)
        #expect(held != nil)
        #expect(keys.read() == nil, "a call due in the window would still find the key")
    }

    @Test func undoPutsTheSameKeyBack() {
        let keys = InMemoryKeychain(fake)
        let held = KeyRemoval.take(from: keys)
        #expect(held?.restore(to: keys) == true)
        #expect(keys.read() == fake)
    }

    @Test func nothingToTakeWithNoKey() {
        let keys = InMemoryKeychain(nil)
        #expect(KeyRemoval.take(from: keys) == nil)
    }
}

import Foundation
@testable import Tessera
import TesseraTess
import Testing

/// Product 12:22 AM Oct 18: Remove is two steps with a plain receipt; nothing holds the key and nothing undoes it.
@MainActor
struct KeyRemovalTests {
    /// A stand-in value; nothing key-shaped sits in this file.
    private let stored = "placeholder value"

    @Test func removeDeletesTheKeyAtOnceAndNothingBringsItBack() {
        let keys = InMemoryKeychain(stored)
        KeyRemoval.remove(from: keys)
        #expect(keys.read() == nil, "a call due right after would find a key")
    }

    @Test func removingWithNoKeyIsHarmless() {
        let keys = InMemoryKeychain(nil)
        KeyRemoval.remove(from: keys)
        #expect(keys.read() == nil)
    }
}

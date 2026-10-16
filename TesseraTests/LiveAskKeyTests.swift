@testable import Tessera
import Testing

/// A Claude key typed or pasted into the workout's ask field is refused, in any case.
struct LiveAskKeyTests {
    @Test(arguments: ["sk-ant-api03-abc", "my key SK-ANT-xyz", "Sk-Ant-1"])
    func keysAreRefused(text: String) {
        #expect(LiveAskField.refuses(text))
    }

    @Test func setsAreNot() {
        #expect(!LiveAskField.refuses("log bench 80x8"))
    }
}

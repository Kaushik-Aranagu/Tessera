import Foundation
@testable import TesseraCore
import Testing

/// Research capture-all-but-key.md KS01 to KS10: the key guard, every shape. The prefix is built from parts.
struct KeyShapeTests {
    static let sk = "sk"
    static let ant = "ant"
    static let pfx = sk + "-" + ant + "-"
    static let fill = "api03-" + "TESTFAKE" + String(repeating: "x", count: 24)

    @Test func everyKeyShapeIsCaught() {
        let keys = [
            Self.pfx + Self.fill, // KS01
            (Self.pfx + Self.fill).uppercased(), // KS02
            "my key is " + Self.pfx + Self.fill + " thanks", // KS03
            "call mom\n" + Self.pfx + Self.fill, // KS04
            Self.pfx + "short", // KS05
            Self.sk + "- " + Self.ant + "-" + Self.fill, // KS06: a space after the first dash
            Self.sk + "-" + Self.ant + Self.fill, // KS07: no last dash
            Self.sk + " - " + Self.ant + " - " + Self.fill, // dictation spacing
        ]
        for key in keys {
            #expect(looksLikeClaudeKey(key), "\(key.prefix(12))")
            #expect(!looksLikeClaudeKey(withoutClaudeKeys(key)), "\(key.prefix(12))")
        }
    }

    @Test func plainPhrasesAreNotKeys() {
        // KS08, KS09 and near misses.
        for phrase in ["could you log bench from earlier?", "put 40 dollars toward the thing for mum", "skant",
                       "sk-and-x", "ask ant about the ski trip", Self.sk + "-" + Self.ant + "s", "desk-antenna"]
        {
            #expect(!looksLikeClaudeKey(phrase), "\(phrase)")
        }
    }
}

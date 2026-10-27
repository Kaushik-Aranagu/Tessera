import Foundation
@testable import TesseraCore
import Testing

/// Input hygiene H1 (docs/ai/harness/input-hygiene.md): a character he never sees can't hide a secret word or a key,
/// and every line the walls caught before is still caught.
struct CanonicalTextTests {
    static let zeroWidth = ["\u{200B}", "\u{200C}", "\u{200D}", "\u{2060}", "\u{FEFF}", "\u{00AD}", "\u{202E}",
                            "\u{2066}", "\u{034F}", "\u{FE0F}"]

    @Test func theCanonicalFormFoldsWhatDrawsTheSame() {
        #expect(CanonicalText.of("ｐａｓｓｗｏｒｄ") == "password")
        #expect(CanonicalText.of("𝐩𝐚𝐬𝐬𝐰𝐨𝐫𝐝") == "password")
        #expect(CanonicalText.of("pass\u{200B}word") == "password")
        #expect(CanonicalText.of("“code” isn’t – here") == "\"code\" isn't - here")
        #expect(CanonicalText.of("a \u{00A0}\t b\r\nc\u{2028}d") == "a b\nc\nd")
        #expect(CanonicalText.of("Bench 80 kg x5") == "Bench 80 kg x5")
    }

    @Test func noInvisibleCharacterHidesASecretWord() {
        for mark in Self.zeroWidth {
            let line = "wifi pass" + mark + "word is tacocat24"
            #expect(SecretWords.mentions(line), "\(mark.unicodeScalars.first?.value ?? 0)")
            #expect(SecretWords.hasValue(line), "\(mark.unicodeScalars.first?.value ?? 0)")
        }
        #expect(SecretWords.mentions("door ｃｏｄｅ 4417"))
        // The phone's keyboard types curly quotes by default.
        #expect(SecretWords.mentions("the “code” is 4417"))
        #expect(SecretWords.isPrivateLine("the “code” is 4417"))
        #expect(SecretWords.cut("Preheat to 350\nthe ‘pin’: 2580").cut == 1)
    }

    @Test func foldingNeverLosesAValue() {
        // A Roman numeral is a number as typed and letters once folded ("pⅰn" becomes "pin", QA on #1470): either
        // reading is enough to wall the line.
        #expect(SecretWords.hasValue("door code p\u{2170}n"))
        #expect(SecretWords.isPrivateLine("door code p\u{2170}n"))
        #expect(SecretWords.isSecretListLine("door code p\u{2170}n"))
        #expect(SecretWords.isPrivateLine("Account # \u{2170}\u{2171}\u{2172}\u{2173}"))
        #expect(SecretWords.cut("Preheat to 350\ndoor code p\u{2170}n").cut == 1)
    }

    @Test func plainLinesStayPlain() {
        for line in ["pinch of salt", "spinach and feta", "PIN the dough", "code 3", "a combination lock",
                     "Bench 80 kg x5", "café crème", "naïve plan"]
        {
            #expect(!SecretWords.isPrivateLine(line), "\(line)")
        }
        #expect(!SecretWords.mentions("pinch of salt") && !SecretWords.mentions("spinach"))
    }

    @Test func noInvisibleOrStyledCharacterHidesAKey() {
        let fill = "api03-" + "TESTFAKE" + String(repeating: "x", count: 24)
        let keys = [
            "sk\u{200B}-ant-" + fill,
            "s\u{200D}k-a\u{00AD}nt-" + fill,
            "ｓｋ－ａｎｔ－" + fill,
            "sk-\u{2060}ant-" + fill,
        ]
        for key in keys {
            #expect(looksLikeClaudeKey(key), "\(key.unicodeScalars.count)")
            #expect(!looksLikeClaudeKey(withoutClaudeKeys("note " + key + " end")), "\(key.unicodeScalars.count)")
        }
        // A note with no key keeps its emoji and spacing exactly.
        let note = "Family dinner 👨‍👩‍👧 at 7  ❤️"
        #expect(withoutClaudeKeys(note) == note)
        for phrase in ["risk\u{200B}-anticipation", "desk–antenna", "ask ant about the ski trip"] {
            #expect(!looksLikeClaudeKey(phrase), "\(phrase)")
        }
    }
}

import Foundation
@testable import TesseraCore
import Testing

/// Input hygiene H2 (docs/ai/harness/input-hygiene.md): one wall with reasons, read on the text as typed and its
/// canonical form. Every line here is a made-up placeholder.
@MainActor
struct WallTests {
    static let key = "sk-ant-api03-" + "TESTFAKE" + String(repeating: "x", count: 24)

    /// Each line and a reason it must carry. Lines come from the rules' own tests, so the wall can't drift from them.
    static let walled: [(String, WallReasons)] = [
        ("my key is " + key, .key),
        ("wifi password is tacocat24", .secret),
        ("door code 4417", .secret),
        ("bought lemons for $4", .money),
        ("bought a tv for 800", .money),
        ("weighed 82 kg for 3 days", .body),
        ("Heart rate day 5x5", .body),
        ("bp 120/80 after 5x5", .body),
        ("burned 400 kcal", .calories),
        ("weighed 82 kg", .privateTitle),
    ]

    static let plain = ["Bench 80 kg x5", "bench 80x5", "pinch of salt", "bought 2 lemons",
                        "bring a stone for the wall", "Push B 5x5 80 for 8", "low calorie yogurt"]

    /// What draws the same but reads differently to a rule: a hidden character or full-width letters.
    static func disguises(_ line: String) -> [String] {
        let wide = String(String.UnicodeScalarView(line.unicodeScalars.map { scalar in
            (0x21...0x7E).contains(scalar.value) ? Unicode.Scalar(scalar.value + 0xFEE0) ?? scalar : scalar
        }))
        var hidden = line
        if let space = hidden.firstIndex(of: " ") {
            hidden.insert(contentsOf: "\u{200B}", at: hidden.index(before: space))
        }
        return [wide, hidden]
    }

    @Test func everyWalledLineCarriesItsReason() {
        for (line, reason) in Self.walled {
            #expect(Wall.judge(line, lastWeightKg: nil).contains(reason), "\(line)")
        }
    }

    @Test func noDisguiseHidesAReason() {
        for (line, reason) in Self.walled {
            for disguised in Self.disguises(line) {
                #expect(Wall.judge(disguised, lastWeightKg: nil).contains(reason), "\(disguised)")
            }
        }
    }

    @Test func plainLinesCarryNoReason() {
        for line in Self.plain {
            #expect(Wall.judge(line, lastWeightKg: nil).isEmpty, "\(line)")
        }
        #expect(Wall.judge("", lastWeightKg: 82).isEmpty)
    }

    /// On a line with nothing to fold, the wall says exactly what each rule says on its own.
    @Test func theWallAgreesWithEachRule() {
        let lines = Self.walled.map(\.0) + Self.plain + ["is 82.4 good?", "82 kg squat", "coffee 7.30 today"]
        for weight in [nil, 82.0] {
            for line in lines where CanonicalText.of(line) == line {
                let reasons = Wall.judge(line, lastWeightKg: weight)
                #expect(reasons.contains(.key) == looksLikeClaudeKey(line), "\(line)")
                #expect(reasons.contains(.secret) == SecretWords.mentions(line), "\(line)")
                #expect(reasons.contains(.money) == PrivateFacts.isMoneyShaped(line), "\(line)")
                #expect(reasons.contains(.body) == PrivateFacts.isBodyShaped(line, lastWeightKg: weight), "\(line)")
                #expect(reasons.contains(.calories) == PrivateFacts.isCalorieShaped(line), "\(line)")
                let title = ObjectPrivacy.isPrivateTitle(line, lastWeightKg: weight)
                #expect(reasons.contains(.privateTitle) == title, "\(line)")
                // The old pair the Door and the Home moments used is the union of two reasons.
                let pair = PrivateFacts.isWalled(line, lastWeightKg: weight)
                #expect(!reasons.isDisjoint(with: [.money, .body]) == pair, "\(line)")
            }
        }
    }

    @Test func theLastWeighInIsABodyFact() {
        #expect(Wall.judge("is 82.4 good?", lastWeightKg: 82).contains(.body))
        #expect(!Wall.judge("82 kg squat", lastWeightKg: 82).contains(.body))
    }

    @Test func theStoreAddsPrivateWords() {
        let store = ObjectStore.open(inMemory: true)
        #expect(!Wall.judge("ozempic-run at 7", lastWeightKg: nil).contains(.privateWord))
        #expect(Wall.judge("ozempic-run at 7", in: store).contains(.privateWord))
        #expect(Wall.judge("ozem\u{200B}pic-run at 7", in: store).contains(.privateWord))
        #expect(!Wall.judge("bench 80x5", in: store).contains(.privateWord))
    }

    @Test func thePresetsNameTheReasonsTheirCallersUsed() {
        #expect(WallReasons.never == [.key, .secret])
        #expect(WallReasons.strictScan == [.secret, .money, .body, .calories])
        #expect(!WallReasons.strictScan.contains(.privateWord))
    }
}

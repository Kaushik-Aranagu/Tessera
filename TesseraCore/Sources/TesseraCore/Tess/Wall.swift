import Foundation

/// Why a line is private: every reason at once, so a caller walls on exactly the reasons it names.
public struct WallReasons: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// A Claude key, or a line holding one.
    public static let key = WallReasons(rawValue: 1 << 0)
    /// A secret word: a password, PIN, passcode, code or wifi key.
    public static let secret = WallReasons(rawValue: 1 << 1)
    /// Money: an amount, a price, a balance.
    public static let money = WallReasons(rawValue: 1 << 2)
    /// His body or health: a weigh-in, a vital, a symptom, a medicine or a dose.
    public static let body = WallReasons(rawValue: 1 << 3)
    /// A line that logs calories.
    public static let calories = WallReasons(rawValue: 1 << 4)
    /// A title only private things use (title words, a doctor's name, a medicine), as `ObjectPrivacy` reads titles.
    public static let privateTitle = WallReasons(rawValue: 1 << 5)
    /// A word of a private thing in the store.
    public static let privateWord = WallReasons(rawValue: 1 << 6)

    /// Never kept, logged or sent, under either policy.
    public static let never: WallReasons = [.key, .secret]
    /// What strict mode's own scan keeps off a Claude rung (the Door's `strictHit`).
    public static let strictScan: WallReasons = [.secret, .money, .body, .calories]
}

/// The one privacy wall (input-hygiene H2, docs/ai/harness/input-hygiene.md). The rules stay where they are
/// (`SecretWords`, `PrivateFacts`, `ObjectPrivacy`, the key guard); this is where they meet. It reads both the text as
/// typed and its canonical form, so a hidden or styled character never slips a line past a rule, and folding never
/// loses a value one reading still holds. Callers ask for the reasons they wall on (`!judge(...).isDisjoint(with:)`)
/// instead of combining the rules their own way.
public enum Wall {
    /// Every reason `text` is private. `lastWeightKg` is the last weigh-in, or nil with a set in focus, as
    /// `PrivateFacts` asks.
    public static func judge(_ text: String, lastWeightKg: Double?) -> WallReasons {
        guard !text.isEmpty else { return [] }
        var reasons: WallReasons = []
        // These two read both forms already (input-hygiene H1).
        if looksLikeClaudeKey(text) {
            reasons.insert(.key)
        }
        if SecretWords.mentions(text) {
            reasons.insert(.secret)
        }
        let canonical = CanonicalText.of(text)
        for reading in canonical == text ? [text] : [text, canonical] {
            if PrivateFacts.isMoneyShaped(reading) {
                reasons.insert(.money)
            }
            if PrivateFacts.isBodyShaped(reading, lastWeightKg: lastWeightKg) {
                reasons.insert(.body)
            }
            if PrivateFacts.isCalorieShaped(reading) {
                reasons.insert(.calories)
            }
            if ObjectPrivacy.isPrivateTitle(reading, lastWeightKg: lastWeightKg) {
                reasons.insert(.privateTitle)
            }
        }
        return reasons
    }

    /// The same, plus the words of private things in the store.
    @MainActor
    public static func judge(_ text: String, lastWeightKg: Double?, store: ObjectStore) -> WallReasons {
        var reasons = judge(text, lastWeightKg: lastWeightKg)
        guard !text.isEmpty else { return reasons }
        let canonical = CanonicalText.of(text)
        if ObjectPrivacy.containsPrivateWord(text, in: store)
            || canonical != text && ObjectPrivacy.containsPrivateWord(canonical, in: store)
        {
            reasons.insert(.privateWord)
        }
        return reasons
    }

    /// The same, with the last weigh-in read from the store.
    @MainActor
    public static func judge(_ text: String, in store: ObjectStore) -> WallReasons {
        judge(text, lastWeightKg: BodyWeight.lastKg(in: store), store: store)
    }
}

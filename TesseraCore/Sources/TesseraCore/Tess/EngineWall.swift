import Foundation

/// One privacy wall in the engine (board 0ai, Product 2:06 to 2:22 and 4:46 PM PT; Research engine-wall and
/// walls-ui §13): every writer that titles something from words it was handed (the on-device model's and Claude's
/// tool writes, Siri, the grammar) runs them through here before a title is stored. His own words in his own place
/// (the Notes page, "note:", restore, RenameObject) are exempt.
public enum EngineWall {
    public enum TaskOutcome: Equatable, Sendable {
        /// Nothing private: the title as given.
        case keep(String)
        /// Something to do with money and a day: the task without its amount ("pay rent 2100 fri" is "Pay rent").
        case withoutAmount(String)
        /// A medicine reminder with a time: a task titled "Private task".
        case privateTask
        /// A secret with a value, money with no day or a body fact: a private note, dated when it had a day.
        case privateNote
    }

    /// What a task titled `title` becomes.
    @MainActor
    public static func task(_ title: String, startsAt: Date?, store: ObjectStore) -> TaskOutcome {
        if title == ObjectPrivacy.taskLabel {
            return .privateTask
        }
        if SecretWords.hasValue(title) {
            return .privateNote
        }
        if PrivateFacts.isMoneyShaped(title) {
            let bare = withoutAmounts(title)
            return isSomethingToDo(title) && startsAt != nil && !bare.isEmpty ? .withoutAmount(bare) : .privateNote
        }
        if PrivateFacts.isBodyShaped(title, lastWeightKg: BodyWeight.lastKg(in: store)) {
            let medicine = PrivateFacts.medicines.contains { title.lowercased().contains($0) }
                || title.lowercased().firstMatch(of: /\d\s*(?:mg|mcg)\b/) != nil
            return medicine && startsAt != nil ? .privateTask : .privateNote
        }
        return .keep(title)
    }

    /// A list or grocery line with its price taken off (Kitchen 2:09 PM PT): "milk $4" is milk; packs and amounts keep
    /// their numbers ("2 lemons", "500 g flour"). Empty when the line was only money.
    public static func withoutPrice(_ line: String) -> String {
        let stripped = line.replacing(/(?i)\s*(?:for\s+)?[$£€₹¥]\s?\d[\d,]*(?:\.\d+)?/, with: "")
            .replacing(/(?i)\s*(?:for\s+)?\b\d[\d,]*(?:\.\d+)?\s?(?:dollars?|bucks|usd|quid)\b/, with: "")
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    /// The title with its amounts and currency taken off: "Pay rent 2100" is "Pay rent".
    static func withoutAmounts(_ title: String) -> String {
        let stripped = withoutPrice(title).replacing(/\s*\b\d[\d,]*(?:\.\d+)?k?\b/, with: "")
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    /// Opens with something to do: "pay rent", "call the doctor", "venmo sam".
    public static func isSomethingToDo(_ phrase: String) -> Bool {
        phrase.firstMatch(
            of: /^(?i)\s*(?:call|ring|book|schedule|see|email|text|ask|refill|order|buy|get|pick up|todo|to do|remind me|pay|send|transfer|venmo)\b/
        ) != nil
    }
}

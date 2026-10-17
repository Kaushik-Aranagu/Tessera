import Foundation

/// One privacy wall in the engine (board 0ai, Product 2:06 to 2:22 and 4:46 PM PT; Research engine-wall and
/// walls-ui §13): every writer that titles something from words it was handed (the on-device model's and Claude's
/// tool writes, Siri, the grammar) runs them through here before a title is stored. His own words in his own place
/// (the Notes page, "note:", restore, RenameObject) are kept as he wrote them, never retitled; a note that holds money,
/// a secret or a body fact is still marked private (`CreateNote`), so it shows only its label.
public enum EngineWall {
    public enum TaskOutcome: Equatable, Sendable {
        /// Nothing private: the title as given.
        case keep(String)
        /// Something to do with money: the task without its amount ("pay rent 2100 fri" is "Pay rent fri").
        case withoutAmount(String)
        /// A medicine reminder with a time: a task titled "Private task".
        case privateTask
        /// A secret with a value, money that isn't something to do, or a body fact: a private note.
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
        let last = BodyWeight.lastKg(in: store)
        if PrivateFacts.isMoneyShaped(title) {
            let bare = withoutAmounts(title)
            // The rest is judged as it would be stored (AI architecture on #627): "refill lexapro $40 fri" is still a
            // medicine with its price gone.
            if isHealth(bare, lastWeightKg: last) {
                return health(bare, startsAt: startsAt)
            }
            // An imperative is ahead of him whether or not a time came with it (Research BM02: the model's write has
            // no startsAt); "paid rent 2100" is a fact, so a private note.
            return isSomethingToDo(title) && !bare.isEmpty ? .withoutAmount(bare) : .privateNote
        }
        if isHealth(title, lastWeightKg: last) {
            return health(title, startsAt: startsAt)
        }
        return .keep(title)
    }

    /// A medicine, a dose or a body fact (Product 8:13 PM PT: a medicine name is a health fact everywhere).
    public static func isHealth(_ phrase: String, lastWeightKg: Double?) -> Bool {
        isMedicine(phrase) || PrivateFacts.isBodyShaped(phrase, lastWeightKg: lastWeightKg)
    }

    static func isMedicine(_ phrase: String) -> Bool {
        let lower = phrase.lowercased()
        return PrivateFacts.words(lower).contains(where: PrivateFacts.medicines.contains)
            || lower.firstMatch(of: /\d\s*(?:mg|mcg)\b/) != nil
    }

    /// A medicine reminder is a private task, with a time or not: the wall masks the label, not the kind (Product 8:28
    /// PM PT). Anything else of his body is a private note.
    static func health(_ phrase: String, startsAt _: Date?) -> TaskOutcome {
        isMedicine(phrase) ? .privateTask : .privateNote
    }

    /// "pay rent fri" is stored and said as "Pay rent fri".
    static func capitalized(_ bare: String) -> String {
        bare.prefix(1).uppercased() + bare.dropFirst()
    }

    /// A list or grocery line with its price taken off (Kitchen 2:09 PM PT): "milk $4" is milk; packs and amounts keep
    /// their numbers ("2 lemons", "500 g flour"). Empty when the line was only money.
    public static func withoutPrice(_ line: String) -> String {
        let stripped = line.replacing(/(?i)\s*(?:for\s+)?[$£€₹¥]\s?\d[\d,]*(?:\.\d+)?/, with: "")
            .replacing(/(?i)\s*(?:for\s+)?\b\d[\d,]*(?:\.\d+)?\s?(?:dollars?|bucks|usd|quid)\b/, with: "")
            // A bare amount with exactly two places at the end is a price (Product 8:40 AM PT Oct 17): "milk 4.99".
            .replacing(/\s+\d+[.,]\d{2}\s*$/, with: "")
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

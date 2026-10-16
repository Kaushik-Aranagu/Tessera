import Foundation
import TesseraCore

/// The Bar's privacy rules, shared with Siri (Product P14): what stays a private note, what is refused, and what is
/// something to do.
extension TessGrammar {
    /// Opens with something to do: "call the doctor thu", "pay rent 2100 friday", "venmo sam 25".
    static func isSomethingToDo(_ phrase: String) -> Bool {
        phrase.firstMatch(
            of: /^(?i)\s*(?:call|ring|book|schedule|see|email|text|ask|refill|order|buy|get|pick up|todo|to do|remind me|pay|send|transfer|venmo)\b/
        ) != nil
    }

    /// The Bar's privacy rule for a phrase another surface files as a task (Siri's Add a Task; Product P14, board 0l):
    /// a secret with a value, a body fact or a money fact that isn't something to do becomes a private note, and
    /// "remember" with a sum is refused. Nil when it's an ordinary task ("pay rent 2100 friday" stays one, W4).
    public func privateParse(_ phrase: String, context: TessContext) -> Parse? {
        if SecretWords.hasValue(phrase), let secret = parseSecret(
            phrase,
            text: Self.normalize(phrase),
            context: context
        ),
            case .privateNote = secret
        {
            return secret
        }
        if let refused = parseRememberedMoney(phrase) {
            return refused
        }
        guard !Self.isSomethingToDo(phrase), PrivateFacts.isWalled(phrase) else { return nil }
        let body = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return .privateNote(body: body.prefix(1).uppercased() + body.dropFirst(), remembered: false)
    }

    /// "remember my rent is 2100": a sum of money is never kept, and never leaves the phone (v9 W10).
    func parseRememberedMoney(_ phrase: String) -> Parse? {
        guard let match = phrase.firstMatch(of: /^(?i)\s*remember(?:\s+that)?\s+(.+)$/),
              PrivateFacts.isMoneyShaped(String(match.1)) else { return nil }
        return .ask(TessMemoryScreen.Refusal.money("").line ?? "I don't keep sums of money.")
    }

    /// A body or health fact nothing else read stays on the phone as a private note (Product on QA L1, Research 138
    /// W8): "knee hurts", "slept badly", "body fat 18%".
    func parseBodyFact(_ phrase: String) -> Parse? {
        guard PrivateFacts.isBodyShaped(phrase) else { return nil }
        let body = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return .privateNote(body: body.prefix(1).uppercased() + body.dropFirst(), remembered: false)
    }
}

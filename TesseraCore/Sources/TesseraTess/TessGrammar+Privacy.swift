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

    /// The Bar's privacy rule for a phrase another surface files as a task (Siri's Add a Task; Product P14 and the
    /// 12:30 PM PT rulings, board 0l-2): the Bar's secret-word check; a body fact is a private note; money is a private
    /// note unless it has a day (then a task, said back without its words); "remember" with a sum is refused. Nil when
    /// it's an ordinary task.
    public func privateParse(_ phrase: String, context: TessContext) -> Parse? {
        if SecretWords.mentions(phrase) {
            switch parseSecret(phrase, text: Self.normalize(phrase), context: context) {
            case let parse? where parse.isPrivateNoteOrAsk: return parse
            default: return nil
            }
        }
        if let refused = parseRememberedMoney(phrase) {
            return refused
        }
        let body = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = Parse.privateNote(body: body.prefix(1).uppercased() + body.dropFirst(), remembered: false)
        if PrivateFacts.isBodyShaped(phrase, lastWeightKg: lastWeightKg(context)) {
            return note
        }
        guard PrivateFacts.isMoneyShaped(phrase) else { return nil }
        if Self.isSomethingToDo(phrase), case let .task(_, startsAt)? = parseTask(phrase, context: context),
           startsAt != nil
        {
            return nil
        }
        // "paid rent 2100 fri": a private note on that day (Product 1:15 PM PT).
        return parsePrivateLog(phrase, context: context) ?? note
    }

    /// "remember my rent is 2100": a sum of money is never kept, and never leaves the phone (v9 W10).
    func parseRememberedMoney(_ phrase: String) -> Parse? {
        guard let match = phrase.firstMatch(of: /^(?i)\s*remember(?:\s+that)?\s+(.+)$/),
              PrivateFacts.isMoneyShaped(String(match.1)) else { return nil }
        return .ask(TessMemoryScreen.Refusal.money("").line ?? "I don't keep sums of money.")
    }

    /// A body or health fact nothing else read stays on the phone as a private note (Product on QA L1, Research 138
    /// W8): "knee hurts", "slept badly", "body fat 18%".
    func parseBodyFact(_ phrase: String, context: TessContext) -> Parse? {
        guard PrivateFacts.isBodyShaped(phrase, lastWeightKg: lastWeightKg(context)) else { return nil }
        let body = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return .privateNote(body: body.prefix(1).uppercased() + body.dropFirst(), remembered: false)
    }

    /// His last weight for the bare-number wall, or nil with a set in focus: mid-workout a number is the bar (Product
    /// 4:46 PM PT).
    func lastWeightKg(_ context: TessContext) -> Double? {
        context.entry == nil ? BodyWeight.lastKg(in: store) : nil
    }
}

extension TessGrammar.Parse {
    var isPrivateNoteOrAsk: Bool {
        switch self {
        case .privateNote, .ask: true
        default: false
        }
    }
}

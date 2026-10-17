import Foundation
import TesseraCore

/// Lists' words (K86.12, K86.13; accepted by Product, Oct 17 4:57), as a pure formatter for the Lists screen.
enum ListsCopy {
    /// The context line: a count only, "2 lists". "running" appears only while a run is open: "2 lists, 1 running"
    /// (Product, Oct 17).
    static func context(lists: Int, running: Int = 0) -> String {
        let count = "\(lists) list\(lists == 1 ? "" : "s")"
        return running > 0 ? "\(count), \(running) running" : count
    }

    /// An Add line receipt, thing first: "Rice, on Packing." (Product, decisions 10:06; lists-copy-sweep-oct17.md).
    static func added(_ thing: String, to list: String) -> String {
        "\(thing), on \(list)."
    }

    /// The Add line's spoken receipt is the engine's own (QA on #760): a secret or money-only line went to a private
    /// note, a price was stripped, a medicine is "Private item". With a stop, and a private list name masked.
    static func spoken(receipt: String, listTitle: String, shownList: String) -> String {
        let named = listTitle == shownList ? receipt : receipt.replacingOccurrences(of: listTitle, with: shownList)
        return named.hasSuffix(".") ? named : named + "."
    }

    /// A list page's count line: "3 of 7"; with nothing on it, "nothing on it yet" (QA on #760).
    static func pageContext(open: Int, all: Int) -> String {
        all == 0 ? "nothing on it yet" : "\(all - open) of \(all)"
    }

    /// Clearing the fold: "3 done, cleared." (Design on #760).
    /// A swipe's receipt, thing first: "Rice, removed." (13.6).
    static func removed(_ thing: String) -> String {
        "\(leading(thing)), removed."
    }

    /// What UNDO says after a remove: "Rice, back on Packing."
    static func backOn(_ thing: String, list: String) -> String {
        "\(leading(thing)), back on \(list)."
    }

    /// A line that starts with the thing starts with a capital, whatever was stored: "rice" reads "Rice, removed."
    /// (Kitchen row 10.9 on #786).
    /// A word that already has a capital after its first letter is left as typed: "iPhone" never reads "IPhone"
    /// (QA on #805).
    static func leading(_ thing: String) -> String {
        let firstWord = thing.prefix { !$0.isWhitespace }
        if firstWord.dropFirst().contains(where: \.isUppercase) {
            return thing
        }
        return thing.prefix(1).uppercased() + thing.dropFirst()
    }

    /// The reusable option's receipt, with the shown (maybe masked) name: "Packing, reusable."
    static func reusable(_ list: String, isOn: Bool) -> String {
        "\(list), \(isOn ? "reusable" : "not reusable")."
    }

    /// The option word with its state, so it never rests on colour: "Reusable, on" / "Reusable, off".
    static func reusableWord(isOn: Bool) -> String {
        "Reusable, \(isOn ? "on" : "off")"
    }

    /// A reset's receipt: "Packing, reset." (10.4, 10.11).
    static func reset(_ list: String) -> String {
        "\(list), reset."
    }

    static func cleared(_ count: Int) -> String {
        "\(count) done, cleared."
    }

    /// A running list's state word: "RUNNING, 2 LEFT" (comma, never a dot or " · ").
    /// The page's context line while a run is open: "Packing, running" (10.7).
    static func running(_ list: String) -> String {
        "\(list), running"
    }

    /// A run's start, with the shown name: "Packing, 6 left." / "Packing, nothing left."
    static func runStarted(_ list: String, left: Int) -> String {
        left == 0 ? "\(list), nothing left." : "\(list), \(left) left."
    }

    /// A run's finish: "Packing, done." or "Packing, done. 3 left." (Product, Oct 16 12:38 PM).
    static func runDone(_ list: String, left: Int) -> String {
        left > 0 ? "\(list), done. \(left) left." : "\(list), done."
    }

    static func runState(left: Int) -> String {
        "RUNNING, \(left) LEFT"
    }

    /// Tess's line for a run, the phone's fact: "Packing has 2 left."; at none left, thing first: "Packing, nothing
    /// left." (Product, Oct 17).
    static func tess(list: String, left: Int) -> String {
        left > 0 ? "\(list) has \(left) left." : "\(list), nothing left."
    }

    /// What the Add line does with a draft. Blank clears. A Claude key is never written or kept: the field clears and
    /// Tess says where a key goes (Product 8:55, as on Groceries). Any other failure keeps the typed text and says so
    /// (Kitchen on #760).
    static func add(_ draft: String,
                    perform: (String) -> OpRecord?) -> (draft: String, line: String?, record: OpRecord?)
    {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return ("", nil, nil) }
        if looksLikeClaudeKey(text) {
            return ("", claudeKeyLine, nil)
        }
        guard let record = perform(text) else { return (draft, "Didn't save that. Try again.", nil) }
        return ("", nil, record)
    }
}

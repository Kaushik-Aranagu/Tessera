import Foundation

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
    static func cleared(_ count: Int) -> String {
        "\(count) done, cleared."
    }

    /// A running list's state word: "RUNNING, 2 LEFT" (comma, never a dot or " · ").
    static func runState(left: Int) -> String {
        "RUNNING, \(left) LEFT"
    }

    /// Tess's line for a run, the phone's fact: "Packing has 2 left."; at none left, thing first: "Packing, nothing
    /// left." (Product, Oct 17).
    static func tess(list: String, left: Int) -> String {
        left > 0 ? "\(list) has \(left) left." : "\(list), nothing left."
    }
}

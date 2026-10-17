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

import Foundation
import TesseraCore

/// The Groceries Add line's side of Core's wall (#763; Product 8:40 AM PT Oct 17): which typed lines go on the list
/// and why the rest stay in the draft. Core decides what is kept (`AddListItem.kept`); this only names the reason.
@MainActor
enum GroceriesWall {
    /// Strongest last: the line spoken is the strongest reason in a batch, key, then secret, then money (Product,
    /// decisions 8:55 AM).
    enum Reason: Int, Comparable {
        case money, secret, key

        static func < (lhs: Reason, rhs: Reason) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    struct Walled: Equatable {
        let line: String
        let reason: Reason
    }

    /// Kept lines go on; walled ones stay, each with why.
    static func split(_ lines: [String], store: ObjectStore) -> (kept: [String], walled: [Walled]) {
        var kept: [String] = [], walled: [Walled] = []
        for line in lines {
            if AddListItem.kept(line.trimmingCharacters(in: .whitespacesAndNewlines), store: store) != nil {
                kept.append(line)
            } else {
                walled.append(Walled(line: line, reason: reason(line)))
            }
        }
        return (kept, walled)
    }

    static func reason(_ line: String) -> Reason {
        if looksLikeClaudeKey(line) {
            return .key
        }
        if SecretWords.isSecretListLine(line) || SecretWords.mentions(line) {
            return .secret
        }
        return .money
    }

    /// What the draft holds after an add: money and secret lines stay as typed; a key-shaped line is cleared and
    /// never shown again (Product 8:55 AM).
    static func heldDraft(_ walled: [Walled]) -> String {
        walled.filter { $0.reason != .key }.map(\.line).joined(separator: ", ")
    }

    /// The one line to say: the strongest reason's.
    static func spoken(_ walled: [Walled]) -> String? {
        walled.map(\.reason).max().map(line)
    }

    /// What the Add line does with a draft, out of the view so it tests (Kitchen on #766).
    struct AddOutcome {
        /// What stays typed: walled money and secret lines; never a key.
        let draft: String
        /// What Tess says.
        let voice: String?
        /// The add to take back, with the 4 s UNDO, whenever something was written.
        let undo: OpRecord?
    }

    /// Kept lines go on and Tess reads the engine's own receipt ("Milk, on Groceries.") with its UNDO. A walled line
    /// stays in the draft with the strongest reason's line and no UNDO. If the engine refuses, the draft stays, minus
    /// any key, and she says so.
    static func add(_ draft: String, engine: ActionEngine, store: ObjectStore) -> AddOutcome {
        add(draft, store: store) { try? engine.perform(AddGroceries(lines: $0), by: .user).record }
    }

    /// The same, with the write passed in so a refused write can be tested.
    static func add(_ draft: String, store: ObjectStore, perform: ([String]) -> OpRecord?) -> AddOutcome {
        let lines = GroceryLines.split(draft)
        guard !lines.isEmpty else { return AddOutcome(draft: draft, voice: nil, undo: nil) }
        let split = split(lines, store: store)
        var record: OpRecord?
        if !split.kept.isEmpty {
            guard let added = perform(split.kept) else {
                // A key never stays visible, even when the add fails (QA on #769).
                let kept = (split.kept + split.walled.filter { $0.reason != .key }.map(\.line)).joined(separator: ", ")
                return AddOutcome(draft: kept, voice: "Didn't save that. Try again.", undo: nil)
            }
            record = added
        }
        // Kept rows keep their receipt and UNDO; the wall's line follows them (Design on #782). UNDO takes back only
        // what was written, so a walled line was never in it.
        let receipt = record?.receipt.map { $0.hasSuffix(".") ? $0 : $0 + "." }
        let voice = [receipt, spoken(split.walled)].compactMap(\.self).joined(separator: " ")
        return AddOutcome(draft: heldDraft(split.walled), voice: voice.isEmpty ? nil : voice, undo: record)
    }

    /// The line beside the held draft; none of them offers UNDO, since nothing was written.
    static func line(_ reason: Reason) -> String {
        switch reason {
        case .money: "That stays on this phone."
        case .secret: "That one stays out of Groceries."
        case .key: claudeKeyLine
        }
    }
}

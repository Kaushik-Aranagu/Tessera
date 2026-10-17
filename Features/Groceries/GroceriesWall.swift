import Foundation
import TesseraCore

/// The Groceries Add line's side of Core's wall (#763; Product 8:40 AM PT Oct 17): which typed lines go on the list
/// and why the rest stay in the draft. Core decides what is kept (`AddListItem.kept`); this only names the reason.
@MainActor
enum GroceriesWall {
    enum Reason: Equatable {
        case money, secret, key
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

    /// The line beside the held draft; none of them offers UNDO, since nothing was written.
    static func line(_ reason: Reason) -> String {
        switch reason {
        case .money: "That stays on this phone."
        case .secret: "That one stays out of Groceries."
        case .key: claudeKeyLine
        }
    }
}

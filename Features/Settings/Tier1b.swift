import Foundation
import TesseraCore

/// Together rounds 9, 10 and 12 (164 undoLogV2, 169 backupsV2, 179 walledPageV2): each piece behind its own Review
/// switch, default Off. Off leaves the app exactly as it was.
enum Tier1b {
    nonisolated static let walledID = "walledPageV2"
    nonisolated static let backupsID = "backupsV2"
    nonisolated static let undoID = "undoLogV2"

    nonisolated static let quietID = "quietHoursV2"
    nonisolated static let kitchenID = "kitchenRoomsV2"

    /// The Kitchen rooms (231 to 233): On unless he turned them Off.
    @MainActor static var kitchenRoomsIsOn: Bool {
        ReviewChoices.shared.value(of: kitchenID) != "Off"
    }

    /// Quiet hours (167): On unless he turned it Off.
    @MainActor static var quietIsOn: Bool {
        ReviewChoices.shared.value(of: quietID) != "Off"
    }

    @MainActor static var walledIsOn: Bool {
        ReviewChoices.shared.value(of: walledID) == "On"
    }

    @MainActor static var backupsIsOn: Bool {
        ReviewChoices.shared.value(of: backupsID) == "On"
    }

    @MainActor static var undoIsOn: Bool {
        ReviewChoices.shared.value(of: undoID) == "On"
    }
}

/// The words the undo log wears in the app. Core words the change itself; these are the app's own short lines.
enum UndoWords {
    static let undo = "Undo"
    static let recentTitle = "Recent changes"
    static let empty = "Nothing changed lately."

    /// The sentence said after an Undo: Core's own line, "Put back." or "Can't put that back.", and "Reversed." for
    /// money. A change that is already gone says nothing.
    static func said(_ outcome: UndoOutcome, money: Bool) -> String? {
        switch outcome {
        case let .putBack(line): money ? "Reversed." : line
        case let .blocked(line): line
        case .gone: nil
        }
    }

    /// "this morning, 7:40 am".
    static func when(_ entry: UndoEntry, now: Date) -> String {
        BackupWords.when(entry.at, now: now)
    }
}

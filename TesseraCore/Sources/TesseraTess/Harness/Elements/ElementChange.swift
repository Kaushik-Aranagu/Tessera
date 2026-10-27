import Foundation
import TesseraCore

// The transition pipeline (Design sheet 287, docs/ai/harness/element-looks.md section 6). Every visible change runs
// input, control, data, render: whoever starts it says what changed (`Change`) and who is driving (`Control`), Core
// writes it, and the place looks its move up in the shell's `TransitionCatalog` by kind and control. A place never
// guesses a move from what it thinks happened, so Tess, his hand and the system get the same move every time. Pure
// values: the moves themselves, their tempos and marks are the shell's.

/// What changed, which decides the move (sheet 287, section 2).
public enum ChangeKind: String, Sendable, CaseIterable, Codable {
    // Inside a place: the content changes, the place stays.
    case value, replace, add, done, remove, reorder, kind
    // The place itself: the content stays.
    case form, trait, motion, level, empty, filled
    // The whole screen.
    case route, appLook, returnToView
}

/// Who is driving it, which changes only the move's tempo and mark, never the kind of move (sheet 287, section 3).
public enum Control: String, Sendable, CaseIterable, Codable {
    /// His gesture: 1x, from under his finger, and it always wins.
    case hand
    /// Her call, pending: the flight and wash first, her blue until it dries, her Undo line.
    case tess
    /// Time, a fetch, a timer, a data job: calm, never under his finger, held until he lifts (2 s at most).
    case system
    /// A rehearsal on the quiet stage: no clock, nothing shown (`StageReport`).
    case stage

    /// Whether anything is drawn for it.
    public var isShown: Bool {
        self != .stage
    }
}

/// One change, handed to the place's `PlaceHost` with its control and whether he can see it.
public struct Change: Sendable, Equatable {
    public var place: ElementPlace
    public var kind: ChangeKind
    /// The items it touches, by id, so a move can match them across the change.
    public var itemIDs: [UUID]
    /// What it was and what it is, in the place's own terms (a value, a form name).
    public var before: String?
    public var after: String?

    public init(place: ElementPlace, kind: ChangeKind, itemIDs: [UUID] = [], before: String? = nil,
                after: String? = nil)
    {
        self.place = place
        self.kind = kind
        self.itemIDs = itemIDs
        self.before = before
        self.after = after
    }
}

/// How a reshape moves (sheet 287): what both forms show travels to where it goes, matched by id; collapse and form
/// again only when the two forms share nothing.
public enum ReshapeMove: Sendable, Equatable {
    case travel(shared: [UUID])
    case collapse

    public init(before: [UUID], after: [UUID]) {
        let kept = Set(after)
        let shared = before.filter { kept.contains($0) }
        self = shared.isEmpty ? .collapse : .travel(shared: shared)
    }
}

extension Reaction {
    /// The change kind a call's reaction hands the place; nil when nothing on screen moves.
    public var change: ChangeKind? {
        switch self {
        case .strike: .done
        case .next, .lines: .replace
        case .keystoneTakes: .add
        case .reform: .kind
        case .navigate: .route
        case .reshape: .form
        case .tessLine: nil
        }
    }
}

extension ShellIntent {
    /// The change kind this intent hands the place. Tess's intents always run under `.tess`.
    public var change: ChangeKind? {
        switch call {
        case "setLook":
            switch LookWords.change(arguments) {
            case .trait("motion", _): .motion
            case .trait: .trait
            case .form, .designed: .form
            case nil: nil
            }
        case "openItem", "openDoor", "goBack": .route
        case "showWindow": .replace
        default: nil
        }
    }
}

import SwiftUI

// The contract between the shell and the content (sheet 283 v5, docs/design/shell-contract-283.md). The shell is one
// persistent view per place; content answers "for this route and this state, what goes in each place?"; the
// navigator owns the route stack and each room's state. The shell never asks the content anything except through
// these types, and content never reaches into a view.

/// Every named place of the shell. Places are created once and never torn down; a place knows its frame, its own
/// move and how it takes touches, and nothing about rooms or data.
enum Place: String, CaseIterable, Hashable {
    case title, navWord, switcher, needs, doorTitle
    case keystone, caption, widget, glyph, dial, doorSummary, page, actionWord, tess
}

/// Level 0 is the landing; level 1 is a door page (more levels later).
enum LayoutKind: Equatable {
    case landing, door
    /// Bridge's own masthead and doors band (sheet 283 v4): Settings word and Departure board, the apps dial.
    case bridge

    init(level: Int) {
        self = level == 0 ? .landing : .door
    }
}

/// How a room's keystone comes in from Bridge's mosaic, and goes back to it (sheet 283 v4, the flip): the mosaic is
/// cut into 16 x 8 tiles that turn away in the room's order; Lookout's blows apart like cloud.
enum KeystoneFlip: String, Equatable, CaseIterable {
    /// Log: row by row.
    case rows
    /// Deck: a left-to-right sweep.
    case sweep
    /// Galley: column by column.
    case columns
    /// Watch: from the ground up.
    case groundUp
    /// Purse: left to right.
    case leftToRight
    /// Lookout: the tiles drift outward with the wind, grow, turn and blur, with a warm glint (700 ms).
    case cloud
}

/// Identity of a place's content: the same id on both sides of a change means "nothing changed", so the place is
/// not touched (its payload may still refresh in place).
struct ContentID: Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    let raw: String

    init(_ raw: String) {
        self.raw = raw
    }

    init(stringLiteral value: String) {
        raw = value
    }

    var description: String {
        raw
    }
}

/// What sort of thing a place holds. Same kind with a new id plays the place's own move; a different kind collapses
/// to a point and forms again.
enum SlotKind: String, Equatable {
    case text, switcher, wall, widget, glyph, dial, summary, list, action
    /// A room's own drawn keystone (Deck's board, Watch's woods, Lookout's skypiece, Purse's chart, Galley's rail),
    /// drawn by the room's `shellScene` renderer; the payload carries only its key.
    case scene
    /// A room built from a document (the Chart room, R1): the places drawn from a tree of kit parts (`PartNode`).
    case parts
    /// A ranked door page or an item page (sheet 284): both fill the Page's block, so a change from one to the other
    /// is the same place with new words and never a collapse.
    case rows
}

/// One row of a door page: an id the shell hands back on tap, a title and a short detail. A private row never
/// carries the note's words: the room fills `title` with "Private note".
struct ShellRow: Identifiable, Equatable {
    let id: String
    let title: String
    var detail = ""
    var isPrivate = false
    /// Swipe right is Done and left is Not now (sheet 283 touch; through GestureKit's `rowSwipe`).
    var swipe = false
}

/// One of the foot's actions as data; the shell hands `id` back when it is done.
struct ShellStep: Identifiable, Equatable {
    let id: String
    let verb: String
    var object = ""
    var hold = false
}

/// The data a place renders. Plain values only: taps come back to the host as `ShellIntent`s.
enum SlotPayload: Equatable {
    case title(String, accent: Color)
    case navWord(String)
    /// Needs (the first line 600 ink) or the caption (one ink 2 line).
    case lines([String])
    case switcher(across: [String], vertical: [String])
    case wall([WallWord], label: String)
    case widget([WidgetItem])
    case glyph(WidgetItem, color: Color)
    case dial([DialDoor])
    case summary(DialDoor)
    case doorTitle(name: String, line: String, color: Color)
    case list([ShellRow])
    case action([ShellStep], accent: Color)
    /// A room's own keystone, by key ("deck.board"). The room's host supplies the drawing through the environment
    /// value `shellScene`, so content stays free of views. The key changes only when the drawing must be rebuilt.
    case scene(String, label: String)
    /// A document room's own composition for one place: a tree of kit parts, drawn by `PartView`.
    case parts(PartTree)
    /// Sheet 284, level 1: the door's rows split the Page's block by rank weights (`RankedPage`).
    case ranked(RankedPageData)
    /// Sheet 284, level 2: Facts over a Body drawn by the item's kind (`ItemPage`).
    case item(ItemPageData)
    /// Sheet 284: the Door title (level 1) or the Item title (level 2): the name in 34 pt bold ink over one line.
    /// Across
    /// goes to the neighbour route (`PageTitle`).
    case pageTitle(PageTitle)
}

/// The Door title or Item title as sheet 284 draws it. `previous` and `next` are the routes an across swipe goes to
/// (the neighbouring door or item); nil where there is none, so the title does not move.
struct PageTitle: Equatable {
    var name: String
    var line: String
    var previous: ShellRoute?
    var next: ShellRoute?
    /// The dial focus the landing keeps when across goes to the previous or next door, so back lands on the door you
    /// were on (level 1 only).
    var previousFocus: Int?
    var nextFocus: Int?
    /// The title of an item (level 2) rather than a door (level 1).
    var isItem = false
}

/// What the `parts` payload carries: the top-level parts of one place, in order, and the room's colour.
struct PartTree: Equatable {
    var nodes: [PartNode]
    var accent: Color
    /// A width wider than the place's own (the Line runs 354 pt while the Needs beside it is empty).
    var width: CGFloat?
}

struct SlotContent: Identifiable, Equatable {
    let id: ContentID
    let kind: SlotKind
    let payload: SlotPayload
    /// A proposed change, not yet set: the place draws it at 38% ink (the Chart room's ghost, sheet 357).
    var ghost = false
}

/// What the shell shows for one route: the layout and the content of each place. A missing place is `nil`: kept,
/// empty and touch-free.
struct Screen: Equatable {
    let layout: LayoutKind
    var slots: [Place: SlotContent]
    /// How this room's keystone arrives from Bridge (and leaves back to it); nil on Bridge itself.
    var flip: KeystoneFlip?

    init(layout: LayoutKind, flip: KeystoneFlip? = nil, slots: [Place: SlotContent?]) {
        self.layout = layout
        self.slots = slots.compactMapValues { $0 }
        self.flip = flip
    }

    subscript(place: Place) -> SlotContent? {
        slots[place]
    }
}

/// Where the shell is: a room, a level and (at level 1) the door that was opened. Named apart from the app's
/// `Route` (the object graph's route).
struct ShellRoute: Hashable, CustomStringConvertible {
    let room: String
    var level = 0
    var door: String?
    /// Level 2: the item (a row id) whose page is open.
    var item: String?

    static func landing(_ room: String) -> ShellRoute {
        ShellRoute(room: room)
    }

    static func door(_ room: String, _ door: String) -> ShellRoute {
        ShellRoute(room: room, level: 1, door: door)
    }

    /// An item page: level 2, under the door it was opened from.
    static func item(_ room: String, _ door: String, _ item: String) -> ShellRoute {
        ShellRoute(room: room, level: 2, door: door, item: item)
    }

    var layout: LayoutKind {
        LayoutKind(level: level)
    }

    var description: String {
        let base = door.map { "\(room)/\(level)/\($0)" } ?? "\(room)/\(level)"
        return item.map { "\(base)/\($0)" } ?? base
    }
}

/// A room's state the navigator keeps per route, so back restores every place exactly.
struct RoomState: Equatable, Hashable {
    var switcherIndex = 0
    var switcherVerticalIndex = 0
    var widgetIndex = 0
    var dialFocus = 0
    var keystonePage = 0
    var scrollOffset: CGFloat = 0
}

/// A room (or a door page) answers one question: for this route and this state, what goes in each place.
protocol RoomContent {
    func screen(for route: ShellRoute, state: RoomState) -> Screen
}

/// What a touch on a place asks for. The host decides (push a door, open a note, run an action, go back).
enum ShellIntent: Equatable {
    case back
    case openDoor(String)
    case openItem(String)
    case action(String)
    /// A row swiped right (Done, or start it) or a widget item's Big line held to strike it.
    case done(String)
    /// A row swiped left: not now.
    case notNow(String)
}

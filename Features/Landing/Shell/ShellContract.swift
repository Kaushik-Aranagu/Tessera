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

    init(level: Int) {
        self = level == 0 ? .landing : .door
    }
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
}

/// One row of a door page: an id the shell hands back on tap, a title and a short detail. A private row never
/// carries the note's words: the room fills `title` with "Private note".
struct ShellRow: Identifiable, Equatable {
    let id: String
    let title: String
    var detail = ""
    var isPrivate = false
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
}

struct SlotContent: Identifiable, Equatable {
    let id: ContentID
    let kind: SlotKind
    let payload: SlotPayload
}

/// What the shell shows for one route: the layout and the content of each place. A missing place is `nil`: kept,
/// empty and touch-free.
struct Screen: Equatable {
    let layout: LayoutKind
    var slots: [Place: SlotContent]

    init(layout: LayoutKind, slots: [Place: SlotContent?]) {
        self.layout = layout
        self.slots = slots.compactMapValues { $0 }
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

    static func landing(_ room: String) -> ShellRoute {
        ShellRoute(room: room)
    }

    static func door(_ room: String, _ door: String) -> ShellRoute {
        ShellRoute(room: room, level: 1, door: door)
    }

    var layout: LayoutKind {
        LayoutKind(level: level)
    }

    var description: String {
        door.map { "\(room)/\(level)/\($0)" } ?? "\(room)/\(level)"
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
}

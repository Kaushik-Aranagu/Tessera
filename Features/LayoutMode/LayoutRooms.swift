// swiftlint:disable identifier_name
import Foundation

/// The seven rooms Layout mode walks, in the board's order, with the words each place's glass card reads (ported from
/// the board's `LPAGES`, `LTOUCH`, `LROOM`, `LNEXT0` and `LNEXT1`, shell-contract-283.md). Debug surface only.
enum LayoutRoom: Int, CaseIterable, Identifiable {
    case bridge, log, lookout, deck, galley, watch, purse

    var id: Int {
        rawValue
    }

    var name: String {
        switch self {
        case .bridge: "Bridge"
        case .log: "Log"
        case .lookout: "Lookout"
        case .deck: "Deck"
        case .galley: "Galley"
        case .watch: "Watch"
        case .purse: "Purse"
        }
    }

    /// The room colour as (light, dark) hex: the board's paper and black looks. Bridge stays ink.
    var hex: (light: UInt32, dark: UInt32)? {
        switch self {
        case .bridge: nil
        case .log: (0x8A4570, 0xE3A3CB)
        case .lookout: (0xC9772E, 0xE8A06A)
        case .deck: (0x0B62AE, 0x8FB0EE)
        case .galley: (0x93611A, 0xC49A5E)
        case .watch: (0x8E4A78, 0xD59AC4)
        case .purse: (0x2A7878, 0x7BC0C4)
        }
    }

    /// Next and previous, looping.
    func moved(_ step: Int) -> LayoutRoom {
        let count = Self.allCases.count
        return Self.allCases[((rawValue + step) % count + count) % count]
    }

    /// Places that are kept but empty on this room's landing.
    var emptyPlaces: Set<String> {
        self == .bridge ? ["Caption", "Action word"] : []
    }

    /// "the landing, 3 of 7": what the Title pane says under the room's name.
    func position(_ level: LayoutLevel) -> String {
        let place = "\(rawValue + 1) of \(Self.allCases.count)"
        if self == .bridge {
            return "one level, \(place)"
        }
        return "\(level == .door ? "a door page" : "the landing"), \(place)"
    }

    /// What the place holds in this room (the card's "Holds" line); nil falls back to the shared words.
    func holds(_ place: String, _ level: LayoutLevel) -> String {
        if level == .door, let door = LayoutCopy.doorHolds[place] {
            return door
        }
        if let own = holdsTable[place] {
            return own
        }
        if emptyPlaces.contains(place) || (self == .bridge && ["Switcher", "Needs"].contains(place)) {
            return "Nothing on this screen. The place is kept so nothing moves into it"
        }
        return "Same as every screen"
    }

    private var holdsTable: [String: String] {
        switch self {
        case .bridge: [
                "Masthead": "Settings word and the departure board (three rows that flip letter by letter)",
                "Settings word": "The way into Settings",
                "Departure board": "Three notice rows that flip letter by letter",
                "Keystone": "The mosaic: gallery, weather, workout, now", "Widget": "The one thing",
                "Dial": "The apps: seven rooms", "Door summary": "One fact for the focused room",
                "Tess": "Tess, and the undo line above her",
            ]
        case .log: [
                "Switcher": "Newest, Due, Pinned, From Tess; up and down: Today, This week, Earlier",
                "Keystone": "The word wall", "Caption": "Tap a word to open its note",
                "Widget": "Four notes, glyphs by kind",
                "Dial": "The doors: All notes, Ideas, From Tess, Voice, Private", "Action word": "Write, Speak, List",
            ]
        case .lookout: [
                "Switcher": "Now, Tonight, Tomorrow, This week", "Keystone": "The skypiece: real sky and raised glass",
                "Caption": "Rain gathers on the glass from 7", "Widget": "Rain, the low, the driest day (no strike)",
                "Dial": "Hours, Tonight, This week, Air, Sky", "Action word": "Alert, Hours, Walk",
            ]
        case .deck: [
                "Switcher": "Today, This week, This month; up and down: Push A, Pull A, Legs",
                "Keystone": "The blackboard", "Caption": "Drag to write. Swipe fast left to wipe",
                "Widget": "Tonight, this week, yesterday\u{2019}s walk",
                "Dial": "Today, This week, Library, Bests, Plan", "Action word": "Start (hold), Log, Rest",
            ]
        case .galley: [
                "Switcher": "Tonight, Tomorrow, This week", "Keystone": "The pass: printed tickets on a rail",
                "Caption": "Swipe a ticket up for its next page", "Widget": "Tacos, rice, the shop, dishes",
                "Dial": "Tonight, Pantry, Recipes, Groceries, Leftovers", "Action word": "Cook, Get, Wash",
            ]
        case .watch: [
                "Switcher": "Evening, Night, Morning", "Keystone": "The woodland",
                "Caption": "Hold a tree to water it. Tap to see it", "Widget": "Next, thirsty, tended",
                "Dial": "Today, Body, Mind, Home, Weekly", "Action word": "Plant, Water, Pause",
            ]
        case .purse: [
                "Switcher": "October, This year, Since May", "Keystone": "The indices",
                "Caption": "Across for a category, up and down for an index",
                "Widget": "Still yours, next drop, today (no strike)",
                "Dial": "This month, Kinds, Saving, Investing, Debts, Mine", "Action word": "Log, Look, Plan",
            ]
        }
    }
}

/// The words shared by every room: how each place is touched, and what it does on the next move.
enum LayoutCopy {
    static let doorHolds = [
        "Door title": "The door\u{2019}s name, its count and its line",
        "Page": "The door\u{2019}s own list, in the one fixed block of its depth",
    ]

    static let touch: [String: String] = [
        "Masthead": "Title tap opens the room index; the nav word goes back",
        "Title": "Tap opens the room index", "Nav word": "Tap goes back",
        "Settings word": "Tap opens Settings", "Departure board": "Tap a row to open what it names",
        "Switcher": "Swipe across or up and down; tap for the next", "Needs": "Changes with the switcher",
        "Keystone": "Its own gestures; a drag that starts here stays here", "Caption": "None",
        "Widget": "Swipe four ways for the next; hold the big line to strike; tap opens", "Glyph": "Follows the item",
        "Dial": "Turn up and down; tap the focus", "Door summary": "Rises when the focus changes",
        "Action word": "Tap; swipe across for others; hold to start", "Tess": "Tap to hear her; hold to talk",
        "Door title": "Swipe across for the next door; tap to rename",
        "Page": "The door\u{2019}s own list: scroll, swipe right Done, left Not now",
    ]

    /// What each place does when you move to the next room.
    static let nextRoom: [String: String] = [
        "Masthead": "Stays", "Title": "Stays; the name flaps to the next room\u{2019}s", "Nav word": "Stays",
        "Switcher": "Stays; its words fold over", "Needs": "Stays; its lines fold over",
        "Keystone": "Stays; its drawing turns tile by tile into the next room\u{2019}s",
        "Caption": "Stays; its line unrolls anew",
        "Widget": "Stays; the item leaves upward and the next rises",
        "Glyph": "Stays; collapses to a point and forms the next",
        "Dial": "Stays; spins too fast to read and slows onto the next doors",
        "Door summary": "Stays; out to the right, the next in from the right",
        "Action word": "Stays; letters stream out and in", "Tess": "Stays; only her colour changes",
        "Door title": "Stays; flaps to the next room\u{2019}s door",
        "Page": "Stays; the list leaves softly and the next settles from the top",
        "Settings word": "Folds away; the room\u{2019}s Title folds open",
        "Departure board": "Folds away; the Switcher and Needs fold open",
    ]

    /// What each place does going to a door page.
    static let toDoor: [String: String] = [
        "Masthead": "Stays", "Title": "Stays; the name flaps to the door\u{2019}s",
        "Nav word": "Stays; flaps to the room\u{2019}s name", "Switcher": "Melts into the Door title",
        "Needs": "Melts into the Door title", "Keystone": "Stays, untouched: same keystone, same content",
        "Caption": "Stays; its line unrolls anew", "Widget": "Melts into the Page", "Glyph": "Melts into the Page",
        "Dial": "Melts into the Page", "Door summary": "Melts into the Page",
        "Action word": "Stays; its letters stream to the door\u{2019}s verb",
        "Tess": "Stays; only her colour can change",
    ]

    /// What each place does going back up from a door page.
    static let backUp: [String: String] = [
        "Masthead": "Stays", "Title": "Stays; flaps back to the room\u{2019}s name",
        "Nav word": "Stays; flaps back to Bridge", "Door title": "Splits back into Switcher and Needs",
        "Keystone": "Stays, untouched", "Caption": "Stays; its line unrolls anew",
        "Page": "Splits back into Widget, Glyph, Dial and Door summary",
        "Action word": "Stays; letters stream back", "Tess": "Stays",
    ]

    /// The frame as the card prints it: "x 24, y 196, 354 by 182 pt".
    static func frame(_ place: LayoutPlace) -> String {
        let f = place.frame
        return "x \(Int(f.minX)), y \(Int(f.minY)), \(Int(f.width)) by \(Int(f.height)) pt"
    }
}

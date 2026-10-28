import Foundation

// Tess AI-first (docs/ai/harness/elements.md): every place of the standing shell (sheet 283) says what it shows and
// what can be done to it, as data. The shell renders it, Tess reads it. A room's `RoomContent` attaches one
// `ElementMeaning` to each place it fills; the navigator gathers them into a `TessFrame`; the `ToolPicker` reads the
// frame to send Tess only the calls that fit where he is. Pure values: no views, no store reads.

/// A place of the shell, by the app's own names (`Place` in Features/Landing/Shell, same raw values).
public enum ElementPlace: String, Sendable, CaseIterable, Codable {
    case title, navWord, switcher, needs, doorTitle
    case keystone, caption, widget, glyph, dial, doorSummary, page, actionWord, tess
}

/// One short fact about a shown thing ("due Thu", "3 this week"), with what it may do: a money amount, a body
/// number or a calendar line is `deviceOnly` and reaches Claude under lab only.
public struct ElementFact: Sendable, Equatable {
    public var text: String
    public var taint: Taint

    public init(_ text: String, taint: Taint = .claudeSafe) {
        self.text = text
        self.taint = taint
    }
}

/// One thing a place shows. `name` is always the shown name: a private thing arrives as its label ("Private note"),
/// so Tess reads what he reads and nothing more. `id` is the object, when it is one; calls carry it, never the name,
/// so a label still points at the right thing.
public struct ElementItem: Sendable, Equatable {
    public var id: UUID?
    /// The class word, singular: "note", "list item", "routine", "door", "window", "spend".
    public var kind: String
    public var name: String
    public var isPrivate: Bool
    /// What the name itself may do: Purse names are `deviceOnly`.
    public var taint: Taint
    public var facts: [ElementFact]

    public init(id: UUID? = nil, kind: String, name: String, isPrivate: Bool = false, taint: Taint = .claudeSafe,
                facts: [ElementFact] = [])
    {
        self.id = id
        self.kind = kind
        self.name = name
        self.isPrivate = isPrivate
        self.taint = taint
        self.facts = facts
    }
}

/// Where a call's input comes from when his words leave it out.
public enum InputSource: String, Sendable, Equatable {
    /// Only from what he says ("12 dollars", "milk and eggs").
    case asked
    /// The thing he means by "this": see `TessFrame.referent()`.
    case referent
    /// The switcher's word now ("Tomorrow", "This week"): a time window.
    case window
    /// The dial's focused door.
    case door
    /// The moment he asked.
    case now
}

public struct CallInput: Sendable, Equatable {
    /// The tool's own argument name ("task", "startsAt").
    public var name: String
    public var source: InputSource
    public var required: Bool

    public init(_ name: String, from source: InputSource, required: Bool = true) {
        self.name = name
        self.source = source
        self.required = required
    }
}

/// How the place answers when a call lands. The shell plays it on the place that offered the call (its own move,
/// sheet 283), and Tess's soul hands off to that place's frame (`handOff(target:)`, tess-soul.md).
public enum Reaction: String, Sendable, Equatable {
    /// The Big line is struck (Done), with Undo 10 s.
    case strike
    /// The item leaves and the next one rises in (Not now, moved).
    case next
    /// The keystone takes the new thing in its own way (a wall word sets, a ticket hangs, chalk is written).
    case keystoneTakes
    /// The glyph collapses to a point and forms again.
    case reform
    /// The shell opens something: a door page or an item, place by place.
    case navigate
    /// The door summary or needs lines change in place.
    case lines
    /// Nothing on screen moves; Tess's own line says it.
    case tessLine
    /// The place takes a new form or trait (sheet 287): what both forms show travels to where it goes, matched by
    /// item id over 520 ms, and the rest fades; it collapses to a point only when the two share no item
    /// (`ReshapeMove`). By Tess, sheet 285's wash comes first, then the travel, then the Undo line; a look carries no
    /// blue (docs/ai/harness/element-looks.md).
    case reshape
}

/// Who may run a call. `deviceOnly` marks money calls: kept on the phone's own rungs (rules and the on-device model)
/// only while `ClaudeSees.moneyWrites` is off; since his Oct 27 pick Claude may run them too. Ghost row, Undo always.
public enum CallReach: String, Sendable, Equatable {
    case anyRung, deviceOnly
}

/// One thing a place lets Tess do.
public struct ElementCall: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        /// A Tess tool (`TessTools`, `open`): it writes typed actions as Tess, pending, as a ghost row with Undo.
        case tool
        /// The shell itself: it changes what is shown and writes nothing (`ShellIntent`).
        case shell
    }

    public var name: String
    public var kind: Kind
    /// The words that point at it, whole words, lowercase ("done", "not now", "move").
    public var phrases: [String]
    public var inputs: [CallInput]
    public var reaction: Reaction
    public var reach: CallReach
    /// The item kinds it applies to ("task", "list item"); empty is any. "Done" on a list item checks it, on a task
    /// completes it: the kind of the thing in focus decides, never a guess.
    public var kinds: Set<String>

    public init(_ name: String, _ kind: Kind = .tool, phrases: [String], inputs: [CallInput] = [],
                reaction: Reaction, reach: CallReach = .anyRung, kinds: Set<String> = [])
    {
        self.name = name
        self.kind = kind
        self.phrases = phrases
        self.inputs = inputs
        self.reaction = reaction
        self.reach = reach
        self.kinds = kinds
    }

    /// Whether it can act on this item.
    public func applies(to item: ElementItem?) -> Bool {
        guard !kinds.isEmpty else { return true }
        guard let item else { return false }
        return kinds.contains(item.kind)
    }
}

/// What one place means right now: what it shows, which of those is in focus, and what can be done to it. A room
/// builds it next to the place's `SlotContent`, from the same facts, so the two never disagree.
public struct ElementMeaning: Sendable, Equatable {
    public var place: ElementPlace
    public var items: [ElementItem]
    /// The item in focus: the widget's shown item, the dial's focused door, the switcher's word.
    public var focus: Int?
    public var calls: [ElementCall]
    /// Whether he can see it now: the shell's `liveScope` (docs/design/live-visibility.md), not whether it is resident.
    /// "This" only points at a shown place, and a call on one that isn't shown writes the data and skips the move.
    public var isShown: Bool

    public init(place: ElementPlace, items: [ElementItem] = [], focus: Int? = nil, calls: [ElementCall] = [],
                isShown: Bool = true)
    {
        self.place = place
        self.items = items
        self.focus = focus
        self.calls = calls
        self.isShown = isShown
    }

    public var focused: ElementItem? {
        focus.flatMap { items.indices.contains($0) ? items[$0] : nil }
    }
}


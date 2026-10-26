import Foundation

// Living elements (Design sheets 286 and 287, docs/ai/harness/element-looks.md). A place's content has a shape (what
// it is); a form is how that content is drawn, and traits tune the form. Only forms the studio drew are here, so a
// reshape can never make a card, a pill, a bar or a ring, and never a new colour: colour stays the room's palette and
// there is no colour trait. The app maps each form name to its view; `LookCatalog` says which place takes which.

/// What a place's content is, whatever draws it. A reshape keeps the room's data and changes only how it is drawn.
public enum ContentShape: String, Sendable, CaseIterable, Codable {
    /// One thing at a time (the widget's Big line).
    case one
    /// A few ranked things (tonight, tomorrow; the needs).
    case few
    /// Rows to scan (a door page).
    case many
    /// Words that carry weight (the switcher, the Log wall).
    case words
    /// The rooms or doors to go to (the dial).
    case doors
    /// One number over time (a trend).
    case measure
    /// A line or two of text (caption, needs, door summary).
    case lines
}

/// One quality of a form he or Tess can tune. Values are words, so Tess reads and writes them as he says them, and
/// shape mode shows them as trait words to tap.
public struct LookTrait: Sendable, Equatable {
    public var name: String
    /// What it changes, for Tess.
    public var summary: String
    /// The words it takes, calmest or smallest first.
    public var values: [String]
    /// The studio's value.
    public var designed: String
    /// Words that step it one value up ("denser") or down ("calmer").
    public var up: [String]
    public var down: [String]
    /// Words that name one value ("numbers only" is `numbers`).
    public var named: [String: String]

    public init(_ name: String, _ summary: String, values: [String], designed: String, up: [String] = [],
                down: [String] = [], named: [String: String] = [:])
    {
        self.name = name
        self.summary = summary
        self.values = values
        self.designed = designed
        self.up = up
        self.down = down
        self.named = named
    }

    /// The value `offset` steps from `value`, or nil past either end.
    public func step(_ value: String, by offset: Int) -> String? {
        guard let index = values.firstIndex(of: value), values.indices.contains(index + offset) else { return nil }
        return values[index + offset]
    }
}

/// A way to draw a place's content.
public struct ElementForm: Sendable, Equatable {
    public var name: String
    /// What it looks like, in the studio's words, for Tess and for the Undo line.
    public var summary: String
    /// The content it can draw.
    public var draws: Set<ContentShape>
    /// Words that name it, lowercase ("as an index", "a list").
    public var phrases: [String]
    /// Traits only this form has (the chalkboard's "shows", the rail's ticket count).
    public var traits: [LookTrait]

    public init(_ name: String, _ summary: String, draws: Set<ContentShape>, phrases: [String] = [],
                traits: [LookTrait] = [])
    {
        self.name = name
        self.summary = summary
        self.draws = draws
        self.phrases = phrases
        self.traits = traits
    }
}

/// The forms the studio drew (sheet 287, section 6). Which place takes which, and in which room, is `LookCatalog`.
public enum ElementForms {
    public static let all: [ElementForm] = [
        ElementForm("type", "Text in the room's ink, one or two lines", draws: [.lines, .one, .words],
                    phrases: ["type", "plain", "as text"]),
        ElementForm("roll", "The three-place roll word inside the 26 pt sentence", draws: [.words],
                    phrases: ["roll", "roll word", "a roll"]),
        ElementForm("rise", "One thing at a time; the next rises in when it's done", draws: [.one, .few],
                    phrases: ["rise", "one at a time", "one thing"]),
        ElementForm("stack", "The first thing big, the next few small under it", draws: [.few, .many],
                    phrases: ["stack", "one and next", "show the next", "a stack"]),
        ElementForm("rows", "Plain rows to scan, a name and its fact", draws: [.few, .many],
                    phrases: ["rows", "list", "a list"]),
        ElementForm("columns", "Names only, two across", draws: [.many, .doors],
                    phrases: ["columns", "two columns", "two across"]),
        ElementForm("ledger", "Names left, numbers right, in Outfit", draws: [.many, .measure],
                    phrases: ["ledger", "names and numbers"]),
        ElementForm("trace", "One thin line over time with the last value at its end", draws: [.measure],
                    phrases: ["trace", "a line", "as a line"]),
        ElementForm("wall", "Words set in a wall, bigger when they matter more", draws: [.words, .many, .few],
                    phrases: ["wall", "word wall"]),
        ElementForm("drawing", "The room's own drawing", draws: [.one], phrases: ["drawing", "the drawing"]),
        ElementForm("reel", "The doors on a reel that turns under the thumb", draws: [.doors],
                    phrases: ["reel", "a reel", "wheel"]),
        ElementForm("index", "The doors as a column of words, one tap each", draws: [.doors],
                    phrases: ["index", "an index", "column", "a column", "list", "a list"]),
        ElementForm("sentence", "One sentence that names them", draws: [.doors, .words, .lines],
                    phrases: ["sentence", "a sentence", "one sentence"]),
        // Keystone materials, each in its own room (`LookCatalog`).
        ElementForm("mosaic", "Bridge's faces: now, gallery, weather, workout", draws: [.few]),
        ElementForm("wordWall", "The Log's wall of words", draws: [.words, .many]),
        ElementForm("chalk", "The Deck's blackboard, lifts and numbers in chalk", draws: [.few, .measure],
                    traits: [LookTrait("shows", "What the board leads with", values: ["week", "bests", "last sets"],
                                       designed: "week", named: ["the week": "week", "my bests": "bests",
                                                                 "last sets": "last sets"])]),
        ElementForm("tickets", "The Galley's rail of tickets", draws: [.few, .many],
                    traits: [LookTrait("count", "How many tickets hang", values: ["1", "2", "3", "5"], designed: "3",
                                       up: ["more tickets"], down: ["fewer tickets"])]),
        ElementForm("woods", "The Watch's woodland, a tree per routine", draws: [.few, .many]),
        ElementForm("sky", "The Lookout's sky under raised glass", draws: [.measure, .one]),
        ElementForm("chart", "The Purse's index chart", draws: [.measure, .many]),
    ]

    public static func form(_ name: String) -> ElementForm? {
        all.first { $0.name == name }
    }
}

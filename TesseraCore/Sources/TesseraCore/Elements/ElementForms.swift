import Foundation

// Living elements (docs/ai/harness/element-looks.md): any place can be reshaped, by his hand or by Tess, and the
// look is kept as an object. A room says what its content is (its shape); the form is how that content is drawn, and
// traits tune the form. Only forms the studio drew are here, so a reshape can never make a card, a pill, a bar or a
// ring, and never a new colour: colour stays the room's palette. The app maps each form name to its view.

/// What a place's content is, whatever draws it. A form takes the shapes it can draw; a reshape keeps the room's data.
public enum ContentShape: String, Sendable, CaseIterable, Codable {
    /// One thing at a time (the widget's Big line).
    case one
    /// A few ranked things (tonight, tomorrow; the needs).
    case few
    /// Rows to scan (a door page).
    case many
    /// Words that carry weight (the Log wall).
    case words
    /// The rooms or doors to go to (the dial).
    case doors
    /// One number over time (a trend).
    case measure
    /// A line or two of text (caption, needs, door summary).
    case lines
}

/// One quality of a form he or Tess can tune. Values are words, so Tess reads and writes them as he says them.
public struct LookTrait: Sendable, Equatable {
    public var name: String
    /// What it changes, for Tess.
    public var summary: String
    /// The words it takes, calmest or smallest first.
    public var values: [String]
    /// The studio's value.
    public var designed: String

    public init(_ name: String, _ summary: String, values: [String], designed: String) {
        self.name = name
        self.summary = summary
        self.values = values
        self.designed = designed
    }

    /// The value one step up or down from `value` ("denser", "bigger", "calmer"), or nil at the end.
    public func step(_ value: String, by offset: Int) -> String? {
        guard let index = values.firstIndex(of: value), values.indices.contains(index + offset) else { return nil }
        return values[index + offset]
    }
}

/// A way to draw a place's content.
public struct ElementForm: Sendable, Equatable {
    public var name: String
    /// What it looks like, in the studio's words, for Tess and for the reshape line.
    public var summary: String
    public var shapes: Set<ContentShape>
    /// The places it fits (`ElementPlace` raw values).
    public var places: Set<String>
    /// The rooms whose material it is (a keystone's chalkboard is the Deck's); empty is any room.
    public var rooms: Set<String>
    /// Its own traits; `ElementForms.common` apply to every form.
    public var traits: [LookTrait]

    public init(_ name: String, _ summary: String, shapes: Set<ContentShape>, places: Set<String>,
                rooms: Set<String> = [], traits: [LookTrait] = [])
    {
        self.name = name
        self.summary = summary
        self.shapes = shapes
        self.places = places
        self.rooms = rooms
        self.traits = traits
    }

    /// Every trait it takes: its own, then the common ones.
    public var allTraits: [LookTrait] {
        traits + ElementForms.common.filter { common in !traits.contains { $0.name == common.name } }
    }

    public func trait(_ name: String) -> LookTrait? {
        allTraits.first { $0.name == name }
    }

    public func fits(place: String, room: String, shape: ContentShape) -> Bool {
        places.contains(place) && shapes.contains(shape) && (rooms.isEmpty || rooms.contains(room))
    }
}

/// The forms the studio drew. The keystone's materials stay in their own room; the rest go anywhere they fit.
public enum ElementForms {
    // MARK: Traits

    static let density = LookTrait("density", "How close the lines sit", values: ["airy", "designed", "dense"],
                                   designed: "designed")
    static let facts = LookTrait("facts", "How much shows beside each name", values: ["none", "one", "all"],
                                 designed: "one")
    static let order = LookTrait("order", "What comes first", values: ["designed", "soonest", "newest", "name"],
                                 designed: "designed")
    static let count = LookTrait("count", "How many show at once", values: ["1", "2", "3", "5", "8"],
                                 designed: "3")

    /// Every form takes these. Size moves with Dynamic Type and never below the type floor; motion never goes past
    /// what the studio drew, and Reduce Motion still wins. "still" draws from the data with no clock, the same switch
    /// as `LiveSwitch.dataOnly` (docs/design/live-visibility.md).
    public static let common: [LookTrait] = [
        LookTrait("size", "How big the type is, from the room's own scale", values: ["smaller", "designed", "bigger"],
                  designed: "designed"),
        LookTrait("motion", "How much it moves", values: ["still", "calm", "designed"], designed: "designed"),
    ]

    // MARK: Forms

    public static let all: [ElementForm] = [
        // Any room.
        ElementForm("rise", "One thing at a time; the next rises in when it's done",
                    shapes: [.one, .few], places: ["widget"], traits: [facts]),
        ElementForm("stack", "The first thing big, the next few small under it", shapes: [.few, .many],
                    places: ["widget", "page"], traits: [facts, count]),
        ElementForm("rows", "Plain rows to scan, a name and its fact", shapes: [.few, .many],
                    places: ["page", "widget"], traits: [density, facts, order]),
        ElementForm("wall", "Words set in a wall, bigger when they matter more", shapes: [.words, .many, .few],
                    places: ["keystone", "page"],
                    traits: [density, LookTrait("weight", "What makes a word big",
                                                values: ["even", "recent", "often"], designed: "recent")]),
        ElementForm("reel", "The doors on a reel that turns under the thumb", shapes: [.doors], places: ["dial"]),
        ElementForm("index", "The doors as a column of words, one tap each", shapes: [.doors], places: ["dial"],
                    traits: [density]),
        ElementForm("ledger", "Names left, numbers right, in Outfit", shapes: [.many, .measure],
                    places: ["page", "widget"], traits: [density, order]),
        ElementForm("trace", "One thin line over time with the last value at its end", shapes: [.measure],
                    places: ["widget", "page", "glyph"]),
        ElementForm("type", "Text in the room's ink, one or two lines", shapes: [.lines, .one],
                    places: ["needs", "caption", "doorSummary", "title"], traits: [count]),
        // Keystone materials, each in its own room.
        ElementForm("mosaic", "Bridge's faces: now, gallery, weather, workout", shapes: [.few], places: ["keystone"],
                    rooms: ["bridge"]),
        ElementForm("chalk", "The Deck's blackboard, lifts and numbers in chalk", shapes: [.few, .measure],
                    places: ["keystone"], rooms: ["deck"],
                    traits: [LookTrait("shows", "What the board leads with", values: ["week", "bests", "last sets"],
                                       designed: "week")]),
        ElementForm("tickets", "The Galley's rail of tickets", shapes: [.few, .many], places: ["keystone"],
                    rooms: ["galley"], traits: [count]),
        ElementForm("woods", "The Watch's woodland, a tree per routine", shapes: [.few, .many],
                    places: ["keystone"], rooms: ["watch"]),
        ElementForm("sky", "The Lookout's sky under raised glass", shapes: [.measure, .one], places: ["keystone"],
                    rooms: ["lookout"]),
        ElementForm("chart", "The Purse's index chart", shapes: [.measure, .many], places: ["keystone"],
                    rooms: ["purse"]),
    ]

    public static func form(_ name: String) -> ElementForm? {
        all.first { $0.name == name.lowercased() }
    }

    /// The forms one place could take for its content, the studio's own first.
    public static func forms(place: String, room: String, shape: ContentShape, designed: String? = nil)
        -> [ElementForm]
    {
        let fits = all.filter { $0.fits(place: place, room: room, shape: shape) }
        guard let designed, let first = fits.firstIndex(where: { $0.name == designed }) else { return fits }
        return [fits[first]] + fits.enumerated().filter { $0.offset != first }.map { $0.element }
    }
}

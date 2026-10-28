import Foundation

// The Chart room's kit (R1, docs/design/tess-built-rooms/r1-spec.md section 3): the twelve kinds of part a room can
// hold, the places each may sit in, the props each takes, and the limits the validator holds a patch to. Builder A
// draws the kinds; Core only names and checks them. The kit description that goes to the model is generated from
// this table, so a kind added here reaches the model and the validator at once.

public enum RoomKit {
    public struct Kind: Sendable, Equatable {
        public let name: String
        /// The shell places this kind may sit in (`Place` raw values).
        public let places: [String]
        /// The prop keys it takes, and nothing else.
        public let props: [String]
        /// One line for the model.
        public let summary: String
    }

    public nonisolated static let kinds: [Kind] = [
        Kind(name: "title", places: ["title"], props: ["text", "color"], summary: "The room's title, 40 pt"),
        Kind(name: "line", places: ["switcher", "caption"], props: ["text", "color", "words"],
             summary: "One sentence, or static words; {count}, {top} and {fieldKey} fill in from the bound class"),
        Kind(name: "lines", places: ["needs", "caption"], props: ["lines", "windows"],
             summary: "Up to two short lines; windows are static records, a|b|c with | between the parts"),
        Kind(name: "number", places: ["keystone", "widget"], props: ["label", "unit", "field", "agg"],
             summary: "One big number from the bound class: agg is count, sum, avg, min, max or latest"),
        Kind(name: "row", places: ["keystone", "widget"], props: ["big", "small", "sort", "max"],
             summary: "A ranked row of numerals over names, at most 4"),
        Kind(name: "list", places: ["widget", "page"], props: ["big", "small", "sort", "max", "cards"],
             summary: "A ranked list: big field, small field, sort, max rows; cards are static records, a|b|c|d|color"),
        Kind(name: "stack", places: ["keystone", "widget"], props: ["children", "axis", "gap"],
             summary: "Layout only: child part ids in the same place, axis h or v"),
        Kind(name: "grid", places: ["keystone", "widget"], props: ["children", "columns"],
             summary: "Layout only: child part ids in the same place, 2 to 4 columns"),
        Kind(name: "glyph", places: ["glyph"], props: ["symbol", "color"],
             summary: "An SF Symbol from the vetted list"),
        Kind(name: "doors", places: ["dial", "doorSummary"], props: ["doors", "summary"],
             summary: "Doors bound to a class (one per object; summary is the field its line reads), or a list of {name, bind} or static records a|b|c"),
        Kind(name: "actionWord", places: ["actionWord"], props: ["verb", "object", "does"],
             summary: "A hold-to-do word; does is one field write, e.g. write Plant.lastWatered"),
        Kind(name: "top", places: ["keystone", "widget", "page"], props: ["on", "field"],
             summary: "Modifier: highlights the top item of the row or list named by on, ranked by field"),
    ]

    public nonisolated static func kind(_ name: String) -> Kind? {
        kinds.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// The shell places a room can fill, in the order the shell draws them.
    public nonisolated static let places = [
        "title",
        "switcher",
        "needs",
        "keystone",
        "caption",
        "widget",
        "glyph",
        "dial",
        "doorSummary",
        "page",
        "actionWord",
    ]
    /// Places that hold exactly one part.
    public nonisolated static let singleOccupantPlaces: Set<String> = ["title", "glyph", "actionWord"]
    public nonisolated static let maxParts = 24
    public nonisolated static let maxText = 80
    public nonisolated static let maxRows = 12
    /// A static record (a|b|c with | between its parts) holds 120 characters, each part 80.
    public nonisolated static let maxRecord = 120
    /// Props whose strings are records or lists of words, not single lines.
    public nonisolated static let recordProps: Set<String> = ["words", "windows", "cards", "doors"]
    /// Traits a room's look takes beyond the studio's LookCatalog: the room's own glyph set, its Say word, and the way
    /// a row is drawn.
    public nonisolated static let roomTraits: [String: Set<String>] = [
        "glyph": ["can", "leaf", "grove", "drop"], "say": ["kept", "off"], "way": ["row", "one", "ladder"],
    ]
    /// A room shows three to four colors; counted in color roles.
    public nonisolated static let maxColors = 4
    /// Theme color roles only, never hex: ink and its softer self, the wine of a warning, slate (the Chart room's own),
    /// and each app's accent. Ember and cobalt are Tess's and never a room's or a part's.
    public nonisolated static let colorRoles = ["ink", "inkSoft", "wine", "slate", "ochre", "sage", "violet", "olive",
                                                "dusk", "rain"]
    /// Roles that are Tess's: a request for one gets a refusal with slate offered.
    public nonisolated static let tessRoles: Set<String> = ["ember", "cobalt"]
    /// The vetted SF Symbols a glyph part may name.
    public nonisolated static let glyphs = [
        "leaf", "drop", "flame", "bolt", "heart", "star", "moon", "sun.max", "cloud.rain", "figure.walk",
        "dumbbell", "fork.knife", "cup.and.saucer", "book", "pencil", "checklist", "calendar", "clock", "chart.bar",
        "chart.line.uptrend.xyaxis", "bed.double", "cart", "house", "sparkles",
    ]
    /// Classes a room can never write: pools and the money that moves through them.
    public nonisolated static let moneyClassKeys: [SystemCatalog.Key] = [.pool, .inflow, .poolMove, .spend, .rateNote]
    /// Functions a sort may wrap a field in.
    public nonisolated static let sortFunctions = ["daysSince"]
    public nonisolated static let aggregates = ["count", "sum", "avg", "min", "max", "latest"]

    /// What the model reads: the kit, generated from the table above.
    public nonisolated static var description: String {
        var lines = ["Parts (kind: places; props; what it is):"]
        for kind in kinds {
            lines.append("- \(kind.name): \(kind.places.joined(separator: ", ")); \(kind.props.joined(separator: ", ")); "
                + kind.summary)
        }
        lines.append("Single-occupant places: \(singleOccupantPlaces.sorted().joined(separator: ", ")).")
        lines.append("At most \(maxParts) parts, \(maxText) characters a line, no full stop at the end of a line.")
        lines.append("Colors are roles only: \(colorRoles.joined(separator: ", ")); at most \(maxColors) in use.")
        lines.append("Glyph symbols: \(glyphs.joined(separator: ", ")).")
        return lines.joined(separator: "\n")
    }
}

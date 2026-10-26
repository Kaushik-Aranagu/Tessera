import Foundation

// Living looks (Design sheet 286, docs/design/living-looks-286.md; docs/ai/harness/element-looks.md). A look is how a
// place draws its meaning: it keeps the place's frame, items, focus and calls, so Tess's frame is the same in every
// look. Looks are settings, kept per room and place or for every room; changing one writes nothing to his things. A
// keystone is its room's identity and has only Quiet. Layout mode and Tess list the same looks from here.

/// One look a place can take.
public struct LookDef: Sendable, Equatable, Identifiable {
    /// Stable id, kept in settings ("column").
    public var id: String
    /// What he sees in Layout mode and what Tess says ("Column").
    public var name: String
    /// Words that name it, lowercase ("as a column", "a list").
    public var phrases: [String]
    /// The rooms that can show it; empty is any. By time needs rows with times.
    public var rooms: Set<String>

    public init(_ id: String, _ name: String, phrases: [String] = [], rooms: Set<String> = []) {
        self.id = id
        self.name = name
        self.phrases = phrases
        self.rooms = rooms
    }

    public func fits(room: String) -> Bool {
        rooms.isEmpty || rooms.contains(room.lowercased())
    }
}

public enum LookCatalog {
    /// Place by place (`ElementPlace` raw values), the default first. Sheet 286, section 2.
    public static let byPlace: [String: [LookDef]] = [
        "switcher": [
            LookDef("wordsAcross", "Words across", phrases: ["words across"]),
            LookDef("rollWord", "Roll word", phrases: ["roll word", "roll"]),
        ],
        "needs": [
            LookDef("twoLines", "Two lines", phrases: ["two lines"]),
            LookDef("oneLine", "One line", phrases: ["one line"]),
            LookDef("count", "Count", phrases: ["count", "a count", "just the count"]),
        ],
        "widget": [
            LookDef("oneThing", "One thing", phrases: ["one thing", "one at a time"]),
            LookDef("oneAndNext", "One and next", phrases: ["one and next", "and the next", "show the next"]),
            LookDef("quiet", "Quiet", phrases: ["quiet", "quieter", "big line only"]),
        ],
        "glyph": [
            LookDef("drawn", "Drawn", phrases: ["drawn"]),
            LookDef("none", "None", phrases: ["none", "no glyph", "hide the glyph"]),
        ],
        "dial": [
            LookDef("reel", "Reel", phrases: ["reel", "a reel"]),
            LookDef("column", "Column", phrases: ["column", "a column", "list", "a list"]),
            LookDef("sentence", "Sentence", phrases: ["sentence", "a sentence"]),
        ],
        "doorSummary": [
            LookDef("lines", "Lines", phrases: ["lines"]),
            LookDef("oneSentence", "One sentence", phrases: ["one sentence"]),
            LookDef("numbers", "Numbers", phrases: ["numbers", "just numbers", "just the numbers"]),
        ],
        "page": [
            LookDef("ranked", "Ranked", phrases: ["ranked"]),
            LookDef("even", "Even", phrases: ["even"]),
            LookDef("twoColumns", "Two columns", phrases: ["two columns"]),
            LookDef("byTime", "By time", phrases: ["by time", "by the time"],
                    rooms: ["watch", "galley", "lookout", "deck"]),
        ],
        "actionWord": [
            LookDef("wordAndLine", "Word and line", phrases: ["word and line"]),
            LookDef("wordOnly", "Word only", phrases: ["word only", "just the word"]),
        ],
        "tess": [
            LookDef("soul", "Soul", phrases: ["soul"]),
            LookDef("still", "Still", phrases: ["still", "stop moving", "keep still"]),
        ],
        // A keystone has no other look: only Quiet (same picture, fewer moving parts, no idle motion).
        "keystone": [
            LookDef("drawn", "As drawn", phrases: ["as drawn"]),
            LookDef("quiet", "Quiet", phrases: ["quiet", "quieter", "calmer", "stop animating", "stop moving"]),
        ],
    ]

    /// The looks one place can take in one room, the default first.
    public static func looks(for place: String, room: String = "") -> [LookDef] {
        (byPlace[place] ?? []).filter { room.isEmpty || $0.fits(room: room) }
    }

    public static func defaultLook(for place: String) -> LookDef? {
        byPlace[place]?.first
    }

    public static func look(_ id: String, for place: String) -> LookDef? {
        byPlace[place]?.first { $0.id == id }
    }
}

/// Where a look is kept: one room, or every room.
public enum LookScope: Sendable, Equatable {
    case room(String)
    case everywhere
}

/// His looks, kept in settings: per room and place, then for every room, then the default. Plain values; the shell
/// reads them for `SlotContent.look`, Layout mode and Tess write them through settings.
public struct RoomLooks: Sendable, Equatable, Codable {
    /// Room, then place, to look id.
    public var rooms: [String: [String: String]] = [:]
    /// Place to look id, for every room.
    public var everywhere: [String: String] = [:]

    public init(rooms: [String: [String: String]] = [:], everywhere: [String: String] = [:]) {
        self.rooms = rooms
        self.everywhere = everywhere
    }

    /// The look a place shows in a room: the room's, then every room's, then the default. A kept look that no longer
    /// exists, or that this room can't show, falls through.
    public func look(room: String, place: String) -> String {
        let room = room.lowercased()
        for id in [rooms[room]?[place], everywhere[place]].compactMap({ $0 }) {
            if let look = LookCatalog.look(id, for: place), look.fits(room: room) {
                return look.id
            }
        }
        return LookCatalog.defaultLook(for: place)?.id ?? ""
    }

    /// With one look set. The default for a room clears the room's own entry, so every room's look shows again.
    /// Nil when the place has no such look or the room can't show it.
    public func setting(_ id: String, place: String, scope: LookScope) -> RoomLooks? {
        guard let look = LookCatalog.look(id, for: place) else { return nil }
        var next = self
        switch scope {
        case let .room(name):
            let room = name.lowercased()
            guard look.fits(room: room) else { return nil }
            next.rooms[room, default: [:]][place] = id
        case .everywhere:
            guard look.rooms.isEmpty else { return nil }
            next.everywhere[place] = id == LookCatalog.defaultLook(for: place)?.id ? nil : id
        }
        return next
    }

    /// Whether the Undo line offers "Everywhere" (sheet 286): Tess set a look in one room and other rooms can show it
    /// but don't.
    public func offersEverywhere(_ id: String, place: String, room: String) -> Bool {
        guard let look = LookCatalog.look(id, for: place), look.rooms.isEmpty else { return false }
        return everywhere[place] != id
    }

    public var encoded: String? {
        guard !rooms.isEmpty || !everywhere.isEmpty else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(self)).flatMap { String(data: $0, encoding: .utf8) }
    }

    public init(encoded: String?) {
        guard let encoded, let data = encoded.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(RoomLooks.self, from: data) else { return }
        self = decoded
    }
}

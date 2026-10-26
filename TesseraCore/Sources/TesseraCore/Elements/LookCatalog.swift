import Foundation

// Living looks (Design sheets 286 and 287, docs/ai/harness/element-looks.md). A look is a place's form plus its
// traits: it keeps the place's frame, items, focus and calls, so Tess's frame is the same in every look. Looks are
// settings, kept per room and place or for every room, and each field inherits: a room names only what differs from
// every room, which names only what differs from the studio's design. A keystone keeps its room's material and tunes
// only its motion. Shape mode, Settings > Layout mode and Tess all read the same table from here.

/// One form a place can take, and the rooms that can show it there (empty is any).
public struct FormSlot: Sendable, Equatable {
    public var form: String
    public var rooms: Set<String>

    public init(_ form: String, rooms: Set<String> = []) {
        self.form = form
        self.rooms = rooms
    }

    public func fits(room: String) -> Bool {
        rooms.isEmpty || rooms.contains(room.lowercased())
    }
}

/// What one place may become: its forms, the designed one first, and the traits every form there takes.
public struct PlaceForms: Sendable, Equatable {
    public var forms: [FormSlot]
    public var traits: [LookTrait]
}

public enum LookCatalog {
    // MARK: Traits (sheet 287, section 6)

    static let density = LookTrait("density", "How close things sit; an index of more than 5 doors takes two columns",
                                   values: ["airy", "designed", "dense"], designed: "designed",
                                   up: ["denser", "tighter"], down: ["airier", "more room", "more space"])
    static let numbers = LookTrait("facts", "What shows beside the words", values: ["designed", "numbers"],
                                   designed: "designed",
                                   named: ["numbers only": "numbers", "just numbers": "numbers",
                                           "just the numbers": "numbers"])
    static let names = LookTrait("facts", "What shows: just names is the Big line only, with no glyph",
                                 values: ["names", "designed"], designed: "designed", up: ["more detail"],
                                 down: ["less detail"],
                                 named: ["just names": "names", "just the names": "names", "names only": "names"])
    static let lines = LookTrait("count", "How many lines", values: ["1", "2"], designed: "2",
                                 named: ["one line": "1", "two lines": "2"])
    static let size = LookTrait("size", "How big the type is, from the room's own scale, never under the floor",
                                values: ["smaller", "designed", "bigger"], designed: "designed",
                                up: ["bigger", "larger"], down: ["smaller"])
    static let glyph = LookTrait("shows", "Whether the glyph shows", values: ["off", "on"], designed: "on",
                                 named: ["hide the glyph": "off", "no glyph": "off", "show the glyph": "on"])
    static let weight = LookTrait("weight", "Ranked rows step from 1.7 to 0.84; even rows are one size",
                                  values: ["even", "ranked"], designed: "ranked",
                                  named: ["even": "even", "evenly": "even", "ranked": "ranked"])
    static let order = LookTrait("order", "What comes first; by time adds a time column", values: ["rank", "time"],
                                 designed: "rank", named: ["by time": "time", "by the time": "time", "by rank": "rank"])
    /// Never past what the studio drew; Reduce Motion still wins, and still is `LiveSwitch.quiet`.
    static let motion = LookTrait("motion", "How much it moves at rest", values: ["still", "calm", "designed"],
                                  designed: "designed", up: ["livelier"], down: ["calmer", "quieter", "slower"],
                                  named: ["still": "still", "stop moving": "still", "stop animating": "still"])
    static let word = LookTrait("shows", "The action word alone, or with its line", values: ["word", "wordAndLine"],
                                designed: "wordAndLine",
                                named: ["word only": "word", "just the word": "word", "word and line": "wordAndLine"])

    // MARK: Places (sheet 287, section 6; `ElementPlace` raw values)

    public static let places: [String: PlaceForms] = [
        "switcher": PlaceForms(forms: [FormSlot("type"), FormSlot("roll")], traits: []),
        "needs": PlaceForms(forms: [FormSlot("type")], traits: [lines, numbers]),
        "widget": PlaceForms(forms: [FormSlot("rise"), FormSlot("stack"), FormSlot("rows"),
                                     FormSlot("ledger", rooms: ["purse"]),
                                     FormSlot("trace", rooms: ["lookout", "purse"])],
                             traits: [names, size]),
        "glyph": PlaceForms(forms: [FormSlot("drawing"), FormSlot("trace")], traits: [glyph]),
        "dial": PlaceForms(forms: [FormSlot("reel"), FormSlot("index"), FormSlot("sentence")], traits: [density]),
        "doorSummary": PlaceForms(forms: [FormSlot("type"), FormSlot("sentence")], traits: [numbers]),
        "page": PlaceForms(forms: [FormSlot("rows"), FormSlot("columns"), FormSlot("wall"), FormSlot("ledger"),
                                   FormSlot("stack")],
                           traits: [weight, order, density]),
        // A keystone is its room's identity: its own material only, tuned by motion (and the board's or rail's own).
        "keystone": PlaceForms(forms: [FormSlot("mosaic", rooms: ["bridge"]), FormSlot("wordWall", rooms: ["log"]),
                                       FormSlot("chalk", rooms: ["deck"]), FormSlot("tickets", rooms: ["galley"]),
                                       FormSlot("woods", rooms: ["watch"]), FormSlot("sky", rooms: ["lookout"]),
                                       FormSlot("chart", rooms: ["purse"])],
                               traits: [motion]),
        "actionWord": PlaceForms(forms: [FormSlot("type")], traits: [word]),
    ]

    /// The forms one place can take in one room, the designed one first. With no room: the forms every room has.
    public static func forms(for place: String, room: String? = nil) -> [ElementForm] {
        slots(place, room: room).compactMap { ElementForms.form($0.form) }
    }

    static func slots(_ place: String, room: String?) -> [FormSlot] {
        (places[place]?.forms ?? []).filter { slot in room.map { slot.fits(room: $0) } ?? slot.rooms.isEmpty }
    }

    /// The studio's form for a place in a room: the first that fits.
    public static func designed(_ place: String, room: String) -> String? {
        slots(place, room: room).first?.form
    }

    /// The traits a place takes in a form: the place's, then the form's own.
    public static func traits(for place: String, form: String?) -> [LookTrait] {
        (places[place]?.traits ?? []) + (form.flatMap { ElementForms.form($0)?.traits } ?? [])
    }

    /// Whether a place has anything to change in a room: another form, or a trait.
    public static func isLiving(_ place: String, room: String) -> Bool {
        forms(for: place, room: room).count > 1 || !traits(for: place, form: designed(place, room: room)).isEmpty
    }
}

/// Where a look is kept: one room, or every room.
public enum LookScope: Sendable, Equatable {
    case room(String)
    case everywhere
}

/// One change to a place's look: another form, one trait to a value, or back to the studio's design.
public enum LookChange: Sendable, Equatable {
    case form(String)
    case trait(String, String)
    case designed
}

/// What a place shows, or what one scope says about it. Unnamed fields inherit.
public struct PlaceLook: Sendable, Equatable, Codable {
    public var form: String?
    public var traits: [String: String]

    public init(form: String? = nil, traits: [String: String] = [:]) {
        self.form = form
        self.traits = traits
    }

    public var isEmpty: Bool {
        form == nil && traits.isEmpty
    }
}

/// His looks, kept in settings. Plain values: the shell reads them for `SlotContent.look`, and shape mode, Layout mode
/// and Tess write them through settings.
public struct RoomLooks: Sendable, Equatable, Codable {
    /// Room, then place.
    public var rooms: [String: [String: PlaceLook]] = [:]
    /// Place, for every room.
    public var everywhere: [String: PlaceLook] = [:]

    public init(rooms: [String: [String: PlaceLook]] = [:], everywhere: [String: PlaceLook] = [:]) {
        self.rooms = rooms
        self.everywhere = everywhere
    }

    /// What a place shows in a room, every field filled: the room's, then every room's, then the studio's. A kept
    /// form or value that no longer exists, or that this room can't show, falls through.
    public func look(room: String, place: String) -> PlaceLook {
        let room = room.lowercased()
        let kept = [rooms[room]?[place], everywhere[place]].compactMap { $0 }
        let slots = LookCatalog.slots(place, room: room)
        let form = kept.compactMap(\.form).first { id in slots.contains { $0.form == id } }
            ?? LookCatalog.designed(place, room: room)
        var traits: [String: String] = [:]
        for trait in LookCatalog.traits(for: place, form: form) {
            traits[trait.name] = kept.compactMap { $0.traits[trait.name] }.first { trait.values.contains($0) }
                ?? trait.designed
        }
        return PlaceLook(form: form, traits: traits)
    }

    /// With one change made. Nil when the place has no such form or value, the room can't show it, or it is tied to
    /// some rooms and the scope is every room. A value the scope would inherit anyway is cleared, not stored.
    public func applying(_ change: LookChange, place: String, scope: LookScope) -> RoomLooks? {
        var next = self
        let room: String?
        switch scope {
        case let .room(name): room = name.lowercased()
        case .everywhere: room = nil
        }
        // This scope's own entry, and what it would show without it.
        var entry: PlaceLook
        var without = self
        let inherited: PlaceLook
        if let room {
            entry = rooms[room]?[place] ?? PlaceLook()
            without.rooms[room]?[place] = nil
            inherited = without.look(room: room, place: place)
        } else {
            entry = everywhere[place] ?? PlaceLook()
            inherited = studio(place)
        }
        switch change {
        case let .form(id):
            guard LookCatalog.slots(place, room: room).contains(where: { $0.form == id }) else { return nil }
            entry.form = id == inherited.form ? nil : id
        case let .trait(name, value):
            // Every room takes only the place's own traits; one room also takes its form's.
            let form: String? = room.flatMap { look(room: $0, place: place).form }
            guard let trait = LookCatalog.traits(for: place, form: form).first(where: { $0.name == name }),
                  trait.values.contains(value) else { return nil }
            entry.traits[name] = value == inherited.traits[name] ? nil : value
        case .designed:
            if let room {
                // Back to the studio's, over whatever every room says.
                let drawn = studio(place, room: room)
                entry = without.look(room: room, place: place) == drawn ? PlaceLook() : drawn
            } else {
                entry = PlaceLook()
                for key in next.rooms.keys {
                    next.rooms[key]?[place] = nil
                }
            }
        }
        if let room {
            next.rooms[room, default: [:]][place] = entry.isEmpty ? nil : entry
        } else {
            next.everywhere[place] = entry.isEmpty ? nil : entry
        }
        next.rooms = next.rooms.filter { !$0.value.isEmpty }
        return next
    }

    /// The studio's look for a place, every field filled. With no room, only the forms every room has.
    func studio(_ place: String, room: String? = nil) -> PlaceLook {
        let form = room.flatMap { LookCatalog.designed(place, room: $0) }
            ?? LookCatalog.slots(place, room: nil).first?.form
        var traits: [String: String] = [:]
        for trait in LookCatalog.traits(for: place, form: form) {
            traits[trait.name] = trait.designed
        }
        return PlaceLook(form: form, traits: traits)
    }

    /// Whether the Undo line offers "Everywhere" (sheet 286): the change was made in one room, every room can take
    /// it, and every room doesn't already.
    public func offersEverywhere(_ change: LookChange, place: String) -> Bool {
        switch change {
        case let .form(id):
            LookCatalog.slots(place, room: nil).contains { $0.form == id } && everywhere[place]?.form != id
        case let .trait(name, value):
            (LookCatalog.places[place]?.traits ?? []).contains { $0.name == name }
                && everywhere[place]?.traits[name] != value
        case .designed:
            false
        }
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

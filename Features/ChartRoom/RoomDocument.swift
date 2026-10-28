import Foundation

// The Chart room's document (R1 spec, docs/design/tess-built-rooms/r1-spec.md): a room is a JSON description of parts.
// Core owns the stored form (the `room` and `roomPart` classes); this is the player's reading of it, a pure value that
// decodes from the same shape, so Core's fixture room can be swapped in with no change here. Pure: no views, no store.

/// The twelve parts of the kit (spec section 3). `top` is a modifier on a `row` or `list`, not a place of its own.
enum PartKind: String, Codable, CaseIterable, Sendable {
    case title, line, lines, number, row, list, stack, grid, glyph, doors, actionWord, top

    /// The shell places a part of this kind may sit in.
    var places: [Place] {
        switch self {
        case .title: [.title]
        case .line: [.switcher, .caption]
        case .lines: [.needs, .caption]
        case .number, .row, .stack, .grid: [.keystone, .widget]
        case .list: [.widget, .page]
        case .glyph: [.glyph]
        case .doors: [.dial, .doorSummary]
        case .actionWord: [.actionWord]
        case .top: []
        }
    }
}

/// One value in a part's `props`: text, a number, a flag or a list of texts.
enum PropValue: Codable, Equatable, Sendable {
    case text(String)
    case number(Double)
    case flag(Bool)
    case texts([String])

    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if let value = try? box.decode(Bool.self) {
            self = .flag(value)
        } else if let value = try? box.decode(Double.self) {
            self = .number(value)
        } else if let value = try? box.decode(String.self) {
            self = .text(value)
        } else {
            self = try .texts(box.decode([String].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.singleValueContainer()
        switch self {
        case let .text(value): try box.encode(value)
        case let .number(value): try box.encode(value)
        case let .flag(value): try box.encode(value)
        case let .texts(value): try box.encode(value)
        }
    }
}

typealias PartProps = [String: PropValue]

extension [String: PropValue] {
    func text(_ key: String) -> String? {
        if case let .text(value) = self[key] {
            value
        } else {
            nil
        }
    }

    func number(_ key: String) -> Double? {
        if case let .number(value) = self[key] {
            value
        } else {
            nil
        }
    }

    func texts(_ key: String) -> [String] {
        switch self[key] {
        case let .texts(values): values
        case let .text(value): [value]
        default: []
        }
    }
}

/// One part of a room: a stable id (its object title, so later sentences can name it), a kind, the place it fills,
/// its props and an optional bind (an `ObjectPath` query, resolved at render time).
struct ChartPart: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var kind: PartKind
    var place: String
    var props: PartProps = [:]
    var bind: String?

    init(id: String, kind: PartKind, place: String, props: PartProps = [:], bind: String? = nil) {
        self.id = id
        self.kind = kind
        self.place = place
        self.props = props
        self.bind = bind
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = try box.decode(String.self, forKey: .id)
        kind = try box.decode(PartKind.self, forKey: .kind)
        place = try box.decodeIfPresent(String.self, forKey: .place) ?? ""
        props = try box.decodeIfPresent(PartProps.self, forKey: .props) ?? [:]
        bind = try box.decodeIfPresent(String.self, forKey: .bind)
    }

    /// The place as the shell names it, nil when the room named one that does not exist.
    var shellPlace: Place? {
        Place(rawValue: place)
    }
}

/// A room as a document: its name, its colour role (never hex), its look traits, what it may reach, and its parts in
/// order (a part's order within a place is its position here).
struct ChartDoc: Codable, Equatable, Sendable {
    var name: String
    var color: String = "slate"
    var look: [String: String] = [:]
    var reach: [String] = []
    var parts: [ChartPart] = []

    init(name: String, color: String = "slate", look: [String: String] = [:], reach: [String] = [],
         parts: [ChartPart] = [])
    {
        self.name = name
        self.color = color
        self.look = look
        self.reach = reach
        self.parts = parts
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        name = try box.decode(String.self, forKey: .name)
        color = try box.decodeIfPresent(String.self, forKey: .color) ?? "slate"
        look = try box.decodeIfPresent([String: String].self, forKey: .look) ?? [:]
        reach = try box.decodeIfPresent([String].self, forKey: .reach) ?? []
        parts = try box.decodeIfPresent([ChartPart].self, forKey: .parts) ?? []
    }

    static func decode(_ json: String) throws -> ChartDoc {
        try JSONDecoder().decode(ChartDoc.self, from: Data(json.utf8))
    }

    func encoded() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    func part(_ id: String) -> ChartPart? {
        parts.first { $0.id == id }
    }

    /// Ids drawn inside another part (a stack's or grid's children): never placed on their own.
    var childIDs: Set<String> {
        Set(parts.filter { $0.kind == .stack || $0.kind == .grid }.flatMap { $0.props.texts("children") })
    }

    /// The top-level parts of one place, in order.
    func parts(in place: Place) -> [ChartPart] {
        let children = childIDs
        return parts.filter { $0.shellPlace == place && $0.kind.places.contains(place) && !children.contains($0.id) }
    }

    /// Every place the document fills.
    var filledPlaces: Set<Place> {
        Set(Place.allCases.filter { !parts(in: $0).isEmpty })
    }
}

// MARK: - Patch (the tool's shape, spec section 2)

/// One op of a Tess patch, as the `patchRoom` tool writes it.
enum PatchOp: Equatable, Sendable {
    case add(ChartPart)
    case set(id: String, props: PartProps, bind: String?)
    case remove(id: String)
    case move(id: String, place: String, index: Int?)
    case look(trait: String, value: String)
    case grant(String)
}

extension PatchOp: Codable {
    private enum Keys: String, CodingKey { case op, id, kind, place, props, bind, trait, value, reach, index }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: Keys.self)
        switch try box.decode(String.self, forKey: .op) {
        case "add":
            self = try .add(ChartPart(
                id: box.decode(String.self, forKey: .id), kind: box.decode(PartKind.self, forKey: .kind),
                place: box.decodeIfPresent(String.self, forKey: .place) ?? "",
                props: box.decodeIfPresent(PartProps.self, forKey: .props) ?? [:],
                bind: box.decodeIfPresent(String.self, forKey: .bind)
            ))
        case "set":
            self = try .set(id: box.decode(String.self, forKey: .id),
                            props: box.decodeIfPresent(PartProps.self, forKey: .props) ?? [:],
                            bind: box.decodeIfPresent(String.self, forKey: .bind))
        case "remove":
            self = try .remove(id: box.decode(String.self, forKey: .id))
        case "move":
            self = try .move(id: box.decode(String.self, forKey: .id), place: box.decode(String.self, forKey: .place),
                             index: box.decodeIfPresent(Int.self, forKey: .index))
        case "look":
            self = try .look(trait: box.decode(String.self, forKey: .trait),
                             value: box.decode(String.self, forKey: .value))
        case "grant":
            self = try .grant(box.decode(String.self, forKey: .reach))
        default:
            throw DecodingError.dataCorruptedError(forKey: .op, in: box, debugDescription: "unknown op")
        }
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: Keys.self)
        switch self {
        case let .add(part):
            try box.encode("add", forKey: .op)
            try box.encode(part.id, forKey: .id)
            try box.encode(part.kind, forKey: .kind)
            try box.encode(part.place, forKey: .place)
            try box.encode(part.props, forKey: .props)
            try box.encodeIfPresent(part.bind, forKey: .bind)
        case let .set(id, props, bind):
            try box.encode("set", forKey: .op)
            try box.encode(id, forKey: .id)
            try box.encode(props, forKey: .props)
            try box.encodeIfPresent(bind, forKey: .bind)
        case let .remove(id):
            try box.encode("remove", forKey: .op)
            try box.encode(id, forKey: .id)
        case let .move(id, place, index):
            try box.encode("move", forKey: .op)
            try box.encode(id, forKey: .id)
            try box.encode(place, forKey: .place)
            try box.encodeIfPresent(index, forKey: .index)
        case let .look(trait, value):
            try box.encode("look", forKey: .op)
            try box.encode(trait, forKey: .trait)
            try box.encode(value, forKey: .value)
        case let .grant(reach):
            try box.encode("grant", forKey: .op)
            try box.encode(reach, forKey: .reach)
        }
    }
}

/// A Tess patch: the receipt line (`say`, no full stop) and its ops. One op group, shown as a ghost until it commits.
struct ChartPatch: Codable, Equatable, Sendable {
    var room: String = "Chart room"
    var say: String
    var ops: [PatchOp]
    /// What he said, shown in the widget place in quotes while Tess works (not part of the tool's call).
    var heard: String = ""

    init(room: String = "Chart room", say: String, ops: [PatchOp], heard: String = "") {
        self.room = room
        self.say = say
        self.ops = ops
        self.heard = heard
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        room = try box.decodeIfPresent(String.self, forKey: .room) ?? "Chart room"
        say = try box.decode(String.self, forKey: .say)
        ops = try box.decode([PatchOp].self, forKey: .ops)
        heard = try box.decodeIfPresent(String.self, forKey: .heard) ?? ""
    }

    static func decode(_ json: String) throws -> ChartPatch {
        try JSONDecoder().decode(ChartPatch.self, from: Data(json.utf8))
    }

    /// A patch that lets the room write his data waits for Allow and never commits on the drying line alone.
    var widensReach: Bool {
        ops.contains {
            if case .grant = $0 {
                true
            } else {
                false
            }
        }
    }

    /// The grant the patch asks for, in words: "mark plants watered" for `write Plant.lastWatered`.
    var grantLine: String? {
        for case let .grant(reach) in ops {
            return reach
        }
        return nil
    }

    /// The places the patch fills or changes (their outlines let go, and their drying line runs).
    func places(in before: ChartDoc) -> [Place] {
        let after = before.applying(self)
        return Place.allCases.filter { before.parts(in: $0) != after.parts(in: $0) }
    }
}

extension ChartDoc {
    /// The document after a patch (pure; undo is the document before). An op naming an unknown part is skipped.
    func applying(_ patch: ChartPatch) -> ChartDoc {
        var next = self
        for op in patch.ops {
            switch op {
            case let .add(part):
                next.parts.removeAll { $0.id == part.id }
                next.parts.append(part)
            case let .set(id, props, bind):
                guard let index = next.parts.firstIndex(where: { $0.id == id }) else { continue }
                for (key, value) in props {
                    next.parts[index].props[key] = value
                }
                if let bind {
                    next.parts[index].bind = bind
                }
            case let .remove(id):
                next.parts.removeAll { $0.id == id }
            case let .move(id, place, index):
                guard let at = next.parts.firstIndex(where: { $0.id == id }) else { continue }
                var part = next.parts.remove(at: at)
                part.place = place
                let peers = next.parts.indices.filter { next.parts[$0].place == place }
                if let index, index < peers.count {
                    next.parts.insert(part, at: peers[index])
                } else {
                    next.parts.append(part)
                }
            case let .look(trait, value):
                next.look[trait] = value
            case let .grant(reach):
                if !next.reach.contains(reach) {
                    next.reach.append(reach)
                }
            }
        }
        return next
    }
}

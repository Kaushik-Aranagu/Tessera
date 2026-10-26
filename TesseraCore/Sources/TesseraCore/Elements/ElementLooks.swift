import Foundation

// A place's look, kept as an `elementLook` object (docs/ai/harness/element-looks.md). One row per scope: a room's
// place at one level, a room's place at every level, or a place in every room. The most specific row wins; a row
// with no form leaves the studio's form in place. Written through actions, so his hand and Tess both get the op log,
// the ghost row and the 10 s Undo, and a look he keeps is history he can browse like any object.

/// Where a look applies. `room` empty is every room; `level` empty is every level ("landing" or "door").
public struct LookScope: Sendable, Hashable, Codable {
    public var room: String
    public var place: String
    public var level: String

    public init(room: String = "", place: String, level: String = "") {
        self.room = room.lowercased()
        self.place = place
        self.level = level.lowercased()
    }

    /// From the most general to this one, so later rows win.
    public var cascade: [LookScope] {
        var out = [LookScope(place: place)]
        if !level.isEmpty {
            out.append(LookScope(place: place, level: level))
        }
        if !room.isEmpty {
            out.append(LookScope(room: room, place: place))
            if !level.isEmpty {
                out.append(self)
            }
        }
        return out
    }

    /// The row's title in the object browser: "Deck dial", "Every dial".
    public var title: String {
        let whereWord = room.isEmpty ? "Every" : room.prefix(1).uppercased() + room.dropFirst()
        let at = level == "door" ? " on door pages" : level == "landing" ? " on the landing" : ""
        return "\(whereWord) \(place)\(at)"
    }
}

/// A place's look as the shell draws it: the form and every trait's value.
public struct ResolvedLook: Sendable, Equatable {
    public var form: ElementForm
    public var traits: [String: String]
    /// Whether anything differs from the studio's look.
    public var isChanged: Bool
    /// The form the studio drew for this place.
    public var designed: String
}

@MainActor
public enum ElementLooks {
    /// The look one place takes: the studio's form and values, then each row of its cascade over them. A stored form
    /// that can't draw today's content (the shape changed) is passed over, never forced.
    public static func look(_ scope: LookScope, shape: ContentShape, designed: String, store: ObjectStore,
                            classes: [SystemCatalog.Key: ClassDef]) -> ResolvedLook?
    {
        guard let base = ElementForms.form(designed) else { return nil }
        var form = base
        var picked: [String: String] = [:]
        for row in scope.cascade.compactMap({ self.row($0, store: store, classes: classes) }) {
            if let name = store.value("form", of: row)?.stringValue, !name.isEmpty,
               let stored = ElementForms.form(name), stored.fits(place: scope.place, room: scope.room, shape: shape)
            {
                form = stored
            }
            picked.merge(decode(store.value("traits", of: row)?.stringValue)) { _, new in new }
        }
        var traits: [String: String] = [:]
        for trait in form.allTraits {
            let value = picked[trait.name].flatMap { trait.values.contains($0) ? $0 : nil }
            traits[trait.name] = value ?? trait.designed
        }
        let changed = form.name != base.name || form.allTraits.contains { traits[$0.name] != $0.designed }
        return ResolvedLook(form: form, traits: traits, isChanged: changed, designed: base.name)
    }

    /// The row kept for exactly this scope, if any.
    public static func row(_ scope: LookScope, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef])
        -> ObjectRecord?
    {
        guard let lookClass = classes[.elementLook] else { return nil }
        return store.objects(of: lookClass).first { row in
            !row.isDeleted && (store.value("room", of: row)?.stringValue ?? "") == scope.room
                && store.value("place", of: row)?.stringValue == scope.place
                && (store.value("level", of: row)?.stringValue ?? "") == scope.level
        }
    }

    /// What the row for exactly this scope keeps: its form (empty is the studio's) and the traits set there.
    public static func stored(_ scope: LookScope, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef])
        -> (form: String, traits: [String: String])
    {
        guard let row = row(scope, store: store, classes: classes) else { return ("", [:]) }
        return (store.value("form", of: row)?.stringValue ?? "", decode(store.value("traits", of: row)?.stringValue))
    }

    static func decode(_ text: String?) -> [String: String] {
        guard let text, let data = text.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    static func encode(_ traits: [String: String]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(traits)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}

// MARK: - Actions

/// Sets a place's look for one scope: the form it takes and the traits he or Tess changed. The form must fit the
/// place (and a keystone's material its own room), and every trait must be one the form takes, with one of its
/// words. Pending as Tess, with Undo; he can browse the row like any object.
public struct SetElementLook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setElementLook", summary: "Change how a place on screen looks",
        parameters: [
            .init("room", .string, "The room (bridge, log, deck...), or empty for every room"),
            .init("place", .string, "The place: widget, keystone, dial, page..."),
            .init("level", .string, "landing, door, or empty for both"),
            .init("form", .string, "The form it takes, or empty to keep the studio's"),
            .init("traits", .json, "Trait names to their words"),
            .init("shape", .string, "What the place shows now (one, few, many, words, doors, measure, lines)",
                  required: false),
        ], isOfferedToModel: false
    )

    public var scope: LookScope
    public var form: String
    public var traits: [String: String]
    public var shape: ContentShape?

    public init(scope: LookScope, form: String, traits: [String: String] = [:], shape: ContentShape? = nil) {
        self.scope = scope
        self.form = form.lowercased()
        self.traits = traits
        self.shape = shape
    }

    enum CodingKeys: String, CodingKey {
        case room, place, level, form, traits, shape
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(scope: LookScope(room: container.decodeIfPresent(String.self, forKey: .room) ?? "",
                                       place: container.decode(String.self, forKey: .place),
                                       level: container.decodeIfPresent(String.self, forKey: .level) ?? ""),
                      form: container.decodeIfPresent(String.self, forKey: .form) ?? "",
                      traits: container.decodeIfPresent([String: String].self, forKey: .traits) ?? [:],
                      shape: container.decodeIfPresent(ContentShape.self, forKey: .shape))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scope.room, forKey: .room)
        try container.encode(scope.place, forKey: .place)
        try container.encode(scope.level, forKey: .level)
        try container.encode(form, forKey: .form)
        try container.encode(traits, forKey: .traits)
        try container.encodeIfPresent(shape, forKey: .shape)
    }

    func refuse(_ reason: String) -> ActionError {
        .invalidArguments(action: Self.descriptor.name, reason: reason)
    }

    /// The traits a scope may set: the form's, or with no form every trait some form of this place takes.
    func allowed() -> [LookTrait] {
        if let chosen = ElementForms.form(form) {
            return chosen.allTraits
        }
        let forms = ElementForms.all.filter { $0.places.contains(scope.place) }
        return forms.flatMap(\.allTraits).reduce(into: [LookTrait]()) { out, trait in
            if let index = out.firstIndex(where: { $0.name == trait.name }) {
                out[index].values += trait.values.filter { !out[index].values.contains($0) }
            } else {
                out.append(trait)
            }
        }
    }

    public func apply(_ transaction: inout Transaction) throws {
        guard ElementForms.all.contains(where: { $0.places.contains(scope.place) }) else {
            throw refuse("no place called \(scope.place)")
        }
        guard ["", "landing", "door"].contains(scope.level) else { throw refuse("no level called \(scope.level)") }
        if !form.isEmpty {
            guard let chosen = ElementForms.form(form) else { throw refuse("no form called \(form)") }
            guard chosen.places.contains(scope.place) else { throw refuse("a \(form) can't be a \(scope.place)") }
            if !chosen.rooms.isEmpty, !chosen.rooms.contains(scope.room) {
                throw refuse("the \(form) is the \(chosen.rooms.sorted().joined(separator: ", ")) room's own")
            }
            if let shape, !chosen.shapes.contains(shape) {
                throw refuse("a \(form) can't show what this \(scope.place) holds")
            }
        }
        let allowed = allowed()
        for (name, value) in traits {
            guard let trait = allowed.first(where: { $0.name == name }) else { throw refuse("no trait called \(name)") }
            guard trait.values.contains(value) else {
                throw refuse("\(name) takes \(trait.values.joined(separator: ", "))")
            }
        }
        let lookClass = try transaction.classDef(.elementLook)
        let row: ObjectRecord
        if let kept = ElementLooks.row(scope, store: transaction.store, classes: transaction.classes) {
            row = kept
        } else {
            row = transaction.create(lookClass, title: scope.title)
        }
        try transaction.set("room", to: .text(scope.room), on: row)
        try transaction.set("place", to: .text(scope.place), on: row)
        try transaction.set("level", to: .text(scope.level), on: row)
        try transaction.set("form", to: .text(form), on: row)
        try transaction.set("traits", to: .text(ElementLooks.encode(traits)), on: row)
    }

    public func summary(in _: ObjectStore) -> String {
        let changes = traits.keys.sorted().map { "\($0) \(traits[$0] ?? "")" }
        let what = ((form.isEmpty ? [] : ["as \(form)"]) + changes).joined(separator: ", ")
        return "Reshaped \(scope.title) \(what.isEmpty ? "as drawn" : what)"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "\(scope.title), reshaped."
    }
}

/// Puts a scope back to the studio's look. The row stays (empty), so the change is history and Undo brings his look
/// back; nothing is deleted.
public struct RestoreElementLook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "restoreElementLook", summary: "Put a place back to how it was drawn",
        parameters: [
            .init("room", .string, "The room, or empty for every room"),
            .init("place", .string, "The place"),
            .init("level", .string, "landing, door, or empty for both"),
        ], isOfferedToModel: false
    )

    public var scope: LookScope

    public init(scope: LookScope) {
        self.scope = scope
    }

    enum CodingKeys: String, CodingKey {
        case room, place, level
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(scope: LookScope(room: container.decodeIfPresent(String.self, forKey: .room) ?? "",
                                       place: container.decode(String.self, forKey: .place),
                                       level: container.decodeIfPresent(String.self, forKey: .level) ?? ""))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scope.room, forKey: .room)
        try container.encode(scope.place, forKey: .place)
        try container.encode(scope.level, forKey: .level)
    }

    public func apply(_ transaction: inout Transaction) throws {
        guard let row = ElementLooks.row(scope, store: transaction.store, classes: transaction.classes) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that place is already as drawn")
        }
        try transaction.set("form", to: .text(""), on: row)
        try transaction.set("traits", to: .text("{}"), on: row)
    }

    public func summary(in _: ObjectStore) -> String {
        "Put \(scope.title) back as drawn"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "\(scope.title), as drawn."
    }
}

import Foundation

/// The Pantry by places (design item 118, Kaushik's layout C, Oct 22). "To get" (the Groceries list) is the first
/// place and is not an object; Fridge, Freezer, Shelf and Counter are `Place` objects seeded once, and he can add
/// his own (Cupboard, Spice rack), rename, reorder or remove them. An ingredient carries a `place` link and a
/// `section` word inside it. Places and sections are only words about where food lives: no money, and nothing here
/// is added to a Claude payload.
@MainActor
public struct PantryPlaces {
    /// The first place, always: the Groceries list under its Pantry name.
    public static let toGet = "To get"

    /// The places seeded the first time, in order, with their sections (item 118 §2). Stable ids: removing one
    /// leaves its tombstone, so it is never put back.
    public static let defaults: [(key: String, name: String, sections: [String])] = [
        ("fridge", "Fridge", ["Door", "Shelves", "Drawer"]),
        ("freezer", "Freezer", ["Drawers", "Ice"]),
        ("shelf", "Shelf", []),
        ("counter", "Counter", []),
    ]

    public static func defaultID(_ key: String) -> UUID {
        SystemCatalog.stableID("place.\(key)")
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// One place for a screen: the object, its words, its sections as shown and how many ingredients are in it.
    public struct Entry {
        public let place: ObjectRecord
        /// The name as shown: "Private place" when the name holds a walled word.
        public let name: String
        /// The section words as shown ("Private section" for a walled word, or for every section of a walled place).
        public let sections: [String]
        public let count: Int
    }

    /// What a title is called in a sentence or a log line: its real words, or "Private place" / "Private item".
    /// Works from the store alone (no class map in hand), as receipts and op summaries need.
    public static func shown(_ object: ObjectRecord, in store: ObjectStore) -> String {
        let classes = PrivateWords.systemClasses(in: store.context)
        return ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) ?? object.title
    }

    /// "Private section" for a walled section word, or for any word of a walled place.
    public func shownSection(_ word: String, in place: ObjectRecord) -> String {
        let walled = PrivateWords.isPrivateTitle(word, lastWeightKg: BodyWeight.lastKg(in: store))
        return walled || ObjectPrivacy.label(of: place, in: store, classes: classes) != nil ? "Private section" : word
    }

    /// A place's section words as a screen shows them.
    public func shownSections(of place: ObjectRecord) -> [String] {
        sections(of: place).map { shownSection($0, in: place) }
    }

    /// Seeds Fridge, Freezer, Shelf and Counter once, each only if its object (live or removed) was never made.
    /// Idempotent and additive; a place he removed stays removed.
    public func ensureDefaults() {
        guard let placeClass = classes[.place] else { return }
        for (index, entry) in Self.defaults.enumerated() where store.object(id: Self.defaultID(entry.key)) == nil {
            let object = store.create(placeClass, title: entry.name, id: Self.defaultID(entry.key))
            try? store.set("order", to: .number(Double(index)), on: object)
            try? store.set("sections", to: .text(entry.sections.joined(separator: ",")), on: object)
        }
    }

    /// His places in order (not "To get"), live ones only.
    public func places() -> [ObjectRecord] {
        guard let placeClass = classes[.place] else { return [] }
        return store.objects(of: placeClass).filter { !$0.isDeleted }.sorted { lhs, rhs in
            let left = store.number("order", of: lhs) ?? .greatestFiniteMagnitude
            let right = store.number("order", of: rhs) ?? .greatestFiniteMagnitude
            return left != right ? left < right : lhs.createdAt < rhs.createdAt
        }
    }

    /// Every place with its count, in order.
    public func entries() -> [Entry] {
        places().map { place in
            Entry(
                place: place,
                name: name(of: place),
                sections: shownSections(of: place),
                count: ingredients(in: place).count
            )
        }
    }

    /// The name a screen shows.
    public func name(of place: ObjectRecord) -> String {
        ObjectPrivacy.label(of: place, in: store, classes: classes) ?? place.title
    }

    /// A place's section words, in order.
    public func sections(of place: ObjectRecord) -> [String] {
        (store.value("sections", of: place)?.stringValue ?? "").split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// The place an ingredient lives in, or nil (it asks once).
    public func place(of ingredient: ObjectRecord) -> ObjectRecord? {
        store.linkedObjects("place", of: ingredient).first { !$0.isDeleted }
    }

    /// The section word inside its place, when it has a valid one.
    public func section(of ingredient: ObjectRecord) -> String? {
        guard let place = place(of: ingredient),
              let word = store.value("section", of: ingredient)?.stringValue, !word.isEmpty,
              sections(of: place).contains(word) else { return nil }
        return word
    }

    /// The ingredients in a place, by name.
    public func ingredients(in place: ObjectRecord) -> [ObjectRecord] {
        guard let ingredientClass = classes[.ingredient] else { return [] }
        return store.objects(of: ingredientClass).filter { !$0.isDeleted && self.place(of: $0)?.id == place.id }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// A place's contents under its section words (the place's own order, then "no section" last): the right half of
    /// the page. A place with no sections lists directly (one group with a nil section).
    public func grouped(in place: ObjectRecord) -> [(section: String?, label: String?, ingredients: [ObjectRecord])] {
        let items = ingredients(in: place)
        let words = sections(of: place)
        var groups: [(section: String?, label: String?, ingredients: [ObjectRecord])] = words.compactMap { word in
            let inside = items.filter { section(of: $0) == word }
            return inside.isEmpty ? nil : (word, shownSection(word, in: place), inside)
        }
        let loose = items.filter { section(of: $0) == nil }
        if !loose.isEmpty {
            groups.append((nil, nil, loose))
        }
        return groups
    }

    /// Ingredients with no place yet: the ones that ask once.
    public func unplaced(_ ingredients: [ObjectRecord]) -> [ObjectRecord] {
        ingredients.filter { place(of: $0) == nil }
    }
}

// MARK: - Actions

/// Adds a place of his own (Cupboard, Spice rack, Garage), last in order.
public struct CreatePlace: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "createPlace", summary: "Add a place to the Pantry",
        parameters: [
            .init("name", .string, "The place's name"),
            .init("sections", .string, "Section words, comma separated", required: false),
        ], isOfferedToModel: false
    )

    public var name: String
    public var sections: String?

    public init(name: String, sections: String? = nil) {
        self.name = name
        self.sections = sections
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 40, clean.lowercased() != PantryPlaces.toGet.lowercased() else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that name will not do")
        }
        let places = PantryPlaces(store: transaction.store, classes: transaction.classes)
        guard !places.places().contains(where: { $0.title.lowercased() == clean.lowercased() }) else {
            throw ActionError.invalidArguments(
                action: Self.descriptor.name,
                reason: "there is already a place with that name"
            )
        }
        let place = try transaction.create(transaction.classDef(.place), title: clean)
        try transaction.set("order", to: .number(Double(places.places().count)), on: place)
        try transaction.set("sections", to: .text(PlaceSections.clean(sections ?? "")), on: place)
        return place
    }

    public func summary(in _: ObjectStore) -> String {
        "Added a place"
    }

    public func receipt(in store: ObjectStore, output place: ObjectRecord) -> String? {
        "\(PantryPlaces.shown(place, in: store)), new place."
    }
}

enum PlaceSections {
    /// Trimmed, de-duplicated words, at most 8 of up to 24 characters.
    static func clean(_ text: String) -> String {
        var seen = Set<String>()
        return text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count <= 24 && seen.insert($0.lowercased()).inserted }.prefix(8)
            .joined(separator: ",")
    }
}

/// Renames a place.
public struct RenamePlace: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "renamePlace", summary: "Rename a place",
        parameters: [.init("place", .object, "The place"), .init("name", .string, "The new name")],
        isOfferedToModel: false
    )

    public var place: UUID
    public var name: String

    public init(place: UUID, name: String) {
        self.place = place
        self.name = name
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(place, is: .place)
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let places = PantryPlaces(store: transaction.store, classes: transaction.classes)
        guard !clean.isEmpty, clean.count <= 40, clean.lowercased() != PantryPlaces.toGet.lowercased(),
              !places.places().contains(where: { $0.id != target.id && $0.title.lowercased() == clean.lowercased() })
        else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that name will not do")
        }
        transaction.setTitle(clean, on: target)
    }

    public func summary(in _: ObjectStore) -> String {
        "Renamed a place"
    }
}

/// Sets a place's section words.
public struct SetPlaceSections: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setPlaceSections", summary: "Change a place's sections",
        parameters: [
            .init("place", .object, "The place"),
            .init("sections", .string, "Section words, comma separated"),
        ],
        isOfferedToModel: false
    )

    public var place: UUID
    public var sections: String

    public init(place: UUID, sections: String) {
        self.place = place
        self.sections = sections
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(place, is: .place)
        try transaction.set("sections", to: .text(PlaceSections.clean(sections)), on: target)
    }

    public func summary(in _: ObjectStore) -> String {
        "Changed a place's sections"
    }
}

/// Moves a place to a position among his places (0 is the first after "To get"). Reorders the rest.
public struct MovePlace: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "movePlace", summary: "Reorder a place",
        parameters: [.init("place", .object, "The place"), .init("toIndex", .integer, "Its new position")],
        isOfferedToModel: false
    )

    public var place: UUID
    public var toIndex: Int

    public init(place: UUID, toIndex: Int) {
        self.place = place
        self.toIndex = toIndex
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(place, is: .place)
        var ordered = PantryPlaces(store: transaction.store, classes: transaction.classes).places()
        guard let from = ordered.firstIndex(where: { $0.id == target.id }) else { return }
        ordered.remove(at: from)
        ordered.insert(target, at: max(0, min(toIndex, ordered.count)))
        for (index, item) in ordered.enumerated() {
            try transaction.set("order", to: .number(Double(index)), on: item)
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Reordered the places"
    }
}

/// Removes a place. Its ingredients lose their place (they ask again, and "To get" is where they go: the screen adds
/// the returned ingredients to Groceries). The place stays as a tombstone, so a default is never put back.
public struct RemovePlace: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "removePlace", summary: "Remove a place",
        parameters: [.init("place", .object, "The place")], isOfferedToModel: false
    )

    public var place: UUID

    public init(place: UUID) {
        self.place = place
    }

    /// The ingredients that were in it.
    public func apply(_ transaction: inout Transaction) throws -> [ObjectRecord] {
        let target = try transaction.object(place, is: .place)
        let places = PantryPlaces(store: transaction.store, classes: transaction.classes)
        let inside = places.ingredients(in: target)
        for item in inside {
            try transaction.setLinks("place", on: item, to: [])
            try transaction.set("section", to: nil, on: item)
        }
        transaction.delete(target)
        // The rest keep their order, closed up.
        for (index, item) in places.places().filter({ $0.id != target.id }).enumerated() {
            try transaction.set("order", to: .number(Double(index)), on: item)
        }
        return inside
    }

    public func summary(in _: ObjectStore) -> String {
        "Removed a place"
    }
}

/// Puts an ingredient in a place (and a section inside it), or takes it out of any place (nil). A section word the
/// place does not have is dropped.
public struct SetItemPlace: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setItemPlace", summary: "Put an item in a place",
        parameters: [
            .init("item", .object, "The ingredient"), .init("place", .object, "The place", required: false),
            .init("section", .string, "A section of that place", required: false),
        ], isOfferedToModel: false
    )

    public var item: UUID
    public var place: UUID?
    public var section: String?

    public init(item: UUID, place: UUID?, section: String? = nil) {
        self.item = item
        self.place = place
        self.section = section
    }

    public func apply(_ transaction: inout Transaction) throws {
        let ingredient = try transaction.object(item, is: .ingredient)
        guard let place else {
            try transaction.setLinks("place", on: ingredient, to: [])
            try transaction.set("section", to: nil, on: ingredient)
            return
        }
        let target = try transaction.object(place, is: .place)
        try transaction.setLinks("place", on: ingredient, to: [target])
        let words = PantryPlaces(store: transaction.store, classes: transaction.classes).sections(of: target)
        let word = section.flatMap { words.contains($0) ? $0 : nil }
        try transaction.set("section", to: word.map(FieldValue.text), on: ingredient)
    }

    public func summary(in store: ObjectStore) -> String {
        "Put \(store.object(id: item).map { PantryPlaces.shown($0, in: store) } ?? "an item") in a place"
    }
}

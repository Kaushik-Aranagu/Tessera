import Foundation

/// What he told the Pantry by hand, and what it was told last (Kitchen engine actions, Oct 23). The ledger that
/// derives a state from buys and cooks takes the later of its own fact and this one: `level(of:)` is that stored fact.
/// Words about food only: no money, and nothing here is added to a Claude payload.
@MainActor
public struct PantryStock {
    public enum Level: String, Codable, Sendable, CaseIterable {
        case `in`, low, out

        /// "running low", "out", "in".
        public var phrase: String {
            switch self {
            case .in: "in"
            case .low: "running low"
            case .out: "out"
            }
        }
    }

    /// The most pins a place (or the recipe shelf) holds.
    public nonisolated static let pinLimit = 3
    public nonisolated static let pinLimitLine = "Three pins already. Unpin one first."

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// What he last set, and when; nil when he never has.
    public func level(of ingredient: ObjectRecord) -> (level: Level, at: Date)? {
        guard let word = store.value("stock", of: ingredient)?.stringValue, let level = Level(rawValue: word),
              let at = store.value("stockAt", of: ingredient)?.dateValue else { return nil }
        return (level, at)
    }

    /// Whether "Not now" is still holding at `now`.
    public func isSnoozed(_ ingredient: ObjectRecord, at now: Date) -> Bool {
        store.value("snoozedUntil", of: ingredient)?.dateValue.map { now < $0 } ?? false
    }

    public func isPinned(_ object: ObjectRecord) -> Bool {
        store.value("pinned", of: object) == .bool(true)
    }

    /// The ingredients pinned in a place (nil: those with no place), by name.
    public func pinned(in place: ObjectRecord?) -> [ObjectRecord] {
        guard let ingredientClass = classes[.ingredient] else { return [] }
        let places = PantryPlaces(store: store, classes: classes)
        return store.objects(of: ingredientClass).filter {
            !$0.isDeleted && isPinned($0) && places.place(of: $0)?.id == place?.id
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public func pinnedRecipes() -> [ObjectRecord] {
        guard let recipeClass = classes[.recipe] else { return [] }
        return store.objects(of: recipeClass).filter { !$0.isDeleted && isPinned($0) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// Every open "To get" row for an ingredient (the same food can be on the list more than once: two pack sizes).
    public func openRows(for ingredient: ObjectRecord) -> [ObjectRecord] {
        let groceries = Groceries(store: store, classes: classes)
        return groceries.list?.orderedChildren.filter {
            !$0.isDeleted && store.value("isDone", of: $0) != .bool(true)
                && groceries.ingredient(of: $0)?.id == ingredient.id
        } ?? []
    }

    /// The first open "To get" row for an ingredient, if one is on the list.
    public func openRow(for ingredient: ObjectRecord) -> ObjectRecord? {
        openRows(for: ingredient).first
    }

    /// "Eggs": the name as any surface outside the room says it ("Private item" for a walled one), capitalised.
    static func said(_ ingredient: ObjectRecord, in store: ObjectStore) -> String {
        let shown = PantryPlaces.shown(ingredient, in: store)
        return shown.prefix(1).uppercased() + shown.dropFirst()
    }

    /// "the fridge": a place's name for a sentence.
    static func placePhrase(of ingredient: ObjectRecord, in store: ObjectStore) -> String? {
        let classes = PrivateWords.systemClasses(in: store.context)
        guard let place = PantryPlaces(store: store, classes: classes).place(of: ingredient) else { return nil }
        let name = PantryPlaces.shown(place, in: store)
        return "the \(name.prefix(1).lowercased() + name.dropFirst())"
    }
}

enum PantryRefusal {
    static let pins = "refused: threePins"
    static let alreadyPlanned = "refused: alreadyPlanned"
    static let wontDo = "refused: wontDo"

    static func line(_ error: any Error) -> String? {
        guard case let ActionError.invalidArguments(_, reason) = error else { return nil }
        switch reason {
        case pins: return PantryStock.pinLimitLine
        case alreadyPlanned: return "Already planned that day."
        case wontDo: return "I can't keep that."
        default: return nil
        }
    }
}

// MARK: - Stock

/// Sets an ingredient's stock to in, low or out. A hand-set level clears a "Not now".
public struct SetIngredientStock: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setIngredientStock", summary: "Set how much of an ingredient is left",
        parameters: [
            .init("item", .object, "The ingredient"),
            .init("level", .string, "in, low or out"),
            .init("time", .date, "Defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var item: UUID
    public var level: PantryStock.Level
    public var time: Date?

    public init(item: UUID, level: PantryStock.Level, time: Date? = nil) {
        self.item = item
        self.level = level
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let ingredient = try transaction.object(item, is: .ingredient)
        try Self.set(level, on: ingredient, at: time ?? transaction.now, in: &transaction)
    }

    @MainActor static func set(_ level: PantryStock.Level, on ingredient: ObjectRecord, at time: Date,
                               in transaction: inout Transaction) throws
    {
        try transaction.set("stock", to: .choice(level.rawValue), on: ingredient)
        try transaction.set("stockAt", to: .date(time), on: ingredient)
        try transaction.set("snoozedUntil", to: nil, on: ingredient)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: item).map { PantryStock.said($0, in: store) } ?? "It"), \(level.phrase)"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        return "\(PantryStock.said(object, in: store)), \(level.phrase)."
    }
}

/// Used up: stock goes to out and the item goes onto To get, as one op (one Undo puts both back).
public struct UseUpIngredient: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "useUpIngredient", summary: "Used up: out, and on To get",
        parameters: [
            .init("item", .object, "The ingredient"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isOfferedToModel: false
    )

    public var item: UUID
    public var time: Date?

    public init(item: UUID, time: Date? = nil) {
        self.item = item
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let ingredient = try transaction.object(item, is: .ingredient)
        try SetIngredientStock.set(.out, on: ingredient, at: time ?? transaction.now, in: &transaction)
        // The wall AddGroceries applies: a walled name still goes on, said as "Private item".
        let share = GroceryShare(recipe: nil, amount: nil, unit: nil, packSize: nil)
        try transaction.addGroceryShare(share, ingredient: ingredient, text: ingredient.title)
        try transaction.refreshShopLine(at: time ?? transaction.now)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: item).map { PantryStock.said($0, in: store) } ?? "It"), used up"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        return "\(PantryStock.said(object, in: store)), used up. On \(PantryPlaces.toGet)."
    }
}

/// Got it: the To get row is done and stock goes back to in.
public struct GotIngredient: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "gotIngredient", summary: "Got it: in, and off To get",
        parameters: [
            .init("item", .object, "The ingredient"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isOfferedToModel: false
    )

    public var item: UUID
    public var time: Date?

    public init(item: UUID, time: Date? = nil) {
        self.item = item
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let ingredient = try transaction.object(item, is: .ingredient)
        let when = time ?? transaction.now
        // Every open row for it: got it means all of it, however many packs were on the list.
        for row in PantryStock(store: transaction.store, classes: transaction.classes).openRows(for: ingredient) {
            try transaction.set("isDone", to: .bool(true), on: row)
            try transaction.set("checkedAt", to: .date(when), on: row)
            try transaction.refreshShopLine(for: row, at: when)
        }
        try SetIngredientStock.set(.in, on: ingredient, at: when, in: &transaction)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: item).map { PantryStock.said($0, in: store) } ?? "It"), got it"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        let back = PantryStock.placePhrase(of: object, in: store).map { "Back in \($0)." } ?? "Back in."
        return "\(PantryStock.said(object, in: store)), got it. \(back)"
    }
}

/// Not now: the Pantry stops asking about it until tomorrow's 4 am day turn.
public struct SnoozeIngredient: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "snoozeIngredient", summary: "Not now: ask again tomorrow",
        parameters: [
            .init("item", .object, "The ingredient"),
            .init("time", .date, "Defaults to now", required: false),
        ],
        isOfferedToModel: false
    )

    public var item: UUID
    public var time: Date?

    public init(item: UUID, time: Date? = nil) {
        self.item = item
        self.time = time
    }

    /// 04:00 on the day after the one `now` belongs to.
    public static func until(_ now: Date, calendar: Calendar = .current) -> Date {
        TesseraDay(calendar: calendar).end(of: now)
    }

    public func apply(_ transaction: inout Transaction) throws {
        let ingredient = try transaction.object(item, is: .ingredient)
        let until = Self.until(time ?? transaction.now, calendar: transaction.calendar)
        try transaction.set("snoozedUntil", to: .date(until), on: ingredient)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: item).map { PantryStock.said($0, in: store) } ?? "It"), not now"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        return "\(PantryStock.said(object, in: store)), not now. Asks again tomorrow."
    }
}

// MARK: - Pins and adding

/// Pins an ingredient to the top of its place, or unpins it. Three at most per place.
public struct PinIngredient: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "pinIngredient", summary: "Pin an ingredient in its place",
        parameters: [.init("item", .object, "The ingredient"),
                     .init("pinned", .boolean, "False to unpin", required: false)],
        isOfferedToModel: false
    )

    public var item: UUID
    public var pinned: Bool?

    public init(item: UUID, pinned: Bool? = true) {
        self.item = item
        self.pinned = pinned
    }

    public func apply(_ transaction: inout Transaction) throws {
        let ingredient = try transaction.object(item, is: .ingredient)
        let on = pinned ?? true
        if on {
            let stock = PantryStock(store: transaction.store, classes: transaction.classes)
            let place = PantryPlaces(store: transaction.store, classes: transaction.classes).place(of: ingredient)
            let others = stock.pinned(in: place).filter { $0.id != ingredient.id }
            guard others.count < PantryStock.pinLimit else {
                throw ActionError.invalidArguments(action: Self.descriptor.name, reason: PantryRefusal.pins)
            }
        }
        try transaction.set("pinned", to: .bool(on), on: ingredient)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: item).map { PantryStock.said($0, in: store) } ?? "It"), \(pinned ?? true ? "pinned" : "unpinned")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: item) else { return nil }
        return "\(PantryStock.said(object, in: store)), \(pinned ?? true ? "pinned" : "unpinned")."
    }
}

/// What `AddToPlace` did: the ingredient, and whether it was already in the Pantry (so it moved).
public struct AddedToPlace {
    public let ingredient: ObjectRecord
    public let moved: Bool
}

/// Adds a thing to a place by name: the ingredient (made if it is new) lives in the place. A thing that is already in
/// the Pantry moves, and a pin does not follow it (it is unpinned, so the new place's three are never exceeded).
public struct AddToPlace: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addToPlace", summary: "Add a thing to a place",
        parameters: [.init("name", .string, "The thing"), .init("place", .object, "The place"),
                     .init("section", .string, "A section of that place", required: false)],
        isOfferedToModel: false
    )

    public var name: String
    public var place: UUID
    public var section: String?

    public init(name: String, place: UUID, section: String? = nil) {
        self.name = name
        self.place = place
        self.section = section
    }

    public func apply(_ transaction: inout Transaction) throws -> AddedToPlace {
        let target = try transaction.object(place, is: .place)
        // The wall every typed name passes: a price comes off, a secret or a key writes nothing.
        guard let kept = AddGroceries.kept([name], store: transaction.store).first,
              let line = IngredientLine.parse(kept)
        else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: PantryRefusal.wontDo)
        }
        let existing = IngredientBook(store: transaction.store, classes: transaction.classes).find(line.name)
        let ingredient = try transaction.ingredient(named: line.name)
        let places = PantryPlaces(store: transaction.store, classes: transaction.classes)
        let before = places.place(of: ingredient)
        if before?.id != target.id, PantryStock(store: transaction.store, classes: transaction.classes)
            .isPinned(ingredient)
        {
            try transaction.set("pinned", to: .bool(false), on: ingredient)
        }
        try transaction.setLinks("place", on: ingredient, to: [target])
        let words = places.sections(of: target)
        try transaction.set("section", to: section.flatMap { words.contains($0) ? $0 : nil }.map(FieldValue.text),
                            on: ingredient)
        return AddedToPlace(ingredient: ingredient, moved: existing != nil && before != nil)
    }

    public func summary(in store: ObjectStore) -> String {
        "Added a thing to \(store.object(id: place).map { PantryPlaces.shown($0, in: store) } ?? "a place")"
    }

    public func receipt(in store: ObjectStore, output: AddedToPlace) -> String? {
        let phrase = PantryStock.placePhrase(of: output.ingredient, in: store) ?? "the Pantry"
        return "\(PantryStock.said(output.ingredient, in: store)), \(output.moved ? "moved" : "added") to \(phrase)."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

// MARK: - Recipes

/// Pins a recipe to the top of the shelf, or unpins it. Three at most.
public struct PinRecipe: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "pinRecipe", summary: "Pin a recipe",
        parameters: [.init("recipe", .object, "The recipe"),
                     .init("pinned", .boolean, "False to unpin", required: false)],
        isOfferedToModel: false
    )

    public var recipe: UUID
    public var pinned: Bool?

    public init(recipe: UUID, pinned: Bool? = true) {
        self.recipe = recipe
        self.pinned = pinned
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(recipe, is: .recipe)
        let on = pinned ?? true
        if on {
            let others = PantryStock(store: transaction.store, classes: transaction.classes).pinnedRecipes()
                .filter { $0.id != object.id }
            guard others.count < PantryStock.pinLimit else {
                throw ActionError.invalidArguments(action: Self.descriptor.name, reason: PantryRefusal.pins)
            }
        }
        try transaction.set("pinned", to: .bool(on), on: object)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: recipe).map { PantryPlaces.shown($0, in: store) } ?? "Recipe"), \(pinned ?? true ? "pinned" : "unpinned")"
    }

    public func receipt(in store: ObjectStore) -> String? {
        guard let object = store.object(id: recipe) else { return nil }
        return "\(PantryPlaces.shown(object, in: store)), \(pinned ?? true ? "pinned" : "unpinned")."
    }
}

/// What `PlanRecipe` made: the occasion, and the weekday word the receipt says (read in the engine's calendar).
public struct PlannedRecipe {
    public let occasion: ObjectRecord
    public let weekday: String
}

/// Plans a recipe for a day, as an occasion (title the recipe, one day long, linking it). A recipe already planned
/// that day is refused, not doubled. The day is read in the engine's calendar, not the device's.
public struct PlanRecipe: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "planRecipe", summary: "Plan a recipe for a day",
        parameters: [.init("recipe", .object, "The recipe"), .init("day", .date, "Any moment of that day")],
        isOfferedToModel: false
    )

    public var recipe: UUID
    public var day: Date

    public init(recipe: UUID, day: Date) {
        self.recipe = recipe
        self.day = day
    }

    /// The occasion that already plans this recipe that day, if one does.
    @MainActor static func existing(recipe: ObjectRecord, day: Date, calendar: Calendar, store: ObjectStore,
                                    classes: [SystemCatalog.Key: ClassDef]) -> ObjectRecord?
    {
        guard let occasionClass = classes[.occasion] else { return nil }
        let tessera = TesseraDay(calendar: calendar)
        return store.objects(of: occasionClass).first { occasion in
            !occasion.isDeleted && store.linkedObjects("links", of: occasion).contains { $0.id == recipe.id }
                && (store.value("start", of: occasion)?.dateValue).map { tessera.isSameDay($0, day) } == true
        }
    }

    public func apply(_ transaction: inout Transaction) throws -> PlannedRecipe {
        let target = try transaction.object(recipe, is: .recipe)
        guard Self.existing(recipe: target, day: day, calendar: transaction.calendar, store: transaction.store,
                            classes: transaction.classes) == nil
        else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: PantryRefusal.alreadyPlanned)
        }
        let tessera = TesseraDay(calendar: transaction.calendar)
        let occasion = try transaction.create(transaction.classDef(.occasion),
                                              title: PantryPlaces.shown(target, in: transaction.store))
        try transaction.set("start", to: .date(tessera.start(of: day)), on: occasion)
        try transaction.set("end", to: .date(tessera.end(of: day)), on: occasion)
        try transaction.setLinks("links", on: occasion, to: [target])
        return PlannedRecipe(occasion: occasion,
                             weekday: TesseraDay.weekdayName(of: tessera.start(of: day) + 3600,
                                                             calendar: transaction.calendar))
    }

    public func summary(in store: ObjectStore) -> String {
        "Planned \(store.object(id: recipe).map { PantryPlaces.shown($0, in: store) } ?? "a recipe")"
    }

    public func receipt(in store: ObjectStore, output: PlannedRecipe) -> String? {
        guard let object = store.object(id: recipe) else { return nil }
        return "\(PantryPlaces.shown(object, in: store)), planned for \(output.weekday)."
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

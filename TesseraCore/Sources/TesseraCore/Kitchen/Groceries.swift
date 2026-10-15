import Foundation

/// The one built-in groceries list (kitchen slice 6): a slice 1 List with aisle sections. Recipe shares merge into
/// one item per ingredient ("400 g + 200 g tomatoes" → "600 g"), and each item links to the recipes it's for.
@MainActor
public struct Groceries {
    public static var listID: UUID {
        SystemCatalog.stableID("kitchen.groceries")
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public var list: ObjectRecord? {
        store.object(id: Self.listID).flatMap { $0.isDeleted ? nil : $0 }
    }

    /// Makes the one groceries list with its fixed id. Called when the catalog is prepared.
    static func installIfNeeded(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        guard store.object(id: listID) == nil, let listClass = classes[.list] else { return }
        let list = store.create(listClass, title: "Groceries")
        list.id = listID
    }

    /// Sections in walking order, each with its open items.
    public func aisles() -> [(aisle: String, items: [ListContents.Item])] {
        guard let list else { return [] }
        let contents = ListContents(store: store, classes: classes)
        return contents.sections(of: list)
            .map { (aisle: $0.name ?? Aisle.other.rawValue, items: $0.items.filter { !$0.isDone }) }
            .filter { !$0.items.isEmpty }
            .sorted { Aisle.order(of: $0.aisle) < Aisle.order(of: $1.aisle) }
    }

    /// The recipes an item is for.
    public func recipes(for item: ObjectRecord) -> [ObjectRecord] {
        guard let recipeClass = classes[.recipe] else { return [] }
        return store.linkedObjects("about", of: item).filter { $0.classDef?.id == recipeClass.id }
    }

    /// The open items that carry this recipe's share (empty when it isn't on the list): the recipe page's "12 to buy".
    public func share(of recipe: ObjectRecord) -> [ListContents.Item] {
        guard let list else { return [] }
        return ListContents(store: store, classes: classes).open(in: list).filter { item in
            GroceryShare.decode(store.value("shares", of: item.object)?.stringValue).contains { $0.recipe == recipe.id }
        }
    }

    public func ingredient(of item: ObjectRecord) -> ObjectRecord? {
        guard let ingredientClass = classes[.ingredient] else { return nil }
        return store.linkedObjects("about", of: item).first { $0.classDef?.id == ingredientClass.id }
    }
}

/// One recipe's (or a typed line's) share of a grocery item. Stored as JSON on the item so a recipe can be taken
/// back out.
struct GroceryShare: Codable, Hashable {
    var recipe: UUID?
    var amount: Double?
    var unit: KitchenUnit?

    static func decode(_ text: String?) -> [GroceryShare] {
        guard let data = text?.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([GroceryShare].self, from: data)) ?? []
    }

    static func encode(_ shares: [GroceryShare]) -> String {
        (try? JSONEncoder().encode(shares)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    /// The shares summed where units are compatible: grams with kilos, millilitres with litres, same units
    /// together, counts together; anything else joined with "+".
    static func quantity(_ shares: [GroceryShare]) -> String? {
        var mass = 0.0, volume = 0.0, count = 0.0
        var other: [KitchenUnit: Double] = [:]
        var order: [KitchenUnit] = []
        var hasMass = false, hasVolume = false, hasCount = false
        for share in shares {
            guard let amount = share.amount else { continue }
            switch share.unit {
            case .gram?, .kilogram?:
                mass += amount * (share.unit?.metricFactor ?? 1)
                hasMass = true
            case .millilitre?, .litre?:
                volume += amount * (share.unit?.metricFactor ?? 1)
                hasVolume = true
            case nil:
                count += amount
                hasCount = true
            case let unit?:
                if other[unit] == nil {
                    order.append(unit)
                }
                other[unit, default: 0] += amount
            }
        }
        var parts: [String] = []
        if hasMass {
            parts.append(mass >= 1000 ? "\(IngredientLine.kitchenNumber(mass / 1000, unit: .kilogram)) kg"
                : "\(IngredientLine.kitchenNumber(mass, unit: .gram)) g")
        }
        if hasVolume {
            parts.append(volume >= 1000 ? "\(IngredientLine.kitchenNumber(volume / 1000, unit: .litre)) l"
                : "\(IngredientLine.kitchenNumber(volume, unit: .millilitre)) ml")
        }
        if hasCount {
            parts.append(IngredientLine.kitchenNumber(count, unit: nil))
        }
        for unit in order {
            if let amount = other[unit] {
                parts.append(IngredientLine(original: "", amount: amount, unit: unit, name: "").quantityText ?? "")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }
}

extension Transaction {
    /// The groceries list (installed with the catalog; made here only if it's missing).
    mutating func groceriesList() throws -> ObjectRecord {
        if let list = store.object(id: Groceries.listID), !list.isDeleted {
            return list
        }
        return try create(classDef(.list), title: "Groceries")
    }

    /// The aisle for an ingredient: what it learned, else the guide, else Other.
    func aisle(of ingredient: ObjectRecord) -> String {
        if let learned = store.value("aisle", of: ingredient)?.stringValue, !learned.isEmpty {
            return learned
        }
        return (AisleGuide.aisle(for: ingredient.title) ?? .other).rawValue
    }

    /// Adds a share for an ingredient to the open item for it (or a new item in its aisle) and refreshes the
    /// item's quantity and links.
    @discardableResult
    mutating func addGroceryShare(_ share: GroceryShare, ingredient: ObjectRecord,
                                  text: String) throws -> ObjectRecord
    {
        let list = try groceriesList()
        let existing = list.orderedChildren.first { item in
            store.value("isDone", of: item) != .bool(true)
                && store.linkedObjects("about", of: item).contains { $0.id == ingredient.id }
        }
        let item: ObjectRecord = if let existing {
            existing
        } else {
            try AddListItem(list: list.id, text: text, section: aisle(of: ingredient)).apply(&self)
        }
        var shares = GroceryShare.decode(store.value("shares", of: item)?.stringValue)
        shares.append(share)
        try writeShares(shares, on: item, ingredient: ingredient)
        return item
    }

    mutating func writeShares(_ shares: [GroceryShare], on item: ObjectRecord, ingredient: ObjectRecord) throws {
        try set("shares", to: .text(GroceryShare.encode(shares)), on: item)
        let quantity = GroceryShare.quantity(shares)
        try set("quantity", to: quantity.map { .text($0) }, on: item)
        var about = [ingredient]
        for id in shares.compactMap(\.recipe) where !about.contains(where: { $0.id == id }) {
            if let recipe = store.object(id: id) {
                about.append(recipe)
            }
        }
        try setLinks("about", on: item, to: about)
    }
}

/// Puts a recipe's ingredients on the groceries list at a size, skipping staples and "to taste" lines unless asked.
public struct AddRecipeToGroceries: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "addRecipeToGroceries",
        summary: "Put a recipe's ingredients on the groceries list",
        parameters: [
            .init("recipe", .object, "The recipe"),
            .init("serves", .integer, "At what size; defaults to the recipe's", required: false),
            .init("includeStaples", .boolean, "Also add salt, oil and the like", required: false),
        ]
    )

    public var recipe: UUID
    public var serves: Int?
    public var includeStaples: Bool?

    public init(recipe: UUID, serves: Int? = nil, includeStaples: Bool? = nil) {
        self.recipe = recipe
        self.serves = serves
        self.includeStaples = includeStaples
    }

    public func apply(_ transaction: inout Transaction) throws -> [ObjectRecord] {
        let recipe = try transaction.object(recipe, is: .recipe)
        let book = RecipeBook(store: transaction.store, classes: transaction.classes)
        let lines = serves.map { book.scaledLines(of: recipe, serves: $0) } ?? book.lines(of: recipe)
        var items: [ObjectRecord] = []
        for line in lines {
            guard let ingredient = line.ingredient else { continue }
            let staple = transaction.store.value("isStaple", of: ingredient) == .bool(true)
                || AisleGuide.staples.contains(IngredientLine.key(for: ingredient.title))
            if staple || line.line.toTaste, includeStaples != true {
                continue
            }
            let share = GroceryShare(recipe: recipe.id, amount: line.line.amountMax ?? line.line.amount,
                                     unit: line.line.unit)
            let item = try transaction.addGroceryShare(
                share,
                ingredient: ingredient,
                text: ingredient.title.lowercased()
            )
            if !items.contains(where: { $0.id == item.id }) {
                items.append(item)
            }
        }
        try transaction.refreshShopLine()
        return items
    }

    public func summary(in store: ObjectStore) -> String {
        "Added \(store.object(id: recipe)?.title ?? "the recipe") to groceries"
    }
}

/// Takes a recipe's share back off the groceries list; items that were only for it go.
public struct RemoveRecipeFromGroceries: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "removeRecipeFromGroceries",
        summary: "Take a recipe's ingredients back off the groceries list",
        parameters: [.init("recipe", .object, "The recipe")]
    )

    public var recipe: UUID

    public init(recipe: UUID) {
        self.recipe = recipe
    }

    public func apply(_ transaction: inout Transaction) throws {
        guard let list = transaction.store.object(id: Groceries.listID) else { return }
        let groceries = Groceries(store: transaction.store, classes: transaction.classes)
        for item in list.orderedChildren where transaction.store.value("isDone", of: item) != .bool(true) {
            let shares = GroceryShare.decode(transaction.store.value("shares", of: item)?.stringValue)
            guard shares.contains(where: { $0.recipe == recipe }) else { continue }
            let rest = shares.filter { $0.recipe != recipe }
            if rest.isEmpty {
                transaction.delete(item)
            } else if let ingredient = groceries.ingredient(of: item) {
                try transaction.writeShares(rest, on: item, ingredient: ingredient)
            }
        }
        try transaction.refreshShopLine()
    }

    public func summary(in store: ObjectStore) -> String {
        "Took \(store.object(id: recipe)?.title ?? "the recipe") off groceries"
    }
}

/// Adds typed lines to the groceries list ("milk", "2 lemons", "500 g mince"), each in its ingredient's aisle,
/// merging with what's already there.
public struct AddGroceries: EngineAction {
    public static let descriptor = ActionDescriptor(name: "addGroceries", summary: "Add things to the groceries list",
                                                    parameters: [
                                                        .init("lines", .json, "Lines such as \"2 lemons\""),
                                                    ])

    public var lines: [String]

    public init(lines: [String]) {
        self.lines = lines
    }

    public func apply(_ transaction: inout Transaction) throws -> [ObjectRecord] {
        var items: [ObjectRecord] = []
        for text in lines {
            guard let line = IngredientLine.parse(text) else { continue }
            let ingredient = try transaction.ingredient(named: line.name)
            let share = GroceryShare(recipe: nil, amount: line.amount, unit: line.unit)
            try items.append(transaction.addGroceryShare(share, ingredient: ingredient, text: line.name))
        }
        guard !items.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "nothing to add")
        }
        try transaction.refreshShopLine()
        return items
    }

    public func summary(in _: ObjectStore) -> String {
        lines.count == 1 ? "Added \(lines[0])" : "Added \(lines.count) things"
    }
}

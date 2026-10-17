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
    /// Exactly one built-in Groceries list after this runs (G29): a copy made while it was deleted brings it back with
    /// its rows, and a second "Groceries" made by `groceriesList()` while it was gone folds into it.
    static func installIfNeeded(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        guard let listClass = classes[.list] else { return }
        let fixed: ObjectRecord
        if let existing = store.object(id: listID) {
            if existing.isDeleted {
                store.restore(existing)
            }
            fixed = existing
        } else {
            fixed = store.create(listClass, title: "Groceries")
            fixed.id = listID
        }
        foldStrays(into: fixed, store: store, listClass: listClass)
    }

    /// A stray list with the built-in's name and no fixed id: its rows move across, then it goes.
    private static func foldStrays(into fixed: ObjectRecord, store: ObjectStore, listClass: ClassDef) {
        let strays = store.objects(of: listClass).filter { $0.id != listID && $0.title == "Groceries" }
        for stray in strays {
            var next = (fixed.orderedChildren.map(\.sortIndex).max() ?? -1) + 1
            for row in stray.orderedChildren {
                store.noteChange(row)
                row.parent = fixed
                row.sortIndex = next
                next += 1
            }
            store.softDelete(stray)
        }
    }

    /// Sections in walking order, each with its open items.
    public func aisles() -> [(aisle: String, items: [ListContents.Item])] {
        guard let list else { return [] }
        let contents = ListContents(store: store, classes: classes)
        // Grouped by the name as shown, so an item stored under "Tins and jars" joins "Cans and jars" (QA S1).
        var order: [String] = []
        var grouped: [String: [ListContents.Item]] = [:]
        for section in contents.sections(of: list) {
            let name = Aisle.shown(section.name ?? Aisle.other.rawValue)
            if grouped[name] == nil {
                order.append(name)
            }
            grouped[name, default: []] += section.items.filter { !$0.isDone }
        }
        return order.map { (aisle: $0, items: grouped[$0] ?? []) }
            .filter { !$0.items.isEmpty }
            .sorted { Aisle.order(of: $0.aisle) < Aisle.order(of: $1.aisle) }
    }

    /// Whether a thing is already on the list, open ("chickpeas" when "1 can chickpeas · 15 oz" is there).
    public func isOn(_ name: String) -> Bool {
        guard let list, let ingredient = IngredientBook(store: store, classes: classes).find(name) else { return false }
        return list.orderedChildren.contains { item in
            store.value("isDone", of: item) != .bool(true) && !item.isDeleted
                && store.linkedObjects("about", of: item).contains { $0.id == ingredient.id }
        }
    }

    /// Open rows on the list that a recipe put there, still to buy ("Tacos tonight, 2 to buy." on Home).
    public func toBuy(for recipe: UUID) -> Int {
        guard let list else { return 0 }
        return list.orderedChildren.count { item in
            !item.isDeleted && store.value("isDone", of: item) != .bool(true)
                && GroceryShare.decode(store.value("shares", of: item)?.stringValue).contains { $0.recipe == recipe }
        }
    }

    /// One pack's size for an item ("14.5 oz"), drawn after the name with a middle dot; nil when it has none.
    public func packSize(of item: ObjectRecord) -> String? {
        GroceryShare.decode(store.value("shares", of: item)?.stringValue).lazy.compactMap(\.packSize).first
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
    /// One pack's size: part of the merge key, so a 14.5 oz and a 28 oz can never add up (Research U5).
    var packSize: String?
    /// False when the share rides a row he typed with his own amount ("1 dozen eggs"): the recipe line lands under
    /// the row, but his amount stands and nothing sums (Kitchen lead, G-R2). Nil means it counts.
    var counts: Bool?

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
        var mass = 0.0, volume = 0.0, count = 0.0, ounces = 0.0, fluidOunces = 0.0
        var hasOunces = false, hasFluidOunces = false
        var other: [KitchenUnit: Double] = [:]
        var order: [KitchenUnit] = []
        var hasMass = false, hasVolume = false, hasCount = false
        for share in shares where share.counts != false {
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
            // US weight is its own group: ounces and pounds add as ounces, never with grams (us-shop.md).
            case .ounce?, .pound?:
                ounces += share.unit == .pound ? amount * 16 : amount
                hasOunces = true
            // Fluid ounces never merge with ounces of weight.
            case .fluidOunce?:
                fluidOunces += amount
                hasFluidOunces = true
            case let unit?:
                if other[unit] == nil {
                    order.append(unit)
                }
                other[unit, default: 0] += amount
            }
        }
        var parts: [String] = []
        // Packs first: "1 can + 15 oz black beans", "1 bag + 6 cups baby spinach" (Design 47, G-R8).
        for unit in order where unit.isPack {
            if let amount = other[unit] {
                parts.append(IngredientLine(original: "", amount: amount, unit: unit, name: "").quantityText ?? "")
            }
        }
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
        if hasOunces {
            // Pounds from 16 oz, only on a whole, ¼, ½ or ¾ pound; else ounces ("18 oz").
            let pounds = ounces / 16
            let quarter = (pounds * 4).rounded() == pounds * 4
            parts.append(pounds >= 1 && quarter ? "\(IngredientLine.kitchenNumber(pounds, unit: .pound)) lb"
                : "\(IngredientLine.kitchenNumber(ounces, unit: .ounce)) oz")
        }
        if hasFluidOunces {
            parts.append("\(IngredientLine.kitchenNumber(fluidOunces, unit: .fluidOunce)) fl oz")
        }
        for unit in order where !unit.isPack {
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
            return Aisle.shown(learned)
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
        // A bare name ("chickpeas") means "make sure it's on": it joins the first open row for that ingredient,
        // sized or not, and leaves the count alone (Design, after QA on #309).
        if share.amount == nil, share.unit == nil, share.recipe == nil,
           let onList = list.orderedChildren.first(where: { item in
               store.value("isDone", of: item) != .bool(true)
                   && store.linkedObjects("about", of: item).contains { $0.id == ingredient.id }
           })
        {
            return onList
        }
        // Same ingredient and the same pack size: two sizes of one thing are two rows (U5). A loose share (no pack
        // size) joins a row with one pack size, pack first with "+" (Research 123 G-R8, Design 47).
        let existing = list.orderedChildren.first { item in
            guard store.value("isDone", of: item) != .bool(true),
                  store.linkedObjects("about", of: item).contains(where: { $0.id == ingredient.id })
            else { return false }
            let shares = GroceryShare.decode(store.value("shares", of: item)?.stringValue)
            let sizes = Set(shares.compactMap(\.packSize))
            let unsizedPack = shares.contains { $0.packSize == nil && $0.unit?.isPack == true }
            if let size = share.packSize {
                // A sized can joins its own size, or a row with no size and no unsized can (U5 both ways; QA F3).
                return sizes == [size] || (sizes.isEmpty && !unsizedPack)
            }
            // An unsized pack ("1 can") never joins a sized one (U5); a loose amount ("15 oz", "6 cups") does.
            return share.unit?.isPack == true ? sizes.isEmpty : sizes.count <= 1
        }
        // A can or jar of something fresh is never filed under Produce ("1 (14.5 oz) can diced tomatoes").
        var section = aisle(of: ingredient)
        if share.unit.map({ [.can, .jar, .carton, .bottle].contains($0) }) == true, section == Aisle.produce.rawValue {
            section = Aisle.cansJars.rawValue
        }
        let item: ObjectRecord = if let existing {
            existing
        } else {
            try AddListItem(list: list.id, text: text, section: section).apply(&self)
        }
        var shares = GroceryShare.decode(store.value("shares", of: item)?.stringValue)
        var share = share
        // His typed amount stands: a recipe's share under "1 dozen eggs" is a line, not a sum (G-R2).
        if share.recipe != nil, shares.contains(where: { $0.recipe == nil && $0.amount != nil }) {
            share.counts = false
        }
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
        // Added again (a new size): take its old share out first, once, so it's replaced, never doubled, and an
        // ingredient listed twice in it ("200 g butter" and "50 g butter") still sums.
        let list = try transaction.groceriesList()
        // Nothing to add (every line a staple, optional or covered) and nothing of it on the list: no write, so no
        // UNDO (Product e1981a39).
        let wanted = lines.filter { line in
            guard let ingredient = line.ingredient else { return false }
            let staple = transaction.store.value("isStaple", of: ingredient) == .bool(true)
                || AisleGuide.isStaple(IngredientLine.key(for: ingredient.title))
            let covered = list.orderedChildren.contains { item in
                transaction.store.value("isDone", of: item) == .bool(true) && !item.isDeleted
                    && transaction.store.linkedObjects("about", of: item).contains { $0.id == ingredient.id }
            }
            return !((staple || line.line.toTaste || line.line.optional) && includeStaples != true) && !covered
        }
        let alreadyOn = Groceries(store: transaction.store, classes: transaction.classes).share(of: recipe).count
        if wanted.isEmpty, alreadyOn == 0 {
            Self.lastAdded[recipe.id] = 0
            return []
        }
        try RemoveRecipeFromGroceries(recipe: recipe.id).apply(&transaction)
        let before = Set(list.orderedChildren.map(\.id))
        var items: [ObjectRecord] = []
        for line in lines {
            guard let ingredient = line.ingredient else { continue }
            let staple = transaction.store.value("isStaple", of: ingredient) == .bool(true)
                || AisleGuide.isStaple(IngredientLine.key(for: ingredient.title))
            // Staples, "to taste" and optional lines ("for serving") stay on the recipe page (G-R3, G-R4).
            if staple || line.line.toTaste || line.line.optional, includeStaples != true {
                continue
            }
            // A same-key row already checked covers the line: nothing is added (G-R2, Kitchen lead).
            let covered = list.orderedChildren.contains { item in
                transaction.store.value("isDone", of: item) == .bool(true) && !item.isDeleted
                    && transaction.store.linkedObjects("about", of: item).contains { $0.id == ingredient.id }
            }
            if covered {
                continue
            }
            let share = GroceryShare(recipe: recipe.id, amount: line.line.amountMax ?? line.line.amount,
                                     unit: line.line.unit, packSize: line.line.packSize)
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
        // New rows only: joined rows still carry the recipe line, but "Added N" counts what is new (G-R14). The
        // receipt reads the same set, so the two never disagree (QA L1, Kitchen lead).
        let made = items.filter { !before.contains($0.id) }
        Self.lastAdded[recipe.id] = made.count
        return made
    }

    /// New rows by recipe from the last `apply` in this process, for the receipt written right after it.
    nonisolated(unsafe) static var lastAdded: [UUID: Int] = [:]

    /// "Tacos, 10 added." (Product W12); "Tacos, nothing to add." when nothing was new (Product e1981a39). The short
    /// name, unless another recipe on the list shares it (Kitchen lead, #389).
    public func summary(in store: ObjectStore) -> String {
        let name = store.object(id: recipe).map { RecipeBook.shortName(of: $0, store: store) } ?? "Recipe"
        let made = Self.lastAdded[recipe] ?? 0
        return made == 0 ? "\(name), nothing to add." : "\(name), \(made) added."
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
            let share = GroceryShare(recipe: nil, amount: line.amount, unit: line.unit, packSize: line.packSize)
            try items.append(transaction.addGroceryShare(share, ingredient: ingredient, text: line.name))
        }
        guard !items.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "nothing to add")
        }
        try transaction.refreshShopLine()
        return items
    }

    /// A medicine or body line is never said back (#688): it reads "Private item".
    @MainActor
    private func shown(_ line: String, in store: ObjectStore) -> String {
        EngineWall.isHealth(line, lastWeightKg: BodyWeight.lastKg(in: store)) ? "Private item" : line
    }

    @MainActor
    public func summary(in store: ObjectStore) -> String {
        // Thing first, the list by name (lists copy sweep, Product 10:06 PM PT).
        let first = lines.first.map { shown($0, in: store) } ?? ""
        return lines.count == 1 ? "\(first.prefix(1).uppercased() + first.dropFirst()), on Groceries"
            : "\(lines.count) things on Groceries"
    }

    @MainActor
    public func receipt(in store: ObjectStore) -> String? {
        guard !lines.isEmpty else { return nil }
        let lines = lines.map { shown($0, in: store) }
        // Name the things: "Oat milk and eggs, on Groceries"; "Oat milk, eggs and 2 more, on Groceries" (Design R7).
        let names = switch lines.count {
        case 1: lines[0]
        case 2: "\(lines[0]) and \(lines[1])"
        default: "\(lines[0]), \(lines[1]) and \(lines.count - 2) more"
        }
        return "\(names.prefix(1).uppercased() + names.dropFirst()), on Groceries"
    }
}

import Foundation

/// Recipes as objects (kitchen slice 3). Reading goes through `RecipeBook`; writing through `CreateRecipe`,
/// `EditRecipe` and `DeleteObject`, all undoable.
@MainActor
public struct RecipeBook {
    public struct Line: Identifiable {
        public let id: UUID
        public let object: ObjectRecord
        public let line: IngredientLine
        public let ingredient: ObjectRecord?
        public var isStaple: Bool
    }

    public struct Step: Identifiable {
        public let id: UUID
        public let object: ObjectRecord
        public let text: String
        public let timers: [ClosedRange<Double>]
        public let uses: [ObjectRecord]

        /// The timers the step offers: every duration up to 24 hours. A longer one ("48 hours") stays plain text.
        public var offeredTimers: [ClosedRange<Double>] {
            RecipeParser.offeredTimers(timers)
        }
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// "Tacos" for "Sheet-pan chicken fajita tacos": the title's last word, capitalised, brackets dropped (Kitchen
    /// lead, #389). Two recipes on the groceries list sharing a short name both read their full titles.
    public static func shortName(of recipe: ObjectRecord, store: ObjectStore) -> String {
        let short = shortName(ofTitle: recipe.title)
        let onList = store.object(id: Groceries.listID)?.orderedChildren
            .filter { !$0.isDeleted && store.value("isDone", of: $0) != .bool(true) }
            .flatMap { GroceryShare.decode(store.value("shares", of: $0)?.stringValue).compactMap(\.recipe) } ?? []
        let clash = Set(onList).subtracting([recipe.id]).contains { other in
            store.object(id: other).map { shortName(ofTitle: $0.title) == short } ?? false
        }
        return clash ? recipe.title : short
    }

    public static func shortName(ofTitle title: String) -> String {
        let bare = title.replacing(/\s*[\(\[][^\)\]]*[\)\]]/, with: "")
        guard let last = bare.split(separator: " ").last else { return title }
        let word = last.trimmingCharacters(in: .punctuationCharacters)
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    public func recipes() -> [ObjectRecord] {
        guard let recipeClass = classes[.recipe] else { return [] }
        return store.objects(of: recipeClass).sorted { $0.createdAt < $1.createdAt }
    }

    /// The saved recipe whose pasted text is exactly this one (the paste screen and Tess check before a second is
    /// written, G59). Private lines are cut the way `CreateRecipe` stores them.
    public func recipe(pastedAs text: String) -> ObjectRecord? {
        let wanted = SecretWords.cut(text).text
        return recipes().first { store.value("sourceText", of: $0)?.stringValue == wanted }
    }

    public func serves(_ recipe: ObjectRecord) -> Int? {
        RecipeLimits.serves(store.number("serves", of: recipe))
    }

    /// The recipe's total time in minutes, inside `RecipeLimits.minutes` (G62).
    public func totalMinutes(_ recipe: ObjectRecord) -> Double? {
        RecipeLimits.minutes(store.number("totalMinutes", of: recipe))
    }

    /// The recipe's active time in minutes, inside `RecipeLimits.minutes` (G62).
    public func activeMinutes(_ recipe: ObjectRecord) -> Double? {
        RecipeLimits.minutes(store.number("activeMinutes", of: recipe))
    }

    public func lines(of recipe: ObjectRecord) -> [Line] {
        guard let lineClass = classes[.recipeLine] else { return [] }
        return recipe.orderedChildren.filter { $0.classDef?.id == lineClass.id }.map { object in
            let ingredient = store.linkedObjects("ingredient", of: object).first
            let line = IngredientLine(
                original: store.value("original", of: object)?.stringValue ?? object.title,
                amount: store.number("amount", of: object), amountMax: store.number("amountMax", of: object),
                unit: store.value("unit", of: object)?.stringValue.flatMap(KitchenUnit.init(rawValue:)),
                name: object.title, prep: store.value("prep", of: object)?.stringValue,
                toTaste: store.value("toTaste", of: object) == .bool(true),
                packSize: store.value("packSize", of: object)?.stringValue,
                optional: store.value("optional", of: object) == .bool(true)
            )
            return Line(id: object.id, object: object, line: line, ingredient: ingredient,
                        isStaple: ingredient.map { store.value("isStaple", of: $0) == .bool(true) } ?? false)
        }
    }

    public func steps(of recipe: ObjectRecord) -> [Step] {
        guard let stepClass = classes[.recipeStep] else { return [] }
        return recipe.orderedChildren.filter { $0.classDef?.id == stepClass.id }.map { object in
            Step(id: object.id, object: object, text: store.value("text", of: object)?.stringValue ?? object.title,
                 timers: RecipeTimers.decode(store.value("timers", of: object)?.stringValue),
                 uses: store.linkedObjects("about", of: object))
        }
    }

    /// Recipes that use an ingredient (its backlinks, through recipe lines).
    public func recipes(using ingredient: ObjectRecord) -> [ObjectRecord] {
        guard let lineClass = classes[.recipeLine] else { return [] }
        let users = store.objects(of: lineClass)
            .filter { store.linkedObjects("ingredient", of: $0).contains { $0.id == ingredient.id } }
            .compactMap(\.parent)
        var seen = Set<UUID>()
        return users.filter { seen.insert($0.id).inserted }
    }
}

/// Timers stored as text ("20" or "60-120", comma separated) so the value stays a plain field.
enum RecipeTimers {
    static func encode(_ timers: [ClosedRange<Double>]) -> String {
        timers.map { range in
            range.lowerBound == range.upperBound ? format(range.lowerBound)
                : "\(format(range.lowerBound))-\(format(range.upperBound))"
        }.joined(separator: ",")
    }

    static func decode(_ text: String?) -> [ClosedRange<Double>] {
        (text ?? "").split(separator: ",").compactMap { part in
            let bounds = part.split(separator: "-").compactMap { Double($0) }
            guard let low = bounds.first else { return nil }
            return low ... max(low, bounds.last ?? low)
        }
    }

    static func format(_ value: Double) -> String {
        value.rounded() == value ? RecipeLimits.whole(value).map(String.init) ?? String(value) : String(value)
    }
}

/// Reads pasted text into a recipe: lines linked to Ingredient objects (found or created), steps with their
/// timers and the ingredients they mention. The text is kept verbatim.
public struct CreateRecipe: EngineAction {
    public static let descriptor = ActionDescriptor(name: "createRecipe", summary: "Save a recipe from text",
                                                    parameters: [
                                                        .init("text", .string, "The recipe as pasted"),
                                                        .init(
                                                            "title",
                                                            .string,
                                                            "Overrides the title read from the text",
                                                            required: false
                                                        ),
                                                    ])

    public var text: String
    public var title: String?
    /// Lines (by index among the non-empty lines) the paste screen re-read: "ingredient", "step" or "ignore".
    public var corrections: [Int: String]?

    public init(text: String, title: String? = nil, corrections: [Int: String]? = nil) {
        self.text = text
        self.title = title
        self.corrections = corrections
    }

    /// The text's lines with any corrections applied.
    public static func lines(of text: String,
                             corrections: [Int: String]?) -> [(line: String, kind: RecipeParser.LineKind)]
    {
        var lines = RecipeParser.classify(text)
        for (index, kind) in corrections ?? [:] where lines.indices.contains(index) {
            let line = lines[index].line
            switch kind {
            case "ingredient":
                lines[index].kind = IngredientLine.parse(line).map { .ingredient($0) } ?? .ignored
            case "step":
                lines[index].kind = .step(text: line, timers: RecipeParser.durations(in: line))
            default:
                lines[index].kind = .ignored
            }
        }
        // A line with a secret and a value never becomes an ingredient or a step (Research 137 PR1, PR7).
        for index in lines.indices where SecretWords.isPrivateLine(lines[index].line) {
            lines[index].kind = .ignored
        }
        return lines
    }

    /// "Weeknight dal is already on Recipes." (a walled or private title is "Private recipe").
    @MainActor
    public static func duplicateLine(of existing: ObjectRecord, in store: ObjectStore) -> String {
        let walled = store.value("isPrivate", of: existing) == .bool(true)
            || ObjectPrivacy.isPrivateRecipeTitle(existing.title, lastWeightKg: BodyWeight.lastKg(in: store))
        return "\(walled ? ObjectPrivacy.recipeLabel : existing.title) is already on Recipes."
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        guard let parsed = RecipeParser.parse(text, lines: Self.lines(of: text, corrections: corrections)) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "no ingredients or steps found")
        }
        // The same paste twice is one recipe: nothing is written, and the refusal names the one he has (G59).
        let book = RecipeBook(store: transaction.store, classes: transaction.classes)
        if let existing = book.recipe(pastedAs: parsed.source) {
            throw ActionError.invalidArguments(action: Self.descriptor.name,
                                               reason: Self.duplicateLine(of: existing, in: transaction.store))
        }
        let recipe = try transaction.create(transaction.classDef(.recipe), title: title ?? parsed.title)
        // The original text keeps every line but the private ones (Research 137 PR1).
        try transaction.set("sourceText", to: .text(SecretWords.cut(parsed.source).text), on: recipe)
        if let serves = RecipeLimits.serves(parsed.serves) {
            try transaction.set("serves", to: .number(Double(serves)), on: recipe)
        }
        if let active = RecipeLimits.minutes(parsed.activeMinutes) {
            try transaction.set("activeMinutes", to: .number(active), on: recipe)
        }
        let stepMinutes = parsed.steps.flatMap(\.timers).reduce(0) { $0 + $1.upperBound }
        if let total = RecipeLimits.minutes(parsed.totalMinutes ?? (stepMinutes > 0 ? stepMinutes : nil)) {
            try transaction.set("totalMinutes", to: .number(total), on: recipe)
        }
        try Self.write(parsed, into: recipe, transaction: &transaction)
        return recipe
    }

    @MainActor
    static func write(_ parsed: ParsedRecipe, into recipe: ObjectRecord, transaction: inout Transaction) throws {
        var index = 0
        var used: [(key: String, ingredient: ObjectRecord)] = []
        for line in parsed.ingredients {
            let ingredient = try transaction.ingredient(named: line.name)
            let object = try transaction.create(transaction.classDef(.recipeLine), title: line.name, parent: recipe)
            transaction.setSortIndex(index, on: object)
            index += 1
            try transaction.set("original", to: .text(line.original), on: object)
            if let amount = line.amount {
                try transaction.set("amount", to: .number(amount), on: object)
            }
            if let high = line.amountMax {
                try transaction.set("amountMax", to: .number(high), on: object)
            }
            if let unit = line.unit {
                try transaction.set("unit", to: .text(unit.rawValue), on: object)
            }
            if let prep = line.prep {
                try transaction.set("prep", to: .text(prep), on: object)
            }
            if line.toTaste {
                try transaction.set("toTaste", to: .bool(true), on: object)
            }
            if let packSize = line.packSize {
                try transaction.set("packSize", to: .text(packSize), on: object)
            }
            if line.optional {
                try transaction.set("optional", to: .bool(true), on: object)
            }
            try transaction.setLinks("ingredient", on: object, to: [ingredient])
            used.append((IngredientLine.key(for: ingredient.title), ingredient))
        }
        for step in parsed.steps {
            let object = try transaction.create(transaction.classDef(.recipeStep),
                                                title: String(step.text.prefix(60)), parent: recipe)
            transaction.setSortIndex(index, on: object)
            index += 1
            try transaction.set("text", to: .text(step.text), on: object)
            if !step.timers.isEmpty {
                try transaction.set("timers", to: .text(RecipeTimers.encode(step.timers)), on: object)
            }
            let words = IngredientLine.key(for: step.text.replacing(/[^\p{L}\s]/, with: " "))
            let padded = " \(words) "
            var mentions: [ObjectRecord] = []
            for (key, ingredient) in used where padded.contains(" \(key) ")
                && !mentions.contains(where: { $0.id == ingredient.id })
            {
                mentions.append(ingredient)
            }
            if !mentions.isEmpty {
                try transaction.setLinks("about", on: object, to: mentions)
            }
        }
    }

    public func summary(in _: ObjectStore) -> String {
        "Saved \(title ?? RecipeParser.parse(text)?.title ?? "a recipe")"
    }
}

/// Changes a recipe's title or serving size.
public struct EditRecipe: EngineAction {
    public static let descriptor = ActionDescriptor(name: "editRecipe", summary: "Rename a recipe or change its size",
                                                    parameters: [
                                                        .init("recipe", .object, "The recipe"),
                                                        .init("title", .string, "New title", required: false),
                                                        .init(
                                                            "serves",
                                                            .integer,
                                                            "How many it serves",
                                                            required: false
                                                        ),
                                                    ])

    public var recipe: UUID
    public var title: String?
    public var serves: Int?

    public init(recipe: UUID, title: String? = nil, serves: Int? = nil) {
        self.recipe = recipe
        self.title = title
        self.serves = serves
    }

    public func apply(_ transaction: inout Transaction) throws {
        let recipe = try transaction.object(recipe, is: .recipe)
        if let title, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            transaction.setTitle(title, on: recipe)
        }
        if let serves {
            try transaction.set("serves", to: RecipeLimits.serves(serves).map { .number(Double($0)) }, on: recipe)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "Changed \(store.object(id: recipe)?.title ?? "the recipe")"
    }
}

public extension RecipeBook {
    /// The recipe's lines at another size (not stored). Without a size on the recipe, they're returned as written.
    func scaledLines(of recipe: ObjectRecord, serves target: Int) -> [Line] {
        let lines = lines(of: recipe)
        guard let serves = serves(recipe), let target = RecipeLimits.serves(target) else { return lines }
        let scaled = RecipeMath.scaled(lines.map(\.line), from: serves, to: target)
        return zip(lines, scaled).map { line, scaled in
            Line(id: line.id, object: line.object, line: scaled, ingredient: line.ingredient, isStaple: line.isStaple)
        }
    }
}

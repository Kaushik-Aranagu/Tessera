import Foundation

/// Ingredient objects, matched by name with simple plurals ("tomatoes" finds "Tomato").
@MainActor
public struct IngredientBook {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func all() -> [ObjectRecord] {
        guard let ingredientClass = classes[.ingredient] else { return [] }
        return store.objects(of: ingredientClass)
    }

    /// The ingredient with this name, ignoring case and plurals.
    public func find(_ name: String) -> ObjectRecord? {
        let key = IngredientLine.key(for: name)
        guard !key.isEmpty else { return nil }
        return all().first { IngredientLine.key(for: $0.title) == key }
    }
}

public extension Transaction {
    /// The ingredient with this name, created (singular, first letter capitalised) when it's new.
    mutating func ingredient(named name: String) throws -> ObjectRecord {
        let book = IngredientBook(store: store, classes: classes)
        if let existing = book.find(name) {
            return existing
        }
        // Titled as written ("Garlic cloves"); `key` is only for matching.
        let typed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = typed.prefix(1).uppercased() + typed.dropFirst()
        return try create(classDef(.ingredient), title: title)
    }
}

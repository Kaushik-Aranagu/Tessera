import Foundation

/// The Kitchen landing's counts (design 131): "covers 4 dinners" and "7 to get", computed on the phone.
@MainActor
public struct KitchenLanding {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Open items on the Groceries list (the To get place).
    public func toGetCount() -> Int {
        Groceries(store: store, classes: classes).aisles().reduce(0) { $0 + $1.items.count }
    }

    /// Recipes whose every needed ingredient is already in a place of the pantry and none of whose ingredients is open
    /// on To get: covered without a shop (Design). A needed line is one that is not
    /// optional, not "to taste" and not a staple; a line with no ingredient behind it cannot be confirmed, so that
    /// recipe is not counted. A recipe with nothing needed is not counted either.
    public func dinnersCovered() -> Int {
        let book = RecipeBook(store: store, classes: classes)
        let places = PantryPlaces(store: store, classes: classes)
        let groceries = Groceries(store: store, classes: classes)
        return book.recipes().count { recipe in
            let all = book.lines(of: recipe)
            guard !all.contains(where: { line in line.ingredient.map { groceries.isOn($0.title) } ?? false }) else {
                return false
            }
            let needed = all.filter { !$0.line.optional && !$0.line.toTaste && !$0.isStaple }
            guard !needed.isEmpty else { return false }
            return needed.allSatisfy { line in
                line.ingredient.map { places.place(of: $0) != nil } ?? false
            }
        }
    }
}

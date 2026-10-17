import Foundation
@testable import TesseraCore
import Testing

/// A grocery row for an ingredient he already has is made directly: a name the list wall would refuse never turns
/// the row into a note and throws (unknownField "shares", found while testing #770).
@MainActor
struct GroceryRowTests {
    @Test func aRecipeWithAWalledIngredientNameStillReachesGroceries() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let recipe = try engine.perform(
            CreateRecipe(text: "Mystery\nIngredients\n1 wifi password\n2 eggs\nMethod\n1. Mix."),
            by: .user
        ).output
        let added = try engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        let rows = Groceries(store: store, classes: classes).shoppingOrder().map(\.text)
        #expect(rows.count == 2, "\(rows)")
        // The secret-word ingredient lands as "Private item", never in his words (QA on #773).
        #expect(rows.contains("Private item") && !rows.contains { $0.lowercased().contains("password") }, "\(rows)")
        engine.undo(added.record)
        #expect(Groceries(store: store, classes: classes).shoppingOrder().isEmpty)
    }

    @Test func anExistingIngredientWithAWalledNameGoesBackOnWithoutThrowing() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ingredient = try store.create(#require(classes[.ingredient]), title: "Wifi password")
        var transaction = Transaction(store: store, classes: classes)
        let row = try transaction.addGroceryShare(GroceryShare(recipe: nil, amount: nil, unit: nil, packSize: nil),
                                                  ingredient: ingredient, text: ingredient.title)
        #expect(row.classDef?.name == classes[.listItem]?.name)
        _ = engine
    }
}

import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// B8 and G102: a private item reads "Private item" on every surface, and nothing opens it.
@MainActor
struct ShopTripTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func items(_ lines: [String]) throws -> [ListContents.Item] {
        try model.engine.perform(AddGroceries(lines: lines), by: .user)
        let list = try #require(model.store.object(id: Groceries.listID))
        return ListContents(store: model.store, classes: model.classes).open(in: list)
    }

    /// G102: a private row always reads "Private item"; there is no tap that shows it.
    @Test func aPrivateRowAlwaysReadsPrivateItem() throws {
        let rows = try items(["advil", "milk"])
        let advil = try #require(rows.first { $0.text.lowercased().contains("advil") })
        let milk = try #require(rows.first { $0.text.lowercased().contains("milk") })
        let trip = ShopTrip()
        #expect(trip.label(for: advil, name: advil.text, lastWeightKg: nil) == "Private item")
        #expect(trip.label(for: milk, name: milk.text, lastWeightKg: nil) == milk.text)
        #expect(trip.maskedLabel(for: advil, name: advil.text, lastWeightKg: nil) == "Private item")
    }

    @Test func aislesComeInTheShopsWalkOrder() {
        let order = ShopTrip.walkOrder(["Frozen", "Produce", "Household", "Dairy and eggs", "Mystery", "Bakery"])
        #expect(order == ["Produce", "Bakery", "Dairy and eggs", "Frozen", "Household", "Mystery"])
    }

    @Test func aPrivateRecipeNameIsOnlyPrivateRecipe() {
        #expect(ShopTrip.recipeNames(["Tacos", "Wifi code lasagna"], lastWeightKg: nil) == ["Tacos", "Private recipe"])
    }

    /// Pantry's swipe adds a thing by its own name (`AddGroceries(lines:)`); a walled one still reads "Private item".
    @Test func aWalledThingSwipedFromPantryReadsPrivateItemOnGroceries() throws {
        let rows = try items(["advil"])
        let trip = ShopTrip()
        #expect(rows.allSatisfy { trip.label(for: $0, name: $0.text, lastWeightKg: nil) == "Private item" })
        #expect(rows.allSatisfy { trip.maskedLabel(for: $0, name: $0.text, lastWeightKg: nil) == "Private item" })
    }
}

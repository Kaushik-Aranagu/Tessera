import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// B8: in SHOP mode a private item reads "Private item" until tapped, only that row opens, and leaving masks again.
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

    @Test func aPrivateRowOpensOnItsFirstTapAndMasksAgainAfterTheTrip() throws {
        let rows = try items(["advil", "milk"])
        let advil = try #require(rows.first { $0.text.lowercased().contains("advil") })
        let milk = try #require(rows.first { $0.text.lowercased().contains("milk") })
        let trip = ShopTrip()

        #expect(trip.label(for: advil, name: advil.text, lastWeightKg: nil) == "Private item")
        #expect(trip.label(for: milk, name: milk.text, lastWeightKg: nil) == milk.text)

        #expect(trip.tap(advil, lastWeightKg: nil) == .reveal)
        #expect(trip.label(for: advil, name: advil.text, lastWeightKg: nil) == advil.text)
        #expect(trip.tap(advil, lastWeightKg: nil) == .strike, "the next tap strikes as any row's would")
        #expect(trip.tap(milk, lastWeightKg: nil) == .strike)

        trip.end()
        #expect(trip.label(for: advil, name: advil.text, lastWeightKg: nil) == "Private item")
    }

    @Test func aislesComeInTheShopsWalkOrder() {
        let order = ShopTrip.walkOrder(["Frozen", "Produce", "Household", "Dairy and eggs", "Mystery", "Bakery"])
        #expect(order == ["Produce", "Bakery", "Dairy and eggs", "Frozen", "Household", "Mystery"])
    }

    @Test func aPrivateRecipeNameIsOnlyPrivateRecipe() {
        #expect(ShopTrip.recipeNames(["Tacos", "Wifi code lasagna"], lastWeightKg: nil) == ["Tacos", "Private recipe"])
    }
}

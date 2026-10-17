import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// pantry-acceptance.md §P, derived app-side: a shop clear makes things in, a finished cook makes them low (Produce
/// out), staples never move by cooking, and nothing touched stays unknown.
@MainActor
struct PantryLedgerTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel
    let saturday = Date(timeIntervalSince1970: 1_792_000_000)

    init() {
        model = AppModel(context: container.mainContext)
    }

    private var ledger: PantryLedger {
        PantryLedger(store: model.store, classes: model.classes)
    }

    private func tacos() throws -> ObjectRecord {
        try model.engine.perform(CreateRecipe(text: """
        Tacos
        1 lb ground beef
        2 limes
        8 corn tortillas
        salt

        Brown the beef.
        Warm the tortillas.
        """), by: .user).output
    }

    private func shop(_ recipe: ObjectRecord, at date: Date) throws {
        try model.engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        for item in model.store.object(id: Groceries.listID)?.orderedChildren ?? [] {
            try model.engine.perform(CheckListItem(item: item.id, time: date), by: .user)
        }
        try model.engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
    }

    private func cook(_ recipe: ObjectRecord, at date: Date) throws {
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id, time: date), by: .user).output
        try model.engine.perform(FinishCooking(cook: cook.id, time: date.addingTimeInterval(1800)), by: .user)
    }

    @Test func aShopMakesThingsInThenACookMakesThemLowAndProduceOut() throws {
        let recipe = try tacos()
        #expect(PantryLedger.hero(ledger.entries()) == "Nothing yet")

        try shop(recipe, at: saturday)
        let shopped = ledger.entries()
        #expect(shopped.count == 3)
        #expect(shopped.allSatisfy { $0.state == .have && $0.lastBoughtAt == saturday })

        try cook(recipe, at: saturday.addingTimeInterval(2 * 86400))
        let cooked = ledger.entries()
        #expect(cooked.map { model.store.displayTitle(of: $0.ingredient) } == [
            "Limes",
            "Corn tortillas",
            "Ground beef",
        ])
        #expect(cooked.map(\.state) == [.out, .low, .low])
        #expect(cooked.allSatisfy { $0.lastBoughtAt == saturday }, "a cook never moves the bought date")
        #expect(PantryLedger.hero(cooked) == "1 out, 2 low")
        // Tess's line names what that cook used up; the context line reads from the last shop.
        let used = ledger.lastCookUsedUp()
        #expect(used?.recipe == "Tacos" && used?.names == ["limes", "corn tortillas", "ground beef"])
        #expect(ledger.lastShop() == saturday)
    }

    @Test func staplesNeverMoveByCookingAndTheNextShopWins() throws {
        let recipe = try tacos()
        try cook(recipe, at: saturday)
        #expect(!ledger.entries().contains { model.store.displayTitle(of: $0.ingredient) == "Salt" })

        let monday = saturday.addingTimeInterval(2 * 86400)
        try shop(recipe, at: monday)
        let after = ledger.entries()
        #expect(after.allSatisfy { $0.state == .have && $0.lastBoughtAt == monday })
        #expect(PantryLedger.hero(after) == "Nothing out")
    }

    @Test func aWalledThingReadsPrivateItem() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: "Rest\n2 advil\n1 cup tea\n\nTake them."), by: .user)
            .output
        try cook(recipe, at: saturday)
        let entries = ledger.entries()
        #expect(entries.contains { $0.isPrivate && $0.label == "Private item" })
        #expect(!entries.contains { $0.label.lowercased().contains("advil") }, "the name never shows")
        // A private row opens nothing; a plain one opens its ingredient.
        #expect(entries.filter(\.isPrivate).allSatisfy { !PantryLine.opens($0) })
        #expect(entries.filter { !$0.isPrivate }.allSatisfy { PantryLine.opens($0) })
    }

    @Test func optionalAndToTasteLinesArentUsed() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: """
        Toast
        2 slices bread
        butter, to taste
        jam (optional)

        Toast the bread.
        """), by: .user).output
        try cook(recipe, at: saturday)
        let names = ledger.entries().map(\.label)
        #expect(names == ["Bread"], "butter to taste and the optional jam aren't used up")
    }

    @Test func aPrivateRecipeIsOnlyPrivateRecipeInTessLine() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: """
        Wifi code lasagna
        2 limes
        1 lb ground beef

        Bake it.
        """), by: .user).output
        try cook(recipe, at: saturday)
        let used = try #require(ledger.lastCookUsedUp())
        #expect(used.recipe == "Private recipe")
        #expect(PantryCopy.tess(recipe: used.recipe, names: used.names).hasPrefix("Private recipe took the "))
    }
}

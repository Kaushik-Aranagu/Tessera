import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kitchen gap hunt 2 (docs/product/kitchen-gap-hunt-2.md): G1, G6 to G9 and G11.
@MainActor
struct KitchenGaps2Tests {
    let store = ObjectStore.open(inMemory: true)

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    // MARK: G6

    @Test func groceriesListCannotBeDeleted() throws {
        let engine = try engine()
        #expect(throws: ActionError.self) {
            try engine.perform(DeleteObject(object: Groceries.listID), by: .tess)
        }
        #expect(Groceries(store: store, classes: engine.classes).list != nil)
        try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        let lists = store.objects(of: engine.classes[.list]!).filter { $0.title == "Groceries" }
        #expect(lists.count == 1)
        // Renaming stays allowed.
        try engine.perform(RenameObject(object: Groceries.listID, title: "Food"), by: .user)
    }

    // MARK: G7

    @Test func deletingARecipeTakesItsShareAndUndoBringsItBack() throws {
        let engine = try engine()
        let groceries = Groceries(store: store, classes: engine.classes)
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nServes 2\nIngredients\n3 onions\n200 g mince\nMethod\nCook it."), by: .user
        ).output
        try engine.perform(AddGroceries(lines: ["2 onions"]), by: .user)
        try engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        #expect(groceries.share(of: recipe).count == 2)

        let delete = try engine.perform(DeleteObject(object: recipe.id), by: .tess).record
        #expect(groceries.toBuy(for: recipe.id) == 0)
        let rows = groceries.aisles().flatMap(\.items)
        #expect(rows.count == 1)
        let onions = try #require(rows.first)
        let shares = GroceryShare.decode(store.value("shares", of: onions.object)?.stringValue)
        #expect(shares.allSatisfy { $0.recipe == nil })
        #expect(store.value("quantity", of: onions.object)?.stringValue == "2")

        _ = engine.undo(delete)
        #expect(groceries.toBuy(for: recipe.id) == 2)
        #expect(groceries.aisles().flatMap(\.items).count == 2)
    }

    // MARK: G8

    @Test func ordinalsAreEnglish() {
        let expected = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "10th",
                        "11th", "12th", "13th", "14th", "15th", "16th", "17th", "18th", "19th", "20th", "21st",
                        "22nd", "23rd", "24th", "25th", "26th", "27th", "28th", "29th", "30th", "31st"]
        for (index, word) in expected.enumerated() {
            #expect(CookLog.ordinal(index + 1) == word)
        }
    }

    @Test func finishLineUsesTheOrdinal() throws {
        let engine = try engine()
        let log = CookLog(store: store, classes: engine.classes)
        let recipe = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user).output
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let first = Date(timeIntervalSince1970: 1_791_986_400) // 14 Oct 2026
        var last = first
        for day in 0 ..< 21 {
            let at = first.addingTimeInterval(Double(day) * 60)
            let cook = try engine.perform(StartCooking(recipe: recipe.id, time: at), by: .user).output
            try engine.perform(FinishCooking(cook: cook.id, time: at), by: .user)
            last = at
        }
        #expect(log.finishLine(for: recipe, at: last, calendar: calendar) ==
            "Spaghetti carbonara, 21st time this month.")
    }

    // MARK: G9

    @Test func longTimersAreNotOfferedAndRefuseClearly() throws {
        let long = RecipeParser.durations(in: "Cure the salmon in the fridge for 48 hours.")
        #expect(long == [2880 ... 2880])
        #expect(RecipeParser.offeredTimers(long).isEmpty)
        #expect(RecipeParser.offeredTimers(RecipeParser.durations(in: "Rest for 24 hours.")).count == 1)
        let step = ParsedRecipe.Step(text: "Cure 48 hours.", timers: long)
        #expect(step.offeredTimers.isEmpty)

        let engine = try engine()
        do {
            try engine.perform(StartKitchenTimer(label: "Cure", minutes: 2880), by: .user)
            Issue.record("a 48 hour timer should be refused")
        } catch {
            #expect(TessCaptureEngine.line(for: error) == "Didn't save that. A timer runs up to 24 hours.")
        }
        try engine.perform(StartKitchenTimer(label: "Rest", minutes: 24 * 60), by: .user)
    }

}

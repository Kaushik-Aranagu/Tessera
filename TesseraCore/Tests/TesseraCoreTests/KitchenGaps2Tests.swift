import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kitchen gap hunt 2 (docs/product/kitchen-gap-hunt-2.md): G1, G6 to G9 and G11.
@MainActor
@Suite(.oldWalls)
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
        let lists = try store.objects(of: #require(engine.classes[.list])).filter { $0.title == "Groceries" }
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
            "Spaghetti carbonara, 21st time this month")
    }

    // MARK: G9

    @Test func longTimersAreNotOfferedAndRefuseClearly() throws {
        let long = RecipeParser.durations(in: "Cure the salmon in the fridge for 48 hours")
        #expect(long == [2880 ... 2880])
        #expect(RecipeParser.offeredTimers(long).isEmpty)
        #expect(RecipeParser.offeredTimers(RecipeParser.durations(in: "Rest for 24 hours")).count == 1)
        let step = ParsedRecipe.Step(text: "Cure 48 hours", timers: long)
        #expect(step.offeredTimers.isEmpty)

        let engine = try engine()
        do {
            try engine.perform(StartKitchenTimer(label: "Cure", minutes: 2880), by: .user)
            Issue.record("a 48 hour timer should be refused")
        } catch {
            #expect(TessCaptureEngine.line(for: error) == "Didn't save that. A timer runs up to 24 hours")
        }
        try engine.perform(StartKitchenTimer(label: "Rest", minutes: 24 * 60), by: .user)
    }

    // MARK: G11

    @Test func renameOntoAnExistingIngredientKeyIsRefused() throws {
        let engine = try engine()
        try engine.perform(
            CreateRecipe(text: "Salsa\nIngredients\n2 tomatoes\n1 roma tomato\nMethod\nChop."), by: .user
        )
        let book = IngredientBook(store: store, classes: engine.classes)
        let tomato = try #require(book.find("tomato"))
        let roma = try #require(book.all().first { $0.title.lowercased().hasPrefix("roma") })
        #expect(throws: ActionError.self) {
            try engine.perform(RenameObject(object: roma.id, title: "Tomatoes"), by: .tess)
        }
        #expect(roma.title.lowercased().hasPrefix("roma"))
        // A fresh key is a plain rename; renaming to its own key is fine.
        try engine.perform(RenameObject(object: roma.id, title: "Roma tomatoes"), by: .tess)
        #expect(roma.title == "Roma tomatoes")
        try engine.perform(RenameObject(object: tomato.id, title: "Tomatoes"), by: .tess)
        #expect(book.all().count == 2)
    }

    // MARK: G1

    @Test func knownPairsStayOneRow() {
        #expect(GroceryLines.split("mac and cheese") == ["mac and cheese"])
        #expect(GroceryLines.split("Salt and pepper") == ["Salt and pepper"])
        #expect(GroceryLines.split("eggs, bread and 2 lemons") == ["eggs", "bread", "2 lemons"])
        #expect(GroceryLines.split("milk, mac and cheese and 2 lemons") == ["milk", "mac and cheese", "2 lemons"])
        #expect(GroceryLines.split("milk and eggs") == ["milk", "eggs"])
        #expect(TessGrammar.splitItems("buy mac and cheese") == ["buy mac and cheese"])
    }
}

// MARK: Gap hunt 3

@MainActor
@Suite(.oldWalls)
struct KitchenGaps3Tests {
    let store = ObjectStore.open(inMemory: true)

    /// G15
    @Test func clearingAnEmptyBasketLogsNothing() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let before = store.context.all(OpRecord.self).count
        #expect(throws: ActionError.self) {
            try engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
        }
        #expect(store.context.all(OpRecord.self).count == before)
        // A shop finished with an empty basket still ends.
        try engine.perform(StartShop(), by: .user)
        try engine.perform(FinishShop(), by: .user)
        #expect(ProcessTable(engine: engine).running() == nil)
    }

    @Test func clearingCheckedRowsKeepsItsReceipt() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let rows = try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user).output
        for row in rows {
            try engine.perform(CheckListItem(item: row.id), by: .user)
        }
        let record = try engine.perform(ClearDoneItems(list: Groceries.listID), by: .user).record
        #expect(record.receipt == "Groceries, done items cleared")
        #expect(Groceries(store: store, classes: engine.classes).aisles().isEmpty)
    }

    /// G16
    @Test func listToolAddsGroceriesThroughTheAddLine() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let json = #"{"list":"groceries","items":[{"text":"milk"},{"text":"eggs"},{"text":"milk $4"}]}"#
        let records = try TessTools.run("addToList", arguments: Data(json.utf8), engine: engine)
        for record in records where record.state == .pending {
            try engine.commit(record)
        }
        let groceries = Groceries(store: store, classes: classes)
        let rows = groceries.aisles().flatMap(\.items)
        #expect(rows.count == 2)
        #expect(groceries.isOn("milk") && groceries.isOn("eggs"))
        #expect(groceries.aisles().contains { $0.aisle == Aisle.dairy.rawValue && $0.items.count == 2 })
    }
}

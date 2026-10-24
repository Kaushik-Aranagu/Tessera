import Foundation
@testable import TesseraCore
import Testing

/// Kitchen engine actions for the Pantry and Recipes screens: each is one undoable op with a receipt sentence.
@MainActor
struct PantryActionsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let stock: PantryStock

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
        stock = PantryStock(store: store, classes: classes)
        PantryPlaces(store: store, classes: classes).ensureDefaults()
    }

    func ingredient(_ name: String) throws -> ObjectRecord {
        let made = try engine.perform(AddToPlace(name: name, place: PantryPlaces.defaultID("fridge")), by: .user)
        return made.output.ingredient
    }

    func receipt(_ result: ActionEngine.Result<some Any>) -> String? {
        result.record.receipt
    }

    @Test func setStockWritesTheLevelAndSaysIt() throws {
        let eggs = try ingredient("Eggs")
        let low = try engine.perform(SetIngredientStock(item: eggs.id, level: .low), by: .user)
        #expect(low.record.receipt == "Eggs, running low.")
        #expect(stock.level(of: eggs)?.level == .low)
        let out = try engine.perform(SetIngredientStock(item: eggs.id, level: .out), by: .user)
        #expect(out.record.receipt == "Eggs, out.")
        engine.undo(out.record)
        #expect(stock.level(of: eggs)?.level == .low)
    }

    @Test func usedUpGoesOutAndOntoToGetInOneUndo() throws {
        let milk = try ingredient("Milk")
        let used = try engine.perform(UseUpIngredient(item: milk.id), by: .user)
        #expect(used.record.receipt == "Milk, used up. On To get.")
        #expect(stock.level(of: milk)?.level == .out)
        #expect(stock.openRow(for: milk) != nil)
        engine.undo(used.record)
        #expect(stock.level(of: milk) == nil)
        #expect(stock.openRow(for: milk) == nil)
    }

    @Test func gotItChecksTheRowAndPutsItBackInItsPlace() throws {
        let feta = try ingredient("Feta")
        try engine.perform(UseUpIngredient(item: feta.id), by: .user)
        let row = try #require(stock.openRow(for: feta))
        let got = try engine.perform(GotIngredient(item: feta.id), by: .user)
        #expect(got.record.receipt == "Feta, got it. Back in the fridge.")
        #expect(stock.level(of: feta)?.level == .in)
        #expect(store.value("isDone", of: row) == .bool(true) && stock.openRow(for: feta) == nil)
        engine.undo(got.record)
        #expect(stock.level(of: feta)?.level == .out && stock.openRow(for: feta) != nil)
    }

    @Test func gotItWithNothingOnTheListStillSetsStock() throws {
        let basil = try ingredient("Basil")
        let got = try engine.perform(GotIngredient(item: basil.id), by: .user)
        #expect(stock.level(of: basil)?.level == .in && got.record.receipt?.hasPrefix("Basil, got it.") == true)
    }

    @Test func notNowSnoozesToTomorrowsFourAM() throws {
        let spinach = try ingredient("Spinach")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 21)))
        let snooze = try engine.perform(SnoozeIngredient(item: spinach.id, time: now), by: .user)
        #expect(snooze.record.receipt == "Spinach, not now. Asks again tomorrow.")
        let until = SnoozeIngredient.until(now)
        #expect(calendar.component(.day, from: until) == 16 && calendar.component(.hour, from: until) == 4)
        #expect(stock.isSnoozed(spinach, at: now))
        #expect(stock.isSnoozed(spinach, at: until.addingTimeInterval(-60)))
        #expect(!stock.isSnoozed(spinach, at: until))
        // Just after midnight it is still tonight's day: the same 4 am.
        let late = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 1)))
        #expect(SnoozeIngredient.until(late) == until)
        // Telling the Pantry how much is left ends the snooze.
        try engine.perform(SetIngredientStock(item: spinach.id, level: .low), by: .user)
        #expect(!stock.isSnoozed(spinach, at: now))
    }

    @Test func threePinsAPlaceThenTheFourthIsRefused() throws {
        let names = ["Eggs", "Milk", "Butter", "Cheese"]
        let items = try names.map(ingredient)
        for item in items.prefix(3) {
            let pinned = try engine.perform(PinIngredient(item: item.id), by: .user)
            #expect(pinned.record.receipt?.hasSuffix(", pinned.") == true)
        }
        let error = #expect(throws: ActionError.self) {
            try engine.perform(PinIngredient(item: items[3].id), by: .user)
        }
        #expect(error.flatMap(PantryRefusal.line) == "Three pins already. Unpin one first.")
        try engine.perform(PinIngredient(item: items[0].id, pinned: false), by: .user)
        try engine.perform(PinIngredient(item: items[3].id), by: .user)
        #expect(stock.pinned(in: PantryPlaces(store: store, classes: classes).place(of: items[3])).count == 3)
        // Pins count per place: another place has its own three.
        let shelf = try #require(store.object(id: PantryPlaces.defaultID("shelf")))
        let rice = try engine.perform(AddToPlace(name: "Rice", place: shelf.id), by: .user).output.ingredient
        try engine.perform(PinIngredient(item: rice.id), by: .user)
    }

    @Test func addingAThingToAPlaceByName() throws {
        let fridge = PantryPlaces.defaultID("fridge")
        let added = try engine.perform(AddToPlace(name: "basil", place: fridge), by: .user)
        #expect(added.record.receipt == "Basil, added to the fridge.")
        #expect(PantryPlaces(store: store, classes: classes).place(of: added.output.ingredient)?.id == fridge)
        // The same name finds the same ingredient, moved.
        let shelf = PantryPlaces.defaultID("shelf")
        let again = try engine.perform(AddToPlace(name: "Basil", place: shelf), by: .user)
        #expect(again.output.ingredient.id == added.output.ingredient.id && again.output.moved)
        #expect(again.record.receipt == "Basil, moved to the shelf." && !added.output.moved)
        #expect(throws: ActionError.self) {
            try engine.perform(AddToPlace(name: "sk-ant-api03-abcdef", place: fridge), by: .user)
        }
        engine.undo(added.record)
    }

    @Test func aPrivateItemIsSaidByItsLabelInReceipts() throws {
        let fridge = PantryPlaces.defaultID("fridge")
        let pill = try engine.perform(AddToPlace(name: "melatonin", place: fridge), by: .user).output.ingredient
        let low = try engine.perform(SetIngredientStock(item: pill.id, level: .low), by: .user)
        #expect(low.record.receipt == "Private item, running low.")
        #expect(low.record.summary.contains("Private item") && !low.record.summary.contains("elatonin"))
        let used = try engine.perform(UseUpIngredient(item: pill.id), by: .user)
        #expect(used.record.receipt == "Private item, used up. On To get.")
    }

    @Test func gotItTicksEveryOpenRowForTheItem() throws {
        let feta = try ingredient("Feta")
        try engine.perform(UseUpIngredient(item: feta.id), by: .user)
        // A second pack size of the same food on the list.
        try engine.perform(AddGroceries(lines: ["feta 200 g"]), by: .user)
        let rows = stock.openRows(for: feta)
        #expect(rows.count >= 1)
        try engine.perform(GotIngredient(item: feta.id), by: .user)
        #expect(stock.openRows(for: feta).isEmpty)
        for row in rows {
            #expect(store.value("isDone", of: row) == .bool(true))
        }
    }

    @Test func movingAnItemDropsItsPinSoNoPlaceHoldsAFourth() throws {
        let fridge = PantryPlaces.defaultID("fridge")
        let shelf = PantryPlaces.defaultID("shelf")
        let items = try ["Rice", "Dal", "Pasta", "Oats"].map { name in
            try engine.perform(AddToPlace(name: name, place: shelf), by: .user).output.ingredient
        }
        for item in items.prefix(3) {
            try engine.perform(PinIngredient(item: item.id), by: .user)
        }
        // Rice moves to the fridge: its pin stays behind, and the shelf has room again.
        try engine.perform(AddToPlace(name: "Rice", place: fridge), by: .user)
        #expect(!stock.isPinned(items[0]))
        try engine.perform(PinIngredient(item: items[3].id), by: .user)
        // The same through the place picker.
        try engine.perform(SetItemPlace(item: items[1].id, place: fridge), by: .user)
        #expect(!stock.isPinned(items[1]))
    }

    @Test func theEngineClockAndCalendarDecideTheSnoozeAndThePlanDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        engine.zone = { calendar.timeZone }
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 21)))
        engine.now = { now }
        let spinach = try ingredient("Spinach")
        try engine.perform(SnoozeIngredient(item: spinach.id), by: .user)
        let until = try #require(store.value("snoozedUntil", of: spinach)?.dateValue)
        #expect(calendar.component(.day, from: until) == 16 && calendar.component(.hour, from: until) == 4)
        let shakshuka = try recipe("Shakshuka")
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 1)))
        let planned = try engine.perform(PlanRecipe(recipe: shakshuka.id, day: day), by: .user)
        // 1 AM Monday in Auckland is before the 4 am turn: still Sunday there.
        #expect(planned.record.receipt == "Shakshuka, planned for Sunday.")
    }

    func recipe(_ title: String) throws -> ObjectRecord {
        try store.create(#require(classes[.recipe]), title: title)
    }

    @Test func threeRecipePinsAndNoFourth() throws {
        let recipes = try ["Shakshuka", "Dal", "Pasta", "Tacos"].map(recipe)
        for item in recipes.prefix(3) {
            try engine.perform(PinRecipe(recipe: item.id), by: .user)
        }
        let error = #expect(throws: ActionError.self) { try engine.perform(PinRecipe(recipe: recipes[3].id), by: .user)
        }
        #expect(error.flatMap(PantryRefusal.line) == "Three pins already. Unpin one first.")
        let unpin = try engine.perform(PinRecipe(recipe: recipes[0].id, pinned: false), by: .user)
        #expect(unpin.record.receipt == "Shakshuka, unpinned." && stock.pinnedRecipes().count == 2)
    }

    @Test func planningARecipeForADayOnceOnly() throws {
        let shakshuka = try recipe("Shakshuka")
        var calendar = Calendar.current
        calendar.timeZone = .current
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 18)))
        let planned = try engine.perform(PlanRecipe(recipe: shakshuka.id, day: monday), by: .user)
        #expect(planned.record.receipt == "Shakshuka, planned for Monday.")
        let occasion = planned.output.occasion
        #expect(store.linkedObjects("links", of: occasion).map(\.id) == [shakshuka.id])
        let again = #expect(throws: ActionError.self) {
            try engine.perform(PlanRecipe(recipe: shakshuka.id, day: monday.addingTimeInterval(3600)), by: .user)
        }
        #expect(again.flatMap(PantryRefusal.line) == "Already planned that day.")
        // Another day is fine; a different recipe the same day is fine.
        let tuesday = monday.addingTimeInterval(86400)
        try engine.perform(PlanRecipe(recipe: shakshuka.id, day: tuesday), by: .user)
        try engine.perform(PlanRecipe(recipe: recipe("Dal").id, day: monday), by: .user)
        engine.undo(planned.record)
        try engine.perform(PlanRecipe(recipe: shakshuka.id, day: monday), by: .user)
    }

    @Test func everyActionDecodesFromItsName() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let id = UUID()
        func check<A: EngineAction>(_ action: A) throws {
            let decoded = try ActionRegistry.decode(name: A.descriptor.name, arguments: encoder.encode(action))
            #expect(decoded is A, "\(A.descriptor.name)")
        }
        try check(SetIngredientStock(item: id, level: .low))
        try check(UseUpIngredient(item: id))
        try check(GotIngredient(item: id))
        try check(SnoozeIngredient(item: id))
        try check(PinIngredient(item: id))
        try check(AddToPlace(name: "Basil", place: id))
        try check(PinRecipe(recipe: id))
        try check(PlanRecipe(recipe: id, day: Date(timeIntervalSince1970: 1_700_000_000)))
    }
}

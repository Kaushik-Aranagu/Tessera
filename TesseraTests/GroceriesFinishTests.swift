@testable import Tessera
import TesseraCore
import Testing

/// G43: Done on a shop reads "Shopping, finished." with UNDO; a failed write says so and undoes nothing.
@MainActor
struct GroceriesFinishTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func basket() throws -> ListContents.Item {
        try model.engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        try model.engine.perform(StartShop(), by: .user)
        let groceries = Groceries(store: model.store, classes: model.classes)
        let milk = try #require(groceries.shoppingOrder().first { $0.text == "milk" })
        try model.engine.perform(CheckListItem(item: milk.id), by: .user)
        return milk
    }

    @Test func finishSaysShoppingFinishedWithUndo() throws {
        let milk = try basket()
        let outcome = GroceriesCopy.finish(engine: model.engine)
        #expect(outcome.line == "Shopping, finished.")
        let record = try #require(outcome.undo)
        #expect(model.store.object(id: milk.id)?.isDeleted == true)
        _ = model.engine.undo(record)
        #expect(model.store.object(id: milk.id)?.isDeleted == false)
    }

    /// A refused write: the failure line, nothing to undo (so the View keeps the basket and plays no haptic).
    @Test func finishFailureSaysDidntSave() {
        let outcome = GroceriesCopy.finish { nil }
        #expect(outcome.line == "Didn't save that. Try again." && outcome.undo == nil)
    }

    @Test func aShopStartDuringAWorkoutSaysWorkoutRunning() throws {
        try model.engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let workout = try model.store.create(#require(model.classes[.workout]), title: "Push day")
        try model.engine.perform(StartWorkout(workout: workout.id), by: .user)
        let groceries = Groceries(store: model.store, classes: model.classes)
        #expect(GroceriesCopy.toggleShop(groceries, engine: model.engine) == "Workout running.")
        #expect(groceries.shop(in: model.engine)?.state != .running)
    }

    @Test func aShopStartsAndSetsAsideSilently() throws {
        try model.engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let groceries = Groceries(store: model.store, classes: model.classes)
        #expect(GroceriesCopy.toggleShop(groceries, engine: model.engine) == nil)
        #expect(groceries.shop(in: model.engine)?.state == .running)
        #expect(GroceriesCopy.toggleShop(groceries, engine: model.engine) == nil)
        #expect(groceries.shop(in: model.engine)?.state == .suspended)
    }

    /// G43: UNDO after a finish puts Pantry back as it was before the shop.
    @Test func undoAfterFinishPutsPantryBack() throws {
        _ = try basket()
        let pantry = PantryLedger(store: model.store, classes: model.classes)
        let before = pantry.entries().map { "\($0.label) \($0.state)" }
        let record = try #require(GroceriesCopy.finish(engine: model.engine).undo)
        #expect(pantry.entries().map { "\($0.label) \($0.state)" } != before)
        _ = model.engine.undo(record)
        #expect(pantry.entries().map { "\($0.label) \($0.state)" } == before)
    }

    /// G43: the finish line names no item, so a private one in the basket never shows.
    @Test func finishLineNamesNoItem() throws {
        try model.engine.perform(AddGroceries(lines: ["condoms"]), by: .user)
        try model.engine.perform(StartShop(), by: .user)
        for item in Groceries(store: model.store, classes: model.classes).shoppingOrder() {
            try model.engine.perform(CheckListItem(item: item.id), by: .user)
        }
        let outcome = GroceriesCopy.finish(engine: model.engine)
        #expect(outcome.line == "Shopping, finished." && !outcome.line.lowercased().contains("condom"))
    }

    /// ER11: a refused clear says so, gives no UNDO, and the View keeps the basket open.
    @Test func aRefusedClearSaysSoWithNoUndo() {
        let outcome = GroceriesCopy.clear(count: 3) { nil }
        #expect(outcome.line == "Didn't save that. Try again." && outcome.undo == nil)
        #expect(GroceriesCopy.didntSave == "Didn't save that. Try again.")
    }

    @Test func aClearSaysHowManyWithUndo() throws {
        _ = try basket()
        let outcome = GroceriesCopy.clear(count: 1) {
            try? model.engine.perform(ClearDoneItems(list: Groceries.listID), by: .user).record
        }
        #expect(outcome.line == "Cleared 1 from the basket." && outcome.undo != nil)
    }
}

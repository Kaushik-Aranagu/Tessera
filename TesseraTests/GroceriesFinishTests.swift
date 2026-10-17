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
}

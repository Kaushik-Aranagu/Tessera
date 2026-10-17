import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// B12: Pantry's front as data (pantry-acceptance S1 to S17).
@MainActor
struct PantryFrontTests {
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
        try model.engine.perform(CreateRecipe(text: "Tacos\n1 lb ground beef\n2 limes\n\nBrown the beef."), by: .user)
            .output
    }

    @Test func nothingKnownIsNothingYet() {
        let front = PantryFront(ledger: ledger, now: saturday)
        #expect(front.hero == "Nothing yet" && front.isEmpty && front.out.isEmpty && front.low.isEmpty)
        #expect(front.context == nil && front.tess == nil)
    }

    @Test func aCookFillsOutAndLowAndTessLine() throws {
        let recipe = try tacos()
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id, time: saturday), by: .user).output
        try model.engine.perform(FinishCooking(cook: cook.id, time: saturday.addingTimeInterval(1800)), by: .user)
        let front = PantryFront(ledger: ledger, now: saturday)
        #expect(front.hero == "1 out, 1 low")
        #expect(front.out.map(\.label) == ["Limes"] && front.low.map(\.label) == ["Ground beef"])
        #expect(front.tess == "Tacos took the limes and ground beef.")
    }

    @Test func aThingAlreadyOnGroceriesIsNotAddedTwice() throws {
        let recipe = try tacos()
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id, time: saturday), by: .user).output
        try model.engine.perform(FinishCooking(cook: cook.id, time: saturday.addingTimeInterval(1800)), by: .user)
        let limes = try #require(ledger.entries().first { $0.label == "Limes" })
        let groceries = Groceries(store: model.store, classes: model.classes)
        #expect(PantryFront
            .swipe(limes, groceries: groceries, store: model.store) == .add(receipt: "Limes, on Groceries."))
        try model.engine.perform(AddGroceries(lines: ["limes"]), by: .user)
        #expect(PantryFront.swipe(limes, groceries: groceries, store: model.store)
            == .already(receipt: "Limes, already on Groceries."))
    }

    @Test func aCheckedRowInTheBasketCoversTheAdd() throws {
        let recipe = try tacos()
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id, time: saturday), by: .user).output
        try model.engine.perform(FinishCooking(cook: cook.id, time: saturday.addingTimeInterval(1800)), by: .user)
        let limes = try #require(ledger.entries().first { $0.label == "Limes" })
        try model.engine.perform(AddGroceries(lines: ["limes"]), by: .user)
        let groceries = Groceries(store: model.store, classes: model.classes)
        let row = try #require(groceries.list?.orderedChildren.first)
        try model.engine.perform(CheckListItem(item: row.id, time: saturday), by: .user)
        #expect(PantryFront.swipe(limes, groceries: groceries, store: model.store)
            == .already(receipt: "Limes, in the basket."))
    }
}

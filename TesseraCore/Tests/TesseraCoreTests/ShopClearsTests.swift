import Foundation
@testable import TesseraCore
import Testing

/// G45: Pantry counts a shop clear as buying, never a checked row he deleted another way.
@MainActor
struct ShopClearsTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test func onlyAShopClearCountsAsBuying() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        let groceries = Groceries(store: store, classes: classes)
        func row(_ name: String) throws -> ObjectRecord {
            try #require(groceries.shoppingOrder().first { $0.text.lowercased() == name }).object
        }
        // Checked by mistake at home, then deleted: not buying.
        let milk = try row("milk")
        try engine.perform(CheckListItem(item: milk.id, time: t0), by: .user)
        try engine.perform(DeleteObject(object: milk.id), by: .user)
        #expect(groceries.shopClears().isEmpty)
        // Checked in the shop and cleared: buying, on the day it was checked.
        try engine.perform(CheckListItem(item: row("eggs").id, time: t0 + 60), by: .user)
        let cleared = try engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
        let bought = groceries.shopClears()
        #expect(bought.map(\.ingredient.title.localizedLowercase) == ["eggs"] && bought.first?.at == t0 + 60)
        // UNDO of the clear puts the row back: nothing was bought.
        engine.undo(cleared.record)
        #expect(groceries.shopClears().isEmpty)
    }
}

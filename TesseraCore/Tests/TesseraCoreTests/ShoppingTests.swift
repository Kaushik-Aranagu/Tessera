import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct ShoppingTests {
    @Test func shoppingRunsOnNowInAisleOrder() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let groceries = Groceries(store: store, classes: classes)
        let table = ProcessTable(engine: engine)
        let lists = ListContents(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk", "2 lemons", "bread", "500 g mince"]), by: .user)
        // US walk order: dairy and eggs before meat and seafood.
        #expect(groceries.shoppingOrder().map(\.text) == ["lemons", "bread", "milk", "mince"])

        try engine.perform(StartShop(), by: .user)
        #expect(table.running()?.nextStep == "Shopping, 4 left")
        #expect(NowPicker(engine: engine).pick().now?.object.id == Groceries.listID)

        let lemons = try #require(groceries.shoppingOrder().first)
        try engine.perform(CheckListItem(item: lemons.id), by: .user)
        #expect(table.running()?.nextStep == "Shopping, 3 left")
        #expect(groceries.shoppingOrder().first?.text == "bread")

        // Leaving the shop suspends it; starting again resumes the same process.
        let running = try #require(table.running())
        try engine.perform(SuspendProcess(process: running.id), by: .user)
        #expect(groceries.shop(in: engine)?.state == .suspended)
        try engine.perform(StartShop(), by: .user)
        #expect(table.running()?.id == running.id)

        let cleared = try engine.perform(FinishShop(), by: .user)
        #expect(cleared.output == 1)
        #expect(table.running() == nil)
        #expect(try lists.items(of: #require(groceries.list)).count == 3)
        #expect(groceries.shop(in: engine) == nil)
    }
}

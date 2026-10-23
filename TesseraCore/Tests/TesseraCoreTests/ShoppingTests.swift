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

    // MARK: G43

    /// 14 rows, a running shop, all 14 checked.
    private func checkedShop() throws -> (engine: ActionEngine, store: ObjectStore, process: UUID) {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let names = (1 ... 14).map { "thing\($0)" }
        try engine.perform(AddGroceries(lines: names), by: .user)
        try engine.perform(StartShop(), by: .user)
        let groceries = Groceries(store: store, classes: classes)
        for row in groceries.shoppingOrder() {
            try engine.perform(CheckListItem(item: row.id), by: .user)
        }
        let process = try #require(ProcessTable(engine: engine).running()).id
        return (engine, store, process)
    }

    @Test func finishShopUndoBringsBackTheBasketAndTheShop() throws {
        let (engine, store, process) = try checkedShop()
        let groceries = Groceries(store: store, classes: engine.classes)
        let lists = ListContents(store: store, classes: engine.classes)
        let list = try #require(groceries.list)
        let before = lists.items(of: list).map { ($0.id, $0.checkedAt) }
        #expect(before.count == 14)
        let done = try engine.perform(FinishShop(), by: .user)
        #expect(done.output == 14)
        #expect(ProcessTable(engine: engine).running() == nil)
        #expect(lists.items(of: list).isEmpty)

        #expect(engine.undo(done.record) == .applied)
        let after = lists.items(of: list)
        #expect(after.count == 14)
        #expect(after.allSatisfy { $0.isDone })
        #expect(Set(after.map(\.id)) == Set(before.map(\.0)))
        for item in after {
            #expect(item.checkedAt == before.first { $0.0 == item.id }.flatMap(\.1))
        }
        let shop = try #require(groceries.shop(in: engine))
        #expect(shop.state == .running && shop.id == process)
        #expect(ProcessTable(engine: engine).running()?.nextStep == "Shopping, all in the basket")
    }

    @Test func finishShopUndoRestoresPantryStates() throws {
        let (engine, store, _) = try checkedShop()
        let list = try #require(Groceries(store: store, classes: engine.classes).list)
        let rows = list.orderedChildren
        let done = try engine.perform(FinishShop(), by: .user)
        #expect(rows.allSatisfy { $0.isDeleted })
        engine.undo(done.record)
        #expect(rows.count == 14)
        #expect(rows.allSatisfy { !$0.isDeleted })
    }

    @Test func finishShopReceiptNamesTheShopFirst() throws {
        let (engine, _, _) = try checkedShop()
        let done = try engine.perform(FinishShop(), by: .user)
        #expect(done.record.receipt == "Shopping, finished")
        #expect(done.record.summary == "Finished shopping")
    }

    @Test func finishShopWithNothingCheckedStillFinishes() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        try engine.perform(StartShop(), by: .user)
        let done = try engine.perform(FinishShop(), by: .user)
        #expect(done.output == 0)
        #expect(ProcessTable(engine: engine).running() == nil)
        #expect(done.record.receipt == "Shopping, finished")
        #expect(Groceries(store: store, classes: classes).shoppingOrder().count == 2)
    }

    @Test func finishShopFailureWritesNothing() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        // No groceries list at all: there is no shop to finish, and nothing is made to finish on.
        store.softDelete(try #require(store.object(id: Groceries.listID)))
        let objects = store.context.objects.count
        let records = engine.history(limit: 100).count
        #expect(throws: ActionError.self) {
            try engine.perform(FinishShop(), by: .user)
        }
        #expect(store.context.objects.count == objects)
        #expect(engine.history(limit: 100).count == records)
        #expect(ProcessTable(engine: engine).running() == nil)
    }
}

/// FinishShop(putAway:): the places are set and the shop finished as one change.
@MainActor
struct FinishShopPutAwayTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let places: PantryPlaces

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        places = PantryPlaces(store: store, classes: engine.classes)
        places.ensureDefaults()
    }

    func ingredient(_ name: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[.ingredient]), title: name)
    }

    func place(_ key: String) throws -> ObjectRecord {
        try #require(store.object(id: PantryPlaces.defaultID(key)))
    }

    func startedShop() throws {
        try engine.perform(AddGroceries(lines: ["milk", "bread"]), by: .user)
        try engine.perform(StartShop(), by: .user)
        let groceries = Groceries(store: store, classes: engine.classes)
        for row in groceries.shoppingOrder() {
            try engine.perform(CheckListItem(item: row.id), by: .user)
        }
    }

    @Test func placesAndFinishAreOneRecordAndOneUndo() throws {
        let milk = try ingredient("milk"), fridge = try place("fridge")
        try startedShop()
        let before = engine.history(limit: 500).count
        let done = try engine.perform(
            FinishShop(putAway: [ShopPutAway(item: milk.id, place: fridge.id, section: "Door")]), by: .user
        )
        #expect(engine.history(limit: 500).count == before + 1)
        #expect(places.place(of: milk)?.id == fridge.id && places.section(of: milk) == "Door")
        #expect(ProcessTable(engine: engine).running() == nil)
        engine.undo(done.record)
        #expect(places.place(of: milk) == nil)
        #expect(ProcessTable(engine: engine).running() != nil)
        #expect(Groceries(store: store, classes: engine.classes).shoppingOrder().isEmpty)
    }

    @Test func aFailedFinishSetsNoPlaces() throws {
        let milk = try ingredient("milk"), fridge = try place("fridge")
        try startedShop()
        let before = engine.history(limit: 500).count
        #expect(throws: (any Error).self) {
            try engine.perform(FinishShop(putAway: [
                ShopPutAway(item: milk.id, place: fridge.id),
                ShopPutAway(item: UUID(), place: fridge.id),
            ]), by: .user)
        }
        #expect(places.place(of: milk) == nil)
        #expect(ProcessTable(engine: engine).running() != nil)
        #expect(engine.history(limit: 500).count == before)
    }

    @Test func aPlainFinishAndTheToolCallStillWork() throws {
        try startedShop()
        let record = try engine.perform(named: "finishShop", arguments: Data("{}".utf8), by: .user)
        #expect(record.action == "finishShop")
        #expect(ProcessTable(engine: engine).running() == nil)
    }

    @Test func theToolCallCarriesPutAway() throws {
        let milk = try ingredient("milk"), fridge = try place("fridge")
        try startedShop()
        let json = #"{"putAway":[{"item":"\#(milk.id.uuidString)","place":"\#(fridge.id.uuidString)"}]}"#
        try engine.perform(named: "finishShop", arguments: Data(json.utf8), by: .user)
        #expect(places.place(of: milk)?.id == fridge.id)
    }
}

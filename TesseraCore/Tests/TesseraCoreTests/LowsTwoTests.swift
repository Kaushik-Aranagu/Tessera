import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Lows from QA on #305, #306 and #309, and Design's bare-add rule.
@MainActor
struct LowsTwoTests {
    @Test func aBareNameJoinsTheSizedRowAndLeavesTheCount() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["1 (15 oz) can chickpeas"]), by: .user)
        let tess = TessCaptureEngine(engine: engine)
        let capture = await tess.capture("buy chickpeas", context: TessContext(commitImmediately: true))
        #expect(capture.line == "Chickpeas, already on Groceries.")
        let groceries = Groceries(store: store, classes: classes)
        let items = groceries.aisles().flatMap(\.items)
        #expect(items.count == 1 && items.first?.quantity == "1 can")
        // "2 cans chickpeas" still adds, same size; a bare add onto a bare row stays one row.
        try engine.perform(AddGroceries(lines: ["1 (15 oz) can chickpeas"]), by: .user)
        #expect(groceries.aisles().flatMap(\.items).first?.quantity == "2 cans")
        try engine.perform(AddGroceries(lines: ["oat milk", "oat milk"]), by: .user)
        #expect(groceries.aisles().flatMap(\.items).count { $0.text.lowercased().contains("oat milk") } == 1)
    }

    @Test func poundCakeIsACake() throws {
        let cake = try #require(IngredientLine.parse("1 pound cake"))
        #expect(cake.unit == nil && cake.name == "pound cake" && cake.amount == 1)
        #expect(IngredientLine.parse("1 pound carrots")?.unit == .pound)
        // QA on #316: "lb" is never a pound cake, and "cake flour" is flour.
        let flour = try #require(IngredientLine.parse("1 lb cake flour"))
        #expect(flour.unit == .pound && flour.name == "cake flour")
        #expect(IngredientLine.parse("1 pound cake flour")?.unit == .pound)
        #expect(IngredientLine.parse("1 lb cake")?.unit == .pound)
    }

    @Test func alreadyOnGroceriesMakesNoRecordWithoutCommitImmediately() async throws {
        // QA S1 on #316: no ghost and no empty UNDO when nothing changes.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["1 (15 oz) can chickpeas"]), by: .user)
        let ops = store.context.all(OpRecord.self).count
        let capture = await TessCaptureEngine(engine: engine).capture("buy chickpeas", context: TessContext())
        #expect(capture.line == "Chickpeas, already on Groceries.")
        #expect(capture.records.isEmpty)
        #expect(store.context.all(OpRecord.self).count == ops)
        // Something with an amount still adds.
        let more = await TessCaptureEngine(engine: engine).capture("buy 2 cans chickpeas", context: TessContext())
        #expect(!more.records.isEmpty)
    }

    @Test func aStoreFromCatalogV4KeepsItsSettingsAndObjectsAtV5() throws {
        // QA L1 on #305: seeding v5 over a v4 store changes nothing he had.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try SettingsStore(engine: engine).update { $0.lookDay = "Porcelain" }
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        let before = store.context.all(ObjectRecord.self).count
        for classDef in store.context.all(ClassDef.self) where classDef.systemKey != nil {
            classDef.packageVersion = 4
        }
        _ = try store.prepareCatalog()
        #expect(SettingsStore(engine: engine).read().lookDay == "Porcelain")
        #expect(store.context.all(ObjectRecord.self).count == before)
    }

    @Test func waitingPhrasesCanBeLetGo() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let tess = TessCaptureEngine(engine: ActionEngine(store: store, classes: classes))
        TessInbox(store: store, classes: classes).add("log bench from earlier", at: .now)
        #expect(tess.waitingCount == 1)
        tess.clearWaiting()
        #expect(tess.waitingCount == 0)
    }
}

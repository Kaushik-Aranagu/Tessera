import Foundation
@testable import TesseraCore
import Testing

/// R18, G196: Pantry state stays out of the shared export and in the full backup.
@MainActor
struct PantryExportTests {
    let store = ObjectStore.open(inMemory: true)

    /// The pantry fields exist after the catalog bump; until then a test adds them to the Ingredient class.
    func storeWithPantryState() throws -> (ObjectRecord, FieldDef) {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ingredientClass = try #require(classes[.ingredient])
        var stateField: FieldDef?
        for (name, key, kind) in [("State", "state", FieldKind.text), ("Bought", "lastBoughtAt", .date)] {
            let field = FieldDef(name: name, key: key, kind: kind)
            field.owner = ingredientClass
            store.context.insert(field)
            stateField = stateField ?? field
        }
        let recipe = try engine.perform(
            CreateRecipe(text: "Dal\nIngredients\n1 cup lentils\nMethod\n1. Cook."), by: .user
        ).output
        let lentils = try #require(RecipeBook(store: store, classes: classes).lines(of: recipe)
            .compactMap(\.ingredient).first)
        try store.set("state", to: .text("lowzzz"), on: lentils)
        try store.set("lastBoughtAt", to: .date(Date(timeIntervalSince1970: 1_792_000_000)), on: lentils)
        let backfill = try OpRecord(action: PantryFields.backfillAction, actor: .system, summary: "Pantry filled in",
                                    ops: [.setValue(object: lentils.id, field: #require(stateField).id, old: nil,
                                                    new: .text("lowzzz"))], state: .committed)
        store.context.insert(backfill)
        return try (lentils, #require(stateField))
    }

    @Test func theSharedExportHoldsNoPantryState() throws {
        let (lentils, _) = try storeWithPantryState()
        let shared = try TesseraExport(context: store.context, maskingPrivate: true)
        let json = try String(decoding: shared.encoded(), as: UTF8.self)
        #expect(!json.contains("lowzzz"), "the state value leaked")
        #expect(!shared.operations.contains { $0.action == PantryFields.backfillAction })
        #expect(json.contains("Lentils"), "the ingredient itself stays")
        // The full copy keeps everything.
        let whole = try String(decoding: TesseraExport(context: store.context, maskingPrivate: false).encoded(),
                               as: UTF8.self)
        #expect(whole.contains("lowzzz"))
        #expect(lentils.title == "Lentils")
    }

    @Test func aProcessStateFieldIsNotPantryState() throws {
        // "state" is also a Process field: only the Ingredient class's pantry fields are left out.
        _ = try storeWithPantryState()
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateList(name: "Packing"), by: .user)
        try engine.perform(StartListRun(list: #require(engine.store.context.all(ObjectRecord.self)
                .first { $0.title == "Packing" }?.id)), by: .user)
        let json = try String(decoding: TesseraExport(context: store.context, maskingPrivate: true).encoded(),
                              as: UTF8.self)
        #expect(json.contains("running"), "a process keeps its state")
    }
}

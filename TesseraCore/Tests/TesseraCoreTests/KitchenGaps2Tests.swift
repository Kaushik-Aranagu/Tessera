import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kitchen gap hunt 2 (docs/product/kitchen-gap-hunt-2.md): G1, G6 to G9 and G11.
@MainActor
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

}

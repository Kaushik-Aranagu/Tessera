import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct ListTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func listsAddCheckMoveAndClearWithUndo() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let lists = ListContents(store: store, classes: classes)

        let packing = try engine.perform(CreateList(name: "Packing"), by: .user).output
        #expect(lists.lists().map(\.title) == ["Groceries", "Packing"])
        let socks = try engine.perform(AddListItem(list: packing.id, text: "Socks", quantity: "5", section: "Clothes"),
                                       by: .user).output
        let charger = try engine.perform(AddListItem(list: packing.id, text: "Charger", section: "Tech"), by: .user)
            .output
        let shirt = try engine.perform(
            AddListItem(list: packing.id, text: "Shirt", section: "Clothes", about: [socks.id]),
            by: .user
        ).output
        #expect(lists.items(of: packing).map(\.text) == ["Socks", "Charger", "Shirt"])
        #expect(lists.items(of: packing).first?.quantity == "5")
        #expect(lists.sections(of: packing).map(\.name) == ["Clothes", "Tech"])
        #expect(lists.sections(of: packing).first?.items.map(\.text) == ["Socks", "Shirt"])
        #expect(store.linkedObjects("about", of: shirt).map(\.id) == [socks.id])

        // Reorder and re-section.
        try engine.perform(MoveListItem(item: shirt.id, index: 0), by: .user)
        #expect(lists.items(of: packing).map(\.text) == ["Shirt", "Socks", "Charger"])
        try engine.perform(MoveListItem(item: charger.id, section: "Bag"), by: .user)
        try engine.perform(RenameListSection(list: packing.id, from: "Clothes", to: "Wear"), by: .user)
        #expect(lists.sections(of: packing).map(\.name) == ["Wear", "Bag"])

        // Checked items stay until cleared; clearing undoes.
        try engine.perform(CheckListItem(item: socks.id), by: .user)
        #expect(lists.done(in: packing).map(\.text) == ["Socks"])
        #expect(lists.items(of: packing).count == 3)
        let clear = try engine.perform(ClearDoneItems(list: packing.id), by: .user)
        #expect(clear.output == 1)
        #expect(lists.items(of: packing).map(\.text) == ["Shirt", "Charger"])
        engine.undo(clear.record)
        #expect(lists.items(of: packing).count == 3)
        try engine.perform(CheckListItem(item: socks.id, done: false), by: .user)
        #expect(lists.open(in: packing).count == 3)
        #expect(lists.item(socks).checkedAt == nil)

        #expect(throws: ActionError.self) { try engine.perform(AddListItem(list: packing.id, text: " "), by: .user) }
    }
}

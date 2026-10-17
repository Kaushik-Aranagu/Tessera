@testable import Tessera
import TesseraCore
import Testing

/// 13.6: a removed row goes, and UNDO puts it back in the same place with its check as it was.
@MainActor
struct ListsRemoveTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func undoPutsTheRowBackInPlace() throws {
        let list = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        for thing in ["socks", "rice", "charger"] {
            try model.engine.perform(AddListItem(list: list.id, text: thing), by: .user)
        }
        let contents = ListContents(store: model.store, classes: model.classes)
        let rice = try #require(contents.open(in: list).first { $0.text == "rice" })
        let gone = try model.engine.perform(DeleteObject(object: rice.id), by: .user).record
        #expect(contents.open(in: list).map(\.text) == ["socks", "charger"])
        _ = model.engine.undo(gone)
        #expect(contents.open(in: list).map(\.text) == ["socks", "rice", "charger"])
    }

    @Test func undoKeepsADoneRowDone() throws {
        let list = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        try model.engine.perform(AddListItem(list: list.id, text: "socks"), by: .user)
        let contents = ListContents(store: model.store, classes: model.classes)
        let socks = try #require(contents.open(in: list).first)
        try model.engine.perform(CheckListItem(item: socks.id), by: .user)
        let gone = try model.engine.perform(DeleteObject(object: socks.id), by: .user).record
        #expect(contents.done(in: list).isEmpty)
        _ = model.engine.undo(gone)
        #expect(contents.done(in: list).map(\.id) == [socks.id])
    }
}

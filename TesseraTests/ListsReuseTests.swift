@testable import Tessera
import TesseraCore
import Testing

/// 10.4 and 10.5 through Core's K88 actions: a list made reusable resets its done items back, in order.
@MainActor
struct ListsReuseTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aReusableListResetsAndUndoChecksThemAgain() throws {
        let list = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        for thing in ["socks", "charger"] {
            try model.engine.perform(AddListItem(list: list.id, text: thing), by: .user)
        }
        let contents = ListContents(store: model.store, classes: model.classes)
        try model.engine.perform(SetListReusable(list: list.id), by: .user)
        #expect(contents.isReusable(list))
        for item in contents.open(in: list) {
            try model.engine.perform(CheckListItem(item: item.id), by: .user)
        }
        let reset = try model.engine.perform(ResetList(list: list.id), by: .user).record
        #expect(contents.open(in: list).map(\.text) == ["socks", "charger"] && contents.done(in: list).isEmpty)
        _ = model.engine.undo(reset)
        #expect(contents.done(in: list).count == 2)
    }
}

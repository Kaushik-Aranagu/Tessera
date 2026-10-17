import Foundation
@testable import TesseraCore
import Testing

/// K88, ship list slice 4: reusable lists and Reset (docs/product/lists-acceptance.md section 4,
/// lists-screens-acceptance
/// 10.11, Product decisions 7:17 PM Oct 15: "done" on a reusable list asks, a hold resets, "reset gym bag" at once).
@MainActor
struct ListReuseTests {
    let store = ObjectStore.open(inMemory: true)
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func setUp() throws -> (engine: ActionEngine, lists: ListContents, bag: ObjectRecord, items: [ObjectRecord]) {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let bag = try engine.perform(CreateList(name: "Gym bag"), by: .user).output
        var items: [ObjectRecord] = []
        for text in ["Towel", "Belt", "Chalk", "Bottle"] {
            try items.append(engine.perform(AddListItem(list: bag.id, text: text), by: .user).output)
        }
        return (engine, ListContents(store: store, classes: classes), bag, items)
    }

    func check(_ items: [ObjectRecord], _ count: Int, engine: ActionEngine) throws {
        for (offset, item) in items.prefix(count).enumerated() {
            try engine.perform(CheckListItem(item: item.id, time: start + Double(offset)), by: .user)
        }
    }

    @Test func theFlagIsOffByDefault() throws {
        let (_, lists, bag, _) = try setUp()
        #expect(!lists.isReusable(bag))
    }

    @Test func turningReusableOnAndOffIsUndoable() throws {
        let (engine, lists, bag, _) = try setUp()
        let turnedOn = try engine.perform(SetListReusable(list: bag.id), by: .user)
        #expect(lists.isReusable(bag))
        #expect(turnedOn.record.receipt == "Gym bag, reusable")
        #expect(turnedOn.record.summary == "Made Gym bag reusable")
        engine.undo(turnedOn.record)
        #expect(!lists.isReusable(bag))
        engine.redo(turnedOn.record)
        #expect(lists.isReusable(bag))
        let turnedOff = try engine.perform(SetListReusable(list: bag.id, reusable: false), by: .user)
        #expect(!lists.isReusable(bag))
        #expect(turnedOff.record.receipt == "Gym bag, not reusable")
        engine.undo(turnedOff.record)
        #expect(lists.isReusable(bag))
    }

    @Test func theFlagLeavesAListsOtherNotesAlone() throws {
        let (engine, lists, bag, _) = try setUp()
        try store.set("notes", to: .richText("Monday, Wednesday, Friday"), on: bag)
        try engine.perform(SetListReusable(list: bag.id), by: .user)
        #expect(lists.isReusable(bag))
        #expect(store.value("notes", of: bag)?.stringValue?.hasPrefix("Monday, Wednesday, Friday") == true)
        try engine.perform(SetListReusable(list: bag.id, reusable: false), by: .user)
        #expect(store.value("notes", of: bag)?.stringValue == "Monday, Wednesday, Friday")
    }

    @Test func groceriesCannotBeReusableAndNothingIsWritten() throws {
        let (engine, _, _, _) = try setUp()
        let before = engine.history(limit: 500).count
        #expect(throws: ActionError.self) {
            try engine.perform(SetListReusable(list: Groceries.listID), by: .user)
        }
        #expect(engine.history(limit: 500).count == before)
    }

    @Test func turningOnWhatIsAlreadyOnWritesNothing() throws {
        let (engine, _, bag, _) = try setUp()
        try engine.perform(SetListReusable(list: bag.id), by: .user)
        let before = engine.history(limit: 500).count
        #expect(throws: ActionError.self) { try engine.perform(SetListReusable(list: bag.id), by: .user) }
        #expect(throws: ActionError.self) {
            try engine.perform(SetListReusable(list: bag.id, reusable: false), by: .user)
            try engine.perform(SetListReusable(list: bag.id, reusable: false), by: .user)
        }
        #expect(engine.history(limit: 500).count == before + 1)
    }

    @Test func resetUnchecksEverythingAndKeepsEveryItemInOrder() throws {
        let (engine, lists, bag, items) = try setUp()
        try engine.perform(SetListReusable(list: bag.id), by: .user)
        try check(items, 3, engine: engine)
        let reset = try engine.perform(ResetList(list: bag.id), by: .user)
        #expect(reset.output == 3)
        #expect(lists.items(of: bag).map(\.text) == ["Towel", "Belt", "Chalk", "Bottle"])
        #expect(lists.items(of: bag).allSatisfy { !$0.isDone && $0.checkedAt == nil && !$0.object.isDeleted })
        #expect(lists.open(in: bag).count == 4)
        #expect(reset.record.receipt == "Gym bag, reset")
        #expect(reset.record.summary == "Reset Gym bag")
    }

    @Test func resetIsOneActionAndOneUndoBringsBackTheChecks() throws {
        let (engine, lists, bag, items) = try setUp()
        try check(items, 3, engine: engine)
        let before = engine.history(limit: 500).count
        let reset = try engine.perform(ResetList(list: bag.id), by: .user)
        #expect(engine.history(limit: 500).count == before + 1)
        #expect(engine.undo(reset.record) == .applied)
        let done = lists.done(in: bag)
        #expect(done.map(\.text) == ["Chalk", "Belt", "Towel"])
        #expect(done.map(\.checkedAt) == [start + 2, start + 1, start])
        engine.redo(reset.record)
        #expect(lists.done(in: bag).isEmpty)
    }

    @Test func resetWorksOnAListThatIsNotReusable() throws {
        let (engine, lists, bag, items) = try setUp()
        try check(items, 2, engine: engine)
        try engine.perform(ResetList(list: bag.id), by: .user)
        #expect(lists.open(in: bag).count == 4)
    }

    @Test func resetWithNothingCheckedWritesNothing() throws {
        let (engine, _, bag, _) = try setUp()
        let before = engine.history(limit: 500).count
        #expect(throws: ActionError.self) { try engine.perform(ResetList(list: bag.id), by: .user) }
        #expect(engine.history(limit: 500).count == before)
    }

    @Test func resetOnlyTouchesItsOwnList() throws {
        let (engine, lists, bag, items) = try setUp()
        let other = try engine.perform(CreateList(name: "Packing"), by: .user).output
        let socks = try engine.perform(AddListItem(list: other.id, text: "Socks"), by: .user).output
        try engine.perform(CheckListItem(item: socks.id, time: start), by: .user)
        try check(items, 2, engine: engine)
        try engine.perform(ResetList(list: bag.id), by: .user)
        #expect(lists.done(in: other).map(\.text) == ["Socks"])
    }

    @Test func clearDoneOnAReusableListUnchecksInsteadOfDeleting() throws {
        let (engine, lists, bag, items) = try setUp()
        try engine.perform(SetListReusable(list: bag.id), by: .user)
        try check(items, 2, engine: engine)
        let clear = try engine.perform(ClearDoneItems(list: bag.id), by: .user)
        #expect(clear.output == 2)
        #expect(lists.items(of: bag).count == 4)
        #expect(lists.open(in: bag).count == 4)
        #expect(clear.record.receipt == "Gym bag, reset")
        engine.undo(clear.record)
        #expect(lists.done(in: bag).count == 2)
    }

    @Test func clearDoneOnAPlainListStillDeletes() throws {
        let (engine, lists, bag, items) = try setUp()
        try check(items, 2, engine: engine)
        let clear = try engine.perform(ClearDoneItems(list: bag.id), by: .user)
        #expect(lists.items(of: bag).count == 2)
        #expect(clear.record.receipt == "Gym bag, done items cleared")
    }

    @Test func aPrivateItemsWordsNeverReachAResetLine() throws {
        let (engine, _, bag, _) = try setUp()
        let pill = try engine.perform(AddListItem(list: bag.id, text: "lexapro"), by: .user).output
        try engine.perform(CheckListItem(item: pill.id, time: start), by: .user)
        let reset = try engine.perform(ResetList(list: bag.id), by: .user)
        #expect(!(reset.record.receipt ?? "").lowercased().contains("lexapro"))
        #expect(!reset.record.summary.lowercased().contains("lexapro"))
    }

    @Test func resetOnGroceriesKeepsTheShopLineCurrent() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["milk", "eggs", "rice"]), by: .user)
        try engine.perform(StartShop(time: start), by: .user)
        let groceries = Groceries(store: store, classes: classes)
        let milk = try #require(groceries.shoppingOrder().first)
        try engine.perform(CheckListItem(item: milk.id, time: start + 60), by: .user)
        #expect(ProcessTable(engine: engine).running()?.nextStep == "Shopping, 2 left")
        try engine.perform(ResetList(list: Groceries.listID, time: start + 120), by: .user)
        #expect(ProcessTable(engine: engine).running()?.nextStep == "Shopping, 3 left")
    }

    @Test func theActionsDecodeFromAToolCall() throws {
        let (engine, lists, bag, items) = try setUp()
        try engine.perform(
            named: "setListReusable",
            arguments: Data(#"{"list":"\#(bag.id.uuidString)"}"#.utf8),
            by: .user
        )
        #expect(lists.isReusable(bag))
        try check(items, 1, engine: engine)
        try engine.perform(named: "resetList", arguments: Data(#"{"list":"\#(bag.id.uuidString)"}"#.utf8), by: .user)
        #expect(lists.done(in: bag).isEmpty)
    }
}

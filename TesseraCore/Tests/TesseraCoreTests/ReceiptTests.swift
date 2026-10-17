import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research receipts-thing-first RC23 to RC32 (board 0p, decisions 12:35 PM PT Oct 16): when the model's own line
/// can't be used, Tess says the thing first; the verb-first summary stays log text.
@MainActor
struct ReceiptTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test func listsSayTheThingFirst() throws {
        let made = try engine.perform(CreateList(name: "Packing"), by: .tess)
        #expect(made.record.receipt == "Packing, made" && made.record.summary == "New list: Packing")
        let list = made.output
        let added = try engine.perform(AddListItem(list: list.id, text: "charger", section: "Cables"), by: .tess)
        #expect(added.record.receipt == "Charger, added to Packing")
        let item = added.output
        #expect(try engine.perform(CheckListItem(item: item.id), by: .tess).record.receipt == "Charger, got")
        #expect(try engine.perform(CheckListItem(item: item.id, done: false), by: .tess).record.receipt
            == "Charger, back on Packing")
        #expect(try engine.perform(MoveListItem(item: item.id, section: "Tech"), by: .tess).record.receipt
            == "Charger, moved to Tech")
        #expect(try engine.perform(RenameListSection(list: list.id, from: "Tech", to: "Cables"), by: .tess).record
            .receipt == "Tech, now Cables")
        #expect(try engine.perform(ClearDoneItems(list: list.id), by: .tess).record.receipt
            == "Packing, done items cleared")
    }

    @Test func tasksAndGroceriesSayTheThingFirst() throws {
        let task = try engine.perform(CreateTask(title: "Call mom"), by: .tess).output
        #expect(try engine.perform(MoveTask(task: task.id, later: true), by: .tess).record.receipt
            == "Call mom, in Later")
        #expect(try engine.perform(SetTaskDone(task: task.id), by: .tess).record.receipt == "Call mom, done")
        #expect(try engine.perform(SetTaskDone(task: task.id, done: false), by: .tess).record.receipt
            == "Call mom, open again")
        #expect(try engine.perform(AddGroceries(lines: ["milk"]), by: .tess).record.receipt == "Milk, on Groceries")
        #expect(try engine.perform(AddGroceries(lines: ["oat milk", "eggs"]), by: .tess).record.receipt
            == "Oat milk and eggs, on Groceries")
        #expect(try engine.perform(AddGroceries(lines: ["milk", "eggs", "rice"]), by: .tess).record.receipt
            == "Milk, eggs and 1 more, on Groceries")
    }

    @Test func aMovedTaskSaysWhen() throws {
        let task = try engine.perform(CreateTask(title: "Call mom"), by: .tess).output
        let now = Date.now
        let tomorrow = try #require(Calendar.current.date(bySettingHour: 18, minute: 30, second: 0,
                                                          of: TesseraDay(calendar: .current).adding(days: 1, to: now)))
        let receipt = try engine.perform(MoveTask(task: task.id, to: tomorrow, time: now), by: .tess).record.receipt
        #expect(receipt == "Call mom, tomorrow 6:30 pm", "\(receipt ?? "nil")")
        // Further than a week out: the date.
        let later = try #require(Calendar.current.date(byAdding: .day, value: 12, to: tomorrow))
        let far = try engine.perform(MoveTask(task: task.id, to: later, time: now), by: .tess).record.receipt
        let date = later.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "en_US")))
        #expect(far == "Call mom, \(date) 6:30 pm", "\(far ?? "nil")")
    }
}

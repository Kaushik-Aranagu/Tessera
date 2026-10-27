import Foundation
@testable import TesseraCore
import Testing

/// K88, put away: a list run set aside to Later, shown with its basket count (lists-screens G9 and 10.11, the shop's
/// put-away note "Shopping moved to Later. 12 in the basket.", decisions Oct 15 7:17 PM: "put away" everywhere).
@MainActor
struct ListPutAwayTests {
    let store = ObjectStore.open(inMemory: true)
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    struct Fixture {
        let engine: ActionEngine
        let lists: ListContents
        let table: ProcessTable
        let trip: ObjectRecord
        let items: [ObjectRecord]
    }

    func setUp(name: String = "Packing, Lisbon", texts: [String] = ["Socks", "Charger", "Passport", "Adapter"]) throws
        -> Fixture
    {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let list = try engine.perform(CreateList(name: name), by: .user).output
        var items: [ObjectRecord] = []
        for text in texts {
            try items.append(engine.perform(AddListItem(list: list.id, text: text), by: .user).output)
        }
        return Fixture(engine: engine, lists: ListContents(store: store, classes: classes),
                       table: ProcessTable(engine: engine), trip: list, items: items)
    }

    func check(_ fixture: Fixture, _ count: Int) throws {
        for (offset, item) in fixture.items.prefix(count).enumerated() {
            try fixture.engine.perform(CheckListItem(item: item.id, time: start + Double(offset)), by: .user)
        }
    }

    // MARK: The action

    @Test func puttingARunAwayKeepsTheBasketAndShowsItsCount() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 3)
        let away = try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 600), by: .user)
        #expect(away.output == 3)
        #expect(away.record.receipt == "Packing, Lisbon put away. 3 in the basket")
        #expect(away.record.summary == "Put Packing, Lisbon away")
        #expect(fixture.table.running() == nil)
        #expect(fixture.table.later().map { $0.subject?.id } == [fixture.trip.id])
        let rows = fixture.lists.items(of: fixture.trip)
        #expect(rows.count == 4 && rows.filter(\.isDone).count == 3 && rows.allSatisfy { !$0.object.isDeleted })
        #expect(rows.compactMap(\.checkedAt).count == 3)
    }

    @Test func anEmptyBasketIsNotCounted() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        let away = try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(away.output == 0)
        #expect(away.record.receipt == "Packing, Lisbon put away")
    }

    @Test func aRunWaitingInTheLedgerCanBePutAway() throws {
        let fixture = try setUp()
        let other = try fixture.engine.perform(CreateList(name: "Gym bag"), by: .user).output
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try fixture.engine.perform(StartListRun(list: other.id, time: start + 10), by: .user)
        try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 20), by: .user)
        #expect(fixture.table.running()?.subject?.id == other.id)
        #expect(fixture.table.later().count == 1)
    }

    @Test func oneUndoPutsTheRunBackWhereItWas() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 2)
        let away = try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(fixture.engine.undo(away.record) == .applied)
        let running = try #require(fixture.table.running())
        #expect(running.subject?.id == fixture.trip.id)
        #expect(fixture.table.later().isEmpty)
        #expect(fixture.lists.putAway().isEmpty)
        #expect(running.nextStep == "Packing, Lisbon, 2 left")
        #expect(fixture.lists.done(in: fixture.trip).count == 2)
    }

    @Test func undoingFromTheLedgerLeavesItSuspendedNotRunning() throws {
        let fixture = try setUp()
        let other = try fixture.engine.perform(CreateList(name: "Gym bag"), by: .user).output
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try fixture.engine.perform(StartListRun(list: other.id, time: start + 10), by: .user)
        let away = try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 20), by: .user)
        fixture.engine.undo(away.record)
        #expect(fixture.table.running()?.subject?.id == other.id)
        #expect(fixture.table.all().first { $0.subject?.id == fixture.trip.id }?.state == .suspended)
    }

    @Test func aListThatIsNotRunningCannotBePutAwayAndNothingIsWritten() throws {
        let fixture = try setUp()
        let before = fixture.engine.history(limit: 500).count
        #expect(throws: ActionError.invalidArguments(
            action: "putAwayListRun",
            reason: "Packing, Lisbon isn't running"
        )) {
            try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id), by: .user)
        }
        #expect(throws: ActionError.self) {
            try fixture.engine.perform(PutAwayListRun(list: Groceries.listID), by: .user)
        }
        #expect(fixture.engine.history(limit: 500).count == before)
    }

    // MARK: The shelf and coming back

    @Test func aPutAwayListLeavesTheShelfAndWaitsInPutAway() throws {
        let fixture = try setUp()
        #expect(fixture.lists.putAway().isEmpty)
        #expect(fixture.lists.shelf().map(\.title) == ["Groceries", "Packing, Lisbon"])
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(fixture.lists.putAway().map(\.title) == ["Packing, Lisbon"])
        #expect(fixture.lists.shelf().map(\.title) == ["Groceries"])
        #expect(fixture.lists.lists().count == 2)
    }

    @Test func runningAPutAwayListBringsTheSameRunBackWithItsItems() throws {
        let fixture = try setUp()
        let first = try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user).output
        try check(fixture, 2)
        try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 60), by: .user)
        let back = try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start + 120), by: .user)
        #expect(back.output.id == first.id)
        let running = try #require(fixture.table.running())
        #expect(running.id == first.id && running.nextStep == "Packing, Lisbon, 2 left")
        #expect(fixture.table.later().isEmpty && fixture.lists.putAway().isEmpty)
        #expect(fixture.table.all().count == 1)
        fixture.engine.undo(back.record)
        #expect(fixture.lists.putAway().map(\.id) == [fixture.trip.id])
    }

    @Test func putAwayListsComeNewestFirstAndNeverIncludeGroceries() throws {
        let fixture = try setUp()
        let other = try fixture.engine.perform(CreateList(name: "Films"), by: .user).output
        try fixture.engine.perform(AddListItem(list: other.id, text: "Heat"), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 10), by: .user)
        try fixture.engine.perform(StartListRun(list: other.id, time: start + 20), by: .user)
        try fixture.engine.perform(PutAwayListRun(list: other.id, time: start + 30), by: .user)
        try fixture.engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        try fixture.engine.perform(StartShop(time: start + 40), by: .user)
        _ = fixture.table.suspendIfIdle(now: start + 40 + ProcessTable.Limits.idleShop + 60, idleLimit: 60)
        _ = fixture.table.tidyNotes(now: start + 40 + ProcessTable.Limits.putAway + 60)
        #expect(fixture.lists.putAway().map(\.title) == ["Films", "Packing, Lisbon"])
    }

    // MARK: Finishing a trip list (G9)

    @Test func finishingAPlainListWithNothingOpenPutsItAwayWhole() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 4)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(finished.output == FinishListRun.Outcome(cleared: 0, left: 0, wasReusable: false, putAway: true))
        #expect(finished.record.receipt == "Packing, Lisbon put away")
        #expect(finished.record.summary == "Put Packing, Lisbon away")
        #expect(fixture.lists.putAway().map(\.id) == [fixture.trip.id])
        #expect(fixture.lists.done(in: fixture.trip).count == 4)
        #expect(fixture.table.running() == nil)
    }

    @Test func undoingAFinishedTripBringsTheRunAndTheListBack() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 4)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.trip.id, time: start + 60), by: .user)
        fixture.engine.undo(finished.record)
        #expect(fixture.lists.putAway().isEmpty)
        #expect(fixture.lists.shelf().map(\.title).contains("Packing, Lisbon"))
        #expect(fixture.table.running()?.subject?.id == fixture.trip.id)
    }

    @Test func finishingWithItemsOpenKeepsTheListOnTheShelf() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 3)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(!finished.output.putAway)
        #expect(finished.record.receipt == "Packing, Lisbon, done. 1 left")
        #expect(fixture.lists.putAway().isEmpty)
    }

    @Test func aReusableListIsNeverPutAwayByFinishing() throws {
        let fixture = try setUp(name: "Gym bag", texts: ["Towel", "Belt"])
        try fixture.engine.perform(SetListReusable(list: fixture.trip.id), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 2)
        try fixture.engine.perform(FinishListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(fixture.lists.putAway().isEmpty)
        #expect(fixture.lists.shelf().map(\.title).contains("Gym bag"))
    }

    @Test func anEmptyListIsNotPutAwayByFinishing() throws {
        let fixture = try setUp(texts: [])
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(!finished.output.putAway)
        #expect(finished.record.receipt == "Packing, Lisbon, done")
    }

    // MARK: The put-away note (idle rule)

    @Test func aRunLeftSevenDaysIsPutAwayWithItsBasketCounted() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 3)
        _ = fixture.table.suspendIfIdle(now: start + 3 + ProcessTable.Limits.idleShop + 60, idleLimit: 60)
        let notes = fixture.table.tidyNotes(now: start + 3 + ProcessTable.Limits.putAway + 60)
        #expect(notes.map(\.line) == ["Packing, Lisbon moved to Later. 3 in the basket"])
        #expect(notes.first?.undo == nil)
        #expect(fixture.lists.putAway().map(\.id) == [fixture.trip.id])
        let rows = fixture.lists.items(of: fixture.trip)
        #expect(rows.filter(\.isDone).count == 3 && rows.allSatisfy { !$0.object.isDeleted })
    }

    @Test func anIdleRunWithNothingCheckedKeepsTheGenericNote() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        _ = fixture.table.suspendIfIdle(now: start + ProcessTable.Limits.idleShop + 60, idleLimit: 60)
        let notes = fixture.table.tidyNotes(now: start + ProcessTable.Limits.putAway + 60)
        #expect(notes.map(\.line) == ["One thing moved to Later"])
    }

    @Test func aShopAndARunPutAwayTogetherGetTheirOwnLines() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 2)
        try fixture.engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        try fixture.engine.perform(StartShop(time: start + 100), by: .user)
        for row in Groceries(store: store, classes: fixture.engine.classes).shoppingOrder() {
            try fixture.engine.perform(CheckListItem(item: row.id, time: start + 110), by: .user)
        }
        _ = fixture.table.suspendIfIdle(now: start + 110 + ProcessTable.Limits.idleShop + 60, idleLimit: 60)
        let lines = fixture.table.tidyNotes(now: start + 110 + ProcessTable.Limits.putAway + 60).map(\.line)
        #expect(Set(lines) == [
            "Packing, Lisbon moved to Later. 2 in the basket",
            "Shopping moved to Later. 2 in the basket",
        ])
    }

    // MARK: Words

    @Test func aPrivateItemsWordsNeverReachAPutAwayLine() throws {
        let fixture = try setUp(texts: ["Socks"])
        let pill = try fixture.engine.perform(AddListItem(list: fixture.trip.id, text: "lexapro"), by: .user).output
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try fixture.engine.perform(CheckListItem(item: pill.id, time: start + 5), by: .user)
        let away = try fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 60), by: .user)
        #expect(away.record.receipt == "Packing, Lisbon put away. 1 in the basket")
        _ = fixture.table.tidyNotes(now: start + ProcessTable.Limits.putAway + 600)
        let lines = [away.record.receipt, away.record.summary] + fixture.table.tidyNotes(now: start).map(\.line)
        for line in lines.compactMap(\.self) {
            #expect(!line.lowercased().contains("lexapro"), "\(line)")
        }
    }

    @Test func aWalledListNameReadsPrivateListInTheOvernightNote() throws {
        let fixture = try setUp(name: "Lexapro refill", texts: ["Pills"])
        try fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user)
        try check(fixture, 1)
        _ = fixture.table.suspendIfIdle(now: start + ProcessTable.Limits.idleShop + 60, idleLimit: 60)
        let notes = fixture.table.tidyNotes(now: start + ProcessTable.Limits.putAway + 60)
        #expect(notes.map(\.line) == ["Private list moved to Later. 1 in the basket"])
    }

    @Test func everyReceiptIsThingFirstAndNeverSaysAt() throws {
        let fixture = try setUp()
        let lines = try [
            fixture.engine.perform(StartListRun(list: fixture.trip.id, time: start), by: .user).record.receipt,
            fixture.engine.perform(PutAwayListRun(list: fixture.trip.id, time: start + 60), by: .user).record.receipt,
        ].compactMap(\.self)
        for line in lines {
            #expect(line.hasPrefix("Packing, Lisbon"), "\(line)")
            #expect(!line.contains(" at "), "\(line)")
        }
    }

    @Test func theActionDecodesFromAToolCall() throws {
        let fixture = try setUp()
        let id = fixture.trip.id.uuidString
        try fixture.engine.perform(named: "startListRun", arguments: Data(#"{"list":"\#(id)"}"#.utf8), by: .user)
        try fixture.engine.perform(named: "putAwayListRun", arguments: Data(#"{"list":"\#(id)"}"#.utf8), by: .user)
        #expect(fixture.lists.putAway().map(\.id) == [fixture.trip.id])
    }
}

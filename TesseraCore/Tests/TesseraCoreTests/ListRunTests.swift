import Foundation
@testable import TesseraCore
import Testing

/// K88, ship list slice 5: run a list on Now (docs/product/lists-acceptance.md section 5, lists-screens 10.7 and 10.11,
/// decisions Oct 16 12:38 PM). The shop's pattern: StartProcess, the ledger, `Limits.idleShop`.
@MainActor
struct ListRunTests {
    let store = ObjectStore.open(inMemory: true)
    let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let idle = ProcessTable.Limits.idleShop

    struct Fixture {
        let engine: ActionEngine
        let lists: ListContents
        let table: ProcessTable
        let packing: ObjectRecord
        let items: [ObjectRecord]
    }

    func setUp(name: String = "Packing", texts: [String] = ["Socks", "Charger", "Passport", "Adapter", "Shirt", "Book"])
        throws -> Fixture
    {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let list = try engine.perform(CreateList(name: name), by: .user).output
        var items: [ObjectRecord] = []
        for text in texts {
            try items.append(engine.perform(AddListItem(list: list.id, text: text), by: .user).output)
        }
        return Fixture(engine: engine, lists: ListContents(store: store, classes: classes),
                       table: ProcessTable(engine: engine), packing: list, items: items)
    }

    func check(_ fixture: Fixture, _ count: Int, at time: Date? = nil) throws {
        for (offset, item) in fixture.items.prefix(count).enumerated() {
            try fixture.engine.perform(CheckListItem(item: item.id, time: (time ?? start) + Double(offset)), by: .user)
        }
    }

    // MARK: Start

    @Test func startingARunMakesTheListTheRunningProcess() throws {
        let fixture = try setUp()
        let started = try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        let running = try #require(fixture.table.running())
        #expect(running.subject?.id == fixture.packing.id)
        #expect(running.nextStep == "Packing, 6 left")
        #expect(running.ownerApp == "Lists")
        #expect(started.output.id == running.id)
        #expect(started.record.receipt == "Packing, 6 left")
        #expect(started.record.summary == "Started Packing")
    }

    @Test func theLineDropsAsItemsAreChecked() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 2, at: start + 60)
        let running = try #require(fixture.table.running())
        #expect(running.nextStep == "Packing, 4 left")
        #expect(running.lastTouchedAt == start + 61)
        try check(fixture, 6, at: start + 120)
        #expect(fixture.table.running()?.nextStep == "Packing, nothing left")
    }

    @Test func addingAndUncheckingWhileRunningKeepsTheLineCurrent() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try fixture.engine.perform(AddListItem(list: fixture.packing.id, text: "Sunscreen"), by: .user)
        #expect(fixture.table.running()?.nextStep == "Packing, 7 left")
        try check(fixture, 1)
        try fixture.engine.perform(CheckListItem(item: fixture.items[0].id, done: false), by: .user)
        #expect(fixture.table.running()?.nextStep == "Packing, 7 left")
    }

    @Test func startingAnotherRunSuspendsTheFirstIntoTheLedger() throws {
        let fixture = try setUp()
        let house = try fixture.engine.perform(CreateList(name: "Leaving the house"), by: .user).output
        try fixture.engine.perform(AddListItem(list: house.id, text: "Keys"), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 2, at: start + 10)
        try fixture.engine.perform(StartListRun(list: house.id, time: start + 100), by: .user)
        #expect(fixture.table.running()?.nextStep == "Leaving the house, 1 left")
        let ledger = fixture.table.ledger(now: start + 200)
        #expect(ledger.map(\.nextStep) == ["Packing, 4 left"])
        #expect(ledger.first?.state == .suspended)
    }

    @Test func aShopAndAListRunTakeNowFromEachOther() throws {
        let fixture = try setUp()
        try fixture.engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try fixture.engine.perform(StartShop(time: start + 60), by: .user)
        #expect(fixture.table.running()?.nextStep == "Shopping, 1 left")
        #expect(fixture.table.ledger(now: start + 90).map(\.nextStep) == ["Packing, 6 left"])
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start + 120), by: .user)
        #expect(fixture.table.running()?.subject?.id == fixture.packing.id)
    }

    @Test func startingAgainResumesTheSameRunNeverASecond() throws {
        let fixture = try setUp()
        let first = try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user).output
        let house = try fixture.engine.perform(CreateList(name: "Gym bag"), by: .user).output
        try fixture.engine.perform(StartListRun(list: house.id, time: start + 10), by: .user)
        let again = try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start + 20), by: .user)
            .output
        #expect(again.id == first.id)
        #expect(fixture.table.running()?.id == first.id)
        #expect(fixture.table.all().count { $0.subject?.id == fixture.packing.id } == 1)
    }

    @Test func undoingAStartGivesNowBackToWhatWasRunning() throws {
        let fixture = try setUp()
        let house = try fixture.engine.perform(CreateList(name: "Gym bag"), by: .user).output
        try fixture.engine.perform(StartListRun(list: house.id, time: start), by: .user)
        let packing = try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start + 10), by: .user)
        fixture.engine.undo(packing.record)
        #expect(fixture.table.running()?.subject?.id == house.id)
        #expect(fixture.table.all().count { $0.subject?.id == fixture.packing.id && $0.state.isOpen } == 0)
    }

    @Test func groceriesAreRefusedAndNothingIsWritten() throws {
        let fixture = try setUp()
        let before = fixture.engine.history(limit: 500).count
        #expect(throws: ActionError.self) {
            try fixture.engine.perform(StartListRun(list: Groceries.listID), by: .user)
        }
        #expect(throws: ActionError.self) {
            try fixture.engine.perform(FinishListRun(list: Groceries.listID), by: .user)
        }
        #expect(fixture.engine.history(limit: 500).count == before)
        #expect(fixture.table.running() == nil)
    }

    @Test func aRunningWorkoutIsNeverSuspendedByARun() throws {
        let fixture = try setUp()
        let workout = try store.create(#require(fixture.engine.classes[.workout]), title: "Push")
        try fixture.engine.perform(StartProcess(subject: workout.id, time: start), by: .user)
        let before = fixture.engine.history(limit: 500).count
        #expect(throws: ActionError.invalidArguments(action: "startListRun", reason: "Workout running.")) {
            try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start + 5), by: .user)
        }
        #expect(fixture.engine.history(limit: 500).count == before)
        #expect(fixture.table.running()?.subject?.id == workout.id)
    }

    @Test func onlyAListCanRun() throws {
        let fixture = try setUp()
        #expect(throws: ActionError.self) {
            try fixture.engine.perform(StartListRun(list: fixture.items[0].id), by: .user)
        }
    }

    @Test func findsTheRunWhereverItWaits() throws {
        let fixture = try setUp()
        #expect(fixture.lists.run(of: fixture.packing, in: fixture.engine) == nil)
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        #expect(fixture.lists.run(of: fixture.packing, in: fixture.engine)?.state == .running)
        let other = try fixture.engine.perform(CreateList(name: "Gym bag"), by: .user).output
        try fixture.engine.perform(StartListRun(list: other.id, time: start + 10), by: .user)
        #expect(fixture.lists.run(of: fixture.packing, in: fixture.engine)?.state == .suspended)
    }

    // MARK: Finish

    @Test func finishingAPlainListClearsWhatWasCheckedAndEndsTheRun() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 3, at: start + 60)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.packing.id, time: start + 600), by: .user)
        #expect(finished.output == FinishListRun.Outcome(cleared: 3, left: 3, wasReusable: false, putAway: false))
        #expect(fixture.lists.items(of: fixture.packing).map(\.text) == ["Adapter", "Shirt", "Book"])
        #expect(fixture.table.running() == nil)
        let process = try #require(fixture.table.all().first)
        #expect(process.state == .done)
        #expect(store.value("endReason", of: process.object)?.stringValue == "done")
        #expect(finished.record.receipt == "Packing, done. 3 left")
        #expect(finished.record.summary == "Finished Packing")
    }

    @Test func finishingAReusableListWithNothingOpenSaysJustDone() throws {
        let fixture = try setUp(name: "Gym bag", texts: ["Towel", "Belt"])
        try fixture.engine.perform(SetListReusable(list: fixture.packing.id), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 2)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.packing.id, time: start + 60), by: .user)
        #expect(finished.record.receipt == "Gym bag, done")
        #expect(finished.output.left == 0 && !finished.output.putAway)
        #expect(fixture.lists.done(in: fixture.packing).count == 2)
    }

    @Test func finishingAReusableListKeepsEveryStrikeAndDoesNotReset() throws {
        let fixture = try setUp(name: "Gym bag", texts: ["Towel", "Belt", "Chalk", "Bottle"])
        try fixture.engine.perform(SetListReusable(list: fixture.packing.id), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 3)
        let before = fixture.engine.history(limit: 500).count
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.packing.id, time: start + 60), by: .user)
        #expect(fixture.engine.history(limit: 500).count == before + 1)
        #expect(finished.output == FinishListRun.Outcome(cleared: 0, left: 1, wasReusable: true, putAway: false))
        #expect(fixture.lists.done(in: fixture.packing).count == 3)
        #expect(fixture.lists.items(of: fixture.packing).count == 4)
        #expect(fixture.table.running() == nil)
        #expect(finished.record.receipt == "Gym bag, done. 1 left")
        #expect(fixture.engine.history(limit: 500).allSatisfy { $0.action != ResetList.descriptor.name })
    }

    @Test func finishingAListThatIsNotRunningWritesNothing() throws {
        let fixture = try setUp()
        let before = fixture.engine.history(limit: 500).count
        #expect(throws: ActionError.invalidArguments(action: "finishListRun", reason: "Packing isn't running")) {
            try fixture.engine.perform(FinishListRun(list: fixture.packing.id), by: .user)
        }
        #expect(fixture.engine.history(limit: 500).count == before)
    }

    @Test func oneUndoBringsBackTheClearedRowsAndTheRun() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 3)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.packing.id, time: start + 60), by: .user)
        #expect(fixture.engine.undo(finished.record) == .applied)
        let running = try #require(fixture.table.running())
        #expect(running.subject?.id == fixture.packing.id)
        #expect(running.state == .running)
        #expect(fixture.lists.done(in: fixture.packing).map(\.text) == ["Passport", "Charger", "Socks"])
        #expect(fixture.lists.done(in: fixture.packing).map(\.checkedAt) == [start + 2, start + 1, start])
        #expect(store.value("endedAt", of: running.object) == nil)
    }

    @Test func undoingAReusableFinishKeepsTheStrikesAndResumesTheRun() throws {
        let fixture = try setUp(name: "Gym bag", texts: ["Towel", "Belt"])
        try fixture.engine.perform(SetListReusable(list: fixture.packing.id), by: .user)
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 2)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.packing.id), by: .user)
        fixture.engine.undo(finished.record)
        #expect(fixture.table.running()?.subject?.id == fixture.packing.id)
        #expect(fixture.lists.done(in: fixture.packing).count == 2)
    }

    @Test func resettingWhileRunningBringsTheCountBack() throws {
        let fixture = try setUp(name: "Gym bag", texts: ["Towel", "Belt"])
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 2)
        #expect(fixture.table.running()?.nextStep == "Gym bag, nothing left")
        try fixture.engine.perform(ResetList(list: fixture.packing.id, time: start + 60), by: .user)
        #expect(fixture.table.running()?.nextStep == "Gym bag, 2 left")
    }

    // MARK: Idle (the shop's rule, G44)

    @Test func aRunUntouchedOvernightIsSuspendedAsTheSystemWithItsBasket() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try check(fixture, 3, at: start + 3600)
        let touched = start + 3600 + 2
        #expect(fixture.table.suspendIfIdle(now: touched + idle - 60, idleLimit: 60) == nil)
        let suspended = try #require(fixture.table.suspendIfIdle(now: touched + idle + 60, idleLimit: 60))
        #expect(fixture.table.running() == nil)
        let process = try #require(fixture.table.all().first { $0.id == suspended.id })
        #expect(process.state == .suspended)
        #expect(process.lastTouchedAt == touched)
        #expect(process.nextStep == "Packing, 3 left")
        let record = try #require(fixture.engine.history(limit: 5).first { $0.action == "suspendProcess" })
        #expect(record.actor == .system)
        #expect(fixture.lists.done(in: fixture.packing).count == 3)
    }

    @Test func checkingARowResetsTheRunsIdleClock() throws {
        let fixture = try setUp()
        try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        try fixture.engine.perform(CheckListItem(item: fixture.items[0].id, time: start + 11 * 3600), by: .user)
        #expect(fixture.table.suspendIfIdle(now: start + 13 * 3600, idleLimit: 60) == nil)
        #expect(fixture.table.running() != nil)
    }

    // MARK: Words

    @Test func aPrivateItemsWordsNeverReachARunLine() throws {
        let fixture = try setUp(texts: ["Socks"])
        let pill = try fixture.engine.perform(AddListItem(list: fixture.packing.id, text: "lexapro"), by: .user).output
        let started = try fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user)
        let checked = try fixture.engine.perform(CheckListItem(item: pill.id, time: start + 5), by: .user)
        let finished = try fixture.engine.perform(FinishListRun(list: fixture.packing.id, time: start + 60), by: .user)
        let spoken = [started.record.receipt, started.record.summary, checked.record.receipt, finished.record.receipt,
                      finished.record.summary, fixture.table.all().first?.nextStep]
        for line in spoken.compactMap(\.self) {
            #expect(!line.lowercased().contains("lexapro"), "\(line)")
        }
        #expect(checked.record.receipt == "Private item, got")
    }

    @Test func everyReceiptIsThingFirstAndNeverSaysAt() throws {
        let fixture = try setUp(name: "Gym bag", texts: ["Towel", "Belt"])
        let lines = try [
            fixture.engine.perform(StartListRun(list: fixture.packing.id, time: start), by: .user).record.receipt,
            fixture.engine.perform(FinishListRun(list: fixture.packing.id, time: start + 60), by: .user).record.receipt,
        ].compactMap(\.self)
        for line in lines {
            #expect(line.hasPrefix("Gym bag"), "\(line)")
            #expect(!line.contains(" at "), "\(line)")
        }
    }

    @Test func theActionsDecodeFromAToolCall() throws {
        let fixture = try setUp()
        let id = fixture.packing.id.uuidString
        try fixture.engine.perform(named: "startListRun", arguments: Data(#"{"list":"\#(id)"}"#.utf8), by: .user)
        #expect(fixture.table.running()?.subject?.id == fixture.packing.id)
        try fixture.engine.perform(named: "finishListRun", arguments: Data(#"{"list":"\#(id)"}"#.utf8), by: .user)
        #expect(fixture.table.running() == nil)
    }
}

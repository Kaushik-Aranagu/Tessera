import Foundation
@testable import TesseraCore
import Testing

/// Together round 9, 164 undoLogV2: one Undo for anything changed in the last 10 minutes, from the op log.
@MainActor
struct UndoLogTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test func theLatestChangeIsOfferedForTenMinutesAndPutBackWhole() throws {
        let task = try engine.perform(CreateTask(title: "Mail forms"), by: .user)
        let entry = try #require(UndoLog.latest(engine: engine, now: .now))
        #expect(entry.id == task.record.id && entry.isRecent && !entry.isMoney)
        #expect(UndoLog.latest(engine: engine, now: .now.addingTimeInterval(11 * 60)) == nil)
        #expect(UndoLog.recent(engine: engine, now: .now.addingTimeInterval(11 * 60)).first?.isRecent == false)
        #expect(UndoLog.undo(entry.id, engine: engine) == .putBack(line: "Put back"))
        #expect(task.output.isDeleted)
        #expect(UndoLog.undo(entry.id, engine: engine) == .gone)
        #expect(UndoLog.latest(engine: engine, now: .now) == nil)
    }

    @Test func theAppsOwnHousekeepingIsNeverOffered() throws {
        try engine.perform(CreateTask(title: "Roll"), by: .system)
        #expect(UndoLog.recent(engine: engine, now: .now).isEmpty)
    }

    @Test func aChangeThatNoLongerFitsIsLeftAloneNotHalfDone() throws {
        let task = try engine.perform(CreateTask(title: "Move me"), by: .user).output
        let early = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let first = try engine.perform(MoveTask(task: task.id, to: early), by: .user)
        try engine.perform(MoveTask(task: task.id, to: early.addingTimeInterval(86400)), by: .user)
        let before = store.value("due", of: task)
        #expect(UndoLog.undo(first.record.id, engine: engine) == .blocked(line: "Can't put that back"))
        #expect(first.record.state == .committed)
        #expect(store.value("due", of: task) == before)
    }

    @Test func aMoneyMoveReadsGenericallyAndIsFlagged() throws {
        let one = try engine.perform(CreatePool(name: "US checking", opening: "500"), by: .user).output
        let two = try engine.perform(CreatePool(name: "Savings", opening: "0"), by: .user).output
        let move = try engine.perform(LogMove(from: one.id, to: two.id, sent: "120", arrived: "120"), by: .user)
        let entry = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == move.record.id })
        #expect(entry.isMoney && entry.sentence == "Money moved")
        #expect(!entry.sentence.contains("120") && !entry.sentence.contains("checking"))
        #expect(UndoLog.undo(entry.id, engine: engine) == .putBack(line: "Put back"))
    }

    @Test func aPrivateThingReadsItsGenericSummaryNotItsWords() throws {
        let task = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user)
        let entry = try #require(UndoLog.latest(engine: engine, now: .now))
        #expect(entry.id == task.record.id && !entry.sentence.lowercased().contains("lexapro"))
    }

    @Test func undoNeverBringsBackAPurgedItem() throws {
        let task = try engine.perform(CreateTask(title: "Quiet thing"), by: .user).output
        let gone = try engine.perform(DeleteObject(object: task.id), by: .user)
        task.title = TessMemoryStore.redacted
        #expect(UndoLog.undo(gone.record.id, engine: engine) == .blocked(line: "Can't put that back"))
        #expect(task.isDeleted)
    }

    @Test func aRetitledThingStillReadsGenericFromItsOldReceipt() throws {
        let made = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user)
        try engine.perform(RenameObject(object: made.output.id, title: "Refill"), by: .user)
        let entry = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == made.record.id })
        #expect(!entry.sentence.lowercased().contains("lexapro"))
    }

    @Test func aMoneyOrBodyShapedReceiptReadsGeneric() throws {
        let made = try engine.perform(CreateTask(title: "Pay 1200 rent"), by: .user)
        let entry = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == made.record.id })
        #expect(!entry.sentence.contains("1200"))
        let body = try engine.perform(CreateNote(body: "weighed 82 kg this morning"), by: .user)
        let note = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == body.record.id })
        #expect(!note.sentence.contains("82"))
    }

    @Test func aMeProfileChangeReadsGeneric() throws {
        let me = try store.create(#require(engine.classes[.meProfile]), title: "Me")
        let record = OpRecord(
            action: "setMe",
            actor: .user,
            summary: "Updated you",
            ops: [.setTitle(object: me.id, old: "Me", new: "Me")],
            state: .committed
        )
        record.receipt = "Height 181 cm, saved"
        store.context.insert(record)
        let entry = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == record.id })
        #expect(entry.sentence == "Updated you" && !entry.sentence.contains("181"))
    }

    /// One batch of two ops: the stale one comes first, so undo (newest op first) puts the second back and only then
    /// meets the stale one. The second must be restored.
    @Test func aBatchWithOneStaleOpIsRolledBackWhole() throws {
        let one = try engine.perform(CreateTask(title: "First"), by: .user).output
        let two = try engine.perform(CreateTask(title: "Second"), by: .user).output
        let record = OpRecord(
            action: "batch", actor: .user, summary: "Renamed two things",
            ops: [.setTitle(object: one.id, old: "Before", new: "Not what it is now"),
                  .setTitle(object: two.id, old: "Before", new: "Second")],
            state: .committed
        )
        store.context.insert(record)
        #expect(UndoLog.undo(record.id, engine: engine) == .blocked(line: "Can't put that back"))
        #expect(one.title == "First" && two.title == "Second" && record.state == .committed)
    }

    @Test func aCalorieOrCalendarRecordReadsGeneric() throws {
        let made = try engine.perform(CreateNote(body: "Logged 600 calories at lunch"), by: .user)
        let entry = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == made.record.id })
        #expect(!entry.sentence.contains("600") && !entry.sentence.lowercased().contains("calor"))
        let sync = OpRecord(action: "syncCalendar", actor: .user, summary: "Calendar mirrored",
                            ops: [.setTitle(object: made.output.id, old: "x", new: "x")], state: .committed)
        sync.receipt = "Dentist at 3 pm"
        store.context.insert(sync)
        let line = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == sync.id })
        #expect(line.sentence == "Calendar mirrored")
    }
}

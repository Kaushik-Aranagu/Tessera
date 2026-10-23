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
        #expect(UndoLog.undo(entry.id, engine: engine) == .putBack(line: "Put back."))
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
        #expect(UndoLog.undo(first.record.id, engine: engine) == .blocked(line: "Can't put that back."))
        #expect(first.record.state == .committed)
        #expect(store.value("due", of: task) == before)
    }

    @Test func aMoneyMoveReadsGenericallyAndIsFlagged() throws {
        let one = try engine.perform(CreatePool(name: "US checking", opening: "500"), by: .user).output
        let two = try engine.perform(CreatePool(name: "Savings", opening: "0"), by: .user).output
        let move = try engine.perform(LogMove(from: one.id, to: two.id, sent: "120", arrived: "120"), by: .user)
        let entry = try #require(UndoLog.recent(engine: engine, now: .now).first { $0.id == move.record.id })
        #expect(entry.isMoney && entry.sentence == "Money moved.")
        #expect(!entry.sentence.contains("120") && !entry.sentence.contains("checking"))
        #expect(UndoLog.undo(entry.id, engine: engine) == .putBack(line: "Put back."))
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
        #expect(UndoLog.undo(gone.record.id, engine: engine) == .blocked(line: "Can't put that back."))
        #expect(task.isDeleted)
    }
}

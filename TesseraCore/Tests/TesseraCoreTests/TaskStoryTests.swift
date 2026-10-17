import Foundation
@testable import TesseraCore
import Testing

/// Core 0am: a task's story from the op log (drawn-sides-acceptance section 5, Q4 to Q6) and the grocery buy cadence
/// (SA-PER-13, SH26).
@MainActor
struct TaskStoryTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    /// Thursday 15 October 2026, 10:00 GMT.
    let now = Date(timeIntervalSince1970: 1_792_058_400)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { .gmt }
    }

    func at(_ days: Double, hour: Double = 0) -> Date {
        now.addingTimeInterval(days * 86400 + hour * 3600)
    }

    @discardableResult
    func stamp(_ record: OpRecord, _ date: Date) -> OpRecord {
        record.createdAt = date
        return record
    }

    /// "Call the plumber" (T1): made Tuesday 9:12, moved Wednesday and Thursday by hand, kept for 2 pm today.
    func plumber() throws -> ObjectRecord {
        let task = try engine.perform(CreateTask(title: "Call the plumber", startsAt: at(-2), minutes: 30), by: .user)
            .output
        task.createdAt = at(-2, hour: -0.8)
        return task
    }

    func move(_ task: ObjectRecord, to date: Date, by actor: Actor, at when: Date) throws {
        try stamp(
            engine.perform(MoveTask(task: task.id, to: date, time: when, calendar: calendar), by: actor).record,
            when
        )
    }

    @Test func keepIsItsOwnActionAndMovesLikeMoveTask() throws {
        #expect(ActionRegistry.descriptors.contains { $0.name == "keepPlannedTask" })
        let task = try plumber()
        let record = try engine.perform(KeepPlannedTask(task: task.id, to: at(0, hour: 4)), by: .user).record
        #expect(record.action == "keepPlannedTask")
        #expect(store.value("startsAt", of: task)?.dateValue == at(0, hour: 4))
        let decoded = try ActionRegistry.decode(
            name: "keepPlannedTask",
            arguments: Data(#"{"task":"\#(task.id)"}"#.utf8)
        )
        #expect(decoded is KeepPlannedTask)
    }

    @Test func taskStoryCountsHandMovesNotNightlyRolls() throws {
        // SA-STORY-1 and SA-STORY-3 (SH25).
        let task = try plumber()
        try move(task, to: at(-1), by: .user, at: at(-1, hour: 1))
        try move(task, to: at(0), by: .user, at: at(0, hour: -1))
        // Two nights rolled by itself (the system moved it back so each roll has something to carry).
        for night in 0 ..< 2 {
            try move(task, to: at(-3), by: .system, at: at(0, hour: -2 + Double(night) * 0.1))
            let roll = try engine.perform(RollForwardTasks(time: now), by: .system).record
            stamp(roll, at(0, hour: -1.9 + Double(night) * 0.1))
        }
        try stamp(
            engine.perform(KeepPlannedTask(task: task.id, to: at(0, hour: 4)), by: .user).record,
            at(0, hour: -0.5)
        )

        let story = TaskStory(of: task, engine: engine)
        #expect(story.moves == 2)
        #expect(story.rolls == 2)
        #expect(story.isInPlan)
        #expect(story.madeAt == task.createdAt)
        #expect(story.events.first == .made(task.createdAt))
        // Oldest first: made, moved, rolled..., planned last.
        if case .planned = story.events.last {} else {
            Issue.record("last should be the keep: \(story.events)")
        }
        #expect(story.events.dropFirst().first == .moved(to: at(-1), at: at(-1, hour: 1)))
    }

    @Test func aSecondKeepIsPlannedNotAMove() throws {
        // SA-STORY-4.
        let task = try plumber()
        try move(task, to: at(-1), by: .user, at: at(-1, hour: 1))
        try move(task, to: at(0), by: .user, at: at(0, hour: -1))
        try stamp(
            engine.perform(KeepPlannedTask(task: task.id, to: at(0, hour: 4)), by: .user).record,
            at(0, hour: -0.5)
        )
        // A second keep at another time (a keep that changes nothing writes no op, so it leaves no trace to count).
        try stamp(
            engine.perform(KeepPlannedTask(task: task.id, to: at(0, hour: 5)), by: .user).record,
            at(0, hour: -0.4)
        )
        let story = TaskStory(of: task, engine: engine)
        #expect(story.moves == 2)
        #expect(story.plannedCount == 2)
    }

    @Test func tessAndSiriMovesCountSystemNeverDoes() throws {
        // SA-STORY-5 (Q5).
        let task = try plumber()
        try move(task, to: at(-1), by: .user, at: at(-1, hour: 1))
        try move(task, to: at(0), by: .user, at: at(0, hour: -1))
        try move(task, to: at(1), by: .tess, at: at(0, hour: -0.5))
        try move(task, to: at(2), by: .intent, at: at(0, hour: -0.4))
        try move(task, to: at(3), by: .system, at: at(0, hour: -0.3))
        #expect(TaskStory(of: task, engine: engine).moves == 4)
    }

    @Test func undoneMovesAreNotInTheStory() throws {
        let task = try plumber()
        let record = try engine.perform(MoveTask(task: task.id, to: at(1), time: now, calendar: calendar), by: .user)
            .record
        #expect(TaskStory(of: task, engine: engine).moves == 1)
        engine.undo(record)
        #expect(TaskStory(of: task, engine: engine).moves == 0)
    }

    @Test func neverMovedTaskHasOnlyItsMakingAndNoPlan() throws {
        // SA-STORY-6 and SA-STORY-11.
        let task = try plumber()
        let story = TaskStory(of: task, engine: engine)
        #expect(story.moves == 0 && story.rolls == 0 && !story.isInPlan)
        #expect(story.events == [.made(task.createdAt)])
        #expect(story.doneAt == nil)
    }

    @Test func doneEndsTheStoryAndLeavesTheMoveCount() throws {
        // SA-STORY-12: done at 5:40 pm, still 2 moves.
        let task = try plumber()
        try move(task, to: at(-1), by: .user, at: at(-1, hour: 1))
        try move(task, to: at(0), by: .user, at: at(0, hour: -1))
        let done = at(0, hour: 7.67)
        try engine.perform(SetTaskDone(task: task.id, time: done), by: .user)
        let story = TaskStory(of: task, engine: engine)
        #expect(story.moves == 2)
        #expect(story.doneAt == done)
        #expect(story.events.last == .done(done))
    }

    @Test func laterShowsAsAMoveWithNoDate() throws {
        let task = try plumber()
        try stamp(engine.perform(MoveTask(task: task.id, later: true), by: .user).record, at(0, hour: -1))
        let story = TaskStory(of: task, engine: engine)
        #expect(story.moves == 1)
        #expect(story.events.last == .moved(to: nil, at: at(0, hour: -1)))
    }

    // MARK: Buy cadence

    /// Buys rice on each date: added, checked, and the shop's done rows cleared (so only the op log remembers).
    func buyRice(on dates: [Date], by actor: Actor = .user) throws {
        for date in dates {
            try engine.perform(AddGroceries(lines: ["rice"]), by: .user)
            let list = try #require(Groceries(store: store, classes: classes).list)
            let item = try #require(list.orderedChildren.first { $0.title == "rice" && !$0.isDeleted })
            try stamp(engine.perform(CheckListItem(item: item.id, time: date), by: actor).record, date)
            try engine.perform(ClearDoneItems(list: list.id), by: .user)
        }
    }

    func rice() throws -> ObjectRecord {
        try #require(IngredientBook(store: store, classes: classes).find("rice"))
    }

    func day(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 11))!
    }

    @Test func ingredientCadenceNeedsThreeBuys() throws {
        // SA-PER-13, SH26 (SL-I1, SL-I5): buys Sep 12, 21, 30 and Oct 9 give 9 days; two buys give nothing.
        try buyRice(on: [day(9, 12), day(9, 21)])
        let two = try BuyCadence(of: rice(), engine: engine, calendar: calendar)
        #expect(two.days.count == 2 && two.everyDays == nil && two.line == nil)

        try buyRice(on: [day(9, 30), day(10, 9)])
        let cadence = try BuyCadence(of: rice(), engine: engine, calendar: calendar)
        #expect(cadence.days.count == 4)
        #expect(cadence.everyDays == 9)
        #expect(cadence.line == "You buy it about every 9 days.")
    }

    @Test func cadenceIgnoresSystemChecksAndRounds() throws {
        try buyRice(on: [day(9, 12), day(9, 21), day(9, 30), day(10, 9)])
        // One more check by .system on the same ingredient never counts.
        try buyRice(on: [day(10, 20)], by: .system)
        #expect(try BuyCadence(of: rice(), engine: engine, calendar: calendar).days.count == 4)
        // Mean gap 10 days over 3 gaps of 9, 9, 12 is 10.
        try buyRice(on: [day(10, 21)])
        let cadence = try BuyCadence(of: rice(), engine: engine, calendar: calendar)
        #expect(cadence.everyDays == 10)
    }

    @Test func twoBuysOnOneDayAreOneBuy() throws {
        try buyRice(on: [day(9, 12), day(9, 12), day(9, 21), day(9, 30)])
        let cadence = try BuyCadence(of: rice(), engine: engine, calendar: calendar)
        #expect(cadence.days.count == 3 && cadence.everyDays == 9)
    }
}

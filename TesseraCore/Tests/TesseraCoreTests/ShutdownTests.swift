import Foundation
@testable import TesseraCore
import Testing

/// M4 slice 7: Shutdown's words (docs/research/shutdown-daylog-copy.md) and its close.
@MainActor
struct ShutdownTests {
    func inputs(tasks: Int = 0, workouts: Int = 0, cooks: Int = 0) -> ShutdownInputs {
        var inputs = ShutdownInputs()
        inputs.tasks = tasks
        inputs.workouts = workouts
        inputs.cooks = cooks
        inputs.attributedWeekday = "Thursday"
        inputs.nextWeekday = "Friday"
        return inputs
    }

    @Test func countsAreNonzeroInAppOrderAndCappedAtThree() {
        var many = inputs(tasks: 4, workouts: 1, cooks: 1)
        many.notes = 2
        #expect(ShutdownLines.counts(many) == "1 workout, cooked once, 4 tasks")
        #expect(ShutdownLines.counts(inputs(tasks: 1)) == "1 task")
        #expect(ShutdownLines.counts(inputs(cooks: 3)) == "cooked 3 times")
    }

    @Test func openerPicksTheFirstMatchingRow() {
        #expect(ShutdownLines.opener(inputs(tasks: 4, workouts: 1, cooks: 1)) == "Did 1 workout, cooked once, 4 tasks")
        var best = inputs(tasks: 3, workouts: 1)
        best.bestLift = "bench"
        #expect(ShutdownLines.opener(best) == "Did 1 workout, 3 tasks. Plus a best on bench")
        var lone = inputs(workouts: 1)
        lone.workoutName = "Pull day"
        #expect(ShutdownLines.opener(lone) == "Pull day, done. That counts")
        var busy = inputs(tasks: 12)
        busy.appsTouched = 1
        #expect(ShutdownLines.opener(busy) == "12 things done. Full day")
        var back = inputs(tasks: 2, workouts: 1)
        back.afterGap = true
        #expect(ShutdownLines.opener(back) == "Back in. Did 1 workout, 2 tasks today")
        var facts = inputs()
        facts.meetings = 3
        facts.sleep = "6h40"
        #expect(ShutdownLines.opener(facts) == "3 meetings, slept 6h40. That was the day")
        #expect(ShutdownLines.opener(inputs()) == "A quiet one. Want a line for tomorrow?")
        var late = inputs(tasks: 3, cooks: 1)
        late.lateNight = true
        #expect(ShutdownLines.opener(late) == "Filed under Thursday. Did cooked once, 3 tasks")
    }

    @Test func carryOverFollowsTheRollingCount() {
        var rolling = inputs()
        #expect(ShutdownLines.carryOver(rolling) == nil)
        rolling.rolling = ["Call the bank"]
        #expect(ShutdownLines.carryOver(rolling) == "Call the bank moves to tomorrow. Tap to keep it")
        rolling.rolling = ["Call the bank about the long form please"]
        #expect(ShutdownLines.carryOver(rolling) == "1 moving to tomorrow. Tap to keep it")
        rolling.rolling = ["a", "b", "c"]
        #expect(ShutdownLines.carryOver(rolling) == "3 moving to tomorrow. Tap any for later")
        rolling.rolling = ["a", "b", "c", "d", "e", "f", "g"]
        #expect(ShutdownLines.carryOver(rolling) == "7 rolling over. Plan my day picks up to 3")
        rolling.rolling = ["a", "b"]
        rolling.pastMidnight = true
        #expect(ShutdownLines.carryOver(rolling) == "2 moving to Friday. Tap any for later")
    }

    @Test func tomorrowPlaceholderAndCloseLines() {
        var day = inputs(tasks: 4)
        day.tomorrowFirstEvent = ("Standup", "9:30 am")
        #expect(ShutdownLines.tomorrowPlaceholder(day) == "Tomorrow starts with Standup at 9:30 am")
        #expect(ShutdownLines.tomorrowPlaceholder(inputs(tasks: 4)) == "One line for tomorrow, if you want")
        #expect(ShutdownLines.tomorrowPlaceholder(inputs()) == "") // B7 already offered it
        #expect(ShutdownLines.close(inputs(tasks: 5)) == "Closed. 5 things in Thursday's log")
        var wrote = inputs(tasks: 5)
        wrote.wroteTomorrowLine = true
        #expect(ShutdownLines.close(wrote) == "Closed. Your line is waiting at 8 am")
        #expect(ShutdownLines.close(inputs()) == "Day closed. Nothing waiting tonight")
        var late = inputs(workouts: 1)
        late.lateNight = true
        #expect(ShutdownLines.close(late) == "Closed. Sleep is also training")
        late.workouts = 0
        late.tasks = 2
        #expect(ShutdownLines.close(late) == "Saved to Thursday. Pick up tomorrow")
    }

    @Test func dayLogLineIsFrozenByRule() {
        var push = inputs(workouts: 1, cooks: 1)
        push.workoutName = "Push day"
        push.recipeName = "carbonara"
        #expect(ShutdownLines.dayLogLine(push) == "Push day and carbonara. Fed and trained")
        var pull = inputs(tasks: 3, workouts: 1)
        pull.workoutName = "Pull day"
        pull.sets = 16
        #expect(ShutdownLines.dayLogLine(pull) == "Pull day, 16 sets. 3 other things too")
        #expect(ShutdownLines.dayLogLine(inputs(tasks: 2)) == "Quiet day. 2 tasks")
        var rest = inputs()
        rest.sleep = "8h05"
        #expect(ShutdownLines.dayLogLine(rest) == "Rest day. Slept 8h05")
        #expect(ShutdownLines.dayLogLine(inputs(), todayOnlyBeforeShutdown: true) == "Fills itself as you go")
        #expect(ShutdownLines.dayLogLine(inputs()) == nil)
    }

    // MARK: The store

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func gatheringCountsTheDayAndWhatRolls() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let done = try engine.perform(CreateTask(title: "Send invoice", startsAt: at(22, 10)), by: .user).output
        try engine.perform(SetTaskDone(task: done.id, done: true, time: at(22, 11)), by: .user)
        try engine.perform(CreateTask(title: "Call the bank", startsAt: at(22, 15)), by: .user)
        let inputs = ShutdownDay(store: store, classes: engine.classes, calendar: calendar).inputs(at: at(22, 21))
        #expect(inputs.tasks == 1 && inputs.rolling == ["Call the bank"])
        #expect(inputs.attributedWeekday == "Thursday" && inputs.nextWeekday == "Friday" && !inputs.lateNight)
        let late = ShutdownDay(store: store, classes: engine.classes, calendar: calendar).inputs(at: at(23, 1))
        #expect(late.lateNight && late.pastMidnight && late.attributedWeekday == "Thursday")
    }

    @Test func closingMovesRowsWritesTheLineAndTheMarkAndUndoTakesItBack() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let keep = try engine.perform(CreateTask(title: "Reply to the landlord", startsAt: at(22, 15)), by: .user)
            .output
        let oven = try engine.perform(CreateTask(title: "Clean the oven", startsAt: at(22, 16)), by: .user).output
        let close = try engine.perform(
            CloseDay(tomorrow: [keep.id], later: [oven.id], line: "Pull A first", dayLine: "Quiet day. 2 tasks",
                     closedAt: at(22, 21, 6), calendar: calendar),
            by: .user
        )
        #expect(store.value("startsAt", of: oven) == nil)
        #expect(store.value("startsAt", of: keep)?.dateValue.map { calendar.component(.day, from: $0) } == 23)
        let taskClass = try #require(engine.classes[.task])
        let lineTask = try #require(store.objects(of: taskClass).first { $0.title == "Pull A first" })
        #expect(store.value("startsAt", of: lineTask)?.dateValue == at(23, 8))
        let shutdown = ShutdownDay(store: store, classes: engine.classes, calendar: calendar)
        let mark = try #require(shutdown.closedMark(for: at(22, 21, 30)))
        #expect(store.value("dayLine", of: mark)?.stringValue == "Quiet day. 2 tasks")
        #expect(store.value("silent", of: mark) == .bool(false))
        #expect(close.record.summary == "Shutdown complete")
        engine.undo(close.record)
        #expect(shutdown.closedMark(for: at(22, 21, 30)) == nil)
        #expect(store.value("startsAt", of: oven)?.dateValue == at(22, 16))
    }

    @Test func theSilentCloseIsMarkedAndCarriesNoLine() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try engine.perform(CloseDay(closedAt: at(22, 22), silent: true, calendar: calendar), by: .system)
        let mark = try #require(ShutdownDay(store: store, classes: engine.classes, calendar: calendar)
            .closedMark(for: at(22, 22, 30)))
        #expect(store.value("silent", of: mark) == .bool(true) && store.value("tomorrowLine", of: mark) == nil)
    }
}

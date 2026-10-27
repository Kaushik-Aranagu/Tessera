import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/research/day-boundary.md's running example: Friday 16 Oct 2026, Los Angeles. Push A 22:50 to Sat 00:40;
/// "Pay rent" Fri 23:00 (not done); "Dentist" Sat 15:00.
@MainActor
struct DayBoundaryTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let calendar = TesseraDayTests.calendar

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        TesseraDayTests.at(month, day, hour, minute)
    }

    @Test func x2ASessionAcrossMidnightIsFridays() throws {
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: push.id, time: at(10, 16, 22, 50)), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: at(10, 17, 0, 40)), by: .user)
        let ledger = TrainingLedger(store: store, classes: classes)
        // Asked at 01:00 Saturday (still Friday), or for Friday's key: Push A. Saturday is empty.
        #expect(ledger.finishedWorkouts(on: at(10, 17, 1), calendar: calendar).map(\.id) == [workout.id])
        #expect(ledger.finishedWorkouts(onDay: TesseraDayTests.key(10, 16), calendar: calendar).count == 1)
        #expect(ledger.finishedWorkouts(on: at(10, 17, 12), calendar: calendar).isEmpty)
        let week = ledger.week(containing: at(10, 17, 1), plan: plan, now: at(10, 17, 1), calendar: calendar)
        // Friday (today, still) is done with Push A; Saturday is ahead.
        let friday = week.first { $0.day == TesseraDayTests.key(10, 16) }
        #expect(friday?.state == .done && friday?.done.count == 1)
        #expect(week.first { $0.day == TesseraDayTests.key(10, 17) }?.state == .upcoming)
    }

    @Test func x1x3TodayAndNotNowAfterMidnight() throws {
        let rent = try engine.perform(CreateTask(title: "Pay rent", startsAt: at(10, 16, 23), minutes: 30), by: .user)
            .output
        try engine.perform(CreateTask(title: "Dentist", startsAt: at(10, 17, 15)), by: .user)
        let tasks = TaskList(store: store, classes: classes)
        let today = tasks.today(at(10, 17, 1), calendar: calendar)
        // Pay rent is still on-day (not carried); the dentist is tomorrow's.
        #expect(today.map(\.title) == ["Pay rent"] && today.first?.isCarriedOver == false)
        #expect(tasks.upcoming(at(10, 17, 1), calendar: calendar).map(\.title) == ["Dentist"])
        // "Not now" at 01:00 would move Pay rent to Saturday 23:00, inside quiet hours: it lands at 7 am that
        // Saturday (Product 0ab, 2:00 PM PT; QA F2 on #553).
        try engine.perform(MoveTask(task: rent.id, time: at(10, 17, 1), calendar: calendar), by: .user)
        #expect(store.value("startsAt", of: rent)?.dateValue == at(10, 17, 7))
    }

    @Test func x3x4TessReadsHisDay() {
        let grammar = TessGrammar(store: store, classes: classes)
        let late = TessContext(now: at(10, 17, 1), calendar: calendar)
        if case let .task(title, startsAt)? = grammar.parse("dentist tomorrow 3pm", context: late) {
            #expect(title == "Dentist" && startsAt == at(10, 17, 15))
        } else {
            Issue.record("dentist tomorrow 3pm")
        }
        let earlier = TessContext(now: at(10, 17, 1, 30), calendar: calendar)
        if case let .note(_, on)? = grammar.parse("watered plants today", context: earlier) {
            #expect(on == at(10, 16, 12))
        } else {
            Issue.record("watered plants today")
        }
        if case let .note(_, on)? = grammar.parse("watered plants yesterday", context: earlier) {
            #expect(on == at(10, 15, 12))
        } else {
            Issue.record("watered plants yesterday")
        }
        // After midnight the reply names the weekday rather than a misleading "tomorrow".
        #expect(TessCaptureEngine.when(at(10, 17, 15), context: late) == "Saturday 3 pm")
        #expect(TessCaptureEngine.when(at(10, 17, 15), context: TessContext(now: at(10, 16, 20), calendar: calendar))
            == "tomorrow 3 pm")
    }

    @Test func theFourAMRollRunsAtFourNotBefore() throws {
        try engine.perform(CreateTask(title: "Pay rent", startsAt: at(10, 16, 23), minutes: 30), by: .user)
        let tasks = TaskList(store: store, classes: classes)
        #expect(tasks.rollForward(engine: engine, now: at(10, 17, 3, 59), calendar: calendar) == nil)
        #expect(tasks
            .rollForward(engine: engine, now: at(10, 17, 4), calendar: calendar) == "Pay rent carried into today")
    }

    @Test func aWorkoutLeftWithNoSetsIsClosedNotSaved() throws {
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: push.id), by: .user).output
        let table = ProcessTable(engine: engine)
        let process = try #require(table.running())
        try engine.perform(SuspendProcess(process: process.id), by: .user)
        let notes = table.tidy(now: Date.now.addingTimeInterval(7 * 3600))
        #expect(notes.first?.hasSuffix(", no sets, not saved") == true)
        #expect(workout.isDeleted && store.value("endedAt", of: workout) == nil)
    }

    @Test func theEmptyWrapUpCarriesItsUndo() throws {
        // Lines audit 2, item 1: "Push A, no sets, not saved." comes with the record its UNDO takes back.
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: push.id), by: .user).output
        let table = ProcessTable(engine: engine)
        try engine.perform(SuspendProcess(process: #require(table.running()).id), by: .user)
        let notes = table.tidyNotes(now: Date.now.addingTimeInterval(7 * 3600))
        let undo = try #require(notes.first?.undo)
        #expect(workout.isDeleted)
        #expect(table.process(for: workout) == nil)
        engine.undo(undo)
        #expect(!workout.isDeleted)
        // QA P1: the process comes back with it, so the workout is never open and unseen, catching later sets.
        #expect(table.process(for: workout)?.state == .suspended)
    }
}

@MainActor
struct UndoSkipsHousekeepingTests {
    @Test func undoAfterFourAMTakesBackHisActionNotTheRoll() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let calendar = TesseraDayTests.calendar
        try engine.perform(CreateTask(title: "Pay rent", startsAt: TesseraDayTests.at(10, 16, 23)), by: .user)
        let note = try engine.perform(CreateNote(body: "Bar felt heavy"), by: .user).output
        // The roll runs after his note (as at 04:00 on foreground), so it is the newest record.
        _ = TaskList(store: store, classes: classes)
            .rollForward(engine: engine, now: TesseraDayTests.at(10, 17, 4, 30), calendar: calendar)
        #expect(engine.history().first?.actor == .system)
        let undone = engine.undoLatest()
        #expect(undone?.action == "createNote" && note.isDeleted)
    }
}

import Foundation
@testable import TesseraCore
import Testing

/// Checking a routine's steps off (sheets 313 and 379).
@MainActor
struct RoutineStepChecksTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let routine: ObjectRecord
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Thursday, Oct 22, 2026, 18:10 UTC.
    let evening = Date(timeIntervalSince1970: 1_792_692_600)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        engine.zone = { utc.timeZone }
        routine = try RoutineSample.evening(in: engine)
    }

    var book: RestBook {
        RestBook(store: store, classes: classes)
    }

    var steps: [ObjectRecord] {
        routine.orderedChildren
    }

    func check(_ index: Int, at when: Date, done: Bool = true) throws -> ActionEngine.Result<TendRoutineStep.Output> {
        try engine.perform(TendRoutineStep(step: steps[index].id, at: when, done: done), by: .user)
    }

    @Test func aStepIsCheckedAndUncheckedAndTheReadsFollow() throws {
        #expect(book.lastDone(ofStep: steps[0].id) == nil)
        let first = try check(0, at: evening)
        #expect(first.output == .init(done: true, routineTended: false))
        #expect(book.lastDone(ofStep: steps[0].id) == evening)
        #expect(book.stepsDone(of: routine.id, on: evening, calendar: calendar) == [steps[0].id])
        #expect(book.stepsLeft(of: routine.id, on: evening, calendar: calendar).count == steps.count - 1)
        // Tomorrow it starts clean.
        let tomorrow = evening.addingTimeInterval(86400)
        #expect(book.stepsDone(of: routine.id, on: tomorrow, calendar: calendar).isEmpty)
        // Uncheck takes it back.
        _ = try check(0, at: evening, done: false)
        #expect(book.lastDone(ofStep: steps[0].id) == nil)
        #expect(book.stepsDone(of: routine.id, on: evening, calendar: calendar).isEmpty)
    }

    @Test func checkingTheLastStepTendsTheRoutineOncePerDayInTheSameGroupAndUndoTakesBothBack() throws {
        for index in 0 ..< steps.count - 1 {
            #expect(try check(index, at: evening).output.routineTended == false)
        }
        #expect(book.tendedDays(of: routine.id, calendar: calendar).isEmpty)
        let last = try check(steps.count - 1, at: evening)
        #expect(last.output == .init(done: true, routineTended: true))
        #expect(book.tendedDays(of: routine.id, calendar: calendar).count == 1)
        #expect(book.isFullyDone(routine.id, on: evening, calendar: calendar))
        // Checking one again the same day does not tend it twice.
        #expect(try check(0, at: evening.addingTimeInterval(60)).output.routineTended == false)
        #expect(book.tendedDays(of: routine.id, calendar: calendar).count == 1)
        // One Undo takes the last check and the tend back together.
        engine.undo(last.record)
        #expect(book.lastDone(ofStep: steps[steps.count - 1].id) == nil)
        #expect(book.tendedDays(of: routine.id, calendar: calendar).isEmpty)
    }

    @Test func uncheckingTheLastStepKeepsTheDaysTendAndTheNextDayTendsAgain() throws {
        for index in 0 ..< steps.count {
            _ = try check(index, at: evening)
        }
        _ = try check(steps.count - 1, at: evening, done: false)
        #expect(!book.isFullyDone(routine.id, on: evening, calendar: calendar))
        #expect(book.tendedDays(of: routine.id, calendar: calendar).count == 1, "it happened")
        let tomorrow = evening.addingTimeInterval(86400)
        for index in 0 ..< steps.count {
            _ = try check(index, at: tomorrow)
        }
        #expect(book.tendedDays(of: routine.id, calendar: calendar).count == 2)
    }

    @Test func aMoveCanBeCheckedButOnlyStepsCountTowardTheRoutine() throws {
        let stretch = try #require(steps.first { $0.title == "Stretch" })
        let move = try #require(stretch.orderedChildren.first)
        let result = try engine.perform(TendRoutineStep(step: move.id, at: evening), by: .user)
        #expect(result.output.routineTended == false)
        #expect(book.lastDone(ofStep: move.id) == evening)
        #expect(book.stepsDone(of: routine.id, on: evening, calendar: calendar).isEmpty)
    }
}

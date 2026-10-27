import Foundation
@testable import TesseraCore
import Testing

/// Design 44: a plan's cycle can be edited, and it rolls on or sits on fixed days (Product 1fdd1c6: a missed fixed
/// day does not roll on; one routine per weekday).
@MainActor
struct PlanDaysTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    /// Monday 12 October 2026 and the days after, at noon in Los Angeles.
    static func at(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let ledger: TrainingLedger
    let routines: [ObjectRecord]
    let plan: ObjectRecord

    init() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        self.classes = classes
        self.engine = engine
        ledger = TrainingLedger(store: store, classes: classes)
        let made = try ["Push A", "Pull A", "Legs A"]
            .map { try engine.perform(CreateRoutine(title: $0), by: .user).output }
        routines = made
        plan = try engine.perform(CreatePlan(title: "PPL", routines: made.map(\.id)), by: .user).output
    }

    var cycle: [String] {
        store.linkedObjects("routines", of: plan).map(\.title)
    }

    func train(_ routine: ObjectRecord, at time: Date) throws {
        let workout = try store.create(#require(classes[.workout]), title: routine.title)
        try store.setLinks("routine", on: workout, to: [routine])
        try store.set("startedAt", to: .date(time), on: workout)
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, time: time), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(3000)), by: .user)
    }

    // MARK: The cycle

    @Test func addMoveAndDropEachUndo() throws {
        let pushC = try engine.perform(CreateRoutine(title: "Push C"), by: .user).output
        let added = try engine.perform(AddRoutineToPlan(plan: plan.id, routine: pushC.id), by: .user)
        #expect(cycle == ["Push A", "Pull A", "Legs A", "Push C"])
        #expect(added.record.summary == "Push C added to PPL")
        engine.undo(added.record)
        #expect(cycle == ["Push A", "Pull A", "Legs A"])
        try engine.perform(AddRoutineToPlan(plan: plan.id, routine: pushC.id, at: 1), by: .user)
        #expect(cycle == ["Push A", "Push C", "Pull A", "Legs A"])
        // Adding a routine already in the cycle moves it, never doubles it.
        try engine.perform(AddRoutineToPlan(plan: plan.id, routine: pushC.id), by: .user)
        #expect(cycle == ["Push A", "Pull A", "Legs A", "Push C"])

        let moved = try engine.perform(MoveRoutineInPlan(plan: plan.id, routine: pushC.id, to: 0), by: .user)
        #expect(cycle == ["Push C", "Push A", "Pull A", "Legs A"])
        engine.undo(moved.record)
        #expect(cycle == ["Push A", "Pull A", "Legs A", "Push C"])

        let dropped = try engine.perform(DropRoutineFromPlan(plan: plan.id, routine: pushC.id), by: .user)
        #expect(cycle == ["Push A", "Pull A", "Legs A"] && dropped.record.summary == "Push C dropped")
        #expect(!pushC.isDeleted) // history keeps the routine
        engine.undo(dropped.record)
        #expect(cycle == ["Push A", "Pull A", "Legs A", "Push C"])
        #expect(throws: ActionError.self) {
            try engine.perform(DropRoutineFromPlan(plan: plan.id, routine: UUID()), by: .user)
        }
    }

    // MARK: Fixed days

    @Test func scheduleModeDefaultsToRollingAndSwitches() throws {
        #expect(PlanSchedule.mode(of: plan, store: store) == .rolling)
        let fixed = try engine.perform(SetScheduleMode(plan: plan.id, mode: .fixed), by: .user)
        #expect(PlanSchedule.mode(of: plan, store: store) == .fixed && fixed.record.summary == "PPL on fixed days")
        engine.undo(fixed.record)
        #expect(PlanSchedule.mode(of: plan, store: store) == .rolling)
        #expect(try engine.perform(SetScheduleMode(plan: plan.id, mode: .rolling), by: .user).record.summary
            == "PPL rolls on")
    }

    @Test func oneRoutinePerWeekdayAndTheLoserIsNamed() throws {
        let pull = try engine.perform(SetRoutineWeekdays(routine: routines[1].id, weekdays: [5]), by: .user)
        #expect(pull.output.isEmpty && pull.record.summary == "Pull A on Thursdays")
        let push = try engine.perform(SetRoutineWeekdays(routine: routines[0].id, weekdays: [2, 5]), by: .user)
        #expect(push.record.summary == "Push A on Mondays and Thursdays")
        #expect(push.output.map(\.weekday) == [5] && push.output.first?.from == routines[1].id)
        #expect(push.output.first?.line(to: "Push A") == "Thursday was Pull A's. Push A has it now")
        #expect(PlanSchedule.weekdays(of: routines[1], store: store).isEmpty)
        #expect(PlanSchedule.weekdays(of: routines[0], store: store) == [2, 5])
        // One UNDO gives Thursday back.
        engine.undo(push.record)
        #expect(PlanSchedule.weekdays(of: routines[1], store: store) == [5])
        #expect(PlanSchedule.weekdays(of: routines[0], store: store).isEmpty)
        #expect(throws: ActionError.self) {
            try engine.perform(SetRoutineWeekdays(routine: routines[0].id, weekdays: [0, 8]), by: .user)
        }
        // A routine in no plan with this one keeps its days.
        let other = try engine.perform(CreateRoutine(title: "Swim"), by: .user).output
        try engine.perform(SetRoutineWeekdays(routine: other.id, weekdays: [5]), by: .user)
        let again = try engine.perform(SetRoutineWeekdays(routine: routines[2].id, weekdays: [5]), by: .user)
        #expect(again.output.map(\.from) == [routines[1].id])
        #expect(PlanSchedule.weekdays(of: other, store: store) == [5])
    }

    @Test func theWeekReadsFixedDaysAndAMissedDayDoesNotRollOn() throws {
        // Push Mon and Thu, Pull Tue, Legs Sat. It's Wednesday noon; Monday was trained, Tuesday was not.
        try engine.perform(SetScheduleMode(plan: plan.id, mode: .fixed), by: .user)
        try engine.perform(SetRoutineWeekdays(routine: routines[0].id, weekdays: [2, 5]), by: .user)
        try engine.perform(SetRoutineWeekdays(routine: routines[1].id, weekdays: [3]), by: .user)
        try engine.perform(SetRoutineWeekdays(routine: routines[2].id, weekdays: [7]), by: .user)
        try train(routines[0], at: Self.at(12, 18))
        let now = Self.at(14)
        let week = ledger.week(containing: now, plan: plan, now: now, calendar: Self.calendar)
        #expect(week.map { $0.planned?.title ?? ($0.done.first?.title ?? "-") }
            == ["Push A", "-", "-", "Push A", "-", "Legs A", "-"])
        #expect(week[0].state == .done)
        #expect(week[1].state == .past && week[1].wasDue && !week[1].isRest) // Tuesday's Pull A: due, not rolled on
        #expect(week[2].state == .today && week[2].isRest) // Wednesday has no routine: a rest day
        #expect(week[4].isRest && week[6].isRest)
        // Next is Thursday's Push A, not the missed Pull A; a rest day today says so.
        #expect(ledger.nextRoutine(in: plan, now: now, calendar: Self.calendar)?.title == "Push A")
        let rest = ledger.restDay(plan: plan, now: now, calendar: Self.calendar)
        #expect(rest?.next.title == "Push A" && rest?.nextDay == week[3].day)
        // On Thursday, once Push A is trained, next is Saturday's Legs A.
        try train(routines[0], at: Self.at(15, 7))
        #expect(ledger.nextRoutine(in: plan, now: Self.at(15), calendar: Self.calendar)?.title == "Legs A")
        // Back to rolling: the cycle rolls on from the last finished routine, whatever the day.
        try engine.perform(SetScheduleMode(plan: plan.id, mode: .rolling), by: .user)
        #expect(ledger.nextRoutine(in: plan, now: Self.at(15), calendar: Self.calendar)?.title == "Pull A")
    }

    @Test func droppingClearsDaysAndReAddingReconciles() throws {
        // QA L1 on #341, Product 4b857dc: a dropped routine loses its days; one added with days takes them, newer
        // pick wins, with the handoff line.
        try engine.perform(SetScheduleMode(plan: plan.id, mode: .fixed), by: .user)
        try engine.perform(SetRoutineWeekdays(routine: routines[0].id, weekdays: [2, 5]), by: .user)
        let dropped = try engine.perform(DropRoutineFromPlan(plan: plan.id, routine: routines[0].id), by: .user)
        #expect(PlanSchedule.weekdays(of: routines[0], store: store).isEmpty)
        engine.undo(dropped.record)
        #expect(PlanSchedule.weekdays(of: routines[0], store: store) == [2, 5] && cycle.count == 3)
        // A routine from another plan arrives with Thursday already set: Push A loses it.
        let swim = try engine.perform(CreateRoutine(title: "Swim"), by: .user).output
        try engine.perform(SetRoutineWeekdays(routine: swim.id, weekdays: [5]), by: .user)
        let added = try engine.perform(AddRoutineToPlan(plan: plan.id, routine: swim.id), by: .user)
        #expect(added.output.map(\.weekday) == [5] && added.output.first?.from == routines[0].id)
        #expect(PlanSchedule.weekdays(of: routines[0], store: store) == [2])
        engine.undo(added.record)
        #expect(PlanSchedule.weekdays(of: routines[0], store: store) == [2, 5] && cycle.count == 3)
    }

    @Test func fixedModeWithNoDaysRollsOn() throws {
        // QA L3 on #341: until a routine has a day, the plan keeps rolling and the editor can steer him to pick days.
        try engine.perform(SetScheduleMode(plan: plan.id, mode: .fixed), by: .user)
        let now = Self.at(14)
        #expect(ledger.nextRoutine(in: plan, now: now, calendar: Self.calendar)?.title == "Push A")
        #expect(ledger.week(containing: now, plan: plan, now: now, calendar: Self.calendar)
            .contains { $0.planned != nil })
        #expect(try engine.perform(SetRoutineWeekdays(routine: routines[0].id, weekdays: []), by: .user).record.summary
            == "Push A, no fixed days")
        #expect(throws: ActionError.self) {
            try engine.perform(SetRoutineWeekdays(routine: routines[0].id, weekdays: [2, 2]), by: .user)
        }
    }

    @Test func aStoreFromCatalogV5ReadsRollingAtV6() throws {
        // Additive: a plan made before the fields exist rolls on, with no days on its routines. The classes are set
        // back to v5 and reseeded, so the fields really are added to an older store (QA L4 on #341).
        for classDef in store.context.all(ClassDef.self) where classDef.systemKey != nil {
            classDef.packageVersion = 5
            for field in classDef.ownFields ?? [] where ["scheduleMode", "fixedWeekdays"].contains(field.key) {
                store.context.delete(field)
            }
        }
        _ = try store.prepareCatalog()
        #expect(store.context.all(FieldDef.self).contains { $0.key == "scheduleMode" })
        #expect(store.context.all(FieldDef.self).contains { $0.key == "fixedWeekdays" })
        #expect(SystemCatalog.package.version >= 6)
        #expect(store.value("scheduleMode", of: plan) == .choice("rolling") || store
            .value("scheduleMode", of: plan) == nil)
        #expect(PlanSchedule.mode(of: plan, store: store) == .rolling)
        #expect(routines.allSatisfy { PlanSchedule.weekdays(of: $0, store: store).isEmpty })
        #expect(Weekdays.ordered([1, 5, 2]) == [2, 5, 1] && Weekdays.decode("2,5,x,9") == [2, 5])
    }
}

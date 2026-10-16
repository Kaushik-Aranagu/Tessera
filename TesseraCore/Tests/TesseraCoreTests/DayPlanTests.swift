import Foundation
@testable import TesseraCore
import Testing

/// The rules plan (M4 slice 6): docs/research/fixtures/plan-my-day-claude.md's days, in Los Angeles, November 2026.
@MainActor
struct DayPlanTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.firstWeekday = 2
        return calendar
    }()

    static func at(_ day: Int, _ time: String, month: Int = 11) -> Date {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: parts[0],
                                                  minute: parts.count > 1 ? parts[1] : 0))!
    }

    func input(_ day: Int, now: String = "08:00") -> PlanInput {
        PlanInput(now: Self.at(day, now), calendar: Self.calendar)
    }

    func event(_ day: Int, _ title: String, _ start: String, _ end: String) -> PlanInput.Event {
        PlanInput.Event(title: title, start: Self.at(day, start), end: Self.at(day, end))
    }

    /// "08:00-08:15 task Reply to landlord*" (* a plan line), for compact expectations.
    func lines(_ plan: DayPlan) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = Self.calendar
        formatter.timeZone = Self.calendar.timeZone
        formatter.dateFormat = "HH:mm"
        return plan.blocks.map { block in
            "\(formatter.string(from: block.start))-\(formatter.string(from: block.end)) \(block.kind.rawValue) "
                + "\(block.title)\(block.ghost ? "*" : "")\(block.movedFrom == nil ? "" : " moved")"
                + "\(block.running ? " running" : "")"
        }
    }

    @Test func d01TiersThenEarliestGap() {
        var day = input(2)
        day.events = [event(2, "Standup", "09:30", "09:45"), event(2, "Design review", "11:00", "12:00"),
                      event(2, "1:1 Priya", "15:00", "15:30")]
        day.workout = PlanInput.Workout(title: "Push A", scheduledFor: Self.at(2, "18:00"))
        day.today = [
            PlanInput.Task(title: "Reply to landlord", minutes: 15, rolls: 1, rolledFrom: Self.at(30, "09:00",
                                                                                                  month: 10),
                           updatedAt: Self.at(30, "09:00", month: 10)),
            PlanInput.Task(title: "Book physio", due: Self.at(2, "00:00"), dueIsDateOnly: true, minutes: 20,
                           updatedAt: Self.at(29, "09:00", month: 10)),
            PlanInput.Task(title: "Expense report", due: Self.at(2, "17:00"), minutes: 45,
                           updatedAt: Self.at(27, "09:00", month: 10)),
        ]
        day.later = [PlanInput.Task(title: "Sort the garage", minutes: 120, updatedAt: Self.at(12, "09:00", month: 10))]
        let plan = DayPlanner.plan(day)
        #expect(lines(plan) == [
            "08:00-08:15 task Reply to landlord*", "08:15-09:00 task Expense report*", "09:00-09:20 task Book physio*",
            "09:30-09:45 event Standup", "11:00-12:00 event Design review", "15:00-15:30 event 1:1 Priya",
            "18:00-19:00 workout Push A",
        ])
        #expect(plan.startWith?.title == "Reply to landlord" && plan.cap == 3)
        #expect(plan.blocks[1].due == Self.at(2, "17:00"))
        #expect(plan.runs.map { $0.map(\.title) } == [["Reply to landlord", "Expense report", "Book physio"]])
    }

    @Test func d02LaterFillsByOldestTouchedAndALongTaskSkipsAShortGap() {
        var day = input(3)
        day.workout = PlanInput.Workout(title: "Pull A", scheduledFor: Self.at(3, "18:00"))
        day.today = [PlanInput.Task(title: "Call bank", due: Self.at(3, "00:00"), dueIsDateOnly: true, minutes: 15,
                                    updatedAt: Self.at(2, "09:00"))]
        day.later = [
            PlanInput.Task(title: "Sort the garage", minutes: 120, updatedAt: Self.at(12, "09:00", month: 10)),
            PlanInput.Task(title: "Renew passport", updatedAt: Self.at(20, "09:00", month: 10)),
            PlanInput.Task(title: "Fix bike light", minutes: 20, updatedAt: Self.at(5, "09:00", month: 10)),
        ]
        #expect(lines(DayPlanner.plan(day)) == [
            "08:00-08:15 task Call bank*", "08:15-08:35 task Fix bike light*", "08:35-10:35 task Sort the garage*",
            "18:00-19:00 workout Pull A",
        ])
        // With Standup known, the garage can't fit before it and goes after.
        day.events = [event(3, "Standup", "09:30", "09:45")]
        #expect(lines(DayPlanner.plan(day))[3] == "09:45-11:45 task Sort the garage*")
    }

    @Test func d04ALightDayPlansTwo() {
        var day = input(5)
        day.light = true
        day.events = [event(5, "Standup", "09:30", "09:45"), event(5, "Client call", "10:00", "11:00")]
        day.today = [
            PlanInput.Task(title: "Pay council tax", due: Self.at(5, "00:00"), dueIsDateOnly: true, minutes: 10,
                           updatedAt: Self.at(1, "09:00")),
            PlanInput.Task(
                title: "Draft Q4 goals",
                due: Self.at(5, "17:00"),
                minutes: 60,
                updatedAt: Self.at(1, "09:00")
            ),
            PlanInput.Task(title: "Call plumber", due: Self.at(5, "00:00"), dueIsDateOnly: true,
                           updatedAt: Self.at(2, "09:00")),
        ]
        let plan = DayPlanner.plan(day)
        #expect(plan.cap == 2 && plan.ghosts.map(\.title) == ["Draft Q4 goals", "Pay council tax"])
        #expect(plan.notPlanned.map(\.title) == ["Call plumber"] && plan.notPlanned.first?.why == .cap)
    }

    @Test func d05AnEventOverTheGymMovesItAfter() {
        var day = input(6)
        day.events = [event(6, "All-hands", "16:00", "17:00"), event(6, "Vendor call", "17:30", "18:30")]
        day.workout = PlanInput.Workout(title: "Pull B", scheduledFor: Self.at(6, "18:00"))
        let workout = DayPlanner.plan(day).blocks.first { $0.kind == .workout }
        #expect(workout?.start == Self.at(6, "18:30") && workout?.movedFrom == Self.at(6, "18:00"))
    }

    @Test func d06CookWaitsForTheEveningAndTimedTasksAreFixed() {
        var day = input(7)
        day.events = [event(7, "Parkrun", "09:00", "10:00"), event(7, "Lunch with Nikhil", "13:00", "14:30")]
        day.workout = PlanInput.Workout(title: "Legs B", scheduledFor: Self.at(7, "11:00"))
        day.today = [
            PlanInput.Task(title: "Call mum", minutes: 20, rolls: 1, rolledFrom: Self.at(6, "19:00"),
                           updatedAt: Self.at(6, "19:00")),
            PlanInput.Task(title: "Cook carbonara", startsAt: nil, due: Self.at(7, "00:00"), dueIsDateOnly: true,
                           updatedAt: Self.at(5, "09:00"), isCook: true),
            PlanInput.Task(
                title: "Dentist",
                startsAt: Self.at(7, "16:45"),
                minutes: 30,
                updatedAt: Self.at(1, "09:00")
            ),
        ]
        day.later = [PlanInput.Task(title: "Sort the garage", minutes: 120, updatedAt: Self.at(12, "09:00", month: 10))]
        #expect(lines(DayPlanner.plan(day)) == [
            "08:00-08:20 task Call mum*", "09:00-10:00 event Parkrun", "11:00-12:00 workout Legs B",
            "13:00-14:30 event Lunch with Nikhil", "14:30-16:30 task Sort the garage*", "16:45-17:15 timedTask Dentist",
            "18:00-18:45 task Cook carbonara*",
        ])
    }

    @Test func aRunningWorkoutSitsAtItsStartAndAFinishedOneHasNoBlock() {
        var day = input(16, now: "08:00")
        day.workout = PlanInput.Workout(title: "Push A", scheduledFor: Self.at(16, "18:00"),
                                        startedAt: Self.at(16, "07:40"))
        #expect(lines(DayPlanner.plan(day)) == ["07:40-08:40 workout Push A running"])
        #expect(DayPlanner.plan(day).startWith?.running == true)
        day.workout?.endedAt = Self.at(16, "08:30")
        #expect(DayPlanner.plan(day).blocks.isEmpty)
    }

    @Test func theWindowOpensAtSevenAndClosesAtNine() {
        // 06:40: nothing before 07:00. 21:05 and 01:30 (still the day before): no window, no plan.
        var early = input(9, now: "06:40")
        early.later = [PlanInput.Task(title: "Fix bike light", minutes: 20, updatedAt: Self.at(5, "09:00"))]
        #expect(DayPlanner.plan(early).ghosts.first?.start == Self.at(9, "07:00"))
        #expect(DayPlanner.plan(input(9, now: "21:05")).window == nil)
        #expect(DayPlanner.plan(input(10, now: "01:30")).window == nil)
        // 08:02 rounds up to 08:05.
        var odd = input(9, now: "08:02")
        odd.later = early.later
        #expect(DayPlanner.plan(odd).ghosts.first?.start == Self.at(9, "08:05"))
    }

    @Test func birthdaysAndDeclinedEventsNeverShow() {
        var day = input(9)
        day.events = [
            PlanInput.Event(title: "Mum's Birthday", start: Self.at(9, "00:00"), end: Self.at(10, "00:00"),
                            allDay: true),
            PlanInput.Event(title: "Bank holiday", start: Self.at(9, "00:00"), end: Self.at(10, "00:00"), allDay: true),
            PlanInput.Event(
                title: "Optional sync",
                start: Self.at(9, "09:00"),
                end: Self.at(9, "10:00"),
                declined: true
            ),
        ]
        let plan = DayPlanner.plan(day)
        #expect(plan.allDay == ["Bank holiday"] && plan.blocks.isEmpty)
    }

    @Test func aTaskThatFitsNowhereIsSkippedAndTheWalkGoesOn() {
        var day = input(9, now: "19:00")
        day.today = [PlanInput.Task(title: "Deep clean", due: Self.at(9, "00:00"), dueIsDateOnly: true, minutes: 180,
                                    updatedAt: Self.at(1, "09:00")),
                     PlanInput.Task(title: "Text Sam", due: Self.at(9, "00:00"), dueIsDateOnly: true, minutes: 10,
                                    updatedAt: Self.at(2, "09:00"))]
        let plan = DayPlanner.plan(day)
        #expect(plan.ghosts.map(\.title) == ["Text Sam"])
        #expect(plan.notPlanned.map(\.title) == ["Deep clean"] && plan.notPlanned.first?.why == .noFit)
    }

    @Test func lightComesFromTheWeekAndTheDayNeverHealth() {
        // C1: 6 a week, 1 done, 4 days left: 5 due, no rest left.
        #expect(DayPlanner.lightReason(trainingDay: true, perWeek: 6, sessionsBeforeToday: 1, daysLeft: 4,
                                       bookedMinutes: 0, fixedBlocks: 0) == .squeezedWeek)
        // One left on the last day is not a squeeze; a rest day can't be.
        #expect(DayPlanner.lightReason(trainingDay: true, perWeek: 4, sessionsBeforeToday: 3, daysLeft: 1,
                                       bookedMinutes: 0, fixedBlocks: 0) == nil)
        #expect(DayPlanner.lightReason(trainingDay: false, perWeek: 6, sessionsBeforeToday: 1, daysLeft: 4,
                                       bookedMinutes: 0, fixedBlocks: 0) == nil)
        #expect(DayPlanner.lightReason(trainingDay: false, perWeek: nil, sessionsBeforeToday: 0, daysLeft: 7,
                                       bookedMinutes: 480, fixedBlocks: 0) == .bookedDay)
        #expect(DayPlanner.lightReason(trainingDay: false, perWeek: nil, sessionsBeforeToday: 0, daysLeft: 7,
                                       bookedMinutes: 0, fixedBlocks: 5) == .cutUpDay)
    }

    @Test func fromTheStore() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateTask(title: "Reply to landlord", startsAt: Self.at(2, "10:00"), minutes: 15),
                           by: .user)
        try engine.perform(CreateTask(title: "Sort the garage"), by: .user)
        let plan = DayPlanner.plan(store: store, classes: classes, plan: nil, now: Self.at(2, "08:00"),
                                   calendar: Self.calendar)
        #expect(lines(plan) == ["08:00-08:30 task Sort the garage*", "10:00-10:15 timedTask Reply to landlord"])
        // Nothing was written.
        #expect(engine.history(limit: 10).count == 2)
    }
}

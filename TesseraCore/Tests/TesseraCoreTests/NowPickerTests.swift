import Foundation
@testable import TesseraCore
import Testing

/// The ranker against Research's fixtures (docs/research/fixtures/ranker.md). Week of Mon Oct 12 2026,
/// America/Los_Angeles. Rows that need things not on master yet (calendar events, list runs, linked lists, the
/// Shutdown and Plan my day offers) wait for those slices.
@MainActor
struct NowPickerTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let picker: NowPicker
    let calendar: Calendar
    let plan: ObjectRecord
    let routines: [ObjectRecord]

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        picker = NowPicker(engine: engine)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        calendar.firstWeekday = 2
        self.calendar = calendar
        plan = try #require(store.object(id: StarterContent.planID))
        routines = store.linkedObjects("routines", of: plan)
    }

    // MARK: Helpers

    /// Oct `day` 2026 at hh:mm, Los Angeles. Mon 12 … Sun 18.
    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @discardableResult
    func task(_ title: String, at start: Date? = nil, minutes: Double? = nil, due: Date? = nil,
              touched: Date? = nil) throws -> ObjectRecord
    {
        let task = try engine.perform(CreateTask(title: title, startsAt: start, minutes: minutes, due: due),
                                      by: .user).output
        if let touched {
            task.updatedAt = touched
        }
        return task
    }

    func trained(_ index: Int, on date: Date) throws {
        let workout = try engine.perform(StartRoutine(routine: routines[index].id, time: date), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: date.addingTimeInterval(3600)), by: .user)
    }

    @discardableResult
    func scheduled(_ title: String, at date: Date) throws -> ObjectRecord {
        let workout = try store.create(#require(classes[.workout]), title: title)
        try store.set("scheduledFor", to: .date(date), on: workout)
        return workout
    }

    func groceries(_ count: Int) throws {
        try engine.perform(AddGroceries(lines: (1 ... count).map { "item \($0)" }), by: .user)
    }

    func rank(_ now: Date, _ edit: (inout RankContext) -> Void = { _ in }) -> [Pick] {
        var context = RankContext(now: now, calendar: calendar, dayFull: false)
        edit(&context)
        return picker.rank(context)
    }

    /// Mon and Wed trained, three a week: Thursday rests (trained yesterday), Friday trains.
    func restThursday() throws {
        try trained(0, on: at(12, 18))
        try trained(1, on: at(14, 18))
    }

    // MARK: Rest day (R01 to R05)

    @Test func r01RestDayBeatsADueTaskAndDropsTheGymNudge() throws {
        try restThursday()
        let nudge = try scheduled("Pull A", at: at(15, 18, 30))
        try task("Renew passport", due: at(15, 9))
        let picks = rank(at(15, 7, 20)) { $0.plan = plan; $0.sessionsPerWeek = 3 }
        #expect(picks.first?.item.kind == .rest && picks.first?.item.title == "Rest day")
        #expect(picks.first?.why.hasPrefix("Rest day. ") == true && picks.first?.why.hasSuffix("is a tap away") == true)
        #expect(picks.dropFirst().first?.item.title == "Renew passport" && picks[1].score == 20)
        #expect(!picks.contains { $0.id == nudge.id })
    }

    @Test func r02RestBeatsTheStrongestGymNudge() throws {
        try restThursday()
        try scheduled("Pull A", at: at(15, 18, 30))
        let picks = rank(at(15, 18, 10)) {
            $0.plan = plan
            $0.sessionsPerWeek = 3
            $0.lastAction = LastAction(area: .training, at: at(15, 18, 7))
        }
        #expect(picks.map(\.item.kind) == [.rest])
    }

    @Test func r03RestSitsAboveReentry() throws {
        try restThursday()
        try task("Water plants", minutes: 10, due: at(15, 9)) // "untimed today" is due today
        let picks = rank(at(15, 10)) { $0.plan = plan; $0.sessionsPerWeek = 3; $0.daysAway = 4 }
        #expect(picks.first?.item.kind == .rest)
        #expect(picks.dropFirst().first?.item.title == "Water plants")
    }

    @Test func r04RunningBeatsRest() throws {
        try restThursday()
        try task("Call mum", due: at(15, 9))
        let workout = try engine.perform(StartRoutine(routine: routines[1].id, time: at(15, 11, 28)), by: .user)
            .output
        let picks = rank(at(15, 11, 30)) { $0.plan = plan; $0.sessionsPerWeek = 3 }
        #expect(picks.first?.item.kind == .process && picks.first?.id == workout.id)
        #expect(picks.first?.why.hasPrefix("Running since ") == true)
        #expect(picks.dropFirst().first?.item.title == "Call mum")
    }

    @Test func r05ATimedTaskWithinFifteenMinutesBeatsTheRestLine() throws {
        try restThursday()
        let landlord = try task("Call landlord", at: at(15, 18))
        let picks = rank(at(15, 17, 50)) { $0.plan = plan; $0.sessionsPerWeek = 3 }
        #expect(picks.first?.id == landlord.id && picks.first?.why == "At 6 pm, your evening slot")
        #expect(picks.dropFirst().first?.item.kind == .rest)
    }

    @Test func dayLoadSkipsTheGymNudgeOnARestDay() throws {
        try scheduled("Pull A", at: at(15, 18, 30))
        let tasks = TaskList(store: store, classes: classes)
        #expect(tasks.load(at: at(15, 12), calendar: calendar).plannedMinutes == 60)
        #expect(tasks.load(at: at(15, 12), restDay: true, calendar: calendar).plannedMinutes == 0)
    }

    // MARK: Running and suspended (R06, R10, R11, R40)

    @Test func r06RunningWinsAndTheShopOfferIsGatedOff() throws {
        try groceries(11)
        try task("Call landlord", at: at(12, 19))
        let workout = try engine.perform(StartRoutine(routine: routines[0].id, time: at(12, 18, 32)), by: .user)
            .output
        let picks = rank(at(12, 18, 45))
        #expect(picks.first?.id == workout.id && picks.first?.item.kind == .process)
        #expect(picks.dropFirst().first?.item.title == "Call landlord")
        #expect(!picks.hasAsk)
    }

    @Test func r10r11SuspendedProcessesNeverTakeNow() throws {
        let dal = try task("Make dal")
        try engine.perform(StartTask(task: dal.id), by: .user)
        let process = try #require(ProcessTable(engine: engine).running())
        try engine.perform(SuspendProcess(process: process.id), by: .user)
        // Nothing else on: Now is quiet; the dal stays a ledger row.
        #expect(rank(at(15, 20, 10)).isEmpty)
        // A carried task takes Now instead.
        let arjun = try task("Reply to Arjun", at: at(14, 10))
        let picks = rank(at(15, 19, 40))
        #expect(picks.map(\.id) == [arjun.id] && picks.first?.why == "Carried from Wed")
    }

    @Test func r40HisOwnStartWins() throws {
        try task("Reply to Arjun", at: at(14, 9), due: at(15, 9))
        let physio = try task("Book physio", due: at(15, 9))
        try engine.perform(StartTask(task: physio.id), by: .user)
        let picks = rank(at(15, 10, 5))
        #expect(picks.first?.id == physio.id && picks.first?.why.hasPrefix("Running since ") == true)
        #expect(picks.dropFirst().first?.item.title == "Reply to Arjun" && picks[1].score == 30)
    }

    // MARK: Shop offer (R14 to R18)

    @Test func r14ShopOfferOpensAtEightInTheEvening() throws {
        try groceries(8)
        try task("Book physio", due: at(12, 9))
        let picks = rank(at(12, 18, 5)) { $0.lastAction = LastAction(area: .groceries, at: at(12, 18, 1)) }
        #expect(picks.first?.item.kind == .offer && picks.first?.score == 30)
        #expect(picks.first?.why == "8 on Groceries, your evening slot")
        #expect(picks.dropFirst().first?.item.title == "Book physio" && picks[1].score == 20)
    }

    @Test func r15r16r17ShopGates() throws {
        try groceries(7)
        try task("Book physio", due: at(12, 9))
        #expect(!rank(at(12, 18, 5)).hasAsk) // 7 on the list
        try engine.perform(AddGroceries(lines: (1 ... 5).map { "more \($0)" }), by: .user)
        #expect(!rank(at(12, 10, 15)).hasAsk) // morning
        #expect(!rank(at(12, 19, 30)) { $0.declined = ["shop"] }.hasAsk) // declined today
        #expect(rank(at(12, 19, 30)).hasAsk)
    }

    @Test func r18ANearTimedTaskBeatsShop() throws {
        try groceries(9)
        let bank = try task("Call bank", at: at(15, 19))
        let picks = rank(at(15, 18, 40))
        #expect(picks.first?.id == bank.id && picks.first?.why == "At 7 pm, your evening slot")
        #expect(picks.dropFirst().first?.item.kind == .offer && picks[1].score == 15)
    }

    // MARK: Workouts and slots (R20 to R22)

    @Test func r20AWorkoutPastItsHourKeepsItsSlotButNotItsSoonPoints() throws {
        let pull = try scheduled("Pull A", at: at(13, 7, 30))
        try task("Reply to Arjun", at: at(12, 9))
        let picks = rank(at(13, 8, 45))
        #expect(picks.first?.id == pull.id && picks.first?.score == 15 && picks.first?.why == "Your morning slot")
        #expect(picks.dropFirst().first?.score == 10)
    }

    @Test func r21r22AWorkoutComingUp() throws {
        let push = try scheduled("Push A", at: at(12, 18, 30))
        try task("Call mum")
        let at55 = rank(at(12, 17, 35))
        #expect(at55.first?.id == push.id && at55.first?.score == 37)
        #expect(at55.first?.why == "At 6:30 pm, your evening slot")
        #expect(rank(at(12, 17, 29)).first?.score == 35)
    }

    @Test func r23ATimedTaskWithinFifteenMinutesTakesNow() throws {
        try scheduled("Legs A", at: at(14, 18, 45))
        let landlord = try task("Call landlord", at: at(14, 18))
        let picks = rank(at(14, 17, 45))
        #expect(picks.first?.id == landlord.id && picks.dropFirst().first?.item.title == "Legs A")
    }

    // MARK: Day full (R26, R27)

    @Test func r26r27DayFullMarksDownUntimedItems() throws {
        let dentist = try task("Dentist", at: at(15, 17))
        try task("Clean garage", due: at(15, 9))
        try task("Sort photos", at: at(13, 9))
        let full = rank(at(15, 16)) { $0.dayFull = true }
        #expect(full.first?.id == dentist.id && full.first?.why == "At 5 pm")
        #expect(full.dropFirst().first?.item.title == "Clean garage" && full[1].score == 10)

        let bank = try task("Call bank", at: at(16, 16, 20))
        try task("Pay rent", at: at(14, 9), due: at(16, 9))
        #expect(rank(at(16, 15)) { $0.dayFull = true }.first?.id == bank.id)
        #expect(rank(at(16, 15)).first?.item.title == "Pay rent") // 30 beats 29 when not full
    }

    // MARK: Quiet (R28, R29)

    @Test func r28r29AnEmptyOrFinishedDayIsQuiet() throws {
        #expect(rank(at(18, 12, 30)).isEmpty)
        let chores = try (1 ... 3).map { try task("Chore \($0)") }
        for chore in chores {
            try engine.perform(SetTaskDone(task: chore.id), by: .user)
        }
        #expect(rank(at(13, 15)).isEmpty)
    }

    // MARK: Ties and hysteresis (R30 to R36)

    @Test func r30r31TiesGoToTheStalestThenAToZ() throws {
        try task("Pay water bill", due: at(15, 9), touched: at(9, 9))
        try task("Renew passport", due: at(15, 9), touched: at(2, 9))
        #expect(rank(at(15, 13, 10)).map(\.item.title) == ["Renew passport", "Pay water bill"])

        let other = NowPickerTests.fresh()
        try other.task("Post parcel", due: other.at(15, 9), touched: other.at(15, 8, 2))
        try other.task("Buy stamps", due: other.at(15, 9), touched: other.at(15, 8, 2))
        #expect(other.rank(other.at(15, 13, 10)).map(\.item.title) == ["Buy stamps", "Post parcel"])
    }

    @Test func r32ATimedItemGetsNoTieAdvantage() throws {
        try task("Pay rent", at: at(14, 9), due: at(15, 9), touched: at(10, 9))
        try task("Call bank", at: at(15, 15, 45), touched: at(14, 9))
        let picks = rank(at(15, 14, 30))
        #expect(picks.map(\.score) == [30, 30])
        #expect(picks.first?.item.title == "Pay rent" && picks.first?.why == "Due today, carried from Wed")
    }

    @Test func r33r34r36TheIncumbentHoldsUnlessBeatenByMoreThanFifteen() throws {
        let arjun = try task("Reply to Arjun", at: at(13, 9), due: at(15, 9))
        let plumber = try task("Call plumber", at: at(15, 11))
        let held = rank(at(15, 10)) {
            $0.incumbent = arjun.id
            $0.lastAction = LastAction(area: .tasks, at: at(15, 10))
        }
        #expect(held.first?.id == arjun.id && held.first?.score == 60 && held[1].score == 50) // R33
        let exactly = rank(at(15, 10, 30)) { $0.incumbent = arjun.id }
        #expect(exactly.map(\.score) == [45, 45] && exactly.first?.id == arjun.id) // R34: exactly 15 holds
        let beaten = rank(at(15, 10, 50)) { $0.incumbent = arjun.id }
        #expect(beaten.first?.id == plumber.id && beaten.first?.why == "At 11 am, your morning slot") // R36
    }

    // MARK: Re-entry (R39) and the old pick

    @Test func r39ReentryFallsThroughWhenNothingFits() throws {
        let plants = try task("Water plants", at: at(14, 9))
        let picks = rank(at(19, 19, 20)) { $0.daysAway = 5 }
        #expect(picks.first?.id == plants.id && picks.first?.why == "Carried from Wed")
    }

    @Test func reentryPicksTheSmallestThingThatFits() throws {
        try task("Long one", at: at(19, 19, 45), minutes: 90)
        let short = try task("Short one", at: at(19, 20), minutes: 20)
        let picks = rank(at(19, 19, 20)) { $0.daysAway = 4 }
        #expect(picks.map(\.id) == [short.id] && picks.first?.why == "Welcome back. Small on purpose")
    }

    @Test func pickReadsTheRanker() throws {
        let current = try task("Review the plan", at: at(15, 13, 45), minutes: 45)
        try task("Groceries", at: at(15, 18))
        let pick = picker.pick(at: at(15, 14), calendar: calendar)
        #expect(pick.now?.id == current.id && pick.now?.endsAt == at(15, 14, 30))
        try engine.perform(StartTask(task: current.id, nextStep: "List the basics"), by: .user)
        let running = picker.pick(at: at(15, 14), calendar: calendar)
        #expect(running.now?.kind == .process && running.now?.nextStep == "List the basics")
        #expect(!running.next.contains { $0.id == current.id })
    }

    @Test func whyLinesAreShortPlainFacts() throws {
        try task("Pay rent", at: at(14, 9), due: at(15, 9))
        try task("Call bank", at: at(15, 15, 45))
        for pick in rank(at(15, 14, 30)) {
            #expect(pick.why.count < 40)
            let lower = pick.why.lowercased()
            #expect(!["missed", "overdue", "late", "behind", "great", "should"].contains(where: lower.contains))
        }
    }

    @Test func n1TaskActionsCountAsTasks() {
        #expect(NowPicker.area(of: "setTaskDone") == .tasks && NowPicker.area(of: "createTask") == .tasks)
        #expect(NowPicker.area(of: "logSet") == .training && NowPicker.area(of: "checkListItem") == .groceries)
    }

    static func fresh() -> NowPickerTests {
        // swiftlint:disable:next force_try
        try! NowPickerTests()
    }
}

private extension [Pick] {
    /// Whether an offer made it into the ranking (a property, so the formatter can't turn it into a key path).
    var hasAsk: Bool {
        contains { $0.isAsk }
    }
}

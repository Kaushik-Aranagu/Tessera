import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research 146 (docs/research/fixtures/rest-weekday.md): the restWeekday reader. PPL x2 (Push A, Pull A, Legs A,
/// Push B, Pull B, Legs B), restWeekday 1 (Sunday), PDT unless a scenario says otherwise.
@MainActor
struct RestWeekdayTests {
    static func calendar(_ zone: String = "America/Los_Angeles") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        calendar.firstWeekday = 2
        return calendar
    }

    let calendar = RestWeekdayTests.calendar()
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let ledger: TrainingLedger
    let plan: ObjectRecord
    let routines: [ObjectRecord]

    init(rest: Int? = 1) throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        ledger = TrainingLedger(store: store, classes: classes)
        plan = try #require(store.object(id: StarterContent.planID))
        routines = store.linkedObjects("routines", of: plan)
        if let rest {
            try setRest(rest, at: Self.at(10, 12, 8)) // set the Monday before the first scenario week
        }
    }

    /// A date in October 2026 in `zone` (default Los Angeles).
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10, zone: String = "America/Los_Angeles")
        -> Date
    {
        calendar(zone).date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Writes the setting as one op stamped `time`, so a scenario can change it mid-week.
    @discardableResult
    func setRest(_ weekday: Int?, at time: Date) throws -> OpRecord {
        var settings = SettingsStore(engine: engine).read()
        settings.restWeekday = weekday
        let record = try engine.perform(WriteSettings(settings: settings), by: .user).record
        record.createdAt = time
        return record
    }

    func train(_ index: Int, at time: Date, zone: String? = nil) throws {
        if let zone {
            engine.zone = { TimeZone(identifier: zone)! }
        }
        let workout = try store.create(#require(classes[.workout]), title: routines[index].title)
        try store.setLinks("routine", on: workout, to: [routines[index]])
        try store.set("startedAt", to: .date(time), on: workout)
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, time: time), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(3000)), by: .user)
    }

    /// Mon 19 to Sat 24 Oct, one routine a day at 18:00 (the week before Sunday 25).
    func trainMondayToSaturday(through lastDay: Int = 24) throws {
        for day in 19 ... lastDay {
            try train(day - 19, at: Self.at(day, 18))
        }
    }

    func week(_ now: Date, rhythm: Int? = 6, calendar: Calendar? = nil) -> [WeekDay] {
        ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: rhythm, calendar: calendar ?? self.calendar)
    }

    func titles(_ week: [WeekDay]) -> [String] {
        week.map { $0.planned?.title ?? ($0.done.first?.title ?? ($0.isRest ? "rest" : "-")) }
    }

    func rest(_ now: Date, rhythm: Int? = 6, calendar: Calendar? = nil) -> RestDay? {
        ledger.restDay(plan: plan, now: now, sessionsPerWeek: rhythm, calendar: calendar ?? self.calendar)
    }

    // MARK: RG1, the week

    @Test func s05MondayPutsRestOnSundayNotThursday() throws {
        try train(5, at: Self.at(17, 18)) // Legs B on Sat 17; rested Sun 18
        let now = Self.at(19, 7)
        let week = week(now)
        #expect(titles(week) == ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B", "rest"])
        #expect(week[6].isRest && week[6].planned == nil && week[6].state == .upcoming)
        #expect(rest(now) == nil)
    }

    @Test func s06ThursdayAfterThreeDone() throws {
        try train(5, at: Self.at(17, 18))
        for day in 19 ... 21 {
            try train(day - 19, at: Self.at(day, 18))
        }
        let now = Self.at(22, 7)
        let week = week(now)
        #expect(week[3].state == .today && week[3].planned?.title == "Push B")
        #expect(titles(week) == ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B", "rest"])
        #expect(rest(now) == nil)
    }

    @Test func s11AMissedWednesdayRollsOnAndSundayStaysRest() throws {
        try train(5, at: Self.at(17, 18))
        try train(0, at: Self.at(19, 18))
        try train(1, at: Self.at(20, 18))
        let now = Self.at(22, 7) // Thursday, Wednesday nothing
        let week = week(now)
        #expect(week[3].planned?.title == "Legs A" && week[4].planned?.title == "Push B"
            && week[5].planned?.title == "Pull B")
        #expect(week[6].isRest && week[6].planned == nil)
        // Legs B waits for Monday Oct 26: the fourth due session has no day this week.
        for (index, day) in [22, 23, 24].enumerated() {
            try train(index + 2, at: Self.at(day, 18))
        }
        #expect(rest(Self.at(25, 10))?.next.title == "Legs B")
    }

    @Test func rg2ARestWeekdayAppliesWithNoRhythmPassed() throws {
        try train(5, at: Self.at(17, 18))
        let now = Self.at(19, 9)
        let week = week(now, rhythm: nil) // S18: the Plans page passes none
        #expect(week[6].isRest && week[6].planned == nil)
        #expect(titles(week).prefix(6).allSatisfy { $0 != "rest" && $0 != "-" })
    }

    @Test func s18PlansPageWeekDrawsSundayAsRest() throws {
        try train(5, at: Self.at(17, 18))
        let now = Self.at(19, 9)
        // PlanData.swift:46 calls week(containing:plan:now:calendar:) with no rhythm.
        let week = ledger.week(containing: now, plan: plan, now: now, calendar: calendar)
        #expect(titles(week) == ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B", "rest"])
    }

    @Test func s19PlanMyDayNeverBooksTheRestDay() throws {
        try trainMondayToSaturday()
        let now = Self.at(25, 7)
        let plan = DayPlanner.plan(store: store, classes: classes, plan: plan, now: now, calendar: calendar)
        #expect(!plan.blocks.contains { $0.kind == .workout })
        let input = DayPlanner.input(store: store, classes: classes, plan: self.plan, now: now, calendar: calendar)
        #expect(input.workout == nil)
        // The day after, a training day, is booked as before.
        let monday = DayPlanner.input(store: store, classes: classes, plan: self.plan, now: Self.at(26, 7),
                                      calendar: calendar)
        #expect(monday.workout?.title == "Push A")
    }

    // MARK: Now and Home on the rest day

    @Test func s07SaturdayNightSaysRestTomorrowAndPushAIsNext() throws {
        try trainMondayToSaturday()
        let now = Self.at(24, 18, 30)
        let sunday = Self.at(25, 12)
        let tomorrow = try #require(rest(sunday))
        #expect(tomorrow.next.title == "Push A" && tomorrow.nextDay == nil)
        #expect(rest(now) == nil)
        #expect(RestDay.line == "Rest day")
    }

    @Test func s08SundayAt1amIsStillSaturday() throws {
        try trainMondayToSaturday()
        let now = Self.at(25, 1)
        #expect(rest(now) == nil)
        #expect(week(now)[5].state == .done)
        #expect(ledger.nextRoutine(in: plan, now: now, calendar: calendar)?.title == "Push A")
    }

    @Test func s09SundayMorningIsRestAndPushAIsATapAway() throws {
        try trainMondayToSaturday()
        let found = try #require(rest(Self.at(25, 10)))
        #expect(found.next.title == "Push A" && found.nextDay == nil)
    }

    @Test func s10MondayAt2amIsStillSundaysRest() throws {
        try trainMondayToSaturday()
        let found = try #require(rest(Self.at(26, 2)))
        #expect(found.next.title == "Push A")
        #expect(rest(Self.at(26, 5)) == nil) // Monday proper trains
    }

    @Test func s12ReviewShowsWednesdayRingAndSundayRestDab() throws {
        try train(5, at: Self.at(17, 18))
        for (index, day) in [19, 20, 22, 23, 24].enumerated() {
            try train(index, at: Self.at(day, 18))
        }
        let week = week(Self.at(25, 21))
        #expect(week[2].state == .past && week[2].wasDue && !week[2].isRest) // Wednesday's ring
        #expect(week[6].isRest && !week[6].wasDue && week[6].state == .today) // Sunday's rest dab
        #expect(week.filter { !$0.done.isEmpty }.count == 5)
        #expect(ledger.nextRoutine(in: plan, now: Self.at(25, 21), calendar: calendar)?.title == "Legs B")
    }

    // MARK: Trained anyway, and a planned session

    @Test func s14AndS15SundaySessionWinsAndAdvancesTheRoll() throws {
        try trainMondayToSaturday()
        let sunday = Self.at(25, 10)
        // Under way on the rest day: not a rest day, running wins.
        let workout = try engine.perform(StartRoutine(routine: routines[0].id, time: sunday), by: .user).output
        #expect(rest(Self.at(25, 10, 5)) == nil)
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, time: sunday), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: sunday.addingTimeInterval(3600)), by: .user)
        let night = Self.at(25, 21)
        let week = week(night)
        #expect(week[6].state == .done && week[6].done.count == 1) // "trained", not "7 of 6"
        #expect(week.compactMap(\.done.first).count == 7)
        #expect(ledger.nextRoutine(in: plan, now: night, calendar: calendar)?.title == "Pull A")
    }

    @Test func s16AScheduledSundaySessionBeatsRest() throws {
        try trainMondayToSaturday()
        let scheduled = try store.create(#require(classes[.workout]), title: "Push A")
        try store.set("scheduledFor", to: .date(Self.at(25, 17)), on: scheduled)
        let now = Self.at(25, 10)
        #expect(rest(now) == nil) // Now: no "Rest day" beside START
        let facts = HomeFacts(engine: engine, calendar: calendar)
        #expect(facts.rest(next: routines[0], now: now) == nil) // Home agrees
        #expect(facts.plannedSession(on: now)?.id == scheduled.id)
        // The week still marks Sunday rest; only today's line yields.
        #expect(week(now)[6].isRest)
    }

    // MARK: Changing it, clearing it, fixed days

    @Test func s20ChangeMidWeekAppliesFromTodayAndPastKeepsItsMarks() throws {
        try train(5, at: Self.at(17, 18))
        for day in 19 ... 21 {
            try train(day - 19, at: Self.at(day, 18))
        }
        let now = Self.at(21, 20)
        try setRest(7, at: now)
        let current = week(now)
        #expect(current[2].state == .done) // Wednesday unchanged
        #expect(titles(current)[3 ... 6].map(\.self) == ["Push B", "Pull B", "rest", "Legs B"])
        // RG7: last week's Sunday (18th) was set to rest on the 12th and keeps its dab.
        let lastWeek = ledger.week(containing: Self.at(18, 12), plan: plan, now: now, sessionsPerWeek: 6,
                                   calendar: calendar)
        #expect(lastWeek[6].state == .past && lastWeek[6].isRest && !lastWeek[6].wasDue)
    }

    @Test func rg7ChangingTheDayNeverTurnsAPastRestSundayIntoARing() throws {
        // Sunday set on the 12th. The 18th (a rest Sunday, nothing trained) is viewed after he moves rest to Friday.
        try setRest(6, at: Self.at(21, 8))
        let now = Self.at(23, 12)
        let lastWeek = ledger.week(containing: Self.at(18, 12), plan: plan, now: now, sessionsPerWeek: 6,
                                   calendar: calendar)
        #expect(lastWeek[6].isRest && !lastWeek[6].wasDue)
        // The Friday it moved to is not rewritten backwards: Friday the 16th was never a rest weekday.
        let fridayRest = lastWeek[4].isRest && !lastWeek[4].wasDue
        let plainFriday = ledger.week(containing: Self.at(16, 12), plan: plan, now: now, sessionsPerWeek: 6,
                                      calendar: calendar)[4]
        #expect(fridayRest == (plainFriday.isRest && !plainFriday.wasDue))
        #expect(lastWeek[4].wasDue)
    }

    @Test func s21AnyReturnsTheFloatingRest() throws {
        try train(5, at: Self.at(17, 18))
        for day in 19 ... 21 {
            try train(day - 19, at: Self.at(day, 18))
        }
        let now = Self.at(21, 20)
        try setRest(nil, at: now)
        let floating = week(now)
        // The same week a store that never had a rest day gives.
        let plain = try RestWeekdayTests(rest: nil)
        try plain.train(5, at: Self.at(17, 18))
        for day in 19 ... 21 {
            try plain.train(day - 19, at: Self.at(day, 18))
        }
        #expect(floating.map(\.isRest) == plain.week(now).map(\.isRest))
        #expect(floating.filter { $0.planned != nil }.count == 3 && floating.contains { $0.isRest && $0.day > now })
    }

    @Test func s22FixedDaysIgnoreTheRestWeekday() throws {
        try engine.perform(SetScheduleMode(plan: plan.id, mode: .fixed), by: .user)
        for (index, routine) in routines.enumerated() {
            try engine.perform(SetRoutineWeekdays(routine: routine.id, weekdays: [index + 2]), by: .user)
        }
        try setRest(5, at: Self.at(18, 12)) // Thursday
        let now = Self.at(19, 7)
        let week = week(now)
        #expect(titles(week) == ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B", "rest"])
        #expect(week[3].planned?.title == "Push B" && !week[3].isRest) // Thursday still trains
        #expect(week[6].isRest) // Sunday: unpinned
    }

    // MARK: Travel and DST

    @Test func s23SundayNightInNewYorkIsStillRest() throws {
        let newYork = Self.calendar("America/New_York")
        for day in 19 ... 24 {
            try train(day - 19, at: Self.at(day, 18, zone: "America/New_York"))
        }
        let now = Self.at(25, 23, zone: "America/New_York") // 8 pm PDT
        let found = try #require(rest(now, calendar: newYork))
        #expect(found.next.title == "Push A")
    }

    @Test func s24MondayEarlyInNewYorkIsMondayThere() throws {
        let newYork = Self.calendar("America/New_York")
        for day in 19 ... 24 {
            try train(day - 19, at: Self.at(day, 18, zone: "America/New_York"))
        }
        let now = Self.at(26, 4, 30, zone: "America/New_York") // 1:30 am PDT
        #expect(rest(now, calendar: newYork) == nil)
        #expect(week(now, calendar: newYork)[0].planned?.title == "Push A")
    }

    @Test func s25AHotelGymSundayStaysSunday() throws {
        for day in 19 ... 24 {
            try train(day - 19, at: Self.at(day, 18))
        }
        try train(0, at: Self.at(25, 7, zone: "America/New_York"), zone: "America/New_York")
        let home = Self.at(26, 8)
        let lastWeek = ledger.week(containing: Self.at(25, 12), plan: plan, now: home, sessionsPerWeek: 6,
                                   calendar: calendar)
        #expect(lastWeek[6].state == .done)
        #expect(ledger.nextRoutine(in: plan, now: home, calendar: calendar)?.title == "Pull A")
    }

    @Test func s26TheRepeatedHourOnNovember1IsStillSaturday() throws {
        // Sun 1 Nov 1:30 am PST, the second 1:30: 09:30 UTC.
        let secondOneThirty = Date(timeIntervalSince1970: 1_793_525_400 - 0)
        var utc = DateComponents()
        utc.timeZone = .gmt
        (utc.year, utc.month, utc.day, utc.hour, utc.minute) = (2026, 11, 1, 9, 30)
        let now = Calendar(identifier: .gregorian).date(from: utc) ?? secondOneThirty
        for day in 26 ... 31 {
            try train((day - 26) % 6, at: Self.at(day, 18))
        }
        #expect(calendar.component(.hour, from: now) == 1)
        #expect(rest(now) == nil)
        #expect(ledger.nextRoutine(in: plan, now: now, calendar: calendar)?.title == "Push A")
    }

    @Test func s27TheTwentyFiveHourSundayHasOneRest() throws {
        for day in 26 ... 31 {
            try train((day - 26) % 6, at: Self.at(day, 18))
        }
        let now = Self.at(1, 10, month: 11)
        #expect(calendar.component(.weekday, from: now) == 1)
        let found = try #require(rest(now))
        #expect(found.next.title == "Push A")
    }

    // MARK: Setting it

    @Test(arguments: ["rest day Sunday", "Rest day sunday.", "make Sunday my rest day", "Sunday is my rest day",
                      "my rest day is Sunday", "Sunday, rest day."])
    func rg3SetRestWeekdayIsAGrammarRuleNotATask(phrase: String) {
        let grammar = TessGrammar(store: store, classes: classes)
        let context = TessContext(now: Self.at(16, 20), calendar: calendar)
        guard case let .setRestWeekday(weekday)? = grammar.parse(phrase, context: context) else {
            Issue.record("\(phrase) did not read as SetRestWeekday")
            return
        }
        #expect(weekday == 1)
        #expect(grammar.parse("rest day Saturday", context: context).map { "\($0)" } == "setRestWeekday(weekday: 7)")
        // Not this rule: a task about rest, and a day mark (not built here).
        if case .setRestWeekday? = grammar.parse("rest day today", context: context) {
            Issue.record("today")
        }
        if case .setRestWeekday? = grammar
            .parse("rest up before the race fri", context: context)
        {
            Issue.record("rest")
        }
    }

    @Test func s01AndS03SayingItWritesOneOpWithUndo() async throws {
        let plain = try RestWeekdayTests(rest: nil)
        let tess = TessCaptureEngine(engine: plain.engine)
        let context = TessContext(now: Self.at(16, 20), calendar: plain.calendar, commitImmediately: true)
        let before = plain.engine.history(limit: 100).count
        let capture = await tess.capture("rest day Sunday", context: context)
        #expect(capture.line == "Sunday, rest day.")
        #expect(TessVoice.violations(in: capture.line).isEmpty)
        let record = try #require(capture.records.first)
        #expect(plain.engine.history(limit: 100).count == before + 1 && record.actor == .tess)
        #expect(RestWeekday.current(in: plain.store) == 1)
        // No task was made.
        #expect(try plain.store.objects(of: #require(plain.classes[.task])).isEmpty)
        // S03: UNDO within the window takes it back; the floating rest returns.
        plain.engine.undo(record)
        #expect(RestWeekday.current(in: plain.store) == nil)
    }

    @Test func s02MakeSundayMyRestDayIsTheSameAsS01() async throws {
        let plain = try RestWeekdayTests(rest: nil)
        let tess = TessCaptureEngine(engine: plain.engine)
        let context = TessContext(now: Self.at(16, 20), calendar: plain.calendar, commitImmediately: true)
        let capture = await tess.capture("make Sunday my rest day", context: context)
        #expect(capture.line == "Sunday, rest day." && capture.records.count == 1)
        #expect(RestWeekday.current(in: plain.store) == 1)
    }

    @Test func s17AlreadySundayWritesNothingNew() async throws {
        let tess = TessCaptureEngine(engine: engine)
        let context = TessContext(now: Self.at(25, 9), calendar: calendar, commitImmediately: true)
        let before = engine.history(limit: 200).count
        let capture = await tess.capture("rest day Sunday", context: context)
        #expect(capture.line == "Sunday, rest day." && capture.records.isEmpty)
        #expect(engine.history(limit: 200).count == before)
        #expect(try store.objects(of: #require(classes[.task])).isEmpty)
    }

    /// A throwaway defaults suite, so the once-per-install flag never leaks between tests.
    func fresh() -> UserDefaults {
        UserDefaults(suiteName: "restWeekday.test.\(UUID().uuidString)")!
    }

    @Test func rg7AWeekBeforeTheFirstLaunchWriteHasNoRestWeekday() throws {
        // The first-launch write (old value nil) on Wed 14 Oct, a move to Friday on Wed 21 Oct.
        let plain = try RestWeekdayTests(rest: nil)
        let started = try RestWeekdayTests(rest: nil)
        let settings = SettingsStore(engine: started.engine)
        let first = try #require(settings.writeFirstRestWeekday(defaults: fresh()))
        first.createdAt = Self.at(14, 9)
        try started.setRest(6, at: Self.at(21, 9))
        let now = Self.at(23, 12)
        func marks(_ test: RestWeekdayTests, containing day: Int) -> [[Bool]] {
            test.ledger.week(containing: Self.at(day, 12), plan: test.plan, now: now, sessionsPerWeek: 6,
                             calendar: test.calendar).map { [$0.isRest, $0.wasDue] }
        }
        // A week before the write reads as if there was never a rest weekday.
        #expect(marks(started, containing: 7) == marks(plain, containing: 7))
        // The week after the write has its Sunday dab; the Friday it moved to marks only from the 21st.
        let written = started.ledger.week(containing: Self.at(15, 12), plan: started.plan, now: now,
                                          sessionsPerWeek: 6, calendar: started.calendar)
        #expect(written[6].isRest && !written[6].wasDue)
    }

    @Test func s04TheFirstLaunchWritesSundayOnceWithUndo() throws {
        let plain = try RestWeekdayTests(rest: nil)
        let settings = SettingsStore(engine: plain.engine)
        let before = plain.engine.history(limit: 100).count
        let record = try #require(settings.writeFirstRestWeekday(defaults: fresh()))
        #expect(plain.engine.history(limit: 100).count == before + 1)
        #expect(RestWeekday.current(in: plain.store) == 1 && RestWeekday.receipt(for: 1) == "Sunday, rest day.")
        // Once: a relaunch writes nothing, and neither does one after UNDO (his answer stands) or after "Any".
        #expect(settings.writeFirstRestWeekday(defaults: fresh()) == nil)
        plain.engine.undo(record)
        #expect(RestWeekday.current(in: plain.store) == nil)
        #expect(settings.writeFirstRestWeekday(defaults: fresh()) == nil)
        #expect(plain.engine.history(limit: 100).count == before + 1)
    }

    @Test func theFirstLaunchLeavesAStoredRestDayAlone() throws {
        let settings = SettingsStore(engine: engine) // restWeekday 1 from init
        let other = try RestWeekdayTests(rest: 4)
        #expect(settings.writeFirstRestWeekday(defaults: fresh()) == nil)
        #expect(SettingsStore(engine: other.engine).writeFirstRestWeekday(defaults: fresh()) == nil)
        #expect(RestWeekday.current(in: other.store) == 4)
    }
}

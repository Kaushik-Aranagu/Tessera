import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct ExerciseAndPlansTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.firstWeekday = 2
        return calendar
    }

    /// October 2026 in London; the 15th is a Thursday.
    private func october(_ day: Int, _ hour: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    // MARK: Words

    @Test func musclesReadAsAPhrase() {
        #expect(ExerciseWords.musclePhrase(primary: ["Chest"], secondary: ["Triceps", "Front Delts"])
            == "chest, with triceps and front delts")
        #expect(ExerciseWords.musclePhrase(primary: ["Chest", "Triceps"], secondary: []) == "chest and triceps")
        #expect(ExerciseWords.musclePhrase(primary: [], secondary: []) == nil)
    }

    @Test func pathWordsAndNumbers() {
        #expect(ExerciseWords.plural("Barbell Lift") == "Barbell Lifts")
        #expect(ExerciseWords.plural("Strength Exercises") == "Strength Exercises")
        #expect(ExerciseWords.signed(6.5) == "+6.5")
        #expect(ExerciseWords.signed(-2.5) == "−2.5")
        #expect(ExerciseWords.set(weight: 85, reps: 6) == "85 × 6")
        #expect(ExerciseWords.nextTime(weight: 82.5, reps: 9, then: 85) == "Next time: 82.5 for 9, then 85.")
        #expect(ExerciseWords.nextTime(weight: 40, reps: 8, then: nil) == "Next time: 40 for 8.")
    }

    /// R34 (trip rehearsal): a Pull A set logged Tuesday night in Honolulu reads "Tue 27" at home on Thursday 08:00
    /// PDT, not "Yesterday" (the instant is Wednesday 05:00 PDT, but the set's own day was Tuesday there).
    @Test func aTripSetKeepsTheDayItHadWhereItWasLogged() throws {
        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let set = try #require(pacific.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 5)))
        let now = try #require(pacific.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 8)))
        let honolulu = TimeZone(identifier: "Pacific/Honolulu")
        #expect(ExerciseWords.historyDate(set, now: now, calendar: pacific, zone: honolulu) == "Tue 27")
        #expect(ExerciseWords.historyDate(set, now: now, calendar: pacific) == "Yesterday")
    }

    @Test func historyDatesFollowTheMockup() throws {
        let now = october(15)
        #expect(ExerciseWords.historyDate(october(15, 9), now: now, calendar: calendar) == "Today")
        #expect(ExerciseWords.historyDate(october(12), now: now, calendar: calendar) == "Mon 12")
        #expect(try ExerciseWords.historyDate(#require(calendar.date(byAdding: .day, value: -18, to: now)), now: now,
                                              calendar: calendar) == "Sep 27")
    }

    @Test func trendSpansDatesAndKeepsAFloorOnTheRange() {
        let points = TrendGeometry.points(
            [(october(1), 100), (october(8), 101), (october(15), 100)],
            until: october(15)
        )
        #expect(points.first?.x == 0)
        #expect(points.last?.x == 1)
        #expect(abs((points[1].x) - 0.5) < 0.001)
        // A 1 kg wobble sits in the middle of a 5 kg range, not edge to edge.
        #expect(points.allSatisfy { $0.y > 0.3 && $0.y < 0.7 })
    }

    // MARK: Exercise digest

    @Test func routingSendsOnlyConcreteExercisesToTheExercisePage() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let bench = try #require(model.classDef(.benchPress))
        #expect(ExerciseRouting.isExercise(bench, classes: model.classes))
        #expect(try !ExerciseRouting.isExercise(#require(model.classDef(.barbellLift)), classes: model.classes))
        #expect(try !ExerciseRouting.isExercise(#require(model.classDef(.exercise)), classes: model.classes))
        #expect(try !ExerciseRouting.isExercise(#require(model.classDef(.workout)), classes: model.classes))
        let paused = ClassDef(name: "Paused Bench Press", parent: bench)
        model.context.insert(paused)
        #expect(ExerciseRouting.isExercise(paused, classes: model.classes))
    }

    @Test func digestReadsRecordsHistoryAndPath() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let bench = try #require(model.classDef(.benchPress))
        let now = Date.now
        log(model, bench, daysAgo: 7, sets: [(80, 8), (80, 7)], now: now)
        log(model, bench, daysAgo: 3, sets: [(82.5, 7), (80, 8)], now: now)

        let digest = ExerciseDigest(exercise: bench, ledger: model.ledger, store: model.store, now: now)
        // The library moved Bench Press under its movement pattern.
        #expect(digest.path.first?.title == "Exercises")
        #expect(digest.path.last?.title.hasPrefix("Horizontal Push") == true)
        #expect(digest.history.count == 2)
        #expect(digest.history.first?.topSet == "82.5 × 7")
        #expect(digest.history.first?.isRecord == true)
        #expect(digest.history.last?.isRecord == false)
        #expect(digest.bestSet == "82.5 × 7")
        #expect(digest.bestE1RM == 101.8)
        #expect(digest.repMaxes[7] == 82.5)
        #expect(digest.repMaxes[8] == 80)
        #expect(digest.trend?.points.count == 2)
        #expect(digest.trend?.isRise == true)
        // The library's bench runs dp(+2.5, 5, 8): same weight, one more rep up to the top of the range.
        #expect(digest.nextTime == "Next time: 82.5 for 8.")
    }

    private func log(_ model: AppModel, _ exercise: ClassDef, daysAgo: Double, sets: [(Double, Double)], now: Date) {
        let store = model.store
        let date = now.addingTimeInterval(-daysAgo * 86400)
        let workout = store.create(model.classDef(.workout)!, title: "Push Day A")
        try? store.set("startedAt", to: .date(date), on: workout)
        try? store.set("endedAt", to: .date(date.addingTimeInterval(3600)), on: workout)
        let entry = store.create(model.classDef(.exerciseEntry)!, parent: workout)
        try? store.setClassLink("exercise", on: entry, to: exercise)
        for (weight, reps) in sets {
            let set = store.create(model.classDef(.set)!, parent: entry)
            try? store.set("weight", to: .mass(weight), on: set)
            try? store.set("reps", to: .number(reps), on: set)
        }
        try? model.context.save()
    }

    // MARK: Week

    private func session(_ day: Int, _ routine: String) -> TrainedSession {
        TrainedSession(workoutID: UUID(), date: october(day), routine: routine, volume: 5000)
    }

    @Test func weekComesFromCoreAndRollsOnFromToday() throws {
        // Fresh install: his PPL×2, nothing done. Today is Push A and the days after roll on in order.
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        // A pinned Monday, so the test never lands on the Sunday the first launch makes a rest day.
        let now = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 12)))
        let week = PlanData(model: model, plan: nil, now: now).week(now: now)
        let todayIndex = try #require(week.days.firstIndex { $0.state == .today })
        // The first launch writes Sunday as the rest day (Research 146): it has no routine, so the days after skip it.
        #expect(week.days[todayIndex].routine == "Push A")
        let after = week.days[(todayIndex + 1)...].compactMap(\.routine)
        #expect(Array(after) == Array(["Pull A", "Legs A", "Push B", "Pull B", "Legs B", "Push A"].prefix(after.count)))
        #expect(week.days[..<todayIndex].allSatisfy { $0.state == .open }) // past days are never "missed"
        #expect(week.headline == "0 of 6\nsessions")
    }

    @Test func aFinishedWorkoutMarksTodayDoneAndThePlanRollsOn() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let routine = try #require(model.todaysRoutine())
        model.startRoutine(routine)
        let session = try #require(model.session)
        session.logSet()
        session.finish(early: true)
        model.session = nil
        model.touch()
        let now = AppClock.now
        let week = PlanData(model: model, plan: nil, now: now).week(now: now)
        // The plan's day turns at 04:00, so between midnight and 4 AM today is still yesterday's date.
        let tesseraToday = TesseraDay(calendar: .current).day(of: now)
        let today = try #require(week.days.first { Calendar.current.isDate($0.date, inSameDayAs: tesseraToday) })
        #expect(today.state == .done && today.routine == "Push A" && today.workoutID == session.workout.id)
        // The next day with a routine: on a Saturday the day after is the rest day the first launch writes.
        let next = week.days.first { $0.date > today.date && $0.routine != nil }
        if let next {
            #expect(next.state == .planned && next.routine == "Pull A")
        }
        #expect(week.done == 1)
    }

    @Test func rhythmAndMuscleCounts() {
        #expect(PlanRhythm.perWeek(cycleCount: 0) == nil)
        #expect(PlanRhythm.perWeek(cycleCount: 3) == 6)
        #expect(PlanRhythm.perWeek(cycleCount: 6) == 6)
        #expect(PlanRhythm.perMonth(perWeek: 6, days: 31) == 26)
        let row = MuscleSets(id: UUID(), name: "Shoulders", sets: 6.5, range: 8 ... 16, paint: nil)
        #expect(row.count == "6½")
        #expect(MuscleSets(id: UUID(), name: "Chest", sets: 0.5, range: 10 ... 20, paint: nil).count == "½")
        #expect(MuscleSets.scale([row]) == 22)
    }

    // MARK: Month

    @Test func monthStartsOnItsWeekdayAndWeighsVolume() {
        let days = (1 ... 31).map { day in
            PlanMonth.Volume(day: calendar.startOfDay(for: october(day)), sessions: day == 5 ? 1 : 0,
                             relative: day == 5 ? 1.5 : 0)
        }
        let month = PlanMonth.build(days: days, sessions: [session(5, "Legs")], cycle: [], now: october(15),
                                    calendar: calendar)
        // 1 October 2026 is a Thursday: three blanks before it in a Monday-first week.
        #expect(month.cells.prefix(3).allSatisfy { $0.day == nil })
        #expect(month.cells[3].day == 1)
        let fifth = month.cells.first { $0.day == 5 }
        #expect(fifth?.weight == 1 && fifth?.size == 42 && fifth?.paint == .cadmium)
        #expect(month.cells.first { $0.day == 15 }?.isToday == true)
        #expect(month.cells.first { $0.day == 16 }?.isFuture == true)
        #expect(month.done == 1)
    }

    @Test func monthWordsCountNeverMisses() {
        #expect(PlanMonth.headline(done: 10, pendingToday: true, planned: 26) == "Session 11\nof 26")
        #expect(PlanMonth.headline(done: 4, pendingToday: false, planned: nil) == "4 sessions\nthis month")
        #expect(PlanMonth.tessLine(done: 10, lastMonth: 13, leftThisWeek: 3, month: "October", previous: "September")
            == "Three more this week keeps October level with September.")
        #expect(PlanMonth.tessLine(done: 2, lastMonth: 13, leftThisWeek: 3, month: "October", previous: "September")
            == "Eleven more keeps October level with September.")
        #expect(PlanMonth.tessLine(done: 2, lastMonth: 0, leftThisWeek: 3, month: "October", previous: "September")
            == nil)
    }

    @Test func theRoutineLibraryIsGroupedByMovementPattern() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let groups = ExerciseLibraryList.groups(model)
        #expect(groups.count >= 6)
        let push = try #require(groups.first { $0.pattern.name == "Horizontal Push" })
        #expect(push.exercises.contains { $0.name == "Bench Press" })
        #expect(groups.allSatisfy { !$0.exercises.isEmpty })
    }

    // MARK: The climb

    @Test func theClimbRunsOldestFirstWithTheBestAsTheRing() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let bench = try #require(model.classDef(.benchPress))
        let now = Date.now
        log(model, bench, daysAgo: 7, sets: [(80, 8), (80, 7)], now: now)
        log(model, bench, daysAgo: 3, sets: [(82.5, 7), (80, 8)], now: now)
        log(model, bench, daysAgo: 1, sets: [(77.5, 8)], now: now)

        let digest = ExerciseDigest(exercise: bench, ledger: model.ledger, store: model.store, now: now)
        #expect(digest.climb.map(\.weight) == [80, 82.5, 77.5])
        #expect(digest.climb.map(\.isBest) == [false, true, false])
        #expect(digest.climb.map(\.setText) == ["80 × 8", "82.5 × 7", "77.5 × 8"])
        #expect(digest.sessionCount == 3)
        #expect(digest.aboutOneRep == 101.8)
        #expect(digest.subtitle?.hasSuffix("Best 82.5 × 7") == true)
    }

    @Test func theClimbShowsTheLastTwelveSessions() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let bench = try #require(model.classDef(.benchPress))
        let now = Date.now
        for day in 1 ... 15 {
            log(model, bench, daysAgo: Double(day), sets: [(60 + Double(day), 8)], now: now)
        }
        let digest = ExerciseDigest(exercise: bench, ledger: model.ledger, store: model.store, now: now)
        #expect(digest.sessionCount == 15)
        #expect(digest.climb.count == ClimbSession.limit)
        #expect(digest.climb.first?.weight == 72, "the twelfth most recent is 12 days ago")
        #expect(digest.climb.last?.weight == 61, "and the newest is yesterday")
    }

    @Test func theAxisRoundsOutToFiveKiloLinesAndNeverGoesFlat() throws {
        let axis = try #require(ClimbAxis(weights: [77.5, 82.5, 80]))
        #expect(axis.low == 75)
        #expect(axis.high == 85)
        #expect(axis.gridlines == [75, 80, 85])
        #expect(axis.unit(80) == 0.5)
        let flat = try #require(ClimbAxis(weights: [80, 80]))
        #expect(flat.high - flat.low == 10, "a flat climb still has room to move")
        #expect(ClimbAxis(weights: [0, 0]) == nil, "bodyweight work has no weight to climb")
        #expect(ClimbAxis(weights: []) == nil)
    }
}

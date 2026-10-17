import Foundation
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct HomeDataTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.firstWeekday = 2
        return calendar
    }

    /// Thursday 15 October 2026 at the given time, London.
    private func thursday(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 15 + dayOffset, hour: hour, minute: minute))!
    }

    // MARK: Day strip geometry

    @Test func timelineMapsTheWakingDay() {
        let timeline = DayTimeline(calendar: calendar)
        #expect(timeline.fraction(of: thursday(7)) == 0)
        #expect(timeline.fraction(of: thursday(15)) == 0.5)
        #expect(timeline.fraction(of: thursday(23)) == 1)
        #expect(timeline.fraction(of: thursday(5)) == 0) // clamped before 07
        #expect(timeline.fraction(of: thursday(23, 30)) == 1) // clamped after 23
    }

    @Test func blocksAreClippedToTheStrip() throws {
        let timeline = DayTimeline(calendar: calendar)
        let morning = try #require(timeline.span(start: thursday(9), end: thursday(11)))
        #expect(morning == 0.125 ... 0.25)

        // Starts before 07: only the visible part remains.
        let early = try #require(timeline.span(start: thursday(6), end: thursday(8)))
        #expect(early == 0 ... 0.0625)

        // Runs past midnight: cut at the end of the strip.
        let late = try #require(timeline.span(start: thursday(22), end: thursday(0, 30, dayOffset: 1)))
        #expect(late.lowerBound == 0.9375 && late.upperBound == 1)

        // Wholly outside 07–23.
        #expect(timeline.span(start: thursday(5), end: thursday(6)) == nil)
        #expect(timeline.span(start: thursday(23, 15), end: thursday(23, 45)) == nil)
    }

    @Test func paintedReachFollowsTheDay() {
        let timeline = DayTimeline(calendar: calendar)
        #expect(timeline.painted(dayOffset: -1, now: thursday(15)) == 1)
        #expect(timeline.painted(dayOffset: 0, now: thursday(15)) == 0.5)
        #expect(timeline.painted(dayOffset: 1, now: thursday(15)) == 0)
    }

    @Test func dayLanePhrasesReadLikeSpeech() {
        let today = DayLane(offset: 0, date: thursday(15, 26), items: [])
        #expect(today.phrase(now: thursday(15, 26), calendar: calendar).hasSuffix(" afternoon"))
        let yesterday = DayLane(offset: -1, date: thursday(15, dayOffset: -1), items: [])
        #expect(yesterday.phrase(now: thursday(15), calendar: calendar).hasSuffix(", done"))
        let item = ScheduleItem(id: UUID(), title: "Dentist", start: thursday(9, dayOffset: 1),
                                end: thursday(10, dayOffset: 1), isDone: false, isWorkout: false)
        let tomorrow = DayLane(offset: 1, date: thursday(15, dayOffset: 1), items: [item, item, item])
        #expect(tomorrow.phrase(now: thursday(15), calendar: calendar).hasSuffix(", three planned"))
    }

    // MARK: Spoken time

    @Test func clockTimesAreSpoken() {
        #expect(SpokenTime.clock(thursday(15, 40), calendar: calendar) == "twenty to four")
        #expect(SpokenTime.clock(thursday(18), calendar: calendar) == "six")
        #expect(SpokenTime.clock(thursday(17, 30), calendar: calendar) == "half past five")
        #expect(SpokenTime.clock(thursday(8, 15), calendar: calendar) == "quarter past eight")
        #expect(SpokenTime.clock(thursday(11, 45), calendar: calendar) == "quarter to noon")
        #expect(SpokenTime.clock(thursday(15, 17), calendar: calendar) == "seventeen minutes past three")
        #expect(SpokenTime.clock(thursday(15, 58), calendar: calendar) == "two minutes to four")
        #expect(SpokenTime.when(thursday(18), now: thursday(15), calendar: calendar) == "this evening, six")
        #expect(SpokenTime.when(thursday(7, 30, dayOffset: 1), now: thursday(15), calendar: calendar)
            == "tomorrow, half past seven")
    }

    @Test func nowLineAndTimeLeft() {
        let task = ScheduleItem(id: UUID(), title: "Groceries", start: thursday(15), end: thursday(15, 40),
                                isDone: false, isWorkout: false)
        #expect(NowPage.contextLine(task, now: thursday(15, 26)).hasPrefix("now, until "))
        #expect(NowPage.timeLeft(task, now: thursday(15, 26)) == ("14 MIN", "LEFT"))
        #expect(NowPage.timeLeft(task, now: thursday(14, 35)) == ("IN", "25 MIN"))
        #expect(NowPage.contextLine(task, now: thursday(14, 35)).hasPrefix("next, "))
    }

    /// Copy rule: never "at" before a time.
    @Test func timeCopyHasNoAtBeforeAClock() {
        let task = ScheduleItem(id: UUID(), title: "Groceries", start: thursday(15), end: thursday(15, 40),
                                isDone: false, isWorkout: false)
        let lines = [
            NowPage.contextLine(task, now: thursday(14, 35)),
            SpokenTime.when(thursday(18), now: thursday(15), calendar: calendar),
            SpokenTime.when(thursday(7, 30, dayOffset: 1), now: thursday(15), calendar: calendar),
            SpokenTime.when(thursday(9, dayOffset: 3), now: thursday(15), calendar: calendar),
        ]
        for line in lines {
            #expect(!line.contains(" at "), "\(line)")
            #expect(line.range(of: #"\bat \d"#, options: .regularExpression) == nil, "\(line)")
        }
    }

    // MARK: Week consistency

    @Test func lastSevenDaysEndOnToday() {
        let days = WeekReview.lastDays(endingAt: thursday(20), calendar: calendar)
        #expect(days.count == 7)
        #expect(days.last == calendar.startOfDay(for: thursday(20)))
        #expect(days.first == calendar.startOfDay(for: thursday(20, dayOffset: -6)))
    }

    @Test func trainedDaysMarkTheDabs() {
        let days = WeekReview.lastDays(endingAt: thursday(20), calendar: calendar)
        let dates = [
            thursday(18, dayOffset: -3), // Monday
            thursday(7, dayOffset: -3), // Monday again: still one day
            thursday(19, dayOffset: -1), // Wednesday
            thursday(18, dayOffset: -9), // outside
        ]
        let trained = WeekReview.trainedDays(dates, on: days, calendar: calendar)
        #expect(trained == [false, false, false, true, false, true, false])
    }

    @Test func consistencyCountsDistinctDaysNotStreaks() {
        let now = thursday(20)
        let dates = [
            thursday(8), // today
            thursday(18, dayOffset: -1),
            thursday(9, dayOffset: -1), // same day twice
            thursday(18, dayOffset: -6), // 7th day back: counts
            thursday(18, dayOffset: -7), // 8th day back: doesn't
            thursday(8, dayOffset: 1), // tomorrow: doesn't
        ]
        let count = WeekReview.daysTrained(dates, endingAt: now, calendar: calendar)
        #expect(count == 3)
        #expect(WeekReview.consistencyLine(count) == "Done 3 of the last 7 days")
        let all = WeekReview.headline(sessions: 6, perWeek: 6, firstWeek: false, firstUseToday: false)
        #expect("\(all.lead) \(all.tail)" == "All six sessions in")
        let four = WeekReview.headline(sessions: 4, perWeek: 6, firstWeek: false, firstUseToday: false)
        #expect("\(four.lead) \(four.tail)" == "Four sessions this week")
        let one = WeekReview.headline(sessions: 1, perWeek: 6, firstWeek: true, firstUseToday: false)
        #expect("\(one.lead) \(one.tail)" == "One session in your first week")
        let quiet = WeekReview.headline(sessions: 0, perWeek: 6, firstWeek: false, firstUseToday: false)
        #expect("\(quiet.lead) \(quiet.tail)" == "A quiet week so far")
        let start = WeekReview.headline(sessions: 0, perWeek: 6, firstWeek: true, firstUseToday: true)
        #expect("\(start.lead) \(start.tail)" == "Your first week starts today")
        #expect(WeekReview.sessionLine(sessions: 4, perWeek: 6) == "4 of 6 sessions this week")
    }

    // MARK: Model-backed helpers

    @Test func setsPerMuscleWalkWorkoutsEntriesAndClasses() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        // Demo history: Push Day A three days ago with 4 bench sets and 3 overhead press sets. Primary muscles come
        // from Core's library: bench is chest, overhead press is front delts.
        let now = AppClock.now
        let window = DateInterval(start: now.addingTimeInterval(-4 * 86400), end: now.addingTimeInterval(-2 * 86400))
        let volume = MuscleVolume.compute(model, in: window)
        let trained = volume.filter { $0.sets > 0 }
        let sets = Dictionary(uniqueKeysWithValues: trained.map { ($0.muscle.title, $0.sets) })
        #expect(sets == ["Chest": 4, "Front Delts": 3])
        #expect(volume.first?.sets == 4)
        #expect(WeekReview.tessLine(trained) == "Front delts: 3 sets this week, toward a usual 10.")
        #expect(WeekReview.tessLine([]) == nil)

        // A subclass without its own profile inherits its parent's muscles.
        let bench = try #require(model.classDef(.benchPress))
        let paused = ClassDef(name: "Paused Bench Press", parent: bench)
        model.context.insert(paused)
        #expect(Set(MuscleVolume.muscles(of: paused, model: model).map(\.title)) == ["Chest"])
    }

    @Test func upcomingSkipsTheHeroAndFinishedItems() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let now = AppClock.now
        let current = try #require(model.currentTask(around: now))
        let upcoming = HomeData.upcoming(model.schedule(around: now), excluding: current, now: now)
        #expect(!upcoming.contains { $0.id == current.id })
        #expect(upcoming.allSatisfy { !$0.isDone })
        #expect(upcoming.map(\.title) == [
            "Push Day A", "Stretch & mobility", "Read Designing Data-Intensive Applications",
        ])

        model.finish(taskID: current.id)
        #expect(model.currentTask(around: now)?.id != current.id)
    }

    @Test func lanesHoldOnlyTheirOwnDay() {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let now = AppClock.now
        let lanes = HomeData.lanes(model, now: now)
        #expect(lanes.map(\.offset) == [-1, 0, 1])
        // His day runs to 04:00: a lane holds the items whose own day is the lane's day.
        let tesseraDay = TesseraDay()
        for lane in lanes {
            #expect(lane.items.allSatisfy { tesseraDay.day(of: $0.start) == lane.date })
        }
        #expect(lanes[1].items.count == model.schedule(around: now)
            .count(where: { tesseraDay.isSameDay($0.start, now) }))
    }

    @Test func trainingTargetsReadLikeTheMockup() {
        #expect(TrainingPage.target(sets: 4, reps: 8) == "4 × 8")
        #expect(TrainingPage.target(sets: 4, reps: 8, weight: 82.5) == "4 × 8 · 82.5")
    }

    @Test func nowDrainsFromFullToEmptyAcrossTheItem() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = start.addingTimeInterval(3600)
        #expect(DrainBar.remaining(start: start, end: end, now: start.addingTimeInterval(-60)) == 1)
        #expect(DrainBar.remaining(start: start, end: end, now: start.addingTimeInterval(900)) == 0.75)
        #expect(DrainBar.remaining(start: start, end: end, now: end.addingTimeInterval(60)) == 0)
    }

    /// His day runs to 04:00 (Research, home-lines-day-one.md): at 00:40 Sunday the day word is still Saturday's.
    @Test func dayLabelKeepsTheDayUntilFour() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        // Sunday 18 Oct 2026, 00:40.
        let late = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 18,
            hour: 0,
            minute: 40
        )))
        #expect(DayLabel.words(now: late, calendar: calendar).hasPrefix("Saturday"))
        let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 9)))
        #expect(DayLabel.words(now: morning, calendar: calendar).hasPrefix("Sunday"))
    }
}

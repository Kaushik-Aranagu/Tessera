import Foundation
@testable import Tessera
@testable import TesseraCore
import Testing

/// The trip week (docs/research/fixtures/trip-week.md, board 0ae): Mon Oct 26 red-eye LAX to JFK, back Wed Oct 28,
/// clocks fall back Sun Nov 1. Review's bands count each task done and each cook on his day where it happened, by the
/// 04:00 boundary in that zone, whichever zone the phone is in when he opens Review.
@MainActor
struct ReviewTripWeekTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!
    static let newYork = TimeZone(identifier: "America/New_York")!
    static let utc = TimeZone(identifier: "UTC")!

    /// Gregorian, Monday first, in the zone given (never `.current`).
    static func calendar(_ zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        calendar.firstWeekday = 2
        return calendar
    }

    /// A wall-clock moment in 2026 in the zone given (October unless said).
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10, in zone: TimeZone = la) -> Date {
        calendar(zone).date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    // The opens (TW18 to TW21), each with the phone's zone then.
    static let tuesdayInNewYork = (now: at(27, 7, in: newYork), calendar: calendar(newYork)) // TW18
    static let wednesdayInNewYork = (now: at(28, 7, in: newYork), calendar: calendar(newYork)) // TW19
    static let thursdayAtHome = (now: at(29, 8), calendar: calendar(la)) // TW20
    /// Sun Nov 1, 9:00 am PST (17:00 UTC), after fall back.
    static let sundayAtHome = (now: at(1, 17, month: 11, in: utc), calendar: calendar(la)) // TW21

    /// One app on an in-memory store, with the starter plan made Thu Oct 1, 9:00 am PDT (first use before the week).
    static func makeModel() -> AppModel {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        model.store.object(id: StarterContent.planID)?.createdAt = at(1, 9)
        return model
    }

    /// Performs as of `time` in `zone`: the record and the object it makes are dated then. `unzoned` strips the zone
    /// from the record, like a row from before v3.
    @discardableResult
    static func run<A: EngineAction>(_ model: AppModel, _ action: A, at time: Date, zone: TimeZone,
                                     unzoned: Bool = false) throws -> A.Output
    {
        model.engine.zone = { zone }
        let result = try model.engine.perform(action, by: .user)
        result.record.createdAt = time
        if unzoned {
            result.record.zone = nil
        }
        if let object = result.output as? ObjectRecord {
            object.createdAt = time
        }
        return result.output
    }

    /// TW1 to TW17, each written only if it happened by `open` (Review is opened mid-trip, so later things do not
    /// exist yet). `unzoned` names the events whose records carry no zone.
    static func writeTrip(_ model: AppModel, through open: Date, unzoned: Set<String> = []) throws {
        let plan = try #require(model.plan)
        let routines = model.store.linkedObjects("routines", of: plan)
        func routine(_ title: String) throws -> ObjectRecord {
            try #require(routines.first { model.store.displayTitle(of: $0) == title })
        }
        func task(_ id: String, _ title: String, made: Date? = nil, done: Date, zone: TimeZone) throws {
            guard done <= open else { return }
            let bare = unzoned.contains(id)
            let task = try run(model, CreateTask(title: title), at: made ?? done, zone: zone, unzoned: bare)
            try run(model, SetTaskDone(task: task.id, time: done), at: done, zone: zone, unzoned: bare)
        }
        func workout(_ title: String, start: Date, end: Date, zone: TimeZone) throws {
            guard end <= open else { return }
            let workout = try run(model, StartRoutine(routine: routine(title).id, time: start), at: start, zone: zone)
            let entry = try #require(workout.orderedChildren.first)
            let set = start.addingTimeInterval(600)
            try run(model, LogSet(entry: entry.id, weight: 60, reps: 8, time: set), at: set, zone: zone)
            try run(model, FinishWorkout(workout: workout.id, time: end), at: end, zone: zone)
        }
        func cook(_ text: String, start: Date, startZone: TimeZone, end: Date, endZone: TimeZone) throws {
            guard end <= open else { return }
            let recipe = try model.engine.perform(CreateRecipe(text: text), by: .system).output
            let cook = try run(model, StartCooking(recipe: recipe.id, time: start), at: start, zone: startZone)
            try run(model, FinishCooking(cook: cook.id, time: end), at: end, zone: endZone)
        }
        func note(_ body: String, at time: Date, zone: TimeZone) throws {
            guard time <= open else { return }
            try run(model, CreateNote(body: body), at: time, zone: zone)
        }
        let la = Self.la, newYork = Self.newYork

        try task("TW1", "print boarding pass", made: at(25, 20), done: at(26, 2), zone: la)
        try task("TW2", "water the plants", done: at(26, 7, 30), zone: la)
        try workout("Push A", start: at(26, 17, 30), end: at(26, 18, 32), zone: la)
        try cook(oats, start: at(26, 21), startZone: la, end: at(27, 6, 55, in: newYork), endZone: newYork)
        // In flight the phone keeps the zone it took off in.
        try task("TW5", "expense report", done: at(27, 1, 20), zone: la)
        try note("slept two hours", at: at(27, 1, 30), zone: la)
        try task("TW7", "call mom", done: at(27, 12, 5, in: newYork), zone: newYork)
        try note("dinner was great", at: at(27, 20, 10, in: newYork), zone: newYork)
        try task("TW9", "send invoice", done: at(27, 23, 30, in: newYork), zone: newYork)
        try workout("Pull A", start: at(28, 5, 40, in: newYork), end: at(28, 6, 30, in: newYork), zone: newYork)
        try task("TW11", "pack", done: at(28, 6, 45, in: newYork), zone: newYork)
        try task("TW12", "check out", done: at(28, 10, 50, in: newYork), zone: newYork)
        try task("TW13", "unpack", done: at(29, 2), zone: la)
        try workout("Legs A", start: at(29, 17, 30), end: at(29, 18, 25), zone: la)
        try cook(tacos, start: at(29, 19), startZone: la, end: at(29, 19, 40), endZone: la)
        // The two 1:30 ams of Sun Nov 1: 8:30 UTC (PDT) and 9:30 UTC (PST).
        try note("can't sleep", at: at(1, 8, 30, month: 11, in: utc), zone: la)
        try task("TW17", "set the clocks", done: at(1, 9, 30, month: 11, in: utc), zone: la)
    }

    static let oats = "overnight oats\nIngredients\n1 cup oats\n1 cup milk\nMethod\n1. Soak overnight."
    static let tacos = "tacos\nIngredients\n4 tortillas\n200 g beans\nMethod\n1. Warm and fill."

    /// The week as Review reads it at an open, with the trip written up to then.
    static func week(at open: (now: Date, calendar: Calendar), unzoned: Set<String> = []) throws -> ReviewWeekData {
        let model = makeModel()
        try writeTrip(model, through: open.now, unzoned: unzoned)
        if !unzoned.isEmpty {
            // The zones already read kept the stripped records' zones; read the log again, as a fresh launch would.
            model.store.invalidateCaches()
        }
        return ReviewWeekData.compute(model, now: open.now, calendar: open.calendar)
    }

    // MARK: - Tasks done

    @Test func inFlightDoneCountsOnMondayInNewYork() throws {
        // TW5 at TW18: done at 4:20 am EDT in flight, still 1:20 am Monday on the phone's LA clock (R12).
        let week = try Self.week(at: Self.tuesdayInNewYork)
        #expect(week.tasksDone[0] == 2)
        #expect(week.tasksDone[1] == 0)
    }

    @Test func twoAmBoardingPassStaysOnSundayInNewYork() throws {
        // TW1 at TW18: 2:00 am at home is last Sunday's, even though it is 5:00 am Monday in New York.
        let week = try Self.week(at: Self.tuesdayInNewYork)
        #expect(week.tasksDone.compactMap(\.self).reduce(0, +) == 2)
    }

    @Test func newYorkWednesdayCountsTwoTwoOne() throws {
        // TW19.
        let week = try Self.week(at: Self.wednesdayInNewYork)
        #expect(week.tasksDone == [2, 2, 1, nil, nil, nil, nil])
    }

    @Test func lateNightNewYorkDoneStaysTuesdayInBothZones() throws {
        // TW9: 11:30 pm Tuesday in New York is 8:30 pm Tuesday at home; a UTC key would move it to Wednesday.
        let away = try Self.week(at: Self.wednesdayInNewYork)
        let home = try Self.week(at: Self.thursdayAtHome)
        #expect(away.tasksDone[1] == 2 && home.tasksDone[1] == 2)
    }

    @Test func hotelPackCountsOnWednesdayAtHome() throws {
        // TW11 at TW20: 6:45 am Wednesday in New York, 3:45 am at home.
        let week = try Self.week(at: Self.thursdayAtHome)
        #expect(week.tasksDone == [2, 2, 3, 0, nil, nil, nil])
    }

    @Test func twoAmUnpackAtHomeBelongsToWednesday() throws {
        // TW13 at TW20: 2:00 am Thursday at home is still Wednesday's.
        let week = try Self.week(at: Self.thursdayAtHome)
        #expect(week.tasksDone[2] == 3)
        #expect(week.tasksDone[3] == 0)
    }

    // MARK: - Cooks

    @Test func oatsCookFinishedAfterLandingIsTuesdayInNewYork() throws {
        // TW4 at TW18: finished 6:55 am in New York.
        let week = try Self.week(at: Self.tuesdayInNewYork)
        #expect(week.cooked[1] == 1)
    }

    @Test func oatsCookFinishedAfterLandingIsTuesdayAtHome() throws {
        // TW4 at TW20: the finish's zone files it, so 3:55 am at home is still Tuesday's, not Monday's.
        let week = try Self.week(at: Self.thursdayAtHome)
        #expect(week.cooked[0] == 0)
        #expect(week.cooked[1] == 1)
    }

    // MARK: - Fall back

    @Test func fallBackNightDoneBelongsToSaturday() throws {
        // TW17 at TW21: the second 1:30 am of the 25-hour Sunday is before 4:00 am, so Saturday's.
        let week = try Self.week(at: Self.sundayAtHome)
        #expect(week.tasksDone[5] == 1)
        #expect(week.tasksDone[6] == 0)
    }

    @Test func sundayAfterTheTripCountsTheWholeWeek() throws {
        // TW21.
        let week = try Self.week(at: Self.sundayAtHome)
        #expect(week.tasksDone == [2, 2, 3, 0, 0, 1, 0])
        #expect(week.cooked == [0, 1, 0, 1, 0, 0, 0])
    }

    // MARK: - Guards

    @Test func trainingBandUnchangedByTheFix() throws {
        // TW18 to TW21: Push A Mon, Pull A Wed (in New York), Legs A Thu; "1/2/2/3 of 6".
        let opens = [Self.tuesdayInNewYork, Self.wednesdayInNewYork, Self.thursdayAtHome, Self.sundayAtHome]
        let expected: [(sessions: Int, trainedDays: [Int])] = [(1, [0]), (2, [0, 2]), (2, [0, 2]), (3, [0, 2, 3])]
        for (open, want) in zip(opens, expected) {
            let week = try Self.week(at: open)
            #expect(week.sessionCount == want.sessions)
            #expect(week.trainingFigure == "\(want.sessions) of 6")
            let trained = week.marks.indices.filter {
                if case .trained = week.marks[$0] {
                    true
                } else {
                    false
                }
            }
            #expect(trained == want.trainedDays)
            #expect(week.sessions.indices.filter { !week.sessions[$0].isEmpty } == want.trainedDays)
        }
    }

    @Test func taskAndCookBandsMatchWeekFactsInEveryZone() throws {
        // Each open: the bands' per-day counts are WeekFacts' days.
        for open in [Self.tuesdayInNewYork, Self.wednesdayInNewYork, Self.thursdayAtHome, Self.sundayAtHome] {
            let model = Self.makeModel()
            try Self.writeTrip(model, through: open.now)
            let week = ReviewWeekData.compute(model, now: open.now, calendar: open.calendar)
            let facts = WeekFactsBuilder(engine: model.engine, calendar: open.calendar)
                .facts(weekContaining: open.now, plan: model.plan, now: open.now)
            for (index, day) in week.days.enumerated() {
                guard let tasks = week.tasksDone[index], let cooked = week.cooked[index] else { continue }
                let factDay = try #require(facts.days.first { $0.date == day })
                #expect(tasks == factDay.tasksDone)
                #expect(cooked == factDay.cooked.count)
            }
        }
    }

    @Test func rowsWithoutAZoneReadInThePhonesZone() throws {
        // TW11 with no stored zone, read at home: 3:45 am Pacific, so Tuesday's (the fallback, as old history reads).
        let week = try Self.week(at: Self.thursdayAtHome, unzoned: ["TW11"])
        #expect(week.tasksDone == [2, 3, 2, 0, nil, nil, nil])
    }
}

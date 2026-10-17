import Foundation
@testable import TesseraCore
import Testing

/// Board 0ae, Research `fixtures/trip-week.md`: every thing in the trip week files under the day where he was when
/// it happened (the 04:00 boundary in its own zone), whichever zone he reads it in. One case per fixture row, each
/// read in Pacific and in Eastern, so a fix keyed by UTC or by the phone's zone fails.
enum TripFixture {
    static let la = TimeZone(identifier: "America/Los_Angeles")!
    static let newYork = TimeZone(identifier: "America/New_York")!
    static let utc = TimeZone(identifier: "UTC")!

    static func calendar(_ zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        calendar.firstWeekday = 2
        return calendar
    }

    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10, in zone: TimeZone = la) -> Date {
        calendar(zone).date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    enum Kind { case task, cook, workout, note }

    struct Row: CustomTestStringConvertible {
        let id: String
        let kind: Kind
        let start: Date
        let end: Date
        let startZone: TimeZone
        let endZone: TimeZone
        /// The October day (31 or less) it belongs to.
        let belongsTo: Int
        var testDescription: String {
            id
        }

        init(_ id: String, _ kind: Kind, start: Date, end: Date? = nil, zone: TimeZone = TripFixture.la,
             endZone: TimeZone? = nil, belongsTo: Int)
        {
            self.id = id
            self.kind = kind
            self.start = start
            self.end = end ?? start
            startZone = zone
            self.endZone = endZone ?? zone
            self.belongsTo = belongsTo
        }
    }

    static let rows: [Row] = [
        Row("TW1", .task, start: at(26, 2), belongsTo: 25),
        Row("TW2", .task, start: at(26, 7, 30), belongsTo: 26),
        Row("TW3", .workout, start: at(26, 17, 30), end: at(26, 18, 32), belongsTo: 26),
        Row("TW4", .cook, start: at(26, 21), end: at(27, 6, 55, in: newYork), endZone: newYork, belongsTo: 27),
        Row("TW5", .task, start: at(27, 1, 20), belongsTo: 26),
        Row("TW6", .note, start: at(27, 1, 30), belongsTo: 26),
        Row("TW7", .task, start: at(27, 12, 5, in: newYork), zone: newYork, belongsTo: 27),
        Row("TW8", .note, start: at(27, 20, 10, in: newYork), zone: newYork, belongsTo: 27),
        Row("TW9", .task, start: at(27, 23, 30, in: newYork), zone: newYork, belongsTo: 27),
        Row("TW10", .workout, start: at(28, 5, 40, in: newYork), end: at(28, 6, 30, in: newYork), zone: newYork,
            belongsTo: 28),
        Row("TW11", .task, start: at(28, 6, 45, in: newYork), zone: newYork, belongsTo: 28),
        Row("TW12", .task, start: at(28, 10, 50, in: newYork), zone: newYork, belongsTo: 28),
        Row("TW13", .task, start: at(29, 2), belongsTo: 28),
        Row("TW14", .workout, start: at(29, 17, 30), end: at(29, 18, 25), belongsTo: 29),
        Row("TW15", .cook, start: at(29, 19), end: at(29, 19, 40), belongsTo: 29),
        // The two 1:30 ams of Sun Nov 1 are 8:30 UTC (PDT) and 9:30 UTC (PST); both are still Saturday.
        Row("TW16", .note, start: at(1, 8, 30, month: 11, in: utc), belongsTo: 31),
        Row("TW17", .task, start: at(1, 9, 30, month: 11, in: utc), belongsTo: 31),
    ]
}

@MainActor
struct TripWeekBandsTests {
    typealias Row = TripFixture.Row
    static let la = TripFixture.la, newYork = TripFixture.newYork, utc = TripFixture.utc
    static func calendar(_ zone: TimeZone) -> Calendar {
        TripFixture.calendar(zone)
    }

    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10, in zone: TimeZone = la) -> Date {
        TripFixture.at(day, hour, minute, month: month, in: zone)
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
    }

    @discardableResult
    func run<A: EngineAction>(_ action: A, at time: Date, zone: TimeZone) throws -> A.Output {
        engine.zone = { zone }
        let result = try engine.perform(action, by: .user)
        result.record.createdAt = time
        if let object = result.output as? ObjectRecord {
            object.createdAt = time
        }
        return result.output
    }

    /// Writes the row as the fixture says; returns the object that files.
    func write(_ row: Row) throws -> ObjectRecord {
        switch row.kind {
        case .task:
            let task = try run(CreateTask(title: row.id), at: row.start.addingTimeInterval(-3600), zone: row.startZone)
            try run(SetTaskDone(task: task.id, time: row.start), at: row.start, zone: row.startZone)
            return task
        case .cook:
            // A different text per cook: the same paste twice is one recipe (G59).
            let recipe = try engine.perform(
                CreateRecipe(text: "oats\nIngredients\n1 cup oats\nMethod\n1. Soak (\(row.start))."),
                by: .system
            ).output
            let cook = try run(StartCooking(recipe: recipe.id, time: row.start), at: row.start, zone: row.startZone)
            try run(FinishCooking(cook: cook.id, time: row.end), at: row.end, zone: row.endZone)
            return cook
        case .workout:
            let plan = try #require(store.object(id: StarterContent.planID))
            let routine = try #require(store.linkedObjects("routines", of: plan).first)
            let workout = try run(StartRoutine(routine: routine.id, time: row.start), at: row.start,
                                  zone: row.startZone)
            let entry = try #require(workout.orderedChildren.first)
            let set = row.start.addingTimeInterval(600)
            try run(LogSet(entry: entry.id, weight: 60, reps: 8, time: set), at: set, zone: row.startZone)
            try run(FinishWorkout(workout: workout.id, time: row.end), at: row.end, zone: row.endZone)
            return workout
        case .note:
            return try run(CreateNote(body: "trip \(row.id)"), at: row.start, zone: row.startZone)
        }
    }

    @Test(arguments: TripFixture.rows) func everyRowFilesOnItsOwnDayInEitherZone(_ row: Row) throws {
        let object = try write(row)
        let reading = Self.at(row.belongsTo + 1, 12)
        for zone in [Self.la, Self.newYork] {
            let calendar = Self.calendar(zone)
            let day = TesseraDay(calendar: calendar)
            let expected = day.day(of: Self.at(row.belongsTo, 12, in: zone))
            let builder = WeekFactsBuilder(engine: engine, calendar: calendar)
            let name = "\(row.id) read in \(zone.identifier)"
            switch row.kind {
            case .task:
                #expect(builder.tasksDoneByDay() == [expected: 1], "\(name)")
            case .cook:
                #expect(builder.cooksByDay().keys.map(\.self) == [expected], "\(name)")
                let lines = DayStory.lines(
                    engine: engine,
                    on: Self.at(row.belongsTo, 12, in: zone),
                    calendar: calendar,
                    now: reading
                )
                #expect(lines.contains { $0.objectIDs == [object.id] }, "\(name): Day log")
            case .workout:
                let ledger = TrainingLedger(store: store, classes: classes)
                #expect(ledger.finishedWorkouts(onDay: expected, calendar: calendar).count == 1, "\(name)")
            case .note:
                let lines = DayStory.lines(
                    engine: engine,
                    on: Self.at(row.belongsTo, 12, in: zone),
                    calendar: calendar,
                    now: reading
                )
                #expect(lines.contains { $0.objectIDs.contains(object.id) }, "\(name)")
            }
        }
    }

    @Test func theWholeWeekCountsTheSameAtHomeAndAway() throws {
        // TW18 to TW21: the whole trip's tasks and cooks, read in New York and at home, count the same: Sun 25 one
        // (TW1), Mon two (TW2, TW5), Tue two (TW7, TW9), Wed three (TW11 to TW13), Sat one (TW17).
        for row in TripFixture.rows where row.kind == .task || row.kind == .cook {
            _ = try write(row)
        }
        let expectedTasks: [Int: Int] = [25: 1, 26: 2, 27: 2, 28: 3, 31: 1]
        for zone in [Self.la, Self.newYork] {
            let calendar = Self.calendar(zone)
            let day = TesseraDay(calendar: calendar)
            let builder = WeekFactsBuilder(engine: engine, calendar: calendar)
            let done = builder.tasksDoneByDay()
            for (date, count) in expectedTasks {
                #expect(done[day.day(of: Self.at(date, 12, in: zone))] == count, "Oct \(date) in \(zone.identifier)")
            }
            #expect(done.values.reduce(0, +) == 9)
            let cooks = builder.cooksByDay()
            #expect(cooks[day.day(of: Self.at(27, 12, in: zone))]?.count == 1)
            #expect(cooks[day.day(of: Self.at(29, 12, in: zone))]?.count == 1)
            #expect(cooks[day.day(of: Self.at(26, 12, in: zone))] == nil)
        }
    }

    @Test func homeCountsACookOnTheDayItWasFinishedWhereItWasFinished() throws {
        // G3: a cook finished in flight at 1:20 am Pacific is Monday's. In New York, once landed (7:00 am EDT Tue),
        // Home must not offer it as done today; at home on Monday it is still today's at 2 am.
        let recipe = try engine.perform(CreateRecipe(text: "oats\nIngredients\n1 cup oats\nMethod\n1. Soak."),
                                        by: .system).output
        let start = Self.at(27, 0, 30)
        let finish = Self.at(27, 1, 20)
        let cook = try run(StartCooking(recipe: recipe.id, time: start), at: start, zone: Self.la)
        try run(FinishCooking(cook: cook.id, time: finish), at: finish, zone: Self.la)

        let newYork = HomeFacts(engine: engine, calendar: Self.calendar(Self.newYork))
        #expect(newYork.cooksFinished(on: Self.at(27, 7, in: Self.newYork)).isEmpty)
        let home = HomeFacts(engine: engine, calendar: Self.calendar(Self.la))
        #expect(home.cooksFinished(on: Self.at(27, 2)).map(\.id) == [cook.id])
        #expect(home.cooksFinished(on: Self.at(27, 12)).isEmpty)
    }
}

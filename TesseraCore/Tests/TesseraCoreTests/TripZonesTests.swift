import Foundation
@testable import TesseraCore
import Testing

/// Research 127, the Oct 26 trip: every record carries the zone it was written in, and the day buckets read it, so a
/// hotel-gym Wednesday stays Wednesday once he is home, and the turnover runs once on a 27-hour day.
@MainActor
struct TripZonesTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!
    static let newYork = TimeZone(identifier: "America/New_York")!

    static func calendar(_ zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    /// A wall-clock moment, October 2026, in the zone given.
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0, in zone: TimeZone = la) -> Date {
        calendar(zone).date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
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
    func run<A: EngineAction>(_ action: A, at time: Date, zone: TimeZone) throws -> ActionEngine.Result<A.Output> {
        engine.zone = { zone }
        let result = try engine.perform(action, by: .user)
        result.record.createdAt = time
        if let object = result.output as? ObjectRecord {
            object.createdAt = time
        }
        return result
    }

    @Test func aHotelGymWednesdayStaysWednesdayAtHome() throws {
        // T1: 06:30 Wednesday in New York is 03:30 Wednesday in Los Angeles, which his 04:00 rule would call Tuesday.
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let start = Self.at(21, 6, 30, in: Self.newYork)
        let workout = try run(StartRoutine(routine: routine.id, time: start), at: start, zone: Self.newYork).output
        let entry = try #require(workout.orderedChildren.first)
        try run(LogSet(entry: entry.id, weight: 60, reps: 5, time: start.addingTimeInterval(300)),
                at: start.addingTimeInterval(300), zone: Self.newYork)
        try run(FinishWorkout(workout: workout.id, time: start.addingTimeInterval(3600)),
                at: start.addingTimeInterval(3600), zone: Self.newYork)

        let home = Self.calendar(Self.la)
        let ledger = TrainingLedger(store: store, classes: classes)
        let wednesday = TesseraDay(calendar: home).day(of: Self.at(21, 12))
        let tuesday = TesseraDay(calendar: home).day(of: Self.at(20, 12))
        #expect(ledger.finishedWorkouts(onDay: wednesday, calendar: home).count == 1)
        #expect(ledger.finishedWorkouts(onDay: tuesday, calendar: home).isEmpty)
        // So Wednesday night at home, Home does not offer the next routine as if he had not trained.
        let week = ledger.week(containing: Self.at(21, 21, 30), plan: plan, now: Self.at(21, 21, 30), calendar: home)
        #expect(week.first { $0.state == .done }?.done.first?.id == workout.id)
        #expect(OpZones(store: store).zone(of: workout.id)?.identifier == "America/New_York")
    }

    @Test func tasksAndCooksFileWhereTheyHappened() throws {
        // T2: a task done and a cook finished at 06:30 Wednesday in New York are Wednesday's when read at home.
        let when = Self.at(21, 6, 30, in: Self.newYork)
        let task = try run(CreateTask(title: "call the hotel"), at: when, zone: Self.newYork).output
        try run(SetTaskDone(task: task.id, time: when), at: when, zone: Self.newYork)
        let recipe = try run(CreateRecipe(text: RecipeParserTests.carbonara), at: when, zone: Self.newYork).output
        let cook = try run(StartCooking(recipe: recipe.id, time: when), at: when, zone: Self.newYork).output
        try run(FinishCooking(cook: cook.id, time: when.addingTimeInterval(1800)), at: when.addingTimeInterval(1800),
                zone: Self.newYork)

        let home = Self.calendar(Self.la)
        let facts = WeekFactsBuilder(engine: engine, calendar: home)
            .facts(weekContaining: Self.at(21, 21), plan: nil, now: Self.at(21, 21))
        let wednesday = try #require(facts.days.first { $0.weekday == 4 })
        let tuesday = try #require(facts.days.first { $0.weekday == 3 })
        #expect(wednesday.tasksDone == 1 && wednesday.cooked.count == 1)
        #expect(tuesday.tasksDone == 0 && tuesday.cooked.isEmpty)
        // Tasks.today reads the same way: on Wednesday at home the done task is today's.
        let today = TaskList(store: store, classes: classes).today(Self.at(21, 21), calendar: home)
        #expect(today.contains { $0.id == task.id && $0.isDone })
        #expect(!TaskList(store: store, classes: classes).today(Self.at(20, 21), calendar: home)
            .contains { $0.id == task.id })
    }

    @Test func theTurnoverRunsOnceOnATravelDay() throws {
        // T3: flying west makes a 27-hour Wednesday; the midnight moves with the zone, the day does not.
        let memory = TessMemoryStore(engine: engine, calendar: Self.calendar(Self.newYork), forgetLogURL: nil)
        try run(CreateTask(title: "pack"), at: Self.at(20, 9, in: Self.newYork), zone: Self.newYork)
        let first = memory.turnover(now: Self.at(21, 5, in: Self.newYork))
        #expect(first.wroteRecent && memory.lines(of: .recent).count == 1)
        // Landed: the same Wednesday, read in Los Angeles, after its 04:00 there.
        let home = TessMemoryStore(engine: engine, calendar: Self.calendar(Self.la), forgetLogURL: nil)
        let again = home.turnover(now: Self.at(21, 5, in: Self.la))
        #expect(!again.wroteRecent && home.lines(of: .recent).count == 1)
        #expect(home.lines(of: .recent).first?.text.hasPrefix("Tue:") == true)
    }
}

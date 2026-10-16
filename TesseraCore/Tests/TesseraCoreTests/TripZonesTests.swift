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

    @Test func aCookFilesOnTheDayItWasFinished() throws {
        // Product G2 (trip-week TW4): oats started Monday 9:00 pm at home, finished Tuesday 6:55 am in New York. The
        // Day log line goes on Tuesday, read in the finish's zone, and keeps its start time and its length.
        let recipe = try engine.perform(
            CreateRecipe(text: "overnight oats\nIngredients\n1 cup oats\n1 cup milk\nMethod\n1. Soak overnight."),
            by: .system
        ).output
        let start = Self.at(26, 21)
        let finish = Self.at(27, 6, 55, in: Self.newYork)
        let cook = try run(StartCooking(recipe: recipe.id, time: start), at: start, zone: Self.la).output
        try run(FinishCooking(cook: cook.id, time: finish), at: finish, zone: Self.newYork)

        for zone in [Self.la, Self.newYork] {
            let calendar = Self.calendar(zone)
            let monday = DayStory.lines(engine: engine, on: Self.at(26, 12, in: zone), calendar: calendar,
                                        now: Self.at(29, 12))
            let tuesday = DayStory.lines(engine: engine, on: Self.at(27, 12, in: zone), calendar: calendar,
                                         now: Self.at(29, 12))
            #expect(!monday.contains { $0.objectIDs == [cook.id] })
            let line = try #require(tuesday.first { $0.objectIDs == [cook.id] })
            #expect(line.text.hasPrefix("Cooked ") && line.text.hasSuffix(", 415 min"))
            #expect(line.time == start)
        }
    }

    @Test func opZonesReadsOnlyWhatIsNew() throws {
        // QA S1 on #377: the op log only grows, so each read walks the new records, never the whole log again.
        for index in 0 ..< 20 {
            try run(CreateTask(title: "task \(index)"), at: Self.at(12, 9), zone: Self.la)
        }
        _ = OpZones(store: store)
        let afterFirst = OpZones.recordsRead(in: store)
        #expect(afterFirst == store.context.operations.count)
        try run(CreateTask(title: "one more"), at: Self.at(12, 10), zone: Self.newYork)
        let zones = OpZones(store: store)
        #expect(OpZones.recordsRead(in: store) == afterFirst + 1)
        let newest = try #require(store.context.operations.values.max { $0.createdAt < $1.createdAt }?.objectIDs.first)
        #expect(zones.zone(of: newest)?.identifier == "America/New_York")
        // Reading twice at one revision costs nothing.
        _ = OpZones(store: store)
        #expect(OpZones.recordsRead(in: store) == afterFirst + 1)
    }

    @Test func zonesDoNotDependOnReadOrder() {
        // QA F1 on #399: a start in New York, a logExercise from Los Angeles, two finishes; read both ways, the same.
        let id = UUID()
        let base = Self.at(21, 6)
        let records: [(Int, TimeZone, Date)] = [
            (0, Self.la, base.addingTimeInterval(-60)), (2, Self.newYork, base),
            (2, Self.la, base.addingTimeInterval(600)), (1, Self.newYork, base.addingTimeInterval(3600)),
            (1, Self.la, base.addingTimeInterval(7200)),
        ]
        var forward = OpZonesState(), backward = OpZonesState()
        for (rank, zone, at) in records {
            forward.set(zone, for: id, rank: rank, at: at)
        }
        for (rank, zone, at) in records.reversed() {
            backward.set(zone, for: id, rank: rank, at: at)
        }
        #expect(forward.zones[id] == backward.zones[id] && forward.zones[id] == Self.newYork) // the earliest start
        var finishes = OpZonesState(), finishesBack = OpZonesState()
        for (rank, zone, at) in records where rank == 1 {
            finishes.set(zone, for: id, rank: rank, at: at)
        }
        for (rank, zone, at) in records.reversed() where rank == 1 {
            finishesBack.set(zone, for: id, rank: rank, at: at)
        }
        #expect(finishes.zones[id] == Self.la && finishesBack.zones[id] == Self.la) // the latest finish
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

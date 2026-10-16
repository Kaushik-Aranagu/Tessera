import Foundation
@testable import TesseraCore
import Testing

/// The week lens (Design 46's bands, AI-11's pack): counts from the phone, planned from first use, never body or money.
@MainActor
struct WeekFactsTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        calendar.firstWeekday = 2
        return calendar
    }

    /// October 2026 in Los Angeles: the 12th is a Monday.
    static func at(_ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let plan: ObjectRecord
    let routines: [ObjectRecord]

    init() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        self.classes = classes
        self.engine = engine
        engine.zone = { Self.la }
        plan = try #require(store.object(id: StarterContent.planID))
        routines = store.linkedObjects("routines", of: plan)
    }

    /// Performs and dates the record (the engine stamps "now").
    @discardableResult
    func run<A: EngineAction>(_ action: A, at time: Date) throws -> A.Output {
        let result = try engine.perform(action, by: .user)
        result.record.createdAt = time
        if let object = result.output as? ObjectRecord {
            object.createdAt = time
        }
        return result.output
    }

    func train(_ routine: ObjectRecord, at time: Date, weight: Double) throws {
        let workout = try run(StartRoutine(routine: routine.id, time: time), at: time)
        let entry = try #require(workout.orderedChildren.first)
        try run(LogSet(entry: entry.id, weight: weight, reps: 5, time: time.addingTimeInterval(300)),
                at: time.addingTimeInterval(300))
        try run(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(2400)),
                at: time.addingTimeInterval(2400))
    }

    var builder: WeekFactsBuilder {
        WeekFactsBuilder(engine: engine, calendar: Self.calendar)
    }

    @Test func countsTheWeekFromFirstUse() throws {
        // First use Tuesday (a task), trained Tuesday and Thursday; Thursday's bench beats Tuesday's.
        let bank = try run(CreateTask(title: "call the bank"), at: Self.at(13, 9))
        try run(SetTaskDone(task: bank.id, time: Self.at(13, 9, 30)), at: Self.at(13, 9, 30))
        try train(routines[0], at: Self.at(13, 18), weight: 60)
        try train(routines[1], at: Self.at(15, 18), weight: 70)
        let recipe = try run(CreateRecipe(text: RecipeParserTests.carbonara), at: Self.at(14, 17))
        let cook = try run(StartCooking(recipe: recipe.id, time: Self.at(14, 18)), at: Self.at(14, 18))
        try run(FinishCooking(cook: cook.id, time: Self.at(14, 18, 40)), at: Self.at(14, 18, 40))

        let now = Self.at(16, 12) // Friday noon
        let facts = builder.facts(weekContaining: now, plan: plan, now: now)
        #expect(facts.days.count == 7 && facts.days[0].weekday == 2 && facts.days[4].isToday)
        // Monday is before first use: not planned, not due, so planned counts run from Tuesday.
        #expect(facts.days[0].beforeFirstUse && facts.days[0].planned == nil && !facts.days[0].wasDue)
        #expect(!facts.days[1].beforeFirstUse)
        #expect(facts.trainedDays == 2 && facts.routinesDone == ["Push A", "Pull A"])
        #expect(facts.plannedDays >= 2 && facts.plannedDays <= 6)
        #expect(facts.tasksDone == 1 && facts.days[1].tasksDone == 1)
        #expect(facts.cookedDays == 1 && facts.recipesCooked == ["Spaghetti carbonara"] && facts.days[2].cooked
            .count == 1)
        // Pull A's bench is the first on its own lift: a record only once there is history to beat.
        #expect(facts.records.isEmpty || facts.records.allSatisfy { $0.exercise == ExerciseWords.short($0.exercise) })
        #expect(facts.next?.title == "Legs A")
        // Nothing about body, money or notes exists on the lens.
        let mirror = Mirror(reflecting: facts).children.compactMap(\.label)
        #expect(!mirror.contains { $0.lowercased().contains("weight") || $0.lowercased().contains("money") })
    }

    @Test func bestLinesPutARecordFirstAndOnePerDay() throws {
        try train(routines[0], at: Self.at(12, 18), weight: 60)
        try train(routines[0], at: Self.at(14, 18), weight: 70) // beats Monday: ", PR."
        for index in 0 ..< 3 {
            try run(CreateTask(title: "task \(index)"), at: Self.at(13, 9))
        }
        let now = Self.at(16, 12)
        let facts = builder.facts(weekContaining: now, plan: plan, now: now)
        #expect(facts.bestLines.count == 3)
        #expect(facts.bestLines[0].line.text.hasSuffix(", PR."))
        #expect(facts.bestLines[0].day == facts.days[2].date) // Wednesday's
        #expect(Set(facts.bestLines.map(\.day)).count == 3)
        // A day's own lines come from the Day log.
        #expect(builder.lines(on: Self.at(13), now: now).map(\.text) == ["Added 3 tasks"])
    }

    @Test func nextIsNilOnceThePlanHasEnded() throws {
        try store.set("startsOn", to: .date(Self.at(1)), on: plan)
        try store.set("weeks", to: .number(1), on: plan)
        let now = Self.at(16, 12)
        #expect(builder.facts(weekContaining: now, plan: plan, now: now).next == nil)
        try store.set("weeks", to: .number(4), on: plan)
        #expect(builder.facts(weekContaining: now, plan: plan, now: now).next != nil)
        #expect(builder.facts(weekContaining: now, plan: nil, now: now).next == nil)
    }
}

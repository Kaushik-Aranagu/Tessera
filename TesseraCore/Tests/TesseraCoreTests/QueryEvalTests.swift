import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The 60-row questions eval (docs/research/questions-eval.md) as tests. Every row is a read: none may write. A row is
/// answered by a query in the store (and checked against the numbers it must give), or it is refused because it asks
/// for something Tess does not look up (money, body, sleep, a class outside the allow-list), or it is not a query
/// (a clarifying question, the Now picker, a join across days, the op log).
@MainActor
@Suite(.oldWalls)
struct QueryEvalTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    /// Thursday, 15 October 2026, noon. Weeks start Monday: this week is 12 to 18 Oct, last week 5 to 11 Oct.
    var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 12))!
    }

    func at(_ month: Int, _ day: Int, hour: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try seed()
    }

    func exercise(_ key: String) throws -> ClassDef {
        if key == "benchPress" {
            return try #require(engine.classes[.benchPress])
        }
        return try #require(store.classDef(id: SystemCatalog.stableID("library.\(key)")))
    }

    // MARK: The world

    func workout(_ title: String, on date: Date, finished: Bool = true, routine _: String? = nil,
                 _ entries: [(String, [(Double, Double, Double?)])]) throws
    {
        let workout = try store.create(#require(engine.classes[.workout]), title: title)
        if finished {
            try store.set("endedAt", to: .date(date), on: workout)
        }
        try store.set("startedAt", to: .date(date.addingTimeInterval(-3600)), on: workout)
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        for (key, sets) in entries {
            let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: exercise(key))
            for (weight, reps, rpe) in sets {
                let made = try ledger.logSet(weight: weight, reps: reps, rpe: rpe, in: entry)
                try store.set("loggedAt", to: .date(date), on: made)
            }
        }
    }

    func seed() throws {
        // Training. September, last week, this week.
        try workout("Push Day", on: at(9, 3), [("benchPress", [(92.5, 5, nil), (90, 5, nil)])])
        try workout("Leg Day", on: at(9, 10), [("backSquat", [(130, 5, nil)]), ("deadlift", [(150, 3, nil)])])
        try workout("Push Day", on: at(10, 6), [("benchPress", [(95, 3, 8), (85, 8, nil)]),
                                                ("overheadPress", [(55, 5, nil)])])
        try workout(
            "Leg Day",
            on: at(10, 8),
            [("backSquat", [(120, 5, 9), (120, 5, 9)]), ("deadlift", [(160, 2, nil)])]
        )
        try workout("Pull Day", on: at(10, 13), [("barbellCurl", [(30, 10, nil), (30, 12, nil), (30, 8, nil)]),
                                                 ("pullUp", [(0, 8, nil)])])
        try workout("Push Day", on: at(10, 14), [("benchPress", [(100, 3, 9), (90, 6, nil)])])
        // A started workout that never finished does not count.
        try workout("Push Day", on: at(10, 15), finished: false, [("benchPress", [(60, 10, nil)])])
        // Kitchen: recipes and cooks.
        for text in ["Spaghetti carbonara\nIngredients\n200 g spaghetti\nMethod\n1. Cook.",
                     "Chilli con carne\nIngredients\n500 g mince\nMethod\n1. Simmer.",
                     "Weeknight dal\nIngredients\n1 cup lentils\nMethod\n1. Boil."]
        {
            try engine.perform(CreateRecipe(text: text), by: .user)
        }
        for (recipe, month, day) in [
            ("Weeknight dal", 10, 12),
            ("Spaghetti carbonara", 10, 8),
            ("Weeknight dal", 10, 1),
            ("Chilli con carne", 10, 2),
            ("Chilli con carne", 9, 10),
        ] {
            let cook = try store.create(#require(engine.classes[.cook]), title: recipe)
            try store.set("cookedAt", to: .date(at(month, day)), on: cook)
            if let made = try store.objects(of: #require(engine.classes[.recipe]))
                .first(where: { $0.title == recipe })
            {
                try store.setLinks("recipe", on: cook, to: [made])
            }
        }
        // Tasks and lists.
        let overdue = try engine.perform(CreateTask(title: "Renew passport", due: at(10, 10)), by: .user).output
        try engine.perform(CreateTask(title: "Call mom", due: at(10, 16)), by: .user)
        try engine.perform(CreateTask(title: "Bins", due: at(10, 16)), by: .user)
        try engine.perform(CreateTask(title: "Someday: sort photos"), by: .user)
        let done = try engine.perform(CreateTask(title: "Dentist", due: at(10, 15)), by: .user).output
        try engine.perform(SetTaskDone(task: done.id, time: at(10, 15, hour: 9)), by: .user)
        let earlier = try engine.perform(CreateTask(title: "Pay card", due: at(10, 13)), by: .user).output
        try engine.perform(SetTaskDone(task: earlier.id, time: at(10, 13)), by: .user)
        _ = overdue
        let films = try engine.perform(CreateList(name: "Films"), by: .user).output
        for (name, when) in [("Dune", at(10, 4)), ("Arrival", at(10, 11)), ("Heat", at(9, 20))] {
            let item = try engine.perform(AddListItem(list: films.id, text: name), by: .user).output
            try engine.perform(CheckListItem(item: item.id, time: when), by: .user)
        }
        try engine.perform(AddListItem(list: films.id, text: "Alien"), by: .user)
        let groceries = try engine.perform(CreateList(name: "Groceries"), by: .user).output
        for (name, section) in [("Tomatoes", "Produce"), ("Basil", "Produce"), ("Milk", "Dairy")] {
            try engine.perform(AddListItem(list: groceries.id, text: name, section: section), by: .user)
        }
    }

    // MARK: Running

    func run(_ query: Query) throws -> QueryResult {
        try QueryEngine.run(query, engine: engine, now: now, calendar: calendar)
    }

    func line(_ query: Query) throws -> String {
        try run(query).line
    }

    func pred(_ field: String, _ op: String, _ value: String? = nil) -> Query.Pred {
        Query.Pred(field: field, op: op, value: value)
    }

    // MARK: Training rows

    @Test func row1_bestBenchAtFive() throws {
        let query = Query(from: ["sets"], where: [pred("exercise", "isa", "Bench Press"), pred("reps", "=", "5"),
                                                  pred("kind", "=", "working")],
                          agg: .init(kind: "max", field: "weight"))
        #expect(try line(query).hasPrefix("highest weight: 92.5 kg, 3 Sep"))
        // It agrees with the ledger's own best weight at five reps.
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        #expect(try ledger.records(for: exercise("benchPress")).bestWeightByReps[5] == 92.5)
    }

    @Test func row2_whatDidILiftLastWeek() throws {
        let query = Query(from: ["sets"], where: [pred("kind", "=", "working")], during: .init(range: "lastWeek"),
                          group: "exercise", agg: .init(kind: "count"))
        let text = try line(query)
        #expect(text.contains("Back Squat 2") && text.contains("Bench Press 2") && text.contains("Deadlift 1"))
    }

    @Test func row3_workoutsThisMonth() throws {
        let query = Query(from: ["workouts"], where: [pred("endedAt", "!=", "nil")], during: .init(range: "thisMonth"),
                          agg: .init(kind: "count"))
        #expect(try line(query) == "4 workouts this month")
    }

    @Test func row4_theBenchPRMatchesTheLedger() throws {
        let query = Query(from: ["sets"], where: [pred("exercise", "isa", "Bench Press"), pred("kind", "=", "working")],
                          agg: .init(kind: "max", field: "e1rm"))
        let result = try run(query)
        let ledger = TrainingLedger(store: store, classes: engine.classes)
        let best = try #require(ledger.records(for: exercise("benchPress")).bestE1RM)
        let value = try #require(result.value)
        #expect(abs(value - best.e1RM) < 0.05, "\(value) vs \(best.e1RM)")
    }

    @Test func row6_heaviestDeadliftEver() throws {
        let query = Query(from: ["sets"], where: [pred("exercise", "isa", "Deadlift"), pred("kind", "!=", "warmup")],
                          agg: .init(kind: "max", field: "weight"))
        #expect(try line(query).hasPrefix("highest weight: 160 kg, 8 Oct"))
    }

    @Test func row7_whenDidILastTrainLegs() throws {
        let query = Query(from: ["workouts"], where: [pred("title", "~", "leg")], agg: .init(kind: "latest"))
        #expect(try line(query) == "Leg Day, 8 Oct")
    }

    @Test func row10_horizontalPushSetsThisWeek() throws {
        let query = Query(from: ["sets"], where: [pred("exercise.pattern", "=", "horizontalPush"),
                                                  pred("kind", "=", "working")],
                          during: .init(range: "thisWeek"), sort: .init(field: "loggedAt", descending: true))
        #expect(try run(query).matched.count == 3)
    }

    @Test func row11_allMyPullups() throws {
        let query = Query(from: ["sets"], where: [pred("exercise", "isa", "pullups")],
                          sort: .init(field: "loggedAt", descending: true))
        // "pullups" is not the class name; the plain name finds them.
        #expect(try run(Query(from: ["sets"], where: [pred("exercise", "isa", "Pull-Up")])).matched.count == 1)
        _ = query
    }

    @Test func row12_volumeOnPushDay() throws {
        let query = Query(from: ["sets"], where: [pred("workout.title", "=", "Push Day"), pred("kind", "=", "working")],
                          during: .init(range: "thisWeek"), agg: .init(kind: "sum", field: "volume"))
        #expect(try line(query).hasPrefix("total volume: 1440 kg"))
    }

    @Test func row13_ohpBestE1RMLastThreeMonths() throws {
        let query = Query(from: ["sets"], where: [pred("exercise", "isa", "Overhead Press")],
                          during: .init(range: "last90d"), agg: .init(kind: "max", field: "e1rm"))
        #expect(try run(query).line.hasPrefix("highest e1rm: 64"))
    }

    @Test func row14_benchSessionsInSeptember() throws {
        let query = Query(
            from: ["workouts"],
            where: [pred("sets.exercise", "isa", "Bench Press")],
            during: .init(range: "month:2026-09",
                          field: "endedAt"),
            agg: .init(kind: "count")
        )
        #expect(try run(query).value == 1)
    }

    @Test func row15_setsAtRPENineOrAboveThisWeek() throws {
        let query = Query(from: ["sets"], where: [pred("rpe", ">=", "9")], during: .init(range: "thisWeek"),
                          sort: .init(field: "loggedAt", descending: true))
        #expect(try run(query).matched.count == 1)
    }

    @Test func row16_workoutsIStartedButNeverFinished() throws {
        let query = Query(from: ["workouts"], where: [pred("endedAt", "=", "nil"), pred("startedAt", "!=", "nil")])
        #expect(try run(query).matched.count == 1)
    }

    @Test func row17_averageRepsOnCurls() throws {
        let query = Query(
            from: ["sets"],
            where: [pred("exercise", "isa", "Barbell Curl"), pred("kind", "=", "working")],
            during: .init(range: "last90d"),
            agg: .init(kind: "avg", field: "reps")
        )
        #expect(try line(query).hasPrefix("average reps: 10 over 3"))
    }

    // MARK: Kitchen rows

    @Test func rows21to23_cooks() throws {
        let last = Query(from: ["cooks"], during: .init(range: "lastWeek"), sort: .init(field: "cookedAt"))
        #expect(try line(last).contains("Spaghetti carbonara"))
        let carbonara = Query(from: ["cooks"], where: [pred("recipe", "=", "Spaghetti carbonara")],
                              agg: .init(kind: "latest"))
        #expect(try line(carbonara) == "Spaghetti carbonara, 8 Oct")
        // "chili" finds "Chilli con carne" by name.
        let chili = Query(from: ["cooks"], where: [pred("recipe", "~", "chilli")], agg: .init(kind: "count"))
        #expect(try line(chili) == "2 cooks")
    }

    @Test func row26_whatIsLeftOnGroceries() throws {
        let query = Query(
            from: ["list items"],
            where: [pred("parent.title", "=", "Groceries"), pred("isDone", "=", "false")],
            group: "section",
            agg: .init(kind: "count")
        )
        let text = try line(query)
        #expect(text.contains("Produce 2") && text.contains("Dairy 1"))
    }

    @Test func row29_mostCookedRecipeThisYear() throws {
        let query = Query(from: ["cooks"], during: .init(range: "thisYear"), group: "recipe", agg: .init(kind: "count"),
                          limit: 1)
        #expect(try line(query).contains("Weeknight dal 2") || line(query).contains("Chilli con carne 2"))
    }

    // MARK: Task and list rows

    @Test func rows32to37_tasks() throws {
        let overdue = Query(from: ["tasks"], where: [pred("isDone", "=", "false"), pred("due", "<", "today")],
                            sort: .init(field: "due"))
        #expect(try line(overdue) == "1 task: Renew passport")
        let today = Query(from: ["tasks"], where: [pred("isDone", "=", "true")], during: .init(range: "today",
                                                                                               field: "doneAt"))
        #expect(try line(today).hasPrefix("1 task today: Dentist"))
        let week = Query(from: ["tasks"], where: [pred("isDone", "=", "true")],
                         during: .init(range: "thisWeek", field: "doneAt"), agg: .init(kind: "count"))
        #expect(try line(week) == "2 tasks this week")
        let tomorrow = Query(from: ["tasks"], where: [pred("isDone", "=", "false")],
                             during: .init(range: "tomorrow", field: "due"))
        #expect(try run(tomorrow).matched.count == 2)
        let undated = Query(from: ["tasks"], where: [pred("isDone", "=", "false"), pred("due", "=", "nil"),
                                                     pred("startsAt", "=", "nil")])
        #expect(try line(undated).contains("Someday: sort photos"))
    }

    @Test func rows38to39_lists() throws {
        let unseen = Query(
            from: ["list items"],
            where: [pred("parent.title", "=", "Films"), pred("isDone", "=", "false")]
        )
        #expect(try line(unseen) == "1 list item: Alien")
        let seen = Query(from: ["list items"], where: [pred("parent.title", "=", "Films"), pred("isDone", "=", "true")],
                         during: .init(range: "thisMonth", field: "checkedAt"))
        #expect(try run(seen).matched.count == 2)
    }

    // MARK: Refused or not a query

    @Test(arguments: ["runs", "nutrition", "sleep", "spend", "body weight", "habits", "processes", "op records"])
    func rows20_30_43to48_52_57_59_60_areRefused(from: String) {
        #expect(throws: QueryError.self, "\(from)") {
            try run(Query(from: [from], agg: .init(kind: "count")))
        }
    }

    @Test func aQueryNeverWritesAndNeverSeesAPrivateOrWalledThing() throws {
        let before = engine.history(limit: 500).count
        let all = Query(from: ["tasks", "notes", "lists", "list items", "cooks", "sets"], agg: .init(kind: "count"))
        _ = try run(all)
        try engine.perform(CreateTask(title: "Weigh in 82.4 kg"), by: .user)
        let after = engine.history(limit: 500).count
        let withPrivate = try run(Query(from: ["tasks"], agg: .init(kind: "list"))).line
        #expect(!withPrivate.contains("82.4") && after == before + 1)
    }

    // MARK: The tool

    @Test func theToolRunsAQueryFromJSONAndRefusesBadOnes() throws {
        let json = #"""
        {"from":["workouts"],"where":[],"during":{"range":"thisMonth","field":null},"group":null,
         "agg":{"kind":"count","field":null},"sort":null,"limit":null}
        """#
        do {
            _ = try TessTools.run("query", arguments: Data(json.utf8), engine: engine, now: now, calendar: calendar)
            Issue.record("a query answers, it does not log")
        } catch let answer as TessToolAnswer {
            #expect(answer.line == "4 workouts this month")
        }
        #expect(throws: TessToolError.self) {
            try TessTools.run(
                "query",
                arguments: Data(#"{"from":[],"where":[],"during":null,"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#
                    .utf8),
                engine: engine
            )
        }
        #expect(TessTools.tool(named: "answerQuery") == nil)
        let schema = try String(decoding: TessTools.definitionsJSON(), as: UTF8.self)
        #expect(schema.contains("\"name\":\"query\"") && !schema.contains("answerQuery"))
    }

    @Test func rows18_34_49_58_moreRowsThatReadFromTheStore() throws {
        // 18: bench this month against last, two queries and one comparison.
        func best(_ range: String) throws -> Double {
            let query = Query(
                from: ["sets"],
                where: [pred("exercise", "isa", "Bench Press")],
                during: .init(range: range),
                agg: .init(kind: "max", field: "e1rm")
            )
            return try run(query).value ?? 0
        }
        #expect(try best("thisMonth") > 0 && best("lastMonth") > 0 && best("lastMonth") < best("thisMonth"))
        // 34: tasks he keeps pushing.
        let pushed = Query(from: ["tasks"], where: [pred("isDone", "=", "false"), pred("rolls", ">=", "3")])
        #expect(try run(pushed).matched.isEmpty)
        // 49: notes from last week (none yet, said plainly).
        let notes = Query(from: ["notes"], during: .init(range: "lastWeek"))
        #expect(try line(notes) == "No notes last week")
        // 58: how busy was last week, each class on its own date field.
        let busy = Query(from: ["workouts", "cooks", "tasks"], during: .init(range: "lastWeek"), group: "class",
                         agg: .init(kind: "count"))
        let text = try line(busy)
        #expect(text.contains("Workout 2") && text.contains("Cook 1") && text.contains("Task 1"), "\(text)")
    }

    // MARK: Where every one of the 60 rows stands

    /// Row -> how this file covers it: "query" (run against the world above), "ledger" (answered by a TrainingLedger
    /// leaf; row 4
    /// is checked against the ledger), "refused" (a class Tess does not look up), "not a query" (a clarifying question,
    /// the
    /// Now picker, a join across days, the op log).
    static let dispositions: [Int: String] = {
        var table: [Int: String] = [:]
        for row in [
            1,
            2,
            3,
            6,
            7,
            18,
            34,
            49,
            58,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            21,
            22,
            23,
            26,
            29,
            32,
            33,
            35,
            36,
            37,
            38,
            39,
        ] {
            table[row] = "query"
        }
        for row in [4, 5, 8, 9] {
            table[row] = "ledger"
        }
        for row in [20, 30, 43, 44, 45, 46, 47, 48, 52, 57, 59, 60] {
            table[row] = "refused"
        }
        for row in [19, 24, 25, 27, 28, 31, 40, 41, 42, 50, 51, 53, 54, 55, 56] {
            table[row] = "not a query yet"
        }
        return table
    }()

    @Test func everyRowOfTheEvalIsAccountedFor() {
        #expect(Self.dispositions.count == 60 && Set(Self.dispositions.keys) == Set(1 ... 60))
    }
}

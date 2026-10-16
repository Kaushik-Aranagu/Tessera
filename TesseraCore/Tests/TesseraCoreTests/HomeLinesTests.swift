import Foundation
@testable import TesseraCore
import Testing

/// The Home lines lens (docs/ai/first-features.md 1a, fixtures H1 to H12; Design 41's slots).
@MainActor
struct HomeLinesTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    /// A wall-clock moment in Los Angeles, Thursday 15 October 2026.
    static func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: hour, minute: minute))!
    }

    func text(_ fact: HomeFact, now: Date = at(21, 40)) -> String {
        HomeLines.line(for: fact, now: now, calendar: Self.calendar).text
    }

    // MARK: The nine rules rows

    @Test func workoutDone() {
        // H1, H11, H12: "{Routine} done." plus the record when there is one.
        let done = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 22, exercisesDone: 6,
                            exercisesPlanned: 6, records: ["Bench"], endedAt: Self.at(20, 5))
        let line = HomeLines.line(for: done, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Push A done. Bench record.")
        #expect(line.hero == "Push A done" && line.context == "done 1 h ago" && line.contextShort == "done 1 h")
        #expect(line.detail == "6 exercises, 22 sets, 1 new best.")
        #expect(line.numbers == [6, 6])
        let plain = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 20, exercisesDone: 6,
                             exercisesPlanned: 6)
        #expect(text(plain) == "Push A done.")
        let two = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 20, exercisesDone: 6,
                           exercisesPlanned: 6, records: ["Bench", "Press"])
        #expect(text(two) == "Push A done. 2 records." && two.numbers == [6, 6, 2])
        #expect(HomeLines.detail(for: two) == "6 exercises, 20 sets, 2 new bests.")
    }

    @Test func workoutDoneWithNothingLogged() {
        // H10: matches ProcessTable's overnight line.
        let empty = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 0, exercisesDone: 0,
                             exercisesPlanned: 6)
        #expect(text(empty) == "Push A, no sets." && HomeLines.hero(for: empty) == "Push A, no sets")
    }

    @Test func workoutRunningAndPaused() {
        // H3, H4: the exercise in focus and the set he is on; weight and reps stay one tap down.
        let running = HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .running, exercise: "Squat", step: 3,
                               exercisesDone: 1, exercisesPlanned: 5, startedAt: Self.at(21, 32))
        let live = HomeLines.line(for: running, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(live.text == "Squat, set 3." && live.hero == "Legs, at squat")
        #expect(live.context == "started 8 min ago" && live.contextShort == "started 8 min")
        #expect(live.numbers == [3])
        let paused = HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, exercise: "Row", step: 2,
                              sets: 5, exercisesDone: 2, exercisesPlanned: 5, startedAt: Self.at(20, 30),
                              lastTouchedAt: Self.at(21, 0))
        let rest = HomeLines.line(for: paused, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(rest.text == "Row paused at set 2." && rest.hero == "Pull B, paused at row")
        #expect(rest.context == "paused 40 min ago" && rest.contextShort == "paused 40 min")
        #expect(rest.detail == "2 exercises, 5 sets.")
        // Paused before any exercise was started: the routine alone.
        let fresh = HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, startedAt: Self.at(21, 39))
        let line = HomeLines.line(for: fresh, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Pull B paused." && line.hero == "Pull B, paused")
        #expect(line.context == "paused 1 min ago" && line.contextShort == "paused 1 min")
        let now = HomeLines.line(for: fresh, now: Self.at(21, 39), calendar: Self.calendar)
        #expect(now.context == "paused just now" && now.contextShort == "paused just now")
    }

    @Test func routinePlannedToday() {
        // H5, H6: "this evening" from 17:00 to 21:00, "today" the rest of his day.
        let legs = HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .planned)
        #expect(text(legs, now: Self.at(18, 10)) == "Legs this evening.")
        #expect(text(legs, now: Self.at(23)) == "Legs today.")
        #expect(text(legs, now: Self.at(9)) == "Legs today.")
        let line = HomeLines.line(for: legs, now: Self.at(18, 10), calendar: Self.calendar)
        #expect(line.hero == "Legs" && line.context == "this evening" && line.detail == nil && line.numbers.isEmpty)
    }

    @Test func restDay() {
        // H7: the existing RestDay line, a stop on the row, none on the hero.
        let rest = HomeFact(id: nil, kind: .rest, title: RestDay.line, state: .planned)
        let line = HomeLines.line(for: rest, now: Self.at(12), calendar: Self.calendar)
        #expect(line.text == "Rest day." && line.hero == "Rest day" && line.context == nil && line.objectID == nil)
    }

    @Test func cookingAndShopping() {
        // H8, H9.
        let chili = HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .paused, step: 3, steps: 8,
                             startedAt: Self.at(19))
        let cook = HomeLines.line(for: chili, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(cook.text == "Chili, on step 3." && cook.hero == "Chili, on step 3" && cook.detail == "Step 3 of 8.")
        #expect(cook.context == "started 2 h ago" && cook.numbers == [3, 8])
        let shop = HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .running, step: 4,
                            startedAt: Self.at(21, 20))
        let line = HomeLines.line(for: shop, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Groceries: 4 left." && line.hero == "Groceries, 4 left" && line.detail == "4 items left.")
        let basket = HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .running, step: 0)
        #expect(text(basket) == "Groceries: all in the basket." && HomeLines
            .detail(for: basket) == "All in the basket.")
        #expect(text(HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .running, step: 1))
            == "Groceries: 1 left.")
    }

    @Test func timedTaskKeepsHisWords() {
        let task = HomeFact(id: UUID(), kind: .task, title: "Call the bank about the card", state: .planned,
                            startsAt: Self.at(18, 30))
        let line = HomeLines.line(for: task, now: Self.at(12), calendar: Self.calendar)
        #expect(line.text == "Call the bank about the card" && line.hero == line.text)
        #expect(line.context == "6:30 pm" && line.detail == nil)
    }

    @Test func rowLinesStayWithinSixWords() {
        let facts = [
            HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 22, exercisesDone: 6,
                     exercisesPlanned: 6, records: ["Bench"]),
            HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 22, records: ["Bench", "Press"]),
            HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, exercise: "Incline", step: 2),
            HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .running, exercise: "Squat", step: 3),
            HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .planned),
            HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .paused, step: 3, steps: 8),
            HomeFact(id: UUID(), kind: .shop, title: "Groceries", state: .running, step: 4),
            HomeFact(id: nil, kind: .rest, title: RestDay.line, state: .planned),
        ]
        for line in HomeLines.lines(for: facts, now: Self.at(18), calendar: Self.calendar) {
            #expect(line.text.split(separator: " ").count <= HomeLines.rowWords, "\(line.text)")
            #expect(!line.text.contains("…") && !line.text.contains("kg") && !line.text.contains("×"))
        }
    }

    @Test func agoWords() {
        #expect(HomeLines.ago(30) == "just now" && HomeLines.ago(21 * 60) == "21 min ago")
        #expect(HomeLines.ago(2 * 3600 + 300) == "2 h ago")
    }

    // MARK: From the store

    @Test func factsFromTheStore() throws {
        // A paused Push A at bench set 2, a cook on step 1, and a shop with 2 left, read as Home would.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let facts = HomeFacts(engine: engine)
        let table = ProcessTable(engine: engine)

        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: push.id), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let running = try #require(table.running())
        try engine.perform(SuspendProcess(process: running.id), by: .user)
        let pausedProcess = try #require(table.process(for: workout))
        let paused = try #require(facts.fact(process: pausedProcess))
        #expect(paused.kind == .workout && paused.state == .paused && paused.step == 2)
        #expect(paused.exercise == ExerciseWords.short(store.linkedClass("exercise", of: entry)?.name ?? ""))
        let line = HomeLines.line(for: paused)
        #expect(line.text == "\(paused.exercise ?? "") paused at set 2." && !line.text.contains("80"))
        #expect(line.objectID == workout.id)

        let recipe = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        let cookProcess = try #require(table.running())
        let cooking = try #require(facts.fact(process: cookProcess))
        #expect(cooking.kind == .cook && cooking.state == .running && cooking.step == 1 && (cooking.steps ?? 0) > 1)
        #expect(HomeLines.line(for: cooking).text == "\(recipe.title), on step 1.")

        try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        try engine.perform(StartShop(), by: .user)
        let shopProcess = try #require(table.running())
        let shop = try #require(facts.fact(process: shopProcess))
        #expect(shop.kind == .shop && shop.step == 2)
        #expect(HomeLines.line(for: shop).text == "Groceries: 2 left.")

        // The planned routine and the rest day.
        let next = try #require(TrainingLedger(store: store, classes: classes).nextRoutine(in: plan))
        #expect(HomeLines.line(for: facts.fact(planned: next), now: Self.at(18), calendar: Self.calendar).text
            == "\(store.displayTitle(of: next)) this evening.")
        #expect(HomeLines.line(for: facts.rest(next: next)).text == "Rest day.")
    }

    @Test func aFinishedWorkoutFromTheStoreNamesItsRecord() throws {
        // Two Push A sessions: the second beats the first on bench, so the line says "Bench record."
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        for (day, weight) in [(1, 60.0), (3, 70.0)] {
            let time = Self.at(18).addingTimeInterval(Double(day) * 86400)
            let workout = try engine.perform(StartRoutine(routine: push.id, time: time), by: .user).output
            let entry = try #require(workout.orderedChildren.first)
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: 5, time: time), by: .user)
            try engine.perform(FinishWorkoutEarly(workout: workout.id, time: time.addingTimeInterval(1800)), by: .user)
        }
        let summaries = ledger.finishedWorkouts(on: Self.at(18).addingTimeInterval(3 * 86400), calendar: Self.calendar)
        let summary = try #require(summaries.first)
        let done = HomeFacts(engine: engine).fact(done: summary)
        let line = HomeLines.line(for: done, now: Self.at(21).addingTimeInterval(3 * 86400), calendar: Self.calendar)
        #expect(line.text == "\(done.title) done. \(done.records[0]) record.")
        #expect(line.context == "done 2 h ago" && line.detail?.hasSuffix("1 set, 1 new best.") == true)
        #expect(!line.text.contains("70"))
    }
}

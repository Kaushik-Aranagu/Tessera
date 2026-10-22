import Foundation
@testable import TesseraCore
import Testing

/// The run-mode control plane: its own rules, and parity with the two runs that exist today (a workout and a cook).
@MainActor
struct RunPlaneTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let store: ObjectStore
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
        try StarterContent.installIfNeeded(store: store, classes: classes)
    }

    func plane(_ specs: [(String, RunStepKind, TimeInterval?)]) -> RunPlane {
        RunPlane(steps: specs.map { RunStep(title: $0.0, kind: $0.1, seconds: $0.2) })
    }

    // MARK: The plane's own rules

    @Test func theFirstStepIsNowAndDoneMovesOnWithOneHaptic() {
        var run = plane([("Water", .check, nil), ("Pills", .check, nil), ("Plan", .check, nil)])
        #expect(run.current?.title == "Water" && run.next?.title == "Pills")
        #expect(run.complete(at: start) == [.stepDone])
        #expect(run.current?.title == "Pills" && run.doneCount == 1)
        run.skip(at: start.addingTimeInterval(5)) // a day mark, no haptic
        #expect(run.current?.title == "Plan" && run.steps[1].state == .skipped && run.doneCount == 1)
        #expect(run.complete(at: start.addingTimeInterval(9)) == [.stepDone])
        #expect(run.isFinished && run.current == nil && run.next == nil && run.activity(at: start) == nil)
        #expect(run.log.map(\.outcome) == [.done, .skipped, .done])
        #expect(run.complete(at: start).isEmpty) // nothing left to do
    }

    @Test func backKeepsEverythingRunningAndComingBackLandsOnTheSameStep() {
        var run = plane([("Stir", .check, nil), ("Simmer", .timed, 600), ("Serve", .check, nil)])
        run.complete(at: start)
        run.startTimer(for: 1, at: start)
        run.back(at: start.addingTimeInterval(30))
        #expect(run.current?.title == "Stir" && run.steps[1].state == .ahead)
        #expect(run.timer(for: run.steps[1].id)?.remaining(at: start.addingTimeInterval(30)) == 570) // not stopped
        #expect(run.log.last?.outcome == .reopened)
        run.go(to: 1, at: start.addingTimeInterval(40))
        #expect(run.current?.title == "Simmer")
        run.go(to: 1, at: start.addingTimeInterval(41)) // already there: nothing changes
        #expect(run.log.count == 2)
        // Back from the first step stays on it.
        var first = plane([("A", .check, nil), ("B", .check, nil)])
        first.back(at: start)
        #expect(first.current?.title == "A")
        // Back after the run is finished reopens the last step.
        var done = plane([("A", .check, nil)])
        done.complete(at: start)
        done.back(at: start)
        #expect(done.current?.title == "A" && !done.isFinished)
    }

    @Test func severalTimersRunAtOnceAndEachEndsOnceWithOneFirmTap() {
        var run = plane([("Pasta", .timed, 600), ("Sauce", .timed, 300), ("Plate", .check, nil)])
        run.startTimer(for: 0, at: start)
        run.startTimer(for: 1, at: start.addingTimeInterval(60))
        run.startTimer(for: 1, at: start.addingTimeInterval(90)) // already running: left alone
        #expect(run.timers.count == 2)
        #expect(run.runningTimers(at: start.addingTimeInterval(100)).map(\.length) == [300, 600])
        #expect(run.tick(at: start.addingTimeInterval(200)).isEmpty)
        #expect(run.tick(at: start.addingTimeInterval(361)) == [.timerEnded]) // sauce
        #expect(run.tick(at: start.addingTimeInterval(362)).isEmpty) // once
        #expect(run.tick(at: start.addingTimeInterval(601)) == [.timerEnded])
        #expect(run.activity(at: start)?.timerEndsAt == nil) // none left counting
        // Finishing a step stops its own timer.
        var timed = plane([("Rest", .timed, 90), ("Next", .check, nil)])
        timed.startTimer(for: 0, at: start)
        timed.complete(at: start.addingTimeInterval(20))
        #expect(timed.timers.isEmpty)
    }

    @Test func pauseFreezesEveryTimerAndResumeContinuesFromWhatWasLeft() {
        var run = plane([("Bake", .timed, 600), ("Rest", .timed, 120), ("Eat", .check, nil)])
        run.startTimer(for: 0, at: start)
        run.startTimer(for: 1, at: start.addingTimeInterval(100))
        run.pause(at: start.addingTimeInterval(200))
        #expect(run.isPaused && run.activity(at: start)?.isPaused == true && run.activity(at: start)?
            .timerEndsAt == nil)
        // An hour later nothing has moved or ended.
        let later = start.addingTimeInterval(3800)
        #expect(run.timers.map { $0.remaining(at: later) } == [400, 20])
        #expect(run.tick(at: later).isEmpty)
        run.resume(at: later)
        #expect(!run.isPaused)
        #expect(run.timers.map { $0.remaining(at: later) } == [400, 20])
        #expect(run.timers.map { $0.remaining(at: later.addingTimeInterval(10)) } == [390, 10])
        #expect(run.tick(at: later.addingTimeInterval(21)) == [.timerEnded])
        // A timer started while paused waits for the resume.
        var waiting = plane([("A", .timed, 60), ("B", .check, nil)])
        waiting.pause(at: start)
        waiting.startTimer(for: 0, at: start.addingTimeInterval(5))
        waiting.resume(at: start.addingTimeInterval(500))
        #expect(waiting.timers.first?.remaining(at: start.addingTimeInterval(500)) == 60)
    }

    @Test func aParallelStepStartsBesideTheNextAndTheRunMovesOn() {
        var run = plane([("Chop", .check, nil), ("Simmer sauce", .parallel, 900), ("Boil pasta", .timed, 600),
                         ("Combine", .check, nil)])
        run.complete(at: start)
        #expect(run.current?.title == "Boil pasta") // the parallel step did not take the screen
        #expect(run.steps[1].state == .done)
        #expect(run.timer(for: run.steps[1].id)?.remaining(at: start) == 900)
        #expect(run.activity(at: start)?.timerEndsAt == start.addingTimeInterval(900))
        #expect(run.log.map(\.outcome) == [.done, .done])
    }

    @Test func theActivityNamesTheStepAndTheSoonestEnd() {
        var run = plane([("Rest", .timed, 90), ("Press", .check, nil)])
        run.startTimer(for: 0, at: start)
        let activity = run.activity(at: start)
        #expect(activity == RunActivity(title: "Rest", number: 1, count: 2,
                                        timerEndsAt: start.addingTimeInterval(90), isPaused: false))
    }

    @Test func aRunSurvivesBeingSavedAndRelaunched() throws {
        var run = plane([("A", .timed, 60), ("B", .check, nil)])
        run.startTimer(for: 0, at: start)
        run.pause(at: start.addingTimeInterval(10))
        let back = try JSONDecoder().decode(RunPlane.self, from: JSONEncoder().encode(run))
        #expect(back == run)
        #expect(back.timers.first?.remaining(at: start.addingTimeInterval(9999)) == 50)
    }

    // MARK: Parity with the workout

    @Test func theWorkoutPlaneIsWhereWorkoutProgressPoints() throws {
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user).output
        let planned = workout.orderedChildren.reduce(0) { $0 + Int(store.number("targetSets", of: $1) ?? 3) }
        var logged = 0
        while true {
            let progress = WorkoutProgress(of: workout, store: store)
            let run = RunPlane(steps: RunSources.workout(workout, store: store))
            #expect(run.steps.count == planned)
            #expect(run.doneCount == logged)
            #expect(run.isFinished == progress.isComplete)
            guard let entry = progress.entry, let name = progress.exerciseName else { break }
            #expect(run.current?.title == "\(name), set \(progress.setIndex + 1)")
            #expect(run.steps.allSatisfy { $0.kind == .counted })
            _ = try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 5,
                                          time: start.addingTimeInterval(Double(logged + 1) * 300)), by: .user)
            logged += 1
        }
        #expect(logged == planned)
    }

    @Test func aWarmupIsReadTheWayWorkoutProgressReadsIt() throws {
        // Parity, quirk included: WorkoutProgress looks at the older isWarmup flag, which a warm-up logged today does
        // not set (it sets kind), so a warm-up moves the next set along there and therefore here. The run plane must
        // not change what the screen shows; whether warm-ups should count is a separate decision.
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        _ = try engine.perform(LogSet(entry: entry.id, weight: 20, reps: 10, isWarmup: true, time: start), by: .user)
        let progress = WorkoutProgress(of: workout, store: store)
        let run = RunPlane(steps: RunSources.workout(workout, store: store))
        #expect(run.current?.title == "\(progress.exerciseName ?? ""), set \(progress.setIndex + 1)")
    }

    // MARK: Parity with the cook

    @Test func theRecipePlaneIsTheRecipesStepsInOrderWithTheirTimers() throws {
        try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user)
        let book = RecipeBook(store: store, classes: classes)
        let recipe = try #require(book.recipes().first)
        let cook = try engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        let recipeSteps = book.steps(of: recipe)
        let steps = RunSources.recipe(cook: cook, store: store, classes: classes)
        #expect(steps.map(\.title) == recipeSteps.map(\.text))
        #expect(steps.map(\.kind) == [.timed, .timed, .check, .check])
        #expect(steps[0].seconds == 600 && steps[1].seconds == 300) // 10 min, and the low end of 5-6
        // Going to a step on the plane lands where the cook's own step goes.
        var run = RunPlane(steps: steps)
        try engine.perform(GoToCookStep(cook: cook.id, step: 2), by: .user)
        run.go(to: 2, at: start)
        let process = try #require(ProcessTable(engine: engine).process(for: cook))
        #expect(process.resumePoint?.index == run.currentIndex)
        #expect(process.nextStep == run.current?.title)
    }

    @Test func aPrivateRecipesStepsCarryNoWordsOnThePlane() throws {
        let recipe = try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\n1. Crush the melatonin.\n2. Bake."),
            by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: start), by: .user).output
        let steps = RunSources.recipe(cook: cook, store: store, classes: classes)
        #expect(steps.count == 2 && steps.allSatisfy { $0.title == "Private recipe" })
    }

    @Test func aPlaneTimerCountsDownLikeTheKitchenTimer() throws {
        let made = try engine.perform(StartKitchenTimer(label: "Pasta", minutes: 10, time: start), by: .user).output
        let kitchen = try #require(CookLog(store: store, classes: classes).timers().first { $0.id == made.id })
        var run = plane([("Pasta", .timed, 600)])
        run.startTimer(for: 0, at: start)
        let timer = try #require(run.timers.first)
        for seconds in [0.0, 1, 90, 599, 600, 1000] {
            let moment = start.addingTimeInterval(seconds)
            #expect(timer.remaining(at: moment) == kitchen.remaining(at: moment), "\(seconds)")
        }
        #expect(timer.endsAt() == kitchen.endsAt)
    }

    // MARK: The default runner and the walls

    @Test func aRoutineWithNoRunnerOfItsOwnGetsChecksAndTimedSteps() {
        let steps = RunSources.routine([("Water", nil), ("Stretch", 120), ("Plan the day", nil)])
        #expect(steps.map(\.kind) == [.check, .timed, .check] && steps[1].seconds == 120)
        #expect(RunPlane(steps: steps).current?.title == "Water")
    }

    @Test func readingRunsWritesNothing() throws {
        try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user)
        let book = RecipeBook(store: store, classes: classes)
        let recipe = try #require(book.recipes().first)
        let cook = try engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        let objects = container.mainContext.all(ObjectRecord.self).count
        let ops = container.mainContext.operations.count
        _ = RunSources.recipe(cook: cook, store: store, classes: classes)
        var run = RunPlane(steps: RunSources.recipe(cook: cook, store: store, classes: classes))
        run.complete(at: start)
        run.pause(at: start)
        #expect(container.mainContext.all(ObjectRecord.self).count == objects)
        #expect(container.mainContext.operations.count == ops)
    }
}

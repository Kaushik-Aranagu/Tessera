@testable import Tessera
import TesseraCore
import Testing

/// G56: while a workout runs, the Cook key says "Workout running.", starts no cook and leaves the workout running.
@MainActor
struct CookWorkoutTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aRunningWorkoutRefusesTheCookWithItsLine() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: "Dal\n1 cup lentils\nSimmer 20 minutes"), by: .user)
            .output
        let workout = try model.store.create(#require(model.classes[.workout]), title: "Push day")
        try model.engine.perform(StartWorkout(workout: workout.id), by: .user)
        let table = ProcessTable(engine: model.engine)

        let line = RecipeCopy.startCook { try model.engine.perform(StartCooking(recipe: recipe.id), by: .user) }
        #expect(line == "Workout running")
        #expect(try model.store.objects(of: #require(model.classes[.cook])).isEmpty)
        #expect(table.running()?.subject?.id == workout.id && table.running()?.state == .running)
    }

    @Test func withNoWorkoutTheCookStartsSilently() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: "Dal\n1 cup lentils\nSimmer 20 minutes"), by: .user)
            .output
        #expect(RecipeCopy.startCook { try model.engine.perform(StartCooking(recipe: recipe.id), by: .user) } == nil)
    }

    @Test func anyOtherRefusalSaysDidntSave() {
        let line = RecipeCopy.startCook { () throws -> Int in
            throw ActionError.invalidArguments(action: "startCooking", reason: "no such recipe")
        }
        #expect(line == "Didn't save that. Try again")
    }

    @Test func resumingASetAsideCookDuringAWorkoutSaysWorkoutRunning() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: "Dal\n1 cup lentils\nSimmer 20 minutes"), by: .user)
            .output
        try model.engine.perform(StartCooking(recipe: recipe.id), by: .user)
        let table = ProcessTable(engine: model.engine)
        let cook = try #require(table.running())
        try model.engine.perform(SuspendProcess(process: cook.id), by: .user)
        let workout = try model.store.create(#require(model.classes[.workout]), title: "Push day")
        try model.engine.perform(StartWorkout(workout: workout.id), by: .user)

        let setAside = try #require(table.all().first { $0.id == cook.id })
        #expect(model.resume(setAside) == "Workout running")
        #expect(table.running()?.subject?.id == workout.id && table.running()?.state == .running)
    }
}

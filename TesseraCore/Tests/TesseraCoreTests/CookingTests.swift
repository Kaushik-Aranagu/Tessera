import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct CookingTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func cookingRunsAsAProcessWithTimers() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let log = CookLog(store: store, classes: classes)
        let table = ProcessTable(engine: engine)
        let recipe = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user).output
        let start = Date.now

        let cook = try engine.perform(StartCooking(recipe: recipe.id, serves: 4, time: start), by: .user).output
        #expect(log.serves(of: cook) == 4)
        let running = try #require(table.running())
        #expect(running.subject?.id == cook.id)
        #expect(running.resumePoint?.index == 0)
        #expect(running.nextStep == "Boil the spaghetti in salted water for 10 minutes.")

        try engine.perform(GoToCookStep(cook: cook.id, step: 1), by: .user)
        #expect(table.running()?.resumePoint?.index == 1)
        #expect(table.running()?.nextStep?.hasPrefix("Fry the guanciale") == true)

        // Two timers at once; Now shows the soonest as its draining bar.
        let pasta = try engine.perform(StartKitchenTimer(label: "Pasta", minutes: 10, cook: cook.id, time: start),
                                       by: .user).output
        _ = try engine.perform(StartKitchenTimer(label: "Guanciale", minutes: 6, cook: cook.id, time: start), by: .user)
        #expect(log.timers().map(\.label) == ["Guanciale", "Pasta"])
        let now = NowPicker(engine: engine).pick(at: start.addingTimeInterval(30)).now
        #expect(now?.object.id == cook.id)
        #expect(now?.endsAt == start.addingTimeInterval(360))
        #expect(now?.nextStep == "Guanciale, 6 min")
        try engine.perform(StopKitchenTimer(timer: pasta.id), by: .user)
        #expect(log.timers().map(\.label) == ["Guanciale"])

        // Finishing stamps the cook, ends the process and stops its timers.
        try engine.perform(FinishCooking(cook: cook.id, note: "Good", time: start.addingTimeInterval(1500)), by: .user)
        #expect(table.running() == nil)
        #expect(log.timers().isEmpty)
        #expect(log.lastCooked(recipe) == start.addingTimeInterval(1500))
        #expect(log
            .finishLine(for: recipe, at: start.addingTimeInterval(1500)) ==
            "Spaghetti carbonara, first time this month.")
        #expect(throws: ActionError.self) {
            try engine.perform(StartKitchenTimer(label: "x", minutes: 0), by: .user)
        }
    }
}

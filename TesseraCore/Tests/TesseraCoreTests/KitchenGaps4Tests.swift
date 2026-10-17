import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kitchen gap hunt 4 (docs/product/kitchen-gap-hunt-4.md): G20 to G23.
@MainActor
struct KitchenGaps4Tests {
    let store = ObjectStore.open(inMemory: true)

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    var context: TessContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return TessContext(now: Date(timeIntervalSince1970: 1_791_986_400), calendar: calendar)
    }

    // MARK: G21

    @Test func aPrivateRecipeReadsPrivateOnTheReceiptTheTaskAndHome() async throws {
        let engine = try engine()
        let tess = TessCaptureEngine(engine: engine)
        let secret = try engine.perform(CreateRecipe(text: "Wifi code lasagna\nIngredients\n2 onions\nMethod\nBake."),
                                        by: .user).output
        let health = try engine.perform(CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\nBake."),
                                        by: .user).output
        let plain = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\nFry."),
                                       by: .user).output
        for recipe in [secret, health] {
            #expect(ObjectPrivacy.label(of: recipe, in: store, classes: engine.classes) == "Private recipe")
        }
        #expect(ObjectPrivacy.label(of: plain, in: store, classes: engine.classes) == nil)

        // Neither the capture line nor a stored title carries the name.
        for phrase in ["cook melatonin lasagna friday 7pm", "cook melatonin lasagna"] {
            let line = await tess.capture(phrase, context: context).line
            #expect(!line.lowercased().contains("lasagna"), "\(line)")
        }
        let titles = TaskList(store: store, classes: engine.classes).all().map(\.task.title)
        #expect(titles.allSatisfy { !$0.lowercased().contains("lasagna") }, "\(titles)")

        let open = await tess.capture("cook tacos friday 7pm", context: context)
        #expect(open.line == "Tacos, Friday 7 pm.", "\(open.line)")

        // Home: planned, running and done all say "Private recipe".
        let facts = HomeFacts(engine: engine)
        let task = try engine.perform(CreateTask(title: "x", startsAt: context.now, about: [health.id]), by: .tess).output
        #expect(facts.fact(plannedCook: task, recipe: health).title == "Private recipe")
        let cook = try engine.perform(StartCooking(recipe: health.id), by: .user).output
        try engine.perform(FinishCooking(cook: cook.id), by: .user)
        let done = try #require(facts.cooksFinished(on: .now).first)
        #expect(HomeLines.line(for: facts.fact(doneCook: done)).text == "Private recipe done.")
    }
}

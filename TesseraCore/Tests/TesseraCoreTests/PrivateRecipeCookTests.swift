import Foundation
@testable import TesseraCore
import Testing

/// G21b: a private recipe's title never reaches an op summary, the cook's own title or the day story.
@MainActor
struct PrivateRecipeCookTests {

    @Test func aPrivateRecipeCooksAsPrivateRecipeEverywhere() throws {
        let host = try TessMemoryTests()
        let thursday = TessMemoryTests.at(15, 18)
        let recipe = try host.run(CreateRecipe(text: "Pie\nIngredients\n1 onion\nMethod\n1. Bake it.",
                                               title: "Password pie"), at: TessMemoryTests.at(1, 9)).output
        let start = try host.run(StartCooking(recipe: recipe.id, time: thursday), at: thursday)
        let cook = start.output
        let finish = try host.run(FinishCooking(cook: cook.id, time: thursday.addingTimeInterval(1800)), at: thursday)
        #expect(start.record.summary == "Cooking Private recipe")
        #expect(finish.record.summary == "Cooked Private recipe")
        #expect(cook.title == "Private recipe")
        // The day story, and the memory's recent line that reads it.
        let lines = DayStory.lines(engine: host.engine, on: TessMemoryTests.at(15), calendar: TessMemoryTests.calendar,
                                   now: TessMemoryTests.at(16, 5))
        #expect(lines.contains { $0.text.hasPrefix("Cooked Private recipe") })
        #expect(!lines.contains { $0.text.contains("Password") })
        host.memory.turnover(now: TessMemoryTests.at(16, 4).addingTimeInterval(1800))
        let recent = host.memory.lines(of: .recent).map(\.text)
        #expect(!recent.isEmpty && recent.allSatisfy { !$0.contains("Password") && !$0.contains("pie") }, "\(recent)")
    }

    @Test func anOlderCookKeepsItsTitleOnlyForAPublicRecipe() throws {
        let host = try TessMemoryTests()
        let thursday = TessMemoryTests.at(15, 18)
        let recipe = try host.run(CreateRecipe(text: "Chili\nIngredients\n1 onion\nMethod\n1. Stir."),
                                  at: TessMemoryTests.at(1, 9)).output
        let start = try host.run(StartCooking(recipe: recipe.id, time: thursday), at: thursday)
        try host.run(FinishCooking(cook: start.output.id, time: thursday.addingTimeInterval(900)), at: thursday)
        #expect(start.record.summary == "Cooking Chili" && start.output.title == "Chili")
        // An old cook made while the recipe was public, the recipe renamed to something private: the story masks it.
        try host.run(RenameObject(object: recipe.id, title: "Password chili"), at: thursday.addingTimeInterval(3600))
        let lines = DayStory.lines(engine: host.engine, on: TessMemoryTests.at(15), calendar: TessMemoryTests.calendar,
                                   now: TessMemoryTests.at(16, 5))
        #expect(lines.contains { $0.text.hasPrefix("Cooked Private recipe") })
        #expect(lines.allSatisfy { !$0.text.contains("Chili") && !$0.text.contains("Password") })
    }
}

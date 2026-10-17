import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Sheet 87's Recipes front as data.
@MainActor
struct RecipesShelfTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel
    let saturday = Date(timeIntervalSince1970: 1_792_000_000)

    init() {
        model = AppModel(context: container.mainContext)
    }

    private var shelf: RecipesShelf {
        RecipesShelf(store: model.store, classes: model.classes, now: saturday.addingTimeInterval(3 * 86400))
    }

    private func recipe(_ title: String) throws -> ObjectRecord {
        try model.engine.perform(CreateRecipe(text: "\(title)\n2 limes\n\nCook it."), by: .user).output
    }

    private func cook(_ recipe: ObjectRecord, at date: Date) throws {
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id, time: date), by: .user).output
        try model.engine.perform(FinishCooking(cook: cook.id, time: date.addingTimeInterval(1800)), by: .user)
    }

    @Test func emptyIsNoneYet() {
        #expect(shelf.context == "None yet" && shelf.rows.isEmpty)
        #expect(shelf.tess == "Paste a link or a page and I'll read it.")
    }

    @Test func aPrivateRecipeIsOnlyPrivateRecipeAndCounted() throws {
        _ = try recipe("Tacos")
        _ = try recipe("Rent 1200 stew")
        #expect(shelf.context == "2 recipes, 1 private")
        #expect(shelf.rows.map(\.name) == ["Private recipe", "Tacos"], "newest first")
        #expect(!shelf.rows.contains { $0.name.contains("1200") })
    }

    @Test func tessLines() throws {
        let tacos = try recipe("Tacos")
        try cook(tacos, at: saturday)
        try cook(tacos, at: saturday.addingTimeInterval(86400))
        #expect(shelf.tess == "Tacos, cooked 2 times.")
        _ = try recipe("Dal")
        #expect(shelf.tess == "Tacos is the one you cook most.")
    }

    @Test func contextCounts() {
        #expect(RecipesShelf.context(count: 1, privateCount: 0) == "1 recipe")
        #expect(RecipesShelf.context(count: 38, privateCount: 2) == "38 recipes, 2 private")
    }

    @Test func tessUsesTheShortNameAndOldDatesCarryTheYear() throws {
        let long = try recipe("Sheet-pan paprika chicken with lemon")
        try cook(long, at: saturday)
        #expect(shelf.tess == "Sheet-pan paprika chicken, cooked 1 time.")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        let lastYear = calendar.date(from: DateComponents(year: 2025, month: 10, day: 3, hour: 12)) ?? .now
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 12)) ?? .now
        #expect(RecipesShelf.day(lastYear, now: now, calendar: calendar) == "Oct 3, 2025")
        let thisYear = calendar.date(from: DateComponents(year: 2026, month: 9, day: 3, hour: 12)) ?? .now
        #expect(RecipesShelf.day(thisYear, now: now, calendar: calendar) == "Sep 3")
    }
}

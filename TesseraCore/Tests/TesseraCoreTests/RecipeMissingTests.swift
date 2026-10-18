import Foundation
@testable import TesseraCore
import Testing

/// Pantry v2 spec, sections M and C (and S11): what a recipe is missing, and CAN COOK.
@MainActor
struct RecipeMissingTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let book: RecipeBook

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        book = RecipeBook(store: store, classes: classes)
    }

    func recipe(_ title: String, _ lines: [String]) throws -> ObjectRecord {
        try engine.perform(
            CreateRecipe(text: "\(title)\nIngredients\n\(lines.joined(separator: "\n"))\nMethod\n1. Cook it."),
            by: .user
        ).output
    }

    /// States by lowercase ingredient title; anything else is unknown.
    func need(_ recipe: ObjectRecord, _ states: [String: PantryState], hides: Bool = false,
              privateOnes: Set<String> = []) -> RecipeNeed
    {
        RecipeMath.missing(
            lines: book.lines(of: recipe),
            state: { states[$0.title.lowercased()] ?? .unknown },
            isPrivateIngredient: { privateOnes.contains($0.title.lowercased()) },
            hidesNames: hides
        )
    }

    @Test func missingGivesZeroOneAndOneToCheck() throws {
        let stew = try recipe("Stew", ["2 carrots", "1 cup rice", "1 lb beef"])
        let all = ["carrots": PantryState.have, "rice": .have, "beef": .have]
        #expect(need(stew, all).score == 0)
        #expect(need(stew, all.merging(["beef": .out]) { $1 }).out.map(\.label) == ["Beef"])
        let unknownBeef = need(stew, ["carrots": .have, "rice": .have])
        #expect(unknownBeef.out.isEmpty && unknownBeef.unknown.map(\.label) == ["Beef"] && unknownBeef.score == 1)
    }

    @Test func stapleOptionalToTasteAndLowNeverCount() throws {
        let dish = try recipe(
            "Dish",
            ["1 cup rice", "1 tsp salt", "parsley, for serving", "pepper, to taste", "2 limes"]
        )
        let result = need(dish, ["rice": .have, "salt": .out, "limes": .low])
        #expect(
            result.score == 0 && result.low.map(\.label) == ["Limes"],
            "\(result.out.count) \(result.unknown.count)"
        )
    }

    @Test func oneIngredientOnTwoLinesCountsOnce() throws {
        let sauce = try recipe("Sauce", ["2 tbsp butter", "1 cup flour", "1 tbsp butter, for the top"])
        #expect(need(sauce, ["butter": .out, "flour": .have]).out.count == 1)
    }

    @Test func scalingNeverChangesWhatIsMissing() throws {
        let stew = try recipe("Stew", ["2 carrots", "1 cup rice"])
        let states = ["carrots": PantryState.out]
        let base = need(stew, states)
        let big = RecipeMath.missing(
            lines: book.scaledLines(of: stew, serves: 12),
            state: { states[$0.title.lowercased()] ?? .unknown }, isPrivateIngredient: { _ in false }
        )
        #expect(base.out.count == big.out.count && base.unknown.count == big.unknown.count)
    }

    @Test func aPrivateIngredientReadsPrivateItemAndAPrivateRecipeHidesNames() throws {
        let dish = try recipe("Dish", ["1 tsp lexapro", "2 carrots"])
        let some = need(dish, ["carrots": .have], privateOnes: ["lexapro"])
        #expect(some.unknown.map(\.label) == ["Private item"] && some.unknownNames == ["Private item"])
        let hidden = need(dish, [:], hides: true)
        #expect(hidden.score == 2 && hidden.unknownNames.isEmpty && hidden.outNames.isEmpty)
    }

    @Test func aDeletedIngredientIsToCheckAndALineWithoutOneIsSkipped() throws {
        let stew = try recipe("Stew", ["2 carrots", "1 cup rice"])
        let lines = book.lines(of: stew)
        let carrots = try #require(lines.compactMap(\.ingredient).first { $0.title == "Carrots" })
        let carrotLine = try #require(lines.first { $0.ingredient?.id == carrots.id })
        try engine.perform(DeleteObject(object: carrots.id), by: .user)
        // A line that still holds the deleted ingredient reads "to check", whatever state it had.
        let held = RecipeMath.missing(lines: [carrotLine], state: { _ in .have }, isPrivateIngredient: { _ in false })
        #expect(held.unknown.map(\.label) == ["Carrots"])
        // Re-read, the link is gone: the line has no ingredient and is skipped, like Groceries does.
        #expect(need(stew, ["rice": .have]).score == 0)
    }

    @Test func saltIsAStapleOnTheRecipePageToo() throws {
        let dish = try recipe("Dish", ["1 tsp salt", "1 cup rice"])
        let lines = book.lines(of: dish)
        #expect(lines.first { $0.line.name.lowercased().contains("salt") }?.isStaple == true)
        #expect(lines.first { $0.line.name.lowercased().contains("rice") }?.isStaple == false)
    }

    // MARK: CAN COOK

    @Test func canCookRanksByMissingThenNotCookedLately() throws {
        let ready = try recipe("Ready", ["1 cup rice"])
        let oneOut = try recipe("OneOut", ["1 cup rice", "2 carrots"])
        let oneUnknown = try recipe("OneUnknown", ["1 cup rice", "1 lb beef"])
        let pantry = PantryBook(store: store, classes: classes)
        // Rice is in (a shop), carrots are out (a produce cook).
        try engine.perform(AddGroceries(lines: ["rice"]), by: .user)
        for row in Groceries(store: store, classes: classes).shoppingOrder() {
            try engine.perform(CheckListItem(item: row.id, time: .now), by: .user)
        }
        try engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
        let cooked = try recipe("Carrot soup", ["2 carrots"])
        let cook = try engine.perform(StartCooking(recipe: cooked.id, time: .now), by: .user).output
        try engine.perform(FinishCooking(cook: cook.id, time: .now.addingTimeInterval(60)), by: .user)

        let ranked = pantry.canCook([oneOut, oneUnknown, ready]).map(\.recipe.title)
        // Ready first; then the one to check ("might be fine") ahead of the one known to be out.
        #expect(ranked == ["Ready", "OneUnknown", "OneOut"], "\(ranked)")
        #expect(pantry.cookableCount([oneOut, oneUnknown, ready]) == 1)
        #expect(pantry.hasAnyState)
    }

    @Test func aTieSortsNeverCookedFirstThenTheOldestCook() throws {
        let alpha = try recipe("Alpha", ["1 cup rice"])
        let beta = try recipe("Beta", ["1 cup rice"])
        let gamma = try recipe("Gamma", ["1 cup rice"])
        let old = try engine.perform(
            StartCooking(recipe: beta.id, time: .now.addingTimeInterval(-9 * 86400)),
            by: .user
        )
        .output
        try engine.perform(FinishCooking(cook: old.id, time: .now.addingTimeInterval(-9 * 86400 + 60)), by: .user)
        let recent = try engine.perform(
            StartCooking(recipe: gamma.id, time: .now.addingTimeInterval(-86400)),
            by: .user
        )
        .output
        try engine.perform(FinishCooking(cook: recent.id, time: .now.addingTimeInterval(-86400 + 60)), by: .user)
        let pantry = PantryBook(store: store, classes: classes)
        #expect(pantry.canCook([gamma, beta, alpha]).map(\.recipe.title) == ["Alpha", "Beta", "Gamma"])
    }

    @Test func aRecipeWithNoLinesIsNeverCookableAndGoesLast() throws {
        let ready = try recipe("Ready", ["1 cup rice"])
        let bare = try engine.perform(CreateRecipe(text: "Bare\nMethod\n1. Wait."), by: .user).output
        let pantry = PantryBook(store: store, classes: classes)
        #expect(pantry.canCook([bare, ready]).map(\.recipe.title) == ["Ready", "Bare"])
        #expect(pantry.cookableCount([bare]) == 0)
    }

    @Test func withNoStateAnywhereThereIsNoStateToSay() {
        let pantry = PantryBook(store: store, classes: classes)
        #expect(!pantry.hasAnyState)
    }
}

import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kitchen gap hunt 9, G62: a huge serves or time never crashes a recipe, from any source.
@MainActor
struct RecipeLimitsTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func theLimitsClampAndNeverTrap() {
        #expect(RecipeLimits.serves(1e300) == 100 && RecipeLimits.serves(.infinity) == nil)
        #expect(RecipeLimits.serves(.nan) == nil && RecipeLimits.serves(-3.0) == nil && RecipeLimits.serves(0.0) == nil)
        #expect(RecipeLimits.serves(4.0) == 4 && RecipeLimits.serves(Int.max) == 100 && RecipeLimits.serves(0) == nil)
        #expect(RecipeLimits.minutes(1e300) == RecipeLimits.minutes.upperBound && RecipeLimits.minutes(.nan) == nil)
        #expect(RecipeLimits.minutes(-.infinity) == nil && RecipeLimits.minutes(0.2) == 1)
        #expect(RecipeLimits.whole(1e300) == nil && RecipeLimits.whole(.nan) == nil && RecipeLimits.whole(12.7) == 12)
        #expect(IngredientLine.kitchenNumber(1e300 + 0.5, unit: .cup).isEmpty == false)
        #expect(RecipeTimers.format(1e300).isEmpty == false)
    }

    @Test(arguments: ["Serves 999999999999", "Serves 100000", "Total time: 99999999 min", "Prep 9999999 min"])
    func aPastedHugeSizeIsCapped(_ size: String) throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let text = "Chili\n\(size)\nIngredients\n1 onion\n2 cans beans\nMethod\n1. Cook it."
        let recipe = try engine.perform(CreateRecipe(text: text), by: .user).output
        let book = RecipeBook(store: store, classes: classes)
        #expect((book.serves(recipe) ?? 1) <= 100)
        #expect(RecipeLimits.minutes.contains(book.totalMinutes(recipe) ?? 1)
            && RecipeLimits.minutes.contains(book.activeMinutes(recipe) ?? 1))
    }

    @Test func aStoredHugeValueReadsInsideTheLimits() throws {
        // A link, Claude or an old store could have written anything: the read clamps.
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let recipe = try engine.perform(
            CreateRecipe(text: "Chili\nIngredients\n1 onion\n2 cans beans\nMethod\n1. Cook it."),
            by: .user
        ).output
        let book = RecipeBook(store: store, classes: classes)
        for value in [1e300, Double.infinity, Double.nan, -1e300] {
            try store.set("serves", to: .number(value), on: recipe)
            try store.set("totalMinutes", to: .number(value), on: recipe)
            #expect(book.serves(recipe).map { RecipeLimits.serves.contains($0) } ?? true, "\(value)")
            #expect(book.totalMinutes(recipe).map { RecipeLimits.minutes.contains($0) } ?? true, "\(value)")
            _ = book.scaledLines(of: recipe, serves: Int.max)
        }
        // An edit and a cook at a huge size are capped too.
        try engine.perform(EditRecipe(recipe: recipe.id, serves: Int.max), by: .user)
        #expect(book.serves(recipe) == 100)
        let cook = try engine.perform(StartCooking(recipe: recipe.id, serves: Int.max), by: .user).output
        #expect(CookLog(store: store, classes: classes).serves(of: cook) == 100)
    }

    @Test func aLinkWithAHugeTimeReadsAsText() {
        let parsed = ParsedRecipe(title: "Chili", serves: Int.max, activeMinutes: nil, totalMinutes: 1e300,
                                  ingredients: [], steps: [], source: "")
        let text = RecipeImport.text(of: parsed)
        #expect(text.contains("Serves 100") && text.contains("Total time: 4320 min"), "\(text)")
    }

    @Test func aTwoDayFermentKeepsItsTime() throws {
        // Kitchen 10:50 AM PT: the cap is 3 days, so 48 h reads as written; over 3 days reads as the cap.
        #expect(RecipeLimits.minutes == 1 ... 4320)
        #expect(RecipeLimits.minutes(2880) == 2880 && RecipeLimits.minutes(5000) == 4320)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let text = "Sourdough\nTotal time: 48 hours\nIngredients\n500 g flour\n350 g water\nMethod\n1. Mix and wait."
        let recipe = try engine.perform(CreateRecipe(text: text), by: .user).output
        let minutes = RecipeBook(store: store, classes: classes).totalMinutes(recipe)
        #expect(minutes == 2880, "\(minutes ?? -1)")
        try store.set("totalMinutes", to: .number(2880), on: recipe)
        #expect(RecipeBook(store: store, classes: classes).totalMinutes(recipe) == 2880)
    }

    @Test func claudesReplyLimitsAreTheSharedOnes() {
        /// The output check reads RecipeLimits, so the edges are the same everywhere (G62): 100 serves and 4320 minutes
        /// pass; one more of either drops the reply.
        func unsafe(serves: Int, minutes: Double) -> Bool {
            let parsed = ParsedRecipe(title: "Chili", serves: serves, activeMinutes: nil, totalMinutes: minutes,
                                      ingredients: [], steps: [], source: "")
            return ClaudeRecipeReader.outputIsUnsafe("Chili", recipe: parsed)
        }
        #expect(!unsafe(serves: 100, minutes: 4320))
        #expect(unsafe(serves: 101, minutes: 60))
        #expect(unsafe(serves: 4, minutes: 4321))
        #expect(unsafe(serves: 4, minutes: 0))
    }
}

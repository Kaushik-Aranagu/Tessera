import Foundation
@testable import TesseraCore
import Testing

struct RecipeParserTests {
    static let carbonara = """
    Spaghetti carbonara
    Serves 2
    Total time: 25 min

    Ingredients
    200 g spaghetti
    100 g guanciale, diced
    2 eggs
    50 g pecorino, finely grated
    Black pepper, to taste

    Method
    1. Boil the spaghetti in salted water for 10 minutes.
    2. Fry the guanciale for 5–6 min until crisp.
    3. Whisk the eggs with the pecorino and plenty of pepper.
    4. Toss everything off the heat and serve.
    """

    @Test func readsHeadingsTimesAndSteps() throws {
        let recipe = try #require(RecipeParser.parse(Self.carbonara))
        #expect(recipe.title == "Spaghetti carbonara")
        #expect(recipe.serves == 2)
        #expect(recipe.totalMinutes == 25)
        #expect(recipe.ingredients.map(\.name) == ["spaghetti", "guanciale", "eggs", "pecorino", "Black pepper"])
        #expect(recipe.ingredients[4].toTaste)
        #expect(recipe.steps.count == 4)
        #expect(recipe.steps[0].text == "Boil the spaghetti in salted water for 10 minutes.")
        #expect(recipe.steps[0].timers == [10 ... 10])
        #expect(recipe.steps[1].timers == [5 ... 6])
        #expect(recipe.source == Self.carbonara)
    }

    @Test func noHeadingsGoesByLineShape() throws {
        let recipe = try #require(RecipeParser.parse("""
        Quick dal
        250 g red lentils
        1 onion, chopped
        a pinch of salt
        Simmer the lentils with the onion for 20–25 minutes, stirring now and then.
        Season and serve with rice.
        """))
        #expect(recipe.title == "Quick dal")
        #expect(recipe.ingredients.count == 3)
        #expect(recipe.steps.count == 2)
        #expect(recipe.steps[0].timers == [20 ... 25])
        #expect(RecipeParser.durations(in: "roast for 1–2 hours") == [60 ... 120])
        #expect(RecipeParser.durations(in: "rest 1 hr 15 min") == [75 ... 75])
        #expect(RecipeParser.parse("  \n ") == nil)
    }
}

@MainActor
struct RecipeObjectTests {
    @Test func savingMakesLinkedObjectsAndUndoes() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let book = RecipeBook(store: store, classes: classes)

        let result = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user)
        let recipe = result.output
        #expect(recipe.title == "Spaghetti carbonara")
        #expect(book.serves(recipe) == 2)
        #expect(store.value("sourceText", of: recipe)?.stringValue == RecipeParserTests.carbonara)
        let lines = book.lines(of: recipe)
        #expect(lines.count == 5)
        #expect(lines[0].line.amount == 200 && lines[0].line.unit == .gram)
        #expect(lines[1].line.prep == "diced")
        #expect(lines[2].ingredient?.title == "Eggs")
        let steps = book.steps(of: recipe)
        #expect(steps.count == 4)
        #expect(steps[1].timers == [5 ... 6])
        #expect(steps[0].uses.map(\.title) == ["Spaghetti"])
        #expect(Set(steps[2].uses.map(\.title)) == ["Eggs", "Pecorino"])
        let egg = try #require(lines[2].ingredient)
        #expect(book.recipes(using: egg).map(\.id) == [recipe.id])

        // A second recipe reuses the ingredient objects.
        _ = try engine.perform(CreateRecipe(text: "Omelette\n3 eggs\nBeat the eggs and cook gently."), by: .user)
        #expect(IngredientBook(store: store, classes: classes).all().count == 5)
        #expect(book.recipes(using: egg).count == 2)

        try engine.perform(EditRecipe(recipe: recipe.id, title: "Carbonara", serves: 4), by: .user)
        #expect(recipe.title == "Carbonara" && book.serves(recipe) == 4)

        engine.undo(result.record)
        #expect(book.recipes().map(\.title) == ["Omelette"])
        #expect(throws: ActionError.self) { try engine.perform(CreateRecipe(text: " "), by: .user) }
    }
}

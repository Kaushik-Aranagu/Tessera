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

@MainActor
struct PasteCorrectionTests {
    @Test func tappedLinesReadAsTheyWereMarked() throws {
        let text = "Toast\nIngredients\n2 slices bread\nbutter\nMethod\nToast the bread."
        let lines = RecipeParser.classify(text)
        #expect(lines.map(\.line).count == 6)
        guard case .title = lines[0].kind, case .heading = lines[1].kind, case .ingredient = lines[3].kind else {
            Issue.record("classify")
            return
        }
        // Mark "butter" as ignored and the step as an ingredient-less step stays a step.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let recipe = try engine.perform(CreateRecipe(text: text, corrections: [3: "ignore"]), by: .user).output
        let book = RecipeBook(store: store, classes: classes)
        #expect(book.lines(of: recipe).map(\.line.name) == ["bread"])
        #expect(book.steps(of: recipe).count == 1)
        #expect(Groceries(store: store, classes: classes).share(of: recipe).isEmpty)
    }
}

/// G59: a sentence is not a title, and the same paste twice is one recipe.
@MainActor
struct RecipeTitleTests {
    @Test func theTitleRule() throws {
        /// Kitchen's ruling on #854: 12 words or fewer, no stop, no quantity first.
        func title(_ first: String) throws -> String {
            try #require(RecipeParser.parse("\(first)\n2 eggs\n1 cup flour\nBake it for 20 minutes.")).title
        }
        func words(_ count: Int) -> String {
            Array(repeating: "dal", count: count).joined(separator: " ")
        }
        #expect(try title(words(9)) == words(9))
        #expect(try title(words(12)) == words(12))
        #expect(try title(words(13)) == "Untitled recipe")
        #expect(try title("Dal:") == "Dal")
        #expect(try title("Mix everything.") == "Untitled recipe")
        #expect(try title("Is this the best dal?") == "Untitled recipe")
        let parsed = try #require(RecipeParser.parse("Mix everything.\n2 eggs\n1 cup flour"))
        #expect(parsed.steps.first?.text == "Mix everything.")
        // A quantity first is an ingredient, never the title.
        #expect(try #require(RecipeParser.parse("2 eggs\nMethod\n1. Whisk.")).title == "Untitled recipe")
        #expect(try #require(RecipeParser.parse("1/2 cup flour\nMethod\n1. Whisk.")).title == "Untitled recipe")
        #expect(try #require(RecipeParser.parse("A pinch of salt\nMethod\n1. Whisk.")).title == "Untitled recipe")
    }

    @Test(arguments: ["30-Minute Dal", "7 Layer Dip", "5 Spice Chicken", "3 Cheese Pasta Bake"])
    func aNameThatStartsWithANumberStaysATitle(_ first: String) throws {
        let parsed = try #require(RecipeParser.parse("\(first)\n2 eggs\n1 cup flour\nBake it for 20 minutes."))
        #expect(parsed.title == first)
    }

    @Test(arguments: [
        "2 eggs",
        "1/2 cup flour",
        "200g flour",
        "1½ cups milk",
        "2-3 cloves garlic",
        "2 Tbsp butter",
        "3",
    ])
    func aQuantityIsNeverTheTitle(_ first: String) throws {
        let parsed = try #require(RecipeParser.parse("\(first)\nMethod\n1. Whisk it."))
        #expect(parsed.title == "Untitled recipe", "\(first)")
    }

    @Test(arguments: ["1. Preheat the oven", "2) Whisk the eggs", "10. Rest it"])
    func aNumberedFirstStepIsAStepNotATitle(_ first: String) throws {
        let parsed = try #require(RecipeParser.parse("\(first)\n2 eggs\n1 cup flour"))
        #expect(parsed.title == "Untitled recipe" && parsed.steps.first?.text.isEmpty == false, "\(first)")
    }

    @Test func theSamePasteTwiceIsOneRecipe() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let text = "Weeknight dal\nIngredients\n1 cup lentils\nMethod\n1. Simmer 20 minutes."
        let first = try engine.perform(CreateRecipe(text: text), by: .user).output
        let book = RecipeBook(store: store, classes: classes)
        #expect(book.recipe(pastedAs: text)?.id == first.id)
        do {
            try engine.perform(CreateRecipe(text: text), by: .user)
            Issue.record("a second copy was written")
        } catch {
            #expect("\(error)".contains("Weeknight dal is already on Recipes."), "\(error)")
        }
        #expect(book.recipes().count == 1)
        // A private title is never named.
        let secret = "Lexapro stew\nIngredients\n1 cup lentils\nMethod\n1. Simmer."
        try engine.perform(CreateRecipe(text: secret), by: .user)
        do {
            try engine.perform(CreateRecipe(text: secret), by: .user)
        } catch {
            #expect(!"\(error)".lowercased().contains("lexapro") && "\(error)".contains("Private recipe"), "\(error)")
        }
    }
}

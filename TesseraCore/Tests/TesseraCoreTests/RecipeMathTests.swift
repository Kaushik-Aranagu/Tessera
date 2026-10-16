import Foundation
@testable import TesseraCore
import Testing

struct RecipeMathTests {
    func line(_ text: String) throws -> IngredientLine {
        try #require(IngredientLine.parse(text))
    }

    @Test func scalingRoundsTheWayYouMeasure() throws {
        let lines = try [
            "200 g spaghetti",
            "2 eggs",
            "1 onion",
            "1 tbsp olive oil",
            "1/3 cup milk",
            "2–3 cloves garlic",
            "1.2 kg potatoes",
            "salt to taste",
            "7 g yeast",
        ].map(line)
        let three = RecipeMath.scaled(lines, from: 2, to: 3)
        #expect(three[0].amount == 300)
        #expect(three[1].amount == 3)
        #expect(three[2].amount == 2) // 1.5 onions → 2
        #expect(three[3].amount == 1.5)
        #expect(three[4].amount == 0.5) // 0.5 cup
        #expect(three[5].amount == 3 && three[5].amountMax == 5) // 4.5 → 5 (rounded half up)
        #expect(three[6].amount == 1.8)
        #expect(three[7] == lines[7]) // to taste stays
        #expect(three[8].amount == 10) // 10.5 g → nearest 5
        let one = RecipeMath.scaled(lines, from: 4, to: 1)
        #expect(one[0].amount == 50)
        #expect(one[1].amount == 1) // never zero eggs
        #expect(RecipeMath.scaled(lines, from: 2, to: 2) == lines)
        #expect(RecipeMath.scaled(lines, from: 0, to: 2) == lines)
    }

    @Test func amountsReadLikeARecipe() throws {
        #expect(try line("1½ tbsp oil").quantityText == "1½ tbsp")
        #expect(try line("2-3 cloves garlic").quantityText == "2–3 cloves")
        #expect(try line("1 clove garlic").quantityText == "1 clove")
        #expect(try line("2 onions").quantityText == "2")
        #expect(try line("0.5 kg flour").quantityText == "0.5 kg")
        #expect(try line("a pinch of salt").quantityText == "1 pinch")
        #expect(try line("salt to taste").quantityText == nil)
    }

    @MainActor
    @Test func recipeBookScalesWithoutStoring() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let book = RecipeBook(store: store, classes: classes)
        let recipe = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user).output
        let four = book.scaledLines(of: recipe, serves: 4)
        #expect(four[0].line.amount == 400)
        #expect(book.lines(of: recipe)[0].line.amount == 200)
    }
}

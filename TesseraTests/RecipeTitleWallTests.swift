import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// G53: a private recipe's title reads "Private recipe" on the recipe page, the original page and the saved line.
@MainActor
struct RecipeTitleWallTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aPrivateTitleIsMaskedUntilShown() {
        for title in ["Rent 1200 stew", "Wifi code lasagna"] {
            let isPrivate = RecipeCopy.isPrivate(title, model: model)
            #expect(isPrivate, "\(title)")
            #expect(RecipeCopy.shownTitle(title, isPrivate: isPrivate, shown: false) == "Private recipe")
            #expect(RecipeCopy.shownTitle(title, isPrivate: isPrivate, shown: true) == title)
        }
    }

    @Test func aPlainTitleShowsAsIs() {
        #expect(!RecipeCopy.isPrivate("Weeknight dal", model: model))
        #expect(RecipeCopy.shownTitle("Weeknight dal", isPrivate: false, shown: false) == "Weeknight dal")
    }

    @Test func thePastedTitleLineStaysMaskedWhileTheTitleIs() {
        let source = "Rent 1200 stew\n2 cups lentils\n\nSimmer."
        #expect(RecipeCopy.maskedSource(source, title: "Rent 1200 stew", masked: true)
            == "Private recipe\n2 cups lentils\n\nSimmer.")
        #expect(RecipeCopy.maskedSource("  rent 1200 STEW  \nSimmer.", title: "Rent 1200 stew", masked: true)
            == "Private recipe\nSimmer.")
        #expect(RecipeCopy.maskedSource(source, title: "Rent 1200 stew", masked: false) == source)
        // Markdown around the pasted title line, as the parser trims it.
        for line in ["# Rent 1200 stew", "**Rent 1200 stew**", "Rent 1200 stew:"] {
            #expect(RecipeCopy.maskedSource("\(line)\nSimmer.", title: "Rent 1200 stew", masked: true)
                == "Private recipe\nSimmer.", "\(line)")
        }
    }

    @Test func pastesReceiptNamesTheThingFirst() {
        #expect(RecipeCopy.saved("Carbonara") == "Carbonara, on Recipes.")
        let title = RecipeCopy.shownTitle("Rent 1200 stew", isPrivate: true, shown: false)
        #expect(RecipeCopy.saved(title) == "Private recipe, on Recipes.")
    }

    @Test func theRecipeOpenedStaysChosenSoAGoneOneSaysSo() {
        // `RecipeView` keeps the id it opened; with a request the pick never moves to another recipe.
        let shown = UUID()
        #expect(RecipeView.opening(requested: shown, rows: []) == shown)
    }
}

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

    @Test func aPrivateTitleIsAlwaysMasked() {
        for title in ["Rent 1200 stew", "Wifi code lasagna"] {
            let isPrivate = RecipeCopy.isPrivate(title, model: model)
            #expect(isPrivate, "\(title)")
            #expect(RecipeCopy.shownTitle(title, isPrivate: isPrivate) == "Private recipe")
        }
    }

    @Test func aPlainTitleShowsAsIs() {
        #expect(!RecipeCopy.isPrivate("Weeknight dal", model: model))
        #expect(RecipeCopy.shownTitle("Weeknight dal", isPrivate: false) == "Weeknight dal")
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
        #expect(RecipeCopy.saved("Sheet-pan paprika chicken with lemon") == "Sheet-pan paprika chicken, on Recipes.")
        #expect(RecipeCopy.shortName("Chili con carne") == "Chili con carne")
        #expect(RecipeCopy.shortName("Weeknight dal (instant pot)") == "Weeknight dal")
        #expect(RecipeCopy.shortName("Mac and cheese") == "Mac and cheese")
        let title = RecipeCopy.shownTitle("Rent 1200 stew", isPrivate: true)
        #expect(RecipeCopy.saved(title) == "Private recipe, on Recipes.")
    }

    @Test func deletingTheShownRecipeKeepsItsPageWhichSaysRecipeGone() throws {
        let shown = try model.engine.perform(CreateRecipe(text: "Tacos\n2 limes\n\nCook."), by: .user).output
        let other = try model.engine.perform(CreateRecipe(text: "Dal\n1 cup lentils\n\nSimmer."), by: .user).output
        model.store.softDelete(shown)
        let rows = [RecipeView.Row(id: other.id, lastOpenedAt: nil, createdAt: other.createdAt)]
        // The visit opened Tacos: it stays on screen rather than jumping to Dal, and the page reads "Recipe gone."
        #expect(RecipeView.shown(opened: shown.id, requested: nil, rows: rows) == shown.id)
        #expect(RecipeCopy.isGone(shown.id, store: model.store))
        #expect(!RecipeCopy.isGone(other.id, store: model.store))
    }
}

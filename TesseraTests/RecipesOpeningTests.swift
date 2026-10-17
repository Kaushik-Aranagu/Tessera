import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// G51 and G55 (Product's rulings on Kitchen's gap hunt 8).
@MainActor
struct RecipesOpeningTests {
    @Test func recipesOpensTheLastOpenedRecipe() {
        let old = Date(timeIntervalSince1970: 1000), mid = Date(timeIntervalSince1970: 2000)
        let new = Date(timeIntervalSince1970: 3000)
        let first = RecipeView.Row(id: UUID(), lastOpenedAt: new, createdAt: old)
        let second = RecipeView.Row(id: UUID(), lastOpenedAt: mid, createdAt: new)
        #expect(RecipeView.opening(requested: nil, rows: [first, second]) == first.id, "the latest opened wins")
    }

    @Test func noneOpenedGivesTheNewest() {
        let old = RecipeView.Row(id: UUID(), lastOpenedAt: nil, createdAt: Date(timeIntervalSince1970: 1000))
        let new = RecipeView.Row(id: UUID(), lastOpenedAt: nil, createdAt: Date(timeIntervalSince1970: 2000))
        #expect(RecipeView.opening(requested: nil, rows: [old, new]) == new.id)
        #expect(RecipeView.opening(requested: nil, rows: []) == nil)
    }

    @Test func aRequestedRecipeWinsAndDeletedOnesAreNotRows() throws {
        let row = RecipeView.Row(id: UUID(), lastOpenedAt: .now, createdAt: .now)
        let asked = UUID()
        #expect(RecipeView.opening(requested: asked, rows: [row]) == asked)
        // Deleted recipes are left out before the pick (RecipeView filters `isDeleted`), so only live rows count.
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        let gone = try model.engine.perform(CreateRecipe(text: "Gone\n1 egg\n\nBoil."), by: .user).output
        let kept = try model.engine.perform(CreateRecipe(text: "Kept\n1 egg\n\nFry."), by: .user).output
        model.store.softDelete(gone)
        let live = RecipeBook(store: model.store, classes: model.classes).recipes().filter { !$0.isDeleted }
        #expect(live.map(\.id) == [kept.id])
    }

    @Test func noStepsReadsAsAnInvitationNeverStepOneOfZero() {
        #expect(RecipeCopy.stepCount(0) == "No steps yet. Paste them below.")
        #expect(RecipeCopy.stepCount(1) == "1 step")
        #expect(RecipeCopy.stepCount(4) == "4 steps")
    }

    @Test func noCookKeyUntilCookMode() {
        #expect(!RecipePage.cookModeReady)
    }
}

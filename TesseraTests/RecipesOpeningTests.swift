import Foundation
@testable import Tessera
import Testing

/// G51 and G55 (Product's rulings on Kitchen's gap hunt 8).
@MainActor
struct RecipesOpeningTests {
    @Test func recipesOpensTheLastOpenedRecipe() {
        let first = UUID(), second = UUID(), gone = UUID()
        #expect(RecipeView.opening(requested: nil, last: second, recipes: [first, second]) == second)
        #expect(
            RecipeView.opening(requested: nil, last: gone, recipes: [first, second]) == first,
            "a deleted one falls back"
        )
        #expect(RecipeView.opening(requested: nil, last: nil, recipes: [first, second]) == first)
        #expect(RecipeView.opening(requested: first, last: second, recipes: [first, second]) == first)
        #expect(RecipeView.opening(requested: nil, last: nil, recipes: []) == nil)
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

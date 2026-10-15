import SwiftUI
import TesseraCore

/// Entry points for the recipe screens, each with its own navigation.
/// `RecipeView(recipeID:)` opens a recipe page; `PasteRecipeView()` opens paste-a-recipe and moves on to the saved
/// recipe. DEBUG: `-recipe` (the first recipe; add `-demoKitchen` to seed some) and `-pasteRecipe`.
struct RecipeView: View {
    let recipeID: UUID?
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        NavigationStack {
            Group {
                if let id = recipeID ?? RecipeBook(store: model.store, classes: model.classes).recipes().first?.id {
                    RecipePage(recipeID: id) { recipe, serves in
                        _ = try? model.engine.perform(StartCooking(recipe: recipe, serves: serves), by: .user)
                        model.touch()
                    }
                } else {
                    PasteRecipe()
                }
            }
            .toolbarTitleDisplayMode(.inline)
        }
        .environment(\.animateEntrance, true)
        #if DEBUG
            .task { KitchenDemo.seedIfRequested(model) }
        #endif
    }
}

struct PasteRecipeView: View {
    @State private var saved: UUID?

    var body: some View {
        NavigationStack {
            PasteRecipe { saved = $0 }
                .navigationDestination(item: $saved) { id in
                    RecipePage(recipeID: id)
                }
                .toolbarTitleDisplayMode(.inline)
        }
        .environment(\.animateEntrance, true)
    }
}

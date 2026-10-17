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
                let recipes = RecipeBook(store: model.store, classes: model.classes).recipes().map(\.id)
                if let id = Self.opening(requested: recipeID, last: Self.lastOpened, recipes: recipes) {
                    RecipePage(recipeID: id)
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

extension RecipeView {
    /// The recipe "Recipes" opens (G51, Product): the one asked for, else the last one opened if it's still there,
    /// else the first.
    static func opening(requested: UUID?, last: UUID?, recipes: [UUID]) -> UUID? {
        if let requested {
            return requested
        }
        if let last, recipes.contains(last) {
            return last
        }
        return recipes.first
    }

    private static let lastOpenedKey = "recipes.lastOpened"

    /// The last recipe page shown, kept on this phone only.
    static var lastOpened: UUID? {
        get { UserDefaults.standard.string(forKey: lastOpenedKey).flatMap(UUID.init(uuidString:)) }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: lastOpenedKey) }
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

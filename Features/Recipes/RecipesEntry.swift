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
                let rows = RecipeBook(store: model.store, classes: model.classes).recipes()
                    .filter { !$0.isDeleted }
                    .map { Row(id: $0.id, lastOpenedAt: model.store.value("lastOpenedAt", of: $0)?.dateValue,
                               createdAt: $0.createdAt) }
                if let id = Self.opening(requested: recipeID, rows: rows) {
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
    /// One recipe as the opener sees it.
    struct Row: Equatable {
        let id: UUID
        let lastOpenedAt: Date?
        let createdAt: Date
    }

    /// The recipe "Recipes" opens (G51, Product: "last opened recipe, the newest if none"): the one asked for, else
    /// the latest `lastOpenedAt`, else the newest by `createdAt`. Rows are live recipes only.
    static func opening(requested: UUID?, rows: [Row]) -> UUID? {
        if let requested {
            return requested
        }
        let opened = rows.compactMap { row in row.lastOpenedAt.map { (row.id, $0) } }
        if let latest = opened.max(by: { $0.1 < $1.1 }) {
            return latest.0
        }
        return rows.max { $0.createdAt < $1.createdAt }?.id
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

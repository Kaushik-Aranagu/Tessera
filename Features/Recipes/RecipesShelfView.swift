import SwiftUI
import TesseraCore

/// Recipes, the front (sheet 87): ‹ KITCHEN, the title, the count line, then one plain line per recipe, newest
/// first: the name in ink (a private one "Private recipe" at 66%) and its day. A row opens its recipe. No cards, no
/// art; a long name wraps, never cut. The side (ITS OBJECTS) waits on SideHost.
struct RecipesShelfView: View {
    var body: some View {
        NavigationStack {
            RecipesShelfPage()
                .navigationDestination(for: UUID.self) { RecipePage(recipeID: $0) }
                // Paste from the shelf stays in the shelf, so back lands here, not Home (QA on #774).
                .navigationDestination(for: ShelfPaste.self) { _ in ShelfPaste.Page() }
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.animateEntrance, true)
    }
}

private struct RecipesShelfPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// Tess speaks once per visit, not each time the shelf reappears (QA on #765).
    @State private var spoke = false

    var body: some View {
        let _ = model.revision
        let shelf = RecipesShelf(store: model.store, classes: model.classes, now: AppClock.now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ Kitchen")
                        .textRole(.label)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityLabel("Back to Kitchen")
                .entrance(0)
                Text("Recipes")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                Text(shelf.context)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1)
                if shelf.rows.isEmpty {
                    Text("No recipes yet.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.ink.opacity(0.66))
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(2)
                    // The way in from an empty shelf (QA on #765).
                    NavigationLink("Paste a recipe", value: ShelfPaste())
                        .buttonStyle(.labelWord)
                        .padding(.top, Theme.Spacing.m)
                        .entrance(3)
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(shelf.rows) { row in
                        NavigationLink(value: row.id) {
                            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                                Text(row.name)
                                    .textRole(.body)
                                    .foregroundStyle(Theme.Colors.ink.opacity(row.isPrivate ? 0.66 : 1))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: Theme.Spacing.m)
                                if let day = row.day {
                                    Text(day)
                                        .textRole(.body)
                                        .foregroundStyle(Theme.Colors.inkSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(HandleButtonStyle())
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(row.day.map { "\(row.name), \($0)" } ?? row.name)
                        .accessibilityHint("Opens the recipe")
                    }
                }
                .padding(.top, Theme.Spacing.xxl)
                .entrance(2)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .onAppear {
            guard !spoke else { return }
            spoke = true
            if let tess = shelf.tess {
                TessVoice.shared.say(tess)
            }
        }
    }
}

/// The Paste path pushed inside the shelf's stack; a save moves on to the new recipe.
struct ShelfPaste: Hashable {
    struct Page: View {
        @State private var saved: UUID?

        var body: some View {
            PasteRecipe { saved = $0 }
                .navigationDestination(item: $saved) { RecipePage(recipeID: $0) }
                .toolbarTitleDisplayMode(.inline)
        }
    }
}

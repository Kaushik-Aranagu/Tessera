import SwiftUI
import TesseraCore
import TesseraTess

/// Recipes, the front (sheet 87): ‹ KITCHEN, the title, the count line, then one plain line per recipe, newest
/// first: the name in ink (a private one "Private recipe" at 66%) and its day. A row opens its recipe. No cards, no
/// art; a long name wraps, never cut. The side (ITS OBJECTS) waits on SideHost.
struct RecipesShelfView: View {
    @State private var path = NavigationPath()
    /// The stack depth with Paste on top, set as Paste appears.
    @State private var pasteDepth: Int?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if Tier1b.kitchenRoomsIsOn {
                    RecipesRoomPage(open: { path.append($0) }, paste: { path.append(ShelfPaste()) })
                } else {
                    RecipesShelfPage()
                }
            }
            .navigationDestination(for: UUID.self) { RecipePage(recipeID: $0) }
            // Paste from the shelf stays in the shelf, so back lands here, not Home (QA on #774). A save swaps
            // Paste for the new recipe, so back from it is the shelf, never Paste again (#774 walk).
            .navigationDestination(for: ShelfPaste.self) { stop in
                // Cleared as Paste leaves, so a recipe opened within the hold is never swapped (QA on #790).
                ShelfPaste.Page(link: stop.link, onTop: { pasteDepth = path.count }, offTop: { pasteDepth = nil })
                    { id in
                        // Only while Paste is still on top: if he already went back, the save stays on the shelf
                        // and nothing is popped (QA on #790).
                        guard !path.isEmpty, path.count == pasteDepth else { return }
                        path.removeLast()
                        path.append(id)
                    }
            }
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
    /// Links kept for later (G65, K86.7), read when the shelf shows and after a remove.
    @State private var kept: [URL] = []

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
                SampleDataWord()
                Text("Recipes")
                    .textRole(.title)
                    .wordFit("Recipes")
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
                                    // Full ink, like every masked line: "Private recipe" isn't dimmed (sheet 99).
                                    .foregroundStyle(Theme.Colors.ink)
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
                if !kept.isEmpty {
                    keptLinks
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(3)
                }
            }
            // Held to the leading edge: a short page (an empty pantry, an empty shelf) is otherwise centred in the
            // scroll view and reads as shifted right (Kaushik, Oct 21).
            .frame(maxWidth: .infinity, alignment: .leading)
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

    /// G65: each kept link by its host only ("seriouseats.com"), never the whole address. Read opens Paste on it, on
    /// his tap only; Remove takes it off the phone. Plain ink, no haptic: information, not a failure.
    private var keptLinks: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(RecipesKeptCopy.heading(kept.count))
                .textRole(.label)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            ForEach(kept, id: \.self) { link in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.l) {
                    Text(RecipesKeptCopy.host(link))
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    NavigationLink("Read", value: ShelfPaste(link: link))
                        .buttonStyle(.labelWord)
                        .accessibilityLabel("Read \(RecipesKeptCopy.host(link))")
                    Button("Remove") {
                        guard let shelf = RecipeLinkShelf.beside(model.store) else { return }
                        let putBack = KeptLinks.remove(link, from: shelf)
                        refreshKept()
                        // A slip beside Read isn't final: the app-wide UNDO for a change, 10 s (Design on #913). It
                        // puts the link back in its own place, not at the end (QA on #1031).
                        TessVoice.shared.say(RecipesKeptCopy.removed(link), takeBack: {
                            putBack()
                            refreshKept()
                        })
                    }
                    .buttonStyle(.labelWord)
                    .accessibilityLabel("Remove \(RecipesKeptCopy.host(link))")
                }
                .frame(minHeight: 44)
            }
        }
        .onAppear(perform: refreshKept)
    }

    private func refreshKept() {
        withAnimation(.smooth(duration: 0.24)) { kept = RecipeLinkShelf.beside(model.store)?.waiting() ?? [] }
    }
}

/// The Paste path pushed inside the shelf's stack; a save moves on to the new recipe.
struct ShelfPaste: Hashable {
    /// A kept link to read on arrival (G65); nil for a plain Paste.
    var link: URL?

    /// Paste under a "‹ RECIPES" back word, with the bar hidden like the shelf.
    struct Page: View {
        var link: URL?
        var onTop: () -> Void = {}
        var offTop: () -> Void = {}
        let onSaved: (UUID) -> Void
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            PasteRecipe(initialLink: link, onSaved: onSaved)
                .safeAreaInset(edge: .top, spacing: 0) {
                    BackWord(title: "Recipes") { dismiss() }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.Spacing.gutter)
                        .background { ThemedBackground() }
                }
                .toolbar(.hidden, for: .navigationBar)
                .onAppear(perform: onTop)
                .onDisappear(perform: offTop)
        }
    }
}

/// The kept-links words: the host alone, never the whole address (G65).
enum RecipesKeptCopy {
    static func host(_ link: URL) -> String {
        let host = link.host() ?? "a link"
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// "Kept for later" with its count: "1 link kept for later" / "3 links kept for later".
    static func heading(_ count: Int) -> String {
        "\(count) link\(count == 1 ? "" : "s") kept for later"
    }

    /// "seriouseats.com, removed."
    static func removed(_ link: URL) -> String {
        "\(host(link)), removed."
    }
}

/// Remove and its UNDO on the kept links. Core's shelf only appends, so putting a link back in its old place takes
/// the links after it off and keeps them again behind it.
@MainActor
enum KeptLinks {
    /// Takes the link off the shelf and returns the take-back that restores it where it was.
    static func remove(_ link: URL, from shelf: RecipeLinkShelf) -> @MainActor () -> Void {
        let index = shelf.waiting().firstIndex(of: link)
        shelf.remove(link)
        return { restore(link, at: index, on: shelf) }
    }

    /// Puts the link back at its old index; a link kept since then stays behind it. With no index, at the end.
    static func restore(_ link: URL, at index: Int?, on shelf: RecipeLinkShelf) {
        let after = index.map { Array(shelf.waiting().dropFirst($0)) } ?? []
        for later in after {
            shelf.remove(later)
        }
        shelf.keep(link)
        for later in after {
            shelf.keep(later)
        }
    }
}

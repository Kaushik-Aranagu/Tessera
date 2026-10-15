import SwiftUI
import TesseraCore

/// Groceries (kitchen screen 13): one page, sections by aisle. Aisle names are Title-tier words set in the left
/// margin, offset and asymmetric; items hang from them at body size. No checkboxes: tapping an item runs the ink
/// strike through it and it sinks into the basket fold at the bottom ("6 in the basket"). A sage dab means it's for
/// a recipe; a long press says which. Adding is the writing line ("eggs, milk, 2 lemons").
///
/// At the shop (hold the title): one column in walking order, the current aisle at hero size under a lit seam.
///
/// Entry point: present `GroceriesView()`, or launch with `-groceries` in DEBUG (`-demoKitchen` seeds recipes and
/// a list).
struct GroceriesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            GroceriesPage()
                .toolbarTitleDisplayMode(.inline)
        }
        .environment(\.animateEntrance, true)
        #if DEBUG
            .task { KitchenDemo.seedIfRequested(model) }
        #endif
    }
}

// MARK: - Page

private struct GroceriesPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = ""
    @State private var striking: Set<UUID> = []
    @State private var basketOpen = false
    @FocusState private var writing: Bool

    private var groceries: Groceries {
        Groceries(store: model.store, classes: model.classes)
    }

    var body: some View {
        let _ = model.revision
        let aisles = groceries.aisles()
        let open = aisles.reduce(0) { $0 + $1.items.count }
        let basket = groceries.list.map { ListContents(store: model.store, classes: model.classes).done(in: $0) } ?? []
        let shop = groceries.shop(in: model.engine)
        let shopping = shop?.state == .running

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(GroceriesCopy.context(open: open, aisles: aisles.count, shopping: shopping))
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .contentTransition(.numericText())
                    .entrance(0)

                ShopTitle(shopping: shopping, onHold: toggleShop)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                GroceryWritingLine(text: $draft, focused: $writing, onSubmit: add)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(2)

                if aisles.isEmpty {
                    GroceriesEmpty(basket: basket.count)
                        .padding(.top, Theme.Spacing.section)
                        .entrance(3)
                } else if shopping {
                    AtTheShop(aisles: aisles, striking: striking, recipes: recipes(for:), onTap: check)
                        .padding(.top, Theme.Spacing.xxl)
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                        ForEach(Array(aisles.enumerated()), id: \.element.aisle) { index, aisle in
                            AisleSection(name: aisle.aisle, items: aisle.items, offset: index.isMultiple(of: 2) ? 0 : 1,
                                         striking: striking, recipes: recipes(for:), onTap: check)
                                .entrance(3 + min(index, 3))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, Theme.Spacing.xxl)
                }

                if !basket.isEmpty {
                    BasketFold(items: basket, isOpen: $basketOpen, onTap: uncheck)
                        .padding(.top, Theme.Spacing.section)
                }

                if shopping {
                    PaintKey(paint: Theme.Colors.health, action: finishShop) { _ in
                        Text("Done shopping")
                    } meta: {
                        Text("Hold")
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    .accessibilityHint("Clears the basket and ends the shop")
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .tesseraAnimation(Theme.Motion.house, value: aisles.map(\.aisle))
            .tesseraAnimation(Theme.Motion.house, value: shopping)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .overlay(alignment: .top) {
            if shopping {
                ProcessSeam(color: Theme.Colors.live)
                    .ignoresSafeArea(edges: .top)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.success, trigger: basket.count)
    }

    private func recipes(for item: ListContents.Item) -> [String] {
        groceries.recipes(for: item.object).map(\.title)
    }

    private func add() {
        let lines = GroceriesCopy.lines(in: draft)
        guard !lines.isEmpty else { return }
        // Keep what was typed if it couldn't be added.
        guard (try? model.engine.perform(AddGroceries(lines: lines), by: .user)) != nil else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            draft = ""
            model.touch()
        }
    }

    /// The ink strike runs through first; then the item sinks into the basket.
    private func check(_ item: ListContents.Item) {
        guard !striking.contains(item.id) else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = striking.insert(item.id) }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 120 : 420))
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                _ = try? model.engine.perform(CheckListItem(item: item.id), by: .user)
                striking.remove(item.id)
                model.touch()
            }
        }
    }

    private func uncheck(_ item: ListContents.Item) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            _ = try? model.engine.perform(CheckListItem(item: item.id, done: false), by: .user)
            model.touch()
        }
    }

    private func toggleShop() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            if let shop = groceries.shop(in: model.engine), shop.state == .running {
                _ = try? model.engine.perform(SuspendProcess(process: shop.id), by: .user)
            } else {
                _ = try? model.engine.perform(StartShop(), by: .user)
            }
            model.touch()
        }
    }

    private func finishShop() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            _ = try? model.engine.perform(FinishShop(), by: .user)
            basketOpen = false
            model.touch()
        }
    }
}

// MARK: - Pieces

/// The hero. Holding it starts (or leaves) the shop; it reads "At the shop" while shopping.
private struct ShopTitle: View {
    let shopping: Bool
    let onHold: () -> Void

    var body: some View {
        Text(shopping ? "At the shop" : "Groceries")
            .textRole(.hero)
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5, perform: onHold)
            .sensoryFeedback(.impact(weight: .medium), trigger: shopping)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: shopping ? "Leave the shop" : "Start shopping", onHold)
    }
}

/// The writing line: a faint sage dab and the prompt; items fly to their aisles on return.
private struct GroceryWritingLine: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        let active = focused.wrappedValue || !text.isEmpty
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .center, spacing: Theme.Spacing.m) {
                PaintDab(color: Theme.Colors.health, size: CGSize(width: 14, height: 12), seed: 5)
                    .opacity(active ? 1 : 0.35)
                    .tesseraAnimation(Theme.Motion.house, value: active)
                TextField("", text: $text, prompt: Text("eggs, milk, 2 lemons")
                    .foregroundStyle(Theme.Colors.inkSecondary))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .focused(focused)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Add to groceries")
            }
            Rectangle()
                .fill(active ? Theme.Colors.health : Theme.Colors.hairline)
                .frame(height: Theme.Stroke.hairline)
                .tesseraAnimation(Theme.Motion.house, value: active)
        }
    }
}

/// One aisle: its name in the margin at the Title tier (every other aisle set in a little), items hanging from it.
private struct AisleSection: View {
    let name: String
    let items: [ListContents.Item]
    let offset: Int
    let striking: Set<UUID>
    let recipes: (ListContents.Item) -> [String]
    let onTap: (ListContents.Item) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(name)
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .padding(.leading, typeSize.isAccessibilitySize ? 0 : CGFloat(offset) * Theme.Spacing.xl)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    GroceryRow(item: item, isStriking: striking.contains(item.id), recipes: recipes(item)) {
                        onTap(item)
                    }
                    .transition(.asymmetric(insertion: .push(from: .top).combined(with: .opacity),
                                            removal: .move(edge: .bottom).combined(with: .opacity)))
                }
            }
            .padding(.leading, typeSize.isAccessibilitySize ? 0 : Theme.Spacing.xl)
        }
        .accessibilityElement(children: .contain)
    }
}

/// One item: the name at body size, a sage dab when it's for a recipe, the quantity hanging right. Tap strikes it;
/// a long press shows the recipes it's for.
private struct GroceryRow: View {
    let item: ListContents.Item
    let isStriking: Bool
    let recipes: [String]
    let onTap: () -> Void
    @State private var showsRecipes = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Text(item.text)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .textRenderer(CompletionRenderer(progress: isStriking ? 1 : 0, color: Theme.Colors.ink))
                        .fixedSize(horizontal: false, vertical: true)
                    if !recipes.isEmpty {
                        PaintDab(color: Theme.Colors.health, size: CGSize(width: 11, height: 9),
                                 seed: item.text.count)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                    }
                    Spacer(minLength: Theme.Spacing.m)
                    if let quantity = item.quantity {
                        Text(quantity)
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                }
                if showsRecipes, !recipes.isEmpty {
                    Text("for \(recipes.joined(separator: ", "))")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.health)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.vertical, Theme.Spacing.s)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
            withTesseraAnimation(Theme.Motion.house, reduceMotion: false) { showsRecipes.toggle() }
        })
        .tesseraAnimation(Theme.Motion.house, value: isStriking)
        .sensoryFeedback(.selection, trigger: isStriking)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Puts it in the basket")
        .accessibilityAction(named: "Which recipes") { showsRecipes.toggle() }
    }
}

/// At the shop: the current aisle at hero size, the rest after it in walking order, smaller. Done aisles have
/// already folded away (they have nothing open).
private struct AtTheShop: View {
    let aisles: [(aisle: String, items: [ListContents.Item])]
    let striking: Set<UUID>
    let recipes: (ListContents.Item) -> [String]
    let onTap: (ListContents.Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
            ForEach(Array(aisles.enumerated()), id: \.element.aisle) { index, aisle in
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(aisle.aisle)
                        .textRole(index == 0 ? .hero : .title)
                        .foregroundStyle(index == 0 ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(aisle.items) { item in
                            GroceryRow(item: item, isStriking: striking.contains(item.id), recipes: recipes(item)) {
                                onTap(item)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .opacity(index == 0 ? 1 : 0.6)
                }
                .transition(.asymmetric(insertion: .opacity,
                                        removal: .move(edge: .top).combined(with: .opacity)))
            }
        }
    }
}

/// The basket: a fold at the bottom that shows only a count until you open it. Tapping an item puts it back.
private struct BasketFold: View {
    let items: [ListContents.Item]
    @Binding var isOpen: Bool
    let onTap: (ListContents.Item) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Rectangle()
                .fill(Theme.Colors.hairline)
                .frame(height: Theme.Stroke.hairline)
            Button {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { isOpen.toggle() }
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    PaintDab(color: Theme.Colors.health, size: CGSize(width: 14, height: 12), seed: 9)
                    Text("\(items.count) in the basket")
                        .textRole(.labelStrong)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .contentTransition(.numericText(value: Double(items.count)))
                    Spacer()
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityHint(isOpen ? "Folds the basket" : "Shows what's in the basket")
            if isOpen {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        Button { onTap(item) } label: {
                            Text(item.text)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.inkTertiary)
                                .textRenderer(CompletionRenderer(progress: 1, color: Theme.Colors.inkTertiary))
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(HandleButtonStyle())
                        .accessibilityHint("Puts it back on the list")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct GroceriesEmpty: View {
    let basket: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(basket > 0 ? "All in the basket." : "Nothing to buy.")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
            Text("Write above, or swipe a recipe's ingredients across.")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
        }
    }
}

enum GroceriesCopy {
    /// "9 to buy across 4 aisles", "Shopping, 3 left".
    static func context(open: Int, aisles: Int, shopping: Bool) -> String {
        if shopping {
            return open == 0 ? "Shopping, all in the basket" : "Shopping, \(open) left"
        }
        guard open > 0 else { return "One list for the kitchen" }
        let aisleText = aisles == 1 ? "one aisle" : "\(aisles) aisles"
        return "\(open) to buy across \(aisleText)"
    }

    /// "eggs, milk and 2 lemons" → three lines.
    static func lines(in text: String) -> [String] {
        text.replacing(/\s+and\s+/, with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#if DEBUG
    /// `-demoKitchen`: two recipes, both on the groceries list, plus a few typed things.
    @MainActor
    enum KitchenDemo {
        static let carbonara = """
        Spaghetti carbonara
        Serves 2
        Total time: 25 min
        Ingredients
        200 g spaghetti
        100 g guanciale, diced
        3 eggs
        50 g pecorino, finely grated
        Black pepper, to taste
        Method
        Boil the spaghetti in salted water for 10 minutes.
        Fry the guanciale for 5–6 min until crisp.
        Whisk the eggs with the pecorino and plenty of pepper.
        Toss everything off the heat, loosen with pasta water and serve.
        """

        static let dal = """
        Weeknight dal
        Serves 4
        Ingredients
        250 g red lentils
        1 onion, finely chopped
        3 cloves garlic, crushed
        1 tbsp ginger, grated
        400 ml coconut milk
        1 tsp turmeric
        a handful of coriander
        Method
        Soften the onion, garlic and ginger for 8 minutes.
        Add the lentils, turmeric and 700 ml water and simmer for 20–25 minutes.
        Stir in the coconut milk, warm through and finish with the coriander.
        """

        static func seedIfRequested(_ model: AppModel) {
            guard ProcessInfo.processInfo.arguments.contains("-demoKitchen"),
                  RecipeBook(store: model.store, classes: model.classes).recipes().isEmpty else { return }
            for text in [carbonara, dal] {
                if let recipe = try? model.engine.perform(CreateRecipe(text: text), by: .user).output {
                    _ = try? model.engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
                }
            }
            _ = try? model.engine.perform(AddGroceries(lines: ["milk", "2 lemons", "sourdough", "kitchen roll"]),
                                          by: .user)
            model.touch()
        }
    }
#endif

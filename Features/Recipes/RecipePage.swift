import SwiftUI
import TesseraCore

/// A recipe (kitchen screen 10). The name is the hero; one context line says its size, time and when it was last
/// cooked. The size is a portion drum: turn it and every amount re-sets itself with a tabular roll. Ingredients sit
/// in one column at body size, amount in 600 and name in 400, staples dimmer, no bullets or separators. Steps don't
/// show here: their count peeks at the bottom over the one key, Cook.
///
/// One gesture away, never on screen by default: tap an ingredient to zoom into it; tap the name for the original
/// text and cook history; swipe the ingredient column left to send it to Groceries.
struct RecipePage: View {
    let recipeID: UUID
    var onCook: (UUID, Int?) -> Void = { _, _ in }

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var zoom
    @State private var serves: Int?
    @State private var sent: Int?
    @State private var drag: CGFloat = 0
    @State private var path: [Route] = []

    var body: some View {
        let _ = model.revision
        let book = RecipeBook(store: model.store, classes: model.classes)
        if let recipe = model.store.object(id: recipeID), !recipe.isDeleted {
            let size = serves ?? book.serves(recipe)
            let lines = size.map { book.scaledLines(of: recipe, serves: $0) } ?? book.lines(of: recipe)
            let steps = book.steps(of: recipe)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(value: Route.object(recipe.id)) {
                        Text(recipe.title)
                            .textRole(.hero)
                            .foregroundStyle(Theme.Colors.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .matchedTransitionSource(id: recipe.id, in: zoom)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHint("The original text and when it was cooked")
                    .entrance(0, hero: true)

                    Text(RecipeCopy.context(recipe, serves: size, model: model, now: AppClock.now))
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.s)
                        .entrance(1)

                    HStack(alignment: .top, spacing: Theme.Spacing.l) {
                        IngredientColumn(lines: lines, zoom: zoom)
                            .offset(x: min(0, drag))
                            .opacity(1 - Double(min(1, -drag / 260)) * 0.6)
                            .gesture(sendGesture(recipe: recipe.id, serves: size))
                        if size != nil {
                            PortionDrum(serves: Binding(get: { size ?? 2 }, set: { serves = $0 }))
                                .accessibilityLabel("Serves")
                        }
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(2)

                    if let sent {
                        Text("\(sent) to buy")
                            .textRole(.labelStrong)
                            .foregroundStyle(Theme.Colors.health)
                            .padding(.top, Theme.Spacing.m)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text(steps.count == 1 ? "1 step" : "\(steps.count) steps")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                        PaintKey(paint: Theme.Colors.now, isTap: true, action: { onCook(recipe.id, size) }) { _ in
                            Text("Cook")
                                .textRole(.labelStrong)
                        }
                        .accessibilityHint("Starts cook mode at this size")
                    }
                    .padding(.top, Theme.Spacing.section)
                    .entrance(3)
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.section)
            }
            .scrollIndicators(.hidden)
            .background { ThemedBackground() }
            .navigationDestination(for: Route.self) { route in
                RecipeDepth(route: route)
                    .navigationTransition(.zoom(sourceID: routeID(route), in: zoom))
            }
            .tesseraAnimation(Theme.Motion.house, value: sent)
        } else {
            Text("This recipe is gone. Undo brings it back.")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { ThemedBackground() }
        }
    }

    private func routeID(_ route: Route) -> UUID {
        switch route {
        case let .object(id), let .classDef(id): id
        }
    }

    /// Swipe the column left: it slides toward the Groceries edge and leaves a count behind.
    private func sendGesture(recipe: UUID, serves: Int?) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                drag = value.translation.width
            }
            .onEnded { value in
                let send = value.translation.width < -120 || value.predictedEndTranslation.width < -260
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                    if send {
                        let items = try? model.engine.perform(AddRecipeToGroceries(recipe: recipe, serves: serves),
                                                              by: .user).output
                        sent = items?.count ?? 0
                        model.touch()
                    }
                    drag = 0
                }
            }
    }
}

/// The ingredients: amount in 600, name in 400, staples and "to taste" dimmer. Tap one to zoom into it.
private struct IngredientColumn: View {
    let lines: [RecipeBook.Line]
    let zoom: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ForEach(lines) { line in
                let dim = line.isStaple || line.line.toTaste
                NavigationLink(value: Route.object(line.ingredient?.id ?? line.id)) {
                    (Text(line.line.quantityText.map { "\($0) " } ?? "")
                        .fontWeight(.semibold)
                        .foregroundStyle(dim ? Theme.Colors.inkTertiary : Theme.Colors.ink)
                        + Text(RecipeCopy.name(of: line.line))
                        .foregroundStyle(dim ? Theme.Colors.inkTertiary : Theme.Colors.ink))
                        .textRole(.body)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                }
                .buttonStyle(HandleButtonStyle())
                .matchedTransitionSource(id: line.ingredient?.id ?? line.id, in: zoom)
                .accessibilityHint("Opens the ingredient")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ingredients")
        .accessibilityHint("Swipe left to add them to groceries")
    }
}

/// One level deeper: an ingredient (its object page) or the recipe's original text and cook history.
private struct RecipeDepth: View {
    let route: Route
    @Environment(AppModel.self) private var model

    var body: some View {
        if case let .object(id) = route, let object = model.store.object(id: id),
           object.classDef?.id == model.classes[.recipe]?.id
        {
            RecipeOriginal(recipe: object)
        } else {
            ObjectPage(route: route)
        }
    }
}

/// The pasted text, verbatim, and when it was cooked.
private struct RecipeOriginal: View {
    let recipe: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        let cooks = CookLog(store: model.store, classes: model.classes).cooks(of: recipe)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                Text(recipe.title)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                MarginSection(label: "Cooked", color: Theme.Colors.now) {
                    if cooks.isEmpty {
                        Text("Not yet.")
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    } else {
                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            ForEach(cooks, id: \.cook.id) { cook in
                                Text(RecipeCopy.cookLine(cook.cook, at: cook.at, model: model))
                                    .textRole(.body)
                                    .foregroundStyle(Theme.Colors.ink)
                            }
                        }
                    }
                }
                MarginSection(label: "As pasted") {
                    Text(model.store.value("sourceText", of: recipe)?.stringValue ?? "")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }
}

@MainActor
enum RecipeCopy {
    /// "serves 2 · 25 min · cooked 12 days ago" (each part only when known).
    static func context(_ recipe: ObjectRecord, serves: Int?, model: AppModel, now: Date) -> String {
        var parts: [String] = []
        if let serves {
            parts.append("serves \(serves)")
        }
        if let total = model.store.number("totalMinutes", of: recipe) {
            parts.append(total >= 60 ? "\(hours(total)) h" : "\(Int(total)) min")
        }
        let last = CookLog(store: model.store, classes: model.classes).lastCooked(recipe)
        parts.append(last.map { "cooked \(relative($0, now: now))" } ?? "not cooked yet")
        return parts.joined(separator: " · ")
    }

    static func hours(_ minutes: Double) -> String {
        (minutes / 60).formatted(.number.precision(.fractionLength(0 ... 1)))
    }

    static func relative(_ date: Date, now: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: date),
                                                   to: Calendar.current.startOfDay(for: now)).day ?? 0
        return switch days {
        case ..<1: "today"
        case 1: "yesterday"
        default: "\(days) days ago"
        }
    }

    /// The ingredient's name with its prep: "guanciale, diced".
    static func name(of line: IngredientLine) -> String {
        let taste = line.toTaste ? ", to taste" : ""
        return line.prep.map { "\(line.name), \($0)" + taste } ?? line.name + taste
    }

    static func cookLine(_ cook: ObjectRecord, at date: Date, model: AppModel) -> String {
        let size = CookLog(store: model.store, classes: model.classes).serves(of: cook).map { ", for \($0)" } ?? ""
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide)) + size
    }
}


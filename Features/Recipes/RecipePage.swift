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
    /// What Cook opens. Until cook mode (screen 12) lands, the page starts the cook itself and shows it running.
    var onCook: ((UUID, Int?) -> Void)?

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Namespace private var zoom
    @State private var serves: Int?
    @State private var sent: (count: Int, record: OpRecord)?
    @State private var drag: CGFloat = 0
    @State private var columnWidth: CGFloat = 260
    @State private var away = false

    var body: some View {
        page.task(id: recipeID) { markOpened() }
    }

    /// Kitchen week one: when the page last opened, written straight to the store (no op, so the log isn't
    /// flooded) and never shown.
    private func markOpened() {
        guard let recipe = model.store.object(id: recipeID) else { return }
        try? model.store.set("lastOpenedAt", to: .date(AppClock.now), on: recipe)
    }

    @ViewBuilder private var page: some View {
        let _ = model.revision
        let book = RecipeBook(store: model.store, classes: model.classes)
        if let recipe = model.store.object(id: recipeID), !recipe.isDeleted {
            let own = book.serves(recipe)
            let size = serves ?? own
            let lines = size.map { book.scaledLines(of: recipe, serves: $0) } ?? book.lines(of: recipe)
            let steps = book.steps(of: recipe)
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("Recipes")
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 32)
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityHint("Back to the recipes")
                .entrance(0)

                NavigationLink(value: Route.object(recipe.id)) {
                    Text(recipe.title)
                        .textRole(.hero)
                        .foregroundStyle(Theme.Colors.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(HandleButtonStyle())
                .matchedTransitionSource(id: recipe.id, in: zoom)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHint("The original text and when it was cooked")
                .entrance(1, hero: true)

                Text(RecipeCopy.context(recipe, serves: size, model: model, now: AppClock.now))
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(2)

                ZStack(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: Theme.Spacing.m) {
                        ScrollView {
                            IngredientColumn(lines: lines, zoom: zoom)
                                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { columnWidth = $0 }
                        }
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                        .offset(x: away ? -columnWidth * 1.4 : min(0, drag))
                        .simultaneousGesture(sendGesture(recipe: recipe.id, serves: size))
                        PortionDrum(serves: Binding(get: { size ?? 2 }, set: { serves = $0 }), isEnabled: own != nil)
                    }
                    if let sent {
                        SentLine(count: sent.count) { undoSend(sent.record) }
                            .frame(width: columnWidth)
                            .transition(.opacity)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, Theme.Spacing.xl)
                .entrance(3)

                // Already on the list (and not just sent): how much of it is still to buy.
                let onList = Groceries(store: model.store, classes: model.classes).share(of: recipe).count
                if sent == nil, onList > 0 {
                    (Text("\(onList)").fontWeight(.semibold) + Text(" to buy, in Groceries"))
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.health)
                        .padding(.top, Theme.Spacing.s)
                        .transition(.opacity)
                }

                Text(steps.count == 1 ? "1 step" : "\(steps.count) steps")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.m)
                let cooking = RecipeCopy.cookStep(of: recipe, model: model)
                HStack(spacing: Theme.Spacing.l) {
                    PaintKey(finish: .ink, paint: Theme.Colors.now, isTap: true,
                             action: { cook(recipe.id, size) })
                    { _ in
                        Text(cooking == nil ? "Cook" : "Cooking")
                    }
                    .frame(maxWidth: 220)
                    .accessibilityHint(cooking == nil ? "Starts cooking at this size" : "It's cooking now")
                    if let cooking {
                        Text(cooking)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.now)
                            .transition(.opacity)
                    }
                }
                .padding(.top, Theme.Spacing.s)
                .tesseraAnimation(Theme.Motion.house, value: cooking)
                .entrance(4)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.l)
            .background { ThemedBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                RecipeDepth(route: route)
                    .navigationTransition(.zoom(sourceID: routeID(route), in: zoom))
            }
            .sensoryFeedback(.success, trigger: sent?.count)
        } else {
            Text("This recipe is gone. Undo brings it back.")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { ThemedBackground() }
        }
    }

    private func cook(_ recipe: UUID, _ serves: Int?) {
        if let onCook {
            onCook(recipe, serves)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            _ = try? model.engine.perform(StartCooking(recipe: recipe, serves: serves), by: .user)
            model.touch()
        }
    }

    private func routeID(_ route: Route) -> UUID {
        switch route {
        case let .object(id), let .classDef(id): id
        }
    }

    /// Swipe the column left: past 40% of its width it slides off toward Groceries and leaves "12 to buy" behind;
    /// after 4 s it comes back.
    private func sendGesture(recipe: UUID, serves: Int?) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height), sent == nil else { return }
                drag = value.translation.width
            }
            .onEnded { value in
                let send = -value.translation.width > columnWidth * 0.4
                    || -value.predictedEndTranslation.width > columnWidth
                guard send, sent == nil else {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { drag = 0 }
                    return
                }
                guard let result = try? model.engine.perform(AddRecipeToGroceries(recipe: recipe, serves: serves),
                                                             by: .user) else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.36)) {
                    away = true
                    drag = 0
                    sent = (result.output.count, result.record)
                    model.touch()
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                        away = false
                        sent = nil
                    }
                }
            }
    }

    private func undoSend(_ record: OpRecord) {
        model.engine.undo(record)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            away = false
            sent = nil
            model.touch()
        }
    }
}

/// "12 to buy, in Groceries" where the column was, with Undo.
private struct SentLine: View {
    let count: Int
    let undo: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            (Text("\(count)").fontWeight(.semibold) + Text(" to buy, in Groceries"))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.health)
            Spacer()
            Button("Undo", action: undo)
                .buttonStyle(InkLabelWordStyle(color: Theme.Colors.live))
                .frame(minHeight: 44)
        }
        .padding(.top, Theme.Spacing.m)
    }
}

/// The ingredients: amount in 600 in a fixed tabular column (so nothing jumps when it rolls), name in 400, prep in
/// secondary ink; staples at 45% with their amounts at 400. Tap a row to zoom into the ingredient; tap a spoon or
/// cup amount to see it in metric for a moment.
private struct IngredientColumn: View {
    let lines: [RecipeBook.Line]
    let zoom: Namespace.ID
    @State private var metric: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                let dim = line.isStaple || line.line.toTaste
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text(amount(line))
                        .textRole(.body)
                        .fontWeight(dim ? .regular : .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.ink)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .smooth(duration: 0.22).delay(Double(index) * 0.015),
                                   value: line.line.amount)
                        .frame(width: 92, alignment: .leading)
                        .onTapGesture { flip(line) }
                    NavigationLink(value: Route.object(line.ingredient?.id ?? line.id)) {
                        (Text(line.line.name)
                            .foregroundStyle(Theme.Colors.ink)
                            + Text(line.line.prep.map { ", \($0)" } ?? "")
                            .foregroundStyle(Theme.Colors.inkSecondary))
                            .textRole(.body)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .matchedTransitionSource(id: line.ingredient?.id ?? line.id, in: zoom)
                    .accessibilityHint("Opens the ingredient")
                }
                .opacity(dim ? 0.45 : 1)
                .frame(minHeight: 44)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ingredients")
        .accessibilityHint("Swipe left to add them to groceries")
    }

    private func amount(_ line: RecipeBook.Line) -> String {
        if metric == line.id, let text = line.line.metricText {
            return text
        }
        return line.line.quantityText ?? (line.line.toTaste ? "to taste" : "")
    }

    private func flip(_ line: RecipeBook.Line) {
        guard line.line.metricText != nil else { return }
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { metric = line.id }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if metric == line.id {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { metric = nil }
            }
        }
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
    /// "serves 2, 25 min, cooked 12 days ago" (each part only when known; never "never cooked").
    static func context(_ recipe: ObjectRecord, serves: Int?, model: AppModel, now: Date) -> String {
        var parts: [String] = []
        if let serves {
            parts.append("serves \(serves)")
        }
        if let total = model.store.number("totalMinutes", of: recipe) {
            parts.append(total >= 60 ? "\(hours(total)) h" : "\(Int(total)) min")
        }
        if let last = CookLog(store: model.store, classes: model.classes).lastCooked(recipe) {
            parts.append("cooked \(relative(last, now: now))")
        }
        return parts.joined(separator: ", ")
    }

    /// "Step 1 of 4" while this recipe is cooking, else nil.
    static func cookStep(of recipe: ObjectRecord, model: AppModel) -> String? {
        guard let running = ProcessTable(engine: model.engine).running(), let cook = running.subject,
              model.store.linkedObjects("recipe", of: cook).first?.id == recipe.id else { return nil }
        let steps = RecipeBook(store: model.store, classes: model.classes).steps(of: recipe).count
        return "Step \((running.resumePoint?.index ?? 0) + 1) of \(steps)"
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

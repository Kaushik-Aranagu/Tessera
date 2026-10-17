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
    /// Turned on in the PR that lands cook mode (screen 12): until then there is no Cook key (G55).
    static let cookModeReady = false
    let recipeID: UUID
    /// What Cook opens. Until cook mode (screen 12) lands, the page starts the cook itself and shows it running.
    var onCook: ((UUID, Int?) -> Void)?

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Namespace private var zoom
    @State private var serves: Int?
    @State private var sent: (line: String, record: OpRecord)?
    /// When the receipt went up, so a hand-off keeps what is left of its window rather than a fresh 10 s (QA on #819).
    @State private var sentAt: Date?
    @State private var drag: CGFloat = 0
    @State private var columnWidth: CGFloat = 260
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var away = false
    /// A private recipe's title, tapped open for this visit; leaving or locking masks it again (G53).
    @State private var titleShown = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // At accessibility sizes the whole page is one scroll, so nothing is clipped (G69).
        if typeSize.isAccessibilitySize {
            ScrollView { page }
                .scrollIndicators(.hidden)
                .background { ThemedBackground() }
                .task(id: recipeID) { markOpened() }
        } else {
            page.task(id: recipeID) { markOpened() }
        }
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
        if !RecipeCopy.isGone(recipeID, store: model.store), let recipe = model.store.object(id: recipeID) {
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

                let masked = RecipeCopy.isPrivate(recipe.title, model: model) && !titleShown
                Group {
                    if masked {
                        // A private recipe reads "Private recipe" until tapped (G53); the next tap opens as usual.
                        Button {
                            withTesseraAnimation(reduceMotion: reduceMotion) { titleShown = true }
                        } label: {
                            heroTitle(ObjectPrivacy.recipeLabel)
                        }
                        .accessibilityHint("Shows it")
                    } else {
                        NavigationLink(value: Route.object(recipe.id)) { heroTitle(recipe.title) }
                            .accessibilityHint("The original text and when it was cooked")
                    }
                }
                .buttonStyle(HandleButtonStyle())
                .matchedTransitionSource(id: recipe.id, in: zoom)
                .accessibilityAddTraits(.isHeader)
                .entrance(1, hero: true)

                Text(RecipeCopy.context(recipe, serves: size, model: model, now: AppClock.now))
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(2)

                ZStack(alignment: .topLeading) {
                    let column = IngredientColumn(lines: lines, zoom: zoom) { send(recipe: recipe.id, serves: size) }
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { columnWidth = $0 }
                    let drum = PortionDrum(serves: Binding(get: { min(max(size ?? 2, 1), 48) }, set: { serves = $0 }),
                                           isEnabled: own != nil, range: PortionDrum.range(written: own))
                    if typeSize.isAccessibilitySize {
                        // The page scrolls as one, the drum above the list (G69).
                        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                            drum
                            column
                                .offset(x: away ? -columnWidth * 1.4 : min(0, drag))
                                .simultaneousGesture(sendGesture(recipe: recipe.id, serves: size))
                        }
                    } else {
                        HStack(alignment: .top, spacing: Theme.Spacing.m) {
                            ScrollView { column }
                                .scrollIndicators(.hidden)
                                .scrollBounceBehavior(.basedOnSize)
                                .offset(x: away ? -columnWidth * 1.4 : min(0, drag))
                                .simultaneousGesture(sendGesture(recipe: recipe.id, serves: size))
                            drum
                        }
                    }
                    if let sent {
                        SentLine(line: sent.line) { undoSend(sent.record) }
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
                    (Text("\(onList)").fontWeight(.semibold) + Text(" to buy, on Groceries"))
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .padding(.top, Theme.Spacing.s)
                        .transition(.opacity)
                }

                Text(RecipeCopy.stepCount(steps.count))
                    .textRole(steps.isEmpty ? .body : .label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.m)
                let cooking = RecipeCopy.cookStep(of: recipe, model: model)
                HStack(spacing: Theme.Spacing.l) {
                    // No Cook key until cook mode lands: a cook nobody can see is worse than none (G55, Product).
                    if Self.cookModeReady {
                        PaintKey(finish: .ink, paint: Theme.Colors.now, isTap: true,
                                 action: { cook(recipe.id, size) })
                        { _ in
                            Text(cooking == nil ? "Cook" : "Cooking")
                        }
                        .frame(maxWidth: 220)
                        .accessibilityHint(cooking == nil ? "Starts cooking at this size" : "It's cooking now")
                    }
                    if let cooking {
                        Text(cooking)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.ink)
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
            .tesseraFeedback(.made, trigger: sent?.line)
            .onDisappear {
                titleShown = false
                // Leaving inside the window hands the receipt and its UNDO to Tess's shared line, so the UNDO
                // follows him (G67).
                if let sent {
                    TessVoice.shared.say(sent.line, undo: sent.record,
                                         holds: RecipeCopy.holdLeft(since: sentAt, now: .now))
                    self.sent = nil
                    away = false
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    titleShown = false
                }
            }
        } else {
            // Product's wording (kitchen gap hunt G3): the fact, then the one way back.
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("Recipe gone.")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                Button("Back to the list") { dismiss() }
                    .buttonStyle(.labelWord(Theme.Colors.ink))
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background { ThemedBackground() }
            .background { EdgeSwipeBack() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func heroTitle(_ text: String) -> some View {
        Text(text)
            .textRole(.hero)
            .foregroundStyle(Theme.Colors.ink)
            .multilineTextAlignment(.leading)
            // At accessibility sizes the name wraps in full rather than shrinking (G69).
            .lineLimit(typeSize.isAccessibilitySize ? nil : 3)
            .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cook(_ recipe: UUID, _ serves: Int?) {
        if let onCook {
            onCook(recipe, serves)
            return
        }
        let refusal = RecipeCopy.startCook {
            try model.engine.perform(StartCooking(recipe: recipe, serves: serves), by: .user)
        }
        // Refused (a workout running, G56): no cook starts, the workout is untouched, and Tess says why.
        if let refusal {
            TessVoice.shared.say(refusal)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
    }

    private func routeID(_ route: Route) -> UUID {
        switch route {
        case let .object(id), let .classDef(id), let .routines(id): id
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
                self.send(recipe: recipe, serves: serves)
            }
    }

    /// The add, from the swipe or VoiceOver's "Add all to Groceries" (G58, K87.8). Added: the column leaves and the
    /// engine's "Tacos, 7 added." stands in its place with UNDO 10 s. Nothing new: the column stays, one line
    /// "Tacos, nothing to add.", no UNDO. Refused: the column springs back and Tess says so.
    private func send(recipe: UUID, serves: Int?) {
        // One add at a time: a second (VoiceOver's action) never replaces the first's UNDO (QA on #819).
        guard sent == nil else { return }
        let title = model.store.object(id: recipe)?.title ?? ""
        let outcome = RecipeCopy.send(isPrivate: RecipeCopy.isPrivate(title, model: model)) {
            let result = try model.engine.perform(AddRecipeToGroceries(recipe: recipe, serves: serves), by: .user)
            return (result.output.count, result.record)
        }
        guard case let .added(line, record) = outcome else {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { drag = 0 }
            if case let .nothing(line) = outcome {
                TessVoice.shared.say(line)
            } else if case let .failed(line) = outcome {
                TessVoice.shared.say(line)
            }
            return
        }
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.36)) {
            away = true
            drag = 0
            sent = (line, record)
            sentAt = .now
            model.touch()
        }
        UIAccessibility.post(notification: .announcement, argument: line)
        Task { @MainActor in
            try? await Task.sleep(for: TessVoice.hold(undo: true, holds: .seconds(10)))
            guard sent?.record.id == record.id else { return }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                away = false
                sent = nil
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

/// "Tacos, 7 added." where the column was, with Undo (K34.7, K37.6).
private struct SentLine: View {
    let line: String
    let undo: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(line)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Button("Undo", action: undo)
                .buttonStyle(InkLabelWordStyle.undo)
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
    /// "1 1/2 tbsp" fits at every text size (G69).
    @ScaledMetric(relativeTo: .body) private var amountWidth: CGFloat = 92
    /// The same add as the swipe, for VoiceOver and Switch Control (G58).
    var onAdd: () -> Void = {}
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
                        .frame(width: amountWidth, alignment: .leading)
                        .onTapGesture { flip(line) }
                    NavigationLink(value: Route.object(line.ingredient?.id ?? line.id)) {
                        (Text(line.line.name)
                            .foregroundStyle(Theme.Colors.ink)
                            + Text(line.line.prep.map { ", \($0)" } ?? "")
                            .foregroundStyle(Theme.Colors.inkSecondary))
                            .textRole(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .matchedTransitionSource(id: line.ingredient?.id ?? line.id, in: zoom)
                    .accessibilityHint("Opens the ingredient")
                }
                .opacity(dim ? 0.45 : 1)
                .frame(minHeight: 44)
                // One stop per row: "2 cups flour, chopped"; activating opens the ingredient (G58).
                .accessibilityElement(children: .combine)
                .accessibilityLabel(RecipeCopy.spokenRow(amount(line), line.line))
                .accessibilityActions {
                    // Only the row's own action here; adding the recipe lives on the list as a whole (G68).
                    if line.line.metricText != nil {
                        Button("Show in metric") { flip(line) }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ingredients")
        .accessibilityAction(named: Text(RecipeCopy.addAllAction), onAdd)
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
    /// The title tapped open on this page; leaving or locking masks it again (G53).
    @State private var titleShown = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let cooks = CookLog(store: model.store, classes: model.classes).cooks(of: recipe)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                let isPrivate = RecipeCopy.isPrivate(recipe.title, model: model)
                Text(RecipeCopy.shownTitle(recipe.title, isPrivate: isPrivate, shown: titleShown))
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .onTapGesture { titleShown = true }
                    .accessibilityAddTraits(isPrivate && !titleShown ? .isButton : [])
                    .accessibilityHint(isPrivate && !titleShown ? "Shows it" : "")
                    .onDisappear { titleShown = false }
                MarginSection(label: "Cooked", color: Theme.Colors.inkSecondary) {
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
                // Only when there's text he pasted: a recipe made another way has no AS PASTED (gap hunt G4).
                if let pasted = RecipeCopy.pasted(model.store.value("sourceText", of: recipe)?.stringValue) {
                    // The title's own line in the paste stays masked while the title is (QA on #752).
                    let source = RecipeCopy.maskedSource(pasted, title: recipe.title, masked: isPrivate && !titleShown)
                    MarginSection(label: "As pasted") {
                        Text(source)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                titleShown = false
            }
        }
    }
}

@MainActor
enum RecipeCopy {
    /// What is left of the add's 10 s UNDO window, at least 1 s (VoiceOver keeps its flat 10 s in TessVoice).
    static func holdLeft(since start: Date?, now: Date) -> Duration {
        let elapsed = start.map { now.timeIntervalSince($0) } ?? 0
        return .milliseconds(Int(max(1, 10 - elapsed) * 1000))
    }

    /// VoiceOver's action on the ingredients as a whole: it adds every line, so it says "all" (G68).
    static let addAllAction = "Add all to Groceries"

    /// What the recipe page's add came to.
    enum SendOutcome: Equatable {
        /// New rows: the engine's "Tacos, 7 added." with UNDO.
        case added(String, OpRecord)
        /// Everything was already there or a staple: "Tacos, nothing to add.", no UNDO (Product e1981a39).
        case nothing(String)
        case failed(String)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.added(a, x), .added(b, y)): a == b && x === y
            case let (.nothing(a), .nothing(b)), let (.failed(a), .failed(b)): a == b
            default: false
            }
        }
    }

    /// The add's outcome from the engine: its own summary line ("Tacos, 7 added." / "Tacos, nothing to add.").
    /// A private recipe never lends its name (G53, QA on #808): "Private recipe, 7 added." / "Private recipe,
    /// nothing to add.", built from the count, never from the engine's line.
    static func send(isPrivate: Bool = false,
                     _ perform: () throws -> (count: Int, record: OpRecord)) -> SendOutcome
    {
        guard let result = try? perform() else { return .failed("Didn't save that. Try again.") }
        let line = isPrivate
            ? "Private recipe, \(result.count == 0 ? "nothing to add" : "\(result.count) added")."
            : result.record.receipt ?? result.record.summary
        return result.count == 0 ? .nothing(line) : .added(line, result.record)
    }

    /// One VoiceOver stop per ingredient row: "2 cups flour, chopped".
    static func spokenRow(_ amount: String, _ line: IngredientLine) -> String {
        [amount, line.name].filter { !$0.isEmpty }.joined(separator: " ") + (line.prep.map { ", \($0)" } ?? "")
    }

    /// What Tess says when a write that starts or resumes something is refused: the engine's "Workout running."
    /// while a workout runs (G56; the Cook key and Resume), "Didn't save that. Try again." for any other refusal, nil
    /// when it went through.
    static func startCook(_ perform: () throws -> some Any) -> String? {
        do {
            _ = try perform()
            return nil
        } catch let ActionError.invalidArguments(_, reason) where reason == StartCooking.workoutRunningReason {
            return StartCooking.workoutRunningLine
        } catch {
            return "Didn't save that. Try again."
        }
    }

    /// Whether a recipe's title is private (the full recipe wall), so every surface reads "Private recipe" (G53).
    /// Switches to Core's helper when it lands.
    static func isPrivate(_ title: String, model: AppModel) -> Bool {
        ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: BodyWeight.lastKg(in: model.store))
    }

    /// The pasted text with any line that holds the title (any case, any "# ", "**" or ":" around it, as the parser
    /// trims) read as "Private recipe" while masked (QA on #752).
    static func maskedSource(_ source: String, title: String, masked: Bool) -> String {
        let key = title.trimmingCharacters(in: CharacterSet(charactersIn: "#*: ").union(.whitespacesAndNewlines))
            .lowercased()
        guard masked, !key.isEmpty else { return source }
        return source.components(separatedBy: "\n").map { line in
            line.lowercased().contains(key) ? ObjectPrivacy.recipeLabel : line
        }.joined(separator: "\n")
    }

    /// Paste's receipt, thing first: "Carbonara, on Recipes."; a private one "Private recipe, on Recipes." (K87.3).
    static func saved(_ shownTitle: String) -> String {
        "\(shortName(shownTitle)), on Recipes."
    }

    /// A receipt's short name: the title's first noun phrase (Product 4:57, K87.2), so a long title never makes a long
    /// line: "Sheet-pan paprika chicken with lemon" reads "Sheet-pan paprika chicken"; "Chili con carne" stays whole.
    static func shortName(_ title: String) -> String {
        var name = title
        for cut in [" with ", ", ", ": ", " (", " - ", " – ", " — "] {
            if let range = name.range(of: cut, options: .caseInsensitive) {
                name = String(name[..<range.lowerBound])
            }
        }
        return name.trimmingCharacters(in: .whitespaces)
    }

    /// The title a surface shows: "Private recipe" for a private one unless it's been tapped open.
    static func shownTitle(_ title: String, isPrivate: Bool, shown: Bool) -> String {
        isPrivate && !shown ? ObjectPrivacy.recipeLabel : title
    }

    /// The text he pasted, or nil when there is none or only blank space.
    static func pasted(_ source: String?) -> String? {
        guard let source, !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return source
    }

    /// "serves 2, 25 min, cooked 12 days ago" (each part only when known; never "never cooked").
    static func context(_ recipe: ObjectRecord, serves: Int?, model: AppModel, now: Date) -> String {
        var parts: [String] = []
        if let serves {
            parts.append("serves \(serves)")
        }
        if let total = model.store.number("totalMinutes", of: recipe) {
            parts.append(duration(total))
        }
        if let last = CookLog(store: model.store, classes: model.classes).lastCooked(recipe) {
            parts.append("cooked \(relative(last, now: now))")
        }
        return parts.joined(separator: ", ")
    }

    /// Whether the recipe a page shows is gone, so it reads "Recipe gone." with a way back (G3).
    static func isGone(_ id: UUID, store: ObjectStore) -> Bool {
        store.object(id: id).map(\.isDeleted) ?? true
    }

    /// "Step 1 of 4" while this recipe is cooking, else nil; never "Step 1 of 0" (G55).
    static func cookStep(of recipe: ObjectRecord, model: AppModel) -> String? {
        guard let running = ProcessTable(engine: model.engine).running(), let cook = running.subject,
              model.store.linkedObjects("recipe", of: cook).first?.id == recipe.id else { return nil }
        let steps = RecipeBook(store: model.store, classes: model.classes).steps(of: recipe).count
        return steps > 0 ? "Step \((running.resumePoint?.index ?? 0) + 1) of \(steps)" : nil
    }

    /// "4 steps", "1 step", and with none, "No steps yet. Paste them below." (G55, Product).
    static func stepCount(_ count: Int) -> String {
        switch count {
        case 0: "No steps yet. Paste them below."
        case 1: "1 step"
        default: "\(count) steps"
        }
    }

    /// Hours and minutes, as the cook log says them (O2, G60): "1 h 35 min", "1 h", "45 min". Never "1.6 h".
    static func duration(_ minutes: Double) -> String {
        // NaN, infinity or an absurd stored value never traps the page (G62): at most 99 h 59 min.
        guard minutes.isFinite else { return "0 min" }
        let total = Int(min(max(minutes, 0), 5999).rounded())
        let (hours, rest) = (total / 60, total % 60)
        if hours == 0 {
            return "\(rest) min"
        }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }

    /// "today", "yesterday", "40 days ago", then months ("3 months ago"), then "last year" / "2 years ago" (G60).
    static func relative(_ date: Date, now: Date) -> String {
        let tesseraDay = TesseraDay()
        let days = Calendar.current.dateComponents([.day], from: tesseraDay.day(of: date),
                                                   to: tesseraDay.today(now)).day ?? 0
        return switch days {
        case ..<1: "today"
        case 1: "yesterday"
        case ..<60: "\(days) days ago"
        case ..<365: "\(days / 30) months ago"
        case ..<730: "last year"
        default: "\(days / 365) years ago"
        }
    }

    /// The ingredient's name with its prep: "guanciale, diced".
    static func name(of line: IngredientLine) -> String {
        let taste = line.toTaste ? ", to taste" : ""
        return line.prep.map { "\(line.name), \($0)" + taste } ?? line.name + taste
    }

    static func cookLine(_ cook: ObjectRecord, at date: Date, model: AppModel, now: Date = AppClock.now) -> String {
        let size = CookLog(store: model.store, classes: model.classes).serves(of: cook).map { ", for \($0)" } ?? ""
        return cookDay(date, now: now) + size
    }

    /// "Tuesday, October 14, 9:05 am"; a date outside this year adds it: "Tuesday, October 14, 2025, 9:05 am" (G60).
    static func cookDay(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        let day = sameYear ? date.formatted(.dateTime.weekday(.wide).day().month(.wide))
            : date.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
        return "\(day), \(HouseTime.clock(date, calendar: calendar))"
    }
}

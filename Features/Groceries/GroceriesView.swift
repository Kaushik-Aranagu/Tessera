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
    @State private var sinking: [Sink] = []
    @State private var basketOpen = false
    @State private var basketTarget: CGPoint = .zero
    @State private var breathe = false
    @State private var landed = 0
    /// SHOP mode's rows: a private one is always masked (G102).
    @State private var trip = ShopTrip()
    @FocusState private var writing: Bool

    private var groceries: Groceries {
        Groceries(store: model.store, classes: model.classes)
    }

    /// A struck item's dab, falling into the basket.
    struct Sink: Identifiable {
        let id: UUID
        var x: CGFloat
        var y: CGFloat
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

                // Shop and list share one slot: the outgoing layout folds back as the incoming one rises (never a
                // cross-fade of two whole layouts).
                ZStack(alignment: .topLeading) {
                    if shopping {
                        AtTheShop(aisles: aisles, striking: striking, recipes: recipes(for:),
                                  label: rowLabel,
                                  onTap: shopTap)
                            .padding(.top, Theme.Spacing.m)
                            .transition(AisleHandoff.transition(reduceMotion: reduceMotion))
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ShopTitle(onHold: toggleShop)
                                .padding(.top, Theme.Spacing.s)
                                .entrance(1, hero: true)

                            GroceryWritingLine(text: $draft, focused: $writing, onSubmit: add)
                                .padding(.top, Theme.Spacing.xl)
                                .entrance(2)

                            if aisles.isEmpty {
                                GroceriesEmpty(basket: basket.count)
                                    .padding(.top, Theme.Spacing.section)
                                    .entrance(3)
                            } else {
                                VStack(alignment: .leading, spacing: 24) {
                                    ForEach(Array(aisles.enumerated()), id: \.element.aisle) { index, aisle in
                                        AisleSection(name: aisle.aisle, items: aisle.items, striking: striking,
                                                     recipes: recipes(for:), label: rowLabel, onTap: shopTap)
                                            .entrance(3 + min(index, 3))
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.top, Theme.Spacing.xxl)
                            }
                        }
                        .transition(AisleHandoff.transition(reduceMotion: reduceMotion))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .tesseraAnimation(Theme.Motion.house, value: aisles.map(\.aisle))
            .tesseraAnimation(Theme.Motion.house, value: shopping)
            .opacity(basketOpen && !shopping ? 0.5 : 1)
            .tesseraAnimation(Theme.Motion.house, value: basketOpen)
        }
        .soulReachesEnd("groceries")
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .coordinateSpace(.named("groceries"))
        // While the basket is open, the dimmed page folds it on a tap (under the basket, so its words still work).
        .overlay {
            if basketOpen, !shopping {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { basketOpen = false }
                    }
                    .accessibilityHidden(true)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if shopping {
                    PaintKey(paint: Theme.Colors.health, hint: "Finishes the shop", action: finishShop) { _ in
                        Text("Done")
                    } meta: {
                        Text("Hold")
                    }
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .accessibilityHint("Clears the basket and ends the shop")
                }
                if !basket.isEmpty, !shopping {
                    BasketFold(items: basket, isOpen: $basketOpen, breathe: breathe, label: basketLabel,
                               onTap: uncheck,
                               onClear: { clearBasket(count: basket.count) })
                        .onGeometryChange(for: CGPoint.self) { proxy in
                            let frame = proxy.frame(in: .named("groceries"))
                            return CGPoint(x: frame.minX + Theme.Spacing.gutter + 6, y: frame.minY + 22)
                        } action: { basketTarget = $0 }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                // Groceries opens as a full-screen layer above Tess's soul, so her reply line is mirrored here, in
                // the inset, so the list scrolls clear of it.
                if TessVoice.shared.note != nil, basket.isEmpty {
                    TessNoteLine()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, Theme.Spacing.xxl)
                        .background {
                            // The page's own ground, faded in at the top, so nothing shows through her words.
                            ThemedBackground()
                                .mask(LinearGradient(stops: [.init(color: .clear, location: 0),
                                                             .init(color: .black, location: 0.45)],
                                                     startPoint: .top, endPoint: .bottom))
                                .ignoresSafeArea(edges: .bottom)
                        }
                        .transition(.opacity)
                }
            }
            .tesseraAnimation(Theme.Motion.house, value: basket.isEmpty)
            .tesseraAnimation(Theme.Motion.house, value: TessVoice.shared.note)
        }

        .overlay {
            // The struck items' dabs, on their arcs into the basket.
            ForEach(sinking) { sink in
                PaintDab(
                    color: Theme.Colors.health,
                    size: CGSize(width: 12, height: 10),
                    seed: abs(sink.id.hashValue % 7)
                )
                .position(x: sink.x, y: sink.y)
                .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) {
            if shopping {
                ProcessSeam(color: Theme.Colors.live)
                    .ignoresSafeArea(edges: .top)
                    .transition(.opacity)
            }
        }
        .onPreferenceChange(RowCenters.self) { rowCenters = $0 }
        .tesseraFeedback(.notNow, trigger: landed)
        // The shop finished is .done in the house map; never a raw sensoryFeedback (Haptics.swift).
        .tesseraFeedback(.done, trigger: finished)
    }

    @State private var rowCenters: [UUID: CGPoint] = [:]

    private func recipes(for item: ListContents.Item) -> [String] {
        // A private recipe is only ever "Private recipe", here too (QA F2 on #732).
        ShopTrip.recipeNames(groceries.recipes(for: item.object).map(\.title),
                             lastWeightKg: BodyWeight.lastKg(in: model.store))
    }

    /// The Add line through the wall (Product 8:40 AM PT Oct 17): kept lines go on the list; a walled line stays in
    /// the draft with its line ("That stays on this phone.", "That one stays out of Groceries." or the key line) and
    /// no UNDO, never a silent clear.
    private func add() {
        guard !GroceriesCopy.lines(in: draft).isEmpty else { return }
        let outcome = GroceriesWall.add(draft, engine: model.engine, store: model.store)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            draft = outcome.draft
            model.touch()
        }
        if let voice = outcome.voice {
            // A new add's UNDO holds 4 s (10 s under VoiceOver); a walled line or a failure has none.
            TessVoice.shared.say(voice, undo: outcome.undo, holds: outcome.undo == nil ? nil : .seconds(4))
        }
    }

    /// What a row reads, in the list and in SHOP mode: a private item is always "Private item" (G102).
    private func rowLabel(_ item: ListContents.Item) -> String {
        trip.label(for: item, name: GroceriesCopy.name(item), lastWeightKg: BodyWeight.lastKg(in: model.store))
    }

    /// The basket never opens a row: a private item there is always "Private item".
    private func basketLabel(_ item: ListContents.Item) -> String {
        trip.maskedLabel(for: item, name: GroceriesCopy.name(item), lastWeightKg: BodyWeight.lastKg(in: model.store))
    }

    /// One tap strikes any row, a private one included; nothing opens (G102).
    private func shopTap(_ item: ListContents.Item) {
        check(item)
    }

    /// The ink strike runs through first (light tap when it ends), then the item folds into a sage dab that arcs
    /// into the basket, and the count rolls up.
    private func check(_ item: ListContents.Item) {
        guard !striking.contains(item.id) else { return }
        withTesseraAnimation(.smooth(duration: 0.32), reduceMotion: reduceMotion) { _ = striking.insert(item.id) }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 450))
            landed += 1
            if !reduceMotion, let start = rowCenters[item.id], basketTarget != .zero || !basketOpen {
                let target = basketTarget == .zero ? CGPoint(x: start.x, y: start.y + 600) : basketTarget
                sinking.append(Sink(id: item.id, x: start.x, y: start.y))
                withTesseraAnimation(.timingCurve(0.55, 0, 0.15, 1, duration: 0.52), reduceMotion: reduceMotion) {
                    if let index = sinking.firstIndex(where: { $0.id == item.id }) {
                        sinking[index].x = target.x
                    }
                }
                withTesseraAnimation(.timingCurve(0.3, 0, 0.25, 1, duration: 0.52), reduceMotion: reduceMotion) {
                    if let index = sinking.firstIndex(where: { $0.id == item.id }) {
                        sinking[index].y = target.y
                    }
                }
            }
            let checked = try? model.engine.perform(CheckListItem(item: item.id, time: AppClock.now), by: .user)
            withTesseraAnimation(.smooth(duration: 0.28), reduceMotion: reduceMotion) {
                striking.remove(item.id)
                model.touch()
            }
            // A refused check: the row stays on the list and Tess says so (ER11).
            if checked == nil {
                GroceriesCopy.sayDidntSave()
            }
            try? await Task.sleep(for: .milliseconds(520))
            sinking.removeAll { $0.id == item.id }
            withTesseraAnimation(.smooth(duration: 0.2), reduceMotion: reduceMotion) { breathe = true }
            try? await Task.sleep(for: .milliseconds(200))
            withTesseraAnimation(.smooth(duration: 0.2), reduceMotion: reduceMotion) { breathe = false }
        }
    }

    private func uncheck(_ item: ListContents.Item) {
        let unchecked = try? model.engine.perform(CheckListItem(item: item.id, done: false), by: .user)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        if unchecked == nil {
            GroceriesCopy.sayDidntSave()
        }
    }

    /// Tess says it beside her soul, with Undo (the same reply line as everywhere else).
    private func clearBasket(count: Int) {
        guard let list = groceries.list else { return }
        let cleared = GroceriesCopy.clear(count: count) {
            try? model.engine.perform(ClearDoneItems(list: list.id), by: .user).record
        }
        // A refused clear keeps the basket open with its rows and says so (Kitchen on #793).
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            if cleared.undo != nil {
                basketOpen = false
            }
            model.touch()
        }
        TessVoice.shared.say(cleared.line, undo: cleared.undo)
    }

    private func toggleShop() {
        let refusal = GroceriesCopy.toggleShop(groceries, engine: model.engine)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        if let refusal {
            TessVoice.shared.say(refusal)
        }
    }

    /// "Shopping, finished." with a 10 s UNDO that brings the basket and the shop back (G43). A failed write keeps
    /// the basket open, says so, and plays no finish haptic.
    private func finishShop() {
        let outcome = GroceriesCopy.finish(engine: model.engine)
        guard let record = outcome.undo else {
            TessVoice.shared.say(outcome.line)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            basketOpen = false
            model.touch()
        }
        TessVoice.shared.say(outcome.line, undo: record, holds: .seconds(10))
        finished += 1
    }

    @State private var finished = 0
}

/// Where each row sits on the page, for the dab's arc.
private struct RowCenters: PreferenceKey {
    static let defaultValue: [UUID: CGPoint] = [:]
    static func reduce(value: inout [UUID: CGPoint], nextValue: () -> [UUID: CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Pieces

/// The hero. Holding it for 0.7 s starts the shop: vermilion paint spreads through the word as you hold, like a
/// hold key; letting go early drains it.
private struct ShopTitle: View {
    let onHold: () -> Void
    @State private var fill: CGFloat = 0
    /// Once the hold lands the title stays vermilion as it folds away (Design).
    @State private var held = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Groceries")
            .textRole(.hero)
            .foregroundStyle(Theme.Colors.ink)
            .overlay(alignment: .leading) {
                Text("Groceries")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.live)
                    .mask(alignment: .leading) {
                        GeometryReader { proxy in
                            Rectangle().frame(width: proxy.size.width * fill)
                        }
                    }
                    .accessibilityHidden(true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.7, maximumDistance: 30) {
                held = true
                onHold()
                // If the shop didn't start, the title is still here: drain it back to ink (QA G8). Once the shop
                // starts this view is gone, so nothing runs.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(700))
                    held = false
                    withTesseraAnimation(.smooth(duration: 0.22), reduceMotion: reduceMotion) { fill = 0 }
                }
            } onPressingChanged: { pressing in
                if pressing {
                    withTesseraAnimation(.smooth(duration: 0.7), reduceMotion: reduceMotion) { fill = 1 }
                } else {
                    guard !held else { return }
                    withTesseraAnimation(.smooth(duration: 0.22), reduceMotion: reduceMotion) { fill = 0 }
                }
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: "Start shopping", onHold)
    }
}

/// The writing line: an "Add" label and the prompt; items fly to their aisles on return.
private struct GroceryWritingLine: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        let active = focused.wrappedValue || !text.isEmpty
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .center, spacing: Theme.Spacing.m) {
                Text("Add")
                    .textRole(.label)
                    .foregroundStyle(active ? Theme.Colors.health : Theme.Colors.inkSecondary)
                    .tesseraAnimation(Theme.Motion.house, value: active)
                    .accessibilityHidden(true)
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

/// One aisle: its name at 34, ink at 85%, at the margin; its items hang 42 pt in.
private struct AisleSection: View {
    let name: String
    let items: [ListContents.Item]
    let striking: Set<UUID>
    let recipes: (ListContents.Item) -> [String]
    /// What each row reads: a private one is always masked (G102).
    let label: (ListContents.Item) -> String
    let onTap: (ListContents.Item) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(name)
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink.opacity(0.85))
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    GroceryRow(item: item, isStriking: striking.contains(item.id), recipes: recipes(item),
                               height: 48, name: label(item)) { onTap(item) }
                        .transition(.asymmetric(insertion: .push(from: .top).combined(with: .opacity),
                                                removal: .opacity.combined(with: .scale(scale: 1, anchor: .top))))
                }
            }
            .padding(.leading, typeSize.isAccessibilitySize ? 20 : 42)
        }
        .accessibilityElement(children: .contain)
    }
}

/// One item on one line: the amount in 600, the name in 400 (the name truncates, never the amount), and a sage dab at
/// the end when it's for a recipe. Tap strikes it; a long press says which recipes.
private struct GroceryRow: View {
    let item: ListContents.Item
    let isStriking: Bool
    let recipes: [String]
    var height: CGFloat = 48
    /// The words the row shows, already masked at the source ("Private item" for a private one); never the raw text.
    let name: String
    let onTap: () -> Void
    @State private var showsRecipes = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    (Text(item.quantity.map { "\($0) " } ?? "").fontWeight(.semibold)
                        + Text(name).fontWeight(.regular))
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        // A long name wraps, never cut (K36.19, the AX rule).
                        .fixedSize(horizontal: false, vertical: true)
                        .textRenderer(StrikeRenderer(progress: isStriking ? 1 : 0, color: Theme.Colors.ink))
                    Spacer(minLength: Theme.Spacing.s)
                    if !recipes.isEmpty {
                        PaintDab(color: Theme.Colors.health, size: CGSize(width: 12, height: 10),
                                 seed: item.text.count)
                    }
                }
                if showsRecipes, !recipes.isEmpty {
                    Text("for \(recipes.joined(separator: ", ").lowercased())")
                        .font(Theme.voice(size: 18))
                        .foregroundStyle(Theme.Colors.health)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named("groceries"))
                Color.clear.preference(
                    key: RowCenters.self,
                    value: [item.id: CGPoint(x: frame.minX + 6, y: frame.midY)]
                )
            }
        }
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { showsRecipes.toggle() }
        })
        .accessibilityElement(children: .combine)
        .accessibilityHint("Puts it in the basket")
        .accessibilityAction(named: "Which recipes") { showsRecipes.toggle() }
    }
}

/// At the shop: the hero is the aisle you're in, its items alone at 64 pt (no hang), and the next aisle peeking.
/// An emptied aisle folds up and away about its top edge and the next one rises into its place.
private struct AtTheShop: View {
    let aisles: [(aisle: String, items: [ListContents.Item])]
    let striking: Set<UUID>
    let recipes: (ListContents.Item) -> [String]
    /// What each row reads: a private one is always masked (G102).
    let label: (ListContents.Item) -> String
    let onTap: (ListContents.Item) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let current = aisles.first {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(current.aisle)
                            .textRole(.hero)
                            .foregroundStyle(Theme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(current.items) { item in
                                GroceryRow(item: item, isStriking: striking.contains(item.id), recipes: recipes(item),
                                           height: 64, name: label(item)) { onTap(item) }
                                    .transition(.opacity)
                            }
                        }
                    }
                    .id(current.aisle)
                    .transition(AisleHandoff.transition(reduceMotion: reduceMotion))
                }
                if aisles.count > 1 {
                    // The peek swaps like a value word: the old one blurs out, then the new one blurs in.
                    ZStack(alignment: .leading) {
                        Text("then \(aisles[1].aisle)")
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink.opacity(0.35))
                            .id(aisles[1].aisle)
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .modifier(active: BlurFade(progress: 0), identity: BlurFade(progress: 1))
                                    .animation(.smooth(duration: 0.22).delay(0.12)),
                                removal: .modifier(active: BlurFade(progress: 0), identity: BlurFade(progress: 1))
                                    .animation(.smooth(duration: 0.12))
                            ))
                    }
                    .padding(.top, Theme.Spacing.xxl)
                }
            }
            .animation(reduceMotion ? .easeOut(duration: 0.18) : .smooth(duration: 0.42), value: current.aisle)
        }
    }
}

/// One aisle (or the whole list) handing over to the next: the outgoing one tilts back about its top edge and fades
/// over 260 ms; the incoming one rises 14 pt out of a 4 pt blur over 340 ms, starting 160 ms in, so two hero words are
/// never fully visible together. Reduce Motion: a short cross-fade.
private enum AisleHandoff {
    static func transition(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity.animation(.easeOut(duration: 0.18)) }
        return .asymmetric(
            insertion: .modifier(active: RiseIn(progress: 0), identity: RiseIn(progress: 1))
                .animation(.smooth(duration: 0.34).delay(0.16)),
            removal: .modifier(active: FoldAway(progress: 1), identity: FoldAway(progress: 0))
                .animation(.smooth(duration: 0.26))
        )
    }
}

/// A word blurring in or out.
private struct BlurFade: ViewModifier {
    var progress: Double
    func body(content: Content) -> some View {
        content.blur(radius: 4 * (1 - progress)).opacity(progress)
    }
}

/// An emptied aisle tilts back about its top edge and fades.
private struct FoldAway: ViewModifier {
    var progress: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(-65 * progress), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
            .opacity(1 - progress)
    }
}

/// The next aisle rises into the hero slot: 14 pt up, blur 4 to 0.
private struct RiseIn: ViewModifier {
    var progress: Double
    func body(content: Content) -> some View {
        content
            .offset(y: 14 * (1 - progress))
            .blur(radius: 4 * (1 - progress))
            .opacity(progress)
    }
}

/// The basket: pinned at the bottom, a seam on top, a faint sage wash, "6 in the basket" with the count rolling.
/// Tap to open the struck items (tap one to put it back) and clear the basket with a hold.
private struct BasketFold: View {
    let items: [ListContents.Item]
    @Binding var isOpen: Bool
    let breathe: Bool
    /// What each basket row reads (a private one stays "Private item"; a tap here takes it back out).
    let label: (ListContents.Item) -> String
    let onTap: (ListContents.Item) -> Void
    let onClear: () -> Void
    /// Clear the basket plays `.cleared` itself: the hold's key is silent (the map has no cue in a key).
    @State private var clears = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { isOpen.toggle() }
            } label: {
                (Text("\(items.count)").fontWeight(.semibold) + Text(" in the basket").fontWeight(.regular))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .contentTransition(.numericText(value: Double(items.count)))
                    .scaleEffect(breathe ? 1.04 : 1, anchor: .leading)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .padding(.horizontal, Theme.Spacing.gutter)
            .accessibilityHint(isOpen ? "Folds the basket" : "Shows what's in the basket")
            if isOpen {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        Button { onTap(item) } label: {
                            (Text(item.quantity.map { "\($0) " } ?? "").fontWeight(.semibold)
                                + Text(label(item)).fontWeight(.regular))
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .textRenderer(StrikeRenderer(progress: 1, color: Theme.Colors.inkSecondary))
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(HandleButtonStyle())
                        .accessibilityHint("Puts it back on the list")
                    }
                    PaintKey(paint: Theme.Colors.health, hint: "Clears the basket", action: {
                        clears += 1
                        onClear()
                    }) { _ in
                        Text("Clear the basket")
                    } meta: {
                        Text("Hold")
                    }
                    .tesseraFeedback(.cleared, trigger: clears)
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.top, Theme.Spacing.xxl)
        // A soft veil instead of a hard sheet edge: it fades in over the page with one hairline seam.
        .veil(edge: .bottom)
    }
}

/// Tess's reply line as BottomChrome draws it (right-aligned, Tess ink, UNDO as a vermilion label word), reading the
/// shared `TessVoice`, for layers that cover her soul.
private struct TessNoteLine: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let voice = TessVoice.shared

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let note = voice.note {
                Text(note.text)
                    .frame(maxWidth: 270, alignment: .trailing)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.tess)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                if let record = note.undo {
                    Button("Undo") {
                        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                            _ = model.engine.undo(record)
                            model.touch()
                            voice.clear()
                        }
                    }
                    .buttonStyle(InkLabelWordStyle.undo)
                    .accessibilityHint("Undoes what Tess just said")
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.trailing, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.s)
    }
}

private struct GroceriesEmpty: View {
    let basket: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(basket > 0 ? "All in the basket." : "Nothing to get.")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
            Text("Tell me \u{201C}milk, eggs\u{201D}, or swipe a recipe's ingredients here.")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.tess)
        }
    }
}

enum GroceriesCopy {
    static let didntSave = "Didn't save that. Try again."

    /// Starts or sets aside the shop. A refused start says why: "Workout running." while a workout runs (QA on
    /// #792), else "Didn't save that. Try again." Nil when it went through.
    @MainActor static func toggleShop(_ groceries: Groceries, engine: ActionEngine) -> String? {
        if let shop = groceries.shop(in: engine), shop.state == .running {
            return RecipeCopy.startCook { try engine.perform(SuspendProcess(process: shop.id), by: .user) }
        }
        return RecipeCopy.startCook { try engine.perform(StartShop(), by: .user) }
    }

    /// A refused write on Groceries says so; nothing scolds, so there is no warning haptic (ER11, Haptics.swift).
    @MainActor static func sayDidntSave() {
        TessVoice.shared.say(didntSave)
    }

    /// Clearing the basket: "Cleared 3 from the basket." with UNDO, or the failure line with nothing to undo.
    static func clear(count: Int, _ perform: () -> OpRecord?) -> (line: String, undo: OpRecord?) {
        guard let record = perform() else { return (didntSave, nil) }
        return ("Cleared \(count) from the basket.", record)
    }

    /// Finishing the shop: the engine's receipt and its record, or the failure line with nothing to undo.
    @MainActor static func finish(engine: ActionEngine) -> (line: String, undo: OpRecord?) {
        finish { try? engine.perform(FinishShop(), by: .user).record }
    }

    @MainActor static func finish(_ perform: () -> OpRecord?) -> (line: String, undo: OpRecord?) {
        guard let record = perform() else {
            return (didntSave, nil)
        }
        let receipt = record.receipt ?? "Shopping, finished"
        return (receipt.hasSuffix(".") ? receipt : receipt + ".", record)
    }

    /// The name as it should read beside its amount: "3 eggs", not "3 egg" (a plain count above one, no unit).
    static func name(_ item: ListContents.Item) -> String {
        guard let quantity = item.quantity, let count = Double(quantity), count > 1,
              !item.text.lowercased().hasSuffix("s") else { return item.text }
        let text = item.text
        if text.hasSuffix("y"), !"aeiou".contains(text.dropLast().last ?? "a") {
            return String(text.dropLast()) + "ies"
        }
        if text.hasSuffix("o") || text.hasSuffix("ch") || text.hasSuffix("sh") {
            return text + "es"
        }
        return text + "s"
    }

    /// "9 to buy across 4 aisles", "Shopping, 3 left".
    static func context(open: Int, aisles: Int, shopping: Bool) -> String {
        if shopping {
            return open == 0 ? "shopping, all in the basket" : "shopping, \(open) left"
        }
        guard open > 0 else { return "Nothing to get" }
        let aisleText = aisles == 1 ? "one aisle" : "\(aisles) aisles"
        return "\(open) to buy across \(aisleText)"
    }

    /// "eggs, milk and 2 lemons" → three lines.
    static func lines(in text: String) -> [String] {
        GroceryLines.split(text)
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
            guard LaunchFlags.has("-demoKitchen"),
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

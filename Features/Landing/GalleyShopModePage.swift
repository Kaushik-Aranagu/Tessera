import SwiftUI
import TesseraCore

/// Shopping mode on the standing shell (sheet 322), over the existing shop: Got checks the thing off, Not here moves it
/// to the end of its aisle, Pay (hold) finishes the shop and puts what was bought in the Pantry, with one Undo. Behind
/// the "Shopping mode" switch (On); Off keeps Groceries as it was.
struct GalleyShopModePage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var navigator = ShellNavigator(root: .landing(GalleyShopContent.room))
    @State private var pushed: [String] = []
    @State private var trip = ShopTrip()

    var body: some View {
        let _ = model.revision
        let facts = Self.facts(model: model, trip: trip, pushed: pushed)
        let focus = facts.aisles.isEmpty ? 0 : min(max(navigator.state.dialFocus, 0), facts.aisles.count - 1)
        ZStack {
            ShellView(room: GalleyShopContent(facts: facts), navigator: navigator, accent: LandingAccent.kitchen) {
                handle($0, facts: facts, aisle: focus)
            }
            .environment(\.doorSummaryStyle, .ticket)
            .environment(\.shellGlyphRoom, .galley)
            .environment(\.shellScene) { _ in
                AnyView(GalleyRail(tickets: GalleyShopContent.tickets(facts, aisle: focus)) { _ in })
            }
        }
        .onAppear(perform: begin)
    }

    // MARK: Intents

    private func handle(_ intent: ShellIntent, facts: GalleyShopFacts, aisle: Int) {
        guard facts.aisles.indices.contains(aisle) || intent == .back else { return }
        switch intent {
        case .back:
            dismiss()
        case .openItem:
            got(facts.aisles[aisle].items.first)
        case let .action(id):
            switch id {
            case "got": got(facts.aisles[aisle].items.first)
            case "nothere":
                if let first = facts.aisles[aisle].items.first {
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pushed.append(first.id) }
                }
            case "pay": pay()
            default: break
            }
        default:
            break
        }
    }

    private func got(_ item: GalleyShopFacts.Item?) {
        guard let item, let id = UUID(uuidString: item.id) else { return }
        let checked = try? model.engine.perform(CheckListItem(item: id, time: AppClock.now), by: .user)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        if checked == nil {
            TessVoice.shared.say("Didn't save that. Try again")
        }
    }

    /// Done shopping: what is in the basket walks to its Pantry place in the same step as the finish.
    private func pay() {
        let groceries = Groceries(store: model.store, classes: model.classes)
        let basket = groceries.list.map { ListContents(store: model.store, classes: model.classes).done(in: $0) } ?? []
        let walk = basket.isEmpty ? nil : ShopWalk.placements(basket: basket, model: model)
        let outcome = GroceriesCopy.finish(engine: model.engine, putAway: walk)
        guard let record = outcome.undo else {
            TessVoice.shared.say(outcome.line)
            return
        }
        model.touch()
        TessVoice.shared.say(outcome.line, undo: record, holds: .seconds(10))
        dismiss()
    }

    private func begin() {
        let groceries = Groceries(store: model.store, classes: model.classes)
        if groceries.shop(in: model.engine)?.state != .running {
            _ = try? model.engine.perform(StartShop(), by: .user)
            model.touch()
        }
    }

    // MARK: Facts

    /// The aisles in store order, each with its open things (a thing sent to the end by Not here moves behind the
    /// rest), the basket count, and tonight's dish.
    @MainActor
    static func facts(model: AppModel, trip: ShopTrip, pushed: [String]) -> GalleyShopFacts {
        let groceries = Groceries(store: model.store, classes: model.classes)
        let weight = BodyWeight.lastKg(in: model.store)
        var facts = GalleyShopFacts()
        facts.aisles = groceries.aisles().map { aisle in
            var items = aisle.items.map { item -> GalleyShopFacts.Item in
                let names = ShopTrip.recipeNames(groceries.recipes(for: item.object).map(\.title), lastWeightKg: weight)
                return GalleyShopFacts.Item(id: item.id.uuidString,
                                            name: trip.label(
                                                for: item,
                                                name: GroceriesCopy.name(item),
                                                lastWeightKg: weight
                                            ),
                                            amount: item.quantity,
                                            why: names.first.map { "For the \($0.lowercased())" })
            }
            items = items.filter { !pushed.contains($0.id) } + pushed.compactMap { id in items.first { $0.id == id } }
            return GalleyShopFacts.Aisle(name: aisle.aisle, items: items)
        }
        facts.got = groceries.list
            .map { ListContents(store: model.store, classes: model.classes).done(in: $0).count } ?? 0
        let front = KitchenFront(model: model, now: AppClock.now)
        if let meal = front.tonight {
            facts.tonight = NotesLandingPage.short(meal.title)
            // Tonight's things on the list; the ones in the basket are struck off as they go in.
            let all = groceries.list.map { list -> [(item: ListContents.Item, done: Bool)] in
                let contents = ListContents(store: model.store, classes: model.classes)
                return contents.sections(of: list).flatMap(\.items).map { ($0, $0.isDone) }
            } ?? []
            let mine = all.filter { entry in
                ShopTrip.recipeNames(groceries.recipes(for: entry.item.object).map(\.title), lastWeightKg: weight)
                    .contains { $0 == meal.title }
            }
            facts.tonightLines = mine.map {
                trip.label(for: $0.item, name: GroceriesCopy.name($0.item), lastWeightKg: weight)
            }
            facts.tonightGot = Set(mine.indices.filter { mine[$0].done })
        }
        return facts
    }
}

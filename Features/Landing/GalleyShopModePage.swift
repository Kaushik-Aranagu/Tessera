import SwiftUI
import TesseraCore

/// Shopping mode (sheets 322, 325, 328): the whole ticket, as cooking. The aisle and where it is; the thing at 64 pt
/// with its amount; why it is on the list and how to pick it; the aisle's list with dotted leaders (got ones struck);
/// what is after this. Got is the verb, swipe up anywhere does it; Not here and Pay (hold) sit beside it. Behind the
/// "Shopping mode" switch (On); Off keeps Groceries as it was.
struct GalleyShopModePage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pushed: [String] = []
    @State private var focus = 0
    @State private var trip = ShopTrip()
    /// "Got" in flight (sheet 332): the pen stroke through the thing, then the words fade, then the check is written.
    @State private var pen: String?
    @State private var penProgress: CGFloat = 0
    @State private var faded = false
    @State private var cue = HapticCue()
    /// The last Pay (sheet 334): the old ticket tears off, then the paid ticket prints in.
    @State private var tearing = false
    @State private var paidCount: Int?
    @State private var paidOffset: CGFloat = GalleyTearOff.from

    var body: some View {
        let _ = model.revision
        let facts = Self.facts(model: model, trip: trip, pushed: pushed)
        let index = facts.aisles.isEmpty ? 0 : min(max(focus, 0), facts.aisles.count - 1)
        let data = GalleyShopScreen(facts, aisle: index)
        ZStack {
            ticket(facts: facts, index: index, data: data)
                .rotationEffect(.degrees(tearing ? GalleyTearOff.angle : 0), anchor: .topLeading)
                .offset(x: tearing ? GalleyTearOff.liftX : 0, y: tearing ? GalleyTearOff.liftY : 0)
                .opacity(tearing ? 0 : 1)
                .animation(reduceMotion ? nil : .easeIn(duration: GalleyTearOff.fade), value: tearing)
                .allowsHitTesting(!tearing)
            if let count = paidCount {
                paid(count)
                    .offset(y: paidOffset)
                    .transition(.identity)
            }
        }
        .onAppear(perform: begin)
        .tesseraFeedback(cue)
    }

    private func ticket(facts: GalleyShopFacts, index: Int, data: GalleyShopScreen) -> some View {
        GalleyModeScreen(room: "Galley", topRight: data.topRight, back: { dismiss() }, verb: { got(facts, index) }) {
            VStack(alignment: .leading, spacing: 0) {
                Text(data.aisle.isEmpty ? "Groceries" : data.aisle)
                    .font(GalleyPaper.plex(.bold, 26))
                    .foregroundStyle(GalleyPaper.olive)
                    .lineLimit(1)
                    .padding(.top, 4)
                if let spot = data.spot {
                    Text(spot)
                        .font(GalleyPaper.plex(.medium, 18))
                        .foregroundStyle(GalleyPaper.inkSecondary)
                }
                if data.empty {
                    Text("All got")
                        .font(GalleyPaper.plex(.bold, 64))
                        .foregroundStyle(GalleyPaper.ink)
                        .padding(.top, 24)
                } else {
                    Text(data.thing)
                        .font(GalleyPaper.plex(.bold, 64))
                        .foregroundStyle(GalleyPaper.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .opacity(faded ? 0.15 : 1)
                        .overlay {
                            if pen != nil {
                                GalleyPenStroke(progress: penProgress)
                                    .stroke(GalleyPaper.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            }
                        }
                        .padding(.top, 18)
                    if let amount = data.amount {
                        Text(amount)
                            .font(GalleyPaper.number(34, weight: .regular))
                            .foregroundStyle(GalleyPaper.ochre)
                    }
                    if let why = data.why {
                        Text(why)
                            .font(GalleyPaper.plex(.medium, 19))
                            .foregroundStyle(GalleyPaper.ink)
                            .padding(.top, 8)
                    }
                    if let tip = data.tip {
                        label("Tip") {
                            Text(tip)
                                .font(GalleyPaper.plex(.regular, 19))
                                .foregroundStyle(GalleyPaper.ink)
                                .lineLimit(2)
                        }
                    }
                    label("In this aisle") {
                        VStack(spacing: 5) {
                            ForEach(data.inAisle.prefix(5)) { line in
                                GalleyLeaderRow(name: line.name, amount: line.amount, struck: line.struck)
                            }
                        }
                        .frame(maxWidth: 230)
                    }
                    if let after = data.after {
                        label("After this") {
                            Text(after)
                                .font(GalleyPaper.plex(.regular, 19))
                                .foregroundStyle(GalleyPaper.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
            }
        } thumb: {
            VStack(alignment: .leading, spacing: 0) {
                GalleyModeReceipt()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 22) {
                            small("Not here") { notHere(facts, index) }
                            small("Pay", hold: true) { pay() }
                        }
                        GalleyModeVerb(word: data.verb, object: data.object, tint: GalleyPaper.olive) {
                            got(facts, index)
                        }
                    }
                    Spacer(minLength: 8)
                    GalleyModeRail(items: data.rail, tint: GalleyPaper.olive) { focus = $0 }
                }
            }
        }
    }

    /// The paid ticket: what was bought, and where it went.
    private func paid(_ count: Int) -> some View {
        GalleyModeScreen(room: "Galley", topRight: "Paid", back: { dismiss() }, verb: { dismiss() }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Paid")
                    .font(GalleyPaper.plex(.bold, 64))
                    .foregroundStyle(GalleyPaper.olive)
                    .padding(.top, 40)
                Text(count == 1 ? "1 thing, put away in the Pantry" : "\(count) things, put away in the Pantry")
                    .font(GalleyPaper.plex(.medium, 22))
                    .foregroundStyle(GalleyPaper.ink)
            }
        } thumb: {
            VStack(alignment: .leading, spacing: 0) {
                GalleyModeReceipt()
                GalleyModeVerb(word: "Done", tint: GalleyPaper.olive) { dismiss() }
            }
        }
    }

    /// The old ticket lifts away and fades; after 220 ms the paid ticket prints in with an overshoot and a double buzz.
    private func tearOff(count: Int) async {
        guard !reduceMotion else {
            tearing = true
            paidOffset = 0
            paidCount = count
            cue.play(.done)
            return
        }
        tearing = true
        try? await Task.sleep(for: .milliseconds(Int(GalleyTearOff.delay * 1000)))
        paidOffset = GalleyTearOff.from
        paidCount = count
        cue.play(.done)
        try? await Task.sleep(for: .milliseconds(100))
        cue.play(.done)
        let step = GalleyTearOff.print / Double(GalleyTearOff.steps.count)
        for offset in GalleyTearOff.steps {
            paidOffset = offset
            try? await Task.sleep(for: .milliseconds(Int(step * 1000)))
        }
    }

    /// Opens the shop the first time (Pay finishes it).
    private func begin() {
        let groceries = Groceries(store: model.store, classes: model.classes)
        if groceries.shop(in: model.engine)?.state != .running {
            _ = try? model.engine.perform(StartShop(), by: .user)
            model.touch()
        }
    }

    private func label(_ title: String, @ViewBuilder _ body: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(GalleyPaper.plex(.bold, 13))
                .tracking(13 * 0.1)
                .foregroundStyle(GalleyPaper.inkSecondary)
            body()
        }
        .padding(.top, 14)
    }

    private func small(_ word: String, hold: Bool = false, _ act: @escaping () -> Void) -> some View {
        Text(hold ? "\(word), hold" : word)
            .font(GalleyPaper.plex(.bold, 17))
            .foregroundStyle(GalleyPaper.ochre)
            .frame(minHeight: 36)
            .contentShape(Rectangle())
            .onTapGesture {
                if !hold {
                    act()
                }
            }
            .onLongPressGesture(minimumDuration: 0.7) {
                if hold {
                    act()
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(word)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { act() }
    }

    // MARK: Doing

    /// Got: a pen stroke through the thing (300 ms), the words fade, then the check is written. Under Reduce Motion
    /// there is no stroke: it is checked at once. One haptic for the move.
    private func got(_ facts: GalleyShopFacts, _ index: Int) {
        guard pen == nil, facts.aisles.indices.contains(index), let item = facts.aisles[index].items.first,
              let id = UUID(uuidString: item.id) else { return }
        guard !reduceMotion else {
            check(id)
            return
        }
        pen = item.id
        penProgress = 0
        cue.play(.done)
        withAnimation(.easeInOut(duration: 0.3)) { penProgress = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.2)) { faded = true }
            try? await Task.sleep(for: .milliseconds(200))
            check(id)
            pen = nil
            faded = false
            penProgress = 0
        }
    }

    private func check(_ id: UUID) {
        let checked = try? model.engine.perform(CheckListItem(item: id, time: AppClock.now), by: .user)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        if checked == nil {
            TessVoice.shared.say("Didn't save that. Try again")
        }
    }

    /// Not here: the thing moves to the end of its aisle.
    private func notHere(_ facts: GalleyShopFacts, _ index: Int) {
        guard facts.aisles.indices.contains(index), let first = facts.aisles[index].items.first else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pushed.append(first.id) }
    }

    /// Pay: what is in the basket walks to its Pantry place in the same step as the finish, with one Undo.
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
        let count = basket.count
        Task { await tearOff(count: count) }
    }

    // MARK: Facts

    /// The aisles in store order, each with its open things (a thing sent to the end by Not here moves behind the
    /// rest) and what is already in the basket, the basket count, and tonight's dish.
    @MainActor
    static func facts(model: AppModel, trip: ShopTrip, pushed: [String]) -> GalleyShopFacts {
        let groceries = Groceries(store: model.store, classes: model.classes)
        let weight = BodyWeight.lastKg(in: model.store)
        let basket = groceries.list.map { ListContents(store: model.store, classes: model.classes).done(in: $0) } ?? []
        func item(_ entry: ListContents.Item) -> GalleyShopFacts.Item {
            let names = ShopTrip.recipeNames(groceries.recipes(for: entry.object).map(\.title), lastWeightKg: weight)
            return GalleyShopFacts.Item(id: entry.id.uuidString,
                                        name: trip.label(
                                            for: entry,
                                            name: GroceriesCopy.name(entry),
                                            lastWeightKg: weight
                                        ),
                                        amount: entry.quantity, why: names.first.map { "For the \($0.lowercased())" })
        }
        var facts = GalleyShopFacts()
        facts.aisles = groceries.aisles().map { aisle in
            var items = aisle.items.map(item)
            items = items.filter { !pushed.contains($0.id) } + pushed.compactMap { id in items.first { $0.id == id } }
            let got = basket.filter { Aisle.shown($0.section ?? Aisle.other.rawValue) == aisle.aisle }.map(item)
            return GalleyShopFacts.Aisle(name: aisle.aisle, items: items, got: got)
        }
        facts.got = basket.count
        let front = KitchenFront(model: model, now: AppClock.now)
        if let meal = front.tonight {
            facts.tonight = NotesLandingPage.short(meal.title)
            // Tonight's things on the list; the ones in the basket count as got.
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

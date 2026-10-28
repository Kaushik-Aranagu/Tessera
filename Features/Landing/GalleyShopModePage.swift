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
    /// Sheet 342: "Everything for the tacos" in the top right for 2.2 s when tonight's dish becomes covered.
    @State private var celebrating = false
    /// The ticket as it was when Pay was pressed: the copy that lifts away (the live one is already empty).
    @State private var frozen: (facts: GalleyShopFacts, index: Int)?
    /// Whether the new thing has arrived (sheet 332): false at the swap, then each block comes in from 30 pt right.
    @State private var shown = true
    /// "Not here" (sheet 339): the aisle's rows as shown while one slides to the end, and the row that settles in last.
    @State private var listOverride: [GalleyShopScreen.Line]?
    @State private var landing: String?
    @State private var landed = true
    @State private var paidCount: Int?
    @State private var paidOffset: CGFloat = GalleyTearOff.from

    var body: some View {
        let _ = model.revision
        let facts = Self.facts(model: model, trip: trip, pushed: pushed)
        let index = facts.aisles.isEmpty ? 0 : min(max(focus, 0), facts.aisles.count - 1)
        let data = GalleyShopScreen(facts, aisle: index)
        let old = frozen
        ZStack {
            ticket(facts: old?.facts ?? facts, index: old?.index ?? index,
                   data: old.map { GalleyShopScreen($0.facts, aisle: $0.index) } ?? data)
                .rotationEffect(.degrees(tearing ? GalleyTearOff.angle : 0), anchor: .topLeading)
                .offset(x: tearing ? GalleyTearOff.liftX : 0, y: tearing ? GalleyTearOff.liftY : 0)
                .opacity(tearing ? 0 : 1)
                .animation(
                    reduceMotion ? nil : .timingCurve(0.5, 0, 0.75, 0.3, duration: GalleyTearOff.fade),
                    value: tearing
                )
                .allowsHitTesting(!tearing)
            if let count = paidCount {
                paid(count)
                    .offset(y: paidOffset)
                    .transition(.identity)
            }
        }
        // The layer behind the paper is paper, never white: nothing flashes at the edges while the ticket lifts.
        .background(GalleyPaper.sheet.ignoresSafeArea())
        .onChange(of: Self.facts(model: model, trip: trip, pushed: pushed).tonightCovered) { old, now in
            // Only on the change from not covered to covered; it goes back to the count after 2.2 s.
            guard now, !old else { return }
            celebrating = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(2200))
                celebrating = false
            }
        }
        .onAppear(perform: begin)
        .tesseraFeedback(cue)
        #if DEBUG
            .task {
                // Simulator only (LaunchFlags): `-shopGot` checks the first thing after 3 s (the pen stroke);
                // `-shopPay` checks three things, then pays after 3 s (the tear-off); `-shopNotHere` sends the first
                // thing to the end of its aisle after 3 s, for stills and recordings.
                let pay = LaunchFlags.has("-shopPay")
                guard LaunchFlags.has("-shopGot") || LaunchFlags.has("-shopNotHere") || pay else { return }
                try? await Task.sleep(for: .seconds(3))
                let groceries = Groceries(store: model.store, classes: model.classes)
                if pay {
                    for item in groceries.aisles().flatMap(\.items).prefix(3) {
                        _ = try? model.engine.perform(CheckListItem(item: item.id, time: AppClock.now), by: .user)
                    }
                    model.touch()
                    try? await Task.sleep(for: .seconds(1))
                }
                let facts = Self.facts(model: model, trip: trip, pushed: pushed)
                if pay {
                    self.pay(facts, 0)
                } else if LaunchFlags.has("-shopNotHere") {
                    notHere(facts, 0)
                } else {
                    got(facts, 0)
                }
            }
        #endif
    }

    private func ticket(facts: GalleyShopFacts, index: Int, data: GalleyShopScreen) -> some View {
        GalleyModeScreen(room: "Galley", topRight: celebrating ? (facts.coveredLine ?? data.topRight) : data.topRight,
                         topRightEmphasis: celebrating ? GalleyPaper.olive : nil, back: { dismiss() },
                         verb: { got(facts, index) })
        {
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
                        .arrives(shown, order: 0, reduceMotion: reduceMotion)
                        .padding(.top, 18)
                    if let amount = data.amount {
                        Text(amount)
                            .font(GalleyPaper.number(34, weight: .regular))
                            .foregroundStyle(GalleyPaper.ochre)
                            .arrives(shown, order: 1, reduceMotion: reduceMotion)
                    }
                    if let why = data.why {
                        Text(why)
                            .font(GalleyPaper.plex(.medium, 19))
                            .foregroundStyle(GalleyPaper.ink)
                            .arrives(shown, order: 2, reduceMotion: reduceMotion)
                            .padding(.top, 8)
                    }
                    if let tip = data.tip {
                        label("Tip") {
                            Text(tip)
                                .font(GalleyPaper.plex(.regular, 19))
                                .foregroundStyle(GalleyPaper.ink)
                                .lineLimit(2)
                        }
                        .arrives(shown, order: 3, reduceMotion: reduceMotion)
                    }
                    label("In this aisle") {
                        VStack(spacing: 5) {
                            ForEach(Array((listOverride ?? data.inAisle).prefix(5).enumerated()),
                                    id: \.element.id)
                            { offset, line in
                                // The pen strikes the thing's own row, in place: the row stays where it is, dimmed.
                                GalleyLeaderRow(name: line.name, amount: line.amount, struck: line.struck)
                                    .opacity(offset == 0 && faded ? 0.45 : 1)
                                    .overlay {
                                        if pen != nil, offset == 0, !line.struck {
                                            GalleyPenStroke(progress: penProgress)
                                                .stroke(GalleyPaper.ink,
                                                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        }
                                    }
                                    // "Not here" (339): the skipped row lifts out and settles in last, fading in on the
                                    // second half.
                                    .opacity(line.id == landing && !landed ? 0 : 1)
                                    .offset(y: line.id == landing && !landed ? -10 : 0)
                                    .animation(reduceMotion ? nil : .easeIn(duration: 0.22).delay(0.22), value: landed)
                                    .transition(.identity)
                            }
                        }
                        .frame(maxWidth: 230)
                        .arrives(shown, order: 4, reduceMotion: reduceMotion)
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
                            small("Pay", hold: true) { pay(facts, index) }
                        }
                        GalleyModeVerb(word: data.verb, object: data.object, tint: GalleyPaper.olive) {
                            got(facts, index)
                        }
                    }
                    Spacer(minLength: 8)
                    GalleyModeRail(items: data.rail, tint: GalleyPaper.olive) { id in
                        if id < GalleyShopScreen.doneIDBase {
                            focus = id
                        }
                    }
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
            // The next thing replaces this one in place: no cross-fade (two words never overlap), so the check is
            // written without an animation and the ticket is whole again at once.
            var swap = Transaction()
            swap.disablesAnimations = true
            withTransaction(swap) {
                shown = false
                check(id, animated: false)
                pen = nil
                faded = false
                penProgress = 0
            }
            // Then the new thing, its how and its tip come in from 30 pt right, 360 ms, 40 ms apart. No cross-fade.
            await Task.yield()
            shown = true
        }
    }

    private func check(_ id: UUID, animated: Bool = true) {
        let checked = try? model.engine.perform(CheckListItem(item: id, time: AppClock.now), by: .user)
        if animated {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { model.touch() }
        }
        if checked == nil {
            TessVoice.shared.say("Didn't save that. Try again")
        }
    }

    /// Not here: the thing moves to the end of its aisle.
    private func notHere(_ facts: GalleyShopFacts, _ index: Int) {
        guard facts.aisles.indices.contains(index), let first = facts.aisles[index].items.first else { return }
        // Sheet 355: "Cilantro, later in this aisle" carries Undo; the line goes back to its old place.
        let id = first.id
        TessVoice.shared.say("\(first.name), later in this aisle", holds: .seconds(10), takeBack: {
            pushed.removeAll { $0 == id }
        })
        guard !reduceMotion else {
            pushed.append(first.id)
            return
        }
        let shownRows = GalleyShopScreen(facts, aisle: index).inAisle
        let plan = GalleyNotHere.plan(rows: shownRows, moving: first.id)
        Task { @MainActor in
            // The other rows slide up over 340 ms (the skipped row is not among them: rows never cross)...
            landing = first.id
            landed = false
            listOverride = plan.without
            withAnimation(.easeInOut(duration: GalleyNotHere.slide)) { listOverride = plan.without }
            // The thing at the top changes with the data: swap, then arrive.
            var swap = Transaction()
            swap.disablesAnimations = true
            withTransaction(swap) {
                shown = false
                pushed.append(first.id)
            }
            await Task.yield()
            shown = true
            try? await Task.sleep(for: .milliseconds(Int(GalleyNotHere.slide * 1000)))
            // ...then the skipped row settles in last over 440 ms, fading in on the second half.
            var land = Transaction()
            land.disablesAnimations = true
            withTransaction(land) { listOverride = plan.final }
            withAnimation(.easeOut(duration: GalleyNotHere.settle)) { landed = true }
            try? await Task.sleep(for: .milliseconds(Int(GalleyNotHere.settle * 1000)))
            listOverride = nil
            landing = nil
        }
    }

    /// Pay: what is in the basket walks to its Pantry place in the same step as the finish, with one Undo.
    private func pay(_ facts: GalleyShopFacts, _ index: Int) {
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
        frozen = (facts, index)
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
                                        name: GalleyCookWords.capital(trip.label(
                                            for: entry,
                                            name: GroceriesCopy.name(entry),
                                            lastWeightKg: weight
                                        )),
                                        amount: entry.quantity, why: names.first.map { "For the \($0.lowercased())" })
        }
        var facts = GalleyShopFacts()
        facts.aisles = groceries.aisles().map { aisle in
            var items = aisle.items.map(item)
            items = items.filter { !pushed.contains($0.id) } + pushed.compactMap { id in items.first { $0.id == id } }
            let got = basket.filter { Aisle.shown($0.section ?? Aisle.other.rawValue) == aisle.aisle }.map(item)
            return GalleyShopFacts.Aisle(name: aisle.aisle, items: items, got: got)
        }
        let open = Set(facts.aisles.map(\.name))
        facts.doneAisles = Array(Set(basket.map { Aisle.shown($0.section ?? Aisle.other.rawValue) }))
            .filter { !open.contains($0) }
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

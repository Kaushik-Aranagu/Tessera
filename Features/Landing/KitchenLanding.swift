import SwiftUI
import TesseraCore

// MARK: - The pass (sheet 259, landing contract v2 §2: the Galley keystone)

/// One paper ticket on the pass. Its pages are what a flip shows; a big ticket takes 2.4 shares of the rail.
struct GalleyTicket: Identifiable, Equatable {
    enum Opens: Equatable {
        case recipe(UUID)
        case recipes
        case groceries
        case pantry
    }

    enum Ink: Equatable {
        case dinner, toGet, runsOut, ask
    }

    let id: String
    let title: String
    let sub: String?
    /// Every line, before paging.
    let lines: [String]
    let big: Bool
    let ink: Ink
    let opens: Opens

    /// Lines a page holds in the 182 pt slot (259 v2): about six on a big ticket, three on a small one.
    var perPage: Int {
        big ? 6 : 3
    }

    /// The ticket's pages; always at least one (an empty ticket still has its title).
    var pages: [[String]] {
        guard !lines.isEmpty else { return [[]] }
        return stride(from: 0, to: lines.count, by: perPage).map { Array(lines[$0 ..< min($0 + perPage, lines.count)]) }
    }

    var share: CGFloat {
        big ? 2.4 : 1
    }
}

/// The landing's tickets as data, so the pass has tests: tonight's dinner, To get, what runs out. Walled recipes and
/// items never reach a ticket; they are counted.
struct GalleyPass: Equatable {
    struct Dinner: Equatable {
        let recipe: UUID?
        /// Already "Private recipe" when walled.
        let title: String
        let isPrivate: Bool
        let start: String?
        let ingredients: [String]
    }

    struct Stock: Equatable {
        let name: String
        let state: PantryLedger.State
        let isPrivate: Bool
    }

    var tickets: [GalleyTicket] = []
    var stateLine: [String] = []
    var hidden = 0
    var low: [String] = []
    var toGet: [String] = []
    var cookable: [String] = []

    static let maxTickets = 4

    static func build(dinner: Dinner?, toGet: [String], stock: [Stock], cookable: [String],
                      cooking: String?) -> GalleyPass
    {
        var pass = GalleyPass()
        let openToGet = toGet.filter { $0 != "Private item" }
        let openStock = stock.filter { !$0.isPrivate }
        pass.low = openStock.filter { $0.state == .out || $0.state == .low }.sorted { $0.state < $1.state }.map(\.name)
        pass.toGet = openToGet
        pass.cookable = cookable
        pass.hidden = toGet.count - openToGet.count + stock.count - openStock.count
        if let dinner {
            // A walled dinner keeps its ticket as "Private recipe" and shows nothing of what is in it.
            pass.tickets.append(GalleyTicket(id: "dinner", title: dinner.title, sub: dinner.start.map { "start \($0)" },
                                             lines: dinner.isPrivate ? [] : dinner.ingredients, big: true,
                                             ink: .dinner,
                                             opens: dinner.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes))
        } else {
            pass.tickets.append(GalleyTicket(id: "dinner", title: "Tonight?", sub: "nothing planned yet",
                                             lines: cookable.isEmpty ? [] : ["you could make"] + cookable,
                                             big: !cookable.isEmpty, ink: .ask, opens: .recipes))
        }
        if !openToGet.isEmpty {
            pass.tickets.append(GalleyTicket(id: "toget", title: "To get", sub: "\(openToGet.count) on the list",
                                             lines: openToGet, big: false, ink: .toGet, opens: .groceries))
        }
        if !pass.low.isEmpty {
            pass.tickets.append(GalleyTicket(id: "runsout", title: "Runs out", sub: "first to go", lines: pass.low,
                                             big: false, ink: .runsOut, opens: .pantry))
        }
        pass.tickets = Array(pass.tickets.prefix(maxTickets))
        pass.stateLine = stateLine(dinner: dinner, cooking: cooking, cookable: cookable.count)
        return pass
    }

    /// A cook running: its own line first. Planned: "Tacos tonight, start at 6:05." then shorter. Nothing planned:
    /// "Tonight? Nothing planned yet." (contract §12 empty state).
    static func stateLine(dinner: Dinner?, cooking: String?, cookable: Int) -> [String] {
        var forms: [String] = []
        if let cooking {
            forms.append(cooking)
        }
        if let dinner {
            if let start = dinner.start {
                forms.append("\(dinner.title) tonight, start at \(start).")
            }
            forms.append("\(dinner.title) tonight.")
            return forms
        }
        if cookable > 0 {
            forms.append("Tonight? Nothing planned yet, you could make \(cookable).")
        }
        forms.append("Tonight? Nothing planned yet.")
        return forms
    }

    /// The update row: "Eggs and milk run out first." / "Eggs runs out first." Nothing low: nil.
    var lowLine: [LandingBrief.Form]? {
        guard let first = low.first else { return nil }
        if low.count >= 2 {
            let pair = "\(low[0]) and \(low[1])"
            return [LandingBrief.Form(text: "\(pair) run out first.", key: pair),
                    LandingBrief.Form(text: "\(first) runs out first.", key: first)]
        }
        return [LandingBrief.Form(text: "\(first) runs out first.", key: first)]
    }
}

/// The rail: a 1 pt line across the top of the slot, the tickets hung from it in shares (big 2.4, others 1). Swipe up
/// on a ticket flips it over its clip to the next page, down flips back; a tap opens its thing.
struct GalleyRail: View {
    let tickets: [GalleyTicket]
    var open: (GalleyTicket.Opens) -> Void

    static let gap: CGFloat = 8
    static let railY: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let shares = tickets.reduce(0) { $0 + $1.share }
            let room = proxy.size.width - Self.gap * CGFloat(max(tickets.count - 1, 0))
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Theme.Colors.inkSecondary.opacity(0.6))
                    .frame(height: 1)
                    .offset(y: Self.railY)
                    .accessibilityHidden(true)
                HStack(alignment: .top, spacing: Self.gap) {
                    ForEach(tickets) { ticket in
                        GalleyTicketView(ticket: ticket, open: open)
                            .frame(width: room * ticket.share / max(shares, 1), height: proxy.size.height - Self.railY)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .top)))
                    }
                }
                .offset(y: Self.railY - 3)
            }
            .tesseraAnimation(Theme.Motion.house, value: tickets.map(\.id))
        }
    }
}

/// One ticket: a clip at the top, paper with a torn foot, the title in the thing's colour in the kitchen hand, a sub
/// line, the page's lines, and "over" when there is a next page. Swipe up flips to the next page, down flips back.
struct GalleyTicketView: View {
    let ticket: GalleyTicket
    var open: (GalleyTicket.Opens) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var page = 0
    @State private var turn: Double = 0
    @State private var cue = HapticCue()

    private var dark: Bool {
        scheme == .dark
    }

    private var paper: Color {
        dark ? Color(hex: 0x2B2722) : Color(hex: 0xF6EFDF)
    }

    private var titleColor: Color {
        switch ticket.ink {
        case .dinner: dark ? Color(hex: 0xE2A07F) : Color(hex: 0x9C4B2C)
        case .toGet: dark ? Color(hex: 0xB5BE7A) : Color(hex: 0x5E6B1F)
        case .runsOut: dark ? Color(hex: 0xEE8E9C) : Color(hex: 0x9A2541)
        case .ask: LandingAccent.kitchen
        }
    }

    var body: some View {
        let pages = ticket.pages
        let shown = pages[min(page, pages.count - 1)]
        VStack(alignment: .leading, spacing: 0) {
            Text(ticket.title)
                .font(.custom("Caveat", fixedSize: ticket.big ? 30 : 25).weight(.bold))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let sub = ticket.sub {
                Text(sub)
                    .font(.custom("Caveat", fixedSize: 18))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            ForEach(Array(shown.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.custom("Caveat", fixedSize: 19))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            if pages.count > 1 {
                Text(page < pages.count - 1 ? "over" : "back")
                    .font(.custom("Caveat", fixedSize: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { TornPaper().fill(paper) }
        .overlay(alignment: .top) { clip }
        .rotation3DEffect(.degrees(turn), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.4)
        .contentShape(Rectangle())
        .onTapGesture { open(ticket.opens) }
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            guard abs(value.translation.height) > abs(value.translation.width), abs(value.translation.height) > 40
            else { return }
            flip(value.translation.height < 0 ? 1 : -1)
        })
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(([ticket.title, ticket.sub].compactMap(\.self) + shown).joined(separator: ", "))
        .accessibilityHint("Opens it")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open(ticket.opens) }
        .accessibilityAdjustableAction { direction in flip(direction == .increment ? 1 : -1) }
        .onChange(of: ticket.lines) { _, _ in page = min(page, max(ticket.pages.count - 1, 0)) }
    }

    /// The clip the ticket hangs from: a short ink stroke over the rail.
    private var clip: some View {
        Rectangle()
            .fill(Theme.Colors.inkSecondary)
            .frame(width: 18, height: 6)
            .offset(y: -3)
            .accessibilityHidden(true)
    }

    /// Over the clip to the next page (rotate to edge-on, swap the page, come back round), or back. At either end the
    /// ticket only nods. Reduce Motion swaps the page in place.
    private func flip(_ step: Int) {
        let pages = ticket.pages.count
        let next = page + step
        guard next >= 0, next < pages else {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { turn = step > 0 ? -8 : 8 }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { turn = 0 }
            return
        }
        cue.play(.selection)
        if reduceMotion {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: true) { page = next }
            return
        }
        Task { @MainActor in
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { turn = step > 0 ? -90 : 90 }
            try? await Task.sleep(for: .milliseconds(220))
            page = next
            turn = step > 0 ? 90 : -90
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { turn = 0 }
        }
    }
}

/// Paper with a torn foot: straight sides and top, a small irregular zigzag along the bottom.
struct TornPaper: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
        let teeth = max(Int(rect.width / 9), 4)
        let step = rect.width / CGFloat(teeth)
        let depths: [CGFloat] = [4, 1, 3, 0, 4, 2, 1, 3]
        for index in (0 ..< teeth).reversed() {
            let x = rect.minX + step * CGFloat(index)
            path.addLine(to: CGPoint(x: x + step / 2, y: rect.maxY - depths[index % depths.count]))
            path.addLine(to: CGPoint(x: x, y: rect.maxY - 4))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - The page

/// The Galley's landing (landing contract v2: hub 282, sheet 259): the sentence at 106, the pass in the keystone slot,
/// its caption at 390, one update row at 424, the doors at 540, "Cook" (or "Plan tonight") at the foot.
struct KitchenLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var open
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var cookCover: KitchenCookCover?
    @State private var recipe: KitchenCookCover?
    @State private var focus = 0
    @State private var switcherIndex = 0
    @State private var switcherVerticalIndex = 0
    @State private var widgetIndex = 0

    static let switcher = ["Tonight", "Tomorrow", "This week"]

    var body: some View {
        let _ = model.revision
        let front = KitchenFront(model: model, now: AppClock.now)
        let pass = load(front)
        LandingScaffold(title: "Galley", accent: LandingAccent.kitchen, navWord: "Bridge", onBack: { dismiss() },
                        switcher: Self.switcher, switcherIndex: $switcherIndex,
                        switcherVerticalIndex: $switcherVerticalIndex,
                        needs: needs(front, pass),
                        keystone: {
                            LandingKeystone(label: "The pass") {
                                GalleyRail(tickets: pass.tickets) { opens in go(opens) }
                            }
                        },
                        caption: caption(pass).map { [$0] } ?? [],
                        widget: widget(front, pass), widgetIndex: $widgetIndex,
                        openWidget: { item in
                            switch item.id {
                            case "cooking": cookCover = front.cooking.map { KitchenCookCover(id: $0.id) }
                            case "dinner": go(front.tonight?.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes)
                            case "toget": open(.groceries)
                            case "runsout": open(.pantry)
                            default: open(.recipes)
                            }
                        },
                        glyph: { _ in GalleyGlyph() },
                        doors: doors(front, pass), focus: $focus,
                        openDoor: { door in
                            switch door.id {
                            case "tonight": go(front.tonight?.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes)
                            case "pantry", "leftovers": open(.pantry)
                            case "groceries": open(.groceries)
                            default: open(.recipes)
                            }
                        },
                        action: action(front))
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $cookCover) { CookClockPage(cookID: $0.id) }
            .fullScreenCover(item: $recipe) { RecipeView(recipeID: $0.id) }
    }

    private func go(_ opens: GalleyTicket.Opens) {
        switch opens {
        case let .recipe(id): recipe = .init(id: id)
        case .recipes: open(.recipes)
        case .groceries: open(.groceries)
        case .pantry: open(.pantry)
        }
    }

    // MARK: Facts

    private func load(_ front: KitchenFront) -> GalleyPass {
        let ledger = PantryLedger(store: model.store, classes: model.classes)
        let stock = ledger.entries().map { GalleyPass.Stock(name: $0.label, state: $0.state, isPrivate: $0.isPrivate) }
        let covered = TesseraCore.KitchenLanding(store: model.store, classes: model.classes).coveredRecipes()
            .filter { !$0.isDeleted && !RecipeCopy.isPrivate($0.title, model: model) }
            .map(\.title)
        let board = PantryBoard(store: model.store, classes: model.classes) { GroceriesCopy.name($0) }
        let toGet = board.toGet.flatMap(\.rows).compactMap { row -> String? in
            if case let .toGet(_, label) = row {
                return label
            }
            return nil
        }
        let dinner = front.tonight.map { meal -> GalleyPass.Dinner in
            let isPrivate = meal.title == "Private recipe"
            let book = RecipeBook(store: model.store, classes: model.classes)
            let lines = meal.recipe.flatMap { model.store.object(id: $0) }
                .map { book.lines(of: $0).map(\.line.original) } ?? []
            return GalleyPass.Dinner(recipe: meal.recipe, title: meal.title, isPrivate: isPrivate,
                                     start: HouseTime.clock(meal.start), ingredients: lines)
        }
        return GalleyPass.build(dinner: dinner, toGet: toGet, stock: stock, cookable: covered,
                                cooking: front.cooking?.line)
    }

    private func caption(_ pass: GalleyPass) -> String? {
        if pass.tickets.contains(where: { $0.pages.count > 1 }) {
            return "Swipe a ticket up for its next page."
        }
        return pass.hidden > 0 ? "\(pass.hidden) private kept off the pass." : nil
    }

    /// Tonight, Pantry, Recipes, Groceries, Leftovers (contract v2 §12). Leftovers has no model yet and opens Pantry.
    private func doors(_ front: KitchenFront, _ pass: GalleyPass) -> [DialDoor] {
        let dark = scheme == .dark
        let wine = dark ? Color(hex: 0xEE8E9C) : Color(hex: 0x9A2541)
        let slate = dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
        let olive = dark ? Color(hex: 0xB5BE7A) : Color(hex: 0x5E6B1F)
        let planned = front.week
            .compactMap { day in day.meal.map { "\(day.weekday) \(NotesLandingPage.short($0.title))" } }
        return [
            DialDoor(id: "tonight", name: "Tonight", color: slate,
                     label: front.tonight == nil ? "Nothing planned yet" : "Next \(front.week.count) days",
                     lines: Array(planned.prefix(3))),
            DialDoor(id: "pantry", name: "Pantry", count: pass.low.isEmpty ? nil : "\(pass.low.count)",
                     color: pass.low.isEmpty ? Theme.Colors.ink : wine,
                     label: pass.low.isEmpty ? "Nothing running low" : "Running low", lines: Array(pass.low.prefix(3))),
            DialDoor(id: "recipes", name: "Recipes", count: front.saved > 0 ? "\(front.saved)" : nil,
                     color: LandingAccent.kitchen,
                     label: pass.cookable.isEmpty ? nil : "You can make \(pass.cookable.count) now",
                     lines: Array(pass.cookable.prefix(3))),
            DialDoor(id: "groceries", name: "Groceries", count: pass.toGet.isEmpty ? nil : "\(pass.toGet.count)",
                     color: olive, label: pass.toGet.isEmpty ? "Nothing to get" : "To get",
                     lines: Array(pass.toGet.prefix(3))),
            DialDoor(id: "leftovers", name: "Leftovers", color: Theme.Colors.ink, label: "Kept in Pantry for now"),
        ]
    }

    /// Two lines beside the switcher, changing with it (283): tonight, tomorrow, or the week.
    private func needs(_ front: KitchenFront, _ pass: GalleyPass) -> [String] {
        switch switcherIndex {
        case 1:
            let tomorrow = front.week.dropFirst().first
            return [tomorrow?.meal.map { "\($0.title) tomorrow" } ?? "Nothing planned tomorrow",
                    tomorrow?.when ?? "Plan it from Recipes"]
        case 2:
            let planned = front.week.count { $0.meal != nil }
            return [planned == 0 ? "Nothing planned this week" : "\(planned) dinners planned",
                    pass.toGet.isEmpty ? "Nothing to get" : "\(pass.toGet.count) to get"]
        default:
            if let cook = front.cooking {
                return [cook.line, "Tap the dish to go on"]
            }
            let first = front.tonight.map { "\($0.title) tonight" } ?? "Tonight?"
            let second = front.tonight.map { "start \(HouseTime.clock($0.start))" } ?? "Nothing planned yet"
            return [first, pass.low.first.map { "\($0) runs out first" } ?? second]
        }
    }

    /// The widget (283): tonight's dish, what is on the way, what runs out. Big lines in the kitchen hand.
    private func widget(_ front: KitchenFront, _ pass: GalleyPass) -> [WidgetItem] {
        var items: [WidgetItem] = []
        if let cook = front.cooking {
            items.append(WidgetItem(id: "cooking", header: "Cooking", big: "Go on", middle: cook.line,
                                    small: "Tap for the clock", bigColor: LandingAccent.kitchen, strikeable: false, handwritten: true))
        }
        if let meal = front.tonight {
            items.append(WidgetItem(id: "dinner", header: "Tonight", big: NotesLandingPage.short(meal.title),
                                    middle: "start \(HouseTime.clock(meal.start))",
                                    small: meal.minutes.map { HouseTime.minutes(Int($0)) } ?? "Tap to open it",
                                    bigColor: LandingAccent.kitchen, strikeable: false, handwritten: true))
        } else {
            items.append(WidgetItem(id: "plan", header: "Tonight", big: "Tonight?", middle: "nothing planned yet",
                                    small: pass.cookable.isEmpty ? "Tap for Recipes"
                                        : "You could make \(pass.cookable.count)",
                                    bigColor: LandingAccent.kitchen, strikeable: false, handwritten: true))
        }
        if !pass.toGet.isEmpty {
            items.append(WidgetItem(id: "toget", header: "On the way", big: "\(pass.toGet.count)", bigIsNumber: true,
                                    unit: pass.toGet.count == 1 ? "thing" : "things",
                                    middle: pass.toGet.prefix(2).joined(separator: ", "), small: "To get",
                                    strikeable: false))
        }
        if let low = pass.low.first {
            items.append(WidgetItem(id: "runsout", header: "Runs out", big: NotesLandingPage.short(low),
                                    middle: pass.low.count > 1 ? "and \(pass.low.count - 1) more" : "first to go",
                                    small: "Tap for Pantry", strikeable: false, handwritten: true))
        }
        return items
    }

    /// Cook when a meal is planned tonight, else Plan tonight. Drag right: Paste a recipe.
    private func action(_ front: KitchenFront) -> LandingFootAction {
        let paste = LandingFootAction.Option(name: "Paste a recipe") { open(.pasteRecipe) }
        if let meal = front.tonight {
            return LandingFootAction(word: "Cook", hint: "Starts \(meal.title)", right: paste) { cook(meal) }
        }
        return LandingFootAction(word: "Plan tonight", hint: "Opens Recipes", right: paste) { open(.recipes) }
    }

    /// Cook: tonight's recipe starts at its size and its clock opens (the same as Cook on the recipe page).
    private func cook(_ meal: KitchenFront.Meal) {
        guard let recipe = meal.recipe else {
            open(.recipes)
            return
        }
        guard let cook = try? model.engine.perform(StartCooking(recipe: recipe, time: AppClock.now), by: .user).output
        else {
            TessVoice.shared.say("Didn't start that. Try again.")
            return
        }
        model.touch()
        cookCover = .init(id: cook.id)
    }
}

/// The widget glyph (283): one ticket hung on a rail, swinging as it is hung. It moves once on arrival and every 7 s;
/// nothing moves under Reduce Motion.
struct GalleyGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var swing: Double = 0

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle().fill(Theme.Colors.inkSecondary.opacity(0.6)).frame(width: 64, height: 1)
            TornPaper()
                .fill(scheme == .dark ? Color(hex: 0x2B2722) : Color(hex: 0xF6EFDF))
                .frame(width: 34, height: 46)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Capsule().fill(LandingAccent.kitchen).frame(width: 18, height: 2)
                        Capsule().fill(Theme.Colors.inkSecondary).frame(width: 22, height: 1.5)
                        Capsule().fill(Theme.Colors.inkSecondary).frame(width: 14, height: 1.5)
                    }
                    .padding(6)
                }
                .rotationEffect(.degrees(swing), anchor: .top)
                .offset(y: 2)
        }
        .frame(width: 80, height: 80, alignment: .top)
        .padding(.top, 10)
        .accessibilityHidden(true)
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { swing = 10 }
                try? await Task.sleep(for: .milliseconds(250))
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { swing = 0 }
                try? await Task.sleep(for: .seconds(7))
            }
        }
    }
}

struct KitchenCookCover: Identifiable {
    let id: UUID
}

#if DEBUG
    /// `-kitchen`: the Galley landing on its own, with its doors opening as Home would open them.
    struct KitchenLandingHost: View {
        @State private var link: HomeLink?

        var body: some View {
            KitchenLandingPage()
                .environment(\.openHomeLink) { link = $0 }
                .fullScreenCover(item: $link) { $0.destination }
        }
    }
#endif

import SwiftUI
import TesseraCore

/// The Galley as content for the standing shell (sheet 283 v5), and the one source of the Galley landing's words:
/// `KitchenLandingPage` (the scaffold) reads the same `Facts`. Level 0 is the landing; level 1 a door page (Tonight,
/// Pantry, Recipes, Groceries, Leftovers): the Door title and a Page of that door's rows. The pass keeps the same id at
/// both levels, so its tickets stay on the rail when a door opens. Walled recipes and items never reach a ticket or a
/// row as words. Pure: no views, no store reads.
struct GalleyRoomContent: RoomContent {
    static let room = "galley"
    static let switcher = ["Tonight", "Tomorrow", "This week"]
    static let sceneKey = "galley.rail"

    struct Facts: Equatable {
        var pass = GalleyPass()
        var doors: [DialDoor] = []
        /// The needs for each switcher word, in `switcher` order.
        var needs: [[String]] = [[], [], []]
        var caption: String?
        var widget: [WidgetItem] = []
        /// Cook's object: tonight's dish (short), or "Pick tonight's dish".
        var cookObject = "Pick tonight's dish"
        var cookHint = "Opens Recipes"
        /// Each door's rows, for its page.
        var rows: [String: [ShellRow]] = [:]
    }

    let facts: Facts
    var accent: Color = LandingAccent.kitchen

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(route.door ?? "tonight")
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let widget = facts.widget
        let item = widget.indices.contains(state.widgetIndex) ? widget[state.widgetIndex] : widget.first
        let doors = facts.doors
        let focused = doors.isEmpty ? nil : doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
        let window = facts.needs.indices.contains(state.switcherIndex) ? state.switcherIndex : 0
        return Screen(layout: .landing, slots: [
            .title: title,
            .navWord: SlotContent(id: "galley.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "galley.switcher", kind: .switcher,
                                   payload: .switcher(across: Self.switcher, vertical: [])),
            .needs: SlotContent(id: ContentID("galley.needs.\(window)"), kind: .text,
                                payload: .lines(facts.needs[window])),
            .keystone: keystone,
            .caption: caption,
            .widget: widget.isEmpty ? nil : SlotContent(id: "galley.widget", kind: .widget, payload: .widget(widget)),
            .glyph: item.map { SlotContent(id: ContentID("galley.glyph.\($0.id)"), kind: .glyph,
                                           payload: .glyph($0, color: $0.bigColor ?? accent)) },
            .dial: doors.isEmpty ? nil : SlotContent(id: "galley.dial", kind: .dial, payload: .dial(doors)),
            .doorSummary: focused.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : SlotContent(id: ContentID("galley.summary.\(door.id)"), kind: .summary, payload: .summary(door))
            },
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Level 1

    private func door(_ id: String) -> Screen {
        let door = facts.doors.first { $0.id == id }
        let rows = facts.rows[id] ?? []
        let line = rows.isEmpty ? (door?.label ?? "Nothing here yet.") : Self.countLine(id, rows.count)
        return Screen(layout: .door, slots: [
            .title: title,
            .navWord: SlotContent(id: "galley.nav.galley", kind: .text, payload: .navWord("Galley")),
            .doorTitle: SlotContent(id: ContentID("galley.door.\(id).title"), kind: .text,
                                    payload: .doorTitle(name: door?.name ?? "Tonight", line: line,
                                                        color: door?.color ?? accent)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("galley.door.\(id).page"), kind: .list, payload: .list(rows)),
            .actionWord: action,
            .tess: nil,
        ])
    }

    static func countLine(_ door: String, _ count: Int) -> String {
        switch door {
        case "tonight": count == 1 ? "1 dinner planned." : "\(count) dinners planned."
        case "pantry": "\(count) running low."
        case "recipes": "You can make \(count) now."
        case "groceries": "\(count) to get."
        default: "\(count) kept."
        }
    }

    // MARK: Shared by both levels (same ids: the pass, title, caption and action are not touched)

    private var title: SlotContent {
        SlotContent(id: "galley.title", kind: .text, payload: .title("Galley", accent: accent))
    }

    private var keystone: SlotContent {
        SlotContent(id: ContentID(Self.sceneKey), kind: .scene, payload: .scene(Self.sceneKey, label: "The pass"))
    }

    private var caption: SlotContent? {
        facts.caption.map { SlotContent(id: "galley.caption", kind: .text, payload: .lines([$0])) }
    }

    private var action: SlotContent {
        SlotContent(id: "galley.action", kind: .action, payload: .action([
            ShellStep(id: "cook", verb: "Cook", object: facts.cookObject),
            ShellStep(id: "get", verb: "Get", object: "To get"),
        ], accent: accent))
    }
}

// MARK: - The facts (one source for the scaffold landing and the shell)

extension GalleyRoomContent {
    /// Each door's meaning colour (241), worn by the dial focus. Tonight is the room's own ochre (QA: it was slate,
    /// the planned colour, which read as another room); Pantry is wine only while something runs low.
    enum DoorTone: Equatable {
        case ochre, wine, olive, ink
    }

    static func tone(door id: String, lowEmpty: Bool) -> DoorTone {
        switch id {
        case "tonight", "recipes": .ochre
        case "pantry": lowEmpty ? .ink : .wine
        case "groceries": .olive
        default: .ink
        }
    }

    static func color(_ tone: DoorTone, scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        return switch tone {
        case .ochre: LandingAccent.kitchen
        case .wine: dark ? Color(hex: 0xEE8E9C) : Color(hex: 0x9A2541)
        case .olive: dark ? Color(hex: 0xB5BE7A) : Color(hex: 0x5E6B1F)
        case .ink: Theme.Colors.ink
        }
    }
}

extension GalleyRoomContent.Facts {
    /// The Galley's facts from the store (the pass, the doors, the needs, the widget and the rows).
    @MainActor
    static func load(model: AppModel, scheme: ColorScheme, front: KitchenFront? = nil) -> Self {
        let front = front ?? KitchenFront(model: model, now: AppClock.now)
        let pass = pass(model: model, front: front)
        var facts = Self()
        facts.pass = pass
        facts.doors = doors(front, pass, scheme: scheme)
        facts.needs = (0 ..< GalleyRoomContent.switcher.count).map { needs(front, pass, window: $0) }
        facts.caption = caption(pass)
        facts.widget = widget(front, pass)
        if let meal = front.tonight {
            facts.cookObject = NotesLandingPage.short(meal.title)
            facts.cookHint = "Starts \(meal.title)"
        }
        facts.rows = rows(front, pass)
        return facts
    }

    @MainActor
    static func pass(model: AppModel, front: KitchenFront) -> GalleyPass {
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

    static func caption(_ pass: GalleyPass) -> String? {
        if pass.tickets.contains(where: { $0.pages.count > 1 }) {
            return "Swipe a ticket up for its next page."
        }
        return pass.hidden > 0 ? "\(pass.hidden) private kept off the pass." : nil
    }

    /// Tonight, Pantry, Recipes, Groceries, Leftovers (contract v2 §12). Leftovers has no model yet and opens Pantry.
    static func doors(_ front: KitchenFront, _ pass: GalleyPass, scheme: ColorScheme) -> [DialDoor] {
        let low = pass.low.isEmpty
        func color(_ id: String) -> Color {
            GalleyRoomContent.color(GalleyRoomContent.tone(door: id, lowEmpty: low), scheme: scheme)
        }
        let planned = front.week
            .compactMap { day in day.meal.map { "\(day.weekday) \(NotesLandingPage.short($0.title))" } }
        return [
            DialDoor(id: "tonight", name: "Tonight", color: color("tonight"),
                     label: front.tonight == nil ? "Nothing planned yet" : "Next \(front.week.count) days",
                     lines: Array(planned.prefix(3))),
            DialDoor(id: "pantry", name: "Pantry", count: pass.low.isEmpty ? nil : "\(pass.low.count)",
                     color: color("pantry"),
                     label: pass.low.isEmpty ? "Nothing running low" : "Running low", lines: Array(pass.low.prefix(3))),
            DialDoor(id: "recipes", name: "Recipes", count: front.saved > 0 ? "\(front.saved)" : nil,
                     color: color("recipes"),
                     label: pass.cookable.isEmpty ? nil : "You can make \(pass.cookable.count) now",
                     lines: Array(pass.cookable.prefix(3))),
            DialDoor(id: "groceries", name: "Groceries", count: pass.toGet.isEmpty ? nil : "\(pass.toGet.count)",
                     color: color("groceries"),
                     label: pass.toGet.isEmpty ? "Nothing to get" : "To get",
                     lines: Array(pass.toGet.prefix(3))),
            DialDoor(id: "leftovers", name: "Leftovers", color: color("leftovers"), label: "Kept in Pantry for now"),
        ]
    }

    /// Two lines beside the switcher, changing with it (283): tonight, tomorrow, or the week.
    static func needs(_ front: KitchenFront, _ pass: GalleyPass, window: Int) -> [String] {
        switch window {
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
    static func widget(_ front: KitchenFront, _ pass: GalleyPass) -> [WidgetItem] {
        var items: [WidgetItem] = []
        if let cook = front.cooking {
            items.append(WidgetItem(id: "cooking", header: "Cooking", big: "Go on", middle: cook.line,
                                    small: "Tap for the clock", bigColor: LandingAccent.kitchen, strikeable: false,
                                    face: .galley))
        }
        if let meal = front.tonight {
            items.append(WidgetItem(id: "dinner", header: "Dinner", big: NotesLandingPage.short(meal.title),
                                    middle: "cook at \(HouseTime.clock(meal.start))",
                                    small: meal.minutes.map { HouseTime.minutes(Int($0)) } ?? "Tap to open it",
                                    bigColor: LandingAccent.kitchen, strikeable: false, face: .galley))
        } else {
            items.append(WidgetItem(id: "plan", header: "Dinner", big: "Tonight?", middle: "nothing planned yet",
                                    small: pass.cookable.isEmpty ? "Tap for Recipes"
                                        : "You could make \(pass.cookable.count)",
                                    bigColor: LandingAccent.kitchen, strikeable: false, face: .galley))
        }
        if !pass.toGet.isEmpty {
            items.append(WidgetItem(id: "toget", header: "On the way", big: "\(pass.toGet.count)", bigIsNumber: true,
                                    unit: pass.toGet.count == 1 ? "thing" : "things",
                                    middle: pass.toGet.prefix(2).joined(separator: ", "), small: "To get",
                                    strikeable: false))
        }
        if let low = pass.low.first {
            items.append(WidgetItem(id: "runsout", header: "Runs out", big: NotesLandingPage.short(low),
                                    middle: pass.low
                                        .count > 1 ? "get it and \(pass.low.count - 1) more" : "first to go, get more",
                                    small: "Tap for Pantry", strikeable: false, face: .galley))
        }
        return items
    }

    /// Each door's page rows. Tonight: the planned week (a walled dish already reads "Private recipe"); Pantry: what
    /// runs low; Recipes: what can be made; Groceries: what to get. Leftovers has no model yet.
    static func rows(_ front: KitchenFront, _ pass: GalleyPass) -> [String: [ShellRow]] {
        var rows: [String: [ShellRow]] = [:]
        rows["tonight"] = front.week.compactMap { day in
            day.meal.map { meal in
                ShellRow(id: meal.recipe?.uuidString ?? "day.\(day.weekday)", title: "\(day.weekday) \(meal.title)",
                         detail: day.when ?? "", isPrivate: meal.title == "Private recipe")
            }
        }
        rows["pantry"] = pass.low.map { ShellRow(id: "pantry.\($0)", title: $0, detail: "Running low") }
        rows["recipes"] = pass.cookable.map { ShellRow(id: "recipe.\($0)", title: $0, detail: "You can make it now") }
        rows["groceries"] = pass.toGet.map { ShellRow(id: "toget.\($0)", title: $0) }
        rows["leftovers"] = []
        return rows
    }
}

/// The Galley opened through the standing shell (`-shellRoom galley` on the simulator). Taps come back as intents: a
/// door pushes its route, a ticket or row opens its thing, Cook starts tonight's dish, back pops.
struct GalleyShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @State private var navigator = ShellNavigator(root: .landing(GalleyRoomContent.room))
    @State private var link: HomeLink?
    @State private var recipe: KitchenCookCover?
    @State private var cookCover: KitchenCookCover?

    var body: some View {
        let _ = model.revision
        let front = KitchenFront(model: model, now: AppClock.now)
        let facts = GalleyRoomContent.Facts.load(model: model, scheme: scheme, front: front)
        ShellView(room: GalleyRoomContent(facts: facts), navigator: navigator, accent: LandingAccent.kitchen) {
            handle($0, front: front)
        }
        .environment(\.doorSummaryStyle, .ticket)
        .environment(\.shellGlyphRoom, .galley)
        .environment(\.shellScene) { _ in
            AnyView(GalleyRail(tickets: facts.pass.tickets) { go($0) })
        }
        .overlay {
            if navigator.route.level == 0 {
                KeystoneHandover(kind: .galleyTicket, from: KitchenLandingPage.firstTicketCentre(facts.pass.tickets))
            }
        }
        .fullScreenCover(item: $link) { $0.destination }
        .fullScreenCover(item: $recipe) { RecipeView(recipeID: $0.id) }
        .fullScreenCover(item: $cookCover) { CookClockPage(cookID: $0.id) }
        #if DEBUG
            .task { await ShellStills.walk(navigator, room: GalleyRoomContent.room) }
        #endif
    }

    private func go(_ opens: GalleyTicket.Opens) {
        switch opens {
        case let .recipe(id): recipe = .init(id: id)
        case .recipes: link = .recipes
        case .groceries: link = .groceries
        case .pantry: link = .pantry
        }
    }

    private func handle(_ intent: ShellIntent, front: KitchenFront) {
        switch intent {
        case .back:
            navigator.pop()
        case let .openDoor(id):
            navigator.push(.door(GalleyRoomContent.room, id))
        case let .openItem(id):
            switch id {
            case "cooking": cookCover = front.cooking.map { KitchenCookCover(id: $0.id) }
            case "dinner": go(front.tonight?.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes)
            case "toget": link = .groceries
            case "runsout": link = .pantry
            default:
                if let uuid = UUID(uuidString: id) {
                    recipe = .init(id: uuid)
                } else if id.hasPrefix("pantry.") {
                    link = .pantry
                } else if id.hasPrefix("toget.") {
                    link = .groceries
                } else {
                    link = .recipes
                }
            }
        case let .action(id):
            if id == "get" {
                link = .groceries
            } else if let meal = front.tonight {
                cook(meal)
            } else {
                link = .recipes
            }
        }
    }

    /// Cook: tonight's recipe starts at its size and its clock opens (the same as Cook on the landing).
    private func cook(_ meal: KitchenFront.Meal) {
        guard let id = meal.recipe else {
            link = .recipes
            return
        }
        guard let cook = try? model.engine.perform(StartCooking(recipe: id, time: AppClock.now), by: .user).output
        else {
            TessVoice.shared.say("Didn't start that. Try again.")
            return
        }
        model.touch()
        cookCover = .init(id: cook.id)
    }
}

#if DEBUG
    /// `-shellDoor <id>` (simulator only, LaunchFlags): opens that door 2 s after launch and, with `-shellBack`, comes
    /// back 3 s later, so stills can catch a room's door page.
    @MainActor
    enum ShellStills {
        static func walk(_ navigator: ShellNavigator, room: String) async {
            guard let door = LaunchFlags.value(after: "-shellDoor") else { return }
            try? await Task.sleep(for: .seconds(2))
            navigator.push(.door(room, door))
            guard LaunchFlags.has("-shellBack") else { return }
            try? await Task.sleep(for: .seconds(3))
            navigator.pop()
        }
    }
#endif

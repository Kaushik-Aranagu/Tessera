import SwiftUI
import TesseraCore

// The rooms as the root shell holds them beside Bridge (sheet 283 v5). Each driver does what the room's own shell host
// does (lane B's `DeckShellHost`, `GalleyShellHost`, ...): loads its facts, draws its keystone, answers its intents and
// presents its pages, but inside the one standing shell, so Bridge to the room and back changes every place in place.
// Back at a room's landing goes to Bridge (the shell pops); a door page goes back up.

// MARK: - Deck

@MainActor
@Observable
final class DeckRoomDriver: ShellRoomDriver {
    let room = DeckRoomContent.room
    let tessRoom: AppID? = .training
    let flip = KeystoneFlip.sweep
    let summaryStyle = DoorSummaryStyle.chalk
    let glyphRoom: GlyphKind.Room? = .deck
    var accent: Color {
        Theme.Colors.Accent.training
    }

    var stop: TrainingStop?
    var libraryOpen = false
    var statsOpen = false
    var logOpen = false
    @ObservationIgnored private var facts: DeckRoomContent.Facts?
    @ObservationIgnored private weak var model: AppModel?

    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent {
        self.model = model
        let facts = DeckRoomContent.Facts.load(model: model, scheme: scheme)
        self.facts = facts
        return DeckRoomContent(facts: facts)
    }

    private var actions: DeckActions? {
        guard let model else { return nil }
        return DeckActions(model: model, reduceMotion: false) { [weak self] place in
            switch place {
            case .page: self?.stop = .page
            case let .route(route): self?.stop = .route(route)
            case .library: self?.libraryOpen = true
            case .stats: self?.statsOpen = true
            case .log: self?.logOpen = true
            }
        }
    }

    func scene(_ key: String) -> AnyView? {
        guard key == DeckRoomContent.boardKey, let facts, let actions else { return nil }
        return AnyView(TrainingBlackboard(board: facts.deck.board, openToday: { actions.goTo(.page) },
                                          openLift: { actions.goTo(.route(.classDef($0))) }))
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        switch intent {
        case .done, .notNow:
            break
        case .back: return false
        case let .openDoor(id): navigator.push(.door(room, id))
        case let .openItem(id): actions?.item(id)
        case let .action(id): actions?.step(id)
        }
        return true
    }

    func overlay(navigator _: ShellNavigator) -> AnyView {
        AnyView(ChalkDustHandOver())
    }

    func presenter() -> AnyView {
        AnyView(DeckPresenter(driver: self))
    }
}

private struct DeckPresenter: View {
    @Bindable var driver: DeckRoomDriver

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .sheet(item: $driver.stop) { stop in
                NavigationStack {
                    switch stop {
                    case .page:
                        ScrollView { TrainingPage().padding(.horizontal, Theme.Spacing.gutter) }
                            .scrollIndicators(.hidden)
                            .background { ThemedBackground() }
                    case let .route(route):
                        ObjectPage(route: route)
                    }
                }
            }
            .fullScreenCover(isPresented: $driver.libraryOpen) { LibraryPage(close: { driver.libraryOpen = false }) }
            .fullScreenCover(isPresented: $driver.statsOpen) {
                TrainingStatsPage(close: { driver.statsOpen = false })
            }
            .fullScreenCover(isPresented: $driver.logOpen) { TrainingLogPage(close: { driver.logOpen = false }) }
    }
}

// MARK: - Galley

@MainActor
@Observable
final class GalleyRoomDriver: ShellRoomDriver {
    let room = GalleyRoomContent.room
    let tessRoom: AppID? = .kitchen
    let flip = KeystoneFlip.columns
    let summaryStyle = DoorSummaryStyle.ticket
    let glyphRoom: GlyphKind.Room? = .galley
    var accent: Color {
        LandingAccent.kitchen
    }

    var link: HomeLink?
    var recipe: KitchenCookCover?
    var cookCover: KitchenCookCover?
    var shopping = false
    /// The Dishes ticket's count while it is on the rail (sheet 388); nil once it has come off. Until Core has the
    /// Dishes model this is only shown by the `-washDishes` simulator flag.
    var dishes: Int?
    var dishesReturned = false
    @ObservationIgnored private var facts: GalleyRoomContent.Facts?
    @ObservationIgnored private var front: KitchenFront?
    @ObservationIgnored private weak var model: AppModel?

    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent {
        self.model = model
        let front = KitchenFront(model: model, now: AppClock.now)
        let facts = GalleyRoomContent.Facts.load(model: model, scheme: scheme, front: front)
        self.front = front
        self.facts = facts
        return GalleyRoomContent(facts: facts)
    }

    func scene(_ key: String) -> AnyView? {
        guard key == GalleyRoomContent.sceneKey, let facts else { return nil }
        return AnyView(GalleyRail(tickets: tickets(facts)) { [weak self] in self?.go($0) })
    }

    /// The rail's tickets, with the Dishes ticket first while there are dishes (sheet 388).
    private func tickets(_ facts: GalleyRoomContent.Facts) -> [GalleyTicket] {
        guard let dishes else { return facts.pass.tickets }
        let ticket = GalleyTicket(id: "dishes", title: "Dishes", sub: nil,
                                  lines: dishes == 0 ? ["all put away"] : [], big: false, ink: .dishes, opens: .recipes,
                                  count: dishes, returned: dishesReturned)
        return [ticket] + facts.pass.tickets
    }

    func entered(navigator _: ShellNavigator) {
        #if DEBUG
            // Simulator only (LaunchFlags): `-washDishes` hangs a Dishes ticket with 7 waiting and washes it after 4 s.
            guard LaunchFlags.has("-washDishes"), dishes == nil else { return }
            dishes = 7
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                await wash()
            }
        #endif
    }

    /// Wash: the count steps down about a dish a beat (80 ms), then half a second later the ticket comes off with
    /// "Dishes, done" and an Undo that hangs it back at 7 waiting. Under Reduce Motion it is simply gone (sheet 388).
    func wash() async {
        guard let waiting = dishes, waiting > 0 else {
            TessVoice.shared.say("The sink is clear")
            return
        }
        let reduce = UIAccessibility.isReduceMotionEnabled
        dishesReturned = false
        if !reduce {
            for left in stride(from: waiting - 1, through: 0, by: -1) {
                withAnimation(.easeOut(duration: 0.08)) { dishes = left }
                try? await Task.sleep(for: .milliseconds(80))
            }
            try? await Task.sleep(for: .milliseconds(500))
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduce) { dishes = nil }
        TessVoice.shared.say("Dishes, done", holds: .seconds(10), takeBack: { [weak self] in
            self?.dishesReturned = true
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduce) { self?.dishes = waiting }
        })
    }

    func overlay(navigator _: ShellNavigator) -> AnyView {
        guard let facts else { return AnyView(EmptyView()) }
        return AnyView(KeystoneHandover(kind: .galleyTicket,
                                        from: KitchenLandingPage.firstTicketCentre(facts.pass.tickets)))
    }

    private func go(_ opens: GalleyTicket.Opens) {
        switch opens {
        case let .recipe(id): recipe = .init(id: id)
        case .recipes: link = .recipes
        case .groceries: link = .groceries
        case .pantry: link = .pantry
        }
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        switch intent {
        case .done, .notNow:
            break
        case .back:
            return false
        case let .openDoor(id):
            navigator.push(.door(room, id))
        case let .openItem(id):
            item(id)
        case let .action(id):
            if id == "get" {
                if Tier1b.shopModeIsOn {
                    shopping = true
                } else {
                    link = .groceries
                }
            } else if let meal = front?.tonight {
                cook(meal)
            } else {
                link = .recipes
            }
        }
        return true
    }

    private func item(_ id: String) {
        switch id {
        case "cooking": cookCover = front?.cooking.map { KitchenCookCover(id: $0.id) }
        case "dinner": go(front?.tonight?.recipe.map { GalleyTicket.Opens.recipe($0) } ?? .recipes)
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
    }

    /// Cook: tonight's recipe starts at its size and its clock opens (the same as Cook on the landing).
    private func cook(_ meal: KitchenFront.Meal) {
        guard let model, let id = meal.recipe else {
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

    func presenter() -> AnyView {
        AnyView(GalleyPresenter(driver: self))
    }
}

private struct GalleyPresenter: View {
    @Bindable var driver: GalleyRoomDriver

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .fullScreenCover(isPresented: $driver.shopping) { GalleyShopModePage() }
            .fullScreenCover(item: $driver.link) { $0.destination }
            .fullScreenCover(item: $driver.recipe) { RecipeView(recipeID: $0.id) }
            .fullScreenCover(item: $driver.cookCover) { CookEntry(cookID: $0.id) }
    }
}

// MARK: - Watch

@MainActor
@Observable
final class WatchRoomDriver: ShellRoomDriver {
    let room = WatchRoomContent.room
    let tessRoom: AppID? = .routines
    let flip = KeystoneFlip.groundUp
    let summaryStyle = DoorSummaryStyle.grow
    let glyphRoom: GlyphKind.Room? = .watch
    var accent: Color {
        WatchRoomContent.accent
    }

    struct Opened: Identifiable {
        let id: UUID
    }

    var selected: UUID?
    var waterRequest: WoodlandWaterRequest?
    var opened: Opened?
    var planting = false
    var draft = ""
    @ObservationIgnored var handOver = WatchHandOver.Moment(kind: .bird, at: Date())
    @ObservationIgnored private var facts: WatchRoomContent.Facts?
    @ObservationIgnored private weak var model: AppModel?
    @ObservationIgnored private var lastWidget = 0

    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent {
        self.model = model
        let facts = WatchRoomContent.Facts.load(model: model, scheme: scheme, selected: selected)
        self.facts = facts
        return WatchRoomContent(facts: facts)
    }

    func scene(_ key: String) -> AnyView? {
        guard key.hasPrefix("watch."), let facts else { return nil }
        return AnyView(RoutinesWoodlandScene(trees: facts.trees, selected: selected, hour: WatchActions.hour(facts.now),
                                             tap: { [weak self] id in self?.tapTree(id) },
                                             water: { id in
                                                 WatchActions.watered(facts.trees.first { $0.id == id }?.name ?? "It")
                                             }, waterRequest: waterRequest)
                .frame(width: LandingKeystone<EmptyView>.size.width, height: LandingKeystone<EmptyView>.size.height))
    }

    private func tapTree(_ id: UUID) {
        if selected == id {
            opened = Opened(id: id)
        } else {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: false) { selected = id }
        }
    }

    func entered(navigator: ShellNavigator) {
        navigator.state.switcherIndex = WatchTime.current(AppClock.now).rawValue
        handOver = .init(kind: .bird, at: Date())
    }

    func overlay(navigator: ShellNavigator) -> AnyView {
        let widget = navigator.state.widgetIndex
        if widget != lastWidget {
            lastWidget = widget
            handOver = .init(kind: widget == 0 ? .bird : .petals, at: Date())
        }
        return AnyView(WatchHandOver(moment: handOver))
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        switch intent {
        case let .done(id):
            // Swipe right starts it: its page opens.
            if let uuid = UUID(uuidString: id) {
                opened = Opened(id: uuid)
            }
        case let .notNow(id):
            // Sheet 355: "not now" hides it for today and carries a 10 s Undo that brings it back where it was.
            let name = facts?.trees.first { $0.id.uuidString == id }?.name ?? "It"
            if let uuid = UUID(uuidString: id) {
                let today = TesseraDay().today(AppClock.now)
                RoutinesNotNow.set(uuid, on: today, hidden: true)
                model?.touch()
                TessVoice.shared.say("\(name) can wait", holds: .seconds(10), takeBack: { [weak self] in
                    RoutinesNotNow.set(uuid, on: today, hidden: false)
                    self?.model?.touch()
                })
            } else {
                TessVoice.shared.say("\(name) can wait")
            }
        case .back:
            return false
        case let .openDoor(id):
            navigator.push(.door(room, id))
        case let .openItem(id):
            if let uuid = UUID(uuidString: id) {
                opened = Opened(id: uuid)
            } else {
                navigator.push(.door(room, "today"))
            }
        case .action("water"):
            if let target = facts?.waterTarget {
                waterRequest = WoodlandWaterRequest(id: target.id, at: Date())
                WatchActions.watered(target.name)
            }
        case .action("pause"):
            if let model {
                WatchActions.togglePause(model: model)
            }
        case .action:
            draft = ""
            planting = true
        }
        return true
    }

    func plant() {
        guard let model else { return }
        if let id = WatchActions.plant(draft, model: model) {
            opened = Opened(id: id)
        }
        draft = ""
    }

    func presenter() -> AnyView {
        AnyView(WatchPresenter(driver: self))
    }
}

private struct WatchPresenter: View {
    @Bindable var driver: WatchRoomDriver

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .sheet(item: $driver.opened) { item in
                NavigationStack { ObjectPage(route: .object(item.id)) }
            }
            .alert("Plant a routine", isPresented: $driver.planting) {
                TextField("Name", text: $driver.draft)
                Button("Plant") { driver.plant() }
                Button("Cancel", role: .cancel) {}
            }
    }
}

// MARK: - Purse

@MainActor
@Observable
final class PurseRoomDriver: ShellRoomDriver {
    let room = PurseRoomContent.room
    let tessRoom: AppID? = .money
    let flip = KeystoneFlip.leftToRight
    let summaryStyle = DoorSummaryStyle.meter
    let glyphRoom: GlyphKind.Room? = .purse
    var accent: Color {
        LandingAccent.money
    }

    var adding = false
    var draft = ""
    @ObservationIgnored private var facts: PurseRoomContent.Facts?
    @ObservationIgnored private weak var model: AppModel?
    @ObservationIgnored private weak var navigator: ShellNavigator?

    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent {
        self.model = model
        let facts = PurseRoomContent.Facts.load(model: model, scheme: scheme)
        self.facts = facts
        return PurseRoomContent(facts: facts)
    }

    func scene(_ key: String) -> AnyView? {
        guard key == PurseRoomContent.sceneKey, let facts, let navigator else { return nil }
        return AnyView(PurseIndexView(categories: facts.categories, category: navigator.binding(\.dialFocus),
                                      index: navigator.binding(\.keystonePage)))
    }

    func entered(navigator: ShellNavigator) {
        self.navigator = navigator
    }

    func overlay(navigator: ShellNavigator) -> AnyView {
        self.navigator = navigator
        return AnyView(KeystoneHandover(kind: .purseDot, from: MoneyLandingView.lineEnd()))
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        switch intent {
        case .done, .notNow:
            break
        case .back:
            return false
        case let .openDoor(id):
            navigator.push(.door(room, id))
        case .openItem:
            break
        case let .action(id):
            switch id {
            case "look":
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: false) {
                    navigator.state.dialFocus = 0
                    navigator.state.keystonePage = 0
                    navigator.state.switcherIndex = 0
                }
            case "plan":
                TessVoice.shared.say("Plans for the month come with Bills.")
            default:
                draft = ""
                adding = true
            }
        }
        return true
    }

    func log(reduceMotion: Bool) {
        guard let model else { return }
        MoneyLandingView.logSpend(draft, model: model, reduceMotion: reduceMotion)
    }

    func presenter() -> AnyView {
        AnyView(PursePresenter(driver: self))
    }
}

private struct PursePresenter: View {
    @Bindable var driver: PurseRoomDriver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .alert("Log a spend", isPresented: $driver.adding) {
                TextField("12.40 lunch", text: $driver.draft)
                    .keyboardType(.numbersAndPunctuation)
                Button("Log") { driver.log(reduceMotion: reduceMotion) }
                Button("Cancel", role: .cancel) {}
            }
    }
}

// MARK: - Settings

@MainActor
@Observable
final class SettingsRoomDriver: ShellRoomDriver {
    let room = SettingsRoomContent.room
    let tessRoom: AppID? = nil
    let flip = KeystoneFlip.rows
    let glyphRoom: GlyphKind.Room? = .log
    var accent: Color {
        Theme.Colors.ink
    }

    var area: SettingsArea?
    var backupLine: String?
    /// The phone's own model under Sample data (the host passes its `realModel`).
    @ObservationIgnored weak var realModel: AppModel?
    var opened = 0
    @ObservationIgnored private var askedBackups = false

    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent {
        if !askedBackups {
            askedBackups = true
            Task { @MainActor in
                // Read once, from the copies' own files; nothing is written.
                self.backupLine = BackupKeeper.lastLine(copies: BackupKeeper.localCopies(), now: AppClock.now)
            }
        }
        _ = opened
        return SettingsRoomContent(facts: .load(model: model, scheme: scheme, realModel: realModel,
                                                backupLine: backupLine))
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        switch intent {
        case .done, .notNow:
            break
        case .back:
            return false
        case let .openDoor(id):
            navigator.push(.door(room, id))
        case let .openItem(id):
            guard let next = SettingsRoomContent.area(for: id) else { return true }
            SettingsAreaSeen.mark(next, at: AppClock.now)
            opened += 1
            area = next
        case .action:
            break
        }
        return true
    }

    func presenter() -> AnyView {
        AnyView(SettingsPresenter(driver: self))
    }
}

private struct SettingsPresenter: View {
    @Bindable var driver: SettingsRoomDriver

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .sheet(item: $driver.area) { area in
                NavigationStack { area.destination }
            }
    }
}

// MARK: - Lookout

@MainActor
@Observable
final class LookoutRoomDriver: ShellRoomDriver {
    let room = LookoutRoomContent.room
    let tessRoom: AppID? = nil
    let flip = KeystoneFlip.cloud
    let summaryStyle = DoorSummaryStyle.fog
    let glyphRoom: GlyphKind.Room? = .lookout
    var accent: Color {
        WeatherAccent.room
    }

    var alertOn = WeatherRainAlert.isOn()
    @ObservationIgnored private var facts: LookoutRoomContent.Facts?
    @ObservationIgnored private var plate: LookoutPlate?
    @ObservationIgnored private weak var navigator: ShellNavigator?

    func content(model _: AppModel, scheme: ColorScheme) -> any RoomContent {
        let facts = LookoutRoomContent.Facts(
            snapshot: WeatherSample.snapshot(now: LookoutShellHost.minute(AppClock.now)),
            alertOn: alertOn
        )
        self.facts = facts
        plate = LookoutPlate.pick(kind: facts.snapshot.kind, at: facts.snapshot.now, dark: scheme == .dark)
        return LookoutRoomContent(facts: facts)
    }

    func scene(_ key: String) -> AnyView? {
        guard key.hasPrefix("lookout."), let facts else { return nil }
        return AnyView(LookoutSkypiece(snapshot: facts.snapshot) { [weak self] in
            guard let self else { return }
            navigator?.push(.door(room, "hours"))
        })
    }

    var backdrop: AnyView? {
        guard let facts, let plate else { return nil }
        return AnyView(LookoutPlateView(plate: plate, fallback: AnyView(
            LookoutSkyView(kind: facts.snapshot.kind, now: facts.snapshot.now)
        )))
    }

    /// The text colour comes from the plate (256), so the page wears the plate's scheme.
    var scheme: ColorScheme? {
        plate.map { $0.lightInk ? .dark : .light }
    }

    func entered(navigator: ShellNavigator) {
        self.navigator = navigator
    }

    func overlay(navigator: ShellNavigator) -> AnyView {
        self.navigator = navigator
        return AnyView(LookoutDropHandover())
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        guard let facts else { return false }
        switch intent {
        case .done, .notNow:
            break
        case .back:
            return false
        case let .openDoor(id):
            navigator.push(.door(room, id))
        case let .openItem(id):
            // A widget card opens its door; a page row has nothing deeper yet.
            if navigator.route.level == 0 {
                navigator.push(.door(room, facts.door(forItem: id).rawValue))
            }
        case .action("hours"):
            navigator.push(.door(room, "hours"))
        case .action("walk"):
            LookoutActions.walk(facts.snapshot)
        case .action:
            LookoutActions.toggleAlert { [weak self] in self?.alertOn = $0 }
        }
        return true
    }
}

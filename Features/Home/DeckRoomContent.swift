import SwiftUI
import TesseraCore

/// Deck (Training) as content for the standing shell (sheet 283 v5): level 0 is the landing, the same content as
/// `TrainingWallLanding` (both read `TrainingWallFacts` and `TrainingDeckFacts`, and the words and foot below);
/// level 1 is a door page: the Door title and a Page of that door's ranked rows (sheet 284); level 2 is an item page:
/// the Item title, Facts and a Body drawn by the item's kind (sets for a lift, siblings for the rest). The keystone is
/// the blackboard, drawn by
/// the host through `shellScene`; its id is the same at both levels, so opening a door never touches it. Private
/// routines read "Private workout" and never reach the board, the switcher or a page. Pure: no views, no store reads.
struct DeckRoomContent: RoomContent {
    static let room = "deck"
    static let title = "Deck"
    static let boardKey = "deck.board"
    static let boardLabel = "The board"
    static let caption = ["Tap a number to open the lift. Swipe left to wipe"]
    static let firstDoor = "today"

    struct Facts: Equatable {
        var wall: TrainingWallFacts
        var deck: TrainingDeckFacts
        /// The rows of each door's page, by door id (the pre-284 rows; the shell draws `pages`).
        var rows: [String: [ShellRow]] = [:]
        /// Sheet 284: each door's ranked page and each lift's item page.
        var pages = DeckPages()
    }

    let facts: Facts
    var accent: Color = Theme.Colors.Accent.training

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        switch route.level {
        case 0: landing(state)
        case 1: door(route.door ?? Self.firstDoor)
        default: item(door: route.door ?? Self.firstDoor, id: route.item ?? "")
        }
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let widget = facts.deck.widget
        let item = widget.indices.contains(state.widgetIndex) ? widget[state.widgetIndex] : widget.first
        let doors = facts.wall.doors
        let focused = doors.isEmpty ? nil : doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
        let needs = facts.deck.needs.indices.contains(state.switcherIndex) ? facts.deck.needs[state.switcherIndex] : []
        return Screen(layout: .landing, slots: [
            .title: title,
            .navWord: SlotContent(id: "deck.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "deck.switcher", kind: .switcher,
                                   payload: .switcher(across: TrainingDeckFacts.across,
                                                      vertical: facts.deck.routineWords)),
            .needs: needs.isEmpty ? nil
                : SlotContent(id: ContentID("deck.needs.\(state.switcherIndex)"), kind: .text, payload: .lines(needs)),
            .keystone: keystone,
            .caption: caption,
            .widget: widget.isEmpty ? nil : SlotContent(id: "deck.widget", kind: .widget, payload: .widget(widget)),
            .glyph: item.map { SlotContent(id: ContentID("deck.glyph.\($0.id)"), kind: .glyph,
                                           payload: .glyph(Self.glyphWords($0), color: accent)) },
            .dial: doors.isEmpty ? nil : SlotContent(id: "deck.dial", kind: .dial, payload: .dial(doors)),
            .doorSummary: focused.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : SlotContent(id: ContentID("deck.summary.\(door.id)"), kind: .summary, payload: .summary(door))
            },
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Level 1

    private func door(_ id: String) -> Screen {
        let doors = facts.wall.doors
        let door = doors.first { $0.id == id }
        let page = facts.pages.doors[id]
        let rows = page?.rows ?? []
        let line = page?.line ?? door?.label ?? door?.lines.first ?? (rows.isEmpty ? "Nothing here yet" : "")
        let place = doors.firstIndex { $0.id == id }
        let previous = place.flatMap { doors.count > 1 ? ($0 + doors.count - 1) % doors.count : nil }
        let next = place.flatMap { doors.count > 1 ? ($0 + 1) % doors.count : nil }
        let title = PageTitle(
            name: door?.name ?? "Today", line: line,
            previous: previous.map { .door(Self.room, doors[$0].id) },
            next: next.map { .door(Self.room, doors[$0].id) },
            previousFocus: previous, nextFocus: next
        )
        return Screen(layout: .door, slots: [
            .title: self.title,
            .navWord: SlotContent(id: "deck.nav.doors", kind: .text, payload: .navWord("Doors")),
            .doorTitle: SlotContent(id: ContentID("deck.door.\(id).title"), kind: .text, payload: .pageTitle(title)),
            .keystone: keystone,
            .caption: doorCaption(id),
            .page: SlotContent(id: ContentID("deck.door.\(id).page"), kind: .rows,
                               payload: .ranked(RankedPageData(rows: rows, accent: accent,
                                                               moreID: DeckPages.moreID(id)))),
            .actionWord: doorFoot(door?.name ?? "Today"),
            .tess: nil,
        ])
    }

    // MARK: Level 2

    private func item(door id: String, id itemID: String) -> Screen {
        let doors = facts.wall.doors
        let door = doors.first { $0.id == id }
        let rows = facts.pages.doors[id]?.rows ?? []
        let place = rows.firstIndex { $0.id == itemID }
        let row = place.map { rows[$0] }
        let previous = place.flatMap { rows.count > 1 ? ($0 + rows.count - 1) % rows.count : nil }
        let next = place.flatMap { rows.count > 1 ? ($0 + 1) % rows.count : nil }
        var name = row?.title ?? "Nothing here"
        var line = row?.sub ?? ""
        var shownFacts: [ItemFact] = []
        var start: String?
        var body = ItemBody.siblings(SiblingsBody.make(rows: rows, current: itemID))
        if let row, !row.isPrivate, let lift = facts.pages.items[DeckPages.itemKey(itemID)] {
            name = lift.title
            line = lift.line
            shownFacts = lift.facts
            body = .sets(lift.sets)
            start = lift.start.isEmpty ? nil : lift.start
        } else if let row, !row.isPrivate, let place {
            shownFacts = Self.plainFacts(row, index: place, count: rows.count, door: door?.name ?? "", doorID: id)
        }
        let title = PageTitle(
            name: name, line: line,
            previous: previous.map { .item(Self.room, id, rows[$0].id) },
            next: next.map { .item(Self.room, id, rows[$0].id) }, isItem: true
        )
        return Screen(layout: .door, slots: [
            .title: self.title,
            .navWord: SlotContent(id: ContentID("deck.nav.door.\(id)"), kind: .text,
                                  payload: .navWord(door?.name ?? "Today")),
            .doorTitle: SlotContent(id: ContentID("deck.item.\(id).\(itemID).title"), kind: .text,
                                    payload: .pageTitle(title)),
            .keystone: keystone,
            .caption: doorCaption(id),
            .page: SlotContent(id: ContentID("deck.item.\(id).\(itemID).page"), kind: .rows,
                               payload: .item(ItemPageData(facts: shownFacts, body: body, accent: accent))),
            .actionWord: itemFoot(name: name, start: start, isPrivate: row?.isPrivate ?? false),
            .tess: nil,
        ])
    }

    /// Each door's own keystone hint (sheet 284): the caption eases to the new door's words when the Door title turns.
    static let doorCaptions = [
        "today": "The board keeps what you chalk on it",
        "week": "Swipe fast left on the board to wipe it",
        "library": "Hold a name on the board to see it",
        "bests": "Bests are written in gold",
        "plan": "Drag on the board to write",
    ]

    private func doorCaption(_ door: String) -> SlotContent {
        let text = Self.doorCaptions[door] ?? Self.caption[0]
        return SlotContent(id: ContentID("deck.caption.\(door)"), kind: .text, payload: .lines([text]))
    }

    /// The foot at level 1: Add to the door, Ask Tess about it. The id is the same for every door, so the verb stays
    /// put and only the object eases over as the door turns.
    private func doorFoot(_ name: String) -> SlotContent {
        SlotContent(id: "deck.action.door", kind: .action, payload: .action([
            ShellStep(id: "add", verb: "Add", object: "to \(name)"),
            ShellStep(id: "ask", verb: "Ask", object: "Tess about \(name)"),
        ], accent: accent))
    }

    /// The foot at level 2: a lift starts its first set (hold) or swaps; any other row opens or asks. A private item
    /// only asks. Two lifts share one id, so only the object eases; lift to row changes the verbs.
    private func itemFoot(name: String, start: String?, isPrivate: Bool) -> SlotContent {
        if let start {
            return SlotContent(id: "deck.action.lift", kind: .action, payload: .action([
                ShellStep(id: "start", verb: "Start", object: start, hold: true),
                ShellStep(id: "swap", verb: "Swap", object: "for dumbbells"),
            ], accent: accent))
        }
        var steps = isPrivate ? [] : [ShellStep(id: "open", verb: "Open", object: name)]
        steps.append(ShellStep(id: "ask", verb: "Ask", object: "Tess about \(isPrivate ? "this" : name)"))
        return SlotContent(id: "deck.action.row", kind: .action, payload: .action(steps, accent: accent))
    }

    /// The facts of a row with no page of its own yet: its value, where it ranks in the door.
    static func plainFacts(_ row: RankedRow, index: Int, count: Int, door: String, doorID: String) -> [ItemFact] {
        var facts: [ItemFact] = []
        if !row.value.isEmpty {
            let label = ["today": "Opens at", "library": "Best", "bests": "Best", "plan": "Takes"][doorID] ?? "Value"
            facts.append(ItemFact(number: row.value, unit: row.unit, label: label, about: doorID == "plan"))
        }
        facts.append(ItemFact(number: "\(index + 1)", unit: "of \(count)", label: door))
        return facts
    }

    // MARK: Shared by both levels (same ids: the keystone, title, caption and action are not touched)

    private var title: SlotContent {
        SlotContent(id: "deck.title", kind: .text, payload: .title(Self.title, accent: accent))
    }

    private var keystone: SlotContent {
        SlotContent(id: "deck.keystone", kind: .scene, payload: .scene(Self.boardKey, label: Self.boardLabel))
    }

    private var caption: SlotContent {
        SlotContent(id: "deck.caption", kind: .text, payload: .lines(Self.caption))
    }

    private var action: SlotContent? {
        let steps = facts.wall.footSteps
        return steps.isEmpty ? nil
            : SlotContent(id: "deck.action", kind: .action, payload: .action(steps, accent: accent))
    }

    /// Deck's glyph is the board's ticks (283): the library picks by words, and "Tonight" or a routine like
    /// "Lower body" would draw a moon, so today's item is picked as the week's sessions. Yesterday keeps its words.
    static func glyphWords(_ item: WidgetItem) -> WidgetItem {
        guard item.id == "today" || item.id == "week" else { return item }
        return WidgetItem(id: item.id, header: "This week", big: "", middle: "")
    }
}

// MARK: - The foot, as data (one source for the scaffold and the shell)

extension TrainingWallFacts {
    /// The foot's steps: the first runs on tap (a start needs the 500 ms hold), the rest are reached by swiping
    /// across. Ready: Start, Log, Rest. Running: Pick up, Log. Rest day: Log a walk, Start the next routine, Log.
    /// Nothing planned: Pick a routine. Done: none.
    var footSteps: [ShellStep] {
        guard let foot = action else { return [] }
        let log = ShellStep(id: "log", verb: "Log", object: "This week")
        switch day {
        case .ready:
            return [ShellStep(id: "start", verb: foot.verb, object: foot.object, hold: true), log,
                    ShellStep(id: "rest", verb: "Rest", object: "Today")]
        case .running:
            return [ShellStep(id: "pickUp", verb: foot.verb, object: foot.object), log]
        case .rest:
            var steps = [ShellStep(id: "walk", verb: foot.verb, object: foot.object)]
            if let next = restOption {
                steps.append(ShellStep(id: "startNext", verb: "Start", object: next, hold: true))
            }
            steps.append(log)
            return steps
        case .nothing:
            return [ShellStep(id: "library", verb: foot.verb, object: foot.object)]
        case .done:
            return []
        }
    }

    /// VoiceOver's hint for the foot's first step.
    static func footHint(_ id: String) -> String {
        switch id {
        case "start": "Hold to start the workout"
        case "pickUp": "Opens the workout"
        case "walk": "Logs a walk"
        case "library": "Opens the library"
        default: ""
        }
    }
}

/// What Deck's taps do, for the scaffold and the shell alike: doors, wall and page rows, widget items and the foot's
/// steps. `goTo` is how the caller shows a page (a push, a cover).
@MainActor
struct DeckActions {
    let model: AppModel
    var reduceMotion = false
    /// Called once a step has started or picked up the workout (the model has set `isWorkoutPresented`). The shell
    /// host passes the environment's `shellOpenWorkout`, so whoever owns the root cover can raise the live workout
    /// over the shell; nil (the scaffold) leaves it to the app root, as before.
    var openWorkout: (@MainActor () -> Void)?
    let goTo: (TrainingGo) -> Void

    private var logOrPage: TrainingGo {
        LogSwitch.isOn ? .log : .page
    }

    /// A door's own page outside the shell (the scaffold opens these straight from the dial).
    func door(_ id: String) {
        switch id {
        case "today": goTo(.page)
        case "week": goTo(logOrPage)
        case "library": goTo(.library)
        case "plan":
            if let plan = model.plan {
                goTo(.route(.routines(plan.id)))
            } else if let planClass = model.classDef(.plan) {
                goTo(.route(.classDef(planClass.id)))
            }
        default: goTo(.stats)
        }
    }

    /// A widget item, a wall word or a page row.
    func item(_ id: String) {
        switch TrainingWallTarget(id: id) {
        case let .exercise(uuid): goTo(.route(.classDef(uuid)))
        case let .routine(uuid): goTo(.route(.object(uuid)))
        case nil:
            if id == "today" || id.hasPrefix("page") {
                goTo(.page)
            } else if id.hasPrefix("best:"), let uuid = UUID(uuidString: String(id.dropFirst(5))) {
                goTo(.route(.classDef(uuid)))
            } else {
                goTo(logOrPage)
            }
        }
    }

    /// The foot's steps that bring up the live workout.
    static func opensWorkout(_ id: String) -> Bool {
        ["start", "pickUp", "startNext"].contains(id)
    }

    /// One of the foot's steps, by id.
    func step(_ id: String) {
        defer {
            if Self.opensWorkout(id), model.isWorkoutPresented {
                openWorkout?()
            }
        }
        switch id {
        case "start": start()
        case "pickUp": model.isWorkoutPresented = true
        case "log": goTo(logOrPage)
        case "rest":
            // Nothing is written: the plan keeps its day; Tess only says so.
            TessVoice.shared.say("Rest it is. Nothing logged, the plan keeps its day")
        case "walk": TessVoice.shared.say("Walks come in from Health")
        case "startNext": startNext()
        case "library": goTo(.library)
        default: break
        }
    }

    /// The same start the Training page does: running picks up, tonight's workout starts, else the routine.
    private func start() {
        model.workoutRisesFromLane = false
        if model.session != nil {
            model.isWorkoutPresented = true
        } else if let workout = model.tonightWorkout() {
            model.startWorkout(workout)
        } else if let routine = model.triedRoutine() ?? model.todaysRoutine() {
            model.startRoutine(routine)
        }
    }

    /// A rest day's other step: the next routine anyway.
    private func startNext() {
        guard let plan = model.plan, let next = model.ledger.nextRoutine(in: plan, now: AppClock.now) else { return }
        model.workoutRisesFromLane = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.startRoutine(next) }
    }

    /// The scaffold's foot from the same steps.
    func footAction(_ facts: TrainingWallFacts) -> LandingFootAction? {
        let steps = facts.footSteps
        guard let first = steps.first else { return nil }
        let alternates = steps.dropFirst().map { next in
            LandingFootAction.Step(verb: next.verb, object: next.object, hold: next.hold) { step(next.id) }
        }
        return LandingFootAction(word: first.verb, object: first.object, hold: first.hold,
                                 hint: TrainingWallFacts.footHint(first.id), alternates: Array(alternates))
        {
            step(first.id)
        }
    }
}

extension DeckRoomContent.Facts {
    /// Deck's facts from the store: the same reads as the scaffold landing, plus each door's rows.
    @MainActor
    static func load(model: AppModel, scheme: ColorScheme) -> Self {
        let wall = TrainingWallFacts.load(model, dark: scheme == .dark)
        let deck = TrainingDeckFacts.load(model, wall: wall, dark: scheme == .dark)
        return Self(wall: wall, deck: deck, rows: rows(wall: wall, deck: deck),
                    pages: DeckPages.load(model: model, wall: wall))
    }

    /// Each door's page: Today's lifts, the week's days, the library's lifts, the bests and the plan's routines.
    /// The wall already holds no private routine, so no row can carry one's name.
    static func rows(wall: TrainingWallFacts, deck: TrainingDeckFacts) -> [String: [ShellRow]] {
        var rows: [String: [ShellRow]] = [:]
        let today = wall.doors.first { $0.id == "today" }
        // A Today row opens its own lift where the line names one; else the Training page.
        rows["today"] = (today?.lines ?? []).enumerated().map { index, line in
            let lift = wall.todayLiftIDs.indices.contains(index) ? wall.todayLiftIDs[index] : nil
            return ShellRow(id: lift.map { "\(TrainingWallTarget.exercise($0).id)#t\(index)" } ?? "page#\(index)",
                            title: line)
        }
        // A trained day opens the first lift it did; other days open the week (the log).
        rows["week"] = deck.board.week.map { day in
            let detail = day.isToday ? "Today" : (day.done ? (day.liftName.map { "Trained, \($0)" } ?? "Trained") : "")
            return ShellRow(
                id: day.liftID.map { "\(TrainingWallTarget.exercise($0).id)#w\(day.id)" } ?? "week#\(day.id)",
                title: day.letter,
                detail: detail
            )
        }
        rows["library"] = wall.words.filter {
            if case .exercise = TrainingWallTarget(id: $0.id) {
                return true
            }
            return false
        }.map { ShellRow(id: $0.id, title: $0.text) }
        rows["bests"] = deck.board.bests.map { best in
            ShellRow(id: "best:\(best.id.uuidString)", title: best.lift, detail: best.number)
        }
        rows["plan"] = wall.words.filter {
            if case .routine = TrainingWallTarget(id: $0.id) {
                return true
            }
            return false
        }.map { ShellRow(id: $0.id, title: $0.text) }
        return rows
    }
}

/// Deck opened through the standing shell (`-shellRoom deck` on the simulator, and Home through `ShellRooms`). Taps
/// come back as intents: a door pushes its page, a word, row or item opens its thing, the foot runs Deck's steps, and
/// back pops (restoring every place). The blackboard is the keystone drawing; the chalk dust hands the widget over.
struct DeckShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.shellOpenWorkout) private var openWorkout
    @State private var navigator = ShellNavigator(root: .landing(DeckRoomContent.room))
    @State private var stop: TrainingStop?
    @State private var libraryOpen = false
    @State private var statsOpen = false
    @State private var logOpen = false

    var body: some View {
        let _ = model.revision
        let facts = DeckRoomContent.Facts.load(model: model, scheme: scheme)
        let actions = actions
        ShellView(room: DeckRoomContent(facts: facts), navigator: navigator,
                  accent: Theme.Colors.Accent.training, act: handle)
            .environment(\.shellScene) { key in
                guard key == DeckRoomContent.boardKey else { return AnyView(EmptyView()) }
                return AnyView(TrainingBlackboard(board: facts.deck.board, openToday: { actions.goTo(.page) },
                                                  openLift: { actions.goTo(.route(.classDef($0))) }))
            }
            .environment(\.doorSummaryStyle, .chalk)
            .environment(\.shellGlyphRoom, .deck)
            .overlay { ChalkDustHandOver() }
            .sheet(item: $stop) { stop in
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
            .fullScreenCover(isPresented: $libraryOpen) { LibraryPage(close: { libraryOpen = false }) }
            .fullScreenCover(isPresented: $statsOpen) { TrainingStatsPage(close: { statsOpen = false }) }
            .fullScreenCover(isPresented: $logOpen) { TrainingLogPage(close: { logOpen = false }) }
        #if DEBUG
            .task { await navigator.walkForStills(room: DeckRoomContent.room) }
        #endif
    }

    private var actions: DeckActions {
        DeckActions(model: model, reduceMotion: reduceMotion, openWorkout: openWorkout) { place in
            switch place {
            case .page: stop = .page
            case let .route(route): stop = .route(route)
            case .library: libraryOpen = true
            case .stats: statsOpen = true
            case .log: logOpen = true
            }
        }
    }

    private func handle(_ intent: ShellIntent) {
        switch intent {
        case .done, .notNow:
            break
        case .back:
            if navigator.route.level == 0 {
                dismiss()
            } else {
                navigator.pop()
            }
        case let .openDoor(id): navigator.push(.door(DeckRoomContent.room, id))
        case let .openItem(id): DeckRouting.open(id, navigator: navigator, actions: actions)
        case let .action(id): DeckRouting.step(id, navigator: navigator, actions: actions)
        }
    }
}

/// What a tap on a row does in the Deck (sheet 284): on the landing the old targets (a lift, a routine); on a door page
/// the row's item page; on an item page a sibling replaces it. "More" rows open the old library, stats or today page.
@MainActor
enum DeckRouting {
    /// The foot's steps at levels 1 and 2 (the landing's keep `DeckActions.step`). Ask has no page of its own yet:
    /// Tess says how to reach her.
    static func step(_ id: String, navigator: ShellNavigator, actions: DeckActions?) {
        let route = navigator.route
        switch id {
        case "add":
            switch route.door ?? DeckRoomContent.firstDoor {
            case "today", "week": actions?.step("log")
            case let door: actions?.door(door)
            }
        case "ask": TessVoice.shared.say("Hold me and ask. I will answer about what is on this page")
        case "swap": TessVoice.shared.say("Swapping a lift happens in the workout")
        case "open": actions?.item(route.item ?? "")
        default: actions?.step(id)
        }
    }

    static func open(_ id: String, navigator: ShellNavigator, actions: DeckActions?) {
        let route = navigator.route
        if route.level == 0 {
            actions?.item(id)
        } else if DeckPages.isMore(id) {
            actions?.door(String(id.dropFirst("more:".count)))
        } else if route.level == 1 {
            navigator.push(.item(route.room, route.door ?? DeckRoomContent.firstDoor, id))
        } else {
            navigator.replace(.item(route.room, route.door ?? DeckRoomContent.firstDoor, id))
        }
    }
}

extension TrainingStop: Identifiable {
    var id: String {
        switch self {
        case .page: "page"
        case let .route(route): "\(route)"
        }
    }
}

extension EnvironmentValues {
    /// For lane S's root (Home's shell): raise the live workout over the shell. Deck's shell host calls it after Start,
    /// Pick up or Start next has begun or resumed a workout (`AppModel.isWorkoutPresented` is already true). Nil by
    /// default: the app root's own cover on `isWorkoutPresented` shows it, as on the scaffold.
    @Entry var shellOpenWorkout: (@MainActor () -> Void)?
}

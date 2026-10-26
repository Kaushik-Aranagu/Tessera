import SwiftUI
import TesseraCore

/// Deck (Training) as content for the standing shell (sheet 283 v5): level 0 is the landing, the same content as
/// `TrainingWallLanding` (both read `TrainingWallFacts` and `TrainingDeckFacts`, and the words and foot below);
/// level 1 is a door page: the Door title and a Page of that door's rows. The keystone is the blackboard, drawn by
/// the host through `shellScene`; its id is the same at both levels, so opening a door never touches it. Private
/// routines read "Private workout" and never reach the board, the switcher or a page. Pure: no views, no store reads.
struct DeckRoomContent: RoomContent {
    static let room = "deck"
    static let title = "Deck"
    static let boardKey = "deck.board"
    static let boardLabel = "The board"
    static let caption = ["Tap a number to open the lift. Swipe left to wipe."]
    static let firstDoor = "today"

    struct Facts: Equatable {
        var wall: TrainingWallFacts
        var deck: TrainingDeckFacts
        /// The rows of each door's page, by door id.
        var rows: [String: [ShellRow]] = [:]
    }

    let facts: Facts
    var accent: Color = Theme.Colors.Accent.training

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(route.door ?? Self.firstDoor)
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
        let door = facts.wall.doors.first { $0.id == id }
        let rows = facts.rows[id] ?? []
        let line = door?.label ?? door?.lines.first ?? (rows.isEmpty ? "Nothing here yet." : "")
        return Screen(layout: .door, slots: [
            .title: title,
            .navWord: SlotContent(id: "deck.nav.deck", kind: .text, payload: .navWord(Self.title)),
            .doorTitle: SlotContent(id: ContentID("deck.door.\(id).title"), kind: .text,
                                    payload: .doorTitle(name: door?.name ?? "Today", line: line,
                                                        color: door?.color ?? accent)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("deck.door.\(id).page"), kind: .list, payload: .list(rows)),
            .actionWord: action,
            .tess: nil,
        ])
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

    /// One of the foot's steps, by id.
    func step(_ id: String) {
        switch id {
        case "start": start()
        case "pickUp": model.isWorkoutPresented = true
        case "log": goTo(logOrPage)
        case "rest":
            // Nothing is written: the plan keeps its day; Tess only says so.
            TessVoice.shared.say("Rest it is. Nothing logged, the plan keeps its day.")
        case "walk": TessVoice.shared.say("Walks come in from Health.")
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
        return Self(wall: wall, deck: deck, rows: rows(wall: wall, deck: deck))
    }

    /// Each door's page: Today's lifts, the week's days, the library's lifts, the bests and the plan's routines.
    /// The wall already holds no private routine, so no row can carry one's name.
    static func rows(wall: TrainingWallFacts, deck: TrainingDeckFacts) -> [String: [ShellRow]] {
        var rows: [String: [ShellRow]] = [:]
        let today = wall.doors.first { $0.id == "today" }
        rows["today"] = (today?.lines ?? []).enumerated().map { index, line in
            ShellRow(id: "page#\(index)", title: line)
        }
        rows["week"] = deck.board.week.map { day in
            ShellRow(id: "week#\(day.id)", title: day.letter,
                     detail: day.isToday ? "Today" : (day.done ? "Trained" : ""))
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
        DeckActions(model: model, reduceMotion: reduceMotion) { place in
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
        case let .openItem(id): actions.item(id)
        case let .action(id): actions.step(id)
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

import SwiftUI
import TesseraCore

/// The Training room while "Landing pages" is On: the landing in its own navigation, with the existing pages behind
/// its doors (the full Training page, Library, Log, Stats, the plan's routines and the Routines landing).
struct TrainingRoomView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [TrainingStop] = []
    @State private var libraryOpen = false
    @State private var statsOpen = false
    @State private var logOpen = false

    var body: some View {
        NavigationStack(path: $path) {
            TrainingWallLanding(goTo: open)
                .navigationDestination(for: TrainingStop.self) { stop in
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
        .environment(\.animateEntrance, true)
    }

    private func open(_ place: TrainingGo) {
        switch place {
        case .page: path.append(.page)
        case let .route(route): path.append(.route(route))
        case .library: libraryOpen = true
        case .stats: statsOpen = true
        case .log: logOpen = true
        }
    }
}

/// A page pushed from the landing.
enum TrainingStop: Hashable {
    case page
    case route(Route)
}

/// Where a door, a wall word or the title goes.
enum TrainingGo {
    case page
    case route(Route)
    case library
    case stats
    case log
}

/// Deck, the Training landing on the sheet 283 scaffold: the blackboard (258) in the keystone slot, the switcher
/// across Today, This week, This month (up and down through the plan's routines), the widget with today, the week
/// and yesterday, This week, Routines, Exercises, Programs and Goals on the dial, and "Start <routine>" at the foot
/// ("Log a walk" on a rest day).
struct TrainingWallLanding: View {
    let goTo: (TrainingGo) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @State private var switcherIndex = 0
    @State private var switcherVerticalIndex = 0
    @State private var widgetIndex = 0

    var body: some View {
        let _ = model.revision
        let facts = TrainingWallFacts.load(model, dark: scheme == .dark)
        let deck = TrainingDeckFacts.load(model, wall: facts, dark: scheme == .dark)
        LandingScaffold(title: "Deck", accent: Theme.Colors.Accent.training, navWord: "Bridge",
                        onBack: { dismiss() }, onTitle: { goTo(.page) },
                        switcher: TrainingDeckFacts.across, switcherVertical: deck.routineWords,
                        switcherIndex: $switcherIndex, switcherVerticalIndex: $switcherVerticalIndex,
                        needs: deck.needs.indices.contains(switcherIndex) ? deck.needs[switcherIndex] : [],
                        keystone: {
                            LandingKeystone(label: "The board") {
                                TrainingBlackboard(board: deck.board, openToday: { goTo(.page) },
                                                   openLift: { goTo(.route(.classDef($0))) })
                            }
                        },
                        caption: ["Tap a number to open the lift. Swipe left to wipe."],
                        widget: deck.widget, widgetIndex: $widgetIndex,
                        openWidget: openWidget,
                        glyph: { item in
                            LandingGlyph(item: Self.glyphWords(item), color: Theme.Colors.Accent.training, room: .deck)
                        },
                        doors: facts.doors, focus: $focus, openDoor: openDoor,
                        action: action(facts), summaryStyle: .chalk)
            .overlay { ChalkDustHandOver() }
            .toolbar(.hidden, for: .navigationBar)
    }

    private func openWidget(_ item: WidgetItem) {
        switch item.id {
        case "today": goTo(.page)
        default: goTo(LogSwitch.isOn ? .log : .page)
        }
    }

    // MARK: Taps

    private func openWord(_ id: String) {
        switch TrainingWallTarget(id: id) {
        case let .exercise(uuid): goTo(.route(.classDef(uuid)))
        case let .routine(uuid): goTo(.route(.object(uuid)))
        case nil: break
        }
    }

    private func spoken(_ word: WallWord) -> String {
        switch TrainingWallTarget(id: word.id) {
        case .routine: "\(word.text), routine"
        default: "\(word.text), exercise"
        }
    }

    private func openDoor(_ door: DialDoor) {
        switch door.id {
        case "today":
            goTo(.page)
        case "week":
            goTo(LogSwitch.isOn ? .log : .page)
        case "library":
            goTo(.library)
        case "plan":
            if let plan = model.plan {
                goTo(.route(.routines(plan.id)))
            } else if let planClass = model.classDef(.plan) {
                goTo(.route(.classDef(planClass.id)))
            }
        default:
            goTo(.stats)
        }
    }

    // MARK: Foot

    private func action(_ facts: TrainingWallFacts) -> LandingFootAction? {
        guard let foot = facts.action else { return nil }
        let log = LandingFootAction.Step(verb: "Log", object: "This week") { goTo(LogSwitch.isOn ? .log : .page) }
        let rest = LandingFootAction.Step(verb: "Rest", object: "Today") {
            // Nothing is written: the plan keeps its day; Tess only says so.
            TessVoice.shared.say("Rest it is. Nothing logged, the plan keeps its day.")
        }
        switch facts.day {
        case .ready:
            return LandingFootAction(
                word: foot.verb,
                object: foot.object,
                hold: true,
                hint: "Hold to start the workout",
                alternates: [log, rest]
            ) { start() }
        case .running:
            return LandingFootAction(word: foot.verb, object: foot.object, hint: "Opens the workout",
                                     alternates: [log]) { model.isWorkoutPresented = true }
        case .rest:
            var alternates = [log]
            if let next = facts.restOption {
                alternates.insert(
                    LandingFootAction.Step(verb: "Start", object: next, hold: true) { startNext() },
                    at: 0
                )
            }
            return LandingFootAction(word: foot.verb, object: foot.object, hint: "Logs a walk",
                                     alternates: alternates)
            {
                TessVoice.shared.say("Walks come in from Health.")
            }
        case .nothing:
            return LandingFootAction(word: foot.verb, object: foot.object, hint: "Opens the library") { goTo(.library) }
        case .done:
            return nil
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

    /// A rest day's right drag: the next routine anyway.
    private func startNext() {
        guard let plan = model.plan, let next = model.ledger.nextRoutine(in: plan, now: AppClock.now) else { return }
        model.workoutRisesFromLane = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.startRoutine(next) }
    }
}

/// The keystone hands the widget over on arrival (283 v3): 70 grains of chalk dust fall from the board's lower edge
/// onto the widget and turn the room's blue as they land. Once, 2.4 s; nothing under Reduce Motion. Never takes a
/// touch.
struct ChalkDustHandOver: View {
    static let grains = 70
    static let duration: TimeInterval = 2.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var start: Date?

    var body: some View {
        GeometryReader { proxy in
            let scale = max(0.86, min(1.1, proxy.size.height / 874))
            if let start, !reduceMotion {
                LiveTimeline(minimumInterval: 1.0 / 60) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    Canvas { context, _ in
                        guard elapsed < Self.duration else { return }
                        draw(&context, elapsed: elapsed, width: proxy.size.width, scale: scale)
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .liveRegion(LiveFeatures.wallHandover)
        .task {
            guard !reduceMotion, start == nil else { return }
            start = .now
            try? await Task.sleep(for: .seconds(Self.duration))
            start = nil
        }
    }

    private func draw(_ context: inout GraphicsContext, elapsed: TimeInterval, width: CGFloat, scale: CGFloat) {
        var rng = ChalkRandom(seed: 258)
        let chalk = Color(white: 0.93)
        let blue = Theme.Colors.Accent.training
        let left = (width - 354) / 2
        for _ in 0 ..< Self.grains {
            let x0 = left + 20 + rng.next() * 314
            let delay = rng.next() * 0.9
            let fall = 0.7 + rng.next() * 0.5
            let drift = (rng.next() - 0.5) * 18
            let land = (430 + rng.next() * 60) * scale
            let size = 1.2 + rng.next() * 1.8
            let phase = (elapsed - delay) / fall
            guard phase > 0 else { continue }
            let fallen = min(phase, 1)
            // Gravity: slow off the board, quick to land.
            let y = 372 * scale + (land - 372 * scale) * fallen * fallen
            let x = x0 + drift * fallen
            let landed = phase >= 1
            let after = max(0, elapsed - delay - fall)
            var dot = context
            dot.opacity = landed ? max(0, 1 - after / 0.6) : 0.85
            dot.fill(Path(ellipseIn: CGRect(x: x, y: y, width: size, height: size)),
                     with: .color(landed || fallen > 0.85 ? blue : chalk))
        }
    }
}

extension TrainingWallLanding {
    /// Deck's glyph is the board's ticks (283): the library picks by words, and "Tonight" or a routine like
    /// "Lower body" would draw a moon, so today's item is picked as the week's sessions. Yesterday keeps its words.
    static func glyphWords(_ item: WidgetItem) -> WidgetItem {
        guard item.id == "today" || item.id == "week" else { return item }
        return WidgetItem(id: item.id, header: "This week", big: "", middle: "")
    }
}

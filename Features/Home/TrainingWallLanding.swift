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
                        glyph: { _ in TallyGlyph() },
                        doors: facts.doors, focus: $focus, openDoor: openDoor,
                        action: action(facts))
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
        case "week":
            if LogSwitch.isOn {
                goTo(.log)
            } else {
                goTo(.page)
            }
        case "routines":
            goTo(.route(.routinesLanding))
        case "exercises":
            goTo(.library)
        case "programs":
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
        guard let word = facts.action else { return nil }
        switch facts.day {
        case .ready:
            return LandingFootAction(word: word, hint: "Starts the workout") { start() }
        case .running:
            return LandingFootAction(word: word, hint: "Opens the workout") { model.isWorkoutPresented = true }
        case let .rest(next, _):
            var action = LandingFootAction(word: word, hint: "Logs a walk") {
                TessVoice.shared.say("Walks come in from Health.")
            }
            if let option = facts.restOption, next != nil {
                action.right = .init(name: option) { startNext() }
            }
            return action
        case .nothing:
            return LandingFootAction(word: word, hint: "Opens the library") { goTo(.library) }
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

/// The widget's glyph: the board's ticks written stroke by stroke, once on arrival and again every 7 s. Still under
/// Reduce Motion.
struct TallyGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        TallyShape(progress: reduceMotion ? 5 : progress)
            .stroke(Theme.Colors.inkSecondary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 64, height: 56)
            .frame(width: 80, height: 80)
            .accessibilityHidden(true)
            .task {
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    progress = 0
                    for stroke in 1 ... 5 {
                        try? await Task.sleep(for: .milliseconds(180))
                        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
                            progress = CGFloat(stroke)
                        }
                    }
                    try? await Task.sleep(for: .seconds(7))
                }
            }
    }
}

/// Four upright strokes and the fifth across them, drawn up to `progress` strokes (fractions draw part of one).
struct TallyShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lines: [(CGPoint, CGPoint)] = (0 ..< 4).map { index in
            let x = rect.minX + rect.width * (0.14 + 0.2 * CGFloat(index))
            return (CGPoint(x: x, y: rect.minY + 6), CGPoint(x: x + 2, y: rect.maxY - 6))
        } + [(CGPoint(x: rect.minX + 2, y: rect.maxY - 14), CGPoint(x: rect.maxX - 2, y: rect.minY + 14))]
        for (index, line) in lines.enumerated() {
            let amount = min(max(progress - CGFloat(index), 0), 1)
            guard amount > 0 else { continue }
            path.move(to: line.0)
            path.addLine(to: CGPoint(x: line.0.x + (line.1.x - line.0.x) * amount,
                                     y: line.0.y + (line.1.y - line.0.y) * amount))
        }
        return path
    }
}

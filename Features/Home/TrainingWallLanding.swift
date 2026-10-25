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

/// The Training landing on the shared kit (landing contract §12): the word wall of lifts and routines in the
/// keystone slot, This week, Routines, Exercises, Programs and Goals on the dial, one line about today, and
/// "Start <routine>" at the foot ("Log a walk" on a rest day).
struct TrainingWallLanding: View {
    let goTo: (TrainingGo) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0

    var body: some View {
        let _ = model.revision
        let facts = TrainingWallFacts.load(model, dark: scheme == .dark)
        LandingFrame(title: "Training", accent: Theme.Colors.Accent.training, stateLine: facts.stateLine,
                     onTitle: { goTo(.page) },
                     keystone: {
                         LandingKeystone(label: "Your lifts and routines") {
                             WordWallView(words: facts.words, open: openWord, label: spoken)
                         }
                     },
                     doors: facts.doors, focus: $focus, openDoor: openDoor,
                     brief: { brief(facts.brief) },
                     action: action(facts),
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: Brief

    @ViewBuilder
    private func brief(_ brief: TrainingBrief?) -> some View {
        if let brief {
            let nameColor = brief.split?.color(dark: scheme == .dark) ?? Theme.Colors.ink
            let name = Text(brief.name).fontWeight(.semibold).foregroundStyle(nameColor)
            // The full line when it fits, else the name alone (AX3 and up); never wrapped, never "...".
            ViewThatFits(in: .horizontal) {
                (Text(brief.before) + name + Text(brief.after)).fixedSize(horizontal: true, vertical: false)
                name.lineLimit(1).minimumScaleFactor(0.5)
            }
            .font(.custom("Figtree", size: 15, relativeTo: .callout))
            .foregroundStyle(Theme.Colors.inkSecondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(brief.text)
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

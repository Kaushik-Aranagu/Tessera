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
        // One source with the shell's `DeckRoomContent`: the same facts, words, taps and foot.
        let facts = DeckRoomContent.Facts.load(model: model, scheme: scheme)
        let actions = DeckActions(model: model, reduceMotion: reduceMotion, goTo: goTo)
        LandingScaffold(title: DeckRoomContent.title, accent: Theme.Colors.Accent.training, navWord: "Bridge",
                        onBack: { dismiss() }, onTitle: { goTo(.page) },
                        switcher: TrainingDeckFacts.across, switcherVertical: facts.deck.routineWords,
                        switcherIndex: $switcherIndex, switcherVerticalIndex: $switcherVerticalIndex,
                        needs: facts.deck.needs.indices.contains(switcherIndex) ? facts.deck.needs[switcherIndex] : [],
                        keystone: {
                            LandingKeystone(label: DeckRoomContent.boardLabel) {
                                TrainingBlackboard(board: facts.deck.board, openToday: { goTo(.page) },
                                                   openLift: { goTo(.route(.classDef($0))) })
                            }
                        },
                        caption: DeckRoomContent.caption,
                        widget: facts.deck.widget, widgetIndex: $widgetIndex,
                        openWidget: { actions.item($0.id) },
                        glyph: { item in
                            LandingGlyph(item: DeckRoomContent.glyphWords(item), color: Theme.Colors.Accent.training,
                                         room: .deck)
                        },
                        doors: facts.wall.doors, focus: $focus, openDoor: { actions.door($0.id) },
                        action: actions.footAction(facts.wall), summaryStyle: .chalk)
            .overlay { ChalkDustHandOver() }
            .toolbar(.hidden, for: .navigationBar)
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

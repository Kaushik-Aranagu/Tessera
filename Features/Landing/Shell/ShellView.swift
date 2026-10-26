import SwiftUI

/// The standing shell (sheet 283 v5): the screen never slides. One persistent `PlaceHost` per place sits in a ZStack
/// at its v4 frame and is never torn down; going anywhere hands each place new content and the place changes it in
/// its own way. Layout changes merge places (Switcher + Needs into the Door title; Widget, Glyph, Dial and Door
/// summary into the Page) and back splits them. No NavigationStack push.
struct ShellView<Room: RoomContent>: View {
    let room: Room
    let navigator: ShellNavigator
    /// The room's color: the soft wash a place leaves as it flows during a merge or split.
    let accent: Color
    var act: (ShellIntent) -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var shown: [Place: SlotContent] = [:]
    @State private var styles: [Place: PlaceStyle] = [:]
    @State private var layout: LayoutKind = .landing
    @State private var washes: [Place: Double] = [:]
    @State private var busy: Set<Place> = []
    @State private var appliedRoute: ShellRoute?
    @State private var driver: Task<Void, Never>?

    private var reduceMotion: Bool {
        systemReduceMotion || ShellProbe.reduceMotion
    }

    private var target: Screen {
        room.screen(for: navigator.route, state: navigator.state)
    }

    var body: some View {
        let next = target
        GeometryReader { proxy in
            let scale = max(0.86, min(1.1, proxy.size.height / 874))
            let dx = (proxy.size.width - 402) / 2
            ZStack(alignment: .topLeading) {
                ForEach(Place.allCases, id: \.self) { place in
                    let rect = ShellLayout.frame(place, in: layout)
                    PlaceHost(place: place, content: shown[place], style: styles[place] ?? .rest, size: rect.size,
                              reduceMotion: reduceMotion, navigator: navigator, act: act)
                        .background(alignment: .topLeading) { wash(place) }
                        .offset(x: rect.minX + dx, y: rect.minY * scale)
                        .allowsHitTesting(shown[place] != nil && !busy.contains(place))
                        .zIndex(place == .glyph ? 1 : 0)
                }
                backEdge(height: proxy.size.height)
                if ShellProbe.enabled {
                    probe
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .background { ThemedBackground() }
        .onChange(of: next, initial: true) { _, screen in apply(screen) }
        .onDisappear { driver?.cancel() }
    }

    /// The soft trace a place leaves while it flows into a merge or spreads from a split (11% room color in Layout
    /// mode; here only while moving, and gone at rest).
    @ViewBuilder
    private func wash(_ place: Place) -> some View {
        if let opacity = washes[place], opacity > 0 {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(opacity))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// The back edge, x 0 to 24: a swipe right goes back.
    private func backEdge(height: CGFloat) -> some View {
        Color.clear
            .frame(width: 24, height: height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.width > 50, abs(value.translation.height) < 80 {
                    act(.back)
                }
            })
            .accessibilityHidden(true)
    }

    /// The simulator's state probe for UI tests.
    private var probe: some View {
        let state = navigator.state
        let label = "route \(navigator.route), switcher \(state.switcherIndex), vertical \(state.switcherVerticalIndex), "
            + "widget \(state.widgetIndex), focus \(state.dialFocus), changing \(navigator.change == nil ? "no" : "yes")"
        return Text(label)
            .font(.system(size: 1))
            .opacity(0.02)
            .frame(width: 2, height: 2)
            .accessibilityIdentifier("shell.state")
            .accessibilityLabel(label)
    }

    // MARK: Changes

    private func apply(_ screen: Screen) {
        if appliedRoute == nil {
            open(screen)
        } else if navigator.route != appliedRoute {
            change(to: screen)
        } else {
            refresh(screen)
        }
    }

    /// The opening: places in order, 80 ms apart, each rising 10 pt from 95% (sheet 283).
    private func open(_ screen: Screen) {
        appliedRoute = navigator.route
        layout = screen.layout
        for place in Place.allCases {
            styles[place] = PlaceStyle(move: .enter, context: .opening)
        }
        driver = Task { @MainActor in
            await Task.yield()
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { shown = screen.slots }
        }
    }

    /// A change of state inside the room (a swipe, a turn): each place that changed plays its move now, no waiting.
    private func refresh(_ screen: Screen) {
        let moves = PlaceMove.plan(from: Screen(layout: layout, slots: shown), to: screen)
        let changed = moves.filter { $0.value != .untouched && $0.value != .none }.map(\.key)
        let payloadOnly = moves.filter { $0.value == .untouched }.map(\.key).filter { shown[$0] != screen[$0] }
        // Same id: the payload refreshes in place with no move.
        for place in payloadOnly {
            shown[place] = screen[place]
        }
        guard !changed.isEmpty else { return }
        for place in changed {
            styles[place] = PlaceStyle(move: moves[place] ?? .move, context: .state)
        }
        Task { @MainActor in
            await Task.yield()
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                for place in changed {
                    shown[place] = navigatorTarget[place]
                }
            }
        }
    }

    private var navigatorTarget: Screen {
        target
    }

    /// A route change on one clock. A new route during a change cancels this one and starts from what is on screen
    /// now (SwiftUI retargets every animation from its presentation value); nothing queues.
    private func change(to screen: Screen) {
        driver?.cancel()
        appliedRoute = navigator.route
        let changeID = navigator.change?.id
        let plan = ShellPlan(from: Screen(layout: layout, slots: shown), to: screen)
        for place in Place.allCases {
            styles[place] = plan.style(place, dial: shown[.dial])
        }
        // Places still entering from a change this one replaces are freed; this change's places wait for their entry.
        busy = plan.affected
        driver = Task { @MainActor in
            let clock = ContinuousClock()
            let start = clock.now
            await Task.yield()
            guard !Task.isCancelled else { return }
            if reduceMotion {
                playReduced(screen)
            } else if plan.oldLayout == plan.newLayout {
                // Same layout: every place plays its own move; the delays live in each place's transition.
                withTesseraAnimation(Theme.Motion.house, reduceMotion: false) { shown = screen.slots }
            } else {
                guard await playLayoutChange(plan, screen, clock: clock, start: start) else { return }
            }
            guard await releaseTouches(plan, clock: clock, start: start) else { return }
            washes = [:]
            if let changeID {
                navigator.finish(changeID)
            }
        }
    }

    /// Reduce Motion: every place cross-fades in 150 ms; merges and splits jump to the end frame.
    private func playReduced(_ screen: Screen) {
        var jump = Transaction()
        jump.disablesAnimations = true
        withTransaction(jump) {
            layout = screen.layout
            washes = [:]
        }
        withTesseraAnimation(reduceMotion: true) { shown = screen.slots }
    }

    /// A merge or a split. False when a newer change took over.
    private func playLayoutChange(_ plan: ShellPlan, _ screen: Screen, clock: ContinuousClock,
                                  start: ContinuousClock.Instant) async -> Bool
    {
        let old = plan.oldLayout
        let new = plan.newLayout
        // 1. Content leaves the places that merge away (or the merged place that splits); places on both sides
        //    play their own move now; the flowing places show their wash.
        withTesseraAnimation(.easeOut(duration: ShellTiming.contentOut), reduceMotion: false) {
            for place in Place.allCases {
                if ShellLayout.exists(place, in: new), ShellLayout.exists(place, in: old) {
                    shown[place] = screen[place]
                } else if !ShellLayout.exists(place, in: new) {
                    shown[place] = nil
                }
            }
            for place in plan.sources {
                washes[place] = 0.09
            }
        }
        try? await clock.sleep(until: start + .seconds(ShellTiming.travelStart))
        guard !Task.isCancelled else { return false }
        // 2. The places flow into the merged rect (or spread from it), frame and corners together, and the washes
        //    fade as they arrive.
        withTesseraAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: ShellTiming.travel), reduceMotion: false) {
            layout = new
            for place in plan.sources {
                washes[place] = 0
            }
        }
        try? await clock
            .sleep(until: start + .seconds(plan.merging ? ShellTiming.mergeArrive : ShellTiming.splitArrive))
        guard !Task.isCancelled else { return false }
        // 3. Content arrives once the places have settled, so text is never stretched. Read the target again: a turn
        //    of state during the change wins.
        let latest = navigatorTarget
        withTesseraAnimation(Theme.Motion.house, reduceMotion: false) {
            for place in plan.arriving {
                shown[place] = latest[place]
            }
        }
        return true
    }

    /// Each place takes touches once its own entry has finished; then the change's clock runs out. False when a newer
    /// change took over.
    private func releaseTouches(_ plan: ShellPlan, clock: ContinuousClock,
                                start: ContinuousClock.Instant) async -> Bool
    {
        let whole = reduceMotion ? ShellTiming.reducedFade : ShellTiming.whole
        for (place, end) in plan.entryEnds {
            try? await clock.sleep(until: start + .seconds(min(end, whole)))
            guard !Task.isCancelled else { return false }
            busy.remove(place)
        }
        try? await clock.sleep(until: start + .seconds(whole))
        return !Task.isCancelled
    }
}

/// One route change worked out ahead: the layouts, each place's move, which places flow and which arrive.
struct ShellPlan {
    let oldLayout: LayoutKind
    let newLayout: LayoutKind
    let moves: [Place: PlaceMove]

    init(from old: Screen, to new: Screen) {
        oldLayout = old.layout
        newLayout = new.layout
        moves = PlaceMove.plan(from: old, to: new)
    }

    var merging: Bool {
        oldLayout == .landing && newLayout == .door
    }

    var splitting: Bool {
        oldLayout == .door && newLayout == .landing
    }

    /// The places whose content changes (they wait for their entry before taking touches).
    var affected: Set<Place> {
        Set(moves.filter { $0.value != .untouched && $0.value != .none }.map(\.key))
    }

    /// The places that flow into a merge or spread from a split.
    var sources: Set<Place> {
        Set(Place.allCases.filter { place in
            switch ShellLayout.travel(place, from: oldLayout, to: newLayout) {
            case .merge, .split: true
            default: false
            }
        })
    }

    /// The places that exist only in the new layout: their content arrives after the places settle.
    var arriving: [Place] {
        Place.allCases.filter { ShellLayout.exists($0, in: newLayout) && !ShellLayout.exists($0, in: oldLayout) }
    }

    var entryEnds: [(Place, Double)] {
        affected.map { place in
            (place, ShellTiming.entryEnd(place, move: moves[place] ?? .none, merging: merging, splitting: splitting))
        }.sorted { $0.1 < $1.1 }
    }

    func style(_ place: Place, dial: SlotContent?) -> PlaceStyle {
        var style = PlaceStyle(move: moves[place] ?? .none, context: .route)
        switch ShellLayout.travel(place, from: oldLayout, to: newLayout) {
        case .merge, .split, .form, .dissolve: style.context = .merge
        case .glide, .absent: break
        }
        if place == .dial, style.move == .move, case let .dial(old)? = dial?.payload {
            style.reelFrom = old.map(\.name)
        }
        return style
    }
}

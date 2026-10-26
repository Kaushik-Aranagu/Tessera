import SwiftUI

extension EnvironmentValues {
    // False inside a page that is not current or is covered. Set by `liveScope`; ANDed down the tree.
    @Entry var liveScope: Bool = true

    // True when the nearest region's switch is Quiet: change-driven moves play, idle loops do not.
    @Entry var liveQuiet: Bool = false

    // Whether the nearest `liveRegion` above is live. Defaults to true outside any region, so un-adopted views
    // behave as before.
    @Entry var isLive: Bool = true
}

private struct LiveScopeModifier: ViewModifier {
    @Environment(\.liveScope) private var outer
    let on: Bool

    func body(content: Content) -> some View {
        content.environment(\.liveScope, outer && on)
    }
}

private struct LiveRegionModifier: ViewModifier {
    let feature: LiveFeature
    var snapshot: (() -> LiveSnapshot)?
    var onReturn: ((LiveDiff) -> Void)?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.liveScope) private var scope
    @State private var visible = false
    @State private var seen: LiveSnapshot?
    @State private var leftAt: Date?

    func body(content: Content) -> some View {
        let switchState = LiveRegistry.shared.switchState(for: feature)
        let live = LiveGate.isLive(
            mode: feature.mode,
            switchState: switchState,
            inputs: .init(sceneActive: scenePhase == .active, visible: visible, scopeOn: scope)
        )
        content
            .environment(\.isLive, live)
            .environment(\.liveQuiet, switchState == .quiet)
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .onChange(of: live, initial: true) { _, now in
                LiveRegistry.shared.record(feature, live: now)
                handle(live: now)
            }
    }

    /// Remember what was drawn when it stops; on return, plan the differences (sheet 286, section 4).
    private func handle(live: Bool) {
        guard let snapshot, let onReturn else { return }
        if !live {
            seen = snapshot()
            leftAt = .now
        } else if let before = seen, let left = leftAt {
            seen = nil
            leftAt = nil
            if case let .play(diff, delay, _) = LiveReturn.plan(seen: before, now: snapshot(), away: Date.now.timeIntervalSince(left)) {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    onReturn(diff)
                }
            }
        }
    }
}

extension View {
    /// Marks the page, or a covered state of it, as current (`true`) or not. The shell sets this per page and per
    /// sheet; leaf features never read it directly.
    func liveScope(_ on: Bool) -> some View {
        modifier(LiveScopeModifier(on: on))
    }

    /// Declares this view as a live feature. Descendants read `\.isLive`, or use `LiveTimeline` / `liveTask`.
    func liveRegion(_ feature: LiveFeature) -> some View {
        modifier(LiveRegionModifier(feature: feature))
    }

    /// A live feature that also plays what changed while he was away. `snapshot` fingerprints what is drawn (called
    /// when the region stops being live and again when it returns). `onReturn` gets at most six differences, once,
    /// 650 ms after return; with more changes or an hour away nothing plays and the view just shows now.
    func liveRegion(_ feature: LiveFeature, snapshot: @escaping () -> LiveSnapshot,
                    onReturn: @escaping (LiveDiff) -> Void) -> some View {
        modifier(LiveRegionModifier(feature: feature, snapshot: snapshot, onReturn: onReturn))
    }

    /// Runs `action` only while the nearest region is live, cancels it when it stops, restarts it on return.
    /// For data-to-pixels work (a repeating timer, a poll) that has no reason to run unseen.
    func liveTask(priority: TaskPriority = .userInitiated,
                  _ action: @escaping @Sendable () async -> Void) -> some View
    {
        modifier(LiveTaskModifier(priority: priority, action: action))
    }
}

private struct LiveTaskModifier: ViewModifier {
    @Environment(\.isLive) private var live
    let priority: TaskPriority
    let action: @Sendable () async -> Void

    func body(content: Content) -> some View {
        content.task(id: live, priority: priority) {
            guard live else { return }
            await action()
        }
    }
}

/// `TimelineView` that stops ticking when the region is not live. Paused, it keeps its last frame; on return the
/// next frame is drawn from the current date and the current data, so nothing replays or catches up.
struct LiveTimeline<Content: View>: View {
    private let interval: TimeInterval
    private let content: (TimelineViewDefaultContext) -> Content

    private let idle: Bool

    @Environment(\.isLive) private var live
    @Environment(\.liveQuiet) private var quiet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `minimumInterval` as `TimelineView(.animation)`. With Reduce Motion on, it never ticks. `idle` marks a loop
    /// with no cause (drift, breathing); Quiet stops those but not change-driven timelines (`idle: false`).
    init(minimumInterval: TimeInterval = 1 / 30, idle: Bool = true,
         @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content) {
        interval = minimumInterval
        self.idle = idle
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: interval, paused: !live || reduceMotion || (idle && quiet)), content: content)
    }
}

/// `TimelineView(.animation)` that stops when the region is not live but leaves Reduce Motion to the caller, for the
/// features whose shipped Reduce Motion look still ticks (a slow fade, a blink). `paused` adds the caller's own
/// reasons.
struct LiveClock<Content: View>: View {
    private let interval: TimeInterval
    private let extraPause: Bool
    private let content: (TimelineViewDefaultContext) -> Content

    @Environment(\.isLive) private var live

    init(minimumInterval: TimeInterval = 1 / 30, paused: Bool = false,
         @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content)
    {
        interval = minimumInterval
        extraPause = paused
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: interval, paused: !live || extraPause), content: content)
    }
}

/// `TimelineView(.periodic)` that stops ticking when not live, for clocks and countdowns. Off-screen it holds one
/// still of the current date.
struct LivePeriodic<Content: View>: View {
    private let seconds: TimeInterval
    private let content: (Date) -> Content

    @Environment(\.isLive) private var live

    init(every seconds: TimeInterval, @ViewBuilder content: @escaping (Date) -> Content) {
        self.seconds = seconds
        self.content = content
    }

    var body: some View {
        if live {
            TimelineView(.periodic(from: .now, by: seconds)) { content($0.date) }
        } else {
            content(.now)
        }
    }
}

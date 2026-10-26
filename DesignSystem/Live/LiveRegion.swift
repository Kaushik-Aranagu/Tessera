import SwiftUI

private struct LiveScopeKey: EnvironmentKey {
    static let defaultValue = true
}

private struct IsLiveKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// False inside a page that is not current or is covered. Set by `liveScope`; ANDed down the tree.
    var liveScope: Bool {
        get { self[LiveScopeKey.self] }
        set { self[LiveScopeKey.self] = newValue }
    }

    /// Whether the nearest `liveRegion` above is live. Defaults to true outside any region, so un-adopted views
    /// behave as before.
    var isLive: Bool {
        get { self[IsLiveKey.self] }
        set { self[IsLiveKey.self] = newValue }
    }
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

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.liveScope) private var scope
    @State private var visible = false

    func body(content: Content) -> some View {
        let live = LiveGate.isLive(
            mode: feature.mode,
            switchState: LiveRegistry.shared.switchState(for: feature),
            inputs: .init(sceneActive: scenePhase == .active, visible: visible, scopeOn: scope)
        )
        content
            .environment(\.isLive, live)
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .onChange(of: live, initial: true) { _, now in
                LiveRegistry.shared.record(feature, live: now)
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

    /// Runs `action` only while the nearest region is live, cancels it when it stops, restarts it on return.
    /// For data-to-pixels work (a repeating timer, a poll) that has no reason to run unseen.
    func liveTask(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
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

    @Environment(\.isLive) private var live
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `minimumInterval` as `TimelineView(.animation)`. With Reduce Motion on, it never ticks.
    init(minimumInterval: TimeInterval = 1 / 30, @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content) {
        interval = minimumInterval
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: interval, paused: !live || reduceMotion), content: content)
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

import SwiftUI

extension EnvironmentValues {
    /// False inside a page that is not current or is covered. Set by `liveScope`; ANDed down the tree.
    @Entry var liveScope: Bool = true

    /// True when the nearest region's switch is Quiet: change-driven moves play, idle loops do not.
    @Entry var liveQuiet: Bool = false

    /// Whether the nearest `liveRegion` above is live. Defaults to true outside any region, so un-adopted views
    /// behave as before.
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
            if case let .play(diff, delay, _) = LiveReturn.plan(
                seen: before,
                now: snapshot(),
                away: Date.now.timeIntervalSince(left)
            ) {
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
                    onReturn: @escaping (LiveDiff) -> Void) -> some View
    {
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
///
/// Pass `feature` when nothing above it declares a region: the timeline then wraps itself in `liveRegion(feature)`.
struct LiveTimeline<Content: View>: View {
    private let feature: LiveFeature?
    private let interval: TimeInterval
    private let idle: Bool
    private let content: (TimelineViewDefaultContext) -> Content

    /// `minimumInterval` as `TimelineView(.animation)`. With Reduce Motion on, it never ticks. `idle` marks a loop
    /// with no cause (drift, breathing); Quiet stops those but not change-driven timelines (`idle: false`).
    init(_ feature: LiveFeature? = nil, minimumInterval: TimeInterval = 1 / 30, idle: Bool = true,
         @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content)
    {
        self.feature = feature
        interval = minimumInterval
        self.idle = idle
        self.content = content
    }

    var body: some View {
        let inner = LiveTimelineBody(interval: interval, idle: idle, calm: true, extraPause: false, content: content)
        if let feature {
            inner.liveRegion(feature)
        } else {
            inner
        }
    }
}

/// `TimelineView(.animation)` that stops when the region is not live but leaves Reduce Motion to the caller, for the
/// features whose shipped Reduce Motion look still ticks (a slow fade, a blink) or that pause for their own reasons
/// (`paused`). Pass `feature` when nothing above it declares a region.
struct LiveClock<Content: View>: View {
    private let feature: LiveFeature?
    private let interval: TimeInterval?
    private let extraPause: Bool
    private let content: (TimelineViewDefaultContext) -> Content

    /// `minimumInterval: nil` ticks at the display rate, as `TimelineView(.animation)`.
    init(_ feature: LiveFeature? = nil, minimumInterval: TimeInterval? = 1 / 30, paused: Bool = false,
         @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content)
    {
        self.feature = feature
        interval = minimumInterval
        extraPause = paused
        self.content = content
    }

    var body: some View {
        let inner = LiveTimelineBody(interval: interval, idle: false, calm: false, extraPause: extraPause,
                                     content: content)
        if let feature {
            inner.liveRegion(feature)
        } else {
            inner
        }
    }
}

/// The ticking part of `LiveTimeline` and `LiveClock`, inside whatever region they set up.
private struct LiveTimelineBody<Content: View>: View {
    let interval: TimeInterval?
    let idle: Bool
    /// True: Reduce Motion pauses it (`LiveTimeline`). False: the caller decides (`LiveClock`).
    let calm: Bool
    let extraPause: Bool
    let content: (TimelineViewDefaultContext) -> Content

    @Environment(\.isLive) private var live
    @Environment(\.liveQuiet) private var quiet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let paused = !live || (calm && reduceMotion) || (idle && quiet) || extraPause
        TimelineView(.animation(minimumInterval: interval, paused: paused), content: content)
    }
}

/// Hands its content whether the region it declares is live, for work that is not a timeline (a repeating animation
/// started by a state flip). Content flips its state from `live`; off screen nothing loops.
struct LiveGated<Content: View>: View {
    let feature: LiveFeature
    let content: (Bool) -> Content

    init(_ feature: LiveFeature, @ViewBuilder content: @escaping (Bool) -> Content) {
        self.feature = feature
        self.content = content
    }

    var body: some View {
        LiveGatedBody(content: content).liveRegion(feature)
    }
}

private struct LiveGatedBody<Content: View>: View {
    let content: (Bool) -> Content
    @Environment(\.isLive) private var live

    var body: some View {
        content(live)
    }
}

/// The soul's 3.2 s breath (1 to 1.08), looping only while the region is live. `on` is the caller's own state (it is
/// off under Reduce Motion). Off screen the scale rests at 1 and nothing repeats.
private struct LiveBreathBody: ViewModifier {
    let on: Bool
    @Environment(\.isLive) private var live

    func body(content: Content) -> some View {
        let active = on && live
        content
            .scaleEffect(active ? 1.08 : 1)
            .tesseraAnimation(active ? .easeInOut(duration: 3.2).repeatForever(autoreverses: true)
                : .linear(duration: 0), value: active)
    }
}

extension View {
    /// Tess's breath as one live feature (`tess.breath`): the soul in the dock and the workout corner use it.
    func liveBreath(on: Bool) -> some View {
        modifier(LiveBreathBody(on: on)).liveRegion(LiveFeatures.soulBreath)
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

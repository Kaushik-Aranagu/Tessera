import SwiftUI
import TesseraCore

/// Home as a mosaic (sheet 199, Builder B's part): the date and a Settings word, three right-aligned lines about the
/// day, the mosaic with its caption, then Next. Nothing else: no write line, mic, widgets, ring or bars. Used in
/// place of Home when Settings › Review › "Mosaic" is On.
struct HomeMosaicPage: View {
    /// The page's own coordinate space, so a finished row's frame can be handed to the mosaic.
    static let space = "homeMosaicPage"

    @Environment(AppModel.self) private var model
    @State private var link: HomeLink?
    /// Set by the mosaic when it is on the page: lays a finished row's colour into the picture.
    @State private var mosaicLay: ((CGRect) -> Bool)?
    /// The mosaic's one caption line.
    @State private var caption = ""
    /// Sheet 200: Tess's pick (mood, its three lines) and the facts it read, refreshed each minute and on a change.
    @State private var pick: MosaicPick?
    @State private var facts: MosaicFacts?
    /// Sheet 201: the moment on the mosaic, its one sentence line, and the beat counters for the entrance haptic.
    @State private var moment: MosaicMomentEvent?
    @State private var momentClause: HomeSentence.Clause?
    @State private var momentTask: Task<Void, Never>?
    @State private var softBeats = 0
    @State private var tickBeats = 0
    @State private var rigidBeats = 0
    @State private var onScreen = false
    @Environment(\.scenePhase) private var scenePhase
    /// Sheet 202: A's full-screen layer, its scene, where the core frame sits and the text it must stay clear of.
    @State private var controller = MosaicScreenController()
    @State private var scene: MosaicScene = .day
    @State private var coreTop: CGFloat = 0
    /// The scroll view's top in the window: content-space frames plus this are screen points at rest.
    @State private var scrollMinY: CGFloat = 0
    /// The scroll view's top inset (the safe area) and how far it is scrolled, both from the scroll view itself.
    @State private var insetTop: CGFloat = 0
    /// Held in an object only the layer reads, so a scroll frame redraws the layer and not the whole page.
    @State private var scroll = HomeScrollOffset()
    /// The day's clauses with Core's loaders, read once per refresh and not on every body.
    @State private var dayClauses: [HomeSentence.Clause]?
    @State private var shield: [CGRect] = []
    /// Sheet 209: the mosaic's pages and the width of the page, for the swipe that changes them.
    @State private var pager = MosaicPager()
    @State private var pageTicks = 0
    @State private var pageWidth: CGFloat = 0

    private var layerOn: Bool {
        HomeMosaic.moodsIsOn && facts != nil && pick != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeMosaic.sectionGap) {
                header
                    // Moods: 64 pt from the safe area to the sentence in all, so the row's gap is what is left.
                    .padding(.bottom, HomeMosaic.moodsIsOn
                        ? HomeMosaic.moodsTopInset - HomeMosaic.headerHeight - HomeMosaic.sectionGap : 0)
                MosaicSentence(pickedClauses: momentClause.map { [$0] } ?? pick?.clauses, dayClauses: dayClauses)
                    // Until the first refresh has read Core's loaders the sentence waits (no flicker between the
                    // fallback and the real lines).
                    .opacity(dayClauses == nil ? 0 : 1)
                    .accessibilityHidden(dayClauses == nil)
                    .mosaicShield()
                VStack(alignment: .leading, spacing: 0) {
                    MosaicSlot(coreTop: $coreTop, facts: facts, scene: $scene, caption: $caption)
                        .padding(.top, HomeMosaic.moodsIsOn ? HomeMosaic.moodsMosaicGap - HomeMosaic.sectionGap : 0)
                    if !caption.isEmpty {
                        Text(caption)
                            .font(Theme.voice(size: 16))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.s)
                            .mosaicShield()
                    }
                }
                // The call site that becomes `mosaic.lay(from: rowFrame, tone: .glaze)` with A's view.
                MosaicNextList { rowFrame in mosaicLay?(rowFrame) ?? false }
                    .mosaicShield()
                if HomeMosaic.appsListIsOn {
                    // Room for Tess above the list (her own layer draws there, sheet 209).
                    Color.clear.frame(height: HomeMosaic.tessRoom).accessibilityHidden(true)
                    AppsListSlot()
                        .mosaicShield()
                }
            }
            .padding(.horizontal, HomeMosaic.gutter)
            .padding(.top, HomeMosaic.moodsIsOn ? 0 : Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.xl)
            .coordinateSpace(.named(Self.space))
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        // Sheet 202: the mosaic is the page's own pixels, edge to edge, behind everything; every touch leans it.
        .background {
            if layerOn, let facts, let mood = pick?.mood {
                HomeLayerHost(
                    scroll: scroll,
                    scrollMinY: scrollMinY,
                    facts: facts,
                    scene: $scene,
                    controller: controller,
                    // The core sits where it does at rest, whatever the scroll, in whole tiles.
                    coreTop: ((scrollMinY + insetTop + coreTop) / 4).rounded() * 4,
                    shield: shield,
                    mood: mood,
                    moment: moment,
                    caption: $caption
                )
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { scrollMinY = $0 }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.top } action: { _, new in insetTop = new }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, new in scroll.value = new }
        .onPreferenceChange(MosaicShieldKey.self) { shield = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
        // A swipe that starts on the mosaic (or within 30 pt) changes its page; A's mosaic takes `pager.index`.
        .simultaneousGesture(
            DragGesture(minimumDistance: 24, coordinateSpace: .global).onEnded { value in
                let size = HomeMosaic.moodsMosaicSize
                let top = scrollMinY - scroll.value + coreTop
                let mosaic = CGRect(x: pageWidth - HomeMosaic.gutter - size.width, y: top,
                                    width: size.width, height: size.height)
                if layerOn, MosaicPager.accepts(start: value.startLocation, translation: value.translation,
                                                mosaic: mosaic, reach: pager.count > 1 ? 0 : MosaicPager.reach),
                    pager.swipe(dx: value.translation.width)
                {
                    pageTicks += 1
                }
            }
        )
        .tesseraFeedback(.selection, trigger: pageTicks)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                pager.returned(at: Date())
            } else if phase == .background {
                pager.leave(at: Date())
            }
        }
        .mosaicTouchFeed(controller, enabled: layerOn)
        .onAppear {
            mosaicLay = { rect in
                MomentMemory.handDoneAt = AppClock.now
                return controller.lay(from: rect, tone: .glaze)
            }
        }
        // Sheet 203: a pull down from the top 40 pt also opens Settings.
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                if value.startLocation.y < 40, value.translation.height > 60,
                   abs(value.translation.width) < value.translation.height
                {
                    link = .settings
                }
            }
        )
        .task(id: Int(AppClock.now.timeIntervalSince1970 / 60) &+ model.revision) { refreshPick() }
        .onAppear { onScreen = true }
        .onDisappear {
            onScreen = false
            endMoment()
        }
        // A mood change cancels the moment, and the sentence turns back with it.
        .onChange(of: pick?.mood) { _, _ in endMoment() }
        .tesseraFeedback(.made, trigger: softBeats)
        .tesseraFeedback(.selection, trigger: tickBeats)
        .tesseraFeedback(.setLogged, trigger: rigidBeats)
        .environment(\.openHomeLink) { link = $0 }
        .fullScreenCover(item: $link) { link in
            // Settings has its own back word ("‹ Home"), so it gets no Close.
            if link == .settings {
                link.destination
            } else {
                link.destination
                    .safeAreaInset(edge: .top, spacing: 0) {
                        HStack {
                            Spacer()
                            Button("Close") { self.link = nil }
                                .buttonStyle(InkLabelWordStyle())
                        }
                        .padding(.horizontal, Theme.Spacing.gutter - 8)
                    }
            }
        }
    }

    private static let backShownKey = "homeMosaic.backShown"

    /// Asks Core's picker what the day looks like now; "Welcome back" shows once per absence.
    private func refreshPick() {
        let at = AppClock.now
        dayClauses = HomeMosaic.firstThree(HomeSentence.compose(HomeSentence.inputs(
            engine: model.engine, plan: model.plan, moneyDue: .next(engine: model.engine, now: at),
            routines: .make(engine: model.engine, now: at), now: at
        )))
        guard HomeMosaic.moodsIsOn else {
            pick = nil
            // The plain 199 mosaic still needs the day's facts.
            facts = HomeMosaic.isOn ? MosaicFacts.make(engine: model.engine, now: AppClock.now) : nil
            return
        }
        let now = AppClock.now
        let read = MosaicFacts.make(engine: model.engine, now: now)
        let defaults = UserDefaults.standard
        let inputs = MosaicMoodInputs.make(engine: model.engine, facts: read, plan: model.plan,
                                           backShown: defaults.bool(forKey: Self.backShownKey),
                                           previous: pick.map { ($0.mood, $0.since) })
        // A second absence says "Welcome back" again: the flag clears once he has been about for a day or two.
        if inputs.daysAway < 3, defaults.bool(forKey: Self.backShownKey), !model.isSample {
            defaults.removeObject(forKey: Self.backShownKey)
        }
        let next = MosaicMoodPicker.pick(inputs)
        if next.mood == .back, !model.isSample {
            defaults.set(true, forKey: Self.backShownKey)
        }
        facts = read
        if next != pick {
            pick = next
        }
        playMoment(read)
    }

    /// Sheet 201: asks Core whether a moment is ready, and plays it. What has played and when stay in memory only;
    /// the Tess slot stays empty until an on-device suggestion exists that never quoted calendar or health text.
    private func playMoment(_ facts: MosaicFacts) {
        guard HomeMosaic.momentsIsOn, moment == nil, onScreen, scenePhase == .active else { return }
        let inputs = MosaicMomentInputs.make(engine: model.engine, facts: facts,
                                             quiet: MosaicMomentMapping.isQuiet(facts.now),
                                             last: MomentMemory.last, played: MomentMemory.played)
        guard let next = MosaicMomentSource.next(inputs) else { return }
        MomentMemory.played.insert(next.key)
        MomentMemory.last = (next.kind, facts.now)
        // A Done from a Next row already flew its tile and played its tap: only the sentence clause follows.
        if next.kind == .finished, let done = MomentMemory.handDoneAt,
           AppClock.now.timeIntervalSince(done) < MomentMemory.handWindow
        {
            momentClause = next.clause
            momentTask?.cancel()
            momentTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(3.2))
                guard !Task.isCancelled else { return }
                momentClause = nil
            }
            return
        }
        let played = MosaicMomentEvent(MosaicMomentMapping.moment(for: next))
        moment = played
        momentClause = next.clause
        switch MosaicMomentMapping.beat(next.kind) {
        case .soft: softBeats += 1
        case .tick: tickBeats += 1
        case .rigid: rigidBeats += 1
        }
        momentTask?.cancel()
        momentTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(played.moment.duration))
            guard !Task.isCancelled, moment?.id == played.id else { return }
            endMoment()
        }
    }

    /// The moment is over (its time, a mood change, or leaving Home): the sentence turns back to the mood's lines.
    private func endMoment() {
        momentTask?.cancel()
        momentTask = nil
        if moment != nil {
            moment = nil
        }
        if momentClause != nil {
            momentClause = nil
        }
    }

    /// The date at the left, the Settings word at the right (a 44 pt target).
    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            Text(AppClock.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(Theme.voice(size: 16))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            SettingsEntry { link = .settings }
        }
    }
}

/// The scroll offset, in an object so only the views that read `value` redraw when it changes.
@MainActor
@Observable
final class HomeScrollOffset {
    var value: CGFloat = 0
}

/// A's layer with the shields moved by the scroll: the words move with the page, so their rectangles do too. Reading
/// the offset here keeps the page itself from redrawing on every scroll frame.
private struct HomeLayerHost: View {
    let scroll: HomeScrollOffset
    let scrollMinY: CGFloat
    let facts: MosaicFacts
    @Binding var scene: MosaicScene
    let controller: MosaicScreenController
    let coreTop: CGFloat
    let shield: [CGRect]
    let mood: MosaicMood
    let moment: MosaicMomentEvent?
    @Binding var caption: String

    var body: some View {
        MosaicHomeLayer(
            facts: facts,
            scene: $scene,
            controller: controller,
            coreTop: coreTop,
            // Content origin is the scroll view's top less its offset.
            shield: shield.map { $0.offsetBy(dx: 0, dy: scrollMinY - scroll.value) },
            mood: mood,
            moment: moment,
            caption: $caption
        )
    }
}

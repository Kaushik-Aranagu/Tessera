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
    /// Where the doorway starts: the tapped word's centre (global), else the mosaic's.
    @State private var doorwayOrigin: CGPoint?
    /// Set by the mosaic when it is on the page: lays a finished row's colour into the picture.
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    /// Core's ranked notices for the board's lines two and three.
    @State private var notices: [HomeNotice] = []
    /// Sheet 213: the things that take turns in the space under the mosaic (Core's ranking when its feed lands).
    @State private var things: [HomeThing] = []
    /// Sheet 215: her layer is open, and the conversation in it.
    @State private var tessOpen = false
    @State private var tessModel = TessLayerModel()
    @State private var listener = SpeechListener()
    @State private var tessHolding = false
    @State private var tessVoice = 0.0
    @State private var tessHeardAt: Date?
    @State private var roomOpen = false
    @State private var roomEntries: [RoomLogEntry] = []
    /// The 72 pt sign slot's global frame (from the thing space) and the sign the mosaic builds in it.
    @State private var signSlot: CGRect = .zero
    /// Sheet 214: the scene Core's picker chose for now (nil: the mood stripes). Weather and place are not read yet.
    @State private var scenery: MosaicScenery?
    /// "Sunset" washes the mosaic to dusk for a few seconds.
    @State private var dusk = false
    @State private var duskTask: Task<Void, Never>?
    @State private var shield: [CGRect] = []
    /// Sheet 209: the mosaic's pages and the width of the page, for the swipe that changes them.
    @State private var pager = MosaicPager(count: MosaicPage.count)
    @State private var pageDirection = 1
    @State private var pageTicks = 0
    /// Sheet 213: the one-thing space's own page (the mosaic's pages are the pager's), and when Home was left.
    @State private var thingIndex = 0
    @State private var thingsLeftAt: Date?
    @State private var pageWidth: CGFloat = 0
    /// The apps wheel is held: the page does not scroll under the same finger.
    @State private var wheelHeld = false

    private var layerOn: Bool {
        HomeMosaic.moodsIsOn && facts != nil && pick != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeMosaic.sectionGap) {
                MosaicSentence(pickedClauses: momentClause.map { [$0] }, dayClauses: dayClauses,
                               onDoor: { clause, frame in
                                   doorwayFrom(frame) {
                                       DaySentence.open(clause, model: model, openLink: { present($0) })
                                   }
                               },
                               noticeList: notices,
                               onRoom: { app, frame in doorwayFrom(frame) { present(linkFor(app)) } },
                               onSky: { playDusk() },
                               facts: facts,
                               paused: scenePhase != .active || link != nil)
                    // Until the first refresh has read Core's loaders the sentence waits (no flicker between the
                    // fallback and the real lines).
                    .opacity(dayClauses == nil ? 0 : 1)
                    .accessibilityHidden(dayClauses == nil)
                    .mosaicShield()
                VStack(alignment: .leading, spacing: 0) {
                    MosaicSlot(coreTop: $coreTop, facts: facts, scene: $scene, caption: $caption)
                        .padding(.top, HomeMosaic.moodsIsOn ? HomeMosaic.moodsMosaicGap - HomeMosaic.sectionGap : 0)
                    // No caption under the mosaic (sheet 211): its words live in the slot's accessibility label.
                }
                // Sheet 213: one thing at a time, no Next list.
                HomeOneThing(things: things, index: $thingIndex, turn: { turnThing($0) },
                             done: { finishThing($0) }, open: { openThing($0) }, onSlot: { signSlot = $0 })
                    .mosaicShield()
                if HomeMosaic.appsListIsOn {
                    AppsListSlot(onHold: { wheelHeld = $0 }, onGlance: { playGlance($0) })
                        .mosaicShield()
                }
            }
            .padding(.horizontal, HomeMosaic.gutter)
            .padding(.top, HomeMosaic.moodsIsOn ? 16 : Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.xl)
            .coordinateSpace(.named(Self.space))
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(wheelHeld)
        // Sheet 216: the date is the board's first line, so the Settings entry sits at the top left, clear of the
        // right-aligned rows (the date row is short and begins well to its right).
        .overlay(alignment: .topLeading) {
            SettingsEntry { link = .settings }
                .padding(.leading, HomeMosaic.gutter - 8)
                .padding(.top, Self.settingsTop)
        }
        // Sheet 212: an 80 pt clear band at the bottom for Tess's corner; everything else sits above it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: HomeMosaic.tessRoom).accessibilityHidden(true)
        }
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
                    caption: $caption,
                    page: MosaicPage(rawValue: pager.index) ?? .mood,
                    pageDirection: pageDirection,
                    signSpec: signSpec,
                    scenery: scenery,
                    dusk: dusk
                )
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { scrollMinY = $0 }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.top } action: { _, new in insetTop = new }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, new in scroll.value = new }
        .onPreferenceChange(MosaicShieldKey.self) { shield = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { pageWidth = $0 }
        // A swipe that starts on the mosaic itself turns the things (the mosaic's own pages are gone).
        .simultaneousGesture(
            DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart), coordinateSpace: .global).onEnded { value in
                let size = HomeMosaic.moodsMosaicSize
                let top = scrollMinY - scroll.value + coreTop
                let mosaic = CGRect(x: pageWidth - HomeMosaic.gutter - size.width, y: top,
                                    width: size.width, height: size.height)
                if layerOn, MosaicPager.accepts(start: value.startLocation, translation: value.translation,
                                                mosaic: mosaic, reach: 0),
                    turnThing(value.translation.width)
                {
                    pageDirection = value.translation.width < 0 ? 1 : -1
                    pageTicks += 1
                }
            }
        )
        .tesseraFeedback(.selection, trigger: pageTicks)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // After two minutes or more away the space is back on its first thing.
                if let left = thingsLeftAt, Date().timeIntervalSince(left) >= MosaicPager.awaySeconds {
                    thingIndex = 0
                }
                thingsLeftAt = nil
                pager.returned(at: Date())
            } else if phase == .background {
                thingsLeftAt = Date()
                pager.leave(at: Date())
            }
        }
        .mosaicTouchFeed(controller, enabled: layerOn)
        // Sheet 215: Home sits under her blur (hers alone) while her layer is open.
        .tessBackdrop(open: tessOpen)
        // Sheet 209 and 215: Tess on her own layer above all of Home; touches pass through except on her. Her
        // conversation opens over Home, and she moves to the bottom middle.
        .overlay { tessOverlay }
        .onChange(of: layerOn, initial: true) { _, on in model.homeTessLayerActive = on && HomeMosaic.appsListIsOn }
        .onDisappear { model.homeTessLayerActive = false }
        // Sheet 203: a pull down from the top 40 pt also opens Settings.
        .simultaneousGesture(
            DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart)).onEnded { value in
                if value.startLocation.y < 40,
                   GestureTuning.pull(dx: Double(value.translation.width), dy: Double(value.translation.height),
                                      velocityY: Double(value.velocity.height)) > 0
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
        .environment(\.openHomeLink) { present($0) }
        .environment(\.playDoorway) { accent, reverse, navigate in
            model.doorway.play(from: doorwayOrigin ?? mosaicCentre, accent: accent, reverse: reverse,
                               reduceMotion: reduceMotion, navigate: { withoutAnimation(navigate) })
            doorwayOrigin = nil
        }
        .fullScreenCover(item: $link) { link in
            // Settings and Today have no Close word of their own; a room has Close at the top right.
            Group {
                if link == .settings || link == .today {
                    link.destination
                } else {
                    link.destination
                        .safeAreaInset(edge: .top, spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Close") { dismissLink() }
                                    .buttonStyle(InkLabelWordStyle())
                            }
                            .padding(.horizontal, Theme.Spacing.gutter - 8)
                        }
                }
            }
            // The edge swipe back runs the doorway in reverse, into the mosaic (no "‹ Home" word on a room).
            .overlay(alignment: .leading) {
                Color.clear
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 12).onEnded { value in
                        if value.translation.width > 60, abs(value.translation.height) < value.translation.width {
                            dismissLink()
                        }
                    })
                    .accessibilityHidden(true)
            }
        }
    }

    /// Settings sits on row 1's baseline (the date): the date row is 30 pt at Figtree 23 under a 16 pt top pad, and the
    /// word is Figtree 16 centred in a 44 pt target, so the offset is the difference of the two baselines.
    static let settingsTop: CGFloat = {
        func face(_ size: CGFloat) -> UIFont {
            UIFont(descriptor: UIFontDescriptor(fontAttributes: [.family: "Figtree"]), size: size)
        }
        let big = face(DepartureBoard.size), small = face(16)
        let row = 16 + (DepartureBoard.rowHeight - big.lineHeight) / 2 + big.ascender
        let word = (44 - small.lineHeight) / 2 + small.ascender
        return max(row - word, 0)
    }()

    private static let backShownKey = "homeMosaic.backShown"

    /// Asks Core's picker what the day looks like now; "Welcome back" shows once per absence.
    private func refreshPick() {
        let at = AppClock.now
        let routinesPart = HomeSentence.RoutinesPart.make(engine: model.engine, now: at)
        let read = MosaicFacts.make(engine: model.engine, now: at)
        things = HomeThings.make(model: model, facts: read, routines: routinesPart)
        let backdrop = model.settingsAreReal ? SettingsStore(engine: model.engine).read().backdrop : .tessPicks
        scenery = facts.flatMap { MosaicScenePicker.pick(backdrop, facts: $0, place: nil, weather: nil) }
        thingIndex = min(thingIndex, max(things.count - 1, 0))
        dayClauses = HomeMosaic.firstThree(HomeSentence.compose(HomeSentence.inputs(
            engine: model.engine, plan: model.plan, moneyDue: .next(engine: model.engine, now: at),
            routines: routinesPart, now: at
        )))
        guard HomeMosaic.moodsIsOn else {
            pick = nil
            // The plain 199 mosaic still needs the day's facts.
            facts = HomeMosaic.isOn ? read : nil
            return
        }
        let now = AppClock.now
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
        notices = HomeNotices.ranked(engine: model.engine, facts: read, plan: model.plan,
                                     moneyDue: .next(engine: model.engine, now: now),
                                     routines: .make(engine: model.engine, now: now))
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

    /// Sheet 206: the apps list settled on an app, so the mosaic plays that app's glance (a new pick restarts it; a
    /// moment already playing, other than a glance, wins). The sentence does not change.
    private func playGlance(_ app: HomeApp) {
        guard layerOn, scenePhase == .active else { return }
        if let moment, case .glance = moment.moment {} else if moment != nil {
            return
        }
        let played = MosaicMomentEvent(.glance(app: app))
        moment = played
        momentTask?.cancel()
        momentTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(played.moment.duration))
            guard !Task.isCancelled, moment?.id == played.id else { return }
            endMoment()
        }
    }

    /// Sheet 209: Tess was tapped, so the mosaic plays the Tess moment (the sentence does not change).
    /// Sheet 209 and 215: Tess on her own layer above all of Home; touches pass through except on her. Her
    /// conversation opens over Home, and she moves to the bottom middle.
    @ViewBuilder private var tessOverlay: some View {
        if layerOn, HomeMosaic.appsListIsOn {
            ZStack {
                if roomOpen {
                    TessRoom(entries: roomEntries, watching: "Watching today.", undo: { entry in
                        switch TessRoomLog.undo(entry, engine: model.engine) {
                        case let .putBack(line): line
                        default: nil
                        }
                    }, close: { roomOpen = false })
                        .transition(.identity)
                }
                if tessOpen {
                    TessConversationLayer(model: tessModel, close: { closeTess() },
                                          answer: { tessAnswer($0) }, send: { tessHeard($0) })
                }
                TessLayer(
                    thoughts: TessThoughts.lines(facts: facts, asksClaude: model.asksClaude),
                    onTap: { tessTapped() },
                    open: tessOpen,
                    holding: tessHolding,
                    voice: tessVoice,
                    heardAt: tessHeardAt,
                    quiet: tessModel.isQuiet(),
                    onHold: { holdBegan() },
                    onHoldEnd: { holdEnded(cancelled: $0) },
                    onDoubleTap: { tessQuiet() },
                    onSwipeUp: { openRoom() }
                )
            }
            .onChange(of: listener.heard) { _, words in
                tessModel.liveSpeech = words
                tessHeardAt = Date()
            }
            .onChange(of: listener.level) { _, level in
                tessVoice = tessHolding ? level : 0
            }
        }
    }

    /// Hold: her layer opens at once and she listens, on this phone only, until he lets go (the speech listener
    /// keeps no audio; its on-device recognition is always required). If listening cannot start, the Ask field is
    /// there with one plain line.
    private func holdBegan() {
        guard layerOn, scenePhase == .active else { return }
        if !tessOpen {
            tessTapped()
        }
        tessHolding = true
        tessModel.stateLine = "Listening. Slide left to let it go"
        listener.onFinish = { text in
            if let text {
                tessSpoke(text)
            }
        }
        Task {
            if let refusal = await listener.start(hold: true) {
                tessHolding = false
                tessModel.stateLine = refusal.line
            }
        }
    }

    private func holdEnded(cancelled: Bool) {
        guard tessHolding else { return }
        tessHolding = false
        tessVoice = 0
        listener.stop(send: !cancelled)
        tessModel.liveSpeech = ""
        tessModel.stateLine = ""
    }

    /// What he said: a line of his, and she answers on the phone.
    private func tessSpoke(_ text: String) {
        tessModel.hear(text)
        tessHeard(text)
    }

    /// Double tap: quiet for an hour (a tap wakes her).
    private func tessQuiet() {
        if tessModel.isQuiet() {
            tessModel.wake()
        } else {
            tessModel.quietForAnHour()
        }
    }

    /// Swipe up: her room, from her corner.
    private func openRoom() {
        roomEntries = TessRoomLog.today(engine: model.engine, now: AppClock.now)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: false) { roomOpen = true }
    }

    /// A tap on her: opens her layer (closes it if it is open).
    private func tessTapped() {
        guard layerOn, scenePhase == .active else { return }
        if tessOpen {
            closeTess()
        } else {
            tessModel.open(engine: model.engine, classes: model.classes, facts: facts)
            tessOpen = true
        }
    }

    private func closeTess() {
        tessModel.close()
        tessOpen = false
    }

    /// What she says to a reply he picked (the phone's own answers; nothing leaves the phone here).
    private func tessAnswer(_ reply: String) -> String? {
        switch reply {
        case "Show me": "Here it is."
        case "Not now", "Leave it", "Fine as it is": "Okay."
        default: "Okay."
        }
    }

    /// Typed words: she answers on the phone, with one plain reply to end it.
    private func tessHeard(_ text: String) {
        Task {
            // The same capture as ever: her grammar or the on-device model turns the words into actions, and she
            // answers in one line.
            let line = await model.ask(text)
            tessModel.say(line.isEmpty ? "Got it." : line, names: [])
            tessModel.offer(["That's all"])
        }
    }

    private func playTess() {
        guard layerOn, scenePhase == .active, moment == nil else { return }
        let played = MosaicMomentEvent(.tess)
        moment = played
        momentTask?.cancel()
        momentTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(played.moment.duration))
            guard !Task.isCancelled, moment?.id == played.id else { return }
            endMoment()
        }
    }

    /// The hold finished a task: the op lands, the one Undo line speaks its shown label, and the next thing comes in.
    /// Returns whether the task was marked done (the one rigid tap plays only then).
    private func finishThing(_ thing: HomeThing) -> Bool {
        guard let id = thing.taskID,
              let record = try? model.engine.perform(SetTaskDone(task: id, done: true), by: .user).record
        else { return false }
        // The op-log "finished" moment that follows shows its clause only: no second tile and no second tap.
        MomentMemory.handDoneAt = AppClock.now
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(thing.undoLine ?? "Done.", undo: record, holds: .seconds(5))
        return true
    }

    /// Sheet 213: the sign for the thing now showing, in its accent. A task's accent is ink, so it does not wash.
    private var signSpec: MosaicSignSpec? {
        guard things.indices.contains(thingIndex) else { return nil }
        let thing = things[thingIndex]
        let alt: Color? = thing.accent == .birthday ? Color(light: 0xB0466A, dark: 0xE07A9A) : nil
        return MosaicSignSpec(
            kind: ThingSignKind(thing.kind),
            accent: thing.accentColor,
            alt: alt,
            washes: thing.accent != .ink,
            slot: signSlot,
            token: thing.id
        )
    }

    /// A swipe on the space: the next thing (left) or the previous (right), wrapping; whether the page turned.
    private func turnThing(_ dx: CGFloat) -> Bool {
        guard things.count > 1, abs(dx) > 50 else { return false }
        thingIndex = ((thingIndex + (dx < 0 ? 1 : -1)) % things.count + things.count) % things.count
        return true
    }

    /// The mosaic's centre in global points, where a doorway starts when no word was tapped.
    private var mosaicCentre: CGPoint {
        let size = HomeMosaic.moodsMosaicSize
        return CGPoint(x: pageWidth - HomeMosaic.gutter - size.width / 2,
                       y: scrollMinY - scroll.value + coreTop + size.height / 2)
    }

    /// A word was tapped: the doorway starts from its centre.
    private func doorwayFrom(_ frame: CGRect, _ open: () -> Void) {
        doorwayOrigin = CGPoint(x: frame.midX, y: frame.midY)
        open()
    }

    private func linkFor(_ app: AppID) -> HomeLink {
        switch HomeApp(appID: app) {
        case .kitchen: .recipes
        case .money: .money
        case .notes: .notes
        case .lists: .lists
        case .training: .training
        default: .review
        }
    }

    /// "Sunset": the mosaic washes to dusk, holds for five seconds, and comes back.
    private func playDusk() {
        guard layerOn, scenePhase == .active else { return }
        dusk = true
        duskTask?.cancel()
        duskTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            dusk = false
        }
    }

    private func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }

    /// Opens a room through the doorway: from the tapped word if there was one, else from the mosaic's centre.
    private func present(_ target: HomeLink) {
        model.doorway.play(from: doorwayOrigin ?? mosaicCentre, accent: doorwayAccent(target), reverse: false,
                           reduceMotion: reduceMotion, navigate: { withoutAnimation { link = target } })
        doorwayOrigin = nil
    }

    /// "Close" or "‹ Home": the doorway back into the mosaic.
    private func dismissLink() {
        let accent = link.map(doorwayAccent) ?? Theme.Colors.ink
        model.doorway.play(from: mosaicCentre, accent: accent, reverse: true, reduceMotion: reduceMotion,
                           navigate: { withoutAnimation { link = nil } })
    }

    private func doorwayAccent(_ target: HomeLink) -> Color {
        switch target {
        case .training: HomeApp.training.accent
        case .recipes, .groceries, .pantry, .pasteRecipe: HomeApp.kitchen.accent
        case .money: HomeApp.money.accent
        case .notes: HomeApp.notes.accent
        case .lists: HomeApp.lists.accent
        case .review: HomeApp.routines.accent
        case .today, .settings: Theme.Colors.ink
        }
    }

    /// A tap goes to the thing's own target: its object, its app's room, Today, or the weather.
    private func openThing(_ thing: HomeThing) {
        switch thing.target {
        case let .object(id):
            model.path.append(Route.object(id))
        case let .room(app):
            present(linkFor(app))
        case .today, .weather:
            present(.today)
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
    var page: MosaicPage = .mood
    var pageDirection = 1
    var signSpec: MosaicSignSpec?
    var scenery: MosaicScenery?
    var dusk = false

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
            caption: $caption,
            page: page,
            pageDirection: pageDirection,
            signSpec: signSpec,
            scenery: scenery,
            dusk: dusk
        )
    }
}

import SwiftUI
import TesseraCore

/// Bridge's state and behaviour, lifted out of `HomeMosaicPage` so the same Bridge can be drawn two ways: as the page
/// it always was, or place by place inside the standing shell (sheet 283 v5), where the departure board, the mosaic,
/// the one-thing box and the apps dial are each a place's content. One stage, one engine, one set of moods, moments
/// and faces, whichever way it is drawn.
@MainActor
@Observable
final class BridgeStage {
    // MARK: Wiring (set by the host each body)

    @ObservationIgnored weak var model: AppModel?
    @ObservationIgnored var reduceMotion = false
    var scenePhase: ScenePhase = .active
    /// Asked first when a room is opened from Bridge: the standing shell takes the rooms it can hold (true). Nil or
    /// false falls back to the room's own full-screen page.
    @ObservationIgnored var openInShell: ((HomeLink) -> Bool)?
    @ObservationIgnored var openDoorInShell: ((HomeV2Door) -> Bool)?

    // MARK: Presentation

    var link: HomeLink?
    /// A room word that opens a room landing as a door (Galley, sheet 283), not a link page.
    var roomDoor: HomeV2Door?
    /// Where the doorway starts: the tapped word's centre (global), else the mosaic's.
    var doorwayOrigin: CGPoint?

    // MARK: The mosaic

    var caption = ""
    /// Sheet 200: Tess's pick (mood, its three lines) and the facts it read, refreshed each minute and on a change.
    var pick: MosaicPick?
    var facts: MosaicFacts?
    /// Sheet 201: the moment on the mosaic, its one sentence line, and the beat counters for the entrance haptic.
    var moment: MosaicMomentEvent?
    var momentClause: HomeSentence.Clause?
    @ObservationIgnored var momentTask: Task<Void, Never>?
    var softBeats = 0
    var tickBeats = 0
    var rigidBeats = 0
    var onScreen = false
    /// Sheet 202: A's full-screen layer, its scene, where the core frame sits and the text it must stay clear of.
    let controller = MosaicScreenController()
    var scene: MosaicScene = .day
    var coreTop: CGFloat = 0
    var scrollMinY: CGFloat = 0
    var insetTop: CGFloat = 0
    let scroll = HomeScrollOffset()
    /// The day's clauses with Core's loaders, read once per refresh and not on every body.
    var dayClauses: [HomeSentence.Clause]?
    /// Core's ranked notices for the board's lines two and three.
    var notices: [HomeNotice] = []
    /// Sheet 213: the things that take turns in the space under the mosaic.
    var things: [HomeThing] = []
    /// The 72 pt sign slot's global frame (from the thing space) and the sign the mosaic builds in it.
    var signSlot: CGRect = .zero
    /// Sheet 214: the scene Core's picker chose for now (nil: the mood stripes).
    var scenery: MosaicScenery?
    /// Home 236: the stack of faces, and the board's latest line it plays as Now.
    let faces = MosaicFaceModel()
    var announcement: MosaicNowReading?
    var gallery: [MosaicScenery] = []
    /// "Sunset" washes the mosaic to dusk for a few seconds.
    var dusk = false
    @ObservationIgnored var duskTask: Task<Void, Never>?
    var shield: [CGRect] = []
    /// Sheet 209: the mosaic's pages.
    var pager = MosaicPager(count: MosaicPage.count)
    var pageDirection = 1
    /// Sheet 213: the one-thing space's own page, and when Home was left.
    var thingIndex = 0
    var thingsLeftAt: Date?
    var pageWidth: CGFloat = 0
    /// The apps wheel is held: the page does not scroll under the same finger.
    var wheelHeld = false

    // MARK: Tess (sheet 215)

    var tessOpen = false
    let tessModel = TessLayerModel()
    let listener = SpeechListener()
    var tessHolding = false
    var tessVoice = 0.0
    var tessHeardAt: Date?
    var roomOpen = false
    var roomEntries: [RoomLogEntry] = []

    var layerOn: Bool {
        HomeMosaic.moodsIsOn && facts != nil && pick != nil
    }

    var active: Bool {
        scenePhase == .active
    }

    // MARK: Faces and the board's Now

    /// Home 236: what the faces draw this minute. The weather is the device's sample until Core's source is allowed;
    /// the workout is only whether one is going, its length and its rest; Now is the board's own latest line.
    func updateFaces(backdrop: MosaicBackdrop, read: MosaicFacts, at now: Date) {
        guard let model else { return }
        let phase = MosaicScenePicker.phase(read)
        let pick = MosaicScenePicker.pick(backdrop, facts: read, place: nil, weather: nil)
        gallery = MosaicGallery.sequence(backdrop: backdrop, pick: pick, phase: phase)
        let workout = model.session.flatMap { session -> MosaicWorkoutReading? in
            guard session.finishedAt == nil else { return nil }
            return MosaicWorkoutReading(startedAt: session.startedAt, restEndsAt: session.restEndsAt,
                                        restTotal: session.restTotal)
        }
        faces.update(
            MosaicFaceInputs(scenery: gallery.first, announcement: announcement,
                             weather: SampleWeatherSource().reading(now: now), workout: workout),
            sequence: gallery, on: { MosaicFaceStack.isOn($0) }, now: now
        )
    }

    /// The board turned to a line: Now plays it. A line with no drawing (Notes, Money) leaves Now empty.
    func announce(_ notice: HomeNotice?) {
        guard let model else { return }
        let next = notice.flatMap(MosaicNowKind.of).map { MosaicNowReading(kind: $0.kind, opens: $0.opens) }
        guard next != announcement else { return }
        announcement = next
        if let facts {
            updateFaces(backdrop: model.settingsAreReal ? SettingsStore(engine: model.engine).read().backdrop
                : .tessPicks, read: facts, at: AppClock.now)
        }
    }

    private static let backShownKey = "homeMosaic.backShown"

    /// Asks Core's picker what the day looks like now; "Welcome back" shows once per absence.
    func refreshPick() {
        guard let model else { return }
        let at = AppClock.now
        let routinesPart = HomeSentence.RoutinesPart.make(engine: model.engine, now: at)
        let read = MosaicFacts.make(engine: model.engine, now: at)
        things = HomeThings.make(model: model, facts: read, routines: routinesPart)
        let backdrop = model.settingsAreReal ? SettingsStore(engine: model.engine).read().backdrop : .tessPicks
        scenery = facts.flatMap { MosaicScenePicker.pick(backdrop, facts: $0, place: nil, weather: nil) }
        updateFaces(backdrop: backdrop, read: read, at: at)
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

    // MARK: Moments

    /// Sheet 201: asks Core whether a moment is ready, and plays it. What has played and when stay in memory only.
    func playMoment(_ facts: MosaicFacts) {
        guard let model, HomeMosaic.momentsIsOn, moment == nil, onScreen, active else { return }
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
                self.momentClause = nil
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
        endLater(played)
    }

    /// Sheet 206: the apps list settled on an app, so the mosaic plays that app's glance.
    func playGlance(_ app: HomeApp) {
        guard layerOn, active else { return }
        if let moment, case .glance = moment.moment {} else if moment != nil {
            return
        }
        let played = MosaicMomentEvent(.glance(app: app))
        moment = played
        endLater(played)
    }

    private func endLater(_ played: MosaicMomentEvent) {
        momentTask?.cancel()
        momentTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(played.moment.duration))
            guard !Task.isCancelled, self.moment?.id == played.id else { return }
            self.endMoment()
        }
    }

    /// The moment is over (its time, a mood change, or leaving Home): the sentence turns back to the mood's lines.
    func endMoment() {
        momentTask?.cancel()
        momentTask = nil
        if moment != nil {
            moment = nil
        }
        if momentClause != nil {
            momentClause = nil
        }
    }

    /// "Sunset": the mosaic washes to dusk, holds for five seconds, and comes back.
    func playDusk() {
        guard layerOn, active else { return }
        dusk = true
        duskTask?.cancel()
        duskTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self.dusk = false
        }
    }

    // MARK: The one thing

    /// The hold finished a task: the op lands, the one Undo line speaks its shown label, and the next thing comes in.
    func finishThing(_ thing: HomeThing) -> Bool {
        guard let model, let id = thing.taskID,
              let record = try? model.engine.perform(SetTaskDone(task: id, done: true), by: .user).record
        else { return false }
        MomentMemory.handDoneAt = AppClock.now
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(thing.undoLine ?? "Done", undo: record, holds: .seconds(5))
        return true
    }

    /// Sheet 213: the sign for the thing now showing, in its accent. A task's accent is ink, so it does not wash.
    var signSpec: MosaicSignSpec? {
        guard things.indices.contains(thingIndex) else { return nil }
        let thing = things[thingIndex]
        let alt: Color? = thing.accent == .birthday ? Color(light: 0xB0466A, dark: 0xE07A9A) : nil
        return MosaicSignSpec(kind: ThingSignKind(thing.kind), accent: thing.accentColor, alt: alt,
                              washes: thing.accent != .ink, slot: signSlot, token: thing.id)
    }

    /// A swipe on the space: the next thing (left) or the previous (right), wrapping; whether the page turned.
    func turnThing(_ dx: CGFloat) -> Bool {
        guard let step = OneThingSwipe.step(index: thingIndex, count: things.count, dx: dx) else { return false }
        thingIndex = step.entering
        return true
    }

    /// A tap goes to the thing's own target: its object, its app's room, Today, or the weather.
    func openThing(_ thing: HomeThing) {
        switch thing.target {
        case let .object(id):
            model?.path.append(Route.object(id))
        case let .room(app):
            present(Self.link(for: app))
        case .today, .weather:
            present(.today)
        }
    }

    // MARK: Opening rooms

    /// The mosaic's centre in global points, where a doorway starts when no word was tapped.
    var mosaicCentre: CGPoint {
        let size = HomeMosaic.moodsMosaicSize
        return CGPoint(x: pageWidth - HomeMosaic.gutter - size.width / 2,
                       y: scrollMinY - scroll.value + coreTop + size.height / 2)
    }

    /// A word was tapped: the doorway starts from its centre.
    func doorwayFrom(_ frame: CGRect, _ open: () -> Void) {
        doorwayOrigin = CGPoint(x: frame.midX, y: frame.midY)
        open()
    }

    static func link(for app: AppID) -> HomeLink {
        switch HomeApp(appID: app) {
        case .kitchen: .recipes
        case .money: .money
        case .notes: .notes
        case .lists: .lists
        case .training: .training
        default: .review
        }
    }

    /// A room word on the board: Galley opens its landing as a door; the rest open their link.
    func openRoomWord(_ app: AppID) {
        if LandingSwitch.isOn, HomeApp(appID: app) == .kitchen {
            if openDoorInShell?(.app(.kitchen)) == true {
                return
            }
            roomDoor = .app(.kitchen)
        } else {
            present(Self.link(for: app))
        }
    }

    /// Opens a room: the standing shell takes it when it can (its places change in place); else the doorway plays
    /// from the tapped word, or the mosaic's centre, into the room's own page.
    func present(_ target: HomeLink) {
        if openInShell?(target) == true {
            doorwayOrigin = nil
            return
        }
        guard let model else { return }
        model.doorway.play(from: doorwayOrigin ?? mosaicCentre, accent: Self.doorwayAccent(target), reverse: false,
                           reduceMotion: reduceMotion, navigate: { Self.withoutAnimation { self.link = target } })
        doorwayOrigin = nil
    }

    /// "Close" or the edge: the doorway back into the mosaic.
    func dismissLink() {
        guard let model else { return }
        let accent = link.map(Self.doorwayAccent) ?? Theme.Colors.ink
        model.doorway.play(from: mosaicCentre, accent: accent, reverse: true, reduceMotion: reduceMotion,
                           navigate: { Self.withoutAnimation { self.link = nil } })
    }

    static func doorwayAccent(_ target: HomeLink) -> Color {
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

    static func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }

    // MARK: Tess

    /// Hold: her layer opens at once and she listens, on this phone only, until he lets go.
    func holdBegan() {
        guard layerOn, active else { return }
        if !tessOpen {
            tessTapped()
        }
        tessHolding = true
        tessModel.stateLine = "Listening. Slide left to let it go"
        listener.onFinish = { [weak self] text in
            if let text {
                self?.tessSpoke(text)
            }
        }
        Task {
            if let refusal = await listener.start(hold: true) {
                tessHolding = false
                tessModel.stateLine = refusal.line
            }
        }
    }

    func holdEnded(cancelled: Bool) {
        guard tessHolding else { return }
        tessHolding = false
        tessVoice = 0
        listener.stop(send: !cancelled)
        tessModel.liveSpeech = ""
        tessModel.stateLine = ""
    }

    func tessSpoke(_ text: String) {
        tessModel.hear(text)
        tessHeard(text)
    }

    /// Double tap: quiet for an hour (a tap wakes her).
    func tessQuiet() {
        if tessModel.isQuiet() {
            tessModel.wake()
        } else {
            tessModel.quietForAnHour()
        }
    }

    /// Swipe up: her room, from her corner.
    func openRoom() {
        guard let model else { return }
        roomEntries = TessRoomLog.today(engine: model.engine, now: AppClock.now)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: false) { roomOpen = true }
    }

    /// A tap on her: opens her layer (closes it if it is open).
    func tessTapped() {
        guard let model, layerOn, active else { return }
        if tessOpen {
            closeTess()
        } else {
            tessModel.open(engine: model.engine, classes: model.classes, facts: facts)
            tessOpen = true
        }
    }

    func closeTess() {
        tessModel.close()
        tessOpen = false
    }

    /// What she says to a reply he picked (the phone's own answers; nothing leaves the phone here).
    func tessAnswer(_ reply: String) -> String? {
        switch reply {
        case "Show me": "Here it is"
        default: "Okay"
        }
    }

    /// Typed words: she answers on the phone, with one plain reply to end it.
    func tessHeard(_ text: String) {
        guard let model else { return }
        Task {
            let line = await model.ask(text)
            tessModel.say(line.isEmpty ? "Got it" : line, names: [],
                          answeredBy: TessLayerModel.AnswerSource(model.lastAnswerSource,
                                                                  keyPresent: model.claudeKeyPresent,
                                                                  failure: model.claudeFailure))
            tessModel.offer(["That's all"])
        }
    }

    // MARK: Coming and going

    func phaseChanged(_ phase: ScenePhase) {
        scenePhase = phase
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

    /// The faces turn on the line clock, a few times a second to keep time, never under a touch.
    func tickFaces() {
        let now = AppClock.now
        faces.tick(now: now, environment: .init(
            reduceMotion: reduceMotion, lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
            quiet: MosaicMomentMapping.isQuiet(now), turnsByItself: HomeMosaic.facesTurnByThemselves,
            paused: !active || link != nil || moment != nil || tessOpen || !onScreen
        ))
    }
}

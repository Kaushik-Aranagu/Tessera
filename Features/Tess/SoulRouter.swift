import Foundation
import Observation
import TesseraCore

/// What happened, from the views' side (docs/design/motion/tess-motion.md §14). Views emit events; they never set
/// her mode.
enum SoulEvent: Equatable {
    /// The surface closes, a line fades, the app comes forward: idle, or resting 23:00 to 06:00.
    case appeared, closed
    /// A line from a face, a notification or the 04:00 roll: idle (the glance arrives with the eyes).
    case returnLine
    /// Tap her, or another screen opens her with a draft.
    case tessOpened
    case draft(isEmpty: Bool)
    /// The ghost dries, or Speak heard words: local grammar.
    case sent, heard
    case dryCancelled
    /// A local capture landed: idle and a brighten, never Done at rest.
    case committed
    /// Her line was said beside her: back to rest 4 s later if the surface is closed.
    case lineShown
    /// A Claude call, Plan my day, a link fetch, a photo read.
    case askClaude, claudeDone, claudeFailed
    case speak(hold: Bool), heardNothing
    /// The workout (page .live).
    case setLogged, newBest, liveAsk, liveAnswered, swapped, topSetAccepted, workoutGathered
    /// The double tap: Done, the flood, idle after it (about 1.1 s under Reduce Motion).
    case goHome(reduceMotion: Bool)
    /// One-ask (a set-count or a dated-lift ask beside her): it owns the page while it waits.
    case askWaiting, askAnswered
    /// The glass-tab lens (§15): she is pinned to the dock while it is held.
    case lensHeld, lensReleased
    /// Stroke her (idea 3): a band pan's finger comes onto her, leaves her, and the pan ends (a stroke or not).
    case strokeEntered, strokeLeft
    case strokeEnded(isStroke: Bool)
    /// One part of a thing ticked (a task, a habit, a grocery row: soul-signals.md): the beat at 520 ms, as the
    /// fleck lands, and +0.10 of colour for the day (idea 4). `taskUndone` takes one back inside its UNDO window.
    case taskDone, taskUndone
    /// Dones that happened while he wasn't looking (Siri, a widget): one beat at once, for the lot.
    case doneElsewhere
    case backgrounded
    /// The app comes forward. `underLive`: a live workout is on top (his moment wins, so no wake).
    case foregrounded(underLive: Bool)
    /// The live workout came up over Home (QA R1 on #558): a wake still playing gives way to it.
    case liveOpened
    /// She watches what he holds (idea 6): a row of a reorderable list is lifted, moved (its centre's global y) and
    /// dropped.
    case rowLifted(y: CGFloat), rowMoved(y: CGFloat), rowDropped
    /// A nudge before the next thing (idea 7): Core's scheduler, ten minutes before a timed item. `row` is its row's
    /// centre on screen (global), nil when the row isn't on screen (then nothing happens: it's not a notification).
    case upcoming(id: String, row: CGPoint?)
    /// She hears him type (idea 8): a space or punctuation after a letter, while she listens.
    case wordTyped
    /// She peeks at the end of a list (idea 9): the page's scroll reached its last row; once per page visit.
    case reachedEnd(page: String), pageLeft(page: String)
    /// She watches the rest clock (idea 10): the live workout's rest timer is in its last 10 s (at its centre).
    case restEnding(at: CGPoint), restEnded
    /// A side turned (sheet 75): `toward` is +1 into the right side, -1 back to the front.
    case sideTurned(toward: CGFloat)
}

/// The nudge's lean: out toward the row, held, and back.
struct SoulNudge: Equatable {
    var start: Date
    /// A unit vector from her toward the row.
    var direction: CGVector
}

/// Everything a moment adds to how she is drawn that isn't her mode, so the chrome passes one value.
struct SoulOverlays: Equatable {
    var expression = SoulExpression.rest
    var expressionDuration = SoulExpression.transition
    var nudge: SoulNudge?
    var peek: Date?
    var pulse: Date?
    var sleep: SoulSleepLook?
    /// The words the ask touches, as page rects (global), in the job's order.
    var readers: [CGRect] = []
    /// A moment's own blink (a drop, the rest clock's Go, a nudge's end, a peek's top), starting then.
    var blink: Date?
}

/// How her eyes sleep: shut and still, opening one eye at a time, or drifting off again.
enum SoulSleepLook: Equatable {
    case asleep
    case opening(since: Date)
    case drifting(since: Date)
}

/// The one place that turns events into Tess's state, and the only timer for it (§14: "views never set a mode",
/// "the router is the only timer"). Home has one router on `AppModel`; the live workout runs its own with
/// `page = .live`. Working, roam, the beat, repaint, eyes and drag ride on this as their overlays arrive.
@MainActor
@Observable
final class SoulRouter {
    enum Page {
        case home, live
    }

    let page: Page
    private(set) var mode: TessSoul.Mode = .idle
    /// The lens is held: she stays at the dock and nothing of hers travels.
    private(set) var isPinned = false
    /// The brighten after a local capture (900 ms), drawn by the chrome.
    private(set) var isBright = false
    /// She looks at her own line for a second after she speaks (§1).
    private(set) var isLookingAtLine = false
    /// Where her eyes look: at him while she listens, at her line just after she speaks, else ahead.
    var gaze: SoulGaze {
        if mode == .listening {
            return .atHim
        }
        if isStrokeCrossing {
            return .alongStroke
        }
        if let heldRowY {
            return .look(x: -1, y: Self.lookY(forRowAt: heldRowY, from: dockCentre))
        }
        if isWatchingRest {
            return .look(x: -1, y: -1)
        }
        if let nudge, isNudging {
            return .look(x: nudge.direction.dx, y: nudge.direction.dy)
        }
        if peek != nil {
            return .look(x: 0.5, y: -1)
        }
        if let sideGlance {
            return .look(x: sideGlance * 0.4, y: 0)
        }
        if let sleepOpening {
            let glance = SoulSleep.glance(opening: Date.now.timeIntervalSince(sleepOpening))
            if glance != .ahead {
                return glance
            }
        }
        // Thinking and waiting look aside, toward her line (18c).
        return isLookingAtLine || mode == .thinking || isAskWaiting ? .atLine : .ahead
    }

    /// The held row's pull: y clamped to (row y - her y) / 600 (her dock's y, 779 when not yet placed).
    static func lookY(forRowAt rowY: CGFloat, from dock: CGPoint?) -> CGFloat {
        min(max((rowY - (dock?.y ?? 779)) / 600, -1), 1)
    }

    /// The nudge's eyes go to the row while the lean is out, until its last moment.
    private var isNudging: Bool {
        guard let nudge else { return false }
        return Date.now.timeIntervalSince(nudge.start) < SoulMove.lean.duration
    }

    /// The mouth's shape for the moment (18c), derived from the mode plus overlays so no view picks a face.
    var expression: SoulExpression {
        SoulExpression.resolve(.init(mode: mode, isAsleep: isAsleep, isAskWaiting: isAskWaiting,
                                     isSmiling: isSmilingAtLine || beat != nil, isFailed: isFailed,
                                     isLive: page == .live))
    }

    /// Her line's smile relaxes over 600 ms; every other change of shape takes 250 ms.
    var expressionDuration: Double {
        isRelaxing ? SoulExpression.relax : SoulExpression.transition
    }

    /// What the chrome draws on top of her mode.
    var overlays: SoulOverlays {
        SoulOverlays(expression: expression, expressionDuration: expressionDuration, nudge: nudge, peek: peek,
                     pulse: pulse, sleep: sleepLook, readers: touchedWords, blink: momentBlink)
    }

    /// In the quiet hours (23:00 to 07:00), at Home.
    var isQuiet: Bool {
        page == .home && Self.isQuietHour(Calendar.current.component(.hour, from: clock()))
    }

    /// Asleep: quiet hours and he has not opened the app (or has left it alone for a minute).
    var isAsleep: Bool {
        isQuiet && openedAt == nil
    }

    /// When the opening of her eyes began, while it is still going on.
    private var sleepOpening: Date? {
        guard isQuiet, let openedAt else { return nil }
        return Date.now.timeIntervalSince(openedAt) < SoulSleep.opening ? openedAt : nil
    }

    var sleepLook: SoulSleepLook? {
        guard isQuiet else { return nil }
        if let openedAt {
            return Date.now.timeIntervalSince(openedAt) < SoulSleep.opening ? .opening(since: openedAt) : nil
        }
        return driftStart.map { .drifting(since: $0) } ?? .asleep
    }

    /// An ask is waiting beside her (§8): no lens, no roam.
    private(set) var isAskWaiting = false
    /// The capture surface is open (her line's 4 s doesn't return her to rest under it).
    private(set) var isSurfaceOpen = false
    /// How many Done one-shots have played (a second Done inside one becomes a beat when the beat lands).
    private(set) var doneCount = 0

    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var brightTimer: Task<Void, Never>?
    @ObservationIgnored private var lineTimer: Task<Void, Never>?
    @ObservationIgnored private var glanceTimer: Task<Void, Never>?
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var wakeTimer: Task<Void, Never>?
    /// Where "woke on" is kept, so a relaunch the same day doesn't wake her twice.
    @ObservationIgnored private let wakeStore: UserDefaults
    static let wokeOnKey = "tess.wokeOn"

    /// When she began waking with him (idea 2), for `SoulWake.duration`; nil otherwise.
    private(set) var wake: Date?

    /// Where her dock is on screen (her centre, global), so a band pan can tell when it crosses her.
    @ObservationIgnored private(set) var dockCentre: CGPoint?
    /// When the ripple of a stroke began (idea 3, `SoulRipple.duration`), the finger is on her, and the blink after.
    private(set) var stroke: Date?
    private(set) var isStrokeCrossing = false
    private(set) var strokeBlink: Date?
    /// Bumped once per stroke for its one soft tick (a second within the ripple restarts it with no tick).
    private(set) var strokeTicks = 0
    @ObservationIgnored private var strokeTimer: Task<Void, Never>?

    // MARK: Face, sleep and the small moments

    /// Her line was shown (smile for 1.5 s, then it relaxes over 600 ms) and her own failure (1.2 s).
    private(set) var isSmilingAtLine = false
    private(set) var isFailed = false
    private(set) var isRelaxing = false
    /// The row he holds (global y), the rest clock's pull, a side's glance, the nudge and the peek.
    private(set) var heldRowY: CGFloat?
    private(set) var isWatchingRest = false
    private(set) var sideGlance: CGFloat?
    private(set) var nudge: SoulNudge?
    private(set) var peek: Date?
    private(set) var pulse: Date?
    private(set) var pulseCount = 0
    /// A moment's own blink (a drop, the rest clock's Go, a nudge's end, a peek's top), starting then.
    private(set) var momentBlink: Date?
    /// The words the ask touches (page rects, global, in the job's order); stays on the phone.
    private(set) var touchedWords: [CGRect] = []
    /// When he opened the app in the quiet hours (she is awake until she is left alone), and when she began to drift
    /// off.
    private(set) var openedAt: Date?
    private(set) var driftStart: Date?
    @ObservationIgnored private var moments: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var nudged: Set<String> = []
    @ObservationIgnored private var peeked: Set<String> = []
    @ObservationIgnored private var lastPulse: Date?
    @ObservationIgnored private var sleepTimer: Task<Void, Never>?
    @ObservationIgnored private var skippedLaunchOpen = false

    /// When her last beat landed (§6, `SoulBeat.duration`); nil when none is playing.
    private(set) var beat: Date?
    /// A done that arrived while she listened beats when she stops (rule 2).
    @ObservationIgnored private var beatAfterListening = false
    @ObservationIgnored private var beatTimer: Task<Void, Never>?
    /// A beat on its way (a done row's fleck still flying).
    @ObservationIgnored private var nextBeat: Date?
    /// The things he has done today, from 04:00, kept across launches (idea 4).
    private(set) var wearDones = 0
    /// At 04:00 yesterday's wear dries over the first idle minute: from this much, from this moment.
    private(set) var wearFade: (from: CGFloat, start: Date)?
    @ObservationIgnored private var didFreshWear = false
    static let wearDayKey = "tess.wearDay"
    static let wearDonesKey = "tess.wearDones"

    /// Her colour for the day, at `date` (the fade included).
    func wear(at date: Date) -> CGFloat {
        let today = SoulBeat.wear(wearDones)
        guard let wearFade else { return today }
        let left = 1 - min(max(date.timeIntervalSince(wearFade.start) / SoulBeat.wearReset, 0), 1)
        return today + wearFade.from * CGFloat(left)
    }

    init(page: Page = .home, clock: @escaping () -> Date = { AppClock.now }, wakeStore: UserDefaults = .standard) {
        self.page = page
        self.clock = clock
        self.wakeStore = wakeStore
        rollWearDay()
    }

    /// Idle, or resting from 23:00 to 06:00 (as built). The workout's corner always rests at idle.
    var rest: TessSoul.Mode {
        guard page == .home else { return .idle }
        // Quiet hours end at 07:00 (decisions 2:00 PM PT Oct 16, Research EQ32). She sleeps in them until he opens
        // the app; she stays awake while he is in it (idea 5).
        return isAsleep ? .resting : .idle
    }

    /// The whole contract is this one switch (§14's table): one case per event, read top to bottom.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func handle(_ event: SoulEvent) {
        if openedAt != nil, event != .backgrounded {
            scheduleSleep()
        }
        switch event {
        case .closed, .heardNothing:
            isSurfaceOpen = false
            // A Done in flight plays out and returns to rest itself (rule 4); work runs on under a closed surface.
            guard !isDoneInFlight, !isWorking else { return }
            settle(rest)
        case .claudeFailed:
            touchedWords = []
            fail()
            // A failure answers the queued ask too: nothing is left to think about (F4).
            guard !isDoneInFlight else {
                queued = nil
                return
            }
            // No Done for a failure: the lights gather and she rests (§5).
            guard !isWorking else { return gather(thenDone: false) }
            settle(rest)
        case let .foregrounded(underLive):
            rollWearDay()
            wakeIfFirstOpen(quiet: underLive)
            if !underLive {
                openEyesAtNight()
            }
            guard !isDoneInFlight, !isWorking else { return }
            settle(rest)
        case .appeared, .returnLine:
            guard !isDoneInFlight, !isWorking else { return }
            settle(rest)
        case .committed:
            // At rest she's small: Done would multiply her dabs into mud, so she brightens instead (as built).
            isSurfaceOpen = false
            if !isWorking {
                settle(rest)
            }
            brighten()
        case .lineShown:
            smileAtLine()
            isLookingAtLine = true
            glanceTimer?.cancel()
            glanceTimer = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.isLookingAtLine = false
            }
            lineTimer?.cancel()
            lineTimer = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(4))
                // Never under his voice or her thinking (rules 1, 2 and 6), nor over a Done.
                guard !Task.isCancelled, let self, !isSurfaceOpen, !isWorking,
                      mode != .done, mode != .listening, mode != .thinking else { return }
                settle(rest)
            }
        case .tessOpened:
            isSurfaceOpen = true
            settle(.listening)
        case .dryCancelled, .speak:
            // His touch: cuts anything, Done included.
            settle(.listening)
        case let .draft(isEmpty):
            // A draft never interrupts thinking or work (rules 5 and 6).
            guard mode == .listening || mode == .idle || mode == .resting else { return }
            settle(isEmpty ? .idle : .listening)
        case .sent, .heard, .liveAsk:
            // Thinking queues behind a Done in flight (rule 4); work outranks a local thought (rule 5).
            guard !isDoneInFlight else { return queue(.thinking) }
            guard !isWorking else { return }
            settle(.thinking)
        case .askClaude:
            // Working (§5). It queues behind a Done in flight (rule 4); a second ask joins the running one (rule 5).
            // The live workout never works: its corner keeps thinking's pulse.
            guard page == .home else { return settle(.thinking) }
            // A new ask during the gather waits for the lights to land, so they never jump (lab note on #453).
            guard !isDoneInFlight, mode != .gathering else { return queue(.working) }
            guard mode != .working else { return }
            settle(.working)
        case .claudeDone:
            touchedWords = []
            // The lights gather first; Done begins as they land (§5).
            guard !isWorking else { return gather(thenDone: true) }
            playDone()
        case .liveAnswered, .setLogged, .swapped, .topSetAccepted, .workoutGathered:
            playDone()
        case .newBest:
            // Thinking 1.2 s, then Done (as built in the workout).
            settle(.thinking)
            timer = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { return }
                self?.playDone()
            }
        case let .goHome(reduceMotion):
            isSurfaceOpen = false
            // The flood (480 ms, 150 under Reduce Motion), its 60 ms settle, then 900 ms to idle (as built).
            playDone(then: (reduceMotion ? 0.15 : 0.48) + 0.06 + 0.9)
        case .askWaiting:
            isAskWaiting = true
        case .askAnswered:
            isAskWaiting = false
        case .lensHeld:
            // Refused while she listens or an ask waits (§15).
            guard !refusesLens else { return }
            isPinned = true
        case .lensReleased:
            isPinned = false
        case .strokeEntered:
            stroked()
        case .strokeLeft:
            isStrokeCrossing = false
        case .taskDone:
            beat(landingIn: SoulBeat.landing, wears: 1)
        case .doneElsewhere:
            beat(landingIn: 0, wears: 1)
        case .taskUndone:
            rollWearDay()
            setWear(wearDones - 1)
        case let .strokeEnded(isStroke):
            isStrokeCrossing = false
            // One blink lands 50 ms after the finger leaves.
            if isStroke, stroke != nil {
                strokeBlink = Date.now.addingTimeInterval(0.05)
            }
        case .liveOpened:
            wakeTimer?.cancel()
            wake = nil
        case .backgrounded:
            // A Done cut by the background would never end: she goes back to rest (QA L6).
            settle(rest)
        case let .rowLifted(y):
            guard !refusesWatching else { return }
            heldRowY = y
        case let .rowMoved(y):
            guard heldRowY != nil else { return }
            heldRowY = y
        case .rowDropped:
            guard heldRowY != nil else { return }
            heldRowY = nil
            momentBlink = Date.now.addingTimeInterval(0.2)
        case let .upcoming(id, row):
            nudgeToward(id: id, row: row)
        case .wordTyped:
            typed(at: .now)
        case let .reachedEnd(page):
            peekAtEnd(of: page)
        case let .pageLeft(page):
            peeked.remove(page)
        case .restEnding:
            guard page == .live else { return }
            isWatchingRest = true
        case .restEnded:
            guard isWatchingRest else { return }
            isWatchingRest = false
            momentBlink = Date.now.addingTimeInterval(0.1)
        case let .sideTurned(toward):
            // Eyes only: 0.4 toward the incoming content over 380 ms, then ahead over 300. Idle only.
            guard mode == .idle, page == .home, !isAskWaiting else { return }
            sideGlance = toward
            runMoment("side", after: 0.38 + 0.3) { [weak self] in self?.sideGlance = nil }
        }
    }

    /// A word finished: one character added, a space or punctuation, right after a letter or digit.
    static func endsWord(from old: String, to new: String) -> Bool {
        guard new.count == old.count + 1, new.hasPrefix(old), let last = new.last,
              let before = old.last, before.isLetter || before.isNumber else { return false }
        return last.isWhitespace || last.isPunctuation
    }

    /// Working, split into lights, or carried at the dock: she watches nothing (ideas 6 and 10's refusals).
    var refusesWatching: Bool {
        page != .home || isWorking || isPinned
    }

    /// The tilt never moves her while carried, working, listening or on a live page (idea 11).
    var refusesTilt: Bool {
        page != .home || isWorking || isPinned || mode == .listening
    }

    /// The page tells her which words the ask touches, in the job's order (idea 1); they never leave the phone.
    func setTouched(_ words: [CGRect]) {
        touchedWords = words
    }

    private func runMoment(_ key: String, after seconds: Double, _ finish: @escaping @MainActor () -> Void) {
        moments[key]?.cancel()
        moments[key] = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    /// Her line's smile: +1 for 1.5 s, then it relaxes over 600 ms.
    private func smileAtLine() {
        isSmilingAtLine = true
        isRelaxing = false
        runMoment("smile", after: SoulExpression.lineSmile) { [weak self] in
            self?.isSmilingAtLine = false
            self?.isRelaxing = true
            self?.runMoment("relax", after: SoulExpression.relax) { self?.isRelaxing = false }
        }
    }

    /// A miss of her own: the only thing that turns a corner down, for 1.2 s.
    private func fail() {
        isFailed = true
        runMoment("fail", after: SoulExpression.failure) { [weak self] in self?.isFailed = false }
    }

    /// He opened the app at night: the right eye first, the left 2.4 s later; she stays awake until left alone.
    private func openEyesAtNight() {
        // Simulator only, for the sleep clip: the cold launch's own foreground leaves her asleep once.
        if LaunchFlags.has("-asleepAtLaunch"), !skippedLaunchOpen {
            skippedLaunchOpen = true
            return
        }
        guard isQuiet else {
            openedAt = nil
            return
        }
        if openedAt == nil {
            openedAt = .now
            driftStart = nil
        }
        scheduleSleep()
    }

    private func scheduleSleep() {
        sleepTimer?.cancel()
        sleepTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(SoulSleep.idleBeforeSleep))
            guard !Task.isCancelled, let self else { return }
            fallAsleep()
        }
    }

    /// Left alone for a minute: she drifts back to sleep over 3 s.
    func fallAsleep() {
        guard openedAt != nil else { return }
        openedAt = nil
        driftStart = .now
        if mode == .idle {
            settle(rest)
        }
    }

    /// One nudge per item, only when its row is on screen, never in the quiet hours or on a live page.
    private func nudgeToward(id: String, row: CGPoint?) {
        guard page == .home, !isQuiet, !nudged.contains(id), let row, let dock = dockCentre,
              !isWorking, mode != .listening, !isPinned else { return }
        nudged.insert(id)
        let dx = row.x - dock.x, dy = row.y - dock.y
        let length = max(hypot(dx, dy), 0.001)
        let start = Date.now
        nudge = SoulNudge(start: start, direction: CGVector(dx: dx / length, dy: dy / length))
        // The eyes blink once as it ends.
        momentBlink = start.addingTimeInterval(SoulMove.lean.duration - 0.2)
        runMoment("nudge", after: SoulMove.lean.duration) { [weak self] in self?.nudge = nil }
    }

    /// One pulse per word, at most one per 180 ms (400 ms in Low Power), only while she listens.
    func typed(at now: Date) {
        guard mode == .listening else { return }
        let gap = PowerState.isLowPower ? SoulPulse.lowPowerGap : SoulPulse.gap
        if let lastPulse, now.timeIntervalSince(lastPulse) < gap {
            return
        }
        lastPulse = now
        pulse = now
        pulseCount += 1
    }

    /// One peek per page visit.
    private func peekAtEnd(of pageID: String) {
        guard page == .home, !refusesWatching, !isAskWaiting, mode != .listening,
              !peeked.contains(pageID) else { return }
        peeked.insert(pageID)
        let start = Date.now
        peek = start
        momentBlink = start.addingTimeInterval(SoulMove.peek.out)
        runMoment("peek", after: SoulMove.peek.duration) { [weak self] in self?.peek = nil }
    }

    /// The glass-tab lens can't form while she listens, the surface is open or an ask waits (§15).
    var refusesLens: Bool {
        mode == .listening || isSurfaceOpen || isAskWaiting
    }

    private func brighten() {
        isBright = true
        brightTimer?.cancel()
        brightTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            self?.isBright = false
        }
    }

    private var isDoneInFlight: Bool {
        mode == .done
    }

    /// Idea 2: the first foreground of his day (from 04:00) wakes her, once. Under a live workout, in Speak or with
    /// an ask waiting, his moment wins and the day still counts as woken.
    private func wakeIfFirstOpen(quiet: Bool) {
        guard page == .home else { return }
        let now = clock()
        // The wake comes with the first open outside quiet hours (motion lab on #558).
        guard !Self.isQuietHour(Calendar.current.component(.hour, from: now)) else { return }
        let today = TesseraDay().day(of: now)
        // `-freshDay` (simulator only, for recordings): every launch is the first open of the day.
        if !LaunchFlags.has("-freshDay"), let last = wakeStore.object(forKey: Self.wokeOnKey) as? Date, last == today {
            return
        }
        wakeStore.set(today, forKey: Self.wokeOnKey)
        guard !quiet, !isAskWaiting, mode != .listening else { return }
        // Real time, not the (demo-shiftable) clock: the view times the wake against its own frames.
        wake = .now
        wakeTimer?.cancel()
        wakeTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(SoulWake.duration))
            guard !Task.isCancelled else { return }
            self?.wake = nil
        }
    }

    /// 23:00 to 07:00.
    static func isQuietHour(_ hour: Int) -> Bool {
        hour >= 23 || hour < 7
    }

    /// Her centre on screen, from the view that draws her at the dock.
    func placeDock(_ centre: CGPoint) {
        dockCentre = centre
    }

    /// Refused while she works, listens, is held at the dock or an ask waits; the pan is then whatever's under it.
    var refusesStroke: Bool {
        page != .home || isWorking || mode == .listening || isAskWaiting || isPinned
    }

    private func stroked() {
        guard !refusesStroke else { return }
        if stroke == nil {
            strokeTicks += 1
        }
        stroke = .now
        isStrokeCrossing = true
        strokeTimer?.cancel()
        strokeTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(SoulRipple.duration))
            guard !Task.isCancelled, let self else { return }
            stroke = nil
            strokeBlink = nil
        }
    }

    /// Working or gathering home from it.
    var isWorking: Bool {
        mode == .working || mode == .gathering
    }

    /// The gather (820 ms), then Done, or rest for a failure (§5).
    private func gather(thenDone: Bool) {
        guard mode != .gathering else { return }
        timer?.cancel()
        queued = nil
        mode = .gathering
        timer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(SoulWork.gatherDuration))
            guard !Task.isCancelled, let self else { return }
            let next = queued
            if thenDone {
                // Done plays as built; an ask that arrived during the gather starts when it ends.
                playDone()
                queued = next
            } else {
                queued = nil
                mode = next ?? rest
            }
        }
    }

    private var queued: TessSoul.Mode?

    private func queue(_ next: TessSoul.Mode) {
        queued = next
    }

    private func settle(_ next: TessSoul.Mode) {
        timer?.cancel()
        queued = nil
        let wasListening = mode == .listening
        mode = next
        if wasListening, next != .listening, beatAfterListening {
            beatAfterListening = false
            beat(landingIn: 0, wears: 0)
        }
    }

    /// The beat lands `delay` seconds from now, and the day's colour steps up with it. A done while she listens waits
    /// for her to stop (rule 2); two beats inside 940 ms merge into one (rule 7). The wear always counts.
    private func beat(landingIn delay: Double, wears: Int) {
        rollWearDay()
        if mode == .listening {
            beatAfterListening = true
            setWear(wearDones + wears)
            return
        }
        let landing = Date.now.addingTimeInterval(delay)
        if let last = nextBeat ?? beat, abs(landing.timeIntervalSince(last)) < SoulBeat.duration {
            setWear(wearDones + wears)
            return
        }
        nextBeat = landing
        beatTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            beat = landing
            nextBeat = nil
            setWear(wearDones + wears)
            try? await Task.sleep(for: .seconds(SoulBeat.duration))
            guard !Task.isCancelled, beat == landing else { return }
            beat = nil
        }
    }

    private func setWear(_ dones: Int) {
        wearDones = max(dones, 0)
        wakeStore.set(wearDones, forKey: Self.wearDonesKey)
    }

    /// At his 04:00 the count starts over; what she wore dries away over a minute rather than in one step.
    private func rollWearDay() {
        let today = TesseraDay().day(of: clock())
        let day = wakeStore.object(forKey: Self.wearDayKey) as? Date
        // `-freshDay` (simulator only): a launch starts the day plain, for recordings.
        if LaunchFlags.has("-freshDay"), !didFreshWear {
            didFreshWear = true
            wakeStore.set(today, forKey: Self.wearDayKey)
            setWear(0)
            return
        }
        if day == today {
            wearDones = wakeStore.integer(forKey: Self.wearDonesKey)
            return
        }
        let previous = day == nil ? 0 : wakeStore.integer(forKey: Self.wearDonesKey)
        if previous > 0 {
            wearFade = (SoulBeat.wear(previous), .now)
        }
        wakeStore.set(today, forKey: Self.wearDayKey)
        setWear(0)
    }

    /// Done's one-shot (1.8 s), then whatever was queued behind it, else rest.
    private func playDone(then seconds: Double = 1.8) {
        timer?.cancel()
        // A Done answers whatever thinking was queued behind the last one (F4).
        queued = nil
        mode = .done
        doneCount += 1
        timer = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            let next = queued ?? rest
            queued = nil
            mode = next
        }
    }
}

extension SoulRouter {
    /// Simulator only, for recordings and the lab's `compare.sh`: `-soulScript work` plays the lab's think scene on
    /// Home (at rest, the ask 2.4 s after launch, the answer 5.2 s later); `workFail` ends it with a failure instead.
    func runScript() {
        guard let script = LaunchFlags.value(after: "-soulScript") else { return }
        if script == "wear" {
            // The lab's wear clip: five things done, 1.2 s apart, from 0.8 s (after a 2.4 s launch settle).
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2.4 + 0.8))
                for _ in 0 ..< 5 {
                    self?.handle(.taskDone)
                    try? await Task.sleep(for: .seconds(1.2))
                }
            }
            return
        }
        if script != "work", script != "workFail", let steps = Self.demoSteps(script) {
            // The picks' scenes (mouth, nudge, peek, type, readers, rows, side), from 2.4 s after launch.
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2.4))
                for (wait, event) in steps {
                    try? await Task.sleep(for: .seconds(wait))
                    if case let .touched(words) = event {
                        self?.setTouched(words)
                    } else if case let .event(event) = event {
                        self?.handle(event)
                    }
                }
            }
            return
        }
        guard script.hasPrefix("work") else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            self?.handle(.askClaude)
            try? await Task.sleep(for: .seconds(5.2))
            self?.handle(script == "workFail" ? .claudeFailed : .claudeDone)
        }
    }
}

extension SoulRouter {
    enum DemoStep {
        case event(SoulEvent)
        case touched([CGRect])
    }

    /// The scenes for `-soulScript`: (seconds to wait, then what happens).
    static func demoSteps(_ script: String) -> [(Double, DemoStep)]? {
        func at(_ wait: Double, _ event: SoulEvent) -> (Double, DemoStep) {
            (wait, .event(event))
        }
        switch script {
        case "mouth":
            return [at(0.5, .tessOpened), at(2.5, .closed), at(0.5, .sent), at(2.5, .lineShown), at(3, .closed),
                    at(0.5, .askWaiting), at(2.5, .askAnswered), at(0.5, .claudeFailed), at(2, .closed)]
        case "nudge":
            return [at(0.5, .upcoming(id: "demo", row: CGPoint(x: 120, y: 330)))]
        case "peek":
            return [at(0.5, .reachedEnd(page: "demo"))]
        case "type":
            return [at(0.5, .tessOpened)] + (0 ..< 8).map { _ in at(0.22, .wordTyped) }
        case "readers":
            let words = [CGRect(x: 40, y: 330, width: 150, height: 22), CGRect(x: 210, y: 420, width: 120, height: 22),
                         CGRect(x: 60, y: 520, width: 170, height: 22), CGRect(x: 180, y: 610, width: 130, height: 22)]
            return [(0.5, .touched(words)), at(0.1, .askClaude), at(6, .claudeDone)]
        case "rows":
            return [at(0.5, .rowLifted(y: 300)), at(0.8, .rowMoved(y: 420)), at(0.8, .rowMoved(y: 600)),
                    at(0.8, .rowDropped)]
        case "side":
            return [at(0.5, .sideTurned(toward: 1)), at(2, .sideTurned(toward: -1))]
        case "sleep":
            return [at(3, .foregrounded(underLive: false))]
        default:
            return nil
        }
    }
}

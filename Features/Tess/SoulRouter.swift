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
        return isLookingAtLine ? .atLine : .ahead
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
        let hour = Calendar.current.component(.hour, from: clock())
        return hour >= 23 || hour < 6 ? .resting : .idle
    }

    /// The whole contract is this one switch (§14's table): one case per event, read top to bottom.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func handle(_ event: SoulEvent) {
        switch event {
        case .closed, .heardNothing:
            isSurfaceOpen = false
            // A Done in flight plays out and returns to rest itself (rule 4); work runs on under a closed surface.
            guard !isDoneInFlight, !isWorking else { return }
            settle(rest)
        case .claudeFailed:
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
        }
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
        guard script.hasPrefix("work") else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            self?.handle(.askClaude)
            try? await Task.sleep(for: .seconds(5.2))
            self?.handle(script == "workFail" ? .claudeFailed : .claudeDone)
        }
    }
}

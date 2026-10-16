import Foundation
import Observation

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
    case backgrounded, foregrounded
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

    init(page: Page = .home, clock: @escaping () -> Date = { AppClock.now }) {
        self.page = page
        self.clock = clock
    }

    /// Idle, or resting from 23:00 to 06:00 (as built). The workout's corner always rests at idle.
    var rest: TessSoul.Mode {
        guard page == .home else { return .idle }
        let hour = Calendar.current.component(.hour, from: clock())
        return hour >= 23 || hour < 6 ? .resting : .idle
    }

    /// The whole contract is this one switch (§14's table): one case per event, read top to bottom.
    // swiftlint:disable:next cyclomatic_complexity
    func handle(_ event: SoulEvent) {
        switch event {
        case .closed, .heardNothing:
            isSurfaceOpen = false
            // A Done in flight plays out and returns to rest itself (rule 4).
            guard !isDoneInFlight else { return }
            settle(rest)
        case .claudeFailed:
            // A failure answers the queued ask too: nothing is left to think about (F4).
            guard !isDoneInFlight else {
                queued = nil
                return
            }
            settle(rest)
        case .appeared, .returnLine, .foregrounded:
            guard !isDoneInFlight else { return }
            settle(rest)
        case .committed:
            // At rest she's small: Done would multiply her dabs into mud, so she brightens instead (as built).
            isSurfaceOpen = false
            settle(rest)
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
                guard !Task.isCancelled, let self, !isSurfaceOpen,
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
            guard mode == .listening || mode == .idle || mode == .resting else { return }
            settle(isEmpty ? .idle : .listening)
        case .sent, .heard, .liveAsk:
            // Thinking queues behind a Done in flight (rule 4).
            guard !isDoneInFlight else { return queue(.thinking) }
            settle(.thinking)
        case .askClaude:
            // `working` arrives with item 2 of the build sheet; until then the long asks think.
            guard !isDoneInFlight else { return queue(.thinking) }
            settle(.thinking)
        case .claudeDone, .liveAnswered, .setLogged, .swapped, .topSetAccepted, .workoutGathered:
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

    private var queued: TessSoul.Mode?

    private func queue(_ next: TessSoul.Mode) {
        queued = next
    }

    private func settle(_ next: TessSoul.Mode) {
        timer?.cancel()
        queued = nil
        mode = next
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

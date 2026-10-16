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
    /// The double tap: Done, the flood, idle after 900 ms.
    case goHome
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
    /// The capture surface is open (her line's 4 s doesn't return her to rest under it).
    private(set) var isSurfaceOpen = false
    /// How many Done one-shots have played (a second Done inside one becomes a beat when the beat lands).
    private(set) var doneCount = 0

    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var brightTimer: Task<Void, Never>?
    @ObservationIgnored private var lineTimer: Task<Void, Never>?
    @ObservationIgnored private let clock: () -> Date

    init(page: Page = .home, clock: @escaping () -> Date = { AppClock.now }) {
        self.page = page
        self.clock = clock
    }

    /// Idle, or resting from 23:00 to 06:00 (as built).
    var rest: TessSoul.Mode {
        let hour = Calendar.current.component(.hour, from: clock())
        return hour >= 23 || hour < 6 ? .resting : .idle
    }

    func handle(_ event: SoulEvent) {
        switch event {
        case .closed, .heardNothing:
            isSurfaceOpen = false
            settle(rest)
        case .appeared, .returnLine, .claudeFailed, .foregrounded:
            settle(rest)
        case .committed:
            // At rest she's small: Done would multiply her dabs into mud, so she brightens instead (as built).
            isSurfaceOpen = false
            settle(rest)
            brighten()
        case .lineShown:
            lineTimer?.cancel()
            lineTimer = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled, let self, !isSurfaceOpen, mode != .done else { return }
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
        case .goHome:
            playDone(then: 0.9 + 0.54)
        case .lensHeld:
            isPinned = true
        case .lensReleased:
            isPinned = false
        case .backgrounded:
            timer?.cancel()
        }
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

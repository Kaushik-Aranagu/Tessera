import CoreHaptics
import SwiftUI

/// The app's one haptic vocabulary (docs/design/task-reward.md, "The haptics map"). Each case is a moment, and each
/// moment has exactly one haptic. Views play them through `.tesseraFeedback`, never a raw `.sensoryFeedback`, so this
/// map is the code. Nothing scolds: there is no error or warning case.
enum Haptic: Equatable, Sendable {
    /// A task, note, grocery, recipe or habit lands; a plan is kept.
    case made
    /// A task, the hero, a habit check-in, a finished workout, the shop finished, Shutdown complete.
    case done
    /// The done fleck reaches the day stroke at now.
    case fleckReachesNow
    /// A swipe is armed, an ink word writes, an ask is answered, Tess opens, each rep, each weight detent, +15 rest.
    case selection
    /// A row is picked up.
    case pickedUp
    /// Not now: the row moves.
    case notNow
    /// Any UNDO.
    case undo
    /// Listening starts.
    case listening
    /// A set is logged.
    case setLogged
    /// A new best, in place of the set's tap.
    case newBest
    /// Reps meet last time (in place of that step's tick).
    case repsMeetLast
    /// Reps pass last time, once per set.
    case repsBeatLast
    /// The weight reel passes a detent where a 5 kg or heavier plate goes on or off (in place of that tick).
    case plateOnOff
    /// A control reaches its bound, once per push.
    case bound
    /// Rest is up, or a kitchen timer ends, with the app on screen.
    case timeUp
    /// A grocery aisle is cleared.
    case aisleCleared
    /// A look is pinned.
    case pinned

    /// The system feedback for the moment; `nil` for `.done`, which plays the three-beat pattern.
    var feedback: SensoryFeedback? {
        switch self {
        case .made: .impact(flexibility: .soft, intensity: 0.6)
        case .done: nil
        case .fleckReachesNow: .impact(flexibility: .soft, intensity: 0.4)
        case .selection: .selection
        case .pickedUp: .impact(weight: .light, intensity: 0.5)
        case .notNow: .impact(weight: .light)
        case .undo: .decrease
        case .listening: .impact(flexibility: .soft, intensity: 0.5)
        case .setLogged: .impact(flexibility: .rigid)
        case .newBest: .success
        case .repsMeetLast: .impact(weight: .light, intensity: 0.6)
        case .repsBeatLast: .impact(flexibility: .rigid, intensity: 0.8)
        case .plateOnOff: .impact(weight: .light)
        case .bound: .impact(flexibility: .soft, intensity: 0.4)
        case .timeUp: .impact(weight: .heavy, intensity: 0.9)
        case .aisleCleared: .impact(weight: .medium)
        case .pinned: .impact(weight: .medium)
        }
    }
}

/// A haptic waiting to play: bump it with `next(_:)` and the view's `.tesseraFeedback(cue)` plays that moment once.
/// One cue per surface keeps "one haptic per beat": a step that meets last time plays the meet tap, not a tick too.
struct HapticCue: Equatable {
    private(set) var haptic: Haptic = .selection
    private(set) var count = 0

    mutating func play(_ haptic: Haptic) {
        self.haptic = haptic
        count += 1
    }
}

/// Done: three rising transient taps (0, 60 and 130 ms) through Core Haptics; `.success` when the engine can't run.
/// The engine and the pattern are made once and warmed with `prepare()` when a surface that can finish appears, so
/// the first beat isn't late. The engine shuts itself down when idle; `play()` restarts it if it has.
@MainActor
enum DonePattern {
    private static var engine: CHHapticEngine?
    private static var isRunning = false
    private static let events: [(time: TimeInterval, intensity: Float, sharpness: Float)] = [
        (0, 0.45, 0.35), (0.06, 0.65, 0.45), (0.13, 1.0, 0.6),
    ]
    private static let pattern: CHHapticPattern? = try? CHHapticPattern(events: events.map { beat in
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: beat.intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: beat.sharpness),
        ], relativeTime: beat.time)
    }, parameters: [])

    private static var supported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    /// Makes and starts the engine ahead of the moment (asynchronously, so it never holds up a frame).
    static func prepare() {
        guard supported, !isRunning, let engine = try? engine ?? makeEngine() else { return }
        engine.start { @Sendable error in
            let started = error == nil
            Task { @MainActor in isRunning = started }
        }
    }

    /// Plays the pattern; returns false when the caller should fall back to `.success`.
    static func play() -> Bool {
        guard supported, let pattern else { return false }
        do {
            let engine = try engine ?? makeEngine()
            if !isRunning {
                try engine.start()
                isRunning = true
            }
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            engine = nil
            isRunning = false
            return false
        }
    }

    private static func makeEngine() throws -> CHHapticEngine {
        let made = try CHHapticEngine()
        made.isAutoShutdownEnabled = true
        // Core Haptics calls these off the main actor: they must be @Sendable, not main-actor closures.
        made.stoppedHandler = { @Sendable _ in Task { @MainActor in isRunning = false } }
        made.resetHandler = { @Sendable in
            Task { @MainActor in
                engine = nil
                isRunning = false
            }
        }
        engine = made
        return made
    }
}

private struct TesseraFeedbackModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let haptic: (Trigger, Trigger) -> Haptic?
    @State private var system = HapticCue()
    @State private var fallback = 0

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { old, new in
                guard let moment = haptic(old, new) else { return }
                if moment == .done {
                    if !DonePattern.play() {
                        fallback += 1
                    }
                } else {
                    system.play(moment)
                }
            }
            .sensoryFeedback(trigger: system) { _, cue in cue.haptic.feedback }
            .sensoryFeedback(.success, trigger: fallback)
    }
}

extension View {
    /// Plays `haptic` each time `trigger` changes. Use instead of `.sensoryFeedback`.
    func tesseraFeedback(_ haptic: Haptic, trigger: some Equatable) -> some View {
        modifier(TesseraFeedbackModifier(trigger: trigger) { _, _ in haptic })
    }

    /// Plays the moment `haptic` returns for a change of `trigger` (nil plays nothing).
    func tesseraFeedback<T: Equatable>(trigger: T, _ haptic: @escaping (_ old: T, _ new: T) -> Haptic?) -> some View {
        modifier(TesseraFeedbackModifier(trigger: trigger, haptic: haptic))
    }

    /// Plays whatever the cue was last bumped with.
    func tesseraFeedback(_ cue: HapticCue) -> some View {
        modifier(TesseraFeedbackModifier(trigger: cue) { _, new in new.haptic })
    }
}

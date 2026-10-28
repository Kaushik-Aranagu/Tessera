import CoreHaptics
import Foundation

/// The new-best buzz (sheet 336): 6 ms on, 50 off, 6 on, 50 off, 12 on, as three short continuous events. Skipped under
/// Reduce Motion by the caller. Same shape as `DonePattern`: the engine is made once and shuts itself down when idle.
@MainActor
enum BestBuzz {
    /// (start, length) in seconds.
    static let beats: [(time: TimeInterval, length: TimeInterval)] = [(0, 0.006), (0.056, 0.006), (0.112, 0.012)]
    private static var engine: CHHapticEngine?
    private static var isRunning = false

    private static let pattern: CHHapticPattern? = try? CHHapticPattern(events: beats.map { beat in
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7),
        ], relativeTime: beat.time, duration: beat.length)
    }, parameters: [])

    /// Plays the buzz; false when the device can't (the caller keeps the `.newBest` notification haptic instead).
    @discardableResult
    static func play() -> Bool {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let pattern else { return false }
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

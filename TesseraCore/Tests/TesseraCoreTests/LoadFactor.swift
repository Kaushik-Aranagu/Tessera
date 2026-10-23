import Foundation

/// How busy this Mac is right now, for tests that time something (sheet-free: a gate must not fail because other work
/// is running). A fixed amount of plain work is timed five times, the fastest counting, against the same work on an
/// idle Mac in a debug build. 1 when idle; capped at 20, so a real slowdown of the thing under test still shows.
enum LoadFactor {
    /// The calibration loop on an idle Mac in a debug build, in milliseconds.
    static let idleMilliseconds = 250.0
    static let cap = 20.0

    /// The fastest of five timings of the calibration loop, in milliseconds.
    static func measuredMilliseconds() -> Double {
        let clock = ContinuousClock()
        var best = Double.infinity
        for _ in 0 ..< 5 {
            var total = 0
            let took = clock.measure {
                for value in 0 ..< 2_000_000 {
                    total &+= value &* value
                }
            }
            if total == 1 {
                print("")
            } // keeps the loop alive
            best = min(best, Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15)
        }
        return best
    }

    static func current() -> Double {
        min(max(measuredMilliseconds() / idleMilliseconds, 1), cap)
    }
}

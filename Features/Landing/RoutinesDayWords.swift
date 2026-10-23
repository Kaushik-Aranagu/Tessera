import Foundation

/// Routines day v2 (feature 162, Review switch "Routines day"): the top of the landing read as one plain sentence about
/// the day. Pure static functions from facts `RoutinesFront` already holds; nothing here reads the store. Names arrive
/// already masked ("Private routine"), so a private routine is said as it is and never with a time. No streak talk
/// and no word about what was missed.
enum RoutinesDayWords {
    /// The routine that comes next: its (masked) name and, when it has one, its usual start.
    struct Next: Equatable {
        let name: String
        let startMinuteOfDay: Int?
    }

    static let pause = "Pause"
    static let busy = "Busy"

    /// "Morning is running. Night is next, usually 9:50 pm." / "Nothing is running. Night is next." /
    /// "Everything is done today." / "Nothing is set up yet."
    static func sentence(running: String?, next: Next?, total: Int) -> String {
        guard total > 0 else { return "Nothing is set up yet." }
        let head: String
        if let running {
            head = "\(running) is running."
        } else if next == nil {
            return "Everything is done today."
        } else {
            head = "Nothing is running."
        }
        guard let next else { return head }
        return head + " " + nextClause(next)
    }

    /// "Night is next, usually 9:50 pm." (no time before the usual start is known).
    static func nextClause(_ next: Next) -> String {
        guard let minute = next.startMinuteOfDay else { return "\(next.name) is next." }
        return "\(next.name) is next, usually \(RoutinesLandingWords.clock(minute))."
    }
}

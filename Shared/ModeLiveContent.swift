import Foundation

/// The mode on the lock screen (sheet 326), as plain data: the Dynamic Island's word and number, and the Live
/// Activity's
/// three lines. Pure and Codable so it can ride an ActivityKit `ContentState`; every countdown is an end date drawn
/// with
/// `Text(timerInterval:)`, so it runs while the app sleeps.
///
/// Walls: a private workout carries only "Rest", the time and "Private workout". No lift name, weight, rep or set count
/// is ever built into the payload (the strings are never made, rather than made and hidden).
struct ModeLiveContent: Codable, Hashable {
    /// The Dynamic Island's word, in the room's face ("Bench"); "Rest" for a private workout.
    var word: String
    /// Live Activity top line, in the room colour: "Rest, then bench".
    var top: String
    /// Middle line, left: the big thing when it is not a countdown ("185 lb × 5"); empty during a rest.
    var big: String
    /// Middle line, right: the next thing ("185 lb × 5, each side 45 + 25").
    var next: String
    /// Bottom line: one quiet fact ("Done about 7:22").
    var quiet: String
    /// The countdown's end and length (Island right, middle left); nil when nothing is counting.
    var timerEnd: Date?
    var timerTotal: TimeInterval
    var isPrivate: Bool
    /// Sheet 356: the face for when the rest hits 0:00, baked into the payload up front so the widget can switch to it
    /// without the app running (on the timer's end date, or when the content goes stale at that date). A private
    /// workout's carries no lift name and no weight.
    var ended: Ended?

    struct Ended: Codable, Hashable {
        /// The Lock Screen's top line: "Rest done, you're up".
        var top: String
        /// The big word: the lift ("Bench"); "Up" for a private workout.
        var big: String
        /// The set you are up for ("185 lb × 5"); empty for a private workout.
        var next: String
    }

    /// What replaces the clock in the Island once the rest is over.
    static let upWord = "up"

    /// Whether the rest is over: its end date has passed, or the system marked the content stale (which `staleDate`
    /// arranges for the same date, so the face flips with the app asleep).
    func hasEnded(at now: Date, isStale: Bool) -> Bool {
        guard ended != nil else { return false }
        return isStale || (timerEnd.map { $0 <= now } ?? false)
    }

    /// The countdown as a range for `Text(timerInterval:)`.
    var timerInterval: ClosedRange<Date>? {
        timerEnd.map { end in
            let start = end.addingTimeInterval(-max(timerTotal, 1))
            return start ... max(end, start)
        }
    }
}

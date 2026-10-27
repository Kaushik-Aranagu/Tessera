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

    /// The countdown as a range for `Text(timerInterval:)`.
    var timerInterval: ClosedRange<Date>? {
        timerEnd.map { end in
            let start = end.addingTimeInterval(-max(timerTotal, 1))
            return start ... max(end, start)
        }
    }
}

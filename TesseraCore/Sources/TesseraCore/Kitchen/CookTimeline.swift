import Foundation

/// One dish's own timeline from its recipe steps, one lane (the start-minute function of "today's clock", PL-E4):
/// a step takes the length of its timer (the top of a range), two minutes with no timer, and a timer over three hours
/// counts as a fixed ten-minute wait (the rest of it is the oven's, not his). A timed step of five minutes or more is a
/// wait; every other step has his hands on it.
public enum CookTimeline {
    public static let untimedMinutes = 2.0
    public static let longTimerMinutes = 180.0
    public static let longTimerWaitMinutes = 10.0

    /// A step's minutes and whether it is a wait.
    public static func shape(of timers: [ClosedRange<Double>]) -> (minutes: Double, isWait: Bool) {
        guard let longest = timers.map(\.upperBound).max(), longest > 0 else { return (untimedMinutes, false) }
        let minutes = longest > longTimerMinutes ? longTimerWaitMinutes : longest
        return (minutes, minutes >= CookPlan.waitFloor / 60)
    }

    /// The local segments of a recipe's steps, in seconds from the dish's own start.
    public static func local(timers steps: [[ClosedRange<Double>]]) -> [CookPlan.Local] {
        var clock = 0.0
        return steps.enumerated().map { index, timers in
            let shape = shape(of: timers)
            let start = clock
            clock += shape.minutes * 60
            return CookPlan.Local(step: index, start: start, end: clock, kind: shape.isWait ? .wait : .hands)
        }
    }
}

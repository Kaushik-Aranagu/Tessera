import Foundation

/// Shutdown's and the Day log's words (docs/research/shutdown-daylog-copy.md, slots A to F): counts only, past tense,
/// never what didn't happen. Pure: the same inputs always give the same line, so a line can be tested and a past day
/// never changes wording on rescrub. No model call.
public struct ShutdownInputs: Equatable, Sendable {
    public var workouts = 0
    public var cooks = 0
    public var tasks = 0
    public var lists = 0
    public var notes = 0
    /// The day's headline names ("Push day", "carbonara") for the Day log lines.
    public var workoutName: String?
    public var recipeName: String?
    public var sets = 0
    public var bestLift: String?
    public var appsTouched = 0
    public var afterGap = false
    public var firstShutdownEver = false
    public var sleep: String? // "6h40"
    public var meetings = 0
    public var travelDay = false
    /// The titles of what rolls to tomorrow, in order.
    public var rolling: [String] = []
    public var itemsUntouchedSevenDays = 0
    public var tomorrowFirstEvent: (title: String, time: String)?
    /// Late night: opened at or after 23:00, or between 00:00 and 04:00. The attributed weekday is the day it files to.
    public var lateNight = false
    public var pastMidnight = false
    public var attributedWeekday = ""
    public var nextWeekday = ""
    public var wroteTomorrowLine = false
    public var tomorrowLineTime = "8 am"

    public init() {}

    public static func == (lhs: ShutdownInputs, rhs: ShutdownInputs) -> Bool {
        lhs.counted == rhs.counted && lhs.rolling == rhs.rolling && lhs.workoutName == rhs.workoutName
            && lhs.lateNight == rhs.lateNight && lhs.attributedWeekday == rhs.attributedWeekday
    }

    var counted: Int {
        workouts + cooks + tasks + lists + notes
    }

    var busy: Bool {
        counted >= 8 || appsTouched >= 3
    }

    var quiet: Bool {
        (1 ... 2).contains(counted)
    }
}

public enum ShutdownLines {
    /// "4 tasks, 1 workout, cooked once": nonzero counts only, at most 3, in app order (Workouts, Kitchen, Tasks,
    /// Lists, Notes).
    public static func counts(_ inputs: ShutdownInputs) -> String {
        var parts: [String] = []
        if inputs.workouts > 0 {
            parts.append(inputs.workouts == 1 ? "1 workout" : "\(inputs.workouts) workouts")
        }
        if inputs.cooks > 0 {
            parts.append(inputs.cooks == 1 ? "cooked once" : "cooked \(inputs.cooks) times")
        }
        if inputs.tasks > 0 {
            parts.append(inputs.tasks == 1 ? "1 task" : "\(inputs.tasks) tasks")
        }
        if inputs.lists > 0 {
            parts.append(inputs.lists == 1 ? "1 list" : "\(inputs.lists) lists")
        }
        if inputs.notes > 0 {
            parts.append(inputs.notes == 1 ? "1 note" : "\(inputs.notes) notes")
        }
        return parts.prefix(3).joined(separator: ", ")
    }

    /// Slot A, the Day log's Tess line (A1 to A10); nil when nothing shows.
    public static func dayLogLine(_ inputs: ShutdownInputs, todayOnlyBeforeShutdown: Bool = false) -> String? {
        let other = max(inputs.counted - (inputs.workouts > 0 ? 1 : 0) - (inputs.cooks > 0 ? 1 : 0), 0)
        if inputs.afterGap, inputs.counted > 0 {
            let headline = [inputs.workoutName, inputs.recipeName].compactMap(\.self).first ?? counts(inputs)
            return "Back in. \(headline)."
        }
        if let lift = inputs.bestLift {
            let more = inputs.counted - 1
            return more > 0 ? "\(lift) best, plus \(more) more things." : "\(lift) best."
        }
        if inputs.travelDay {
            return "Travel day. \(inputs.counted) things logged on the move."
        }
        if inputs.workouts > 0, inputs.cooks > 0, let workout = inputs.workoutName, let recipe = inputs.recipeName {
            return "\(workout) and \(recipe). Fed and trained."
        }
        if inputs.busy {
            return "Full one. \(inputs.counted) things across \(inputs.appsTouched) apps."
        }
        if inputs.workouts > 0, let workout = inputs.workoutName {
            return other > 0 ? "\(workout), \(inputs.sets) sets. \(other) other things too." : "\(workout), \(inputs.sets) sets."
        }
        if inputs.cooks > 0, let recipe = inputs.recipeName {
            return other > 0 ? "Cooked \(recipe). \(other) more things logged." : "Cooked \(recipe)."
        }
        if inputs.quiet {
            return "Quiet day. \(counts(inputs))."
        }
        if inputs.counted == 0, let sleep = inputs.sleep {
            return "Rest day. Slept \(sleep)."
        }
        if inputs.counted == 0, todayOnlyBeforeShutdown {
            return "Fills itself as you go."
        }
        return nil
    }

    /// Slot B, the Shutdown opener (B1 to B7), or F1 late at night.
    public static func opener(_ inputs: ShutdownInputs) -> String {
        let counted = counts(inputs)
        if inputs.lateNight, inputs.counted > 0 {
            return "Filed under \(inputs.attributedWeekday). Did \(counted)."
        }
        if inputs.afterGap, inputs.counted > 0 {
            return "Back in. Did \(counted) today."
        }
        if let lift = inputs.bestLift, inputs.counted > 0 {
            return "Did \(counted). Plus a best on \(lift)."
        }
        if inputs.busy {
            return "\(inputs.counted) things done. Full day."
        }
        if inputs.counted >= 2 {
            return "Did \(counted)."
        }
        if inputs.counted == 1 {
            let name = inputs.workoutName ?? inputs.recipeName
            return name.map { "\($0), done. That counts." } ?? "Did \(counted)."
        }
        if inputs.meetings > 0 || inputs.sleep != nil {
            var parts: [String] = []
            if inputs.meetings > 0 {
                parts.append("\(inputs.meetings) meetings")
            }
            if let sleep = inputs.sleep {
                parts.append(parts.isEmpty ? "Slept \(sleep)" : "slept \(sleep)")
            }
            let lead = parts.joined(separator: ", ")
            return parts.count == 1 && inputs.meetings == 0 ? "\(lead). That was the day."
                : "\(lead.prefix(1).uppercased() + lead.dropFirst()). That was the day."
        }
        return "A quiet one. Want a line for tomorrow?"
    }

    /// Slot C, the carry-over line (C1 to C4), or F2 past midnight. Nil when nothing rolls.
    public static func carryOver(_ inputs: ShutdownInputs) -> String? {
        let count = inputs.rolling.count
        guard count > 0 else { return nil }
        if inputs.pastMidnight {
            return "\(count) moving to \(inputs.nextWeekday). Tap any for later."
        }
        if inputs.firstShutdownEver {
            return "\(count) moving to tomorrow. Tap any for later."
        }
        if count >= 6 {
            return "\(count) rolling over. Plan my day picks up to 3."
        }
        if count == 1 {
            let task = inputs.rolling[0]
            return task.split(separator: " ").count > 4 ? "1 moving to tomorrow. Tap to keep it."
                : "\(task) moves to tomorrow. Tap to keep it."
        }
        return "\(count) moving to tomorrow. Tap any for later."
    }

    /// Slot C's own small line for items untouched for 7 days or more (C1).
    public static func autoAge(_ inputs: ShutdownInputs) -> String? {
        inputs.itemsUntouchedSevenDays > 0
            ? "\(inputs.itemsUntouchedSevenDays) going to Later. Still there, just quieter." : nil
    }

    /// Slot D, the placeholder for tomorrow's line (D1, D2); empty on a day B7 already offered it.
    public static func tomorrowPlaceholder(_ inputs: ShutdownInputs) -> String {
        if let event = inputs.tomorrowFirstEvent {
            return "Tomorrow starts with \(event.title) at \(event.time)."
        }
        let offeredAlready = inputs.counted == 0 && inputs.meetings == 0 && inputs.sleep == nil
        return offeredAlready ? "" : "One line for tomorrow, if you want."
    }

    /// Slot E, the close (E1 to E5), or F3 and F4 late at night.
    public static func close(_ inputs: ShutdownInputs) -> String {
        if inputs.lateNight {
            return inputs.workouts > 0 ? "Closed. Sleep is also training."
                : "Saved to \(inputs.attributedWeekday). Pick up tomorrow."
        }
        if inputs.afterGap {
            return "Closed. Tomorrow picks up from here."
        }
        if let lift = inputs.bestLift {
            return "Closed. \(lift) best filed under \(inputs.attributedWeekday)."
        }
        if inputs.wroteTomorrowLine {
            return "Closed. Your line is waiting at \(inputs.tomorrowLineTime)."
        }
        if inputs.counted > 0 {
            return "Closed. \(inputs.counted) things in \(inputs.attributedWeekday)'s log."
        }
        return "Day closed. Nothing waiting tonight."
    }
}

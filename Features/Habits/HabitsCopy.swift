import Foundation

/// Habits' words (sheet 85, habits-85.md; builder-briefs-81-88.md), as a pure formatter for when Core's Habit
/// engine lands. The walls hold everywhere, the side included: no streak or run length, no "missed", no percentage,
/// no sentence about a gap, and a zero never reads as a shortfall.
enum HabitsCopy {
    /// The count at the right: "3 of 5"; at zero the target, "5 a week" (never "0 of 5").
    static func count(done: Int, target: Int) -> String {
        done > 0 ? "\(done) of \(target)" : "\(target) a week"
    }

    /// Made: "Read added, 5 times a week." (UNDO 4 s).
    static func added(_ name: String, target: Int) -> String {
        "\(name) added, \(target) time\(target == 1 ? "" : "s") a week"
    }

    /// A check-in, and Tess's line on both stops of the side: "Read, 3 of 5 this week."; at zero (an UNDO back to
    /// none) the target, "Read, 5 a week." (never "0 of", QA on #753).
    static func checkIn(_ name: String, done: Int, target: Int) -> String {
        done > 0 ? "\(name), \(done) of \(target) this week" : "\(name), \(target) a week"
    }

    /// A second swipe the same day: nothing happens, and she says so.
    static func alreadyIn(_ name: String) -> String {
        "\(name) is already in for today"
    }

    /// A long list: up to two names, "Read and Stretch are done for the week."; one is "Read is done for the week.";
    /// three or more, "Read, Stretch and 2 more are done for the week." Nil when none are.
    static func doneForWeek(_ names: [String]) -> String? {
        switch names.count {
        case 0: nil
        case 1: "\(names[0]) is done for the week"
        case 2: "\(names[0]) and \(names[1]) are done for the week"
        default: "\(names[0]), \(names[1]) and \(names.count - 2) more are done for the week"
        }
    }

    /// The empty front.
    static let empty = "No habits yet"
    /// The empty side.
    static let emptySide = "Nothing to look back on yet"

    /// The front's context line: "Thursday, 3 days to go"; on Monday, "Monday, a new week". `daysLeft` counts the
    /// days after today in the week (Monday to Sunday).
    static func context(weekday: String, daysLeft: Int) -> String {
        if weekday == "Monday", daysLeft == 6 {
            return "Monday, a new week"
        }
        switch daysLeft {
        // Design, Oct 17: "Sunday, the last day" and "Saturday, 1 day to go".
        case 0: return "\(weekday), the last day"
        case 1: return "\(weekday), 1 day to go"
        default: return "\(weekday), \(daysLeft) days to go"
        }
    }

    /// HOW IT COUNTS: "5 a week, by hand" / "3 a week, workouts".
    static func rule(target: Int, source: String) -> String {
        "\(target) a week, \(source)"
    }

    /// HOW IT COUNTS, THE WEEK (no "at" before a time).
    static let weekLines = [
        "A week runs Monday to Sunday",
        "A day starts 4 am",
        "Going past the number keeps counting",
    ]

    /// VoiceOver for a row: "Read, 3 of 5 this week, marked today"; a zero one "Meditate, 4 a week, nothing marked
    /// yet".
    static func voiceOver(_ name: String, done: Int, target: Int, markedToday: Bool) -> String {
        guard done > 0 else { return "\(name), \(target) a week, nothing marked yet" }
        return "\(name), \(done) of \(target) this week" + (markedToday ? ", marked today" : "")
    }

    /// Words no Habits line may ever carry (the walls): a score, a shortfall or a gap.
    static let walled = ["streak", "missed", "miss", "%", "percent", "behind", "in a row", "skipped", "failed", "0 of"]
}

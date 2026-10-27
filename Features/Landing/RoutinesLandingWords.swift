import Foundation
import TesseraCore

/// The Routines landing's words (design 131 section 2 and 2c; product/routines-landing-build-sheet-oct22.md section
/// 2): computed on the phone from fixed templates, from numbers and names this file is handed. Nothing here reads the
/// store or sends anything anywhere. The usual start and length counts come from Core's `RoutineUsual`; this file
/// only words them. If Core adds the same templates to `LandingSentences`, these shrink to calls into it.
enum RoutinesLandingWords {
    static let browse = "Browse"
    static let newRoutine = "New routine"
    static let pickUp = "Pick up"
    static let privateName = "Private routine"
    static let privateStep = "Private step"

    // MARK: Frame

    /// "Nothing set up yet." / "1 routine." / "3 routines." / "3 routines, 1 done today." / "All done today."
    static func subtitle(total: Int, doneToday: Int) -> String {
        guard total > 0 else { return "Nothing set up yet" }
        if doneToday >= total {
            return "All done today"
        }
        if doneToday > 0 {
            return "\(total) \(total == 1 ? "routine" : "routines"), \(doneToday) done today"
        }
        return "\(total) \(total == 1 ? "routine" : "routines")"
    }

    // MARK: The top

    static let nothingRunning = "Nothing is running"
    static let everythingDone = "Everything is done today"

    static func start(_ name: String) -> String {
        "Start \(name)"
    }

    // MARK: Lines

    /// "5 exercises" for a workout routine, "6 steps" for any other.
    static func countWords(_ count: Int, workout: Bool) -> String {
        let noun = workout ? "exercise" : "step"
        return "\(count) \(count == 1 ? noun : noun + "s")"
    }

    /// "Push A, 5 exercises" (fewer than seven finished runs).
    static func stepsLine(name: String, count: Int, workout: Bool) -> String {
        "\(name), \(countWords(count, workout: workout))"
    }

    /// "Morning, 14 days, usually 6:40, 22 min" (seven or more runs). Nothing here counts a streak or a miss.
    static func usualLine(name: String, days: Int, startMinuteOfDay: Int, lengthMinutes: Int) -> String {
        "\(name), \(days) \(days == 1 ? "day" : "days"), usually \(clock(startMinuteOfDay)), "
            + HouseTime.minutes(lengthMinutes)
    }

    /// "Morning, done at 6:58"; skipped steps change nothing.
    static func doneLine(name: String, at date: Date, calendar: Calendar = .current) -> String {
        "\(name), done at \(clock(minuteOfDay(date, calendar: calendar)))"
    }

    /// The rail row's plain value on the right: "14 days, usually 6:40, 22 min" or "6 steps".
    static func railValue(days: Int?, startMinuteOfDay: Int?, lengthMinutes: Int?, count: Int,
                          workout: Bool) -> String
    {
        guard let days, let startMinuteOfDay, let lengthMinutes else { return countWords(count, workout: workout) }
        return "\(days) \(days == 1 ? "day" : "days"), usually \(clock(startMinuteOfDay)), "
            + HouseTime.minutes(lengthMinutes)
    }

    /// Read aloud: "Morning. Ran 14 of the last 30 days. Usually starts 6:40. Usually 22 minutes."
    static func spokenLine(name: String, days: Int, startMinuteOfDay: Int, lengthMinutes: Int) -> String {
        "\(name). Ran \(days) of the last 30 days. Usually starts \(clock(startMinuteOfDay)). "
            + "Usually \(lengthMinutes == 1 ? "1 minute" : "\(lengthMinutes) minutes")"
    }

    /// "Morning is running. Step: Shoes on. 4 minutes on this step."
    static func spokenTop(name: String, step: String, onStep: String) -> String {
        "\(name) is running. Step: \(step). \(onStep)"
    }

    // MARK: Time

    /// "6:40" before noon, "6:40 pm" from noon; the first hour after midnight reads "12:10 am".
    static func clock(_ minuteOfDay: Int) -> String {
        let minute = ((minuteOfDay % 1440) + 1440) % 1440
        let hour = minute / 60, rest = minute % 60
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        let time = "\(twelve):" + String(format: "%02d", rest)
        if hour >= 12 {
            return time + " pm"
        }
        return hour == 0 ? time + " am" : time
    }

    static func minuteOfDay(_ date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    // MARK: Places on the rail

    /// What an empty place says when it is focused (no button; writing is the foot word).
    static func nothingIn(_ place: RoutinePlace) -> String {
        switch place {
        case .today: "Nothing left today"
        case .morning: "Nothing in the morning yet"
        case .midday: "Nothing at midday yet"
        case .evening: "Nothing in the evening yet"
        case .night: "Nothing at night yet"
        case .anyTime: "Nothing here yet"
        }
    }
}

/// The rail's places: Today is pinned above the loop; the rest are the dial, by the time of day a routine usually
/// starts (Any time holds routines with no usual start yet).
enum RoutinePlace: String, CaseIterable, Identifiable, Sendable {
    case today = "Today"
    case morning = "Morning"
    case midday = "Midday"
    case evening = "Evening"
    case night = "Night"
    case anyTime = "Any time"

    var id: String {
        rawValue
    }

    static let dial: [RoutinePlace] = [.morning, .midday, .evening, .night, .anyTime]

    /// The place a usual start falls in: morning 4:00 to 10:59, midday 11:00 to 15:59, evening 16:00 to 20:59, night
    /// after that until 4:00. No usual start is Any time.
    static func of(startMinuteOfDay minute: Int?) -> RoutinePlace {
        guard let minute else { return .anyTime }
        switch ((minute % 1440) + 1440) % 1440 {
        case 4 * 60 ..< 11 * 60: return .morning
        case 11 * 60 ..< 16 * 60: return .midday
        case 16 * 60 ..< 21 * 60: return .evening
        default: return .night
        }
    }
}

/// The rail's knob: Kind. All is the default and is remembered. A routine may sit in All and in its kind.
enum BrowseKind: String, CaseIterable, Sendable {
    case all = "All"
    case daily = "Daily"
    case workouts = "Workouts"

    var next: BrowseKind {
        let all = Self.allCases
        return all[((all.firstIndex(of: self) ?? 0) + 1) % all.count]
    }

    var previous: BrowseKind {
        let all = Self.allCases
        return all[((all.firstIndex(of: self) ?? 0) + all.count - 1) % all.count]
    }
}

import Foundation

/// The You page's words (Design 108 section 3 and its mockup `long-press-and-you-108.png`): four sentences with the
/// values as words, then what the app knows of his training, in the same plain voice. No em-dashes, no streaks.
enum MeCopy {
    static let eyebrow = "kept on this phone"
    static let title = "You"
    static let door = "You"
    static let doorHint = "Your weight, height, age and training"

    // MARK: The four sentences

    /// The weight's value word: hidden until he taps it, the weigh-in once shown, "not logged" with none.
    static func weightWord(_ kilograms: Double?, shown: Bool, format: (Double) -> String = Format.mass) -> String {
        guard let kilograms else { return "not logged" }
        return shown ? format(kilograms) : "hidden"
    }

    /// What follows the weight word: ", from your last weigh-in." or a plain stop with none.
    static func weightTail(_ kilograms: Double?) -> String {
        kilograms == nil ? "." : ", from your last weigh-in."
    }

    /// Height, age and sex have no place to be kept yet (a phone-only profile store is Core's to add).
    static let notSaid = "not said"
    static let unsaidFields = ["Height", "Age", "Sex"]

    static let keptLine = "Used for one thing: an estimate of the calories a workout burns. That stays on this phone "
        + "and never goes to Claude."

    static let weightShowHint = "Shows your last weigh-in"
    static let weightHideHint = "Hides it again"

    // MARK: Training

    /// "142 workouts since March 2025.", "1 workout, in March 2025.", "No workouts logged yet."
    static func workouts(_ count: Int, since first: Date?, calendar: Calendar = .current) -> String {
        guard count > 0 else { return "No workouts logged yet." }
        let month = first.map { monthYear($0, calendar: calendar) }
        if count == 1 {
            return month.map { "1 workout, in \($0)." } ?? "1 workout."
        }
        let number = count.formatted(.number)
        return month.map { "\(number) workouts since \($0)." } ?? "\(number) workouts."
    }

    /// "1,860 working sets." / "1 working set."; nothing at zero.
    static func sets(_ count: Int) -> String? {
        guard count > 0 else { return nil }
        return count == 1 ? "1 working set." : "\(count.formatted(.number)) working sets."
    }

    /// How he trains, from the plan's rhythm: "Trains 4 days a week." Nil without one.
    static func rhythm(_ perWeek: Int?) -> String? {
        guard let perWeek, perWeek > 0 else { return nil }
        return perWeek == 1 ? "Trains 1 day a week." : "Trains \(perWeek) days a week."
    }

    // MARK: Bests

    /// How many lifts show before the rest are paged in.
    static let bestsShown = 5

    /// Most-trained first, then by name, so the list never shuffles between visits.
    static func ordered(_ bests: [MeFacts.Best]) -> [MeFacts.Best] {
        bests.sorted { lhs, rhs in
            lhs.sessions != rhs.sessions ? lhs.sessions > rhs.sessions
                : lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    /// "48 sessions".
    static func sessions(_ count: Int) -> String {
        count == 1 ? "1 session" : "\(count.formatted(.number)) sessions"
    }

    /// The trailing best: "e1RM 102.5 kg", or the session count for a lift with no estimate (bodyweight work).
    static func bestTrailing(_ best: MeFacts.Best, format: (Double) -> String = Format.mass) -> String {
        guard let e1RM = best.bestE1RM, e1RM > 0 else { return sessions(best.sessions) }
        return "e1RM \(format((e1RM * 10).rounded() / 10))"
    }

    /// VoiceOver for a best row: "Bench Press, best estimated one-rep max 102.5 kg, 48 sessions".
    static func bestSpoken(_ best: MeFacts.Best, format: (Double) -> String = Format.mass) -> String {
        guard let e1RM = best.bestE1RM, e1RM > 0 else { return "\(best.name), \(sessions(best.sessions))" }
        return "\(best.name), best estimated one-rep max \(format((e1RM * 10).rounded() / 10)), "
            + sessions(best.sessions)
    }

    /// The reveal word under the first five: "All 14" or "Fewer". Nil when everything already shows.
    static func moreWord(total: Int, expanded: Bool) -> String? {
        guard total > bestsShown else { return nil }
        return expanded ? "Fewer" : "All \(total)"
    }

    static let noBests = "Your best lifts show here once you log a set."

    // MARK: Areas

    static let areasLabel = "Areas"
    static let tessLabel = "Tess"
    static let trainingLabel = "Training"
    static let bestsLabel = "Bests"

    private static func monthYear(_ date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle.dateTime.month(.wide).year()
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        style.locale = calendar.locale ?? .current
        return date.formatted(style)
    }
}

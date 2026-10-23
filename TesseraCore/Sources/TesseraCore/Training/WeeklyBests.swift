import Foundation

/// Twelve weekly bests for one lift: the Training room's lintel ridge (sheet 210). Lifting history only: no body or
/// health data, and the ridge data never goes to widgets, the Lock Screen, Tess or Claude lines, or backups.
public struct WeeklyBests: Equatable, Sendable {
    public static let weeks = 12

    /// One value per week, oldest first, the last being the week of `now`: that week's best e1RM, or nil with no
    /// working set of the lift that week.
    public let bests: [Double?]
    /// The week with the highest e1RM (the later one on a tie), where the ridge glints once.
    public let bestIndex: Int?
    /// The set behind that week's best, for the one plain line ("Bench best 205 lb, three weeks ago"). In the stored
    /// unit; the page formats it.
    public let bestWeight: Double?
    public let bestReps: Double?

    /// 0 is this week.
    public var weeksAgo: Int? {
        bestIndex.map { Self.weeks - 1 - $0 }
    }

    /// "this week", "last week", "three weeks ago".
    public var whenWords: String? {
        guard let ago = weeksAgo else { return nil }
        let words = ["", "", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]
        switch ago {
        case 0: return "this week"
        case 1: return "last week"
        default: return "\(words[min(ago, 11)]) weeks ago"
        }
    }

    public var isEmpty: Bool {
        bestIndex == nil
    }
}

public extension TrainingLedger {
    /// The lift's best e1RM in each of the last twelve weeks (weeks as the calendar draws them), and which week is the
    /// best. Warm-ups and sets that can't estimate a max honestly are left out, as for every other best.
    func weeklyBests(of exercise: ClassDef, now: Date = .now, calendar: Calendar = .current) -> WeeklyBests {
        let count = WeeklyBests.weeks
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now),
              let first = calendar.date(byAdding: .weekOfYear, value: -(count - 1), to: thisWeek.start)
        else {
            return WeeklyBests(bests: Array(repeating: nil, count: count), bestIndex: nil, bestWeight: nil,
                               bestReps: nil)
        }
        var bests = [Double?](repeating: nil, count: count)
        var sets = [LoggedSet?](repeating: nil, count: count)
        for session in sessions(of: exercise) where session.date >= first && session.date < thisWeek.end {
            let weeks = calendar.dateComponents([.weekOfYear], from: first, to: session.date).weekOfYear ?? -1
            guard (0 ..< count).contains(weeks) else { continue }
            for set in session.sets where set.isE1RMEligible && set.e1RM > (bests[weeks] ?? -.infinity) {
                bests[weeks] = set.e1RM
                sets[weeks] = set
            }
        }
        var index: Int?
        for (offset, value) in bests.enumerated() {
            guard let value else { continue }
            if index == nil || value >= (bests[index ?? 0] ?? -.infinity) {
                index = offset
            }
        }
        return WeeklyBests(bests: bests, bestIndex: index, bestWeight: index.flatMap { sets[$0]?.weight },
                           bestReps: index.flatMap { sets[$0]?.reps })
    }
}

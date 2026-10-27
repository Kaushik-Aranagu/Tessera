import Foundation

/// The words of the Stats page and the Training landing (Product build sheet, Oct 22), from fixed templates over
/// numbers and names it is handed. Say "best", never "record"; never "streak", "lost", "broke" or "down". Names that
/// reach here are already masked.
public enum TrainingSentences {
    // MARK: Landing (L1 to L6)

    /// L1, reusing the landing sentence from the landing pages: "Push A today, about 45 min. Bench opens at 82.5."
    public static func today(routine: String?, minutes: Int?, opener: (exercise: String, weight: String)?)
        -> LandingSentence
    {
        LandingSentences.training(session: routine, minutes: minutes, opener: opener)
    }

    /// L2.
    public static func running(routine: String, done: Int, total: Int) -> String {
        "\(routine) is running. \(done) of \(total) sets"
    }

    /// L3.
    public static func finished(routine: String, minutes: Int) -> String {
        "\(routine) done, \(HouseTime.minutes(minutes))"
    }

    public static let restDay = "Rest day"
    public static let noPlan = "No plan yet"
    public static let privateToday = "A private workout today"

    // MARK: Strength (S1 to S5)

    /// S1: "Your best Bench is about 93 kg for 1, on Oct 6."
    public static func best(_ best: TrainingStats.Best, unit: MassUnit, calendar: Calendar = .current) -> String {
        "Your best \(best.exercise) is about \(StatsMass.estimate(kg: best.e1RM, unit: unit)) for 1, on \(day(best.date, calendar))"
    }

    /// S2 to S5 for one lift, or nil when there is nothing to claim.
    public static func strength(_ line: TrainingStats.StrengthLine, range: TrainingStats.Range, unit: MassUnit)
        -> String?
    {
        switch line.change {
        case let .up(steps):
            let amount = Double(steps) * StatsMass.step(unit)
            return "\(line.exercise) is up \(StatsMass.trimmed(amount)) \(unit == .kilograms ? "kg" : "lb") in \(range.word)"
        case .steady: return "\(line.exercise) is steady"
        case .holding: return "\(line.exercise) is holding near its best"
        case .first:
            return "First number for \(line.exercise): about \(StatsMass.estimate(kg: line.nowKg ?? 0, unit: unit)) for 1"
        case .none: return nil
        }
    }

    /// The opening line: the lift with the largest change, else the first claim.
    public static func strengthOpening(_ lines: [TrainingStats.StrengthLine], range: TrainingStats.Range,
                                       unit: MassUnit) -> String?
    {
        func magnitude(_ line: TrainingStats.StrengthLine) -> Int {
            if case let .up(steps) = line.change {
                return steps
            }
            return 0
        }
        let ranked = lines.sorted { magnitude($0) > magnitude($1) }
        return ranked.compactMap { strength($0, range: range, unit: unit) }.first
    }

    // MARK: Volume and habit (S6 to S9)

    /// S6: "Chest 4 sets this week, toward a usual 10." / "..., in its usual 10 to 20." / "Chest 24 sets this week."
    public static func volume(_ row: TrainingStats.MuscleRow) -> String {
        let sets = setsText(row.sets)
        switch row.band {
        case .below: return "\(row.name) \(sets) sets this week, toward a usual \(Int(TrainingStats.Volume.minTarget))"
        case .within:
            let low = Int(TrainingStats.Volume.minTarget), high = Int(TrainingStats.Volume.maxTarget)
            return "\(row.name) \(sets) sets this week, in its usual \(low) to \(high)"
        case .above: return "\(row.name) \(sets) sets this week"
        }
    }

    /// S7.
    public static func sessions(_ count: Int, usual: Int) -> String {
        "\(count) \(count == 1 ? "session" : "sessions") this week. Usual \(usual)"
    }

    /// S8, only for a finished run of 3 weeks or more.
    public static func bestRun(_ weeks: Int?) -> String? {
        guard let weeks, weeks >= 3 else { return nil }
        return "Best run: \(weeks) weeks in a row"
    }

    /// S9, only behind the light-weeks switch.
    public static let lighterWeek = "A lighter week"

    // MARK: Balance (S10, S11)

    public static func balance(_ balance: TrainingStats.Balance) -> [String] {
        var lines: [String] = []
        if balance.pull > 0, balance.push > 0 {
            if balance.isPushPullEven {
                lines.append("Push and pull are even")
            } else {
                lines.append(balance.pull > balance.push ? "Pull is a little ahead of push"
                    : "Push is a little ahead of pull")
            }
        }
        if balance.isUpperLowerEven {
            lines.append("Upper and lower are even")
        } else {
            lines.append(balance.upperShare > 0.5 ? "Upper gets more of your sets" : "Lower gets more of your sets")
        }
        return lines
    }

    // MARK: Words

    static func setsText(_ sets: Double) -> String {
        StatsMass.trimmed((sets * 10).rounded() / 10)
    }

    static func day(_ date: Date, _ calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

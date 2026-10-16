import Foundation
import TesseraCore

extension TessGrammar {
    /// "bench 80x8 mon", "yesterday squat 100x5": a lift with a day name, first or last. A past day asks (K887,
    /// A026); today's name logs as usual; never a task.
    func parseDatedLift(_ text: String, context: TessContext) -> Parse? {
        var words = text.split(separator: " ").map(String.init)
        guard words.count >= 3 else { return nil }
        let isDay = { (word: String) in TessDates.weekdays[word] != nil || ["yesterday", "today"].contains(word) }
        guard let index = isDay(words[words.count - 1]) ? words.count - 1 : isDay(words[0]) ? 0 : nil else {
            return nil
        }
        let dayWord = words.remove(at: index)
        guard case let .lift(exercise, sets, reps, weight, unit)? = parseLift(words.joined(separator: " "), entry: nil)
        else { return nil }
        let calendar = context.calendar
        let today = TesseraDay(calendar: calendar).day(of: context.now)
        let back = if let weekday = TessDates.weekdays[dayWord] {
            (calendar.component(.weekday, from: today) - weekday + 7) % 7
        } else {
            dayWord == "today" ? 0 : 1
        }
        guard back > 0 else {
            return .lift(exercise: exercise, sets: sets, reps: reps, weight: weight, unit: unit)
        }
        guard let day = calendar.date(byAdding: .day, value: -back, to: today),
              let noon = calendar.date(byAdding: .hour, value: 12, to: day) else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        formatter.timeZone = calendar.timeZone
        return .askDatedLift(TessDatedLiftAsk(
            exercise: exercise.id, name: TessCaptureEngine.shortName(exercise.name), sets: sets, reps: reps,
            weight: weight, unit: unit, day: noon, dayName: formatter.string(from: noon)
        ))
    }
}

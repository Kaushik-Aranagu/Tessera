import Foundation

/// A routine's plain counts for its landing line: "Morning, 14 days, usually 6:40, 22 min" (design 131). They show
/// after seven runs; nothing counts a streak and nothing can fall.
public struct RoutineRun: Sendable, Hashable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public enum RoutineUsual {
    public static let runsNeeded = 7

    public struct Counts: Sendable, Equatable {
        public let days: Int
        /// Minutes after 04:00 of the logical day, rounded to five.
        public let startMinutes: Int
        public let lengthMinutes: Int
    }

    public static func counts(of runs: [RoutineRun], calendar: Calendar = .current) -> Counts? {
        let tesseraDay = TesseraDay(calendar: calendar)
        let finished = runs.filter { $0.end > $0.start }
        guard finished.count >= runsNeeded else { return nil }
        let days = Set(finished.map { tesseraDay.day(of: $0.start) }).count
        // The usual start and length are the median of the last 14 runs.
        let lastFourteen = finished.sorted { $0.start > $1.start }.prefix(14)
        // Wall-clock minutes after 04:00 (a run after midnight sits beside one before it, and a daylight-saving day
        // moves nothing).
        let starts = lastFourteen.map { run -> Int in
            let parts = tesseraDay.calendar.dateComponents([.hour, .minute], from: run.start)
            return ((parts.hour ?? 0) * 60 + (parts.minute ?? 0) - TesseraDay.startHour * 60 + 1440) % 1440
        }
        let lengths = lastFourteen.map { Int($0.end.timeIntervalSince($0.start) / 60) }
        let usual = (median(starts) / 5) * 5 + (median(starts) % 5 >= 3 ? 5 : 0)
        return Counts(days: days, startMinutes: usual, lengthMinutes: max(1, median(lengths)))
    }

    /// "Morning, 14 days, usually 6:40, 22 min", or nil before seven runs.
    public static func line(name: String, runs: [RoutineRun], calendar: Calendar = .current) -> String? {
        guard let counts = counts(of: runs, calendar: calendar) else { return nil }
        let start = TesseraDay.startHour * 60 + counts.startMinutes
        let clock = clockWords(minuteOfDay: start % (24 * 60))
        return "\(name), \(counts.days) \(counts.days == 1 ? "day" : "days"), usually \(clock), \(HouseTime.minutes(counts.lengthMinutes))"
    }

    static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle] + 1) / 2 : sorted[middle]
    }

    /// The house clock for a minute of the logical day, mornings unmarked: "6:40", "6:35 pm", "12:05 pm".
    static func clockWords(minuteOfDay: Int) -> String {
        let hour = minuteOfDay / 60, minute = minuteOfDay % 60
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return "\(twelve):" + String(format: "%02d", minute) + (hour >= 12 ? " pm" : "")
    }

    /// A house time with its morning "am" left off ("6:58 am" reads "6:58"); afternoon and evening keep "pm".
    static func unmarked(_ time: String) -> String {
        time.hasSuffix(" am") ? String(time.dropLast(3)) : time
    }
}

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
        // Minutes after the day's own 04:00 start, so a run after midnight sits beside one before it.
        let starts = finished.map { Int($0.start.timeIntervalSince(tesseraDay.start(of: $0.start)) / 60) }
        let lengths = finished.map { Int($0.end.timeIntervalSince($0.start) / 60) }
        let usual = (median(starts) / 5) * 5 + (median(starts) % 5 >= 3 ? 5 : 0)
        return Counts(days: days, startMinutes: usual, lengthMinutes: max(1, median(lengths)))
    }

    /// "Morning, 14 days, usually 6:40, 22 min", or nil before seven runs.
    public static func line(name: String, runs: [RoutineRun], calendar: Calendar = .current) -> String? {
        guard let counts = counts(of: runs, calendar: calendar) else { return nil }
        let start = TesseraDay.startHour * 60 + counts.startMinutes
        let clock = clockWords(minuteOfDay: start % (24 * 60))
        return "\(name), \(counts.days) days, usually \(clock), \(lengthWords(counts.lengthMinutes))"
    }

    static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle] + 1) / 2 : sorted[middle]
    }

    /// 6:40, 12:05, 11:30: the twelve-hour clock with no am or pm.
    static func clockWords(minuteOfDay: Int) -> String {
        let hour = minuteOfDay / 60 % 12 == 0 ? 12 : minuteOfDay / 60 % 12
        return "\(hour):" + String(format: "%02d", minuteOfDay % 60)
    }

    static func lengthWords(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        return minutes % 60 == 0 ? "\(minutes / 60) hr" : "\(minutes / 60) hr \(minutes % 60) min"
    }
}

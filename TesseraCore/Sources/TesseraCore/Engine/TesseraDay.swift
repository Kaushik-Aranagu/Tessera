import Foundation

/// His day runs 04:00 to 04:00 (docs/research/day-boundary.md): from midnight to 03:59 it is still the day before.
/// One rule for every surface. It reads the wall-clock hour, so DST days are right for free (1 Nov is 25 h long, the
/// March change 23 h).
///
/// Keys (buckets, "is this cell today") use `day(of:)`, the midnight of the date a moment belongs to. Range filters
/// use `start(of:)` and `end(of:)`, the 04:00 edges.
public struct TesseraDay: Sendable {
    /// "Sunday": always US English, whatever the device or calendar locale (Product 8:30 PM PT).
    public static func weekdayName(of date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// The hour his day turns over, 0 to 8, as the app applies it from Settings ("The day turns over at"). 4 until he
    /// changes it, which is today's behaviour. Set once at launch and when the setting changes.
    public nonisolated(unsafe) static var configuredStartHour = 4

    public static var startHour: Int {
        configuredStartHour
    }

    public var calendar: Calendar
    /// The hour this day turns over: the configured one unless a caller says otherwise (tests, previews). It is read
    /// when
    /// the instance is made, so a long-lived `TesseraDay` keeps the old hour after a change: build one when it is
    /// needed (it is a cheap value), do not hold one.
    public var startHour: Int

    /// Weeks start on Monday everywhere (the plan, Review and the set counts agree, whatever the locale; QA R5).
    public init(calendar: Calendar = .current, startHour: Int? = nil) {
        var calendar = calendar
        calendar.firstWeekday = 2
        self.calendar = calendar
        self.startHour = min(max(startHour ?? Self.configuredStartHour, 0), 8)
    }

    /// The midnight of the date `date` belongs to: 00:00 to 03:59 belong to the day before.
    public func day(of date: Date) -> Date {
        let midnight = calendar.startOfDay(for: date)
        guard calendar.component(.hour, from: date) < startHour else { return midnight }
        return calendar.date(byAdding: .day, value: -1, to: midnight) ?? midnight
    }

    /// Today for `now`.
    public func today(_ now: Date) -> Date {
        day(of: now)
    }

    /// 04:00 on the day `date` belongs to.
    public func start(of date: Date) -> Date {
        let key = day(of: date)
        return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: key) ?? key
    }

    /// 04:00 on the next day: the end of the day `date` belongs to.
    public func end(of date: Date) -> Date {
        let next = calendar.date(byAdding: .day, value: 1, to: day(of: date)) ?? day(of: date)
        return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: next) ?? next
    }

    public func interval(of date: Date) -> DateInterval {
        DateInterval(start: start(of: date), end: end(of: date))
    }

    public func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        day(of: lhs) == day(of: rhs)
    }

    /// The same wall time, `days` logical days later. 01:00 Saturday plus one day is 01:00 Sunday, still in Saturday's
    /// logical day + 1.
    public func adding(days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// The midnight key of the logical day `days` after `date`'s.
    public func day(_ days: Int, after date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: day(of: date)) ?? day(of: date)
    }

    /// The week (Monday first) holding the day `date` belongs to, with 04:00 edges.
    public func week(containing date: Date) -> DateInterval {
        let key = day(of: date)
        guard let calendarWeek = calendar.dateInterval(of: .weekOfYear, for: key) else { return interval(of: date) }
        let first = calendarWeek.start
        let next = calendarWeek.end
        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: first) ?? first
        let end = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: next) ?? next
        return DateInterval(start: start, end: end)
    }

    /// The month holding the day `date` belongs to, with 04:00 edges (00:30 on the 1st is still last month).
    public func month(containing date: Date) -> DateInterval {
        guard let calendarMonth = calendar.dateInterval(of: .month, for: day(of: date)) else {
            return interval(of: date)
        }
        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: calendarMonth.start)
            ?? calendarMonth.start
        let end = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: calendarMonth.end)
            ?? calendarMonth.end
        return DateInterval(start: start, end: end)
    }

    /// The week's day keys (midnights), Monday first.
    public func weekDays(containing date: Date) -> [Date] {
        guard let calendarWeek = calendar.dateInterval(of: .weekOfYear, for: day(of: date)) else { return [] }
        return (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: calendarWeek.start) }
    }
}

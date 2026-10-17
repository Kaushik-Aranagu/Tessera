import Foundation

extension TessDates {
    /// A resolved time that has already passed, moved ahead. "thu" said on a Thursday means today (Product,
    /// 2026-10-15): with no time, never in the past (the next whole hour); with a time that's passed, next week, unless
    /// the fall-back night's second pass is still ahead (DS8). "today" with no time after 09:00: the next whole hour
    /// (23:30 after 11 pm).
    static func ahead(_ resolved: Date, now: Date, fromWeekday: Bool, saidDay: Bool, saidTime: Bool, hour: Int,
                      minute: Int, calendar: Calendar) -> Date?
    {
        let next = calendar.component(.hour, from: now) + 1
        if fromWeekday {
            if saidTime, let later = laterPass(
                hour: hour,
                minute: minute,
                of: resolved,
                after: now,
                calendar: calendar
            ) {
                return later // "bins sun 1:30am" said at 1:10 am PST: the second 1:30, not next week
            }
            if !saidTime, next < 24 {
                return calendar.date(bySettingHour: next, minute: 0, second: 0, of: now)
            }
            return calendar.date(byAdding: .day, value: 7, to: resolved)
        }
        if saidDay, !saidTime {
            // With no whole hour left today: 23:30, which the quiet-hours step then moves to 7 am (#553).
            return next < 24 ? calendar.date(bySettingHour: next, minute: 0, second: 0, of: now)
                : calendar.date(bySettingHour: 23, minute: 30, second: 0, of: now)
        }
        return resolved
    }

    /// The second pass of a repeated wall time on the fall-back night, when the first pass has gone and the second is
    /// still ahead: "1:30am" said at 1:45 am PDT is 1:30 am PST, 45 minutes away (Research dst-nov-1 DS8). Nil on
    /// every other night, where a wall time happens once.
    static func laterPass(hour: Int, minute: Int, of day: Date, after now: Date, calendar: Calendar) -> Date? {
        guard let first = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), first <= now,
              let last = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day,
                                       matchingPolicy: .nextTime, repeatedTimePolicy: .last, direction: .forward),
              last > now, last != first else { return nil }
        return last
    }
}

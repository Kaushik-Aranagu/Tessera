import Foundation

/// His quiet hours (Settings > "Quiet hours"): when Tessera does not put things in front of him. 11 pm to 7 am until he
/// changes it, which is what the app has always done. A start and an end as minutes of the clock day; they may cross
/// midnight. Equal minutes mean no quiet hours. Phone only.
public struct QuietHours: Equatable, Sendable {
    public static let standard = QuietHours(startMinute: 23 * 60, endMinute: 7 * 60)

    /// As the app applies them from Settings, for the few places that have no store (the grammar). Set once at launch
    /// and when the setting changes; everything with a store reads the setting itself.
    public nonisolated(unsafe) static var current = QuietHours.standard

    public let startMinute: Int
    public let endMinute: Int

    public init(startMinute: Int, endMinute: Int) {
        self.startMinute = min(max(startMinute, 0), 1439)
        self.endMinute = min(max(endMinute, 0), 1439)
    }

    public var isNone: Bool {
        startMinute == endMinute
    }

    public func contains(minuteOfDay minute: Int) -> Bool {
        guard !isNone else { return false }
        return startMinute < endMinute ? (startMinute ..< endMinute).contains(minute)
            : (minute >= startMinute || minute < endMinute)
    }

    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return contains(minuteOfDay: (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
    }

    /// Where a time inside the quiet hours moves to: the end, on the calendar day it falls in, or the next day when it
    /// falls in the evening part. A time outside them is unchanged.
    public func leaving(_ date: Date, calendar: Calendar = .current) -> Date {
        guard contains(date, calendar: calendar) else { return date }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let crossesMidnight = startMinute > endMinute
        let day = crossesMidnight && minute >= startMinute ? calendar.date(byAdding: .day, value: 1, to: date) ?? date
            : date
        return calendar.date(bySettingHour: endMinute / 60, minute: endMinute % 60, second: 0, of: day) ?? date
    }

    /// "11 pm to 7 am": the house clock words.
    public var words: String {
        isNone ? "Off" : "\(HouseTime.clock(minuteOfDay: startMinute)) to \(HouseTime.clock(minuteOfDay: endMinute))"
    }
}

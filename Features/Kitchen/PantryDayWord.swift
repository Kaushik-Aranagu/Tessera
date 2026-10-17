import Foundation
import TesseraCore

/// When something was bought, on his day (it starts at 4 AM, so a 1:20 am check belongs to the day before; G24):
/// "bought today", "bought yesterday", "bought Sat" within the week, then "bought Oct 3" (US month first).
enum PantryDayWord {
    static func bought(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        "bought \(day(date, now: now, calendar: calendar, spoken: false))"
    }

    /// VoiceOver's form: full names ("bought Saturday", "bought October 3").
    static func spoken(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        "bought \(day(date, now: now, calendar: calendar, spoken: true))"
    }

    private static func day(_ date: Date, now: Date, calendar: Calendar, spoken: Bool) -> String {
        let house = TesseraDay(calendar: calendar)
        let then = house.day(of: date), today = house.day(of: now)
        let days = calendar.dateComponents([.day], from: then, to: today).day ?? 0
        switch days {
        case ..<1: return "today"
        case 1: return "yesterday"
        case 2 ... 6:
            let name = TesseraDay.weekdayName(of: then, calendar: calendar)
            return spoken ? name : String(name.prefix(3))
        default:
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = spoken ? "MMMM d" : "MMM d"
            return formatter.string(from: then)
        }
    }
}

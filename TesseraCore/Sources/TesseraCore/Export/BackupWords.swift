import Foundation
import GRDB

/// Backups in words (Together round 10, 169, switch backupsV2): sentences and counts only. A name, a title or a money
/// amount is never listed; money is counted inside the total of things and nowhere else.
public enum BackupWords {
    /// "4,210".
    public static func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// "tonight, 9:14 pm", "this morning, 7:40 am", "yesterday, 9:14 pm", "Thursday, 9:14 pm", "Oct 12, 9:14 pm".
    public static func when(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let day = TesseraDay(calendar: calendar)
        let clock = HouseTime.clock(date, calendar: calendar)
        let this = day.day(of: date), today = day.day(of: now)
        if this == today {
            let hour = calendar.component(.hour, from: date)
            return (hour >= 17 ? "tonight" : hour >= 12 ? "this afternoon" : hour >= 4 ? "this morning" : "tonight")
                + ", " + clock
        }
        if this == day.day(-1, after: now) {
            return "yesterday, \(clock)"
        }
        let days = calendar.dateComponents([.day], from: this, to: today).day ?? 99
        if days > 0, days < 7 {
            return "\(TesseraDay.weekdayName(of: date, calendar: calendar)), \(clock)"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: date)), \(clock)"
    }

    /// "Last backup tonight, 9:14 pm. 4,210 things." Or "No backup yet." The count is the whole store, money included
    /// and unlisted.
    public static func lastLine(createdAt: Date?, things: Int?, now: Date, calendar: Calendar = .current) -> String {
        guard let createdAt else { return "No backup yet." }
        let base = "Last backup \(when(createdAt, now: now, calendar: calendar))."
        guard let things else { return base }
        return base + " \(number(things)) \(things == 1 ? "thing" : "things")."
    }

    /// The last 7 backups as dates for the Restore list, newest first: "Thursday, Oct 22".
    public static func restoreDates(_ dates: [Date], calendar: Calendar = .current) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMM d"
        return dates.sorted(by: >).prefix(7).map { formatter.string(from: $0) }
    }

    /// What a restore would change, in one sentence, shown before it happens: counts only. The copy he has now stays
    /// in Backups and the restore can be undone for 10 minutes.
    public static func restorePreview(copyThings: Int, nowThings: Int) -> String {
        func things(_ count: Int) -> String {
            "\(number(count)) \(count == 1 ? "thing" : "things")"
        }
        let verb = copyThings == nowThings ? "the same" : copyThings < nowThings ? "fewer" : "more"
        let compare = verb == "the same" ? "as" : "than"
        return "That copy has \(things(copyThings)), \(verb) \(compare) the \(number(nowThings)) you have now. "
            + "Today's copy stays in Backups, and you can undo this for 10 minutes."
    }

    /// What a copy leaves out, said only for what it really leaves out. The calendar and Health mirrors are in no copy.
    /// Private notes, recipes, items and secret-word lines (which is where a weigh-in lives) are left out only of the
    /// copy for the iCloud Drive folder; the copy on the phone keeps every word behind Face ID.
    public static func notIncluded(leavingOutPrivate: Bool) -> String {
        leavingOutPrivate ? "Not included: health, calendar, body, private things, Tess's conversation and what lab mode sent."
            : "Not included: health, calendar, Tess's conversation and what lab mode sent."
    }

    // MARK: Counts

    private nonisolated static let thingCountSQL = "SELECT COUNT(*) FROM object WHERE deletedAt IS NULL AND isClassObject = 0"

    /// Live things in a backup file (a count only; nothing in it is read).
    public nonisolated static func thingCount(at url: URL) -> Int? {
        var configuration = Configuration()
        configuration.readonly = true
        guard let queue = try? DatabaseQueue(path: url.path, configuration: configuration) else { return nil }
        defer { try? queue.close() }
        return try? queue.read { try Int.fetchOne($0, sql: thingCountSQL) }
    }

    /// Live things in the store he has now.
    @MainActor
    public static func thingCount(in context: TesseraContext) -> Int? {
        try? context.save()
        return try? context.database.read { try Int.fetchOne($0, sql: thingCountSQL) }
    }
}

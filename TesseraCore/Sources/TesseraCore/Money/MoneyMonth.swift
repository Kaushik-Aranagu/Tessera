import Foundation

/// The Money page's month (Together round 8, 160, switch moneyMonthV2): one sentence in plain words, a line per pool
/// and
/// a level of the month's spend against the month before. Phone only: these figures never reach Claude, a log, a
/// backup listing or a widget, and never Home. A pool is named the way the rest of Money names it.
///
/// `text` is for the Money page only: Home, the Lock Screen, widgets, intents and every model get none of it (a test
/// scans for the type and its reader).
public struct PoolMonthLine: Equatable, Sendable {
    public let pool: UUID
    /// "US checking, 2,100."
    public let text: String
    public let spent: Decimal
    public let lastMonth: Decimal
    /// This month's spend against last month's, 0 to 1 (a bigger month fills the track). Nil with nothing last month.
    public let fill: Double?
}

public extension PoolReport {
    /// "May, spent 1,240 US and 310 EUR, about 1,560 in all." Each currency exact; the one "about" only when there is
    /// more than one currency and every one has a rate. "May, nothing spent." with none.
    func monthSentence(monthOf date: Date? = nil, calendar: Calendar = .current) -> String {
        let at = date ?? now
        let name = monthName(at, calendar)
        let sums = spends(inMonthOf: at, calendar: calendar)
        guard !sums.isEmpty else { return "\(name), nothing spent." }
        let codes = sums.keys.sorted { $0 == "USD" ? true : ($1 == "USD" ? false : $0 < $1) }
        let parts = codes.map { "\(Self.plain(sums[$0] ?? 0, lakh: lakh)) \($0 == "USD" ? "US" : $0)" }
        var text = "\(name), spent \(Self.joined(parts))"
        if codes.count > 1 {
            var dollars = Decimal(0)
            var all = true
            var oldest: Date?
            for code in codes {
                if let rate = rate(to: code) {
                    dollars += (sums[code] ?? 0) * rate.dollars
                    if code != "USD" {
                        oldest = min(oldest ?? rate.date, rate.date)
                    }
                } else {
                    all = false
                }
            }
            if all {
                text += ", about \(Self.plain(PoolMath.rounded(dollars, places: 0), lakh: lakh)) in all"
                text += "."
                // Said once, in words, when a rate behind the "about" is more than two weeks old.
                if let oldest, now.timeIntervalSince(oldest) > Double(Self.staleDays) * 86400 {
                    text += " The rates are old."
                }
                return text
            }
        }
        return text + "."
    }

    /// A line per live pool for the month: its balance now and the month's spend against last month's.
    func poolLines(monthOf date: Date? = nil, calendar: Calendar = .current) -> [PoolMonthLine] {
        let at = date ?? now
        let day = TesseraDay(calendar: calendar)
        let previous = day.month(containing: at).start.addingTimeInterval(-3600 * 24 * 2)
        let spent = poolSpends(inMonthOf: at, calendar: calendar)
        let before = poolSpends(inMonthOf: previous, calendar: calendar)
        return book.pools().filter { store.value("archivedAt", of: $0)?.dateValue == nil }.map { pool in
            let now = spent[pool.id] ?? 0, last = before[pool.id] ?? 0
            let fill: Double? = last > 0 ? min(1, max(0, NSDecimalNumber(decimal: now / last).doubleValue)) : nil
            let balance = Self.plain(book.balance(of: pool), lakh: lakh)
            return PoolMonthLine(pool: pool.id, text: "\(name(of: pool)), \(balance).", spent: now, lastMonth: last,
                                 fill: fill)
        }
    }

    /// The first day of the oldest and newest month that has a spend, for the scrub's two ends. Nil with none.
    func monthRange(calendar: Calendar = .current) -> ClosedRange<Date>? {
        guard let spendClass = classes[.spend] else { return nil }
        let dates = store.objects(of: spendClass).filter { !$0.isDeleted }
            .compactMap { store.value("spentAt", of: $0)?.dateValue }
        guard let first = dates.min(), let last = dates.max() else { return nil }
        let day = TesseraDay(calendar: calendar)
        return day.month(containing: first).start ... day.month(containing: last).start
    }

    // MARK: Pieces

    private func spends(inMonthOf date: Date, calendar: Calendar) -> [String: Decimal] {
        var sums: [String: Decimal] = [:]
        for entry in SpendLedger(store: store, classes: classes).entries(inMonthOf: date, calendar: calendar) {
            sums[entry.currency ?? "USD", default: 0] += entry.amount
        }
        return sums
    }

    private func poolSpends(inMonthOf date: Date, calendar: Calendar) -> [UUID: Decimal] {
        var sums: [UUID: Decimal] = [:]
        for entry in SpendLedger(store: store, classes: classes).entries(inMonthOf: date, calendar: calendar) {
            if let pool = store.linkedObjects("pool", of: entry.object).first {
                sums[pool.id, default: 0] += entry.amount
            }
        }
        return sums
    }

    private func monthName(_ date: Date, _ calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        formatter.dateFormat = sameYear ? "MMMM" : "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// "1,240" or "1,240.50": the cents only when there are some.
    static func plain(_ value: Decimal, lakh: Bool) -> String {
        let rounded = PoolMath.rounded(value, places: 2)
        let whole = PoolMath.rounded(rounded, places: 0)
        if rounded == whole {
            return PoolFormat.wholeNumber(rounded, lakh: lakh)
        }
        let negative = rounded < 0
        let magnitude = abs(rounded)
        let integer = NSDecimalNumber(decimal: magnitude).intValue
        let cents = NSDecimalNumber(decimal: PoolMath.rounded((magnitude - Decimal(integer)) * 100, places: 0)).intValue
        return (negative ? "-" : "") + PoolFormat.wholeNumber(Decimal(integer), lakh: lakh)
            + String(format: ".%02d", cents)
    }

    private static func joined(_ parts: [String]) -> String {
        parts.count < 3 ? parts.joined(separator: " and ")
            : parts.dropLast().joined(separator: ", ") + " and " + parts[parts.count - 1]
    }
}

import Foundation
import TesseraCore

/// Money's words (ship-list-m5-money.md with its Oct 17 amendments; sheet money-reading-grammar). Amounts are drawn
/// as typed and summed in exact cents by Core's `SpendLedger`; nothing here converts or sums across currencies. The
/// word is "logged", never "you spent". No budget, no red.
enum MoneyCopy {
    static let symbols = ["EUR": "€", "GBP": "£", "USD": "$", "INR": "₹"]

    /// The month sentence (the Money front's hero): "7 spends. Most went to lunch, 24.80, and coffee, 9.00." then
    /// one line per other currency: "Also $38.20 in 1 spend." Unmarked first, then currencies by code (Core's order).
    /// An empty month is "Nothing logged yet."
    static func monthSentence(_ entries: [SpendLedger.Entry]) -> [String] {
        guard !entries.isEmpty else { return ["Nothing logged yet."] }
        let groups = Dictionary(grouping: entries, by: \.currency)
        let order = groups.keys.sorted { ($0 ?? "") < ($1 ?? "") }
        var lines: [String] = []
        for (index, currency) in order.enumerated() {
            let group = groups[currency] ?? []
            if index == 0 {
                lines.append(lead(group, currency: currency))
            } else {
                let total = group.reduce(Decimal(0)) { $0 + $1.amount }
                lines.append("Also \(drawn(total, currency: currency)) in \(count(group.count)).")
            }
        }
        return lines
    }

    /// "7 spends. Most went to lunch, 24.80, and coffee, 9.00." The top two words by total, ties by word.
    private static func lead(_ group: [SpendLedger.Entry], currency: String?) -> String {
        var categories: [String: Decimal] = [:]
        for entry in group where !entry.category.isEmpty {
            categories[entry.category, default: 0] += entry.amount
        }
        let top = categories.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(2)
            .map { "\($0.key), \(drawn($0.value, currency: currency))" }
        let head = "\(count(group.count))."
        switch top.count {
        case 0: return head
        case 1: return "\(head) Most went to \(top[0])."
        default: return "\(head) Most went to \(top[0]), and \(top[1])."
        }
    }

    static func count(_ count: Int) -> String {
        "\(count) \(count == 1 ? "spend" : "spends")"
    }

    /// A total as drawn: "24.80", "$38.20", "€8.00".
    static func drawn(_ value: Decimal, currency: String?) -> String {
        let symbol = currency.map { symbols[$0] ?? "\($0) " } ?? ""
        return symbol + MoneyAmount.format(value)
    }

    /// The front's context line: "October, 16 days in" (his day turns at 4 am).
    static func context(now: Date, calendar: Calendar = .current) -> String {
        let house = TesseraDay(calendar: calendar)
        let day = house.day(of: now)
        let days = calendar.component(.day, from: day)
        return "\(monthName(day, calendar: calendar)), \(days) \(days == 1 ? "day" : "days") in"
    }

    /// The label over a currency's own lines: "IN DOLLARS" (drawn uppercase by the label role).
    static func currencyHeading(_ currency: String) -> String {
        "In \(unit(currency).plural)"
    }

    /// The day label in the ledger, US order: "Oct 15" (the label role draws it uppercase).
    static func dayLabel(_ date: Date, calendar: Calendar = .current) -> String {
        format(date, "MMM d", calendar: calendar)
    }

    /// The spoken amount: "12 dollars 40", "8 euros", "1 pound 5". Unmarked reads as dollars (his house is US); the
    /// drawn "12.40" is never what VoiceOver says (G307).
    static func spoken(_ value: Decimal, currency: String?) -> String {
        let cents = NSDecimalNumber(decimal: value * 100).rounding(accordingToBehavior: nil).intValue
        let whole = cents / 100, part = cents % 100
        let names = unit(currency)
        let head = "\(whole) \(whole == 1 ? names.one : names.plural)"
        return part == 0 ? head : "\(head) \(part)"
    }

    /// One ledger line for VoiceOver, one combined element: "Oct 15, lunch, 12 dollars 40".
    static func spokenLine(day: Date, word: String, amount: Decimal, currency: String?,
                           calendar: Calendar = .current) -> String
    {
        let parts = [dayLabel(day, calendar: calendar), word, spoken(amount, currency: currency)]
        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// The spend page's context line, house clock and US dates: "lunch, Thu Oct 15, 1:10 pm" (amendment 3).
    static func spendContext(note: String, spentAt: Date, calendar: Calendar = .current) -> String {
        let when = "\(format(spentAt, "EEE MMM d", calendar: calendar)), \(HouseTime.clock(spentAt, calendar: calendar))"
        return note.isEmpty ? when : "\(note), \(when)"
    }

    /// "In no currency." or "In euros."
    static func currencyLine(_ currency: String?) -> String {
        guard let currency, !currency.isEmpty else { return "In no currency." }
        return "In \(unit(currency).plural)."
    }

    /// The named delete on a spend's row and page (G304): "Delete 12.40 lunch".
    static func deleteName(_ title: String) -> String {
        "Delete \(title)"
    }

    /// "12.40 lunch, deleted."
    static func deleted(_ title: String) -> String {
        "\(title), deleted."
    }

    /// The empty front: one cobalt line from Tess.
    static let emptyTess = "Tell me what you spent. Try: spent 4.50 coffee."
    /// What the writing line shows before he types.
    static let prompt = "spent 12.40 lunch"
    /// A line the writing line can't read as a spend.
    static let didntCatch = "Didn't catch that. Try: spent 12.40 lunch."

    // MARK: The groceries total

    /// The quiet line under a finished shop, and Now's slot while it waits: Core's "Groceries total?".
    @MainActor static var totalPrompt: String {
        ShopReceipt.prompt
    }

    /// Where the question comes from: "From the 5:40 pm shop."
    static func totalContext(endedAt: Date, calendar: Calendar = .current) -> String {
        "From the \(HouseTime.clock(endedAt, calendar: calendar)) shop."
    }

    /// The skip control's name (amendment 8).
    static let skipName = "Skip the Groceries total"

    private static func unit(_ currency: String?) -> (one: String, plural: String) {
        switch currency {
        case "EUR": ("euro", "euros")
        case "GBP": ("pound", "pounds")
        case "INR": ("rupee", "rupees")
        case "USD", nil, "": ("dollar", "dollars")
        case let .some(code): (code, code)
        }
    }

    private static func monthName(_ date: Date, calendar: Calendar) -> String {
        format(date, "LLLL", calendar: calendar)
    }

    private static func format(_ date: Date, _ pattern: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

/// The Money page's writing line: "spent 12.40 lunch", "12.40 on lunch", "€8 parking", "20 eur taxi". "spent" or
/// "paid" may lead; "on" or "for" after the amount is dropped. On the Money page the place says it's money, so a
/// whole number counts ("450 groceries"). Core's grammar (slice 4) owns the ask bar; this reads only this page.
enum MoneyCapture {
    static func spend(_ text: String) -> LogSpend? {
        var words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lead = words.firstMatch(of: /^(?i:spent|paid)\s+/) {
            words = String(words[lead.range.upperBound...])
        }
        guard let amount = MoneyAmount.parse(words) else { return nil }
        var note = MoneyAmount.note(after: words)
        if let filler = note.firstMatch(of: /^(?i:on|for)\s+/) {
            note = String(note[filler.range.upperBound...])
        }
        let value = NSDecimalNumber(decimal: amount.amount).doubleValue
        guard value > 0 else { return nil }
        return LogSpend(
            amount: value,
            typed: amount.typed,
            currency: amount.currency,
            note: note,
            spentAt: AppClock.now
        )
    }

    /// A typed total for the waiting shop: "38.20", "$38.20", "38".
    static func total(_ text: String) -> LogShopTotal? {
        guard let amount = MoneyAmount.parse(text) else { return nil }
        let value = NSDecimalNumber(decimal: amount.amount).doubleValue
        guard value > 0 else { return nil }
        return LogShopTotal(amount: value, typed: amount.typed, currency: amount.currency, time: AppClock.now)
    }
}

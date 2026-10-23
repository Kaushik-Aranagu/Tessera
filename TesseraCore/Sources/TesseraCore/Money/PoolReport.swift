import Foundation

/// Money pools, PR 3: what the Money page says about pools. Totals per currency, the month's spends and fees, the one
/// "about" dollar total with the rates behind it, and the sentences. Pure reads from the objects and the rates handed
/// in: nothing here fetches, stores or sends. The ECB table (the one cached by `CurrencyRatesFetch`) is used first; a
/// rate he typed or a move implied stands in when there is none. A pool's name is "Private pool" when it is walled.
@MainActor
public struct PoolReport {
    public static let staleDays = 14

    public struct Rate: Equatable, Sendable {
        /// Dollars for one of the currency.
        public let dollars: Decimal
        public let date: Date
    }

    public struct Line: Equatable, Sendable {
        public let currency: String
        public let word: String
        public let amount: Decimal
        /// "Dollars $912.60", "Rupees INR 18,400.00".
        public let text: String
    }

    public struct About: Equatable, Sendable {
        /// Whole dollars, half up; nil when nothing needed converting.
        public let dollars: Int?
        public let leftOut: [String]
        /// The oldest rate used, for "Rates from Oct 18."
        public let ratesFrom: Date?
        public let isStale: Bool
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    public let ecb: CurrencyRates?
    public let now: Date
    public let lakh: Bool

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], ecb: CurrencyRates? = nil,
                now: Date = .now, lakh: Bool = false)
    {
        self.store = store
        self.classes = classes
        self.ecb = ecb
        self.now = now
        self.lakh = lakh
    }

    var book: PoolBook {
        PoolBook(store: store, classes: classes)
    }

    public static let words = ["USD": "Dollars", "INR": "Rupees", "EUR": "Euros", "GBP": "Pounds"]

    public static func word(_ code: String) -> String {
        words[code] ?? code
    }

    // MARK: Totals

    /// Every pool's balance added up per currency (archived pools stay in), dollars first.
    public func totals() -> [Line] {
        var sums: [String: Decimal] = [:]
        for pool in book.pools() {
            sums[book.currency(of: pool), default: 0] += book.balance(of: pool)
        }
        return sums.keys.sorted { lhs, rhs in lhs == "USD" ? true : (rhs == "USD" ? false : lhs < rhs) }.map { code in
            let amount = sums[code] ?? 0
            return Line(currency: code, word: Self.word(code), amount: amount,
                        text: "\(Self.word(code)) \(PoolFormat.amount(amount, currency: code, lakh: lakh, text: true))")
        }
    }

    /// The month's spends per currency ("USD" for unmarked), by the 4 AM month the ledger uses.
    public func monthSpends(calendar: Calendar = .current) -> [String: Decimal] {
        var sums: [String: Decimal] = [:]
        for entry in SpendLedger(store: store, classes: classes).entries(inMonthOf: now, calendar: calendar) {
            sums[entry.currency ?? "USD", default: 0] += entry.amount
        }
        return sums
    }

    /// The month's fees paid, per currency of the pool they left.
    public func monthFees(calendar: Calendar = .current) -> [String: Decimal] {
        let month = TesseraDay(calendar: calendar).month(containing: now)
        var sums: [String: Decimal] = [:]
        for move in book.moves() {
            guard let at = store.value("at", of: move)?.dateValue ?? Optional(move.createdAt), at >= month.start,
                  at < month.end,
                  let source = store.linkedObjects("fromPool", of: move).first else { continue }
            sums[book.currency(of: source), default: 0] += book.figures(of: move).fee
        }
        return sums.filter { $0.value > 0 }
    }

    // MARK: Rates

    /// Dollars for one of a currency: the ECB table first, else the newest rate he noted or a move implied.
    public func rate(to code: String) -> Rate? {
        if code == "USD" {
            return Rate(dollars: 1, date: now)
        }
        // The one place a Double meets the money: the ECB table is published and cached as Double. It is turned into a
        // Decimal at once and rounded to 8 places; every amount of his stays Decimal from its typed digits.
        if let ecb, let usd = ecb.rates["USD"], let other = ecb.rates[code], usd > 0, other > 0 {
            return Rate(dollars: PoolMath.rounded(Decimal(usd) / Decimal(other), places: 8), date: ecb.date)
        }
        guard let noteClass = classes[.rateNote] else { return nil }
        var best: Rate?
        for note in store.objects(of: noteClass) where !note.isDeleted {
            let pair = (store.value("pair", of: note)?.stringValue ?? "").split(separator: "/").map(String.init)
            let value = PoolBook.decimal(store.value("valueTyped", of: note)?.stringValue)
            let at = store.value("at", of: note)?.dateValue ?? note.createdAt
            guard pair.count == 2, value > 0, pair.contains("USD"), pair.contains(code) else { continue }
            // "USD/INR 83.10" is rupees for a dollar; "INR/USD 0.012" is dollars for a rupee.
            let dollars = pair == ["USD", code] ? PoolMath.rounded(1 / value, places: 8) : value
            if best.map({ at > $0.date }) ?? true {
                best = Rate(dollars: dollars, date: at)
            }
        }
        return best
    }

    /// Dollars and other currencies in one: USD exact, the rest at their rate, half up to a whole dollar. A currency
    /// with no rate is left out and named.
    public func about() -> About {
        var dollars = Decimal(0)
        var converted = false
        var leftOut: [String] = []
        var oldest: Date?
        for line in totals() {
            if line.currency == "USD" {
                dollars += line.amount
            } else if let rate = rate(to: line.currency) {
                dollars += line.amount * rate.dollars
                converted = true
                oldest = min(oldest ?? rate.date, rate.date)
            } else if line.amount != 0 {
                leftOut.append(line.currency)
            }
        }
        let stale = oldest.map { now.timeIntervalSince($0) > Double(Self.staleDays) * 86400 } ?? false
        return About(dollars: converted ? NSDecimalNumber(decimal: PoolMath.rounded(dollars, places: 0)).intValue : nil,
                     leftOut: leftOut, ratesFrom: oldest, isStale: stale)
    }

    // MARK: Words

    /// A pool's name wherever a line shows it.
    public func name(of pool: ObjectRecord) -> String {
        PoolRules.shown(pool, in: store)
    }

    /// "US checking is below zero by $120.00." for each pool under zero (allowed, said once, never red).
    public func belowZero() -> [String] {
        book.pools().compactMap { pool in
            let balance = book.balance(of: pool)
            guard balance < 0 else { return nil }
            let amount = PoolFormat.amount(-balance, currency: book.currency(of: pool), lakh: lakh, text: true)
            return "\(name(of: pool)) is below zero by \(amount)."
        }
    }

    /// The total rule's lines under the per-currency ones: "In dollars, about $1,136", "Rates from Oct 18.",
    /// "Rupees are not in the total.", "These rates are old."
    public func aboutLines(calendar: Calendar = .current) -> [String] {
        let total = about()
        var lines: [String] = []
        if let dollars = total.dollars {
            lines.append("In dollars, about \(PoolFormat.wholeDollars(Decimal(dollars), lakh: lakh))")
            if let from = total.ratesFrom {
                lines.append("Rates from \(Self.day(from, calendar)).")
            }
            if total.isStale {
                lines.append("These rates are old.")
            }
        }
        for code in total.leftOut {
            lines.append("\(Self.word(code)) \(Self.word(code) == code ? "is" : "are") not in the total.")
        }
        return lines
    }

    static func day(_ date: Date, _ calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// "Fees this month: $5.00." (one phrase per currency, joined with "and"), nil with none.
    public func feesLine(calendar: Calendar = .current) -> String? {
        let fees = monthFees(calendar: calendar)
        guard !fees.isEmpty else { return nil }
        let parts = fees.keys.sorted { $0 == "USD" ? true : ($1 == "USD" ? false : $0 < $1) }.map { PoolFormat.amount(
            fees[$0] ?? 0,
            currency: $0,
            lakh: lakh,
            text: true
        ) }
        return "Fees this month: \(parts.joined(separator: " and "))."
    }

    /// "Archived pools are still counted." when an archived pool holds money that the totals include; nil otherwise.
    public func archivedNote() -> String? {
        let counted = book.pools().contains {
            store.value("archivedAt", of: $0)?.dateValue != nil && book.balance(of: $0) != 0
        }
        return counted ? "Archived pools are still counted." : nil
    }

    /// The Money landing's pool sentence: "US checking has $1,345.00." / "$1,345.00 in US checking, INR 82,650.00 in
    /// India account." (two pools; more are the doors').
    public func sentence(nothingLate: Bool) -> LandingSentence {
        let pools = book.pools().filter { store.value("archivedAt", of: $0)?.dateValue == nil }
        let shown = pools.prefix(2).map { pool in
            (name: name(of: pool),
             amount: PoolFormat.amount(
                 book.balance(of: pool),
                 currency: book.currency(of: pool),
                 lakh: lakh,
                 text: true
             ))
        }
        let lead = nothingLate ? "Nothing is late. " : ""
        switch shown.count {
        case 0: return LandingSentence(text: nothingLate ? "Nothing is late." : "No pools yet.", key: nil)
        case 1: return LandingSentence(text: "\(lead)\(shown[0].name) has \(shown[0].amount).", key: shown[0].name)
        default:
            return LandingSentence(
                text: "\(shown[0].amount) in \(shown[0].name), \(shown[1].amount) in \(shown[1].name).",
                key: shown[0].name
            )
        }
    }

    /// "Moved $1,000.00, got INR 82,650.00." as the Money page's new line, "US checking got $3,200.00, paycheck.",
    /// "Coffee $4.50, US checking."
    public func newLine(for row: ObjectRecord) -> String? {
        switch row.classDef?.id {
        case classes[.inflow]?.id:
            guard let pool = store.linkedObjects("pool", of: row).first else { return nil }
            let amount = PoolFormat.amount(PoolBook.decimal(store.value("amountTyped", of: row)?.stringValue),
                                           currency: book.currency(of: pool), lakh: lakh, text: true)
            return "\(name(of: pool)) got \(amount), \(store.value("source", of: row)?.stringValue ?? "paycheck")."
        case classes[.poolMove]?.id:
            let figures = book.figures(of: row)
            let from = store.linkedObjects("fromPool", of: row).first,
                into = store.linkedObjects("toPool", of: row).first
            return "Moved \(PoolFormat.amount(figures.sent, currency: from.map(book.currency(of:)) ?? "USD", lakh: lakh, text: true)), got "
                + "\(PoolFormat.amount(figures.arrived, currency: into.map(book.currency(of:)) ?? "USD", lakh: lakh, text: true))."
        case classes[.spend]?.id:
            guard let pool = store.linkedObjects("pool", of: row).first else { return nil }
            let note = (store.value("note", of: row)?.stringValue ?? "").trimmingCharacters(in: .whitespaces)
            let word = note.isEmpty ? "Spent" : note.prefix(1).uppercased() + note.dropFirst()
            let typed = MoneyAmount.parse(store.value("typed", of: row)?.stringValue ?? "")?.amount ?? 0
            let amount = PoolFormat.amount(typed, currency: book.currency(of: pool), lakh: lakh, text: true)
            // Word by word, as the past sentence does: "ozempic pharmacy run" never shows its first word.
            let hidden = ObjectPrivacy.isPrivateWord(note, in: store)
                || note.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains { ObjectPrivacy.isPrivateWord(
                    String($0),
                    in: store
                ) }
            let shownWord = hidden ? "Private spend" : word
            return "\(shownWord) \(amount), \(name(of: pool))."
        default: return nil
        }
    }

    /// The move page: "You sent $1,000.00 and paid $5.00 in fees. You got INR 82,650.00. Your rate was 82.24 for a
    /// dollar after fees."
    public func movePage(for move: ObjectRecord) -> String {
        let figures = book.figures(of: move)
        let from = store.linkedObjects("fromPool", of: move).first.map(book.currency(of:)) ?? "USD"
        let into = store.linkedObjects("toPool", of: move).first.map(book.currency(of:)) ?? "USD"
        func shown(_ value: Decimal, _ code: String) -> String {
            PoolFormat.amount(value, currency: code, lakh: lakh, text: true)
        }
        var text = "You sent \(shown(figures.sent, from))"
        text += figures.fee > 0 ? " and paid \(shown(figures.fee, from)) in fees." : "."
        text += " You got \(shown(figures.arrived, into))."
        if from != into, let rate = figures.effectiveRate {
            text += " Your rate was \(PoolFormat.rate(rate)) for \(from == "USD" ? "a dollar" : "one \(from)") after fees."
        }
        return text
    }
}

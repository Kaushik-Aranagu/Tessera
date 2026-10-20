import Foundation

/// A month of spends and its one line (Money slice 2). Sums are `Decimal` of the typed digits, never `Double`, so
/// 0.10 + 0.20 is 0.30. Totals group by currency; spends with no currency form their own group. The word is
/// "logged", never "you spent".
@MainActor
public struct SpendLedger {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public struct Entry {
        public let object: ObjectRecord
        public let amount: Decimal
        public let currency: String?
        public let category: String
        public let spentAt: Date
    }

    public func entries(inMonthOf date: Date, calendar: Calendar = .current) -> [Entry] {
        guard let spendClass = classes[.spend] else { return [] }
        let month = TesseraDay(calendar: calendar).month(containing: date)
        return store.objects(of: spendClass).compactMap { object -> Entry? in
            guard !object.isDeleted, let at = store.value("spentAt", of: object)?.dateValue, at >= month.start,
                  at < month.end else { return nil }
            // The typed digits, not the Double: exact cents.
            let typed = store.value("typed", of: object)?.stringValue ?? ""
            let digits = MoneyAmount.parse(typed)?.amount
                ?? store.number("amount", of: object).flatMap { Decimal(string: String($0)) } ?? 0
            let currency = store.value("currency", of: object)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
            return Entry(object: object, amount: digits, currency: currency,
                         category: store.value("category", of: object)?.stringValue ?? "", spentAt: at)
        }.sorted { $0.spentAt > $1.spentAt }
    }

    static let symbols = ["EUR": "€", "GBP": "£", "USD": "$", "INR": "₹"]

    /// An amount as the house shows it: the sign against the number when a currency is set ("€26.90"), the bare
    /// number otherwise, never a code.
    public static func shown(_ amount: Decimal, currency: String?) -> String {
        (currency.flatMap { symbols[$0] } ?? "") + MoneyAmount.format(amount)
    }

    /// The thing first, then the amount: "Coffee, 12.40." A walled word reads "Private spend"; no word reads
    /// "Spent 12.40."
    public static func receiptLine(for spend: ObjectRecord, in store: ObjectStore) -> String {
        let typed = store.value("typed", of: spend)?.stringValue ?? ""
        let amount = MoneyAmount.parse(typed)?.amount
            ?? store.number("amount", of: spend).flatMap { Decimal(string: String($0)) } ?? 0
        let currency = store.value("currency", of: spend)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        let shown = shown(amount, currency: currency)
        let note = (store.value("note", of: spend)?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isEmpty {
            return "Spent \(shown)."
        }
        if PrivateWords.isPrivateTitle(note, lastWeightKg: BodyWeight.lastKg(in: store)) {
            return "\(ObjectPrivacy.spendLabel), \(shown)."
        }
        return "\(note.prefix(1).uppercased() + note.dropFirst()), \(shown)."
    }

    /// "October, logged: 41 spends · groceries 312.40 · lunch 86.10", then one line per other currency
    /// ("€ 60.00 in 3 spends"). "October: nothing logged yet" for an empty month.
    public func monthLine(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "LLLL"
        let month = formatter.string(from: date)
        let all = entries(inMonthOf: date, calendar: calendar)
        guard !all.isEmpty else { return "\(month): nothing logged yet" }
        let groups = Dictionary(grouping: all, by: \.currency)
        // Unmarked first, then currencies by code.
        let order = groups.keys.sorted { ($0 ?? "") < ($1 ?? "") }
        var lines: [String] = []
        for (index, currency) in order.enumerated() {
            let group = groups[currency] ?? []
            let count = "\(group.count) \(group.count == 1 ? "spend" : "spends")"
            if index == 0 {
                var categories: [String: Decimal] = [:]
                for entry in group where !entry.category.isEmpty {
                    categories[entry.category, default: 0] += entry.amount
                }
                let top = categories.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(2)
                    .map { "\($0.key) \(MoneyAmount.format($0.value))" }
                let lead = currency.map { "\(Self.symbols[$0] ?? $0) " } ?? ""
                lines.append("\(month), logged: \(lead)\(count)" + top.map { " · " + $0 }.joined())
            } else {
                let total = group.reduce(Decimal(0)) { $0 + $1.amount }
                let symbol = currency.map { Self.symbols[$0] ?? $0 } ?? ""
                lines.append("\(symbol) \(MoneyAmount.format(total)) in \(count)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

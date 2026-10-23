import Foundation

/// Money pools, the numbers (Part B, PR 1). Everything is `Decimal` built from the typed digits, never `Double`, so
/// sums are exact. Corrupt digits count 0 and never crash. Nothing here is offered to Claude, logged or stored: a
/// balance, a rate or a fee is derived on demand from the objects.
@MainActor
public struct PoolBook {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// Typed digits as an exact amount: "1,850.00" and "82650" read; anything else is 0.
    public nonisolated static func decimal(_ typed: String?) -> Decimal {
        guard let typed else { return 0 }
        let clean = typed.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
        guard clean.wholeMatch(of: /-?\d+(?:\.\d+)?/) != nil,
              let value = Decimal(string: clean, locale: Locale(identifier: "en_US_POSIX")) else { return 0 }
        return value
    }

    // MARK: A move

    public struct MoveFigures: Equatable, Sendable {
        public let sent: Decimal
        public let fee: Decimal
        public let arrived: Decimal

        /// What left the sending pool: sent plus the fee, in its currency.
        public var leaves: Decimal {
            sent + fee
        }

        /// Of the second currency for one of the first, after fees, to 8 places; nil when nothing arrived or left.
        public var effectiveRate: Decimal? {
            guard arrived > 0, leaves > 0 else { return nil }
            return PoolMath.rounded(arrived / leaves, places: 8)
        }

        /// What one of the second currency cost in the first, after fees, to 8 places.
        public var costBasis: Decimal? {
            guard arrived > 0, leaves > 0 else { return nil }
            return PoolMath.rounded(leaves / arrived, places: 8)
        }
    }

    public func figures(of move: ObjectRecord) -> MoveFigures {
        MoveFigures(sent: Self.decimal(store.value("sentTyped", of: move)?.stringValue),
                    fee: Self.decimal(store.value("feeTyped", of: move)?.stringValue),
                    arrived: Self.decimal(store.value("arrivedTyped", of: move)?.stringValue))
    }

    // MARK: A pool

    public func pools() -> [ObjectRecord] {
        classes[.pool].map { store.objects(of: $0).filter { !$0.isDeleted } } ?? []
    }

    public func currency(of pool: ObjectRecord) -> String {
        store.value("currency", of: pool)?.stringValue.flatMap { $0.isEmpty ? nil : $0 } ?? "USD"
    }

    public func moves(from pool: ObjectRecord? = nil, to target: ObjectRecord? = nil) -> [ObjectRecord] {
        guard let moveClass = classes[.poolMove] else { return [] }
        return store.objects(of: moveClass).filter { move in
            guard !move.isDeleted else { return false }
            let out = store.linkedObjects("fromPool", of: move).first
            let into = store.linkedObjects("toPool", of: move).first
            return (pool.map { out?.id == $0.id } ?? true) && (target.map { into?.id == $0.id } ?? true)
        }
    }

    /// The pool a new row defaults to for a currency: the one used last (an inflow, a spend or an arrival), else the
    /// only pool of that currency, else nil. Archived and deleted pools are not offered.
    public func lastUsedPool(currency: String) -> ObjectRecord? {
        let live = pools()
            .filter { store.value("archivedAt", of: $0)?.dateValue == nil && self.currency(of: $0) == currency }
        guard !live.isEmpty else { return nil }
        var latest: [UUID: Date] = [:]
        func touch(_ pool: ObjectRecord?, _ at: Date) {
            if let pool {
                latest[pool.id] = max(latest[pool.id] ?? .distantPast, at)
            }
        }
        for key in [SystemCatalog.Key.inflow, .spend] {
            guard let classDef = classes[key] else { continue }
            for row in store.objects(of: classDef) where !row.isDeleted {
                touch(store.linkedObjects("pool", of: row).first, row.createdAt)
            }
        }
        for move in moves() {
            touch(store.linkedObjects("toPool", of: move).first, move.createdAt)
        }
        if let used = live.filter({ latest[$0.id] != nil })
            .max(by: { latest[$0.id] ?? .distantPast < latest[$1.id] ?? .distantPast })
        {
            return used
        }
        return live.count == 1 ? live[0] : nil
    }

    /// Spends logged before pools, or with none: summed per currency code ("USD" for unmarked). Derived, never
    /// written: nothing about an old spend is rewritten.
    public func spendsWithNoPool() -> [String: Decimal] {
        guard let spendClass = classes[.spend] else { return [:] }
        var sums: [String: Decimal] = [:]
        for spend in store.objects(of: spendClass)
            where !spend.isDeleted && store.linkedObjects("pool", of: spend).isEmpty
        {
            let code = store.value("currency", of: spend)?.stringValue.flatMap { $0.isEmpty ? nil : $0 } ?? "USD"
            sums[code, default: 0] += MoneyAmount.parse(store.value("typed", of: spend)?.stringValue ?? "")?.amount ?? 0
        }
        return sums
    }

    /// opening + inflows - spends - what left in moves + what arrived in moves. Archived and deleted rows count as
    /// they stand: an archived pool stays in totals, a deleted row is gone.
    public func balance(of pool: ObjectRecord) -> Decimal {
        var total = Self.decimal(store.value("openingTyped", of: pool)?.stringValue)
        if let inflowClass = classes[.inflow] {
            for inflow in store.objects(of: inflowClass) where !inflow.isDeleted
                && store.linkedObjects("pool", of: inflow).first?.id == pool.id
            {
                total += Self.decimal(store.value("amountTyped", of: inflow)?.stringValue)
            }
        }
        if let spendClass = classes[.spend] {
            for spend in store.objects(of: spendClass) where !spend.isDeleted
                && store.linkedObjects("pool", of: spend).first?.id == pool.id
            {
                let typed = store.value("typed", of: spend)?.stringValue ?? ""
                // The typed digits only: a spend with none reads 0 (no Double on this path).
                total -= MoneyAmount.parse(typed)?.amount ?? 0
            }
        }
        for move in moves(from: pool) {
            total -= figures(of: move).leaves
        }
        for move in moves(to: pool) {
            total += figures(of: move).arrived
        }
        return total
    }
}

public enum PoolMath {
    /// Rounds half up to `places` decimal places.
    public static func rounded(_ value: Decimal, places: Int) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, places, .plain)
        return output
    }
}

/// How an amount is shown: "$1,850.00" for dollars, "INR 82,650.00" in plain text, the local symbol in the app.
/// Lakh grouping (8,26,500.00) only when its switch is on.
public enum PoolFormat {
    static let symbols = ["USD": "$", "EUR": "€", "GBP": "£", "INR": "₹"]

    /// The digits only: two decimals, grouped by thousands, or by lakh (3, then 2, 2, ...) when asked.
    public static func digits(_ amount: Decimal, lakh: Bool = false) -> String {
        let cents = PoolMath.rounded(abs(amount), places: 2)
        let text = NSDecimalNumber(decimal: cents).description(withLocale: Locale(identifier: "en_US_POSIX"))
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        let whole = String(parts[0])
        let fraction = parts.count > 1 ? String(parts[1]) : ""
        let paddedFraction = (fraction + "00").prefix(2)
        return group(whole, lakh: lakh) + "." + paddedFraction
    }

    static func group(_ whole: String, lakh: Bool) -> String {
        guard whole.count > 3 else { return whole }
        let last3 = String(whole.suffix(3))
        var rest = String(whole.dropLast(3))
        var chunks: [String] = []
        let size = lakh ? 2 : 3
        while rest.count > size {
            chunks.insert(String(rest.suffix(size)), at: 0)
            rest = String(rest.dropLast(size))
        }
        if !rest.isEmpty {
            chunks.insert(rest, at: 0)
        }
        return (chunks + [last3]).joined(separator: ",")
    }

    /// Whole dollars for a line that says "about": "$1,136", "-$40", with no cents to cut off.
    public static func wholeDollars(_ value: Decimal, lakh: Bool = false) -> String {
        let rounded = PoolMath.rounded(value, places: 0)
        let digits = NSDecimalNumber(decimal: abs(rounded)).stringValue
        return (rounded < 0 ? "-" : "") + "$" + group(digits, lakh: lakh)
    }

    /// "$1,850.00", "-$120.00"; with `text` set, "INR 82,650.00": the code and a space for every currency but
    /// dollars, so a sentence never has a bare symbol it could be misread by.
    public static func amount(_ amount: Decimal, currency: String, lakh: Bool = false, text: Bool = false) -> String {
        // A negative that rounds to zero ("-0.004") reads "$0.00", never "-$0.00".
        let sign = PoolMath.rounded(amount, places: 2) < 0 ? "-" : ""
        let body = digits(amount, lakh: lakh)
        if currency == "USD" {
            return "\(sign)$\(body)"
        }
        if !text, let symbol = symbols[currency] {
            return "\(sign)\(symbol)\(body)"
        }
        return "\(sign)\(currency) \(body)"
    }

    /// A rate to two places for a sentence: "82.24".
    public static func rate(_ value: Decimal) -> String {
        digits(value, lakh: false)
    }
}

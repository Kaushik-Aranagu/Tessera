import Foundation

/// A table of euro-based reference rates (units of the currency per 1 EUR) and the day they are for. Pure: the
/// fetch lives in `CurrencyRatesFetch.swift` (TesseraTess), the cache in `RatesCache`.
public struct CurrencyRates: Equatable, Codable, Sendable {
    public var rates: [String: Double]
    public var date: Date

    public init(rates: [String: Double], date: Date) {
        self.rates = rates.merging(["EUR": 1]) { given, _ in given }
        self.date = date
    }

    /// The currencies the wheel can swipe through, in code order.
    public var currencies: [String] {
        rates.keys.sorted()
    }

    /// `amount` in `from`, expressed in `to`; nil when either currency is unknown. An estimate, never his data.
    public func convert(_ amount: Double, from: String, to: String) -> Double? {
        guard let source = rates[from.uppercased()], let target = rates[to.uppercased()], source > 0 else {
            return nil
        }
        return amount / source * target
    }
}

/// The rates saved on the phone. A file in Application Support, never in a backup. Holds rates only: no amount, no
/// currency he used, nothing of his.
public struct RatesCache: Sendable {
    public let url: URL?
    /// The last time a fetch was tried (success or not), so a page opening never fetches more than once an hour.
    public static let minimumInterval: TimeInterval = 3600

    public init(url: URL? = RatesCache.defaultURL) {
        self.url = url
    }

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/currency-rates.json")
    }

    private struct Saved: Codable {
        var table: CurrencyRates
        var fetchedAt: Date
    }

    public func read() -> (table: CurrencyRates, fetchedAt: Date)? {
        guard let url, let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return nil }
        return (saved.table, saved.fetchedAt)
    }

    public func write(_ table: CurrencyRates, fetchedAt: Date) {
        guard let url, let data = try? JSONEncoder().encode(Saved(table: table, fetchedAt: fetchedAt)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: [.atomic])
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }

    /// The attempt file beside the table: the time of the last try, success or not, so a failing network is not
    /// retried on every page open, nor on every launch.
    var attemptURL: URL? {
        url.map { $0.deletingPathExtension().appendingPathExtension("attempt") }
    }

    public func lastAttempt() -> Date? {
        guard let attemptURL, let data = try? Data(contentsOf: attemptURL),
              let seconds = try? JSONDecoder().decode(Double.self, from: data) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    public func noteAttempt(at date: Date) {
        guard let attemptURL, let data = try? JSONEncoder().encode(date.timeIntervalSince1970) else { return }
        try? FileManager.default.createDirectory(at: attemptURL.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: attemptURL, options: [.atomic])
        var excluded = attemptURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }

    /// Whether a fetch is due: nothing tried or saved in the last hour.
    public func isFetchDue(now: Date) -> Bool {
        let last = [read()?.fetchedAt, lastAttempt()].compactMap(\.self).max()
        guard let last else { return true }
        return now.timeIntervalSince(last) >= Self.minimumInterval
    }

    /// The table to use now: whatever is saved (live or old), with its date. Nil when nothing was ever saved: the
    /// money wheel then stops.
    public func current() -> CurrencyRates? {
        read()?.table
    }
}

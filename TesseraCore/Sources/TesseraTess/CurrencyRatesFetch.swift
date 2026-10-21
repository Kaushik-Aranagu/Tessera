import Foundation
import TesseraCore

/// The one network call for the money wheel: the ECB's euro reference rates, a plain GET of a public daily file. The
/// request carries nothing of his (no amount, no currency he used, no query, no body, no key), never goes through
/// Claude, and what comes back is cached on the phone (`RatesCache`). Fetched when a page showing money opens, and at
/// most once an hour while the app stays up. Rates are published on ECB working days, so the date shown can be a
/// weekend behind. This file is the only place the app talks to this host.
@MainActor
public final class CurrencyRatesFetch {
    public static let url =
        URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")! // swiftlint:disable:this force_unwrapping

    public let cache: RatesCache
    public let session: URLSession
    public var now: () -> Date = { .now }
    public var timeout: TimeInterval = 8
    private var lastAttempt: Date?

    public init(cache: RatesCache = RatesCache(), session: URLSession = URLSession(configuration: .ephemeral)) {
        self.cache = cache
        self.session = session
    }

    /// The table to use now. Fetches first when one is due (nothing saved, or the last try over an hour ago); with
    /// no connection or a bad answer the last saved table stands, with its own date. Nil only when nothing was ever
    /// saved: the money wheel stops.
    public func refreshIfNeeded() async -> CurrencyRates? {
        let moment = now()
        let due = cache
            .isFetchDue(now: moment) &&
            (lastAttempt.map { moment.timeIntervalSince($0) >= RatesCache.minimumInterval } ?? true)
        if due {
            lastAttempt = moment
            if let table = await fetch() {
                cache.write(table, fetchedAt: moment)
                return table
            }
        }
        return cache.current()
    }

    func fetch() async -> CurrencyRates? {
        var request = URLRequest(url: Self.url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await session.data(for: request, delegate: NoRedirects.shared),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return Self.parse(data)
    }

    /// `<Cube time='2026-10-20'>` then `<Cube currency='USD' rate='1.1670'/>` rows.
    nonisolated static func parse(_ data: Data) -> CurrencyRates? {
        guard let xml = String(data: data, encoding: .utf8),
              let day = xml.firstMatch(of: /<Cube time=['"](\d{4})-(\d{2})-(\d{2})['"]/) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let date = calendar.date(from: DateComponents(year: Int(day.1), month: Int(day.2), day: Int(day.3),
                                                            hour: 12)) else { return nil }
        var rates: [String: Double] = [:]
        for match in xml.matches(of: /<Cube currency=['"]([A-Z]{3})['"] rate=['"]([0-9.]+)['"]/) {
            if let rate = Double(match.2), rate > 0 {
                rates[String(match.1)] = rate
            }
        }
        return rates.isEmpty ? nil : CurrencyRates(rates: rates, date: date)
    }
}

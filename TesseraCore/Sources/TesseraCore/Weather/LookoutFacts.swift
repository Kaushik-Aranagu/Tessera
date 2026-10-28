import Foundation

/// The facts the Lookout's level pages read (Design's lookout checklist): rain chance, wind and gusts, humidity,
/// air, pressure, the sun and the moon. Plain values and the short words beside them; no place is ever named.
public struct LookoutFacts: Equatable, Sendable {
    public enum Trend: String, Sendable {
        case rising, falling, steady
    }

    /// The most likely rain in the next 12 hours, 0 to 100, and when it peaks.
    public let rainChance: Int
    public let rainPeaksAt: Date?
    public let windKph: Double
    public let gustKph: Double
    /// "west", "north-east"; nil with no direction.
    public let windFrom: String?
    /// Gusts well above the steady wind (8 km/h or more).
    public let isGusting: Bool
    public let humidity: Int?
    public let humidityTrend: Trend
    public let pressureHpa: Double?
    public let pressureTrend: Trend
    /// How fast the pressure moves: a change under 3 hPa in six hours is "slowly".
    public let pressureIsSlow: Bool
    public let aqi: Int?
    public let aqiWord: String?
    public let sunrise: Date?
    public let sunset: Date?
    public let moon: MoonPhase
    /// Today's daylight in minutes, and how it differs from tomorrow's (negative: tomorrow is shorter).
    public let daylightMinutes: Int?
    public let daylightChangeMinutes: Int?
    /// Rain is coming within 12 hours.
    public let rainSoon: Bool

    /// "Falling slowly", "Rising", "Steady".
    public var pressureWords: String {
        switch pressureTrend {
        case .steady: "Steady"
        case .rising: pressureIsSlow ? "Rising slowly" : "Rising"
        case .falling: pressureIsSlow ? "Falling slowly" : "Falling"
        }
    }

    /// "Rising toward rain", "Rising", "Falling", "Steady".
    public var humidityWords: String {
        switch humidityTrend {
        case .steady: "Steady"
        case .falling: "Falling"
        case .rising: rainSoon ? "Rising toward rain" : "Rising"
        }
    }

    /// "From the west, gusting", "From the west", or "Calm" under 3 km/h.
    public var windWords: String {
        guard windKph >= 3 else { return "Calm" }
        let from = windFrom.map { "From the \($0)" } ?? "Wind"
        return isGusting ? "\(from), gusting" : from
    }

    /// "Two minutes less", "A minute more", "Same as today".
    public var daylightWords: String? {
        guard let change = daylightChangeMinutes else { return nil }
        if change == 0 {
            return "Same as today"
        }
        let size = abs(change)
        let words = ["", "A minute", "Two minutes", "Three minutes", "Four minutes", "Five minutes"]
        let amount = size < words.count ? words[size] : "\(size) minutes"
        return "\(amount) \(change < 0 ? "less" : "more")"
    }
}

public extension WeatherReport {
    /// The Lookout's facts as of `date`. Trends read the next six hours; "rain soon" the next twelve.
    func lookoutFacts(at date: Date, calendar: Calendar = .current) -> LookoutFacts {
        let ahead = hourly.filter { $0.time >= date.addingTimeInterval(-3600) }
        let twelve = Array(ahead.prefix(12))
        let peak = twelve.max { $0.precipitationChance < $1.precipitationChance }
        let six = ahead.first { $0.time >= date.addingTimeInterval(6 * 3600) } ?? ahead.last

        func trend(_ start: Double?, _ end: Double?, steadyWithin limit: Double) -> LookoutFacts.Trend {
            guard let start, let end else { return .steady }
            return end - start >= limit ? .rising : start - end >= limit ? .falling : .steady
        }
        let pressureStart = now.pressureHpa ?? ahead.first?.pressureHpa
        let pressureEnd = six?.pressureHpa
        let pressureDelta = abs((pressureEnd ?? 0) - (pressureStart ?? 0))
        let today = daily.first { calendar.isDate($0.date, inSameDayAs: date) } ?? daily.first
        let tomorrow = today.flatMap { day in daily.first { $0.date > day.date } }
        func daylight(_ day: Day?) -> Int? {
            guard let rise = day?.sunrise, let set = day?.sunset else { return nil }
            return Int((set.timeIntervalSince(rise) / 60).rounded())
        }
        let todayMinutes = daylight(today)
        let change = todayMinutes.flatMap { mine in daylight(tomorrow).map { $0 - mine } }
        return LookoutFacts(
            rainChance: peak?.precipitationChance ?? 0,
            rainPeaksAt: (peak?.precipitationChance ?? 0) > 0 ? peak?.time : nil,
            windKph: now.windKph, gustKph: now.gustKph, windFrom: now.windFrom,
            isGusting: now.gustKph - now.windKph >= 8, humidity: now.humidity,
            humidityTrend: trend(now.humidity.map(Double.init), six?.humidity.map(Double.init), steadyWithin: 5),
            pressureHpa: now.pressureHpa, pressureTrend: trend(pressureStart, pressureEnd, steadyWithin: 1),
            pressureIsSlow: pressureDelta < 3, aqi: air?.usAQI, aqiWord: air?.category, sunrise: today?.sunrise,
            sunset: today?.sunset, moon: MoonPhase(on: date), daylightMinutes: todayMinutes,
            daylightChangeMinutes: change, rainSoon: twelve.contains { $0.condition.isPrecipitation }
        )
    }
}

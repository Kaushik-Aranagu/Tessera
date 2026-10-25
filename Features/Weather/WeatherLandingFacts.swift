import Foundation
import TesseraCore

// The Weather landing's facts (sheet 243 on the landing contract), the pure part: what the sky is now, the next
// hours, the week and the air, and every line the page says, longest form first. No city is ever named here.
//
// There is no live forecast in the app yet: Open-Meteo lives on unmerged branches (core/weather, #1401, #1402). Until
// it lands the landing reads the same deterministic sample the Home mosaic reads (`SampleWeatherSource`), says so in
// its brief, and keeps the house rules for the fetcher in one place (`WeatherFetchRules`).

/// The rules the live source must keep: free Open-Meteo only, the coordinate rounded to 0.1 degree before it leaves
/// the phone, one fetch per 30 minutes. Nothing keeps the coordinate; no city is looked up or shown.
enum WeatherFetchRules {
    static let host = "api.open-meteo.com"
    static let cacheLife: TimeInterval = 30 * 60

    /// 0.1 degree, about 11 km: the only precision that ever leaves the phone.
    static func rounded(_ degrees: Double) -> Double {
        (degrees * 10).rounded() / 10
    }

    static func isFresh(fetchedAt: Date?, now: Date) -> Bool {
        guard let fetchedAt else { return false }
        let age = now.timeIntervalSince(fetchedAt)
        return age >= 0 && age < cacheLife
    }
}

/// One hour of the forecast.
struct WeatherHour: Equatable {
    let date: Date
    let temperature: Int
    let kind: WeatherKind
}

/// One day of the week.
struct WeatherDay: Equatable {
    let date: Date
    let high: Int
    let low: Int
    let kind: WeatherKind
}

/// What the landing is drawn from.
struct WeatherSnapshot: Equatable {
    var now: Date
    var temperature: Int
    var feelsLike: Int
    var high: Int
    var low: Int
    var fahrenheit: Bool
    var kind: WeatherKind
    var hours: [WeatherHour]
    var week: [WeatherDay]
    /// "good", "fair", "poor".
    var air: String
    var uvIndex: Int
    var wind: Int
    var isSample: Bool
    var fetchedAt: Date

    var night: Bool {
        WeatherKind.isNight(at: now)
    }
}

/// The sample snapshot, built on the mosaic's `SampleWeatherSource` so Home and the room never disagree.
@MainActor
enum WeatherSample {
    private static var cached: WeatherSnapshot?

    /// One snapshot per 30 minutes, like the live source will keep.
    static func snapshot(now: Date, fahrenheit: Bool = Locale.current.measurementSystem == .us,
                         calendar: Calendar = .current) -> WeatherSnapshot
    {
        if let cached, cached.fahrenheit == fahrenheit, WeatherFetchRules.isFresh(
            fetchedAt: cached.fetchedAt,
            now: now
        ) {
            var kept = cached
            kept.now = now
            return kept
        }
        let made = make(now: now, fahrenheit: fahrenheit, calendar: calendar)
        cached = made
        return made
    }

    static func make(now: Date, fahrenheit: Bool, calendar: Calendar = .current) -> WeatherSnapshot {
        let source = SampleWeatherSource(fahrenheit: fahrenheit)
        let reading = source.reading(now: now)
        let hourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let hours = (1 ... 12).map { step -> WeatherHour in
            let date = calendar.date(byAdding: .hour, value: step, to: hourStart) ?? now
            let temperature = source.reading(now: date)?.temperature ?? 0
            return WeatherHour(date: date, temperature: temperature,
                               kind: kind(for: date, now: now, calendar: calendar))
        }
        let today = calendar.startOfDay(for: now)
        let highs = reading?.week ?? Array(repeating: 0, count: 7)
        let week = highs.enumerated().map { offset, high -> WeatherDay in
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            let noon = calendar.date(byAdding: .hour, value: 13, to: date) ?? date
            return WeatherDay(date: date, high: high, low: high - (fahrenheit ? 12 : 7),
                              kind: dayKind(noon, calendar: calendar))
        }
        let temperature = reading?.temperature ?? 0
        let hour = calendar.component(.hour, from: now)
        let uvIndex = (8 ..< 18).contains(hour) ? max(1, 6 - abs(13 - hour)) : 0
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        let wind = (fahrenheit ? 5 : 8) + (day * 3) % (fahrenheit ? 9 : 14)
        return WeatherSnapshot(now: now, temperature: temperature, feelsLike: temperature - 2,
                               high: max(week.first?.high ?? temperature, temperature),
                               low: min(week.first?.low ?? temperature, temperature), fahrenheit: fahrenheit,
                               kind: kind(for: now, now: now, calendar: calendar), hours: hours, week: week,
                               air: day % 5 == 4 ? "fair" : "good", uvIndex: uvIndex, wind: wind, isSample: true,
                               fetchedAt: now)
    }

    /// The day's sky from the mosaic's rule, then the change it says is coming a few hours on.
    private static func kind(for date: Date, now: Date, calendar: Calendar) -> WeatherKind {
        let base = dayKind(now, calendar: calendar)
        let ahead = calendar.dateComponents([.hour], from: now, to: date).hour ?? 0
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        switch base {
        case .rain: return ahead >= 3 ? .partlyCloudy : .rain
        case .snow: return ahead >= 5 ? .mainlyClear : .snow
        default:
            // The mosaic's clear days bring rain about four hours on, every other day.
            if day % 2 == 0, ahead >= 4, ahead < 7 {
                return .rain
            }
            return base
        }
    }

    private static func dayKind(_ date: Date, calendar: Calendar) -> WeatherKind {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        if day % 7 == 3 {
            return .rain
        }
        if day % 11 == 5 {
            return .snow
        }
        return [WeatherKind.clear, .partlyCloudy, .mainlyClear, .overcast][day % 4]
    }
}

/// Every word and line the landing says.
enum WeatherWords {
    // swiftlint:disable:next cyclomatic_complexity
    /// The keystone word, longest first ("Partly cloudy", then "Cloudy").
    static func condition(_ kind: WeatherKind, night: Bool) -> [String] {
        switch kind {
        case .clear: [night ? "Clear" : "Sunny"]
        case .mainlyClear: ["Mostly clear", "Clear"]
        case .partlyCloudy: ["Partly cloudy", "Cloudy"]
        case .overcast: ["Overcast", "Grey"]
        case .fog: ["Fog"]
        case .drizzle: ["Drizzle"]
        case .rain: ["Rain"]
        case .heavyRain: ["Heavy rain", "Rain"]
        case .freezingDrizzle: ["Freezing drizzle", "Ice"]
        case .freezingRain: ["Freezing rain", "Ice"]
        case .snow: ["Snow"]
        case .heavySnow: ["Heavy snow", "Snow"]
        case .snowGrains: ["Snow grains", "Snow"]
        case .thunderstorm: ["Thunderstorm", "Storm"]
        case .thunderstormHail: ["Hail"]
        }
    }

    static func name(_ kind: WeatherKind, night: Bool) -> String {
        condition(kind, night: night)[0]
    }

    static func isWet(_ kind: WeatherKind) -> Bool {
        switch kind {
        case .drizzle, .rain, .heavyRain, .freezingDrizzle, .freezingRain, .thunderstorm, .thunderstormHail: true
        default: false
        }
    }

    /// "4 pm", "12 am": the house hour.
    static func hour(_ date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let shown = hour % 12 == 0 ? 12 : hour % 12
        return "\(shown) \(hour < 12 ? "am" : "pm")"
    }

    static func degrees(_ value: Int) -> String {
        "\(value)°"
    }

    /// The first change of sky in the next hours: "Rain from 4 pm" / "Dry by 7 pm" / nil.
    static func change(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> String? {
        let nowWet = isWet(snapshot.kind)
        if nowWet {
            guard let dry = snapshot.hours.first(where: { !isWet($0.kind) }) else { return nil }
            return "dry by \(hour(dry.date, calendar: calendar))"
        }
        guard let wet = snapshot.hours.first(where: { isWet($0.kind) }) else { return nil }
        return "\(name(wet.kind, night: false).lowercased()) from \(hour(wet.date, calendar: calendar))"
    }

    /// The header line, longest first: never wraps, never ellipsizes (FitLine picks).
    static func stateLine(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> [String] {
        let now = degrees(snapshot.temperature)
        let feels = "feels like \(degrees(snapshot.feelsLike))"
        let range = "high \(degrees(snapshot.high)), low \(degrees(snapshot.low))"
        var forms: [String] = []
        if let change = change(snapshot, calendar: calendar) {
            forms.append("\(now), \(feels), \(range), \(change).".capitalizedFirst)
            forms.append("\(now), \(range), \(change).")
            forms.append("\(now), \(change).")
        }
        forms.append("\(now), \(feels), \(range).")
        forms.append("\(now), \(range).")
        forms.append("\(now) now.")
        return forms.sorted { $0.count > $1.count }
    }

    /// The brief at 612: when it changes, plainly; a sample says it is one.
    static func brief(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> (lead: String, rest: String) {
        if snapshot.isSample {
            return ("Sample sky", " until the live forecast is on.")
        }
        if let change = change(snapshot, calendar: calendar) {
            return (change.capitalizedFirst, ".")
        }
        return ("Steady", " for the next 12 hours.")
    }

    static func windUnit(_ fahrenheit: Bool) -> String {
        fahrenheit ? "mph" : "km/h"
    }

    /// The Air door's lines.
    static func airLines(_ snapshot: WeatherSnapshot) -> [String] {
        ["Air is \(snapshot.air)", "UV \(snapshot.uvIndex)", "Wind \(snapshot.wind) \(windUnit(snapshot.fahrenheit))"]
    }

    /// The Hours door: the next three hours, one line each ("4 pm 58° rain").
    static func hourLines(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> [String] {
        snapshot.hours.prefix(3).map {
            "\(hour($0.date, calendar: calendar)) \(degrees($0.temperature)) \(name($0.kind, night: false).lowercased())"
        }
    }

    /// The Week door: only the notable days, by name ("Saturday rain").
    static func weekLines(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> [String] {
        let days = snapshot.week.dropFirst()
        let notable = days.filter { $0.kind != snapshot.kind && $0.kind != .clear }
        let picked = (notable.isEmpty ? Array(days.prefix(2)) : Array(notable.prefix(3)))
        return picked.map { day in
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.date) - 1]
            return "\(weekday) \(name(day.kind, night: false).lowercased())"
        }
    }

    /// Every line the page can show, for the no-city test.
    static func allLines(_ snapshot: WeatherSnapshot) -> [String] {
        let brief = brief(snapshot)
        return stateLine(snapshot) + [brief.lead + brief.rest] + airLines(snapshot) + hourLines(snapshot)
            + weekLines(snapshot) + condition(snapshot.kind, night: snapshot.night)
    }
}

/// The on-phone Rain alert switch (243): kept in UserDefaults on this phone only, never in a backup. The live source
/// schedules the "30 minutes before rain" notice when it lands; until then the switch only remembers his choice.
enum WeatherRainAlert {
    static let key = "weather.rainAlert"

    static func isOn(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key)
    }

    static func set(_ on: Bool, _ defaults: UserDefaults = .standard) {
        defaults.set(on, forKey: key)
    }

    static func receipt(on: Bool) -> String {
        on ? "Rain alert on. You'll hear 30 minutes before rain." : "Rain alert off."
    }
}

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

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
        let todays = hours.filter { calendar.isDate($0.date, inSameDayAs: now) }
        let hour = calendar.component(.hour, from: now)
        let uvIndex = (8 ..< 18).contains(hour) ? max(1, 6 - abs(13 - hour)) : 0
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        let wind = (fahrenheit ? 5 : 8) + (day * 3) % (fahrenheit ? 9 : 14)
        return WeatherSnapshot(now: now, temperature: temperature, feelsLike: temperature - 2,
                               high: ([week.first?.high ?? temperature, temperature] + todays.map(\.temperature)).max()
                                   ?? temperature,
                               low: ([week.first?.low ?? temperature, temperature] + todays.map(\.temperature)).min()
                                   ?? temperature, fahrenheit: fahrenheit,
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

    /// The shortest word, for the dial's 150 pt fact lines ("cloudy", "ice").
    static func short(_ kind: WeatherKind, night: Bool) -> String {
        condition(kind, night: night).last ?? name(kind, night: night)
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
        briefForms(snapshot, calendar: calendar)[0]
    }

    /// The brief's forms, longest first; the last always fits at AX5.
    static func briefForms(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> [(
        lead: String,
        rest: String
    )] {
        if snapshot.isSample {
            return [("Sample sky", " until the live forecast is on."), ("Sample sky", ".")]
        }
        if let change = change(snapshot, calendar: calendar) {
            return [(change.capitalizedFirst, ".")]
        }
        return [("Steady", " for the next 12 hours."), ("Steady", ".")]
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
            "\(hour($0.date, calendar: calendar)) \(degrees($0.temperature)) \(short($0.kind, night: false).lowercased())"
        }
    }

    /// The Week door: only the notable days, by name ("Saturday rain").
    static func weekLines(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> [String] {
        let days = snapshot.week.dropFirst()
        let notable = days.filter { $0.kind != snapshot.kind && $0.kind != .clear }
        let picked = (notable.isEmpty ? Array(days.prefix(2)) : Array(notable.prefix(3)))
        return picked.map { day in
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.date) - 1]
            return "\(weekday) \(short(day.kind, night: false).lowercased())"
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
extension WeatherWords {
    /// The foot's object under "Alert": what it alerts about, and whether it is on.
    static func alertObject(on: Bool) -> String {
        on ? "Rain, on" : "Rain"
    }

    /// Tess's walk line: the dry daylight hour nearest a comfortable temperature in the next hours. Says nothing
    /// about a place; writes nothing.
    static func walkLine(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> String {
        let comfortable = snapshot.fahrenheit ? 65 : 18
        let daylight = snapshot.hours.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return hour >= 6 && hour <= 20 && !isWet($0.kind)
        }
        guard let best = daylight.min(by: {
            abs($0.temperature - comfortable) != abs($1.temperature - comfortable)
                ? abs($0.temperature - comfortable) < abs($1.temperature - comfortable) : $0.date < $1.date
        }) else {
            return "No dry daylight hour for a walk soon."
        }
        return "Best walk around \(hour(best.date, calendar: calendar)), \(degrees(best.temperature)) and dry."
    }
}

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

// MARK: - Lookout (sheet 283): the sky behind the page, the switcher's needs and the widget's items

/// The page sky, drawn by hour and condition until the photo plates land (256). Two stops (top, then the colour it
/// settles to by 520 pt), each in a light and a dark half, so ink stays readable on it in both looks.
enum LookoutSky {
    enum Hour: Equatable { case dawn, day, dusk, night }

    struct Stops: Equatable {
        let top: UInt32
        let bottom: UInt32
    }

    /// The point down the page where the sky reaches its lower colour; below it the colour holds.
    static let settle: CGFloat = 520

    static func hour(_ date: Date, calendar: Calendar = .current) -> Hour {
        switch calendar.component(.hour, from: date) {
        case 5 ..< 8: .dawn
        case 8 ..< 17: .day
        case 17 ..< 21: .dusk
        default: .night
        }
    }

    /// Wet, grey or snowy skies take over from the hour; clear and broken skies wear the hour's colour.
    static func stops(kind: WeatherKind, hour: Hour, dark: Bool) -> Stops {
        switch kind {
        case .overcast, .fog:
            dark ? Stops(top: 0x2A2D33, bottom: 0x17181B) : Stops(top: 0xD9DCE0, bottom: 0xF1F2F3)
        case .drizzle, .rain, .heavyRain, .freezingDrizzle, .freezingRain, .thunderstorm, .thunderstormHail:
            dark ? Stops(top: 0x1F2933, bottom: 0x121519) : Stops(top: 0xC9D3DC, bottom: 0xECEFF2)
        case .snow, .heavySnow, .snowGrains:
            dark ? Stops(top: 0x262C36, bottom: 0x15181D) : Stops(top: 0xE3E8EE, bottom: 0xF7F8FA)
        case .clear, .mainlyClear, .partlyCloudy:
            switch hour {
            case .dawn: dark ? Stops(top: 0x3A2A35, bottom: 0x1E1A22) : Stops(top: 0xF6DCCB, bottom: 0xF9EFE6)
            case .day: dark ? Stops(top: 0x1E3550, bottom: 0x141C26) : Stops(top: 0xCFE3F5, bottom: 0xF3F7FA)
            case .dusk: dark ? Stops(top: 0x3A2443, bottom: 0x1A1520) : Stops(top: 0xE8D3E6, bottom: 0xF8E9DC)
            case .night: dark ? Stops(top: 0x0E1424, bottom: 0x0A0C12) : Stops(top: 0xD5DAE6, bottom: 0xEEF0F5)
            }
        }
    }

    /// Relative luminance of a colour, for the contrast test (WCAG).
    static func luminance(_ hex: UInt32) -> Double {
        func channel(_ value: UInt32) -> Double {
            let scaled = Double(value) / 255
            return scaled <= 0.03928 ? scaled / 12.92 : pow((scaled + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(hex >> 16 & 0xFF) + 0.7152 * channel(hex >> 8 & 0xFF) + 0.0722 * channel(hex & 0xFF)
    }

    static func contrast(_ first: UInt32, _ second: UInt32) -> Double {
        let (lighter, darker) = (max(luminance(first), luminance(second)), min(luminance(first), luminance(second)))
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// One widget item's words (the view adds colours).
struct LookoutCard: Equatable {
    enum Opens: Equatable { case hours, week }

    let id: String
    let header: String
    let big: String
    let bigIsNumber: Bool
    let unit: String?
    let middle: String
    let small: String
    let opens: Opens
    let wet: Bool
}

extension WeatherWords {
    static let switcher = ["Now", "Tonight", "Tomorrow", "This week"]

    /// Tonight's temperature: the 9 pm hour when the forecast reaches it, else the day's low.
    static func tonight(_ snapshot: WeatherSnapshot, calendar: Calendar = .current) -> Int {
        snapshot.hours.first { calendar.component(.hour, from: $0.date) == 21 }?.temperature ?? snapshot.low
    }

    static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
    }

    /// The day the week card names: the first notable day after tomorrow, else three days on.
    static func notableDay(_ snapshot: WeatherSnapshot) -> WeatherDay? {
        let later = snapshot.week.dropFirst(2)
        return later.first { $0.kind != snapshot.kind && $0.kind != .clear } ?? later.dropFirst().first ?? later.first
    }

    /// The two needs lines beside the switcher, for each of its words. Never a city.
    static func needs(_ snapshot: WeatherSnapshot, switcher index: Int, calendar: Calendar = .current) -> [String] {
        switch index {
        case 1:
            let night = name(snapshot.hours.first { calendar.component(.hour, from: $0.date) == 21 }?.kind
                ?? snapshot.kind, night: true).lowercased()
            return ["Tonight \(degrees(tonight(snapshot, calendar: calendar)))", "\(night) after dark".capitalizedFirst]
        case 2:
            guard snapshot.week.count > 1 else { return ["Tomorrow", "No forecast yet"] }
            let day = snapshot.week[1]
            return ["Tomorrow \(degrees(day.high))",
                    "Low \(degrees(day.low)), \(short(day.kind, night: false).lowercased())"]
        case 3:
            let lines = weekLines(snapshot, calendar: calendar)
            let warmest = snapshot.week.dropFirst().max { $0.high < $1.high }
            return [lines.first?.capitalizedFirst ?? "A steady week",
                    warmest.map { "High \(degrees($0.high)) \(weekday($0.date, calendar: calendar))" } ?? ""]
        default:
            let word = name(snapshot.kind, night: snapshot.night)
            return ["\(word), \(degrees(snapshot.temperature))",
                    change(snapshot, calendar: calendar)?.capitalizedFirst ?? "Steady for now"]
        }
    }

    /// The widget's items (283): what is coming, tonight, and a day to note. Lookout has no strike.
    static func cards(_ snapshot: WeatherSnapshot, alertOn: Bool, calendar: Calendar = .current) -> [LookoutCard] {
        var cards: [LookoutCard] = []
        let wetHour = isWet(snapshot.kind) ? nil : snapshot.hours.first { isWet($0.kind) }
        if let wetHour {
            cards.append(LookoutCard(id: "coming", header: "Coming", big: name(wetHour.kind, night: false),
                                     bigIsNumber: false, unit: nil,
                                     middle: "from \(hour(wetHour.date, calendar: calendar))",
                                     small: alertOn ? "Rain alert is on" : "Rain alert is off",
                                     opens: .hours, wet: true))
        } else if let change = change(snapshot, calendar: calendar) {
            cards.append(LookoutCard(id: "coming", header: "Coming", big: "Dry", bigIsNumber: false, unit: nil,
                                     middle: change.replacingOccurrences(of: "dry ", with: ""),
                                     small: "Rain until then", opens: .hours, wet: false))
        } else {
            cards.append(LookoutCard(id: "coming", header: "Coming", big: "Steady", bigIsNumber: false, unit: nil,
                                     middle: "for the next 12 hours", small: "No rain in the hours ahead",
                                     opens: .hours, wet: false))
        }
        let nightKind = snapshot.hours.first { calendar.component(.hour, from: $0.date) == 21 }?.kind ?? snapshot.kind
        cards.append(LookoutCard(id: "tonight", header: "Tonight", big: "\(tonight(snapshot, calendar: calendar))",
                                 bigIsNumber: true, unit: "°", middle: name(nightKind, night: true),
                                 small: "Low \(degrees(snapshot.low)) before morning", opens: .hours,
                                 wet: isWet(nightKind)))
        if let day = notableDay(snapshot) {
            cards.append(LookoutCard(id: "day", header: weekday(day.date, calendar: calendar), big: "\(day.high)",
                                     bigIsNumber: true, unit: "°", middle: name(day.kind, night: false),
                                     small: "Low \(degrees(day.low))", opens: .week, wet: isWet(day.kind)))
        }
        return cards
    }
}

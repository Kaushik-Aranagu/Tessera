import SwiftUI
import TesseraCore

// Home 236 v2.4 and v2.5: the weather words and their effects. One effect per case; the word's colour follows its
// cloud. Clouds sit behind the word (in front there is only a 10% veil), fog masks the word where the mist is thick
// (never below 30% opacity), and the wind warning sways at 1.35x. Reduce Motion: no effects, only the colour.
// This file is the pure part: the kinds, the colours and the plan of what each case draws, so every case tests without
// a screen. `WeatherKind` has the case names of Core's WeatherCondition and maps to it when Core's enum is on the base.

/// The weather tokens by name (DesignSystem/WeatherTokens.swift holds the colours).
enum WeatherToken: Equatable, Sendable {
    case pcloud, moon, fog, ice, storm, rain, warn, bolt

    var colour: Color {
        switch self {
        case .pcloud: Theme.Colors.Weather.pcloud
        case .moon: Theme.Colors.Weather.moon
        case .fog: Theme.Colors.Weather.fog
        case .ice: Theme.Colors.Weather.ice
        case .storm: Theme.Colors.Weather.storm
        case .rain: Theme.Colors.Weather.rain
        case .warn: Theme.Colors.Weather.warn
        case .bolt: Theme.Colors.Weather.bolt
        }
    }
}

enum WeatherKind: String, CaseIterable, Equatable, Sendable {
    case clear, mainlyClear, partlyCloudy, overcast, fog
    case drizzle, rain, heavyRain
    case freezingDrizzle, freezingRain
    case snow, heavySnow, snowGrains
    case thunderstorm, thunderstormHail

    /// Night, for the moon and the stars: before 6 and from 8 in the evening.
    static func isNight(at date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 20
    }

    /// A weather word from a notice's own words, until Core hands the condition over: "Rain from 4 PM", "Snow
    /// tonight", "Thunderstorms", "Fog". Nil when the words name no weather (Sunset keeps its sky).
    static func infer(from text: String) -> WeatherKind? {
        let words = text.lowercased()
        func has(_ parts: String...) -> Bool {
            parts.contains { words.contains($0) }
        }
        if has("hail") {
            return .thunderstormHail
        }
        if has("thunder", "storm") {
            return .thunderstorm
        }
        if has("freezing rain") {
            return .freezingRain
        }
        if has("freezing drizzle", "freezing") {
            return .freezingDrizzle
        }
        if has("snow grain") {
            return .snowGrains
        }
        if has("heavy snow", "blizzard") {
            return .heavySnow
        }
        if has("snow", "flurr") {
            return .snow
        }
        if has("heavy rain", "downpour") {
            return .heavyRain
        }
        if has("drizzle") {
            return .drizzle
        }
        if has("rain", "shower") {
            return .rain
        }
        if has("fog", "mist") {
            return .fog
        }
        if has("overcast") {
            return .overcast
        }
        if has("partly cloudy", "partly sunny") {
            return .partlyCloudy
        }
        if has("mainly clear", "mostly clear") {
            return .mainlyClear
        }
        if has("clear", "sunny") {
            return .clear
        }
        return nil
    }

    /// The word's token: the colour of its cloud.
    func token(night: Bool) -> WeatherToken {
        switch self {
        case .clear, .mainlyClear, .partlyCloudy: night ? .moon : .pcloud
        case .overcast, .fog: .fog
        case .drizzle, .rain, .heavyRain: .rain
        case .freezingDrizzle, .freezingRain, .snow, .heavySnow, .snowGrains: .ice
        case .thunderstorm, .thunderstormHail: .storm
        }
    }

    func colour(night: Bool) -> Color {
        token(night: night).colour
    }
}

/// What rides over a word besides its weather.
enum WeatherOverlay: String, CaseIterable, Equatable, Sendable {
    case windy, windWarning, heatWarning, coldWarning

    /// The letters sway; the wind warning's is 1.35x the plain wind's, with a shiver.
    var sway: Double {
        switch self {
        case .windy: 1
        case .windWarning: 1.35
        case .heatWarning, .coldWarning: 0
        }
    }

    var token: WeatherToken? {
        switch self {
        case .windy: nil
        case .windWarning, .heatWarning: .warn
        case .coldWarning: .ice
        }
    }

    var colour: Color? {
        token?.colour
    }
}

/// Which tone a cloud is.
enum WeatherCloudTone: Equatable, Sendable {
    case white, grey, rain, storm
}

/// One flat-bottomed cumulus: where it sits across the word (0 left to 1 right), its size as a share of the word's
/// width, its alpha (laid on at one alpha) and its drift speed.
struct WeatherCloud: Equatable, Sendable {
    var tone: WeatherCloudTone
    var across: Double
    var size: Double
    var alpha: Double
    var drift: Double
}

/// Where the clouds sit, in one place so the revision slots in: the vertical centre as a share of the word's height
/// from its top. 0.5 is level with the word (v2.6); the clouds are behind the word either way.
struct WeatherCloudPlacement: Equatable, Sendable {
    var centre = 0.5
    /// A cloud is 1.1x the line's height, level with the word, clipped to its box, never wider than half of it.
    var height = 1.1
    /// The veil in front of the word, so the cloud never competes with the letters (8%).
    var veil = 0.08
    /// A white cloud is laid on at 0.9 of its alpha; grey, rain and storm clouds at 0.62.
    static let whiteAlpha = 0.9
    static let darkAlpha = 0.62

    static func alpha(_ cloud: WeatherCloud) -> Double {
        cloud.alpha * (cloud.tone == .white ? whiteAlpha : darkAlpha)
    }

    /// Rain, snow and hail start at the top of the word and fall to just under the line (v2.8).
    static let fallStart = 0.0
    static let fallEnd = 1.12
    static let widest = 0.5
    static let standard = WeatherCloudPlacement()
}

/// What a case draws. Pure data.
struct WeatherPlan: Equatable, Sendable {
    var clouds: [WeatherCloud] = []
    /// Falling strokes: how many, how long (pt), the slant (pt across per stroke), splashes at the foot.
    var strokes = 0
    var strokeLength = 0.0
    var slant = 0.0
    var splashes = false
    var flakes = 0
    var grains = 0
    var snowCap = false
    var glaze = false
    var bolt = false
    var hail = false
    /// Soft wisps in the cloud's tone drift in front of the word, clipped to it, at this alpha (v2.8).
    var wisps = 0.0
    var mist = false
    /// Soft warm shine behind a clear day's word (no rays, no moving sun) and stars on a clear night.
    var shine = false
    var stars = false
    /// Strokes and flakes are drawn in ice.
    var icy = false

    /// Seconds between bolts.
    static let boltPeriod = 5.2
    /// The fog never takes the word below this opacity.
    static let fogFloor = 0.30

    static func of(_ kind: WeatherKind, night: Bool) -> WeatherPlan {
        var plan = WeatherPlan()
        switch kind {
        case .clear:
            plan.shine = !night
            plan.stars = night
        case .mainlyClear:
            plan.shine = !night
            plan.stars = night
            plan.clouds = [WeatherCloud(tone: .white, across: 0.7, size: 0.38, alpha: 0.75, drift: 0.8)]
            plan.wisps = 0.30
        case .partlyCloudy:
            plan.clouds = [WeatherCloud(tone: .white, across: 0.3, size: 0.52, alpha: 0.7, drift: 0.7),
                           WeatherCloud(tone: .white, across: 0.78, size: 0.44, alpha: 0.78, drift: 1.0)]
            plan.wisps = 0.34
        case .overcast:
            plan.clouds = [WeatherCloud(tone: .grey, across: 0.2, size: 0.55, alpha: 0.8, drift: 0.6),
                           WeatherCloud(tone: .grey, across: 0.55, size: 0.6, alpha: 0.85, drift: 0.9),
                           WeatherCloud(tone: .grey, across: 0.88, size: 0.5, alpha: 0.8, drift: 0.7)]
            plan.wisps = 0.40
        case .fog:
            plan.mist = true
        case .drizzle:
            plan.strokes = 14
            plan.strokeLength = 5
        case .rain:
            plan.strokes = 26
            plan.strokeLength = 8
        case .heavyRain:
            plan.strokes = 44
            plan.strokeLength = 11
            plan.slant = 4
            plan.splashes = true
        case .freezingDrizzle:
            plan = of(.drizzle, night: night)
            plan.glaze = true
            plan.icy = true
        case .freezingRain:
            plan = of(.rain, night: night)
            plan.glaze = true
            plan.icy = true
        case .snow:
            plan.flakes = 20
        case .heavySnow:
            plan.flakes = 42
            plan.snowCap = true
        case .snowGrains:
            plan.grains = 36
        case .thunderstorm:
            plan.bolt = true
        case .thunderstormHail:
            plan = of(.thunderstorm, night: night)
            plan.hail = true
        }
        return plan
    }
}

/// The words of the strokes and the flash, as maths a test can read.
enum WeatherMotion {
    /// Whether a bolt is in the sky at `time`: it lasts a quarter of a second at the start of each period.
    static func boltPhase(at time: TimeInterval) -> Double? {
        let into = time.truncatingRemainder(dividingBy: WeatherPlan.boltPeriod)
        return into < 0.25 ? into / 0.25 : nil
    }

    /// How bright the word flashes at `time`: 1 at the strike, easing to 0 over a quarter second.
    static func flash(at time: TimeInterval) -> Double {
        boltPhase(at: time).map { 1 - $0 } ?? 0
    }

    /// The fog's opacity for the word at a point `across` (0 to 1) and `time`: a moving horizontal mask, never below
    /// the
    /// floor.
    static func fogOpacity(row: Double, time: TimeInterval) -> Double {
        let wave = 0.5 + 0.5 * sin(row * 9 + time * 0.8)
        return WeatherPlan.fogFloor + (1 - WeatherPlan.fogFloor) * (1 - 0.85 * wave)
    }

    /// The sway of the letters at `time`, in points, for an overlay's strength.
    static func sway(_ overlay: WeatherOverlay, at time: TimeInterval) -> Double {
        overlay.sway * 1.6 * sin(time * 2.2)
    }

    /// A stroke's place down the word (0 top to 1 foot) at `time`; each has its own speed and offset from its index.
    static func fall(index: Int, time: TimeInterval, speed: Double) -> Double {
        let offset = Double((index * 37) % 100) / 100
        return (time * speed * (0.8 + Double(index % 5) * 0.1) + offset).truncatingRemainder(dividingBy: 1)
    }
}

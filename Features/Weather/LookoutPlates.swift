import SwiftUI
import UIKit

/// The Lookout's page sky (283, 254-256): a real photographed plate by condition and hour band, graded so the page's
/// text always reads, and the text colour taken from the plate. The plates are the CC0 first working set in
/// `Resources/WeatherPlates` (README in docs/handoff/design-sheets/weather-plates). A change of plate cross-fades over
/// 8 s; Reduce Motion shows the new plate at once and nothing moves.
struct LookoutPlate: Equatable {
    enum Band: String, Equatable, CaseIterable { case day, dusk, night }

    /// The plate set, `<condition>-<time>`, e.g. "broken-dusk".
    let set: String
    /// The file shown (without ".jpg"), one variant of the set.
    let file: String
    let band: Band
    /// The board's darkening by band and weather (night .5, rain .3, storm .5), toward the night ink 080C18.
    let darken: Double
    /// True when the page reads in light ink on this plate (the scheme turns dark for the page).
    let lightInk: Bool
    /// The grade over the plate, so the text reaches 7:1 against the plate's average light.
    let grade: (tone: UInt32, alpha: Double)

    static func == (lhs: LookoutPlate, rhs: LookoutPlate) -> Bool {
        lhs.file == rhs.file && lhs.darken == rhs.darken && lhs.lightInk == rhs.lightInk
            && lhs.grade.tone == rhs.grade.tone && lhs.grade.alpha == rhs.grade.alpha
    }

    /// The files of each set (README: `<set>-<n>.jpg`).
    static let sets: [String: [String]] = [
        "clear-day": ["clear-day-1"], "clear-dusk": ["clear-dusk-1"], "clear-night": ["clear-night-1", "clear-night-2"],
        "broken-day": ["broken-day-1", "broken-day-2"], "broken-dusk": ["broken-dusk-1"],
        "overcast-day": ["overcast-day-1"], "overcast-dusk": ["overcast-dusk-1"],
        "cloudy-night": ["cloudy-night-1"], "fog-day": ["fog-day-1"],
    ]

    /// Each plate's average colour over the part of the page that carries text (masthead and keystone, centred
    /// crop), measured from the files. The ink and the grade are worked out from it.
    static let average: [String: UInt32] = [
        "broken-day-1": 0xC2CBE0, "broken-day-2": 0xA9B6CC, "broken-dusk-1": 0x9FA1BE, "clear-day-1": 0xAFC3DA,
        "clear-dusk-1": 0xA6A4C4, "clear-night-1": 0x030610, "clear-night-2": 0x02030B, "cloudy-night-1": 0x9EABBA,
        "fog-day-1": 0xEEF4FB, "overcast-day-1": 0xBEC2CA, "overcast-dusk-1": 0x808497,
    ]

    static let nightTone: UInt32 = 0x080C18
    /// The inks the page wears on a plate (the house looks' darkest and lightest inks, the worst case).
    static let darkInk: UInt32 = 0x1D1A16
    static let lightInk: UInt32 = 0xEFE8DC
    static let target = 7.0

    /// Night first (before 6, from 8 pm), then dawn and dusk (5 to 8, 5 pm to 8 pm), else day.
    static func band(at date: Date, calendar: Calendar = .current) -> Band {
        if WeatherKind.isNight(at: date, calendar: calendar) {
            return .night
        }
        let hour = calendar.component(.hour, from: date)
        return (5 ..< 8).contains(hour) || (17 ..< 20).contains(hour) ? .dusk : .day
    }

    private enum Sky { case clear, cloudy, overcast, rain, storm, fog, snow }

    private static func sky(_ kind: WeatherKind) -> Sky {
        switch kind {
        case .clear, .mainlyClear: .clear
        case .partlyCloudy: .cloudy
        case .overcast: .overcast
        case .fog: .fog
        case .drizzle, .rain, .heavyRain, .freezingDrizzle, .freezingRain: .rain
        case .thunderstorm, .thunderstormHail: .storm
        case .snow, .heavySnow, .snowGrains: .snow
        }
    }

    /// The set for a sky and band (board 255's table).
    static func set(for kind: WeatherKind, band: Band) -> String {
        switch (sky(kind), band) {
        case (.clear, .day): "clear-day"
        case (.clear, .dusk): "clear-dusk"
        case (.clear, .night): "clear-night"
        case (.cloudy, .day), (.snow, .day): "broken-day"
        case (.cloudy, .dusk): "broken-dusk"
        case (.overcast, .day), (.rain, .day), (.storm, .day): "overcast-day"
        case (.overcast, .dusk), (.rain, .dusk), (.storm, .dusk), (.snow, .dusk): "overcast-dusk"
        case (.fog, .day), (.fog, .dusk): "fog-day"
        case (_, .night): "cloudy-night"
        }
    }

    static func darken(for kind: WeatherKind, set: String, band: Band) -> Double {
        let byBand: Double = switch band {
        case .day: 0
        case .dusk: 0.08
        case .night: set == "clear-night" ? 0 : 0.5
        }
        let byWeather: Double = switch sky(kind) {
        case .clear, .snow: 0
        case .cloudy, .overcast: 0.05
        case .rain: 0.3
        case .storm: 0.5
        case .fog: 0.08
        }
        return min(byBand + byWeather, 0.8)
    }

    /// The plate for this moment. The variant is the day's (it holds all day, then the next one), so the page never
    /// jumps between variants on a redraw. `dark` (the Black look) deepens the plate a little more.
    static func pick(kind: WeatherKind, at date: Date, dark: Bool = false, calendar: Calendar = .current)
        -> LookoutPlate
    {
        let band = band(at: date, calendar: calendar)
        let set = set(for: kind, band: band)
        let files = sets[set] ?? ["clear-day-1"]
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let file = files[day % files.count]
        let darken = min(darken(for: kind, set: set, band: band) + (dark ? 0.18 : 0), 0.85)
        let base = mix(average[file] ?? 0x9FB3C8, nightTone, darken)
        let light = contrast(lightInk, base) >= contrast(darkInk, base)
        let ink = light ? lightInk : darkInk
        let tone: UInt32 = light ? nightTone : 0xFFFFFF
        var alpha = 0.0
        while contrast(ink, mix(base, tone, alpha)) < target, alpha < 0.9 {
            alpha += 0.02
        }
        return LookoutPlate(set: set, file: file, band: band, darken: darken, lightInk: light,
                            grade: (tone, (alpha * 100).rounded() / 100))
    }

    /// The plate's average after the darkening and the grade: what the text sits on.
    var graded: UInt32 {
        let base = Self.mix(Self.average[file] ?? 0x9FB3C8, Self.nightTone, darken)
        return Self.mix(base, grade.tone, grade.alpha)
    }

    var ink: UInt32 {
        lightInk ? Self.lightInk : Self.darkInk
    }

    static func mix(_ base: UInt32, _ over: UInt32, _ alpha: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let low = Double(base >> shift & 0xFF), high = Double(over >> shift & 0xFF)
            return UInt32((low + (high - low) * alpha).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    static func contrast(_ first: UInt32, _ second: UInt32) -> Double {
        LookoutSky.contrast(first, second)
    }

    /// The plate's image from the app bundle, cached.
    @MainActor static func image(_ file: String) -> UIImage? {
        if let hit = cache[file] {
            return hit
        }
        guard let path = Bundle.main.path(forResource: file, ofType: "jpg"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        cache[file] = image
        return image
    }

    @MainActor private static var cache: [String: UIImage] = [:]
}

/// The page behind the Lookout's sections: the plate filling the page (cropped at the sides), its darkening and its
/// grade. A new plate fades in over the old one for 8 s; under Reduce Motion it is simply there.
struct LookoutPlateView: View {
    let plate: LookoutPlate
    /// The drawn sky, for a plate that is missing from the bundle.
    let fallback: AnyView

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: LookoutPlate?
    @State private var generation = 0

    static let fade: Animation = .easeInOut(duration: 8)

    var body: some View {
        let current = shown ?? plate
        ZStack {
            layer(current)
                .id(current.file + "\(current.darken)\(current.grade.alpha)")
                .zIndex(Double(generation))
                .transition(.asymmetric(insertion: .opacity, removal: .identity))
        }
        .clipped()
        .accessibilityHidden(true)
        .onChange(of: plate) { _, new in
            if reduceMotion {
                shown = new
                generation += 1
            } else {
                withTesseraAnimation(Self.fade, reduceMotion: reduceMotion) {
                    shown = new
                    generation += 1
                }
            }
        }
    }

    private func layer(_ plate: LookoutPlate) -> some View {
        ZStack {
            if let image = LookoutPlate.image(plate.file) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                fallback
            }
            Color(hex: LookoutPlate.nightTone).opacity(plate.darken)
            Color(hex: plate.grade.tone).opacity(plate.grade.alpha)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

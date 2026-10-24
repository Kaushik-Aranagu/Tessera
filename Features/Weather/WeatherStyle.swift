import SwiftUI

// CLOUD-WRITTEN, NOT COMPILED. Colors and type for the Weather room (sheet 243). Every condition wears one color in
// both rooms of the page (a word, a temperature, an hour's word). The room's title is sky amber and the go green is
// the app-wide "done / good" green, so a page never shows more than 3 or 4 colors: amber title, the condition's color,
// ink, and (on the landing) the rain color of its one action.

extension WeatherKind {
    /// Light then dark. Rain, snow and wind are the sheet's own; the rest sit between them and the amber title.
    var color: Color {
        switch self {
        case .clear: Color(light: 0x8C6F14, dark: 0xE6CB6E)
        case .partlyCloudy: Color(light: 0x7D7566, dark: 0xC4BBA6)
        case .cloudy: Color(light: 0x6F7C8A, dark: 0xA9B5C2)
        case .fog: Color(light: 0x84898F, dark: 0xB9BEC4)
        case .rain: WeatherPalette.rain
        case .heavyRain: Color(light: 0x3F6480, dark: 0x7FA3BE)
        case .storm: Color(light: 0x5B5578, dark: 0xA9A3CF)
        case .snow: Color(light: 0x6E8296, dark: 0xC9D6E2)
        case .wind: Color(light: 0x5E6E7E, dark: 0xB4C2CC)
        }
    }
}

enum WeatherPalette {
    /// The room's title: sky amber, the same as the sky word on Home.
    static var title: Color {
        Theme.Colors.Accent.skyFrom
    }

    /// The rain color: the Rain alert word and the rain words.
    static var rain: Color {
        Color(light: 0x557A93, dark: 0x9DBACE)
    }

    /// "good" in the air line: the app-wide go green.
    static var good: Color {
        Color(light: 0x25803D, dark: 0x8FC9A0)
    }
}

enum WeatherType {
    static func figtree(_ size: CGFloat, _ weight: Font.Weight = .regular,
                        relativeTo style: Font.TextStyle = .body) -> Font
    {
        Theme.Typography.face("Figtree", size: size, relativeTo: style, serif: false).weight(weight)
    }

    /// Outfit numerals: 200 from 28 pt up, 300 below, tabular (the house rule for figures).
    static func outfit(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        Theme.Typography.face("Outfit", size: size, relativeTo: style, serif: false)
            .weight(Theme.numeralWeight(size: size))
            .monospacedDigit()
    }
}

extension View {
    /// Figures carry the house tracking, -0.02 em.
    func weatherNumeral(_ size: CGFloat) -> some View {
        font(WeatherType.outfit(size, relativeTo: size > 40 ? .largeTitle : .title3))
            .tracking(-0.02 * size)
    }
}

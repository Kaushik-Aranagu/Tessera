import SwiftUI

/// The five looks' workout palettes plus `context`, for the rest Live Activity (themes.md addendum, "Live Activity").
/// Compiled into the app and the widget extension, so the extension draws the right look from the names in the
/// activity's content state, with no App Group.
struct RestPalette: Hashable {
    var ground: UInt32
    var ink: UInt32
    var signal: UInt32
    var rest: UInt32
    var tess: UInt32
    var context: UInt32
    /// The Lock Screen's tint strength and how strongly the sky washes show.
    var tintAlpha: Double = 1
    var skyLeft = 0.35
    var skyRight = 0.45

    static let porcelain = RestPalette(ground: 0x14111A, ink: 0xF5F2EC, signal: 0xFF5B3A, rest: 0xF0A500,
                                       tess: 0x8FB0FF, context: 0x6A4C9C)
    static let obsidian = RestPalette(ground: 0x000000, ink: 0xF5F2EC, signal: 0xFF5B3A, rest: 0xFFC23D,
                                      tess: 0x86B4FF, context: 0xB7A6E0)
    static let plein = RestPalette(ground: 0x1C1828, ink: 0xF3ECE0, signal: 0xD9563F, rest: 0xE8BD4C,
                                   tess: 0x9DBFE6, context: 0x7A5C8E)
    static let lacquer = RestPalette(ground: 0x0C0812, ink: 0xF1E7D6, signal: 0xF06A4C, rest: 0xE8B54A,
                                     tess: 0x8DB2FF, context: 0xC3A6DE)
    static let celadon = RestPalette(ground: 0x0E1C17, ink: 0xEEF3EF, signal: 0xEE7056, rest: 0xE2A93A,
                                     tess: 0x9DBBEA, context: 0x456680)

    /// Kaushik's Lock Screen pick (2026-10-15, live-activity.md): Cobalt sky, in every look.
    static let cobaltSky = RestPalette(ground: 0x120E1A, ink: 0xF6EFE4, signal: 0xE2603F, rest: 0xE8BD4C,
                                       tess: 0x3F7FC0, context: 0x7A5CA0, tintAlpha: 0.46, skyLeft: 0.75, skyRight: 0.45)

    static func named(_ name: String?) -> RestPalette? {
        switch name?.lowercased() {
        case "porcelain": .porcelain
        case "obsidian": .obsidian
        case "plein": .plein
        case "lacquer": .lacquer
        case "celadon": .celadon
        default: nil
        }
    }

    /// The day look by Light, the night look by Dark (Porcelain and Obsidian when the state carries none).
    static func forState(day: String?, night: String?, dark: Bool) -> RestPalette {
        dark ? named(night) ?? .obsidian : named(day) ?? .porcelain
    }

    /// The colours the face draws with.
    var cream: Color {
        Color(rgb: ink)
    }

    var vermilion: Color {
        Color(rgb: signal)
    }

    var materialTint: Color {
        Color(rgb: ground).opacity(tintAlpha)
    }

    /// Go: the sky warms to rest and signal.
    var goWash1: Color {
        Color(rgb: rest).opacity(0.75)
    }

    var goWash2: Color {
        Color(rgb: signal).opacity(0.6)
    }

    /// The rest sky: Workout.tess at 35% top-left, context at 45% top-right.
    var wash1: Color {
        Color(rgb: tess).opacity(skyLeft)
    }

    var wash2: Color {
        Color(rgb: context).opacity(skyRight)
    }

    var line: Color {
        cream
    }

    var tick: Color {
        vermilion
    }
}

extension Color {
    /// The extension's own hex initialiser (the app's lives in DesignSystem).
    init(rgb hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension EnvironmentValues {
    @Entry var restPalette: RestPalette = .obsidian
}

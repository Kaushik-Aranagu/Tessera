import SwiftUI
import TesseraCore

/// Tess in a room's colour on its landing (sheet 283: bottom right, 306,776 96x96, the room's colour, Ember only
/// while she cues). Core's director already derives her three paints from a screen's one accent; this hands it the
/// room's accent in OKLCH.
enum SoulRoomTint {
    /// Each room's landing accent, light and dark (landing contract §9).
    static func hex(_ room: AppID, dark: Bool) -> UInt32 {
        switch room {
        case .training: dark ? 0x8FB0EE : 0x0B62AE
        case .kitchen: dark ? 0xC49A5E : 0x93611A
        case .money: dark ? 0x8DBFA7 : 0x3F7A62
        case .notes, .lists: dark ? 0xE3A3CB : 0x8A4570
        case .routines: dark ? 0xD59AC4 : 0x8E4A78
        }
    }

    /// The director that paints her from `room`'s accent.
    static func director(_ room: AppID) -> CoreSoulDirector {
        CoreSoulDirector(accents: { dark in [room: oklch(hex: hex(room, dark: dark))] })
    }

    /// sRGB hex to OKLCH (Björn Ottosson's matrices), hue in degrees.
    static func oklch(hex: UInt32) -> OKLCH {
        func linear(_ channel: UInt32) -> Double {
            let value = Double(channel) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let red = linear((hex >> 16) & 0xFF), green = linear((hex >> 8) & 0xFF), blue = linear(hex & 0xFF)
        let long = cbrt(0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
        let medium = cbrt(0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
        let short = cbrt(0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
        let lightness = 0.2104542553 * long + 0.7936177850 * medium - 0.0040720468 * short
        let axisA = 1.9779984951 * long - 2.4285922050 * medium + 0.4505937099 * short
        let axisB = 0.0259040371 * long + 0.7827717662 * medium - 0.8086757660 * short
        var hue = atan2(axisB, axisA) * 180 / .pi
        if hue < 0 {
            hue += 360
        }
        return OKLCH(lightness: lightness, chroma: (axisA * axisA + axisB * axisB).squareRoot(), hue: hue)
    }
}

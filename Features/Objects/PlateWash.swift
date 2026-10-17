import Foundation

/// The plate's colours and shapes (sheet 88, imagery-88.md), pure so they test without a screen. Colours are hex
/// until Core's `Ingredient.colour` table lands; until then a plate is Kitchen green.
enum PlateWash {
    /// Kitchen green, the end of the fallback chain (`#12936A`, the kit token).
    static let kitchenGreen: UInt32 = 0x12936A
    /// Ink, for shading pale foods (Porcelain's ink).
    static let ink: UInt32 = 0x17141F

    /// The wash's pigments: the first three non-staple ingredient colours in the recipe's own order, nothing
    /// repeated, pale ones shaded 12% toward ink; Kitchen green when there are none.
    static func pigments(_ colours: [UInt32]) -> [UInt32] {
        var seen = Set<UInt32>()
        let picked = colours.filter { seen.insert($0).inserted }.prefix(3).map { isPale($0) ? shade($0) : $0 }
        return picked.isEmpty ? [kitchenGreen] : Array(picked)
    }

    /// Relative luminance above 0.85.
    static func isPale(_ hex: UInt32) -> Bool {
        let (red, green, blue) = channels(hex)
        func linear(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue) > 0.85
    }

    /// 12% of the way toward ink.
    static func shade(_ hex: UInt32, by amount: Double = 0.12) -> UInt32 {
        let (red, green, blue) = channels(hex), (inkRed, inkGreen, inkBlue) = channels(ink)
        func mix(_ from: Double, _ toward: Double) -> UInt32 {
            UInt32(((from + (toward - from) * amount) * 255).rounded())
        }
        return mix(red, inkRed) << 16 | mix(green, inkGreen) << 8 | mix(blue, inkBlue)
    }

    /// One soft ellipse of the wash, in unit space (x across, y down, both 0 to 1).
    struct Blob: Equatable {
        var x: Double
        var y: Double
        var width: Double
        var height: Double
        var pigment: Int
    }

    /// Three to five ellipses seeded by the object, the same every time it draws.
    static func blobs(seed: UInt64, pigments: Int) -> [Blob] {
        var state = seed | 1
        func next() -> Double {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return Double(state % 10000) / 10000
        }
        let count = 3 + Int(next() * 3)
        return (0 ..< count).map { index in
            Blob(x: next(), y: 0.2 + next() * 0.6, width: 0.25 + next() * 0.35, height: 0.6 + next() * 0.8,
                 pigment: index % max(pigments, 1))
        }
    }

    private static func channels(_ hex: UInt32) -> (Double, Double, Double) {
        (Double(hex >> 16 & 0xFF) / 255, Double(hex >> 8 & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }
}

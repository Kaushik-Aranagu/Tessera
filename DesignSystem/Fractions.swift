import SwiftUI
import UIKit

/// Fractions drawn as digits (Design 116). Neither Figtree nor Outfit has the one-third and two-thirds characters and
/// Outfit lacks the eighths, so every fraction is written "1 1/2" (whole part, a thin space, numerator/denominator)
/// and the font's diagonal-fractions feature (`frac`) sets the numerator and denominator small. The string Core
/// writes stays as it is for VoiceOver.
enum Fractions {
    private static let glyphs: [Character: (Int, Int)] = [
        "½": (1, 2), "¼": (1, 4), "¾": (3, 4), "⅓": (1, 3), "⅔": (2, 3),
        "⅛": (1, 8), "⅜": (3, 8), "⅝": (5, 8), "⅞": (7, 8),
    ]

    /// "1½" → "1 1/2" (thin space U+2009), "½" → "1/2". Text with no fraction glyph comes back unchanged.
    static func digits(_ text: String) -> String {
        var out = ""
        for character in text {
            if let (top, bottom) = glyphs[character] {
                if let last = out.last, last.isNumber {
                    out.append("\u{2009}")
                }
                out += "\(top)/\(bottom)"
            } else {
                out.append(character)
            }
        }
        return out
    }

    /// Outfit at `size` with the diagonal-fractions feature on; nil when the old face is chosen.
    static func font(size: CGFloat, weight: UIFont.Weight) -> Font? {
        guard Choice.fontIsNew() else { return nil }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Outfit",
            .traits: [UIFontDescriptor.TraitKey.weight: weight],
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kFractionsType,
                UIFontDescriptor.FeatureKey.selector: kDiagonalFractionsSelector,
            ]],
        ])
        let scaled = UIFontMetrics(forTextStyle: .title3).scaledValue(for: size)
        return Font(UIFont(descriptor: descriptor, size: scaled))
    }
}

/// A numeral that may carry a fraction: digits with `frac` in the new pair, the glyphs as before otherwise.
struct FractionText: View {
    let text: String
    let size: CGFloat
    var weight: Font.Weight = .light

    init(_ text: String, size: CGFloat, weight: Font.Weight = .light) {
        self.text = text
        self.size = size
        self.weight = weight
    }

    var body: some View {
        if let font = Fractions.font(size: size, weight: size >= 28 ? .thin : .light) {
            Text(Fractions.digits(text)).font(font).monospacedDigit().tracking(-0.02 * size)
        } else {
            Text(text).numeral(size, weight: weight)
        }
    }
}

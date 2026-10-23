import SwiftUI
import UIKit

/// Tess's own typeface (sheet 215 rev 16): Newsreader, bundled under the SIL OFL (Resources/Fonts/OFL-newsreader.txt),
/// with New York, the system serif, when it can't be loaded. Everything she says is set in it and in ink; his words
/// stay in Figtree and numbers in Outfit. Sizes scale with Dynamic Type through AX5.
enum TessFont {
    static let family = "Newsreader"

    /// Her line beside her on Home.
    static let besideSize: CGFloat = 18
    /// Her lines in her layer, and the newest one.
    static let layerSize: CGFloat = 17
    static let newestSize: CGFloat = 23

    @MainActor static var isBundled: Bool {
        UIFont(name: family, size: 12) != nil
    }

    /// A line of hers at `size`, scaling relative to `style`. Linked words ask for `.medium`.
    @MainActor
    static func line(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        if isBundled {
            return Font.custom(family, size: size, relativeTo: style).weight(weight)
        }
        return Font.system(size: size, weight: weight, design: .serif)
    }

    @MainActor static var beside: Font { line(besideSize) }
    @MainActor static var inLayer: Font { line(layerSize) }
    @MainActor static var newest: Font { line(newestSize, relativeTo: .title3) }
    /// A word that is a door: weight 500, never broken across lines (the caller keeps it in one `Text`).
    @MainActor static var linked: Font { line(layerSize, weight: .medium) }
}

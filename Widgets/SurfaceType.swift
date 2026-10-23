import SwiftUI

/// Surfaces v2 type and colour for the extension (Design 142): Figtree words, Outfit numbers, both bundled in the
/// extension (`UIAppFonts`). Sizes are scaled with Dynamic Type from a text style, so nothing is a fixed system size.
/// A missing font file falls back to the system font and the layout still holds.
enum SurfaceType {
    /// Figtree words; `relativeTo` is the text style the size scales with.
    static func words(_ size: CGFloat, _ weight: Font.Weight = .regular,
                      relativeTo style: Font.TextStyle = .body) -> Font
    {
        .custom("Figtree", size: size, relativeTo: style).weight(weight)
    }

    /// Outfit numbers, tabular. Light, as the app draws figures.
    static func numerals(_ size: CGFloat, _ weight: Font.Weight = .light,
                         relativeTo style: Font.TextStyle = .body) -> Font
    {
        .custom("Outfit", size: size, relativeTo: style).weight(weight).monospacedDigit()
    }
}

enum SurfaceStyle {
    /// An app's accent: light or dark by the surface's appearance. Hexes live in `SurfaceAccent`.
    static func accent(_ app: String) -> Color {
        Color(UIColor { traits in
            uiColor(SurfaceAccent.hex(app: app, dark: traits.userInterfaceStyle == .dark))
        })
    }

    /// The dark-ground variant, for Live Activities and the Island (their ground is dark).
    static func accentOnDark(_ app: String) -> Color {
        Color(uiColor(SurfaceAccent.hex(app: app, dark: true)))
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

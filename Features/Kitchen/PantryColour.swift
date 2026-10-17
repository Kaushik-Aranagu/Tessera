import SwiftUI

/// Pantry's ochre (Product and Design, Oct 17): one named value the area-colour pass replaces (later
/// `palette.pantry`, or `areaLean(area)` from sheet 86). Only on the state words, at a 72% mix with ink, and on the
/// index line; never on rows, labels or the ground, and never in place of cobalt.
enum PantryColour {
    /// Light looks (Porcelain, Plein, Celadon) and dark looks (Obsidian, Lacquer).
    static let light: UInt32 = 0xA4601A
    static let dark: UInt32 = 0xE3A857

    static var ochre: Color {
        Color(hex: ThemeStore.shared.paintLook.isDark ? dark : light)
    }

    /// The state word's colour: 72% ochre, 28% ink.
    static var stateWord: Color {
        ochre.mix(with: Theme.Colors.ink, by: 0.28)
    }
}

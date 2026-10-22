import SwiftUI

/// Each app's one accent (Design 131 table E, Kaushik's v2 picks, Oct 22). Light then dark. Only the app it belongs
/// to uses it: its sentence's key word and its one action underline. Cobalt and violet stay Tess's, apart from the
/// approved Notes violet (127).
extension Theme.Colors {
    enum Accent {
        /// Training: hot red.
        static let training = Color(light: 0xC4472A, dark: 0xEE6A4C)
        /// Kitchen: ochre.
        static let kitchen = Color(light: 0xA8701F, dark: 0xE0A458)
        /// Money: sage.
        static let money = Color(light: 0x3F7A62, dark: 0x8DBFA7)
        /// Notes: violet.
        static let notes = Color(light: 0x5B3FB8, dark: 0xB9A9E0)
        /// Lists: olive.
        static let lists = Color(light: 0x5E6B1F, dark: 0xB5BE7A)
        /// Routines: dusk rose.
        static let routines = Color(light: 0xA4505F, dark: 0xD79AA6)
    }
}

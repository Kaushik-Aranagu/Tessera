import SwiftUI

/// Each app's one accent (Design 131 table E, Kaushik's v2 picks, Oct 22). Light then dark. Only the app it belongs
/// to uses it: its sentence's key word and its one action underline. Cobalt and violet stay Tess's, apart from the
/// approved Notes violet (127).
extension Theme.Colors {
    enum Accent {
        /// A look can tune an accent (sheet 213): the day look by day, the night look by night; else the app's own.
        private static func tuned(_ key: KeyPath<LookAccents, UInt32>, light: UInt32, dark: UInt32) -> Color {
            let pair = ThemeStore.shared.pair
            return Color(
                light: pair.day.accents?[keyPath: key] ?? light,
                dark: pair.night.accents?[keyPath: key] ?? dark
            )
        }

        /// Training: hot red.
        static var training: Color {
            tuned(\.training, light: 0xC4472A, dark: 0xEE6A4C)
        }

        /// Kitchen: ochre.
        static var kitchen: Color {
            tuned(\.kitchen, light: 0xA8701F, dark: 0xC49A5E)
        }

        /// Kitchen's small words (sheet 231: Cook now, Undo, low, Get it): darker by day so they reach 4.5:1.
        static var kitchenText: Color {
            Color(light: 0x93611A, dark: 0xC49A5E)
        }

        /// Kitchen's section names (a slate, so the names stand apart from the place and its actions).
        static var kitchenSection: Color {
            Color(light: 0x34506F, dark: 0xA7BCD6)
        }

        /// Kitchen's low, eat by tomorrow and throw out today (a wine).
        static var kitchenWarn: Color {
            Color(light: 0x9A2541, dark: 0xEE8E9C)
        }

        /// Kitchen's leftover days that are fine (a pine).
        static var kitchenFresh: Color {
            Color(light: 0x2F6450, dark: 0x8EC7AE)
        }

        /// Money: sage.
        static var money: Color {
            tuned(\.money, light: 0x3F7A62, dark: 0x8DBFA7)
        }

        /// Notes: violet.
        static var notes: Color {
            tuned(\.notes, light: 0x5B3FB8, dark: 0xB9A9E0)
        }

        /// Lists: olive.
        static var lists: Color {
            tuned(\.lists, light: 0x5E6B1F, dark: 0xB5BE7A)
        }

        /// Routines: dusk rose.
        static var routines: Color {
            tuned(\.routines, light: 0x8E4A78, dark: 0xD79AA6)
        }

        /// The sky word's two stops ("Sunset").
        static var skyFrom: Color {
            tuned(\.skyFrom, light: 0xC9772E, dark: 0xE8A06A)
        }

        static var skyTo: Color {
            tuned(\.skyTo, light: 0xB0466A, dark: 0xE07A9A)
        }
    }
}

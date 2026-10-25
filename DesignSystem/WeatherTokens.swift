import SwiftUI

/// The weather words' colours (Home 236 v2.4), light then dark. A weather word takes the colour of its cloud, so the
/// tokens are named for the weather, not for a use. Only the weather words wear them.
extension Theme.Colors {
    enum Weather {
        /// White-cloud days (clear, mainly clear, partly cloudy).
        static var pcloud: Color {
            Color(light: 0x8A7552, dark: 0xDCCDAA)
        }

        /// Nights.
        static var moon: Color {
            Color(light: 0x4A5788, dark: 0xB3BDE8)
        }

        /// Fog, and the grey of an overcast sky.
        static var fog: Color {
            Color(light: 0x727880, dark: 0xA7ACB2)
        }

        /// Anything freezing, hail, and the cold warning.
        static var ice: Color {
            Color(light: 0x2F7299, dark: 0x9FD0EE)
        }

        /// A storm cloud.
        static var storm: Color {
            Color(light: 0x53507A, dark: 0xABA8DC)
        }

        /// The wind and heat warnings.
        static var warn: Color {
            Color(light: 0xA23B27, dark: 0xF08F72)
        }

        /// Lightning, and only lightning.
        static var bolt: Color {
            Color(light: 0x5B4FD0, dark: 0xFFF1A8)
        }

        /// Rain: the same token as `Accent.rain`.
        static var rain: Color {
            Theme.Colors.Accent.rain
        }
    }
}

import SwiftUI

/// Design tokens. Placeholder values — replace as the visual design takes shape.
enum Theme {
    enum Colors {
        static let accent = Color.indigo
        static let background = Color(.systemBackground)
        static let surface = Color(.secondarySystemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
    }

    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let sectionTitle = Font.headline
        static let body = Font.body
        static let caption = Font.caption
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 14
        static let l: CGFloat = 22
    }

    /// Always applied through `MotionPolicy` (`.pilotAnimation` / `withPilotAnimation`).
    enum Motion {
        /// House spring — ~90% of all motion.
        static let house = Animation.spring(Spring(duration: 0.42, bounce: 0.12))
        /// Direct manipulation: drags, swipes, toggles under the finger.
        static let snappy = Animation.snappy(duration: 0.25)
        /// Rare celebrations only.
        static let celebrate = Animation.bouncy(duration: 0.5)
    }
}

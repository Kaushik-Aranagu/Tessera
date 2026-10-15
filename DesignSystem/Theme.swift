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

    enum Motion {
        static let quick = Animation.snappy(duration: 0.2)
        static let standard = Animation.smooth(duration: 0.35)
        static let bouncy = Animation.bouncy(duration: 0.45)
    }
}

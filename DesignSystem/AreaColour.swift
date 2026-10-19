import SwiftUI

/// An area of the app that owns a colour (sheet 86, option C): a page takes the colour of its area, Home the colour
/// of what leads (a workout in the hero leans Training; a run of tasks stays neutral).
enum AppArea: Equatable, Sendable {
    case training, kitchen, review
    /// Today's tasks and anything without an area stay ink (cobalt is Tess's voice only).
    case neutral
}

extension Theme.Colors {
    /// The area's own colour: Training's, Kitchen's health green, Review's violet; ink for neutral. Each look's
    /// palette already carries its light partner for the dark looks.
    static func area(_ area: AppArea) -> Color {
        switch area {
        case .training: training
        case .kitchen: health
        case .review: context
        case .neutral: ink
        }
    }

    /// The area's colour mixed 72% with ink, so it reads as ink with a lean, never as a link. For caps labels, the
    /// title's key word, the lead numeral and (at 34%) the section hairline. Never on rows, notes or Tess's cobalt.
    static func areaLean(_ area: AppArea) -> Color {
        ink.mix(with: self.area(area), by: 0.72)
    }

    /// The page ground leaning 2.5% toward the area (3% in a dark look): an overlay colour, never behind text alone.
    static func groundTint(_ area: AppArea) -> Color {
        guard area != .neutral else { return .clear }
        return self.area(area).opacity(ThemeStore.shared.paintLook.isDark ? 0.03 : 0.025)
    }
}

extension HomeSpatialView.Page {
    /// The area a Home page belongs to (sheet 86 C): Today, with no area of its own, stays neutral.
    var area: AppArea {
        switch self {
        case .review: .review
        case .today: .neutral
        case .training: .training
        case .kitchen: .kitchen
        }
    }
}

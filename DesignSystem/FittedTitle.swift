import SwiftUI
import UIKit

/// A big fixed title in a one-line slot (sheet 230): it shrinks 1 pt at a time until it fits, down to 0.75x of its size
/// (the exercise name 34 down to 26 at most); only past that floor does a short form take over (Tess's, over 22
/// characters). It never wraps, never pushes its neighbours and never ends in "...".
struct FittedTitle: View {
    let text: String
    /// The short form used once even the floor is too wide, if there is one.
    var short: String?
    var size: CGFloat = 34
    var weight: Font.Weight = .semibold
    var color: Color = Theme.Colors.Accent.training
    var floor: CGFloat = 0.75

    @State private var width: CGFloat = 0

    var body: some View {
        let fit = fitted
        Text(fit.text)
            .font(Theme.Training.words(fit.size, weight: weight, relativeTo: .title))
            .foregroundStyle(color)
            .lineLimit(1)
            // Never "...": a last resort that still keeps one line if a measure is off by a hair.
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .tesseraAnimation(Theme.Motion.snappy, value: fit.size)
    }

    private var fitted: (text: String, size: CGFloat) {
        guard width > 0 else { return (text, size) }
        let uiWeight = Self.uiWeight(weight)
        if let fit = TitleFit.size(for: text, width: width, from: size, weight: uiWeight, floor: floor) {
            return (text, fit)
        }
        if let short, short != text {
            let lowest = (size * floor).rounded(.up)
            return (
                short,
                TitleFit.size(for: short, width: width, from: size, weight: uiWeight, floor: floor) ?? lowest
            )
        }
        return (text, (size * floor).rounded(.up))
    }

    private static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .bold, .heavy, .black: .bold
        case .semibold: .semibold
        case .medium: .medium
        case .light, .thin, .ultraLight: .light
        default: .regular
        }
    }
}

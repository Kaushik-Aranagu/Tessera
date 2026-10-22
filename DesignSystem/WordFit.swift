import SwiftUI
import UIKit

/// A title wraps only at spaces. If its longest word cannot fit the line at the reader's text size, the whole title
/// steps down to the largest size at which it does (floor about 0.6 of where it started), never splitting the word
/// and never hyphenating (Design on #1202). In the Figtree pair only; the old pair is untouched.
private struct WordFitModifier: ViewModifier {
    let text: String
    /// The type the title is drawn in when it wraps (the Title step).
    var points: CGFloat = 48
    @Environment(\.dynamicTypeSize) private var size

    func body(content: Content) -> some View {
        guard Choice.fontIsNew() else { return AnyView(content) }
        let fitted = WordFit.largest(fitting: text, points: points, from: size)
        return AnyView(content.dynamicTypeSize(...fitted))
    }
}

enum WordFit {
    /// The page side margin, twice, plus a little slack for the tracking and the text's own side bearings.
    private static var available: CGFloat {
        UIScreen.main.bounds.width - 2 * Theme.Spacing.gutter - 4
    }

    /// The measure is of the font alone; the drawn word is a few percent wider (tracking, shaping), so keep a margin.
    private static let slack: CGFloat = 1.08

    static func widestWord(_ text: String, points: CGFloat) -> CGFloat {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: Theme.activeFonts.display,
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.medium],
        ])
        let font = UIFont(descriptor: descriptor, size: points)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .kern: -0.03 * points]
        return text.split(whereSeparator: \.isWhitespace)
            .map { ($0 as NSString as String as NSString).size(withAttributes: attributes).width }
            .max() ?? 0
    }

    /// The largest size at or below `current` where the longest word fits, no lower than 0.6 of the start.
    static func largest(fitting text: String, points: CGFloat, from current: DynamicTypeSize) -> DynamicTypeSize {
        let sizes = DynamicTypeSize.allCases
        guard let start = sizes.firstIndex(of: current), current > .xxxLarge else { return current }
        let startPoints = scaled(points, current)
        var index = start
        while index > 0 {
            let candidate = sizes[index]
            let candidatePoints = scaled(points, candidate)
            if widestWord(text, points: candidatePoints) * Self.slack <= available || candidate <= .xxxLarge
                || candidatePoints < 0.6 * startPoints
            {
                return candidate
            }
            index -= 1
        }
        return sizes[index]
    }

    private static func scaled(_ points: CGFloat, _ size: DynamicTypeSize) -> CGFloat {
        UIFontMetrics(forTextStyle: .title1)
            .scaledValue(for: points, compatibleWith: UITraitCollection(preferredContentSizeCategory: category(size)))
    }

    static func category(_ size: DynamicTypeSize) -> UIContentSizeCategory {
        switch size {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

extension View {
    /// Wraps this title at spaces only, stepping the text size down just enough for its longest word to fit.
    func wordFit(_ text: String, points: CGFloat = 48) -> some View {
        modifier(WordFitModifier(text: text, points: points))
    }
}

import SwiftUI
import UIKit

/// Sheet 298: no box ever cuts a word. A ticket's words fit the paper: a line too wide loses its letter-spacing first,
/// then steps down in size, to 9 pt at the least. Measured with the real face, never truncated.
enum GalleyFit {
    struct Fit: Equatable {
        let size: CGFloat
        let tracking: CGFloat
    }

    static let floor: CGFloat = 9
    /// The drawn word is a little wider than the font's measure (shaping, side bearings).
    private static let slack: CGFloat = 1.03
    private static let step: CGFloat = 0.25

    /// The first (size, tracking) from the wanted one that fits `width`: tracking to nothing first, then smaller type.
    static func fit(_ text: String, face: String, size: CGFloat, tracking: CGFloat, width: CGFloat) -> Fit {
        guard !text.isEmpty else { return Fit(size: size, tracking: tracking) }
        var current = size
        var space = tracking
        if measure(text, face: face, size: current, tracking: space) <= width {
            return Fit(
                size: current,
                tracking: space
            )
        }
        space = 0
        while measure(text, face: face, size: current, tracking: space) > width, current > floor {
            current = max(current - step, floor)
        }
        return Fit(size: current, tracking: space)
    }

    static func measure(_ text: String, face: String, size: CGFloat, tracking: CGFloat) -> CGFloat {
        let font = UIFont(name: face, size: size) ?? UIFont.systemFont(ofSize: size)
        let base = (text as NSString).size(withAttributes: [.font: font]).width
        return (base + tracking * CGFloat(max(text.count - 1, 0))) * slack
    }
}

/// One line of a ticket, fitted to the width it is given.
struct GalleyFitLine: View {
    let text: String
    let face: String
    let size: CGFloat
    var tracking: CGFloat = 0
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let fit = GalleyFit.fit(text, face: face, size: size, tracking: tracking, width: proxy.size.width)
            Text(text)
                .font(.custom(face, fixedSize: fit.size))
                .tracking(fit.tracking)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
                .frame(width: proxy.size.width, alignment: .leading)
        }
        .frame(height: size * 1.25)
    }
}

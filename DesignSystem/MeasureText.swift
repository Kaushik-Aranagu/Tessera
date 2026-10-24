import SwiftUI

/// The app-wide rule (Kaushik, Oct 23, 11:24 PM; sheet 230 v3.1): a weight or any measured number always shows its
/// unit, at about half the number's size, never under 10 pt, in Figtree 400. Core will split number and unit in
/// `Measure`; until then everything splits here, behind this one seam.
enum MeasureLine {
    /// The unit's point size for a number set at `size`.
    static func unitSize(for size: CGFloat) -> CGFloat {
        max(10, (size / 2).rounded())
    }

    /// Units the seam knows how to find after a number.
    private static let units = "lb|kg|min|reps|sec"

    private static let pattern = try? NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s?("# + units + #")\b"#)

    /// The pieces of a line: plain runs and (number, unit) pairs, in order.
    enum Piece: Equatable {
        case plain(String)
        case measured(number: String, unit: String)
    }

    static func pieces(_ line: String) -> [Piece] {
        guard let pattern else { return [.plain(line)] }
        let ns = line as NSString
        var pieces: [Piece] = []
        var cursor = 0
        for match in pattern.matches(in: line, range: NSRange(location: 0, length: ns.length)) {
            if match.range.location > cursor {
                pieces.append(.plain(ns.substring(with: NSRange(
                    location: cursor,
                    length: match.range.location - cursor
                ))))
            }
            pieces.append(.measured(number: ns.substring(with: match.range(at: 1)),
                                    unit: ns.substring(with: match.range(at: 2))))
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length {
            pieces.append(.plain(ns.substring(from: cursor)))
        }
        return pieces
    }

    /// A line of text whose measured numbers carry their unit at half size ("185 lb for 5"): one `Text`, so it lays
    /// out, scales and speaks as a line.
    @MainActor
    static func text(_ line: String, size: CGFloat, weight: Font.Weight = .regular) -> Text {
        var result = Text("")
        for piece in pieces(line) {
            switch piece {
            case let .plain(run):
                // swiftlint:disable:next shorthand_operator
                result = result + Text(run).font(Theme.Training.words(size, weight: weight))
            case let .measured(number, unit):
                // swiftlint:disable:next shorthand_operator
                result = result + Text(number).font(Theme.Training.words(size, weight: weight))
                    + Text("\u{2009}\(unit)").font(Theme.Training.words(unitSize(for: size), weight: .regular))
            }
        }
        return result
    }
}

/// A number with its unit beside it: the numeral at `size` (Outfit), the unit at half in Figtree 400, 2 pt after.
struct MeasuredNumber: View {
    let number: String
    let unit: String
    var size: CGFloat
    var weight: Font.Weight?
    var color: Color = Theme.Colors.ink
    var unitColor: Color = Theme.Colors.inkSecondary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(number)
                .font(Theme.Training.number(size, weight: weight))
                .foregroundStyle(color)
            Text(unit)
                .font(Theme.Training.words(MeasureLine.unitSize(for: size)))
                .foregroundStyle(unitColor)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

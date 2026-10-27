import SwiftUI

/// Sheets 313 and 314: a count line where only the number that changed moves, like a counter. A number going down drops
/// in from above while the old one falls away below; one going up (an undo) rises from below. Every other word stays
/// still, and the number's own width eases so the words after it slide over instead of jumping. The new number arrives
/// over 300 ms from 60 ms with a little overshoot. Reduce Motion: the line changes in place.
enum RollingLine {
    /// "3 of 7" gives ("", 3, " of 7"): the first whole number is the one that rolls. nil when the line has none.
    static func split(_ line: String) -> (before: String, number: Int, after: String)? {
        guard let range = line.range(of: #"\d+"#, options: .regularExpression),
              let number = Int(line[range]) else { return nil }
        return (String(line[..<range.lowerBound]), number, String(line[range.upperBound...]))
    }
}

struct RollingText: View {
    let line: String
    var font: Font
    var color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let parts = RollingLine.split(line) {
            HStack(spacing: 0) {
                Text(parts.before)
                Text("\(parts.number)")
                    .contentTransition(.numericText(value: Double(parts.number)))
                Text(parts.after)
            }
            .font(font)
            .foregroundStyle(color)
            .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.2).delay(0.06), value: parts.number)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(line)
        } else {
            Text(line).font(font).foregroundStyle(color)
        }
    }
}

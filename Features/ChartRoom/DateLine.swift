import SwiftUI

// Sheet 381: the dates turn over. A line that ends in dates ("Watered Oct 23, Oct 20 and Oct 17") is built from runs,
// and each date run's identity is its place (0, 1, 2), not its value. So a changed value rolls in place with a numeric
// text transition, staggered by place, front first, 60 ms apart: old lifts away, new rises, and no date ever slides
// past
// the words between them. Undo rolls them the other way. The line's text is right from the first frame (it is one
// accessibility element with the whole text). Reduce Motion: the line just changes.

enum DateLine {
    /// Seconds between one place's roll and the next, front first.
    static let stagger = 0.06

    /// The text before the dates, and the dates themselves in order, when the line ends in one to three of them
    /// ("Oct 25, Oct 23 and Oct 20"); nil for any other line.
    static func parse(_ text: String) -> (prefix: String, dates: [String])? {
        let date = "[A-Z][a-z]{2} [0-9]{1,2}"
        guard let range = text.range(of: "(?:\\(date)(?:, | and ))*\\(date)$", options: .regularExpression)
            ?? text.range(of: "\\(date)$", options: .regularExpression)
        else { return nil }
        let tail = String(text[range])
        let dates = tail.replacingOccurrences(of: " and ", with: ", ").components(separatedBy: ", ")
        guard (1 ... 3).contains(dates.count) else { return nil }
        return (String(text[..<range.lowerBound]), dates)
    }

    /// A sortable number for "Oct 23" (month, then day); 0 when it is not a date. Used to tell which way a roll goes.
    static func ordinal(_ date: String) -> Int {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let parts = date.split(separator: " ")
        guard parts.count == 2, let month = months.firstIndex(of: String(parts[0])),
              let day = Int(parts[1]) else { return 0 }
        return (month + 1) * 32 + day
    }

    /// Undo rolls the other way: the front date moved to an earlier one.
    static func rollsDown(from old: [String], to new: [String]) -> Bool {
        guard let before = old.first, let after = new.first else { return false }
        return ordinal(after) < ordinal(before)
    }

    /// When a place rolls, after the change: front first. Reduce Motion: at once.
    static func delay(place: Int, reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : Double(place) * stagger
    }

    /// The words between the dates: ", " between the first ones, " and " before the last.
    static func separator(before place: Int, of count: Int) -> String {
        place == count - 1 && count > 1 ? " and " : ", "
    }
}

/// The line, drawn in runs: every date rolls in place. `countsDown` is true for Undo (the other way).
struct RollingDates: View {
    let text: String
    var countsDown = false
    var size: CGFloat = 20
    var weight: Font.Weight = .medium
    var color: Color = Theme.Colors.ink

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var down = false

    var body: some View {
        if let line = DateLine.parse(text) {
            HStack(spacing: 0) {
                Text(line.prefix)
                ForEach(Array(line.dates.enumerated()), id: \.offset) { place, date in
                    if place > 0 {
                        Text(DateLine.separator(before: place, of: line.dates.count))
                    }
                    Text(date)
                        .contentTransition(.numericText(countsDown: countsDown || down))
                        .animation(
                            reduceMotion ? nil : Theme.Motion.house.delay(DateLine.delay(
                                place: place,
                                reduceMotion: false
                            )),
                            value: date
                        )
                }
            }
            .font(.custom("Figtree", size: size, relativeTo: .body).weight(weight))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .onChange(of: text) { old, new in
                down = DateLine.rollsDown(from: DateLine.parse(old)?.dates ?? [], to: DateLine.parse(new)?.dates ?? [])
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
        } else {
            Text(text)
        }
    }
}

extension EnvironmentValues {
    /// True while an Undo rolls a page's dates back (they roll the other way).
    @Entry var datesCountDown: Bool = false
}

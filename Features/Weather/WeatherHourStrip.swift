import SwiftUI
import TesseraCore

// CLOUD-WRITTEN, NOT COMPILED. The hour columns (sheet 243): 59 pt wide, the time over the temperature over one word
// in the condition's color. A drag across (or up and down) pages three hours at a time; the columns slide, they do
// not snap. The drag goes through the app's gesture kit, so the axis, the distance and the flick are `GestureTuning`'s.

struct WeatherHourStrip: View {
    let hours: [WeatherHour]
    /// The first column shown, as an hour index into `hours`; it is rounded down to a whole page.
    var firstHour = 0
    var calendar = Calendar.current

    static let columnWidth: CGFloat = 59
    static let pageSize = 3
    static let height: CGFloat = 78

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Int?

    var body: some View {
        GeometryReader { proxy in
            let visible = max(3, Int(proxy.size.width / Self.columnWidth))
            let last = max(0, hours.count - visible)
            let shown = min(start ?? (firstHour / Self.pageSize * Self.pageSize), last)
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                    column(hour, index: index)
                }
            }
            .offset(x: -CGFloat(shown) * Self.columnWidth)
            .frame(width: proxy.size.width, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            .pageSwipe { next in move(next ? 1 : -1, from: shown, last: last) }
            .pullGesture { down in move(down ? -1 : 1, from: shown, last: last) }
            .tesseraAnimation(Theme.Motion.house, value: shown)
        }
        .frame(height: Self.height)
        .accessibilityIdentifier("weather.hours")
    }

    private func move(_ pages: Int, from shown: Int, last: Int) {
        let next = min(max(shown + pages * Self.pageSize, 0), last)
        guard next != shown else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { start = next }
    }

    private func column(_ hour: WeatherHour, index: Int) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(WeatherSentences.columnTime(hour.time, calendar: calendar))
                .font(WeatherType.figtree(13, .regular, relativeTo: .footnote))
                .foregroundStyle(Theme.Colors.inkSecondary)
            Text("\(hour.temperature)°")
                .weatherNumeral(24)
                .foregroundStyle(Theme.Colors.ink)
            Text(hour.kind.short)
                .font(WeatherType.figtree(13, .semibold, relativeTo: .footnote))
                .foregroundStyle(hour.kind.color)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: Self.columnWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(WeatherSentences.columnTime(hour.time, calendar: calendar)), \(hour.temperature) degrees, "
                + hour.kind.short
        )
        .accessibilityIdentifier("weather.hour.\(index)")
    }
}

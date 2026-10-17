import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

/// The finish (docs/design/workout-v1.md, "Finishing the workout"). The set view clears; the day and "Push Day A,
/// done" enter from below. Every set stroke of the session appears scattered across the middle in its paint, then
/// they draw together to the centre, rotating level and shrinking (1.9 s, 22 ms apart). As they meet, one painted
/// mark draws across in the session's colours over a blurred halo. Then the totals, and Tess says the one-line
/// summary. Swipe down (or the key) to drop it into today on Home.
///
/// Reduce Motion: no gather; the mark and lines fade in. Haptics stay (Tess's `done`).
struct WorkoutFinishView: View {
    /// Paint of every logged set, in the order they were logged.
    let strokes: [Color]
    let title: String
    let startedAt: Date
    let endedAt: Date
    let summary: WorkoutSession.Summary
    /// Fires as the mark lands (Tess plays `done` and says the summary).
    var onGathered: () -> Void
    var onDone: () -> Void

    @State private var entered = false
    @State private var gathered = false
    @State private var mark: CGFloat = 0
    @State private var settled = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let gather = 1.9
    private static let stagger = 0.022

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(dayLine)
                    .font(Theme.voice)
                    .foregroundStyle(Paint.secondary)
                Text(Self.heroText(title: title))
                    .font(Theme.numeral(56, weight: .medium))
                    .foregroundStyle(Paint.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
            }
            .offset(y: entered || reduceMotion ? 0 : 24)
            .opacity(entered ? 1 : 0)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.xl)
            .accessibilityElement(children: .combine)

            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    if !reduceMotion {
                        ForEach(strokes.indices, id: \.self) { index in
                            scattered(index, in: size)
                        }
                    }
                    paintedMark
                        .frame(width: min(size.width - 48, 300), height: 48)
                        .position(x: size.width / 2, y: size.height / 2)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("\(Int((summary.duration / 60).rounded())) min, \(volume) kg moved")
                    .textRole(.label)
                    .foregroundStyle(Paint.cream)
                Text("It drops into today on Home.")
                    .font(Theme.voice)
                    .foregroundStyle(Paint.secondary)
            }
            .opacity(settled ? 1 : 0)
            .padding(.horizontal, Theme.Spacing.gutter)
            .accessibilityElement(children: .combine)

            PaintKey(paint: Paint.cobalt, isTap: true, height: 64, action: onDone) { _ in
                Text("Back to today")
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .opacity(settled ? 1 : 0)
            .accessibilityHint("Drops the workout into today on Home")
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 30).onEnded { drag in
            if settled, drag.translation.height > 80 {
                onDone()
            }
        })
        .task { await play() }
    }

    /// "Push Day A, done" with the routine's name held together: a short name (16 characters or fewer) keeps its
    /// words together with no-break spaces, so the line breaks only between "A," and "done" (or scales). A longer
    /// name glues just its last two words and ", done", so it wraps at the earlier spaces instead of one huge unit.
    static func heroText(title: String) -> String {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return "Workout, done" }
        let glue = "\u{00A0}"
        if title.count <= 16 {
            return title.replacingOccurrences(of: " ", with: glue) + ", done"
        }
        let words = title.split(separator: " ", omittingEmptySubsequences: true)
        guard words.count > 2 else { return title + ", done" }
        let head = words.dropLast(2).joined(separator: " ")
        return head + " " + words.suffix(2).joined(separator: glue) + ", done"
    }

    private var dayLine: String {
        Self.dayLine(startedAt: startedAt, endedAt: endedAt)
    }

    /// "Friday, 11:40 pm to 12:50 am": the weekday of his 4 am day at the start, times in the house clock.
    static func dayLine(startedAt: Date, endedAt: Date, calendar: Calendar = .current) -> String {
        let day = TesseraDay(calendar: calendar).day(of: startedAt)
        var style = Date.FormatStyle.dateTime.weekday(.wide)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        let weekday = day.formatted(style)
        return "\(weekday), \(HouseClock.time(startedAt, calendar: calendar)) to \(HouseClock.time(endedAt, calendar: calendar))"
    }

    private var volume: String {
        summary.volume.formatted(.number.precision(.fractionLength(0)))
    }

    // MARK: The gather

    private func scattered(_ index: Int, in size: CGSize) -> some View {
        let start = Self.scatter(index, in: size)
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let delay = 0.4 + Double(index) * Self.stagger
        return Brushstroke()
            .stroke(strokes[index], style: StrokeStyle(lineWidth: 9, lineCap: .round))
            .frame(width: 64, height: 20)
            .blur(radius: 0.4)
            .rotationEffect(.degrees(gathered ? 0 : Self.angle(index)))
            .scaleEffect(gathered ? 0.3 : 1)
            .position(gathered ? centre : start)
            .opacity(gathered && mark > 0 ? 0 : 1)
            .tesseraAnimation(.timingCurve(0.5, 0, 0.2, 1, duration: Self.gather).delay(delay), value: gathered)
            .tesseraAnimation(.easeOut(duration: 0.3), value: mark > 0)
    }

    /// The one painted mark: 16 pt, wet-edged, a gradient through the session's colours, over a 30 pt halo.
    private var paintedMark: some View {
        let colors = Self.uniqueColors(strokes)
        let gradient = LinearGradient(colors: colors.count > 1 ? colors : colors + colors, startPoint: .leading,
                                      endPoint: .trailing)
        return ZStack {
            Brushstroke(progress: mark)
                .stroke(gradient, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                .blur(radius: 15)
                .opacity(0.45)
            Brushstroke(progress: mark)
                .stroke(gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
            // The wet edge: a lighter rim along the stroke.
            Brushstroke(progress: mark)
                .stroke(Theme.Colors.Workout.ink.opacity(0.22), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .offset(y: -5)
                .blendMode(.screen)
        }
        .opacity(reduceMotion ? (mark > 0 ? 1 : 0) : 1)
    }

    private func play() async {
        let motion = !reduceMotion
        withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.6), reduceMotion: reduceMotion) {
            entered = true
        }
        if motion, !strokes.isEmpty {
            try? await Task.sleep(for: .milliseconds(30))
            gathered = true
            let last = 0.4 + Double(strokes.count - 1) * Self.stagger + Self.gather
            try? await Task.sleep(for: .seconds(max(last - 0.35, 0.4)))
        } else {
            try? await Task.sleep(for: .milliseconds(400))
        }
        withTesseraAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.9), reduceMotion: reduceMotion) { mark = 1 }
        onGathered()
        try? await Task.sleep(for: .milliseconds(motion ? 900 : 200))
        withTesseraAnimation(.easeOut(duration: 0.4), reduceMotion: reduceMotion) { settled = true }
    }

    // MARK: Helpers

    private static func unit(_ seed: Double) -> CGFloat {
        let value = sin(seed) * 43758.5453
        return CGFloat(value - value.rounded(.down))
    }

    static func scatter(_ index: Int, in size: CGSize) -> CGPoint {
        let seed = Double(index + 1)
        let x = 36 + unit(seed * 12.9898) * max(size.width - 72, 1)
        let y = 20 + unit(seed * 78.233) * max(size.height - 40, 1)
        return CGPoint(x: x, y: y)
    }

    static func angle(_ index: Int) -> Double {
        Double(unit(Double(index + 1) * 39.3468)) * 80 - 40
    }

    static func uniqueColors(_ colors: [Color]) -> [Color] {
        var seen: [Color] = []
        for color in colors where !seen.contains(color) {
            seen.append(color)
        }
        return seen.isEmpty ? [Paint.live] : seen
    }
}

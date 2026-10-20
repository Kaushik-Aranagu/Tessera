import SwiftUI
import TesseraCore

// MARK: - Geometry (pure)

/// Maps clock times onto the waking day, 07:00 → 0 and 23:00 → 1, so the stroke and its wet tip agree on one scale.
struct DayTimeline: Equatable {
    var startHour = 7.0
    var endHour = 23.0
    var calendar = Calendar.current

    /// Unclamped hours since midnight of `date`'s own day.
    func hours(of date: Date) -> Double {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60 + Double(parts.second ?? 0) / 3600
    }

    /// Where `date` sits on his day, clamped to 0 … 1. His day runs to 04:00, so 01:50 is hour 25.8 of the day
    /// that's ending (the tip stays at the evening end), not hour 1.8 of a new one.
    func fraction(of date: Date) -> Double {
        let hour = hours(of: date)
        return fraction(hour: hour < Double(TesseraDay.startHour) ? hour + 24 : hour)
    }

    func fraction(hour: Double) -> Double {
        min(max((hour - startHour) / (endHour - startHour), 0), 1)
    }

    /// The visible part of an item, or nil when it falls wholly outside 07–23. Past midnight is still the same day
    /// until 04:00 (B4), so an item running to 00:30 ends at hour 24.5, up to 28; anything later is cut at 28.
    func span(start: Date, end: Date) -> ClosedRange<Double>? {
        let startHours = hours(of: start)
        let endHours = calendar.isDate(end, inSameDayAs: start) ? hours(of: end)
            : TesseraDay(calendar: calendar).isSameDay(end, start) ? min(hours(of: end) + 24, 28) : 28
        guard endHours > startHour, startHours < endHour else { return nil }
        let lower = fraction(hour: startHours), upper = fraction(hour: max(endHours, startHours))
        return lower ... upper
    }

    /// How much of a lane's day is painted: past days fully, future days not at all, today up to now.
    func painted(dayOffset: Int, now: Date) -> Double {
        dayOffset < 0 ? 1 : dayOffset > 0 ? 0 : fraction(of: now)
    }
}

/// One page of the day stroke.
struct DayLane: Identifiable, Equatable {
    /// Days from today: −1 yesterday, 0 today, 1 tomorrow.
    let offset: Int
    let date: Date
    let items: [ScheduleItem]
    /// Workouts finished that day, start to end: drawn as vermilion marks on the stroke.
    var workouts: [ClosedRange<Date>] = []

    var id: Int {
        offset
    }

    /// "Thursday afternoon", "Wednesday, done", "Friday, three planned".
    func phrase(now: Date, calendar: Calendar = .current) -> String {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        if offset == 0 {
            return "\(weekday) \(SpokenTime.partOfDay(now, calendar: calendar))"
        }
        if offset < 0 {
            return "\(weekday), done"
        }
        return items.isEmpty ? "\(weekday), nothing planned" : "\(weekday), \(SpokenTime.number(items.count)) planned"
    }
}

// MARK: - The day stroke

/// The day as one watercolour brushstroke, painted up to now, with a dashed ink guide for the rest. Its own bounded
/// x lane inside TODAY: one full-width page per day, opening on today and stopping at the edges. A nested horizontal
/// scroll view claims horizontal swipes only inside its own frame; the page gutters around it still page Home.
struct HomeDayStrip: View {
    let lanes: [DayLane]
    @State private var position = ScrollPosition(id: 0)

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(lanes) { lane in
                    DayStrokePage(lane: lane)
                        .containerRelativeFrame(.horizontal)
                        .id(lane.offset)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        // Opens on today on first layout, without a visible jump.
        .scrollPosition($position)
        .onAppear { position.scrollTo(id: 0) }
        .frame(height: 96)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Swipe left or right for other days")
    }
}

private struct DayStrokePage: View {
    let lane: DayLane
    private let timeline = DayTimeline()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = AppClock.adjust(context.date)
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(lane.phrase(now: now))
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.ink)
                DayStroke(painted: timeline.painted(dayOffset: lane.offset, now: now), isToday: lane.offset == 0,
                          marks: lane.workouts.compactMap { timeline.span(start: $0.lowerBound, end: $0.upperBound) })
                    .frame(height: 30)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText(now: now))
        }
    }

    private func accessibilityText(now: Date) -> String {
        let count = lane.items.count
        let things = count == 1 ? "1 thing" : "\(count) things"
        let clock = lane.offset == 0 ? " Now \(Format.clock(now))." : ""
        let trained = lane.workouts.isEmpty ? "" : " Trained."
        return "\(lane.phrase(now: now)). \(things) scheduled.\(trained)\(clock)"
    }
}

/// A 20 pt stroke with round caps through sky → sage → violet → amber → vermilion, painted to `painted`; a dashed
/// ink guide (22%) carries the rest. Finished workouts sit on it as vermilion marks. Paints in over 700 ms on first
/// appearance; today carries a breathing wet tip.
private struct DayStroke: View {
    let painted: Double
    let isToday: Bool
    /// Finished workouts, as fractions of the day: a short vermilion stroke laid over the day where each happened.
    var marks: [ClosedRange<Double>] = []
    @Environment(\.motionReduced) private var reduceMotion
    @State private var drawn: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let reach = min(drawn, painted)
            ZStack(alignment: .topLeading) {
                BrushPath().trim(from: painted, to: 1)
                    .stroke(
                        Theme.Colors.ink.opacity(0.22),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 6])
                    )
                // One thin pass at 60%: the day at rest (ink-line.md, no-dots.md).
                BrushPath().trim(from: 0, to: reach)
                    .stroke(gradient, style: StrokeStyle(lineWidth: HomeStroke.day, lineCap: .round))
                    .opacity(0.6)
                    .blur(radius: 0.3)
                ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                    // At least a dab, even for a short session.
                    let lower = min(mark.lowerBound, 0.985), upper = max(mark.upperBound, lower + 0.015)
                    BrushPath().trim(from: lower, to: min(upper, min(reach + 0.015, 1)))
                        .stroke(Theme.Colors.live, style: StrokeStyle(lineWidth: HomeStroke.session, lineCap: .round))
                        .blur(radius: 0.4)
                }
                if isToday, reach > 0 {
                    // The moment: a breathing sheen on the stroke's last 14 pt, not a dot (no-dots).
                    WetTip(reach: reach, length: 14 / max(size.width, 1), gradient: gradient)
                }
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            guard drawn == 0 else { return }
            if reduceMotion {
                drawn = 1
            } else {
                withTesseraAnimation(.smooth(duration: 0.7), reduceMotion: reduceMotion) { drawn = 1 }
            }
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(gradient: HomeStroke.gradient, startPoint: .leading, endPoint: .trailing)
    }

    static func point(at fraction: Double, in size: CGSize) -> CGPoint {
        let path = BrushPath().path(in: CGRect(origin: .zero, size: size))
        let start = CGPoint(x: BrushPath.inset, y: size.height / 2 + 1)
        guard fraction > 0 else { return start }
        return path.trimmedPath(from: 0, to: fraction).currentPoint ?? start
    }
}

/// A gently uneven horizontal brush path, inset by the cap radius. A `Shape`, so its trim animates.
private struct BrushPath: Shape {
    static let inset: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        Path { path in
            let mid = rect.midY
            path.move(to: CGPoint(x: rect.minX + Self.inset, y: mid + 1))
            path.addCurve(
                to: CGPoint(x: rect.maxX - Self.inset, y: mid - 1),
                control1: CGPoint(x: rect.minX + rect.width * 0.35, y: mid - 4),
                control2: CGPoint(x: rect.minX + rect.width * 0.65, y: mid + 4)
            )
        }
    }
}

/// Now: the stroke's last 14 pt, 1.5 pt thicker, with an amber sheen that breathes (3.6 s). Reduce Motion: still.
private struct WetTip: View {
    let reach: Double
    /// The sheen's length as a share of the stroke.
    let length: Double
    /// The stroke's own spectrum: the end keeps its colour, only thicker and breathing (amber is a moment only).
    let gradient: LinearGradient
    @Environment(\.motionReduced) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        BrushPath().trim(from: max(reach - length, 0), to: reach)
            .stroke(gradient, style: StrokeStyle(lineWidth: HomeStroke.now, lineCap: .round))
            .blur(radius: breathe ? 1.2 : 0.4)
            .opacity(breathe ? 0.55 : 1)
            .tesseraAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: breathe)
            .onAppear { breathe = !reduceMotion }
            .onChange(of: reduceMotion) { _, reduce in breathe = !reduce }
            .allowsHitTesting(false)
    }
}

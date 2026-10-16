import SwiftUI
import TesseraCore

/// WEEK: "this week, rolling on", "3 of 6 sessions", the days across as dabs, then sets per muscle in a bounded
/// window: a painted fill drawing toward this week's count over a soft sage band for the muscle's range.
struct WeekPage: View {
    let data: PlanData
    let now: Date
    @Environment(AppModel.self) private var model

    var body: some View {
        let week = data.week(now: now)
        let muscles = data.muscleSets(model: model, now: now)
        VStack(alignment: .leading, spacing: 0) {
            PlanHeading(context: data.plan == nil ? "this week" : "this week, rolling on",
                        headline: week.headline)
                .padding(.bottom, Theme.Spacing.xl)

            DaysAcross(week: week, data: data)
                .entrance(3)
                .padding(.bottom, Theme.Spacing.xl)

            Text("Sets per muscle")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
                .entrance(4)
                .padding(.bottom, Theme.Spacing.s)

            MuscleWindow(rows: muscles)
                .frame(minHeight: 150, maxHeight: 270)
                .entrance(5)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Days across

private struct DaysAcross: View {
    let week: PlanWeek
    let data: PlanData
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(week.days.enumerated()), id: \.element.id) { index, day in
                DayColumn(day: day, seed: index) { open(day) }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, -8)
        .accessibilityElement(children: .contain)
    }

    /// Done days zoom into their workout; today goes into live mode (starting the routine if nothing is set up).
    private func open(_ day: PlanWeek.Day) {
        switch day.state {
        case .done:
            if let id = day.workoutID {
                model.open(.object(id))
            }
        case .today:
            if let id = day.workoutID, let workout = model.object(id) {
                model.startWorkout(workout)
            } else if let routine = data.cycle.first(where: { $0.title == day.routine }), model.canStart(routine),
                      let result = try? model.engine.perform(StartRoutine(routine: routine.id, time: AppClock.now),
                                                             by: .user)
            {
                model.startWorkout(result.output)
            }
        default:
            break
        }
    }
}

private struct DayColumn: View {
    let day: PlanWeek.Day
    let seed: Int
    let action: () -> Void
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        let isToday = day.state == .today
        let tappable = day.state == .done || isToday
        Button(action: action) {
            VStack(spacing: Theme.Spacing.s) {
                Text(day.date.formatted(.dateTime.weekday(.narrow)))
                    .textRole(.label)
                    .foregroundStyle(isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                dab
                    .frame(width: 34, height: 30)
                Text(caption)
                    .font(PageType.caption)
                    .foregroundStyle(day.state == .rest ? Theme.Colors.muted : Theme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .disabled(!tappable)
        .modifier(ZoomSource(id: Route.object(day.workoutID ?? UUID()),
                             namespace: day.state == .done ? namespace : nil))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityHint(isToday ? "Starts the workout" : day.state == .done ? "Opens the workout" : "")
        .accessibilityAddTraits(tappable ? .isButton : [])
    }

    @ViewBuilder private var dab: some View {
        let tilt = Angle.degrees(Double((seed * 37) % 20) - 10)
        switch day.state {
        case .done:
            DabShape(seed: seed).fill(day.paint?.color ?? Theme.Colors.health)
                .rotationEffect(tilt).blur(radius: 0.5)
        case .today:
            DabShape(seed: seed).stroke(day.paint?.color ?? Theme.Colors.live, lineWidth: 2.5)
                .rotationEffect(tilt).blur(radius: 0.3)
        case .planned:
            DabShape(seed: seed).stroke(Theme.Colors.ink.opacity(0.25), lineWidth: 1.5)
                .rotationEffect(tilt).blur(radius: 0.3)
        case .rest, .open:
            Color.clear
        }
    }

    private var caption: String {
        switch day.state {
        case .rest: "Rest"
        case .open: " "
        default: day.routine.map(RoutinePaint.short) ?? " "
        }
    }

    private var spoken: String {
        let name = day.date.formatted(.dateTime.weekday(.wide))
        let routine = day.routine ?? ""
        return switch day.state {
        case .done: "\(name), \(routine), done"
        case .today: "\(name), today, \(routine)"
        case .planned: "\(name), \(routine), planned"
        case .rest: "\(name), rest"
        case .open: "\(name), nothing planned"
        }
    }
}

// MARK: - Sets per muscle

private struct MuscleWindow: View {
    let rows: [MuscleSets]

    var body: some View {
        let scale = MuscleSets.scale(rows)
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    MuscleFillRow(row: row, scale: scale, index: index)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 44, for: .scrollContent)
        .fadesAtBottom(from: 0.82)
    }
}

/// One 50 pt row: the name, the fill stroke over its range band, the count. Under the band is just short of it.
private struct MuscleFillRow: View {
    let row: MuscleSets
    let scale: Double
    let index: Int
    @State private var drawn: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let fill = CGFloat(min(row.sets / scale, 1))
        HStack(spacing: Theme.Spacing.m) {
            Text(row.name)
                .textRole(.bodyStrong)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.8)
                .frame(width: typeSize.isAccessibilitySize ? 150 : 112, alignment: .leading)
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Theme.Colors.health.opacity(0.16))
                        .frame(width: width * CGFloat((row.range.upperBound - row.range.lowerBound) / scale),
                               height: 14)
                        .offset(x: width * CGFloat(row.range.lowerBound / scale))
                    FillStroke()
                        .stroke(Theme.Colors.ink.opacity(0.14), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    FillStroke(progress: fill * drawn)
                        .stroke(row.paint?.color ?? Theme.Colors.inkSecondary,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .blur(radius: 0.4)
                        .opacity(row.sets > 0 ? 1 : 0)
                }
                .frame(height: proxy.size.height)
            }
            .frame(height: 20)
            Text(row.count)
                .font(Theme.numeral(21, weight: .regular))
                .foregroundStyle(Theme.Colors.ink)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .frame(minHeight: 50)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            if reduceMotion {
                drawn = 1
            } else {
                withTesseraAnimation(.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.8).delay(Double(min(index, 10)) * 0.06),
                                     reduceMotion: reduceMotion) { drawn = 1 }
            }
        }
    }

    private var spoken: String {
        let count = row.count.replacingOccurrences(of: "½", with: " and a half")
        let low = Format.kilograms(row.range.lowerBound), high = Format.kilograms(row.range.upperBound)
        return "\(row.name), \(count) sets this week, range \(low) to \(high)"
    }
}

/// The fill's path: "M2 11 C 60 7, 120 13, 188 9" on a 190 × 20 box, drawn in to `progress`.
struct FillStroke: Shape {
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 190, scaleY = rect.height / 20
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }
        var path = Path()
        path.move(to: point(2, 11))
        path.addCurve(to: point(188, 9), control1: point(60, 7), control2: point(120, 13))
        return path.trimmedPath(from: 0, to: max(min(progress, 1), 0))
    }
}

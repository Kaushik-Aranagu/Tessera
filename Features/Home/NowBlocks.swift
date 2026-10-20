import SwiftUI
import TesseraCore

/// The building blocks that sit under Next on Now: what Tess did today (always, when she did something), then the
/// body weight trend and Habits when "Areas shown" is All. Each block draws nothing when it has nothing to say.
struct NowBlocks: View {
    @Environment(AppModel.self) private var model

    /// Body weight and Habits show only when Areas shown is All. A dedicated Review row per block would be better;
    /// this reads the shared one for now.
    static func showsAreas(_ value: String?) -> Bool {
        value == "All"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WhatTessDid()
                .padding(.top, Theme.Spacing.xl)
            if Self.showsAreas(ReviewChoices.shared.value(of: "areasShown")) {
                BodyWeightBlock()
                    .padding(.top, Theme.Spacing.xl)
                HabitsBlock(lines: HabitLine.read(model))
                    .padding(.top, Theme.Spacing.xl)
            }
        }
    }
}

// MARK: - Body weight

/// The trend in big type, today's weight smaller beside it, the week in one plain sentence, and a quiet 90-day line:
/// the trend strong, the weigh-ins as faint dots. No arrows, no red or green, no goal.
struct BodyWeightBlock: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let day = TesseraDay(calendar: .current)
        let points = BodyWeightTrend.series(BodyWeightTrend.daily(WeighInNotes.read(model), day: day.day(of:)))
        MarginSection(label: "Body weight") {
            if let last = points.last {
                let rate = BodyWeightTrend.rateLine(BodyWeightTrend.weeklyRate(points))
                let isToday = last.day == day.today(AppClock.now)
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                        Text("\(BodyWeightTrend.format(last.trend)) kg")
                            .textRole(.titleNumber)
                            .foregroundStyle(Theme.Colors.ink)
                        if isToday {
                            Text("today \(BodyWeightTrend.format(last.kg))")
                                .textRole(.data)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                        }
                    }
                    if let rate {
                        Text(rate)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    TrendLine(points: BodyWeightTrend.recent(points))
                        .frame(height: 56)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(BodyWeightCopy.voiceOver(trend: last.trend, today: isToday ? last.kg : nil,
                                                             rate: rate))
            } else {
                Text(BodyWeightCopy.empty)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum BodyWeightCopy {
    static let empty = "No weigh-ins yet. Tell Tess \"82 kg\"."

    /// "Body weight trend 80.0 kilograms, today 80.6, 0.3 kg less than last week".
    static func voiceOver(trend: Double, today: Double?, rate: String?) -> String {
        var parts = ["Body weight trend \(BodyWeightTrend.format(trend)) kilograms"]
        if let today {
            parts.append("today \(BodyWeightTrend.format(today))")
        }
        if let rate {
            parts.append(rate)
        }
        return parts.joined(separator: ", ")
    }
}

/// The quiet line: trend as a stroke, raw weigh-ins as faint dots, scaled to their own range.
private struct TrendLine: View {
    let points: [BodyWeightTrend.Point]

    var body: some View {
        Canvas { context, size in
            guard points.count > 1, let first = points.first?.day, let last = points.last?.day else { return }
            let values = points.flatMap { [$0.kg, $0.trend] }
            let low = (values.min() ?? 0) - 0.2
            let high = (values.max() ?? 1) + 0.2
            let span = max(last.timeIntervalSince(first), 1)
            func place(_ day: Date, _ kg: Double) -> CGPoint {
                CGPoint(x: size.width * day.timeIntervalSince(first) / span,
                        y: size.height * (1 - (kg - low) / max(high - low, 0.1)))
            }
            for point in points {
                let center = place(point.day, point.kg)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 1.5, y: center.y - 1.5, width: 3, height: 3)),
                             with: .color(Theme.Colors.inkTertiary))
            }
            var path = Path()
            for (index, point) in points.enumerated() {
                let at = place(point.day, point.trend)
                if index == 0 {
                    path.move(to: at)
                } else {
                    path.addLine(to: at)
                }
            }
            context.stroke(path, with: .color(Theme.Colors.ink),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Habits

/// One habit on the block. Core has no Habit class yet, so nothing reads one in; the block is ready for when it does.
struct HabitLine: Identifiable, Equatable {
    let id: UUID
    let name: String
    let done: Int
    let target: Int
    let markedToday: Bool

    /// Core's Habit engine isn't here yet: no habits to read.
    @MainActor
    static func read(_: AppModel) -> [HabitLine] {
        []
    }

    /// Days after today in the Monday-to-Sunday week (his 04:00 day).
    static func daysLeft(in day: Date, calendar: Calendar) -> Int {
        (8 - calendar.component(.weekday, from: day)) % 7
    }
}

/// Habits as a block (sheet 85 words, HabitsCopy): the week's context line, then one row per habit with its count
/// at the right. Counts consistency, never a streak; a zero reads as the target.
struct HabitsBlock: View {
    let lines: [HabitLine]

    var body: some View {
        let today = TesseraDay(calendar: .current).today(AppClock.now)
        let weekday = today.formatted(.dateTime.weekday(.wide))
        MarginSection(label: "Habits") {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(HabitsCopy.context(weekday: weekday,
                                        daysLeft: HabitLine.daysLeft(in: today, calendar: .current)))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                if lines.isEmpty {
                    Text(HabitsCopy.empty)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                                Text(line.name).textRole(.body).foregroundStyle(Theme.Colors.ink)
                                Spacer(minLength: Theme.Spacing.m)
                                Text(HabitsCopy.count(done: line.done, target: line.target))
                                    .textRole(.data)
                                    .foregroundStyle(Theme.Colors.inkSecondary)
                            }
                            .frame(minHeight: 44)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(HabitsCopy.voiceOver(line.name, done: line.done, target: line.target,
                                                                     markedToday: line.markedToday))
                            if index < lines.count - 1 {
                                RowSeparator()
                            }
                        }
                    }
                }
            }
        }
    }
}

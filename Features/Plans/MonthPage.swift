import SwiftUI
import TesseraCore

/// MONTH: the month's name, "Session 11 of 26", then the month as dabs in a seven-column grid. A trained day is a
/// dab in its routine's paint, sized and strengthened by volume against usual; today is ringed; future days are
/// muted numerals. A two-dab key, and one forward-looking line from Tess.
struct MonthPage: View {
    let data: PlanData
    let now: Date
    @Environment(AppModel.self) private var model

    var body: some View {
        let calendar = Calendar.current
        let month = data.month(model.ledger, now: now, calendar: calendar)
        let week = data.week(now: now, calendar: calendar)
        let pending = week.days.contains { $0.state == .today }
        let planned = data.perWeek.map { perWeek in
            PlanRhythm.perMonth(perWeek: perWeek, days: calendar.range(of: .day, in: .month, for: now)?.count ?? 30)
        }
        VStack(alignment: .leading, spacing: 0) {
            PlanHeading(context: now.formatted(.dateTime.month(.wide)),
                        headline: PlanMonth.headline(done: month.done, pendingToday: pending, planned: planned))
                .padding(.bottom, Theme.Spacing.xl)

            MonthGrid(month: month, calendar: calendar)
                .entrance(3)
                .padding(.bottom, Theme.Spacing.l)

            Key()
                .entrance(4)
                .padding(.bottom, Theme.Spacing.l)

            if let line = tessLine(month: month, week: week, calendar: calendar) {
                Text(line)
                    .font(PageType.voice)
                    .foregroundStyle(Theme.Colors.tess)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Tess: \(line)")
                    .entrance(5)
            }

            Spacer(minLength: 0)
        }
    }

    private func tessLine(month: PlanMonth, week: PlanWeek, calendar: Calendar) -> String? {
        guard let previous = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
        let lastMonth = model.ledger.month(containing: previous, calendar: calendar).reduce(0) { $0 + $1.sessions }
        let left = week.days.count { $0.state == .today || $0.state == .planned }
        return PlanMonth.tessLine(done: month.done, lastMonth: lastMonth, leftThisWeek: left,
                                  month: now.formatted(.dateTime.month(.wide)),
                                  previous: previous.formatted(.dateTime.month(.wide)))
    }
}

private struct MonthGrid: View {
    let month: PlanMonth
    let calendar: Calendar
    @Environment(\.motionReduced) private var reduceMotion

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        let rows = (month.cells.count + 6) / 7
        // Six-week months tighten their rows so the page still fits one screen.
        let rowHeight: CGFloat = rows > 5 ? 40 : 46
        VStack(spacing: Theme.Spacing.s) {
            HStack(spacing: 0) {
                ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, letter in
                    Text(letter).textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            LazyVGrid(columns: columns, spacing: rows > 5 ? 4 : 8) {
                ForEach(month.cells) { cell in
                    DayDab(cell: cell)
                        .frame(height: rowHeight)
                        // Dabs fade up row by row.
                        .riseIn(cell.id < 0 ? 0 : (cell.id - 1 + leading) / 7, token: 0, stagger: 0.05)
                }
            }
        }
    }

    private var leading: Int {
        month.cells.count { $0.day == nil }
    }

    private var weekdayLetters: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0 ..< 7).map { symbols[(start + $0) % 7] }
    }
}

private struct DayDab: View {
    let cell: PlanMonth.Cell
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        if let day = cell.day {
            Button {
                if let id = cell.workoutID {
                    model.open(.object(id))
                }
            } label: {
                ZStack {
                    if let paint = cell.paint, cell.weight != nil {
                        DabShape(seed: day)
                            .fill(paint.color.opacity(cell.opacity))
                            .frame(width: cell.size, height: cell.size * 0.88)
                            .rotationEffect(.degrees(Double((day * 41) % 24) - 12))
                            .blur(radius: 1)
                    }
                    if cell.isToday {
                        DabShape(seed: day)
                            .stroke(Theme.Colors.live, lineWidth: 2.5)
                            .frame(width: 34, height: 30)
                            .rotationEffect(.degrees(Double((day * 41) % 24) - 12))
                    }
                    Text("\(day)")
                        .font(PageType.caption)
                        .monospacedDigit()
                        .foregroundStyle(numeral)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .disabled(cell.workoutID == nil)
            .modifier(ZoomSource(id: Route.object(cell.workoutID ?? UUID()),
                                 namespace: cell.workoutID == nil ? nil : namespace))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spoken(day))
            .accessibilityAddTraits(cell.workoutID == nil ? [] : .isButton)
        } else {
            Color.clear.accessibilityHidden(true)
        }
    }

    private var numeral: Color {
        if let weight = cell.weight, weight > 0.6 {
            return Theme.Colors.paper
        }
        return cell.isFuture ? Theme.Colors.muted : Theme.Colors.ink
    }

    private func spoken(_ day: Int) -> String {
        let date = cell.date?.formatted(.dateTime.weekday(.wide).month(.wide).day()) ?? "\(day)"
        let today = cell.isToday ? ", today" : ""
        guard let weight = cell.weight else { return date + today }
        let effort = weight > 0.75 ? "heavier than usual" : weight < 0.5 ? "lighter than usual" : "a usual session"
        return "\(date)\(today), trained, \(effort)"
    }
}

/// A small faint dab "lighter" and a big strong one "heavier than usual". Nothing else explains it.
private struct Key: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            PaintDab(color: Theme.Colors.live.opacity(0.35), size: CGSize(width: 14, height: 12), seed: 1)
            Text("lighter")
            PaintDab(color: Theme.Colors.live.opacity(0.9), size: CGSize(width: 24, height: 21), seed: 2)
                .padding(.leading, Theme.Spacing.s)
            Text("heavier than usual")
        }
        .font(PageType.small)
        .foregroundStyle(Theme.Colors.inkSecondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bigger, stronger dabs mean heavier sessions than usual")
    }
}

import SwiftUI
import TesseraCore

// The Training Log (Product build sheet, Oct 22): sessions by month, newest month first. Every word comes from Core's
// `TrainingStats.logMonths`; the page only lays it out. A private session is an outline row with its date and
// "Private workout" and nothing else. Calories show only behind the `caloriesBurned` switch, and Core says them.

enum LogSwitch {
    nonisolated static let choiceID = "trainingLog"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// A row with the identity the page needs to turn it (Core's `LogRow` is a value).
struct LogEntry: Identifiable {
    let id: Int
    let row: TrainingStats.LogRow
}

struct TrainingLogPage: View {
    let close: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 is the newest month.
    @State private var page = 0

    var body: some View {
        let months = TrainingStats(store: model.store, classes: model.classes).logMonths(
            now: AppClock.now,
            calories: CaloriesOptions(on: ReviewChoices.shared.value(of: "caloriesBurned") == "On")
        )
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if months.isEmpty {
                    Text("Sessions you finish are listed here.")
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.l)
                } else {
                    let index = min(page, months.count - 1)
                    monthTitle(months, index: index)
                    PageTurnRows(items: entries(of: months[index]), page: index) { entry in
                        LogRowView(row: entry.row, open: { open(entry.row) })
                    }
                    .padding(.top, Theme.Spacing.m)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        // A swipe left turns to the older month, right to the newer one.
        .pageSwipe { next in turn(next ? 1 : -1, count: months.count) }
    }

    private var header: some View {
        Button(action: close) {
            Text("‹ Training")
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel("Back to Training")
    }

    /// The month as a large word with its two neighbours as plain ink words.
    private func monthTitle(_ months: [TrainingStats.LogMonth], index: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(months[index].month.formatted(.dateTime.month(.wide).year()))
                .font(Theme.voice(size: 44).weight(.medium))
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: turn(-1, count: months.count)
                    case .decrement: turn(1, count: months.count)
                    @unknown default: break
                    }
                }
            HStack(spacing: Theme.Spacing.xl) {
                if index + 1 < months.count {
                    Button("Earlier") { turn(1, count: months.count) }
                        .buttonStyle(InkLabelWordStyle())
                }
                if index > 0 {
                    Button("Later") { turn(-1, count: months.count) }
                        .buttonStyle(InkLabelWordStyle())
                }
            }
        }
    }

    private func turn(_ delta: Int, count: Int) {
        let next = min(max(page + delta, 0), max(count - 1, 0))
        guard next != page else { return }
        page = next
    }

    private func entries(of month: TrainingStats.LogMonth) -> [LogEntry] {
        month.rows.enumerated().map { LogEntry(id: $0.offset, row: $0.element) }
    }

    /// The row's workout, found by its title and date (Core's row is a value); a private row opens nothing.
    private func open(_ row: TrainingStats.LogRow) {
        guard !row.isPrivate, let workoutClass = model.classDef(.workout) else { return }
        let match = model.store.objects(of: workoutClass).first { workout in
            let when = (model.store.value("endedAt", of: workout) ?? model.store.value("startedAt", of: workout))?
                .dateValue
            return workout.title == row.title && when.map { abs($0.timeIntervalSince(row.date)) < 1 } == true
        }
        if let match {
            close()
            model.open(.object(match.id))
        }
    }
}

/// One session: its title, then the date, sets, length and (when on) calories as one line of plain words.
private struct LogRowView: View {
    let row: TrainingStats.LogRow
    let open: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .textRole(.body)
                    .foregroundStyle(row.isPrivate ? Theme.Colors.inkSecondary : Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(details)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var day: String {
        row.date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// "Oct 14, 22 sets, 1 hr 35 min, about 280 kcal"; a private row is its date alone.
    private var details: String {
        if row.isPrivate {
            return day
        }
        return [day, row.setsText, row.duration, row.calories].compactMap(\.self).joined(separator: ", ")
    }

    private var spoken: String {
        let date = row.date.formatted(.dateTime.month(.wide).day())
        if row.isPrivate {
            return "\(row.title), \(date)."
        }
        let duration = row.duration.map {
            $0.replacingOccurrences(of: " hr", with: " hour").replacingOccurrences(of: " min", with: " minutes")
        }
        return ([row.title, date, row.setsText, duration, row.calories].compactMap(
            \.self
        )).joined(separator: ", ") + "."
    }
}

import SwiftUI
import TesseraCore

/// Week thread v2 (feature 168, Review switch "Week thread"): the Routines week as one thin rose thread across seven
/// days, solid where a routine ran that day and a quiet gap where none did. Never a mark, never red, never a count of
/// what was missed. It reuses the page's thread grammar (`ThreadMetrics.width`, rounded line). Reduce Motion: it
/// appears without drawing.
enum RoutinesWeekThreadData {
    struct Day: Equatable {
        /// Midnight of the Tessera day.
        let date: Date
        let ran: Bool
    }

    /// The seven days ending today (oldest first), each with whether any run started on it. A day starts at 04:00.
    static func days(runs: [Date], now: Date, calendar: Calendar = .current) -> [Day] {
        let tesseraDay = TesseraDay(calendar: calendar)
        let today = tesseraDay.day(of: now)
        let ran = Set(runs.map { tesseraDay.day(of: $0) })
        return (0 ..< 7).reversed().compactMap { back in
            guard let date = tesseraDay.calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return Day(date: date, ran: ran.contains(date))
        }
    }

    /// The thread is drawn only when at least one day ran; an all-gap week draws nothing (no count of gaps either).
    static func hasThread(_ days: [Day]) -> Bool {
        days.contains { $0.ran }
    }

    /// "Ran on Monday, Wednesday and Thursday." Names only the days that ran.
    static func spoken(_ days: [Day], calendar: Calendar = .current) -> String {
        let names = days.filter(\.ran).map { TesseraDay.weekdayName(of: $0.date, calendar: calendar) }
        // The thread is hidden when no day ran, so there is never a "nothing ran" line to say.
        switch names.count {
        case 0, 1: return names.first.map { "Ran on \($0)" } ?? ""
        default: return "Ran on \(names.dropLast().joined(separator: ", ")) and \(names[names.count - 1])"
        }
    }

    /// One letter under each day.
    static func letter(of date: Date, calendar: Calendar = .current) -> String {
        String(TesseraDay.weekdayName(of: date, calendar: calendar).prefix(1))
    }

    /// Every finished workout made from a routine is one run of it (the same rule `RoutinesFront` uses).
    @MainActor
    static func runStarts(model: AppModel) -> [Date] {
        guard let workoutClass = model.classDef(.workout) else { return [] }
        let store = model.store
        return store.objects(of: workoutClass).compactMap { workout in
            guard !workout.isDeleted,
                  store.linkedObjects("routine", of: workout).first != nil,
                  let start = store.value("startedAt", of: workout)?.dateValue,
                  let end = store.value("endedAt", of: workout)?.dateValue, end > start else { return nil }
            return start
        }
    }
}

/// The Review switch "Week thread", default Off.
enum WeekThreadSwitch {
    nonisolated static let choiceID = "weekThreadV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// The Review switch "Routines day", default Off.
enum RoutinesDaySwitch {
    nonisolated static let choiceID = "routinesDayV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

struct RoutinesWeekThread: View {
    let days: [RoutinesWeekThreadData.Day]
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        if RoutinesWeekThreadData.hasThread(days) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                WeekLine(ran: days.map(\.ran))
                    .trim(from: 0, to: reduceMotion || drawn ? 1 : 0)
                    .stroke(accent, style: StrokeStyle(lineWidth: ThreadMetrics.width, lineCap: .round))
                    .frame(height: ThreadMetrics.width)
                    .tesseraAnimation(Theme.Motion.house, value: drawn)
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        Text(RoutinesWeekThreadData.letter(of: day.date))
                            .textRole(.data)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .onAppear { drawn = true }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(RoutinesWeekThreadData.spoken(days))
        }
    }
}

/// Seven cells across; a line through each cell where a routine ran, a gap (nothing) where not. Runs on neighbouring
/// days join into one stretch.
private struct WeekLine: Shape {
    let ran: [Bool]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !ran.isEmpty else { return path }
        let cell = rect.width / CGFloat(ran.count)
        let inset: CGFloat = 6
        var index = 0
        while index < ran.count {
            guard ran[index] else { index += 1; continue }
            var end = index
            while end + 1 < ran.count, ran[end + 1] {
                end += 1
            }
            path.move(to: CGPoint(x: rect.minX + CGFloat(index) * cell + inset, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + CGFloat(end + 1) * cell - inset, y: rect.midY))
            index = end + 1
        }
        return path
    }
}

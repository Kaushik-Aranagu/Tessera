import SwiftUI
import TesseraCore

/// Review side v0 (M2 slice 14): the week so far as one sentence, seven day dabs, the counts in a line, what was
/// put away and the workouts, then one forward-looking Tess line. Counts only: never streaks, never misses.
/// One screen tall; no cards, no chart box.
///
/// Entry point: present `ReviewView()` (it brings its own navigation), or launch with `-review` in DEBUG
/// (`-demoReview` finishes and puts away a few demo tasks first).
struct ReviewView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ReviewPageBody()
                .toolbarTitleDisplayMode(.inline)
        }
        .environment(\.animateEntrance, true)
        #if DEBUG
            .task { ReviewDemo.seedIfRequested(model) }
        #endif
    }
}

// MARK: - The week, computed

/// What happened in the last seven days, read from Core (tasks, the op log, the training ledger).
@MainActor
struct ReviewWeek {
    struct PutAway: Identifiable {
        let id: UUID
        let title: String
        let movedAt: Date
    }

    let interval: DateInterval
    /// The seven days, oldest first, and whether anything got done on each.
    let days: [Date]
    let goodDays: [Bool]
    let tasksDone: Int
    let notesWritten: Int
    let putAway: [PutAway]
    let workouts: [WorkoutSummary]

    var goodDayCount: Int {
        goodDays.count(where: \.self)
    }

    static func compute(_ model: AppModel, now: Date, calendar: Calendar = .current) -> ReviewWeek {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let interval = DateInterval(start: start, end: max(now, start))
        let tasks = TaskList(store: model.store, classes: model.classes)

        let doneDates = tasks.all().compactMap { item -> Date? in
            guard item.isDone, let doneAt = model.store.value("doneAt", of: item.task)?.dateValue,
                  interval.contains(doneAt) else { return nil }
            return doneAt
        }
        let notes = NoteList(store: model.store, classes: model.classes).recent(limit: 1000)
            .count { interval.contains($0.createdAt) }

        // Put away = still in Later, sent there this week (by "not now → Later" or the 7-roll rule).
        let later = Dictionary(uniqueKeysWithValues: tasks.later().map { ($0.id, $0) })
        var putAway: [UUID: PutAway] = [:]
        for record in model.engine.history(limit: 1000)
            where record.state != .undone && interval.contains(record.createdAt)
            && ["moveTask", "rollForwardTasks"].contains(record.action)
        {
            for id in record.objectIDs where putAway[id] == nil {
                if let item = later[id] {
                    putAway[id] = PutAway(id: id, title: item.title, movedAt: record.createdAt)
                }
            }
        }

        var workouts: [WorkoutSummary] = []
        var day = start
        while day <= now {
            workouts += model.ledger.finishedWorkouts(on: day, calendar: calendar)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let days = (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let finished = doneDates + workouts.compactMap(\.endedAt)
        let goodDays = days.map { day in finished.contains { calendar.isDate($0, inSameDayAs: day) } }

        return ReviewWeek(
            interval: interval, days: days, goodDays: goodDays, tasksDone: doneDates.count, notesWritten: notes,
            putAway: putAway.values.sorted { $0.movedAt > $1.movedAt },
            workouts: workouts.sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
        )
    }
}

@MainActor
enum ReviewCopy {
    /// "Four good days of seven", "A quiet week so far" (a good day = anything finished).
    static func headline(_ count: Int) -> String {
        WeekReview.headline(count)
    }

    /// "9 tasks done, 3 workouts and 2 notes." Zeros are left out rather than counted.
    static func counts(_ week: ReviewWeek) -> String {
        let parts = [
            (week.tasksDone, "task done", "tasks done"),
            (week.workouts.count, "workout", "workouts"),
            (week.notesWritten, "note", "notes"),
        ].filter { $0.0 > 0 }.map { "\($0.0) \($0.0 == 1 ? $0.1 : $0.2)" }
        guard let last = parts.last else { return "Nothing finished yet, and that's fine." }
        return (parts.count == 1 ? last : parts.dropLast().joined(separator: ", ") + " and " + last) + "."
    }

    /// Tess's one line, looking forward: a muscle behind its weekly sets, else what's resting in Later.
    @MainActor
    static func tess(_ week: ReviewWeek, model: AppModel) -> String? {
        if let line = WeekReview.tessLine(MuscleVolume.compute(model, in: week.interval)) {
            return line
        }
        switch week.putAway.count {
        case 0: return nil
        case 1: return "\(week.putAway[0].title) is resting in Later. Want it back on Monday?"
        default: return "\(SpokenTime.number(week.putAway.count).capitalized) things are resting in Later. "
            + "Pick one for Monday?"
        }
    }

    /// The day as a short name ("Mon"), or "today".
    static func day(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "today"
        }
        return date.formatted(.dateTime.weekday(.abbreviated))
    }
}

// MARK: - The page

private struct ReviewPageBody: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let week = ReviewWeek.compute(model, now: now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("the week so far")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text(ReviewCopy.headline(week.goodDayCount))
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("\(ReviewCopy.headline(week.goodDayCount)). "
                        + WeekReview.consistencyLine(week.goodDayCount))
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                WeekDabs(days: week.days, good: week.goodDays, now: now)
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(2)

                Text(ReviewCopy.counts(week))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(3)

                if !week.putAway.isEmpty {
                    MarginSection(label: "Put away") {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(week.putAway.prefix(3)) { item in
                                ReviewLine(title: item.title, when: ReviewCopy.day(item.movedAt, now: now),
                                           tint: Theme.Colors.inkSecondary)
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(4)
                }

                if !week.workouts.isEmpty {
                    MarginSection(label: "Workouts", color: Theme.Colors.training) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(week.workouts.prefix(4)) { workout in
                                ReviewLine(title: workout.title,
                                           when: workout.endedAt.map { ReviewCopy.day($0, now: now) },
                                           tint: Theme.Colors.training)
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(5)
                }

                if let line = ReviewCopy.tess(week, model: model) {
                    Text(line)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(6)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }
}

/// Seven dabs, oldest to today: filled sage where something got done, a faint ink ring otherwise (neutral, never
/// red). Each fills in turn the first time the page appears; with Reduce Motion they're simply there.
private struct WeekDabs: View {
    let days: [Date]
    let good: [Bool]
    let now: Date
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let isToday = Calendar.current.isDate(day, inSameDayAs: now)
                let filled = good[index] && (shown || reduceMotion)
                VStack(spacing: Theme.Spacing.s) {
                    PaintDab(color: filled ? Theme.Colors.health : Theme.Colors.ink.opacity(0.25),
                             size: CGSize(width: 34, height: 30), seed: index + 11, filled: filled)
                        .scaleEffect(filled || !good[index] ? 1 : 0.8)
                        .animation(reduceMotion ? nil : Theme.Motion.house.delay(Double(index) * 0.05),
                                   value: shown)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .textRole(.label)
                        .foregroundStyle(isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide)))\(isToday ? ", today" : ""), "
                    + (good[index] ? "something done" : "quiet"))
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear { shown = true }
    }
}

/// One line in a section: the title, and the day hanging right in the section's colour.
private struct ReviewLine: View {
    let title: String
    let when: String?
    let tint: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Text(title)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Spacing.m)
            if let when {
                Text(when)
                    .textRole(.data)
                    .foregroundStyle(tint)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
    /// `-demoReview`: finish two of the demo tasks and put one away, so the page has something to count.
    @MainActor
    enum ReviewDemo {
        static func seedIfRequested(_ model: AppModel) {
            guard ProcessInfo.processInfo.arguments.contains("-demoReview") else { return }
            let tasks = TaskList(store: model.store, classes: model.classes)
            let open = tasks.all().filter { !$0.isDone }
            guard open.count >= 3, NoteList(store: model.store, classes: model.classes).recent().isEmpty else { return }
            for item in open.prefix(2) {
                _ = try? model.engine.perform(SetTaskDone(task: item.id), by: .user)
            }
            _ = try? model.engine.perform(MoveTask(task: open[2].id, later: true), by: .user)
            _ = try? model.engine.perform(CreateNote(body: "Deload next week on @Bench Press"), by: .user)
            model.touch()
        }
    }
#endif

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
        // His days (04:00 to 04:00): at 01:00 Saturday the week still ends on Friday.
        let tesseraDay = TesseraDay(calendar: calendar)
        // The plan's week, Monday first, as on Home (Research Q2): days ahead are simply not here yet.
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2
        let today = tesseraDay.today(now)
        let weekday = (mondayFirst.component(.weekday, from: today) + 5) % 7
        let firstKey = calendar.date(byAdding: .day, value: -weekday, to: today) ?? today
        let start = tesseraDay.start(of: calendar.date(byAdding: .hour, value: 12, to: firstKey) ?? firstKey)
        let interval = DateInterval(start: start, end: max(now, start))
        let tasks = TaskList(store: model.store, classes: model.classes)

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

        // Each day's sessions belong to the day they started, as everywhere else.
        let days = (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: firstKey) }
        let byDay = days.map { model.ledger.finishedWorkouts(onDay: $0, calendar: calendar) }
        let workouts = byDay.flatMap(\.self)
        // A task done counts on the day it was done where it was done (trip R12).
        let doneDays = WeekFactsBuilder(engine: model.engine, calendar: calendar).tasksDoneByDay()
        let goodDays = days.indices.map { index in
            !byDay[index].isEmpty || doneDays[days[index]] ?? 0 > 0
        }

        return ReviewWeek(
            interval: interval, days: days, goodDays: goodDays,
            // The same count as the bands: each done on its own day where it happened (Design on #552).
            tasksDone: days.filter { $0 <= today }.reduce(0) { $0 + (doneDays[$1] ?? 0) }, notesWritten: notes,
            putAway: putAway.values.sorted { $0.movedAt > $1.movedAt },
            workouts: workouts.sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
        )
    }
}

@MainActor
enum ReviewCopy {
    /// Anything done counts here (Research's review-sentence §4): "Something done on four days", "Something done
    /// every day", "A quiet week so far". Never "good", never "of seven".
    static func headline(_ count: Int) -> String {
        switch count {
        case 0: "A quiet week so far"
        case 7: "Something done every day"
        case 1: "Something done on one day"
        default: "Something done on \(SpokenTime.number(count)) days"
        }
    }

    /// "9 tasks done, 3 workouts and 2 notes." Zeros are left out rather than counted.
    static func counts(_ week: ReviewWeek) -> String {
        let parts = [
            (week.tasksDone, "task done", "tasks done"),
            (week.workouts.count, "workout", "workouts"),
            (week.notesWritten, "note", "notes"),
        ].filter { $0.0 > 0 }.map { "\($0.0) \($0.0 == 1 ? $0.1 : $0.2)" }
        guard let last = parts.last else { return "Nothing to count this week." }
        return (parts.count == 1 ? last : parts.dropLast().joined(separator: ", ") + " and " + last) + "."
    }

    /// Tess's one line, looking forward: a muscle behind its weekly sets, else what's resting in Later.
    @MainActor
    static func tess(_ week: ReviewWeek, model: AppModel) -> String? {
        // Quiet about sets on thin weeks (3 sessions or fewer): a fact there reads as a debt.
        if week.workouts.count > 3, let line = WeekReview.tessLine(MuscleVolume.compute(model, in: week.interval)) {
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
        if TesseraDay(calendar: calendar).isSameDay(date, now) {
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
                ReviewHeadline(text: ReviewCopy.headline(week.goodDayCount))
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("\(ReviewCopy.headline(week.goodDayCount)). "
                        + WeekReview.consistencyLine(week.goodDayCount))
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                WeekDabs(days: week.days, good: week.goodDays,
                         plan: WeekReview.planMarks(model, days: week.days, now: now, calendar: WeekReview.mondayFirst),
                         now: now)
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
                    MarginSection(label: "Workouts", color: Theme.Colors.inkSecondary) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(week.workouts.prefix(4)) { workout in
                                ReviewLine(title: workout.title,
                                           when: workout.endedAt.map { ReviewCopy.day($0, now: now) },
                                           tint: Theme.Colors.inkSecondary)
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

                // The look, until Settings exists: "Porcelain by day, Obsidian by night", each name a value word.
                LookSentence()
                    .padding(.top, Theme.Spacing.section)

                // His rest day, until Settings exists (RG4).
                RestDaySentence()
                    .padding(.top, Theme.Spacing.xxl)

                // Claude, until Settings exists: the key, the month and what Tess may send.
                ClaudeSection()
                    .padding(.top, Theme.Spacing.xxl)

                // The quiet way in to backups: a label word at the foot of the week.
                NavigationLink {
                    BackupView()
                } label: {
                    Text("Backups")
                }
                .buttonStyle(.labelWord)
                .padding(.top, Theme.Spacing.l)
                .accessibilityHint("Where your history is kept")
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }
}

/// Seven marks, oldest to today, as on Home's Review: sage where something got done, the dry rest stroke where the
/// plan rests, the faint ring for an open day, nothing before first use. Each pops in turn the first time the page
/// appears; with Reduce Motion they're simply there.
private struct WeekDabs: View {
    let days: [Date]
    let good: [Bool]
    let plan: [Date: WeekReview.DayMark]
    let now: Date
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func mark(_ index: Int) -> WeekReview.DayMark {
        if good[index] {
            return .trained(1)
        }
        let planned = plan[Calendar.current.startOfDay(for: days[index])]
        if planned == .rest {
            return .rest
        }
        return planned ?? .planned
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let isToday = day == TesseraDay().today(now)
                let mark = mark(index)
                VStack(spacing: Theme.Spacing.s) {
                    DayMarkView(mark: mark, seed: index + 11, delay: 0.1 + Double(index) * 0.05)
                        .frame(width: 34, height: 30)
                        .scaleEffect(shown || reduceMotion ? 1 : 0.8)
                        .opacity(shown || reduceMotion ? 1 : 0)
                        .animation(reduceMotion ? nil : Theme.Motion.house.delay(Double(index) * 0.05),
                                   value: shown)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .textRole(.label)
                        .foregroundStyle(mark == .none || mark == .planned ? Theme.Colors.inkTertiary
                            : isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide)))\(isToday ? ", today" : ""), "
                    + (good[index] ? "something done" : mark == .rest ? "rest" : mark == .planned ? "planned" : "open"))
                .accessibilityHidden(mark == .none)
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
            guard LaunchFlags.has("-demoReview") else { return }
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

import SwiftUI
import TesseraCore

// MARK: - The week, computed

/// The plan's week (Monday first) as Review's bands read it: training marks, tasks done and cooks per day, and the
/// day log's lines. Core's WeekFacts lens replaces the per-day counts when it lands; the shape here stays.
@MainActor
struct ReviewWeekData {
    let now: Date
    let calendar: Calendar
    /// Day keys (midnights), Monday to Sunday.
    let days: [Date]
    let today: Date
    let marks: [WeekReview.DayMark]
    let sessions: [[WorkoutSummary]]
    let perWeek: Int?
    /// The sentence, for VoiceOver.
    let headline: String
    /// The hero: the count alone ("Four sessions", "All six sessions"); "the week so far" above it says the rest.
    let hero: String
    /// Core's pick of the week's lines (a record, a first, the fullest day).
    let coreBestLines: [WeekFacts.Line]
    /// Per day: nil for a day still ahead (or before first use), else the count.
    let tasksDone: [Int?]
    let cooked: [Int?]
    let lines: [Int: [DayLine]]

    static func compute(_ model: AppModel, now: Date, calendar: Calendar) -> ReviewWeekData {
        let tesseraDay = TesseraDay(calendar: calendar)
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let week = model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        let days = week.map(\.day)
        let today = tesseraDay.today(now)
        let firstUse = ReviewPage.firstUse(model)
        let firstDay = firstUse.map { tesseraDay.day(of: $0) }
        let firstWeek = firstUse.map { use in days.first.map { use >= $0 } ?? false } ?? false
        let firstUseToday = firstUse.map { tesseraDay.isSameDay($0, now) } ?? false
        let restToday = NowPicker(engine: model.engine).restDay(plan: plan, at: now, sessionsPerWeek: perWeek,
                                                                calendar: calendar) != nil
        let marks = WeekReview.marks(week.map(WeekReview.Slot.init), firstUse: firstUse, restToday: restToday,
                                     now: now, calendar: calendar)
        let sessionCount = week.reduce(0) { $0 + $1.done.count }
        let headline = WeekReview.headline(sessions: sessionCount, perWeek: perWeek, firstWeek: firstWeek,
                                           firstUseToday: firstUseToday)

        func past(_ day: Date) -> Bool {
            day <= today && (firstDay.map { day >= $0 } ?? true)
        }
        // Tasks done and cooks, by the day they happened where they happened (never the day they were planned
        // for; a hotel Wednesday stays Wednesday at home, trip R12), read the way the week's facts read them.
        let builder = WeekFactsBuilder(engine: model.engine, calendar: calendar)
        let dones = builder.tasksDoneByDay()
        let cooks = builder.cooksByDay()
        let tasksDone = days.map { day -> Int? in past(day) ? dones[day] ?? 0 : nil }
        let cooked = days.map { day -> Int? in past(day) ? cooks[day]?.count ?? 0 : nil }
        // The day log's lines for each day so far (a window of history per day, never the whole log).
        var lines: [Int: [DayLine]] = [:]
        for (index, day) in days.enumerated() where past(day) {
            lines[index] = builder.lines(onDay: day, now: now, isRestDay: marks[index] == .rest)
        }
        let hero: String = if sessionCount == 0 {
            firstUseToday ? "Your first week" : "A quiet week"
        } else if let perWeek, perWeek > 0, sessionCount == perWeek {
            "All \(SpokenTime.number(perWeek)) sessions"
        } else {
            "\(headline.lead) \(sessionCount == 1 ? "session" : "sessions")"
        }
        return ReviewWeekData(now: now, calendar: calendar, days: days, today: today, marks: marks,
                              sessions: week.map(\.done), perWeek: perWeek,
                              headline: "\(headline.lead) \(headline.tail)", hero: hero,
                              coreBestLines: builder.facts(weekContaining: now, plan: plan, now: now).bestLines,
                              tasksDone: tasksDone, cooked: cooked, lines: lines)
    }

    func isPast(_ index: Int) -> Bool {
        tasksDone[index] != nil
    }

    func isToday(_ index: Int) -> Bool {
        days[index] == today
    }

    var sessionCount: Int {
        sessions.reduce(0) { $0 + $1.count }
    }

    /// "3 of 6", or the bare count without a plan.
    var trainingFigure: String {
        perWeek.map { "\(sessionCount) of \($0)" } ?? String(sessionCount)
    }

    var sessionLine: String {
        WeekReview.sessionLine(sessions: sessionCount, perWeek: perWeek)
    }

    /// Always US English, like every other line Tess writes (Product 8:30 PM PT).
    func dayName(_ index: Int) -> String {
        days[index].formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "en_US_POSIX")))
    }

    func letter(_ index: Int) -> String {
        days[index].formatted(.dateTime.weekday(.narrow))
    }

    /// A day's finished lines. Days whose log has no words yet (history seeded without ops) read from their sessions.
    func logLines(_ index: Int) -> [DayLine] {
        let finished = (lines[index] ?? []).filter { $0.kind == .finished }
        guard finished.isEmpty else { return finished }
        return sessions[index].map { workout in
            let best = workout.records.first.map { ", \($0.exercise) best" } ?? ""
            return DayLine(time: workout.startedAt, text: "\(workout.title) done\(best).", objectIDs: [workout.id],
                           kind: .finished)
        }
    }

    /// Core picks the week's three best lines when WeekFacts lands (a best, a first, a record count). Until then:
    /// finished lines, a best or a first ahead of the rest, newest first among equals, shown in day order.
    var bestLines: [WeekLines.Row] {
        // Core's pick when the log has words; the session fallback otherwise.
        let core = coreBestLines.compactMap { pick -> WeekLines.Row? in
            guard let index = days.firstIndex(where: { $0 == pick.day }) else { return nil }
            return WeekLines.Row(id: "\(index)-\(pick.line.text)",
                                 lead: days[index].formatted(.dateTime.weekday(.abbreviated)),
                                 text: pick.line.text, objectID: pick.line.objectIDs.first)
        }
        if !core.isEmpty {
            return core
        }
        func score(_ line: DayLine) -> Int {
            let text = line.text.lowercased()
            if text.contains("best") || text.contains("record") || text.contains(" pr") {
                return 3
            }
            if text.contains("first") {
                return 2
            }
            return 1
        }
        let candidates = days.indices.flatMap { index in logLines(index).map { (index, $0) } }
        let picked = candidates.sorted {
            score($0.1) == score($1.1) ? $0.0 > $1.0 : score($0.1) > score($1.1)
        }.prefix(3)
        return picked.sorted { $0.0 < $1.0 }.map { index, line in
            WeekLines.Row(id: "\(index)-\(line.text)", lead: days[index].formatted(.dateTime.weekday(.abbreviated)),
                          text: line.text, objectID: line.objectIDs.first)
        }
    }

    /// The page reading one day: its name, its own line as the hero, and its log lines (at most 4).
    struct Day {
        let name: String
        /// The day's own line, longest first; the page draws the first that fits one line (never "…").
        let heroForms: [String]
        let lines: [WeekLines.Row]

        var hero: String {
            heroForms[0]
        }
    }

    func day(_ index: Int) -> Day {
        let done = tasksDone[index] ?? 0
        let doneWords = done == 0 ? nil : "\(done) done"
        // The day's best fact: the first record line ("Bench 85 × 8, best."), else the first record the summary knows.
        let best = logLines(index).first { $0.text.contains(", best.") }?.text.split(separator: " ").first
            .map { "\($0) best" }
            ?? sessions[index].first?.records.first.map { "\(TesseraCore.ExerciseWords.short($0.exercise)) best" }
        let forms: [String] = if let workout = sessions[index].first {
            [[best, doneWords].compactMap(\.self).joined(separator: ", "),
             [workout.title, doneWords].compactMap(\.self).joined(separator: ", "),
             workout.title].filter { !$0.isEmpty }
        } else if let doneWords {
            [doneWords]
        } else if marks[index] == .rest {
            ["Rest day"]
        } else if isPast(index) {
            ["A quiet day"]
        } else {
            ["Still ahead"]
        }
        let dayLines = (lines[index] ?? []).filter { $0.kind != .tail }
        let rows = (dayLines.isEmpty ? logLines(index) : dayLines).prefix(4).map { line in
            WeekLines.Row(id: "\(index)-\(line.text)", lead: line.clock(calendar) ?? "", text: line.text,
                          objectID: line.objectIDs.first)
        }
        var seen = Set<String>()
        return Day(name: dayName(index), heroForms: forms.filter { seen.insert($0).inserted }, lines: rows)
    }

    /// VoiceOver reads each band as one element.
    var trainingSpoken: String {
        let marks = days.indices.map { index -> String in
            switch self.marks[index] {
            case .trained: "\(dayName(index)) trained"
            case .rest: "\(dayName(index)) rest"
            case .open: "\(dayName(index)) open"
            case .planned, .none: ""
            }
        }.filter { !$0.isEmpty }
        return "Training, \(sessionLine). " + marks.joined(separator: ", ") + "."
    }

    var tasksSpoken: String {
        let total = tasksDone.compactMap(\.self).reduce(0, +)
        let parts = days.indices.compactMap { index -> String? in
            guard let count = tasksDone[index], count > 0 else { return nil }
            return "\(dayName(index)) \(count)"
        }
        return "Tasks done, \(total). " + parts.joined(separator: ", ") + "."
    }

    var cookedSpoken: String {
        let names = days.indices.filter { (cooked[$0] ?? 0) > 0 }.map(dayName)
        return "Cooked, \(names.count). " + names.joined(separator: ", ") + "."
    }
}

// MARK: - Bands

/// The seven day letters: today in ink, past days inkSecondary, days ahead inkTertiary. Each is a column's handle.
struct DayLetters: View {
    let week: ReviewWeekData
    let reading: Int?
    let read: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(week.days.indices, id: \.self) { index in
                Text(week.letter(index))
                    .textRole(.label)
                    .foregroundStyle(week.isToday(index) || reading == index ? Theme.Colors.ink
                        : week.isPast(index) ? Theme.Colors.inkSecondary : Theme.Colors.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .opacity(reading == nil || reading == index ? 1 : 0.3)
                    .contentShape(Rectangle())
                    .onTapGesture { read(index) }
                    .accessibilityLabel(week.dayName(index))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Reads \(week.dayName(index)).")
            }
        }
    }
}

/// One band: a Label 16 inkSecondary at the left, its week figure at the right in ink, and a mark per day under it
/// in the day's column. A column being read keeps its mark; the rest recede to 30%.
struct WeekBand<Cell: View>: View {
    let label: String
    let figure: String?
    let height: CGFloat
    let reading: Int?
    let read: (Int) -> Void
    let spoken: String
    @ViewBuilder let cell: (Int) -> Cell

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                Spacer(minLength: 0)
                if let figure {
                    Text(figure)
                        .textRole(.labelStrong)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
            HStack(spacing: 0) {
                ForEach(0 ..< 7, id: \.self) { index in
                    cell(index)
                        .frame(maxWidth: .infinity)
                        .opacity(reading == nil || reading == index ? 1 : 0.3)
                        .contentShape(Rectangle())
                        .onTapGesture { read(index) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(height: height, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

/// A day's numeral in a band (tasks, money): Label 16/600 tabular; "·" at 38% for a day with none.
struct WeekNumeral: View {
    let value: String?
    let muted: Bool

    var body: some View {
        if muted {
            Color.clear.frame(height: 20)
        } else if let value, value != "0" {
            Text(value)
                .textRole(.labelStrong)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.ink)
        } else {
            Text("·")
                .textRole(.labelStrong)
                .foregroundStyle(Theme.Colors.ink.opacity(0.38))
        }
    }
}

/// THE WEEK'S LINES (or a day's name over its own lines): "Tue  Bench 85 × 8, a best." at 16, the lead in 600
/// inkSecondary. A line opens its thing.
struct WeekLines: View {
    struct Row: Identifiable {
        let id: String
        let lead: String
        let text: String
        let objectID: UUID?
    }

    let title: String
    let rows: [Row]
    let calendar: Calendar
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.bottom, 2)
            if rows.isEmpty {
                Text("Nothing written down yet.")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            ForEach(Array(rows.enumerated()), id: \.element.id) { offset, row in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text(row.lead)
                        .font(Theme.voice(size: 16))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.inkSecondary)
                    Text(row.text.replacingOccurrences(of: " × ", with: "\u{00A0}×\u{00A0}"))
                        .font(Theme.voice(size: 16))
                        .foregroundStyle(Theme.Colors.ink)
                        // A long line wraps; nothing on this page ends in "…" (QA F1).
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: 24)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let id = row.objectID {
                        model.open(.object(id))
                    }
                }
                .entrance(7 + offset)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

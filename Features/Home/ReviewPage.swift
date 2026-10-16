import SwiftUI
import TesseraCore

// MARK: - Week maths (pure)

/// Consistency and volume for the Review page. Counts days, never streaks; missed days are neutral.
enum WeekReview {
    /// Weekly working sets per muscle that count as "enough" (a common hypertrophy floor).
    static let weeklySetTarget = 10

    /// The last `count` days ending today, oldest first, each at the start of its day.
    static func lastDays(_ count: Int = 7, endingAt now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0 ..< count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    /// One flag per day: whether anything was trained that day.
    static func trainedDays(_ dates: [Date], on days: [Date], calendar: Calendar) -> [Bool] {
        days.map { day in dates.contains { calendar.isDate($0, inSameDayAs: day) } }
    }

    /// Distinct days with training among the last `days` days, today included.
    static func daysTrained(_ dates: [Date], lastDays days: Int = 7, endingAt now: Date, calendar: Calendar) -> Int {
        trainedDays(dates, on: lastDays(days, endingAt: now, calendar: calendar), calendar: calendar)
            .count(where: \.self)
    }

    /// The hero sentence: "Four good days of seven", "A quiet week so far".
    static func headline(_ count: Int, of days: Int = 7) -> String {
        guard count > 0 else { return "A quiet week so far" }
        let number = SpokenTime.number(count)
        let noun = count == 1 ? "good day" : "good days"
        return "\(number.prefix(1).uppercased())\(number.dropFirst()) \(noun) of \(SpokenTime.number(days))"
    }

    /// The hero opens with a session count: "Four sessions of six", "One session so far", "No sessions yet".
    /// Every finished workout counts, so two in a day are two.
    static func sessionHeadline(done: Int, planned: Int?) -> String {
        guard done > 0 else { return "No sessions yet" }
        let number = SpokenTime.number(done)
        let spoken = number.prefix(1).uppercased() + number.dropFirst()
        let noun = done == 1 ? "session" : "sessions"
        guard let planned, planned > 0 else { return "\(spoken) \(noun) so far" }
        return "\(spoken) \(noun) of \(SpokenTime.number(planned))"
    }

    /// "4 of 6 sessions this week" (VoiceOver).
    static func sessionLine(done: Int, planned: Int?) -> String {
        planned.map { "\(done) of \($0) sessions this week" } ?? "\(done) sessions this week"
    }

    /// "Done 4 of the last 7 days" (for VoiceOver and anywhere the plain count reads better).
    static func consistencyLine(_ count: Int, of days: Int = 7) -> String {
        "Done \(count) of the last \(days) days"
    }

    /// Tess's one line: the muscle furthest behind its weekly target (over the last seven days), if any is.
    @MainActor
    static func tessLine(_ volume: [MuscleVolume], target: Int = weeklySetTarget) -> String? {
        // Only muscles trained this week: an untrained muscle out of 18 isn't "behind", it just isn't in the plan.
        let trained = volume.filter { $0.sets > 0 }
        guard let behind = trained.min(by: { $0.sets < $1.sets }), behind.sets < target else { return nil }
        let sets = behind.sets == 1 ? "1 set" : "\(behind.sets) sets"
        return "\(behind.muscle.title) is a little behind: \(sets) of \(target) this week."
    }
}

/// Sets per muscle, read through the object model: workout → entries → sets, entry → exercise class → its
/// profile's primary muscles (walking up the class chain, so Paused Bench Press counts like Bench Press).
struct MuscleVolume: Identifiable, Equatable {
    let id: UUID
    let muscle: ObjectRecord
    let sets: Int

    @MainActor
    init(muscle: ObjectRecord, sets: Int) {
        id = muscle.id
        self.muscle = muscle
        self.sets = sets
    }

    @MainActor
    static func compute(_ model: AppModel, in interval: DateInterval) -> [MuscleVolume] {
        var counts: [UUID: Int] = [:]
        for (workout, date) in HomeData.trainingDates(model) where interval.contains(date) {
            for entry in workout.orderedChildren {
                guard let exercise = model.store.linkedClass("exercise", of: entry) else { continue }
                let sets = entry.orderedChildren.count(where: { set in
                    model.store.number("reps", of: set) != nil && model.store.value("isWarmup", of: set) != .bool(true)
                })
                guard sets > 0 else { continue }
                for muscle in muscles(of: exercise, model: model) {
                    counts[muscle.id, default: 0] += sets
                }
            }
        }
        return model.objects(of: .muscle)
            .map { MuscleVolume(muscle: $0, sets: counts[$0.id] ?? 0) }
            .sorted { $0.sets == $1.sets ? $0.muscle.title < $1.muscle.title : $0.sets > $1.sets }
    }

    @MainActor
    static func muscles(of exercise: ClassDef, model: AppModel) -> [ObjectRecord] {
        var current: ClassDef? = exercise
        var seen = Set<UUID>()
        while let classDef = current, seen.insert(classDef.id).inserted {
            if let profile = model.prototype(of: classDef) {
                let muscles = model.store.linkedObjects("primaryMuscles", of: profile)
                if !muscles.isEmpty {
                    return muscles
                }
            }
            current = classDef.parent
        }
        return []
    }
}

// MARK: - Page

/// REVIEW: "the week so far", a sentence instead of a chart, seven day dabs and one line from Tess.
struct ReviewPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let calendar = Calendar.current
        // The plan's week from Core: done days carry their workouts, days ahead carry the plan or a rest day.
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let week = model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        let sessions = week.reduce(0) { $0 + $1.done.count }
        let window = week.first.map { DateInterval(start: $0.day, end: now) }
        let volume = window.map { MuscleVolume.compute(model, in: $0) } ?? []

        VStack(alignment: .leading, spacing: 0) {
            Text("the week so far")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .padding(.bottom, Theme.Spacing.m)
                .entrance(0)

            Text(WeekReview.sessionHeadline(done: sessions, planned: perWeek))
                .textRole(.hero)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(WeekReview.sessionLine(done: sessions, planned: perWeek))
                .siblingParallax()
                .entrance(1, hero: true)
                .padding(.bottom, Theme.Spacing.xxl)

            DayDabs(week: week, now: now, calendar: calendar)
                .entrance(2)
                .padding(.bottom, Theme.Spacing.xxl)

            if let line = WeekReview.tessLine(volume) {
                Text(line)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.tess)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(3)
            }

            Spacer(minLength: 0)
        }
    }
}

/// The week, Monday to Sunday, one mark a day. A trained day is a sage dab (a second, smaller dab for a second
/// session). A rest day the plan leaves is a small muted dab: rest is part of the plan, not a gap. A day still
/// planned is a faint ring; a past day with nothing is a quiet ring, never red. Letters underneath; today's in ink.
private struct DayDabs: View {
    let week: [WeekDay]
    let now: Date
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.offset) { index, day in
                let isToday = calendar.isDate(day.day, inSameDayAs: now)
                VStack(spacing: Theme.Spacing.s) {
                    mark(day, seed: index)
                        .frame(width: 40, height: 30)
                    Text(day.day.formatted(.dateTime.weekday(.narrow)))
                        .textRole(.label)
                        .foregroundStyle(isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(day, isToday: isToday))
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func mark(_ day: WeekDay, seed: Int) -> some View {
        if !day.done.isEmpty {
            ZStack(alignment: .topTrailing) {
                PaintDab(color: Theme.Colors.health, size: CGSize(width: 34, height: 30), seed: seed)
                if day.done.count > 1 {
                    PaintDab(color: Theme.Colors.health.opacity(0.8), size: CGSize(width: 16, height: 14),
                             seed: seed + 3)
                        .offset(x: 8, y: -6)
                }
            }
        } else if day.isRest {
            PaintDab(color: Theme.Colors.muted.opacity(0.45), size: CGSize(width: 16, height: 13), seed: seed)
        } else if day.state == .past {
            PaintDab(color: Theme.Colors.ink.opacity(0.25), size: CGSize(width: 34, height: 30), seed: seed,
                     filled: false)
        } else {
            PaintDab(color: Theme.Colors.ink.opacity(0.12), size: CGSize(width: 34, height: 30), seed: seed,
                     filled: false)
        }
    }

    private func label(_ day: WeekDay, isToday: Bool) -> String {
        let name = day.day.formatted(.dateTime.weekday(.wide))
        let state: String = switch day.done.count {
        case 0: day.isRest ? "rest day" : day.state == .past ? "nothing logged" : "planned"
        case 1: "trained"
        default: "trained, \(day.done.count) sessions"
        }
        return isToday ? "\(name), today, \(state)" : "\(name), \(state)"
    }
}

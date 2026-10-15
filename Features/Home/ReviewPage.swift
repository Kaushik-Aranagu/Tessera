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
        let dates = HomeData.trainingDates(model).map(\.date)
        let days = WeekReview.lastDays(endingAt: now, calendar: calendar)
        let trained = WeekReview.trainedDays(dates, on: days, calendar: calendar)
        let count = trained.count(where: \.self)
        let window = days.first.map { DateInterval(start: $0, end: now) }
        let volume = window.map { MuscleVolume.compute(model, in: $0) } ?? []

        VStack(alignment: .leading, spacing: 0) {
            Text("the week so far")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .padding(.bottom, Theme.Spacing.m)
                .entrance(0)

            Text(WeekReview.headline(count))
                .textRole(.hero)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("\(WeekReview.headline(count)). \(WeekReview.consistencyLine(count)).")
                .siblingParallax()
                .entrance(1, hero: true)
                .padding(.bottom, Theme.Spacing.xxl)

            DayDabs(days: days, trained: trained)
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

/// Seven dabs, 34×30, oldest to today. A trained day is filled with sage (done days); a missed day is an empty ink
/// ring at 25% — neutral, never red. Letters sit underneath; today's is in ink.
private struct DayDabs: View {
    let days: [Date]
    let trained: [Bool]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let isToday = index == days.count - 1
                VStack(spacing: Theme.Spacing.s) {
                    PaintDab(
                        color: trained[index] ? Theme.Colors.health : Theme.Colors.ink.opacity(0.25),
                        size: CGSize(width: 34, height: 30),
                        seed: index,
                        filled: trained[index]
                    )
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .textRole(.label)
                        .foregroundStyle(isToday ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(day, trained: trained[index], isToday: isToday))
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func label(_ day: Date, trained: Bool, isToday: Bool) -> String {
        let name = day.formatted(.dateTime.weekday(.wide))
        let state = trained ? "trained" : "rest"
        return isToday ? "\(name), today, \(state)" : "\(name), \(state)"
    }
}

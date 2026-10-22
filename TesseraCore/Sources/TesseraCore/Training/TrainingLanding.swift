import Foundation

/// The Training landing's facts (L1 to L6): today's routine, how long it takes, the lift it opens with and the week as
/// marks. Computed on the phone; a private routine reads as a private workout and gives no duration or opener. The
/// running workout and the place knob (Gym or Home) are read by the app (`ProcessTable.openWorkout()` and the place
/// state), not here.
@MainActor
public extension TrainingStats {
    struct LandingFacts: Equatable, Sendable {
        public enum Mark: String, Sendable { case done, today, open, rest }
        public let routine: String?
        public let isPrivate: Bool
        public let minutes: Int?
        public let opener: Opener?
        public let marks: [Mark]
        public let isRestDay: Bool

        public struct Opener: Equatable, Sendable {
            public let exercise: String
            public let weightKg: Double
        }
    }

    /// Minutes between a workout's first and last logged set.
    func workoutMinutes(_ workout: ObjectRecord) -> Int? {
        var first: Date?
        var last: Date?
        for entry in workout.orderedChildren {
            for set in entry.orderedChildren {
                guard let at = store.value("loggedAt", of: set)?.dateValue else { continue }
                first = min(first ?? at, at)
                last = max(last ?? at, at)
            }
        }
        return first.flatMap { start in last.map { Int($0.timeIntervalSince(start) / 60) } }
    }

    /// The median length of the last 3 finished workouts of a routine, to the nearest 5 minutes; nil with none.
    func usualMinutes(of routine: ObjectRecord) -> Int? {
        guard let workoutClass = classes[.workout] else { return nil }
        let recent = store.objects(of: workoutClass).filter { workout in
            !workout.isDeleted && store.value("endedAt", of: workout) != nil
                && store.linkedObjects("routine", of: workout).first?.id == routine.id
        }
        .sorted { ($0.updatedAt) > ($1.updatedAt) }
        .prefix(3).compactMap(workoutMinutes).filter { $0 > 0 }.sorted()
        guard !recent.isEmpty else { return nil }
        let middle = recent.count.isMultiple(of: 2) ? (recent[recent.count / 2 - 1] + recent[recent.count / 2]) / 2
            : recent[recent.count / 2]
        return max(5, Int((Double(middle) / 5).rounded()) * 5)
    }

    /// When he usually starts a routine: the median time of day of the first set of the last 3 finished workouts of it,
    /// placed on `day`. Nil with no history. Rounded to the nearest 5 minutes.
    func usualStart(of routine: ObjectRecord, on day: Date, calendar: Calendar = .current) -> Date? {
        guard let workoutClass = classes[.workout] else { return nil }
        let starts = store.objects(of: workoutClass).filter { workout in
            !workout.isDeleted && store.value("endedAt", of: workout) != nil
                && store.linkedObjects("routine", of: workout).first?.id == routine.id
        }
        .sorted { $0.updatedAt > $1.updatedAt }.prefix(3).compactMap { workout -> Int? in
            let first = workout.orderedChildren.flatMap(\.orderedChildren)
                .compactMap { store.value("loggedAt", of: $0)?.dateValue }.min()
                ?? store.value("startedAt", of: workout)?.dateValue
            return first.map { date in
                let parts = calendar.dateComponents([.hour, .minute], from: date)
                return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        }
        .sorted()
        guard !starts.isEmpty else { return nil }
        let middle = starts.count.isMultiple(of: 2) ? (starts[starts.count / 2 - 1] + starts[starts.count / 2]) / 2
            : starts[starts.count / 2]
        let minutes = Int((Double(middle) / 5).rounded()) * 5
        return calendar.date(bySettingHour: minutes / 60 % 24, minute: minutes % 60, second: 0, of: day)
    }

    func landingFacts(plan: ObjectRecord?, now: Date, calendar: Calendar = .current) -> LandingFacts {
        let week = ledger.week(containing: now, plan: plan, now: now, calendar: calendar)
        let marks = week.map { day -> LandingFacts.Mark in
            switch day.state {
            case .done: .done
            case .today: day.isRest ? .rest : .today
            case .upcoming, .past: day.isRest ? .rest : .open
            }
        }
        let rest = ledger.restDay(plan: plan, now: now, calendar: calendar) != nil
        guard let today = week.first(where: { $0.state == .today }), let routine = today.planned, !rest else {
            return LandingFacts(routine: nil, isPrivate: false, minutes: nil, opener: nil, marks: marks,
                                isRestDay: rest)
        }
        let isPrivate = ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) != nil
        if isPrivate {
            return LandingFacts(routine: ObjectPrivacy.routineLabel, isPrivate: true, minutes: nil, opener: nil,
                                marks: marks, isRestDay: false)
        }
        var opener: LandingFacts.Opener?
        if let entry = routine.orderedChildren.first(where: { $0.classDef?.id == classes[.exerciseEntry]?.id }),
           let exercise = store.linkedClass("exercise", of: entry), let weight = ledger.prefill(for: entry).weight
        {
            opener = LandingFacts.Opener(exercise: exercise.name, weightKg: weight)
        }
        return LandingFacts(routine: routine.title, isPrivate: false, minutes: usualMinutes(of: routine),
                            opener: opener, marks: marks, isRestDay: false)
    }
}

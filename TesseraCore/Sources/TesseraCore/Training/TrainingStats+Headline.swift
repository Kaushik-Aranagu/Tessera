import Foundation

@MainActor
public extension TrainingStats {
    /// Two dated estimates for one exercise, in kilograms. A negative change is valid data, not a gain claim.
    struct E1RMChange: Equatable, Sendable {
        public let exerciseID: UUID
        public let exercise: String
        public let since: Date
        public let baselineDate: Date
        public let latestDate: Date
        public let baselineKg: Double
        public let latestKg: Double

        public var kilograms: Double {
            latestKg - baselineKg
        }
    }

    /// The current run against this plan's routines and the caller's weekly goal (the same rhythm as the week UI).
    /// Only finished, nonprivate workouts from those routines count, once per workout. The current plan and goal
    /// apply to history; this does not infer earlier versions of the plan or check individual fixed weekdays.
    /// An unfinished current week preserves the run through last week without adding a week. Once its goal is met,
    /// it joins the run. The first completed week below goal ends the count; older best runs are irrelevant.
    func consecutiveWeeksOnPlan(plan: ObjectRecord?, sessionsPerWeek: Int?, now: Date,
                                calendar: Calendar = .current) -> Int
    {
        guard let plan, !plan.isDeleted, let planClass = classes[.plan],
              plan.classDef.map({ ClassResolver.isSubclass($0, of: planClass) }) == true,
              ObjectPrivacy.shownLabel(of: plan, in: store, classes: classes) == nil,
              let sessionsPerWeek, sessionsPerWeek > 0 else { return 0 }
        let routines = Set(store.linkedObjects("routines", of: plan).filter { !$0.isDeleted }.map(\.id))
        guard !routines.isEmpty else { return 0 }
        let isPrivate = privateWorkouts().isPrivate
        func metGoal(_ week: DateInterval) -> Bool {
            let done = ledger.week(containing: week.start, plan: plan, now: now,
                                   sessionsPerWeek: sessionsPerWeek, calendar: calendar).flatMap(\.done)
            let counted = done.filter { summary in
                guard let ended = summary.endedAt, ended <= now, !isPrivate(summary.workout),
                      let routine = store.linkedObjects("routine", of: summary.workout).first else { return false }
                return routines.contains(routine.id)
            }
            return Set(counted.map(\.id)).count >= sessionsPerWeek
        }

        let day = TesseraDay(calendar: calendar)
        var week = day.week(containing: now)
        var count = metGoal(week) ? 1 : 0
        while let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: week.start), previous < week.start {
            week = day.week(containing: previous)
            guard metGoal(week) else { break }
            count += 1
        }
        return count
    }

    /// Latest eligible session at or before `since`, compared with the latest one in (`since`, `now`].
    /// Each point is that session's best eligible e1RM, using the ledger's formula and rep/RPE/warm-up rules.
    /// The explicit exercise class includes its subclasses, like `ledger.sessions(of:)`. Private workouts and
    /// private exercise titles are excluded. Both points must exist; a first number never becomes a gain claim.
    /// Values stay in kilograms; the app converts to the display unit and shows a gain only when it is positive.
    func e1RMChange(for exerciseID: UUID, since: Date, now: Date) -> E1RMChange? {
        guard since < now, let root = classes[.exercise], let exercise = store.classDef(id: exerciseID),
              ClassResolver.isSubclass(exercise, of: root) else { return nil }
        let lastKg = BodyWeight.lastKg(in: store)
        func isPlain(_ name: String) -> Bool {
            !ObjectPrivacy.isPrivateTitle(name, lastWeightKg: lastKg)
        }
        guard isPlain(exercise.name) else { return nil }
        var baseline: (date: Date, kg: Double)?
        var latest: (date: Date, kg: Double)?
        for session in counted(ledger.sessions(of: exercise)) where session.date <= now {
            guard let actualExercise = store.linkedClass("exercise", of: session.entry), isPlain(actualExercise.name),
                  let kg = session.sets.filter({ $0.isE1RMEligible && $0.reps > 0 && $0.weight > 0 })
                  .map(\.e1RM).filter({ $0.isFinite && $0 > 0 }).max() else { continue }
            if session.date <= since {
                if baseline.map({ session.date > $0.date }) ?? true {
                    baseline = (session.date, kg)
                } else if session.date == baseline?.date {
                    baseline?.kg = max(baseline?.kg ?? kg, kg)
                }
            } else if latest.map({ session.date > $0.date }) ?? true {
                latest = (session.date, kg)
            } else if session.date == latest?.date {
                latest?.kg = max(latest?.kg ?? kg, kg)
            }
        }
        guard let baseline, let latest else { return nil }
        return E1RMChange(exerciseID: exercise.id, exercise: exercise.name, since: since,
                          baselineDate: baseline.date, latestDate: latest.date,
                          baselineKg: baseline.kg, latestKg: latest.kg)
    }
}

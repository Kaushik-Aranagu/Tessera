import Foundation
import TesseraCore

/// Reads the plan, its sessions and this week's sets per muscle out of Core for `PlansView`.
@MainActor
struct PlanData {
    let plan: ObjectRecord?
    let cycle: [ObjectRecord]
    let next: ObjectRecord?
    let sessions: [TrainedSession]
    let today: (routine: String, id: UUID?)?
    let perWeek: Int?
    private let ledger: TrainingLedger

    init(model: AppModel, plan chosen: ObjectRecord?, now: Date) {
        let store = model.store
        let ledger = model.ledger!
        self.ledger = ledger
        plan = chosen ?? model.plan
        cycle = plan.map { store.linkedObjects("routines", of: $0) } ?? []
        next = plan.flatMap { ledger.nextRoutine(in: $0, now: now) }
        perWeek = PlanRhythm.perWeek(cycleCount: cycle.count)

        sessions = model.objects(of: .workout).compactMap { workout in
            guard let ended = store.value("endedAt", of: workout)?.dateValue else { return nil }
            return TrainedSession(workoutID: workout.id, date: ended, routine: Self.routine(of: workout, store: store),
                                  volume: Self.volume(of: workout, ledger: ledger))
        }

        let calendar = Calendar.current
        let candidates = [model.session?.workout, model.tonightWorkout(around: now)].compactMap(\.self)
        today = candidates.first { workout in
            guard store.value("endedAt", of: workout) == nil else { return false }
            let when = (store.value("startedAt", of: workout) ?? store.value("scheduledFor", of: workout))?.dateValue
            // His day runs 04:00 to 04:00: a session started at 23:50 is still today's at 00:30.
            return when.map { TesseraDay(calendar: calendar).isSameDay($0, now) } ?? false
        }
        .map { (Self.routine(of: $0, store: store), $0.id) }
    }

    var cycleTitles: [String] {
        cycle.map(\.title)
    }

    func week(now: Date, calendar: Calendar = .current) -> PlanWeek {
        PlanWeek.from(ledger.week(containing: now, plan: plan, now: now, calendar: calendar), cycle: cycleTitles,
                      perWeek: perWeek, todayWorkoutID: today?.id)
        { summary in
            Self.routine(of: summary.workout, store: ledger.store)
        }
    }

    func month(_ ledger: TrainingLedger, now: Date, calendar: Calendar = .current) -> PlanMonth {
        PlanMonth.build(days: ledger.month(containing: now, calendar: calendar).map {
            PlanMonth.Volume(day: $0.day, sessions: $0.sessions, relative: $0.relative)
        }, sessions: sessions,
        cycle: cycleTitles, now: now, calendar: calendar)
    }

    /// Sets per muscle this week (Core's fractional count) against each muscle's weekly range.
    func muscleSets(model: AppModel, now: Date, calendar: Calendar = .current) -> [MuscleSets] {
        let store = model.store
        let counts = model.ledger.weeklySets(weekContaining: now, calendar: calendar)
        let paints = dominantPaint(model: model, now: now, calendar: calendar)
        let rows = model.objects(of: .muscle).map { muscle in
            let low = store.number("weeklySetsMin", of: muscle) ?? 10
            let high = max(store.number("weeklySetsMax", of: muscle) ?? 20, low)
            return MuscleSets(id: muscle.id, name: muscle.title, sets: counts[muscle.id] ?? 0, range: low ... high,
                              paint: paints[muscle.id])
        }
        return MuscleSets.sorted(rows)
    }

    /// The routine that put the most sets on each muscle this week, so the fill wears that routine's paint.
    private func dominantPaint(model: AppModel, now: Date, calendar: Calendar) -> [UUID: RoutinePaint] {
        let week = TesseraDay(calendar: calendar).week(containing: now)
        let store = model.store
        var weights: [UUID: [String: Double]] = [:]
        for session in sessions where week.contains(session.date) {
            guard let workout = store.object(id: session.workoutID) else { continue }
            for entry in workout.orderedChildren {
                guard let exercise = store.linkedClass("exercise", of: entry) else { continue }
                let sets = Double(entry.orderedChildren.count { set in
                    model.ledger.setKind(set).counts && store.number("reps", of: set) != nil
                })
                for muscle in store.linkedObjects("primaryMuscles", ofClass: exercise) {
                    weights[muscle.id, default: [:]][session.routine, default: 0] += sets
                }
                for muscle in store.linkedObjects("secondaryMuscles", ofClass: exercise) {
                    weights[muscle.id, default: [:]][session.routine, default: 0] += sets / 2
                }
            }
        }
        return weights.compactMapValues { byRoutine in
            byRoutine.max { $0.value < $1.value }.map { RoutinePaint.of($0.key, cycle: cycleTitles) }
        }
    }

    // MARK: Helpers

    /// The routine's own title, as the key the week, month and paints match on (never shown as is): every place that
    /// draws or speaks it masks it there with `ObjectPrivacy.routineTitle` (G274, hunt 22).
    static func routine(of workout: ObjectRecord, store: ObjectStore) -> String {
        store.linkedObjects("routine", of: workout).first?.title ?? workout.title
    }

    static func volume(of workout: ObjectRecord, ledger: TrainingLedger) -> Double {
        workout.orderedChildren.reduce(0) { total, entry in
            total + entry.orderedChildren.reduce(0) { sum, set in
                ledger.setKind(set).counts ? sum + (ledger.store.number("volume", of: set) ?? 0) : sum
            }
        }
    }
}

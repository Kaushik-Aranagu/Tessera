import Foundation

/// The Training landing's stat lines (sheet 230): "3 of 6 this week", "14 sessions since Oct 1" and "+10 lb on bench
/// since Oct 1". Pure reads from the ledger; no number leads and nothing reads "lost" or "down".
@MainActor
public extension TrainingStats {
    struct WeekCount: Equatable, Sendable {
        public let done: Int
        public let planned: Int
    }

    /// Sessions done this week against the sessions the plan has for it: what is done, plus the days still ahead that
    /// the plan trains (today included when nothing is done yet). A rest day ahead is not a session.
    func weekCount(plan: ObjectRecord?, now: Date, calendar: Calendar = .current) -> WeekCount {
        let week = ledger.week(containing: now, plan: plan, now: now, calendar: calendar)
        let done = week.reduce(0) { $0 + $1.done.count }
        let ahead = week.filter { day in
            day.done.isEmpty && !day.isRest && day.planned != nil && (day.state == .today || day.state == .upcoming)
        }.count
        return WeekCount(done: done, planned: done + ahead)
    }

    /// How many sessions a week the plan asks for: its own number, else one per routine up to six; on fixed days, the
    /// days that have a routine.
    func sessionsPerWeek(of plan: ObjectRecord, now: Date, calendar: Calendar = .current) -> Int {
        if PlanSchedule.mode(of: plan, store: store) == .fixed, PlanSchedule.hasFixedDays(plan, store: store) {
            let days = TesseraDay(calendar: calendar).weekDays(containing: now)
            return days.filter { PlanSchedule.routine(on: $0, in: plan, store: store, calendar: calendar) != nil }.count
        }
        let routines = store.linkedObjects("routines", of: plan).count
        return Int(store.number("sessionsPerWeek", of: plan) ?? Double(min(max(routines, 1), 6)))
    }

    /// Sessions done since the 1st of the month, counting up and never resetting: the number, and the day it counts
    /// from. Days run 04:00 to 04:00 like every day count.
    struct MonthCount: Equatable, Sendable {
        public let count: Int
        public let since: Date
    }

    func sessionsThisMonth(now: Date, calendar: Calendar = .current) -> MonthCount {
        let tessera = TesseraDay(calendar: calendar)
        let today = tessera.today(now)
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        var count = 0
        var cursor = first
        while cursor <= today {
            count += ledger.finishedWorkouts(onDay: tessera.day(of: cursor.addingTimeInterval(3600 * 12)),
                                             calendar: calendar).count
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return MonthCount(count: count, since: first)
    }

    /// A lift that went up since a date, in display steps (2.5 kg or 5 lb).
    struct LiftGain: Equatable, Sendable {
        public let exercise: String
        public let exerciseID: UUID
        public let since: Date
        public let steps: Int
        public let unit: MassUnit

        /// The gain in kilograms, whole steps of the unit.
        public var kilograms: Double {
            let size = StatsMass.step(unit)
            return Double(steps) * size / (unit == .pounds ? MassUnit.poundsPerKilogram : 1)
        }
    }

    /// The lift to lead the landing with and how far it is up since `since`: of the lifts with counted sessions since
    /// then, the one done most often (ties by name), its best estimated max over its first 28 days there against its
    /// best
    /// in the last 28 days, in whole steps. Nil when there isn't enough to say, or it is not up.
    func headlineGain(since: Date, now: Date, unit: MassUnit = .kilograms, calendar _: Calendar = .current)
        -> LiftGain?
    {
        let recentStart = now.addingTimeInterval(-28 * 86400)
        var best: (gain: LiftGain, sessions: Int)?
        let last = BodyWeight.lastKg(in: store)
        let grouped = Dictionary(grouping: counted(), by: { $0.exercise.id })
        for group in grouped.values {
            let exercise = group[0].exercise
            // A lift whose name is a private word never leads the landing.
            guard !ObjectPrivacy.isPrivateTitle(exercise.name, lastWeightKg: last) else { continue }
            let all = group.map(\.session).filter { $0.date >= since && $0.date <= now }.sorted { $0.date < $1.date }
            func top(_ session: TrainingLedger.Session) -> Double? {
                session.sets.filter(\.isE1RMEligible).map(\.e1RM).max()
            }
            let eligible = all.filter { top($0) != nil }
            guard eligible.count >= 2, let first = eligible.first else { continue }
            let thenEnd = first.date.addingTimeInterval(28 * 86400)
            guard thenEnd <= recentStart,
                  let thenKg = eligible.filter({ $0.date < thenEnd }).compactMap(top).max(),
                  let nowKg = eligible.filter({ $0.date >= recentStart }).compactMap(top).max() else { continue }
            let size = StatsMass.step(unit)
            let steps = Int(((StatsMass.inDisplay(nowKg, unit) - StatsMass.inDisplay(thenKg, unit)) / size)
                .rounded(.toNearestOrAwayFromZero))
            guard steps > 0 else { continue }
            let gain = LiftGain(
                exercise: exercise.name,
                exerciseID: exercise.id,
                since: since,
                steps: steps,
                unit: unit
            )
            if best == nil || eligible.count > best!.sessions
                || (eligible.count == best!.sessions && exercise.name < best!.gain.exercise)
            {
                best = (gain, eligible.count)
            }
        }
        return best?.gain
    }
}

public extension TrainingSentences {
    /// "3 of 6 this week"; with nothing planned, "3 this week".
    static func weekCount(_ count: TrainingStats.WeekCount) -> String {
        count.planned > 0 ? "\(count.done) of \(count.planned) this week" : "\(count.done) this week"
    }

    /// "since Oct 1": the words after the number, which a screen sets in its own face.
    static func sinceFirst(_ month: TrainingStats.MonthCount, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return "\(month.count == 1 ? "session" : "sessions") since \(formatter.string(from: month.since))"
    }

    /// "14 sessions since Oct 1" for a surface that sets one line.
    static func sessionsSinceFirst(_ month: TrainingStats.MonthCount, calendar: Calendar = .current) -> String {
        "\(month.count) \(sinceFirst(month, calendar: calendar))"
    }

    /// "+10 lb on bench press since Oct 1". Only a gain has a line.
    @MainActor
    static func gain(_ gain: TrainingStats.LiftGain, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        let amount = StatsMass.text(kg: gain.kilograms, unit: gain.unit)
        return "+\(amount) on \(gain.exercise.lowercased()) since \(formatter.string(from: gain.since))"
    }

    /// "Starts with 8 min on the rower" for the landing brief (no final stop, like every shown line), or nil with no
    /// warm-up.
    static func warmUpLine(_ warmUp: WarmUp?) -> String? {
        warmUp.map { "Starts with \($0.phrase)" }
    }
}

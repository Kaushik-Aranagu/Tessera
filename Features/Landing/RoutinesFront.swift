import SwiftUI
import TesseraCore

/// What the Routines landing and its Browse rail know, read once from the store (Design 131 §2 Routines, 2c; build
/// sheet LR-n). Today every routine is a workout routine (Push A), so a run is a finished workout made from it; the
/// default runner for morning and night routines waits on run mode (PR 3), and until then the landing never shows a
/// routine that cannot run (a routine with no exercises is left out). Names are masked at the source: a private
/// routine reads "Private routine" and its counts are left off.
struct RoutinesFront {
    /// The rose: dusk rose #D79AA6 in the dark, #A4505F in the light (131 table E). Cobalt and violet are Tess's.
    static let accent = Color(light: 0xA4505F, dark: 0xD79AA6)

    struct Usual: Equatable {
        let days: Int
        let startMinuteOfDay: Int
        let lengthMinutes: Int
    }

    struct Item: Identifiable {
        let id: UUID
        let record: ObjectRecord
        /// "Private routine" when walled.
        let name: String
        let isPrivate: Bool
        let exercises: Int
        /// Nil before seven finished runs, and always for a private routine (no counts).
        let usual: Usual?
        let runsIn30: Int
        let lastRun: Date?
        /// When it finished today, if it did.
        let doneAt: Date?
        /// Days of the week it is pinned to in a fixed-days plan (1 Sunday to 7 Saturday).
        let weekdays: Set<Int>

        var place: RoutinePlace {
            RoutinePlace.of(startMinuteOfDay: usual?.startMinuteOfDay)
        }

        var line: String {
            if let doneAt {
                return RoutinesLandingWords.doneLine(name: name, at: doneAt)
            }
            if let usual {
                return RoutinesLandingWords.usualLine(name: name, days: usual.days,
                                                      startMinuteOfDay: usual.startMinuteOfDay,
                                                      lengthMinutes: usual.lengthMinutes)
            }
            // A private routine says nothing about what is in it.
            if isPrivate {
                return name
            }
            return RoutinesLandingWords.stepsLine(name: name, count: exercises, workout: true)
        }

        var railValue: String {
            guard !isPrivate else { return "" }
            return RoutinesLandingWords.railValue(days: usual?.days, startMinuteOfDay: usual?.startMinuteOfDay,
                                                  lengthMinutes: usual?.lengthMinutes, count: exercises, workout: true)
        }

        var spokenLine: String {
            if doneAt == nil, let usual {
                return RoutinesLandingWords.spokenLine(name: name, days: usual.days,
                                                       startMinuteOfDay: usual.startMinuteOfDay,
                                                       lengthMinutes: usual.lengthMinutes)
            }
            return line
        }
    }

    struct Running {
        /// The routine the live workout was made from, when it still exists.
        let routineID: UUID?
        let name: String
        let step: String
        let seconds: TimeInterval
    }

    let now: Date
    let items: [Item]
    let running: Running?
    /// The routine ids he usually runs today and has not run yet, in usual-start order.
    let todayIDs: [UUID]

    @MainActor
    init(model: AppModel, now: Date, calendar: Calendar = .current) {
        self.now = now
        let store = model.store
        let tesseraDay = TesseraDay(calendar: calendar)
        let today = tesseraDay.day(of: now)

        // Every finished workout made from a routine is one run of it.
        var runs: [UUID: [RoutineRun]] = [:]
        var finishedToday: [UUID: Date] = [:]
        if let workoutClass = model.classDef(.workout) {
            for workout in store.objects(of: workoutClass) where !workout.isDeleted {
                guard let routine = store.linkedObjects("routine", of: workout).first,
                      let start = store.value("startedAt", of: workout)?.dateValue,
                      let end = store.value("endedAt", of: workout)?.dateValue, end > start else { continue }
                runs[routine.id, default: []].append(RoutineRun(start: start, end: end))
                if tesseraDay.day(of: end) == today {
                    finishedToday[routine.id] = max(finishedToday[routine.id] ?? end, end)
                }
            }
        }

        let cutoff = now.addingTimeInterval(-30 * 86400)
        items = model.objects(of: .routine).filter { model.canStart($0) }.map { routine in
            let label = LandingNames.shown(routine, in: store, classes: model.classes)
            let isPrivate = label != routine.title
            let own = runs[routine.id] ?? []
            return Item(
                id: routine.id,
                record: routine,
                name: isPrivate ? RoutinesLandingWords.privateName : routine.title,
                isPrivate: isPrivate,
                exercises: routine.orderedChildren.filter { !$0.isDeleted }.count,
                usual: isPrivate ? nil : Self.usual(of: own, now: now, calendar: calendar),
                runsIn30: own.filter { $0.start >= cutoff }.count,
                lastRun: own.map(\.start).max(),
                doneAt: finishedToday[routine.id],
                weekdays: PlanSchedule.weekdays(of: routine, store: store)
            )
        }

        if let session = model.session, session.finishedAt == nil {
            let routine = store.linkedObjects("routine", of: session.workout).first
            let isPrivate = session.isPrivate
            running = Running(
                routineID: routine?.id,
                name: isPrivate ? RoutinesLandingWords.privateName : session.shownTitle,
                step: isPrivate ? RoutinesLandingWords.privateStep : (session.currentExercise?.name ?? "First set"),
                seconds: max(0, now.timeIntervalSince(session.lastTouchedAt))
            )
        } else {
            running = nil
        }

        todayIDs = Self.todayIDs(model: model, items: items, now: now, calendar: calendar)
    }

    // MARK: Counts

    /// Usual start (median of the last 14 runs, five minutes), usual length and the days he ran in the last 30. Core's
    /// `RoutineUsual` does the medians; nil before seven finished runs.
    static func usual(of runs: [RoutineRun], now: Date, calendar: Calendar) -> Usual? {
        guard runs.count >= RoutineUsual.runsNeeded else { return nil }
        let newest = runs.sorted { $0.start > $1.start }
        guard let counts = RoutineUsual.counts(of: Array(newest.prefix(14)), calendar: calendar) else { return nil }
        let tesseraDay = TesseraDay(calendar: calendar)
        let recent = newest.filter { $0.start >= now.addingTimeInterval(-30 * 86400) }
        let days = Set(recent.map { tesseraDay.day(of: $0.start) }).count
        guard days > 0 else { return nil }
        return Usual(days: days, startMinuteOfDay: (TesseraDay.startHour * 60 + counts.startMinutes) % 1440,
                     lengthMinutes: counts.lengthMinutes)
    }

    // MARK: Today

    /// In a fixed-days plan the routine pinned to today's weekday; on a rolling plan the one that comes next. Either
    /// way, nothing he has already run today.
    @MainActor
    private static func todayIDs(model: AppModel, items: [Item], now: Date, calendar: Calendar) -> [UUID] {
        guard let plan = model.plan else { return [] }
        var ids: [UUID] = []
        if PlanSchedule.mode(of: plan, store: model.store) == .fixed, PlanSchedule.hasFixedDays(
            plan,
            store: model.store
        ) {
            let weekday = calendar.component(.weekday, from: now)
            ids = items.filter { $0.weekdays.contains(weekday) }.map(\.id)
        } else if let next = model.ledger.nextRoutine(in: plan, now: now, calendar: calendar) {
            ids = [next.id]
        }
        let left = items.filter { ids.contains($0.id) && $0.doneAt == nil }
        return left.sorted { ($0.usual?.startMinuteOfDay ?? 1440) < ($1.usual?.startMinuteOfDay ?? 1440) }.map(\.id)
    }

    // MARK: Order

    /// Next usual start after now first, then the most used (ties by the latest run). Routines that ran today follow
    /// the ones still to come.
    var ordered: [Item] {
        let minute = RoutinesLandingWords.minuteOfDay(now)
        func ahead(_ item: Item) -> Int? {
            guard item.doneAt == nil, let usual = item.usual else { return nil }
            return (usual.startMinuteOfDay - minute + 1440) % 1440
        }
        let withStart = items.filter { ahead($0) != nil }.sorted { (ahead($0) ?? 0) < (ahead($1) ?? 0) }
        let rest = items.filter { ahead($0) == nil }.sorted(by: Self.moreUsed)
        return withStart + rest
    }

    /// Up to three Start words for a quiet day: the most used in the last 30 days, ties by the latest run.
    var startWords: [Item] {
        Array(items.sorted(by: Self.moreUsed).prefix(3))
    }

    private static func moreUsed(_ lhs: Item, _ rhs: Item) -> Bool {
        if lhs.runsIn30 != rhs.runsIn30 {
            return lhs.runsIn30 > rhs.runsIn30
        }
        return (lhs.lastRun ?? .distantPast) > (rhs.lastRun ?? .distantPast)
    }

    /// The up to three lines under the top: the ordered routines, less the one that is running.
    var lines: [Item] {
        Array(ordered.filter { $0.id != running?.routineID }.prefix(3))
    }

    // MARK: Sentences

    var doneToday: Int {
        items.filter { $0.doneAt != nil }.count
    }

    var allDone: Bool {
        !items.isEmpty && running == nil && doneToday == items.count
    }

    var subtitle: String {
        RoutinesLandingWords.subtitle(total: items.count, doneToday: doneToday)
    }

    /// The word that carries the page's one accent underline (build sheet Q3 default).
    enum Underlined { case pickUp, firstStart, browse }

    var underlined: Underlined {
        if running != nil {
            return .pickUp
        }
        if !items.isEmpty, !allDone {
            return .firstStart
        }
        return .browse
    }

    func item(_ id: UUID) -> Item? {
        items.first { $0.id == id }
    }
}

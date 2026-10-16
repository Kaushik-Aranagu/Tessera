import Foundation

// The ranker (context-packing slice 1, docs/research/context-packing.md §5; fixtures in
// docs/research/fixtures/ranker.md). Precedence: a running process, then a timed task within 15 minutes, then a
// planned rest day, then re-entry, then the scored rank. Every pick says why in plain facts.

/// One ranked item and why it's there (at most two reasons; hysteresis and penalties are never shown).
public struct Pick: Identifiable {
    public var id: UUID {
        item.id
    }

    public let item: NowItem
    public let score: Int
    public let why: String
    /// An offer (Shop): only one survives in a ranking.
    public let isAsk: Bool
}

/// Where in the app something lives, for "you were just in Groceries".
public enum Area: String, Sendable {
    case tasks, training, groceries, kitchen, notes, other
}

/// The parts of a day the ranker scores against.
public enum DayPart: String, Sendable {
    case early, morning, midday, afternoon, evening, shutdown, late

    public init(hour: Int) {
        self = switch hour {
        case ..<TesseraDay.startHour: .late
        case ..<7: .early
        case 7 ..< 12: .morning
        case 12 ..< 14: .midday
        case 14 ..< 17: .afternoon
        case 17 ..< 21: .evening
        case 21 ..< 22: .shutdown
        default: .late
        }
    }
}

/// The newest thing he did, and when.
public struct LastAction: Sendable {
    public var area: Area
    public var at: Date

    public init(area: Area, at: Date) {
        self.area = area
        self.at = at
    }
}

/// What the ranker reads besides the store. Only `now` is required; the rest default to "nothing known".
public struct RankContext {
    public var now: Date
    public var calendar: Calendar
    /// The plan Home trains from, for the rest-day override.
    public var plan: ObjectRecord?
    /// The plan's rhythm when the plan object doesn't carry one.
    public var sessionsPerWeek: Int?
    /// The current Now: it keeps +15, and a challenger must beat it by more than 15.
    public var incumbent: UUID?
    public var lastAction: LastAction?
    /// Days since the last thing he did; 3 or more is re-entry.
    public var daysAway: Int
    /// Nil works it out from `TaskList.load`.
    public var dayFull: Bool?
    /// Offers declined today ("shop"); they don't come back that day.
    public var declined: Set<String>

    public init(now: Date = .now, calendar: Calendar = .current, plan: ObjectRecord? = nil,
                sessionsPerWeek: Int? = nil, incumbent: UUID? = nil, lastAction: LastAction? = nil,
                daysAway: Int = 0, dayFull: Bool? = nil, declined: Set<String> = [])
    {
        self.now = now
        self.calendar = calendar
        self.plan = plan
        self.sessionsPerWeek = sessionsPerWeek
        self.incumbent = incumbent
        self.lastAction = lastAction
        self.daysAway = daysAway
        self.dayFull = dayFull
        self.declined = declined
    }
}

@MainActor
public extension NowPicker {
    /// Weights from context-packing §5.
    enum Weight {
        static let soon = 40, dueToday = 20, carried = 10, dayPart = 15, lastAction = 15, dayFull = -10
        static let incumbent = 15, soonWindow = 90, overrideWindow = 15, reentryDays = 3
        static let shopAt = 8, workoutMinutes = 60.0, lastActionMinutes = 30.0
    }

    /// Everything that could be on Now, best first. Suspended processes never appear (they live in the ledger).
    /// Empty means the quiet line ("All quiet.").
    func rank(_ context: RankContext) -> [Pick] {
        let calendar = context.calendar, now = context.now
        let part = DayPart(hour: calendar.component(.hour, from: now))
        let running = runningItem(at: now)
        let rest = running == nil ? restDay(plan: context.plan, at: now, sessionsPerWeek: context.sessionsPerWeek,
                                            calendar: calendar) : nil
        let dayFull = context.dayFull
            ?? TaskList(store: store, classes: engine.classes).load(at: now, restDay: rest != nil, calendar: calendar)
            .isFull
        var candidates = candidates(context, part: part, includeWorkouts: rest == nil, nothingRunning: running == nil)
        candidates.removeAll { $0.item.id == running?.id }
        let scored = score(candidates, context, part: part, dayFull: dayFull)

        // 1. A running process wins.
        if let running {
            let since = running.startsAt.map { "Running since \(clock($0, calendar))" } ?? "Running"
            return [Pick(item: running, score: .max, why: since, isAsk: false)] + scored
        }
        // 2. A timed task within 15 minutes (it beats the rest line, R05), then 3. a planned rest day: the quiet
        // line, with the next routine a tap away.
        let soon = scored.first { pick in
            guard pick.item.kind == .task, let start = pick.item.startsAt else { return false }
            let minutes = start.timeIntervalSince(now) / 60
            return minutes >= 0 && minutes <= Double(Weight.overrideWindow)
        }
        let restPick = rest.map { rest in
            Pick(item: NowItem(id: rest.next.id, kind: .rest, object: rest.next, title: RestDay.line,
                               startsAt: nil, endsAt: nil, nextStep: nil),
                 score: .max, why: "\(RestDay.line). \(rest.next.title) is a tap away", isAsk: false)
        }
        if soon != nil || restPick != nil {
            let lead = [soon, restPick].compactMap(\.self)
            return lead + scored.filter { $0.id != soon?.id }
        }
        // 4. Re-entry: the smallest thing that fits now, and nothing else.
        if context.daysAway >= Weight.reentryDays,
           let small = candidates.filter({ $0.fits(part, calendar) }).min(by: { $0.minutes < $1.minutes })
        {
            return [Pick(item: small.item, score: .max, why: "Welcome back. Small on purpose", isAsk: false)]
        }
        // 5. The scored rank.
        return scored
    }

    /// The newest thing he did by hand (undone ones skipped), for `RankContext.lastAction`.
    func lastAction() -> LastAction? {
        engine.history(limit: 50).first { $0.actor == .user && $0.state != .undone }
            .map { LastAction(area: Self.area(of: $0.action), at: $0.createdAt) }
    }

    /// Whole days since the last thing he did by hand, for `RankContext.daysAway`.
    func daysAway(at now: Date, calendar: Calendar = .current) -> Int {
        guard let last = lastAction() else { return 0 }
        let day = TesseraDay(calendar: calendar)
        return calendar.dateComponents([.day], from: day.day(of: last.at), to: day.today(now)).day ?? 0
    }

    /// Which area an action belongs to: "task" is checked first, so setTaskDone is a task, not training (QA N1).
    static func area(of action: String) -> Area {
        let lower = action.lowercased()
        if lower.contains("task") {
            return .tasks
        }
        if lower.contains("note") {
            return .notes
        }
        if ["grocer", "shop", "listitem", "doneitems"].contains(where: lower.contains) {
            return .groceries
        }
        if ["cook", "kitchentimer", "recipe"].contains(where: lower.contains) {
            return .kitchen
        }
        if ["logset", "editset", "workout", "routine", "exercise", "slot", "plan", "nextset"]
            .contains(where: lower.contains)
        {
            return .training
        }
        return .other
    }
}

// MARK: - Candidates and scores

@MainActor
private extension NowPicker {
    struct Candidate {
        let item: NowItem
        let area: Area
        /// When it starts, for soon points and its day part.
        let start: Date?
        /// Soon points stop here: start plus its length (an hour for a workout).
        let soonUntil: Date?
        let dueToday: Bool
        let carriedFrom: Date?
        let minutes: Double
        let lastTouched: Date
        let isAsk: Bool
        /// The gate fact that leads an offer's why ("8 on Groceries").
        let lead: String?
        /// For offers: the day part they belong to.
        let part: DayPart?

        func fits(_ now: DayPart, _ calendar: Calendar) -> Bool {
            (part ?? start.map { DayPart(hour: calendar.component(.hour, from: $0)) }) == now
        }
    }

    func candidates(_ context: RankContext, part: DayPart, includeWorkouts: Bool,
                    nothingRunning: Bool) -> [Candidate]
    {
        let now = context.now, calendar = context.calendar
        let parked = Set(ProcessTable(engine: engine).ledger(now: now).compactMap { $0.subject?.id })
        var result: [Candidate] = []
        for item in TaskList(store: store, classes: engine.classes).today(now, calendar: calendar)
            where !item.isDone && !parked.contains(item.id)
        {
            let startsAt = item.isCarriedOver ? nil : store.value("startsAt", of: item.task)?.dateValue
            let minutes = item.minutes ?? TaskList.defaultTaskMinutes
            if let startsAt {
                // A timed task that's over leaves Now (as before); one still going stays.
                guard TesseraDay(calendar: calendar).isSameDay(startsAt, now),
                      startsAt.addingTimeInterval((item.minutes ?? 0) * 60) >= now else { continue }
            }
            let due = store.value("due", of: item.task)?.dateValue
            result.append(Candidate(
                item: NowItem(id: item.id, kind: .task, object: item.task, title: item.title, startsAt: startsAt,
                              endsAt: startsAt.map { $0.addingTimeInterval(minutes * 60) }, nextStep: nil),
                area: .tasks, start: startsAt,
                soonUntil: startsAt.map { $0.addingTimeInterval((item.minutes ?? 0) * 60) },
                dueToday: due.map { TesseraDay(calendar: calendar).isSameDay($0, now) } ?? false,
                carriedFrom: item.isCarriedOver ? item.when : nil,
                minutes: minutes, lastTouched: item.task.updatedAt, isAsk: false, lead: nil, part: nil
            ))
        }
        if includeWorkouts, let workoutClass = engine.classes[.workout] {
            for workout in store.objects(of: workoutClass) {
                // Not started (a started one is running or parked in the ledger), not finished, scheduled today.
                guard store.value("endedAt", of: workout) == nil, store.value("startedAt", of: workout) == nil,
                      let scheduled = store.value("scheduledFor", of: workout)?.dateValue,
                      TesseraDay(calendar: calendar).isSameDay(scheduled, now) else { continue }
                result.append(Candidate(
                    item: NowItem(id: workout.id, kind: .workout, object: workout,
                                  title: store.displayTitle(of: workout), startsAt: scheduled, endsAt: nil,
                                  nextStep: nil),
                    area: .training, start: scheduled,
                    soonUntil: scheduled.addingTimeInterval(Weight.workoutMinutes * 60), dueToday: false,
                    carriedFrom: nil, minutes: Weight.workoutMinutes, lastTouched: workout.updatedAt, isAsk: false,
                    lead: nil, part: nil
                ))
            }
        }
        // Shop: 8 or more on Groceries, in the evening, nothing running, not declined today.
        let groceries = Groceries(store: store, classes: engine.classes)
        let open = groceries.aisles().reduce(0) { $0 + $1.items.count }
        if nothingRunning, part == .evening, open >= Weight.shopAt, !context.declined.contains("shop"),
           let list = groceries.list
        {
            result.append(Candidate(
                item: NowItem(id: list.id, kind: .offer, object: list, title: "Shop", startsAt: nil, endsAt: nil,
                              nextStep: nil),
                area: .groceries, start: nil, soonUntil: nil, dueToday: false, carriedFrom: nil, minutes: 30,
                lastTouched: now, isAsk: true, lead: "\(open) on Groceries", part: .evening
            ))
        }
        return result
    }

    func score(_ candidates: [Candidate], _ context: RankContext, part: DayPart, dayFull: Bool) -> [Pick] {
        let now = context.now, calendar = context.calendar
        let recent = context.lastAction.flatMap {
            now.timeIntervalSince($0.at) / 60 < Weight.lastActionMinutes ? $0.area : nil
        }
        let scored = candidates.map { candidate -> (Pick, Candidate) in
            var points = 0
            var why: [String] = []
            if let lead = candidate.lead {
                why.append(lead)
            }
            if let start = candidate.start, let until = candidate.soonUntil {
                let minutes = Int(start.timeIntervalSince(now) / 60)
                if now < start, minutes <= Weight.soonWindow {
                    points += Weight.soon - minutes / 3
                    why.append("at \(clock(start, calendar))")
                } else if now >= start, now <= until {
                    points += Weight.soon
                    why.append("at \(clock(start, calendar))")
                }
            }
            if candidate.dueToday {
                points += Weight.dueToday
                why.append("due today")
            }
            if let from = candidate.carriedFrom {
                points += Weight.carried
                why.append("carried from \(weekday(from, calendar))")
            }
            if candidate.fits(part, calendar) {
                points += Weight.dayPart
                why.append("your \(part.rawValue) slot")
            }
            if let recent, recent == candidate.area {
                points += Weight.lastAction
            }
            if dayFull, candidate.start == nil, !candidate.isAsk {
                points += Weight.dayFull
            }
            if candidate.item.id == context.incumbent {
                points += Weight.incumbent
            }
            let line = why.prefix(2).joined(separator: ", ")
            return (Pick(item: candidate.item, score: points, why: line.prefix(1).uppercased() + line.dropFirst(),
                         isAsk: candidate.isAsk), candidate)
        }
        // Best first; a tie keeps the incumbent, then goes to the stalest, then A to Z.
        let sorted = scored.sorted { lhs, rhs in
            if lhs.0.score != rhs.0.score {
                return lhs.0.score > rhs.0.score
            }
            let lhsHeld = lhs.0.id == context.incumbent, rhsHeld = rhs.0.id == context.incumbent
            if lhsHeld != rhsHeld {
                return lhsHeld
            }
            if lhs.1.lastTouched != rhs.1.lastTouched {
                return lhs.1.lastTouched < rhs.1.lastTouched
            }
            return lhs.0.item.title.localizedStandardCompare(rhs.0.item.title) == .orderedAscending
        }
        var askSeen = false
        return sorted.map(\.0).filter { pick in
            guard pick.isAsk else { return true }
            defer { askSeen = true }
            return !askSeen
        }
    }

    /// "since 6:02 pm", never "18:02" (TW18).
    func clock(_ date: Date, _ calendar: Calendar) -> String {
        HouseTime.clock(date, calendar: calendar)
    }

    func weekday(_ date: Date, _ calendar: Calendar) -> String {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return symbols[(calendar.component(.weekday, from: date) - 1) % 7]
    }
}

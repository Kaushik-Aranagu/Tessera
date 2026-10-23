import Foundation

/// One pair of hands (Together, piece 2, switch `oneHands`): the day's hands-on stretches from the workout (usual
/// start and length), the cook (the plan's hands segments; its waits are free) and the routines (usual start and
/// length), and where two of them land on top of each other, with the smallest shift of the one that can move. The cook
/// plan keeps its own hands rule (`CookPlan`); this lifts the same rule across apps. Computed on the phone; a private
/// workout or recipe reads "Private workout" or "Private recipe".
public struct HandsEvent: Equatable, Sendable {
    public let app: AppID
    public let label: String
    public let start: Date
    public let end: Date
    /// The stretches that need his hands: all of a workout or routine, only the hands segments of a cook.
    public let hands: [DateInterval]
    /// Running or anchored to a serve time: it does not move.
    public let isFixed: Bool
}

public struct HandsShift: Equatable, Sendable {
    /// The app and label that moves.
    public let app: AppID
    public let label: String
    public let newStart: Date
    public let by: TimeInterval
}

public struct HandsCollision: Equatable, Sendable {
    public let a: HandsEvent
    public let b: HandsEvent
    /// Where the overlap begins.
    public let at: Date
    public let overlap: TimeInterval
    public let fix: HandsShift?
}

public extension ObjectStore {
    /// The plan Home trains from: the starter plan if it is there, else the oldest live plan (the one rule, in Core).
    func activePlan(classes: [SystemCatalog.Key: ClassDef]) -> ObjectRecord? {
        if let starter = object(id: StarterContent.planID), !starter.isDeleted {
            return starter
        }
        guard let planClass = classes[.plan] else { return nil }
        return objects(of: planClass).filter { !$0.isDeleted }.min { $0.createdAt < $1.createdAt }
    }
}

@MainActor
public extension ProcessTable {
    /// The day's hands events, in start order. A workout or routine with no usual start or length yet has none; a cook
    /// shows once a session is planned or running.
    func handsEvents(on day: Date, plan: ObjectRecord?, routines: [RoutinesLanding.Item] = [],
                     calendar: Calendar = .current) -> [HandsEvent]
    {
        let store = engine.store, classes = engine.classes
        let dayStart = TesseraDay(calendar: calendar)
        var events: [HandsEvent] = []
        // The workout: today's routine at his usual start and length.
        let stats = TrainingStats(store: store, classes: classes)
        let facts = stats.landingFacts(plan: plan, now: day, calendar: calendar)
        if let name = facts.routine, !facts.isRestDay,
           let planned = plan.flatMap({ stats.ledger.week(containing: day, plan: $0, now: day, calendar: calendar) })?
           .first(where: { $0.state == .today })?.planned,
           let start = stats.usualStart(of: planned, on: day, calendar: calendar),
           let minutes = stats.usualMinutes(of: planned)
        {
            let end = start.addingTimeInterval(Double(minutes) * 60)
            events.append(HandsEvent(app: .training, label: name, start: start, end: end,
                                     hands: [DateInterval(start: start, end: end)], isFixed: openWorkout() != nil))
        }
        // The cook: the plan's hands segments, fixed to its serve time.
        let cooks = CookSessionBook(store: store, classes: classes)
        if let session = cooks.current() {
            let plan = cooks.plan(of: session, now: day)
            let hands = plan.segs.filter { $0.kind == .hands && $0.end > $0.start }
                .map { DateInterval(start: $0.start, end: $0.end) }
            if let first = plan.placements.map(\.start).min(), let last = plan.placements.map(\.end).max(),
               dayStart.isSameDay(first, day)
            {
                let names = plan.placements.sorted { $0.dish.order < $1.dish.order }.map(\.dish.name)
                events.append(HandsEvent(app: .kitchen, label: CookPlan.names(names), start: first, end: last,
                                         hands: hands, isFixed: true))
            }
        }
        // Routines: each at its usual start and length.
        for item in routines {
            guard let counts = RoutineUsual.counts(of: item.runs, calendar: calendar) else { continue }
            let minutes = TesseraDay.startHour * 60 + counts.startMinutes
            guard let start = calendar.date(bySettingHour: minutes / 60 % 24, minute: minutes % 60, second: 0, of: day)
            else { continue }
            let end = start.addingTimeInterval(Double(counts.lengthMinutes) * 60)
            events.append(HandsEvent(app: .routines, label: item.isPrivate ? RoutinesLanding.privateRoutine : item.name,
                                     start: start, end: end, hands: [DateInterval(start: start, end: end)],
                                     isFixed: false))
        }
        return events.sorted { $0.start < $1.start }
    }

    /// Where two events need his hands at once, earliest first, each with the smallest shift of the one that can move
    /// (a fixed event never moves; of two that can, the later starter moves). A wait is never a collision.
    func collisions(on day: Date, plan: ObjectRecord?, routines: [RoutinesLanding.Item] = [],
                    calendar: Calendar = .current) -> [HandsCollision]
    {
        let events = handsEvents(on: day, plan: plan, routines: routines, calendar: calendar)
        var found: [HandsCollision] = []
        for (index, first) in events.enumerated() {
            for second in events[(index + 1)...] {
                guard let overlap = Self.firstOverlap(first.hands, second.hands) else { continue }
                let mover: HandsEvent? = first.isFixed && second.isFixed ? nil : (second.isFixed ? first : second)
                let blockers = mover.map { $0.start == first.start && $0.label == first.label ? second : first }
                let fix = mover.flatMap { moving in blockers.map { Self.shift(moving, around: $0) } }
                found.append(HandsCollision(
                    a: first,
                    b: second,
                    at: overlap.start,
                    overlap: overlap.duration,
                    fix: fix
                ))
            }
        }
        return found.sorted { $0.at < $1.at }
    }

    /// The first stretch where two sets of hands intervals overlap.
    private static func firstOverlap(_ lhs: [DateInterval], _ rhs: [DateInterval]) -> DateInterval? {
        var best: DateInterval?
        for left in lhs {
            for right in rhs {
                guard let shared = left.intersection(with: right), shared.duration > 0 else { continue }
                if best.map({ shared.start < $0.start }) ?? true {
                    best = shared
                }
            }
        }
        return best
    }

    /// The smallest later start for `moving` with its hands clear of `blocker`'s.
    private static func shift(_ moving: HandsEvent, around blocker: HandsEvent) -> HandsShift {
        var shift = 0.0
        for _ in 0 ..< 16 {
            let moved = moving.hands.map { DateInterval(start: $0.start.addingTimeInterval(shift),
                                                        end: $0.end.addingTimeInterval(shift)) }
            guard let overlap = moved.compactMap({ mine in
                blocker.hands.compactMap { mine.intersection(with: $0) }.first { $0.duration > 0 }
            }).first, let clearsAt = blocker.hands.filter({ $0.end > overlap.start }).map(\.end).min() else { break }
            let inMoved = moved.first { $0.intersection(with: overlap) != nil }
            shift += clearsAt.timeIntervalSince(inMoved?.start ?? overlap.start)
        }
        return HandsShift(app: moving.app, label: moving.label, newStart: moving.start.addingTimeInterval(shift),
                          by: shift)
    }
}

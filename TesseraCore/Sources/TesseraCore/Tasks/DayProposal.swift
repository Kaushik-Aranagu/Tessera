import Foundation

/// Plan my day, the proposal (design sheet 157): the day as ordered clauses. His calendar events are fixed and never
/// move or change; the workout, the routines and his tasks sit at their usual or planned time, pushed to the first gap
/// after an event they would land on. The sentences are the apps' own landing sentences (`HomeSentence`), nothing new.
/// It is a pure read: nothing is written to the store. Calendar data stays on the phone: this type is not used by
/// anything in TesseraTess (a test scans for it), and an event reads only by its title, "Busy" when that is private;
/// attendees, locations and notes are never read. Money gives due words only, never an amount; health, body and
/// calorie facts are never included.
///
/// Named `DayProposal` because `DayPlan` is the existing block plan the Plan wording reads.
public enum DayProposal {
    public static let maxClauses = 8
    public static let busyLabel = "Busy"

    public enum Kind: String, Sendable, Equatable {
        /// A calendar event: it does not move.
        case fixed
        /// Everything else: it may be pushed after an event.
        case proposed
    }

    public struct Clause: Equatable, Sendable {
        public let app: AppID?
        public let text: String
        /// Where it sits in the day (after any push); nil for an untimed clause, which goes last.
        public let time: Date?
        public let kind: Kind
        public let opens: HomeSentence.Opens
        /// True when it was moved to clear a calendar event.
        public let wasPushed: Bool

        public init(app: AppID?, text: String, time: Date?, kind: Kind, opens: HomeSentence.Opens,
                    wasPushed: Bool = false)
        {
            self.app = app
            self.text = text
            self.time = time
            self.kind = kind
            self.opens = opens
            self.wasPushed = wasPushed
        }
    }

    /// How long an item with no known length holds the floor when it is checked against an event.
    static let defaultMinutes = 30
    static let taskMinutes = 15
}

@MainActor
public extension DayProposal {
    /// The day, in order. Running first as "Now"; then calendar events and proposed items by time; untimed last.
    static func propose(engine: ActionEngine, plan: ObjectRecord?, routines: [RoutinesLanding.Item] = [],
                        running: RoutinesLanding.Running? = nil, moneyDue: HomeSentence.MoneyDue? = nil,
                        now: Date = .now, calendar: Calendar = .current) -> [Clause]
    {
        let store = engine.store, classes = engine.classes
        let table = ProcessTable(engine: engine)
        let hands = table.handsEvents(on: now, plan: plan, routines: routines, calendar: calendar)
        let usual = hands.first { $0.app == .routines && $0.start >= now }?.start ?? hands.first { $0.app == .routines }?
            .start
        let facts = RoutinesLanding.facts(items: routines, running: running, now: now, calendar: calendar)
        let routinesPart = routines.isEmpty && running == nil ? nil
            : HomeSentence.RoutinesPart(facts: facts, nextUsualStart: usual)
        var inputs = HomeSentence.inputs(engine: engine, plan: plan, moneyDue: moneyDue, routines: routinesPart,
                                         now: now, calendar: calendar)
        // The running process leads as Now; the app it belongs to does not say it twice.
        var lead: Clause?
        if let process = table.running() {
            let subject = process.subject ?? process.object
            let label = ObjectPrivacy.shownLabel(of: subject, in: store, classes: classes) ?? subject.title
            lead = Clause(app: nil, text: "Now: \(label).", time: now, kind: .proposed, opens: .object(subject.id))
            if let classDef = subject.classDef {
                if classes[.workout].map({ ClassResolver.isSubclass(classDef, of: $0) }) == true {
                    inputs.training = nil
                } else if classes[.cookSession].map({ ClassResolver.isSubclass(classDef, of: $0) }) == true {
                    inputs.kitchen = nil
                }
            }
        }
        let busy = busyStretches(engine: engine, now: now, calendar: calendar)
        let fixed = events(engine: engine, now: now, calendar: calendar)
        // The hands rule across the workout and the routines: the one that can move takes OneHands' smallest shift.
        var handsStart: [AppID: Date] = [:]
        for collision in table.collisions(on: now, plan: plan, routines: routines, calendar: calendar) {
            if let fix = collision.fix, fix.app == .training || fix.app == .routines {
                handsStart[fix.app] = fix.newStart
            }
        }
        var proposed: [Clause] = []
        let candidates: [(HomeSentence.Clause, minutes: Int)] = [
            inputs.training.map { ($0, minutes(of: .training, in: hands)) },
            inputs.kitchen.map { ($0, defaultMinutes) },
            inputs.routines.map { ($0, minutes(of: .routines, in: hands)) },
            inputs.money.map { ($0, defaultMinutes) },
        ].compactMap(\.self)
        for (clause, minutes) in candidates {
            // The cook is fixed to its serve time, so it keeps its place; the rest clear an event.
            let anchored = clause.app == .kitchen
            let wanted = clause.app.flatMap { handsStart[$0] } ?? clause.time
            let placed = anchored ? wanted : wanted.map { push($0, minutes: minutes, past: busy) }
            proposed.append(Clause(app: clause.app, text: clause.text, time: placed, kind: .proposed, opens: clause.opens,
                                   wasPushed: placed != clause.time && !anchored))
        }
        let cookTask = inputs.kitchen.flatMap { if case let .object(id) = $0.opens { id } else { nil } }
        let list = TaskList(store: store, classes: classes)
        let day = TesseraDay(calendar: calendar)
        for item in list.today(now, calendar: calendar) where !item.isDone {
            guard let when = item.when, day.isSameDay(when, now) else { continue }
            // A dish planned for tonight is the kitchen's clause already.
            if store.linkedObjects("about", of: item.task).contains(where: { $0.id == cookTask }) { continue }
            let label = ObjectPrivacy.shownLabel(of: item.task, in: store, classes: classes) ?? item.title
            let minutes = item.minutes.map { max(Int($0), 1) } ?? taskMinutes
            let placed = push(when, minutes: minutes, past: busy)
            proposed.append(Clause(app: nil, text: "\(label).", time: placed, kind: .proposed,
                                   opens: .object(item.task.id), wasPushed: placed != when))
        }
        let ordered = (fixed + proposed).enumerated().sorted { lhs, rhs in
            switch (lhs.element.time, rhs.element.time) {
            case let (left?, right?): left != right ? left < right : lhs.offset < rhs.offset
            case (_?, nil): true
            case (nil, _?): false
            case (nil, nil): lhs.offset < rhs.offset
            }
        }.map(\.element)
        return Array(([lead].compactMap(\.self) + ordered).prefix(maxClauses))
    }

    private static func minutes(of app: AppID, in hands: [HandsEvent]) -> Int {
        hands.first { $0.app == app }.map { max(Int($0.end.timeIntervalSince($0.start) / 60), 1) } ?? defaultMinutes
    }

    /// The first start at or after `time` whose stretch clears every busy event; an event is never moved.
    private static func push(_ time: Date, minutes: Int, past busy: [DateInterval]) -> Date {
        var start = time
        for _ in 0 ... busy.count {
            let span = DateInterval(start: start, duration: Double(minutes) * 60)
            guard let hit = busy.first(where: { $0.start < span.end && $0.end > span.start }) else { break }
            start = hit.end
        }
        return start
    }

    /// Today's busy calendar stretches, [start, end): what a proposed item must not land on.
    private static func busyStretches(engine: ActionEngine, now: Date, calendar: Calendar) -> [DateInterval] {
        eventObjects(engine: engine, now: now, calendar: calendar)
            .filter { engine.store.value("busy", of: $0.object) == .bool(true) }
            .map { DateInterval(start: $0.start, end: $0.end) }
            .sorted { $0.start < $1.start }
    }

    private static func events(engine: ActionEngine, now: Date, calendar: Calendar) -> [Clause] {
        let store = engine.store, classes = engine.classes
        return eventObjects(engine: engine, now: now, calendar: calendar).map { event in
            // Title only. A private or walled title reads "Busy"; attendees, place and notes are never read.
            let masked = ObjectPrivacy.shownLabel(of: event.object, in: store, classes: classes) != nil
                || store.value("isPrivate", of: event.object) == .bool(true) || event.object.title.isEmpty
            let label = masked ? busyLabel : event.object.title
            return Clause(app: nil, text: "\(label) at \(HouseTime.clock(event.start, calendar: calendar)).",
                          time: event.start, kind: .fixed, opens: .object(event.object.id))
        }
    }

    /// Today's timed, live calendar events that are his, by start.
    private static func eventObjects(engine: ActionEngine, now: Date, calendar: Calendar)
        -> [(object: ObjectRecord, start: Date, end: Date)]
    {
        let store = engine.store
        guard let eventClass = engine.classes[.event] else { return [] }
        let day = TesseraDay(calendar: calendar)
        let from = day.start(of: now), to = day.end(of: now)
        return store.objects(of: eventClass).compactMap { object in
            guard !object.isDeleted, store.value("allDay", of: object) != .bool(true),
                  store.value("cancelled", of: object) != .bool(true),
                  store.value("countsForMe", of: object) != .bool(false),
                  let start = store.value("start", of: object)?.dateValue,
                  let end = store.value("end", of: object)?.dateValue,
                  start >= from, start < to else { return nil }
            return (object, start, max(end, start))
        }.sorted { $0.start < $1.start }
    }
}

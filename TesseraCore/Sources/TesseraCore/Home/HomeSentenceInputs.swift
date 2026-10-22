import Foundation

/// Gathers each app's clause for Home's day sentence from what Core knows. Money and Routines have no store model in
/// Core yet, so their facts are handed in. Everything is read on the phone and masked the way the landing pages mask.
@MainActor
public extension HomeSentence {
    /// A bill that is due, by name and day: the only money Home ever says (never an amount).
    struct MoneyDue: Sendable {
        public let name: String
        public let at: Date

        public init(name: String, at: Date) {
            self.name = name
            self.at = at
        }
    }

    /// The routines' part: their landing facts and when the next one is usually started.
    struct RoutinesPart: Sendable {
        public let facts: RoutinesLanding.Facts
        public let nextUsualStart: Date?

        public init(facts: RoutinesLanding.Facts, nextUsualStart: Date? = nil) {
            self.facts = facts
            self.nextUsualStart = nextUsualStart
        }
    }

    static func inputs(engine: ActionEngine, plan: ObjectRecord?, moneyDue: MoneyDue? = nil,
                       routines: RoutinesPart? = nil, unit: MassUnit = .kilograms, now: Date = .now,
                       calendar: Calendar = .current) -> Inputs
    {
        let store = engine.store, classes = engine.classes
        var inputs = Inputs()
        // Training: "Push A today, about 45 min. Bench opens at 82.5." at his usual start of it.
        let stats = TrainingStats(store: store, classes: classes)
        let facts = stats.landingFacts(plan: plan, now: now, calendar: calendar)
        if let routine = facts.routine, !facts.isRestDay {
            let opener = facts.opener.map { (
                exercise: $0.exercise,
                weight: StatsMass.number(kg: $0.weightKg, unit: unit)
            ) }
            let sentence = TrainingSentences.today(routine: routine, minutes: facts.minutes, opener: opener)
            let planned = plan.flatMap { stats.ledger.week(containing: now, plan: $0, now: now, calendar: calendar) }?
                .first { $0.state == .today }?.planned
            let start = facts.isPrivate ? nil : planned
                .flatMap { stats.usualStart(of: $0, on: now, calendar: calendar) }
            inputs.training = Clause(app: .training, sentence: sentence,
                                     opens: planned.map { .object($0.id) } ?? .app(.training), time: start)
        }
        inputs.kitchen = kitchenClause(store: store, classes: classes, now: now, calendar: calendar)
        if let moneyDue {
            let name = ObjectPrivacy.isPrivateWord(moneyDue.name, in: store) ? "Private bill" : moneyDue.name
            let sentence = LandingSentences.money(
                nothingLate: false,
                due: (name, TesseraDay.weekdayName(of: moneyDue.at, calendar: calendar)), trend: nil
            )
            inputs.money = Clause(app: .money, sentence: sentence, opens: .app(.money),
                                  time: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: moneyDue.at))
        }
        let notes = NotesLanding(store: store, classes: classes)
        if let line = notes.facts(.init(now: now, calendar: calendar)).margin.first {
            inputs.notes = Clause(app: .notes, sentence: line.sentence, opens: .app(.notes),
                                  since: notes.notes().map(\.createdAt).max())
        }
        let lists = ListsLanding(engine: engine).facts(.init(now: now, calendar: calendar))
        if let lead = lists.lead, !lead.sentence.text.hasSuffix("touched last.") {
            inputs.lists = Clause(app: .lists, sentence: lead.sentence, opens: .object(lead.list), since: now)
        }
        if let routines {
            let top = routines.facts.top.sentence
            let isLive = routines.facts.top.step != nil
            let line = isLive ? top : routines.facts.lines.first.map { LandingSentence(text: $0 + ".", key: nil) }
            if let line {
                inputs.routines = Clause(app: .routines, sentence: line, opens: .app(.routines),
                                         time: isLive ? now : routines.nextUsualStart)
            }
        }
        return inputs
    }

    /// Kitchen: a planned or running multi-dish cook says its own landing line; else a dish planned for today (a task
    /// about a recipe, dated today) says "Tacos tonight, start at 6:05 pm." A private recipe reads "Private recipe".
    private static func kitchenClause(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date,
                                      calendar: Calendar) -> Clause?
    {
        let book = CookSessionBook(store: store, classes: classes)
        if let session = book.current() {
            let plan = book.plan(of: session, now: now)
            guard let start = plan.placements.map(\.start).min() else { return nil }
            return Clause(app: .kitchen, sentence: LandingSentence(text: plan.landing(calendar: calendar), key: nil),
                          opens: .object(session.id), time: start)
        }
        guard let taskClass = classes[.task] else { return nil }
        let day = TesseraDay(calendar: calendar)
        let dated = store.objects(of: taskClass).compactMap { task -> (ObjectRecord, ObjectRecord, Date)? in
            guard !task.isDeleted, store.value("isDone", of: task) != .bool(true),
                  let when = store.value("startsAt", of: task)?.dateValue, day.isSameDay(when, now),
                  let recipe = store.linkedObjects("about", of: task).first(where: {
                      $0.classDef?.id == classes[.recipe]?.id
                  }) else { return nil }
            return (task, recipe, when)
        }
        guard let next = dated.min(by: { $0.2 < $1.2 }) else { return nil }
        let name = ObjectPrivacy.shownLabel(of: next.1, in: store, classes: classes) ?? next.1.title
        let sentence = LandingSentences.kitchen(dish: name, start: HouseTime.clock(next.2, calendar: calendar),
                                                shortOf: nil)
        return Clause(app: .kitchen, sentence: sentence, opens: .object(next.1.id), time: next.2)
    }
}

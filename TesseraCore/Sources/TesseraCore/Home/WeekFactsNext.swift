import Foundation

/// Next-week facts (design sheet 159, the Sunday reset), beside the this-week lens above: one forward-looking sentence
/// per app about the week ahead, only for
/// apps with something to say. Each sentence reuses the app's own words where it has them. Never a score, a comparison
/// with this week, or a word about what was not done; money gives a name and a weekday and never an amount or a
/// balance; a private workout, recipe, list, routine or bill reads its label. Computed on the phone; none of it goes to
/// a model (a test keeps this type out of `TesseraTess`).
@MainActor
public extension WeekFacts {
    struct NextLine: Equatable, Sendable {
        public let app: AppID
        public let text: String
        public let opens: HomeSentence.Opens

        public init(app: AppID, text: String, opens: HomeSentence.Opens) {
            self.app = app
            self.text = text
            self.opens = opens
        }
    }

    static let privateBill = "Private bill"
    static let maxNames = 3

    /// Next week, Monday 04:00 to the Monday after (his days run 04:00 to 04:00).
    static func nextWeek(after now: Date, calendar: Calendar = .current) -> DateInterval {
        let day = TesseraDay(calendar: calendar)
        return day.week(containing: day.week(containing: now).end)
    }

    /// The lines in app order. `bills` is the bill list as (name, due date), handed in because Core has no bills model.
    static func next(engine: ActionEngine, plan: ObjectRecord?, routines: [RoutinesLanding.Item] = [],
                     bills: [HomeSentence.MoneyDue] = [], now: Date = .now,
                     calendar: Calendar = .current) -> [NextLine]
    {
        let week = nextWeek(after: now, calendar: calendar)
        return [
            training(engine: engine, plan: plan, week: week, now: now, calendar: calendar),
            kitchen(engine: engine, week: week),
            money(engine: engine, bills: bills, week: week, calendar: calendar),
            notes(engine: engine, now: now, calendar: calendar),
            lists(engine: engine, week: week, now: now, calendar: calendar),
            self.routines(routines, now: now, calendar: calendar),
        ].compactMap(\.self)
    }

    // MARK: Training

    /// "Push A, Pull A and Legs next week." The plan's rolling order over next week's days; rest days say nothing.
    private static func training(engine: ActionEngine, plan: ObjectRecord?, week: DateInterval, now: Date,
                                 calendar: Calendar) -> NextLine?
    {
        guard let plan else { return nil }
        let store = engine.store, classes = engine.classes
        let days = TrainingStats(store: store, classes: classes).ledger
            .week(containing: week.start, plan: plan, now: now, calendar: calendar)
        var seen = Set<UUID>()
        var routines: [ObjectRecord] = []
        for day in days where !day.isRest {
            if let planned = day.planned, seen.insert(planned.id).inserted {
                routines.append(planned)
            }
        }
        guard !routines.isEmpty else { return nil }
        let names = routines.map { routine in
            ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) != nil
                ? ObjectPrivacy.routineLabel : routine.title
        }
        return NextLine(app: .training, text: "\(CookPlan.names(names)) next week.",
                        opens: routines.count == 1 ? .object(routines[0].id) : .app(.training))
    }

    // MARK: Kitchen

    /// "Tacos and chili are planned, 5 to get." Dishes are tasks about a recipe dated next week; the shopping is only
    /// the count on Groceries.
    private static func kitchen(engine: ActionEngine, week: DateInterval) -> NextLine? {
        let store = engine.store, classes = engine.classes
        guard let taskClass = classes[.task] else { return nil }
        let dated = store.objects(of: taskClass).compactMap { task -> (recipe: ObjectRecord, at: Date)? in
            guard !task.isDeleted, store.value("isDone", of: task) != .bool(true),
                  let when = store.value("startsAt", of: task)?.dateValue, week.start <= when, when < week.end,
                  let recipe = store.linkedObjects("about", of: task).first(where: {
                      $0.classDef?.id == classes[.recipe]?.id
                  }) else { return nil }
            return (recipe, when)
        }.sorted { $0.at < $1.at }
        var seen = Set<UUID>()
        var dishes: [ObjectRecord] = []
        for entry in dated where seen.insert(entry.recipe.id).inserted {
            dishes.append(entry.recipe)
        }
        guard !dishes.isEmpty else { return nil }
        let names = dishes.map { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) ?? $0.title }
        var text = "\(CookPlan.names(names)) \(dishes.count == 1 ? "is" : "are") planned"
        let toGet = KitchenLanding(store: store, classes: classes).toGetCount()
        if toGet > 0 {
            text += ", \(toGet) to get"
        }
        return NextLine(
            app: .kitchen,
            text: text + ".",
            opens: dishes.count == 1 ? .object(dishes[0].id) : .app(.kitchen)
        )
    }

    // MARK: Money

    /// "Rent is due Friday." / "Rent is due Friday, Phone Sunday." Names and weekdays, never an amount. A name that
    /// carries a digit or a currency sign could be an amount, so it reads "Private bill".
    private static func money(engine: ActionEngine, bills: [HomeSentence.MoneyDue], week: DateInterval,
                              calendar: Calendar) -> NextLine?
    {
        let due = bills.filter { week.start <= $0.at && $0.at < week.end }.sorted { $0.at < $1.at }
        guard !due.isEmpty else { return nil }
        let store = engine.store
        let shown = due.map { bill -> (name: String, weekday: String) in
            let risky = bill.name.contains { $0.isNumber || $0.isCurrencySymbol }
            let name = risky || ObjectPrivacy.isPrivateWord(bill.name, in: store) ? privateBill : bill.name
            return (
                name,
                TesseraDay.weekdayName(of: TesseraDay(calendar: calendar).day(of: bill.at), calendar: calendar)
            )
        }
        return NextLine(app: .money, text: dueText(shown), opens: .app(.money))
    }

    // MARK: Notes

    /// The first waiting margin line of the Notes landing, else nothing.
    private static func notes(engine: ActionEngine, now: Date, calendar: Calendar) -> NextLine? {
        let landing = NotesLanding(store: engine.store, classes: engine.classes)
        guard let line = landing.facts(.init(now: now, calendar: calendar)).margin.first(where: { $0.kind == .waiting })
        else { return nil }
        return NextLine(app: .notes, text: line.sentence.text, opens: .app(.notes))
    }

    // MARK: Lists

    /// "Packing is due Fri." Lists with an open item due next week, soonest first; else a list that is running.
    private static func lists(engine: ActionEngine, week: DateInterval, now _: Date, calendar: Calendar) -> NextLine? {
        let landing = ListsLanding(engine: engine)
        let rows = landing.rows()
        let due = rows.compactMap { row -> (row: ListsLanding.Row, at: Date)? in
            let dates = row.items.filter { !$0.isDone }.compactMap(landing.dueDate)
                .filter { week.start <= $0 && $0 < week.end }
            return dates.min().map { (row, $0) }
        }.sorted { $0.at < $1.at }
        if !due.isEmpty {
            let shown = due.map { (name: $0.row.name, weekday: shortDay($0.at, calendar)) }
            return NextLine(app: .lists, text: dueText(shown),
                            opens: due.count == 1 ? .object(due[0].row.list.id) : .app(.lists))
        }
        let running = landing.runningLists()
        guard let started = rows.filter({ running[$0.list.id] != nil })
            .max(by: { (running[$0.list.id] ?? .distantPast) < (running[$1.list.id] ?? .distantPast) })
        else { return nil }
        return NextLine(app: .lists, text: LandingSentences.listRunning(started.name, left: started.left).text,
                        opens: .object(started.list.id))
    }

    // MARK: Routines

    /// "Morning runs daily." / "Morning runs about 3 days a week." Only routines with a usual start (seven runs), by
    /// plain counts of the days they ran in the last four weeks. No streaks, nothing that can fall.
    private static func routines(_ items: [RoutinesLanding.Item], now: Date, calendar: Calendar) -> NextLine? {
        let day = TesseraDay(calendar: calendar)
        let recent: Date = day.adding(days: -28, to: day.start(of: now))
        var best: (name: String, perWeek: Int)?
        for item in items where !item.isWorkout {
            guard RoutineUsual.counts(of: item.runs, calendar: calendar) != nil else { continue }
            var days = Set<Date>()
            for run in item.runs where run.start >= recent && run.end > run.start {
                days.insert(day.day(of: run.start))
            }
            let perWeek = Int((Double(days.count) / 4.0).rounded())
            let name = item.isPrivate ? RoutinesLanding.privateRoutine : item.name
            if perWeek > 0, best == nil || perWeek > best!.perWeek || (perWeek == best!.perWeek && name < best!.name) {
                best = (name, perWeek)
            }
        }
        guard let best else { return nil }
        let unit = best.perWeek == 1 ? "day" : "days"
        let text = best.perWeek >= 7 ? "\(best.name) runs daily." : "\(best.name) runs about \(best.perWeek) \(unit) a week."
        return NextLine(app: .routines, text: text, opens: .app(.routines))
    }

    // MARK: Words

    private static func shortDay(_ date: Date, _ calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE"
        return formatter.string(from: TesseraDay(calendar: calendar).day(of: date))
    }

    /// "Rent is due Friday." / "Rent is due Friday, Phone Sunday and Gym Monday." (at most three, then "and more").
    private static func dueText(_ items: [(name: String, weekday: String)]) -> String {
        guard let first = items.first else { return "" }
        let more = items.count > maxNames
        let rest = items.dropFirst().prefix(maxNames - 1).map { "\($0.name) \($0.weekday)" }
        var text = "\(first.name) is due \(first.weekday)"
        if !rest.isEmpty {
            let parts = more ? rest : Array(rest)
            text += more ? ", " + parts.joined(separator: ", ") + " and more"
                : (parts.count == 1 ? " and \(parts[0])" : ", " + parts.dropLast().joined(separator: ", ")
                    + " and \(parts[parts.count - 1])")
        }
        return text + "."
    }
}

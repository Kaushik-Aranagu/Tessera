import Foundation

/// A birthday Home may say. Local only: it comes from the phone (Contacts later, never a service), is never stored by
/// Core, and appears in no backup, log, widget or Claude line (a test scans for the type). The host must never fill
/// these from the Calendar app's birthday calendar: calendar text stays out of everything but the Today screen.
public struct OneThingBirthday: Sendable {
    public let name: String
    public let month: Int
    public let day: Int
    /// The year born, when known, for "turns 60".
    public let year: Int?
    /// His own short line about it, shown as the small tier when it is plain.
    public let note: String?

    public init(name: String, month: Int, day: Int, year: Int? = nil, note: String? = nil) {
        self.name = name
        self.month = month
        self.day = day
        self.year = year
        self.note = note
    }
}

/// The weather for the one-thing space, as the host reads it (a sample until Apple weather is entitled).
public struct OneThingWeather: Sendable {
    public let degrees: Int
    public let summary: String
    public let isSample: Bool

    public init(degrees: Int, summary: String, isSample: Bool = true) {
        self.degrees = degrees
        self.summary = summary
        self.isSample = isSample
    }
}

/// What finishing a thing does, where one applies: only a task can be struck through.
public enum OneThingDone: Equatable, Sendable {
    case task(UUID)
}

/// One thing for Home's one-thing space (sheet 213): three tiers of words, a kind, an accent and, for a task, a done
/// action. Ranked on the phone, at most seven. No card: these are only strings and an accent. Private things read their
/// shown label; no money, health, body or calories; calendar text is not a source.
public struct OneThing: Equatable, Sendable, Identifiable {
    public enum Kind: String, CaseIterable, Sendable {
        case training, groceries, birthday, task, list, weather, routine
    }

    public enum Target: Equatable, Sendable {
        case room(AppID)
        case object(UUID)
        case today
        case weather
    }

    public enum Accent: Equatable, Sendable {
        case app(AppID)
        /// Ink: a task.
        case ink
        /// The rose family, never cobalt.
        case birthday
        /// The sky gradient: the weather.
        case sky
    }

    public let id: String
    public let kind: Kind
    /// Outfit 66 pt for a number or time, Figtree 36 pt for a word.
    public let big: String
    public let mid: String
    /// The app word inside `mid`, highlighted; nil for a plain or private one.
    public let midKeyword: String?
    public let small: String
    public let accent: Accent
    public let done: OneThingDone?
    public let isPrivate: Bool
    /// Where a tap goes: an app's room, one object, Today or the weather page.
    public let target: Target
    /// Lower is more important: minutes until it matters.
    let urgency: Int

    /// "Pack the charger, done." or "Private, done." for the one Undo line.
    public var undoLine: String? {
        done == nil ? nil : "\(isPrivate ? "Private" : big), done."
    }
}

@MainActor
public enum OneThings {
    public static let limit = 7

    /// The things for the space, most important first.
    public static func ranked(engine: ActionEngine, facts: MosaicFacts, plan: ObjectRecord?,
                              routines: HomeSentence.RoutinesPart? = nil, birthdays: [OneThingBirthday] = [],
                              weather: OneThingWeather? = nil, unit: MassUnit = .kilograms,
                              calendar: Calendar = .current, limit: Int = OneThings.limit) -> [OneThing]
    {
        let now = facts.now
        var things: [OneThing] = []
        things += [training(engine, plan, now, unit, calendar), groceries(engine, now, calendar),
                   task(engine, now, calendar), list(engine, now, calendar),
                   routine(engine, routines, now, calendar)].compactMap(\.self)
        things += birthdays.compactMap { birthday($0, engine: engine, now: now, calendar: calendar) }
        if let weather {
            things.append(Self.weather(weather, facts: facts, calendar: calendar))
        }
        let kinds = OneThing.Kind.allCases
        let sorted = things.sorted { lhs, rhs in
            lhs.urgency != rhs.urgency ? lhs.urgency < rhs.urgency
                : (kinds.firstIndex(of: lhs.kind) ?? 0) < (kinds.firstIndex(of: rhs.kind) ?? 0)
        }
        return Array(sorted.prefix(max(0, min(limit, Self.limit))))
    }

    // MARK: Words

    /// "2:10": hours and minutes to a time.
    static func clockGap(from now: Date, to later: Date) -> String {
        let minutes = max(0, Int(later.timeIntervalSince(now) / 60))
        return "\(minutes / 60):\(String(format: "%02d", minutes % 60))"
    }

    private static let numbers = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                                  "eleven", "twelve"]
    private static let ordinals = ["", "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"]

    static func word(_ number: Int) -> String {
        numbers.indices.contains(number) ? numbers[number] : "\(number)"
    }

    /// "today", "yesterday", "three days ago", "three weeks ago", "two months ago".
    static func ago(days: Int) -> String {
        switch days {
        case ..<1: "today"
        case 1: "yesterday"
        case 2 ... 13: "\(word(days)) days ago"
        case 14 ..< 60: "\(word(days / 7)) weeks ago"
        default: "\(word(min(days / 30, 12))) months ago"
        }
    }

    // MARK: Things

    private static func training(_ engine: ActionEngine, _ plan: ObjectRecord?, _ now: Date, _ unit: MassUnit,
                                 _ calendar: Calendar) -> OneThing?
    {
        let store = engine.store, classes = engine.classes
        let stats = TrainingStats(store: store, classes: classes)
        let facts = stats.landingFacts(plan: plan, now: now, calendar: calendar)
        guard let routine = facts.routine, !facts.isRestDay else { return nil }
        let planned = plan.flatMap { stats.ledger.week(containing: now, plan: $0, now: now, calendar: calendar) }?
            .first { $0.state == .today }?.planned
        let start = planned.flatMap { stats.usualStart(of: $0, on: now, calendar: calendar) }
        let name = facts.isPrivate ? ("Private", true) : AppSummaryLines.shown(routine, in: store, classes: classes)
        // The lift it opens with, and his best at it, for a plain routine only.
        var mid = name.0
        var small = ""
        if !name.1, let opener = facts.opener {
            let lift = AppSummaryLines.shown(opener.exercise, in: store, classes: classes)
            if !lift.isPrivate {
                mid += ", \(lift.text.lowercased()) first"
                if let exercise = store.allClasses().first(where: { $0.name == opener.exercise }),
                   let best = bestLine(
                       exercise,
                       name: lift.text,
                       stats: stats,
                       now: now,
                       unit: unit,
                       calendar: calendar
                   )
                {
                    small = best
                }
            }
        }
        let gap = start.map { Int(max(0, $0.timeIntervalSince(now)) / 60) } ?? 600
        return OneThing(
            id: "training",
            kind: .training,
            big: name.1 ? "Today" : (start.map { clockGap(from: now, to: $0) } ?? "Today"),
            mid: mid,
            midKeyword: name.1 ? nil : name.0,
            small: small,
            accent: .app(.training),
            done: nil,
            isPrivate: name.1,
            target: planned.map { .object($0.id) } ?? .room(.training),
            urgency: gap
        )
    }

    /// "Bench best 205 lb, three weeks ago": his heaviest estimated set and when it was.
    private static func bestLine(_ exercise: ClassDef, name: String, stats: TrainingStats, now: Date, unit: MassUnit,
                                 calendar: Calendar) -> String?
    {
        var best: (weight: Double, e1RM: Double, date: Date)?
        for session in stats.ledger.sessions(of: exercise) {
            for set in session.sets where set.isE1RMEligible && set.e1RM > (best?.e1RM ?? 0) {
                best = (set.weight, set.e1RM, session.date)
            }
        }
        guard let best else { return nil }
        let days = TesseraDay(calendar: calendar).calendar.dateComponents(
            [.day], from: TesseraDay(calendar: calendar).day(of: best.date),
            to: TesseraDay(calendar: calendar).day(of: now)
        ).day ?? 0
        let first = name.split(separator: " ").first.map(String.init) ?? name
        return "\(first) best \(unit.text(kilograms: best.weight)) \(unit.symbol), \(ago(days: days))"
    }

    private static func groceries(_ engine: ActionEngine, _ now: Date, _ calendar: Calendar) -> OneThing? {
        let store = engine.store, classes = engine.classes
        let groceries = Groceries(store: store, classes: classes)
        let open = groceries.shoppingOrder()
        guard !open.isEmpty else { return nil }
        let names = open.prefix(4).map { AppSummaryLines.shown($0.text, in: store, classes: classes).text == "Private"
            ? "Private item" : $0.text
        }
        // "For tacos tonight": a dish planned for today that these are for.
        var small = "From the groceries list"
        var gap = 600
        if let taskClass = classes[.task], let recipeClass = classes[.recipe] {
            let day = TesseraDay(calendar: calendar)
            let dated = store.objects(of: taskClass).compactMap { task -> (ObjectRecord, Date)? in
                guard !task.isDeleted, store.value("isDone", of: task) != .bool(true),
                      let when = store.value("startsAt", of: task)?.dateValue, day.isSameDay(when, now),
                      let recipe = store.linkedObjects("about", of: task).first(where: {
                          $0.classDef?.id == recipeClass.id
                      }) else { return nil }
                return (recipe, when)
            }
            if let next = dated.min(by: { $0.1 < $1.1 }) {
                let dish = AppSummaryLines.shown(next.0.title, in: store, classes: classes, of: next.0)
                let when = calendar.component(.hour, from: next.1) >= 16 ? "tonight" : "today"
                small = dish.1 ? "For a dish \(when)" : "For \(dish.text.lowercased()) \(when)"
                gap = max(0, Int(next.1.timeIntervalSince(now) / 60))
            }
        }
        return OneThing(
            id: "groceries",
            kind: .groceries,
            big: "\(open.count)",
            mid: "to get: " + names.joined(separator: ", "),
            midKeyword: "to get",
            small: small,
            accent: .app(.kitchen),
            done: nil,
            isPrivate: false,
            target: .room(.kitchen),
            urgency: gap
        )
    }

    private static func task(_ engine: ActionEngine, _ now: Date, _ calendar: Calendar) -> OneThing? {
        let store = engine.store, classes = engine.classes
        guard let taskClass = classes[.task] else { return nil }
        let day = TesseraDay(calendar: calendar)
        let candidates = store.objects(of: taskClass).compactMap { task -> (ObjectRecord, Date)? in
            guard !task.isDeleted, store.value("isDone", of: task) != .bool(true) else { return nil }
            // A task about a recipe is a cook, which is not this thing.
            if store.linkedObjects("about", of: task).contains(where: { $0.classDef?.id == classes[.recipe]?.id }) {
                return nil
            }
            let when = store.value("startsAt", of: task)?.dateValue ?? store.value("due", of: task)?.dateValue
            guard let when, day.isSameDay(when, now) || when < now else { return nil }
            return (task, when)
        }
        guard let top = candidates.min(by: { $0.1 < $1.1 }) else { return nil }
        let name = AppSummaryLines.shown(top.0.title, in: store, classes: classes, of: top.0)
        let weekday = TesseraDay.weekdayName(of: top.1, calendar: calendar)
        let mid = day.isSameDay(top.1, now) ? "Today at \(HouseTime.clock(top.1, calendar: calendar))"
            : "Since \(weekday)"
        return OneThing(id: "task-\(top.0.id)", kind: .task, big: name.text, mid: mid, midKeyword: nil,
                        small: "Hold to strike it through", accent: .ink, done: .task(top.0.id), isPrivate: name.1,
                        target: .object(top.0.id), urgency: max(0, Int(top.1.timeIntervalSince(now) / 60)))
    }

    private static func list(_ engine: ActionEngine, _ now: Date, _ calendar: Calendar) -> OneThing? {
        let facts = ListsLanding(engine: engine).facts(.init(now: now, calendar: calendar))
        guard let lead = facts.lead, lead.total > 0 else { return nil }
        let name = AppSummaryLines.shown(lead.name, in: engine.store, classes: engine.classes)
        let items = lead.nextItems.map { AppSummaryLines.shown($0, in: engine.store, classes: engine.classes).isPrivate
            ? "a private item" : $0
        }
        return OneThing(id: "list-\(lead.list)", kind: .list, big: "\(lead.total - lead.left) of \(lead.total)",
                        mid: name.text, midKeyword: name.1 ? nil : name.text,
                        small: name.1 || items.isEmpty ? "" : "Next up: " + items.prefix(3).joined(separator: ", "),
                        accent: .app(.lists), done: nil, isPrivate: name.1, target: .object(lead.list), urgency: 700)
    }

    private static func routine(_ engine: ActionEngine, _ part: HomeSentence.RoutinesPart?, _ now: Date,
                                _ calendar: Calendar) -> OneThing?
    {
        // The name and the time come from the same routine; with only a time handed in, the first line's name.
        guard let part, let next = part.nextUsualStart,
              let first = part.nextRoutine ?? part.facts.lines.first else { return nil }
        let name = AppSummaryLines.shown(
            part.nextRoutine ?? first.split(separator: ",").first.map(String.init) ?? first,
            in: engine.store,
            classes: engine.classes
        )
        let gap = Int(max(0, next.timeIntervalSince(now)) / 60)
        return OneThing(id: "routine", kind: .routine, big: HouseTime.clock(next, calendar: calendar),
                        mid: name.text, midKeyword: name.1 ? nil : name.text, small: "", accent: .app(.routines),
                        done: nil, isPrivate: name.1, target: .room(.routines), urgency: gap)
    }

    private static func birthday(_ birthday: OneThingBirthday, engine: ActionEngine, now: Date,
                                 calendar: Calendar) -> OneThing?
    {
        let today = TesseraDay(calendar: calendar).day(of: now)
        let year = calendar.component(.year, from: today)
        guard let this = calendar.date(from: DateComponents(year: year, month: birthday.month, day: birthday.day)),
              let date = this >= today ? this : calendar.date(from: DateComponents(
                  year: year + 1,
                  month: birthday.month,
                  day: birthday.day
              )),
              let days = calendar.dateComponents([.day], from: today, to: date).day, days <= 14 else { return nil }
        let name = AppSummaryLines.shown(birthday.name, in: engine.store, classes: engine.classes)
        if name.1 {
            return nil
        }
        let big = days == 0 ? "Today" : days == 1 ? "Tomorrow" : TesseraDay.weekdayName(of: date, calendar: calendar)
        let age = birthday.year.map { calendar.component(.year, from: date) - $0 }
        let mid = age.map { "\(name.text) turns \($0)" } ?? "\(name.text)'s birthday"
        let note = birthday.note
            .flatMap { AppSummaryLines.shown($0, in: engine.store, classes: engine.classes).isPrivate
                ? nil : $0
            }
        let small = note ?? (days == 0 ? "Today." : days == 1 ? "One day." : "\(word(days).capitalized) days.")
        return OneThing(
            id: "birthday-\(birthday.month)-\(birthday.day)-\(MosaicMomentSource.hashed(birthday.name))",
            kind: .birthday,
            big: big,
            mid: mid,
            midKeyword: name.text,
            small: small,
            accent: .birthday,
            done: nil,
            isPrivate: false,
            target: .today,
            urgency: days * 1440
        )
    }

    private static func weather(_ weather: OneThingWeather, facts: MosaicFacts, calendar: Calendar) -> OneThing {
        let sun = if facts.now < facts.sunrise {
            "Sunrise at \(HouseTime.clock(facts.sunrise, calendar: calendar))"
        } else if facts.now < facts.sunset {
            "Sunset at \(HouseTime.clock(facts.sunset, calendar: calendar))"
        } else {
            "Sunset was at \(HouseTime.clock(facts.sunset, calendar: calendar))"
        }
        return OneThing(id: "weather", kind: .weather, big: "\(weather.degrees)°", mid: weather.summary,
                        midKeyword: nil, small: weather.isSample ? "\(sun). A sample until Apple weather" : sun,
                        accent: .sky, done: nil, isPrivate: false, target: .weather, urgency: 5000)
    }
}

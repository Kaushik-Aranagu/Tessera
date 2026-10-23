import Foundation

/// The apps in Home's apps list (sheet 205). Tasks is an app here though it has no AppID of its own.
public enum AppSummaryApp: String, CaseIterable, Sendable {
    case training, kitchen, routines, tasks, notes, lists, money
}

/// One plain line of fact for an app, for the apps list: "Push A at 6:15 pm, bench first", "Tacos tonight, 4 to get",
/// "Stretch at 8 pm", "3 left today", "Trip packing, edited at noon", "Packing, 6 of 14 done", "Rent is due Friday".
/// Computed on the phone, no model. Money is words only, never an amount; health, body and calories never appear; a
/// private or walled top item reads "Private" in place of its title, and then nothing else about it.
public struct AppSummaryLine: Equatable, Sendable {
    public let app: AppSummaryApp
    public let text: String
    public let opens: HomeSentence.Opens
    /// The top item was private or walled, so the line shows no title.
    public let isPrivate: Bool
}

@MainActor
public enum AppSummaryLines {
    public static let nothingPlanned = "Nothing planned"

    /// One line per app, in the fixed order of `AppSummaryApp.allCases` (the view orders them by his Settings).
    public static func lines(engine: ActionEngine, plan: ObjectRecord?, moneyDue: HomeSentence.MoneyDue? = nil,
                             routines: HomeSentence.RoutinesPart? = nil, now: Date = .now,
                             calendar: Calendar = .current) -> [AppSummaryLine]
    {
        [
            training(engine, plan, now, calendar), kitchen(engine, now, calendar),
            routinesLine(engine, routines, now, calendar), tasks(engine, now, calendar), notes(engine, now, calendar),
            lists(engine, now, calendar), money(engine, moneyDue, calendar),
        ]
    }

    // MARK: Words

    /// A title as the list shows it: "Private" for anything private, walled or secret.
    static func shown(_ title: String, in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef],
                      of object: ObjectRecord? = nil) -> (text: String, isPrivate: Bool)
    {
        let masked = object.map { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) != nil } ?? false
        let hidden = masked || ObjectPrivacy.containsPrivateWord(title, in: store) || SecretWords.mentions(title)
            || PrivateFacts.isWalled(title, lastWeightKg: BodyWeight.lastKg(in: store))
            || PrivateFacts.isCalorieShaped(title) || title.hasPrefix("Private ")
        return hidden ? ("Private", true) : (title, false)
    }

    // MARK: Apps

    private static func training(_ engine: ActionEngine, _ plan: ObjectRecord?, _ now: Date, _ calendar: Calendar)
        -> AppSummaryLine
    {
        let store = engine.store, classes = engine.classes
        let stats = TrainingStats(store: store, classes: classes)
        let facts = stats.landingFacts(plan: plan, now: now, calendar: calendar)
        guard let routine = facts.routine else {
            return AppSummaryLine(app: .training, text: nothingPlanned, opens: .app(.training), isPrivate: false)
        }
        if facts.isRestDay {
            return AppSummaryLine(app: .training, text: "Rest day", opens: .app(.training), isPrivate: false)
        }
        let name = facts.isPrivate ? ("Private", true) : shown(routine, in: store, classes: classes)
        let planned = plan.flatMap { stats.ledger.week(containing: now, plan: $0, now: now, calendar: calendar) }?
            .first { $0.state == .today }?.planned
        var text = name.0
        if !name.1, let planned, let start = stats.usualStart(of: planned, on: now, calendar: calendar) {
            text += " at \(HouseTime.clock(start, calendar: calendar))"
        }
        // The lift it opens with only for a plain routine; a private one shows nothing but "Private".
        if !name.1, let opener = facts.opener {
            let lift = shown(opener.exercise, in: store, classes: classes)
            if !lift.isPrivate {
                text += ", \(lift.text.lowercased()) first"
            }
        }
        return AppSummaryLine(app: .training, text: text, opens: planned.map { .object($0.id) } ?? .app(.training),
                              isPrivate: name.1)
    }

    private static func kitchen(_ engine: ActionEngine, _ now: Date, _ calendar: Calendar) -> AppSummaryLine {
        let store = engine.store, classes = engine.classes
        let groceries = Groceries(store: store, classes: classes)
        let day = TesseraDay(calendar: calendar)
        if let taskClass = classes[.task], let recipeClass = classes[.recipe] {
            let dated = store.objects(of: taskClass).compactMap { task -> (ObjectRecord, ObjectRecord, Date)? in
                guard !task.isDeleted, store.value("isDone", of: task) != .bool(true),
                      let when = store.value("startsAt", of: task)?.dateValue, day.isSameDay(when, now),
                      let recipe = store.linkedObjects("about", of: task).first(where: {
                          $0.classDef?.id == recipeClass.id
                      }) else { return nil }
                return (task, recipe, when)
            }
            if let next = dated.min(by: { $0.2 < $1.2 }) {
                let name = shown(next.1.title, in: store, classes: classes, of: next.1)
                let toGet = groceries.toBuy(for: next.1.id)
                let when = calendar.component(.hour, from: next.2) >= 16 ? "tonight" : "today"
                let tail = toGet > 0 ? ", \(toGet) to get" : ""
                let words = name.1 ? name.text : "\(name.text) \(when)"
                return AppSummaryLine(app: .kitchen, text: words + tail,
                                      opens: .object(next.1.id), isPrivate: name.1)
            }
        }
        let open = groceries.shoppingOrder().count
        return AppSummaryLine(app: .kitchen, text: open > 0 ? "\(open) to get" : nothingPlanned,
                              opens: .app(.kitchen), isPrivate: false)
    }

    private static func routinesLine(_: ActionEngine, _ part: HomeSentence.RoutinesPart?, _: Date,
                                     _ calendar: Calendar) -> AppSummaryLine
    {
        guard let part else {
            return AppSummaryLine(app: .routines, text: nothingPlanned, opens: .app(.routines), isPrivate: false)
        }
        if part.facts.top.step != nil {
            // Running: its own words, already masked ("Morning is running").
            return AppSummaryLine(app: .routines, text: part.facts.top.sentence.text, opens: .app(.routines),
                                  isPrivate: part.facts.top.sentence.text.contains("Private"))
        }
        guard let line = part.facts.lines.first else {
            return AppSummaryLine(app: .routines, text: nothingPlanned, opens: .app(.routines), isPrivate: false)
        }
        let name = line.split(separator: ",").first.map(String.init) ?? line
        let hidden = name.hasPrefix("Private")
        var text = hidden ? "Private" : name
        if let next = part.nextUsualStart {
            text += " at \(HouseTime.clock(next, calendar: calendar))"
        }
        return AppSummaryLine(app: .routines, text: text, opens: .app(.routines), isPrivate: hidden)
    }

    private static func tasks(_ engine: ActionEngine, _ now: Date, _ calendar: Calendar) -> AppSummaryLine {
        let store = engine.store
        let day = TesseraDay(calendar: calendar)
        let left = engine.classes[.task].map { taskClass in
            store.objects(of: taskClass).count { task in
                guard !task.isDeleted, store.value("isDone", of: task) != .bool(true) else { return false }
                let when = store.value("startsAt", of: task)?.dateValue ?? store.value("due", of: task)?.dateValue
                return when.map { day.isSameDay($0, now) } ?? false
            }
        } ?? 0
        return AppSummaryLine(app: .tasks, text: left > 0 ? "\(left) left today" : "Nothing left today",
                              opens: .app(.lists), isPrivate: false)
    }

    private static func notes(_ engine: ActionEngine, _: Date, _ calendar: Calendar) -> AppSummaryLine {
        let store = engine.store, classes = engine.classes
        guard let noteClass = classes[.note],
              let note = store.objects(of: noteClass).filter({ !$0.isDeleted }).max(by: { $0.updatedAt < $1.updatedAt })
        else { return AppSummaryLine(app: .notes, text: "No notes yet", opens: .app(.notes), isPrivate: false) }
        let body = store.value("body", of: note)?.stringValue ?? note.title
        let title = note.title.isEmpty ? String(body.prefix(30)) : note.title
        let name = shown(title, in: store, classes: classes, of: note)
        let text = name.1 ? "Private" : "\(name.text), edited at \(HouseTime.clock(note.updatedAt, calendar: calendar))"
        return AppSummaryLine(app: .notes, text: text, opens: name.1 ? .app(.notes) : .object(note.id),
                              isPrivate: name.1)
    }

    private static func lists(_ engine: ActionEngine, _ now: Date, _ calendar: Calendar) -> AppSummaryLine {
        let facts = ListsLanding(engine: engine).facts(.init(now: now, calendar: calendar))
        guard let lead = facts.lead else {
            return AppSummaryLine(app: .lists, text: "No lists yet", opens: .app(.lists), isPrivate: false)
        }
        let name = shown(lead.name, in: engine.store, classes: engine.classes)
        let text = name.1 ? "Private" : "\(name.text), \(lead.total - lead.left) of \(lead.total) done"
        return AppSummaryLine(app: .lists, text: text, opens: .object(lead.list), isPrivate: name.1)
    }

    private static func money(_ engine: ActionEngine, _ due: HomeSentence.MoneyDue?, _ calendar: Calendar)
        -> AppSummaryLine
    {
        guard let due else {
            return AppSummaryLine(app: .money, text: "Nothing is due", opens: .app(.money), isPrivate: false)
        }
        let name = shown(due.name, in: engine.store, classes: engine.classes)
        let day = TesseraDay.weekdayName(of: due.at, calendar: calendar)
        // Words only: when a bill is due, never what it costs.
        return AppSummaryLine(app: .money, text: name.1 ? "Private bill is due \(day)" : "\(name.text) is due \(day)",
                              opens: .app(.money), isPrivate: name.1)
    }
}

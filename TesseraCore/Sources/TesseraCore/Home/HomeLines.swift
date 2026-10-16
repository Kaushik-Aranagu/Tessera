import Foundation

/// One Home item as the phone knows it (docs/ai/home-lines.md, first-features.md 1a). The rules lines and, later,
/// the Claude pack both read this, so the two can never disagree about a number. Titles and short exercise names
/// only: no weights, reps, volume, health or notes ever sit here.
public struct HomeFact: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case workout, cook, shop, task, rest
    }

    public enum State: String, Sendable {
        case running, paused, done, planned
    }

    /// The object the line is about (the workout, cook, list or task); nil for the rest-day line.
    public let id: UUID?
    public let kind: Kind
    /// The routine, recipe, list or task title, as he wrote it.
    public let title: String
    public let state: State
    /// The exercise in focus, short ("Bench"), for a running or paused workout.
    public let exercise: String?
    /// The set he is on (1-based), the cook step he is on (1-based), or the items left to grab.
    public let step: Int?
    /// Cook steps in all; nil elsewhere.
    public let steps: Int?
    /// Logged working sets, for a finished or paused workout.
    public let sets: Int
    public let exercisesDone: Int
    public let exercisesPlanned: Int
    /// Short names of the exercises he set a record on, in workout order.
    public let records: [String]
    /// For a planned cook: grocery rows for that recipe still to buy.
    public let toBuy: Int?
    /// Days since the same routine or recipe was last done; nil when never, or not cheap to know.
    public let sinceLastDays: Int?
    public let startedAt: Date?
    public let endedAt: Date?
    public let lastTouchedAt: Date?
    /// A timed task's start, or a planned thing's slot when it has one.
    public let startsAt: Date?

    public init(id: UUID?, kind: Kind, title: String, state: State, exercise: String? = nil, step: Int? = nil,
                steps: Int? = nil, sets: Int = 0, exercisesDone: Int = 0, exercisesPlanned: Int = 0,
                records: [String] = [], toBuy: Int? = nil, sinceLastDays: Int? = nil, startedAt: Date? = nil,
                endedAt: Date? = nil, lastTouchedAt: Date? = nil, startsAt: Date? = nil)
    {
        self.id = id
        self.kind = kind
        self.title = title
        self.state = state
        self.exercise = exercise
        self.step = step
        self.steps = steps
        self.sets = sets
        self.exercisesDone = exercisesDone
        self.exercisesPlanned = exercisesPlanned
        self.records = records
        self.toBuy = toBuy
        self.sinceLastDays = sinceLastDays
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.lastTouchedAt = lastTouchedAt
        self.startsAt = startsAt
    }

    /// The names a line about this item may use: its title, the exercise in focus, the records.
    public var names: [String] {
        [title] + [exercise].compactMap(\.self) + records
    }

    /// The numbers the facts hold; the line's own digits join them in `HomeLine.numbers`.
    var factNumbers: [Int] {
        var numbers = [step, steps, toBuy, sinceLastDays].compactMap(\.self)
        if kind == .workout, state != .planned {
            numbers += [exercisesDone, exercisesPlanned, sets]
            if records.count > 1 {
                numbers.append(records.count)
            }
        }
        return numbers
    }
}

/// One Home item's words, in the slots Design 41 draws and home-lines.md fills. The hero and the row line are the
/// phone's, always; the context line and the detail are what Claude may reword (AI-4), inside the caps here.
public struct HomeLine: Equatable, Sendable {
    /// The row line, rules only: "Push A done. Bench record.", "Bench paused at set 2.", "Chili, on step 3."
    public let text: String
    /// The hero, rules only: "Push A done", "Push A, paused at bench", "Chili, step 3". No stop; the type carries it.
    public let hero: String
    /// The time words above the hero: "paused 21 min ago", "this evening", "done at 7:40 pm". At most 6 words and
    /// 32 characters, no stop. Nil when there is nothing to say.
    public let context: String?
    /// The context when the full one doesn't fit its width: "paused 21 min". Words shorten, never the type.
    public let contextShort: String?
    /// SO FAR, one tap down, one sentence with its stop: "1 exercise, 2 sets, 1 new best." At most 14 words and
    /// 80 characters. Nil when the item has no counts.
    public let detail: String?
    /// True when Claude never gets this line: a live workout, or a workout with no sets logged.
    public let fixed: Bool
    public let objectID: UUID?
    /// Every digit a reworded context or detail may carry: the facts' numbers and every number in the rules words
    /// (7:40 gives 7 and 40). A checker refuses any other.
    public let numbers: [Int]
    /// The names a reworded line may use.
    public let names: [String]
    /// The fact behind it, for the Claude pack (AI-4).
    public let fact: HomeFact

    init(text: String, hero: String, context: String?, contextShort: String?, detail: String?, fixed: Bool,
         fact: HomeFact)
    {
        self.text = text
        self.hero = hero
        self.context = context
        self.contextShort = contextShort ?? context
        self.detail = detail
        self.fixed = fixed
        objectID = fact.id
        var seen = Set<Int>()
        numbers = (fact.factNumbers + HomeLines.digits(in: context) + HomeLines.digits(in: detail))
            .filter { seen.insert($0).inserted }
        names = fact.names
        self.fact = fact
    }
}

/// The Home lines lens: one plain line per Home item from facts the phone already has, never cut off. Pure rules,
/// no key and no network; Claude's words (AI-4) only ever replace a context or detail that passed the checks.
public enum HomeLines {
    /// The caps the phone enforces on anything that fills these slots (home-lines.md section 1).
    public static let rowWords = 6
    public static let contextWords = 6, contextCharacters = 32
    public static let detailWords = 14, detailCharacters = 80

    /// Whether words fit the context slot: 6 words, 32 characters, no stop. A line that fails is refused, not cut.
    public static func fitsContext(_ words: String) -> Bool {
        let trimmed = words.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !trimmed.hasSuffix(".") && trimmed.count <= contextCharacters
            && trimmed.split(separator: " ").count <= contextWords
    }

    /// Whether a sentence fits the detail slot: one sentence, 14 words, 80 characters, with its stop.
    public static func fitsDetail(_ sentence: String) -> Bool {
        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        return trimmed.hasSuffix(".") && trimmed.count <= detailCharacters
            && trimmed.split(separator: " ").count <= detailWords
            && trimmed.dropLast().allSatisfy { !"?!".contains($0) } && !trimmed.dropLast().contains(". ")
    }

    /// The rules words for one fact.
    public static func line(for fact: HomeFact, now: Date = .now, calendar: Calendar = .current) -> HomeLine {
        let when = context(for: fact, now: now, calendar: calendar)
        let fixed = fact.kind == .workout && (fact.state == .running || (fact.state == .done && fact.sets == 0))
        return HomeLine(text: text(for: fact, now: now, calendar: calendar),
                        hero: hero(for: fact, now: now, calendar: calendar),
                        context: when.full, contextShort: when.short, detail: detail(for: fact), fixed: fixed,
                        fact: fact)
    }

    public static func lines(for facts: [HomeFact], now: Date = .now, calendar: Calendar = .current) -> [HomeLine] {
        facts.map { line(for: $0, now: now, calendar: calendar) }
    }

    // MARK: The row line (first-features.md 1a)

    static func text(for fact: HomeFact, now: Date, calendar: Calendar) -> String {
        switch fact.kind {
        case .rest:
            return "\(RestDay.line)."
        case .workout:
            return workoutText(for: fact, now: now, calendar: calendar)
        case .cook:
            if fact.state == .planned {
                return "\(fact.title) \(dayWord(now, calendar: calendar)), \(toBuy(fact))."
            }
            guard let step = fact.step else { return "\(fact.title), cooking." }
            return "\(fact.title), on step \(step)."
        case .shop:
            guard let left = fact.step, left > 0 else { return "\(fact.title): all in the basket." }
            return "\(fact.title): \(left) left."
        case .task:
            // His own words; the time sits at the right, drawn by the page.
            return fact.title
        }
    }

    static func workoutText(for fact: HomeFact, now: Date, calendar: Calendar) -> String {
        switch fact.state {
        case .done:
            // "Push A done. Bench record." A finished workout with nothing logged is no session.
            guard fact.sets > 0 else { return "\(fact.title), no sets." }
            switch fact.records.count {
            case 0: return "\(fact.title) done."
            case 1: return "\(fact.title) done. \(fact.records[0]) record."
            default: return "\(fact.title) done. \(fact.records.count) records."
            }
        case .running:
            guard let exercise = fact.exercise, let step = fact.step else { return "\(fact.title), under way." }
            return "\(exercise), set \(step)."
        case .paused:
            guard let exercise = fact.exercise, let step = fact.step else { return "\(fact.title) paused." }
            return "\(exercise) paused at set \(step)."
        case .planned:
            return "\(fact.title) \(dayWord(now, calendar: calendar))."
        }
    }

    // MARK: The hero (home-lines.md section 2, rules only)

    static func hero(for fact: HomeFact, now: Date, calendar: Calendar) -> String {
        switch (fact.kind, fact.state) {
        case (.rest, _): RestDay.line
        case (.workout, .done): fact.sets > 0 ? "\(fact.title) done" : "\(fact.title), no sets"
        case (.workout, .running):
            if let exercise = fact.exercise, let step = fact.step {
                "\(fact.title), \(exercise.lowercased()) set \(step)"
            } else {
                fact.title
            }
        case (.workout, .paused): fact.exercise.map { "\(fact.title), paused at \($0.lowercased())" }
            ?? "\(fact.title), paused"
        case (.workout, .planned), (.task, _): fact.title
        case (.cook, .planned): "\(fact.title) \(dayWord(now, calendar: calendar))"
        case (.cook, _): fact.step.map { "\(fact.title), step \($0)" } ?? fact.title
        case (.shop, _): fact.step.map { $0 > 0 ? "\(fact.title), \($0) left" : "\(fact.title), all in the basket" }
            ?? fact.title
        }
    }

    // MARK: The context line (home-lines.md section 2; Claude may reword it)

    static func context(for fact: HomeFact, now: Date, calendar: Calendar) -> (full: String?, short: String?) {
        func since(_ word: String, _ date: Date?) -> (String?, String?) {
            guard let date else { return (nil, nil) }
            let ago = ago(now.timeIntervalSince(date))
            return ("\(word) \(ago)", ago == "just now" ? "\(word) just now" : "\(word) \(ago.dropLast(4))")
        }
        func same(_ words: String) -> (String?, String?) {
            (words, words)
        }
        if fact.kind == .task {
            // A timed task's clock; nothing when it has none.
            return fact.startsAt.map { same(DayStoryClock.sentenceTime($0, calendar: calendar)) } ?? (nil, nil)
        }
        switch (fact.kind, fact.state) {
        case (.rest, _), (.task, _):
            return same(Self.weekdays[calendar.component(.weekday, from: now) - 1])
        case (.workout, .done):
            // "done at 7:40 pm"; a workout with no sets only says when: "this afternoon".
            guard let ended = fact.endedAt else { return (nil, nil) }
            guard fact.sets > 0 else { return same(partWord(ended, calendar: calendar)) }
            return same("done at \(DayStoryClock.sentenceTime(ended, calendar: calendar))")
        case (.workout, .paused), (.cook, .paused):
            return since("paused", fact.lastTouchedAt ?? fact.startedAt)
        case (.workout, .running), (.cook, .running), (.cook, .done):
            return same("now")
        case (.workout, .planned):
            return same(dayWord(now, calendar: calendar))
        case (.cook, .planned):
            return same(toBuy(fact))
        case (.shop, _):
            return same("at the store")
        }
    }

    // MARK: SO FAR (one tap down; Claude may reword it)

    static func detail(for fact: HomeFact) -> String? {
        switch fact.kind {
        case .workout where fact.state != .planned:
            var parts = [count(fact.exercisesDone, "exercise"), count(fact.sets, "set")]
            if !fact.records.isEmpty {
                parts.append(fact.records.count == 1 ? "1 new best" : "\(fact.records.count) new bests")
            }
            return parts.joined(separator: ", ") + "."
        case .cook where fact.state != .planned:
            guard let step = fact.step else { return nil }
            return fact.steps.map { "Step \(step) of \($0)." } ?? "Step \(step)."
        case .shop:
            return fact.step.map { $0 == 0 ? "All in the basket." : "\(count($0, "item")) left." }
        default:
            return nil
        }
    }

    // MARK: Words

    /// "this evening" from 17:00 to 21:00, "tonight" after, "today" the rest of his day (DayPart).
    static func dayWord(_ now: Date, calendar: Calendar) -> String {
        switch DayPart(hour: calendar.component(.hour, from: now)) {
        case .evening: "this evening"
        case .shutdown, .late: "tonight"
        default: "today"
        }
    }

    /// The part of the day a moment fell in: "this morning", "this afternoon", "this evening", "tonight".
    static func partWord(_ date: Date, calendar: Calendar) -> String {
        switch DayPart(hour: calendar.component(.hour, from: date)) {
        case .early, .morning: "this morning"
        case .midday, .afternoon: "this afternoon"
        case .evening: "this evening"
        case .shutdown, .late: "tonight"
        }
    }

    static func toBuy(_ fact: HomeFact) -> String {
        switch fact.toBuy ?? 0 {
        case 0: "nothing to buy"
        case 1: "1 to buy"
        case let count: "\(count) to buy"
        }
    }

    /// His weekdays, in words Tess uses (a bare calendar has no locale, so no symbols of its own).
    static let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    static func count(_ number: Int, _ word: String) -> String {
        "\(number) \(word)\(number == 1 ? "" : "s")"
    }

    /// "just now", "21 min ago", "2 h ago" (never a mm:ss duration).
    public static func ago(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 {
            return "just now"
        }
        if minutes < 60 {
            return "\(minutes) min ago"
        }
        return "\(minutes / 60) h ago"
    }

    /// Every run of digits in some words, in order: "done at 7:40 pm" gives [7, 40].
    public static func digits(in words: String?) -> [Int] {
        guard let words else { return [] }
        return words.matches(of: /\d+/).compactMap { Int($0.output) }
    }
}

/// "6:12 pm", "11:20 pm", "12 pm", shared with the Day log.
enum DayStoryClock {
    static func sentenceTime(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0, minute = parts.minute ?? 0
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        let half = hour < 12 ? "am" : "pm"
        return minute == 0 ? "\(twelve) \(half)" : String(format: "%d:%02d %@", twelve, minute, half)
    }
}

/// Builds the facts from the store, one per thing Home shows: the done workout (the hero), the running or paused
/// process, the planned routine, the planned cook, the rest day, a timed task.
@MainActor
public struct HomeFacts {
    public let engine: ActionEngine
    public var calendar: Calendar

    public init(engine: ActionEngine, calendar: Calendar = .current) {
        self.engine = engine
        self.calendar = calendar
    }

    var store: ObjectStore {
        engine.store
    }

    /// A workout finished today, from Core's summary (counts and records; never the weights).
    public func fact(done summary: WorkoutSummary) -> HomeFact {
        let routine = store.linkedObjects("routine", of: summary.workout).first
        return HomeFact(id: summary.id, kind: .workout, title: summary.title, state: .done, sets: summary.sets,
                        exercisesDone: summary.exercisesDone, exercisesPlanned: summary.exercisesPlanned,
                        records: summary.records.map { ExerciseWords.short($0.exercise) },
                        sinceLastDays: routine.flatMap {
                            daysSinceLastRun(of: $0, before: summary.startedAt ?? summary.endedAt ?? .now)
                        },
                        startedAt: summary.startedAt, endedAt: summary.endedAt)
    }

    /// A running or suspended process: a workout, a cook or a shop.
    public func fact(process: ProcessSnapshot) -> HomeFact? {
        guard let subject = process.subject, let classDef = subject.classDef else { return nil }
        let state: HomeFact.State = process.state == .running ? .running : .paused
        let title = store.displayTitle(of: subject)
        let classes = engine.classes
        if let workout = classes[.workout], store.isSubclass(classDef, ofClassID: workout.id) {
            let progress = WorkoutProgress(of: subject, store: store)
            let sets = subject.orderedChildren.reduce(0) { total, entry in
                total + entry.orderedChildren.count { !$0.isDeleted && store.number("reps", of: $0) != nil }
            }
            return HomeFact(id: subject.id, kind: .workout, title: title, state: state,
                            exercise: progress.exerciseName.map(ExerciseWords.short),
                            step: progress.isComplete ? nil : progress.setIndex + 1, sets: sets,
                            exercisesDone: progress.entriesStarted, exercisesPlanned: progress.entryCount,
                            startedAt: process.startedAt, lastTouchedAt: process.lastTouchedAt)
        }
        if let cook = classes[.cook], store.isSubclass(classDef, ofClassID: cook.id) {
            let recipe = store.linkedObjects("recipe", of: subject).first
            let steps = recipe.map { RecipeBook(store: store, classes: classes).steps(of: $0).count } ?? 0
            return HomeFact(id: subject.id, kind: .cook, title: title, state: state,
                            step: (process.resumePoint?.index ?? 0) + 1, steps: steps > 0 ? steps : nil,
                            startedAt: process.startedAt, lastTouchedAt: process.lastTouchedAt)
        }
        if subject.id == Groceries.listID {
            let left = Groceries(store: store, classes: classes).shoppingOrder().count
            return HomeFact(id: subject.id, kind: .shop, title: title, state: state, step: left,
                            startedAt: process.startedAt, lastTouchedAt: process.lastTouchedAt)
        }
        return nil
    }

    /// The routine the plan says comes next, not started yet.
    public func fact(planned routine: ObjectRecord, at startsAt: Date? = nil, now: Date = .now) -> HomeFact {
        HomeFact(id: routine.id, kind: .workout, title: store.displayTitle(of: routine), state: .planned,
                 sinceLastDays: daysSinceLastRun(of: routine, before: now), startsAt: startsAt)
    }

    /// A cook planned for today ("cook tacos thu": a task about the recipe), with what's still to buy for it.
    public func fact(plannedCook task: ObjectRecord, recipe: ObjectRecord) -> HomeFact {
        HomeFact(id: task.id, kind: .cook, title: store.displayTitle(of: recipe), state: .planned,
                 toBuy: Groceries(store: store, classes: engine.classes).toBuy(for: recipe.id),
                 startsAt: store.value("due", of: task)?.dateValue)
    }

    /// A timed task on Now or Next: his words, with its time.
    public func fact(task: ObjectRecord, startsAt: Date?) -> HomeFact {
        HomeFact(id: task.id, kind: .task, title: store.displayTitle(of: task), state: .planned, startsAt: startsAt)
    }

    /// The quiet "Rest day." line; `next` is the routine one tap away.
    public func rest(next: ObjectRecord?) -> HomeFact {
        HomeFact(id: next?.id, kind: .rest, title: RestDay.line, state: .planned)
    }

    /// Whole days since this routine was last finished before `before`; nil when it never was.
    func daysSinceLastRun(of routine: ObjectRecord, before: Date) -> Int? {
        guard let workoutClass = engine.classes[.workout] else { return nil }
        let last = store.objects(of: workoutClass).lazy
            .filter { !$0.isDeleted && store.linkedObjects("routine", of: $0).first?.id == routine.id }
            .compactMap { store.value("endedAt", of: $0)?.dateValue }
            .filter { $0 < before }
            .max()
        guard let last else { return nil }
        let day = TesseraDay(calendar: calendar)
        return calendar.dateComponents([.day], from: day.day(of: last), to: day.day(of: before)).day
    }
}

/// Exercise names as Tess says them in a line: "Bench", not "Bench Press".
public enum ExerciseWords {
    public static func short(_ name: String) -> String {
        ["Bench Press": "Bench", "Back Squat": "Squat", "Barbell Row": "Row", "Incline Bench Press": "Incline",
         "Overhead Press": "Press"][name] ?? name
    }
}

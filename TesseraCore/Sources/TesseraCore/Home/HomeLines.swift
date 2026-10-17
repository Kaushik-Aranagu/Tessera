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
    /// A planned thing for tomorrow ("Pull A tomorrow", "Rest day tomorrow"; Design 44, Research G12).
    public var tomorrow = false

    public init(id: UUID?, kind: Kind, title: String, state: State, exercise: String? = nil, step: Int? = nil,
                steps: Int? = nil, sets: Int = 0, exercisesDone: Int = 0, exercisesPlanned: Int = 0,
                records: [String] = [], toBuy: Int? = nil, sinceLastDays: Int? = nil, startedAt: Date? = nil,
                endedAt: Date? = nil, lastTouchedAt: Date? = nil, startsAt: Date? = nil, tomorrow: Bool = false)
    {
        self.tomorrow = tomorrow
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
    /// The time words above the hero: "paused 21 min ago", "this evening", "7:40 pm". At most 6 words and
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

    /// One sentence for a widget or the Lock Screen (Design 54): the hero, then the context. A bare time word joins
    /// without a comma ("Push A today."); a fact joins after a comma ("Tacos tonight, 2 to buy."); a context that
    /// repeats the hero's state drops and its clock becomes `widgetMeta`. "Push A done, a bench best."
    public var widgetLine: String {
        widgetWords + "."
    }

    /// The inline Lock Screen face takes the line without its stop. A rest day is "Rest day" alone: widgets have no
    /// day label, so the weekday is the meta (home-lines.md §2, Design 54).
    public var widgetWords: String {
        let records = fact.records
        if fact.kind == .rest {
            return hero
        }
        if fact.kind == .workout, fact.state == .done, fact.sets > 0, !records.isEmpty {
            return records.count == 1 ? "\(hero). \(records[0]) best" : "\(hero). \(records.count) bests"
        }
        guard let context, !HomeLines.repeatsState(context, hero: hero) else { return hero }
        // "tomorrow, first": the bare time word joins without a comma, the fact after one (Design 54 rule 2).
        if let comma = context.firstIndex(of: ","), HomeLines.isTimeWord(String(context[..<comma])) {
            return "\(hero) \(context)"
        }
        return HomeLines.isTimeWord(context) ? "\(hero) \(context)" : "\(hero), \(context)"
    }

    /// The widget's meta, a time only: the clock of a context the line dropped ("8:05 pm"), the weekday on a rest day,
    /// how long a paused thing has waited ("40 min"); nil while something runs.
    public var widgetMeta: String? {
        if fact.kind == .rest {
            return fact.tomorrow ? nil : weekday
        }
        guard let context, context != "now", HomeLines.repeatsState(context, hero: hero) else { return nil }
        return context.firstMatch(of: /\d{1,2}(:\d{2})? ?(am|pm)/).map { String($0.output.0) }
            ?? (contextShort.map { $0.replacingOccurrences(of: "paused ", with: "").replacingOccurrences(
                of: "done ",
                with: ""
            ) })
    }

    /// His day's weekday when the line was read ("Thursday"), for the rest day's widget meta.
    public let weekday: String

    /// Nothing on Home: "All quiet."
    public static let quiet = "All quiet."

    init(text: String, hero: String, context: String?, contextShort: String?, detail: String?, fixed: Bool,
         fact: HomeFact, weekday: String)
    {
        self.weekday = weekday
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
                        fact: fact, weekday: weekday(now: now, calendar: calendar))
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
                return "\(cookWhen(fact, now: now, calendar: calendar)), \(toBuy(fact))."
            }
            if fact.state == .done {
                return "\(fact.title) done."
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
            // "Push A done. Bench best." (never "record" in a line; Design G3). No sets logged is no session.
            guard fact.sets > 0 else { return "\(fact.title), no sets." }
            switch fact.records.count {
            case 0: return "\(fact.title) done."
            case 1: return "\(fact.title) done. \(fact.records[0]) best."
            default: return "\(fact.title) done. \(fact.records.count) bests."
            }
        case .running:
            // Every set logged, finish not tapped: "Push A, all sets in." (Design G5).
            guard let exercise = fact.exercise, let step = fact.step else { return "\(fact.title), all sets in." }
            return "\(exercise), set \(step)."
        case .paused:
            guard let exercise = fact.exercise, let step = fact.step else { return "\(fact.title) paused." }
            return "\(exercise) paused at set \(step)."
        case .planned:
            if let at = fact.startsAt, !fact.tomorrow {
                return "\(fact.title), \(DayStoryClock.sentenceTime(at, calendar: calendar))."
            }
            return "\(fact.title) \(fact.tomorrow ? "tomorrow" : dayWord(now, calendar: calendar))."
        }
    }

    /// "Tacos tonight" (a cook is an evening thing until it has a time), "Tacos, 7 pm" with one (Kitchen lead, G8).
    static func cookWhen(_ fact: HomeFact, now: Date, calendar: Calendar) -> String {
        if fact.tomorrow {
            return "\(fact.title) tomorrow"
        }
        if let at = fact.startsAt {
            // Hero times carry "pm" (TW17, Product): "Tacos, 7 pm".
            return "\(fact.title), \(HouseTime.clock(at, calendar: calendar))"
        }
        let evening: Set<DayPart> = [.evening, .shutdown, .late]
        let word = evening.contains(DayPart(hour: calendar.component(.hour, from: now))) ? "tonight" : "today"
        return "\(fact.title) \(word)"
    }

    // MARK: The hero (home-lines.md section 2, rules only)

    static func hero(for fact: HomeFact, now: Date, calendar: Calendar) -> String {
        switch (fact.kind, fact.state) {
        case (.rest, _): fact.tomorrow ? "\(RestDay.line) tomorrow" : RestDay.line
        case (.workout, .done): fact.sets > 0 ? "\(fact.title) done" : "\(fact.title), no sets"
        case (.workout, .running):
            if let exercise = fact.exercise, let step = fact.step {
                "\(fact.title), \(exercise.lowercased()) set \(step)"
            } else {
                "\(fact.title), all sets in"
            }
        case (.workout, .paused): fact.exercise.map { "\(fact.title), paused at \($0.lowercased())" }
            ?? "\(fact.title), paused"
        case (.workout, .planned):
            if let at = fact.startsAt, !fact.tomorrow {
                "\(fact.title), \(DayStoryClock.sentenceTime(at, calendar: calendar))"
            } else {
                fact.title
            }
        case (.task, _): fact.title
        case (.cook, .planned): cookWhen(fact, now: now, calendar: calendar)
        case (.cook, .done): "\(fact.title) done"
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
            // The day label above the hero already names the day, so the rest line says "today" (Builder B's #366);
            // the weekday lives on as the widget's meta through `weekday(now:calendar:)`.
            return same(fact.tomorrow ? "tomorrow" : "today")
        case (.workout, .done):
            // "7:40 pm" alone: the hero already says done (home-lines.md §2, no repeats); a workout with no sets only
            // says when: "this afternoon".
            guard let ended = fact.endedAt else { return (nil, nil) }
            guard fact.sets > 0 else { return same(partWord(ended, calendar: calendar)) }
            return same(DayStoryClock.sentenceTime(ended, calendar: calendar))
        case (.workout, .paused), (.cook, .paused), (.shop, .paused):
            // A paused shop is him at home, not at the store (Research G2).
            return since("paused", fact.lastTouchedAt ?? fact.startedAt)
        case (.workout, .running), (.cook, .running):
            return same("now")
        case (.workout, .planned):
            // The closed day's look ahead: "tomorrow, first" (m4-steers §7), so Now and the widget agree.
            return same(fact.tomorrow ? "tomorrow, first" : dayWord(now, calendar: calendar))
        case (.cook, .planned) where (fact.toBuy ?? 0) == 0:
            // Nothing left to buy: the context goes back to the day word; the row keeps "nothing to buy" (Kitchen K87,
            // rulings C8 and B6).
            return same(dayWord(now, calendar: calendar))
        default:
            return kitchenContext(for: fact, calendar: calendar).map { ($0, $0) } ?? (nil, nil)
        }
    }

    /// The done cook's clock, the planned cook's count, the shop's place.
    static func kitchenContext(for fact: HomeFact, calendar: Calendar) -> String? {
        switch (fact.kind, fact.state) {
        case (.cook, .done): fact.endedAt.map { DayStoryClock.sentenceTime($0, calendar: calendar) }
        case (.cook, .planned): toBuy(fact)
        case (.shop, _): "at the store"
        default: nil
        }
    }

    // MARK: SO FAR (one tap down; Claude may reword it)

    static func detail(for fact: HomeFact) -> String? {
        switch fact.kind {
        case .workout where fact.state != .planned && fact.sets > 0:
            // A zero count reads as grading, so there is no SO FAR until a set is in (Research G4).
            var parts = [count(fact.exercisesDone, "exercise"), count(fact.sets, "set")]
            if !fact.records.isEmpty {
                parts.append(fact.records.count == 1 ? "1 new best" : "\(fact.records.count) new bests")
            }
            return parts.joined(separator: ", ") + "."
        case .cook where fact.state == .running || fact.state == .paused:
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

    /// His day's weekday: at 01:00 Friday it is still Thursday (QA on #334). The widget's meta on a rest day.
    public static func weekday(now: Date, calendar: Calendar = .current) -> String {
        let day = TesseraDay(calendar: calendar).day(of: now)
        return weekdays[calendar.component(.weekday, from: day) - 1]
    }

    static func count(_ number: Int, _ word: String) -> String {
        "\(number) \(word)\(number == 1 ? "" : "s")"
    }

    /// "just now" up to 2 min, "21 min ago", "2 h ago" from 60 min rounded to the nearest hour (Research G6, G11).
    public static func ago(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 2 {
            return "just now"
        }
        if minutes < 60 {
            return "\(minutes) min ago"
        }
        return "\(max(1, Int((Double(minutes) / 60).rounded()))) h ago"
    }

    /// Time words that join a hero without a comma in a widget line.
    static func isTimeWord(_ context: String) -> Bool {
        ["today", "tonight", "this evening", "this afternoon", "this morning", "tomorrow", "now"].contains(context)
            || weekdays.contains(context)
    }

    /// Whether a context only repeats the hero's state ("8:05 pm" under "Push A done"; "paused 21 min ago"
    /// under "Push A, paused at incline"; "now" under a running hero).
    static func repeatsState(_ context: String, hero: String) -> Bool {
        let lower = hero.lowercased()
        let clock = context.wholeMatch(of: /\d{1,2}(:\d{2})? ?(am|pm)/) != nil
        return (context.hasPrefix("done") && lower.contains("done")) || (clock && lower.contains("done"))
            || (context.hasPrefix("paused") && lower.contains("paused")) || context == "now"
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
        HouseTime.clock(date, calendar: calendar)
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
            let title = cookTitle(subject, recipe: recipe)
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

    /// The routine the plan says comes next, not started yet; `tomorrow` for the evening's look ahead (Design 44).
    public func fact(planned routine: ObjectRecord, at startsAt: Date? = nil, now: Date = .now,
                     tomorrow: Bool = false) -> HomeFact
    {
        HomeFact(id: routine.id, kind: .workout, title: store.displayTitle(of: routine), state: .planned,
                 sinceLastDays: daysSinceLastRun(of: routine, before: now), startsAt: startsAt, tomorrow: tomorrow)
    }

    /// A cook finished today stays on Home like a done workout, until 04:00 (Research G1).
    public func fact(doneCook cook: ObjectRecord) -> HomeFact {
        HomeFact(
            id: cook.id,
            kind: .cook,
            title: cookTitle(cook, recipe: store.linkedObjects("recipe", of: cook).first),
            state: .done,
            startedAt: store.value("startedAt", of: cook)?.dateValue,
            endedAt: store.value("cookedAt", of: cook)?.dateValue
        )
    }

    /// Cooks finished on his day containing `now`, newest first.
    public func cooksFinished(on now: Date) -> [ObjectRecord] {
        guard let cookClass = engine.classes[.cook] else { return [] }
        let day = TesseraDay(calendar: calendar)
        return store.objects(of: cookClass).filter { cook in
            guard !cook.isDeleted, let at = store.value("cookedAt", of: cook)?.dateValue else { return false }
            return day.isSameDay(at, now)
        }
        .sorted {
            (store.value("cookedAt", of: $0)?.dateValue ?? .distantPast) >
                (store.value("cookedAt", of: $1)?.dateValue ?? .distantPast)
        }
    }

    /// A cook's name on Home: "Private recipe" when the recipe's title is private (gap hunt G21, ObjectPrivacy).
    private func cookTitle(_ object: ObjectRecord, recipe: ObjectRecord?) -> String {
        let last = BodyWeight.lastKg(in: store)
        if let label = ObjectPrivacy.label(of: recipe ?? object, in: store, classes: engine.classes) {
            return label
        }
        let title = store.displayTitle(of: object)
        return PrivateFacts.isPrivateTitle(title, lastWeightKg: last) || EngineWall.isHealth(title, lastWeightKg: last)
            ? ObjectPrivacy.recipeLabel : title
    }

    /// A cook planned for today ("cook tacos thu": a task about the recipe), with what's still to buy for it.
    public func fact(plannedCook task: ObjectRecord, recipe: ObjectRecord) -> HomeFact {
        // The planned time first (a captured cook has startsAt, never due); a date-only due (midnight) has no clock.
        var at = store.value("startsAt", of: task)?.dateValue
        if at == nil, let due = store.value("due", of: task)?.dateValue,
           calendar.dateComponents([.hour, .minute], from: due) != DateComponents(hour: 0, minute: 0)
        {
            at = due
        }
        return HomeFact(id: task.id, kind: .cook, title: cookTitle(recipe, recipe: recipe), state: .planned,
                        toBuy: Groceries(store: store, classes: engine.classes).toBuy(for: recipe.id),
                        startsAt: at)
    }

    /// A timed task on Now or Next: his words, with its time.
    public func fact(task: ObjectRecord, startsAt: Date?) -> HomeFact {
        HomeFact(id: task.id, kind: .task, title: store.displayTitle(of: task), state: .planned, startsAt: startsAt)
    }

    /// The quiet "Rest day." line; `next` is the routine one tap away. `tomorrow` for "Rest day tomorrow". Nil when a
    /// session is planned for the day: the planned session wins, and "Rest day" never sits beside a START key
    /// (Product 96db137).
    public func rest(next: ObjectRecord?, tomorrow: Bool = false, now: Date = .now) -> HomeFact? {
        if !tomorrow, plannedSession(on: now) != nil {
            return nil
        }
        return HomeFact(id: next?.id, kind: .rest, title: RestDay.line, state: .planned, tomorrow: tomorrow)
    }

    /// A workout scheduled for his day containing `now`, or started from a routine and not finished (the app's
    /// "tonight's workout"); nil when nothing is planned.
    public func plannedSession(on now: Date) -> ObjectRecord? {
        guard let workoutClass = engine.classes[.workout] else { return nil }
        let day = TesseraDay(calendar: calendar)
        return store.objects(of: workoutClass).first { workout in
            guard !workout.isDeleted, store.value("endedAt", of: workout) == nil,
                  let date = store.value("scheduledFor", of: workout)?.dateValue
                  ?? store.value("startedAt", of: workout)?.dateValue else { return false }
            return day.isSameDay(date, now)
        }
    }

    /// A scheduled session, not started: "Push A at 7 pm" over the START key.
    public func fact(scheduled workout: ObjectRecord) -> HomeFact {
        HomeFact(id: workout.id, kind: .workout, title: store.displayTitle(of: workout), state: .planned,
                 startsAt: store.value("scheduledFor", of: workout)?.dateValue)
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
    static let table = ["Bench Press": "Bench", "Back Squat": "Squat", "Barbell Row": "Row",
                        "Incline Bench Press": "Incline", "Overhead Press": "Press", "Deadlift": "Deadlift",
                        "Romanian Deadlift": "RDL", "Lat Pulldown": "Pulldown", "Close-Grip Pulldown": "Pulldown",
                        "Straight-Arm Pulldown": "Pulldown", "Dumbbell Lateral Raise": "Lateral raise",
                        "Cable Lateral Raise": "Lateral raise", "Face Pull": "Face pull", "Lying Leg Curl": "Leg curl",
                        "Seated Leg Curl": "Leg curl", "Standing Calf Raise": "Calf raise",
                        "Seated Calf Raise": "Calf raise", "Leg Extension": "Leg extension", "Leg Press": "Leg press",
                        "Hip Thrust": "Hip thrust", "Pull-Up": "Pull-up", "Chin-Up": "Chin-up", "Push-Up": "Push-up",
                        "Incline Dumbbell Press": "Incline DB press", "Dumbbell Bench Press": "DB bench",
                        "Close-Grip Bench Press": "Close-grip bench", "Seated Cable Row": "Cable row",
                        "Chest-Supported Row": "Chest-supported row", "One-Arm Dumbbell Row": "One-arm row",
                        "T-Bar Row": "T-bar row", "Front Squat": "Front squat", "Goblet Squat": "Goblet squat",
                        "Hack Squat": "Hack squat", "Smith Machine Squat": "Smith squat",
                        "Bulgarian Split Squat": "Split squat", "Sumo Deadlift": "Sumo deadlift",
                        "Dumbbell Romanian Deadlift": "DB RDL", "Seated Dumbbell Shoulder Press": "DB shoulder press",
                        "Machine Shoulder Press": "Machine press", "Machine Chest Press": "Chest press"]
    /// Words that only say the kit: shortened, never dropped, so two lifts never share a name (QA F1 on #369).
    static let kitShort = ["Dumbbell": "DB", "Barbell": "BB", "Kettlebell": "KB", "Machine": "machine",
                           "Smith Machine": "Smith"]

    /// "Bench" for "Bench Press"; a name with no row keeps every word, with "Dumbbell" as "DB" and "Barbell" as "BB"
    /// ("Incline DB press", "Chest-Supported row"), the first word capitalised and the rest lowercased.
    public static func short(_ name: String) -> String {
        if let known = table[name] {
            return known
        }
        var words = name.replacingOccurrences(of: "Smith Machine", with: "Smith").split(separator: " ").map(String.init)
        guard words.count > 1 else { return name }
        words = words.map { kitShort[$0] ?? $0 }
        return words.enumerated().map { index, word in
            index == 0 || ["DB", "BB", "KB"].contains(word) ? word : word.lowercased()
        }.joined(separator: " ")
    }
}

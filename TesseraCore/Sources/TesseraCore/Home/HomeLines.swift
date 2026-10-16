import Foundation

/// One Home item as the phone knows it (docs/ai/first-features.md, feature 1a). The rules line and, later, the Claude
/// pack both read this, so the two can never disagree about a number. Titles and short exercise names only: no
/// weights, reps, volume, health or notes ever sit here.
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
    /// Logged working sets, for a finished workout.
    public let sets: Int
    public let exercisesDone: Int
    public let exercisesPlanned: Int
    /// Short names of the exercises he set a record on, in workout order.
    public let records: [String]
    public let startedAt: Date?
    public let endedAt: Date?
    public let lastTouchedAt: Date?
    /// A timed task's start, or a planned routine's slot when it has one.
    public let startsAt: Date?

    public init(id: UUID?, kind: Kind, title: String, state: State, exercise: String? = nil, step: Int? = nil,
                steps: Int? = nil, sets: Int = 0, exercisesDone: Int = 0, exercisesPlanned: Int = 0,
                records: [String] = [], startedAt: Date? = nil, endedAt: Date? = nil, lastTouchedAt: Date? = nil,
                startsAt: Date? = nil)
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
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.lastTouchedAt = lastTouchedAt
        self.startsAt = startsAt
    }

    /// The numbers a line about this item may carry (architecture 5.4, "licensed numbers").
    public var numbers: [Int] {
        var numbers: [Int] = []
        if let step {
            numbers.append(step)
        }
        if let steps {
            numbers.append(steps)
        }
        if state == .done, kind == .workout {
            numbers += [exercisesDone, exercisesPlanned]
            if records.count > 1 {
                numbers.append(records.count)
            }
        }
        return numbers
    }
}

/// One Home item's words, in the slots Design 41 draws: the row line, the hero (the thing and its state), the
/// context line above it (the time, with a shorter form when it doesn't fit) and the one-sentence detail a tap down.
public struct HomeLine: Equatable, Sendable {
    /// The row line: "Push A done. Bench record.", "Bench paused at set 2.", "Chili, on step 3."
    public let text: String
    /// The hero: "Push A done", "Push A, paused at bench", "Push A". No trailing stop; the type carries it.
    public let hero: String
    /// The time words: "paused 21 min ago", "this evening", "today"; nil when there is no time to say.
    public let context: String?
    /// The context when the full one doesn't fit: "paused 21 min". Words shorten, never the type.
    public let contextShort: String?
    /// One tap down, as prose: "1 exercise, 2 sets, 1 new best." Nil when the item has no counts.
    public let detail: String?
    public let objectID: UUID?
    public let numbers: [Int]
    /// The fact behind it, for the Claude pack (AI-4).
    public let fact: HomeFact

    public init(text: String, hero: String, context: String?, contextShort: String?, detail: String?, fact: HomeFact) {
        self.text = text
        self.hero = hero
        self.context = context
        self.contextShort = contextShort ?? context
        self.detail = detail
        objectID = fact.id
        numbers = fact.numbers
        self.fact = fact
    }
}

/// The Home lines lens: one plain line per Home item from facts the phone already has, six words at most, never
/// cut off. Pure rules, no key and no network; Claude's words (AI-4) only ever replace a line that passed the checks.
public enum HomeLines {
    /// Row lines are 6 words or fewer; the hero (the done or paused workout) 9 or fewer (architecture 5.4).
    public static let rowWords = 6, heroWords = 9

    /// The rules line for one fact (first-features.md, "Rules lines (1a)").
    public static func line(for fact: HomeFact, now: Date = .now, calendar: Calendar = .current) -> HomeLine {
        let when = context(for: fact, now: now, calendar: calendar)
        return HomeLine(text: text(for: fact, now: now, calendar: calendar), hero: hero(for: fact),
                        context: when.full, contextShort: when.short, detail: detail(for: fact), fact: fact)
    }

    public static func lines(for facts: [HomeFact], now: Date = .now, calendar: Calendar = .current) -> [HomeLine] {
        facts.map { line(for: $0, now: now, calendar: calendar) }
    }

    static func text(for fact: HomeFact, now: Date, calendar: Calendar) -> String {
        switch fact.kind {
        case .rest:
            return "\(RestDay.line)."
        case .workout:
            return workoutText(for: fact, now: now, calendar: calendar)
        case .cook:
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
            // "Legs this evening" from 17:00 to 21:00; "Legs today" the rest of his day (DayPart).
            let hour = calendar.component(.hour, from: now)
            return DayPart(hour: hour) == .evening ? "\(fact.title) this evening." : "\(fact.title) today."
        }
    }

    /// The hero: the thing and its state, no time (Design 41 rule 1).
    static func hero(for fact: HomeFact) -> String {
        switch (fact.kind, fact.state) {
        case (.rest, _): RestDay.line
        case (.workout, .done): fact.sets > 0 ? "\(fact.title) done" : "\(fact.title), no sets"
        case (.workout, .running): fact.exercise.map { "\(fact.title), at \($0.lowercased())" } ?? fact.title
        case (.workout, .paused): fact.exercise.map { "\(fact.title), paused at \($0.lowercased())" }
            ?? "\(fact.title), paused"
        case (.workout, .planned): fact.title
        case (.cook, _): fact.step.map { "\(fact.title), on step \($0)" } ?? fact.title
        case (.shop, _): fact.step.map { $0 > 0 ? "\(fact.title), \($0) left" : "\(fact.title), all in the basket" }
            ?? fact.title
        case (.task, _): fact.title
        }
    }

    /// The context line: when. "paused 21 min ago" shortens to "paused 21 min" (Design 41 rule 2).
    static func context(for fact: HomeFact, now: Date, calendar: Calendar) -> (full: String?, short: String?) {
        func since(_ word: String, _ date: Date?) -> (String?, String?) {
            guard let date else { return (nil, nil) }
            let ago = ago(now.timeIntervalSince(date))
            return ("\(word) \(ago)", ago == "just now" ? "\(word) just now" : "\(word) \(ago.dropLast(4))")
        }
        switch (fact.kind, fact.state) {
        case (.rest, _): return (nil, nil)
        case (.workout, .done): return since("done", fact.endedAt)
        case (.workout, .paused): return since("paused", fact.lastTouchedAt ?? fact.startedAt)
        case (.workout, .running), (.cook, _), (.shop, _): return since("started", fact.startedAt)
        case (.workout, .planned):
            let hour = calendar.component(.hour, from: now)
            let word = DayPart(hour: hour) == .evening ? "this evening" : "today"
            return (word, word)
        case (.task, _):
            guard let startsAt = fact.startsAt else { return (nil, nil) }
            let clock = DayStoryClock.sentenceTime(startsAt, calendar: calendar)
            return (clock, clock)
        }
    }

    /// One tap down: the counts as one sentence, never on Home itself (Design 41 rule 6).
    static func detail(for fact: HomeFact) -> String? {
        switch fact.kind {
        case .workout where fact.state != .planned:
            var parts = [count(fact.exercisesDone, "exercise"), count(fact.sets, "set")]
            if !fact.records.isEmpty {
                parts.append(fact.records.count == 1 ? "1 new best" : "\(fact.records.count) new bests")
            }
            return parts.joined(separator: ", ") + "."
        case .cook:
            guard let step = fact.step else { return nil }
            return fact.steps.map { "Step \(step) of \($0)." } ?? "Step \(step)."
        case .shop:
            return fact.step.map { $0 == 0 ? "All in the basket." : "\(count($0, "item")) left." }
        default:
            return nil
        }
    }

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
/// process, the planned routine, the rest day, a timed task.
@MainActor
public struct HomeFacts {
    public let engine: ActionEngine

    public init(engine: ActionEngine) {
        self.engine = engine
    }

    var store: ObjectStore {
        engine.store
    }

    /// A workout finished today, from Core's summary (counts and records; never the weights).
    public func fact(done summary: WorkoutSummary) -> HomeFact {
        HomeFact(id: summary.id, kind: .workout, title: summary.title, state: .done, sets: summary.sets,
                 exercisesDone: summary.exercisesDone, exercisesPlanned: summary.exercisesPlanned,
                 records: summary.records.map { ExerciseWords.short($0.exercise) },
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
            return HomeFact(id: subject.id, kind: .workout, title: title, state: state,
                            exercise: progress.exerciseName.map(ExerciseWords.short),
                            step: progress.isComplete ? nil : progress.setIndex + 1,
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
    public func fact(planned routine: ObjectRecord, at startsAt: Date? = nil) -> HomeFact {
        HomeFact(id: routine.id, kind: .workout, title: store.displayTitle(of: routine), state: .planned,
                 startsAt: startsAt)
    }

    /// A timed task on Now or Next: his words, with its time.
    public func fact(task: ObjectRecord, startsAt: Date?) -> HomeFact {
        HomeFact(id: task.id, kind: .task, title: store.displayTitle(of: task), state: .planned, startsAt: startsAt)
    }

    /// The quiet "Rest day." line; `next` is the routine one tap away.
    public func rest(next: ObjectRecord?) -> HomeFact {
        HomeFact(id: next?.id, kind: .rest, title: RestDay.line, state: .planned)
    }
}

/// Exercise names as Tess says them in a line: "Bench", not "Bench Press".
public enum ExerciseWords {
    public static func short(_ name: String) -> String {
        ["Bench Press": "Bench", "Back Squat": "Squat", "Barbell Row": "Row", "Incline Bench Press": "Incline",
         "Overhead Press": "Press"][name] ?? name
    }
}

import Foundation

/// How the mosaic looks right now (Home departure mosaic, sheet 200, switch homeMosaicMoods, needs homeMosaic).
public enum MosaicMood: String, CaseIterable, Sendable {
    case morning, day, golden, running, rest, back, done, rain, night
}

/// How the mosaic changes from one mood to the next.
public enum MosaicTransition: String, CaseIterable, Sendable {
    case wave, fall, wipe, dissolve, gather

    /// Each mood's own changeover.
    public static func standard(for mood: MosaicMood) -> MosaicTransition {
        switch mood {
        case .morning, .rain: .fall
        case .day, .running, .done: .wave
        case .golden: .wipe
        case .rest, .night: .dissolve
        case .back: .gather
        }
    }
}

/// What the picker reads, all of it on the phone and none of it sent anywhere. Weather is not here yet: `raining` stays
/// false until WeatherKit exists, and it will use a coarse place and never be paired with his data.
public struct MosaicMoodInputs: Sendable {
    public var facts: MosaicFacts
    /// A process is running (a workout, a cook, a shop).
    public var running: Bool
    /// The words for what is running, already masked ("Private workout"), for the sentence only.
    public var runningLabel: String?
    /// The app the running thing belongs to, nil when it is masked (then its words are plain).
    public var runningApp: AppID?
    public var isRestDay: Bool
    /// Whole days since he last did anything by hand.
    public var daysAway: Int
    /// "Welcome back" has been shown since this absence began: it shows once.
    public var backShown: Bool
    /// Tasks due today, and how many of them are finished (private ones count; only the counts are read).
    public var dueToday: Int
    public var doneToday: Int
    public var raining: Bool
    /// The mood on screen and since when, for the 10-minute hold.
    public var previous: (mood: MosaicMood, since: Date)?

    public init(facts: MosaicFacts, running: Bool = false, runningLabel: String? = nil, isRestDay: Bool = false,
                daysAway: Int = 0, backShown: Bool = false, dueToday: Int = 0, doneToday: Int = 0,
                raining: Bool = false, runningApp: AppID? = nil, previous: (mood: MosaicMood, since: Date)? = nil)
    {
        self.facts = facts
        self.running = running
        self.runningLabel = runningLabel
        self.runningApp = runningApp
        self.isRestDay = isRestDay
        self.daysAway = daysAway
        self.backShown = backShown
        self.dueToday = dueToday
        self.doneToday = doneToday
        self.raining = raining
        self.previous = previous
    }
}

/// The pick: the mood, its changeover, the three lines of the sentence, and when this mood began.
public struct MosaicPick: Equatable, Sendable {
    public let mood: MosaicMood
    public let transition: MosaicTransition
    /// The three lines as the day sentence's own clauses: an app word carries its app and key word, a masked or private
    /// thing is plain text with no key word, and Tess's own words are never an app word.
    public let clauses: [HomeSentence.Clause]
    public let since: Date

    public var lines: [String] {
        clauses.map(\.text)
    }
}

/// Tess picks the mood (sheet 200). On the phone only: it has no model call and no asksClaude, and no mood cue, health,
/// calendar, body, calorie or walled title ever leaves the phone. First match wins; a mood is held at least ten minutes
/// except running and done.
public enum MosaicMoodPicker {
    public static let hold: TimeInterval = 600

    public static func pick(_ input: MosaicMoodInputs) -> MosaicPick {
        let fresh = firstMatch(input)
        var mood = fresh
        var since = input.facts.now
        if let previous = input.previous {
            since = previous.since
            let heldLongEnough = input.facts.now.timeIntervalSince(previous.since) >= hold
            let exempt = fresh == .running || fresh == .done || previous.mood == .running || previous.mood == .done
            if fresh == previous.mood {
                mood = fresh
            } else if !heldLongEnough, !exempt {
                mood = previous.mood
            } else {
                since = input.facts.now
            }
        }
        return MosaicPick(mood: mood, transition: .standard(for: mood), clauses: lines(for: mood, input),
                          since: since)
    }

    /// The nine in order, first match wins.
    static func firstMatch(_ input: MosaicMoodInputs) -> MosaicMood {
        let facts = input.facts
        let calendar = facts.calendarForPicker
        let hour = calendar.component(.hour, from: facts.now)
        if input.running {
            return .running
        }
        if input.dueToday > 0, input.doneToday >= input.dueToday, hour < 22, hour >= TesseraDay.startHour {
            return .done
        }
        if input.daysAway >= 3, !input.backShown {
            return .back
        }
        if input.isRestDay {
            return .rest
        }
        if hour >= 22 || hour < TesseraDay.startHour {
            return .night
        }
        if abs(facts.sunset.timeIntervalSince(facts.now)) <= 30 * 60 {
            return .golden
        }
        let sinceSunrise = facts.now.timeIntervalSince(facts.sunrise)
        if sinceSunrise >= 0, sinceSunrise <= 60 * 60 {
            return .morning
        }
        if input.raining {
            return .rain
        }
        return .day
    }

    /// Three lines, one clause each, from words already on the phone. Titles are masked before they get here.
    static func lines(for mood: MosaicMood, _ input: MosaicMoodInputs) -> [HomeSentence.Clause] {
        let facts = input.facts
        let plain = MosaicMomentSource.plain
        let time = plain(facts.caption(for: .time))
        switch mood {
        case .running:
            let words = "\(input.runningLabel ?? "Something") is running."
            let line = input.runningLabel.flatMap { label in
                input.runningApp.map { MosaicMomentSource.accented(words, key: label, app: $0) }
            } ?? plain(words)
            return [time, line, nextClause(facts)]
        case .done:
            return [time, plain("Everything due today is done."), plain(facts.caption(for: .done))]
        case .back:
            return [time, plain("Welcome back."), dayClause(facts)]
        case .rest:
            return [time, plain("Today is a rest day."), dayClause(facts)]
        case .night, .golden:
            return [time, plain(facts.caption(for: .sky)), plain(facts.caption(for: .done))]
        case .morning:
            return [time, plain(facts.caption(for: .sky)), dayClause(facts)]
        case .rain:
            return [time, plain("Rain is on its way."), dayClause(facts)]
        case .day:
            return [time, dayClause(facts), plain(facts.caption(for: .done))]
        }
    }

    private static func dayClause(_ facts: MosaicFacts) -> HomeSentence.Clause {
        appClause(facts.caption(for: .day), facts)
    }

    private static func nextClause(_ facts: MosaicFacts) -> HomeSentence.Clause {
        appClause(facts.caption(for: .next), facts)
    }

    /// The caption with the next thing's name as an app word when it belongs to an app and is not masked.
    private static func appClause(_ text: String, _ facts: MosaicFacts) -> HomeSentence.Clause {
        guard let next = facts.nextTimed, let app = next.app, text.contains(next.title) else {
            return MosaicMomentSource.plain(text)
        }
        return MosaicMomentSource.accented(text, key: next.title, app: app)
    }
}

@MainActor
public extension MosaicMoodInputs {
    /// Reads the phone: the running process, today's rest day, the days away and what is due today. `plan` is the plan
    /// Home trains from.
    static func make(engine: ActionEngine, facts: MosaicFacts, plan: ObjectRecord? = nil, backShown: Bool = false,
                     raining: Bool = false, previous: (mood: MosaicMood, since: Date)? = nil) -> MosaicMoodInputs
    {
        let store = engine.store, classes = engine.classes
        let calendar = facts.calendarForPicker
        let running = ProcessTable(engine: engine).running()
        var label: String?
        var runningApp: AppID?
        if let running {
            let subject = running.subject
            let masked = subject.flatMap { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) }
            let words = masked ?? subject?.title ?? running.ownerApp
            let hidden = words.map {
                ObjectPrivacy.isPrivateWord($0, in: store) || SecretWords.mentions($0)
                    || PrivateFacts.isWalled($0, lastWeightKg: BodyWeight.lastKg(in: store))
            } ?? true
            label = hidden ? MosaicMoodInputs.privateLabel(of: running, store: store) : words
            // An app word only for a thing that is shown as itself.
            runningApp = hidden || masked != nil ? nil : subject?.classDef.flatMap { ClassResolver.app(for: $0) }
        }
        let stats = TrainingStats(store: store, classes: classes)
        let rest = plan.map { stats.landingFacts(plan: $0, now: facts.now, calendar: calendar).isRestDay } ?? false
        var due = 0, done = 0
        if let taskClass = classes[.task] {
            let day = TesseraDay(calendar: calendar)
            for task in store.objects(of: taskClass) where !task.isDeleted {
                guard let dueDate = store.value("due", of: task)?.dateValue, day.isSameDay(dueDate, facts.now) else {
                    continue
                }
                due += 1
                if store.value("isDone", of: task) == .bool(true) {
                    done += 1
                }
            }
        }
        return MosaicMoodInputs(
            facts: facts, running: running != nil, runningLabel: label, isRestDay: rest,
            daysAway: NowPicker(engine: engine).daysAway(at: facts.now, calendar: calendar), backShown: backShown,
            dueToday: due, doneToday: done, raining: raining, runningApp: runningApp, previous: previous
        )
    }

    /// The app's own private label for what is running: never a new phrase.
    static func privateLabel(of process: ProcessSnapshot, store _: ObjectStore) -> String {
        let app = process.subject?.classDef.flatMap { ClassResolver.app(for: $0) }
            ?? process.ownerApp
            .flatMap { name in AppID.allCases.first { $0.name == name || name == "Workouts" && $0 == .training } }
        switch app {
        case .kitchen: return ObjectPrivacy.recipeLabel
        case .routines: return RoutinesLanding.privateRoutine
        case .notes: return ObjectPrivacy.noteLabel
        case .lists: return ListContents.privateListLabel
        default: return ObjectPrivacy.routineLabel
        }
    }
}

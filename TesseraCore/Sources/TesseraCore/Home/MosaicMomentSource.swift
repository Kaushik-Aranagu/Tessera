import Foundation

/// The weather a moment can show. Inert until the paid WeatherKit entitlement exists: the host passes nil, and when it
/// is on it uses a coarse place and never pairs the answer with his data.
public enum MosaicWeather: String, CaseIterable, Sendable {
    case snow, fog, wind, storm, heat
}

/// What kind of moment (sheet 201): weather, an announcement, Tess, an app's event.
public enum MosaicMomentKind: Equatable, Sendable {
    case weather(MosaicWeather)
    /// The next timed thing, 15 minutes ahead.
    case announcement
    /// An on-device suggestion is ready.
    case tess
    /// A kitchen timer finished.
    case timer
    /// Something finished (an op-log finish).
    case finished
    /// A new best.
    case best
    /// A task or routine is due now.
    case reminder
    /// His own "arrived" mark.
    case delivery

    /// A timer and a finish always play: they are not held to one moment in ten minutes.
    public var isExempt: Bool {
        self == .timer || self == .finished
    }
}

/// One moment to play and its one sentence line. The line is a `HomeSentence.Clause`, the day sentence's own type, so
/// one renderer covers both: a plain thing is plain, an app word carries its app and key word, a masked or private
/// thing is plain text with no key word, and Tess's own words are never an app word. A clause with no key word opens
/// nothing.
public struct MosaicMomentPick: Equatable, Sendable {
    public let kind: MosaicMomentKind
    public let clause: HomeSentence.Clause
    /// Three lines, as `MosaicPick.clauses`: the moment's own line, then two lines of context (the time and the day).
    public let clauses: [HomeSentence.Clause]
    /// What the picture takes from the item: only an app accent or the glaze, never a word about the item itself.
    public let tone: MosaicTone
    /// When it happened (the timer's end, the finish, the best, the start of a reminder), or now for the others.
    public let at: Date
    /// Which event this is, so it never plays twice.
    public let key: String

    public var line: String {
        clause.text
    }
}

/// Everything the source reads, all of it on the phone. The host fills it with `MosaicMomentInputs.make`.
public struct MosaicMomentInputs: Sendable {
    public struct Candidate: Equatable, Sendable {
        public let kind: MosaicMomentKind
        public let clause: HomeSentence.Clause
        public let at: Date
        public let key: String
        public var tone: MosaicTone = .glaze
    }

    public var now: Date
    public var quiet: Bool
    /// The last moment that played, for the one-in-ten-minutes rule.
    public var last: (kind: MosaicMomentKind, at: Date)?
    /// Keys that have played, so an event never plays twice.
    public var played: Set<String>
    public var candidates: [Candidate]
    /// The two context lines under a moment's own line (the time, then the day), already masked.
    public var context: [HomeSentence.Clause]

    public init(now: Date, quiet: Bool = false, last: (kind: MosaicMomentKind, at: Date)? = nil,
                played: Set<String> = [], candidates: [Candidate] = [], context: [HomeSentence.Clause] = [])
    {
        self.context = context
        self.now = now
        self.quiet = quiet
        self.last = last
        self.played = played
        self.candidates = candidates
    }
}

/// Decides when a moment plays and what it says. On the phone only: no model call, no asksClaude; nothing it reads or
/// says goes to Claude, a backup, a log or a widget. Walled titles are masked ("Private workout"), no money amount is
/// ever a line, and health, body and calories are never shown.
public enum MosaicMomentSource {
    public static let spacing: TimeInterval = 600
    /// An event older than this has passed: its moment is not played late.
    public static let freshness: TimeInterval = 120
    public static let announceMinutes = 15

    /// The moment to play now, or nil. Priority when several are ready: timer, finished, best, reminder, delivery,
    /// announcement, Tess, weather. A timer plays even in quiet hours; nothing else does.
    public static func next(_ input: MosaicMomentInputs) -> MosaicMomentPick? {
        let spaced = input.last.map { input.now.timeIntervalSince($0.at) >= spacing } ?? true
        let ready = input.candidates
            .filter { !input.played.contains($0.key) }
            .filter { input.quiet ? $0.kind == .timer : ($0.kind.isExempt || spaced) }
            .sorted { rank($0.kind) < rank($1.kind) }
        return ready.first.map {
            MosaicMomentPick(kind: $0.kind, clause: $0.clause, clauses: [$0.clause] + input.context.prefix(2),
                             tone: $0.tone, at: $0.at, key: $0.key)
        }
    }

    private static func rank(_ kind: MosaicMomentKind) -> Int {
        switch kind {
        case .timer: 0
        case .finished: 1
        case .best: 2
        case .reminder: 3
        case .delivery: 4
        case .announcement: 5
        case .tess: 6
        case .weather: 7
        }
    }

    // MARK: Lines

    /// A plain line: no app word, nothing to open.
    static func plain(_ text: String) -> HomeSentence.Clause {
        HomeSentence.Clause(app: nil, sentence: LandingSentence(text: text, key: nil), opens: .app(.notes))
    }

    /// A line whose first word is an app word in its accent.
    static func accented(_ text: String, key: String, app: AppID, opens: HomeSentence.Opens? = nil)
        -> HomeSentence.Clause
    {
        HomeSentence.Clause(app: app, sentence: LandingSentence(text: text, key: key), opens: opens ?? .app(app))
    }

    /// A key that holds no words: FNV-1a over the text, in hex. Played keys are kept, so they must not hold a line.
    static func hashed(_ text: String) -> String {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in text.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
        }
        return String(hash, radix: 16)
    }

    public static func weatherLine(_ weather: MosaicWeather) -> String {
        switch weather {
        case .snow: "It is snowing"
        case .fog: "Fog outside"
        case .wind: "It is windy"
        case .storm: "A storm is passing"
        case .heat: "It is hot out"
        }
    }
}

@MainActor
public extension MosaicMomentInputs {
    /// Reads the phone for what is ready at `facts.now`. `events` are the day's hands events (workout, cook, routines).
    /// `weather` stays nil until WeatherKit; `tessLine` is an on-device suggestion that is ready, or nil.
    static func make(engine: ActionEngine, facts: MosaicFacts, quiet: Bool = false,
                     last: (kind: MosaicMomentKind, at: Date)? = nil, played: Set<String> = [],
                     weather: MosaicWeather? = nil, tessLine: String? = nil, events: [HandsEvent] = [])
        -> MosaicMomentInputs
    {
        let now = facts.now
        let store = engine.store, classes = engine.classes
        let weight = BodyWeight.lastKg(in: store)
        var found: [Candidate] = []
        func fresh(_ date: Date) -> Bool {
            date <= now && now.timeIntervalSince(date) <= MosaicMomentSource.freshness
        }

        if let weather {
            found.append(Candidate(kind: .weather(weather), clause: MosaicMomentSource.plain(
                MosaicMomentSource.weatherLine(weather)
            ), at: now, key: "weather-\(weather.rawValue)"))
        }
        // The next timed thing at 15 minutes, masked like every caption.
        if let next = facts.nextTimed, let free = facts.freeMinutes, free <= MosaicMomentSource.announceMinutes,
           free > 0
        {
            let text = "\(next.title) in \(HouseTime.minutes(free))"
            let clause = next.app.map { MosaicMomentSource.accented(text, key: next.title, app: $0) }
                ?? MosaicMomentSource.plain(text)
            found.append(Candidate(
                kind: .announcement,
                clause: clause,
                at: now,
                key: "announce-\(next.start.timeIntervalSince1970)",
                tone: next.app.map { .accent($0) } ?? .glaze
            ))
        }
        // An on-device suggestion that is ready: vetted like any line, Tess's words are never an app word.
        if let tessLine, !tessLine.isEmpty, !isWalled(tessLine, store: store, weight: weight) {
            found.append(Candidate(kind: .tess, clause: MosaicMomentSource.plain(tessLine), at: now,
                                   key: "tess-\(MosaicMomentSource.hashed(tessLine))"))
        }
        // A kitchen timer that has just finished.
        for timer in CookLog(store: store, classes: classes).timers(at: now) where !timer.object.isDeleted
            && fresh(timer.endsAt)
        {
            let name = timer.label.trimmingCharacters(in: .whitespacesAndNewlines)
            let hidden = KitchenTimerAlerts.hidesLabel(name, cook: timer.cook, in: store)
                || isWalled(name, store: store, weight: weight)
            let label = hidden ? "Timer" : name.prefix(1).uppercased() + name.dropFirst()
            let text = "\(label) is done"
            found.append(Candidate(kind: .timer, clause: hidden ? MosaicMomentSource.plain(text)
                    : MosaicMomentSource.accented(text, key: String(label), app: .kitchen),
                at: timer.endsAt, key: "timer-\(timer.id)", tone: .accent(.kitchen)))
        }
        // Something finished, from the op log (the app only; no title ever).
        for finish in facts.finishedToday where fresh(finish.time) {
            found.append(Candidate(kind: .finished, clause: MosaicMomentSource.plain("Done"), at: finish.time,
                                   key: "finish-\(finish.time.timeIntervalSince1970)",
                                   tone: finish.app.map { .accent($0) } ?? .glaze))
        }
        let recent = engine.history(
            from: now.addingTimeInterval(-MosaicMomentSource.freshness),
            to: now.addingTimeInterval(1)
        )
        for record in recent where record.state == .committed {
            if record.action == MarkArrived.descriptor.name {
                let groceries = record.summary == "Groceries arrived"
                let clause = groceries ? MosaicMomentSource.accented(
                    "Groceries are here",
                    key: "Groceries",
                    app: .kitchen
                )
                    : MosaicMomentSource.plain("A delivery is here")
                found.append(Candidate(kind: .delivery, clause: clause, at: record.createdAt,
                                       key: "arrived-\(record.id)", tone: groceries ? .accent(.kitchen) : .glaze))
            }
            if record.action == "finishWorkout", let isPrivate = newBest(in: record, engine: engine) {
                // A best from a private workout is a plain finish: no Training accent, no hint of what it was.
                if isPrivate {
                    found.append(Candidate(kind: .finished, clause: MosaicMomentSource.plain("Done"),
                                           at: record.createdAt, key: "best-\(record.id)"))
                } else {
                    found.append(Candidate(kind: .best, clause: MosaicMomentSource.accented(
                        "A new best", key: "A new best", app: .training
                    ), at: record.createdAt, key: "best-\(record.id)", tone: .accent(.training)))
                }
            }
        }
        // A task or routine due now.
        if let taskClass = classes[.task] {
            for task in store.objects(of: taskClass)
                where !task.isDeleted && store.value("isDone", of: task) != .bool(true)
            {
                guard let start = store.value("startsAt", of: task)?.dateValue ?? store.value("due", of: task)?
                    .dateValue,
                    fresh(start) else { continue }
                let shown = ObjectPrivacy.shownLabel(of: task, in: store, classes: classes)
                    ?? (isWalled(task.title, store: store, weight: weight) ? ObjectPrivacy.taskLabel : nil)
                let text = "\(shown ?? task.title), now"
                // A task belongs to no app, so its line is plain whether it is masked or not.
                let clause = MosaicMomentSource.plain(text)
                found.append(Candidate(kind: .reminder, clause: clause, at: start, key: "reminder-\(task.id)"))
            }
        }
        for event in events where event.app == .routines && fresh(event.start) {
            let hidden = event.isPrivate || isWalled(event.label, store: store, weight: weight)
            let label = hidden ? RoutinesLanding.privateRoutine : event.label
            let clause = hidden ? MosaicMomentSource.plain("\(label), now")
                : MosaicMomentSource.accented("\(label), now", key: label, app: .routines)
            found.append(Candidate(kind: .reminder,
                                   clause: clause,
                                   at: event.start,
                                   key: "reminder-\(MosaicMomentSource.hashed(label))-\(event.start.timeIntervalSince1970)",
                                   tone: hidden ? .glaze : .accent(.routines)))
        }
        // A best never plays after its own finish: the finish that ended the same workout is dropped.
        let bestTimes = Set(found.filter { $0.key.hasPrefix("best-") }.map(\.at))
        found.removeAll { $0.key.hasPrefix("finish-") && bestTimes.contains($0.at) }
        // The two lines under a moment's own: the time, then the day (the next timed thing as an app word when it has
        // one), all masked already.
        var day = MosaicMomentSource.plain(facts.caption(for: .day))
        if let next = facts.nextTimed, let app = next.app, day.text.contains(next.title) {
            day = MosaicMomentSource.accented(day.text, key: next.title, app: app)
        }
        return MosaicMomentInputs(now: now, quiet: quiet, last: last, played: played, candidates: found,
                                  context: [MosaicMomentSource.plain(facts.caption(for: .time)), day])
    }

    private static func isWalled(_ text: String, store: ObjectStore, weight: Double?) -> Bool {
        // The one wall (input-hygiene H2); a key-shaped line is walled here too now.
        !Wall.judge(text, lastWeightKg: weight, store: store)
            .isDisjoint(with: [.key, .secret, .money, .body, .calories, .privateWord])
    }

    /// Whether the workout a `finishWorkout` record ended set a new best (a heavier one-rep estimate than any before it
    /// for an exercise he had a best for). The answer is whether that workout is private; nil is no new best.
    private static func newBest(in record: OpRecord, engine: ActionEngine) -> Bool? {
        let store = engine.store, classes = engine.classes
        let ledger = TrainingLedger(store: store, classes: classes)
        for workout in record.objectIDs.compactMap({ store.object(id: $0) })
            where workout.classDef?.id == classes[.workout]?.id
        {
            for entry in workout.orderedChildren {
                guard let exercise = store.linkedClass("exercise", of: entry),
                      let prior = ledger.records(for: exercise, excludingWorkout: workout.id).bestE1RM?.e1RM,
                      let mine = ledger.sessions(of: exercise).first(where: { $0.workoutID == workout.id })?.sets
                      .filter(\.isE1RMEligible).map(\.e1RM).max(), mine > prior + 0.05 else { continue }
                return ObjectPrivacy.shownLabel(of: workout, in: store, classes: classes) != nil
            }
        }
        return nil
    }
}

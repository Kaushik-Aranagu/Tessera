import Foundation
import TesseraCore

/// What the night pass keeps between nights, in `Application Support/Tessera/night-pass.json` (excluded from
/// backups): the last night it finished, the hash each expertise pack was built with, and the summaries it wrote
/// (the last 60 days and 26 weeks). Summaries hold shown names and counts only.
public struct NightRecord: Codable, Sendable, Equatable {
    public static let fileName = "night-pass.json"
    public static let keepDays = 60
    public static let keepWeeks = 26
    /// How long a tool path no run has taken is kept.
    public static let keepProcedureDays = 90

    public var lastNight: String?
    /// Expertise raw value to the hash its cached pack was built with.
    public var packHashes: [String: String]
    /// Summary path ("/summaries/day/2026-10-23") to its lines.
    public var summaries: [String: String]
    /// Which tool paths answered each job (input-hygiene H6). Nil in a file from before it.
    public var procedures: ProcedureBook?

    public init(lastNight: String? = nil, packHashes: [String: String] = [:], summaries: [String: String] = [:],
                procedures: ProcedureBook? = nil)
    {
        self.lastNight = lastNight
        self.packHashes = packHashes
        self.summaries = summaries
        self.procedures = procedures
    }

    /// Drops the oldest summaries past the limits. Stamps sort as text, so the newest are last.
    public mutating func trim() {
        for (folder, limit) in [("/summaries/day/", Self.keepDays), ("/summaries/week/", Self.keepWeeks)] {
            let paths = summaries.keys.filter { $0.hasPrefix(folder) }.sorted()
            for path in paths.dropLast(limit) {
                summaries[path] = nil
            }
        }
    }

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    public static func load(from url: URL? = defaultURL) -> NightRecord {
        guard let url, let data = try? Data(contentsOf: url),
              let record = try? JSONDecoder().decode(NightRecord.self, from: data)
        else { return NightRecord() }
        return record
    }

    public func save(to url: URL? = NightRecord.defaultURL) {
        guard let url, let data = try? JSONEncoder().encode(self) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #if os(iOS)
            try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
            try? data.write(to: url, options: [.atomic])
        #endif
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }
}

/// Memory spec M5 into M6: the 4 am run. It builds the night pass's inputs from the store, runs the planned steps
/// through actions (so the op log has them and Undo works), records the night, then runs the nightly eval and keeps
/// its row. The Claude parts arrive as closures, so the run is testable with a fake brain: `reflect` is one Door call
/// per active agent, and `ask` is one compiled ask per eval question and model.
///
/// After it, on Sundays, the caller feeds `MemoryEvalRecord.tunerMisses` to the BudgetTuner.
@MainActor
public struct NightRun {
    public struct Report: Sendable, Equatable {
        public var night: String
        public var steps: [NightPass.Step]
        /// Steps whose action refused (a belief closed in between, say). The rest still ran.
        public var failed: [NightPass.Step]
        public var reflected: [String]
        public var eval: [EvalNight]
    }

    public var engine: ActionEngine
    public var calendar: Calendar
    public var now: Date
    public var policy: DoorPolicy
    /// The models the eval runs on (M6: Haiku and Sonnet).
    public var models: [BrainID]

    public init(engine: ActionEngine, calendar: Calendar = .current, now: Date = .now, policy: DoorPolicy = .lab,
                models: [BrainID] = [.haiku, .sonnet])
    {
        self.engine = engine
        self.calendar = calendar
        self.now = now
        self.policy = policy
        self.models = models
    }

    var store: ObjectStore {
        engine.store
    }

    var classes: [SystemCatalog.Key: ClassDef] {
        engine.classes
    }

    var pass: NightPass {
        NightPass(calendar: calendar, now: now)
    }

    // MARK: The run

    /// Nil when this night already ran. `runs` are Tess's run digests from the trace: the closing day's teach the
    /// procedure book. Until the run loop stamps each run's reading, every digest reads as `.unknown` and nothing is
    /// learned.
    public func run(
        record: inout NightRecord, eval: inout MemoryEvalRecord, packs: [AgentSpec.Expertise: String] = [:],
        notebooks: [NightPass.NotebookFile] = [], runs: [RunDigest] = [], prune: (String) -> Void = { _ in },
        reflect: (AgentSpec) async -> Void = { _ in }, ask: (EvalQuestion, BrainID) async -> String?
    ) async -> Report? {
        let pass = pass
        guard record.lastNight != pass.night else { return nil }
        var hashes: [AgentSpec.Expertise: (now: String, built: String?)] = [:]
        for (expertise, hash) in packs {
            hashes[expertise] = (now: hash, built: record.packHashes[expertise.rawValue])
        }
        let start = pass.dayStart
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        let sunday = calendar.component(.weekday, from: pass.closingDay) == 1
        let weekStart = calendar.date(byAdding: .day, value: -6, to: start) ?? start
        let steps = pass.plan(
            beliefs: TessBeliefStore(engine: engine).all(), series: series(), day: items(from: start, to: end),
            week: sunday ? items(from: weekStart, to: end) : [], notebooks: notebooks, packs: hashes,
            agents: AgentSpec.available(under: policy), lastNight: record.lastNight, policy: policy
        )

        var failed: [NightPass.Step] = []
        var reflected: [String] = []
        for step in steps {
            do {
                switch step {
                case let .merge(keep, close):
                    _ = try engine.perform(MergeBelief(keep: keep, close: close, at: now), by: .system)
                case let .revise(belief, words, value, evidence):
                    _ = try engine.perform(ReviseBelief(belief: belief, words: words, value: value, evidence: evidence,
                                                    at: now), by: .system)
                case let .confirm(belief):
                    _ = try engine.perform(ConfirmBelief(belief: belief), by: .system)
                case let .summary(path, text):
                    record.summaries[path] = text
                case let .prune(path):
                    prune(path)
                case let .refresh(expertise):
                    record.packHashes[expertise.rawValue] = packs[expertise]
                case let .reflect(agent):
                    if let spec = AgentSpec.named(agent) {
                        await reflect(spec)
                        reflected.append(agent)
                    }
                }
            } catch {
                failed.append(step)
            }
        }
        learn(runs.filter { $0.at >= start && $0.at < end }, into: &record)
        record.lastNight = pass.night
        record.trim()

        let nights = await runEval(night: pass.night, record: &eval, ask: ask)
        return Report(night: pass.night, steps: steps, failed: failed, reflected: reflected, eval: nights)
    }

    /// The closing day's runs into the procedure book (H6); paths no run has taken in 90 days go.
    func learn(_ runs: [RunDigest], into record: inout NightRecord) {
        var book = record.procedures ?? ProcedureBook()
        for run in runs {
            book.learn(run)
        }
        if let cutoff = calendar.date(byAdding: .day, value: -NightRecord.keepProcedureDays, to: now) {
            book.expire(before: cutoff)
        }
        record.procedures = book
    }

    /// M6: tonight's questions, kept misses first, asked on each model and scored exactly. A question counts toward
    /// the kept list only when every model answered it, so a failed call never reads as a right answer.
    func runEval(night: String, record: inout MemoryEvalRecord,
                 ask: (EvalQuestion, BrainID) async -> String?) async -> [EvalNight]
    {
        let facts = MemoryEvalFacts.from(store: store, classes: classes, calendar: calendar, now: now)
        let eval = MemoryEval(calendar: calendar, now: now)
        let questions = eval.questions(from: facts, night: night, keep: record.kept)
        var olds: [UUID: String] = [:]
        for change in facts.changes {
            if let belief = change.belief {
                olds[belief] = change.old
            }
        }
        var nights: [EvalNight] = []
        var answeredBy: [String: Int] = [:]
        for model in models {
            var row = EvalNight(night: night, model: model.rawValue)
            for question in questions {
                guard let reply = await ask(question, model) else { continue }
                answeredBy[question.id, default: 0] += 1
                let old = question.belief.flatMap { olds[$0] }
                row.record(question, right: eval.isRight(reply, for: question, old: old))
            }
            nights.append(row)
        }
        let answered = questions.filter { answeredBy[$0.id] == models.count }
        record.add(nights, questions: answered)
        return nights
    }

    // MARK: Inputs

    /// Every workout start and cook time, private ones included: only the time is read.
    func series() -> [NightPass.Event] {
        var events: [NightPass.Event] = []
        if let workoutClass = classes[.workout] {
            for workout in store.objects(of: workoutClass) where !workout.isDeleted {
                if let at = store.value("startedAt", of: workout)?.dateValue {
                    events.append(.init(id: workout.id, at: at, classID: workoutClass.id, verb: "train"))
                }
            }
        }
        if let cookClass = classes[.cook] {
            for cook in store.objects(of: cookClass) where !cook.isDeleted {
                if let at = store.value("cookedAt", of: cook)?.dateValue {
                    events.append(.init(id: cook.id, at: at, classID: cookClass.id, verb: "cook"))
                }
            }
        }
        return events
    }

    /// What happened between two times, by shown name. A note is a count only: its title may be his words.
    func items(from start: Date, to end: Date) -> [NightPass.DayItem] {
        func inside(_ date: Date?) -> Date? {
            guard let date, date >= start, date < end else { return nil }
            return date
        }
        func shown(_ object: ObjectRecord) -> String {
            ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) ?? object.title
        }
        var items: [NightPass.DayItem] = []
        if let workoutClass = classes[.workout] {
            for workout in store.objects(of: workoutClass) where !workout.isDeleted {
                guard let at = inside(store.value("startedAt", of: workout)?.dateValue) else { continue }
                items.append(.init(kind: "workout", name: shown(workout), at: at, room: AppID.training.rawValue))
            }
        }
        if let cookClass = classes[.cook] {
            for cook in store.objects(of: cookClass) where !cook.isDeleted {
                guard let at = inside(store.value("cookedAt", of: cook)?.dateValue) else { continue }
                let name = store.linkedObjects("recipe", of: cook).first.map(shown) ?? shown(cook)
                items.append(.init(kind: "cook", name: name, at: at, room: AppID.kitchen.rawValue))
            }
        }
        if let taskClass = classes[.task] {
            for task in store.objects(of: taskClass) where !task.isDeleted {
                guard let at = inside(store.value("doneAt", of: task)?.dateValue) else { continue }
                items.append(.init(kind: "task done", name: shown(task), at: at, room: "today"))
            }
        }
        if let noteClass = classes[.note] {
            for note in store.objects(of: noteClass) where !note.isDeleted {
                guard let at = inside(note.createdAt) else { continue }
                items.append(.init(kind: "note", name: "", at: at, room: AppID.notes.rawValue))
            }
        }
        return items
    }
}

// MARK: - The eval's store adapter

public extension MemoryEvalFacts {
    /// Questions with no belief behind them, each with the word that would mean one exists.
    static let unknownTopics: [(String, String)] = [
        ("cuisine", "What's my favorite cuisine?"), ("shoe", "What's my shoe size?"),
        ("movie", "What's my favorite movie?"),
    ]

    /// The store as the nightly eval's facts. Private workouts, private exercises and recipes, private beliefs and
    /// deleted rows are left out, so no walled title or number becomes a question.
    @MainActor
    static func from(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], calendar: Calendar,
                     now: Date) -> MemoryEvalFacts
    {
        let lastKg = BodyWeight.lastKg(in: store)
        func isPlain(_ name: String) -> Bool {
            !ObjectPrivacy.isPrivateTitle(name, lastWeightKg: lastKg)
        }
        func isShown(_ object: ObjectRecord) -> Bool {
            ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) == nil
        }

        var sets: [SetFact] = []
        let ledger = TrainingLedger(store: store, classes: classes)
        let stats = TrainingStats(store: store, classes: classes)
        let exercises: [ClassDef] = store.exerciseGroups(root: classes[.exercise]).flatMap(\.exercises)
        for exercise in exercises where isPlain(exercise.name) {
            let own = stats.counted(ledger.sessions(of: exercise)).filter { session in
                store.linkedClass("exercise", of: session.entry)?.id == exercise.id
            }
            for session in own where session.date < now {
                for set in session.sets where set.reps == set.reps.rounded() && set.reps >= 1 {
                    sets.append(SetFact(exercise: exercise.name, day: session.date, weight: set.weight, unit: "kg",
                                        reps: Int(set.reps)))
                }
            }
        }

        var events: [Event] = []
        if let cookClass = classes[.cook] {
            for cook in store.objects(of: cookClass) where !cook.isDeleted && isShown(cook) {
                guard let day = store.value("cookedAt", of: cook)?.dateValue, day < now,
                      let recipe = store.linkedObjects("recipe", of: cook).first, !recipe.isDeleted, isShown(recipe)
                else { continue }
                events.append(Event(name: recipe.title, verb: "cook", day: day))
            }
        }
        if let workoutClass = classes[.workout] {
            for workout in store.objects(of: workoutClass) where !workout.isDeleted && isShown(workout) {
                // The question names the routine, so the routine must be shown too.
                guard let day = store.value("startedAt", of: workout)?.dateValue, day < now,
                      let routine = store.linkedObjects("routine", of: workout).first, !routine.isDeleted,
                      isShown(routine)
                else { continue }
                events.append(Event(name: routine.title, verb: "do", day: day))
            }
        }

        let beliefs = classes[.belief].map { beliefClass in
            store.objects(of: beliefClass).filter { !$0.isDeleted }
        } ?? []
        var changes: [Change] = []
        var verbs: [UUID: String] = [:]
        if let id = classes[.workout]?.id {
            verbs[id] = "train"
        }
        if let id = classes[.cook]?.id {
            verbs[id] = "cook"
        }
        for current in beliefs where store.value("validUntil", of: current) == nil {
            guard store.value("key", of: current)?.stringValue == TessBelief.Key.usualTime.rawValue,
                  store.value("isPrivate", of: current) != .bool(true),
                  let old = store.linkedObjects("supersedes", of: current).first,
                  let subject = store.linkedClass("subjectClass", of: current), let verb = verbs[subject.id],
                  let hourNow = store.value("value", of: current)?.stringValue.flatMap(NightPass.hour(of:)),
                  let hourThen = store.value("value", of: old)?.stringValue.flatMap(NightPass.hour(of:)),
                  NightPass.clock(hourNow) != NightPass.clock(hourThen)
            else { continue }
            changes.append(Change(question: "When do I usually \(verb)?", old: NightPass.clock(hourThen),
                                  current: NightPass.clock(hourNow), belief: current.id))
        }

        let open = beliefs.filter { store.value("validUntil", of: $0) == nil }.map { $0.title.lowercased() }
        let unknowns: [String] = unknownTopics.filter { pair in !open.contains { $0.contains(pair.0) } }
            .map { $0.1 }
        return MemoryEvalFacts(sets: sets, events: events, changes: changes, unknowns: unknowns)
    }
}

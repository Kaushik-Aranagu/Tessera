import Foundation
import Observation
import os
import SwiftUI
import TesseraCore
import TesseraIntents
import TesseraTess

/// Something you can navigate to: every name in the UI is a handle to one of these.
enum Route: Hashable {
    case object(UUID)
    case classDef(UUID)
    /// A plan's routines (docs/design/training-mode.md, "Routines").
    case routines(UUID)
}

/// One row of the day's schedule.
struct ScheduleItem: Identifiable, Equatable {
    enum Status: String {
        case done = "DONE", now = "NOW", boarding = "BOARDING", soon = "SOON", later = "LATER"
    }

    let id: UUID
    let title: String
    let start: Date
    let end: Date
    let isDone: Bool
    let isWorkout: Bool

    func status(at now: Date) -> Status {
        if isDone || end < now && !isWorkout {
            return .done
        }
        if start <= now, now < end {
            return .now
        }
        let minutes = start.timeIntervalSince(now) / 60
        if minutes <= 15 {
            return .boarding
        }
        if minutes <= 90 {
            return .soon
        }
        return .later
    }
}

@MainActor
@Observable
final class AppModel {
    let context: TesseraContext
    let store: ObjectStore
    private(set) var classes: [SystemCatalog.Key: ClassDef] = [:]
    /// Whether the settings object lives in his real store (not a memory fallback or a failed seed).
    var settingsAreReal = false

    /// "Tess asks Claude", for misses and Plan my day: the one settings field, and never on a throwaway store.
    var asksClaude: Bool {
        settingsAreReal && SettingsStore(engine: engine).read().sendsMissesToClaude
    }

    /// Plan my day's Claude wording stays off until Core's G4 and G9 land and its eval passes (AI architecture, Oct
    /// 16). Turning it on is their one-line change.
    static let planWordingReady = false

    /// Plan my day's wording through Claude: one instance for the app, so its cache holds across reopens.
    var planWording: ClaudePlanWording {
        if let wording = planWordingStore {
            return wording
        }
        let wording = ClaudePlanWording(
            keys: SystemKeychain(),
            ledger: TessUsageLedger(store: store, classes: classes)
        ) {
            [weak self] in self?.asksClaude ?? false
        }
        planWordingStore = wording
        return wording
    }

    @ObservationIgnored private var planWordingStore: ClaudePlanWording?

    /// A demo flag is on: Claude's Home words are never read or written (home-lines-job.md §5).
    static var isDemo: Bool {
        ["-demo", "-resetDemo", "-theme", "-fakeClaudeKey"].contains(where: { LaunchFlags.has($0) })
    }

    /// Home's done job through Claude (board 0al): one instance, so its per-workout cache holds.
    var homeDone: ClaudeHomeDone {
        if let job = homeDoneStore {
            return job
        }
        let job = ClaudeHomeDone(keys: SystemKeychain(), ledger: TessUsageLedger(store: store, classes: classes),
                                 cacheURL: Self.isDemo ? nil : ClaudeHomeDone.defaultCacheURL)
        {
            [weak self] in self?.asksClaude ?? false
        }
        homeDoneStore = job
        return job
    }

    @ObservationIgnored private var homeDoneStore: ClaudeHomeDone?

    /// Claude's words for a finished workout's Home slots, or nil: the rules words stand (Kaushik's "Sonnet on
    /// Home", 2:41 PM PT Oct 16). Show the rules line first; a returned slot replaces its rules words.
    func homeDoneWords(for line: HomeLine) async -> HomeDoneWords? {
        guard !Self.isDemo, line.fact.kind == .workout, line.fact.state == .done, let ended = line.fact.endedAt
        else { return nil }
        let label = HomeDonePack.dayLabel(finish: ended, calendar: homeDone.calendar)
        return await homeDone.words(for: line, dayLabel: label, store: store)
    }

    /// Bumped after writes so views re-read derived data.
    private(set) var revision = 0
    /// Pages above Home.
    var path: [Route] = []
    /// Pages zoomed into from the live workout (z), stacked inside the workout's own cover.
    var workoutPath: [Route] = []
    /// How each pushed page arrives: zoom out of the tapped row (deeper) or cross-fade (jump / up).
    @ObservationIgnored private(set) var arrivals: [Route: Arrival] = [:]
    /// Pages already seen this session — their entrance choreography only plays on the first visit.
    @ObservationIgnored private var visited: Set<Route> = []
    var hasRevealedGreeting = false
    var session: WorkoutSession?
    /// The workout cover zooms out of Training's first lane (set by START; cleared when the cover goes).
    var workoutRisesFromLane = false
    var isWorkoutPresented = false {
        didSet {
            if isWorkoutPresented {
                session?.touch()
            } else {
                // Whoever closed the cover, the next one (Resume, the seam) is a plain one.
                workoutRisesFromLane = false
            }
        }
    }

    var commandDraft = ""
    var isCommandExpanded = false
    /// What Tess's soul is doing right now.
    /// Tess's state, set only by the router (tess-motion.md §14); views emit `soul.handle(_:)` events.
    let soul = SoulRouter()
    var tessMode: TessSoul.Mode {
        soul.mode
    }

    /// "Tess has eyes" (Settings › Tess, off by default). Core's `tessEyes` field is on its way; until then only the
    /// simulator's `-tessEyes` flag turns them on (LaunchFlags is simulator-only, so never on the phone).
    var tessHasEyes: Bool {
        LaunchFlags.has("-tessEyes")
    }

    /// Home (the launcher Tess paints in) vs Today.
    /// Where you were when Tess took you Home; tapping her again goes back.
    var homeReturnPath: [Route]?

    /// `launchDefaults`: where once-per-install launch decisions are kept; the app tests pass a throwaway suite (QA on
    /// #665), so a test run never decides for an install.
    init(context: TesseraContext, launchDefaults: UserDefaults = .standard) {
        self.context = context
        store = ObjectStore(context: context)
        do {
            // Built-in classes, the 72-exercise library and Kaushik's starter plan (cheap after the first run).
            classes = try store.prepareCatalog()
        } catch {
            // Never crash on launch, DEBUG included (the phone runs DEBUG builds): log it and open with what loaded.
            Logger(subsystem: "com.kaushikaranagu.tessera", category: "launch")
                .error("Seeding failed: \(String(describing: error), privacy: .public)")
        }
        engine = ActionEngine(store: store, classes: classes)
        ledger = TrainingLedger(store: store, classes: classes)
        // QA F1: only his real store holds his settings. On a throwaway store (memory fallback, a failed seed) the
        // settings read as empty, which would mean "yes": skip the migrate (it would delete his old "no") and keep
        // Claude off.
        settingsAreReal = TesseraSchema.lastOpenOutcome == .opened && classes[.settings] != nil
        // The release that adds the settings object: the old keys move in once, as system (settings-object.md).
        // Never while a demo flag is on, so a demo can't freeze a look into his data.
        let demo = Self.isDemo
        if !demo, settingsAreReal {
            SettingsStore(engine: engine).migrateAtLaunch(looks: ThemeStore.sharedDefaults, standard: .standard,
                                                          folderName: BackupKeeper.pickedFolder
                                                              .map(BackupCopy.folderName))
            // The first launch with the restWeekday reader: Sunday, as one op with UNDO ("Sunday, rest day.";
            // Research 146). Once; an UNDO or a later "Any" leaves a record, so it is never written twice.
            SettingsStore(engine: engine).writeFirstRestWeekday(defaults: launchDefaults)
        }
        runtime = TesseraRuntime(engine: engine)
        soul.runScript()
        // A cold launch is a foreground too: told now, so her first frame already has her eyes shut if she wakes.
        soul.handle(.foregrounded(underLive: false))
        // Claude is the last capture step, gated on the one "Tess asks Claude" field, the key and the pause
        // (it checks each at every call). Off in demos, so a fake key never goes over the network.
        if !demo, let capture = runtime.tess as? TessCaptureEngine {
            capture.claude = ClaudeTessModel(
                keys: SystemKeychain(),
                ledger: TessUsageLedger(store: store, classes: classes),
                flags: ClaudeMissFlags()
            ) { [weak self] in
                self?.asksClaude ?? false
            }
        }
        // Core's calm note (store couldn't open, legacy migration pending) wins; else this launch's outcome.
        let outcome: String? = switch TesseraSchema.lastOpenOutcome {
        case .opened: nil
        case .recoveredWithBackup: "Started fresh; your old data is saved in Backups."
        case .inMemoryFallback: "Couldn't open your data, so nothing will be saved this time."
        }
        launchNote = TesseraSchema.launchNote ?? outcome
    }

    /// One calm line in Tess's voice when launch didn't go normally (a failed migration). Shown in the Ask bar.
    var launchNote: String?

    /// Tess's capture engine and the App Intents runtime (Core's TesseraTess / TesseraIntents).
    @ObservationIgnored private(set) var runtime: TesseraRuntime!

    /// Every UI write goes through typed actions, so it lands in the op log with undo (Core engine).
    @ObservationIgnored private(set) var engine: ActionEngine!
    @ObservationIgnored private(set) var ledger: TrainingLedger!

    /// What's running (Core's process table): the running process is Now; suspended ones form Home's ledger.
    var processes: ProcessTable {
        _ = revision
        return ProcessTable(engine: engine)
    }

    // MARK: Tess captures (ghost rows)

    /// A capture Tess made that is still wet paint: drawn as a ghost row until committed or dropped.
    private(set) var pendingCapture: OpRecord?
    /// The capture just committed, for the Undo in the Ask Tess bar (about 4 s).
    private(set) var lastCapture: OpRecord?
    /// Every record the last capture committed (one phrase can log several sets); Undo reverts them all.
    @ObservationIgnored private var lastCaptures: [OpRecord] = []
    /// Captured ids, so the delayed timers never touch a record that is gone (a reset context, a discard).
    @ObservationIgnored private var pendingCaptureID: UUID?
    @ObservationIgnored private var lastCaptureID: UUID?

    static let captureDryTime: Double = 2

    /// Proposes a task as a pending op (a ghost). It dries into a normal row after `captureDryTime` unless dropped.
    @discardableResult
    func capture(title: String, startsAt: Date) -> UUID? {
        commitCapture()
        guard let record = try? engine.perform(
            CreateTask(title: title, startsAt: startsAt, minutes: 30), by: .tess, pending: true
        ).record else { return nil }
        pendingCapture = record
        pendingCaptures = [record]
        let id = record.id
        pendingCaptureID = id
        touch()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.captureDryTime))
            if let self, pendingCaptureID == id {
                commitCapture()
            }
        }
        return record.objectIDs.first
    }

    func isGhost(_ objectID: UUID) -> Bool {
        pendingCaptures.contains { $0.objectIDs.contains(objectID) }
    }

    /// Everything Tess just proposed (one phrase can become several actions).
    private(set) var pendingCaptures: [OpRecord] = []

    /// Ask Tess: the grammar or on-device model turns the phrase into pending actions (ghost rows), which dry after
    /// `captureDryTime` unless tapped or dropped. Returns Tess's one line.
    func ask(_ phrase: String) async -> String {
        commitCapture()
        let result = await runtime.tess.capture(phrase, context: TessContext(now: AppClock.now,
                                                                             entry: session?.currentEntry?.id))
        return land(result)
    }

    /// The open set-count ask ("2 × 10: 2 sets, or 2 kg?"), if the last phrase raised one.
    var pendingSetAsk: TessSetCountAsk? {
        (runtime.tess as? TessCaptureEngine)?.pendingAsk
    }

    /// A tap on one of the ask's answers: lands like a capture and returns Tess's line.
    func answer(_ choice: TessSetCountAsk.Choice) -> String {
        guard let engine = runtime.tess as? TessCaptureEngine else { return "" }
        let result = engine.answer(choice, context: TessContext(now: AppClock.now, entry: session?.currentEntry?.id))
        return land(result)
    }

    /// The open dated-lift ask ("Bench 80 × 8 for Monday?"), if the last phrase raised one.
    var pendingDatedLift: TessDatedLiftAsk? {
        (runtime.tess as? TessCaptureEngine)?.pendingDatedLift
    }

    /// LOG or NOT NOW on the dated-lift ask: lands like a capture and returns Tess's line.
    func answer(_ choice: TessDatedLiftAsk.Choice) -> String {
        guard let engine = runtime.tess as? TessCaptureEngine else { return "" }
        let result = engine.answer(choice, context: TessContext(now: AppClock.now, entry: session?.currentEntry?.id))
        return land(result)
    }

    /// Pending records become ghost rows that dry after `captureDryTime`; returns Tess's line.
    private func land(_ result: TessCapture) -> String {
        let pending = result.records.filter { $0.state == .pending }
        if let first = pending.first {
            pendingCaptures = pending
            pendingCapture = first
            let id = first.id
            pendingCaptureID = id
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Self.captureDryTime))
                if let self, pendingCaptureID == id {
                    commitCapture()
                }
            }
        }
        session?.refreshAfterExternalWrite()
        touch()
        return result.line
    }

    /// Tap, or the stroke finishing: the ghost dries into a real row.
    func commitCapture() {
        guard let record = pendingCapture else { return }
        for other in pendingCaptures where other.id != record.id {
            try? engine.commit(other)
        }
        let committed = pendingCaptures.isEmpty ? [record] : pendingCaptures
        pendingCaptures = []
        try? engine.commit(record)
        adoptCapturedSets(committed)
        pendingCapture = nil
        pendingCaptureID = nil
        lastCapture = record
        lastCaptures = committed.contains { $0.id == record.id } ? committed : committed + [record]
        let id = record.id
        lastCaptureID = id
        touch()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            if let self, lastCaptureID == id {
                lastCapture = nil
                lastCaptureID = nil
            }
        }
    }

    /// Swipe the ghost away: nothing is written.
    func discardCapture() {
        guard let record = pendingCapture else { return }
        for other in pendingCaptures.reversed() where other.id != record.id {
            _ = try? engine.discard(other)
        }
        pendingCaptures = []
        _ = try? engine.discard(record)
        pendingCapture = nil
        pendingCaptureID = nil
        touch()
    }

    /// Undo in the Ask Tess bar, through the op log.
    func undoLastCapture() {
        guard let record = lastCapture else { return }
        for other in lastCaptures.reversed() where other.id != record.id {
            engine.undo(other)
        }
        lastCaptures = []
        engine.undo(record)
        lastCapture = nil
        lastCaptureID = nil
        session?.refreshAfterExternalWrite()
        touch()
    }

    /// Tess's one-liners from the last tidy (e.g. a workout wrapped up overnight).
    var processNotes: [String] = []
    /// What UNDO beside those lines takes back: only the empty wrap-up ("Push A, no sets, not saved.") has one.
    var processUndo: OpRecord?

    /// On launch and foreground: suspend a process idle past its rest plus 10 minutes, then apply the stale rules.
    func tidyProcesses(now: Date = AppClock.now) {
        let idleLimit = (session?.restSeconds ?? 180) + 10 * 60
        let table = ProcessTable(engine: engine)
        // While the live cover is up (a long locked rest, cardio) the workout is in use: never suspend it, and if
        // something already did, run it again.
        if isWorkoutPresented {
            if let workout = session?.workout, let process = table.process(for: workout), process.state != .running {
                _ = try? engine.perform(ResumeProcess(process: process.id, time: now), by: .system)
            }
        } else {
            table.suspendIfIdle(now: now, idleLimit: idleLimit)
        }
        let notes = table.tidyNotes(now: now)
        processNotes = notes.map(\.line)
        processUndo = notes.lazy.compactMap(\.undo).first
        // The 04:00 roll: unfinished tasks from earlier days move to today, after 7 rolls to Later (late-night #1).
        if let rolled = TaskList(store: store, classes: classes).rollForward(engine: engine, now: now) {
            processNotes.append(rolled)
        }
        // Tess's memory turnover: yesterday's day line, the 14-day cut, Sunday's noticed lines (AI-7).
        let memory = TessMemoryStore(engine: engine)
        memory.reapplyForgetsIfRestored(now: now) // the first launch after a restore forgets again (QA F2b, F6)
        memory.turnover(now: now)
        pickUpRunningWorkout(table)
        // A workout left untouched for 6 hours is wrapped up by Core; let the live session go with it.
        if let session, store.value("endedAt", of: session.workout) != nil {
            self.session = nil
            isWorkoutPresented = false
        }
        touch()
    }

    /// Resume lands on the process's resume point: for a workout, the live cover at its set with the dial preset.
    func resume(_ process: ProcessSnapshot) {
        _ = try? engine.perform(ResumeProcess(process: process.id, time: AppClock.now), by: .user)
        if let workout = process.subject, workout.classDef?.id == classes[.workout]?.id {
            if session?.workout.id != workout.id {
                session = WorkoutSession(workout: workout, model: self)
            }
            if let point = process.resumePoint {
                session?.apply(point)
            }
            isWorkoutPresented = true
        }
        touch()
    }

    // MARK: Navigation

    enum Relation {
        /// Into a child, subclass or linked object from a tapped row: zooms out of that row.
        case deeper
        /// To an ancestor (breadcrumbs): pops back if it's on the path, otherwise cross-fades in.
        case up
        /// A jump that isn't spatial (search, Tess, links elsewhere): cross-fade.
        case jump
    }

    enum Arrival { case zoom, crossFade }

    func open(_ route: Route, _ relation: Relation = .deeper) {
        // While the workout cover is up, depth stacks inside it, so the process stays in front.
        if isWorkoutPresented {
            workoutPath = navigate(workoutPath, to: route, relation)
        } else {
            path = navigate(path, to: route, relation)
        }
    }

    private func navigate(_ stack: [Route], to route: Route, _ relation: Relation) -> [Route] {
        guard route != stack.last else { return stack }
        var stack = stack
        switch relation {
        case .deeper:
            arrivals[route] = .zoom
            stack.append(route)
        case .jump:
            arrivals[route] = .crossFade
            stack.append(route)
        case .up:
            if let index = stack.firstIndex(of: route) {
                stack.removeSubrange((index + 1)...)
            } else {
                arrivals[route] = .crossFade
                stack.append(route)
            }
        }
        return stack
    }

    func back() {
        if isWorkoutPresented, !workoutPath.isEmpty {
            workoutPath.removeLast()
        } else if !path.isEmpty {
            path.removeLast()
        }
    }

    /// True the first time a page is shown this session (then it's marked as seen).
    func consumeFirstVisit(_ route: Route?) -> Bool {
        let key = route ?? .object(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        return visited.insert(key).inserted
    }

    func title(of route: Route) -> String {
        switch route {
        case let .object(id): object(id)?.title ?? "Object"
        case let .classDef(id): classDef(id: id)?.name ?? "Class"
        case .routines: "Routines"
        }
    }

    func classDef(_ key: SystemCatalog.Key) -> ClassDef? {
        classes[key]
    }

    func touch() {
        try? context.save()
        revision += 1
    }

    // MARK: Lookup

    func object(_ id: UUID) -> ObjectRecord? {
        store.object(id: id)
    }

    func classDef(id: UUID) -> ClassDef? {
        store.classDef(id: id)
    }

    func objects(of key: SystemCatalog.Key) -> [ObjectRecord] {
        guard let classDef = classes[key] else { return [] }
        return (classDef.objects ?? []).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    /// The "profile" object of a class: holds class-level values like Bench Press's muscles and cues.
    func prototype(of classDef: ClassDef) -> ObjectRecord? {
        (classDef.objects ?? []).first { $0.parent == nil && $0.title == classDef.name && !$0.isDeleted }
    }

    // MARK: Today

    /// Derived schedule, rebuilt only when data changes (or the window drifts by a minute) — the
    /// once-a-second UI ticks must stay far under a frame.
    @ObservationIgnored private var scheduleCache: (revision: Int, anchor: Date, items: [ScheduleItem])?
    @ObservationIgnored private var workoutCache: (revision: Int, anchor: Date, workout: ObjectRecord?)?

    func schedule(around now: Date = AppClock.now) -> [ScheduleItem] {
        let revision = revision
        if let cache = scheduleCache, cache.revision == revision, abs(cache.anchor.timeIntervalSince(now)) < 60 {
            return cache.items
        }
        let items = buildSchedule(around: now)
        scheduleCache = (revision, now, items)
        return items
    }

    private func buildSchedule(around now: Date) -> [ScheduleItem] {
        let window = now.addingTimeInterval(-14 * 3600) ... now.addingTimeInterval(12 * 3600)
        var items: [ScheduleItem] = objects(of: .task).compactMap { task in
            guard case let .date(start)? = store.value("startsAt", of: task), window.contains(start) else { return nil }
            let length = store.value("length", of: task)?.numericValue ?? 1800
            let done = store.value("isDone", of: task) == .bool(true)
            return ScheduleItem(id: task.id, title: task.title, start: start, end: start.addingTimeInterval(length),
                                isDone: done, isWorkout: false)
        }
        if let workout = tonightWorkout(around: now),
           case let .date(start)? = store.value("scheduledFor", of: workout)
        {
            items.append(ScheduleItem(id: workout.id, title: workout.title, start: start,
                                      end: start.addingTimeInterval(75 * 60), isDone: false, isWorkout: true))
        }
        return items.sorted { $0.start < $1.start }
    }

    /// The task happening now, else the next one not done.
    func currentTask(around now: Date = AppClock.now) -> ScheduleItem? {
        let items = schedule(around: now).filter { !$0.isWorkout && !$0.isDone }
        return items.first { $0.start <= now && now < $0.end } ?? items.first { $0.start > now }
    }

    func tonightWorkout(around now: Date = AppClock.now) -> ObjectRecord? {
        let revision = revision
        if let cache = workoutCache, cache.revision == revision, abs(cache.anchor.timeIntervalSince(now)) < 60 {
            return cache.workout
        }
        let workout = findTonightWorkout(around: now)
        workoutCache = (revision, now, workout)
        return workout
    }

    private func findTonightWorkout(around now: Date) -> ObjectRecord? {
        objects(of: .workout).first { workout in
            // Scheduled, or started from a routine (no schedule) and not finished: either is today's workout.
            guard let date = store.value("scheduledFor", of: workout)?.dateValue
                ?? store.value("startedAt", of: workout)?.dateValue else { return false }
            // His day, not a ±12 h window (late-night #5): a workout left open last night isn't tonight's.
            return store.value("endedAt", of: workout) == nil && TesseraDay().isSameDay(date, now)
        }
    }

    func finish(taskID: UUID) {
        _ = try? engine.perform(SetTaskDone(task: taskID, done: true), by: .user)
        touch()
    }

    // MARK: Workout

    func startWorkout(_ workout: ObjectRecord) {
        if session?.workout.id != workout.id {
            if store.value("startedAt", of: workout) == nil {
                _ = try? engine.perform(StartWorkout(workout: workout.id, time: AppClock.now), by: .user)
            }
            session = WorkoutSession(workout: workout, model: self)
        }
        isWorkoutPresented = true
        touch()
    }

    func endWorkout() {
        guard let session else { return }
        _ = try? engine.perform(FinishWorkout(workout: session.workout.id, time: AppClock.now), by: .user)
        isWorkoutPresented = false
        self.session = nil
        touch()
    }

    // MARK: Training stats

    struct LoggedSet {
        let weight: Double
        let reps: Double
        let e1RM: Double
    }

    struct SessionSummary: Identifiable {
        let id: UUID
        let workout: ObjectRecord
        let date: Date
        let sets: [LoggedSet]
    }

    /// Completed sessions for an exercise class (and its subclasses), newest first.
    /// Completed sessions for an exercise class (and its subclasses), newest first. Reads Core's training index
    /// (milliseconds even with years of history) instead of walking backlinks.
    func history(of exercise: ClassDef) -> [SessionSummary] {
        _ = revision
        return ledger.sessions(of: exercise).map { session in
            SessionSummary(id: session.id, workout: session.workout, date: session.date,
                           sets: session.sets.map { LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) })
        }
    }

    func bestSet(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> LoggedSet? {
        _ = revision
        return ledger.bestSet(of: exercise, excludingWorkout: excludedID)
            .map { LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) }
    }

    /// Evaluates the Set class's own `e1rm` expression for values that aren't logged yet.
    func previewE1RM(weight: Double, reps: Double) -> Double? {
        guard let setClass = classes[.set], let source = ClassResolver.field("e1rm", of: setClass)?.expression,
              let expression = try? Formula.parse(source) else { return nil }
        return expression.evaluate { ["weight": weight, "reps": reps][$0] }
    }
}

// MARK: - Plan

extension AppModel {
    /// The plan Home trains from: Kaushik's starter PPL×2, else the first plan there is.
    var plan: ObjectRecord? {
        _ = revision
        return store.object(id: StarterContent.planID) ?? objects(of: .plan).first
    }

    /// Today's routine from the plan, when there is no workout object for today yet (nothing scheduled, nothing
    /// running, nothing finished today). The plan rolls: the routine after the last one finished.
    func todaysRoutine(now: Date = AppClock.now) -> ObjectRecord? {
        guard session == nil, tonightWorkout(around: now) == nil, finishedToday(now: now).isEmpty,
              let plan else { return nil }
        return ledger.nextRoutine(in: plan, now: now)
    }

    /// Workouts finished today, newest first (Core's summaries: counts, records and Tess's line).
    func finishedToday(now: Date = AppClock.now) -> [WorkoutSummary] {
        finishedWorkouts(on: now)
    }

    /// Core caches these per store revision.
    func finishedWorkouts(on day: Date) -> [WorkoutSummary] {
        _ = revision
        return ledger.finishedWorkouts(on: day)
    }

    /// A routine with no exercises has nothing to start: no Start word, and no empty "0 kg moved" workout.
    func canStart(_ routine: ObjectRecord) -> Bool {
        routine.orderedChildren.contains { !$0.isDeleted }
    }

    /// Start: today's workout from the routine through the engine (one entry per slot, prefilled), then live mode.
    func startRoutine(_ routine: ObjectRecord) {
        guard canStart(routine), let workout = try? engine.perform(
            StartRoutine(routine: routine.id, time: AppClock.now),
            by: .user
        )
        .output else { return }
        session = WorkoutSession(workout: workout, model: self)
        isWorkoutPresented = true
        touch()
    }

    /// After a relaunch the workout's process is still running but the live session is gone: pick it back up (not
    /// presented), so Now shows it with Resume.
    func pickUpRunningWorkout(_ table: ProcessTable) {
        guard session == nil, let workout = table.running()?.subject,
              workout.classDef?.id == classes[.workout]?.id, store.value("endedAt", of: workout) == nil else { return }
        session = WorkoutSession(workout: workout, model: self)
    }

    /// Sets typed in the Bar ("log bench 80x8") land in the live workout: they seat like a held set. Typed on Home
    /// with nothing running, Core starts a workout; it becomes the running session (Now shows it with Resume).
    func adoptCapturedSets(_ records: [OpRecord]) {
        let logs = records.filter { $0.action == LogExercise.descriptor.name || $0.action == LogSet.descriptor.name }
        guard !logs.isEmpty else { return }
        if session == nil {
            pickUpRunningWorkout(ProcessTable(engine: engine))
        }
        let setClass = classes[.set]?.id
        let ids = logs.flatMap(\.objectIDs).filter { store.object(id: $0)?.classDef?.id == setClass }
        session?.seatCaptured(setIDs: ids)
    }
}

extension SettingsStore {
    /// The pre-settings-object UserDefaults key for "Tess asks Claude". Read only by Core's migrate.
    static let legacyMissesKey = "tess.missesGoToClaude"

    /// Core's migrate, run on every launch, then the old misses key goes: the settings object owns "Tess asks Claude"
    /// from here, so a "no" left in the key can never outvote a later yes on the next launch (QA M1). Idempotent.
    func migrateAtLaunch(looks: UserDefaults, standard: UserDefaults, folderName: String?) {
        guard (try? migrate(looks: looks, standard: standard, folderName: folderName)) != nil else { return }
        standard.removeObject(forKey: Self.legacyMissesKey)
    }
}

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
    /// The Routines landing and its Browse rail (Design 131, behind Review › Landing pages).
    case routinesLanding
    case routinesBrowse
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

    /// For the Sample data model: his own model, whose "Tess asks Claude" choice the sample follows (read only).
    @ObservationIgnored weak var claudeOwner: AppModel?

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
            // Not in Low Power: the plan's words are a nicety, so Claude waits for charge.
            [weak self] in (self?.asksClaude ?? false) && !PowerState.isLowPower
        }
        planWordingStore = wording
        return wording
    }

    @ObservationIgnored private var planWordingStore: ClaudePlanWording?

    /// A demo flag is on: Claude's Home words are never read or written (home-lines-job.md §5).
    static var isDemo: Bool {
        ["-demo", "-resetDemo", "-theme", "-fakeClaudeKey"].contains(where: { LaunchFlags.has($0) })
    }

    @ObservationIgnored private var homeDoneStore: ClaudeHomeDone?
    /// Names training days (Core's DayNamer): one instance; see AppModel+DayNames.swift.
    @ObservationIgnored var dayNamerStore: DayNamer?
    @ObservationIgnored var dayNaming: Task<Void, Never>?
    /// The one rates fetch for the money wheel (a single instance, so its once-an-hour cap holds app-wide); see
    /// AppModel+Measure.swift. `ratesTable` is what the wheel reads: the live table or the last saved one.
    @ObservationIgnored var currencyFetchStore: CurrencyRatesFetch?
    var ratesTable: CurrencyRates?

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
    /// The cook a Live Activity link opened (`tessera://cook?cook=<id>&alert=<food>`): the cooking cover shows it, with
    /// the alert printed when one came with the link.
    struct CookLink: Identifiable, Equatable {
        let id: UUID
        let alert: String?
    }

    var cookLink: CookLink?

    /// The link from the cooking activity: its own cook if the link names one that still runs, else the cook running
    /// now; nothing opens when no cook runs.
    func openCook(from url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let named = items.first { $0.name == "cook" }?.value.flatMap { UUID(uuidString: $0) }
        let running = KitchenFront(model: self, now: AppClock.now).cooking?.id
        guard let id = [named, running].compactMap(\.self).first(where: { store.object(id: $0) != nil }) else { return }
        let alert = items.first { $0.name == "alert" }?.value.flatMap { $0.isEmpty ? nil : $0 }
        cookLink = CookLink(id: id, alert: alert)
    }

    var isWorkoutPresented = false {
        didSet {
            if isWorkoutPresented {
                session?.touch()
                // A launch straight into the live workout (the Live Activity, Resume): his moment wins the wake.
                soul.handle(.liveOpened)
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

    /// "Tess has eyes": the review switch "Tess has eyes" (Off by default; its UserDefaults key is `review.tessFace`),
    /// or the simulator's `-tessEyes` flag (LaunchFlags is simulator-only, so never on the phone).
    var tessHasEyes: Bool {
        LaunchFlags.has("-tessEyes") || Choice.tessHasEyes()
    }

    /// Home (the launcher Tess paints in) vs Today.
    /// Where you were when Tess took you Home; tapping her again goes back.
    var homeReturnPath: [Route]?

    /// `launchDefaults`: where once-per-install launch decisions are kept; the app tests pass a throwaway suite (QA on
    /// #665), so a test run never decides for an install.
    init(context: TesseraContext, launchDefaults: UserDefaults = .standard, seedsStarterLists: Bool = false,
         isSample: Bool = false)
    {
        self.context = context
        self.isSample = isSample
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
        // Her conversation keeps seven days: turns older than that go at launch (and before every write).
        TessConversation(store: store, classes: classes).expire()
        // QA F1: only his real store holds his settings. On a throwaway store (memory fallback, a failed seed) the
        // settings read as empty, which would mean "yes": skip the migrate (it would delete his old "no") and keep
        // Claude off.
        // The sample's store is never his (QA on #1199): no settings migrate, no Claude, no first-launch writes.
        settingsAreReal = !isSample && TesseraSchema.lastOpenOutcome == .opened && classes[.settings] != nil
        // The release that adds the settings object: the old keys move in once, as system (settings-object.md).
        // Never while a demo flag is on, so a demo can't freeze a look into his data.
        let demo = Self.isDemo || isSample
        if !demo, settingsAreReal {
            SettingsStore(engine: engine).migrateAtLaunch(looks: ThemeStore.sharedDefaults, standard: .standard,
                                                          folderName: BackupKeeper.pickedFolder
                                                              .map(BackupCopy.folderName))
            // The first launch with the restWeekday reader: Sunday, as one op with UNDO ("Sunday, rest day.";
            // Research 146). Once; an UNDO or a later "Any" leaves a record, so it is never written twice.
            restReceipt = SettingsStore(engine: engine).writeFirstRestWeekday(defaults: launchDefaults)
            // The three starter lists (Gym bag, Leaving the house, Packing): once each, never put back after a delete.
            // Only the app's own launch asks for them: a test model starts with just the lists it makes.
            if seedsStarterLists {
                _ = try? StarterLists.installIfNeeded(store: store, classes: classes)
            }
        }
        if isSample, seedsStarterLists {
            _ = try? StarterLists.installIfNeeded(store: store, classes: classes)
        }
        PantryPlaces(store: store, classes: classes).ensureDefaults() // Fridge, Freezer, Shelf, Counter, once (118)
        applySettingsProcessWide()
        runtime = TesseraRuntime(engine: engine)
        soul.runScript()
        // A cold launch is a foreground too: told now, so her first frame already has her eyes shut if she wakes.
        soul.handle(.foregrounded(underLive: false))
        // Claude is the last capture step, gated on the one "Tess asks Claude" field, the key and the pause
        // (it checks each at every call). Off in demos, so a fake key never goes over the network. Sample data keeps
        // it (Kaushik, Oct 24): its calls are counted in the sample's own store, never written to his.
        if !Self.isDemo, let capture = runtime.tess as? TessCaptureEngine {
            capture.claude = ClaudeTessModel(
                keys: SystemKeychain(),
                ledger: TessUsageLedger(store: store, classes: classes),
                flags: claudeFlags
            ) { [weak self] in
                self?.asksClaude ?? false
            }
            // Only when a request really leaves the phone: the Ask shows "Asking Claude." with Cancel (batch 3).
            claudeFlags.willSend = { [weak self] in self?.isAskingClaude = true }
            refreshKeyQuestion()
            // What he says to Tess that the phone's grammar missed goes through TessRun and the Door, with the key from
            // the Keychain: her reply, her tools, the ledger and "What was sent". The old Claude capture step now only
            // reads the phrases that waited offline.
            capture.claudeInline = false
            tessLive = TessLive(engine: engine, keys: SystemKeychain(), asksClaude: { [weak self] in
                self?.asksClaude ?? false
            }, folder: TesseraSchema.defaultURL.deletingLastPathComponent())
        }
        // Core's calm note (store couldn't open, legacy migration pending) wins; else this launch's outcome.
        let outcome: String? = switch TesseraSchema.lastOpenOutcome {
        case .opened: nil
        case .recoveredWithBackup: "Started fresh; your old data is saved in Backups"
        case .inMemoryFallback: "Couldn't open your data, so nothing will be saved this time"
        }
        // Both are read, oldest first, one at a time (hunt 28 CALL 3 B); a restore says its copy's date (sheet 111).
        launchNotes = LaunchNoteQueue([TesseraSchema.launchNote.map(RestoreOffer.dated), outcome])
    }

    /// The Sample data model (SampleData): its own in-memory store, nothing written beside his.
    let isSample: Bool

    /// The notes waiting for this launch (LaunchNoteQueue): one shows at a time, never stacked.
    var launchNotes = LaunchNoteQueue()

    /// Claude's flags, kept so Cancel can reach the call in flight.
    @ObservationIgnored let claudeFlags = ClaudeMissFlags()
    /// A capture is on its way to Claude right now: the Ask says "Asking Claude." with Cancel until it answers, fails
    /// or is cancelled (8 s at most, Core's one deadline).
    private(set) var isAskingClaude = false
    /// "Use the Claude key still on this phone?" is due: a key is here and he has never answered (G687).
    private(set) var keyQuestionDue = false
    /// Whether a Claude key is stored: a Bool only, for Tess's status line ("Claude is on" or "No key yet"). The key's
    /// text is never kept.
    private(set) var claudeKeyPresent = false
    /// He said Later, or Now already showed it this launch: Now stays quiet until the next cold launch.
    var keyQuestionQuietOnNow = false

    /// The first launch's "Sunday, rest day." op, shown once in Tess's band with UNDO, then cleared.
    var restReceipt: OpRecord?

    /// Tess's capture engine and the App Intents runtime (Core's TesseraTess / TesseraIntents).
    @ObservationIgnored private(set) var runtime: TesseraRuntime!

    /// Every UI write goes through typed actions, so it lands in the op log with undo (Core engine).
    @ObservationIgnored private(set) var engine: ActionEngine!
    @ObservationIgnored private(set) var ledger: TrainingLedger!

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

    /// Everything Tess just proposed (one phrase can become several actions).
    private(set) var pendingCaptures: [OpRecord] = []

    /// Ask Tess: the grammar or on-device model turns the phrase into pending actions (ghost rows), which dry after
    /// `captureDryTime` unless tapped or dropped. Returns Tess's one line.
    func ask(_ phrase: String) async -> String {
        commitCapture()
        #if DEBUG
            // `-askingClaudeDemo` (simulator only, for recordings): the line shows for 3 s as if a request had left,
            // through the same flag Core's willSend sets. Nothing is sent; no key is involved.
            if LaunchFlags.has("-askingClaudeDemo") {
                isAskingClaude = true
                try? await Task.sleep(for: .seconds(3))
            }
        #endif
        if let routed = routedWrite(phrase) {
            lastAnswerSource = nil
            return routed
        } // Write anywhere (135 part 5)
        var result = await runtime.tess.capture(phrase, context: captureContext())
        // The phone's grammar and model understood nothing: a question or a free sentence goes to Tess herself.
        if let live = tessLive, result.source == .none, result.records.isEmpty, result.asking == nil,
           !result.isRefusal
        {
            // "Asking Claude." shows only when the Door may really send; with Claude off she still answers on the
            // phone.
            isAskingClaude = asksClaude
            result = await live.capture(phrase, screen: nil)
        }
        isAskingClaude = false
        lastAnswerSource = result.source
        return land(result)
    }

    /// Who answered the last Ask: Claude, or the phone's own routes (the grammar, the on-device model; nil for a
    /// routed write). Tess's sheet shows it as one small line under her reply.
    private(set) var lastAnswerSource: TessCapture.Source?

    private var isDrainingWaiting = false

    /// Home's own Tess layer (sheet 215) is on screen: she is the corner Tess there, so the dock's soul steps aside.
    var homeTessLayerActive = false
    /// The pixel doorway (sheets 206 and 211): one for the whole app, drawn over everything at the root.
    let doorway = Doorway()

    /// The live Tess (`TessRun` behind the Door). Nil in a demo, where nothing leaves the phone.
    @ObservationIgnored var tessLive: TessLive?
    /// The view changes Tess's last answer called for (open this, go back), for the shell's navigator to play.
    var tessShellCalls: [TesseraTess.ShellIntent] {
        tessLive?.lastShell ?? []
    }

    /// The open set-count ask ("2 × 10: 2 sets, or 2 kg?"), if the last phrase raised one.
    var pendingSetAsk: TessSetCountAsk? {
        (runtime.tess as? TessCaptureEngine)?.pendingAsk
    }

    /// A tap on one of the ask's answers: lands like a capture and returns Tess's line.
    func answer(_ choice: TessSetCountAsk.Choice) -> String {
        guard let engine = runtime.tess as? TessCaptureEngine else { return "" }
        let result = engine.answer(choice, context: captureContext())
        return land(result)
    }

    /// LOG or NOT NOW on the dated-lift ask: lands like a capture and returns Tess's line.
    func answer(_ choice: TessDatedLiftAsk.Choice) -> String {
        guard let engine = runtime.tess as? TessCaptureEngine else { return "" }
        let result = engine.answer(choice, context: captureContext())
        return land(result)
    }

    /// The last capture asked to keep his words in the Ask for a retry (Core's `TessCapture.keepsWords`).
    private(set) var lastKeepsWords = false

    /// Pending records become ghost rows that dry after `captureDryTime`; returns Tess's line.
    func land(_ result: TessCapture) -> String {
        lastKeepsWords = result.keepsWords
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
        let memory = TessMemoryStore(engine: engine, forgetLogURL: forgetLogURL)
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
    /// Picks a set-aside process back up. While a workout runs the engine refuses anything else, so Tess says
    /// "Workout running." and nothing changes (G56, QA on #792); the line is returned for tests.
    @discardableResult
    func resume(_ process: ProcessSnapshot) -> String? {
        if let refusal = RecipeCopy.startCook({
            try engine.perform(ResumeProcess(process: process.id, time: AppClock.now), by: .user)
        }) {
            TessVoice.shared.say(refusal)
            return refusal
        }
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
        return nil
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
        case .routines, .routinesLanding, .routinesBrowse: "Routines"
        }
    }

    func classDef(_ key: SystemCatalog.Key) -> ClassDef? {
        classes[key]
    }

    /// Saves and redraws. `naming: false` is for the naming pass's own writes, which must not restart the pass.
    func touch(naming: Bool = true) {
        try? context.save()
        revision += 1
        reconcileTimerAlerts()
        if naming {
            nameTrainingDaysSoon()
        }
    }

    /// One local notification per running kitchen timer, kept in step after every change (G217): Stop, Finish and an
    /// UNDO cancel it, so a timer never rings for something he has put down. Off on a throwaway store and in demos.
    @ObservationIgnored private var timerAlertScheduler: SystemTimerAlertScheduler?

    private func reconcileTimerAlerts() {
        guard settingsAreReal, !Self.isDemo else { return }
        let scheduler = timerAlertScheduler ?? SystemTimerAlertScheduler()
        timerAlertScheduler = scheduler
        let alerts = KitchenTimerAlerts(store: store, classes: classes)
        Task { await alerts.reconcile(with: scheduler) }
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
            // Masked at the source: the queue row, its label and hint and the spoken receipts all read this (G274).
            items.append(ScheduleItem(id: workout.id, title: ObjectPrivacy.routineTitle(workout.title, in: store),
                                      start: start,
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
        // "Try today": a ready workout stands in for the Plan's next routine for this day only.
        if let routine = triedRoutine(now: now) {
            return routine
        }
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

// MARK: - Claude in the Ask (same file, so it reaches the private state)

extension AppModel {
    /// On the way to the foreground: the phrases that waited for Claude go through the walls again and are read, each
    /// as its own ghost; a week-old one is deleted. Nothing happens with Claude off or no key, and a phrase that is
    /// still offline stays.
    func drainWaitingPhrases() async {
        // Never while he has a ghost waiting: committing it would be a write he did not tap.
        guard !isDrainingWaiting, pendingCapture == nil, !isWorkoutPresented,
              let engine = runtime.tess as? TessCaptureEngine,
              engine.waitingCount > 0 else { return }
        isDrainingWaiting = true
        defer { isDrainingWaiting = false }
        let read = await engine.readWaiting(context: captureContext())
        isAskingClaude = false
        guard let last = read.last else { return }
        // The first-send notice wins and is never dropped; else a lone phrase keeps its own line, and two or more
        // read together get a count.
        let line = read.first(where: \.isNotice)?.line ?? (read.count == 1 ? last.line : "Offline, \(read.count) read")
        // One landing for the lot, so every drained ghost stays pending together and is seen.
        _ = land(TessCapture(records: read.flatMap(\.records), line: line, source: .claude))
    }

    /// Cancel under "Asking Claude.": Core stops the call and the capture ends with "Cancelled".
    func cancelAskingClaude() {
        claudeFlags.cancelAsking()
        tessLive?.cancel()
    }
}

// MARK: - The found-key question (G687)

extension AppModel {
    /// Whether the question is due now. Key presence is a Bool only: the key's text is read by the Keychain call and
    /// dropped here, never kept, logged or written. Never in a demo or on a throwaway store.
    func refreshKeyQuestion(keys: any TessKeychain = SystemKeychain()) {
        let present = keys.read() != nil
        claudeKeyPresent = present
        keyQuestionDue = !Self.isDemo && settingsAreReal
            && SettingsStore(engine: engine).claudeQuestionDue(keyPresent: present)
    }

    /// His answer: Yes or No writes one op and returns its receipt; Later (nil) writes nothing and quiets Now for
    /// this launch.
    @discardableResult
    func answerKeyQuestion(_ answer: Bool?) -> String? {
        guard let answer else {
            keyQuestionQuietOnNow = true
            return nil
        }
        guard (try? SettingsStore(engine: engine).answerClaudeQuestion(answer)) != nil else {
            return ClaudeKeyQuestionCopy.notSaved
        }
        keyQuestionDue = false
        touch()
        return answer ? ClaudeKeyQuestionCopy.yesReceipt : ClaudeKeyQuestionCopy.noReceipt
    }
}

// MARK: - Launch notes (G694)

extension AppModel {
    /// One calm line in Tess's voice when launch didn't go normally (a failed migration). Shown in the Ask bar.
    /// Letting it go (nil) brings the next waiting note, if any.
    var launchNote: String? {
        get { launchNotes.current }
        set {
            if let newValue {
                launchNotes.enqueue(newValue)
            } else {
                launchNotes.advance()
            }
        }
    }
}

/// Home's done job, kept out of the class body.
extension AppModel {
    /// Home's done job through Claude (board 0al): one instance, so its per-workout cache holds.
    var homeDone: ClaudeHomeDone {
        if let job = homeDoneStore {
            return job
        }
        let job = ClaudeHomeDone(keys: SystemKeychain(), ledger: TessUsageLedger(store: store, classes: classes),
                                 cacheURL: Self.isDemo || isSample ? nil : ClaudeHomeDone.defaultCacheURL)
        {
            [weak self] in self?.asksClaude ?? false
        }
        homeDoneStore = job
        return job
    }

    /// Claude's words for a finished workout's Home slots, or nil: the rules words stand (Kaushik's "Sonnet on
    /// Home", 2:41 PM PT Oct 16). Show the rules line first; a returned slot replaces its rules words.
    func homeDoneWords(for line: HomeLine) async -> HomeDoneWords? {
        guard !Self.isDemo, line.fact.kind == .workout, line.fact.state == .done, let ended = line.fact.endedAt
        else { return nil }
        let label = HomeDonePack.dayLabel(finish: ended, calendar: homeDone.calendar)
        return await homeDone.words(for: line, dayLabel: label, store: store)
    }
}

/// "Tess asks Claude", kept out of the class body.
extension AppModel {
    /// "Tess asks Claude", for misses, Plan my day, Home's done words and day names: the one settings field (On
    /// unless he chose Off), never on a throwaway store and never in a demo (`isDemo`: -demo, -resetDemo, -theme,
    /// -fakeClaudeKey). Sample data is the stamped test world and may ask Claude (Kaushik, Oct 24): it follows his own
    /// stored choice, read from his model and never written.
    var asksClaude: Bool {
        guard !Self.isDemo else { return false }
        let source = isSample ? (claudeOwner ?? self) : self
        guard source.settingsAreReal || source.isSample || TestStoreGate.allowsClaude(source.store)
        else { return false }
        return SettingsStore(engine: source.engine).read().sendsMissesToClaude
    }
}

/// The process table and ghost lookups, kept out of the class body.
extension AppModel {
    /// What's running (Core's process table): the running process is Now; suspended ones form Home's ledger.
    var processes: ProcessTable {
        _ = revision
        return ProcessTable(engine: engine)
    }

    func isGhost(_ objectID: UUID) -> Bool {
        pendingCaptures.contains { $0.objectIDs.contains(objectID) }
    }
}

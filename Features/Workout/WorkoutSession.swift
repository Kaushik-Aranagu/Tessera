import Foundation
import Observation
import TesseraCore

/// A live workout: the "process" running while you train. x = exercises (`currentIndex`, in today's running
/// order), y = sets of the current exercise (done above, the dialled set at eye level, remaining below). Rest lives
/// in the same set block: after a set is seated the weight dial becomes the countdown.
///
/// Every write goes through Core's `ActionEngine` (LogSet, SwapExercise, FinishWorkout), so the op log holds it and
/// undo replays it. Defaults come from Core's `TrainingLedger.nextTarget`; the dial's detents from the exercise's
/// `LoadProfile`.
@MainActor
@Observable
final class WorkoutSession {
    let workout: ObjectRecord
    private unowned let model: AppModel
    private var ledger: TrainingLedger {
        model.ledger
    }

    /// The exercise on screen (x), an index into `entries`.
    private(set) var currentIndex = 0
    /// The dialled set. Opens prefilled (the ledger's next target, else the last set), so most sets need one hold.
    var weight: Double = 20
    var reps: Double = 8
    var rpe: Double?
    /// The effort stop-slider is hidden until you pull up on the reps.
    var isEffortShown = false
    private(set) var restEndsAt: Date?
    private(set) var restTotal: TimeInterval = 0
    /// Increments on every change to the session's shape (a set logged or undone, a swap, a reorder). Drives the
    /// seat animation, haptics and the Live Activity.
    private(set) var loggedCount = 0
    /// Last time you did anything in this process (log, skip, page, open it). Drives suspension.
    private(set) var lastTouchedAt = AppClock.now
    /// Why the dial opened where it did ("Same weight; aim for 8 reps on every set"), from the ledger.
    private(set) var targetReason: String?
    /// The line under the countdown after a rest drag ("+15. Drag again for more.").
    private(set) var restNote: String?
    /// The top-set check, when the first working set ran heavy.
    private(set) var topSetCheck: TopSetCheck?
    /// When the workout was finished (the gather plays; FinishWorkout has been performed).
    private(set) var finishedAt: Date?

    /// Idle this long outside a rest and the workout counts as suspended: it leaves Now for a ledger row on Home.
    static let suspendAfter: TimeInterval = 20 * 60
    /// Without a slot target, a first set at RPE 10 is what counts as running heavy.
    static let defaultTargetRPE = 8.0

    func isSuspended(at now: Date = AppClock.now) -> Bool {
        if case .rest = phase(at: now) {
            return false
        }
        return now.timeIntervalSince(lastTouchedAt) > Self.suspendAfter
    }

    /// Called when you open the live workout again.
    func touch() {
        lastTouchedAt = AppClock.now
    }

    /// The set that was just seated, for the seat / paint-bleed / PR choreography.
    private(set) var lastSeated: Seated?
    /// The last logged set, undoable until the next set is logged. Shares the op log with the Lock Screen.
    private(set) var undoable: Undoable?

    enum Phase: Equatable {
        /// Dialling the next set.
        case set
        /// Resting; the dial counts down.
        case rest(endsAt: Date)
        /// All sets of this exercise are seated: the key pages to the next exercise.
        case exerciseDone
        /// Every exercise is done.
        case workoutDone
    }

    init(workout: ObjectRecord, model: AppModel) {
        self.workout = workout
        self.model = model
        order = workout.orderedChildren.map(\.id)
        currentIndex = entries.firstIndex { loggedSets(of: $0).count < targetSets(of: $0) } ?? 0
        loadDefaults()
    }

    var startedAt: Date {
        if case let .date(date)? = model.store.value("startedAt", of: workout) {
            return date
        }
        return AppClock.now
    }

    // MARK: Running order (x)

    /// Today's order of entries, by id. The plan keeps its own order; this is for this session only.
    private(set) var order: [UUID]

    var entries: [ObjectRecord] {
        _ = loggedCount
        let children = workout.orderedChildren
        let rank = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return children.enumerated()
            .sorted {
                (rank[$0.element.id] ?? order.count + $0.offset) < (rank[$1.element.id] ?? order.count + $1.offset)
            }
            .map(\.element)
    }

    var currentEntry: ObjectRecord? {
        let all = entries
        return all.indices.contains(currentIndex) ? all[currentIndex] : nil
    }

    /// Moves an exercise in today's running order; the one on screen stays on screen.
    func move(entryID: UUID, to index: Int) {
        var ids = entries.map(\.id)
        guard let from = ids.firstIndex(of: entryID) else { return }
        let current = currentEntry?.id
        let target = min(max(index, 0), ids.count - 1)
        guard target != from else { return }
        ids.remove(at: from)
        ids.insert(entryID, at: target)
        order = ids
        if let current, let index = ids.firstIndex(of: current) {
            currentIndex = index
        }
        loggedCount += 1
        lastTouchedAt = AppClock.now
    }

    func exerciseClass(of entry: ObjectRecord) -> ClassDef? {
        model.store.linkedClass("exercise", of: entry)
    }

    var currentExercise: ClassDef? {
        currentEntry.flatMap(exerciseClass(of:))
    }

    func targetSets(of entry: ObjectRecord) -> Int {
        max(Int(model.store.number("targetSets", of: entry) ?? 3) - (skipped[entry.id] ?? 0), 0)
    }

    /// Planned sets skipped this session, per exercise entry (nothing is written for a skipped set).
    private var skipped: [UUID: Int] = [:]

    /// Skips the planned set (e.g. Skip on the Lock Screen once rest is over): the exercise needs one set fewer.
    /// Something outside the live screen wrote to this workout (Tess, an intent): re-read sets and defaults.
    func refreshAfterExternalWrite() {
        loggedCount += 1
    }

    func skipSet() {
        guard let entry = currentEntry, setRows(of: entry).count < targetSets(of: entry) else { return }
        skipped[entry.id, default: 0] += 1
        restEndsAt = nil
        loggedCount += 1
    }

    func targetReps(of entry: ObjectRecord) -> Double {
        model.store.number("targetReps", of: entry) ?? 8
    }

    func targetWeight(of entry: ObjectRecord) -> Double? {
        model.store.number("targetWeight", of: entry)
    }

    /// The slot's RPE target, else 8.
    func targetRPE(of entry: ObjectRecord) -> Double {
        model.store.linkedObjects("slot", of: entry).first.flatMap { model.store.number("targetRPE", of: $0) }
            ?? Self.defaultTargetRPE
    }

    /// "3 × 12" for the running order.
    func scheme(of entry: ObjectRecord) -> String {
        "\(targetSets(of: entry)) × \(Int(targetReps(of: entry)))"
    }

    func loggedSets(of entry: ObjectRecord) -> [AppModel.LoggedSet] {
        setRows(of: entry).map { AppModel.LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) }
    }

    func setRows(of entry: ObjectRecord) -> [SetRow] {
        _ = loggedCount
        return entry.orderedChildren.enumerated().compactMap { index, set in
            guard let weight = model.store.number("weight", of: set), let reps = model.store.number("reps", of: set),
                  let e1RM = model.store.number("e1rm", of: set) else { return nil }
            return SetRow(id: set.id, number: index + 1, weight: weight, reps: reps,
                          rpe: model.store.number("rpe", of: set), e1RM: e1RM)
        }
    }

    func isFinished(_ entry: ObjectRecord) -> Bool {
        setRows(of: entry).count >= targetSets(of: entry)
    }

    /// 1-based number of the set being dialled in the current exercise.
    var currentSetNumber: Int {
        guard let entry = currentEntry else { return 1 }
        return min(setRows(of: entry).count + 1, max(targetSets(of: entry), 1))
    }

    var restSeconds: TimeInterval {
        guard let exercise = currentExercise else { return 120 }
        let slotValue = currentEntry.flatMap { model.store.linkedObjects("slot", of: $0).first }
            .flatMap { model.store.number("restSeconds", of: $0) }
        let prototypeValue = model.prototype(of: exercise).flatMap { model.store.number("restSeconds", of: $0) }
        let inherited = ClassResolver.field("restSeconds", of: exercise)?.defaultValue?.numericValue
        return slotValue ?? prototypeValue ?? inherited ?? 120
    }

    func phase(at now: Date = AppClock.now) -> Phase {
        if let end = restEndsAt, end > now {
            return .rest(endsAt: end)
        }
        if !entries.isEmpty, entries.allSatisfy(isFinished) {
            return .workoutDone
        }
        if let entry = currentEntry, isFinished(entry) {
            return .exerciseDone
        }
        return .set
    }

    /// 1 → 0 across the rest.
    func restFraction(at now: Date = AppClock.now) -> Double? {
        guard let end = restEndsAt, restTotal > 0 else { return nil }
        let remaining = end.timeIntervalSince(now)
        return remaining > 0 ? remaining / restTotal : nil
    }

    // MARK: Stored choices (see the extensions below)

    @ObservationIgnored private var profiles: [UUID: any LoadProfile] = [:]
    @ObservationIgnored private var detentCache: [UUID: [Double]] = [:]
    /// Bests set this session, in order.
    private(set) var bests: [Seated] = []
    /// Today's swaps: entry id → the exercise it replaced.
    private var swaps: [UUID: String] = [:]
    private var presetWeight: [UUID: Double] = [:]
    private var estimated: Set<UUID> = []
}

extension WorkoutSession {
    // MARK: Loads (the dial's detents)

    func loadProfile(of exercise: ClassDef) -> any LoadProfile {
        if let cached = profiles[exercise.id] {
            return cached
        }
        let profile = model.store.loadProfile(for: exercise)
        profiles[exercise.id] = profile
        return profile
    }

    /// Every weight the gym can load for the current exercise, ascending.
    var detents: [Double] {
        guard let exercise = currentExercise else { return Array(stride(from: 0, through: 300, by: 2.5)) }
        if let cached = detentCache[exercise.id] {
            return cached
        }
        let loads = loadProfile(of: exercise).loadable(upTo: 300)
        let detents = loads.isEmpty ? Array(stride(from: 0, through: 300, by: 2.5)) : loads
        detentCache[exercise.id] = detents
        return detents
    }

    /// Plates for one side when the exercise is plate-loaded; nil for dumbbells, stacks and bodyweight.
    var plateLoad: PlateLoad? {
        currentExercise.flatMap { loadProfile(of: $0) as? PlateLoad }
    }

    /// One side's plates for the dialled weight, or nil when the bar can't make it.
    var platesPerSide: [Double]? {
        plateLoad?.plates(for: weight)
    }

    /// When the current exercise was swapped in today: the name it replaced ("Bench Press").
    var swappedFrom: String? {
        currentEntry.flatMap { swaps[$0.id] }
    }

    // MARK: Personal records

    /// Reps of last time's top set for this exercise (the drum's ghost before today's first set).
    var lastTimeReps: Double? {
        guard let exercise = currentExercise,
              let last = ledger.sessions(of: exercise, excludingWorkout: workout.id).first else { return nil }
        return last.sets.max { $0.weight < $1.weight }?.reps
    }

    var previewE1RM: Double? {
        ledger.e1RM(weight: weight, reps: reps, rpe: rpe)
    }

    /// Best set before this workout, for the PR hint.
    var previousBest: AppModel.LoggedSet? {
        currentExercise.flatMap { ledger.bestSet(of: $0, excludingWorkout: workout.id) }
            .map { AppModel.LoggedSet(weight: $0.weight, reps: $0.reps, e1RM: $0.e1RM) }
    }

    /// Best e1RM including sets already logged today, so a second PR has to beat the first.
    private var bestE1RMSoFar: Double? {
        let today = currentEntry.map { setRows(of: $0).map(\.e1RM) } ?? []
        return ([previousBest?.e1RM].compactMap(\.self) + today).max()
    }

    var isPersonalRecord: Bool {
        guard let preview = previewE1RM, let best = bestE1RMSoFar else { return false }
        return preview > best + 0.05
    }

    /// Reps needed at the current weight to beat the previous best e1RM.
    var repsForRecord: Int? {
        currentExercise.flatMap { ledger.repsToBeatBestE1RM(weight: weight, for: $0, excludingWorkout: workout.id) }
    }

    // MARK: Actions

    func adjustWeight(by delta: Double) {
        weight = max(0, min(400, weight + delta))
    }

    /// One loadable step up or down (the dial's one-tap twins).
    func stepWeight(up: Bool) {
        let loads = detents
        if up {
            weight = loads.first { $0 > weight + 0.001 } ?? weight
        } else {
            weight = loads.last { $0 < weight - 0.001 } ?? weight
        }
    }

    func adjustReps(by delta: Double) {
        reps = max(1, min(50, reps + delta))
    }

    /// Hold to log: seats the dialled set, then the dial turns into the rest countdown.
    func logSet(source: SetSource = .hold, by actor: Actor = .user) {
        guard let entry = currentEntry, let exercise = currentExercise else { return }
        let wasRecord = isPersonalRecord
        var records = ledger.recordsBeaten(weight: weight, reps: reps, rpe: rpe, for: exercise,
                                           excludingWorkout: workout.id)
        if wasRecord, !records.contains(.e1RM) {
            records.append(.e1RM)
        } else if !wasRecord {
            records.removeAll { $0 == .e1RM }
        }
        let e1RM = previewE1RM
        guard let result = try? model.engine.perform(
            LogSet(entry: entry.id, weight: weight, reps: reps, rpe: rpe, source: source, unit: Format.unit),
            by: actor
        ) else { return }
        let set = result.output
        undoable = Undoable(record: result.record, entryID: entry.id, setID: set.id, weight: weight, reps: reps,
                            rpe: rpe)
        restTotal = restSeconds
        loggedCount += 1
        lastTouchedAt = AppClock.now
        let number = setRows(of: entry).count
        let seated = Seated(setID: set.id, entryID: entry.id, number: number, records: records, e1RM: e1RM,
                            weight: weight, reps: reps)
        lastSeated = seated
        if !records.isEmpty {
            bests.append(seated)
        }
        restNote = nil
        offerTopSetCheck(entry: entry, number: number)
        rpe = nil
        // The last set of the exercise doesn't need a rest before paging on, but the workout's last does nothing.
        restEndsAt = entries.allSatisfy(isFinished) ? nil : AppClock.now.addingTimeInterval(restTotal)
        model.touch()
    }

    var canUndo: Bool {
        guard let undoable else { return false }
        return undoable.record.state != .undone && finishedAt == nil
    }

    /// Undoes the last logged set through the op log, and puts its numbers back on the dial to fix and re-log.
    func undoLastSet() {
        guard canUndo, let undoable else { return }
        model.engine.undo(undoable.record)
        if let index = entries.firstIndex(where: { $0.id == undoable.entryID }) {
            currentIndex = index
        }
        bests.removeAll { $0.setID == undoable.setID }
        if topSetCheck?.entryID == undoable.entryID, !(topSetCheck?.isAccepted ?? false) {
            topSetCheck = nil
        }
        self.undoable = nil
        restEndsAt = nil
        restNote = nil
        lastSeated = nil
        loggedCount += 1
        weight = undoable.weight
        reps = undoable.reps
        rpe = undoable.rpe
        lastTouchedAt = AppClock.now
        model.touch()
    }

    // MARK: Rest

    func skipRest() {
        guard restEndsAt != nil else { return }
        restEndsAt = nil
        if let entry = currentEntry, !isFinished(entry) {
            restNote = "Skipped. Set \(currentSetNumber) is up."
        } else {
            restNote = "Skipped."
        }
        lastTouchedAt = AppClock.now
    }

    func extendRest(by seconds: TimeInterval) {
        guard let end = restEndsAt else { return }
        restEndsAt = end.addingTimeInterval(seconds)
        restTotal += seconds
        restNote = "+\(Int(seconds)). Drag again for more."
        lastTouchedAt = AppClock.now
    }

    // MARK: Top-set check

    private func offerTopSetCheck(entry: ObjectRecord, number: Int) {
        topSetCheck = nil
        let target = targetSets(of: entry)
        guard number == 1, target > 1, let rpe, rpe >= targetRPE(of: entry) + 2,
              let suggested = suggestedDrop(weight: weight, reps: reps, rpe: rpe, targetRPE: targetRPE(of: entry))
        else { return }
        topSetCheck = TopSetCheck(entryID: entry.id, suggested: suggested, fromSet: 2, toSet: target)
    }

    /// The loadable weight at which these reps land on the target RPE (same e1RM, the honest way), rounded down.
    func suggestedDrop(weight: Double, reps: Double, rpe: Double, targetRPE: Double) -> Double? {
        guard let e1RM = ledger.e1RM(weight: weight, reps: reps, rpe: rpe),
              let perfect = ledger.e1RM(weight: 1, reps: reps, rpe: targetRPE), perfect > 0 else { return nil }
        let ideal = e1RM / perfect
        let drop = detents.last { $0 <= ideal + 0.001 }
        guard let drop, drop < weight - 0.001 else { return nil }
        return drop
    }

    /// One tap: the rest of the exercise re-presets to the suggested weight.
    func acceptTopSetCheck() {
        guard var check = topSetCheck, !check.isAccepted else { return }
        check.isAccepted = true
        topSetCheck = check
        presetWeight[check.entryID] = check.suggested
        if currentEntry?.id == check.entryID {
            weight = check.suggested
        }
        lastTouchedAt = AppClock.now
    }

    // MARK: Swap

    /// The dial holds a converted load nobody has lifted yet (until the swapped exercise's first set).
    var isEstimatedLoad: Bool {
        guard let entry = currentEntry, estimated.contains(entry.id) else { return false }
        return setRows(of: entry).isEmpty
    }

    func swapOptions() -> [ExerciseSwaps.Option] {
        guard let exercise = currentExercise else { return [] }
        return ExerciseSwaps(store: model.store, ledger: ledger)
            .options(for: exercise, from: weight, excludingWorkout: workout.id)
    }

    /// Swaps the current exercise for today only, through the engine. The slot and scheme stay.
    func swap(to option: ExerciseSwaps.Option) {
        guard let entry = currentEntry, let from = currentExercise else { return }
        guard let result = try? model.engine.perform(
            SwapExercise(entry: entry.id, exercise: option.exercise.id, targetWeight: option.load), by: .user
        ) else { return }
        let swappedID = result.output
        if swappedID != entry.id, let index = order.firstIndex(of: entry.id) {
            order.removeAll { $0 == swappedID }
            order.insert(swappedID, at: index + 1)
        }
        swaps[swappedID] = swaps[entry.id] ?? from.name
        presetWeight[swappedID] = option.load
        if option.isEstimate, option.load != nil {
            estimated.insert(swappedID)
        }
        if topSetCheck?.entryID == entry.id {
            topSetCheck = nil
        }
        loggedCount += 1
        currentIndex = entries.firstIndex { $0.id == swappedID } ?? currentIndex
        loadDefaults()
        if let load = option.load {
            weight = loadProfile(of: option.exercise).nearest(to: load)
        }
        lastTouchedAt = AppClock.now
        model.touch()
    }

    // MARK: Paging

    func select(entryAt index: Int) {
        guard entries.indices.contains(index), index != currentIndex else { return }
        currentIndex = index
        lastSeated = nil
        lastTouchedAt = AppClock.now
        loadDefaults()
    }

    var nextEntryIndex: Int? {
        let next = currentIndex + 1
        return entries.indices.contains(next) ? next : nil
    }

    /// The first exercise after the current one that still has sets to do.
    var nextUnfinishedIndex: Int? {
        let all = entries
        let order = Array(all.indices.dropFirst(currentIndex + 1)) + Array(all.indices.prefix(currentIndex))
        return order.first { !isFinished(all[$0]) }
    }

    // MARK: Finish

    /// Hold to finish: ends the workout through the engine. The view then plays the gather.
    func finish() {
        guard finishedAt == nil else { return }
        let now = AppClock.now
        _ = try? model.engine.perform(FinishWorkout(workout: workout.id, time: now), by: .user)
        finishedAt = now
        restEndsAt = nil
        undoable = nil
        loggedCount += 1
        model.touch()
    }

    // MARK: Defaults

    /// Prefill: the weight Tess re-preset (top-set check, swap), else the last set today, else the ledger's next
    /// target (the progression rule, else last time), else the entry's planned target. Always on a loadable detent.
    private func loadDefaults() {
        guard let entry = currentEntry else { return }
        let last = setRows(of: entry).last
        let target = currentExercise.map { exercise in
            ledger.nextTarget(for: exercise, slot: model.store.linkedObjects("slot", of: entry).first,
                              excludingWorkout: workout.id)
        }
        let hasHistory = target?.weight != nil
        targetReason = hasHistory ? target?.reason : nil
        let prefill = target?.weight ?? targetWeight(of: entry)
        let raw = presetWeight[entry.id] ?? last?.weight ?? prefill
        if let raw, let exercise = currentExercise {
            weight = loadProfile(of: exercise).nearest(to: raw)
        } else {
            weight = raw ?? detents.first ?? 20
        }
        if let last {
            reps = last.reps
        } else if hasHistory, let target {
            reps = Double(target.reps)
        } else {
            reps = model.store.number("targetReps", of: entry) ?? Double(target?.reps ?? 8)
        }
        rpe = nil
    }
}

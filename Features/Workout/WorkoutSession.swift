import Foundation
import Observation
import TesseraCore

/// A live workout: the "process" running while you train. x = exercises (`currentIndex`, in today's running
/// order), y = sets of the current exercise (done above, the dialled set at eye level, remaining below). Rest lives
/// in the same set block: after a set is seated the weight dial becomes the countdown.
///
/// Every write goes through Core's `ActionEngine` (LogSet, LogNextSet, EditSet, SwapEntryExercise, FinishWorkout), so
/// the op log holds it and
/// undo replays it. Defaults come from Core's `TrainingLedger.prefill`; the dial's detents from the exercise's
/// `WeightDial`.
@MainActor
@Observable
final class WorkoutSession {
    let workout: ObjectRecord
    unowned let model: AppModel
    var ledger: TrainingLedger {
        model.ledger
    }

    /// The exercise on screen (x), an index into `entries`.
    private(set) var currentIndex = 0
    /// The dialled set. Opens prefilled (Core's `ledger.prefill`: last time's set), so most sets need one hold.
    var weight: Double = 20
    var reps: Double = 8
    var rpe: Double?
    /// The routine's title as the room may see it: "Private workout" when the title is private (the wall follows
    /// what the room can see, so the Done hero, UNDO line, Live Activity and context line all use this).
    var shownTitle: String {
        ObjectPrivacy.routineTitle(workout.title, in: model.store)
    }

    /// Whether the routine's title is private (the room sees "Private workout" in its place).
    var isPrivate: Bool {
        shownTitle != workout.title
    }

    /// The effort stop-slider is hidden until you pull up on the reps.
    var isEffortShown = false
    private(set) var restEndsAt: Date?
    /// The set a restored rest follows (a relaunch mid-rest has no seated set of its own).
    var restAfterSetID: UUID?
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
    var lastSeated: Seated?
    /// The last logged set, undoable until the next set is logged. Shares the op log with the Lock Screen.
    var undoable: Undoable?
    /// LOG … AND FINISH: the finish and the set it came with, taken back together for 10 s ("Push A, back on.").
    private(set) var finishedWithSet: (finish: OpRecord, set: Undoable, at: Date)?

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
        // A relaunch mid-rest: the countdown carries on from the process's resume point (see +Rest).
        if let rest = Self.savedRest(for: workout, model: model) {
            restEndsAt = rest.endsAt
            restTotal = rest.total
            restAfterSetID = rest.afterSet
        }
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

    // MARK: Busy (Design 128)

    /// Exercises marked busy today (a machine taken): they go to the end of the order and come round again.
    private(set) var busy: Set<UUID> = []

    /// What "Busy" moved and where it was, for the receipt's Undo.
    struct BusyReceipt {
        let name: String
        let entryID: UUID
        let previousOrder: [UUID]
        let previousIndex: Int
    }

    var currentIsBusy: Bool {
        currentEntry.map { busy.contains($0.id) } ?? false
    }

    /// The exercise classes marked busy, so a list can fade them.
    var busyExerciseIDs: Set<UUID> {
        Set(entries.filter { busy.contains($0.id) }.compactMap { exerciseClass(of: $0)?.id })
    }

    /// Whether any other exercise still has sets to do (Busy has somewhere to go).
    var hasOtherUnfinished: Bool {
        guard let current = currentEntry else { return false }
        return entries.contains { $0.id != current.id && !isFinished($0) }
    }

    /// "Busy": the exercise moves to the end of today's order and the next one slides up. Nil when there is nothing
    /// to slide up (the page then offers Similar).
    func markBusy() -> BusyReceipt? {
        guard finishedAt == nil, let entry = currentEntry, let exercise = currentExercise, !isFinished(entry),
              !busy.contains(entry.id), hasOtherUnfinished else { return nil }
        endEditing()
        let before = entries.map(\.id)
        let index = currentIndex
        busy.insert(entry.id)
        var ids = before
        ids.remove(at: index)
        ids.append(entry.id)
        order = ids
        currentIndex = min(index, ids.count - 1)
        lastSeated = nil
        loggedCount += 1
        loadDefaults()
        return BusyReceipt(name: exercise.name, entryID: entry.id, previousOrder: before, previousIndex: index)
    }

    /// Takes "Busy" back: the order and the exercise on screen are as they were.
    func undoBusy(_ receipt: BusyReceipt) {
        busy.remove(receipt.entryID)
        order = receipt.previousOrder
        currentIndex = receipt.previousIndex
        lastSeated = nil
        loggedCount += 1
        loadDefaults()
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
        dropWhatHungOnGoneSets()
        loggedCount += 1
    }

    /// A set taken back from outside (Siri, the Lock Screen, Tess) takes its rest, Undo and best with it.
    private func dropWhatHungOnGoneSets() {
        let gone = { (id: UUID) in self.model.store.object(id: id).map(\.isDeleted) ?? true }
        var changed = false
        if let seated = lastSeated, gone(seated.setID) {
            if restEndsAt != nil {
                endRest()
            }
            lastSeated = nil
            changed = true
        }
        if let undoable, gone(undoable.setID) {
            self.undoable = nil
            changed = true
        }
        let before = bests.count
        bests.removeAll { gone($0.setID) }
        if changed || bests.count != before {
            persistRest()
        }
    }

    func skipSet() {
        guard let entry = currentEntry, setRows(of: entry).count < targetSets(of: entry) else { return }
        skipped[entry.id, default: 0] += 1
        restEndsAt = nil
        loggedCount += 1
        persistRest()
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

    /// This set's place last session: "last time 82.5 × 8".
    func lastTime(setNumber: Int) -> (weight: Double, reps: Double)? {
        guard let entry = currentEntry, let exercise = exerciseClass(of: entry) else { return nil }
        let sets = model.ledger.sessions(of: exercise, excludingWorkout: workout.id).first?.sets ?? []
        guard !sets.isEmpty else { return nil }
        let set = sets[min(setNumber - 1, sets.count - 1)]
        return (set.weight, set.reps)
    }

    /// The set on the dial is the workout's last: every other exercise is done and this is its final set.
    var isLastSetOfWorkout: Bool {
        guard let entry = currentEntry else { return false }
        let others = entries.filter { $0.id != entry.id }
        return others.allSatisfy(isFinished) && setRows(of: entry).count + 1 >= targetSets(of: entry)
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

    @ObservationIgnored private var dials: [UUID: TesseraCore.WeightDial] = [:]
    /// Bests set this session, in order.
    var bests: [Seated] = []
    /// Today's swaps: entry id → the exercise it replaced.
    private var swaps: [UUID: String] = [:]
    private var presetWeight: [UUID: Double] = [:]
    private var estimated: Set<UUID> = []
    /// What Core prefilled the current set with.
    private(set) var prefill: SetPrefill?
    /// The logged set being changed on the dial and drum (tap its stroke); nil when dialling the next set.
    var editingSetID: UUID?
    /// Tess's line after an edit or its undo ("Changed set 2 to 85 × 6.").
    var editNote: String?
    /// The next set's numbers, put back when the edit ends.
    var editStash: (weight: Double, reps: Double, rpe: Double?)?
    /// The last edit, undoable until the next action.
    var lastEdit: (record: OpRecord, number: Int)?
}

extension WorkoutSession {
    // MARK: Loads (Core's weight dial: detents, snap, steps, plates per side)

    func weightDial(of exercise: ClassDef) -> TesseraCore.WeightDial {
        if let cached = dials[exercise.id] {
            return cached
        }
        let dial = model.store.weightDial(for: exercise)
        dials[exercise.id] = dial
        return dial
    }

    /// The current exercise's dial; nil before there is one.
    var dial: TesseraCore.WeightDial? {
        currentExercise.map(weightDial(of:))
    }

    /// Every weight the gym can load for the current exercise, ascending.
    var detents: [Double] {
        guard let detents = dial?.detents, !detents.isEmpty else {
            return Array(stride(from: 0, through: 300, by: 2.5))
        }
        return detents
    }

    /// One side's plates for the dialled weight; nil for dumbbells, stacks, bodyweight, or a load the bar can't make.
    var platesPerSide: [Double]? {
        dial?.platesPerSide(weight)
    }

    /// "25 + 5 + 1.25", "bar", or nil when the lift isn't plate-loaded.
    var plateLine: String? {
        dial?.plateLine(weight)
    }

    /// Spoken with the weight: "80 kilograms, 30 per side".
    var spokenLoad: String {
        let base = "\(Format.kilograms(weight)) kilograms"
        guard let plates = platesPerSide else { return base }
        return plates.isEmpty ? "\(base), bar only" : "\(base), \(Format.kilograms(plates.reduce(0, +))) per side"
    }

    /// When the current exercise was swapped in today: the name it replaced ("Bench Press").
    var swappedFrom: String? {
        currentEntry.flatMap { swaps[$0.id] }
    }

    // MARK: Actions

    func adjustWeight(by delta: Double) {
        weight = max(0, min(400, weight + delta))
    }

    func adjustReps(by delta: Double) {
        reps = max(1, min(50, reps + delta))
    }

    /// Hold to log: seats the dialled set, then the dial turns into the rest countdown.
    func logSet(source: SetSource = .hold, by actor: Actor = .user) {
        guard let entry = currentEntry, let exercise = currentExercise else { return }
        let beaten = ledger.recordsBeaten(weight: weight, reps: reps, rpe: rpe, for: exercise,
                                          excludingWorkout: workout.id)
        let e1RM = previewE1RM
        // One hold on an untouched prefill is Core's LogNextSet (the same action as the Lock Screen's Done).
        let performed: (output: ObjectRecord, record: OpRecord)? = if isAtPrefill, presetWeight[entry.id] == nil {
            (try? model.engine.perform(LogNextSet(entry: entry.id, source: source), by: actor))
                .map { ($0.output, $0.record) }
        } else {
            (try? model.engine.perform(
                LogSet(entry: entry.id, weight: weight, reps: reps, rpe: rpe, source: source, unit: Format.unit),
                by: actor
            )).map { ($0.output, $0.record) }
        }
        guard let result = performed else { return }
        lastEdit = nil
        editNote = nil
        let set = result.output
        // One celebration per exercise per session (Core decides); later records still count, quietly.
        let records = ledger.shouldCelebrate(set) ? beaten : []
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
        restEndsAt = nextRestEnd(finished: entries.allSatisfy(isFinished))
        persistRest()
        model.touch()
        // The next set opens prefilled: this session's weight, last time's reps for that set.
        loadDefaults()
    }

    /// When the rest after a set ends: never after the workout's last set, and never with the Rest timer switch Off
    /// (a flip mid-workout takes effect at the next set; Product's default is On).
    private func nextRestEnd(finished: Bool) -> Date? {
        finished || !Choice.restTimerIsOn() ? nil : AppClock.now.addingTimeInterval(restTotal)
    }

    /// Sets logged from outside the live screen (typed in the Bar, Tess) seat like a held set once they dry: the
    /// stroke paints in, the dial becomes the rest, and the next set opens prefilled.
    func seatCaptured(setIDs: [UUID]) {
        // The typed set is now the latest action: the live Undo must not reach back to an earlier held set.
        endEditing()
        undoable = nil
        lastEdit = nil
        editNote = nil
        let all = entries
        guard let (entry, row) = all.lazy.compactMap({ entry in
            self.setRows(of: entry).last { setIDs.contains($0.id) }.map { (entry, $0) }
        }).last else { return refreshAfterExternalWrite() }
        if let index = all.firstIndex(where: { $0.id == entry.id }), index != currentIndex {
            currentIndex = index
        }
        lastSeated = Seated(setID: row.id, entryID: entry.id, number: row.number, records: [], e1RM: row.e1RM,
                            weight: row.weight, reps: row.reps)
        restTotal = restSeconds
        restEndsAt = nextRestEnd(finished: all.allSatisfy(isFinished))
        persistRest()
        lastTouchedAt = AppClock.now
        loggedCount += 1
        loadDefaults()
    }

    /// The 10 s after LOG … AND FINISH.
    func canTakeBackFinish(at now: Date = AppClock.now) -> Bool {
        guard let finishedWithSet else { return false }
        return now.timeIntervalSince(finishedWithSet.at) < 10
    }

    /// Takes back the finish and its set together: the workout runs again with the set's numbers on the dial.
    func takeBackFinish() {
        guard canTakeBackFinish(), let finishedWithSet else { return }
        model.engine.undo(finishedWithSet.finish)
        self.finishedWithSet = nil
        finishedAt = nil
        undoable = finishedWithSet.set
        undoLastSet()
        model.touch()
    }

    var canUndo: Bool {
        guard let undoable else { return false }
        return undoable.record.state != .undone && finishedAt == nil
    }

    /// Undoes the last logged set through the op log, and puts its numbers back on the dial to fix and re-log.
    func undoLastSet() {
        guard canUndo, let undoable else { return }
        endEditing()
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
        persistRest()
        model.touch()
    }

    // MARK: Rest

    /// Ends the rest without a skip note (its set was taken back).
    func endRest() {
        restAfterSetID = nil
        restEndsAt = nil
        restNote = nil
    }

    func skipRest() {
        guard restEndsAt != nil else { return }
        restEndsAt = nil
        if let entry = currentEntry, !isFinished(entry) {
            restNote = "Rest skipped. Set \(currentSetNumber) is up."
        } else {
            restNote = "Rest skipped."
        }
        lastTouchedAt = AppClock.now
        persistRest()
    }

    func extendRest(by seconds: TimeInterval) {
        guard let end = restEndsAt else { return }
        restEndsAt = end.addingTimeInterval(seconds)
        restTotal += seconds
        restNote = "+\(Int(seconds)). Drag again for more."
        lastTouchedAt = AppClock.now
        persistRest()
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

    /// Swaps the current exercise for today only, through the engine. The slot and scheme stay. Returns the op, which
    /// the easy swap hands to its UNDO.
    @discardableResult
    func swap(to option: ExerciseSwaps.Option) -> OpRecord? {
        endEditing()
        guard let entry = currentEntry, let from = currentExercise else { return nil }
        guard let result = try? model.engine.perform(
            SwapEntryExercise(entry: entry.id, exercise: option.exercise.id, targetWeight: option.load), by: .user
        ) else { return nil }
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
            weight = weightDial(of: option.exercise).snap(load)
        }
        lastTouchedAt = AppClock.now
        // The swap moves the resume point on; a rest that was running keeps running after a relaunch.
        persistRest()
        model.touch()
        return result.record
    }

    /// Takes a swap back (the easy swap's UNDO): the engine undoes it and the live screen re-reads its entries.
    func undoSwap(_ record: OpRecord) {
        _ = model.engine.undo(record)
        refreshAfterExternalWrite()
        loadDefaults()
        model.touch()
    }

    // MARK: Paging

    func select(entryAt index: Int) {
        guard entries.indices.contains(index), index != currentIndex else { return }
        editingSetID = nil
        editStash = nil
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
    /// Early (from the running order): Core's FinishWorkoutEarly marks the unstarted exercises skipped, one undo.
    func finish(early: Bool = false, withSet: Bool = false) {
        guard finishedAt == nil else { return }
        endEditing()
        let now = AppClock.now
        let record: OpRecord? = if early, !entries.allSatisfy(isFinished) {
            try? model.engine.perform(FinishWorkoutEarly(workout: workout.id, time: now), by: .user).record
        } else {
            try? model.engine.perform(FinishWorkout(workout: workout.id, time: now), by: .user).record
        }
        if withSet, let record, let undoable {
            finishedWithSet = (record, undoable, now)
        }
        finishedAt = now
        restEndsAt = nil
        undoable = nil
        loggedCount += 1
        model.touch()
    }

    // MARK: Defaults

    /// Prefill (Core's `ledger.prefill`): set 1 opens at last time's set 1, later sets keep this session's weight with
    /// last time's reps for that position, a first-ever session opens at the slot's target. A weight Tess re-preset
    /// (top-set check, swap) wins. Always on a loadable detent; with no weight at all, the lightest load.
    private func loadDefaults() {
        guard let entry = currentEntry else { return }
        let prefill = ledger.prefill(for: entry)
        self.prefill = prefill
        targetReason = Self.reason(for: prefill)
        // Core prefills a light first-session weight too (StartRoutine, store.startingWeight); bands have none.
        if let raw = presetWeight[entry.id] ?? prefill.weight, let exercise = currentExercise {
            weight = weightDial(of: exercise).snap(raw)
        } else {
            weight = 0
        }
        reps = Double(prefill.reps)
        rpe = nil
    }
}

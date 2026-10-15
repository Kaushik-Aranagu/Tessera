import Foundation
import Observation
import TesseraCore

/// A live workout: the "process" running while you train. x = exercises (`currentIndex`), y = sets of the current
/// exercise (done above, the dialled set at eye level, remaining below). Rest lives in the same set block: after a set
/// is seated the weight dial becomes the countdown. Reads targets and rest through the object model (rest comes from
/// the exercise class's inherited `restSeconds`, e.g. 3:00 for any barbell lift).
@MainActor
@Observable
final class WorkoutSession {
    let workout: ObjectRecord
    private unowned let model: AppModel
    private var ledger: TrainingLedger {
        model.ledger
    }

    /// The exercise on screen (x).
    private(set) var currentIndex = 0
    /// The dialled set. Opens on last set's values (or the target), so most sets need one hold.
    var weight: Double = 20
    var reps: Double = 8
    var rpe: Double?
    private(set) var restEndsAt: Date?
    private(set) var restTotal: TimeInterval = 0
    /// Increments on every logged set (drives the seat animation + haptics).
    private(set) var loggedCount = 0
    /// Last time you did anything in this process (log, skip, page, open it). Drives suspension.
    private(set) var lastTouchedAt = AppClock.now

    /// Idle this long outside a rest and the workout counts as suspended: it leaves Now for a ledger row on Home.
    static let suspendAfter: TimeInterval = 20 * 60

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

    struct Seated: Equatable {
        let setID: UUID
        let entryID: UUID
        /// 1-based number of the set within its exercise.
        let number: Int
        let records: [TrainingLedger.RecordKind]
        let e1RM: Double?
    }

    /// One row of the sets stack.
    struct SetRow: Identifiable, Equatable {
        let id: UUID
        let number: Int
        let weight: Double
        let reps: Double
        let rpe: Double?
        let e1RM: Double
    }

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
        currentIndex = entries.firstIndex { loggedSets(of: $0).count < targetSets(of: $0) } ?? 0
        loadDefaults()
    }

    var startedAt: Date {
        if case let .date(date)? = model.store.value("startedAt", of: workout) {
            return date
        }
        return AppClock.now
    }

    var entries: [ObjectRecord] {
        _ = loggedCount
        return workout.orderedChildren
    }

    var currentEntry: ObjectRecord? {
        entries.indices.contains(currentIndex) ? entries[currentIndex] : nil
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
        let prototypeValue = model.prototype(of: exercise).flatMap { model.store.number("restSeconds", of: $0) }
        let inherited = ClassResolver.field("restSeconds", of: exercise)?.defaultValue?.numericValue
        return prototypeValue ?? inherited ?? 120
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

    // MARK: Personal records

    var previewE1RM: Double? {
        ledger.e1RM(weight: weight, reps: reps)
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

    func adjustReps(by delta: Double) {
        reps = max(1, min(50, reps + delta))
    }

    /// Hold to log: seats the dialled set, then the dial turns into the rest countdown.
    func logSet(source: SetSource = .hold, by actor: Actor = .user) {
        guard let entry = currentEntry, let exercise = currentExercise else { return }
        let wasRecord = isPersonalRecord
        var records = ledger.recordsBeaten(weight: weight, reps: reps, for: exercise, excludingWorkout: workout.id)
        if wasRecord, !records.contains(.e1RM) {
            records.append(.e1RM)
        } else if !wasRecord {
            records.removeAll { $0 == .e1RM }
        }
        let e1RM = previewE1RM
        guard let set = try? model.engine.perform(
            LogSet(entry: entry.id, weight: weight, reps: reps, rpe: rpe, source: source), by: actor
        ).output else { return }
        restTotal = restSeconds
        loggedCount += 1
        lastTouchedAt = AppClock.now
        lastSeated = Seated(setID: set.id, entryID: entry.id, number: setRows(of: entry).count, records: records,
                            e1RM: e1RM)
        // The last set of the exercise doesn't need a rest before paging on, but the workout's last does nothing.
        restEndsAt = entries.allSatisfy(isFinished) ? nil : AppClock.now.addingTimeInterval(restTotal)
        model.touch()
    }

    func skipRest() {
        restEndsAt = nil
    }

    func extendRest(by seconds: TimeInterval) {
        guard let end = restEndsAt else { return }
        restEndsAt = end.addingTimeInterval(seconds)
        restTotal += seconds
    }

    /// Removes the most recent set of the current exercise (undo).
    func undoLastSet() {
        guard let entry = currentEntry, let last = entry.orderedChildren.last else { return }
        model.store.softDelete(last)
        restEndsAt = nil
        lastSeated = nil
        loggedCount += 1
        loadDefaults()
        model.touch()
    }

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
        let order = Array(entries.indices.dropFirst(currentIndex + 1)) + Array(entries.indices.prefix(currentIndex))
        return order.first { !isFinished(entries[$0]) }
    }

    private func loadDefaults() {
        guard let entry = currentEntry else { return }
        let last = setRows(of: entry).last
        weight = last?.weight ?? targetWeight(of: entry) ?? 20
        reps = last?.reps ?? targetReps(of: entry)
        rpe = nil
    }
}

import Foundation
import TesseraCore

/// The workout mode's state (sheets 321, 324, 325), a plain value with no views and no store: the lifts, the sets
/// done, the phase and the rest's end date. Every time-dependent answer takes `now`, and the rest is an end date,
/// never a ticking counter, so it survives the lock screen. Weights are in the display unit (lb or kg).
struct WorkoutModeState: Equatable {
    // MARK: Types

    /// How the lift is loaded: the bar and plates, or a stack with a pin (cable and machine lifts).
    enum Equipment: Equatable, Sendable {
        case barbell
        case stack
    }

    enum Felt: String, CaseIterable, Equatable, Sendable {
        case easy, right, hard

        var word: String {
            switch self {
            case .easy: "Easy"
            case .right: "Right"
            case .hard: "Hard"
            }
        }

        /// Easy adds a step to the sets left, Hard takes one off, Right leaves them.
        var direction: Double {
            switch self {
            case .easy: 1
            case .right: 0
            case .hard: -1
            }
        }
    }

    struct Done: Equatable, Sendable {
        var weight: Double
        var reps: Int
        var felt: Felt?
        var at: Date
    }

    struct PlannedSet: Equatable, Sendable {
        var weight: Double
        var reps: Int
        var done: Done?
    }

    /// What the ledger remembers of this lift (resolved up front through `ModeHistory`; display unit).
    struct LiftHistory: Equatable, Sendable {
        struct Set: Equatable, Sendable {
            var weight: Double
            var reps: Int
        }

        var lastTime: [Set] = []
        var best: Set?
        var bestDate: Date?
        /// The best estimated max in the ledger, if any.
        var bestEstimate: Double?
    }

    struct Lift: Identifiable, Equatable, Sendable {
        let id: String
        var name: String
        var equipment: Equipment = .barbell
        var restSeconds: Int
        var sets: [PlannedSet]
        var history = LiftHistory()
        var isWarmUp = false
        /// The timed warm-up this lift stands for: minutes, no weight or reps.
        var warmUp: WarmUpPlan?

        var setsLeft: Int {
            sets.count { $0.done == nil }
        }

        var isComplete: Bool {
            setsLeft == 0
        }

        var nextIndex: Int? {
            sets.firstIndex { $0.done == nil }
        }
    }

    enum Phase: Equatable {
        /// On a set; dragging changes its weight.
        case set
        /// Resting after a logged set of `lift`; `endsAt` is the end date.
        case rest(endsAt: Date, total: TimeInterval, lift: Int)
        /// Every lift is done.
        case done
    }

    /// What the Felt control or Lighter did, for the receipt line.
    struct Receipt: Equatable {
        var text: String
        var setsChanged: Int
    }

    // MARK: Values

    var title: String
    /// A private workout: the title is "Private workout" and nothing about the lifts leaves the app.
    var isPrivate = false
    var unit: MassUnit
    var inventory: PlateInventory
    var startedAt: Date
    var lifts: [Lift]
    /// The lift on screen and the one the dial picked.
    var focus = 0
    var phase: Phase = .set {
        didSet { trackRestBaseline(from: oldValue) }
    }

    /// The weights of the resting lift's sets as the rest began, so Felt is always measured from them (sheet 345):
    /// Easy then Hard then Right gives +5, then -5, then 0 against the start of the rest, never a running total.
    /// Cleared when the rest ends.
    private(set) var restBaseline: [Double]?
    private(set) var finishedAt: Date?
    /// The last logged set, takeable back for ten seconds.
    private(set) var undoable: (lift: Int, set: Int, at: Date)?
    /// Typical seconds a set takes (the clock's estimate until real sets say otherwise).
    var setSeconds: Double = 40

    static let undoWindow: TimeInterval = 10
    static let lighterSteps = 2

    init(title: String, unit: MassUnit, startedAt: Date, lifts: [Lift], inventory: PlateInventory? = nil) {
        self.title = title
        self.unit = unit
        self.inventory = inventory ?? .standard(for: unit)
        self.startedAt = startedAt
        self.lifts = lifts
        focus = lifts.firstIndex { !$0.isComplete } ?? 0
        if lifts.allSatisfy(\.isComplete) {
            phase = .done
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title && lhs.unit == rhs.unit && lhs.lifts == rhs.lifts && lhs.focus == rhs.focus
            && lhs.phase == rhs.phase && lhs.startedAt == rhs.startedAt && lhs.finishedAt == rhs.finishedAt
    }

    var step: Double {
        inventory.step
    }

    var current: Lift {
        lifts[focus]
    }

    /// The set the focused lift is on, if it has one left.
    var currentSet: PlannedSet? {
        current.nextIndex.map { current.sets[$0] }
    }

    var setsDone: Int {
        lifts.reduce(0) { $0 + $1.sets.count { $0.done != nil } }
    }

    var liftsLeft: Int {
        lifts.count { !$0.isComplete }
    }

    var isDone: Bool {
        phase == .done
    }

    /// Weight lifted so far, in the display unit.
    var volume: Double {
        lifts.flatMap(\.sets).compactMap(\.done).reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    // MARK: Moves

    /// The dial picks the lift to do next.
    /// During a rest it only queues the lift (it takes effect when the rest ends, through the auto-turn).
    mutating func select(lift index: Int) {
        guard lifts.indices.contains(index), !isDone else { return }
        if case .rest = phase {
            queuedFocus = index
        } else {
            focus = index
        }
    }

    /// The lift picked during a rest, to turn to when the rest ends.
    private(set) var queuedFocus: Int?

    /// Dragging the weight: `steps` of 5 lb (2.5 kg) on the sets left of the focused lift, never under zero.
    /// Returns whether anything changed (the light tick fires on a change).
    @discardableResult
    mutating func drag(steps: Int) -> Bool {
        guard case .set = phase, steps != 0, let from = current.nextIndex else { return false }
        let before = lifts[focus].sets
        shift(lift: focus, from: from, by: Double(steps) * step)
        return before != lifts[focus].sets
    }

    /// Sets an exact weight on the set you are on and the sets after it.
    mutating func set(weight: Double) {
        guard case .set = phase, let from = current.nextIndex else { return }
        let delta = max(weight, 0) - lifts[focus].sets[from].weight
        shift(lift: focus, from: from, by: delta)
    }

    private mutating func shift(lift: Int, from: Int, by delta: Double) {
        for index in lifts[lift].sets.indices where index >= from && lifts[lift].sets[index].done == nil {
            lifts[lift].sets[index].weight = max(lifts[lift].sets[index].weight + delta, 0)
        }
    }

    /// Done: logs the set you are on, starts the lift's rest. The last set of the last lift ends the workout.
    @discardableResult
    mutating func logSet(at now: Date) -> Bool {
        guard case .set = phase, let index = current.nextIndex else { return false }
        let planned = lifts[focus].sets[index]
        lifts[focus].sets[index].done = Done(weight: planned.weight, reps: planned.reps, felt: nil, at: now)
        undoable = (focus, index, now)
        if liftsLeft == 0 {
            phase = .done
            finishedAt = now
        } else {
            let seconds = Double(current.restSeconds)
            phase = .rest(endsAt: now.addingTimeInterval(seconds), total: seconds, lift: focus)
        }
        return true
    }

    func canUndo(at now: Date) -> Bool {
        guard let undoable else { return false }
        return now.timeIntervalSince(undoable.at) <= Self.undoWindow
    }

    /// Takes the last logged set back (10 s), back on that set with no rest.
    @discardableResult
    mutating func undo(at now: Date) -> Bool {
        guard canUndo(at: now), let target = undoable else { return false }
        lifts[target.lift].sets[target.set].done = nil
        queuedFocus = nil
        focus = target.lift
        phase = .set
        finishedAt = nil
        undoable = nil
        return true
    }

    private mutating func trackRestBaseline(from old: Phase) {
        switch (old, phase) {
        case (.rest, .rest):
            break
        case let (_, .rest(_, _, lift)):
            restBaseline = lifts[lift].sets.map(\.weight)
        default:
            restBaseline = nil
        }
    }

    /// The next weight Felt changed during this rest, old to new (the screen strikes the old number and writes the new
    /// one after it); nil when nothing changed.
    var restNextChange: (old: Double, new: Double)? {
        guard case let .rest(_, _, lift) = phase, let baseline = restBaseline, let next = lifts[lift].nextIndex,
              baseline.indices.contains(next) else { return nil }
        let new = lifts[lift].sets[next].weight
        return abs(new - baseline[next]) < 0.001 ? nil : (baseline[next], new)
    }

    /// Felt, asked during the rest: the word goes beside the set you just logged; Easy puts the sets left a step above
    /// their weight at the start of the rest, Hard a step below, Right back at it. Never cumulative.
    @discardableResult
    mutating func apply(felt: Felt) -> Receipt? {
        guard case let .rest(_, _, liftIndex) = phase else { return nil }
        guard let lastDone = lifts[liftIndex].sets.lastIndex(where: { $0.done != nil }) else { return nil }
        lifts[liftIndex].sets[lastDone].done?.felt = felt
        let from = lifts[liftIndex].nextIndex ?? lifts[liftIndex].sets.count
        let left = lifts[liftIndex].sets.count - from
        // Measured from the weights at the start of the rest, so a second answer replaces the first.
        if let baseline = restBaseline {
            for index in lifts[liftIndex].sets.indices where index >= from && baseline.indices.contains(index) {
                lifts[liftIndex].sets[index].weight = max(baseline[index] + felt.direction * step, 0)
            }
        }
        guard felt.direction != 0, left > 0 else {
            return Receipt(text: "\(felt.word), weight stays", setsChanged: 0)
        }
        let amount = PlateLoad.number(step)
        let sign = felt.direction > 0 ? "+" : "-"
        let noun = left == 1 ? "set" : "sets"
        return Receipt(
            text: "\(felt.word), \(sign)\(amount) \(unit.symbol) on the \(left) \(noun) left",
            setsChanged: left
        )
    }

    /// Takes a Felt answer back: the sets left return to their weights at the start of the rest, and the word comes off
    /// the set you logged.
    @discardableResult
    mutating func undoFelt() -> Bool {
        guard case let .rest(_, _, lift) = phase, let baseline = restBaseline else { return false }
        for index in lifts[lift].sets.indices
            where lifts[lift].sets[index].done == nil && baseline.indices.contains(index)
        {
            lifts[lift].sets[index].weight = baseline[index]
        }
        if let last = lifts[lift].sets.lastIndex(where: { $0.done != nil }) {
            lifts[lift].sets[last].done?.felt = nil
        }
        return true
    }

    /// Lighter: two steps (10 lb, 5 kg) off the sets left of the focused lift.
    @discardableResult
    mutating func lighter() -> Receipt? {
        guard !isDone, let from = current.nextIndex else { return nil }
        let amount = step * Double(Self.lighterSteps)
        shift(lift: focus, from: from, by: -amount)
        let left = current.setsLeft
        return Receipt(
            text: "Lighter, -\(PlateLoad.number(amount)) \(unit.symbol) on the \(left) \(left == 1 ? "set" : "sets") left",
            setsChanged: left
        )
    }

    /// Rest: a rest now (the lift's own length) from a set, or `seconds` more during one.
    mutating func rest(at now: Date, extendBy seconds: TimeInterval = 30) {
        switch phase {
        case let .rest(endsAt, total, lift):
            phase = .rest(endsAt: endsAt.addingTimeInterval(seconds), total: total + seconds, lift: lift)
        case .set:
            let length = Double(current.restSeconds)
            phase = .rest(endsAt: now.addingTimeInterval(length), total: length, lift: focus)
        case .done:
            break
        }
    }

    /// Tap to start now.
    mutating func endRest(at _: Date) {
        guard case let .rest(_, _, lift) = phase else { return }
        phase = .set
        turnAfterRest(from: lift)
    }

    /// Called as time passes: a rest whose end date has gone is over, and a finished lift turns the dial to the next
    /// lift with sets left.
    mutating func tick(at now: Date) {
        if case let .rest(endsAt, _, lift) = phase, endsAt <= now {
            phase = .set
            turnAfterRest(from: lift)
        }
    }

    private mutating func turnAfterRest(from lift: Int) {
        if let queued = queuedFocus {
            queuedFocus = nil
            if lifts.indices.contains(queued), !lifts[queued].isComplete {
                focus = queued
                return
            }
        }
        guard lifts[lift].isComplete else { focus = lift; return }
        let order = Array(lifts.indices)
        focus = (order.drop { $0 <= lift } + order.prefix { $0 <= lift }).first { !lifts[$0].isComplete } ?? lift
    }

    /// Finish (hold) ends it early with the sets done.
    mutating func finish(at now: Date) {
        phase = .done
        finishedAt = now
        undoable = nil
        queuedFocus = nil
    }

    // MARK: Time

    func elapsed(at now: Date) -> TimeInterval {
        max((finishedAt ?? now).timeIntervalSince(startedAt), 0)
    }

    func restRemaining(at now: Date) -> TimeInterval? {
        guard case let .rest(endsAt, _, _) = phase else { return nil }
        return max(endsAt.timeIntervalSince(now), 0)
    }

    /// When the workout will likely end: the rest left, then each set left at `setSeconds` and its lift's rest, with
    /// no rest after the very last set.
    func doneAbout(at now: Date) -> Date? {
        guard !isDone else { return finishedAt }
        var seconds = restRemaining(at: now) ?? 0
        var remaining = lifts.reduce(0) { $0 + $1.setsLeft }
        for lift in lifts where lift.setsLeft > 0 {
            for _ in 0 ..< lift.setsLeft {
                seconds += lift.warmUp.map { Double($0.minutes * 60) } ?? setSeconds
                remaining -= 1
                if remaining > 0 {
                    seconds += Double(lift.restSeconds)
                }
            }
        }
        // The rest already running counted the lift's rest after the set just done; the set loop above adds the rest
        // between sets still to come, so a rest in progress is not double counted when it is the only thing left.
        return now.addingTimeInterval(seconds)
    }
}

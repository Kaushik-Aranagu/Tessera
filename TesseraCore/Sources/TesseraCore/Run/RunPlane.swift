import Foundation

// The run-mode control plane (design/run-mode-126.md). A routine is an ordered list of steps; the plane holds which
// step
// is now, what is done or skipped, the timers (several at once), pause and resume, going back without stopping, and the
// log of what was done when. It has no look of its own and touches no storage: runners (workout, recipe, default)
// read their data into steps, ask the plane to move, and draw what it says. Time is always passed in, so every
// rule is testable and a pause or a relaunch cannot drift.

public enum RunStepKind: String, Codable, Sendable, Hashable {
    /// Weight and reps, or reps: the live set.
    case counted
    /// A countdown: rest, simmer, stretch, plank.
    case timed
    /// Just done or skip: water, pills, plan the day.
    case check
    /// Runs beside the next step ("at the same time"): its timer starts on arrival and the run moves on.
    case parallel
}

public enum RunStepState: String, Codable, Sendable, Hashable {
    case ahead, now, done, skipped
}

public struct RunStep: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var kind: RunStepKind
    /// How long a timed or parallel step runs, in seconds.
    public var seconds: TimeInterval?
    public var state: RunStepState

    public init(id: UUID = UUID(), title: String, kind: RunStepKind, seconds: TimeInterval? = nil,
                state: RunStepState = .ahead)
    {
        self.id = id
        self.title = title
        self.kind = kind
        self.seconds = seconds
        self.state = state
    }
}

/// One countdown. It counts down from `startedAt` for `length`; paused, it keeps what was left.
public struct RunTimer: Identifiable, Codable, Sendable, Hashable {
    /// The step it belongs to.
    public let id: UUID
    public let length: TimeInterval
    public var startedAt: Date
    /// What was left when the run was paused; nil while it counts.
    public var frozenRemaining: TimeInterval?
    /// Set once its end has been reported, so the firm tap comes once.
    public var hasEnded = false

    public func remaining(at now: Date) -> TimeInterval {
        if let frozenRemaining {
            return frozenRemaining
        }
        return max(0, startedAt.addingTimeInterval(length).timeIntervalSince(now))
    }

    public func endsAt() -> Date {
        startedAt.addingTimeInterval(length)
    }
}

public enum RunHaptic: String, Codable, Sendable, Hashable {
    /// One per step done.
    case stepDone
    /// The countdown ended: one firm tap.
    case timerEnded
}

public struct RunLogEntry: Codable, Sendable, Hashable {
    public enum Outcome: String, Codable, Sendable { case done, skipped, reopened }

    public let step: UUID
    public let outcome: Outcome
    public let when: Date
}

/// What a Live Activity shows: the step, where it is in the run, and the soonest timer end.
public struct RunActivity: Sendable, Hashable {
    public let title: String
    public let number: Int
    public let count: Int
    public let timerEndsAt: Date?
    public let isPaused: Bool
}

public struct RunPlane: Codable, Sendable, Hashable {
    public private(set) var steps: [RunStep]
    public private(set) var timers: [RunTimer] = []
    public private(set) var log: [RunLogEntry] = []
    /// When the run was paused; nil while it runs.
    public private(set) var pausedAt: Date?

    public init(steps: [RunStep]) {
        self.steps = steps
        if !steps.contains(where: { $0.state == .now }), let first = steps.firstIndex(where: { $0.state == .ahead }) {
            self.steps[first].state = .now
        }
    }

    // MARK: Reading

    /// The index of the step that is now; nil once the run is finished.
    public var currentIndex: Int? {
        steps.firstIndex { $0.state == .now }
    }

    public var current: RunStep? {
        currentIndex.map { steps[$0] }
    }

    public var isFinished: Bool {
        currentIndex == nil
    }

    public var isPaused: Bool {
        pausedAt != nil
    }

    public var doneCount: Int {
        steps.count { $0.state == .done }
    }

    /// The step after the current one, faint on screen so the next thing is never a surprise.
    public var next: RunStep? {
        guard let index = currentIndex else { return nil }
        return steps[(index + 1)...].first { $0.state == .ahead }
    }

    public func timer(for step: UUID) -> RunTimer? {
        timers.first { $0.id == step }
    }

    /// Timers still counting, soonest end first.
    public func runningTimers(at now: Date) -> [RunTimer] {
        timers.filter { !$0.hasEnded || $0.remaining(at: now) > 0 }
            .sorted { $0.remaining(at: now) < $1.remaining(at: now) }
    }

    public func activity(at _: Date) -> RunActivity? {
        guard let index = currentIndex else { return nil }
        // A frozen countdown has no end date while paused; paused, the Live Activity shows none at all.
        let soonest = timers.filter { !$0.hasEnded && $0.frozenRemaining == nil }.map { $0.endsAt() }.min()
        return RunActivity(title: steps[index].title, number: index + 1, count: steps.count,
                           timerEndsAt: isPaused ? nil : soonest, isPaused: isPaused)
    }

    // MARK: Moving

    /// The current step is done: one haptic, the log gets a row, and the next step is now. A timed step's own timer
    /// stops with it. A parallel step that comes up starts its timer and the run moves on beside it.
    @discardableResult
    public mutating func complete(at now: Date) -> [RunHaptic] {
        guard let index = currentIndex else { return [] }
        steps[index].state = .done
        timers.removeAll { $0.id == steps[index].id }
        log.append(RunLogEntry(step: steps[index].id, outcome: .done, when: now))
        advance(from: index, at: now)
        return [.stepDone]
    }

    /// The current step is skipped (a day mark, not a failure): no haptic, the log gets a row.
    public mutating func skip(at now: Date) {
        guard let index = currentIndex else { return }
        steps[index].state = .skipped
        timers.removeAll { $0.id == steps[index].id }
        log.append(RunLogEntry(step: steps[index].id, outcome: .skipped, when: now))
        advance(from: index, at: now)
    }

    /// Back, without stopping anything: the step before this one is now again and this one waits. Timers keep running.
    /// Coming back to a step that was done reopens it.
    public mutating func back(at now: Date) {
        guard let index = currentIndex ?? steps.indices.last, index > 0 || currentIndex == nil else { return }
        let target = currentIndex == nil ? index : index - 1
        go(to: target, at: now)
    }

    /// Land on any step (the strip, or coming back to where he was). Returning to the step that is already now changes
    /// nothing.
    public mutating func go(to target: Int, at now: Date) {
        guard steps.indices.contains(target), currentIndex != target else { return }
        if let index = currentIndex {
            steps[index].state = .ahead
        }
        if steps[target].state == .done || steps[target].state == .skipped {
            log.append(RunLogEntry(step: steps[target].id, outcome: .reopened, when: now))
        }
        steps[target].state = .now
    }

    private mutating func advance(from index: Int, at now: Date) {
        var cursor = index + 1
        while cursor < steps.count {
            switch steps[cursor].state {
            case .ahead:
                if steps[cursor].kind == .parallel {
                    // Beside the next step: start its clock and move on; it is done as far as the run goes.
                    startTimer(for: cursor, at: now)
                    steps[cursor].state = .done
                    log.append(RunLogEntry(step: steps[cursor].id, outcome: .done, when: now))
                    cursor += 1
                    continue
                }
                steps[cursor].state = .now
                return
            default:
                cursor += 1
            }
        }
    }

    // MARK: Timers

    /// Starts the countdown of a step (its own length); several run at once. Starting one that is running leaves it.
    public mutating func startTimer(for index: Int, at now: Date) {
        guard steps.indices.contains(index), let length = steps[index].seconds, length > 0,
              !timers.contains(where: { $0.id == steps[index].id }) else { return }
        var timer = RunTimer(id: steps[index].id, length: length, startedAt: now)
        if isPaused {
            timer.frozenRemaining = length
        }
        timers.append(timer)
    }

    public mutating func startTimer(forStep id: UUID, at now: Date) {
        if let index = steps.firstIndex(where: { $0.id == id }) {
            startTimer(for: index, at: now)
        }
    }

    public mutating func stopTimer(for step: UUID) {
        timers.removeAll { $0.id == step }
    }

    /// Reports the timers that have just ended, once each: one firm tap per countdown.
    @discardableResult
    public mutating func tick(at now: Date) -> [RunHaptic] {
        guard !isPaused else { return [] }
        var haptics: [RunHaptic] = []
        for index in timers.indices where !timers[index].hasEnded && timers[index].remaining(at: now) == 0 {
            timers[index].hasEnded = true
            haptics.append(.timerEnded)
        }
        return haptics
    }

    // MARK: Pause and resume

    /// Freezes every countdown where it is.
    public mutating func pause(at now: Date) {
        guard !isPaused else { return }
        pausedAt = now
        for index in timers.indices where !timers[index].hasEnded {
            timers[index].frozenRemaining = timers[index].remaining(at: now)
        }
    }

    /// Starts every frozen countdown again from what it had left.
    public mutating func resume(at now: Date) {
        guard isPaused else { return }
        pausedAt = nil
        for index in timers.indices {
            if let left = timers[index].frozenRemaining {
                timers[index].startedAt = now.addingTimeInterval(left - timers[index].length)
                timers[index].frozenRemaining = nil
            }
        }
    }
}

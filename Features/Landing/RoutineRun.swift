import Foundation
import TesseraCore

/// Routine mode (sheets 323 and 329), as a value: which move of which step the evening is on, when it ends, what is
/// tended and what is left for tomorrow. Time is always an end date (never a ticking counter), so it survives the lock
/// screen; "Not tonight" skips a step without breaking a streak. Pure, so every transition tests without a view.
struct RoutineRun: Equatable {
    /// One thing to do for a stretch of time: a step's move, or a step with no moves as a whole.
    struct Beat: Equatable {
        let step: Int
        let title: String
        let cue: String?
        let breath: String?
        let seconds: Int
        /// The beat belongs to a step with more than one beat (its moves).
        let isMove: Bool
    }

    struct Step: Equatable, Identifiable {
        let id: Int
        let title: String
        let minutes: Int
        let beats: [Int]
    }

    let beats: [Beat]
    let steps: [Step]
    private(set) var index = 0
    private(set) var endsAt: Date?
    /// Seconds left when paused; nil while running.
    private(set) var pausedLeft: TimeInterval?
    private(set) var tended: Set<Int> = []
    private(set) var skipped: Set<Int> = []
    private(set) var finished = false

    /// From already-made beats and steps (the tests build their evening this way).
    init(beats: [Beat], steps: [Step]) {
        self.beats = beats
        self.steps = steps
    }

    /// From a routine's steps. A step with moves becomes one beat per move; one without is a single beat of its length.
    init(_ source: [RoutineStep]) {
        var beats: [Beat] = []
        var steps: [Step] = []
        for (number, step) in source.enumerated() {
            var mine: [Int] = []
            if step.moves.isEmpty {
                mine.append(beats.count)
                beats.append(Beat(step: number, title: step.title, cue: step.cue, breath: step.breath,
                                  seconds: max(step.seconds, 1), isMove: false))
            } else {
                for move in step.moves {
                    mine.append(beats.count)
                    beats.append(Beat(step: number, title: move.move, cue: move.cue ?? step.cue,
                                      breath: move.breath ?? step.breath, seconds: max(move.seconds, 1), isMove: true))
                }
            }
            steps.append(Step(id: number, title: step.title, minutes: step.minutes, beats: mine))
        }
        self.beats = beats
        self.steps = steps
    }

    var isEmpty: Bool {
        beats.isEmpty
    }

    var beat: Beat? {
        beats.indices.contains(index) && !finished ? beats[index] : nil
    }

    var isPaused: Bool {
        pausedLeft != nil
    }

    // MARK: Moves

    mutating func start(at now: Date) {
        guard !beats.isEmpty else {
            finished = true
            return
        }
        index = 0
        endsAt = now.addingTimeInterval(TimeInterval(beats[0].seconds))
    }

    /// Time has passed: any move whose end has gone by gives way to the next, from its own end (so a long sleep still
    /// lands on the right move), never past the evening's end.
    mutating func tick(now: Date) {
        while !finished, !isPaused, let end = endsAt, end <= now {
            advance(at: end)
        }
    }

    /// Next: the move is done early; the next begins now.
    mutating func next(now: Date) {
        guard !finished else { return }
        advance(at: now)
    }

    /// Finish: the evening ends here; what was tended counts.
    mutating func finish() {
        finished = true
        endsAt = nil
        pausedLeft = nil
    }

    mutating func pause(now: Date) {
        guard !finished, let end = endsAt, pausedLeft == nil else { return }
        pausedLeft = max(0, end.timeIntervalSince(now))
        endsAt = nil
    }

    mutating func resume(now: Date) {
        guard let left = pausedLeft else { return }
        pausedLeft = nil
        endsAt = now.addingTimeInterval(left)
    }

    /// Not tonight: the step on is left for tomorrow. Its streak is kept; nothing is owed.
    mutating func notTonight(now: Date) {
        guard let beat, !finished else { return }
        skipped.insert(beat.step)
        moveToNextStep(after: beat.step, at: now)
    }

    private mutating func advance(at moment: Date) {
        guard let beat else { return }
        let last = steps[beat.step].beats.last
        if index == last {
            tended.insert(beat.step)
            moveToNextStep(after: beat.step, at: moment)
        } else {
            index += 1
            begin(at: moment)
        }
    }

    private mutating func moveToNextStep(after step: Int, at moment: Date) {
        pausedLeft = nil
        guard let next = steps.first(where: { $0.id > step && !skipped.contains($0.id) && !tended.contains($0.id) }),
              let first = next.beats.first
        else {
            finished = true
            endsAt = nil
            return
        }
        index = first
        begin(at: moment)
    }

    private mutating func begin(at moment: Date) {
        endsAt = moment.addingTimeInterval(TimeInterval(beats[index].seconds))
    }

    // MARK: Reading

    func secondsLeft(at now: Date) -> TimeInterval {
        if let pausedLeft {
            return pausedLeft
        }
        return max(0, (endsAt ?? now).timeIntervalSince(now))
    }

    /// 0 at the start to 1 once the last step is tended; a step left for tomorrow does not darken it.
    var dusk: Double {
        RoutineSteps.dusk(tended: tended.count, of: steps.count)
    }

    /// 1-based position of the move within its step, and how many the step has.
    var moveCount: (at: Int, of: Int)? {
        guard let beat, beat.isMove, let first = steps[beat.step].beats.first else { return nil }
        return (index - first + 1, steps[beat.step].beats.count)
    }

    /// The breath the guide shows now: "in" for 4 s, then "out" for 6 s, for a move that asks for both; a move that
    /// asks for one keeps it. Nothing when the move has no breath. Words only.
    func breath(at now: Date) -> String? {
        guard let beat, let breath = beat.breath?.lowercased() else { return nil }
        switch breath {
        case "in", "out": return breath
        default:
            let elapsed = max(0, TimeInterval(beat.seconds) - secondsLeft(at: now))
            return elapsed.truncatingRemainder(dividingBy: 10) < 4 ? "in" : "out"
        }
    }

    /// Whether the evening counts as kept: at least one step tended (skipped ones are only left for tomorrow).
    var kept: Bool {
        !tended.isEmpty
    }
}

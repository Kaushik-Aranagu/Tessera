import Foundation

/// What a logged set looks like as a mark (Design sheet 108, section 1): one brush circle per set. Pure logic, so the
/// shapes and the words are tested without drawing anything.
struct SetMarkSpec: Hashable, Identifiable {
    let id: UUID
    /// 1-based number of the set within its exercise.
    let number: Int
    let reps: Int
    /// Reps planned for the set (the slot's target).
    let target: Int
    /// The load in the stored unit (kilograms); a heavier set draws a thicker stroke.
    let weight: Double
    /// The heaviest load of the exercise this session or recently: the top of the thickness range.
    let heaviest: Double
    let isBest: Bool
    /// A private workout shows circles without any values.
    var isPrivate = false

    /// The circle's outcome: closed = on target, open = short (the gap is the missing reps), overlapping = more than
    /// planned, flare = a best (never called a record).
    enum Shape: Hashable {
        case closed
        case open(gap: Double)
        case overlap(extra: Double)
        case flare
    }

    var shape: Shape {
        if isBest {
            return .flare
        }
        guard target > 0 else { return .closed }
        if reps == target {
            return .closed
        }
        if reps < target {
            return .open(gap: Double(target - reps) / Double(target))
        }
        return .overlap(extra: min(1, Double(reps - target) / Double(target)))
    }

    /// 5 to 10 pt on the 390 pt stage: the heavier the set against the heaviest, the thicker the stroke.
    var thickness: Double {
        guard heaviest > 0, weight > 0 else { return 5 }
        return 5 + 5 * min(max(weight / heaviest, 0), 1)
    }

    /// The exact line a tap shows, in the app's own weight unit: "Set 3: 85 kg x 9". Nothing for a private workout.
    func detailLine(format: (Double) -> String) -> String? {
        isPrivate ? nil : "Set \(number): \(format(weight)) \u{00D7} \(reps)"
    }

    /// What VoiceOver says: "Set 2, 8 reps, 82.5 kilograms". A private workout says only the set.
    func spoken(kilograms: (Double) -> String) -> String {
        guard !isPrivate else { return "Set \(number)" }
        return "Set \(number), \(reps) \(reps == 1 ? "rep" : "reps"), \(kilograms(weight))"
    }
}

/// The timing of one logged set's animation: a rep is 0.30 s, the last two take 0.52 s and 0.74 s (Motion lab's v6
/// study), and then the circle draws and flies to its slot.
enum SetMarkClock {
    static let rep = 0.30
    static let lastTwo = [0.52, 0.74]
    /// Seconds the circle takes to draw once the reps are done.
    static let draw = 0.62
    /// Seconds the circle takes to fly to its slot.
    static let fly = 0.5
    /// The wet ink dries to ink in about this long.
    static let dry = 1.1

    /// How long each rep lasts, in order: 0.30 s, except the last two (0.52 s, 0.74 s) when there are at least two.
    static func repDurations(reps: Int) -> [Double] {
        guard reps > 0 else { return [] }
        var durations = Array(repeating: rep, count: reps)
        if reps >= 2 {
            durations[reps - 2] = lastTwo[0]
            durations[reps - 1] = lastTwo[1]
        } else {
            durations[0] = lastTwo[1]
        }
        return durations
    }

    /// Seconds from the first rep to the circle closing.
    static func closes(reps: Int) -> Double {
        repDurations(reps: reps).reduce(0, +) + draw
    }

    /// Which rep is under way at `time`, with how far through it (0 to 1); nil before the first and after the last.
    static func rep(at time: Double, reps: Int) -> (index: Int, phase: Double)? {
        var start = 0.0
        for (index, duration) in repDurations(reps: reps).enumerated() {
            if time < start + duration {
                return (index, (time - start) / duration)
            }
            start += duration
        }
        return nil
    }

    /// Whether the rep is one of the last two, which tremble.
    static func trembles(index: Int, reps: Int) -> Bool {
        reps > 0 && index >= max(reps - 2, 0)
    }
}

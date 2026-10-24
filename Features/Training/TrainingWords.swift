import Foundation

/// Every line the Training rebuild says, as pure functions, so the words in sheet 230 are pinned by tests. Sentence
/// case, no exclamation marks, nothing about money, health or the body.
enum TrainingWords {
    // MARK: Sets

    static func reps(_ count: Int) -> String {
        "\(count) \(count == 1 ? "rep" : "reps")"
    }

    /// "Set 1, 5 reps." and, once the 5 s have run out, "Set 1, 5 reps, kept." (a confirmation, not a question).
    static func confirmation(set: Int, reps count: Int, kept: Bool) -> String {
        kept ? "Set \(set), \(reps(count)), kept." : "Set \(set), \(reps(count))."
    }

    /// The words around the scrolling number in the confirmation: ("Set 1, ", " reps." or " reps, kept.").
    static func confirmationParts(set: Int, reps count: Int, kept: Bool) -> (before: String, after: String) {
        ("Set \(set), ", " \(count == 1 ? "rep" : "reps")\(kept ? ", kept." : ".")")
    }

    /// The 10 s Undo line after a set: "Set 2, logged."
    static func logged(set: Int) -> String {
        "Set \(set), logged."
    }

    /// "Set 1 of 3".
    static func setOf(_ set: Int, _ total: Int) -> String {
        "Set \(set) of \(max(total, set))"
    }

    /// The trail of a lift's done sets: "5 5 5".
    static func trail(_ reps: [Int]) -> String {
        reps.map(String.init).joined(separator: " ")
    }

    /// What a session-wheel row says beside the name: a lift done shows its trail, one to come "3 by 6" (sets by reps)
    /// and one part done "5, 2 left".
    static func rowInfo(done: [Int], sets: Int, plannedReps: Int) -> String {
        if done.isEmpty {
            return "\(sets) by \(plannedReps)"
        }
        if done.count >= sets {
            return trail(done)
        }
        return "\(trail(done)), \(sets - done.count) left"
    }

    // MARK: Rest, warm-up, done

    /// "Rest 1:30", green.
    static func rest(_ seconds: Int) -> String {
        "Rest \(clock(seconds))"
    }

    /// "Set 2 is next", or the next lift's name when this lift is done.
    static func next(set: Int, of total: Int, nextLift: String?) -> String {
        set <= total ? "Set \(set) is next" : (nextLift.map { "\($0) is next" } ?? "That was the last set")
    }

    static func clock(_ seconds: Int) -> String {
        let total = max(seconds, 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static let skipRest = "Skip rest"
    static let doneWarming = "Done warming up"
    static let finish = "Finish"

    /// "warm-up and 4 lifts" (or "4 lifts" with no warm-up, "1 lift").
    static func doneSummary(lifts: Int, warmedUp: Bool) -> String {
        let lifts = "\(lifts) \(lifts == 1 ? "lift" : "lifts")"
        return warmedUp ? "warm-up and \(lifts)" : lifts
    }

    /// "Bench held at 185. Next Push A is Friday."
    static func doneBrief(lift: String, held: String, nextName: String, nextDay: String) -> String {
        "\(lift) held at \(held). Next \(nextName) is \(nextDay)."
    }

    // MARK: Foot, receipts

    /// The foot holds ONE word.
    static func foot(startName: String) -> String {
        "Start \(startName)"
    }

    static func footLog(set: Int) -> String {
        "Log set \(set)"
    }

    static func footResume(name: String, verb: String = "Pick up") -> String {
        "\(verb) \(name)"
    }

    /// "Dips now, bench press after."
    static func swappedIn(now: String, after: String) -> String {
        "\(now) now, \(after.lowercasedFirst) after."
    }

    /// "185 lb loads as 85 kg."
    static func unitReceipt(from: String, to: String) -> String {
        "\(from) loads as \(to)."
    }

    /// "Bench press, set 2 of 3. 4 lifts to go."
    static func going(lift: String, set: Int, of total: Int, liftsToGo: Int) -> String {
        "\(lift), set \(set) of \(total). \(liftsToGo) \(liftsToGo == 1 ? "lift" : "lifts") to go."
    }

    static let privateWorkout = "Private workout"
}

extension TrainingLane {
    /// The reps a lane plans, from its scheme ("4 × 5–8" is 8, the top of the range; "3 × 12" is 12).
    static func plannedReps(scheme: String) -> Int {
        let digits = scheme.split { !$0.isNumber }.compactMap { Int($0) }
        return digits.count >= 2 ? digits.last ?? 8 : 8
    }
}

extension String {
    /// The first letter lowercased, the rest untouched ("Bench press" to "bench press", "DB press" stays).
    var lowercasedFirst: String {
        guard let first, !dropFirst().prefix(1).contains(where: \.isUppercase) else { return self }
        return first.lowercased() + dropFirst()
    }
}

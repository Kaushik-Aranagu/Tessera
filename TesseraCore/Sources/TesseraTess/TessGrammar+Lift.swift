import Foundation
import TesseraCore

/// Named lifts: "bench 80x8", "squat 100 5", "bench 3 sets of 8 at 80", "pull ups 3x8".
extension TessGrammar {
    func parseLift(_ text: String, entry: ObjectRecord?) -> Parse? {
        var lift = LiftWords()
        // "8 reps only" is 8 (never groceries). "bench 3 sets of 8 at 80" is 3 sets of 8 at 80; with no weight said
        // it never becomes 3 kg (QA F1 on #282).
        var rest = Substring(text.replacing(/(\d) reps?(?: only)?\b/) { "\($0.1)" }
            .replacing(/(\d) only\b/) { "\($0.1)" })
        if let said = rest.firstMatch(of: /(\d+) sets? of (\d+)/), let sets = Int(said.1), let reps = Double(said.2) {
            (lift.sets, lift.reps, lift.setsSaid) = (sets, reps, true)
            rest.removeSubrange(said.range)
            rest = Substring(rest.replacing(/\b(?:at|@)\b/, with: " "))
        }
        if let scheme = rest.firstMatch(of: /(\d+(?:\.\d+)?)(?: ?x ?| by )(\d+)(?: (?:at|@) (\d+(?:\.\d+)?))?/) {
            lift.readScheme(Double(scheme.1) ?? 0, Double(scheme.2) ?? 0, at: scheme.3.flatMap { Double($0) },
                            weightElsewhere: Self.hasOtherNumber(rest, excluding: scheme.range))
            rest.removeSubrange(scheme.range)
        }
        rest.split(separator: " ").forEach { lift.read($0) }
        guard !lift.words.isEmpty, let exercise = resolveExercise(lift.words.joined(separator: " ")) else { return nil }
        // "pull ups 3x8": on a bodyweight lift a bare N x M is N sets of M, never N kg (A181).
        let bodyweight = store.equipmentKind(of: exercise) == .bodyweight
        // In a live workout with that lift in focus, it asks like a bare "10x8" does (Product 9:40 PM PT).
        if bodyweight, lift.weightFromScheme, let entry, store.linkedClass("exercise", of: entry)?.id == exercise.id,
           let first = lift.weight, first.rounded() == first, first >= 1, let reps = lift.reps
        {
            return .askSetCount(TessSetCountAsk(entry: entry.id, count: Int(first), reps: reps, bodyweight: true))
        }
        if bodyweight, lift.weightFromScheme, let first = lift.weight, first <= 10, first.rounded() == first {
            (lift.sets, lift.weight) = (Int(first), 0)
        }
        // "pull-ups 8" with Pull-Up in focus: one number on a bodyweight lift is reps (Research on #282, as K898).
        if bodyweight, !lift.weightFromScheme, !lift.setsSaid, lift.reps == nil, let only = lift.weight, let entry,
           store.linkedClass("exercise", of: entry)?.id == exercise.id
        {
            (lift.reps, lift.weight) = (only, 0)
        }
        if bodyweight, lift.weight == nil, lift.reps != nil {
            // "dips 3 sets of 10", or "pull-ups 8" in focus: at bodyweight (Research on #282).
            lift.weight = 0
        }
        // "bench 3x8": a bare N x M under the lightest load is N sets with no weight said, never N kg. The last weight
        // in focus if there is one, else ask (QA F1, Research on #282).
        if !bodyweight, lift.weightFromScheme, let first = lift.weight, first <= 10, first.rounded() == first,
           let lightest = store.weightDial(for: exercise).detents.first, first < lightest, let reps = lift.reps
        {
            let name = TessCaptureEngine.shortName(exercise.name)
            if let entry, store.linkedClass("exercise", of: entry)?.id == exercise.id, let last = lastSet(in: entry) {
                return .sets(Array(repeating: .set(entry: entry, weight: last.weight, reps: reps, kind: .working,
                                                   phrase: .full), count: Int(first)))
            }
            return .ask("\(name) \(Int(first)) × \(TessVoice.number(reps)) at what weight?")
        }
        if lift.setsSaid, lift.weight == nil, let reps = lift.reps {
            let name = TessCaptureEngine.shortName(exercise.name)
            return .ask("\(name) \(lift.sets) × \(TessVoice.number(reps)) at what weight?")
        }
        // "bench 3x5 at 7": 7 kg is under anything the bar can load, so it's a time, not a weight (QA on #274).
        if lift.weightAfterAt, let at = lift.weight, at <= 12,
           let lightest = store.weightDial(for: exercise).detents.first, at < lightest
        {
            return nil
        }
        let (sets, unit, reps, weight) = (lift.sets, lift.unit, lift.reps, lift.weight)
        guard let reps, let weight, (1 ... 20).contains(sets), reps >= 1, reps <= 100, reps.rounded() == reps,
              weight > 0 || bodyweight && weight == 0, unit.toKilograms(weight) <= 1000 else { return nil }
        if let entry, sets == 1, store.linkedClass("exercise", of: entry)?.id == exercise.id {
            return .set(entry: entry, weight: unit.toKilograms(weight), reps: reps, kind: .working, phrase: .full,
                        unit: unit)
        }
        return .lift(exercise: exercise, sets: sets, reps: reps, weight: weight, unit: unit)
    }

    /// The numbers and words of a lift phrase.
    struct LiftWords {
        var sets = 1
        var unit = MassUnit.kilograms
        var reps: Double?
        var weight: Double?
        var words: [Substring] = []
        /// "3 sets of 8" said the sets in words.
        var setsSaid = false
        /// The weight is the first number of a bare "N x M" (no "at", no other number).
        var weightFromScheme = false
        /// The weight came after "at" ("3x5 at 80"), where a small number may be a clock time.
        var weightAfterAt = false

        mutating func readScheme(_ first: Double, _ second: Double, at atWeight: Double?, weightElsewhere: Bool) {
            if let atWeight {
                // "3x8 at 80": sets x reps at weight.
                (sets, reps, weight) = (Int(first), second, atWeight)
                weightAfterAt = true
            } else if first <= 10, second <= 30, weightElsewhere {
                // "3x10 bench 80": sets x reps, weight elsewhere.
                (sets, reps) = (Int(first), second)
            } else {
                // "80x8": weight x reps.
                (weight, reps) = (first, second)
                weightFromScheme = true
            }
        }

        mutating func read(_ token: Substring) {
            if let parsed = MassUnit(parsing: String(token)) {
                unit = parsed
            } else if let value = Double(token) {
                if weight == nil {
                    weight = value
                } else if reps == nil {
                    reps = value
                }
            } else if !["for", "at", "@", "of", "x", "sets", "reps", "log", "logged", "add", "did"].contains(token) {
                words.append(token)
            }
        }
    }

    static func hasOtherNumber(_ text: Substring, excluding range: Range<Substring.Index>) -> Bool {
        var copy = text
        copy.removeSubrange(range)
        return copy.split(separator: " ").contains { Double($0) != nil }
    }
}

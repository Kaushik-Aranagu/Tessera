import Foundation

/// The muscle words for a day ("chest, shoulders and triceps"), from the routine's working sets (Design sheet 107).
/// Primary muscles only, counted by sets; Lats, Upper Back and Lower Back are one "back", the three delts one
/// "shoulders". The top three go in the body's order, joined by hand with no Oxford comma. A private routine gets
/// no sentence.
public enum MuscleSummary {
    /// The plain US word for a stored muscle name, with the folds applied.
    public static func word(for stored: String) -> String {
        switch stored.lowercased() {
        case "lats", "upper back", "lower back": "back"
        case "front delts", "side delts", "rear delts": "shoulders"
        case "adductors": "inner thighs"
        case "abductors": "outer hips"
        default: stored.lowercased()
        }
    }

    /// The order the words read in, head to toe: ties and the final sentence follow it.
    static let order = ["chest", "back", "shoulders", "biceps", "triceps", "forearms", "abs", "core", "quads", "glutes",
                        "hamstrings", "inner thighs", "outer hips", "calves"]

    static func rank(_ word: String) -> Int {
        order.firstIndex(of: word) ?? order.count
    }

    /// "chest, shoulders and triceps": at most three words, no Oxford comma; empty for none.
    public static func sentence(_ words: [String]) -> String {
        switch words.count {
        case 0: ""
        case 1: words[0]
        default: words.dropLast().joined(separator: ", ") + " and " + words[words.count - 1]
        }
    }

    /// The top three muscle words by working sets, in the body's order.
    @MainActor
    public static func topWords(of routine: ObjectRecord, store: ObjectStore, limit: Int = 3) -> [String] {
        var sets: [String: Double] = [:]
        for slot in routine.orderedChildren where !slot.isDeleted {
            let count = store.number("sets", of: slot) ?? 0
            guard count > 0, let exercise = store.linkedClass("exercise", of: slot) else { continue }
            for muscle in store.linkedObjects("primaryMuscles", ofClass: exercise) {
                sets[word(for: muscle.title), default: 0] += count
            }
        }
        let top = sets.sorted { lhs, rhs in
            lhs.value != rhs.value ? lhs.value > rhs.value : rank(lhs.key) < rank(rhs.key)
        }.prefix(limit).map(\.key)
        return top.sorted { rank($0) < rank($1) }
    }

    /// The line for a routine, or nil for a private routine (and for one with no muscles).
    @MainActor
    public static func works(of routine: ObjectRecord, store: ObjectStore) -> String? {
        guard ObjectPrivacy.routineTitle(routine.title, in: store) != ObjectPrivacy.routineLabel else { return nil }
        let words = topWords(of: routine, store: store)
        return words.isEmpty ? nil : sentence(words)
    }
}

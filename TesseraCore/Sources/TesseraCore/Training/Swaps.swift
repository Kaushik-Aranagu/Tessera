import Foundation

@MainActor
public extension TrainingLedger {
    /// Exercises to swap in for `exercise` ("bench taken"): same family first, then same movement pattern,
    /// each ranked by how much the primary muscles overlap. Works for either class-tree shape, because pattern
    /// and family live on the exercises' class objects.
    func swapCandidates(for exercise: ClassDef, limit: Int = 8) -> [ClassDef] {
        guard let root = classes[.exercise] else { return [] }
        let family = store.classValue("family", of: exercise)?.stringValue
        let pattern = store.classValue("pattern", of: exercise)?.stringValue
        let muscles = Set(store.linkedObjects("primaryMuscles", ofClass: exercise).map(\.id))
        let candidates = ClassResolver.descendants(of: root).filter { candidate in
            candidate.id != exercise.id && store.isConcreteExercise(candidate, root: root)
        }
        let scored = candidates.compactMap { candidate -> (ClassDef, Int, Double)? in
            let sameFamily = family != nil && store.classValue("family", of: candidate)?.stringValue == family
            let samePattern = pattern != nil && store.classValue("pattern", of: candidate)?.stringValue == pattern
            guard sameFamily || samePattern else { return nil }
            let theirs = Set(store.linkedObjects("primaryMuscles", ofClass: candidate).map(\.id))
            let overlap = muscles.isEmpty ? 0 : Double(muscles.intersection(theirs).count) / Double(muscles.count)
            return (candidate, sameFamily ? 0 : 1, overlap)
        }
        return scored
            .sorted { ($0.1, -$0.2, $0.0.name) < ($1.1, -$1.2, $1.0.name) }
            .prefix(limit)
            .map(\.0)
    }
}

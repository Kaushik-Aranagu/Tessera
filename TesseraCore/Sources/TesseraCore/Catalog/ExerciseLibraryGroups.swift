import Foundation

/// One heading in the exercise library: a movement pattern with its exercises, or the person's own exercises that
/// sit outside the library's patterns ("Yours").
@MainActor
public struct ExerciseGroup: Identifiable {
    public let id: UUID

    /// The movement pattern class ("library.pattern.*"); nil for "Yours".
    public let pattern: ClassDef?
    public let name: String
    /// Concrete exercises under it, by name.
    public let exercises: [ClassDef]

    static let yoursID = SystemCatalog.stableID("library.group.yours")
}

@MainActor
public extension ObjectStore {
    /// The exercise library for pickers, by movement pattern in the library's order, each pattern's exercises by
    /// name, then "Yours" for exercises made outside the patterns. Empty patterns are left out. `root` is the
    /// Exercise class.
    func exerciseGroups(root: ClassDef?) -> [ExerciseGroup] {
        guard let root else { return [] }
        let everything = ClassResolver.descendants(of: root)
        let patterns = everything.filter { $0.systemKey?.hasPrefix("library.pattern.") == true }
        var placed = Set<UUID>()
        var groups: [ExerciseGroup] = patterns.map { pattern in
            let exercises = ClassResolver.descendants(of: pattern).dropFirst()
                .filter { isConcreteExercise($0, root: root) && ($0.subclasses ?? []).isEmpty }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            placed.formUnion(exercises.map(\.id))
            return ExerciseGroup(id: pattern.id, pattern: pattern, name: pattern.name, exercises: exercises)
        }
        let yours = everything
            .filter { !placed.contains($0.id) && isConcreteExercise($0, root: root) && ($0.subclasses ?? []).isEmpty }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        groups.append(ExerciseGroup(id: ExerciseGroup.yoursID, pattern: nil, name: "Yours", exercises: yours))
        return groups.filter { !$0.exercises.isEmpty }
    }
}

import Foundation
import TesseraCore

/// What an exercise works, read once from the store, for every place a figure is drawn (Design brief 1, sheet 107).
@MainActor
enum MuscleReading {
    typealias Muscles = [(name: String, role: MuscleRole)]

    /// An exercise's primary muscles, then its secondary ones that are not also primary.
    static func muscles(of exercise: ClassDef?, store: ObjectStore) -> Muscles {
        guard let exercise else { return [] }
        let primary = store.linkedObjects("primaryMuscles", ofClass: exercise)
        let primaryIDs = Set(primary.map(\.id))
        let secondary = store.linkedObjects("secondaryMuscles", ofClass: exercise)
            .filter { !primaryIDs.contains($0.id) }
        return primary.map { (name: $0.title, role: MuscleRole.primary) }
            + secondary.map { (name: $0.title, role: MuscleRole.secondary) }
    }

    /// The union of several exercises' muscles: primary if primary anywhere, in a stable order.
    static func union(_ lists: [Muscles]) -> Muscles {
        var roles: [String: MuscleRole] = [:]
        for list in lists {
            for muscle in list where roles[muscle.name] != .primary {
                roles[muscle.name] = muscle.role
            }
        }
        return roles.map { (name: $0.key, role: $0.value) }.sorted { $0.name < $1.name }
    }

    /// What a figure may light: a private routine lights nothing (the lit figure says what the "Works ..." words
    /// would, so drawing it loosens the privacy rule); its figure is the plain outline.
    static func lit(_ muscles: Muscles, isPrivate: Bool) -> Muscles {
        isPrivate ? [] : muscles
    }

    /// The primary muscles' words for VoiceOver ("works chest and triceps"); empty when none.
    static func spoken(_ muscles: Muscles) -> String {
        let primary = muscles.filter { $0.role == .primary }.map(\.name)
        return primary.isEmpty ? "" : MuscleWords.works(primary).lowercased()
    }

    /// Whether the exercise page was opened from a private workout or routine (the live workout, or any page before
    /// this one on the stack): its figure is then the plain outline. When unsure, wall.
    static func openedFromPrivate(_ model: AppModel) -> Bool {
        if model.isWorkoutPresented, let session = model.session, session.shownTitle != session.workout.title {
            return true
        }
        let stack = model.isWorkoutPresented ? model.workoutPath : model.path
        return stack.dropLast().contains { route in
            guard case let .object(id) = route, let record = model.object(id) else { return false }
            return ObjectPrivacy.routineTitle(model.store.displayTitle(of: record), in: model.store)
                == ObjectPrivacy.routineLabel
        }
    }
}

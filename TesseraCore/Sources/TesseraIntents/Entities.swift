import AppIntents
import Foundation
import TesseraCore

/// An exercise class (Bench Press, Overhead Press…) for Siri and Shortcuts.
public struct ExerciseEntity: AppEntity {
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Exercise"
    public static let defaultQuery = ExerciseQuery()

    public let id: UUID
    public let name: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ExerciseQuery: EntityStringQuery {
    @Dependency private var runtime: TesseraRuntime

    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [ExerciseEntity] {
        await MainActor.run {
            identifiers.compactMap { id in
                runtime.store.classDef(id: id).map { ExerciseEntity(id: $0.id, name: $0.name) }
            }
        }
    }

    public func entities(matching string: String) async throws -> [ExerciseEntity] {
        await MainActor.run {
            let needle = string.lowercased()
            return Self.all(runtime).filter { $0.name.lowercased().contains(needle) }
        }
    }

    public func suggestedEntities() async throws -> [ExerciseEntity] {
        await MainActor.run { Self.all(runtime) }
    }

    @MainActor
    static func all(_ runtime: TesseraRuntime) -> [ExerciseEntity] {
        guard let root = runtime.engine.classes[.exercise] else { return [] }
        return ClassResolver.descendants(of: root)
            .filter { runtime.store.isConcreteExercise($0, root: root) }
            .map { ExerciseEntity(id: $0.id, name: $0.name) }
            .sorted { $0.name < $1.name }
    }
}

/// A routine (Push Day A) for "Start Push Day".
public struct RoutineEntity: AppEntity {
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
    public static let defaultQuery = RoutineQuery()

    public let id: UUID
    public let title: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    /// The one way to build a routine entity: the title it carries and shows is the masked one ("Private workout"
    /// for a private routine), so Shortcuts, Siri's picker and Spotlight never see the raw words.
    @MainActor
    init(routine: ObjectRecord, in store: ObjectStore) {
        id = routine.id
        title = ObjectPrivacy.routineTitle(routine.title, in: store)
    }
}

public struct RoutineQuery: EntityStringQuery {
    @Dependency private var runtime: TesseraRuntime

    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [RoutineEntity] {
        await MainActor.run { Self.entities(for: identifiers, runtime) }
    }

    public func entities(matching string: String) async throws -> [RoutineEntity] {
        await MainActor.run { Self.entities(matching: string, runtime) }
    }

    public func suggestedEntities() async throws -> [RoutineEntity] {
        await MainActor.run { Self.all(runtime) }
    }

    @MainActor
    static func entities(for identifiers: [UUID], _ runtime: TesseraRuntime) -> [RoutineEntity] {
        identifiers.compactMap { id in
            guard let routine = runtime.store.object(id: id), !routine.isDeleted else { return nil }
            return RoutineEntity(routine: routine, in: runtime.store)
        }
    }

    /// Matches the shown title only: typing a private routine's own words finds nothing.
    @MainActor
    static func entities(matching string: String, _ runtime: TesseraRuntime) -> [RoutineEntity] {
        all(runtime).filter { $0.title.lowercased().contains(string.lowercased()) }
    }

    @MainActor
    static func all(_ runtime: TesseraRuntime) -> [RoutineEntity] {
        guard let routineClass = runtime.engine.classes[.routine] else { return [] }
        return runtime.store.objects(of: routineClass).map { RoutineEntity(routine: $0, in: runtime.store) }
    }
}

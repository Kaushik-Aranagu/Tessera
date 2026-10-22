import Foundation
import TesseraCore

/// Which routes get their own object page instead of the generic one.
@MainActor
enum ExerciseRouting {
    /// A concrete exercise: a subclass of Exercise, but not Exercise itself or one of the built-in categories
    /// (Strength Exercise, Barbell Lift), which stay generic class pages listing their subclasses.
    static func isExercise(_ classDef: ClassDef, classes: [SystemCatalog.Key: ClassDef]) -> Bool {
        guard let root = classes[.exercise], ClassResolver.isSubclass(classDef, of: root) else { return false }
        let categories: Set<SystemCatalog.Key> = [.exercise, .strengthExercise, .barbellLift]
        return !categories.contains { classes[$0]?.id == classDef.id }
    }

    /// The Plan class page (newest plan) or one plan object both open Plans.
    struct PlanRoute {
        let object: ObjectRecord?
    }

    static func plan(for route: Route, model: AppModel) -> PlanRoute? {
        guard let planClass = model.classDef(.plan) else { return nil }
        switch route {
        case let .classDef(id):
            return id == planClass.id ? PlanRoute(object: nil) : nil
        case let .object(id):
            guard let object = model.object(id), let objectClass = object.classDef,
                  ClassResolver.isSubclass(objectClass, of: planClass) else { return nil }
            return PlanRoute(object: object)
        case .routines, .routinesLanding, .routinesBrowse:
            return nil
        }
    }
}

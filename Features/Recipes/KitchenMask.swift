import Foundation
import TesseraCore

/// A private recipe names nothing anywhere: not its lines, its steps, its timers, or the step a running cook is on
/// (masking everywhere, QA on #1032). Core stores step text and timer labels as typed; the app masks them where it
/// shows them, from the recipe they belong to.
enum KitchenMask {
    /// A step of a private recipe, on its object page.
    static let stepLabel = "Private step"
    /// A timer of a private recipe's cook, as the timer alerts say a hidden label.
    static let timerLabel = "Timer"

    /// The recipe a line, step, timer or cook belongs to, or nil when the object isn't part of one.
    @MainActor
    static func recipe(of object: ObjectRecord, in store: ObjectStore,
                       classes: [SystemCatalog.Key: ClassDef]) -> ObjectRecord?
    {
        func isA(_ key: SystemCatalog.Key, _ def: ClassDef?) -> Bool {
            guard let def, let target = classes[key] else { return false }
            return ClassResolver.isSubclass(def, of: target)
        }
        let classDef = object.classDef
        if isA(.recipeStep, classDef) || isA(.recipeLine, classDef) {
            return object.parent.flatMap { isA(.recipe, $0.classDef) ? $0 : nil }
        }
        if isA(.cook, classDef) {
            return store.linkedObjects("recipe", of: object).first
        }
        if isA(.kitchenTimer, classDef) {
            return store.linkedObjects("cook", of: object).first.flatMap { store.linkedObjects("recipe", of: $0).first }
        }
        return nil
    }

    /// Whether the object is part of a private recipe (the recipe rule, G21b).
    @MainActor
    static func isPrivate(_ object: ObjectRecord, in store: ObjectStore,
                          classes: [SystemCatalog.Key: ClassDef]) -> Bool
    {
        guard let recipe = recipe(of: object, in: store, classes: classes) else { return false }
        return ObjectPrivacy.isPrivateRecipeTitle(recipe.title, lastWeightKg: BodyWeight.lastKg(in: store))
    }

    /// What a part of a private recipe shows in place of its own words, or nil when it may show them.
    @MainActor
    static func label(of object: ObjectRecord, in store: ObjectStore,
                      classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        guard isPrivate(object, in: store, classes: classes), let classDef = object.classDef else { return nil }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        if isA(.recipeStep) {
            return stepLabel
        }
        if isA(.recipeLine) {
            return ShopTrip.privateLabel
        }
        if isA(.kitchenTimer) {
            return timerLabel
        }
        return isA(.cook) ? ObjectPrivacy.recipeLabel : nil
    }

    /// A running cook's step on Home when its recipe is private: "Step 2 of 6", never the step's own text, and
    /// nothing when the count is unknown. `.none` when the process isn't a private recipe's cook.
    @MainActor
    static func cookStep(_ process: ProcessSnapshot, store: ObjectStore,
                         classes: [SystemCatalog.Key: ClassDef]) -> String??
    {
        guard let cook = process.subject, let cookClass = classes[.cook], let subjectClass = cook.classDef,
              ClassResolver.isSubclass(subjectClass, of: cookClass),
              let recipe = recipe(of: cook, in: store, classes: classes),
              ObjectPrivacy.isPrivateRecipeTitle(recipe.title, lastWeightKg: BodyWeight.lastKg(in: store))
        else { return .none }
        let count = RecipeBook(store: store, classes: classes).steps(of: recipe).count
        let index = process.resumePoint?.index ?? 0
        return .some(count > 0 && index < count ? "Step \(index + 1) of \(count)" : nil)
    }
}

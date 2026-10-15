import Foundation
import SwiftData

// Everything the app needs from storage, through the engine. The app should not import SwiftData or touch a
// ModelContext: storage is moving to GRDB (docs/engine/grdb-migration.md), and only these calls will carry over.
public extension ObjectStore {
    /// Opens the app's store (or an in-memory one for tests and previews). The store keeps its container alive.
    static func open(inMemory: Bool = false) -> ObjectStore {
        let container = TesseraSchema.makeContainer(inMemory: inMemory)
        let store = ObjectStore(context: container.mainContext)
        store.cache.container = container
        return store
    }

    /// Seeds the built-in classes and installs the exercise library if needed. Call once at launch.
    @discardableResult
    func prepareCatalog() throws -> [SystemCatalog.Key: ClassDef] {
        let classes = try SystemCatalog.seed(in: context)
        try ExerciseLibraryInstaller.installIfNeeded(store: self, classes: classes)
        return classes
    }

    /// Persists pending writes now (they also save automatically).
    func save() {
        try? context.save()
    }

    /// Every class, oldest first.
    func allClasses() -> [ClassDef] {
        (try? context.fetch(FetchDescriptor<ClassDef>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
    }

    /// The class with this name, preferring built-in and library classes.
    func classDef(named name: String) -> ClassDef? {
        let matches = allClasses().filter { $0.name == name }
        return matches.first { $0.systemKey != nil } ?? matches.first
    }

    /// Creates a user class (the class editor's "New subclass").
    @discardableResult
    func createClass(name: String, parent: ClassDef?, symbolName: String = "circle",
                     colorRole: String = "neutral", traits: [ClassTrait] = []) -> ClassDef
    {
        let classDef = ClassDef(name: name, parent: nil, symbolName: symbolName, colorRole: colorRole, traits: traits)
        context.insert(classDef)
        classDef.parent = parent
        invalidateCaches()
        return classDef
    }

    /// Wipes objects, links, the op log and user classes, keeping built-in and library classes (demo reset).
    func resetUserData() {
        try? context.delete(model: ObjectLink.self)
        try? context.delete(model: ObjectRecord.self)
        try? context.delete(model: OpRecord.self)
        for classDef in allClasses() where classDef.systemKey == nil {
            context.delete(classDef)
        }
        try? context.save()
        invalidateCaches()
    }
}

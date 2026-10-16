import Foundation

/// Everything the app needs from storage, through the engine. The app should not import SwiftData or touch a
/// TesseraContext directly (docs/engine/grdb-migration.md).
public extension ObjectStore {
    /// Opens the app's store (or an in-memory one for tests and previews). The store keeps its container alive.
    static func open(inMemory: Bool = false) -> ObjectStore {
        let container = TesseraSchema.makeContainer(inMemory: inMemory)
        let store = ObjectStore(context: container.mainContext)
        store.cache.container = container
        return store
    }

    /// Seeds the built-in classes, the exercise library and the starter plan if needed. Call once at launch.
    @discardableResult
    func prepareCatalog() throws -> [SystemCatalog.Key: ClassDef] {
        let classes = try SystemCatalog.seed(in: context)
        try ExerciseLibraryInstaller.installIfNeeded(store: self, classes: classes)
        try StarterContent.installIfNeeded(store: self, classes: classes)
        Groceries.installIfNeeded(store: self, classes: classes)
        return classes
    }

    /// Persists pending writes now (they also save automatically).
    func save() {
        try? context.save()
    }

    /// Every class, oldest first.
    func allClasses() -> [ClassDef] {
        context.all(ClassDef.self).sorted { $0.createdAt < $1.createdAt }
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
    /// Never on a phone: on an iOS device this does nothing, whoever calls it (docs/research/debug-paths.md).
    func resetUserData() {
        #if os(iOS) && !targetEnvironment(simulator)
            return
        #else
            context.deleteAll(ObjectLink.self)
            context.deleteAll(ObjectRecord.self)
            context.deleteAll(OpRecord.self)
            for classDef in allClasses() where classDef.systemKey == nil {
                context.delete(classDef)
            }
            try? context.save()
            invalidateCaches()
            // The starter plan and gym kit are user data too; put them back so a reset install looks like a fresh one.
            // The library classes survive, so its equipment objects are reinstalled explicitly.
            if let classes = try? SystemCatalog.seed(in: context) {
                _ = try? ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: self,
                                                          classes: classes)
            }
            _ = try? prepareCatalog()
        #endif
    }
}

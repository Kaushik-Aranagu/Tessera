import Foundation
import GRDB

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

    /// An in-memory copy of this store that nothing observes and nothing writes back from (`TesseraContext.fork`).
    @MainActor
    func fork() throws -> ObjectStore {
        ObjectStore(context: try context.fork())
    }

    /// Seeds the built-in classes, the exercise library and the starter plan if needed. Call once at launch.
    @discardableResult
    func prepareCatalog(now: Date = .now, calendar: Calendar = .current) throws -> [SystemCatalog.Key: ClassDef] {
        let classes = try SystemCatalog.seed(in: context)
        try ExerciseLibraryInstaller.installIfNeeded(store: self, classes: classes)
        try StarterContent.installIfNeeded(store: self, classes: classes)
        StarterContent.backfillKinds(store: self, classes: classes)
        Groceries.installIfNeeded(store: self, classes: classes)
        closeStaleCooksAfterRestore(classes: classes, now: now, calendar: calendar)
        return classes
    }

    /// A cook found running in a store restored from an earlier day's copy was left open by that day, not by him now
    /// (G27): it closes as not finished, silently, with its timers stopped. Only cooks that were already running when
    /// the copy was made; a cook started after the restore is live.
    @MainActor
    private func closeStaleCooksAfterRestore(classes: [SystemCatalog.Key: ClassDef], now: Date, calendar: Calendar) {
        guard let url = context.url, let restored = TesseraBackup.restoredAt(for: url),
              let madeSeconds = try? context.database.read({ try Double.fetchOne(
                  $0,
                  sql: "SELECT createdAt FROM backupInfo"
              ) })
        else { return }
        let made = Date(timeIntervalSince1970: madeSeconds)
        let day = TesseraDay(calendar: calendar)
        guard day.day(of: made) < day.day(of: restored) else { return }
        _ = try? ActionEngine(store: self, classes: classes).perform(
            CloseStaleCooks(madeAt: made, at: now),
            by: .system
        )
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
                     colorRole: String = "neutral", traits: [ClassTrait] = [], id: UUID? = nil) -> ClassDef
    {
        let classDef = ClassDef(name: name, parent: nil, symbolName: symbolName, colorRole: colorRole, traits: traits)
        if let id {
            classDef.id = id
        }
        context.insert(classDef)
        classDef.parent = parent
        invalidateCaches()
        return classDef
    }

    /// Removes a user class nothing uses yet (undo of a new subclass). False for a built-in class, or one with
    /// subclasses or objects.
    @discardableResult
    func deleteClass(_ classDef: ClassDef) -> Bool {
        guard classDef.systemKey == nil, (classDef.subclasses ?? []).isEmpty, (classDef.objects ?? []).isEmpty,
              (classDef.incomingLinks ?? []).isEmpty else { return false }
        context.delete(classDef)
        invalidateCaches()
        return true
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

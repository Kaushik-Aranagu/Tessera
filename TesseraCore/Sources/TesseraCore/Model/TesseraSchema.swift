import Foundation
import SwiftData

public enum TesseraSchema {
    public static let models: [any PersistentModel.Type] = TesseraSchemaV1.models

    /// What happened when the store was opened, for a calm note in the UI if it wasn't routine.
    public enum OpenOutcome: Equatable, Sendable {
        case opened
        /// The existing store couldn't be migrated. It was moved aside, untouched, and a fresh store was started.
        case recoveredWithBackup(URL)
        /// Nothing on disk could be opened; running from memory this session.
        case inMemoryFallback
    }

    /// The outcome of the last `makeContainer()` call that opened a store on disk.
    public nonisolated(unsafe) static var lastOpenOutcome: OpenOutcome = .opened

    /// Local-only store for now. Switch `cloudKitDatabase` to `.private(...)`
    /// once the iCloud entitlement is added (needs a paid developer account).
    ///
    /// Never crashes on a store it can't open: the old files are moved to a dated backup folder next to the
    /// store and a fresh store starts, so an update with a bad migration can't stop the app from launching.
    public static func makeContainer(inMemory: Bool = false, url: URL? = nil) -> ModelContainer {
        let schema = Schema(versionedSchema: TesseraSchemaV1.self)
        let configuration = url.map {
            ModelConfiguration(schema: schema, url: $0, cloudKitDatabase: .none)
        } ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)

        if let container = try? open(schema, configuration) {
            if !inMemory {
                lastOpenOutcome = .opened
            }
            return disablingAutosaveIfInMemory(container, inMemory: inMemory)
        }
        if !inMemory, let backup = moveStoreAside(configuration.url),
           let container = try? open(schema, configuration)
        {
            lastOpenOutcome = .recoveredWithBackup(backup)
            return container
        }
        lastOpenOutcome = .inMemoryFallback
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try disablingAutosaveIfInMemory(open(schema, memory), inMemory: true)
        } catch {
            fatalError("Failed to create even an in-memory ModelContainer: \(error)")
        }
    }

    private static func open(_ schema: Schema, _ configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(for: schema, migrationPlan: TesseraMigrationPlan.self, configurations: configuration)
    }

    private static func disablingAutosaveIfInMemory(_ container: ModelContainer, inMemory: Bool) -> ModelContainer {
        // In-memory stores (tests, previews) don't need autosave, and its timer could fire after a
        // short-lived container is gone.
        if inMemory, Thread.isMainThread {
            MainActor.assumeIsolated { container.mainContext.autosaveEnabled = false }
        }
        return container
    }

    /// Moves the store and its -wal/-shm and external-storage siblings into `Backups/<date>/`. Returns that folder.
    static func moveStoreAside(_ storeURL: URL) -> URL? {
        let manager = FileManager.default
        let folder = storeURL.deletingLastPathComponent()
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let backup = folder.appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent(stamp, isDirectory: true)
        let name = storeURL.lastPathComponent
        let stem = storeURL.deletingPathExtension().lastPathComponent
        guard let siblings = try? manager.contentsOfDirectory(atPath: folder.path) else { return nil }
        let related = siblings.filter { $0.hasPrefix(name) || $0.hasPrefix(".\(stem)_SUPPORT") }
        guard !related.isEmpty else { return nil }
        do {
            try manager.createDirectory(at: backup, withIntermediateDirectories: true)
            for file in related {
                try manager.moveItem(at: folder.appendingPathComponent(file), to: backup.appendingPathComponent(file))
            }
            return backup
        } catch {
            return nil
        }
    }
}

/// The schema as first shipped. When a change can't be inferred (renaming or retyping a stored property,
/// changing an attribute option such as external storage), freeze copies of the old models in a
/// `TesseraSchemaV1` namespace, add `TesseraSchemaV2`, and add a stage to `TesseraMigrationPlan`.
/// Additive changes (new defaulted properties, new models) migrate on their own.
public enum TesseraSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [ClassDef.self, FieldDef.self, ObjectRecord.self, ObjectLink.self, ViewDef.self, OpRecord.self]
    }
}

public enum TesseraMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [TesseraSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

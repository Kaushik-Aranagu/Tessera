import Foundation

/// Opens Tessera's store. One SQLite database (GRDB) holds the whole object graph.
@MainActor
public enum TesseraSchema {
    /// What happened when the store was opened, for a calm note in the UI if it wasn't routine.
    public enum OpenOutcome: Equatable, Sendable {
        case opened
        /// The existing store couldn't be opened. It was moved aside, untouched, and a fresh store was started.
        case recoveredWithBackup(URL)
        /// Nothing on disk could be opened; running from memory this session.
        case inMemoryFallback
    }

    /// The outcome of the last `makeContainer()` call that opened a store on disk.
    public static var lastOpenOutcome: OpenOutcome = .opened

    /// `Application Support/Tessera/tessera.sqlite`.
    public static var defaultURL: URL {
        let folder = URL.applicationSupportDirectory.appendingPathComponent("Tessera", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("tessera.sqlite")
    }

    /// Never crashes on a store it can't open: the old files are moved to a dated backup folder next to the
    /// store and a fresh store starts, so a bad migration can't stop the app from launching.
    public static func makeContainer(inMemory: Bool = false, url: URL? = nil) -> TesseraContainer {
        if inMemory {
            return TesseraContainer(memory: ())
        }
        let storeURL = url ?? defaultURL
        if let context = try? TesseraContext(url: storeURL) {
            lastOpenOutcome = .opened
            return TesseraContainer(context)
        }
        if let backup = moveStoreAside(storeURL), let context = try? TesseraContext(url: storeURL) {
            lastOpenOutcome = .recoveredWithBackup(backup)
            return TesseraContainer(context)
        }
        lastOpenOutcome = .inMemoryFallback
        return TesseraContainer(memory: ())
    }

    /// Moves a pre-GRDB SwiftData store (and its support files) into `Backups/<date>/` after its data moved across.
    public nonisolated static func moveStoreAsideForLegacy(_ storeURL: URL) -> URL? {
        moveStoreAside(storeURL)
    }

    /// Moves the store and its -wal/-shm siblings into `Backups/<date>/`. Returns that folder.
    nonisolated static func moveStoreAside(_ storeURL: URL) -> URL? {
        let manager = FileManager.default
        let folder = storeURL.deletingLastPathComponent()
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let backup = folder.appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent(stamp, isDirectory: true)
        let name = storeURL.lastPathComponent
        guard let siblings = try? manager.contentsOfDirectory(atPath: folder.path) else { return nil }
        let stem = storeURL.deletingPathExtension().lastPathComponent
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

/// Holds the open store. (Named for continuity with the SwiftData container it replaces.)
@MainActor
public final class TesseraContainer {
    public let mainContext: TesseraContext

    init(_ context: TesseraContext) {
        mainContext = context
    }

    init(memory _: Void) {
        // An in-memory GRDB queue can't fail to open short of running out of memory.
        // swiftlint:disable:next force_try
        mainContext = try! TesseraContext(url: nil)
        mainContext.autosaveEnabled = false
    }
}

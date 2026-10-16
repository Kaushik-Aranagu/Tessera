import Foundation
import GRDB

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

    /// Never crashes on a store it can't open. Only a store that's actually damaged (not a database, corrupt, or its
    /// schema won't migrate) is moved to a dated backup folder for a fresh start; a passing problem (a full disk, a
    /// locked file before first unlock) leaves the files alone and runs from memory this time. If the fresh store
    /// won't open either, the backup goes back. Either way a note is kept for the next launch.
    public static func makeContainer(inMemory: Bool = false, url: URL? = nil) -> TesseraContainer {
        if inMemory {
            return TesseraContainer(memory: ())
        }
        let storeURL = url ?? defaultURL
        // A restore staged last time takes its place before anything opens.
        // The real store keeps what a restore replaces in Documents/Backups (seen in Files); a store at another path
        // (tests, tools) keeps it next to itself.
        TesseraBackup.applyPendingRestore(
            to: storeURL,
            keepIn: url == nil ? TesseraBackup.keptFolder
                : storeURL.deletingLastPathComponent().appendingPathComponent("Kept", isDirectory: true)
        )
        let (container, outcome) = open(storeURL) { try TesseraContext(url: $0) }
        lastOpenOutcome = outcome
        return container
    }

    static func open(_ storeURL: URL,
                     opener: (URL) throws -> TesseraContext) -> (TesseraContainer, OpenOutcome)
    {
        let firstError: any Error
        do {
            return try (TesseraContainer(opener(storeURL)), .opened)
        } catch {
            firstError = error
        }
        guard isDamaged(firstError) else {
            setLaunchNote("Couldn't open your data just now, so nothing you do this time will be kept. "
                + "Your history is untouched; close and reopen the app.")
            return (TesseraContainer(memory: ()), .inMemoryFallback)
        }
        guard let backup = moveStoreAside(storeURL) else {
            return (TesseraContainer(memory: ()), .inMemoryFallback)
        }
        if let context = try? opener(storeURL) {
            setLaunchNote("Your data couldn't be read, so I started fresh. The old files are kept in Backups.")
            return (TesseraContainer(context), .recoveredWithBackup(backup))
        }
        moveBack(from: backup, to: storeURL)
        setLaunchNote("Couldn't open your data just now. Your history is untouched; close and reopen the app.")
        return (TesseraContainer(memory: ()), .inMemoryFallback)
    }

    /// Damage worth starting fresh for: only SQLite's own corruption codes (not a database, corrupt, bad format or
    /// schema). Anything else (a full disk, I/O, a locked file, or a decode bug in our own code) is passing: the store
    /// stays where it is and the launch note says so, so a bug never looks like a wipe (QA G2).
    nonisolated static func isDamaged(_ error: any Error) -> Bool {
        guard let error = error as? DatabaseError else { return false }
        return [ResultCode.SQLITE_CORRUPT, .SQLITE_NOTADB, .SQLITE_FORMAT, .SQLITE_SCHEMA]
            .contains(error.resultCode)
    }

    nonisolated static func moveBack(from backup: URL, to storeURL: URL) {
        let manager = FileManager.default
        let folder = storeURL.deletingLastPathComponent()
        // Anything the failed fresh open left behind goes first.
        for file in (try? manager.contentsOfDirectory(atPath: folder.path)) ?? []
            where file.hasPrefix(storeURL.lastPathComponent)
        {
            try? manager.removeItem(at: folder.appendingPathComponent(file))
        }
        for file in (try? manager.contentsOfDirectory(atPath: backup.path)) ?? [] {
            try? manager.moveItem(at: backup.appendingPathComponent(file), to: folder.appendingPathComponent(file))
        }
        try? manager.removeItem(at: backup)
    }

    // MARK: Launch note

    private nonisolated static let launchNoteKey = "tessera.launchNote"

    /// Something the app should say calmly on launch about the store (a fresh start, a migration still to come).
    /// Kept across launches until cleared, so it's never lost to a second failure.
    public nonisolated static var launchNote: String? {
        UserDefaults.standard.string(forKey: launchNoteKey)
    }

    public nonisolated static func setLaunchNote(_ note: String) {
        UserDefaults.standard.set(note, forKey: launchNoteKey)
    }

    public nonisolated static func clearLaunchNote() {
        UserDefaults.standard.removeObject(forKey: launchNoteKey)
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
        // Unique even for two moves in one second.
        let parent = folder.appendingPathComponent("Backups", isDirectory: true)
        var backup = parent.appendingPathComponent(stamp, isDirectory: true)
        var suffix = 2
        while manager.fileExists(atPath: backup.path) {
            backup = parent.appendingPathComponent("\(stamp)-\(suffix)", isDirectory: true)
            suffix += 1
        }
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

import Foundation
import GRDB

/// One-file backups (docs/research/free-signing-survival.md): a `.tessera` file is a plain SQLite copy of the store,
/// made with GRDB's backup API (consistent even with writes in flight), plus a one-row `backupInfo` table. A rolling
/// copy is written once a day and the newest 7 kept; a restore is staged and applied at the next launch, before the
/// store opens, so nothing swaps a live database. The JSON `TesseraExport` stays the readable "take my data
/// elsewhere" format.
public enum TesseraBackup {
    public static let format = "tessera-backup"
    public static let version = 1
    public static let fileExtension = "tessera"

    public struct Info: Equatable, Sendable {
        public var createdAt: Date
        public var appVersion: String?
        public var migrations: [String]
    }

    public enum BackupError: Error, Equatable {
        /// Not a Tessera backup at all.
        case notABackup
        /// A Tessera backup that won't read.
        case damaged
        /// Made by a newer build (it knows migrations this one doesn't).
        case newerSchema
    }

    // MARK: Writing

    /// Writes a consistent copy of the store to `url` (replacing anything there) and stamps it.
    @MainActor
    public static func write(from context: TesseraContext, to url: URL, now: Date = .now,
                             appVersion: String? = nil) throws
    {
        try context.save()
        try? FileManager.default.removeItem(at: url)
        let copy = try DatabaseQueue(path: url.path)
        try context.database.backup(to: copy)
        // One self-contained file: the copy inherits WAL mode from the store, which would leave -wal/-shm siblings.
        try copy.writeWithoutTransaction { try $0.execute(sql: "PRAGMA journal_mode = DELETE") }
        try copy.write { db in
            try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS backupInfo(format TEXT NOT NULL, version INTEGER NOT NULL, createdAt REAL NOT NULL,
              appVersion TEXT);
            DELETE FROM backupInfo;
            """)
            try db.execute(sql: "INSERT INTO backupInfo VALUES (?, ?, ?, ?)",
                           arguments: [format, version, now.timeIntervalSince1970, appVersion])
        }
        try copy.close()
        for sibling in ["-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: url.path + sibling)
        }
    }

    /// A stamped copy of the store file at `storeURL` (closed, at launch), for keeping what's replaced by a restore.
    nonisolated static func write(fromStoreAt storeURL: URL, to url: URL, now: Date = .now) throws {
        try? FileManager.default.removeItem(at: url)
        let source = try DatabaseQueue(path: storeURL.path)
        defer { try? source.close() }
        let copy = try DatabaseQueue(path: url.path)
        try source.backup(to: copy)
        try copy.writeWithoutTransaction { try $0.execute(sql: "PRAGMA journal_mode = DELETE") }
        try copy.write { db in
            try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS backupInfo(format TEXT NOT NULL, version INTEGER NOT NULL, createdAt REAL NOT NULL,
              appVersion TEXT);
            DELETE FROM backupInfo;
            """)
            try db.execute(sql: "INSERT INTO backupInfo VALUES (?, ?, ?, NULL)",
                           arguments: [format, version, now.timeIntervalSince1970])
        }
        try copy.close()
        for sibling in ["-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: url.path + sibling)
        }
    }

    /// Where the store a restore replaces is kept, as a stamped backup the app can restore again (undo) and Files
    /// can see.
    public nonisolated static var keptFolder: URL {
        URL.documentsDirectory.appendingPathComponent("Backups", isDirectory: true)
    }

    /// Today's rolling copy in `folder`, once a day ("Tessera-2026-10-15.tessera"), keeping the newest `keep`.
    /// Returns the file written, or nil when today's copy already exists.
    @MainActor
    @discardableResult
    public static func writeRolling(from context: TesseraContext, in folder: URL, keep: Int = 7, now: Date = .now,
                                    calendar: Calendar = .current) throws -> URL?
    {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let day = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        let file = folder.appendingPathComponent("Tessera-\(day).\(fileExtension)")
        guard !FileManager.default.fileExists(atPath: file.path) else { return nil }
        // Written under a temporary name, then renamed: a kill mid-write never leaves a partial copy.
        let partial = folder.appendingPathComponent(".\(file.lastPathComponent).partial")
        try write(from: context, to: partial, now: now)
        try FileManager.default.moveItem(at: partial, to: file)
        let copies = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            .filter { $0.hasPrefix("Tessera-") && $0.hasSuffix(".\(fileExtension)") }
            .sorted(by: >)
        for old in copies.dropFirst(keep) {
            try? FileManager.default.removeItem(at: folder.appendingPathComponent(old))
        }
        return file
    }

    // MARK: Checking

    /// Opens a backup read-only and checks it: SQLite and intact, stamped as a Tessera backup, and no newer than this
    /// build's schema.
    public static func inspect(_ url: URL) throws -> Info {
        var configuration = Configuration()
        configuration.readonly = true
        let queue: DatabaseQueue
        do {
            queue = try DatabaseQueue(path: url.path, configuration: configuration)
        } catch {
            throw BackupError.notABackup
        }
        defer { try? queue.close() }
        do {
            return try queue.read { db in
                guard try db.tableExists("backupInfo") else { throw BackupError.notABackup }
                guard try String.fetchOne(db, sql: "PRAGMA quick_check") == "ok" else { throw BackupError.damaged }
                guard let row = try Row.fetchOne(db, sql: "SELECT * FROM backupInfo"),
                      row["format"] as String? == format else { throw BackupError.notABackup }
                let migrations = try TesseraDatabaseSchema.migrator.appliedIdentifiers(db)
                let known = Set(TesseraDatabaseSchema.migrator.migrations)
                guard Set(migrations).isSubset(of: known) else { throw BackupError.newerSchema }
                return Info(createdAt: Date(timeIntervalSince1970: row["createdAt"]), appVersion: row["appVersion"],
                            migrations: migrations.sorted())
            }
        } catch let error as BackupError {
            throw error
        } catch let error as DatabaseError where error.resultCode == .SQLITE_NOTADB {
            throw BackupError.notABackup
        } catch {
            throw BackupError.damaged
        }
    }

    // MARK: Restoring

    /// Where a checked backup waits for the next launch.
    public static func pendingURL(for storeURL: URL) -> URL {
        storeURL.deletingLastPathComponent().appendingPathComponent("restore-pending.sqlite")
    }

    /// Checks a backup and stages it to replace the store at the next launch. Throws if it isn't a good backup.
    @MainActor
    public static func stageRestore(from url: URL, storeURL: URL = TesseraSchema.defaultURL) throws -> Info {
        let info = try inspect(url)
        let pending = pendingURL(for: storeURL)
        try? FileManager.default.removeItem(at: pending)
        try FileManager.default.copyItem(at: url, to: pending)
        return info
    }

    /// The restore waiting for the next launch, if any (nil when none is staged or the staged file is unreadable).
    @MainActor
    public static func pendingRestore(storeURL: URL = TesseraSchema.defaultURL) -> Info? {
        let pending = pendingURL(for: storeURL)
        guard FileManager.default.fileExists(atPath: pending.path) else { return nil }
        return try? inspect(pending)
    }

    /// Drops a staged restore, so the next launch opens the store as it is.
    @MainActor
    public static func cancelRestore(storeURL: URL = TesseraSchema.defaultURL) {
        try? FileManager.default.removeItem(at: pendingURL(for: storeURL))
    }

    /// At launch, before the store opens: if a restore is staged, the current store is first kept as a stamped
    /// backup in `keptFolder` (so the restore can be undone by restoring that), then moved aside and the staged file
    /// takes its place. Anything goes wrong, and the current store stays as it was. A staged file that turns out bad is
    /// set aside and the current
    /// store stays as it was. Returns whether a restore was applied.
    @discardableResult
    nonisolated static func applyPendingRestore(to storeURL: URL, keepIn keptFolder: URL = keptFolder,
                                                now: Date = .now) -> Bool
    {
        let manager = FileManager.default
        let pending = pendingURL(for: storeURL)
        guard manager.fileExists(atPath: pending.path) else { return false }
        guard (try? inspect(pending)) != nil else {
            let rejected = storeURL.deletingLastPathComponent().appendingPathComponent("restore-rejected.sqlite")
            try? manager.removeItem(at: rejected)
            try? manager.moveItem(at: pending, to: rejected)
            TesseraSchema.setLaunchNote("That backup couldn't be read, so your data is as it was.")
            return false
        }
        let hasStore = manager.fileExists(atPath: storeURL.path)
        if hasStore {
            // What's here now is kept first as a stamped backup he can restore again: the undo for a restore.
            // Local time in the name (UTC read a day ahead every evening).
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HHmmss"
            let stamp = formatter.string(from: now)
            let kept = keptFolder.appendingPathComponent("Before-restore-\(stamp).\(fileExtension)")
            do {
                try manager.createDirectory(at: keptFolder, withIntermediateDirectories: true)
                try write(fromStoreAt: storeURL, to: kept, now: now)
            } catch {
                TesseraSchema.setLaunchNote("Couldn't keep a copy of your data first, so I didn't restore. "
                    + "I'll try again next time.")
                return false
            }
        }
        let backup = TesseraSchema.moveStoreAside(storeURL)
        // A store that's there but wouldn't fully move aside: stop, rather than let a leftover -wal replay onto the
        // restored file.
        if hasStore, backup == nil || manager.fileExists(atPath: storeURL.path)
            || manager.fileExists(atPath: storeURL.path + "-wal")
        {
            if let backup {
                TesseraSchema.moveBack(from: backup, to: storeURL)
            }
            TesseraSchema.setLaunchNote("Couldn't restore that backup just now, so your data is as it was. "
                + "I'll try again next time.")
            return false
        }
        do {
            try manager.moveItem(at: pending, to: storeURL)
        } catch {
            if let backup {
                TesseraSchema.moveBack(from: backup, to: storeURL)
            }
            TesseraSchema.setLaunchNote("Couldn't restore that backup just now, so your data is as it was.")
            return false
        }
        TesseraSchema.setLaunchNote("Restored from your backup. What was here before is kept in Backups, "
            + "so you can restore it again.")
        return true
    }
}

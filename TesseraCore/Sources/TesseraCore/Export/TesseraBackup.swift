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
        try write(from: context, to: file, now: now)
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

    /// At launch, before the store opens: if a restore is staged, the current store goes to Backups (so it can be
    /// put back) and the staged file takes its place. A staged file that turns out bad is set aside and the current
    /// store stays as it was. Returns whether a restore was applied.
    @discardableResult
    nonisolated static func applyPendingRestore(to storeURL: URL) -> Bool {
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
        let backup = TesseraSchema.moveStoreAside(storeURL)
        do {
            try manager.moveItem(at: pending, to: storeURL)
        } catch {
            if let backup {
                TesseraSchema.moveBack(from: backup, to: storeURL)
            }
            TesseraSchema.setLaunchNote("Couldn't restore that backup just now, so your data is as it was.")
            return false
        }
        TesseraSchema.setLaunchNote("Restored from your backup. What was here before is kept in Backups.")
        return true
    }
}

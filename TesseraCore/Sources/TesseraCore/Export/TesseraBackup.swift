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
        /// When the data in this copy last came from a restore: a smaller copy after a restore is expected, not a loss.
        public var restoredAt: Date?

        public init(createdAt: Date, appVersion: String?, migrations: [String], restoredAt: Date? = nil) {
            self.createdAt = createdAt
            self.appVersion = appVersion
            self.migrations = migrations
            self.restoredAt = restoredAt
        }
    }

    /// Beside the store: when the last restore was applied, carried into every later copy's `backupInfo`.
    nonisolated static func restoreMarker(for storeURL: URL) -> URL {
        storeURL.deletingLastPathComponent().appendingPathComponent("restored-at")
    }

    nonisolated static func restoredAt(for storeURL: URL?) -> Date? {
        guard let storeURL, let text = try? String(contentsOf: restoreMarker(for: storeURL), encoding: .utf8),
              let seconds = Double(text) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    /// Before-restore copies kept (newest first).
    public static let keepBeforeRestore = 3

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
              appVersion TEXT, restoredAt REAL);
            DELETE FROM backupInfo;
            """)
            try db.execute(sql: "INSERT INTO backupInfo VALUES (?, ?, ?, ?, ?)",
                           arguments: [format, version, now.timeIntervalSince1970, appVersion,
                                       restoredAt(for: context.url)?.timeIntervalSince1970])
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
              appVersion TEXT, restoredAt REAL);
            DELETE FROM backupInfo;
            """)
            try db.execute(sql: "INSERT INTO backupInfo VALUES (?, ?, ?, NULL, ?)",
                           arguments: [format, version, now.timeIntervalSince1970,
                                       restoredAt(for: storeURL)?.timeIntervalSince1970])
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

    /// The rolling copy for his day (docs/research/backup-logical-day.md): named by `TesseraDay` in the zone in force
    /// ("Tessera-2026-10-21.tessera"), written on the first background after 04:00 and replaced by every background
    /// between 00:00 and 04:00 that night, so day D's copy holds all of D. Written under a temporary name and swapped
    /// in
    /// atomically, so a kill never leaves a day without its copy. Keeps the `keep` newest days and never deletes the
    /// file just written. If the clock reads behind the newest copy, only a missing day is written: nothing is
    /// replaced or pruned. Returns the file written, or nil when there was nothing to do.
    @MainActor
    @discardableResult
    public static func writeRolling(from context: TesseraContext, in folder: URL, keep: Int = 7, now: Date = .now,
                                    calendar: Calendar = .current) throws -> URL?
    {
        let manager = FileManager.default
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        let key = TesseraDay(calendar: calendar).day(of: now)
        let parts = calendar.dateComponents([.year, .month, .day], from: key)
        let day = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        let file = folder.appendingPathComponent("Tessera-\(day).\(fileExtension)")
        let names = try manager.contentsOfDirectory(atPath: folder.path)
        let copies = names.filter { $0.hasPrefix("Tessera-") && $0.hasSuffix(".\(fileExtension)") }.sorted(by: >)
        let newest = copies.first.flatMap { try? inspect(folder.appendingPathComponent($0)).createdAt }
        // A newest copy more than 2 days ahead is a clock that was set forward once, not one running behind: it
        // doesn't stop pruning or the late-night refresh for weeks (QA B10).
        let clockBehind = newest.map { now < $0 && $0.timeIntervalSince(now) <= 2 * 86400 } ?? false
        // A store with nothing he did (a fresh install, only the seeded catalog) is never copied: it would crowd
        // out a good copy, or replace tonight's (restore walk, risk 1).
        try context.save() // the counts below read the database (QA on #239)
        let ops = try context.database.read { try userOps(in: $0) }
        guard ops > 0 else { return nil }
        let exists = manager.fileExists(atPath: file.path)
        if exists {
            // Restored since the day's copy was made: that copy is the store from before, so it's rewritten (risk 2).
            let made = try? inspect(file).createdAt
            let restored = made.flatMap { made in restoredAt(for: context.url).map { $0 > made } } ?? false
            if !restored {
                // After 04:00 the day's copy is made; only the late tail (00:00 to 04:00) refreshes it, and never
                // with fewer of his actions than it holds.
                guard calendar.component(.hour, from: now) < TesseraDay.startHour, !clockBehind,
                      ops >= (try? userOps(at: file)) ?? 0 else { return nil }
            }
        }
        // Stray partials from a killed write (any day) go.
        for name in names where name.hasPrefix(".") && name.hasSuffix(".partial") {
            try? manager.removeItem(at: folder.appendingPathComponent(name))
        }
        let partial = folder.appendingPathComponent(".\(file.lastPathComponent).partial")
        try write(from: context, to: partial, now: now)
        if exists {
            _ = try manager.replaceItemAt(file, withItemAt: partial)
        } else {
            try manager.moveItem(at: partial, to: file)
        }
        guard !clockBehind else { return file }
        let kept = try manager.contentsOfDirectory(atPath: folder.path)
            .filter { $0.hasPrefix("Tessera-") && $0.hasSuffix(".\(fileExtension)") }
            .sorted(by: >)
        for old in kept.dropFirst(keep) where old != file.lastPathComponent {
            try? manager.removeItem(at: folder.appendingPathComponent(old))
        }
        return file
    }

    // MARK: Checking

    /// Actions he (or Tess, or Siri) took; the seeded catalog and housekeeping don't count.
    nonisolated static func userOps(in db: Database) throws -> Int {
        // Settings ops (a look tap, the migration) aren't his things: a store holding only a look is still empty.
        try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM op WHERE actor != 'system' AND instr(objectIDs, ?) = 0",
                         arguments: [SettingsStore.objectID.uuidString]) ?? 0
    }

    /// The same count in a copy on disk, opened read-only.
    nonisolated static func userOps(at url: URL) throws -> Int {
        var configuration = Configuration()
        configuration.readonly = true
        let queue = try DatabaseQueue(path: url.path, configuration: configuration)
        defer { try? queue.close() }
        return try queue.read { try userOps(in: $0) }
    }

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
                // A newer migration or a newer catalog (QA B6): "That copy is from a newer Tessera. Update first."
                guard try !TesseraDatabaseSchema.isNewer(db) else { throw BackupError.newerSchema }
                // Older copies have no restoredAt column: nil.
                let restored = (row.hasColumn("restoredAt") ? row["restoredAt"] as Double? : nil)
                    .map { Date(timeIntervalSince1970: $0) }
                return Info(createdAt: Date(timeIntervalSince1970: row["createdAt"]), appVersion: row["appVersion"],
                            migrations: migrations.sorted(), restoredAt: restored)
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
                // The 3 newest Before-restore copies are kept; older ones go (never the one just written).
                let befores = (try? manager.contentsOfDirectory(atPath: keptFolder.path)) ?? []
                for old in befores.filter({ $0.hasPrefix("Before-restore-") }).sorted(by: >)
                    .dropFirst(keepBeforeRestore)
                    where old != kept.lastPathComponent
                {
                    try? manager.removeItem(at: keptFolder.appendingPathComponent(old))
                }
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
        try? String(now.timeIntervalSince1970).write(
            to: restoreMarker(for: storeURL),
            atomically: true,
            encoding: .utf8
        )
        TesseraSchema.setLaunchNote("Restored from your backup. What was here before is kept in Backups, "
            + "so you can restore it again.")
        return true
    }
}

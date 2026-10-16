import Foundation
import os
import TesseraCore
import UniformTypeIdentifiers

extension UTType {
    /// A Tessera backup: one SQLite file (exported type declared in project.yml).
    static let tesseraBackup = UTType(exportedAs: "com.kaushikaranagu.tessera.backup", conformingTo: .data)
}

/// The daily copies (docs/research/free-signing-survival.md): once a day, on the first move to the background, a
/// `.tessera` copy goes to Documents/Backups (seen in Files, survives a bad store) and, if he picked one, to a folder
/// outside the app (iCloud Drive/Tessera), so it survives deleting the app. Seven of each are kept.
@MainActor
enum BackupKeeper {
    private static let bookmarkKey = "tessera.backupFolderBookmark"

    static var localFolder: URL {
        URL.documentsDirectory.appendingPathComponent("Backups", isDirectory: true)
    }

    /// A daily copy that didn't save: where, when and why. Shown quietly on Backups until a copy there saves again.
    struct Failure: Codable, Equatable {
        enum Place: String, Codable { case iPhone, folder }
        let place: Place
        let at: Date
        let reason: String
    }

    private static let failureKey = "tessera.backupFailures"
    private static let log = Logger(subsystem: "com.kaushikaranagu.tessera", category: "backup")

    /// The copies that failed last time they ran, by place.
    static var failures: [Failure] {
        guard let data = UserDefaults.standard.data(forKey: failureKey) else { return [] }
        return (try? JSONDecoder().decode([Failure].self, from: data)) ?? []
    }

    private static func note(_ place: Failure.Place, error: (any Error)?, now: Date) {
        var current = failures.filter { $0.place != place }
        if let error {
            log
                .error(
                    "Daily copy to \(place.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)"
                )
            current.append(Failure(place: place, at: now, reason: String(describing: error)))
        }
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: failureKey)
        }
    }

    #if DEBUG
        /// `-backupFailure`: a failed iPhone copy, to see the quiet line.
        static func simulateFailureIfRequested() {
            guard LaunchFlags.has("-backupFailure") else { return }
            note(.iPhone, error: CocoaError(.fileWriteOutOfSpace), now: AppClock.now)
        }
    #endif

    /// Writes today's copies if they're not there yet. Never throws at the caller, but a copy that fails is logged
    /// and remembered, so Backups can say so quietly (a revoked folder, a full disk) instead of looking safe.
    static func runDaily(_ context: TesseraContext, now: Date = AppClock.now) {
        do {
            _ = try TesseraBackup.writeRolling(from: context, in: localFolder, now: now)
            note(.iPhone, error: nil, now: now)
        } catch {
            note(.iPhone, error: error, now: now)
        }
        guard let folder = pickedFolder else {
            // A folder was picked but its bookmark won't resolve (deleted, iCloud signed out): a failure, not "no
            // folder", so Backups doesn't look safe while nothing is written there.
            let picked = UserDefaults.standard.data(forKey: bookmarkKey) != nil
            note(.folder, error: picked ? CocoaError(.fileNoSuchFile) : nil, now: now)
            return
        }
        let accessing = folder.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                folder.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try TesseraBackup.writeRolling(from: context, in: folder, now: now)
            note(.folder, error: nil, now: now)
        } catch {
            note(.folder, error: error, now: now)
        }
    }

    /// The folder outside the app he picked once, from its saved bookmark (refreshed when stale). Nil if none, or if
    /// it's gone.
    static var pickedFolder: URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale) else { return nil }
        if stale, url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            if let fresh = try? url.bookmarkData() {
                UserDefaults.standard.set(fresh, forKey: bookmarkKey)
            }
        }
        return url
    }

    /// Saves the picked folder (from the folder picker's security-scoped URL) and writes a copy there now.
    static func pick(_ url: URL, context: TesseraContext) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        try UserDefaults.standard.set(url.bookmarkData(), forKey: bookmarkKey)
        _ = try TesseraBackup.writeRolling(from: context, in: url, now: AppClock.now)
    }

    static func forget() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        // No folder, no folder failure to report (QA L4).
        note(.folder, error: nil, now: AppClock.now)
    }

    /// The saved bookmark itself, so a forget can be undone (held in memory for the UNDO only).
    static var bookmark: Data? {
        get { UserDefaults.standard.data(forKey: bookmarkKey) }
        set { UserDefaults.standard.set(newValue, forKey: bookmarkKey) }
    }

    /// The newest copy on this iPhone, if any.
    static var latestLocal: Date? {
        let files = (try? FileManager.default.contentsOfDirectory(at: localFolder, includingPropertiesForKeys: nil))
            ?? []
        return files.filter { $0.pathExtension == TesseraBackup.fileExtension }
            .compactMap { try? TesseraBackup.inspect($0).createdAt }
            .max()
    }

    /// A fresh copy to hand to the share/export sheet.
    static func copyForSaving(_ context: TesseraContext) throws -> URL {
        // Local date in the name, not UTC (a copy saved at 21:00 is today's).
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: AppClock.now)
        let url = URL.temporaryDirectory.appendingPathComponent("Tessera-\(day).\(TesseraBackup.fileExtension)")
        try TesseraBackup.write(from: context, to: url, now: AppClock.now)
        return url
    }
}

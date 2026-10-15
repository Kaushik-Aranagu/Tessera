import Foundation
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

    /// Writes today's copies if they're not there yet. Never throws at the caller: a missing folder or a revoked
    /// bookmark just skips that copy.
    static func runDaily(_ context: TesseraContext, now: Date = AppClock.now) {
        _ = try? TesseraBackup.writeRolling(from: context, in: localFolder, now: now)
        guard let folder = pickedFolder else { return }
        let accessing = folder.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                folder.stopAccessingSecurityScopedResource()
            }
        }
        _ = try? TesseraBackup.writeRolling(from: context, in: folder, now: now)
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
        let day = AppClock.now.formatted(.iso8601.year().month().day())
        let url = URL.temporaryDirectory.appendingPathComponent("Tessera-\(day).\(TesseraBackup.fileExtension)")
        try TesseraBackup.write(from: context, to: url, now: AppClock.now)
        return url
    }
}

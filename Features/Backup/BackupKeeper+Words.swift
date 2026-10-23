import Foundation
import TesseraCore

/// Backups in plain sentences (169, backupsV2): the copies on this phone as dates and counts, read from the files.
extension BackupKeeper {
    /// A copy on this phone: where it is and when it was made.
    struct LocalCopy: Equatable {
        let url: URL
        let createdAt: Date
    }

    /// The daily copies on this phone, newest first, at most 7.
    static func localCopies() -> [LocalCopy] {
        let files = (try? FileManager.default.contentsOfDirectory(at: localFolder, includingPropertiesForKeys: nil))
            ?? []
        let copies = files.filter { $0.pathExtension == TesseraBackup.fileExtension }
            .compactMap { url in
                (try? TesseraBackup.inspect(url).createdAt).map { LocalCopy(url: url, createdAt: $0) }
            }
            .sorted { $0.createdAt > $1.createdAt }
        return Array(copies.prefix(7))
    }

    /// "Last backup tonight, 9:14 pm. 4,210 things." The count is the whole copy, money counted and never listed.
    static func lastLine(copies: [LocalCopy], now: Date) -> String {
        guard let latest = copies.first else { return BackupWords.lastLine(createdAt: nil, things: nil, now: now) }
        return BackupWords.lastLine(createdAt: latest.createdAt, things: BackupWords.thingCount(at: latest.url),
                                    now: now)
    }
}

/// What a restore says before it runs, and for how long it can be taken back.
enum BackupPreview {
    /// How long a staged restore can be undone from Backups.
    static let undoWindow: Duration = .seconds(600)

    /// Counts only: "That copy has 4,100 things, fewer than the 4,210 you have now. ..." Nil when a count can't be
    /// read, so the older recipe line stands.
    @MainActor static func line(copyAt url: URL, replacing context: TesseraContext) -> String? {
        guard let copy = BackupWords.thingCount(at: url), let now = BackupWords.thingCount(in: context) else {
            return nil
        }
        return BackupWords.restorePreview(copyThings: copy, nowThings: now)
    }
}

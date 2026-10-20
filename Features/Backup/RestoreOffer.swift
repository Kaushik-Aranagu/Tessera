import Foundation
import TesseraCore

/// The quiet restore offer on Now (G688, hunt 28 CALL 1 B; reinstall spec section 2; Design sheets 106 section 4 and
/// 111). On a fresh store (none of his actions, no folder picked, no restore staged, not dismissed: Core's
/// `TesseraBackup.offersRestore`) Tess offers once, in one line, never a modal. A copy on this iPhone from before this
/// store began is offered by its date; with none here (a delete took Documents with it) the line points at Backups,
/// where the iCloud Drive copy is picked.
@MainActor
enum RestoreOffer {
    /// What the line offers.
    enum Offer: Equatable {
        /// A copy in Documents/Backups made before this store began.
        case copy(url: URL, createdAt: Date)
        /// No usable copy on this iPhone: "Have a copy from before? Backups, Restore."
        case backups
    }

    private static let dismissedKey = "tessera.restoreOfferDismissed"
    private static let restoredDayKey = "tessera.restoreOfferStagedAt"

    /// Where the dismissal lives; tests pass their own suite. A UserDefaults flag only, never an op and never in a
    /// backup (spec 2.3).
    static var defaults: UserDefaults = .standard

    /// "Not now", or a restore staged from the line: the offer is not made again by itself (CALL 4 A).
    static var isDismissed: Bool {
        defaults.bool(forKey: dismissedKey)
    }

    static func dismiss() {
        defaults.set(true, forKey: dismissedKey)
    }

    /// The offer to make, or nil. `fresh` is Core's condition; `copies` are the checked files on this iPhone with
    /// their stamps; `storeBornAt` is the oldest op in the live store (a copy written after it is this store's own
    /// daily copy, so it has nothing of his to bring back). A running workout or cook hides the line, since a restore
    /// would be refused then (hunt 27 CALL 3 A).
    static func offer(fresh: Bool, busy: Bool, copies: [(url: URL, createdAt: Date)], storeBornAt: Date?)
        -> Offer?
    {
        guard fresh, !busy else { return nil }
        let older = copies.filter { copy in storeBornAt.map { copy.createdAt < $0 } ?? true }
        guard let newest = older.max(by: { $0.createdAt < $1.createdAt }) else { return .backups }
        return .copy(url: newest.url, createdAt: newest.createdAt)
    }

    /// Every readable `.tessera` file in Documents/Backups with its stamp (a newer or damaged one is left out: it
    /// could not be restored).
    static func localCopies(in folder: URL = BackupKeeper.localFolder) -> [(url: URL, createdAt: Date)] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == TesseraBackup.fileExtension }
            .compactMap { url in (try? TesseraBackup.inspect(url)).map { (url, $0.createdAt) } }
    }

    // MARK: The dated launch note

    /// Remembers the stamp of a copy just staged, so the next launch can say "Restored the 3 Oct backup." in place of
    /// Core's undated "Restored from your backup." (sheet 111).
    static func rememberStaged(_ createdAt: Date) {
        defaults.set(createdAt.timeIntervalSince1970, forKey: restoredDayKey)
    }

    static func forgetStaged() {
        defaults.removeObject(forKey: restoredDayKey)
    }

    /// Core's launch note with the copy's date when a restore of a remembered copy just landed; the stamp is used once.
    static func dated(_ note: String) -> String {
        guard note.hasPrefix(RestoreOfferCopy.coreRestored),
              defaults.object(forKey: restoredDayKey) != nil else { return note }
        let stamp = Date(timeIntervalSince1970: defaults.double(forKey: restoredDayKey))
        forgetStaged()
        // Core's second sentence (a Before-restore copy was kept) stays as it is.
        return RestoreOfferCopy.restored(stamp) + note.dropFirst(RestoreOfferCopy.coreRestored.count)
    }
}

/// Every string the offer says (sheet 106 section 4, sheet 111, reinstall spec 2.4). Plain, date first.
enum RestoreOfferCopy {
    /// "A copy from 3 Oct is on this iPhone. Restore it?"
    static func offer(_ createdAt: Date) -> String {
        "A copy from \(day(createdAt)) is on this iPhone. Restore it?"
    }

    /// No copy here: the ruled line (hunt 28 CALL 1 B).
    static let backups = "Have a copy from before? Backups, Restore."
    static let backupsHint = "Opens Settings, where Backups is"

    /// The warning with the stamp, before anything is staged (sheet 111).
    static func confirm(_ createdAt: Date) -> String {
        "Restore the \(day(createdAt)) backup? This replaces what is on this phone now."
    }

    static let inIt = "In it: your objects, links, views and settings."
    static let notInIt = "Not in it: the Claude key, the bookmark, flags, Claude spend, Health and calendar copies."
    static let walled = "Private words stay walled in every copy."

    static let restore = "Restore"
    /// The second step, in place of Restore: the two-step word is the check (sheet 111).
    static let replace = "Replace what is here"
    static let replaceLabel = "Replace what is on this phone"
    static let notNow = "Not now"

    /// After staging: Core applies it at the next cold launch.
    static let staged = "It comes back the next time you open Tessera."
    static let notStaged = "That copy couldn't be staged. Nothing was replaced."
    static let newer = "This backup is from a newer Tessera."
    static let unreadable = "This backup could not be read."

    /// Refused while something runs (hunt 27 CALL 3 A): one line naming it.
    static func waits(for what: String) -> String {
        "Restore waits until \(what) is done."
    }

    /// Core's restored note starts with this; the dated one replaces it (sheet 111).
    static let coreRestored = "Restored from your backup."

    /// "Restored the 3 Oct backup."
    static func restored(_ createdAt: Date) -> String {
        "Restored the \(day(createdAt)) backup."
    }

    /// "3 Oct": the copy's own 4 AM day, as in its file name (BackupCopy.fileDay).
    static func day(_ createdAt: Date, calendar: Calendar = .current) -> String {
        let key = TesseraDay(calendar: calendar).day(of: createdAt)
        let noon = calendar.date(byAdding: .hour, value: 12, to: key) ?? key
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "d MMM"
        return formatter.string(from: noon)
    }
}

# Free signing survival: keeping Kaushik's data through 7-day re-signs

For: Core engine, iOS build, Coordinator
Date: 2026-10-15

**Answer.** When the free profile expires, Tessera stops launching but its data stays on the phone. Pressing Run in Xcode again brings it back with
the data intact. Data is only lost if the app is deleted, the bundle id changes, or the phone is erased. Today nothing protects against those three:
Core has a JSON export and a launch fallback, but no screen calls the export, and every copy lives inside the app's own container. The fix is a small
Core slice: a SQLite snapshot file (`.tessera`), a daily rolling copy, and a restore that runs at the next launch.

## What exists today (origin/master 0c0bfdb)
- Launch fallback: `TesseraCore/Sources/TesseraCore/Model/TesseraSchema.swift:30` (`makeContainer`), `:41-64` (`open`: a damaged store is moved aside,
  a passing error runs in memory), `:67-72` (`isDamaged`), `:113-134` (`moveStoreAside` into `Application Support/Tessera/Backups/<date>/`).
  `App/AppModel.swift:92-98` turns the outcome into a launch note.
- Store: `TesseraContext.swift:36-46` opens a GRDB `DatabasePool` in WAL mode. Migrations `v1` and `v2` are at `TesseraDatabaseSchema.swift:12` and
  `:46`. GRDB is 7.11.1 (`Package.resolved`).
- Export: `TesseraCore/Sources/TesseraCore/Export/TesseraExport.swift:5` is a lossless JSON export (`format "tessera-export"`, version 1). `decode`
  refuses newer versions (`:156`) and `restore` refuses a non-empty store (`:164-167`). It is tested in `ExportTests.swift:7` and `:54`. Only the
  legacy SwiftData move uses it (`TesseraLegacyStore/LegacySchema.swift:37`). No file in `App/` or `Features/` calls it, and there is no
  `fileExporter`, `fileImporter`, `UIFileSharingEnabled` or `LSSupportsOpeningDocumentsInPlace` anywhere.
- Signing: `project.yml:14` sets team WMP2WF3P54. The app uses two App IDs (`com.kaushikaranagu.tessera` and `.widgets`), and
  `App/Tessera.entitlements` asks for HealthKit.

## 1. What happens to his data
- **On expiry (day 7):** iOS will not launch the app. It opens and closes at once. Apple's DTS engineer Quinn confirms that free-provisioned apps
  "deactivate after 7 days" and that "Doing a Product > Run in Xcode should be sufficient to get the app running again" ([forum
  724896](https://developer.apple.com/forums/thread/724896)). The app and its container stay on the phone. Inferred: Apple never says "the container
  is kept" in so many words, but nothing removes it and the Run fix implies it.
- **Reinstall from Xcode, same bundle id and team:** this is an over-install, the same as an app update, so Documents, Library and UserDefaults carry
  over. Apple staff: "The bundle ID serves as the primary key associated with the application's data sandbox" ([forum
  807785](https://developer.apple.com/forums/thread/807785)).
- **Data is lost when:**
  - he deletes the app (deleting removes the app and its data; Offload keeps the data);
  - the bundle id changes, which creates a new, empty container ([forum 807785](https://developer.apple.com/forums/thread/807785));
  - he uses Erase All Content and Settings. Inferred: restoring an iCloud backup will not bring back an app that Xcode installed, because it did not
    come from the App Store.
- **Team change:** Apple staff say the container follows the bundle id. But a bundle id belongs to one team, so in practice a new team means a new
  bundle id and an empty app. Inferred.
- **The real risk:** if Xcode ever fails with a signing or "already installed" error, the obvious fix is "delete the app and run again". That wipes
  everything. Inferred from the points above. Export first, every time.

## 2. Re-signing each week with the least effort
- **Pair once, wirelessly.** In Xcode 27's Device Hub, choose Add Device (+), then Pair Nearby Device, with the iPhone on the same Wi-Fi as the Mac.
  Tap Trust and turn on Developer Mode (Settings > Privacy & Security). After an iOS update he must pair again ([Device
  Hub](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub), [Developer
  Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)). Pairing by cable also works, and afterwards Run works
  over Wi-Fi.
- **The one-minute routine (every 6 days, before expiry):** open the MacBook, open the Tessera project, choose the iPhone as the run destination,
  press Cmd-R and wait for the app to open. Keep the phone unlocked on the same Wi-Fi.
- **Limits for a Personal Team:** up to 10 App IDs at a time and 3 test devices per platform. App IDs, devices and profiles each expire after 7 days
  ([Choosing a Membership](https://developer.apple.com/support/compare-memberships)). Forum reports also say only 3 free-signed apps can be installed
  at once ([forum 724896](https://developer.apple.com/forums/thread/724896); not an official number). Tessera uses 2 App IDs. Never rename bundle ids,
  because each new name uses up another slot and starts an empty container.
- **Not allowed or risky:** AltStore-style tools refresh free signing from a helper app on the computer and need his Apple Account login
  ([AppleInsider](https://appleinsider.com/inside/ios/tips/how-to-sideload-ios-apps-to-the-iphone-with-altstore/amp)). That puts his Apple Account
  credentials in third-party software, and it still has the 3-app and 7-day limits. We do not recommend it. The only Apple route without the weekly
  re-sign is the paid Apple Developer Program (one year profiles, TestFlight).
- **HealthKit:** `v1-gap-audit.md:47` already flags this. Check tonight that the Personal Team will sign the HealthKit entitlement. If Xcode refuses,
  drop the entitlement for this install. Inferred: Apple's capability table did not render for us, so this is not confirmed.

## 3. One-file export and restore
- **Consistent copy.** Use GRDB's backup API: `try pool.backup(to: DatabaseQueue(path: tmp))`. It works on a `DatabasePool`, blocks until the copy is
  complete, and "the backup still reflects a consistent database state" even with concurrent writes ([GRDB backup
  guide](https://mintlify.wiki/groue/GRDB.swift/guides/backup)). `VACUUM INTO` also makes "a consistent snapshot" and a smaller file, but the target
  must not exist yet, and the backup API "uses fewer CPU cycles" ([SQLite VACUUM](https://Sqlite.org/lang_vacuum.html)). Inferred: `VACUUM` cannot run
  inside a transaction, which GRDB's read blocks open. Pick the backup API.
- **Format: `.tessera` is a plain SQLite file, not a zip.** Inside the copy, write a one-row `backupInfo` table: `format = "tessera-backup"`, `version
  = 1`, `createdAt`, app version, and the applied migration ids. The `grdb_migrations` table is already the schema version. A zip adds a dependency,
  because iOS has no public zip API (inferred), and gains nothing for a single file. Declare an exported UTType `com.kaushikaranagu.tessera.backup`
  with extension `tessera`, conforming to `public.data`. The JSON `TesseraExport` stays the readable "take my data elsewhere" format.
- **Rolling backup.** Once a day, on the first move to background, write `Documents/Backups/Tessera-YYYY-MM-DD.tessera` and keep the newest 7 (the
  5-year store is about 20 MB, `storage-spike.md:46`). Set `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` to YES in `project.yml`. The
  folder then shows in Files under On My iPhone > Tessera, as long as Documents holds at least one file
  ([UIFileSharingEnabled](https://developer.apple.com/documentation/bundleresources/information-property-list/uifilesharingenabled), [forum
  765329](https://developer.apple.com/forums/thread/765329)).
- **Important correction:** Documents is inside the app container, so **deleting the app deletes these copies too**. They protect against a bad store
  or a bad restore, not against losing the app. To survive deletion, let him pick a folder once (for example iCloud Drive/Tessera) with a folder
  picker. Save it as a security-scoped bookmark, and also write each day's copy there. Apple documents this flow: "Your app can even save a bookmark
  for this URL, letting it access the directory the next time it launches" ([Providing access to
  directories](https://developer.apple.com/documentation/uikit/providing-access-to-directories)). Handle a revoked bookmark calmly. Until then, a
  manual "Save a copy" through `fileExporter` to iCloud Drive does the same job.
- **Restore.** `fileImporter` for the `.tessera` type gives a security-scoped URL. Call `startAccessingSecurityScopedResource` before reading and stop
  afterwards ([fileImporter](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:))).
  Copy the file into the container, then check it: it opens read-only, `PRAGMA quick_check` returns ok, `backupInfo.format` matches, and the migrator
  is not superseded (it has no migration id this build does not know). GRDB's `hasBeenSuperseded` should cover the last check (inferred; check the
  name against 7.11.1). Stage it as `Application Support/Tessera/restore-pending.sqlite` and apply it at the next launch, before the store opens. This
  avoids swapping a live `DatabasePool` and in-memory graph. **Undo:** the current store goes through the existing `moveStoreAside` into
  `Backups/<date>/`, so "Undo restore" means staging that folder's file the same way. If the restored file will not open, the existing `moveBack` puts
  the old store back.

## 4. Smallest Core slice
`TesseraCore/Sources/TesseraCore/Export/TesseraBackup.swift`, about 150 lines, reusing `moveStoreAside`, `moveBack` and `setLaunchNote`:
- `write(from: TesseraContext, to: URL)`, `inspect(URL) throws -> BackupInfo` (errors: `notABackup`, `damaged`, `newerSchema`), `writeRolling(in: URL,
  keep: 7, now: Date)`, `stageRestore(from: URL)`, and a pending-restore step at the top of `TesseraSchema.makeContainer`.
- The app part is separate and small: two Info.plist keys and a UTType in `project.yml`, a scenePhase hook in `App/TesseraApp.swift:70`, and export,
  import and folder-pick actions placed in a designed surface, not a stock settings list.

Done when these Swift Testing cases pass in `swift test`:
1. `backupRoundTripsEverything`: back up a seeded store with uncheckpointed WAL writes. The copy's `TesseraExport` JSON equals the source's.
2. `inspectRefusesForeignDamagedAndNewer`: a text file throws `notABackup`, a truncated copy throws `damaged`, and a copy with an extra `v99`
   migration row throws `newerSchema`.
3. `rollingKeepsOnePerDayAndSeven`: ten simulated days leave 7 files, and a second write on the same day does nothing.
4. `stagedRestoreSwapsAtLaunchAndKeepsOldStore`: after `makeContainer`, the data matches the import and the previous store sits in `Backups/<date>/`.
5. `badRestoreLeavesCurrentStoreUntouched`: a corrupt pending file is moved aside, the current store opens unchanged, and a launch note is set.

## 5. Kaushik's checklist for tonight
1. Pair the iPhone in Device Hub (Pair Nearby Device on the same Wi-Fi), turn on Developer Mode, tap Trust, then press Run.
2. If Xcode refuses the HealthKit entitlement, remove it for this install. Never delete Tessera from the phone to fix an install error.
3. Add a calendar reminder every 6 days: "MacBook, open Tessera, choose iPhone, Cmd-R".
4. Until the backup slice ships, log knowing a deleted app means lost data. Keep the bundle id and team exactly as they are.

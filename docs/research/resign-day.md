# Re-sign day, Thu 22 Oct: what survives, what would lose data, the safe order (board item 92)

*Research, 2026-10-16. Checked against `origin/master` at `c5d7193` (after #221, look storage, and #226). Builds on
`free-signing-survival.md`. Times Pacific (PDT). No Swift run, no install made.*

**The answer in one line.** Pressing Run in Xcode with the same bundle id (`com.kaushikaranagu.tessera`) and the same
free Personal Team (`WMP2WF3P54`) installs over the top, like an app update. Everything below stays: his history,
the backups, the backup folder, his Claude key, his look. Only deleting the app, or changing the bundle id or team,
loses anything.

**What's signed.** `project.yml:13-15` (team `WMP2WF3P54`, Automatic signing), `project.yml:67` (app
`com.kaushikaranagu.tessera`), `project.yml:95` (widget extension `com.kaushikaranagu.tessera.widgets`). Entitlements:
`App/Tessera.entitlements:5-12` (HealthKit, App Group `group.com.kaushikaranagu.tessera`) and
`Widgets/TesseraWidgets.entitlements:5-8` (the same App Group). Both App IDs and the group must keep exactly these
names.

## What survives an install over the top

| Thing | Where it lives (master) | Survives Run over the top? | Survives deleting the app? |
|---|---|---|---|
| **His history** (the GRDB database) | `Application Support/Tessera/tessera.sqlite`, `TesseraCore/Sources/TesseraCore/Model/TesseraSchema.swift:19-24` | **Yes.** The app's container is kept on an update; the bundle id is its key | **No** |
| **The 7 daily copies on the iPhone** | `Documents/Backups/Tessera-YYYY-MM-DD.tessera`, `Features/Backup/BackupKeeper.swift:18-20`; written on the first move to the background each day (`App/TesseraApp.swift:81-85`), newest 7 kept (`TesseraCore/Sources/TesseraCore/Export/TesseraBackup.swift:120`, pruned at `:153`) | **Yes** (same container) | **No.** They sit inside the app, so they go with it (`BackupView.swift` says so in the line under the folder sentence) |
| **The 7 copies in his chosen folder** (iCloud Drive/Tessera) | Outside the app, written by `BackupKeeper.runDaily` (`BackupKeeper.swift:63-89`) | **Yes** | **Yes.** This is the copy that outlives a delete |
| **The chosen folder itself** (the bookmark that lets the app write there) | A security-scoped bookmark in standard UserDefaults, key `tessera.backupFolderBookmark` (`BackupKeeper.swift:16`, saved at `:107-116`, read and refreshed when stale at `:93-104`) | **Yes.** UserDefaults are kept on an update; a stale bookmark is refreshed on its own | **No.** He picks the folder again; the files in it are still there |
| **His Claude key** | Keychain, generic password, service `com.kaushikaranagu.tessera.anthropic`, `kSecAttrSynchronizable` false (`TesseraCore/Sources/TesseraTess/ClaudeKey.swift:22-31`), saved as `WhenUnlockedThisDeviceOnly` (`ClaudeKey.swift:48`) | **Yes.** Keychain items belong to the team id plus bundle id, which don't change. Read back on the Claude section's load (`Features/Settings/ClaudeSection.swift:220-227`) | Usually stays in the Keychain, but don't rely on it (inferred). Never in any backup by design (`ClaudeKey.swift:7-9`), so a new phone or an erase means pasting it again |
| **His look** ("Porcelain by day, Obsidian by night" or his pick) | App Group UserDefaults, suite `group.com.kaushikaranagu.tessera`, keys `look.day`, `look.night`, `look.pinned` (`DesignSystem/Looks.swift:139-152`, written at `:314-320`). Older choices in standard UserDefaults move over once (`Looks.swift:146-150`) | **Yes**, as long as the App Group stays signed. The group was verified on the free Personal Team on 2026-10-16 (`Looks.swift:139-140`, #221 commit) | **No.** It falls back to Porcelain and Obsidian. A backup does not bring it back: `adoptRestored` (`Looks.swift:159-167`) has no caller on master yet |
| **Capture-miss log** (Kitchen week one reads it) | `Application Support/Tessera/capture-misses.jsonl` (`TesseraCore/Sources/TesseraCore/Diagnostics/CaptureMissLog.swift:28-33`), excluded from device backup (`:49-52`), never in a `.tessera` copy (`:1-5`) | **Yes** | **No**, and no copy anywhere by design. Read it before any delete, or week one loses its link data |
| **Backup failure notes** | standard UserDefaults, `tessera.backupFailures` (`BackupKeeper.swift:30-51`) | Yes | No (harmless) |
| **Rest timer Live Activity** | ActivityKit, started at the first rest (`Features/Workout/LiveActivity/RestActivityController.swift:61`), picked up again on launch (`:47`), ended with the workout (`:153`). It draws the look from its own state, no App Group (`Shared/LookTable.swift:3-5`) | A running one is likely ended when the app is replaced (inferred). Nothing stored is lost: the workout lives in the database and the next rest starts a new one | n/a |
| **Siri and Shortcuts** | Six App Shortcuts declared in the app (`App/AppIntentsPackageLink.swift:13-27`), intents in `TesseraCore/Sources/TesseraIntents/Intents.swift` | **Yes.** The phrases come back with the install; a shortcut he built in the Shortcuts app keeps pointing at the same bundle id (inferred). Siri may need a minute after install to learn the phrases again | No: phrases go with the app; his own shortcuts would show the action as missing |
| **Widgets** | The extension holds only the rest Live Activity (`Widgets/TesseraWidgetsBundle.swift:5-8`). There is no Home Screen or Lock Screen widget to lose | n/a | n/a |
| **Apple Health permission** | `App/Tessera.entitlements:5-8`; the permission is tied to the bundle id | Yes (inferred) | No: he grants it again |

## What would lose data

- **Deleting the app.** Removes the database, the 7 iPhone copies, the capture-miss log, the folder bookmark and the
  look. Only the folder copies (iCloud Drive/Tessera) survive, so he'd restore from yesterday's or today's copy and
  pick the folder again. This is the one real risk, because "delete it and run again" is the usual fix for an Xcode
  install error.
- **Changing the bundle id** (in Xcode's Signing tab or `project.yml:67`). A new id is a new, empty app: the old data
  sits in the old app, which then expires. It also uses up one of the free team's 10 App IDs a week.
- **Changing the team** (signing in with another Apple Account, or "Fix issue" picking a different team). A bundle id
  belongs to one team, so in practice this forces a new bundle id: same as above. The Keychain item is tied to the team
  too, so the Claude key would be unreadable even if the data moved.
- **Letting signing lapse, then deleting.** A lapse on its own is safe: after 7 days the app opens and closes at once,
  but its data is untouched, and Run brings it back. The loss comes only if he deletes the app to "fix" it.
- **Changing the App Group id** (`group.com.kaushikaranagu.tessera` in either entitlements file or `Looks.swift:141`).
  No history is lost, but the look goes back to whatever was in standard UserDefaults before #221 (or Porcelain and
  Obsidian). If Xcode refuses the App Group on the free team on Thursday, the fix is to remove the App Group lines from
  both entitlements files for this install, not to rename it and not to delete the app. The look then may reset; the
  data does not.
- **Erasing the phone, or moving to a new phone.** Same as deleting, plus the Claude key is gone for good
  (`WhenUnlockedThisDeviceOnly`, never synced).

## The safe order on Thursday

1. **Not mid-workout.** Finish or don't start one until after. A running rest Live Activity will drop.
2. **Make sure today's copy exists.** Open Tessera, then go to the Home Screen (the day's copy is made on the first
   move to the background). Reopen, go to Review > Backups: it should say "Kept in two places" and "the last one
   today". Before 4:00 AM PT the copy is filed under yesterday's date (his 4 AM day); that is fine.
3. **On the Mac.** Build the exact commit, never master: the build on his phone (7b321d2 today) for a plain re-sign, or the pin
   SHA named in decisions.md on his "install it" (see `oct-22-list.md`). Check `git rev-parse --short HEAD` prints that SHA, run `xcodegen generate`, open the project, choose his iPhone, leave the Signing tab
   alone (team WMP2WF3P54, bundle id as is), press Cmd-R. Phone unlocked, same Wi-Fi.
4. **If Xcode shows a signing or install error: stop. Never delete the app.** Read the error first. "Untrusted
   developer" means Settings > General > VPN & Device Management > trust. A device not paired means pair again in
   Device Hub. An App Group refusal means remove the group lines for this install (above). Anything else: send the
   error text to the coordinator before touching the phone.
5. **Let the app open by itself** from Xcode. It installs over the top; no data step is needed.
6. Run the checks below.
7. Add the next reminder: Wed 28 Oct, before the same time of day as this install.

## If he ever rolls back to an older build

Current rule (pin-checklist §7, decisions 12:16 pm PT Oct 16; refreshed 12:55 pm PT, `pin-gate-dry-read.md` G27):
before the Catalog v9 pin is on his phone, the rollback build is 444e72b (v5); once the pin is installed, it is
7b321d2, the only older build tested on the v9 store (gate V4). Install the rollback over the top; never delete the
app. A re-sign builds the exact SHA installed on his phone, never master. Never restore a copy made on a newer build
onto an older one: the pin refuses a newer copy ("That copy is from a newer Tessera. Update first.", #475), and the
older builds are untested for it.

## Check right after (one line each, with what he should see)

1. **App opens straight to Now**, with no Tess note about a fresh start or moving the store aside.
2. **Review shows this week as before**: the same workouts and set counts he saw this morning.
3. **One exercise page**: its history and best still go back to before today.
4. **Review > Backups**: "Kept in two places" and "A copy is made every day, the last one today. Seven are kept."
5. **The folder sentence on Backups** reads "Also kept in Tessera.", not "a folder you choose", and no line saying
   "The folder you chose can't be reached".
6. **Files > On My iPhone > Tessera > Backups**: the same `Tessera-` files as before, at most 7, today's among them.
7. **Review > Claude**: "Key ends in ..." with the same last four characters as before, and "works". Don't paste it
   again.
8. **The look sentence on Review**: the same looks he had before (for example "Porcelain by day, Obsidian by night.").
9. **Shortcuts app > Tessera**: the six actions are there (Tell Tess, Log a Set, Undo Last Set, Start Workout, Finish
   Workout, Add Task).
10. **Next workout, first rest**: the rest timer shows on the Lock Screen in his look.

If 1 to 3 look wrong (an empty app), stop: don't log anything new and don't delete. The data is either still in the
container or in the folder copies, and a restore from Backups brings it back.

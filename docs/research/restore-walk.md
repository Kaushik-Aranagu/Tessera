# Restore walk: delete, reinstall, restore from the iCloud Drive copy (board item 94)

*Research, 2026-10-16. Checked against `origin/master` at `e9f4a06` (merge of #233, 2026-10-15 20:27 PDT). Builds on
`resign-day.md`, which covers installing over the top. Times Pacific (PDT). Nothing was built or run; lines marked
"inferred" are read from the code and Apple's behaviour, not seen on a phone.*

**The answer in one line.** After a delete (or on a new phone) the app opens empty, with no folder and no key. He goes
to Review > Backups, taps Restore, picks the newest `Tessera-YYYY-MM-DD.tessera` in iCloud Drive/Tessera, holds
Replace, then closes Tessera from the app switcher and opens it again. Everything in the database comes back. The
folder link, his Claude key, his look, the "Misses go to Claude" choice and the capture-miss log do not.

## The walk, step by step

### 1. The app opens empty

A delete removes the app's container, so `Application Support/Tessera/tessera.sqlite` is gone
(`TesseraCore/Sources/TesseraCore/Model/TesseraSchema.swift:19-24`). The first launch makes a fresh store and seeds the
built-in classes, the exercise library and the starter plan (`App/AppModel.swift:85-86`). Nothing on screen says "you
had data before" or "restore from your folder": there is no launch note for a fresh install
(`AppModel.swift:96-101` only speaks for a recovered or in-memory store).

### 2. Getting to Backups

Review is one of Home's pages (`Features/Home/HomeSpatialView.swift:218`). At the foot of Review, under the look
sentence and the CLAUDE section, sits the label word **"Backups"** (`Features/Review/ReviewView.swift:228-236`). Tap it.

What Backups says on a fresh install (`Features/Backup/BackupView.swift`):

- "your history" (`:43`)
- **"Kept on this iPhone"** (`:48-49`, because no folder is picked)
- If he hasn't left the app yet: "The first copy is made when you leave the app today." (`:293`). Once he has, "A copy
  is made every day, the last one today. Seven are kept." (`:300`). Careful: that "today" copy is a copy of the
  **empty** store (see Gap 2).
- "Also keep them in **a folder you choose**." (`:304-311`)
- "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them." (`:89-91`)
- Two label words: **"Save a copy"** and **"Restore"** (`:98-104`)

### 3. The folder link did not survive

The folder is remembered only as a security-scoped bookmark in standard UserDefaults, key
`tessera.backupFolderBookmark` (`Features/Backup/BackupKeeper.swift:16`, saved at `:114`, read at `:93-104`).
UserDefaults live in the app's container, so a delete wipes them. The files in iCloud Drive/Tessera are untouched.

Because the key is simply absent (not present and broken), the app does not say the folder is lost. The line "The folder
you chose can't be reached, so copies are only on this iPhone. Choose it again." (`BackupView.swift:317-318`) only
shows when a bookmark exists but won't resolve (`BackupKeeper.swift:70-75`). After a delete he sees the plain "a folder
you choose" sentence, as if he had never picked one. He must pick iCloud Drive/Tessera again by tapping "a folder you
choose" (`BackupView.swift:79-85`, `:135-143`); on success: "Saved a copy there. One a day from now on." (`:139`).

**Do this after the restore, not before.** Picking the folder writes a copy of the current store there at once
(`BackupKeeper.swift:115`). Before the restore that is the empty store (see Gap 1).

### 4. Picking the copy

Tap **"Restore"**. The Files picker opens for `.tessera` files and plain data (`BackupView.swift:144-147`). He goes to
iCloud Drive > Tessera and picks the newest `Tessera-YYYY-MM-DD.tessera` (names from
`TesseraCore/Sources/TesseraCore/Export/TesseraBackup.swift:125-128`; the date is his 4 AM day).

The app checks the file before anything else (`BackupView.swift:210-232`, `TesseraBackup.inspect` at
`TesseraBackup.swift:163-195`: SQLite, intact, stamped, not from a newer build) and copies it into the app.
What he may see:

- Good copy: **"Replace everything with the copy from <weekday, day, month>?"** (`BackupView.swift:164`; the date is
  the copy's `createdAt`, written with `BackupCopy.day` at `:326-328`). Below it the hold key **Replace** with "Hold"
  beside it (`:168-172`), and **"Keep what's here"** (`:174-175`).
- A copy made by a newer build than the one he just installed: "That copy is from a newer Tessera. Update first."
  (`:227-228`). So install current master, never an older fallback, before restoring.
- Anything else (not a backup, damaged, could not be read): "That file isn't a Tessera backup." (`:229-230`).

### 5. Holding Replace

Replace is a hold key (`PaintKey`, `BackupView.swift:168`), 0.9 s by default (`DesignSystem/Theme.swift:571`,
`DesignSystem/Paint.swift:235`). Once held, the copy is staged as `Application Support/Tessera/restore-pending.sqlite`
(`TesseraBackup.swift:200-212`). Nothing is replaced yet. He sees:

- "What's here now is kept in Backups, so this can be undone." (`BackupView.swift:239`)
- **"A restore is waiting"** (`:181`)
- "The copy from <date> replaces everything the next time Tessera opens. Close Tessera from the app switcher to restore
  now." (`:184-185`)
- **"Cancel restore"** (`:189-193`); if tapped: "Cancelled. Nothing will be replaced."
- If staging failed: "That copy couldn't be staged. Nothing was replaced." (`:242`)

### 6. Close and reopen: the restore is applied

The swap happens at the next launch, before the store opens (`TesseraSchema.swift:35-42`, calling
`TesseraBackup.applyPendingRestore` at `TesseraBackup.swift:233-303`). Just going to the Home Screen and back is not a
launch; he must swipe Tessera away in the app switcher, then open it.

At that launch, in order:
1. The staged file is checked again. If it is bad, it is set aside and the store stays (`:240-246`).
2. The current store (the near-empty one from step 1) is kept as **`Before-restore-YYYY-MM-DDTHHMMSS.tessera`** in
   `Documents/Backups` (`:247-258`). Only the **3 newest** Before-restore copies are kept (`:259-266`,
   `keepBeforeRestore = 3` at `:41`). These are his undo: restoring one puts things back as they were.
3. The store is moved aside, the staged file takes its place (`:273-294`), and a `restored-at` marker is written
   beside it (`:295-299`), carried into every later copy's stamp (`:29-38`, `:73`).

The line he then sees in the Ask bar at the bottom (`Features/Command/BottomChrome.swift:107-109`):
**"Restored from your backup. What was here before is kept in Backups, so you can restore it again."**
(`TesseraBackup.swift:300-301`). It stays until he opens Tess (`BottomChrome.swift:371-375`).

If something went wrong instead, one of these (all in `TesseraBackup.swift`):
"That backup couldn't be read, so your data is as it was." (`:244`);
"Couldn't keep a copy of your data first, so I didn't restore. I'll try again next time." (`:268-269`);
"Couldn't restore that backup just now, so your data is as it was. I'll try again next time." (`:282-283`);
"Couldn't restore that backup just now, so your data is as it was." (`:292`).

### 7. Undo, if the wrong copy went in

Review > Backups > Restore, then in the picker: On My iPhone > Tessera > Backups > the newest `Before-restore-...`
file. Same hold, same close and reopen. On a fresh install the Before-restore copy is just the empty starter store, so
"undo" there means "back to empty".

### 8. After the restore

- Pick the folder again: tap "a folder you choose", choose iCloud Drive/Tessera. The hero then reads
  **"Kept in two places"** and "These survive deleting the app." (`BackupView.swift:48-49`, `:91`).
- Paste his Claude key again (below).
- Pick his look again if it was not Porcelain by day, Obsidian by night.
- Grant Apple Health again when asked (the permission belongs to the install, inferred).

## What comes back

Everything that lives in the one SQLite file, because a `.tessera` copy is a full GRDB backup of the store
(`TesseraBackup.swift:56-79`). That is all six tables from `TesseraDatabaseSchema.swift` (`v1` to `v3`):

| Comes back | Where it lives |
|---|---|
| All his objects: workouts, sets, exercises, routines, plans, tasks, notes, recipes, groceries, his custom classes and fields | `object`, `classDef`, `fieldDef`, `link` tables |
| The op log, so history, undo records, PRs, trends and weekly sets read the same | `op` table (with `route`, `model`, `zone` from v2 and v3) |
| Saved views | `viewDef` table |
| Tess usage this month ("This month $x of $10."), and the last key check's outcome | `tessCall` objects (`TesseraCore/Sources/TesseraTess/ClaudeKey.swift:153-156`), read by `ClaudeSection.swift:143`, `:253-256`. They show again once the key is back |
| When the last restore happened | `restored-at` marker, rewritten by this restore |

Object ids are kept, so links between objects and any Shortcut parameter that names a routine still point at the same
thing (inferred).

## What does not come back

| Lost | Where it lived | Why | What he sees |
|---|---|---|---|
| **The folder link** | Standard UserDefaults, `tessera.backupFolderBookmark` (`BackupKeeper.swift:16`) | Gone with the container. A security-scoped bookmark can't be carried in a backup anyway | "Also keep them in a folder you choose." No hint he had one |
| **His Claude key** | Keychain, service `com.kaushikaranagu.tessera.anthropic`, not synced (`ClaudeKey.swift:23-31`), `WhenUnlockedThisDeviceOnly` (`:48`). Never in a backup by design (`:7-9`) | On a new phone it is gone for good. After a delete on the same phone a Keychain item can outlive the app, but don't rely on it (inferred) | CLAUDE: "Tess thinks **on this phone** only." and "Add a Claude key" (`ClaudeSection.swift:124-131`) |
| **His look** | App Group UserDefaults `group.com.kaushikaranagu.tessera`, keys `look.day`, `look.night`, `look.pinned` (`DesignSystem/Looks.swift:141`, `:191-195`, written at `:314-321`) | Not in the database, so not in a copy. `adoptRestored` (`Looks.swift:159-167`) exists for exactly this but **has no caller on master**, and the backup carries no look to give it | Porcelain by day, Obsidian by night (`Looks.swift:205-209`) |
| **"Misses go to Claude: yes/no"** | `@AppStorage("tess.missesGoToClaude")`, standard UserDefaults, default `true` (`ClaudeSection.swift:59`) | UserDefaults | Back to **yes**. If he had set "no", captures the phone can't read go to Claude again as soon as he pastes the key |
| **Capture-miss log** (Kitchen week one reads it) | `Application Support/Tessera/capture-misses.jsonl`, excluded from device backup (`TesseraCore/Sources/TesseraCore/Diagnostics/CaptureMissLog.swift:28-33`, `:49-52`), never in a copy (`:1-5`) | By design it never leaves the phone | Week one's miss data starts again from zero |
| **The 7 copies on the iPhone** and any old Before-restore copies | `Documents/Backups` (`BackupKeeper.swift:18-20`, `TesseraBackup.swift:107-109`) | Inside the container | Only the iCloud Drive copies remain |
| **Siri and Shortcuts** | Six App Shortcuts declared in the app (`App/AppIntentsPackageLink.swift:13-27`) | The six phrases come back with the install. Shortcuts he built himself in the Shortcuts app may show the Tessera action as missing and need it added again (inferred) | Siri may need a few minutes to learn the phrases |
| **Backup failure notes, launch note** | Standard UserDefaults, `tessera.backupFailures` (`BackupKeeper.swift:30`), `tessera.launchNote` (`TesseraSchema.swift:99`) | UserDefaults | Nothing; harmless |
| **Apple Health permission** | The system, per install | Inferred | Asked again |
| **A running rest Live Activity** | ActivityKit | Ends with the app | Nothing stored is lost |

That is every UserDefaults key on master: `tessera.backupFolderBookmark`, `tessera.backupFailures`,
`tessera.launchNote`, `tess.missesGoToClaude` (standard), and `look.day`, `look.night`, `look.pinned` (App Group). None
is in a backup.

## Gaps found on the walk

**Gap 1. Picking the folder before restoring can spoil the folder copies.** `BackupKeeper.pick` writes a copy of the
current store straight away (`BackupKeeper.swift:107-116`) through `writeRolling` (`TesseraBackup.swift:120-157`). On a
fresh install that store is empty. If today's file is missing in the folder (new phone, or he deleted before leaving
the app today), an empty `Tessera-<today>.tessera` becomes the newest copy and the oldest good copy is pruned (`:150-155`).
Between 00:00 and 04:00 it is worse: today's good file exists and is **replaced** with the empty one (`:134-148`). The
same happens on every daily run while the store is empty.

**Gap 2. The iPhone's "today" copy after a restore is the empty one.** His first trip to the background on the fresh
install writes `Documents/Backups/Tessera-<today>.tessera` from the empty store (`App/TesseraApp.swift:83-85`). After
the restore, that file exists, so `writeRolling` won't refresh it until the next day (`TesseraBackup.swift:134-137`).
Backups still says "the last one today", which is true but of the wrong data until tomorrow. The same applies to a
folder file written empty under Gap 1.

**Gap 3. Nothing tells him a restore is possible.** A fresh install looks exactly like a first install. No line on Home
or Backups says "reinstalled? restore from your iCloud Drive copy", and the folder sentence doesn't mention he had a
folder.

**Gap 4. The look is not in the backup, and `adoptRestored` is never called.** The method and its rule (apply only if
this phone never chose a look) are ready in `Looks.swift:154-167`, but no copy stores the look and no launch path calls it.

**Gap 5. "Misses go to Claude" resets to yes.** A privacy choice kept outside the database (`ClaudeSection.swift:59`).

**Gap 6. The Claude section doesn't say why the key is missing.** After a restore the database shows months of Claude
use, but the section says "Tess thinks on this phone only." with no word that the key stayed on the old phone.

**Gap 7. The confirm date can differ from the file name.** The file is named by his 4 AM day; the question shows the
copy's `createdAt` day (`BackupView.swift:164`). A copy written at 01:30 Friday is `Tessera-<Thursday>.tessera` but asks
"Replace everything with the copy from Friday ...?". Small, but it is the one moment he needs to be sure.

**Gap 8. One error line for every bad pick.** A damaged copy, a non-backup and a file the picker couldn't read all say
"That file isn't a Tessera backup." (`BackupView.swift:229-230`), though `inspect` knows `damaged` apart
(`TesseraBackup.swift:43-50`).

**Not a gap, by design:** his Claude key never in a backup, the capture-miss log never leaves the phone.

## Fix list

| # | Gap | Proposed fix | Owner | Size |
|---|---|---|---|---|
| 1 | Empty store overwrites or crowds out good folder copies | `writeRolling` skips writing when the store has no user ops (only the seeded catalog), and never replaces a day's file with one that has fewer ops than it. One count query before the write, plus a test | Core | Small (about 20 lines and 2 tests) |
| 2 | Stale "today" copy after a restore | In `writeRolling`, let a day's file be replaced when the `restored-at` marker is newer than that file's `createdAt`. The marker already exists (`TesseraBackup.swift:29-38`) | Core | Small (a few lines and a test) |
| 3 | No hint that a restore is possible | When the store holds no user ops, Backups adds one line under the hero: "Reinstalled? Restore brings back your copy from iCloud Drive." Home's first launch can say the same once in the Ask bar | Builder B | Small |
| 3b | Folder forgotten silently | Store the folder's display name (not the bookmark) in the database when he picks it. After a restore, when no bookmark exists, Backups says "Your copies were kept in iCloud Drive/Tessera. Choose it again." on the folder sentence | Core (a settings value in the store) + Builder B (the line) | Small |
| 4 | Look lost | Core keeps `look.day`, `look.night`, `look.pinned` in the database (a settings object written when he changes look, so it rides in every copy). Builder A writes them on each look change and, at launch after a restore (fresh `restored-at` marker), calls `ThemeStore.adoptRestored`. Its "never chosen" rule already protects a look chosen on this phone | Core + Builder A | Small to medium (needs the settings object first) |
| 5 | "Misses go to Claude" resets to yes | Move the choice into the same settings object in the database instead of `@AppStorage` | Builder B (on Core's settings object) | Small |
| 6 | Key missing without explanation | When there is no key but the store has `tessCall` records, the CLAUDE section reads "Your key stays on the phone it was added on. Paste it again to let Tess ask Claude." in place of the plain line | Builder B | Tiny |
| 7 | Confirm date differs from file name | Show the file's day (his 4 AM day, `TesseraDay`) in "Replace everything with the copy from ...?", not the raw `createdAt` day | Builder B | Tiny |
| 8 | One error line for every bad pick | Split `damaged` from `notABackup`: "That copy is damaged. Try the day before." | Builder B | Tiny |
| - | Capture-miss log | No change: it never leaving the phone is the point. Remind him to read it before any delete | none | n/a |
| - | His Claude key | No change: device-only by design | none | n/a |

The settings object (fixes 3b, 4, 5) is the one shared piece: a single system class in `SystemCatalog` with a few
string fields, so preferences ride in every backup like everything else. Worth doing once, then each owner moves their
keys onto it.

## What to tell him

- If the app is ever deleted, or you get a new phone, your history is safe in iCloud Drive > Tessera, as long as you
  had picked that folder in Backups before.
- To get it back: install Tessera again from the Mac (the newest build, never an older one). Open it, swipe across to
  Review, tap **Backups** at the bottom, tap **Restore**, go to iCloud Drive > Tessera, pick the newest file.
  Hold **Replace**. Then swipe Tessera away in the app switcher and open it again. You'll see "Restored from your
  backup."
- **Only then** tap "a folder you choose" and pick iCloud Drive > Tessera again. Doing it before the restore can put an
  empty copy in that folder.
- Paste your Claude key again in Review > CLAUDE. It is never in a backup.
- If your look was not Porcelain by day and Obsidian by night, tap the look sentence on Review and set it again.
- If you had set "Misses go to Claude" to no, set it to no again.
- Your own Shortcuts may need the Tessera action added again. The six built-in ones come back by themselves.
- If the wrong copy went in: Restore again and pick the newest "Before-restore" file in On My iPhone > Tessera >
  Backups. The last three are kept.
- Before ever deleting the app on purpose: read the capture-miss log first, it is not in any backup.

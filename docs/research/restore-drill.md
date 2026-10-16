# Backup and restore drill (board item 28)

For: QA, Mac lead
Date: 2026-10-16
Traced by hand from origin/master (no Swift toolchain here). Run it on the iPhone 17 simulator, DEBUG build. It takes about 20 minutes.

**What it proves.** A daily `.tessera` copy is made on the way out, a restore is staged only by holding "Replace", it is applied on the next
launch before the store opens, the old store is kept as a Before-restore copy, and that copy undoes the restore. The app never crashes on launch.

Code read: `TesseraCore/Sources/TesseraCore/Export/TesseraBackup.swift`, `TesseraCore/Sources/TesseraCore/Model/TesseraSchema.swift`,
`Features/Backup/BackupKeeper.swift`, `Features/Backup/BackupView.swift`, `Features/Review/ReviewView.swift:210`, `App/TesseraApp.swift`,
`App/AppModel.swift`, `Features/Demo/DemoData.swift`, `DesignSystem/Paint.swift` (PaintKey), `docs/research/free-signing-survival.md`,
`docs/qa/review-112.md`, `docs/qa/review-118.md`.

## Where the files are

Set these once in Terminal (after the app is installed):

```bash
APP=com.kaushikaranagu.tessera
DATA=$(xcrun simctl get_app_container booted $APP data)
SUP="$DATA/Library/Application Support/Tessera"
DOCS="$DATA/Documents/Backups"
```

| File | Where | Made by |
|---|---|---|
| `tessera.sqlite` (+ `-wal`, `-shm`) | `$SUP` | the live store |
| `restore-pending.sqlite` | `$SUP` | holding "Replace" (`stageRestore`) |
| `restore-rejected.sqlite` | `$SUP` | a staged file that fails the check at launch |
| `Backups/<UTC stamp, e.g. 2026-10-16T09-15-12Z>/tessera.sqlite` (+ `-wal`, `-shm`) | `$SUP` | the old store, moved aside by a restore (`moveStoreAside`) |
| `Tessera-YYYY-MM-DD.tessera` (newest 7 kept) | `$DOCS` | the daily copy on the first move to background |
| `.Tessera-YYYY-MM-DD.tessera.partial` | `$DOCS` | only while a daily copy is being written; must never stay |
| `Before-restore-YYYY-MM-DDTHHMMSS.tessera` | `$DOCS` | the launch that applies a restore (the undo) |
| `Tessera-YYYY-MM-DD.tessera` | the picked user folder | same daily copy, if a folder was picked |

Notes from the code:
- The Before-restore copy goes to `Documents/Backups`, not `Application Support/Tessera`. Its stamp is built from the real clock in UTC
  (`applyPendingRestore` uses `.now`, not `AppClock`), so it ignores `-demoTime`. The exact stamp text (hand traced from
  `ISO8601FormatStyle ... .timeSeparator(.omitted).dateTimeSeparator(.standard)`) should look like `2026-10-16T091512`; record what you see.
- The daily copy's day comes from `AppClock.now` and the local calendar.
- A daily copy is written once per day per folder. If today's file already exists, nothing new is written. So start from a clean install.

Useful commands:

```bash
# Launch (cold) with arguments, killing any running copy first
xcrun simctl launch --terminate-running-process booted $APP -demoTime 18:10 -resetDemo
# Kill (same as swiping it away in the app switcher)
xcrun simctl terminate booted $APP
# Send Tessera to the background without killing it (opens Settings on top)
xcrun simctl launch booted com.apple.Preferences
# List backup files
ls -la "$SUP" "$SUP/Backups" "$DOCS" 2>/dev/null
# Read a copy's stamp and schema
sqlite3 "$DOCS/Tessera-$(date +%F).tessera" "select * from backupInfo; select identifier from grdb_migrations;"
# Find the markers in any store or copy
sqlite3 <file> "select title from object where deletedAt is null and (lower(title) like '%oat milk%' or lower(title) like '%saffron%');"
```

The markers are two grocery items added through Tess: `buy oat milk` before the copy and `buy saffron` after it. Check the exact title Tess
stores the first time and use it from then on.

**Important.** Only the first launch of the drill uses `-resetDemo`. `DemoData.prepare` runs after `makeContainer`, so `-resetDemo` on a later
launch wipes the restored data right after the restore is applied. `-demo` on a later launch can also add the demo plan on top. Every later launch
uses `-demoTime 18:10` alone.

## The drill (10 steps)

### 1. Make data
- Do: `xcrun simctl uninstall booted $APP`, then install the DEBUG build (Xcode Run, or `xcrun simctl install booted <path>/Tessera.app`).
  `xcrun simctl launch --terminate-running-process booted $APP -demoTime 18:10 -resetDemo`. In the Ask bar type `buy oat milk` and send.
- Expect: the demo day at 18:10. Oat milk shows in Groceries. `ls "$SUP"` shows `tessera.sqlite`, `tessera.sqlite-wal`, `tessera.sqlite-shm` and
  nothing named `restore-*`. `$DOCS` does not exist yet.
- Fail: a crash, a launch note in the Ask bar, any `restore-*` file, or a file already in `$DOCS`.

### 2. Take a copy
- Do: `xcrun simctl launch booted com.apple.Preferences` (Tessera goes to the background), wait 5 seconds, then bring Tessera back
  (tap its icon, or `xcrun simctl launch booted $APP -demoTime 18:10`, which only foregrounds a running app). Go to Review, scroll to the foot,
  tap "Backups".
- Expect: `$DOCS/Tessera-YYYY-MM-DD.tessera` (today) exists and no `.partial` file. `sqlite3` on it shows a `backupInfo` row
  `tessera-backup|1|<seconds>|` (appVersion is empty) and migrations `v1`, `v2`. The oat milk marker query returns one row. On screen:
  - "your history"
  - "Kept on this iPhone"
  - "A copy is made every day, the last one today. Seven are kept."
  - "Also keep them in a folder you choose." (the last four words are the tappable value word)
  - "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them."
  - "Save a copy" and "Restore"
- Fail: no file, a `.partial` left behind, no `backupInfo`, the marker missing, or the screen still says "The first copy is made when you leave
  the app today."

### 3. Change data
- Do: go back, type `buy saffron`, send. Remove oat milk (check it off or delete it). Background again with `xcrun simctl launch booted
  com.apple.Preferences`, then come back.
- Expect: Groceries shows saffron and not oat milk. `ls -la "$DOCS"`: still exactly one `Tessera-YYYY-MM-DD.tessera` with the same size and time
  as in step 2 (once a day only). The copy still has oat milk and no saffron.
- Fail: the daily copy was rewritten (it would now hold saffron, and the drill can no longer prove anything).

### 4. Restore from the hold "Replace" key
- Do: Review > "Backups" > "Restore". In the picker go to Browse > On My iPhone > Tessera > Backups and pick `Tessera-YYYY-MM-DD.tessera`.
- Expect: "Replace everything with the copy from Friday, October 16?" (en_US; en_GB reads "Friday 16 October"), a "Replace" key with "HOLD"
  beside it, and "Keep what's here". A short tap on Replace does nothing. No `restore-pending.sqlite` yet. Now press and hold Replace for about
  one second (0.9 s, finger still).
- Expect after the hold: the line "What's here now is kept in Backups, so this can be undone." and a block:
  - "A restore is waiting"
  - "The copy from Friday, October 16 replaces everything the next time Tessera opens. Close Tessera from the app switcher to restore now."
  - "Cancel restore"
- Files: `$SUP/restore-pending.sqlite` exists and has the oat milk marker. Groceries in the app still shows saffron (nothing swaps live).
- Fail: a tap stages it, the live data changes before relaunch, no pending file, or "That copy couldn't be staged. Nothing was replaced."

### 5. Relaunch (the restore is applied here)
- Do: `xcrun simctl terminate booted $APP`, then `xcrun simctl launch booted $APP -demoTime 18:10` (no `-resetDemo`, no `-demo`).
- Expect: no crash. The Ask bar shows "Restored from your backup. What was here before is kept in Backups, so you can restore it again." Files:
  `restore-pending.sqlite` is gone; `$SUP/tessera.sqlite` is the restored file; `$SUP/Backups/<UTC stamp>/` holds the old `tessera.sqlite` and its
  `-wal`/`-shm`; `$DOCS/Before-restore-<stamp>.tessera` exists.
- Fail: a crash, any other launch note, `restore-pending.sqlite` still there, no Before-restore file, or `restore-rejected.sqlite` appears.

### 6. Compare
- Do: in the app open Groceries. Then `xcrun simctl terminate booted $APP` and run the marker query on `$SUP/tessera.sqlite`,
  on `$DOCS/Tessera-YYYY-MM-DD.tessera` and on `$DOCS/Before-restore-*.tessera`. Also compare the user rows:
  `sqlite3 <file> "select id,title from object where deletedAt is null and isClassObject=0 order by id" > out.txt` for the live store and the daily
  copy, then `diff`.
- Expect: the app and live store have oat milk and no saffron. The Before-restore copy has saffron and no oat milk. The diff between the live store
  and the daily copy is empty, or differs only in process rows that the launch tidy touched (write down any row that differs).
- Fail: saffron in the live store, oat milk missing, or the Before-restore copy missing saffron.

### 7. Undo with the Before-restore copy
- Do: launch with `-demoTime 18:10`. Review > "Backups" > "Restore" > On My iPhone > Tessera > Backups > `Before-restore-<stamp>.tessera`. Hold
  "Replace".
- Expect: "Replace everything with the copy from Friday, October 16?" then, after the hold, "A restore is waiting". `$SUP/restore-pending.sqlite`
  has saffron.
- Fail: the picker greys out the file, or "That file isn't a Tessera backup."

### 8. Relaunch to apply the undo
- Do: `xcrun simctl terminate booted $APP`, then `xcrun simctl launch booted $APP -demoTime 18:10`.
- Expect: the same "Restored from your backup..." note. Saffron is back and oat milk is gone, as at the end of step 3. A second
  `Before-restore-<stamp>.tessera` now exists (the restored state from step 5), and a second `<UTC stamp>` folder under `$SUP/Backups`.
- Fail: a crash, or data not matching step 3.

### 9. Audit the files and the note
- Do: `ls -la "$SUP" "$SUP/Backups" "$DOCS"`. Tap the Ask bar to clear the launch note, then kill and relaunch with `-demoTime 18:10`.
- Expect: no `restore-pending.sqlite`, no `restore-rejected.sqlite`, no `.partial` file, no `picked-*.tessera` left in the app's tmp
  (`ls "$DATA/tmp"`). `$DOCS` holds one daily copy and two Before-restore copies. After the relaunch there is no launch note. Backups screen line
  2 reads "A copy is made every day, the last one today. Seven are kept."
- Fail: any leftover staged or temp file, or the note coming back after it was cleared.

### 10. Cancel a staged restore
- Do: stage the daily copy again (step 4). Tap "Cancel restore". Kill and relaunch with `-demoTime 18:10`.
- Expect: "Cancelled. Nothing will be replaced." and the waiting block goes. `restore-pending.sqlite` is gone at once. After the relaunch there is
  no note, saffron is still there, and no new Before-restore file was made.
- Fail: the restore is applied anyway, or a new Before-restore file appears.

## Edge cases

### A. The user folder is missing or unreachable
Setup: in the simulator Files app make a folder "On My iPhone > TessDrill" (an iCloud Drive folder works too if the simulator is signed in).
1. Backups > tap "a folder you choose" > pick TessDrill. Expect: "Saved a copy there. One a day from now on.", hero "Kept in two places",
   "Also kept in On My iPhone/TessDrill." (the name is the last two path parts unless it is in iCloud Drive, where it reads
   "iCloud Drive/..."), "These survive deleting the app." A `Tessera-YYYY-MM-DD.tessera` is in TessDrill.
2. Cancel the picker instead. Expect: nothing changes and no message.
3. Delete TessDrill in Files, return to Tessera, background it, come back, open Backups. Expect: no crash. Either the hero falls back to
   "Kept on this iPhone" (the bookmark no longer resolves) or it still says "Kept in two places" (record which). The local daily copy is unaffected.
4. For iCloud offline: turn on airplane mode on the Mac (or sign out of iCloud in the simulator), background the app. Expect: no crash and no
   message; the local copy is still written.
- Fail: a crash, or the local copy not written because the folder failed.
- Code note: `runDaily` uses `try?` for the folder copy and `pickedFolder` only returns nil when the bookmark will not resolve. A folder that
  resolves but cannot be written is silent: the screen keeps saying "Kept in two places" and "These survive deleting the app." That is the gap.

### B. A copy from an older build or schema
1. Older schema: make a v1-only copy from the step 2 file and drop it where the picker can see it:
   ```bash
   mkdir -p "$DATA/Documents/drill"
   cp "$DOCS/Tessera-$(date +%F).tessera" "$DATA/Documents/drill/old-v1.tessera"
   sqlite3 "$DATA/Documents/drill/old-v1.tessera" "DELETE FROM grdb_migrations WHERE identifier='v2'; ALTER TABLE op DROP COLUMN route; ALTER TABLE op DROP COLUMN model;"
   ```
   Restore it (On My iPhone > Tessera > drill), hold Replace, relaunch with `-demoTime 18:10`. Expect: it is accepted, the restore note shows,
   and `select identifier from grdb_migrations` on the live store returns `v1`, `v2` (migrated forward on open). The oat milk marker is there.
2. Newer schema: `cp` again to `new-v99.tessera` and run `INSERT INTO grdb_migrations VALUES('v99');`. Pick it. Expect:
   "That copy is from a newer Tessera. Update first." and no `restore-pending.sqlite`.
3. Optional, Mac lead: build the first master commit that has `TesseraBackup.swift`, make a daily copy, reinstall today's build over it, restore
   that copy.
- Fail: the v1 copy refused, a crash on the migrating launch, or the v99 copy staged.
- Code note: `inspect` checks migrations only. It never reads `backupInfo.version`, so a future format 2 file with known migrations would be
  accepted. `appVersion` is always empty in daily and saved copies (nothing passes it), so an older build cannot be named on screen.

### C. A corrupt or zero-byte copy
1. `: > "$DATA/Documents/drill/zero.tessera"` (zero bytes). Pick it. Expect: "That file isn't a Tessera backup." Nothing staged.
2. `head -c 20000 "$DOCS/Tessera-$(date +%F).tessera" > "$DATA/Documents/drill/cut.tessera"` (truncated). Expect: "That file isn't a Tessera
   backup." (the code throws `damaged`, but the screen gives the same line as not a backup).
3. `echo hello > "$DATA/Documents/drill/text.tessera"`. Expect the same line.
4. Bad file reaching launch: stage a good copy (hold Replace), then overwrite the staged file behind the app's back:
   `xcrun simctl terminate booted $APP; echo garbage > "$SUP/restore-pending.sqlite"`, launch with `-demoTime 18:10`. Expect: no crash, the note
   "That backup couldn't be read, so your data is as it was.", `restore-rejected.sqlite` in `$SUP`, no `restore-pending.sqlite`, no
   Before-restore file, data unchanged.
- Fail: any crash, anything staged from 1 to 3, or data changed in 4.

### D. Killing the app between staging and the relaunch
1. Stage a restore (hold Replace). Then `xcrun simctl terminate booted $APP` at once (or swipe it away in the app switcher). Launch with
   `-demoTime 18:10`. Expect: the restore applies, as in step 5. This is the normal path; the screen tells him to do exactly this.
2. Stage a restore, background the app, leave it 10 minutes, come back. Expect: still "A restore is waiting"; nothing applied. Note that iOS
   may kill a backgrounded app at any time, so the restore can land on a launch he did not expect (`docs/qa/review-118.md`).
3. Stage, then log a set before killing. Expect after relaunch: the set is gone from the live data and present in the newest Before-restore copy.
4. Kill during the apply is not something simctl can time. If a Mac lead wants to try, use a 5-year store (`scripts/test.sh --scale` fixtures) and
   kill within a second of launch, several times. Expect: every following launch opens without a crash, and the data is either the old store or
   the restored one, never empty. A Before-restore file left half written must not be picked up as valid (`inspect` should refuse it).
- Fail: a crash, an empty store, or a pending restore that never applies.

### E. Restoring while a workout is running
1. Start a workout from Today, log two sets, leave the live cover open. Go to Review > Backups (use the in-app path) and stage the step 2 copy.
2. Expect before relaunch: the workout keeps running, the rest Live Activity keeps counting, and sets still save.
3. Kill and relaunch with `-demoTime 18:10`. Expect: no crash, the restore note, the workout gone (the copy had none running), What's running
   empty, and the rest Live Activity ended (`RestActivityController.update(for: nil)` on launch; check the Lock Screen and Dynamic Island).
   The two sets are in the newest Before-restore copy.
4. Restore that Before-restore copy. Expect after relaunch: the workout is back in What's running and Resume lands on the live cover.
- Fail: a crash, a Live Activity left pointing at a workout that no longer exists, or the sets lost from both the store and the Before-restore copy.
- Code note: nothing warns that a workout is running when Replace is held.

## Where the code disagrees with the rules
1. **The `-resetDemo` trap.** The restore is applied in `makeContainer`, then `DemoData.prepare` runs. Relaunching with `-resetDemo` wipes the
   restored store straight away. Not a phone bug (DEBUG only), but it will fake a failed drill.
2. **"7 daily copies plus the user folder".** The code keeps 7 in `Documents/Backups` and 7 more in the picked folder. Before-restore copies
   sit in the same `Documents/Backups` but are never pruned, and each restore also leaves a full moved-aside store in
   `Application Support/Tessera/Backups/<stamp>/` that nothing ever removes.
3. **The Before-restore copy is not under Application Support/Tessera.** It is in `Documents/Backups` (so Files can see it). The moved-aside store
   is the one under Application Support.
4. **"Last copy" is wrong after a restore.** `latestLocal` counts Before-restore files, so "the last one today" can be the restore time
   (also flagged in `review-112.md`, still open).
5. **No format version check.** `backupInfo.version` is written as 1 and never read. Only migrations decide "newer".
6. **Damaged reads as foreign.** A cut or corrupt copy says "That file isn't a Tessera backup.", not that it is damaged.
7. **The user folder can fail silently** (case A).
8. **Never crash on launch.** The restore path cannot throw. But `AppModel.init` calls `assertionFailure` if `prepareCatalog` throws, so in a
   DEBUG build a restored store the catalog cannot seed would crash at launch. Release builds continue without classes.
9. **Partial move aside.** `moveStoreAside` returns nil after a partial move without moving files back (`review-112.md`, still open). The restore
   then stops with "Couldn't restore that backup just now..." and the files that did move stay stranded; the Before-restore copy still has them.

## Open questions
1. Should Before-restore copies and the moved-aside `Application Support/Tessera/Backups/<stamp>/` folders be pruned (keep the last 2?), and
   should `latestLocal` skip Before-restore files?
2. Should the Backups screen check that the picked folder is reachable and say so, instead of "Kept in two places"?
3. Should `inspect` refuse `backupInfo.version` above 1, and should copies carry the app version so an older build can be named?
4. Should holding Replace during a running workout warn first, or wait until the workout ends?
5. `inspect` runs `PRAGMA quick_check` on the main actor (on pick, and in the view's `.task`). On a 5-year store (about 20 MB) is the pause
   noticeable? Worth timing with `--scale`.
6. Should a damaged copy get its own line ("That copy is damaged") so he knows to try another day's copy?
7. Is the Before-restore stamp in UTC the right choice, given he reads it in Files next to local-day daily copies?

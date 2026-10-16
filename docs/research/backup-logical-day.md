# Daily copies keyed by the 4 AM day: rule and 12 timelines (board item 65)

For Core's PR (name and write the daily copy by the 4 AM logical day, not the calendar date) and for QA. Traced by hand
on `origin/master` d9411a5 (no Swift toolchain here, so traced, not run). All times Pacific (America/Los_Angeles)
unless marked. "Ops to 07:42" means the copy's `op` table holds every op with `createdAt` up to 07:42.

## Where master is
- Trigger: every move to `.background` calls `BackupKeeper.runDaily` (`App/TesseraApp.swift:78-82`, `initial: true`).
- `runDaily` writes the iPhone copy, then the picked folder copy, both via `writeRolling` (`BackupKeeper.swift:63-86`).
- `writeRolling` names the file by the **calendar date** of `now` (`TesseraBackup.swift:94-96`), skips if that file
  exists (`:97`), writes `.Tessera-<day>.tessera.partial` then moves it (`:99-101`), keeps the 7 newest names (`:102-107`).
- `TesseraDay` is on master (`Engine/TesseraDay.swift:19-23`, wall-clock hour, so DST is right) and `RollForward.logicalDay`
  already calls it (`RollForward.swift:71-73`). The "off by one hour on DST days" in day-boundary.md is fixed; the copy is
  the one place still on the calendar date (day-boundary.md listed it as "stays calendar", week-one-dryrun.md shows why not).

## Target rule
1. **Key.** K = `TesseraDay(calendar:).day(of: now)` written `yyyy-MM-dd` in the calendar's zone, file `Tessera-K.tessera`.
   The calendar is the one in force at the write (`Calendar.current`), so the zone travels with the phone.
2. **Write.** On each move to background (and on `pick`): if `Tessera-K` is missing, write it. If it exists and the
   wall-clock hour is 4 or later, skip. If it exists and the hour is 00 to 03 (the late tail of day K), **replace** it.
   So the copy for day D is first written on the first background after D 04:00 and then rewritten by every background
   between 00:00 and 04:00 that night. A copy written before 04:00 always belongs to the previous logical day.
3. **Replace, not skip (recommended).** The check-in may run before he opens the app in the morning. Then the newest
   copy is `Tessera-D`; with skip it is D's morning copy and holds almost none of D; with replace it holds D up to his last
   late-night background. The morning copy it overwrites is a strict subset of the new one (same store, later), and 6
   other days remain. Replace must be atomic: write the `.partial`, then `FileManager.replaceItemAt(_:withItemAt:)`
   (`moveItem` at `:101` throws when the target exists), so a kill never leaves day K with no copy.
4. **Keep.** The 7 newest `Tessera-*.tessera` names (logical days, gaps allowed). Never delete the file just written.
   `Before-restore-*` and `.partial` files are not counted; stray `.partial` files for other days are removed.
5. **Clock behind.** If `now` is earlier than the newest copy's `backupInfo.createdAt`, write only a missing file, never
   replace, and never prune the new file (see T9).
6. **Folder mirrors.** The picked folder runs the same rule on its own files. A saved bookmark that will not resolve is a
   folder failure, not "no folder" (see T11). Missed folder days are not backfilled.

## The 12 timelines
Each step: event, then expected files. M = master, verdict, then the Swift Testing test for Core
(`TesseraCoreTests/BackupTests.swift`, inject `now:` instants and a `Calendar` fixed to the zone; never `Calendar.current`).

**T1 Normal day.** Wed 21 Oct 07:42 bg: write `Tessera-2026-10-21` (ops to 07:42, all of Tue's day). 12:10 bg, 21:00 bg:
skip. Thu 22 07:42 bg: write `-10-22` (all of Wed's day). M: same (`:94-97`, calendar date equals logical day after
04:00). **Pass.** Test `normalDayWritesOnceAfterFour`.

**T2 Late night past 00:00 and 04:00.** Wed 07:42 bg: `-10-21`. 23:05 logs a set; 23:10 bg: skip. Thu 00:20 bg: replace
`-10-21` (ops to 00:20). 01:30 capture; 01:40 bg: replace `-10-21` (to 01:40). 03:59:59 bg: replace (to 03:59). 04:00:00
bg: write `-10-22` (all of Wed incl. 00:20 to 04:00). 07:42 bg: skip. M: 00:20 writes `-10-22` (calendar Thu), every later
step skips at `:97`; `-10-22` stops at 00:20 and the late hours first appear in Fri's copy, read as Thu's day (the
week-one-dryrun partial case). **Fail.** Tests `lateNightCopyReplacesPreviousLogicalDay`, `fourAMExactlyStartsNewCopy`.

**T3 No app use for 2 days.** Fri 23 07:00 bg: `-10-23`. Sat, Sun: no foreground (a Siri set logged Sat 10:00 changes
the store but sends no background). Mon 26 08:00 bg: `-10-26` (ops to 08:00, incl. the Siri set). Files: `-23`, `-26`,
nothing for Sat or Sun, no backfill. M: same. **Pass.** Test `gapDaysAreNotBackfilled`.

**T4 First launch after install.** Mon 19 23:40 installs, logs 2 ops; 23:55 bg: empty Backups, write `-10-19`. Tue 01:10
bg: replace `-10-19`. 07:30 bg: `-10-20`. Variant: first launch Tue 01:10: first copy is `-10-19` (yesterday's date, by
the rule). Variant: picks a folder Mon 23:58: `pick` writes `-10-19` there at once (`BackupKeeper.swift:104-113`).
M: 01:10 writes `-10-20`, 07:30 skips; the variant names its first copy `-10-20`. **Fail.** Also `BackupCopy.local`
(`BackupView.swift:292-296`) says "today" by calendar date; at 01:15 with a 23:55 copy it says "yesterday": move it to
`TesseraDay.isSameDay`. Test `firstEverCopyAfterMidnightTakesYesterdaysName`.

**T5 Restore from a copy.** Tue 20 07:30 bg: `-10-20` (500 ops). 10:00 stages a restore of `-10-18` (420 ops). 10:05
relaunch: `applyPendingRestore` keeps `Before-restore-2026-10-20T100500.tessera` (`TesseraBackup.swift:199-207`), the store
is now the 18th's. 10:10 bg: skip; `-10-20` stays the pre-restore data (a second undo point). Wed 07:30 bg: `-10-21`
(restored data plus Tue's new ops, about 440). `Before-restore-*` never pruned (prefix filter `:103`). M: same files.
**Pass**, with one gap: the check-in's Q1 reads "ops lower than the day before" as "his data isn't safe" (week-one-checkin
warning 1). Proposed: a `restoredAt` column in `backupInfo` carried into later copies. Tests
`restoreDoesNotRewriteTodaysCopy`, `beforeRestoreCopiesAreNotPruned`.

**T6 DST fall back, Sun 1 Nov 2026 (01:30 twice).** Sat 31 Oct 08:00 PDT bg: `-10-31`. Sun 01:30 PDT (08:30Z) bg:
replace `-10-31`. 01:30 PST (09:30Z) bg: replace again (later ops). 03:30 PST (11:30Z) bg: replace. 04:05 PST (12:05Z)
bg: `-11-01` (holds all of Sat's 25 h day). M: 08:30Z writes `-11-01`, all later steps skip; Sunday's copy stops at the
first 01:30. **Fail.** Test `fallBackBothOneThirtiesReplaceSaturday` (instants in Z, calendar LA).

**T7 DST spring forward, Sun 14 Mar 2027.** Sat 13 08:00 PST bg: `-03-13`. Sun 01:50 PST (09:50Z) bg: replace `-03-13`.
03:10 PDT (10:10Z, 20 real minutes later) bg: replace (hour 3, still Sat's 23 h day). 04:05 PDT (11:05Z) bg: `-03-14`.
M: 09:50Z writes `-03-14`, later steps skip. **Fail.** Test `springForwardThreeTenIsStillSaturday`.

**T8 Travel to New York and back.** Mon 26 Oct 07:30 PDT bg: `-10-26`. 21:45 PDT at the gate bg: skip. Red-eye; Tue
06:50 EDT (10:50Z, 03:50 in LA) bg, zone now New York: `-10-27` (hour 6 in the zone in force). Wed 01:15 EDT (05:15Z) bg:
replace `-10-27`. Wed 07:00 EDT: `-10-28`. Home; Wed 21:40 PDT (Thu 04:40Z) bg: skip. Thu 00:30 PDT bg: replace
`-10-28`. Thu 07:30 PDT: `-10-29`. M: landing step same; Wed 01:15 EDT writes `-10-28` and 07:00 skips; Thu 00:30 PDT
writes `-10-29` and 07:30 skips. **Fail** (the two late steps). Test `travelKeysByZoneInForceAtEachWrite` (swap the
calendar's `timeZone` between calls).

**T9 Phone clock set backwards.** Files `-10-16` to `-10-22`. Thu 22 12:00 he sets the clock to Sat 10 Oct 12:00, bg: key
`-10-10` missing, write it, prune nothing (8 files). Clock back to auto; Fri 23 07:30 bg: `-10-23`, prune to the 7 newest
(`-10-10` and `-10-16` go). Variant: clock set to Thu 22 01:00 after the 07:42 copy: now is earlier than the newest
`createdAt`, so no replace of `-10-21` with data newer than its name. M: `-10-10` sorts last, `dropFirst(7)` deletes it in
the same call (`:102-107`) and `runDaily` notes success, so it looks saved; the variant replaces nothing (skip at `:97`
since `-10-22` exists by calendar), so only the base case fails. **Fail.** Test `clockSetBackNeverDeletesTheCopyJustWritten`.

**T10 8th day pruning.** Files `-10-14` to `-10-20`. Wed 21 00:30 bg: replace `-10-20`, still 7 files. 07:42 bg: write
`-10-21`, `-10-14` goes: `-10-15` to `-10-21`. Gaps: files `-10, -12, -14, -16, -18, -19, -20`; writing `-21` drops `-10`
(7 newest logical days, not 7 calendar days). `Before-restore-*` and `.partial` ignored. M: 00:30 writes `-10-21` and
prunes `-10-14` early, 07:42 skips; count right, contents wrong (as T2). **Partial.** Test `pruneKeepsSevenNewestLogicalDays`.

**T11 User folder unavailable.** Picked iCloud Drive/Tessera Mon 19 (both places get `-10-19`). Tue he deletes that folder
(or signs out of iCloud), so the bookmark won't resolve. Tue 07:30 bg: iPhone `-10-20` written; folder: nothing, and a
folder failure "the folder you chose can't be reached" is recorded and shown on Backups. Folder only moved (stale but
resolves): bookmark refreshed (`BackupKeeper.swift:94-99`), `-10-20` written at the new place. Folder back Thu: only
`-10-22` there, no backfill. M: `pickedFolder` returns nil (`:91-93`) and `runDaily` treats nil as "no folder", noting
success and clearing any old failure (`:70-72`); Backups looks safe while the folder gets nothing. **Fail.** Tests
`folderRunsTheSameRuleOnItsOwnFiles` (Core) and `unresolvableBookmarkIsAFolderFailure` (app `TesseraTests`; needs
`BackupKeeper` to take its `UserDefaults` and a folder resolver).

**T12 App killed before background.** Wed 21 07:30 opens, logs sets until 08:00, no background yet; the app is
jetsammed or crashes while active: no copy for the 21st. 12:00 relaunch, 12:05 bg: `-10-21` (ops to 12:05, incl. the
08:00 sets if they were saved). Kill mid-write at 12:05: `.Tessera-2026-10-21.tessera.partial` left, no `-10-21`; next bg
rewrites it (`:37` removes the old partial). Kill mid-replace at Thu 00:20: old `-10-21` intact. A partial for a day never
retried is removed at the next write. M: first part same; a stray partial for another day stays forever (hidden, not
pruned, `:103`). **Pass**, stray partial **Fail** (minor). Test `killedMidWriteKeepsOldCopyAndNoStrayPartial`.

Master fails: T2, T4, T6, T7, T8, T9, T11, T12 (partial file); T10 partial; T1, T3, T5 pass.
Also fix the existing `rollingKeepsOnePerDayAndSeven` to inject an LA calendar; it uses `Calendar.current` today.

## QA on the phone (3 timelines)
Read each copy on the Mac: `sqlite3 -readonly F "SELECT datetime(createdAt,'unixepoch','localtime') FROM backupInfo;
SELECT datetime(MAX(createdAt),'unixepoch','localtime') FROM op;"`. Files are in Files > On My iPhone > Tessera > Backups.

**T2 late night.** Settings > General > Date & Time: Set Automatically off. 1) Set 23:55; open Tessera, log one set,
swipe home. 2) Set 00:20 next day; open, add a capture, swipe home. 3) Set 03:58; open, log a set, swipe home. 4) Set
04:05; open, swipe home. Expect: yesterday's file `createdAt` 03:58 with the 03:58 set inside; today's file `createdAt`
04:05 with all three. No file dated today with `createdAt` 00:20. Set Automatically back on.

**T11 folder gone.** 1) Backups > pick iCloud Drive/Tessera-QA; check it gets today's file. 2) In Files, delete
Tessera-QA. 3) Next day (or after clearing today's files), open and leave Tessera. Expect: iPhone copy written; Backups
shows a quiet line that the folder can't be reached. 4) Pick a new folder; the line goes and a copy lands there.

**T12 app killed.** 1) After 04:00 with no copy for today yet, open Tessera, log a set. 2) Open the app switcher and swipe
Tessera away without going home first. 3) Check Backups in Files: note whether today's file exists (it tells us if
`.background` fires before a switcher kill). 4) Open and leave normally: today's file appears with the set inside.

## Open questions
1. Replace only between 00:00 and 04:00 (this rule), or on every background (last copy of the day wins)? Every background
   costs a full copy each time; the 5-year scale test should time `write` before choosing.
2. Siri, Lock Screen and widget writes never send a background (T3): should a write from an intent schedule a copy?
3. A restore marker in `backupInfo` (T5) so the check-in doesn't call a restore a data loss.
4. T9 clock-behind guard: write-missing-only (proposed) or skip with a visible failure?
5. Should the folder copy backfill days the folder missed from the iPhone copies (T11)?
6. `Before-restore-*` files are never pruned; keep all, or the newest 3?

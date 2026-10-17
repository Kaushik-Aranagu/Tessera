# QA review: #641 (Core, restWeekday reader, Research 146)

Head: 01347531. Real delta (three-dot): 11 files, +620/-11.

## Verdict: FIX FIRST (1 medium, 1 merge conflict), rest PASS

### Conflict
merge-tree against master 2d0f68d: CONFLICT in TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift (the `.task` receipt block that #638 rewrote sits beside the new `.setRestWeekday` case). Merge master in; keep #638's stored-title lines and the new case.

### Medium: RestWeekday.inForce falls back to the CURRENT value when the first change replaced nil
RestWeekday.swift `inForce`: `return changes.first?.old ?? current`. `old` is nil for the first write of a real install (the first-launch Sunday write, change 1: old nil, new 1). For any past day before that write, `nil ?? current` returns today's value. After he later moves rest to Friday (change 2: old 1, new 6), every week before the first launch is read as Friday rest: weeks redrawn, which is exactly RG7. The tests miss it because the fixture seeds restWeekday = 1 at init (no op, so old is 1).
Fix: separate "no change on record" from "old was nil": `if let first = changes.first { return first.old }; return current`. A nil old then means no rest weekday that day (plain week). If Product wants pre-launch Sundays dabbed, say so; either way it must not follow `current`. Add a test: nil start, first-launch write at day X, move to Friday at day Y, view a week before X: no rest marks.

### Passes
- RG1/RG2: rest weekday leaves the pool before the spread, with or without a rhythm; past rest weekday keeps its mark (wasRestWeekday); wasDue spread skips past rest weekdays. Fixed-days plans never read it (S22).
- RG3: grammar rule sits after the question check and before Rule 3; shapes anchored, bare weekday only ("rest day today", "rest day sunday morning" fall through). S17 same-day: line, no op, no UNDO.
- RG5: restDay returns nil when a planned session exists, same test as Home. NowPicker tests adjusted to match.
- First-launch write: one Tess op via WriteSettings, receipt "Sunday, rest day." thing first; skipped when a value or any change record (undone too) exists, so UNDO and "Any" stand. Copy: no "…", no em dash, no "at".
- Time zone cases S23-S27 (NY, hotel gym, Nov 1, 25-hour day) covered.

### Lows
1. App test ExerciseAndPlansTests now does `guard week.days[todayIndex].routine != nil else { return }`, so on a Sunday it passes without asserting. Pin the clock (AppClock / demoTime to a Monday) instead.
2. hasPlannedSession scans every workout object per restDay call; the comment above hasWorkoutUnderway says that path is kept cheap at any history size. Fine now (Home does the same); run `scripts/test.sh --scale` once and index by day if it shows.
3. With restWeekday set to "Any", writeFirstRestWeekday scans the whole op log on each launch (current nil, changes non-empty after the scan). Cache a "written" marker or check the cheapest record first.

## Re-verify at 7b6bc773: PASS (merge-tree clean on master)
- RG7 closed. inForce now returns `first.old` when any change exists (nil old, the first-launch write, means no rest weekday that day) and `current` only when nothing is on record. rg7AWeekBeforeTheFirstLaunchWriteHasNoRestWeekday writes Sunday on Oct 14 (old nil), moves to Friday on Oct 21, and asserts no rest marks the week of Oct 7 and a rest Sunday on the 18th.
- Lows: ExerciseAndPlansTests pins Monday Oct 19 (no more Sunday no-op). The once-per-install flag `restWeekday.firstLaunchDecided` skips the scan on later launches; hasEverBeenWritten stops at the first op on the field (undone ones count, so UNDO and "Any" stand). The flag is set in every branch except a failed write, which retries next launch.
- Ruling on the restore caveat: ACCEPT. The flag is a device-local UserDefaults bool in `.standard`, not a launch flag and not user content: it is read only by this one-time write, never enters the op log, backups, exports or logs, and nothing in BackupKeeper/BackupCopy enumerates UserDefaults, so it is clear of the data-safety rules (LaunchFlags, ProcessInfo, UITests, backups). If a backup is restored onto a fresh store while the flag is set, restWeekday stays "Any" (floating rest, same as before the feature) and "rest day Sunday" sets it in one line; nothing is lost or wrong.
- Lows (not blocking):
  1. Reset paths keep the flag: `-resetDemo` (simulator) and the in-app data reset wipe the store but not the flag, so the first demo run has a Sunday rest day and later ones do not. Make `-resetDemo` clear the key through LaunchFlags so the demo is deterministic (the in-app reset is a Product call).
  2. The app tests build AppModel on UserDefaults.standard, so the first run on a simulator writes Sunday and later runs do not; the pinned-Monday test passes either way (compactMap drops a nil Sunday) but is not asserting which. Inject a defaults suite into AppModel for tests.
  3. A write that fails every launch (`try?`) rescans the op log each launch until it succeeds; log once or set the flag after N tries.

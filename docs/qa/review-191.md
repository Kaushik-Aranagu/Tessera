# Review #191 (merged 966636f) — backup failures, D1, D3, D5: PASS (not in tonight's install)

Static review only.

## D1: can Lock Screen or Siri undo reach the 04:00 roll? No, confirmed.
- Lock Screen Undo and Siri's "Undo Last Set" both go through `UndoLastSetIntent → takeBackLatestSet`. That only
  acts on a history record that **created a set object**. The roll (`RollForwardTasks`: only `set` ops on tasks),
  the wrap-up (FinishWorkout, EndProcess) and the zero-set close (EndProcess, DeleteObject) create nothing, so they
  are skipped. A wrapped-up workout is ended, so `takeBackLatestSet` returns nil for its sets and never reopens it.
- In-app Undo words (Ask Tess bar, BottomChrome, workout, recipes, groceries, routine editor) all undo a specific
  record they hold, never "the latest", so they can't reach the roll either.
- `undoLatest()` with no actor or action now skips `.system`. It has no app caller today, so this is a guard for
  later callers. When an actor or action is named, `.system` still matches only if asked for. Tests cover it.

## D3: closed
`finishedWorkouts(on:)` always takes a moment, and `onDay:` takes a day key. WeekView and ReviewView pass keys
through `onDay:`. The remaining `on:` callers (AppModel.finishedToday, HomeSpatialView lanes: now ± 1 day) pass
moments. So there's no midnight ambiguity left.

## D5: closed
`TesseraDay.month(containing:)` has 04:00 edges, and "this month" uses it.

## Backup failures
- writeRolling is in do/catch for both places. A success clears that place's failure; no folder clears the folder
  failure. Failures live in UserDefaults (not in the store, so not in backups or exports). The reason is logged,
  not shown.
- BackupView: "Kept in two places" only shows while the folder copy has no failure. The quiet line reads
  "Today's/The last copy to <folder> didn't save. It tries again when you leave the app." It's in the context color
  and never an alarm. OK.
- B6 (low): `-backupFailure` (DEBUG) writes a real failure entry that stays until the next successful iPhone copy.
  It's only used in demos, and the phone never passes it.
- B7 (low): `failures` is read in body from UserDefaults, which isn't observed, so it refreshes on the view's
  `.task` (refresh += 1) and on revision changes. A failure that happens while Backups is open shows on the next
  open. Fine.

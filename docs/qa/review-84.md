# QA: data-safety merge #84 (17a383b, head 6bbafa4)

*Repo maintainer (QA), 2026-10-15 18:58 UTC. Static read of the diff on master; no Swift toolchain here, so the new tests (DataSafetyTests, CommaSetTests, NoteJoinTests) are Core's evidence.*

**Verdict: pass, nothing blocking the cut.**

## Fixed and checked
- D1: `ActionEngine.undoLatestSet()` undoes the newest set from any path (typed, hold, Lock Screen, Tess) and never reaches into a finished workout. `UndoLastSetIntent` uses it.
- D2: only SQLITE_CORRUPT / NOTADB / FORMAT / SCHEMA (or a non-SQLite error) moves the store to Backups. Full disk, I/O and locked-before-unlock run from memory and leave the files alone; a failed fresh open moves the backup back. `load()` only throws SQLite errors, so a bad row can't trigger a fresh start.
- D3: a failed legacy migration leaves the old store in place and retries next launch (seeded-only store is cleared first). The app still skips migration on an in-memory fallback.
- D4: exports keep fractional seconds; whole-second exports still read. Ties in history and object order now break by UUIDv7 id.
- P1: only workouts go idle. P3: Siri's Log Next Set and Finish find a set-aside workout. P2 (Core half): logging into a set-aside workout makes it running again. P4: the model gets an allow-list of person actions.
- B1: comma sets carry the exercise name, not the first part's numbers. B4: a multi-set phrase is all or nothing. K2/H5: "80x8, 80x8, 80x6" with an entry in focus is three sets, test row restored.
- B2: NoteEditor tracks a real edit, so typing back to the original after an autosave still saves. N1: split and join are exact inverses.

## Still open (not in #84)
- **B3 (iOS build, daily use):** `App/AppModel.swift` `commitCapture` keeps only the first record as `lastCapture`, so Undo after "80x8, 80x8, 80x6" removes one set of three. Fix: keep every committed record (`lastCaptures`) and undo them newest first.
- G1 (iOS build): open from the #46-#58 review.
- B5 (watch, not a fix): undated "get X" of three words or fewer is still groceries.

## Low, after the cut
- L1: `TesseraSchema.launchNote` (UserDefaults) is written but the app never reads it; the Ask bar uses `lastOpenOutcome`. So "Your older history hasn't moved across yet" is never shown, and a note from a passing failure is never cleared. Either show it in `AppModel.launchNote` and clear it on a clean open, or drop it.
- L2: a migration retry only works while the store has no op log; once Kaushik has used the app, a retry throws `storeNotEmpty` every launch, silently (`try?`). Old data stays safe in place. Fine while there is no old SwiftData store on the phone.
- L3: `ProcessTable.openWorkout` sits between the ledger's doc comment and `ledger()`, so the comment now documents the wrong function.

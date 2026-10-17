# QA review: #463 finish-early workouts reach Apple Health (Builder A, QA H1)

Head checked: `3ae3ca6` (1 commit, from master). `git merge-tree` against master is clean. Static review only; Builder A reports 443 engine and 139 app tests green.

**Verdict: PASS.**

- The fix is in HealthExporter.swift:17 and :26-29. The observer now exports on `finishWorkout` or `finishWorkoutEarly`.
- **Exactly once for each path.**
  - `FinishWorkoutEarly.apply` runs `FinishWorkout(...).apply(&transaction)` inside its own transaction (TrainingActions.swift:282-291). The engine writes one OpRecord, whose action is `finishWorkoutEarly`. No second `finishWorkout` record is made, so an early finish fires the observer once.
  - A normal finish is untouched: one `finishWorkout` record, one export.
  - Neither action calls the other through `engine.perform`, so there's no double write.
  - Health dedupes by `HKMetadataKeySyncIdentifier` anyway (#438 H2).
- **The workout is in the record.** `OpRecord.objectIDs` is every object an op touched (Models.swift:566), so it includes the workout through its `endedAt` op. The exporter's `isWorkout` filter keeps the workout and drops the skipped entries.

## Lows (non-blocking)
- L1: the new tests check only the `exports(_:)` name predicate, not the observer. A refactor that made `FinishWorkoutEarly` perform `FinishWorkout` as its own op would export twice, and these tests would still pass. A test that counts observer hits for each path would pin "exactly once". HealthKit can't run in tests, so a counting stub is enough.
- L2 (pre-existing): an early finish with no logged sets exports an empty strength workout, as a normal finish already does. Normally the wrap-up path deletes those.

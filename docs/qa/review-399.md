# QA review: #399 Core incremental OpZones and bests without a sort

Head `b1b989b` on 1698cf7. Trial merge onto master 62775b5 is clean. Four files: OpZones.swift, ObjectStore+Caches.swift, TrainingLedger.swift, TripZonesTests.swift. This is a static review; there is no Swift toolchain here.

## Verdict: FIX FIRST (one condition in `OpZonesState.set`)

### F1. "First start wins" now depends on dictionary order
The old code sorted the log by `createdAt` and kept the **earliest** start for each id (`started[id] == nil`). The new loop reads `operations.values` in dictionary order, which Swift reseeds every launch. `set(_:for:rank:at:)` (OpZones.swift, `OpZonesState`) keeps whichever rank-2 record it reads first, because `at` is only compared for rank 1.

The comment says "a workout starts once", but `starts` holds three actions: `startWorkout`, `startRoutine` and `logExercise`. Any object touched by two start records can therefore file under a different zone from one launch to the next. That includes a `logExercise` into the workout in progress, or "bench 80x8 mon" into a past day's workout (TrainingActions.swift:341-351), when it is written in another zone than the start (the trip). The first full read at launch is exactly the case where all of them arrive at once. Rank 0 has the same gap in principle, though a create only happens once.

Fix, one condition: earliest wins for ranks 2 and 0, latest wins for rank 1:
```swift
if let current = ranks[id] {
    let wins = rank > current.rank
        || (rank == current.rank && (rank == 1 ? at >= current.at : at < current.at))
    guard wins else { return }
}
```
That makes the result the same in any read order and equal to the old sorted result, ties aside. Please also add a test that drives `OpZonesState` directly with the same records in two orders (a start in New York, a later start in LA on the same id, then a finish) and expects the same zones. The new `opZonesReadsOnlyWhatIsNew` covers the incremental read, not the order.

## Checked and fine
- Ranks reproduce the old merge order: start beats finish beats create, and among finishes the latest `createdAt` wins.
- Undo marks a record `.undone` and keeps it (ActionEngine.swift:142-147), so the log still only grows. The old code didn't filter on state either.
- A restore is staged and applied at the next launch with a fresh context (BackupView.swift:266-275), so `opZonesState` never sees a swapped log.
- `rekey` and `resetUserData` can shrink or swap the log in the same session. `resetUserData` is simulator-only (ObjectStore+Lifecycle.swift:53-60). A gap can only last until the next record arrives, because unseen ids are read whenever the count moves. See L2.
- The revision gate is kept: a second read at the same revision returns the cache. A value-only change skips the walk (the count is unchanged).
- Bests: `records(for:)` reads the same sessions (`descendants` × `sessionsByClass`, the excluded workout filtered out) and makes the same strict `>` and `max` comparisons. `recordsBeaten` compares values only. So "best" receipts, the #344 flag, `shouldCelebrate` and Home's "N bests" are unchanged on any history.
- Nothing is written: no catalog bump, no schema change, no op change. `DerivedCache` is memory-only.

## Lows
- L1: tie order for `bestE1RM`. The old pass walked newest-first, so on an exact e1RM tie the newest set was kept. The index is in insertion order, so now the oldest is kept. Only the "was 82.5 × 7" hint (RecordHint.swift:32-34) and Exercise's "Best set" show the set, and the text differs only when two different weight × reps have the exact same e1RM. Fine as is; worth a sentence in the comment.
- L2: `invalidateCaches()` doesn't drop `opZonesState`. After the simulator demo reset, `seen` keeps the old ids and the count gate can skip a read once. Setting `derived.opZonesState = nil` in `resetUserData` (or in `noteChange(nil)`) closes it. That's for the demo only.
- The 1500-history number is still to come from Core. The pin's M4 gate times the restore, not this build, so the gate doesn't depend on that number.

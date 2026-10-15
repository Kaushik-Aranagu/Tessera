# QA review: data safety (storage, op log and undo, export)

*Repo maintainer, 2026-10-15. This was a static read of master (after #77), with no Swift toolchain, so nothing was compiled or run. It covers the engine's data path from the merges #6, #8, #12, #13, #14, #17, #20, #22 and #33. Core owns everything here.*

## Findings

- **D1 (high): "Undo Last Set" removes the wrong set.** `TesseraCore/Sources/TesseraIntents/Intents.swift:66`, with matching in `Actions/ActionEngine.swift:148-156`
  - **What's wrong:** the undo only looks for records named `logSet`. Holding the prefill and the Lock Screen's Done both log through `LogNextSet`, which is recorded as `logNextSet` (`Training/Prefill.swift:64-66`). `TrainingActions.swift:314` also wraps `LogSet` in its own record.
  - **Failure:** type set 1, hold the prefill for sets 2 and 3, then say "Undo Last Set" in Siri or Shortcuts. Set 1 is removed, set 3 stays, and the dialog says "Last set removed". With no typed set in this workout, it deletes a typed set from an older, finished workout.
  - **Fix:** match every action that creates a set, or better, undo the newest record in the running workout that created a set object.
- **D2 (medium): any error opening the database swaps in an empty store, and a second failure hides it.** `Model/TesseraSchema.swift:36-41`
  - **What's wrong:** every open error is treated as corruption and the store is moved to `Backups/`, including a full disk, an I/O error, or files still locked before first unlock.
  - **Failure:**
    1. On a full disk, the move (a rename) succeeds and the fresh open fails, so the app runs from memory.
    2. On the next launch `tessera.sqlite` is gone, so an empty store opens as `.opened` with no note.
    3. The whole history now sits only in `Backups/`, and the app has no way back to it.
  - **Fix:** move the store aside only for `SQLITE_CORRUPT`/`SQLITE_NOTADB` or a failed migration, and fall back to memory without moving anything otherwise. If the fresh open fails after a move, move the backup back. Persist the "recovered" note.
- **D3 (medium): one failed SwiftData migration strands the old data for good.** `App/TesseraApp.swift:23-25` (`try? LegacyStore.migrate`), `TesseraLegacyStore/LegacySchema.swift:33-37`, `Export/TesseraExport.swift:158-160`
  - **What's wrong:** the error is swallowed, then `prepareCatalog()` seeds and saves into the new store.
  - **Failure:** on every later launch, `restore(into:)` throws `storeNotEmpty`, which is swallowed too. The old data is never moved across or set aside, no note appears, and the pre-GRDB history stays invisible.
  - **Fix:** migrate before seeding, or let restore proceed when only seeded content exists. Keep a persistent "migration pending" flag and show a launch note on failure.
- **D4 (medium): export and the SwiftData move drop fractional seconds from every date.** `Export/TesseraExport.swift:142` and `:148`, `LegacySchema.swift:25` (`.iso8601`)
  - **What's wrong:** the `.iso8601` strategy writes whole seconds, so the export isn't lossless, and every upgrading user's history passes through it once.
  - **Failure:** records made in the same second tie on `createdAt`. `context.all` returns dictionary order, so `history()`, `undoLatest`, and `objects(of:)` where `sortIndex` is 0, can order differently on each launch. The new restore check (`child.deletedAt == deletedAt`, from #70) can also bring back a child that was deleted separately in the same second.
  - **Fix:** write dates at full precision (seconds as a Double, or ISO 8601 with fractional seconds), and break sort ties by the UUIDv7 id.

## Checked and fine

- `save()` writes everything in one GRDB transaction and keeps unsaved changes after an error.
- The migrator (v1 only) is idempotent.
- Deletes are written before inserts.
- Inverse relationships stay in step.
- Rollback in `perform` and undo/redo through `Op.inverse` are correct.
- The revision-keyed training index doesn't go stale.
- There's one `ObjectStore`.
- The Live Activity intents run in the app process, so there's no cross-process database access.

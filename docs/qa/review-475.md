# Review: #475 core/catalog-version-guard (B5/B6) + ledger flake fix

QA, Oct 16 2026, ~12:45 PM PT. Head **a0403b6** (2 commits: 12e0768, a0403b6), merges cleanly onto master. Static review.

## Verdict: PASS

| Check | Where | Result |
|---|---|---|
| B5: older build never opens a newer store, no crash | `TesseraSchema.open` (TesseraSchema.swift:51-57) calls `TesseraDatabaseSchema.isNewer(at:)` first; read-only open, every error is `try?`, returns `.inMemoryFallback` with a launch note. File is untouched (test compares bytes before/after) | ok |
| B5 knock-ons | `TesseraApp.swift:24` already skips the legacy SwiftData move on `.inMemoryFallback`; `AppModel.swift:144` shows `TesseraSchema.launchNote` ahead of the generic fallback line | ok |
| B6: restore refuses a newer catalog before touching anything | `TesseraBackup.inspect` (TesseraBackup.swift:211) now uses `isNewer(db)` (unknown migration OR `MAX(packageVersion)` for package `system` above this build's). `stageRestore` calls `inspect` before it removes or copies anything (:236-241); `applyPendingRestore` re-inspects at launch (:270) | ok |
| Tests | `BackupTests.aNewerCatalogIsNeverRestoredOrOpened`: good copy passes; v+1 copy refused by inspect and stageRestore; v+1 store opens in memory, note says "newer Tessera", bytes unchanged | ok |
| Ledger flake fix | `ClaudeKey.swift`: `pendingNano` moves from one static to a static dictionary keyed by `ObjectIdentifier(store.context)`. `capNano`, `canSpend` arithmetic, `reserve` (`estimateNano > 0` guard, QA A6) and `settle` unchanged. App has one store: AppModel.swift:132 and ClaudeSection.swift:69/443 all build the ledger on `model.store`, so they still share holds | $50 cap and reserve unchanged |
| No catalog number change | SystemCatalog.swift:350 still `version: 9`; only `nonisolated` added | ok |

## Lines he sees (for Design)

1. **New:** launch note in the Ask bar when the store is from a newer build: "Your data is from a newer Tessera, so I left it untouched. Update the app to open it; nothing you do this time will be kept." (TesseraSchema.swift:54-55). Uses a semicolon; Design may want two sentences.
2. **Existing, now also for a newer catalog:** Backups picker "That copy is from a newer Tessera. Update first." (BackupView.swift:257).
3. **Existing, now also for a newer staged restore:** "That backup couldn't be read, so your data is as it was." (TesseraBackup.swift:274). Slightly off for this case (it could be read; it is just newer). Low, see R2.

## Follow-ups (not pin blockers)

- **M1 (medium) rolling copies during a fallback session.** `BackupKeeper.runDaily` (TesseraApp.swift:83) still runs on `.inMemoryFallback`. `writeRolling` skips a store with no user ops, but if he keeps using the downgraded build for a week (the note says nothing is kept, but he may still log), each day writes a copy of the throwaway in-memory store and prunes to 7, rolling away the good copies the newer build made. Pre-existing for every fallback cause; B5 makes fallback last for as long as the older build is installed. Fix: skip `runDaily` when `TesseraSchema.lastOpenOutcome == .inMemoryFallback`.
- **R1 fail-open.** `isNewer(at:)` returns false when the read-only open fails (TesseraDatabaseSchema.swift:28-31), and the normal opener then runs. Fine for a missing file; for a WAL store whose -shm can't be opened read-only it would skip B5. Test uses a DELETE-journal copy, so the WAL case is untested. Worth one test with a live WAL store.
- **R2** Give a newer staged restore its own launch note ("That backup is from a newer Tessera, so your data is as it was.") instead of "couldn't be read".
- **R3** `TessUsageLedger.pending` never drops entries; one per context. Harmless in the app (one context); in tests an `ObjectIdentifier` can be reused by a later context at the same address. Settled holds are 0, so only a crashed-mid-call test could leak a hold.

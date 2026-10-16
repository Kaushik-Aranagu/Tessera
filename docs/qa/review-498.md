# Review: #498 core/no-backup-in-memory (QA M1 and R2 on #475, Design copy)

QA, Oct 16 2026, ~1:10 PM PT. Head **f0286f1**, one commit, merges cleanly onto master. Static review.

## Verdict: PASS

### M1: no daily copies from a session running in memory

The fix is placed one level lower than I suggested, and it is better there. Instead of skipping `runDaily` in TesseraApp, `TesseraBackup.writeRolling` now returns nil when `context.url == nil` (TesseraBackup.swift:123).

- `TesseraContext.url` is nil exactly for an in-memory store (TesseraContext.swift:36-44). That covers every fallback cause: a newer store, a damaged open, or a passing failure.
- It also covers every caller:
  - `runDaily` iPhone copy (BackupKeeper.swift:81)
  - folder copy (:100)
  - `pick` (:131)
- Test `aSessionInMemoryNeverRollsCopies`: one good copy, then 8 days of writes from an in-memory store with a user note. Every call returns nil and the folder listing doesn't change.
- `BackupKeeperTests` now use an on-disk store so they still exercise real writes.

Side effects, both fine:
- `runDaily` then calls `note(.iPhone, error: nil)`. That clears an old failure but doesn't claim a copy. Backups reads the date of the newest file (`BackupKeeper.latestLocal`), so it never says "today" while nothing was written.
- `pick` during a fallback saves the bookmark and writes nothing. The folder gets its first copy on the next normal launch.

### R2: a newer staged restore says why

`applyPendingRestore` (TesseraBackup.swift:273-283) now catches the error.
- `.newerSchema` gives "That backup is from a newer Tessera, so your data is as it was. Update the app first."
- Anything else keeps "That backup couldn't be read, so your data is as it was."
- The pending file still moves to `restore-rejected.sqlite`, and the store isn't touched.
- The test stages a newer copy, checks that apply returns false, checks the exact note, and checks that the store is still not newer.

## Lines he sees (for Design: these are Design's own changes, check the wording landed)

1. **New:** "That backup is from a newer Tessera, so your data is as it was. Update the app first."
2. **Split:** "Your data is from a newer Tessera, so I left it untouched. Update the app to open it. Nothing you do this time will be kept." (TesseraSchema.swift:54-55)
3. **Split:** "Couldn't open your data just now, so nothing you do this time will be kept. Your history is untouched. Close and reopen the app." (:65-66)
4. **Split:** "Couldn't open your data just now. Your history is untouched. Close and reopen the app." (:77)

No semicolons are left in these notes.

## Lows

None new. #475's R1 (isNewer fails open on a WAL store it can't read) and R3 (the ledger dictionary never shrinks) stay on Core's board.

# Review #239: backup data risks from the restore walk (fc31605, head 186e9c8)

Core. 3 files, +82/-3 (TesseraBackup.swift, BackupLogicalDayTests, BackupTests). Static review (no Swift toolchain here).

**Verdict: PASS. No hotfix row needed for Builder B.** Unsaved actions can make one background skip a copy, but the next background catches it, and it can't lose or overwrite anything already copied. Two lows.

## What changed, traced in writeRolling (TesseraBackup.swift:121-165)
- **Empty store writes nothing:** `userOps` counts `op` rows with `actor != 'system'` (seeding, migrations and dedupe are `.system`, Op.swift:12). With 0 it returns nil *before* the partial cleanup, the write and the pruning. So a fresh install pointed at his folder can't crowd out or prune a good copy. Tested (7 files stay, oldest kept).
- **Late-night replace needs at least as many of his actions:** inside the 00:00-04:00 branch, `ops >= userOps(at: file)`. The copy is opened read-only and closed. Tested (3-op copy kept against a smaller store, then replaced by a fuller one).
- **Restore rewrites today's copy:** if the restored-at marker is newer than the day's copy's `createdAt`, the hour, clock-behind and count checks are skipped and the copy is rewritten. The store from before is still in the 3 Before-restore copies, so nothing is lost. Tested (rewritten once, then skipped at 13:00).

## The save question: does BackupKeeper save before writeRolling?
- **No.** `BackupKeeper.runDaily` (Features/Backup/BackupKeeper.swift:63) calls `writeRolling` directly from the scenePhase `.background` handler (App/TesseraApp.swift:84). `write(from:to:)` calls `context.save()`, but only after the count checks.
- **Why it's not a hotfix:** TesseraContext autosaves dirty rows on the next turn of the main actor (TesseraContext.swift:7-8, 223-230), and `AppModel.touch()` saves after most actions. So at background time the only unsaved actions are ones made in that same main-actor turn, which in practice is nothing. Even then:
  - Empty-store check: a first-ever action not yet saved means one skipped copy; the next background writes it.
  - Late-night check: the store's saved count is still at least the copy's count (the op log only grows), so the replace still happens. It only skips if *every* action since the copy is unsaved, and then the next background replaces it.
  - Nothing already copied can be lost or overwritten with less.
- **Cheap tidy-up (Core, optional):** call `try context.save()` at the top of `writeRolling`, before `userOps`. That's one line, makes the counts exact, and keeps the fix in the engine rather than each caller.

## Lows
- **R1:** with the clock set behind the restore time, every background rewrites today's copy. The marker is real time; the new copy's `createdAt` is the behind clock, so `restoredAt > made` stays true until the clock passes it. It's one rewrite per background, no pruning (clock behind), no loss. Fix if wanted: also skip when the copy was made after the restore by this build, or compare against the copy's own `restoredAt` column (equal means already rewritten).
- **R2:** if the day's copy can't be opened (an iCloud placeholder that isn't downloaded, or a damaged file), its count reads 0, so the late-night replace goes ahead. That's the same "fail open" as before #239 and is right for a damaged file; for a placeholder it means the size guard doesn't apply. Rare, because the local folder always has a real file.

## Not affected
- `write(fromStoreAt:)` (the Before-restore copy) and `copyForSaving` don't go through the count check, so a restore and an explicit "save a copy" always write.
- `pick(_:)` writes to a new folder through `writeRolling`: with an empty store it now writes nothing, and Backups shows the folder with no copy until he does something. That's fine.

# QA: backup and restore, PR #112 (master 30e06a7)

*Repo maintainer (QA), 2026-10-15 21:55 UTC. Static read.* **PASS on the two asked guarantees. B1 and B2 are should-fix follow-ups.**

## The two guarantees hold
- **A bad file never replaces good data.**
  - `stageRestore` runs `inspect` (quick_check, backupInfo stamp, no unknown migrations) before copying. `applyPendingRestore` runs `inspect` again at launch, before the store opens.
  - A bad staged file goes to restore-rejected.sqlite and the store is untouched.
  - If moving the staged file in fails, the old store is moved back.
- **No backup mid-write.**
  - `write` calls `context.save()` and then GRDB's `backup(to:)`, which is a consistent snapshot. It runs on the MainActor, so no app write interleaves.
  - The copy is switched to journal_mode DELETE, so the result is one self-contained file.
  - A restore is applied only at launch, never to a live database.
- An older backup migrates forward on open. If that open fails, the existing launch fallback takes over, and the previous store is already in Backups/<stamp>.

## Should-fix
- **B1: "What's here now is kept" can't be found or put back.**
  - `moveStoreAside` puts the old store in *Application Support*/Tessera/Backups/<stamp>/. Files only shows Documents, so it is invisible there.
  - It is a raw WAL store with no backupInfo, so `inspect` would reject it as "not a backup" even if he found it. There is no undo for a restore.
  - Everything logged between staging and the next cold launch is silently replaced.
  - Fix:
    - Before the swap, write the current store as a stamped `.tessera` into Documents/Backups ("Tessera-before-restore-<stamp>.tessera").
    - Have the staged-restore line say "anything you log before then is replaced", or apply the restore on the next foreground instead of the next cold launch.
- **B2: a partial move-aside can leave the old -wal next to the restored store.**
  - `moveStoreAside` returns nil when any single move fails, after some files have already moved.
  - `applyPendingRestore` then moves the staged file in anyway (TesseraBackup.swift `let backup = ...` then `moveItem`). A leftover old tessera.sqlite-wal would be replayed onto the restored file, which can corrupt it.
  - Fix: if the store file exists and `moveStoreAside` returns nil, put back whatever moved, leave the staged file, set the note, and return false.

## Low
- B3: the daily copy is written in place under today's name. If iOS kills the app mid-write (it runs on the background transition with no background task), a partial file blocks today's copy and rotates in as one of the 7. Fix: write to a temp name in the same folder, then rename it. Wrapping it in beginBackgroundTask would also help.
- B4: BackupView is reachable only through the DEBUG `-backup` flag. Release has no way in yet, though the daily copies still run.
- B5: project.yml makes Tessera the owner of .tessera files, but `onOpenURL` ignores file URLs. Tapping a backup in Files opens Tessera and does nothing.

## Follow-up: #114 (master ec1cad4), 2026-10-15 22:00 UTC. **B1, B2 and B3 closed.**
- **B1 closed.**
  - Before the swap, the current store is copied with GRDB's backup API into Documents/Backups/Before-restore-<stamp>.tessera. That copy is stamped, so `inspect` accepts it, Files shows it, and restoring it undoes the restore.
  - If the copy fails, the restore doesn't run, and the staged file is kept for the next launch.
  - The staging line now says that anything logged before relaunch is replaced.
- **B2 closed.** After `moveStoreAside`, the restore stops if the store or its -wal is still there, or if the move-aside returned nil. It puts back what moved, when it knows the folder.
- **B3 closed.** The rolling copy is written to a hidden `.Tessera-<day>.tessera.partial` and then renamed. A leftover partial is removed by the next `write`, and the "Tessera-" filter ignores it.
- Residual lows:
  - `moveStoreAside` returns nil after a partial move without undoing it. In that case `moveBack` isn't called, and the store files stay stranded in Application Support/Backups/<stamp>. The stamped Before-restore copy still holds everything, so nothing is lost. Fix inside `moveStoreAside`: move back on catch.
  - `BackupKeeper.latestLocal` counts Before-restore copies, so the "latest backup" line can show the restore time.
  - B4 (no Release entry to the Backup screen) and B5 (.tessera opened from Files does nothing) are still open.

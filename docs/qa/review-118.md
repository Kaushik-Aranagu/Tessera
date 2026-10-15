# QA: Groceries polish, Backups entry, PaintDab seed, PR #118 (master a07f6a0)

*Repo maintainer (QA), 2026-10-15 22:25 UTC. Static read.* **PASS on Groceries and the seed fix. The Backups entry needs R1 before the phone.**

## R1 (should-fix before the phone): Restore has no confirm and no way to cancel
- The Review page now reaches BackupView in Release ("Backups" label word, ReviewView.swift:209-222). In BackupView, "Restore" opens the file picker, and picking a file calls `TesseraBackup.stageRestore` right away (BackupView.swift `restore(from:)`). There is no confirm step showing the copy's date and what will be replaced.
- Once staged, nothing in the UI can cancel it. `restore-pending.sqlite` waits for the next cold launch, which iOS can trigger silently at any time. Everything logged in between is replaced. The Before-restore copy (#114) makes this recoverable, but only by a second restore.
- Fix:
  1. After `inspect`, show a confirm in the house style (a sentence plus a stroke word): "Replace everything with the copy from Tue 14 Oct? What's here now is kept in Backups." Only stage on Confirm.
  2. While `pendingURL` exists, BackupView shows "A restore is waiting for the next launch" and a "Cancel restore" word that deletes the pending file.
  3. Optional: offer "Restart now". iOS gives no relaunch API, so the honest copy is "Close Tessera from the app switcher to restore now".

## Fine
- The Backups entry is pushed inside ReviewView's own NavigationStack (the cover from #107), with a hairline and a label word, no button shape.
- PaintDab negative seed: the only hash-derived seed, `abs(sink.id.hashValue % 7)` (GroceriesView.swift:137), is now non-negative. The other call sites pass counts or indexes. `DabShape` uses `seed % 4`, and `InkActions` uses `(i + seed) % count`, so a negative seed would have crashed. Every caller now passes a non-negative seed.
- Groceries: the aisle grouping uses `aisles.first` and `aisles[1]` only behind `count > 1`. `ClearDoneItems` goes through `try?` with `by: .user`. The sink, fold and rise motions all go through reduceMotion. The long press to clear is 0.7 s (deliberate).
- Low: `ClearDoneItems` after the 0.7 s hold has no Undo line (other destructive list actions get Tess's Undo).

## Follow-up: #120 (master 19f37e6), 2026-10-15 22:36 UTC. **R1 closed.**
- Picking a file now only runs `inspect` and copies the file to tmp while security-scoped access lasts. It then asks "Replace everything with the copy from <day>?"
- The Replace key is a hold PaintKey (live paint, "Hold" meta), and only that calls `stageRestore`. "Keep what's here" deletes the temp copy.
- While `pendingRestore()` is non-nil, the view shows "A restore is waiting" with the day, the replace warning and the app-switcher hint, plus a "Cancel restore" word. That word deletes restore-pending.sqlite, and the refresh hides the block.
- Low R2: `pendingRestore()` runs `inspect` (open, quick_check, migration read) inside `body` on every render. On a large store that's main-thread work on every entrance animation tick. Cache it in `@State` and refresh on stage or cancel.
- Low R3: an unreadable staged file reads as "no restore waiting". That's safe, since launch rejects it, but the UI says nothing about it.

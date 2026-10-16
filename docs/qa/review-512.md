# Review: #512 core/thing-first-lines (board 0p, Research RC23-RC32)

QA, Oct 16 2026, ~1:35 PM PT. Head **dd21e5c**: one commit, merges cleanly onto master. Static review.

## Verdict: PASS

### What changes
- `EngineAction` gets an optional `receipt(in:)`. It defaults to nil, so actions without one fall back to `summary`.
- `ActionEngine` sets `record.receipt` after a successful `apply` (ActionEngine.swift:62).
- Actions that now have a thing-first line:
  - SetTaskDone: "Call mom, done" / "Call mom, back on"
  - AddGroceries: "Milk, on Groceries" / "3 things, on Groceries"
  - CreateList: "Films, made"
  - AddListItem: "Dune, on Films"
  - CheckListItem: "Dune, got" / "Dune, back on Films"
  - MoveListItem: "Dune, moved to Watched"
  - RenameListSection: "Watched, now Seen"
  - ClearDoneItems: "Films, done items cleared"
  - MoveTask: "Call mom, tomorrow 6:30 pm" / "Call mom, in Later"
- Fallback lines:
  - Claude (ClaudeTessModel.swift:128-131): when Claude's own line fails the voice checks, the line is now `receipt ?? summary` plus ".".
  - On-device (TessModelCapture.swift:44-45): the last record's `receipt ?? summary` plus ".". It used to be the bare summary with no period.
  - `summary` stays the verb-first log text for the Day log and op history.

### Data safety
- `OpRecord.receipt` is a plain in-memory property with no `didChange`. The GRDB mapping writes explicit columns (TesseraDatabaseSchema.swift:134, :265), so the receipt is never stored, backed up or migrated, and no schema or catalog change is needed.
- After a relaunch, loaded records have `receipt == nil`. That's fine because only the live fallback line reads it.
- No launch flags, no ProcessInfo, no migration.

### Privacy
- Nothing new goes to Claude. Receipts are only used after the tools ran, for the line shown on screen.
- Every receipt names the same thing its summary already named, so nothing new is exposed. CreateNote and EditNote have no receipt, so private notes still say "Noted" or "Private note".

## What he sees (for Design)
The spoken or shown line after a Tess or Claude miss now leads with the thing. The full list is above. Lines worth a look:
- "Call mom, back on" for a reopened task. It may read better as "Call mom, back on today".
- "Films, done items cleared".

## Lows
- **R1:** `MoveTask.receipt` uses `Calendar.current` and `TesseraDay()` (Tasks.swift:150-156), not the context calendar. That matches `apply`, which also uses `TesseraDay()`, so it's consistent. Thread the calendar through when MoveTask gets one.
- **R2:** A move more than 6 days out says only the weekday ("Call mom, Thu 3 pm"). That reads as this coming Thursday. Rare, since moves are usually days, not weeks.

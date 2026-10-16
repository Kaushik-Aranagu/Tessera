# Review #258: settings object, catalog v4 (67442a1, head 5455f14)

Core. 6 files, +344/-5. Static review (no Swift toolchain here). Checked against research/settings-object.md.

**Verdict: PASS.** Of the merge check's three minors, two are confirmed as lows and one is dismissed. Nothing blocks.

## Checked
- **One object with a fixed id:** `SystemCatalog.stableID("settings")` is the same on every phone. `WriteSettings` creates it with that id on the first write (`Transaction.create(id:)` → `ObjectStore.create(id:)`). After that, every change is one op, so settings ride in the op log, every backup and every export, and come back with a restore.
- **Nothing secret or device-bound:**
  - Fields: looks (day, night, pinned), missesGoToClaude, backupFolderName, backupFolderPickedAt, restWeekday. No key, no last four, no bookmark.
  - `backupFolderName` refuses anything path-like (a leading "/", `file:`, `/private/`, `/var/mobile`, `containers/`, a UUID), both in `init` and through `didSet`.
- **All optional:** `read()` creates nothing and returns all nil until the first write. `sendsMissesToClaude` defaults to true (Product, 8:28 PM PT).
- **Migration:** copies only the old keys that are actually set, as `.system`. It never overwrites a field that came back from a restore, except that "no" wins for misses.
- **Backups (#239 rule):** `userOps` now excludes ops whose `objectIDs` contain the settings id. So a fresh install that only tapped a look still counts as empty and never crowds out a good copy. The id is written as `uuidString` on both sides, so the `instr` match holds. Tested.
- **Catalog v4:** the version bump re-seeds and adds the Settings class. User edits are preserved, as before.
- `update` writes nothing when nothing changed.

## The merge check's three minors
1. **`restWeekday` isn't range-checked: confirmed, low.** `read()` does `Int(number)`, so 0, 8 or 3.5 (from a hand-edited import or a future bug) comes through as 0, 8 or 3. Nothing reads it yet. But the first reader will likely index weekday symbols with it (`weekdaySymbols[w - 1]`), and 0 or 8 would crash there. Fix in `read()`: keep it only if it's a whole number in 1...7, else nil. Same guard in `TesseraSettings.init`.
2. **"Unneeded `try`" in `WriteSettings.apply`: dismissed.** `transaction.classDef(_:)` throws (Transaction.swift:26), and it sits inside the expression the `try` covers (`… ?? transaction.create(transaction.classDef(.settings), …)`). The `try` is required. If the build shows a warning, it's for something else; send me the exact text.
3. **A soft-deleted settings object: confirmed, low.** `read()` treats a deleted object as "no settings", but `WriteSettings` finds the same object by id (`store.object(id:)` returns deleted objects) and writes onto it without undeleting it. Every later change then lands on a deleted object, and `read()` keeps returning defaults, so his looks and preferences silently stop sticking.
   - How it could happen: an undo of the op that first created the object, or an import that carries it deleted. There's no UI path today (no UNDO is offered on a look tap), so it's rare.
   - Fix: in `WriteSettings.apply`, if the found object `isDeleted`, restore it first (the undo path's un-delete). Or, simpler, have `read()` ignore `isDeleted` for this one fixed object, since it is never meant to be deleted. Groceries uses the "deleted means make a new one" pattern, but a fixed id can't be recreated, so un-deleting is the right fix here.

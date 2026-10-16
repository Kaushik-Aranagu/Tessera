# Miss counts in the `.tessera` copy (brief for Core)

*Research, 2026-10-16. Traced by hand on `origin/master` at `ab45919` (Merge #184); no Swift run. Reads with
`week-one-checkin.md` (Blocks), `day-boundary.md` (TesseraDay). Times are Pacific. `Core/` means
`TesseraCore/Sources/TesseraCore/`.*

**Ask:** the morning check-in reads only the daily `.tessera` copy, and "Didn't catch that." misses never reach it.
Smallest change so each copy carries counts only (day, route, source, n). No text, no titles, ever.

## 1. What is there today

**The log** (`Core/Diagnostics/CaptureMissLog.swift`):
- One JSON line per miss: `text` (cut to 200 chars), `at` (ISO 8601), `route`, `source` (`:7-15`). Blank text is
  dropped (`:37-38`). Newest 2000 kept, trimmed past 2200 (`:17-19`, `:68-74`).
- File `capture-misses.jsonl` beside `tessera.sqlite` (`:29-33`), marked excluded from device backup (`:45-52`),
  append only: nothing ever removes or edits a miss. Nil for an in-memory store (`:27`). `all()` reads it (`:61-66`).
- Doc comment says `route` is "the last route that tried"; in practice it is `TessCapture.Source.rawValue`
  (`TesseraCore/Sources/TesseraTess/TessCapturing.swift:36-43`). The router's fall-through returns `.none`
  (`TesseraCore/Sources/TesseraTess/TessModel.swift:68`), and the grammar step never returns a no-write result (`TessModel.swift:94`). So
  route is `none` (nothing understood) or `model` (the on-device model answered without acting, `TessModel.swift:123`).
  `grammar` never appears.

**Call sites (all three):**
| # | Where | route | source |
|---|---|---|---|
| 1 | `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:32-34` (`capture(_:context:source:)`, on `!understood`) | `none` / `model` | caller's |
| 1a | via `TessCaptureEngine.swift:22-24` from the Tess bar, `App/AppModel.swift:166` | | `ghost row` |
| 1b | via the same default from Siri / Shortcuts, `TesseraCore/Sources/TesseraIntents/Intents.swift:150` | | `ghost row` (mislabelled) |
| 2 | `Features/Recipes/PasteRecipe.swift:191` (CreateRecipe threw, e.g. a link) | `none` | `paste` |

**How a copy is built:**
- `TesseraBackup.write(from:to:now:appVersion:)` (`Core/Export/TesseraBackup.swift:33-55`): save, GRDB `backup(to:)`
  into a fresh file (`:38-39`), journal to DELETE (`:41`), then one `copy.write` that creates and fills the one-row
  `backupInfo` (`:42-50`). Only the copy is touched there; the live store is not.
- `writeRolling` names `Tessera-YYYY-MM-DD.tessera` by calendar date, writes to a `.partial` then renames, keeps 7
  (`:90-109`). Callers: `BackupKeeper.runDaily` (local, then picked folder; `Features/Backup/BackupKeeper.swift:23-33`),
  `BackupKeeper.pick` (`:51-60`), share sheet `copyForSaving` (`:76-81`). Before-restore copies use the closed-file
  path `write(fromStoreAt:)` (`TesseraBackup.swift:58-78`), no context.
- `inspect` accepts a copy if `grdb_migrations` is a subset of this build's (`:131-133`). Extra plain tables are fine
  (`backupInfo` already is one).

## 2. Shape: two options

| | A. `missCount` table in the live store | B. counts computed at copy time, into the copy only |
|---|---|---|
| Write point | new migration `v3` in `Core/Model/TesseraDatabaseSchema.swift` after `:46-51`; upsert at each `record` | inside the existing `copy.write { }` at `TesseraBackup.swift:42-50` |
| Live schema | changes (v3); a v3 copy is "newer" to older builds (`:133`) | unchanged; migrations stay v1, v2 |
| Write path | raw SQL beside `TesseraContext`, which owns all writes (CLAUDE.md: never touch the db directly) | none on the phone's store; reads `CaptureMissLog.all()` |
| Restore | restoring an old copy rewinds counts | no effect; the copy rebuilds the table each time |
| Lines | ~40 plus migration tests | ~25 |

**Recommend B.** It is the smallest, needs no migration and no new write path, keeps the live store exactly as it is,
and the counts land only where the check-in reads them. The jsonl already keeps 2000 misses, years at his rate.

**B in detail** (`TesseraBackup.write(from:...)`):
1. Add params `misses: [CaptureMissLog.Miss]? = nil, calendar: Calendar = .current`. When nil, read
   `context.url.map { CaptureMissLog(url: $0.deletingLastPathComponent().appendingPathComponent("capture-misses.jsonl")).all() } ?? []`
   (same path as `CaptureMissLog.swift:31`; `TesseraContext.url` is `Core/Model/TesseraContext.swift:36`). Pass
   `calendar` through from `writeRolling` (`:91`).
2. In the `copy.write` block, after `backupInfo`:
   ```sql
   DROP TABLE IF EXISTS missCount;
   CREATE TABLE missCount(day TEXT NOT NULL, route TEXT NOT NULL, source TEXT NOT NULL, n INTEGER NOT NULL,
     PRIMARY KEY(day, route, source));
   ```
   then one `INSERT` per group of `misses` by (logical day string, route, source). DROP, not `DELETE`, so a stale
   table that came in through a restore is rebuilt clean.
3. **Day** = 4 AM logical day as `YYYY-MM-DD`, by the wall-clock hour (hour < 4 means the calendar day before). Use
   `TesseraDay.day(of:)` from `day-boundary.md` if it has landed (not on master at `ab45919`); otherwise a 4-line
   private helper with that rule. **Not** `RollForwardTasks.logicalDay` (`Core/Tasks/RollForward.swift:71-73`): it
   subtracts 4 h of absolute time and is wrong for an hour on both DST days (fixtures F11, F13).
4. `write(fromStoreAt:)` (before-restore copy) is left alone: those copies are for undoing a restore, not the check-in.
5. Optional one-liner (recommend): `Intents.swift:150` passes `source: "siri"` so Siri misses stop reading as
   `ghost row`. Needs the 3-arg `capture` on `TessCapturing` or a cast; Core's call.

Privacy: `day`, `route`, `source`, `n` only. The copy goes to iCloud Drive and the share sheet, so no text, no hour.

## 3. Fixtures (calendar `America/Los_Angeles`; copy taken 2027-03-15 09:00 unless noted)

| # | Miss at (Pacific) | route | source | Day key | Note |
|---|---|---|---|---|---|
| F1 | Tue 2026-10-20 08:12 PDT | none | ghost row | 2026-10-20 | plain |
| F2 | Tue 10-20 12:40 PDT | model | ghost row | 2026-10-20 | model answered, wrote nothing; at 12:41 he rephrases and the model logs it (an `op` row, route `onDevice`). F2 still counts: the log is append only |
| F3 | Tue 10-20 19:05 PDT | none | paste | 2026-10-20 | a link pasted as a recipe |
| F4 | Tue 10-20 23:50 PDT | none | ghost row | 2026-10-20 | |
| F5 | Wed 10-21 01:30 PDT | none | ghost row | 2026-10-20 | late night belongs to Tuesday |
| F6 | Wed 10-21 03:59 PDT | model | ghost row | 2026-10-20 | last minute of Tuesday |
| F7 | Wed 10-21 04:00 PDT | none | ghost row | 2026-10-21 | boundary is inclusive at 04:00 |
| F8 | Wed 10-21 07:15 PDT, Siri | none | ghost row (`siri` with the one-liner) | 2026-10-21 | |
| F9 | Wed 10-21 09:00 PDT, text "   " | | | none | blank, never recorded (`CaptureMissLog.swift:38`) |
| F10 | Thu 10-22 | | | none | empty day: no rows for 2026-10-22 |
| F11 | Sun 11-01 01:30 PDT then 01:30 PST | none | ghost row | 2026-10-31 (both) | the doubled hour |
| F12 | Sun 11-01 03:30 PST | none | ghost row | 2026-10-31 | `logicalDay` would say 11-01 |
| F13 | Sun 2027-03-14 04:30 PDT | none | ghost row | 2027-03-14 | `logicalDay` would say 03-13 |

Expected `missCount` in the copy (ordered by day, route, source):
```
2026-10-20|model|ghost row|2      (F2, F6)
2026-10-20|none|ghost row|3       (F1, F4, F5)
2026-10-20|none|paste|1           (F3)
2026-10-21|none|ghost row|2       (F7, F8; with the Siri one-liner: 1, plus 2026-10-21|none|siri|1)
2026-10-31|none|ghost row|3       (F11 x2, F12)
2027-03-14|none|ghost row|1       (F13)
```
Total 12. No row for 2026-10-22. Also: a copy taken Wed 10-21 03:00 PDT holds only F1 to F5, so Tuesday reads `model|ghost row|1`,
`none|ghost row|3`, `none|paste|1` (partial, per Q1). A copy with no jsonl has the table and 0 rows.

## 4. Check-in Q8 (after Q5; uses `$DAY`, `$START`, `$END` from the setup block)

```sql
SELECT (SELECT COALESCE(SUM(n),0) FROM missCount WHERE day='$DAY') misses,
 (SELECT COUNT(*) FROM op WHERE actor IN ('tess','intent') AND createdAt>=$START AND createdAt<$END) captures;
SELECT route, source, n FROM missCount WHERE day='$DAY' ORDER BY n DESC;
```
Normal: 0 to 2 misses. **Threshold: 3 or more misses in a day, or misses over 20% of misses + captures** (grammar
or the model is missing his phrasing; joins warning sign 2). `paste` misses are kitchen, reported but not counted
toward the threshold. "no such table: missCount" means the copy predates the change: say "misses n/a". Yesterday is
complete only under Q1's coverage rule (copy after 04:00 today). Message line 3 gains `misses <n> (<k> paste)`.

## 5. Tests Core should add (`TesseraCore/Tests/TesseraCoreTests/BackupTests.swift`)

- `copyCarriesMissCountsOnly`: F1 to F13 in, expected rows out; `missCount` columns are exactly day, route, source, n.
- `copyHoldsNoMissText`: the copy's bytes contain none of the miss texts (`Data.range(of:)` on each).
- `missDayTurnsAtFourAM`: F6 to 2026-10-20, F7 to 2026-10-21.
- `missDayIsDSTSafe`: F11, F12 to 2026-10-31 and F13 to 2027-03-14 with a Los Angeles calendar.
- `missLaterWrittenStillCounts`: a model miss then a model write of the rephrase gives n 1 and one committed op.
- `copyWithoutMissLogHasEmptyTable`: no jsonl (and in-memory store) gives the table with 0 rows.
- `missCountIsRebuiltNotAccumulated`: restore a copy, write a new one; counts equal the jsonl, not doubled.
- `liveStoreUnchangedByCopy`: no `missCount` in the live store; `grdb_migrations` still v1, v2; `inspect` passes.
- `siriMissesAreLabelled` (only with the one-liner): an intent capture miss has source `siri`.

## Open questions

- Siri label: take the `Intents.swift:150` one-liner now, or leave Siri misses inside `ghost row`?
- Q8 threshold 20% is a guess for week one; revisit after 7 copies.
- Wait for `TesseraDay` (day-boundary.md) or ship the private helper first and swap later?

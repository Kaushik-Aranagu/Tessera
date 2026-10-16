# Week-one check-in: dry run on a sample copy (board item 60)

*Research, 2026-10-16. Schema and shapes read from `origin/master` at `0a27447` (Merge #189); no Swift run.
Runs `week-one-checkin.md` Q1 to Q7 and `miss-counts.md` Q8 against synthetic `.tessera` copies. Times Pacific
(PDT all week). `Core/` means `TesseraCore/Sources/TesseraCore/`.*

## Sample and how it was run

- Generator: `/tmp/claude-0/-home-claude/a21dc68c-0951-5bbf-9e1c-7675729e9a02/scratchpad/checkin/gen_sample.py`;
  runner `run_checkin.py`, fixes `corrected.sql` and `dates.sql` in the same folder. Synthetic data only.
- Shapes match master: tables exactly as `Core/Model/TesseraDatabaseSchema.swift` v1 + v2 (`op.route`, `op.model`),
  `grdb_migrations` v1, v2, `backupInfo(format, version, createdAt REAL, appVersion)` as `Core/Export/TesseraBackup.swift:42-50`.
  Times are REAL Unix seconds; ids upper-case `uuidString`; `op.ops` and `object."values"` are BLOBs of Swift JSON
  (`{"setValue":{"object":..,"field":..,"new":{"choice":{"_0":"lockScreen"}}}}`); values keyed by field id, sorted;
  dates inside JSON are seconds since 2001 (Swift's default). Class and field ids use `SystemCatalog.stableID`
  (`system.set`, `system.set.source`, ...). `missCount` is added per miss-counts.md option B (not on master).
- Week: Fri Push A, Sat Pull A, Sun Legs A, Mon rest, Tue Push B, Wed Pull B. Wednesday (the day read): 19 live sets
  (Lock Screen, hold, dial, one Tess set he edited at 50 s, one Tess "3x10" = one `logExercise` op with 3 sets);
  Tess captures on grammar, onDevice (one by Siri), claude; undos at 6 s, 40 s, 3 min and 3 h 45 min; a dismissed ghost
  row; a Shortcut that started Legs B at 19:10 and was never used; late night 23:05, 00:45, 03:30 Tess writes; at 01:30
  `tidy` closed Legs B. On master that is `endProcess` + `deleteObject` by `system`, not `finishWorkout`
  (`Core/Processes/ProcessTable.swift:124-129`, commit 7eb2b58). 6 misses on Wednesday's logical day, one at Thu 04:00.
- Copies: `Tessera-2026-10-21.tessera` (Wed 07:35), `Tessera-2026-10-22.tessera` (Thu 07:42, the morning case) and
  `partial-2026-10-22.tessera` (Thu 00:20, the partial case, see below).
- No `sqlite3` CLI in this container, so Python's sqlite3 3.45.1 ran each statement read-only (`mode=ro`), with
  `TZ=America/Los_Angeles`. Queries were pulled verbatim from the two docs' sql blocks; only `$DAY`, `$START`, `$END`
  were substituted. **Adapted:** `date -v-4H -v-1d +%F` (macOS) became Python `now - 4 h - 1 day`; `date -j -f ... +%s`
  became GNU `date -d "$DAY 04:00" +%s`. Run time Thu 22 07:45, so DAY=2026-10-21, START 1792580400, END 1792666800.

## Morning case: Thu 22 copy at 07:42, reading Wed 21

| Check | Actual output | Expected | Match |
|---|---|---|---|
| Setup | `quick_check` ok; migrations v1, v2 | ok, v1, v2 | yes |
| Q1 | copied 2026-10-22 07:42; ops 157, pending 0, last_write 07:30 (Wed copy: 122) | after 04:00, up, 0 | yes |
| Q2a | sets 19 | 15 to 25 | yes |
| Q2b | intent/lockScreen 6 + 1 undone; user/hold 7 + 1 undone; user/dial 2 + 1 undone; tess/other 2 | a third Lock Screen | **wrong count** (bug 2) |
| Q3 | intent/- 7 + 1 undone; tess grammar 5 + 1 undone, onDevice 2 + 1 undone, claude 1 | mostly grammar | yes, but see bug 3 |
| Q4 | a logSet 1; b createTask 1; b logNextSet 1; c logNextSet 1 (discard at 1 s left out) | flag on any `c` | yes, flag fired |
| Q5 | undone "Buy chalk Friday"; undone "Lunch walk" (dismissed); edited "Logged set 20 x 10" | 3 = sign 2 | yes, sign 2 fired |
| Q6 | 23:05 Email landlord; 00:45 Gym (onDevice); 03:30 Stretch 10 min | 3 rows | yes |
| Q7 | user finishWorkout 18:50 Pull B 19 | expected also Legs B, 0 sets | **no** (bug 4) |
| Q8 | misses 6, captures 18; none/ghost row 3, model/ghost row 2, none/paste 1 | 5 + 1 paste, 10 captures | **numbers wrong** (bug 5) |

Q8's day key was right: Thu 01:30 and 03:59 went to 2026-10-21, Thu 04:00 to 2026-10-22, matching miss-counts F5 to F7.

## Partial case: the copy master really writes after that late night

`writeRolling` names the file by calendar date and writes it on the first move to background of that date
(`TesseraBackup.swift:90-108`). He backgrounded at 00:20 Thursday, so `Tessera-2026-10-22.tessera` is the 00:20 copy
and **no other copy is made Thursday**; the 07:42 file above cannot exist on master after a late night.

Run on `partial-2026-10-22.tessera`, same DAY: Q1 copied 2026-10-22 00:20, ops 152, last_write 23:05 (rule says
"partial", correct). Q2 to Q5 same as above. Q3 one fewer onDevice. Q6 only 23:05. Q7 only Pull B (the 01:30 wrap-up
is after the copy). Q8 misses 4, captures 16 (00:20 to 04:00 misses missing). The 00:20 to 04:00 hours show up only in
Friday's copy, which the Friday check reads as Thursday's day, so **Wednesday's late night is never checked**.
Fix (kit): when Q1 says partial, re-run Q6, Q7 and Q8 for the same DAY on the next copy. Fix (Core, small): key
`writeRolling`'s file name by the 4 AM logical day (TesseraDay) instead of the calendar date, so the first copy after
04:00 is Thursday's.

## Bugs in the queries, with fixes (all run; outputs from the 07:42 copy)

**1. Setup times (macOS `date`).** `date -j -f '%Y-%m-%d %H:%M'` takes the seconds it is not given from the clock
(BSD fills unspecified fields with now; could not run here, Linux). START drifts up to 59 s. `END=START+86400` is wrong
on the two DST days: Sat 31 Oct END lands Sun 01 Nov 03:00 PST (an hour of Saturday's night lost); Sat 13 Mar 2027 it
lands Sun 05:00 PDT (an hour of Sunday taken). Q6's `$END-18000` likewise. Fix:
```bash
START=$(date -j -f '%Y-%m-%d %H:%M:%S' "$DAY 04:00:00" +%s)
END=$(date -j -v+1d -f '%Y-%m-%d %H:%M:%S' "$DAY 04:00:00" +%s)
LATE=$(date -j -f '%Y-%m-%d %H:%M:%S' "$DAY 23:00:00" +%s)     # Q6: createdAt>=$LATE AND createdAt<$END
```

**2. Q2's split counts op rows, not sets.** Tess's "3x10 face pull 15" is one `logExercise` row holding 3 sets with no
source (`LogExercise` passes none, `Core/Actions/TrainingActions.swift`); Tess single sets carry `tess` and fall in
`other`. Message line 2 would read 6 + 7 + 2 = 15 of 19. Fix, from the sets themselves:
```sql
SELECT COALESCE(json_extract(CAST(s."values" AS TEXT), '$."'||f.id||'".choice._0'),'none') src, COUNT(*) sets
FROM object s JOIN classDef c ON c.id=s.classID AND c.systemKey='system.set' JOIN fieldDef f ON f.key='system.set.source'
WHERE s.deletedAt IS NULL AND s.createdAt>=$START AND s.createdAt<$END GROUP BY 1 ORDER BY 2 DESC;
```
Output: hold 7, lockScreen 6, none 3, dial 2, tess 1 (19). `none` is Tess lifts.

**3. `intent` is not a capture.** Lock Screen "Done" sets and Shortcuts are `actor='intent'` (`TesseraIntents/Intents.swift:50`);
Siri "Tell Tess" runs Tess and is `actor='tess'`. Q3's table is fine because it splits by actor, but Q8's `captures`
uses `actor IN ('tess','intent')`: 18 instead of 10. Use `actor='tess'` for captures everywhere.

**4. Q7 can't see the zero-set wrap-up on master.** Since 7eb2b58 `tidy` closes an unused workout with `endProcess` +
`deleteObject` (workout soft-deleted), so no `finishWorkout` row exists and sign 3's 0-set case never fires.
Fix: `WHERE (o.action IN ('finishWorkout','finishWorkoutEarly') OR (o.action='deleteObject' AND o.actor='system'))`.
Output adds `system deleteObject 2026-10-22 01:30 Legs B 0`. Table 4's cause for sign 3 (zero sets "saved as trained")
is out of date: master no longer saves it; a 0-set row now means a started-and-abandoned workout, not data harm.

**5. Q8 counts paste and intent.** The text says paste misses don't count toward the threshold, but the query sums
them. Fix:
```sql
SELECT (SELECT COALESCE(SUM(n),0) FROM missCount WHERE day='$DAY' AND source<>'paste') misses,
 (SELECT COALESCE(SUM(n),0) FROM missCount WHERE day='$DAY' AND source='paste') paste,
 (SELECT COUNT(*) FROM op WHERE actor='tess' AND createdAt>=$START AND createdAt<$END) captures;
```
Output: misses 5, paste 1, captures 10 (33%, as written it read 25%). Both fire here; they differ near 20%.

**6. Q1 `last_write` misses undos.** Undo writes no row, only bumps `updatedAt`. Use
`MAX(MAX(createdAt),MAX(updatedAt))`. Same output on this sample.

**7. Q5 "edited" only follows `objectIDs[0]`.** For a Tess lift that is the new entry or set 1, so editing set 2 or 3 is
missed. Fix (keeps process rows out, since every set also touches the workout's process):
```sql
... AND EXISTS (SELECT 1 FROM json_each(c.objectIDs) j JOIN object o ON o.id=j.value JOIN classDef k
  ON k.id=o.classID AND k.systemKey<>'system.process' WHERE instr(e.objectIDs, j.value)>0)
```
Same 3 rows on this sample.

**8. Dates inside JSON are not Unix time.** Q6 asks to check late Tess dates; `startsAt` is seconds since 2001, so
`datetime(x,'unixepoch')` reads 1995. Add 978307200:
```sql
SELECT strftime('%H:%M',p.createdAt,'unixepoch','localtime') said, o.title,
 datetime(json_extract(CAST(o."values" AS TEXT),'$."'||f.id||'".date._0')+978307200,'unixepoch','localtime') startsAt
FROM op p JOIN object o ON o.id=json_extract(p.objectIDs,'$[0]') JOIN fieldDef f ON f.key='system.task.startsAt'
WHERE p.actor='tess' AND p.action='createTask' AND p.createdAt>=$LATE AND p.createdAt<$END;
```
Output: 23:05 Email landlord 2026-10-22 09:00; 00:45 Gym 2026-10-22 19:00; 03:30 Stretch 10 min 2026-10-22 08:00.

Checked and fine: column names (`action`, `actor`, `state`, `route`, `createdAt`, `updatedAt`, `objectIDs`,
`systemKey`, `deletedAt`, `parentID`) all exist; `CAST(ops AS TEXT) LIKE '%"_0":"lockScreen"%'` matches the real
JSON (`_` is a LIKE wildcard, harmless); upper-case ids make `instr` joins work; `missCount.day` and `$DAY` are both
`YYYY-MM-DD`. Q4's 3 s Tess filter dropped the 1 s discard as intended, but a ghost row left until the next tap can be
discarded later than 3 s and would count as an undo. A Lock Screen take-back of one set from a multi-set capture is a
`deleteObject`, not an undo (`ActionEngine.takeBackLatestSet`), so Q4 misses it.

## Can't be answered from a copy today

- **Misses (Q8):** no `missCount` on master; a real copy gives "no such table", so "misses n/a" until Core ships B.
- Miss text and root causes: on the phone only, by design. Misfire root causes must come from summaries by hand.
- Undo source (in-app, Lock Screen, Siri): undo flips state and records no actor.
- Siri vs Tess bar captures: both `actor='tess'`, no source on the op. Weak hint: Siri commits at once
  (`updatedAt=createdAt`), the bar commits about 2 s later.
- Anything after the copy: a late night's 00:20 to 04:00, and a wrap-up that runs only when he next opens the app.
- Writes lost before autosave (oplog-health B3) leave no trace at all.

## Morning message as it would read (corrected queries, 07:42 copy)

```
Week one, Wed 21 Oct check (copy taken 7:42 AM PT, covers Wed 4:00 AM to Thu 4:00 AM).
Training: Pull B, 19 sets (6 Lock Screen, 7 hold, 2 dial, 4 Tess); finished by him yes; Legs B opened by Shortcut 7:10 PM, closed empty at 1:30 AM.
Tess: 10 captures (6 grammar, 3 on-device, 1 Claude); misfires 3: "Buy chalk Friday", "Lunch walk" (dismissed), a set edited; misses 5 (1 paste).
Undos: 4 (1 within 10 s, 2 within 5 min, 1 later). Late night 11 PM to 4 AM: 3 writes, dates Thu 9 AM, 7 PM, 8 AM (check "Gym").
Copy health: ok, ops 157 up from 122, pending 0.
Warning signs: sign 2 fired (3 misfires, 5 misses), proposing the grammar fix ahead of the queue for Core.
```
With the real (00:20) copy, line 1 reads "partial to 12:20 AM", line 4 "1 write", line 3 "8 captures ... misses 3",
and the Legs B note is missing until Friday.

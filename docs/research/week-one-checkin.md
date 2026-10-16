# Week-one check-in kit (board item 50)

*Research, 2026-10-16, for the coordinator. Traced by hand on `origin/master` at `cef88f1` (Merge #180); no Swift run.
Reads with `training-week-one.md` (what to count at week end), `oplog-health.md`, `late-night.md`, `restore-drill.md`.
Times are Pacific (PDT, UTC-7, all of week one). Paths starting `Core/` are under `TesseraCore/Sources/TesseraCore/`.*

The coordinator can't see his phone. The only copy of his data off the phone is a daily `.tessera` backup: a
byte-for-byte SQLite copy of `tessera.sqlite` plus a one-row `backupInfo` table (`Core/Export/TesseraBackup.swift:33-56`).
A Mac session reads it each morning and posts counts. Nothing here ever writes to his data.

## 1. One-time setup

**His one step (30 s, tonight after install):** Review > Backups > tap the words "a folder you choose" > iCloud Drive >
make or pick a folder named `Tessera` > Open. The line then reads "Also kept in iCloud Drive/Tessera."
- Why it works: `BackupKeeper.pick` saves a bookmark and writes a copy at once (`Features/Backup/BackupKeeper.swift:51-60`);
  after that `runDaily` writes `Tessera-YYYY-MM-DD.tessera` (local calendar date) to that folder too, on the first move
  to the background each calendar day, newest 7 kept (`BackupKeeper.swift:23-33`, `TesseraBackup.swift:90-108`,
  trigger `App/TesseraApp.swift:73-76`). iCloud Drive then syncs it to his Mac. No entitlement needed (a picker grant).
- Without it, the copies stay in On My iPhone > Tessera > Backups and he would have to AirDrop one every morning.

**Mac session, once:** the folder appears at `~/Library/Mobile Documents/com~apple~CloudDocs/Tessera`. If macOS asks
whether Terminal (or Claude) may access iCloud Drive, he says Allow once. Then each morning:

```bash
export TZ=America/Los_Angeles
SRC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Tessera"; W="$HOME/tessera-checkin"; mkdir -p "$W"
F=$(ls -1 "$SRC"/Tessera-*.tessera 2>/dev/null | tail -1); echo "newest: $F"   # dot-files (.partial, .icloud) skipped
cp "$F" "$W/$(basename "$F")"; DB="$W/$(basename "$F")"                          # work on a copy, never in the folder
DAY=$(date -v-4H -v-1d +%F)                    # yesterday's logical day (04:00 to 04:00)
START=$(date -j -f '%Y-%m-%d %H:%M' "$DAY 04:00" +%s); END=$((START+86400))
q() { sqlite3 -readonly -header -column "$DB" "$1"; }
q "PRAGMA quick_check; SELECT identifier FROM grdb_migrations;"   # expect ok, v1, v2
```
- If `ls -a "$SRC"` shows only `.Tessera-<date>.tessera.icloud`, the Mac hasn't downloaded it: `brctl download` that
  path (or open the folder in Finder) and retry. If the newest file is not today's, he hasn't opened Tessera yet today.
- **Coverage lag:** the copy holds everything up to its `backupInfo.createdAt`. Yesterday's logical day is complete only
  if that is after 04:00 today (it usually is: his first morning open and close writes it). Otherwise say "partial".

## 2. The morning list (run in order; `op` and `object` are the real tables, `Core/Model/TesseraDatabaseSchema.swift:12-49`)

`op` columns: `action`, `actor` (user, tess, intent, system), `state` (committed, pending, undone), `summary`,
`createdAt`/`updatedAt` (Unix s), `ops` (JSON), `objectIDs` (JSON), `route` (grammar, onDevice, claude; Tess only).
Undo writes no row: it flips `state` to `undone` and bumps `updatedAt` (`Core/Actions/ActionEngine.swift:137-142`).

**Q1. Copy health (first, gates the rest)**
```sql
SELECT datetime(createdAt,'unixepoch','localtime') AS copied FROM backupInfo;
SELECT COUNT(*) ops, SUM(state='pending') pending, datetime(MAX(createdAt),'unixepoch','localtime') last_write FROM op;
```
Normal: copied this morning after 04:00; `ops` higher than yesterday's copy (keep the old file in `$W`); pending 0.
Threshold: copy older than 30 h, `ops` lower than the day before, or `quick_check` not `ok` (warning sign 1).

**Q2. Sets logged yesterday, by how**
```sql
SELECT COUNT(*) sets FROM object s JOIN classDef c ON c.id=s.classID
WHERE c.systemKey='system.set' AND s.deletedAt IS NULL AND s.createdAt>=$START AND s.createdAt<$END;
SELECT actor, CASE WHEN CAST(ops AS TEXT) LIKE '%"_0":"lockScreen"%' THEN 'lockScreen' WHEN CAST(ops AS TEXT) LIKE
 '%"_0":"hold"%' THEN 'hold' WHEN CAST(ops AS TEXT) LIKE '%"_0":"dial"%' THEN 'dial' ELSE 'other' END src,
 state, COUNT(*) n FROM op WHERE action IN ('logSet','logNextSet','logExercise')
 AND createdAt>=$START AND createdAt<$END GROUP BY 1,2,3;
```
Normal: 15 to 25 live sets on a training day, 0 on the rest day; a third or more from `lockScreen`.
Threshold: a training day under 10 sets, or a day with `startRoutine` and 0 sets (see Q7).

**Q3. Captures by route**
```sql
SELECT actor, COALESCE(route,'-') route, state, COUNT(*) n FROM op
WHERE actor IN ('tess','intent') AND createdAt>=$START AND createdAt<$END GROUP BY 1,2,3;
```
Normal: most `tess` rows on `grammar`, a few `onDevice`, `claude` only where he asked a plan or question.
Threshold: `onDevice` plus `claude` more than half of captures (grammar is missing his phrasing), or any `pending`
left over (a ghost row that never committed or discarded).

**Q4. Undos, within 10 s and later**
```sql
SELECT CASE WHEN updatedAt-createdAt<=10 THEN 'a: <=10s' WHEN updatedAt-createdAt<=300 THEN 'b: <=5min'
 ELSE 'c: later' END lag, action, COUNT(*) n FROM op
WHERE state='undone' AND updatedAt>=$START AND updatedAt<$END
 AND NOT (actor='tess' AND updatedAt-createdAt<3) GROUP BY 1,2 ORDER BY 1;
```
Normal: 0 to 3 a day, nearly all `a`. Threshold: any `c` (a mistake found late), or 3 or more set undos in one session
(he fixes numbers by undo and re-log; editing is too hard).

**Q5. Misfires: a Tess capture undone, dismissed or edited by him within 2 min**
```sql
WITH cap AS (SELECT * FROM op WHERE actor='tess' AND state<>'pending' AND createdAt>=$START AND createdAt<$END)
SELECT 'undone' kind, summary FROM cap WHERE state='undone' AND updatedAt-createdAt<=120
UNION ALL SELECT 'edited', c.summary FROM cap c WHERE c.state='committed' AND EXISTS (SELECT 1 FROM op e
 WHERE e.actor='user' AND e.state='committed' AND e.createdAt BETWEEN c.createdAt AND c.createdAt+120
 AND instr(e.objectIDs, json_extract(c.objectIDs,'$[0]'))>0);
```
Normal: 0 or 1. Threshold: 3 or more in a day, or over a quarter of Q3's `tess` rows (warning sign 2). Read the
summaries against `fixtures/grammar-regression.md` root causes (RC11, RC13, RELT, DAY4, LEAD) and name the code.
The capture-miss log ("Didn't catch that.") is **not readable here**: see Blocks.

**Q6. Late-night writes, 23:00 to 04:00**
```sql
SELECT strftime('%H:%M',createdAt,'unixepoch','localtime') t, actor, action, COALESCE(route,'-') route, summary
FROM op WHERE createdAt>=$END-18000 AND createdAt<$END AND actor<>'system' ORDER BY createdAt;
```
Normal: nothing, or a late workout's sets. Threshold: any Tess capture with a time word ("tonight", "tomorrow", a bare
hour): check its date by `late-night.md` S2 to S5 (logical Friday rules); a wrong date counts as a misfire.

**Q7. Workouts closed by the 6 h wrap-up, and zero-set workouts**
```sql
SELECT o.actor, o.action, datetime(o.createdAt,'unixepoch','localtime') at, w.title,
 (SELECT COUNT(*) FROM object e JOIN object s ON s.parentID=e.id AND s.deletedAt IS NULL
  WHERE e.parentID=w.id AND e.deletedAt IS NULL) sets
FROM op o JOIN object w ON instr(o.objectIDs, w.id)>0 JOIN classDef c ON c.id=w.classID AND c.systemKey='system.workout'
WHERE o.action IN ('finishWorkout','finishWorkoutEarly') AND o.state='committed' AND o.createdAt>=$START;
```
Normal: one row a training day, `actor` user or intent, 15 or more sets. Threshold: any `system` row (the wrap-up
from `ProcessTable.tidy`, written when he next opens the app, so look from `$START` to the copy), or any row with
`sets` 0 (warning sign 3).

## 3. Morning message to Product (6 lines, Pacific)

```
Week one, <Tue 20 Oct> check (copy taken <7:42 AM PT>, covers <Mon 4:00 AM to Tue 4:00 AM> | partial to <time>).
Training: <Push A>, <18> sets (<7> Lock Screen, <9> hold, <2> dial); finished by him <yes | wrapped up at 6 h>.
Tess: <9> captures (<8> grammar, <1> on-device, <0> Claude); misfires <1>: "<task title>" (<root cause>).
Undos: <2> (<2> within 10 s, <0> later). Late night 11 PM to 4 AM: <none | 3 writes, dates right | wrong>.
Copy health: <ok, ops 1,204 up from 1,151 | stale since Sun>.
Warning signs: <none | sign N fired, proposing <fix> ahead of the queue for <owner>>.
```

## 4. Three warning signs that jump a fix ahead of the queue

| # | Sign and detecting query | Threshold | Likely cause (file:line) | Owner |
|---|---|---|---|---|
| 1 | **His data isn't safe.** Q1 | No new copy for 2 mornings running while he used the app; `ops` falls from one copy to the next; `quick_check` fails | Both daily writes are `try?`, so a failure is silent (`Features/Backup/BackupKeeper.swift:23-33`); the copy only runs on a move to background (`App/TesseraApp.swift:73-76`); Lock Screen and Siri writes wait on autosave and can be lost (`Core/Model/TesseraContext.swift:222-230`, oplog-health B3) | Core |
| 2 | **Tess writes the wrong thing.** Q5 (with Q6's night rows) | 3 or more misfires in a day, or over 25% of captures, or the same root cause on 2 days | `TessDates.find` in `TesseraCore/Sources/TesseraTess/TessGrammar.swift:492` (RC11, RC13, RELT, about 61 regression rows); late "tonight" at `TessGrammar.swift:502-507` | Core |
| 3 | **A workout doesn't close properly.** Q7, cross-checked with Q2 | Any `system` finish, or any finished workout with 0 sets | Zero-set wrap-up saved as trained (`Core/Processes/ProcessTable.swift:122-125`, Core). A wrap-up with sets means he walked away without finishing: the finish step on the live screen (`Features/Workout/WorkoutSession.swift:555-562`) and the all-night "Go" Live Activity (`Features/Workout/LiveActivity/RestActivityController.swift:117`) | Core if 0 sets; Builder A if sets |

When a sign fires, the morning message names it on line 6 with the fix and owner, and the coordinator moves that fix
to the top of the owner's queue that day. Builder B's wrap-up line (`App/AppModel.swift:252`, the note nobody sees)
rides with sign 3.

## 5. Privacy

- Only counts, action names, routes and titles of his own items (task titles, routine names) go into project files or
  messages. No set weights or reps lists, no Health values of any kind, no note bodies, no full capture text beyond a
  task title.
- The `.tessera` copies stay on his Mac in `~/tessera-checkin`; never copy one into the repo, the project files or a
  cloud session. Delete copies older than 7 days there.
- Read-only always: work on the copy, `sqlite3 -readonly`, no `UPDATE`, no restore, never write into the iCloud folder.

## Blocks on master

- **The capture-miss log can't be read from a backup.** It is `capture-misses.jsonl` beside the store, excluded from
  device backup and never in a `.tessera` copy, by design (`Core/Diagnostics/CaptureMissLog.swift:3-5, 29-32`). So
  "Didn't catch that." misses are invisible to this kit. Smallest fix (Core): a `missCount(day, route, source, n)`
  table written into each `.tessera` copy, counts only, text stays on the phone. Until then Q5 counts misfires only.
- Undo source is not recorded (training-week-one count 5), so Q4 can't split in-app, Tess bar and Siri undos.
- The daily copy is one per calendar day, so a copy taken at 00:15 after a late session misses 00:15 to 04:00 until
  the next day's copy (`late-night.md` S9). Q1's coverage line says so.

# Monday's pull list (board item 128, for 101)

For: the coordinator and the Mac session that reads his backup copy on Mon Oct 19. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). This is the short list behind `week-two.md` (item 101): what to read from his first training weekend, where each thing lives, and which edit it feeds. It was checked by hand against the build on his phone, 444e72b (installed 11:28 PM PT Oct 15). Nothing was run.

**Goal.** His answers arrive, the reads below are already done, and `week-two.md`'s edits go out within the hour.

## 0. Before Monday (the coordinator, 5 minutes)

- **Which build made the copy.** Read `backupInfo.migrations` (`SELECT * FROM backupInfo;`).
  - A copy with "v6" or later in that list came from 7b321d2 or newer. Note it, because routine weekdays and `scheduleMode` only exist from v6 on.
  - On 444e72b, routines have no weekdays: the plan rolls on.
- **The window.** Fri 16 Oct 04:00 to Mon 19 Oct 04:00 PDT: `S=1792148400`, `E=1792407600` (checked with `date`).
- **Two clocks.**
  - Columns named `createdAt`, `updatedAt` and `deletedAt` are seconds since 1970.
  - Dates inside an object's `values` JSON (`startedAt`, `endedAt`, `loggedAt`, `doneAt`) are seconds since 2001. Add `978307200` before comparing them with `S` and `E`.
- **Privacy** (`week-one-checkin.md` §5). Only counts, weekdays, routine names, exercise names and kit settings leave the Mac. His set weights and reps never do.

## 1. The pulls

| # | What | Where it lives on 444e72b | How to read it | Feeds (week-two.md) |
|---|---|---|---|---|
| P0 | Copy health | `backupInfo`, `PRAGMA quick_check` | `week-one-checkin.md` Q1. A failing P0 stops everything else: use every "no data" wording | All |
| P1 | Sets per day | `object` with class `system.set`, `createdAt` | `week-two.md` W1 (86's D1) | Q1 sets |
| P2 | Starts, finishes, and days with nothing | `op.action` in `startRoutine`, `startWorkout`, `finishWorkout`, `finishWorkoutEarly` (state `committed`) | `week-two.md` W2. A **missed day** is a logical day with 0 starts that isn't the free day (P3). There is no "missed" object: the plan rolls on | Q2 missed days |
| P3 | Rest days | `settings` object, field `system.settings.restWeekday` (empty unless he set it); the free day is the one with 0 starts | `SELECT json_extract(CAST(o."values" AS TEXT),'$."'||f.id||'"') FROM object o JOIN classDef c ON c.id=o.classID AND c.systemKey='system.settings' JOIN fieldDef f ON f.key='system.settings.restWeekday';` then W3 | Q4 rest day; Oct 22 question 12 |
| P4 | Day marks (skip, rest today) | **Not on 444e72b.** Product logged the day mark tonight, and it isn't built. Exercise skips inside a workout live on `system.exerciseEntry.skipped` | Count entries with `skipped` true in the window: exercise names and counts only | Q1 (a "Most" answer); no day-mark edit |
| P5 | Bests | **Not stored**: `TrainingLedger` computes them | Per exercise, the best e1RM (weight × (1 + reps / 30), warm-ups excluded) in the window against everything before `S`. The query is below. Report the **count** and the exercise names only | Q1 message line ("2 new bests"); 101's progression note |
| P6 | Body weight | **Not on 444e72b** (no class; it is on Builder A's queue) | Nothing to read. If he mentions it Monday, it goes to Builder A's Body weight item as a note | none |
| P7 | The set ask | It writes nothing. The proxies are Tess-logged sets and takebacks | `week-two.md` W4. 444e72b carries the ask (#248 fdcaee4 and #254 e7a5be4 are both ancestors, checked), so W4's "no ask in his build" row doesn't apply | Q3 set ask |
| P8 | His kit | `system.equipment` objects: `barWeight`, `plates`, `loads` | `week-two.md` W5 and 86's D4 (`near_top`, `edits`). Kit values may be quoted | Q5 weights |
| P9 | How workouts ended | `op.actor` on finishes (`user`, `intent`, `system`) | `week-two.md` W6 | Q1 "Most" |
| P10 | What Tess missed | `CaptureMissLog`, a JSON lines file beside the database. **Never in the backup**, by design | Not readable from the copy. Skip it; Kitchen's week-one read uses it on the phone | none |

**The P5 query.** Class refs are rows in `link` (`toClassID`), not values. Adjust the JSON paths (`mass._0`, `number._0`, `bool._0`) on the first run if they differ.

```sql
WITH f AS (SELECT key, id FROM fieldDef WHERE key IN
  ('system.set.weight','system.set.reps','system.set.isWarmup','system.exerciseEntry.exercise')),
sets AS (
  SELECT s.createdAt t, x.name ex,
    json_extract(CAST(s."values" AS TEXT),'$."'||(SELECT id FROM f WHERE key='system.set.weight')||'".mass._0') w,
    json_extract(CAST(s."values" AS TEXT),'$."'||(SELECT id FROM f WHERE key='system.set.reps')||'".number._0') r,
    json_extract(CAST(s."values" AS TEXT),'$."'||(SELECT id FROM f WHERE key='system.set.isWarmup')||'".bool._0') wu
  FROM object s JOIN classDef cs ON cs.id=s.classID AND cs.systemKey='system.set'
  JOIN object e ON e.id=s.parentID
  JOIN link l ON l.fromID=e.id AND l.fieldID=(SELECT id FROM f WHERE key='system.exerciseEntry.exercise')
  JOIN classDef x ON x.id=l.toClassID
  WHERE s.deletedAt IS NULL AND w > 0 AND r > 0 AND IFNULL(wu,0)=0)
SELECT ex FROM sets GROUP BY ex
HAVING MAX(CASE WHEN t>=1792148400 AND t<1792407600 THEN w*(1+r/30.0) END)
     > IFNULL(MAX(CASE WHEN t<1792148400 THEN w*(1+r/30.0) END), 0);
```

The query prints only exercise names, so nothing private leaves the Mac. If he had no sets before `S` (his data began this weekend), every exercise counts as new. Then say "first numbers" in the message, not "bests", and skip the count.

## 2. What changed since week-two.md was written (Oct 15, `d9780e1`)

1. **His phone runs 444e72b**, not b19fb4a. It has the set ask (#248 and #254). So Q3 can use its "with data" wording if P7 shows asks were answered.
2. **Rest day.** If he has already answered Oct 22's question 12, or said "rest day Sunday" to Tess (on 444e72b that phrase makes a task called "Rest day", item 122 V-T12), Q4 is settled. Check `decisions.md` before sending Monday's message. A task titled "Rest day" in the window counts as his answer.
3. **Fixed days and day marks** (v6, #341 and #363, and Product's day-mark decision) aren't on 444e72b. `week-two.md`'s Q2 edits assume a rolling plan, which is still right for this weekend's data.
4. **"best", not "PR".** Product's 8e55cd9 makes "best" the one word everywhere. Any message line built from P5 says "new best".
5. **Trip week.** The re-read on Mon Oct 26 (`S=1792407600`, `E=1793012400`) runs before the trip starts at 22:30 that night, so the zone breaks in `fixtures/trip-rehearsal.md` (T1 to T3) don't touch it. The week after, Nov 2, does: read it after Core's T1 lands.

## 3. Order on Monday

1. Run P0. If it fails, stop and use the "no data" wordings.
2. Run P1 to P3, P5, P7 and P8 in one pass, about 10 minutes, and paste the counts into the coordinator's note.
3. When his answers arrive, take each answer's block from `week-two.md` §3, adjusted by §2 above, and send it to Product.

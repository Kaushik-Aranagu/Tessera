# Training week one: Monday's one-word questions (board item 86)

*Research, 2026-10-16, for the coordinator's Mon 19 Oct 9:50 AM PT trigger. Drawn from `week-one-checkin.md`,
`week-one-dryrun.md` (corrected queries), `miss-counts.md`, `backup-logical-day.md`, `fixtures/set-logger.md`,
`set-logger-rerun.md`, `starter-content.md` and `product/decisions.md`. Times Pacific (PDT). No Swift run.*

**What Monday's copy covers.** Week one proper runs Mon 19 to Sun 25 Oct (`training-week-one.md`), so Monday's copy
holds the warm-up weekend: logical days Fri 16, Sat 17, Sun 18 (Fri 04:00 to Mon 04:00 PT). The answers set the
defaults for the week that starts that morning. Current defaults: kg, PPL x2 (Push A, Pull A, Legs A, Push B, Pull B,
Legs B; 16 to 18 planned sets each), 20 kg bar, 1.25 kg smallest plate (one pair each, so the bar tops out at 177.5 kg),
dumbbells 2 to 50 kg in 2 kg steps, a missed day rolls on, 6 h auto-finish, SQ8 set asks, the 4 AM day.

**I can't read the copy** (his iCloud Drive). The Mac session runs `week-one-checkin.md` section 1 setup (copy to
`~/tessera-checkin`, `sqlite3 -readonly`, `TZ=America/Los_Angeles`), then the reads below with fixed bounds
S=1792148400 (Fri 16 04:00) and E=1792407600 (Mon 19 04:00); no DST change in this window, so `-14400` is safe.
- **Which variant.** No `Tessera-*.tessera` in the folder: the folder isn't set, use every "no data" wording and add
  the setup line to the message. Copy present but D1 is empty: he didn't train, use "no data" wordings. Copy taken
  before 04:00 Mon (`backupInfo.createdAt`, or newest file is `-10-18`): partial, say "so far" in Q1.

```sql
-- D1 sets per logical day and workout (feeds Q1, Q2, Q4)
SELECT date(s.createdAt-14400,'unixepoch','localtime') day, strftime('%w',s.createdAt-14400,'unixepoch','localtime') wd,
 w.title, COUNT(*) sets FROM object s JOIN classDef c ON c.id=s.classID AND c.systemKey='system.set'
 JOIN object e ON e.id=s.parentID JOIN object w ON w.id=e.parentID
WHERE s.deletedAt IS NULL AND s.createdAt>=1792148400 AND s.createdAt<1792407600 GROUP BY 1,2,3 ORDER BY 1;
-- D2 how workouts ended (dry run bug 4 fix: a system deleteObject is an empty wrap-up)
SELECT o.actor, o.action, datetime(o.createdAt,'unixepoch','localtime') at, w.title FROM op o
 JOIN object w ON instr(o.objectIDs,w.id)>0 JOIN classDef c ON c.id=w.classID AND c.systemKey='system.workout'
WHERE (o.action IN ('finishWorkout','finishWorkoutEarly') OR (o.action='deleteObject' AND o.actor='system'))
 AND o.state='committed' AND o.createdAt>=1792148400;
-- D3 sets by source (bug 2 fix; 'tess' and 'none' are Tess sets) and Tess set ops taken back (feeds Q1, Q3)
SELECT COALESCE(json_extract(CAST(s."values" AS TEXT),'$."'||f.id||'".choice._0'),'none') src, COUNT(*) sets
FROM object s JOIN classDef c ON c.id=s.classID AND c.systemKey='system.set' JOIN fieldDef f ON f.key='system.set.source'
WHERE s.deletedAt IS NULL AND s.createdAt>=1792148400 AND s.createdAt<1792407600 GROUP BY 1;
SELECT state, COUNT(*) n FROM op WHERE actor='tess' AND action IN ('logSet','logNextSet','logExercise')
 AND createdAt>=1792148400 AND createdAt<1792407600 GROUP BY 1;
-- D4 loads near the kit's top (EZ 167.5, bar 177.5) and weight fixes after logging (feeds Q5)
SELECT SUM(x>=167.5) near_top, COUNT(*) sets FROM (SELECT json_extract(CAST(s."values" AS TEXT),'$."'||f.id||'".mass._0') x
 FROM object s JOIN classDef c ON c.id=s.classID AND c.systemKey='system.set' JOIN fieldDef f ON f.key='system.set.weight'
 WHERE s.deletedAt IS NULL AND s.createdAt>=1792148400 AND s.createdAt<1792407600);
SELECT COUNT(*) edits FROM op WHERE action='editSet' AND state='committed' AND createdAt>=1792148400 AND createdAt<1792407600;
```
Privacy (`week-one-checkin.md` 5): only counts and routine names go in the message; never his set weights.

## Q1. Sets logged (D1, D2, D3)
**Ask:** "Sat Push A: 17 sets. All of them?" (day, routine, count from D1; one workout: the one with most sets).
If D2 shows a `system` row: "Push A closed itself after 6 hours with 17 sets. All of them?" **Default: All.**
**No data:** "Did you train this weekend?" Yes / No. Yes means sets went unlogged: treat as Most.

| Answer | Change | Owner |
|---|---|---|
| **All** (default) | None. Keep the 6 h auto-finish; D3's Lock Screen share is the week's baseline | coordinator |
| Most | Board item: save right after each Lock Screen and Siri set (oplog-health B3, lost before autosave) moves ahead; if D2 had a wrap-up, the finish step on the live screen joins it | Core; Builder A |
| Few | Board item: watch the next 3 sessions with the morning kit Q2 and Q7; Design reviews taps per set on the live screen | Research; Design, Builder A |

## Q2. Missed days (D1 days with 0 sets, D2's last finished routine)
**Ask:** "No workout Sunday, so today is Pull A, next in line. Good?" (the empty day and the routine after the last
finished one). With no gap: "If you miss a day, pick up where you left off?" **Default: Yes.**
**No data:** "If you miss a day, pick up where you left off?"

| Answer | Change | Owner |
|---|---|---|
| **Yes** (default) | None. A missed day rolls on (morning-questions 3, `PlanSchedule.swift:3-21`) | coordinator |
| No | Reopens his Oct 15 call: Product logs fixed weekdays; board item gives the plan `startsOn` and a weekday per routine, and Week shows today's routine by date | Product; Core |

## Q3. The set asks (SQ8; D3 Tess sets and take-backs)
The copy never records that an ask was shown, and the ask exists only if his build has it (check `install-check.md`
against the review guide tag). **Ask, with Tess sets and the ask in his build:** "When you say '2 x 10', I ask
'2 sets or 2 kg?'. Keep asking?" **Default: Keep.**
**No data** (no Tess sets, or the build lacks the ask): "If you say '2 x 10', should I ask 'sets or kg?' first?" Ask / Sets.

| Answer | Change | Owner |
|---|---|---|
| **Keep** / Ask (default) | None. SQ8 as decided 7:53 PM Oct 15 (N 6 or less and under half the last weight) | coordinator |
| Less | Board item: ask only when N is 3 or less; group K and Q8 rows re-run | Core; Research |
| Never / Sets | Product logs it; board item drops the ask, a bare N x M is always sets, and Undo is the fix for a wrong one | Product; Core |

## Q4. Rest day (D1 weekdays with no sets)
The seeded plan has no weekly rhythm, so no rest day ever shows (`starter-content.md` M2). **Ask:** "Rest day:
Sunday?" (or the weekday D1 shows empty, if not Sunday). **Default: Yes (Sunday).**
**No data:** "Which day do you want off? Sunday?" Same answers.

| Answer | Change | Owner |
|---|---|---|
| **Yes** (default) | Board item: the starter plan gets 6 sessions a week and Sunday off, so Now shows "Rest day" (fixes M2) | Core; Builder B (the line) |
| A weekday ("Wednesday") | Same, with that day | Core; Builder B |
| Any | 6 a week with no fixed day: he rests when he skips, Now never says "Rest day"; Product logs it | Product; Core |

## Q5. Weights (D4)
**Ask:** "Do the app's weights match your gym?" If D4 `near_top` > 0: "The bar tops out at 177.5 kg in the app.
Enough?" (Yes / Plates). If `edits` is 3 or more, add "You fixed 4 weights." before the question. **Default: Yes.**
**No data:** the same first wording.

| Answer | Change | Owner |
|---|---|---|
| **Yes** (default) | None. 20 kg bar, 1.25 kg plates, dumbbells in 2 kg steps stay | coordinator |
| Dumbbells | Follow-up later today: "Step 2.5 or 1?"; board item changes the kit's dumbbell rack (`StarterContent.swift:61`) | Core |
| Plates | Board item: two pairs of 20 and 25 in the kit (`StarterContent.swift:60`), so the bar reaches 267.5 kg | Core |

## The 9:50 AM PT message (Mon 19 Oct)
Filled from the reads; one-word replies, he can say "defaults" to take every ★.
```
Morning! Week one starts today. 5 quick ones, one word each, or say "defaults" for every ★.
1. Sat Push A: 17 sets. All of them? ★All / Most / Few
2. No workout Sunday, so today is Pull A. Good? ★Yes / No
3. When you say "2 x 10", I ask "sets or kg?". Keep asking? ★Keep / Less / Never
4. Rest day: Sunday? ★Yes / another day / Any
5. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
(Folder not set: add "6. 30 s: Review > Backups > a folder you choose > iCloud Drive/Tessera. ★Done")
```

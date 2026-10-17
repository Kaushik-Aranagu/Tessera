# Week-two plan (board item A, 101, Monday Oct 19)

For: the coordinator and Product. Owner: Research lab. Written Sat Oct 17, 2026 (Pacific). This folds `week-two-monday.md`
(144's kit), `week-two-pulls.md` (128) and the 25 fixes in `week-two-stale-check.md` into one plan, so nothing has to be
read against the other three. Decisions are read through 6:44 pm Oct 16 (`product/decisions.md`). Nothing was run. The
repo copy of `docs/research/` here is behind master (no restWeekday reader, which agrees with the stale check), so code
lines are cited from the stale check's pass on `9ab8ae3`.

**Eval prep.** Board item A lists none. The two Claude gates (use 1 grammar misses, use 2 Plan my day) wait for his key
and his yes, not for Monday. Nothing here spends a Claude call.

## 1. What is true on Monday morning

1. **Phone build.** Release 1 is `56dd028` (#544). Decisions log later releases (release 7 is `26dde994`, 6:32 pm Oct 16).
   Read the build from the copy's `backupInfo.migrations` (expect v9), not from this page. Every release since `a36b161`
   carries the set ask (#248, #254), routine weekdays and fixed days (#341, #359, #363) and the stored best flag
   (`wasRecord`, #344).
2. **Signing lapses Fri Oct 23, 2:12 pm.** The riders check is the Thu Oct 22, 9:30 am call. Fixes ride the next release
   on merge (3:03 pm rule, gates kept). Nothing waits for an Oct 22 install.
3. **`restWeekday` is stored and read by nothing.** Catalog v9 (`SystemCatalog.swift:244`, `TesseraSettings.swift:25`).
   `week()`, `restDay` and NowPage do not read it. Until the reader lands, the rest day floats where the engine puts it.
4. **Day marks ("rest day today") are decided, not built.** A planned session beats a rest day. Receipts are thing first.
5. **Settled by Product, 11:47 am Oct 16.**
   - Q4 "Yes, Sunday": keep the rolling plan and store `restWeekday`. Core adds the reader. Fixed days ignore it.
   - Message B's Q1 is "Did every set you lifted this weekend get logged?" with Yes, Most or Didn't train.
   - Q2 "No": he switches to fixed days himself on the Routines page. Builder A only if he asks.
   - First launch of the build with the reader writes Sunday as one op with UNDO (11:52 am). A session trained on Sunday
     anyway advances the roll. Changing the rest weekday never redraws past weeks.

## 2. Monday run order (Pacific)

| # | Time | Step | Who |
|---|---|---|---|
| 1 | 7:00 am | Confirm the build from the copy. Read `decisions.md` for any Kaushik answer since 6:44 pm Oct 16. A rest-day answer (or a "Rest day" task from him in the window) drops Q4 | coordinator |
| 2 | 7:30 am | Copy the newest `.tessera` to `~/tessera-checkin`. Run P0. If P0 fails or there is no copy, use message B | Mac session |
| 3 | 7:40 am | One pass of about 10 minutes: P1, P2, P3, P5, P7, P8, P9 with S=1792148400 and E=1792407600 | Mac session |
| 4 | 8:00 am | Post counts, weekdays, routine and exercise names only (section 6) to the coordinator's note | Mac session |
| 5 | 8:15 am | Fill message A from the counts, or take B. Pick wordings by the rules under section 3 | coordinator |
| 6 | 8:30 am | Findings that move work whatever he answers (a 0-set wrap-up, kept light Tess sets) go to Product now | coordinator |
| 7 | 8:45 am | Pre-fill section 4's blocks so only his reply time is left | coordinator |
| 8 | 9:50 am | The training-questions trigger fires. Send the message | coordinator |
| 9 | Reply + 20 min | `decisions.md` lines, then board edits grouped by board, in one message to Product. Product applies and tells each owner by reply + 45 min | coordinator, Product |
| 10 | 6:00 pm | Anything unanswered carries to Thursday (`oct-22-list.md`). Q4 is already its question 12. The rest go in Thursday's 6:00 pm message. Q1 drops as stale | coordinator |

The window is Fri Oct 16, 4:00 am to Mon Oct 19, 4:00 am PDT (S and E checked with `date`). Columns `createdAt`,
`updatedAt` and `deletedAt` are seconds since 1970. Dates inside an object's `values` JSON are seconds since 2001, so add
978307200 before comparing them with S and E.

## 3. The pulls (what to read, where it lives)

| # | What | Where | How to read it | Feeds |
|---|---|---|---|---|
| P0 | Copy health | `backupInfo`, `PRAGMA quick_check` | `week-one-checkin.md` Q1. A failing P0 stops everything: use the no-data wording | all |
| P1 | Sets per day | `object`, class `system.set`, `createdAt` | Count per logical day (4 am day) | Q1 |
| P2 | Starts, finishes, empty days | `op.action` in `startRoutine`, `startWorkout`, `finishWorkout`, `finishWorkoutEarly` (state `committed`) | A missed day is a logical day with 0 starts that is not the free day (P3). There is no "missed" object | Q2 |
| P3 | Rest days | `settings` object, field `system.settings.restWeekday` (empty unless he set it) | Empty means the free day is the one with 0 starts | Q4 |
| P4 | Skips | `system.exerciseEntry.skipped` | Count true entries in the window, exercise names and counts only. Day marks are not built | Q1 "Most" |
| P5 | Bests | `wasRecord` on the set (#344) on v6+ copies | Count sets flagged, report exercise names only. On a v5 copy use `TrainingLedger`'s best e1RM query in `week-two-pulls.md` | message line, Q1 |
| P6 | Body weight | Not read Monday | If he mentions it, it goes to the body weight owner as a note | none |
| P7 | The set ask | Writes nothing. Proxies: Tess-logged sets and takebacks | With the ask on his build, a kept light Tess set means the ask was missed | Q3 |
| P8 | His kit | `system.equipment`: `barWeight`, `plates`, `loads` | Kit values may be quoted. `near_top` counts and `edits` count | Q5 |
| P9 | How workouts ended | `op.actor` on finishes (`user`, `intent`, `system`) | A `system` finish means the 6-hour auto-finish closed it | Q1 |
| P10 | What Tess missed | `CaptureMissLog`, beside the database | Never in the backup. Skip it | none |

**Wording rules for message A.**
- No sets before S: every lift is new, so line 3 reads "First numbers on [Bench press, Squat]." Say "best" only when there
  was history to beat.
- P9 `system` finish: Q1 reads "[Push A] closed itself after 6 hours with [17] sets. All of them?"
- No empty day: Q2 reads "If you miss a day, pick up where you left off?"
- Q3 uses the with-data wording. If P7 shows kept light Tess sets, say so first: "Tess asked [N] times and you kept [M]."
- P8 `near_top` over 0: Q5 reads "The bar tops out at 177.5 kg in the app. Enough? ★Yes / Plates". `edits` of 3 or more
  adds "You fixed [4] weights." first.
- Q4 already answered: drop it and say "4 quick ones".
- Folder not set: add "6. 30 s: Review > Backups > a folder you choose > iCloud Drive/Tessera. ★Done".

## 4. The message, ready to paste

**A. With data** (P0 passed and the copy has sets).
```
Your first training weekend, from last night's backup:
[days trained] days trained ([Sat Push A, Sun Pull A]), [sets] sets in all.
[N] new bests: [Bench press, Lat pulldown].
Your training week starts today. 5 quick ones, one word each. Reply "defaults" to take every ★.
1. [Sat] [Push A]: [17] sets. All of them? ★All / Most / Few
2. No workout [Sunday], so today is [Pull A]. Good? ★Yes / No
3. When you say "2 x 10", I ask "2 sets, or 2 kg?". Keep asking? ★Keep / Less / Never
4. Rest day: Sunday? ★Yes / Another day (say which) / Any
5. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
```

**B. No data** (P0 fails, or no copy).
```
I couldn't read your weekend from the backup, so no numbers today.
Your training week starts today. 5 quick ones, one word each. Reply "defaults" to take every ★.
1. Did every set you lifted this weekend get logged? ★Yes / Most / Didn't train
2. If you miss a day, pick up where you left off? ★Yes / No
3. If you say "2 x 10", should I ask "2 sets, or 2 kg?" first? ★Ask / Sets
4. Rest day: Sunday? ★Yes / Another day (say which) / Any
5. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
6. 30 s: Review > Backups > a folder you choose > iCloud Drive/Tessera. ★Done
```
B's Q1: Yes = All, Most = Most, Didn't train = no edit. "defaults" logs whatever weekday Q4 shows (decisions 9:06 pm Oct 15),
so pre-fill Sunday unless P3 shows another free day.

## 5. Board edits per answer (so the reply turns into work the same morning)

`<time>` is his reply time. Receipts are thing first. Paths are under `TesseraCore/Sources/TesseraCore/`.

| Q | Answer | Edit | Owner |
|---|---|---|---|
| Q1 | All ★ | None. The 6-hour auto-finish stays | none |
| Q1 | Most | Core: save right after each Lock Screen and Siri set (still autosave, `Model/TesseraContext.swift:222-231`). Builder A: the finish step, only if P9 had a `system` finish | Core, Builder A |
| Q1 | Few | Research starts a sets-logged watch. Design cuts taps per set. Builder A builds Design's change | Research, Design, Builder A |
| Q2 | Yes ★ | None. The plan stays ROLLS ON. A missed day rolls on (`Training/PlanSchedule.swift:20-30`) | none |
| Q2 | No | `decisions.md`: "Fixed days, a missed day waits (<time> PT, Kaushik, Monday Q2 No)". He switches PPL x2 to FIXED DAYS and pins days on the Routines page ("PPL x2, on fixed days."). Builder A writes it only if he asks. The fields and readers are built, so Core only keeps tests that Now, Review and the Plans week read fixed days. QA checks them on his restored copy | Product, QA, Core |
| Q3 | Keep ★ | Core's done note gets "; Kaushik kept the ask Mon 19 Oct (<time> PT)" | Core |
| Q3 | Less | Core: ask at N of 3 or less (`TessGrammar+Live.swift:141`). Research re-runs K876 to K881, K817, D473, Q01 to Q28. Rides the next release on merge | Core, Research |
| Q3 | Never | `decisions.md` line. Core drops the bare N x M ask. Builder A line edit. Research rows to "sets". Rides the next release on merge | Product, Core, Builder A, Research |
| Q4 | Yes ★ | `decisions.md`: "Sunday, rest day" (new). Core: the reader in `week()` and `restDay` on a rolling plan (6 a week over Mon to Sat), plus one op with UNDO on first launch writing `restWeekday` = 1 ("Sunday, rest day."). Fixed days ignore it. Builder A and Builder B pass nothing new. QA checks that Now, Review and Plans show Sunday as rest. Ships in the next release. If the reader misses it, Sunday keeps the engine's floating rest day | Product, Core, Research, QA |
| Q4 | Another day | The same with that day's number (Mon 2 to Sat 7) | same |
| Q4 | Any | `decisions.md`: "No fixed rest weekday". `restWeekday` stays empty | Product |
| Q5 | Yes ★ | None | none |
| Q5 | Plates | Core: two pairs of 25 and 20 (`Catalog/StarterContent.swift:60`), his Equipment by one op with UNDO ("Plates, two pairs of 25 and 20."), skipping values he set. Research re-runs kit rows | Core, Research |
| Q5 | Dumbbells | Same day, send "Dumbbells: steps of 2.5 kg or 1 kg? ★2.5 / 1". Then Core's rack block (`StarterContent.swift:61`) with the receipt "Dumbbells, steps of 2.5 kg." and Research's rows | coordinator, Core, Research |
| all | any | Thursday: drop `oct-22-list.md` question 12 once Q4 is answered. Research re-reads his week on Mon Oct 26 | coordinator, Research |

**Re-read on Mon Oct 26** uses S=1792407600 and E=1793012400. It runs before the trip starts that night, so the zone
breaks in `fixtures/trip-rehearsal.md` (T1 to T3) do not touch it. The Nov 2 read does: take it after Core's T1 lands.

## 6. Privacy (what leaves the Mac)

- **May leave:** counts (sets, days, starts, finishes, undos, edits, `near_top`, light-set count), weekdays, routine names,
  exercise names, kit settings (bar, plates, dumbbell rack), build and copy dates.
- **Never leaves:** any set weight or reps, e1RM values, body facts (weight, Health values), money, note bodies, Private
  note text, his Claude key. The `.tessera` copy stays in `~/tessera-checkin`, is read with `sqlite3 -readonly`, and is
  deleted after 7 days. The message quotes counts and names only: "[17] sets" is fine, "Bench 80 × 8" is not.

## 7. Open questions for Product

1. **Which build to write against.** Decisions log release 7 (`26dde994`). Confirm the newest installed release and that it
   carries no change to the set ask or the Plans week, or section 5 needs a re-read on that head.
2. **Is Core's `restWeekday` reader on a release yet?** I could not confirm it from the files here. If it is not, Q4 "Yes"
   writes a value nothing reads, so the same-morning receipt should wait for the reader's merge.
3. **Thursday's 6:00 pm message.** Do Q4 and any unanswered Monday question both ride it, or does Q4 get a Tuesday nudge?

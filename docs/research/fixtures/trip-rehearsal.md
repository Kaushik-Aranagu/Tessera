# The Oct 26 trip, rehearsed (board item 127)

For: Core. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Traced by hand on master e9bfef0, not run (no Swift toolchain). TessMemory's 04:00 turnover is not on master; it is
traced on `origin/core/tess-memory` (f55bb0e, #356). Builds on `fixtures/dst-travel.md` (D01 to D20) and
`zone-per-item.md`. Decisions used: day boundary 04:00; Day log times print in the phone's current zone, the day an
item lands on reads its stored zone (8:56 PM PT); quiet hours 23:00 to 07:00; Plan my day window 07:00 to 21:00, offer
from 08:00; Shutdown 21:00; PPL x2 rolling, 6 a week, rest Sunday.

## What landed since dst-travel.md

| Piece | Where on master | Effect on the trip |
|---|---|---|
| `op.zone` column, migration v3 | `Model/TesseraDatabaseSchema.swift:52-55`, insert `:118`, load `:251`; `Models.swift:549-552` | Every op stores where he was |
| Stamped in `perform` | `Actions/ActionEngine.swift:38` (`autoupdatingCurrent`), `:67` | One door; Tess, intents and app all get it |
| JSON export key | `Export/TesseraExport.swift:78`, write `:140`, restore `:253` | Zone rides out and back |
| Day log reads the zone | `DayLog/DayStory.swift:118-125`, root zone `:433-454`, workouts `:221` | Items land on the day of the zone they were logged in |
| Workouts by start day | `Training/WorkoutSummary.swift:101` | Start day, but in the **current** zone (no `op.zone` read) |
| Day cache keyed by zone | `Training/WorkoutSummary.swift:92-96` | D08 fixed |
| Tasks, roll-forward, history on `TesseraDay` | `Tasks/Tasks.swift:38-47, 64`; `Tasks/RollForward.swift:52-56, 100-102`; `Features/Exercise/ExerciseDigest.swift:191-197` | D05, D11, D17, D19 fixed |

**dst-travel rows now fixed on master:** D04, D14 (start day, `WorkoutSummary.swift:101`), D05, D11 (`Tasks.swift:38-47`),
D08 (`WorkoutSummary.swift:92-96`), D17 (`RollForward.swift:100-102`), D19 (`ExerciseDigest.swift:191-197`). All 7 old
fails pass. **D07 now fails:** it passed "by accident" under the old midnight cut; under `TesseraDay` in the current
zone, the Wednesday hotel session reads as Tuesday once he is home. That is T1 below.

## The trip

Offsets: PDT is UTC-7, EDT is UTC-4, all four days (fall back is 1 Nov). In flight the phone keeps the zone it took
off in (airplane mode, no network), so `autoupdatingCurrent` stays put until landing (one device check, Q1).

| Step | Pacific | Eastern | UTC | What he does | Stored (action, `op.zone`) |
|---|---|---|---|---|---|
| S1 | Mon 26 17:30 to 18:32 | 20:30 to 21:32 | 00:30Z to 01:32Z Tue | Push A in LA, 18 sets, Bench 82.5 × 8 | `startRoutine` ... `finishWorkout`, LA |
| S2 | Mon 18:40 | 21:40 | 01:40Z Tue | Types "call mom tue 9am", "send invoice tue 10pm" | `createTask` ×2, LA; `startsAt` 16:00Z Tue, 05:00Z Wed |
| S3 | Mon 22:15 | Tue 01:15 | 05:15Z Tue | Backgrounds at the gate; boards 22:30 PDT | nothing; backup try |
| S4 | Tue 01:20, 01:30 | 04:20, 04:30 | 08:20Z, 08:30Z | In flight: done "expense report"; note "slept two hours" | `setTaskDone`, `createNote`, LA |
| S5 | Tue 03:55 | 06:55 | 10:55Z | Lands 06:45 EDT, opens the app; phone now EDT | roll-forward, turnover |
| S6 | Tue 09:05 | 12:05 | 16:05Z | Done "call mom" | `setTaskDone`, NY |
| S7 | Tue 17:10 | 20:10 | 00:10Z Wed | Meal out, note "dinner at Via Carota" | `createNote`, NY |
| S8 | Wed 02:35 | 05:35 | 09:35Z | Opens the app before the hotel gym | roll-forward, turnover |
| S9 | Wed 02:40 to 03:30 | 05:40 to 06:30 | 09:40Z to 10:30Z | Pull A in the hotel gym, Row 70 × 8 | `startRoutine` ... `finishWorkout`, NY |
| S10 | Wed 07:50 | 10:50 | 14:50Z | Done "check out" | `setTaskDone`, NY |
| S11 | Wed 15:00 to 21:20 | 18:00 to 00:20 | 22:00Z to 04:20Z Thu | JFK to LAX; opens Home 21:30 PDT | nothing until open |
| S12 | Thu 29 06:30 | 09:30 | 13:30Z | Opens at home; Legs A planned | roll-forward, turnover |

## Expected lines, surface by surface

P = master (or the #356 branch where marked) gives the expected line. F = it does not. n/b = not built yet.

| # | Read at | Surface | Expected | Master, traced | P/F |
|---|---|---|---|---|---|
| R01 | Mon 18:35 PDT | Home | Hero "Push A done", context "done at 6:32 pm", detail "6 exercises, 18 sets." | `HomeLines.swift:214, 253-256`; bucket in LA (`WorkoutSummary.swift:101`) | P |
| R02 | Mon 21:45 PDT | Day log, Mon | "17:30 Push A, 62 min. Bench 82.5 × 8." / "18:40 Added 2 tasks" | `DayStory.swift:221, 266` | P |
| R03 | Mon 21:45 PDT | WeekFacts | Mon trained; trainedDays 1; Tue planned Pull A | `WeekFacts.swift:92-126` | P |
| R04 | Tue 01:20 PDT, in flight | Stored | `op.zone` "America/Los_Angeles" on S4 | `ActionEngine.swift:38, 67` | P |
| R05 | Tue 01:35 PDT | Backup | `Tessera-2026-10-26.tessera` refreshed (hour 1, before 04:00), now holds S1 to S4 | `TesseraBackup.swift:125, 148-150` | P |
| R06 | Tue 06:55 EDT | Roll-forward (04:00) | Runs once, in EDT. "call mom" (12:00 EDT) stays; invoice (Wed 01:00 EDT) is still Tue; nothing carried, no Tess line | `RollForward.swift:52-56`; `Tasks.swift:44-47, 82` | P |
| R07 | Tue 06:55 EDT | Turnover (#356) | Runs once for Tue (Mon's day was 21 h; none skipped). Writes "Mon: Push A done, 2 tasks, done expense report, note: slept two hours." | Branch `TessMemory+Turnover.swift:23-31`; in-flight items stay Mon via `DayStory.swift:118-121` | P |
| R08 | Tue 06:55 EDT | Day log, Mon | "20:30 Push A ..." / "21:40 Added 2 tasks" / "04:20 Done: expense report" / "04:30 Note: slept two hours" (times in EDT, day by stored zone) | `DayStory.swift:167, 277, 301` | P |
| R09 | Tue 06:55 EDT | Day log, Tue | Empty; S4 is not here | same | P |
| R10 | Tue 07:00 EDT | Home | Hero "Pull A", "Pull A today.", context "today"; task row "call mom", context "12 pm" | `HomeLines.swift:206, 245, 262`; `NowRanker.swift` (D01) | P |
| R11 | Tue 07:00 EDT | Tasks today | Done list does **not** hold "expense report" (Mon's, in its zone) | `Tasks.swift:45` tests `doneAt` in the EDT interval (08:00Z on): shows it as done today | F |
| R12 | Tue 07:00 EDT | WeekFacts | tasksDone Mon 1, Tue 0; trainedDays 1 (Push A Mon, 20:30 EDT) | `WeekFacts.swift:216-219`: `doneAt` in EDT, so Tue 1, Mon 0 | F |
| R13 | Tue 08:00 EDT | Plan my day | Offer from 08:00 EDT; window 07:00 to 21:00 EDT; "call mom" fixed 12:00; Pull A first free hour from 17:00 EDT; invoice (01:00 Wed) outside the window, not placed | `DayPlan.swift:208-217, 227-230`; `DayPlan+Store.swift:64, 79-81` | P |
| R14 | Tue | Quiet hours | "call mom" rings 12:00 EDT; invoice at 01:00 EDT saves, silent (23:00 to 07:00 in the zone at fire time) | No notifications on master | n/b |
| R15 | Tue 20:15 EDT | Day log, Tue | "12:05 Done: call mom" / "20:10 Note: dinner at Via Carota" | `DayStory.swift:277, 301` | P |
| R16 | Wed 05:35 EDT | Roll-forward (04:00) | Invoice (Tue in EDT) to Thu 05:00Z (Thu 01:00 EDT), `rolls` 1; "send invoice carried into today." | `RollForward.swift:61-75` (D06) | P |
| R17 | Wed 05:35 EDT | Turnover (#356) | Writes "Tue: done call mom, note: dinner at via carota." (day key Tue 00:00 EDT, 04:00Z) | Branch `:29-32` | P |
| R18 | Wed 06:00 EDT | Home, running | Hero "Pull A, row set 2", context "now" | `HomeLines.swift:215-219, 260` | P |
| R19 | Wed 06:35 EDT | Home, done | Hero "Pull A done", context "done at 6:30 am" | `WorkoutSummary.swift:101` in EDT | P |
| R20 | Wed 06:35 EDT | WeekFacts | Mon and Wed trained; trainedDays 2; Tue past, due | `WeekView.swift:50, 87-93` | P |
| R21 | Wed 07:00 EDT | Plan my day | Window 07:00 to 21:00 EDT; no workout block (trained today); invoice outside | `DayPlan+Store.swift:64` | P |
| R22 | Wed 21:30 PDT | Home | Hero "Pull A done", context "done at 3:30 am"; no second session offered | `WorkoutSummary.swift:101` reads 02:40 **PDT**, so Pull A is Tue; Home shows planned "Legs A tonight." | F |
| R23 | Wed 21:30 PDT | Day log, Wed | "02:40 Pull A, 50 min. Row 70 × 8." / "07:50 Done: check out" | `DayStory.swift:221` with `dayZone` NY | P |
| R24 | Wed 21:30 PDT | WeekFacts | Mon, Wed trained; Wed is today, done | Mon, **Tue** trained; Wed today, empty, Legs A planned (`WorkoutSummary.swift:101`) | F |
| R25 | Wed 21:30 PDT | Turnover (#356) | Wed's day is 27 h (08:00Z Wed to 11:00Z Thu). Runs at most once more and writes nothing new | Process key Wed 00:00 PDT (07:00Z) is not Wed 00:00 EDT (04:00Z): runs again. `recent.contains { $0.day == yesterday }` compares Tue 07:00Z to 04:00Z: writes a **second "Tue:" line**, new rule `recent.<epoch>` | F |
| R26 | Wed 21:30 PDT | Roll-forward | Invoice is Wed 22:00 PDT, today; nothing moves, no record | `RollForward.swift:94-104` | P |
| R27 | Wed 21:30 PDT | Plan my day | Window closed (21:30 is past 21:00 PDT); no offer; Shutdown's hour | `DayPlan.swift:217-221` | P |
| R28 | Wed 21:35 PDT | Backup | `Tessera-2026-10-28` exists (made 05:35 EDT); hour 21, not replaced; `clockBehind` false (absolute) | `TesseraBackup.swift:131-150` | P |
| R29 | Thu 06:30 PDT | Roll-forward | Invoice to Thu 22:00 PDT (05:00Z Fri), `rolls` 2 | `RollForward.swift:61-75` | P |
| R30 | Thu 06:30 PDT | Turnover (#356) | Writes "Wed: Pull A done, done check out." | Branch `:29-32`, Pull A on Wed via zone | P |
| R31 | Thu 07:00 PDT | Plan my day | Window 07:00 to 21:00 PDT; Legs A from 17:00 PDT; invoice 22:00 outside | `DayPlan.swift:208-217` | P |
| R32 | Thu 08:00 PDT | WeekFacts, Review | Mon Push A, Tue due, Wed Pull A, Thu Legs A today, Sun rest; trainedDays 2, plannedDays 6; tasksDone Mon 1, Tue 1, Wed 1 | trainedDays 2 but on Mon and **Tue**; Wed reads past; tasks Mon 0, Tue 2. `bestLines` (via DayStory) put Pull A on Wed, so the strip and its own lines disagree | F |
| R33 | Thu 08:00 PDT | Day log, Mon | "17:30 Push A ..." / "18:40 Added 2 tasks" / "01:20 Done: expense report" / "01:30 Note: slept two hours" | `DayStory.swift:118-121` | P |
| R34 | Thu 08:00 PDT | Exercise history | Row's Pull A set reads "Yesterday" | `ExerciseDigest.swift:191-197` in PDT: Tue, so "Tue 27" | F |
| R35 | Any | Export, restore | JSON ops carry "zone": NY for S5 to S10, LA for the rest; restore puts them back; a pre-v3 copy restores with NULL (device zone) | `TesseraExport.swift:140, 253`; `.tessera` is the store, column rides; tests in `OpZoneTests.swift:106-126` | P |

**Master: 35 rows, 27 P, 7 F, 1 n/b** (F: R11, R12, R22, R24, R25, R32, R34; R25 is on the #356 branch). Every stored
value is right, including every `op.zone`. All failures are **reads** that ignore `op.zone`, or day keys compared as
absolute instants across zones. Because the zone is now written, a read fix that lands after the trip still repairs
these days in place.

## Breaks

| # | Where | Rows | Proposed default | Owner | When |
|---|---|---|---|---|---|
| T1 | `Training/WorkoutSummary.swift:96-101`: workouts bucket by `startedAt` in the current zone, never the root op's zone. Everything on top inherits it: Home (`AppModel.swift:594-600`), `WeekView.swift:50`, `PlanSchedule.swift:14`, `RestDay.swift:46`, `DayPlan+Store.swift:64, 77`, Review | R22, R24, R32 (D07) | `TesseraDay.day(of: started, loggedIn: rootZone)` returning the **current-zone** midnight of that y-m-d (`zone-per-item.md`); root zone from a map built once per revision in `DerivedCache`, the same rule as `StoreDayLookup.zones` (`DayStory.swift:433-454`). Keep the zone in the cache key | Core | **Before Oct 26.** Home offers a second session Wed night and Review files Pull A under Tue: the exact zone check |
| T2 | Done tasks by day: `Tasks.swift:45` (today's done list) and `WeekFacts.swift:216-219` (`tasksDoneByDay`); `cooksByDay` `:204-208` has the same shape | R11, R12, R32 | Day of `doneAt` in the zone of the `setTaskDone` record that set it (cook: `finishCooking`); NULL falls back to current | Core | **Before Oct 26** (small, same helper as T1) |
| T3 | Turnover keys by absolute midnight: in-process guard (`TessMemory+Turnover.swift:23-24`), the recent-day check and `rule: "recent.<epoch>"` (`:29-31`) | R25 | Key days by y-m-d text ("2026-10-27") for the guard, the check and the rule, so a 27 h day runs once and a zone change never makes a second line | Core (#356) | **Before Oct 26 if #356 merges first**: it writes a durable memory line he would have to forget by hand |
| T4 | `ExerciseDigest.swift:191-197`: "Today" and "Yesterday" read the set's instant in the current zone | R34 | Same helper as T1 on the workout's root zone | Builder A | Can wait (one word, self-heals with T1's helper) |
| T5 | Notifications not built; quiet hours untested | R14 | Fire a timed task at its fixed instant (`UNTimeIntervalNotificationTrigger` or components **with** a time zone); judge quiet hours 23:00 to 07:00 in the zone at fire time. A zoneless `DateComponents` trigger would ring "call mom" at 09:00 EDT, breaking dst-travel rule 6 | whoever builds notifications | Can wait (not on the phone for the trip) |
| T6 | Times print in the current zone: Wed's page shows "02:40 Pull A", Home at home says "done at 3:30 am" | R22, R23 | Keep (decision 8:56 PM PT). Product may later print a zone-tagged time when an item's zone differs from the phone's | Product | Can wait |
| T7 | No `NSSystemTimeZoneDidChange` or `significantTimeChangeNotification` observer in App or Features | none on this trip | Foreground already refreshes; add the observer so a phone left open across the flip redraws Now | Builder B | Can wait |

**Top 3 before Oct 26:** T1 (workouts by stored zone), T2 (done tasks by stored zone), T3 (turnover by y-m-d, if #356
lands first). T1 and T2 share one helper, about 40 lines plus tests.

## Tests to add (Swift Testing, fixed zones, never `.current`)

- `TripRehearsalTests.hotelGymStaysWednesdayAtHome`: Pull A started 09:40Z with root op zone NY; `finishedWorkouts(onDay:)`
  in an LA calendar returns it for Wed 28 (T1, R22, R24).
- `inFlightDoneTaskIsMonday`: `setTaskDone` at 08:20Z, zone LA; `TaskList.today` in NY at 10:55Z leaves it out, and
  `tasksDoneByDay` in NY puts it on Mon 26 (T2, R11, R12).
- `turnoverRunsOnceOnALongWestDay`: turnover at 09:35Z Wed in NY, then at 04:30Z Thu in LA; one "Tue:" line (T3, R25).
- Keep `OpZoneTests.aTripStampsTheZoneInForce` as the write-side guard for R04.

## Open questions (default first)

1. **Does the phone keep PDT in flight?** Default yes (airplane mode, no network). One device check on the red-eye: the
   S4 records should read "America/Los_Angeles". If the phone flips mid-air, S4 lands on Tue, which is still honest.
2. **Tue on the plan.** Default: Tue reads "due" in Review, never "missed"; he may say "rest day today" on landing,
   which marks the day (decision 2:53 AM PT) and keeps Pull A for Wed.
3. **Turnover on landing east at 06:55 EDT, before 04:00 PDT would have come.** Default: run it (Mon's day was 21 h);
   nothing is lost and Mon's line is complete because in-flight items keep their zone.

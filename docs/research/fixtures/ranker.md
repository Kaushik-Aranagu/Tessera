# Ranker fixtures: 40 contexts for NowPicker.rank

For: Core engine · Date: 2026-10-15 · Research lab
Reads with: `../context-packing.md` (signals, weights, why lines, the 20 moments; none are repeated here), `../ranker-tuning.md`, `../lists-daily.md` (G3), `../../product/decisions.md` (3:37 PM PT rest-day decision), `../whats-running.md`, `../tess-voice.md`. Code: origin/master `e56c15e`.

## Names Core uses today (origin/master e56c15e)

- `NowPicker.pick(at:next:calendar:)` in `Tasks/NowPicker.swift` returns `(now: NowItem?, next: [NowItem])`. `NowItem` has `id`, `kind` (`.process`, `.task`, `.workout`), `object`, `title`, `startsAt`, `endsAt`, `nextStep`. A cook's soonest timer (`CookLog.timers()`, `Timer.label`, `endsAt`) becomes Now's line, for example "Rice, 8 min".
- `ProcessTable` (`Processes/ProcessTable.swift`): `running()`, `ledger(now:)`, `openWorkout()`, `suspendIfIdle(now:idleLimit:)` (workouts only), `tidy(now:)`, `wakeWaiting(now:)`. `Limits.ledgerRows = 3`, `leavesHome` 3 days, `putAway` 7 days, `wrapUpWorkout` 6 h.
- `ProcessSnapshot`: `state` (`ProcessState`: running, suspended, waiting, done, closed, putAway), `ownerApp`, `nextStep`, `resumePoint`, `startedAt`, `lastTouchedAt`, `checkAt`.
- `TaskList.Item`: `when`, `minutes`, `isDone`, `isCarriedOver`, `rolls`. Tasks read `startsAt`; workouts read `scheduledFor` and `endedAt`.
- `TaskList.load(at:)` gives `DayLoad` (`plannedMinutes`, `freeMinutes`, `isFull`, `couldMove`). Untimed tasks count 30 min, today's unfinished workout 60 min, free time ends at 23:00.
- Rest days: `TrainingLedger.week(containing:plan:now:sessionsPerWeek:)` returns `WeekDay` with `isRest` and `planned`. `isRest` is only true when the plan has routines.
- Shop: `StartShop`, `Groceries.listID`. List runs other than the shop (`StartListRun`) are Lists slice 5, not on master.
- Not on master: `rank`, `Pick`, `Candidate`, `Signals`, `RankWeights`, `why`, `Event`. `git grep` for `rank(`, `ranker`, `RankWeights` finds nothing. These fixtures assume context-packing slice 1 (`NowPicker.rank` with `Pick.why`) and use its names. The `override` values follow ranker-tuning's log (`running`, `eventSoon`, `reentry`) plus a new `restDay`.

## Fixture setup shared by all rows

- Week of Mon Oct 12 to Sun Oct 18, 2026. Clock pinned through `AppClock` (`-demoTime`), calendar America/Los_Angeles.
- Plan: Push A, Pull A, Legs A, `sessionsPerWeek` 3, usual slot evening (`scheduledFor` 18:30 unless the row says otherwise). Each workout @links the reusable list "Gym bag".
- Weights as in context-packing §5: soon `40 - m/3` when the start is 0 to 90 min away (m in whole minutes, integer division), due today +20, carried +10, fits the day part +15, last action in the same app under 30 min +15, place +10, habit +10, day full and untimed -10, incumbent +15. A task with no date is not on Today and is never a candidate; an untimed task is a candidate only when it is due today (+20) or carried (+10). So a carried task (+10) ranks above a timed task more than 90 min out (0).
- A timed item fits the day part its start falls in; a workout fits its usual slot; untimed tasks fit no part. Shop fits evening, Shutdown fits shutdown, Plan my day fits morning.
- No incumbent unless the row says so (first render after foreground). Last action is "none" when the newest `.user` op is 30 min old or more.
- "Rest day" means `WeekDay.isRest` is true for today. "Gym nudge" means a workout object still has `scheduledFor` today anyway.
- Why lines are plain facts, under 40 characters, no grading words (no missed, overdue, late, behind, great, should). Hysteresis and penalties never appear in a why.

## The 40 contexts

Score notes in the last column use the weights above. "Rest day" in the Now column is the quiet line from decisions.md.

| ID | Clock, day | Running | Suspended | Today's plan | Tasks (times) | Linked lists | Shop | Last action | Day full | Expected Now | Why (Tess) | Runner-up | Rule exercised |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| R01 | 07:20 Thu | none | none | Rest day; Pull A still scheduled 18:30 (gym nudge) | Renew passport (due today) | Gym bag on Pull A | 4 | none, first open | no | Rest day | Rest day. Pull A is a tap away | Renew passport (20) | `restDay` override; the workout is not a candidate on a rest day |
| R02 | 18:10 Thu | none | none | Rest day; Pull A scheduled 18:30 | none | Gym bag on Pull A (20 min out) | 5 | Opened Training, 3 min ago | no | Rest day | Rest day. Pull A is a tap away | none (Pull A would have scored 34+15+15 = 64) | Rest beats the strongest gym nudge; the G3 word is hidden with its workout |
| R03 | 10:00 Sat | none | none | Rest day | Water plants, 10 min (no date) | none | 6 | Last `.user` op Tue 21:40 (4 days away) | no | Rest day | Rest day. Legs A is a tap away | none (Water plants has no date, so it is not on Today) | `restDay` sits above `reentry`; Tess line "Good to see you. Here is today." still allowed |
| R04 | 11:30 Sun | Pull A, since 11:28 | none | Rest day | Call mum (no date) | none | 3 | StartWorkout, 2 min ago | no | Pull A | Running since 11:28 | none (Call mum has no date, so it is not on Today) | Running beats `restDay`; starting a rest-day workout is fine |
| R05 | 17:50 Wed | none | none | Rest day | Call landlord 18:00 | none | 2 | none | no | Call landlord | At 18:00 | Rest day | A timed task within 15 min beats `restDay` (decisions.md 4:01 PM PT). C2 resolved |
| R06 | 18:45 Mon | Push A, since 18:32 | none | Push A 18:30 | Call landlord 19:00 | Gym bag on Push A | 11 | LogSet, 1 min ago | no | Push A | Running since 18:32 | Call landlord 19:00 (35+15 = 50) | Running always wins; Shop offer gated off while anything runs |
| R07 | 09:20 Tue | Legs A, since 08:50 | none | Legs A 08:30 | none; event Standup 09:30 | none | 4 | LogSet, 2 min ago | no | Legs A | Running since 08:50 | Standup 09:30 | Running beats `eventSoon` (context-packing yes/no 1) |
| R08 | 21:05 Mon | Push A, since 20:15 | none | Push A 20:00 | none; Shutdown opted in, 21:00 | none | 3 | LogSet, 1 min ago | no | Push A | Running since 20:15 | Shutdown (40+15 = 55, the one ask) | Running beats an offer at its own start time |
| R09 | 17:50 Wed | Gym bag list run, since 17:48 | none | Legs A 18:30 | none | Gym bag on Legs A | 3 | Started Gym bag run, 2 min ago | no | Gym bag, "3 left" | Running since 17:48 | Legs A 18:30 (27+15 = 42) | A list run is a process and wins as running (G11; needs Lists slice 5) |
| R10 | 19:40 Fri | none | Dal cook, set aside 19:25, step 5 of 8 | none | Reply to Arjun (carried from Wed) | none | 3 | SuspendProcess (Kitchen), 15 min ago | no | Reply to Arjun | Carried from Wed | none; ledger row "Dal, step 5 of 8, 15 min ago" | Suspended processes never take Now; they sit in the ledger. FLAG C3 |
| R11 | 20:10 Fri | none | Dal cook, set aside 19:25 | none | none (Arjun done 19:55) | none | 3 | CompleteTask, 15 min ago | no | Quiet line "All quiet." | Nothing due. Dal is one row down | none; ledger row Dal | Same rule with nothing else on: Now is quiet, Dal stays a ledger row. FLAG C3 |
| R12 | 19:10 Fri | Dal cook, since 18:20, timer Rice ends 19:18 | none | none | Call mum (no date) | none | 3 | App in background 30 min | no | Dal, line "Rice, 8 min" | Running since 18:20 | none (Call mum has no date, so it is not on Today) | Cook idle rule: never suspended while a timer runs |
| R13 | 19:14 Fri | Dal cook, since 18:20, no timer, last step 18:30 | none | none | Call mum (no date) | none | 3 | App in background 30 min | no | Dal | Running since 18:20 | none (Call mum has no date, so it is not on Today) | Cook idle rule: 44 min after the last step it is still running (limit 45) |
| R14 | 18:05 Mon | none | none | none | Book physio (due today) | none | 8 | AddListItem "milk" in Groceries, 4 min ago | no | Shop offer | 8 on Groceries, your evening slot | Book physio (20) | Shop gate opens at exactly 8, evening, nothing running; offer 15+15 = 30. FLAG C8 |
| R15 | 18:05 Mon | none | none | none | Book physio (due today); Call mum (no date) | none | 7 | AddListItem "milk" in Groceries, 4 min ago | no | Book physio | Due today | none (Call mum has no date, so it is not on Today) | Shop gate closed at 7; no offer exists |
| R16 | 10:15 Sun | none | none | none | Clean bathroom (due today) | none | 12 | none | no | Clean bathroom | Due today | none (Shop waits for 17:00) | Shop gate is evening only, however long the list |
| R17 | 19:30 Tue | none | none | none | Pay water bill (due today); Call mum (no date) | none | 10 | Declined Shop offer at 18:10 | no | Pay water bill | Due today | none (Call mum has no date, so it is not on Today) | A declined offer does not come back that day |
| R18 | 18:40 Thu | none | none | none | Call bank 19:00 | none | 9 | none | no | Call bank | At 19:00, your evening slot | Shop offer (15), the one ask on Today | Offers compete on score; a near timed task beats Shop |
| R19 | 07:40 Mon | none | none | Push A 18:30 | Pay rent (due today); Dentist 11:30 | Gym bag on Push A | 4 | none, first open | no | Pay rent | Due today | Plan my day offer (15) | Morning: Plan my day scores only through its signals. FLAG C8 |
| R20 | 08:45 Tue | none | none | Pull A 07:30, not started | Reply to Arjun (carried from Mon) | Gym bag on Pull A | 4 | none | no | Pull A | Your morning slot | Reply to Arjun (10) | Start plus 60 min has passed: no soon points, still today, never "missed". FLAG C10 |
| R21 | 17:35 Mon | none | none | Push A 18:30 | Call mum (no date) | Gym bag on Push A (55 min out) | 5 | none | no | Push A, with the ink word "Gym bag" | At 18:30, your evening slot | none (Call mum has no date, so it is not on Today) | G3: linked list shows on Now within 60 min; Push A 22+15 = 37 |
| R22 | 17:29 Mon | none | none | Push A 18:30 | Call mum (no date) | Gym bag on Push A (61 min out) | 5 | none | no | Push A, no list word | At 18:30, your evening slot | none (Call mum has no date, so it is not on Today) | G3 boundary: 61 min is outside; Push A 20+15 = 35 |
| R23 | 17:45 Wed | none | none | Legs A 18:45 | Call landlord 18:00 | Gym bag on Legs A (60 min out) | 4 | none | no | Call landlord | At 18:00, your evening slot | Legs A 18:45 (35), "Gym bag" on its Today line | G3 when the linked item is not Now; landlord 35+15 = 50. FLAG C7 |
| R24 | 22:40 Thu | none | none | Pull A tomorrow 07:30 | none left (Shutdown 21:10 rolled Reply to Arjun to Fri) | none | 2 | Shutdown done, 90 min ago | no | Quiet, dimmed: "Tomorrow starts with Pull A 07:30" | Day closed. Pull A at 07:30 | none | Late night with the day closed: no candidate, quiet Now |
| R25 | 23:15 Thu | none | none | none | Reply to Arjun (carried from Tue); Shutdown not opted in | none | 2 | none | no | Reply to Arjun | Carried from Tue | none | Late part has no weight or penalty, so a carried task still takes Now. FLAG C11 |
| R26 | 16:00 Thu | none | none | Legs A 18:30 | Dentist 17:00; Clean garage (due today); Sort photos (carried) | Gym bag on Legs A | 3 | none | yes (planned 8h20, free 7h00) | Dentist | At 17:00 | Clean garage (20-10 = 10) | Day full: -10 on untimed only; Dentist 20. Tess line, the one ask: "Today is full. Move Sort photos to Later?" |
| R27 | 15:00 Fri | none | none | none | Pay rent (due today, carried from Wed); Call bank 16:20 | none | 2 | none | yes (planned 9h, free 8h) | Call bank | At 16:20, your afternoon slot | Pay rent (30-10 = 20) | Day full tips the pick to the timed item; not full, Pay rent 30 beats Call bank 29 |
| R28 | 12:30 Sun | none | none | no plan | none; no events | none | 2 | none | no | Quiet line "All quiet." | Nothing due today | none | Empty day without a plan is not a rest day (`isRest` needs routines). FLAG C12 |
| R29 | 15:00 Tue | none | none | Pull A done 07:40 | 3 tasks, all done | none | 3 | CompleteTask, 40 min ago | no | Quiet line "All quiet." | Pull A and 3 tasks done | none | Done items leave the candidate set; Later is not pulled up on a done day |
| R30 | 13:10 Thu | none | none | none | Renew passport (due, touched Oct 2); Pay water bill (due, touched Oct 9) | none | 4 | none | no | Renew passport | Due today | Pay water bill (20) | Tie at 20 goes to the stalest `lastTouched` |
| R31 | 13:10 Thu | none | none | none | Post parcel and Buy stamps (both due, both touched 08:02 in one capture) | none | 4 | none | no | Buy stamps | Due today | Post parcel (20) | Tie with the same `lastTouched`: title A to Z. FLAG C4 |
| R32 | 14:30 Thu | none | none | none | Pay rent (due, carried from Wed, touched Oct 10); Call bank 15:45 (created Oct 14) | none | 3 | none | no | Pay rent | Due today, carried from Wed | Call bank (15+15 = 30) | A timed item gets no tie advantage; 30 against 30 goes to the stalest |
| R33 | 10:00 Thu | none | none | none | Reply to Arjun (due, carried from Tue), incumbent Now; Call plumber 11:00 just captured | none | 4 | Capture in Tasks, 0 min ago | no | Reply to Arjun | Due today, carried from Tue | Call plumber (20+15+15 = 50) | Hysteresis holds: Arjun 30+15 = 45, plus incumbent 15 = 60 |
| R34 | 10:30 Thu | none | none | none | Same as R33, Arjun still incumbent | none | 4 | none (capture 30 min ago) | no | Reply to Arjun | Due today, carried from Tue | Call plumber (30+15 = 45) | Challenger exactly 15 above raw 30: incumbent holds. FLAG C5 |
| R35 | 10:40 Thu | none | none | none | Same as R33 | none | 4 | none; Home open since 10:30, no op | no | Reply to Arjun | Due today, carried from Tue | Call plumber | No event, no re-rank, though plumber would now score 49. FLAG C6 |
| R36 | 10:50 Thu | none | none | none | Same as R33 | none | 4 | none; foreground at 10:50 | no | Call plumber | At 11:00, your morning slot | Reply to Arjun (30) | Foreground re-ranks; plumber 37+15 = 52 beats 30+15 by more than the margin |
| R37 | 14:50 Thu | none | none | none | Expense report (due today); event 1:1 Priya 15:00 | none | 3 | none | no | 1:1 Priya | Starts at 15:00 | Expense report (20) | `eventSoon` override at 10 min (needs M4 slice 1 `Event`) |
| R38 | 14:44 Thu | none | none | none | Expense report (due today); event 1:1 Priya 15:00 | none | 3 | none | no | Expense report | Due today | 1:1 Priya 15:00 (takes Now at 14:45) | Event 16 min out is not an override and is not scored; 14:45 is a re-rank boundary. FLAG C9 |
| R39 | 19:20 Mon | none | none | no plan | Water plants (carried from Wed), untimed | none | 3 | Last `.user` op Wed (5 days away) | no | Water plants | Carried from Wed | none | `reentry` finds nothing that fits the evening, so it falls through to the normal rank |
| R40 | 10:05 Thu | Book physio, since 10:05 | none | none | Reply to Arjun (due, carried), was Now; Book physio (due today) | none | 4 | StartTask Book physio from a Today line, 0 min ago | no | Book physio | Running since 10:05 | Reply to Arjun (30) | His own choice wins: StartTask makes it running; RankLog records `overridden` with `chosenId` |

Row count: 40.

Coverage: planned rest day R01 to R05; running R04, R06 to R09, R12, R13, R40; suspended cook R10, R11 (cook idle rule R12, R13); shop of 8 or more R06, R14, R16 to R18; morning R19, R20, R33 to R36; evening R02, R14, R15, R17, R18, R21 to R23; late night R24, R25; linked list 60 min before R21 to R23 (and hidden on a rest day, R02); day full R26, R27; empty days R28, R29; ties R30 to R32; hysteresis R33 to R36; overrides R03, R04, R37 to R40.

## Rules the rows imply, in precedence order

1. **Running process wins.** Any kind: workout, cook, shop, list run or task. Why "Running since HH:mm". Starting something new suspends the old one. (R04, R06 to R09, R12, R13, R40)
2. **Event or timed task within 15 min** (`eventSoon`; events after M4 slice 1). Why "Starts at HH:mm" or "At HH:mm". Never beats a running process. Beats a planned rest day (decisions.md 4:01 PM PT). (R05, R07, R37)
3. **Planned rest day** (`restDay`, new). `WeekDay.isRest` for today drops today's workout from the candidates and puts the quiet "Rest day" line on Now, above every scored item. An event or timed task within 15 min still beats it (rule 2). The routine stays one tap away. (R01 to R05)
4. **Re-entry** (`reentry`, 3 or more days away): smallest item that fits the day part; if nothing fits, fall through. Below rest day. (R03, R39)
5. **Scored rank** with the context-packing weights. Soon points stop once start plus length has passed (workouts count 60 min, as in `DayLoad`). (R14 to R27)
6. **Day full**: -10 on untimed items only; the warning is the day's one ask, in the Tess line, offering `couldMove`. (R26, R27)
7. **Offers** (Shop, Plan my day, Shutdown) have no base score; they score only through their signals and are gated. Shop needs 8 or more open items on `Groceries.listID`, evening, nothing running, not declined today. Only one ask survives. The offer's why starts with its gate fact. (R14 to R19, R08)
8. **Suspended processes never take Now.** They stay in `ProcessTable.ledger`. If nothing else scores, Now is the quiet line. (R10, R11)
9. **Cook idle rule**: a running cook is not suspended while a timer runs or within 45 min of the last step. (R12, R13)
10. **Linked list (G3)**: a list @linked from a task or workout shows as an ink word when the item starts within 60 min (inclusive), on Now if the item is Now, else on its Today line. Hidden when its item is not a candidate (rest day). (R02, R21 to R23)
11. **Ties**: stalest `lastTouched`, then title A to Z. Timed items get no extra tie advantage. (R30 to R32)
12. **Hysteresis**: the incumbent keeps +15; a challenger must beat it by more than 15. Re-rank only on the events in context-packing §6; an open, idle Home never changes its pick. (R33 to R36)
13. **Quiet Now** when nothing is left: "All quiet." in the day, dimmed "Tomorrow starts with ..." once the day is closed. (R11, R24, R28, R29)

## Contradictions and silences

| # | Rows | What the sources say | What I followed |
|---|---|---|---|
| C1 | R01 to R05 | context-packing §5 has three hard overrides and ranker-tuning freezes "the three hard overrides". decisions.md (3:37 PM PT) adds a fourth: a planned rest day wins on Now. context-packing is silent on rest days except moment 17. | decisions.md. `restDay` is override 3, after `running` and `eventSoon`. Its place above `reentry` is my call (R03). |
| C2 | R05 | Read literally, "rest wins on Now" put the rest line above a timed task 10 min away. | Resolved by decisions.md 4:01 PM PT: running, then event or timed task within 15 min, then rest day. R05 now picks Call landlord. |
| C3 | R10, R11 | context-packing §5 lists "suspended processes as resumable items" among candidates, and whats-running says a woken waiting item "becomes eligible to be Now". context-packing moment 19 says "suspended items never take Now". | Moment 19, because ranker-tuning says a moment wins over any change. |
| C4 | R31 | Prose says ties go "to the stalest, then title". The sort tuple compares `$0.item.title > $1.item.title`, which puts Z before A. | A to Z, as the prose reads. The code sketch needs flipping. |
| C5 | R34 | Prose: the incumbent holds "unless a challenger beats it by 15". The code adds 15 to the incumbent, so exactly 15 makes a tie that goes to the stalest item. | The incumbent holds at exactly 15 (never flicker). |
| C6 | R33 to R36 | The brief asked for "no flip-flop within N minutes". context-packing has no time window, only the 15-point margin and event-only re-ranking. ranker-tuning's N = 20 min is the outcome window, not a hold time. | context-packing: margin plus events, no time hold. |
| C7 | R02, R21 to R23 | lists-daily G3 says the list word shows "on Now 60 min before". context-packing has no list candidate and is silent on a linked item that is not Now. | The word rides the linked item: on Now if it is Now, else on its Today line; hidden on a rest day; 60 min is inclusive. |
| C8 | R14, R18, R19 | context-packing gives offers gates but no score, and the why reasons have no slot for the gate fact. | Offers score only through signals; the gate fact ("8 on Groceries") leads the why. |
| C9 | R38 | Events are not in the §5 candidate list, though moment 1 shows them as Today lines. | Events are Today lines only, and take Now through `eventSoon`. |
| C10 | R20 | `max(0, ...)` gives a workout whose start has passed the full 40 soon points, and master keeps it in `timedItems` all day. | Soon points stop at start plus length (60 min for a workout). |
| C11 | R25 | The late part (from 22:00) carries no weight or penalty, so a carried task can be Now at 23:15, unlike moment 14's quiet line. | The math as written. A late-part rule is a question for Product. |
| C12 | R28 | Moment 17 calls an empty day "Rest day". On master `WeekDay.isRest` is only true when the plan has routines. | master: no plan means "All quiet.", not "Rest day". |

One code gap to note, not a contradiction: `TaskList.load` counts any unfinished workout with `scheduledFor` today as 60 min, so a gym nudge on a rest day (R01, R02) makes the day look fuller than it is. When `restDay` lands, `DayLoad` should skip that workout too.

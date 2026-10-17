# Evening and quiet hours: 40 evenings for Core 0y and 0ab (Product item AW)

Research, Oct 16 2026. Checked against origin/master at ba86ff4. Docs only.

Each case is one evening. It gives the setup, when Shutdown shows, what holds it, when quiet hours start and end,
and what a 7 am default time snaps to. Every instant is given in Pacific (or the trip zone) and in UTC, so a Core test
can pin it with `TimeZone(identifier: "America/Los_Angeles")` and an exact `Date`. Status on master is "pass",
"wrong" or "not built", with file:line where code exists.

This fixture links and does not repeat:
- [shutdown-evening.md](shutdown-evening.md) (SH1 to SH16): what he sees and hears on each Shutdown.
- [shutdown-flow.md](shutdown-flow.md) (S1 to S27): the hold, UNDO, the line and the check-in, step by step.
- [dst-nov-1.md](dst-nov-1.md) (DS1 to DS42): every piece of time math on the fall-back night.
- [trip-week.md](trip-week.md) (TW1 to TW21): which day each thing files under while away.
- [asks-after-close.md](asks-after-close.md) (C1 to C14): which app asks hold, expire or return.

## The rulings this encodes (docs/product/decisions.md on origin/master)

| Rule | Value | Source |
|---|---|---|
| Day boundary | 4:00 am wall clock; midnight to 3:59 am is still the day before | `TesseraDay.swift:9-26`; 12:35 PM PT Oct 16 ("Every weekday comes from the 4 am day") |
| Shutdown | 9:00 pm wall clock; the 9 to 10 pm hero is Shutdown once built | 1:06 PM PT Oct 16 |
| The close | 10:00 pm silent close if not held; written on the first open after 10 pm, no rows moved | 11:57 AM PT Oct 16 |
| Live workout | Holds Shutdown and the 10 pm close until Finish; the close runs after Finish, stamped 10:00 pm; the workout files on the day it started | 11:57 AM PT Oct 16 |
| Paused workout | Holds the same as a live one | 1:06 PM PT Oct 16 |
| Running cook | Holds Shutdown until DONE or the clock ends | 1:06 PM PT Oct 16; Core 0y "live, paused and cooking holds" |
| Cook filing | A cook belongs to the day it finished, everywhere | 1:40 PM PT Oct 16 |
| Shutdown on screen | The close waits while Shutdown is on screen and keeps his draft until 4 am | 11:57 AM PT Oct 16 |
| Quiet hours | 11:00 pm to 7:00 am wall clock; app asks hold; his own timers still ring | AQ6, CL9, CL11 (3:34 and 3:43 AM PT Oct 16) |
| Default-time snap | A task given only a day whose default time lands in 11 pm to 7 am snaps to 7 am; a time he types is kept | 1:22 PM PT Oct 16; Core 0ab |
| Tess wakes | 7 am, the end of quiet hours, not 4 am | 12:13 PM PT Oct 16 |
| Trips | The 10 pm close uses the phone's local time | 1:06 PM PT Oct 16 |

## What exists on master

- **The band.** `DayPart(hour:)` gives `.evening` 5 to 9 pm, `.shutdown` 9 to 10 pm, `.late` 10 pm to 4 am, `.early`
  4 to 7 am (`NowRanker.swift:26-40`). It reads the calendar's wall hour, so DST and the phone's zone come free.
- **The hero during a hold.** A running process (workout or cook) is Now's first pick (`NowRanker.swift:112-115`,
  `NowPicker.swift:54-68`). Only `.running` counts; a paused workout is not Now (`ProcessTable.swift:38-40`).
- **No Shutdown, no closed state, no close, no quiet-hours gate.** Nothing in `Features/` or `TesseraCore` stores a
  closed mark or checks 11 pm to 7 am. `Haptics.swift:10,129` only mentions Shutdown. No `UNUserNotificationCenter`.
- **Default times.** An untimed day defaults to 9 am (`TessGrammar.swift:643`). When that is past, a weekday or "today"
  moves to the next whole hour (`TessGrammar.swift:680-693`), which can land in quiet hours. There is no snap.
- **Tess resting.** `SoulRouter.rest` rests 11 pm to 6 am (`SoulRouter.swift:80-84`), not 7 am.
- **Cook filing.** The Day log files a cook on its start day (`DayStory.swift:240-249`). Review's band and WeekFacts
  file by `cookedAt`, the finish (`ReviewWeek.swift:60-64`, `WeekFacts.swift:206`).
- **Core board.** 0y (Shutdown engine) and 0ab (the 7 am snap) are open in ops/board/core.md; neither has landed.

## The evenings

Pacific is UTC-7 (PDT) until Nov 1 2:00 am, then UTC-8 (PST). New York is UTC-4 (EDT). Thu Oct 22 is the
reference weeknight. "Snap probe" is the 7 am a default time in that night's quiet hours should land on.

### Ordinary weeknights

| ID | Evening and setup | Shutdown shows | What holds it | Quiet hours | Snap probe | Status on master |
|---|---|---|---|---|---|---|
| EQ1 | Mon Oct 19. Push A done 6 pm, 3 tasks open, he holds CLOSE THE DAY at 9:12 pm (04:12Z Oct 20). As SH1, SH2 | 9:00 pm PDT, 04:00Z Oct 20 | Nothing | 11:00 pm (06:00Z Oct 20) to Tue 7:00 am (14:00Z Oct 20) | Tue 7:00 am, 14:00Z Oct 20 | not built: no Shutdown; the band is right (`NowRanker.swift:36-37`) |
| EQ2 | Tue Oct 20. 2 tasks open; he never touches the phone after 8 pm, first open 10:40 pm (05:40Z Oct 21). As SH8, S14 | 9:00 pm (04:00Z Oct 21), unseen | Nothing | 11:00 pm (06:00Z Oct 21) to Wed 7:00 am (14:00Z Oct 21) | Wed 7:00 am, 14:00Z Oct 21 | not built: the 10:40 pm open should write the closed mark stamped 10:00 pm (05:00Z Oct 21) and move no rows |
| EQ3 | Wed Oct 21. Shutdown on screen from 9:41 pm, he is still typing the line at 10:00 pm, leaves at 10:04 pm (05:04Z Oct 22). As S22 | 9:00 pm (04:00Z Oct 22) | Shutdown on screen, until 10:04 pm | 11:00 pm (06:00Z Oct 22) to Thu 7:00 am (14:00Z Oct 22) | Thu 7:00 am, 14:00Z Oct 22 | not built. Close runs at 10:04 pm; draft kept until Thu 4:00 am (11:00Z Oct 22); stamp is Q7 |
| EQ4 | Thu Oct 22. Band edges: 8:59:59 pm (03:59:59Z Oct 23), 9:00:00 pm (04:00Z), 9:59:59 pm (04:59:59Z), 10:00:00 pm (05:00Z) | 9:00:00 pm exactly | n/a | 11:00 pm (06:00Z Oct 23) to Fri 7:00 am (14:00Z Oct 23) | Fri 7:00 am, 14:00Z Oct 23 | pass: `.evening`, `.shutdown`, `.shutdown`, `.late` (`NowRanker.swift:35-38`) |
| EQ5 | Thu Oct 22. 2 tasks open, Pull A planned Fri. He opens Home at 9:01 pm | 9:00 pm | Nothing | as EQ4 | as EQ4 | not built: Now should read "Pull A, tomorrow, first" from 9 pm even before Shutdown (12:35 PM PT); NowRanker never passes `tomorrow:` |
| EQ6 | Thu Oct 22, closed at 9:10 pm. An Upkeep ask ("radiators") comes due at 11:05 pm (06:05Z Oct 23). As C1 | 9:00 pm | Nothing | 11:00 pm to Fri 7:00 am | Fri 7:00 am | not built: the ask must hold until Fri 7:00 am (14:00Z Oct 23); there is no gate (CL3) |

### A live workout past 10 pm

| ID | Evening and setup | Shutdown shows | What holds it | Quiet hours | Snap probe | Status on master |
|---|---|---|---|---|---|---|
| EQ7 | Tue Oct 20. Push A started 8:40 pm (03:40Z Oct 21), Finish 10:25 pm (05:25Z). As S27 | 10:25 pm, after the finish view (05:25Z Oct 21) | The live workout, 9:00 to 10:25 pm | 11:00 pm (06:00Z Oct 21) to Wed 7:00 am (14:00Z) | Wed 7:00 am, 14:00Z Oct 21 | not built. The hero stays Push A (pass, `NowRanker.swift:112-115`); it files on Tue (pass, `DayStory.swift:217-221`); the close is stamped 10:00 pm (05:00Z Oct 21) |
| EQ8 | Wed Oct 21. Legs B started 9:40 pm (04:40Z Oct 22), Finish 11:20 pm (06:20Z Oct 22), inside quiet hours | Q1: Shutdown page after Finish, or a silent close | The live workout, 9:40 to 11:20 pm | 11:00 pm (06:00Z Oct 22) to Thu 7:00 am (14:00Z) | Thu 7:00 am, 14:00Z Oct 22 | not built. Close stamped 10:00 pm (05:00Z Oct 22); workout on Wed; the check-in expires at the close (C6) |
| EQ9 | Thu Oct 22. Pull A started 9:30 pm (04:30Z Oct 23), he falls asleep and never taps Finish | Q2 | The live workout, open-ended | 11:00 pm (06:00Z Oct 23) to Fri 7:00 am (14:00Z) | Fri 7:00 am, 14:00Z Oct 23 | not built. The 6 h wrap-up (`DayStory.swift:74,230`) would end it at 3:30 am (10:30Z), before the 4:00 am boundary (11:00Z) |
| EQ10 | Fri Oct 23. Push A paused at incline 8:50 pm (03:50Z Oct 24), resumed 9:20 pm, Finish 9:45 pm (04:45Z) | 9:45 pm, after the finish view | Paused, then live, 9:00 to 9:45 pm | 11:00 pm (06:00Z Oct 24) to Sat 7:00 am (14:00Z) | Sat 7:00 am, 14:00Z Oct 24 | not built. Supersedes SH6's default (row under Shutdown). A paused workout is not Now (`ProcessTable.swift:38-40`), so the hold needs `openWorkout()` (`:43-48`) |
| EQ11 | Thu Oct 22, closed at 9:10 pm. Push A started 10:30 pm (05:30Z Oct 23), Finish 11:35 pm (06:35Z); a rest timer rings 11:12 pm | Not again: the day is closed | Nothing (started after the close) | 11:00 pm to Fri 7:00 am | Fri 7:00 am | pass: files on Thu, the start day (`DayStory.swift:217-221`). His rest timer is his and rings in quiet hours (CL9). The closed day staying closed is not built |

### A cook running at 9 pm

| ID | Evening and setup | Shutdown shows | What holds it | Quiet hours | Snap probe | Status on master |
|---|---|---|---|---|---|---|
| EQ12 | Sun Oct 25. Chili cook started 8:30 pm (03:30Z Oct 26), timer to 9:25 pm (04:25Z), DONE 9:40 pm (04:40Z). Updates SH5, S20 | 9:40 pm if "the clock" is DONE; 9:25 pm if it is the timer (Q3) | The running cook | 11:00 pm (06:00Z Oct 26) to Mon 7:00 am (14:00Z) | Mon 7:00 am, 14:00Z Oct 26 | not built. The cook takes Now (pass, `NowPicker.swift:54-68`) |
| EQ13 | Tue Oct 20. Braise started 7:45 pm (02:45Z Oct 21), no timer, DONE Wed 12:40 am (07:40Z Oct 21) | Q1 (DONE lands in quiet hours) | The running cook, 9:00 pm to 12:40 am | 11:00 pm (06:00Z Oct 21) to Wed 7:00 am (14:00Z) | Wed 7:00 am, 14:00Z Oct 21 | not built. Close stamped 10:00 pm (05:00Z Oct 21). The cook files on Tue either way: 12:40 am is still his Tuesday |
| EQ14 | Thu Oct 22, closed at 9:10 pm. Dough cook started 11:30 pm (06:30Z Oct 23), DONE Fri 4:15 am (11:15Z) | Not again | Nothing (started after the close) | 11:00 pm to Fri 7:00 am | Fri 7:00 am | **wrong**: the cook belongs to Friday, its finish day. The Day log files it Thu from the start entry (`DayStory.swift:240-249`). Review and WeekFacts say Fri (pass, `ReviewWeek.swift:60-64`, `WeekFacts.swift:206`) |
| EQ15 | Wed Oct 21. Shutdown on screen at 9:05 pm; he starts the pasta cook at 9:10 pm (04:10Z Oct 22), DONE 9:35 pm (04:35Z) | 9:00 pm, then folds back at 9:10 pm, returns 9:35 pm (Q11) | Shutdown on screen, then the cook | 11:00 pm to Thu 7:00 am | Thu 7:00 am | not built |
| EQ16 | Thu Oct 22, closed at 9:10 pm. He says "rice 12" at 11:05 pm (06:05Z Oct 23), no cook | Not again | Nothing (a kitchen timer is not a cook) | 11:00 pm to Fri 7:00 am | Fri 7:00 am | not built: it rings at 11:17 pm (06:17Z), haptic included (CL9). `StartKitchenTimer` schedules no notification (CL6, S12) |

### A trip night in another zone (TimeZone "America/New_York")

| ID | Evening and setup | Shutdown shows | What holds it | Quiet hours | Snap probe | Status on master |
|---|---|---|---|---|---|---|
| EQ17 | Mon Oct 26 in New York, phone in Eastern. 2 tasks open. As SH12, S21 | 9:00 pm EDT, 01:00Z Oct 27 (6:00 pm PDT) | Nothing | 11:00 pm EDT (03:00Z Oct 27) to Tue 7:00 am EDT (11:00Z), by the phone (Q6) | Tue 7:00 am EDT, 11:00Z Oct 27 | not built. Close at 10:00 pm EDT (02:00Z Oct 27). The band follows the phone (`NowRanker.swift:29-40` reads the calendar hour) |
| EQ18 | Tue Oct 27, 1:00 am EDT (05:00Z), his Monday. He types "call mom mon" | n/a | n/a | inside quiet hours | Tue 7:00 am EDT, 11:00Z Oct 27 | **wrong**: lands at 2:00 am EDT (06:00Z), the next whole hour (`TessGrammar.swift:680-684`) |
| EQ19 | Wed Oct 28, flies home; the phone switches to Pacific on landing at 7:30 pm PDT. As TW13 | 9:00 pm PDT, 04:00Z Oct 29 (not 9 pm EDT, which passed in the air at 01:00Z) | Nothing | 11:00 pm PDT (06:00Z Oct 29) to Thu 7:00 am PDT (14:00Z) | Thu 7:00 am PDT, 14:00Z Oct 29 | not built. His Wednesday runs 4:00 am EDT (08:00Z Oct 28) to 4:00 am PDT (11:00Z Oct 29), 27 h |

### The Nov 1 fall-back night

| ID | Evening and setup | Shutdown shows | What holds it | Quiet hours | Snap probe | Status on master |
|---|---|---|---|---|---|---|
| EQ20 | Sat Oct 31. Closed at 9:20 pm. As DS11 to DS13, SH13 | 9:00 pm PDT, 04:00Z Nov 1 | Nothing | 11:00 pm PDT (06:00Z Nov 1) to Sun 7:00 am PST (15:00Z): 9 real hours | Sun 7:00 am PST, 15:00Z Nov 1 | not built. Close 10:00 pm PDT (05:00Z); day turns at 4:00 am PST (12:00Z), the band is right (`TesseraDay.swift:22-26`) |
| EQ21 | Sun Nov 1, 1:30 am PDT (08:30Z) and again 1:30 am PST (09:30Z), his Saturday. He types "call mom sat" | n/a | n/a | inside quiet hours | Sun 7:00 am PST, 15:00Z Nov 1, both times | **wrong**: both land at 2:00 am PST (10:00Z) (`TessGrammar.swift:680-684`) |
| EQ22 | Sat Oct 31. Pull A started 9:30 pm PDT (04:30Z Nov 1), Finish 1:15 am PST (09:15Z). As DS15 | Q1 | The live workout | as EQ20 | as EQ20 | not built. Close stamped 10:00 pm PDT (05:00Z Nov 1); files on Sat (pass, `DayStory.swift:217-221`) |
| EQ23 | Sun Nov 1, the first PST evening | 9:00 pm PST, 05:00Z Nov 2 | Nothing | 11:00 pm PST (07:00Z Nov 2) to Mon 7:00 am PST (15:00Z) | Mon 7:00 am PST, 15:00Z Nov 2 | not built. Close 10:00 pm PST (06:00Z Nov 2) |

### Edges

| ID | Evening and setup | Shutdown shows | What holds it | Quiet hours | Snap probe | Status on master |
|---|---|---|---|---|---|---|
| EQ24 | Thu Oct 22. Shutdown dismissed: he leaves it at 9:05 pm (04:05Z Oct 23) for Groceries, back on Home at 9:30 pm (04:30Z) | 9:00 pm, and again at 9:30 pm: leaving is not closing | Nothing | 11:00 pm to Fri 7:00 am | Fri 7:00 am | not built. Silent close at 10:00 pm (05:00Z); CLOSE THE DAY brings Shutdown back until 4:00 am (SH8) |
| EQ25 | Thu Oct 22. He looks for a "not now" on Shutdown at 9:02 pm | 9:00 pm | Nothing | as EQ24 | as EQ24 | not built; no such control is drawn (Q4) |
| EQ26 | Thu Oct 22, 11:20 pm (06:20Z Oct 23). "Not now" on the untimed task "call the bank" | Closed | Nothing | inside | Fri 7:00 am, 14:00Z Oct 23 | **wrong** (under Q5's answer): moves to Fri 11:20 pm (06:20Z Oct 24), a time he never typed, inside quiet hours (`Tasks.swift:126-132`) |
| EQ27 | Thu Oct 22, 8:00 pm. He types "bins 11:30pm" | 9:00 pm, "Bins" a row (Q8) | Nothing | 11:00 pm to Fri 7:00 am | none: typed | pass: Thu 11:30 pm (06:30Z Oct 23), kept (`TessGrammar.swift:643-677`) |
| EQ28 | Thu Oct 22, 9:30 pm. He types "call mom fri 6am" | 9:00 pm | Nothing | as EQ27 | none: typed | pass: Fri 6:00 am (13:00Z Oct 23), kept |
| EQ29 | Thu Oct 22, 9:30 pm. "wake me fri at 5", then "call mom fri at 5" | 9:00 pm | Nothing | as EQ27 | none: typed | pass: the first is Fri 5:00 am (12:00Z Oct 23) by the am cue; the bare 5 is Fri 5:00 pm (00:00Z Oct 24) (`TessGrammar.swift:644-650`) |
| EQ30 | Fri Oct 23 at 3:59 am (10:59Z), his Thursday, and at 4:00 am (11:00Z), his Friday. He types "call mom thu" | n/a | n/a | inside | 3:59 am: Fri 7:00 am, 14:00Z Oct 23 | **wrong** at 3:59 am: lands 4:00 am (11:00Z) (`TessGrammar.swift:680-684`). Pass at 4:00 am: next Thu Oct 29 9:00 am (16:00Z Oct 29) (`TessGrammar.swift:742-746`) |
| EQ31 | Fri Oct 23, 4:00 am boundary after a Thursday closed at 9:10 pm with "pay the plumber" left at 2:00 pm Thu | n/a | n/a | still inside until 7:00 am | n/a | pass: the roll at 4:00 am (11:00Z) moves it to Fri 2:00 pm, rolls 1 (`RollForward.swift:51-77`); `.early` from 4 am (`NowRanker.swift:32`). Clearing the draft and closed mark is not built |
| EQ32 | Fri Oct 23, 6:30 am (13:30Z). He opens Home | n/a | n/a | inside until 7:00 am | n/a | **wrong**: Tess is idle from 6:00 am; she should rest until 7:00 am (12:13 PM PT) (`SoulRouter.swift:80-84`) |
| EQ33 | Thu Oct 22. "File taxes" typed 6:00 pm as "file taxes 11:30pm", still open at 9:00 pm | 9:00 pm; whether the task is a rolling row is Q8 | Nothing | 11:00 pm to Fri 7:00 am | none: typed | not built: should ring at 11:30 pm (06:30Z Oct 23) inside quiet hours, being a time he gave (Q9; `notifications.md` §4) |
| EQ34 | EQ33 undone; Fri Oct 23 4:00 am roll | n/a | n/a | n/a | none: typed | pass: Fri 11:30 pm (06:30Z Oct 24), rolls 1, `rolledFrom` 06:30Z Oct 23 (`RollForward.swift:56-77`) |
| EQ35 | Thu Oct 22, 10:30 pm (05:30Z Oct 23). He types "call mom today" | Closed or past | n/a | starts 11:00 pm | Fri 7:00 am, 14:00Z Oct 23 | **wrong** (under Q5): lands 11:00 pm (06:00Z), the next whole hour, inside quiet hours (`TessGrammar.swift:688-693`) |
| EQ36 | Thu Oct 22, 11:30 pm (06:30Z Oct 23). He types "call mom today" | Closed | n/a | inside | Fri 7:00 am, 14:00Z Oct 23 | **wrong**: the next hour is 24, so the guard skips and the task stays at Thu 9:00 am (16:00Z Oct 22), already past (`TessGrammar.swift:690-693`) |
| EQ37 | Thu Oct 22, 11:30 pm (06:30Z Oct 23). He types "call mom thu" | Closed | n/a | inside | Fri 7:00 am, 14:00Z Oct 23 | **wrong** (under Q5): jumps a week to Thu Oct 29 9:00 am (16:00Z Oct 29) (`TessGrammar.swift:682-684`) |
| EQ38 | Thu Oct 22, 10:40 pm (05:40Z), then 11:10 pm (06:10Z). He types "call mom tonight" | Closed or past | n/a | starts 11:00 pm | none (Q10) | pass under Q10's answer: 11:00 pm (06:00Z), then 11:59 pm (06:59Z), kept as "tonight" (`TessGrammar.swift:664-670`) |
| EQ39 | Fri Oct 23, 1:00 am (08:00Z), his Thursday. He types "call mom thu". The 0ab test | n/a | n/a | inside | Fri 7:00 am, 14:00Z Oct 23 | **wrong**: lands 2:00 am (09:00Z) (`TessGrammar.swift:680-684`; QA review-507 R1) |
| EQ40 | Thu Oct 22, 2:00 pm (21:00Z). He types "call mom fri" | n/a | n/a | n/a | none: 9 am is outside | pass: Fri 9:00 am (16:00Z Oct 23) (`TessGrammar.swift:643`) |

## Counts

40 evenings: 9 pass, 10 wrong, 21 not built.

- Pass: EQ4, EQ11, EQ27, EQ28, EQ29, EQ31, EQ34, EQ38, EQ40.
- Wrong: EQ14, EQ18, EQ21, EQ26, EQ30, EQ32, EQ35, EQ36, EQ37, EQ39.
- Not built: EQ1, EQ2, EQ3, EQ5, EQ6, EQ7, EQ8, EQ9, EQ10, EQ12, EQ13, EQ15, EQ16, EQ17, EQ19, EQ20, EQ22, EQ23, EQ24,
  EQ25, EQ33.

The seven grammar "wrong" rows (EQ18, EQ21, EQ30, EQ35, EQ36, EQ37, EQ39) are one fix: after `TessGrammar.find`
picks a date with `saidTime == false`, if its wall hour is 23 or under 7, move it to the next 7:00 am at or after it.
EQ36 and EQ37 also need the `next < 24` branches to fall through to that rule instead of keeping a past date or
jumping a week.

## Swift Testing names for Core

Helper for every sketch: `let la = TimeZone(identifier: "America/Los_Angeles")!`, a Gregorian calendar in that zone
(`ny` = "America/New_York" for EQ17 to EQ19), and `utc("2026-10-23T08:00:00Z")` parsing ISO 8601. Type names such as
`EveningClock` are placeholders; Core names the 0y engine.

| ID | Suite and test | Sketch |
|---|---|---|
| EQ1 | `EveningClockTests.shutdownOpensAtNinePM()` | now 04:00Z Oct 20, la: `shutdownStarts == utc(04:00Z Oct 20)`, `close == 05:00Z`, `quiet == 06:00Z...14:00Z Oct 20` |
| EQ2 | `EveningClockTests.firstOpenAfterTenWritesClosedMarkStampedTen()` | open 05:40Z Oct 21, 2 open tasks: closed mark `at == 05:00Z Oct 21`, both tasks' `startsAt` unchanged |
| EQ3 | `EveningClockTests.closeWaitsWhileShutdownOnScreen()` | on screen 04:41Z to 05:04Z Oct 22: no close at 05:00Z; close at 05:04Z; draft kept until 11:00Z Oct 22 |
| EQ4 | `DayPartTests.bandEdgesAtNineAndTen()` | la: 03:59:59Z Oct 23 `.evening`, 04:00Z `.shutdown`, 04:59:59Z `.shutdown`, 05:00Z `.late` |
| EQ5 | `NowRankerTests.nowReadsTomorrowFirstFromNinePM()` | now 04:01Z Oct 23, Pull A planned Fri: pick title "Pull A", `tomorrow == true` |
| EQ6 | `QuietHoursTests.appAskRaisedAtElevenHoldsUntilSeven()` | ask at 06:05Z Oct 23: `heldUntil == 14:00Z Oct 23` |
| EQ7 | `ShutdownHoldTests.liveWorkoutHoldsCloseUntilFinish()` | start 03:40Z, finish 05:25Z Oct 21: no close before 05:25Z; closed mark `at == 05:00Z Oct 21`; workout day key Oct 20 |
| EQ8 | `ShutdownHoldTests.finishInQuietHoursClosesStampedTen()` | finish 06:20Z Oct 22: closed mark `at == 05:00Z Oct 22`; per Q1, no Shutdown page |
| EQ9 | `ShutdownHoldTests.unfinishedWorkoutCloseRunsByFourAM()` | start 04:30Z Oct 23, no finish: closed by 11:00Z Oct 23 at the latest, stamped 05:00Z (Q2) |
| EQ10 | `ShutdownHoldTests.pausedWorkoutHoldsLikeLive()` | paused 03:50Z Oct 24, resumed 04:20Z, finish 04:45Z: Shutdown starts 04:45Z |
| EQ11 | `DayStoryTests.workoutAfterCloseFilesOnStartDay()` | start 05:30Z, end 06:35Z Oct 23: line on Oct 22; day stays closed |
| EQ12 | `ShutdownHoldTests.runningCookHoldsUntilDone()` | cook 03:30Z, timer end 04:25Z, DONE 04:40Z Oct 26: Shutdown starts 04:40Z (or 04:25Z per Q3) |
| EQ13 | `ShutdownHoldTests.cookPastMidnightStampsCloseAtTen()` | cook 02:45Z, DONE 07:40Z Oct 21: closed mark 05:00Z Oct 21; cook day Oct 20 |
| EQ14 | `DayStoryTests.cookFilesOnFinishDay()` | start 06:30Z, `cookedAt` 11:15Z Oct 23: Day log line on Oct 23, none on Oct 22 |
| EQ15 | `ShutdownHoldTests.cookStartedOverShutdownTakesHero()` | Shutdown 04:05Z, cook 04:10Z, DONE 04:35Z Oct 22: hero is cook 04:10Z to 04:35Z, Shutdown after |
| EQ16 | `KitchenTimerTests.timerRingsInQuietHours()` | "rice 12" at 06:05Z Oct 23: a notification request at 06:17Z, not held |
| EQ17 | `EveningClockTests.tripUsesPhoneZone()` | ny, now 01:00Z Oct 27: shutdown 01:00Z, close 02:00Z, quiet 03:00Z...11:00Z Oct 27 |
| EQ18 | `DefaultTimeSnapTests.tripWeekdayAtOneAMSnapsToSevenLocal()` | ny, "call mom mon" at 05:00Z Oct 27: `startsAt == 11:00Z Oct 27` |
| EQ19 | `EveningClockTests.zoneChangeMidDayUsesLandingZone()` | calendar switched to la at 02:30Z Oct 29: shutdown 04:00Z Oct 29; day interval 08:00Z Oct 28 to 11:00Z Oct 29 |
| EQ20 | `EveningClockTests.fallBackNightQuietIsNineHours()` | la, 04:00Z Nov 1: shutdown 04:00Z, close 05:00Z, quiet 06:00Z...15:00Z Nov 1, day end 12:00Z |
| EQ21 | `DefaultTimeSnapTests.fallBackBothOneThirtiesSnapToSevenPST()` | "call mom sat" at 08:30Z and at 09:30Z Nov 1: both `startsAt == 15:00Z Nov 1` |
| EQ22 | `ShutdownHoldTests.workoutAcrossFallBackStampsTenPDT()` | start 04:30Z, finish 09:15Z Nov 1: closed mark 05:00Z Nov 1; day key Oct 31 |
| EQ23 | `EveningClockTests.firstPSTEvening()` | 05:00Z Nov 2: shutdown 05:00Z, close 06:00Z, quiet 07:00Z...15:00Z Nov 2 |
| EQ24 | `EveningClockTests.leavingShutdownIsNotClosing()` | leave 04:05Z, back 04:30Z Oct 23: hero Shutdown; closed mark only at 05:00Z |
| EQ25 | `EveningClockTests.shutdownHasNoNotNow()` | per Q4: no dismiss action changes the close time (05:00Z Oct 23) |
| EQ26 | `TaskMoveTests.notNowOnUntimedTaskLateSnapsToSeven()` | untimed task, Not now at 06:20Z Oct 23: `startsAt == 14:00Z Oct 23` |
| EQ27 | `DefaultTimeSnapTests.typedElevenThirtyIsKept()` | "bins 11:30pm" at 03:00Z Oct 23: `startsAt == 06:30Z Oct 23` |
| EQ28 | `DefaultTimeSnapTests.typedSixAMIsKept()` | "call mom fri 6am" at 04:30Z Oct 23: `startsAt == 13:00Z Oct 23` |
| EQ29 | `DefaultTimeSnapTests.amCueKeepsFiveAM()` | "wake me fri at 5" at 04:30Z Oct 23: 12:00Z Oct 23; "call mom fri at 5": 00:00Z Oct 24 |
| EQ30 | `DefaultTimeSnapTests.threeFiftyNineSnapsFourAMDoesNot()` | "call mom thu" at 10:59Z Oct 23: 14:00Z Oct 23; at 11:00Z Oct 23: 16:00Z Oct 29 |
| EQ31 | `RollForwardTests.fourAMRollAfterClosedDay()` | task 21:00Z Oct 22, roll at 11:00Z Oct 23: `startsAt == 21:00Z Oct 23`, rolls 1 |
| EQ32 | `SoulRouterTests.restsUntilSeven()` (app target) | clock 13:30Z Oct 23, la: `rest == .resting`; 14:00Z: `.idle` |
| EQ33 | `NotificationPlanTests.typedTaskRingsInQuietHours()` | task at 06:30Z Oct 23: request fires 06:30Z, not held to 14:00Z (Q9) |
| EQ34 | `RollForwardTests.elevenThirtyTaskRollsToSameWallTime()` | roll at 11:00Z Oct 23: `startsAt == 06:30Z Oct 24`, `rolledFrom == 06:30Z Oct 23` |
| EQ35 | `DefaultTimeSnapTests.todayAtTenThirtySnapsToSeven()` | "call mom today" at 05:30Z Oct 23: `startsAt == 14:00Z Oct 23` |
| EQ36 | `DefaultTimeSnapTests.todayAtElevenThirtyNeverPast()` | "call mom today" at 06:30Z Oct 23: `startsAt == 14:00Z Oct 23`, and `> now` |
| EQ37 | `DefaultTimeSnapTests.weekdayAtElevenThirtyStaysThisWeek()` | "call mom thu" at 06:30Z Oct 23: `startsAt == 14:00Z Oct 23`, not 16:00Z Oct 29 |
| EQ38 | `DefaultTimeSnapTests.tonightIsNotSnapped()` | "call mom tonight" at 05:40Z: 06:00Z Oct 23; at 06:10Z: 06:59Z Oct 23 |
| EQ39 | `DefaultTimeSnapTests.callMomThuAtOneAMSnapsToSeven()` | "call mom thu" at 08:00Z Oct 23: `startsAt == 14:00Z Oct 23` |
| EQ40 | `DefaultTimeSnapTests.daytimeDefaultUnchanged()` | "call mom fri" at 21:00Z Oct 22: `startsAt == 16:00Z Oct 23` |

The 0ab test in full:

```swift
@Test func callMomThuAtOneAMSnapsToSeven() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    let now = utc("2026-10-23T08:00:00Z") // Fri 1:00 am PDT, his Thursday
    let found = TessDates.find(in: ["call", "mom", "thu"], now: now, calendar: calendar)
    #expect(found.date == utc("2026-10-23T14:00:00Z")) // Fri 7:00 am PDT
    #expect(found.saidTime == false)
}
```

## Open questions for Product

1. **A hold that ends inside quiet hours (EQ8, EQ13, EQ22).** After a Finish or DONE at or after 11 pm, does Shutdown
   show, or does the day close silently? Recommend: before 11 pm, Shutdown shows; from 11 pm, the close runs silently
   stamped 10:00 pm and CLOSE THE DAY stays until 4 am. The check-in expires at the close (C6).
2. **A hold that never ends (EQ9).** A workout left live or paused, or a cook never marked DONE: when does the close
   run? Recommend: at the hold's end, the 6 h wrap-up (`DayStory.liveFor`) or 4:00 am, whichever is first, always
   stamped 10:00 pm.
3. **"Until DONE or the clock ends" (EQ12).** Which clock: the last timer, or the recipe clock's last step? Recommend:
   the last step's end on the recipe clock; a cook with no clock holds until DONE, capped by Q2. A timer ending alone
   does not release it.
4. **"Not now" on Shutdown (EQ25).** None is drawn. Recommend: none; leaving Shutdown is the not now, it stays the 9 to
   10 pm hero, and the 10 pm close runs silently.
5. **What the 7 am snap covers (EQ26, EQ35 to EQ37).** The ruling names "a task given only a day". Recommend: it
   covers every time he did not type ("today", a weekday, and Not now on an untimed task), it lands on the next
   7:00 am at or after the default, and the receipt names the day ("Call mom, Friday at 7 am.").
6. **Quiet hours on a trip (EQ17).** Only the 10 pm close is ruled to use the phone's time. Recommend: quiet hours and
   the snap use the phone's local time too.
7. **The close stamp when it waited for Shutdown on screen (EQ3).** Recommend: 10:00 pm, the same as a workout hold, so
   every silent close reads one time.
8. **A task timed later tonight at Shutdown (EQ27, EQ33).** Is "Bins, 11:30 pm" a row moving to tomorrow? Recommend:
   no; it stays tonight above the label, and rolls at 4 am only if still open.
9. **A typed time that rings inside quiet hours (EQ33).** `notifications.md` §4 says a time he gave rings at any hour,
   but decisions.md has no line for it. Recommend: yes, it rings, like his timers (CL9).
10. **"tonight" after 10 pm (EQ38).** It defaults to 11:00 pm or 11:59 pm, inside quiet hours. Recommend: not snapped,
    since 7 am would contradict the word he said; it is kept like a typed time.
11. **A cook started while Shutdown is on screen (EQ15).** Recommend: the cook takes the hero and holds; Shutdown comes
    back at DONE with his draft intact.

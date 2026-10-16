# Habits, first use: his first week, line by line

For: Builder B (Habits page, Review's habit lines) and Core (M3 slice 2: `Habit`, `HabitCheckIn`, `HabitLedger`,
the habit grammar rows). Research lab. Date: 2026-10-16, America/Los_Angeles (Pacific).

His first week with habits, from typing "new habit read 5 a week" on Friday evening to the Habits page, Review's week
line and a paused week. Every habit line in `m3-lines.md` (H1 to H10, A1 to A15, the habit VoiceOver rows) and every
grammar default HP1 to HP7 is reached in a step; the coverage table at the end lists them in order. Lines no source
gives, and places where sources disagree, are marked **GAP n** and collected at the end with a recommendation and
an owner. Nothing here was run: master has no habit code, so every line is a hand walk against the sources.

## Source map

| Short | File | What it gives |
|---|---|---|
| H, A, V | `research/m3-lines.md` sections 4, 5, 6 | Habits page lines (H1 to H10), habit Tess lines (A1 to A15), habit VoiceOver rows (V-block, V-row, V-today, V-rule, V-count). Wins on copy |
| HP1 to HP7 | `research/fixtures/habits-grammar.md` "Proposed defaults", rows L819 to L848 | Grammar: counts, existing names, days, past forms, running process, shared names, pause/skip/delete. Confirmed by Product 7:50 PM PT |
| Sheet | `design/body-weight-and-habits.md` section 2 (same as branch `claude/project-thread-b3tu3f` `docs/design/body-weight-and-habits.md`) | Entry word "Habits" on Today, layout (196 pt apart from y 226), colours by class, pause by 0.7 s hold. Wins over `design/habits.md` |
| DH | `design/habits.md` (steer, recording `habits.mp4`) | Motion: paint drop, haptic, count roll, completion brushstroke, tapping a done day clears it |
| RM | `research/fixtures/review-m3.md` sections 2, 3, 5 | Review: week line clauses, at most 3 habit lines, paused and created-this-week rules |
| HL | `research/fixtures/habits-from-logs.md` | Logs that tick habits (workouts, cooks, "read {n} {unit}" notes), 4 AM edges |
| Dec | `product/decisions.md` | 7:34 PM (x of target, no streaks), 7:50 PM (HP1 to HP7), 7:53 PM (habits from logs, week starts Mon 04:00), 8:07 PM (Review with habits, at most 3, "Gym, paused this week") |
| R | `research/habits.md` | Data shape, never-list (no red, no streaks, no backfill, no notifications) |

Master read: `origin/master` at `68ad34c` (Merge PR #253, Oct 15 20:55). `git grep -i habit` over `*.swift` finds
nothing: no `Habit` class, no ledger, no grammar rule, no model tool, no `Features/Habits/`. What exists and is
reused:

- `TesseraCore/Sources/TesseraCore/Engine/TesseraDay.swift:10` (`startHour = 4`), `:17` (Monday first),
  `:65` (`week(containing:)`, Monday 04:00 edges), `:88` (`weekDays`).
- `TesseraCore/Sources/TesseraTess/TessGrammar.swift:59` (`parse`), `:74` and `:200` (`parseForProcess`), `:395`
  (`parseLift`), `:512` (`parseTask`); `TessGrammar+Live.swift:14` (`parseLive`); `TessGrammar+Kitchen.swift:151`
  (`skip` is an errand verb). The L-row hand traces were made on `bf28a92`; `TessGrammar.swift` and `+Live` have
  changed since (110 and 119 lines), so "master today" outcomes below are carried from those traces, not re-traced.
- `App/AppModel.swift:124` and `:204` (capture UNDO, 4 s only; no 10 s path), `:226` (`undoLastCapture`).
- `Features/Home/HomeSpatialView.swift:166` (Review's foot `HomeLinkLine(links: [.review, .notes])`), `:201` (`HomeLink`:
  groceries, recipes, pasteRecipe, notes, review; no habits), `:260` (`HomeLinkLine`). `NowPage` (Today) has no foot line.
- `Features/Home/ReviewPage.swift:34-47` (hero `headline`), `:50` (`sessionLine`), `:263-265` (header VoiceOver,
  hero plus session line only), `:374-392` (day dab labels). `TesseraCore/Sources/TesseraCore/Training/WeekView.swift:69-78`
  (`wasDue`, knows nothing of pauses).

Column key: **#** step, **He** what he does or says, **Shows** the screen or Tess (exact line, Tess in quotes),
**Src** line ID, **Master** code on `origin/master` ("missing" means no code at all).

## The walk

Setup: the demo store as on Oct 16 (Push A, Pull A, Legs A starter routines; plan 3 sessions a week; an open task
"Call mum"). Weeks: W0 Mon Oct 12 to Sun Oct 18 (the creation week), W1 Mon Oct 19 to Sun Oct 25, W2 Mon Oct 26 to
Sun Nov 1 (the paused week). Each day runs 04:00 to 04:00.

### Fri Oct 16 (W0, his first habit)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 1 | 20:55 | On Today, looks at the foot line | The word **Habits** (Body 21/600) in the foot line | Sheet section 2 entry; H1 "the Today foot word Habits still shows" | missing: `HomeLink` has no `.habits` (`HomeSpatialView.swift:201-216`); `NowPage` has no `HomeLinkLine` |
| 2 | 20:56 | Taps **Habits** | Zoom in. Back word "‹ TODAY". Hero "This week". Context "Friday, 2 days to go". One line "No habits yet." Writing placeholder "new habit read 5 a week" | H1, H2 | missing (no `Features/Habits/`) |
| 3 | 20:57 | Types "new habit read 5 a week" | Ghost row, dries in 2 s. Tess: "Read added, 5 times a week." UNDO 4 s | A1, HP1 (L819) | missing. Today the phrase reaches `parseLift` (`TessGrammar.swift:395`): a weight 5 and no reps, so nil; it goes to the model, which has no habit tool. Nothing is written |
| 4 | 20:57 | (does not tap UNDO; had he, Tess: "Read taken back.") | The block slides in: "Read" at Title 34, count "**0** of 5" on the right, seven faint dabs, today's letter F in ink, no history line | A1 undo, H3, H5, H10; **GAP 1** (creation week: H3 "0 of 5" here, RM "Read 0, new this week") | missing |
| 5 | 20:58 | VoiceOver on, swipes through the block | "Read, 0 of 5 this week". Week row "None done yet". Today's dab "Read today, not in yet", hint "Double-tap to check in." | V-block, V-row, V-today | missing |
| 6 | 21:00 | Taps Friday's dab | Paint falls 26 pt, lands wet at ×1.25, dries (460 ms); `.impact(medium, 0.8)`; count rolls to "**1** of 5". Tess: "Read, 1 of 5 this week." UNDO 4 s | A2; DH check-in motion | missing |
| 7 | 21:00 | VoiceOver on Friday's dab | "Read today, in". Week row "Friday done" | V-today, V-row | missing |
| 8 | 21:05 | Types "new habit read 5 a week" again | Nothing written. Tess: "Read is already a habit, 5 times a week." | HP2 | missing |
| 9 | 21:06 | Types "new habit read 8 a week" | Goes to the model (a target past 7 is never clamped). No line given for what the model says | HP1 (L823); **GAP 2** | today: nil to the model, nothing written |

### Sat Oct 17 (W0)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 10 | 00:40 | Types "read 20 pages" in bed | Counts for Friday (before 04:00), already in. Tess: "Read is already in for today." Nothing written | A6, HP4 ("read" from the irregular table), Dec 8:07 PM (4 AM day); **GAP 3** (A2 calls this a check-in, HL calls a "read {n} {unit}" note a log with "Note counted for Read") | `TesseraDay.swift:22-27` gives the 4 AM day; the habit path is missing |
| 11 | 09:00 | Types "new habit meditate" | Tess: "Meditate added, 3 times a week." (no count is 3) | A1, HP1 (L820) | missing |
| 12 | 09:02 | Types "meditated" | Tess: "Meditate, 1 of 3 this week." (the habit's name, not the phrase) | A3, HP4 (L833 shape) | missing; today "meditated" is a note (past verb) |
| 13 | 09:10 | Opens Habits | Context "Saturday, 1 day to go". Read block, then Meditate block "**1** of 3" | H2; **GAP 4** (Saturday's line and the page order are not written) | missing |
| 14 | 09:30 | Types "new habit train 3 a week" | Tess: "Train added, 3 times a week." A manual habit (the grammar never sets a rule) | A1, HP1 (L825 shape) | missing |
| 15 | 09:31 | On Train's block, makes it count workouts | Label under the name: "COUNTS WHEN A WORKOUT FINISHES". Dabs take the training class colour | H7, Sheet (colour by class); **GAP 5** (no control or Tess line for setting a rule) | missing |
| 16 | 09:31 | Looks at Train's dabs | Tuesday Oct 13 (Push A) and Thursday Oct 15 (Pull A) were finished before Train existed. Shown as? | **GAP 6** (R: rule counts are a query over the week, so 2 of 3; RM: days before creation draw nothing) | missing |
| 17 | 10:00 to 11:05 | Finishes Push A, 14 sets | The finish's own line, then a mark flies in from the top and lands on Saturday; count rolls. Tess: "Push A counted for Train, 1 of 3." (taking GAP 6 as "nothing before creation") | A8; DH rule motion; HL (a set must be logged) | missing; the finish exists, no habit count |
| 18 | 11:10 | Taps Saturday's rule dab on Train | Tess: "Push A, Saturday 10:00 am", then zooms to the workout | A14 (D4 time format) | missing |
| 19 | 11:10 | VoiceOver on that dab; on the block | "Saturday, Push A, 10:00 am", hint "Opens the workout." Block: "Train, 1 of 3 this week, counts when a workout finishes" | V-rule, V-block | missing |
| 20 | 12:00 | Types "new habit call mum once a week" | Tess: "Call mum added, 1 times a week." by A1's pattern | A1, HP1 (`once`); **GAP 7** (singular) | missing |
| 21 | 12:01 | Types "call mum" | Habit and open task share the name: the model decides. Nothing from habits | HP6 (L839) | today: nil, to the model |

### Sun Oct 18 (W0, last day; first look at Review)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 22 | 10:00 | Opens Habits | Context "Sunday, the last day". Four blocks: Read 1 of 5, Meditate 1 of 3, Train 1 of 3, Call mum 0 of 1 | H2, H3 | missing |
| 23 | 17:00 | Types "called mum" | One ghost row: check-in plus the task ticked. Tess: "Call mum done for the week." Under the block, a brushstroke paints behind the dabs Monday to Sunday (6 pt at 55%, 700 ms). No confetti, no `.success` | HP6 (L840), A4, DH completion; **GAP 8** (DH turns "of 1" the habit's colour; Sheet and H4 keep the count in ink) | missing; today nil |
| 24 | 20:00 | Swipes to REVIEW | Hero "All three sessions in" (Push A Tue 13, Pull A Thu 15, Push A Sat 17; plan 3 a week) | `ReviewPage.swift:34-47` | exists |
| 25 | 20:00 | Reads under the hero | Week line by RM's creation-week rule: "Train 1, new this week, Read 1, new this week, Meditate 1, new this week." | RM section 3 rule 1, section 5; **GAP 9** (unreadable when commas sit inside clauses) | missing: no week line in `ReviewPage` |
| 26 | 20:00 | Reads the habit lines | At most 3, rule habits first then creation order: Train, Read, Meditate, each a label line over a painted thread. Call mum (fourth) is not on Review; it is on the full Review and the Habits page | RM section 2, Dec 8:07 PM; **GAP 10** (label text for "new this week" and for the cap; see also GAP 11) | missing |
| 27 | 20:01 | VoiceOver on the header | "{hero}. {sessionLine}. {week line}" | RM section 3 VoiceOver | partly: `ReviewPage.swift:263-265` reads hero plus session line only |

### Mon Oct 19 (W1, a new week)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 28 | 03:50 | Types "✓ read" | Counts for Sunday, W0. Tess: "Read, 2 of 5 this week." | A2, HL (03:50 rule), Dec 8:07 PM (Mon 12:05 AM counts for Sunday) | 4 AM edge exists (`TesseraDay.swift:65`); habit path missing |
| 29 | 04:00 | (asleep) | Every count goes to 0 quietly. No summary, no notification | H9, R (week boundary) | missing |
| 30 | 07:00 | Opens Habits | Context "Monday, a new week". Each block "**0** of n", every dab faint, M in ink, no history line (W0 was a creation week, left out of history) | H2, H5, H10, RM section 5 | missing |
| 31 | 07:01 | Types "habit read" | Tess: "Read, 1 of 5 this week." | A2 | missing |
| 32 | 07:02 | Types "skip read today" | Nothing written, never a task. No Tess line given | HP7 (L846); **GAP 12** | today: a task "Skip read" tonight (L846 HABW; `skip` is an errand verb, `TessGrammar+Kitchen.swift:151`, then `parseTask` `:512`) |
| 33 | 18:00 | Starts Push A; between sets says "meditate" | A running process: the bare name is not a check-in; it goes to the workout or the model. Nothing from habits | HP5 (L836) | `TessGrammar.swift:200` (`parseForProcess`), `TessGrammar+Live.swift:14` |
| 34 | 18:20 | Says "habit meditate" | Tess: "Meditate, 1 of 3 this week." | HP5, A3 | missing |
| 35 | 18:45 | Finishes Push A, 14 sets | Tess: "Push A counted for Train, 1 of 3." | A8 | missing |

### Tue Oct 20 (W1)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 36 | 07:10 | Starts and finishes Legs A by mistake with 3 sets, taps the finish's UNDO | Tess: "Legs A taken back. Train 1 of 3." | A9 | missing (the finish UNDO exists, the habit clause does not) |
| 37 | 07:30 | Taps Tuesday's dab on Read | Tess: "Read, 2 of 5 this week." | A2 | missing |
| 38 | 07:31 | Taps Monday's dab on Read (already done) by mistake | The drop plays in reverse; Monday clears; count rolls to 1. Tess line not given | DH ("tapping a done day clears it"); **GAP 13** | missing |
| 39 | 07:31 | Taps Monday again | Tess: "Read, 2 of 5 this week." | A2 | missing |
| 40 | 12:00 | Types "new habit read 4 a week" | Tess: "Read now 4 times a week." UNDO 4 s | A12, HP2 (L824) | missing |
| 41 | 12:00 | Taps UNDO | Tess: "Read target taken back." Target back to 5 | A12 undo | capture UNDO 4 s exists (`AppModel.swift:204`) |
| 42 | 21:00 | Types "meditated yesterday" | Monday is already in (step 34): nothing written, count stays 1 of 3. Tess: "Meditate is already in for Monday." | HP3 (L833), A6b (item 109) | missing; today a note "Meditated" dated Monday |

### Wed Oct 21 (W1, late night)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 43 | 22:50 to Thu 00:40 | Pull A, 15 sets | Counts on Wednesday (`startedAt` day). Tess: "Pull A counted for Train, 2 of 3." | A8, HL | missing |
| 44 | Thu 01:10 | Types "read 25 pages" | Counts for Wednesday. Tess: "Read, 3 of 5 this week." (or HL's "Note counted for Read, 3 of 5.", GAP 3) | A2, HL, 4 AM | missing |
| 45 | Thu 01:12 | Types "ran 5k yesterday" | No habit called Run: nothing from habits; a note "Ran 5k" on Tuesday as today | A15, HP4 | note path exists |
| 46 | Thu 01:13 | Types "habit sing" | No habit Sing: falls through, never creates one | A15 (L848); **GAP 14** (A15 says "it becomes a task"; L848 expects nil) | today nil |

### Thu Oct 22 (W1)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 47 | 07:30 | Types "read" | Tess: "Read, 4 of 5 this week." | A2, HP4 | missing |
| 48 | 07:31 | Types "meditate sat" | A future day is a plan: task "Meditate" Saturday, no time. Never a check-in | HP3 (L838 shape) | task path exists (`parseTask`, `:512`; today it gets 09:00) |
| 49 | 07:32 | Types "meditated last friday" | A day before Monday: to the model, no backfill. No line given | HP3, R ("no backfill"); **GAP 2** | today a note |
| 50 | 18:00 to 19:00 | Legs A, 16 sets | Train reaches 3 of 3. Brushstroke paints Monday to Thursday behind Train's dabs. Tess: "Train done for the week." by A4, or "Legs A counted for Train, done for the week." by HL | A4, A8, DH; **GAP 15** (A4 and A8 together) | missing |
| 51 | 19:30 | Types "delete read" | Needs the word "habit": to the model | HP7 | today nil |
| 52 | 19:31 | Types "delete habit call mum" | Tess: "Call mum deleted." UNDO 10 s. Check-ins go with it; the "Call mum" task stays | A13, HP7 (L847) | missing; no 10 s capture UNDO (`AppModel.swift:204` is 4 s) |
| 53 | 19:31 | Taps UNDO within 10 s | Tess: "Call mum is back." | A13 undo (D9) | missing |
| 54 | 20:00 | Opens REVIEW | Hero "All three sessions in". Week line "Train 3 of 3, Read 4 of 5, Meditate 1 of 3." No weight clause (no weigh-ins). Habit lines Train, Read, Meditate; Call mum stays off (fourth, and 0) | `ReviewPage.swift:41`; RM sections 2 and 3; Dec 8:07 PM; **GAP 11** | hero exists; week line and habit lines missing |
| 55 | 20:01 | VoiceOver on Read's Review line | "Read, 4 of 5 this week. Monday, Tuesday, Wednesday and Thursday done." | RM section 3 | missing |
| 56 | 20:05 | Opens Habits | No history line yet on any habit (W0 left out, W1 not over) | H6, H10 | missing |

### Sat Oct 24 (W1, after the walk window, for H4 and A5)

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| 57 | 11:00 | Push A, 14 sets | Tess: "Push A counted for Train, 4 this week." Count "**4** of 3", nothing else: no "+1", no colour change | A5, H4, RM ("Gym 4 of 3") | missing |

## The paused week (W2, Mon Oct 26 to Sun Nov 1)

He travels; Read goes on hold for the week.

| # | Time | He | Shows | Src | Master |
|---|---|---|---|---|---|
| P1 | Mon 04:00 | (asleep) | Counts to 0 quietly | H9 | missing |
| P2 | Mon 07:00 | Opens Habits | Train: "Met in 1 of the last 1 weeks." by H6's pattern (W1 met, W0 out) | H6; **GAP 16** | missing |
| P3 | Mon 07:01 | Holds Read's count 0.7 s | Label "PAUSED THIS WEEK" under the name; every dab faint (14%); count reads "paused". Tess: "Read paused this week." UNDO 4 s ("Read pause taken back.") | A10, H8, H3, Sheet | missing |
| P4 | Mon 07:02 | VoiceOver on the block and the count | Block "Read, paused this week". Count actions "Resume this week" (was "Pause this week") | V-block, V-count | missing |
| P5 | Mon 07:05 | Types "pause read", then "skip read this week", then "pause read till monday" | Each is the same pause (already paused: what Tess says is not given). "till monday" ends with the week; never a task | HP7 (L843, L844); **GAP 17** | "pause read till monday" today writes a task "Pause read till" Mon Nov 2 (L844 HABW) |
| P6 | Tue 21:00 | Types "read 20 pages" in the hotel | The dab paints; the week stays paused and out of history. Tess: "Read, in for today. The week stays paused." | A7, Dec 7:53 PM | missing |
| P7 | Wed 08:00 | Holds the count again | Tess: "Read back on this week, 1 of 5." UNDO 4 s | A11 | missing |
| P8 | Wed 08:00 | Taps UNDO | Tess: "Read resume taken back." The week is paused again | A11 undo | capture UNDO exists, 4 s |
| P9 | Wed 08:05 | Types "pause read next week" | Pauses W3 (Mon Nov 2). Tess line not given | HP7; **GAP 17** | missing |
| P10 | Wed 08:06 | Types "resume read" | Resumes this week: "Read back on this week, 1 of 5." | HP7 (L845), A11 | missing |
| P11 | Wed 08:06 | Types "unpause read" | Same as "resume"; already on, so the line is not given | HP7; **GAP 17** | missing |
| P12 | Wed 08:07 | Holds the count to pause W2 again | Tess: "Read paused this week." | A10 | missing |
| P13 | Sun Nov 1 01:30 PST | (clocks fall back) | The day runs 25 h; nothing is said | HL (fall-back night) | `TesseraDay` handles the calendar day |
| P14 | Sun 20:00 | Opens REVIEW | Week line leaves Read out: "Train 2 of 3, Meditate 1 of 3." Read's line "Read, paused this week" with Tuesday's stretch of the thread painted | RM sections 3 and 5, Dec 8:07 PM | missing |
| P15 | Sun 20:00 | VoiceOver on Read's Review line | "Read, paused this week. Tuesday done." | RM section 3 | missing |
| P16 | Mon Nov 2 07:00 | Opens Habits | Read: no history line (W1 4 of 5 not met; W0 and W2 left out). Train: "Met in 1 of the last 2 weeks." | H6 | missing |

If Train (the workout-rule habit) had been the paused one, Review's training dabs drop their rings for that week
(RM section 5, R10); master's `wasDue` (`WeekView.swift:69-78`) has no pause flag, so the rings would stay.

## Coverage, in source order

| Line | Steps | | Line | Steps |
|---|---|---|---|---|
| H1 | 1, 2 | | A6, A6b | 10, 42 |
| H2 | 2, 13, 22, 30 | | A7 | P6 |
| H3 | 4, 22, P3 | | A8 | 17, 35, 43, 50 |
| H4 | 57 | | A9 | 36 |
| H5 | 4, 30 | | A10 | P3, P12 |
| H6 | 56, P2, P16 | | A11 | P7, P8, P10 |
| H7 | 15 | | A12 | 40, 41 |
| H8 | P3 | | A13 | 52, 53 |
| H9 | 29, P1 | | A14 | 18 |
| H10 | 4, 30, 56 | | A15 | 45, 46 |
| A1 | 3, 4, 11, 14, 20 | | V-block, V-row, V-today | 5, 7, 19, P4 |
| A2 | 6, 31, 37, 39, 44, 47 | | V-rule, V-count | 19, P4 |
| A3 | 12, 34 | | HP1 | 3, 9, 11, 14, 20 |
| A4 | 23, 50 | | HP2 | 8, 40 |
| A5 | 57 | | HP3 | 42, 48, 49 |
| | | | HP4 | 10, 12, 45, 47 |
| | | | HP5 | 33, 34 |
| | | | HP6 | 21, 23 |
| | | | HP7 | 32, 51, 52, P5, P9 to P11 |

Every habit line is reached. Body weight lines (B1 to B16, T1 to T16) are Builder A's and are not walked; with no
weigh-ins, Review shows no weight clause and no weight line (RM section 5).

## Gaps

| # | What | Recommendation | Owner | Status |
|---|---|---|---|---|
| 1 | Creation week, conflict: the Habits page shows "**0** of 5" (H3, H5) while Review reads "Read 0, new this week" with no target (RM section 5) | Page keeps "**n** of 5" (he just set 5; hiding it reads odd); only Review and history treat the week as new. Note it in `m3-lines.md` H3 | Research (copy), Builder B | Folded (item 109): m3-lines.md H11. Decided (Product 9:04 PM PT): the page shows "0 of 5"; only Review and history call the week new |
| 2 | No line when the model gets a habit phrase it cannot do: a target past 7 (step 9), a day before Monday (step 49). The model has no habit tool on master or in any spec | Model answers in one line, nothing written: "Habits go up to 7 a week." and "Habits count this week only." | Core (model tool), Research (lines) | Open |
| 3 | Conflict: "read 20 pages" is a check-in with "Read, 3 of 5 this week." (A2, Sheet) but HL treats "read {n} {unit}" as a note that ticks Read, "Note counted for Read, 1 of 5." | Typed alone it is a check-in (A2). Only a note made through "note: ..." or the Notes page ticks by HL's rule, and then says A2's line, not "Note counted for", so one phrase never gets two lines | Product to confirm; Research to amend HL | Folded (item 109): fixtures/habits-from-logs.md rule 8 (and m3-lines.md A2). Decided (Product 9:04 PM PT): typed alone a check-in; a note made as a note ticks with the same line |
| 4 | H2 gives Thursday's "3 days to go" only: Saturday's "1 day to go" (plural rule) is not written. Order of blocks on the Habits page is not given (Review orders rule habits first) | "Saturday, 1 day to go". Page order: creation order, same as the habit lines' manual order, rule habits not lifted | Research (copy), Design (order) | Open |
| 5 | No control, gesture or Tess line for giving a habit a rule ("counts when a workout finishes"). HP1 says the grammar never sets one; Sheet and DH only show the label | A label word under the name, "COUNTS BY HAND", that cycles on tap to "COUNTS WHEN A WORKOUT FINISHES" and "COUNTS WHEN A COOK FINISHES"; Tess: "Train now counts workouts." with 4 s UNDO "Train rule taken back." | Design, Research (line) | Open |
| 6 | Conflict: a rule habit made mid-week. R says rule counts are a query over the week (Tue and Thu would count, 2 of 3); RM says days before creation draw nothing | Count only finishes after `createdAt` in the creation week; whole weeks after that count every finish | Core (HabitLedger), Product to confirm | Decided (Product 9:04 PM PT): only finishes after createdAt count in the creation week; whole weeks after count every finish (shown in fixtures/review-m3.md R13) |
| 7 | A1 with a target of 1 gives "Call mum added, 1 times a week." A12 has the same problem ("now 1 times a week") | "once a week" for a target of 1 ("Call mum added, once a week."), digits for 2 to 7 | Research (copy) | Folded (item 109): m3-lines.md A16 |
| 8 | Conflict: DH turns "of 5" the habit's colour when the target is reached; Sheet says the number is 600 ink, H4 says no colour change past the target | Keep the count in ink; the brushstroke is the only reward mark (matches no-colour-for-state and H4) | Design | Decided (Product 9:04 PM PT): to Design, with Product's lean: the count stays in ink at rest, colour only in the moment the target is met |
| 9 | RM's creation-week clause "{Name} {n}, new this week" joined by ", " gives "Train 1, new this week, Read 1, new this week, Meditate 1, new this week." | In the creation week, one tail for all: "Train 1, Read 1, Meditate 1, all new this week." or leave habits out of the week line that week | Research (RM), Builder B | Folded (item 109): fixtures/review-m3.md R13 (section 3 rule 1) |
| 10 | Review's habit label for a new habit and the cap: RM gives "GYM · 3 OF 3" and "Gym, paused this week" but no label for "new this week"; nothing says the fourth habit is hidden | "READ · 1, NEW THIS WEEK". No line about the hidden fourth; the full Review lists all | Research (RM), Builder B | Folded (item 109): fixtures/review-m3.md R13 ("One habit, three forms") |
| 11 | Wording conflict for Review's habit line: the board's example "Read, 4 of 5 this week" (also VoiceOver in RM) vs RM's visible label "READ · 4 OF 5" vs the week line "Read 4 of 5" | Visible label "READ · 4 OF 5"; VoiceOver "Read, 4 of 5 this week."; week line "Read 4 of 5". State all three in RM so Builder B does not mix them | Research | Folded (item 109): fixtures/review-m3.md R14 ("One habit, three forms") |
| 12 | "skip read today" writes nothing (HP7) but no Tess line is given; silence after typing looks broken | Tess: "Read, nothing to skip." or say nothing and clear the field. Default: no line, the field clears (an empty day is already blank) | Product | Decided (Product 9:04 PM PT): says nothing and clears the field |
| 13 | Tapping a done day clears it (DH) but m3-lines has no line for clearing a past day | Same as A2's undo shape: "Read Monday taken back, 1 of 5." with 4 s UNDO "Read Monday is back." | Research (copy) | Folded (item 109): m3-lines.md A17 (UNDO 10 s, not 4 s: clearing deletes a check-in, so the undo rule's destructive window applies) |
| 14 | Conflict: A15 says an unknown habit name "becomes a task as usual"; L848 expects nil for "habit sing" | With the word "habit", nil (to the model); a bare unknown name ("meditated") goes on as today (note or task) | Research to amend A15 | Folded (item 109): m3-lines.md A15 (amended) |
| 15 | A rule finish that reaches the target has two sources: A4 "Train done for the week." and HL "Legs A counted for Train, done for the week." | HL's form (names the workout, then what happened), and add it to m3-lines as A8b | Research | Folded (item 109): m3-lines.md A8b (A8c adds the past-target form) |
| 16 | H6 with one eligible week gives "Met in 1 of the last 1 weeks." | Show H6 from 2 eligible weeks; with 1 eligible met week, "Met last week." | Research (copy), Core (lastWeeks) | Folded (item 109): m3-lines.md H12 (H6 amended) |
| 17 | HP7 lines not in m3-lines: "pause X" when already paused, "unpause X" when not paused, "pause X next week" | "Read is already paused this week."; "Read is already on this week."; "Read paused next week." with 4 s UNDO "Read pause taken back." | Research (copy) | Folded (item 109): m3-lines.md A18, A19, A20 |
| 18 | Code: master has no `Habit`, `HabitCheckIn`, `HabitLedger`, `PauseHabitWeek`, grammar rows, model tool, `Features/Habits/`, `HomeLink.habits`, Today foot line, Review week line, or a 10 s capture UNDO (`AppModel.swift:204` is 4 s). Three phrases write wrong tasks today (L822, L844, L846) | Core: slice 2 engine, grammar rows before `parseTask`, the skip guard with them, a 10 s UNDO for A13. Builder B: the page, the foot word, Review lines | Core, Builder B | Open |
| 19 | `wasDue` (`WeekView.swift:69-78`) has no pause flag, so a paused workout habit leaves rings on Review (RM R10) | Core adds the pause flag in slice 2 | Core | Decided (Product 9:04 PM PT): the pause flag goes to Core's M3 slice 2 |
| 20 | Superseded but still on disk: `design/habits.md` says "Read, 3 of 7.", "three days to go", 168 pt from y 208; `research/habits.md` says the week starts Monday 00:00 and shows "+1" past the target | Mark both as superseded by the Sheet, m3-lines and Dec 7:53 PM (Monday 04:00) | Design, Research | Closed (Product 9:04 PM PT): research/habits.md marked superseded. design/habits.md is Design's to mark |

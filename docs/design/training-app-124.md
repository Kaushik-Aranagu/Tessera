# Item 124: Training as a full app (structure and screens, design side)
Kaushik, Oct 22: library of workouts and their details, scenarios, metrics and analytics.
Product writes the scope and ship list; this sheet is the structure and screens only.
Stills: mockups/training-app-124.png (Library, Bench Press, Stats, Programs).

## Map (tap the title "Training" for its index, as in sheet 73)
- Today: today's routine, START. The live workout stays its own page (no rail).
- Plan: the week and the routines. Dial rail: pinned Today, knob Routine, dial muscle groups.
- Library: knob Exercises | Workouts | Programs (on its own line under the subtitle).
  - Exercises: pinned Mine (the ones he does), dial = muscle groups, section words =
    equipment (Barbell, Dumbbell, Cable, Body), rows = name + his last weight.
  - Workouts: single sessions to try (dial = Push, Pull, Legs, Full body, Short).
  - Programs: multi-week plans (dial = Strength, Muscle, Run, Short); rows = week blocks;
    "Start" puts it on the Plan from next Monday.
- Exercise page (one tap from any row): dial = History, Best, Notes, Similar. Gym visual GIF
  as it is, on this page only. Last sessions, best set, "about N kg for 1".
- Log: every session; dial = months, rows = sessions with time as "1 hr 35 min".
- Stats: pinned Best; knob Range (3 months | Year); dial = Strength (about-one-rep estimate,
  by lift), Volume (weekly sets per muscle), Habit (sessions per week, the days), Balance
  (push vs pull, upper vs lower in words). One Outfit 200 number, one line of words, at
  most one thin ink trend line; no charts with axes, no rings.

## Scenarios that set the defaults
- At the gym: Training opens on Today; a long press on any exercise opens its page.
- Bored of the routine: Library > Workouts, Short, "Try today" swaps today's routine.
- New block: Library > Programs, Start; the Plan shows "Week 1 of 12" on its subtitle.
- Am I getting stronger: Stats opens on Strength, 3 months; the words line says it plainly.
- An exercise is busy: from the live set, "Similar" on the exercise page swaps it in.

## Rules
Words "best", never "record". No muscle figure by exercise names, no 3D, no paid assets.
Body, health and calorie numbers never reach Claude. Private routines stay outlined. (Send side superseded by Kaushik's Oct 27 11:59 AM ruling, docs/product/decisions.md; the backup, log, widget and screen walls stay.)
Everything else as sheet 119 (rail) and sheet 116 (type).

## Own layouts (Kaushik, Oct 22: not every page uses the same layout; each gets the clearest form for its data)
Stills: mockups/training-own-125.png. The dial is used only where the data is places of lists.
- Stats is a single page, not a rail. Strength: one line per lift, a stroke from 3 months ago
  to now on that lift's own scale, the best as a hot outline ring, the number in Outfit at
  the right. Sets this week: tally marks, one stroke per set, grouped in fives, count beside.
  Habit: 13 weeks as stacked day marks (one mark per session), this week in the hot colour,
  a skipped week a flat hairline. One line of words under it.
- Exercise page is a single page, not a rail. Gym visual, then "the climb": sessions down
  the page, weight across (light grid at 5 kg steps), each session a dot joined by a thin
  line, the best a hot ring, the set as Outfit text on the right. Tap a dot = that session.
- Kickers are sentence case (sheet 116).

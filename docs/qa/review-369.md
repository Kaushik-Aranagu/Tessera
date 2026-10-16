# QA review: PR #369, HomeLines follow-up (Core)

Head `a5e2112e89c41a8a6996984216f120cc34624924` (core/home-lines-2, off master e9bfef0). Static review; Core reports
418 package tests green. Trial merge onto master: clean. 2 files, +234/-48: HomeLines.swift and its tests. Engine
only: no app code, catalog, migration or flags.
Checked against docs/ai/home-lines.md (caps; §2 no-repeat rule, e99dcd8/4904320), Research 116 G1-G12, Kitchen's
G8 and Design 54's widget study (`studies/widgets-home-lines.html` on the Design branch).

## Verdict: FIX FIRST (two small items)

### F1. Two different lifts share a short name
`ExerciseWords.short` drops kit words and keeps the last two words when a name has no row of its own. Incline is in
the kit set, so "Incline Dumbbell Press" (on Push A in the demo and in the catalog) becomes "Press", the same as
"Overhead Press". "Cable Row" and "Chest-Supported Row" become "Row", the same as "Barbell Row".
- Home then names the wrong lift: "Push A done. Press best." when the best was the incline.
- #363's R1 de-duplicates bests by this short name, so an incline best and an overhead best in one week count as one.

**Fix:** take "incline" out of the kit words (it names the lift, not the kit), or add table rows ("Incline Dumbbell
Press": "Incline DB", "Cable Row": "Cable row", and so on). Then add a test that no two catalog exercises share a
short name, unless they're meant to (the three pulldowns, the two lateral raises).

### F2. The rest day's widget line says "Rest day today."
The no-repeat rule (home-lines.md §2) says widgets have no day label, so the widget line keeps "Rest day." with the
weekday as its meta. Design 54's study shows "Rest day." with no meta. Here `widgetWords` joins the context "today"
as a time word, so the line is "Rest day today." (pinned by the test at HomeLinesTests.swift:101), and `widgetMeta`
is nil. That leaves each face to find the weekday itself.
**Fix:** for `.rest`, `widgetWords` is the hero alone and `widgetMeta` is `HomeLines.weekday(now:)`, or nil if Design
54 wants no meta. Then repin the test.

## Checked and fine
- **Caps.** Every new context fits the caps: "today", "tomorrow", "tonight", "done at 9:40 pm", "paused 21 min
  ago", "at the store". Digits come only from the fact (clock times, counts), so they survive.
- **Design's words.** "best" / "bests", never "record" (G3). "Push A, all sets in." (G5). "nothing to buy" stays.
  The SO FAR detail is gone until a set is in (G4). "just now" up to 2 min, and hours rounded from 60 min (G6, G11).
- **Kitchen G8.** A planned cook with no time reads "Tacos today" before 17:00 and "Tacos tonight" after. With a time
  it reads "Tacos at 7" or "Tacos at 7:30" (`shortTime`). A done cook stays on Home as "Tacos done", context
  "done at 9:40 pm", until 04:00 (G1). The builders are `fact(doneCook:)` and `cooksFinished(on:)`, which uses his
  04:00 day.
- **Paused shop** reads "paused 21 min ago", not "at the store" (G2). A cook's step detail shows only while it is
  running or paused.
- **No-repeat.** Rest and task contexts are "today" (or "tomorrow") from the lens itself, so Builder B can drop
  #366's override. `HomeLines.weekday(now:)` keeps the 04:00 day (01:00 Friday is Thursday).
- **Tomorrow facts** (Design 44): "Pull A tomorrow." and "Rest day tomorrow", context "tomorrow".
- **Widget joins.** A bare time word joins without a comma ("Push A today."), a fact joins after one ("Tacos
  tonight, 2 to buy."), and a context that repeats the hero's state drops and gives its clock to `widgetMeta`
  ("Push A done, a bench best." with "8:05 pm"). `HomeLine.quiet` is "All quiet."

## Lows
- `widgetMeta` for a running workout is "now", because `repeatsState` treats "now" as a repeat and falls back to the
  short context. The comment says meta is "a time only"; nil reads better under "Push A, bench set 4." (Design's
  study shows a rest timer there, which is the face's job).
- Design's study has "Pull A tomorrow, first." with a time meta; the lens gives "Pull A tomorrow." Design should say
  whether "first" (Research's first-of-the-week cue) belongs in the lens.
- `isTimeWord` misses "this afternoon" and "this morning", which `partWord` can return for a done workout with no
  sets. A widget would print "Push A, no sets, this afternoon". That's a rare state.

## Addendum: re-check at `b6ca3a5` (Oct 16, about 3:25 AM Pacific): PASS

The trial merge onto master 38466f1 is clean. The delta since a5e2112 is HomeLines.swift and its tests.

- **F1 closed.** `ExerciseWords.short` never drops a word now. "Dumbbell", "Barbell" and "Kettlebell" read as DB,
  BB and KB, and the catalog's presses, rows and squats have their own rows ("Incline DB press", "Cable row",
  "Chest-supported row", "DB bench"). A test asserts that no two catalog lifts share a short name, except the groups
  that are meant to (pulldowns, lateral raises, leg curls, calf raises). The incline best and the overhead best stay
  two bests in WeekFacts.
- **F2 closed.** For `.rest`, `widgetWords` is "Rest day" and `widgetMeta` is `HomeLine.weekday`, read at line time
  through the 04:00 day. On the tomorrow form the meta is nil.
- **Lows taken.** `widgetMeta` is nil while something runs, and "this afternoon" and "this morning" are now time
  words. The look ahead on a closed day says "tomorrow, first", so the widget reads "Pull A tomorrow, first." by the
  join rule, which matches Design 54's study.
- **Product 96db137.** `rest(next:now:)` returns nil when `plannedSession(on:)` finds a workout scheduled for, or
  started and unfinished on, his day. `fact(scheduled:)` gives "Push A at 7 pm" over START. That closes my #366 L3,
  where "Rest day" sat beside a Push Day A at 19:00.
- **AI 0cc7ba2.** Under a done hero the context is the clock alone ("8:05 pm"), and the widget sentence is "Push A
  done. Bench best." or "Push A done. 2 bests.". Caps hold, and the digits come from the fact.

### Merge order (not a #369 defect)
`HomeFacts.rest(next:)` now returns `HomeFact?`. #366 at 52a729b calls `HomeLines.line(for: facts.rest(next:
next), now: now)` (NowPage.swift:59) with a non-optional argument, so the two won't compile together. Builder B's
fix head for #366 should rebase onto #369, take the optional (show `fact(scheduled:)` with START when it's nil), and
drop the `context: "today"` override. Otherwise #369 waits for #366 and Core adapts the call. Nothing on master
calls `rest(next:)` today.

### For Design
Strings he'll see moved. The done workout's and done cook's context goes from "done at 7:40 pm" to "7:40 pm", a
scheduled session reads "Push A at 7 pm", and the closed day's context reads "tomorrow, first". These are the AI
thread's and Product's calls, already decided. Design may want one glance before Builder B's Home records them.

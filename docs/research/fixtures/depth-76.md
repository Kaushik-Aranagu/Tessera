# One way to show more: fixtures for sheet 76 (Research BL)

*Research, Oct 16. Sources: Design sheet 76 (`docs/design/depth.md` at 1cab06a, with the Reduce Motion fade corrected to MotionPolicy's 150 ms in Design e9efac4, `design/depth.md:50` on the shared mount), the glance rules in `every-side.md` ("Two stops", "Every glance"), the study `studies/depth.html` at 1cab06a, Product's decision 2:59 pm Oct 16 ("one way to show more") and decision 2:37 pm Oct 16 ("sides open in two stops"). Read against origin/master e1c8e1d. Every value is made up. "Today" in every row is Friday Oct 16, 2026 at 6:10 pm (`-demoTime 18:10`), so this week is Oct 12 to 18. The phone is an iPhone 17 in portrait, 402 by 874 pt.*

These rows extend Research BD2 (`fixtures/side-lines.md`). They replace its GL-15 (Review: THE MONTH, dropped by 76) and GL-7 (An exercise: YOUR SETUP, now the fourth page of one side whose glance is HISTORY's).

How to read a row: **Src** names the line each row comes from. `76 map` is the sheet's map table, `76 run` its "Collections" part, `76 pages` its "A side with pages" part, `76 built` its "What changes" table, `76 access` its "Motion and access" part, `76 core` its "For each team", `75 stops` is every-side.md's "Two stops", `75 glance` its "Every glance" table, `D2:59` and `D2:37` are Product's decisions. Word and character counts are written (words / characters).

## 0. What master has today (e1c8e1d)

| Finding | Where |
|---|---|
| **No SideHost.** No `SideHost`, `ScreenSide` or side declaration exists on master or on any remote branch (searched the history of every remote for `struct SideHost`). None of the three zones exist yet; every row in sections 2 to 4 is a test for Core 0ak's host. | n/a |
| **Review does not page by week.** `ReviewPage` computes one week, the one holding now: `ReviewWeekData.compute(model, now: AppClock.now, ...)`. There is no run of weeks, no first or last week, and no swipe. A tap on a day letter reads that day, and a tap elsewhere returns to the week. | `Features/Home/ReviewPage.swift:233`, `:314-330` |
| The week data has what THE DAYS needs per day: day keys Monday first, sessions per day, tasks done per day (nil for a day ahead or before first use), cooks per day, and the day's own line forms. A per-day count of "days with something" and a "fullest day" pick do not exist. | `Features/Home/ReviewWeek.swift:9-27`, `:29-75`, `:163-189` |
| First use (the first week of the run) is already computed: the plan's creation or the first workout, whichever is earlier. | `Features/Home/ReviewPage.swift:226-229` |
| An older Review side (`ReviewView`, M2 slice 14) still exists and is still routed from Home. It is not the page 76 changes. | `Features/Review/ReviewView.swift:10`, `Features/Home/HomeSpatialView.swift:351` |
| **The exercise page has no run.** `ExercisePage` takes only the exercise class, so it can't know the routine it was opened from or that routine's order. It is reached through `ObjectPage`. | `Features/Exercise/ExercisePage.swift:7-8`, `Features/Objects/ObjectPage.swift:16` |
| **HISTORY, REP MAXES and MUSCLES are a horizontal paging ScrollView in a window in the middle of the page.** It claims every horizontal pan inside its frame, including one that starts in the last 32 pt. 76 moves them into the side's pages; until then this window and the middle swipe collide. SETUP has no view yet. | `Features/Exercise/ExerciseViews.swift:4-21`, `:38-49`, `:61-64` (remembers the open view per exercise) |
| The HISTORY rows give each session's top set by (weight, reps) and a best flag. The flag is true only for the session that holds the all-time best e1RM set, so a rep-max best (best weight at a rep count) is not flagged. | `Features/Exercise/ExerciseDigest.swift:75-85` (flag at :83) |
| Sessions include the exercise's subclasses, newest first. | `TesseraCore/Sources/TesseraCore/Training/TrainingLedger.swift:96-109` |
| e1RM is the Set class's own formula, Epley by default (`weight * (1 + reps / 30)`), and a set counts toward it only when reps plus reps in the tank are 12 or fewer. | `Catalog/SystemCatalog.swift:357`; `TrainingLedger.swift:86`, `:182-194`, `:265-272` |
| **Sheet 76's bench numbers don't follow the formula.** 82.5 × 7 is an e1RM of 101.75 kg, so it can't be "a best" next to "about 95 kg for 1" (study REP MAXES: 1 rep "95 kg, estimated", 5 reps "87.5 kg", which is itself 102.1). The fixtures below compute with Epley; see Q1. | `studies/depth.html:87-94` at 1cab06a |
| Motion: `MotionPolicy.reducedMotionFade` is `easeOut(duration: 0.15)`, so every animation under Reduce Motion is a 150 ms crossfade. This matches Design e9efac4, not the 200 ms in 1cab06a. | `DesignSystem/MotionPolicy.swift:5-11` |
| Haptics: `.selection` exists (`DesignSystem/Haptics.swift:15`, `:49`). `.bound` ("a control reaches its bound, once per push", :35, :59) is used by the live weight reel and reps row only. 76 names no haptic for a run's end. | `Features/Workout/Instruments/WeightReel.swift:161`, `RepsRow.swift:127` |
| The system back swipe: pages that hide the back button borrow the navigation controller's pop gesture through `EdgeSwipeBack`, which allows it only when there's a page to pop to. | `Features/Backup/EdgeSwipeBack.swift:7-46`, used at `BackupView.swift:155`, `RoutineEditor.swift:92`, `RoutinesPage.swift:94`, `ClaudeSection.swift:489` |
| Row swipes the right edge must beat only inside its zone: a routine row's DROP (pan left past the arm, axis-locked to horizontal), the capture row's discard on Now (left past 80 pt), the recipe page's column swipe. | `Features/Plans/RoutinesPage.swift:328-339`, `Features/Home/NowPage.swift:457-464`, `Features/Recipes/RecipePage.swift:172` |
| The live workout's exercise lane owns x and keeps it (76 run, "Live surfaces keep theirs"). | `Features/Workout/ExerciseStrip.swift:128`, `Features/Workout/WorkoutModeView.swift:364` |

## 1. Glance fixtures (stop 1)

The glance (75 stops, D2:37): the side's label at its top, one big fact at Hero 56 with its unit at 21, at most two small facts at Body 19, and the side's word at its foot. Small facts are checked against the context cap used in BD2 (6 words, 32 characters, no stop). A zero is not a big fact: with no big fact there's no glance and the right edge opens straight to the full side (BD2 GL-E3, GL-E4). An empty small fact is left out, with no dash, blank or "none" (BD2 GL-E1).

### 1a. Review: THE DAYS

**Rules used** (76 built; the study's data, `depth.html:77-80`; picks in Q2 to Q5):
- Label THE DAYS. Big fact: the days of the shown week with anything done (a session, a task done, or a cook), as "N" *of 7 days*.
- Small 1: the fullest day, as "Weekday, N tasks" (the most tasks done; a tie goes to the earlier day). When no day has a task done, the first day with a session, as "Weekday, Routine".
- Small 2: "N to go", the days from today on with nothing yet. Only the week holding today has it; a past week leaves it out.
- The foot word is ALL DAYS (the study's word; see Q5). Tess's line, both stops: "Wednesday was your fullest day." (study, `depth.html:109`).
- The full side lists all seven days, one line each, Monday first: "Wednesday, Pull A and Row, 6 tasks". A day ahead reads "nothing yet". A line follows the copy rule: two or three named, and "and N more" from four.

| ID | Week (data) | Big fact | Small 1 | Small 2 | Src |
|---|---|---|---|---|---|
| DP1 | Oct 12 to 18 (this week). Mon Push A, 3 tasks. Tue 2 tasks. Wed Pull A and Row, 6 tasks. Thu Legs A, 1 task. Fri Push Day A, 2 tasks. Sat, Sun nothing yet | "5" *of 7 days* | "Wednesday, 6 tasks" (3 / 18) | "2 to go" (3 / 7) | 76 built (Review row); 75 glance |
| DP2 | Oct 5 to 11 (last week, the one before DP1). Mon Push A, 2 tasks. Tue 4 tasks. Wed Pull A, 1 task. Thu nothing. Fri 2 tasks. Sat Legs A. Sun nothing | "5" *of 7 days* | "Tuesday, 4 tasks" (3 / 16) | left out (a past week) | 76 run; Q3 |
| DP3 | Tie: Sep 28 to Oct 4. Mon 3 tasks, Wed 3 tasks, Fri 3 tasks, every other day nothing | "3" *of 7 days* | "Monday, 3 tasks" (3 / 15), the earlier of the tie | left out | Q4 |
| DP4 | One item: this week, only today (Fri) has anything, 1 task done | "1" *of 7 days* | "Friday, 1 task" (3 / 14), singular "task" | "2 to go" (3 / 7): today has something, so only Sat and Sun are to go | 75 glance; Q3 |
| DP4 note | Same week, but today has nothing yet either: Mon to Thu quiet, nothing today | no glance (0 is not a big fact) | | The right edge opens the full side straight away, showing seven lines; Tess's band is empty | BD2 GL-E4; 75 stops ("A side too small for two stops opens straight to the full side") |
| DP5 | Empty: a past week with nothing at all (Aug 31 to Sep 6, he was away) | no glance | | Straight to the full side: seven lines, each "nothing" for a past day. Tess's band is empty | BD2 GL-E3, GL-E4 |
| DP6 | Sessions but no tasks: Sep 21 to 27. Mon Push A, Wed Pull A, Sat Legs A, no task done all week | "3" *of 7 days* | "Monday, Push A" (3 / 14) | left out | Q4 |
| DP7 | A private item must not be named: this week, Wed has 6 tasks done, one titled "Call Dr. Lin about results", and a private note written | "5" *of 7 days* | "Wednesday, 6 tasks" (3 / 18): a count only | "2 to go" | 75 Tess 4 ("Never" a private note's words); D2:41 (a side never shows a private fact its front hides) |
| DP7 full | The full side's Wednesday line for DP7 | | | "Wednesday, Pull A and Row, 6 tasks". No task titles and no note words appear on THE DAYS at all; the private note is not counted as "something done" and is never named | Q2 |
| DP8 | "And N more": Sep 14 to 20. Wed has four sessions (Pull A, Row, Run, Stretch) and 5 tasks; the rest of the week is quiet but Sat has 2 tasks | "2" *of 7 days* | "Wednesday, 5 tasks" (3 / 18) | left out | 75 stops (copy rule) |
| DP8 full | The full side's Wednesday line for DP8 | | | "Wednesday, Pull A, Row and 2 more, 5 tasks" (9 / 42). It is a row on the full side, not a glance fact, so it may pass the context cap; it must stay on one line at the default size and wrap at accessibility sizes, never "..." | 75 stops (copy rule); 76 access (Dynamic Type) |
| DP9 | The first week (first use Wed Sep 2): Sep 2 is a Wednesday. Wed 1 task, Thu Push A, Fri 2 tasks, Sat, Sun nothing | "3" *of 7 days* | "Friday, 2 tasks" (3 / 15) | left out | `ReviewPage.swift:226`; Q3 |
| DP10 | Big fact width under Dynamic Type at AX3: DP1's week | "5" *of 7 days* at Title 44 if Hero 56 won't fit on one line | as DP1, wrapped, never shrunk below Body | as DP1 | 76 access (Dynamic Type) |
| DP11 | A cook only: Sep 7 to 13, Sun cooked chili, nothing else all week | "1" *of 7 days* | left out (no task, no session) | left out | Q2 |

### 1b. An exercise: HISTORY

**Rules used** (76 built; study `depth.html:81-94`; picks in Q1, Q6, Q7):
- Label HISTORY. The glance is the first page's (76 pages: "The glance shows the first page's big fact and two small ones"), and the foot word is ALL OF IT.
- Big fact: the last session's top set, as "82.5" *× 7* (the history row's top set, `ExerciseDigest.swift:77-80`).
- Small 1: when, as "today", a weekday within the last six days, else "Oct 9"; plus ", a best" when that session holds a best.
- Small 2: the best e1RM as "about N kg for 1", rounded to the nearest kg. Left out when no set is eligible.
- Tess's line (both stops): "About N kg for 1, estimated." (76 built), empty when small 2 is empty.
- e1RM = weight × (1 + reps / 30) (`SystemCatalog.swift:357`).

The exercise is Bench press, opened from the routine Push Day A (back word "PUSH DAY A").

| ID | Sessions (newest first) | Big fact | Small 1 | Small 2 | Src |
|---|---|---|---|---|---|
| DP12 | Today 82.5 × 7, 80 × 8. Mon 80 × 8. Oct 9 80 × 7. Oct 6 77.5 × 8 | "82.5" *× 7* | "today, a best" (3 / 13) | "about 102 kg for 1" (5 / 18), from 101.75 | 76 built (exercise row); Q1 |
| DP13 | Mon 80 × 8. Oct 9 82.5 × 7. Oct 6 77.5 × 8 (last session isn't the best) | "80" *× 8* | "Monday" (1 / 6) | "about 102 kg for 1" (5 / 18), from Oct 9's set | 75 glance (BEFORE: the last time) |
| DP14 | Older last session: Oct 9 80 × 7 only. Oct 6 77.5 × 8 | "80" *× 7* | "Oct 9, a best" (3 / 13): 98.67 beats 98.17 | "about 99 kg for 1" (5 / 17) | Q6 |
| DP15 | One item: one session ever, today 60 × 8 | "60" *× 8* | "today, the first time" (4 / 21), not "a best" | "about 76 kg for 1" (5 / 17) | Q7 |
| DP16 | Empty: never done | no glance | | The right edge opens the full side straight away; HISTORY's page shows its empty state; Tess's band is empty. REP MAXES, MUSCLES and SETUP are still reachable by their words | BD2 GL-E3; 76 pages |
| DP17 | No eligible set: Oct 9 40 × 15, 40 × 14 (over 12 reps) | "40" *× 15* | "Oct 9" (2 / 5) | left out; Tess's band empty | `TrainingLedger.swift:86`, `:271-272` |
| DP18 | RPE makes a set ineligible: today 100 × 10 @ RPE 7 (13 effective reps); Mon 85 × 6 | "100" *× 10* | "today" (1 / 5), not a best, because 100 × 10 isn't eligible | "about 102 kg for 1" (5 / 18), from 85 × 6 = 102.0 | `TrainingLedger.swift:191-194` |
| DP19 | A rep-max best that isn't an e1RM best: today 90 × 3 (99.0); best e1RM 82.5 × 7 on Oct 9 (101.75); 90 kg was never lifted for 3 before | "90" *× 3* | "today, a best" (3 / 13) per Q6's pick. Master's flag says no (`ExerciseDigest.swift:83`) | "about 102 kg for 1" (5 / 18) | Q6 |
| DP20 | Same top weight in one session: today 80 × 8, 80 × 6 | "80" *× 8* (max by weight, then reps) | "today" (1 / 5) | "about 101 kg for 1" (5 / 18), from 101.33 | `ExerciseDigest.swift:77` |
| DP21 | Two sessions on one day: 7 am 80 × 6, 6 pm 102.5 × 3 | "102.5" *× 3* (the later session) | "today, a best" (3 / 13) | "about 113 kg for 1" (5 / 18), from 112.75 | `TrainingLedger.swift:104` (newest first) |
| DP22 | A private item must not be named: today's workout has a note "left knee sore, see Dr. Lin" and the exercise's setup note "Third hole" | "82.5" *× 7* | "today, a best" | "about 102 kg for 1" | 75 Tess 4; D2:41. No note text on the glance or on HISTORY's page. SETUP may show "Third hole" on its own page only (BD2 GL-E8) |
| DP23 | A subclass: Bench press's last session is a "Paused bench press" 77.5 × 5 today; plain bench last Mon 80 × 8 | "77.5" *× 5* | "today" (1 / 5) | "about 101 kg for 1" (5 / 18) | `TrainingLedger.swift:96-104`; Q8 |
| DP24 | Bodyweight: Pull-up, today 0 × 10 (no weight) | "10" *reps* | "today" (1 / 5) | left out (no e1RM at 0 kg) | Q9 |
| DP25 | "And N more" does not apply: the glance never lists sessions. The full HISTORY page with 23 sessions shows every one, newest first, and scrolls vertically | n/a | n/a | n/a | 76 map ("Up and down: reading") |

## 2. Run ends never wrap

A run is the parent's order (76 run): Review's weeks, a routine's exercises, Plans' WEEK and MONTH, and a side's pages (76 pages). It never wraps. At either end the body rubber-bands: it follows the thumb with resistance and springs back on the house spring over 380 ms (`Theme.Motion.house`). The context line ("Oct 12 to 18") and the title don't move (76 run, "Along keeps the name"). No haptic plays at an end, along a run or between pages (Q10). `sideTurned` never plays along a run (76 access).

Review's run is first use's week to this week. There are no future weeks (Q11). Push Day A's run is Bench press, Overhead press, Incline dumbbell press, Triceps pushdown, Lateral raise.

| ID | Steps | Expected | Src |
|---|---|---|---|
| DP26 | Review, this week (Oct 12 to 18). Swipe left from x 250 by 120 pt and let go | The body moves less than the thumb, then springs back over 380 ms. Still Oct 12 to 18. No haptic. No week after this one appears, and it never wraps to the first week | 76 run ("The ends of a run rubber-band", "never wraps around"); D2:59 |
| DP27 | Review, this week. Swipe right in the middle | Oct 5 to 11 slides in 1:1, settles over 380 ms; the leaving page keeps a soft shadow on its edge. The context line reads "Oct 5 to 11"; the area name REVIEW holds still | 76 run |
| DP28 | Review, the first week (first use, Aug 31 to Sep 6). Swipe right in the middle by 150 pt | Rubber-band and spring back. Still the first week. It doesn't wrap to this week, and it doesn't leave Review (only the left edge leaves) | 76 run; 76 map (left edge) |
| DP29 | Review, the week before this one. A fast flick left with high velocity | Exactly one step, to this week, and stop. A second flick left rubber-bands (DP26). A flick never skips past an end | 76 run |
| DP30 | Review, a week where the first use is today (one-member run). Swipe left, then right | Both rubber-band. No dot row or counter appears anywhere | 76 run ("There's no dot row and no counter") |
| DP31 | Bench press from Push Day A (first of five). Swipe right in the middle | Rubber-band; still Bench press. Never wraps to Lateral raise | 76 run; 76 built (exercise row) |
| DP32 | Lateral raise (last of five). Swipe left in the middle | Rubber-band; still Lateral raise. Never wraps to Bench press | 76 run |
| DP33 | Overhead press. Swipe left | Incline dumbbell press slides in. The back word "PUSH DAY A" and the title's place hold still; the title text changes with the body | 76 run ("Along keeps the name") |
| DP34 | Bench press opened from the exercise library (no routine, no run). Swipe left in the middle | There's no run, so it goes **in**: past 60 pt it settles on the HISTORY glance (DP12's values) | 76 map (the middle, "When there's no run, it goes in") |
| DP35 | Bench press's full side on SETUP (page 4). Swipe left in the middle | Rubber-band; SETUP stays ink. Never wraps to HISTORY. The routine's run doesn't move: the next exercise waits until the front | 76 pages ("Only the nearest run moves"); study `depth.html:161` |
| DP36 | Bench press's full side on HISTORY (page 1). Swipe left three times | REP MAXES, MUSCLES, SETUP in turn, one page per swipe. Each facet word goes ink as its page lands, the rest at 40%. No haptic between pages | 76 pages |
| DP37 | Plans, MONTH (last of WEEK, MONTH). Swipe left in the middle | Rubber-band; still MONTH. Swipe right goes to WEEK. On WEEK, swipe right rubber-bands | 76 built (Plans row) |
| DP38 | Live workout, the last exercise in the lane. Swipe left | The lane's own behavior as built (`ExerciseStrip.swift:128`); SideHost's run rules don't apply to the live surface | 76 run ("Live surfaces keep theirs") |
| DP39 | Reduce Motion on. DP26 and DP32 again | No rubber band (nothing slides): the pan does nothing at the end, and nothing crossfades because nothing changes. A step that does change (DP27) is a 150 ms crossfade | 76 access, corrected to 150 ms (Design e9efac4); `MotionPolicy.swift:6`; Q12 |
| DP40 | VoiceOver on. Review, this week. Focus the body (adjustable) and swipe up | VoiceOver reads "Week of Oct 12 to 18" again and the system's end sound plays; there's no next week. Swipe down reads "Week of Oct 5 to 11" | 76 access ("the run is an adjustable element on the body") |
| DP41 | VoiceOver on. Lateral raise, adjustable body, swipe up | "Lateral raise" stays; no wrap to Bench press. Swipe down reads "Triceps pushdown" | 76 access |
| DP42 | Paging back across a time change: Review, swipe right from the week of Mar 9 to 15, 2026 | The week before reads "Mar 2 to 8" (Monday first, `WeekReview.mondayFirst`), seven days, none doubled or dropped around Sunday Mar 8 | 76 run ("weeks by week"); `ReviewPage.swift:109-110` |

## 3. The step-back swipe

Per 76 ("Swipe right always goes one step back the way you came") and D2:37 ("A swipe right goes back one stop at a time"): from the full side to the glance, from the glance to the front, from a side's second page to the first, and along a run to the one before. A step back needs a right swipe past 60 pt (Q13). `sideTurned` plays only on the move that lands back on the front, never between the glance and the full side (75 stops, motion lab). The `.selection` tick plays only on landing on the full side, so no step back ticks.

| ID | Steps | Expected | Src |
|---|---|---|---|
| DP43 | Review, front. Right edge in (a little, let go before half width) | The glance: THE DAYS, "5" *of 7 days*, "Wednesday, 6 tasks", "2 to go", ALL DAYS at its foot. The front stays at 30% on the left. `sideTurned` plays. No haptic | 75 stops; 76 built |
| DP44 | From DP43, pull further past half width (201 pt), or tap ALL DAYS | The full side, seven lines. One `.selection`. No `sideTurned` | 75 stops; 76 pages (haptics) |
| DP45 | From DP44 (full side), swipe right in the middle | Back to the glance (not to the front). No haptic, no `sideTurned` | D2:37; 76 map ("From the full side it goes to the glance") |
| DP46 | From DP45 (glance), swipe right | Back to the front, Oct 12 to 18. `sideTurned` plays toward the front | D2:37; 75 stops |
| DP47 | From DP46 (front, this week), swipe right | Along the run: Oct 5 to 11. It is not "back" out of Review | 76 map ("Along a run, it goes to the one before") |
| DP48 | Bench press full side on MUSCLES (page 3). Swipe right three times, then once more, then once more | REP MAXES, then HISTORY, then the glance, then the front (Bench press). Each swipe moves exactly one step. The fifth swipe goes along the run, and Bench press is first, so it rubber-bands (DP31) | 76 map; 76 pages; Q14 |
| DP49 | Bench press full side on MUSCLES. One long swipe right across the whole width | One step only: REP MAXES. A long swipe never skips a step | D2:37 ("one stop at a time") |
| DP50 | Bench press full side, reached by tapping the context word HISTORY on the front (not by a pan). Swipe right | The glance, then the front on the next swipe: steps go by stops, whatever way he came in | D2:37; Q15 |
| DP51 | Bench press full side on MUSCLES. Tap the word REP MAXES, then swipe right | REP MAXES lands with no haptic. The swipe right goes to HISTORY (the page before in order), not back to MUSCLES | 76 pages ("Tapping a word goes to its page"); Q14 |
| DP52 | Bench press full side on MUSCLES. Left-edge pan (start at x 10) | Lands straight on the front in one move. `sideTurned` plays. The next left-edge pan from the front leaves to Push Day A | 76 map (left edge: "From a side, it lands straight on the front"); Q16 |
| DP53 | Review glance. Swipe right by 40 pt and let go | Under the threshold: springs back to the glance over 380 ms. Nothing changes | Q13 |
| DP54 | Review glance. Tap the dimmed front on the left half | Back to the front, as DP46 | 75 stops (front "still reads"); Q17 |
| DP55 | Reduce Motion on. DP45, DP46, DP48 | Each step is a 150 ms crossfade; nothing slides. `sideTurned` doesn't play (75 motion lab: never under Reduce Motion). The `.selection` tick still plays on landing on the full side | 76 access; `MotionPolicy.swift:6` |
| DP56 | VoiceOver on. Bench press full side on MUSCLES. Two-finger scrub (escape), three times | Escape steps back one **stop**, not one page: full side to the glance, then the glance to the front, then out to Push Day A. Pages are reached by their facet words, which are buttons | 76 access ("the facet words are buttons"; "Nothing depends on an edge pan"); Q18 |
| DP57 | VoiceOver on. Review front, rotor Actions | A custom action "Show the days" opens the side (the full side; see Q18). On the side, a custom action "Show the week" returns to the front | 76 access ("The side is a custom action named by its word") |

## 4. The edge zones

From 76's map and core rows. Widths are measured in from the screen's edges on any phone. On iPhone 17 (402 pt wide) that is:

| Zone | Region (iPhone 17, portrait) | Owns | Src |
|---|---|---|---|
| Left edge | x 0 to 24, from below the top pull to above Tess's band | **Out**: back where he came from; from a side, straight to the front | 76 map |
| Middle | x 24 to 370 | **Along** when the screen declares a run, else **in** | 76 map; 76 core |
| Right edge | x 370 to 402 | **In**: a little to the glance, further to the full side | 76 map; 76 core |
| Up and down | anywhere, vertical-first pans | Reading: scrolls one page | 76 map |
| Pull down at the top | a downward pan at the top of a page | The index of areas (73), except on live pages | 76 map |
| Tess's band | 736 and below on Design's canvas, which is the bottom 116 pt; on iPhone 17 y 758 and below (Q19) | Hers, every screen | 76 map; 75 rule 4 |

A pan is judged where it **starts**. Its axis is locked when it first moves past 10 pt: horizontal when |dx| > |dy| (as `RoutinesPage.swift:331`), else vertical (Q20).

| ID | Steps | Expected | Src |
|---|---|---|---|
| DP58 | Review front. Pan left starting at x 385, y 400, by 80 pt | The glance (DP43): the right edge goes in, even though Review's middle is a run | 76 map ("It's the one way in that never changes"); D2:59 |
| DP59 | Review front. Pan left starting at x 360, y 400, by 80 pt | Along the run (the middle): rubber-band at this week (DP26). It does not open the side | 76 map; 76 core |
| DP60 | Review front. Pan left starting at x 371 (the zone's first point) and at x 369 | x 371 opens the glance; x 369 goes along | 76 core (32 pt) |
| DP61 | Review, week Oct 5 to 11. Pan right starting at x 12 | Out: leaves Review to where he came from (the system pop where there's a page to pop; on a root tab, nothing). It doesn't step along the run | 76 map (left edge "Back to where you came from") |
| DP62 | Same, pan right starting at x 30 | Along: Sep 28 to Oct 4 | 76 map |
| DP63 | Same, pan right starting at x 23 and at x 25 | x 23 is out, x 25 is along | 76 core (24 pt) |
| DP64 | Routines, a row. Pan left starting at x 385 on the row | The side opens (LAST TIMES glance). The row's DROP doesn't arm | 76 core ("The edge zones win over a row's own swipe only when the pan starts inside them"); `RoutinesPage.swift:328-339` |
| DP65 | Routines, a row. Pan left starting at x 300 on the row | The row's DROP arms as built. The side doesn't open | 76 core; 75 rule 4 (a row's own swipe stays the row's) |
| DP66 | Now, a capture row in its 2 s dry time. Pan left starting at x 385 | The side (THE DAY glance) opens; the capture isn't discarded. From x 300, the row discards as built | 76 core; `NowPage.swift:457-464` |
| DP67 | Any screen. Pan left starting at x 385, y 770 (inside Tess's band) | Tess's: the side doesn't open | 76 map (Tess's band); 75 rule 4 |
| DP68 | Review front. A pan starting at x 385, y 300 that moves mostly down | Vertical: the page scrolls (or, at the top, the index pull). The side doesn't open | 76 map ("Up and down: reading"; "Pull down at the top") |
| DP69 | Live workout. Pan left starting at x 385 | The live surface keeps its own gestures; the side stays a peek (the running order). See Q21 | 76 run ("Live surfaces keep theirs"); 75 rule 7 |
| DP70 | Bench press (until Builder A moves the views). Pan left starting at x 385 inside the HISTORY / REP MAXES window | Expected after 76: the glance opens. On master today the window's paging ScrollView takes it and shows REP MAXES. This row fails until the window is gone | `ExerciseViews.swift:38-49`; 76 built |
| DP71 | Bench press glance open. Pan left starting at x 200 | To the full side (the glance holds no pages; the run waits) | 76 pages ("The run outside waits"); Q14 |
| DP72 | System back swipe: Bench press pushed from Push Day A. Pan right starting at x 2 | The system's interactive pop runs (the same as the left-edge zone's out). The two must be one gesture, not two competing ones: one pop, not a pop plus a run step | 76 map; `EdgeSwipeBack.swift:43-45`; Q22 |
| DP73 | System content back swipe (iOS 26 and later lets a right swipe anywhere in the content pop the page). Bench press from Push Day A. Pan right starting at x 200 | Along the run, to the exercise before (or the rubber band on the first). The page doesn't pop. SideHost must turn off or outrank the content pop on any screen that declares a run, and on a side | 76 map; Q22 |
| DP74 | Same as DP73 on a screen with no run (a note). Pan right starting at x 200 on the front | Nothing happens (there's no step back on a front with no run). It doesn't pop; only the left edge leaves | 76 map; Q23 |
| DP75 | Dynamic Type at AX5. DP58 and DP61 | Zone widths stay 24 and 32 pt; they don't scale with type | Q24 |
| DP76 | Reduce Motion on. DP58 | The glance appears as a 150 ms crossfade, no slide, no `sideTurned`. A pan past half width crossfades to the full side and plays `.selection` | 76 access; 75 stops; `MotionPolicy.swift:6` |
| DP77 | VoiceOver on, every screen in DP58 to DP74 | No zone is needed. The side is the custom action named by its word; a run is the adjustable body; the facet words are buttons; the side word in the context line is a button too. Every row above has a VoiceOver path that doesn't use a pan | 76 access ("Nothing depends on an edge pan") |
| DP78 | Voice Control or Switch Control. "Tap The days" | The word works as a button and opens the side | 75 rule 4 ("The word always works") |
| DP79 | A screen declares a side with five pages (a test double), and Bench press declares four | The four-page side builds; the five-page declaration fails SideHost's registry test. Four facet words fit one row at the default size and wrap to a second row (never shrink) at AX3 | 76 pages ("up to four pages"; Dynamic Type); D2:59 ("A side has up to four pages"); 76 core |

## 5. Row count

| Section | Rows |
|---|---|
| 1a. Glance, THE DAYS | 11 (DP1 to DP11; DP4 note, DP7 full and DP8 full are sub-rows) |
| 1b. Glance, HISTORY | 14 (DP12 to DP25) |
| 2. Run ends | 17 (DP26 to DP42) |
| 3. Step back | 15 (DP43 to DP57) |
| 4. Edge zones | 22 (DP58 to DP79) |
| **Total** | **79** |

## 6. Open questions (with Research's pick)

- **Q1. The bench numbers.** Sheet 76's glance ("82.5 × 7", "today, a best", "about 95 kg for 1") and the study's REP MAXES (95 kg for 1, 87.5 kg for 5) don't fit the Set class's formula: 82.5 × 7 is 101.75. *Pick:* the fixtures compute with the formula (`SystemCatalog.swift:357`), so DP12 reads "about 102 kg for 1". Design to swap the mock's numbers or confirm.
- **Q2. What counts as a day "with something".** *Pick:* a session, a task done, or a cook. A note doesn't count (a private note would then show up as a counted day with nothing nameable). The study's data agrees (Sat and Sun "nothing yet").
- **Q3. "To go" and past weeks.** *Pick:* "N to go" is the days from today on with nothing yet, shown only for the week that holds today; a past week leaves small 2 out. Days before first use are neither done nor to go, and the big fact stays "of 7 days".
- **Q4. The fullest day.** *Pick:* most tasks done, the earlier day on a tie; with no tasks all week, the first day with a session, named by routine (DP6). Tess's line names it ("Wednesday was your fullest day.").
- **Q5. THE DAYS's foot word.** 76 says ALL OF IT for a side with pages; THE DAYS has one page and the study says ALL DAYS. *Pick:* ALL DAYS.
- **Q6. What "a best" means on the glance.** Master flags only the session holding the all-time best e1RM (`ExerciseDigest.swift:83`). *Pick:* any best, e1RM or best weight at a rep count, so DP19 reads "today, a best". It needs a small change in the digest.
- **Q7. The first session.** *Pick:* "today, the first time", never "a best" (there's nothing to beat).
- **Q8. Subclasses in HISTORY.** The ledger folds in subclasses (Paused bench press into Bench press). *Pick:* keep it, as the page does today. Design to confirm the glance's top set may come from a subclass.
- **Q9. Bodyweight sets.** *Pick:* "10" *reps* as the big fact and no e1RM, not "0 × 10".
- **Q10. A haptic at a run's end.** 76 names none; `.bound` exists for a control's bound. *Pick:* none. The rubber band is the signal, as the facet word is between pages.
- **Q11. Future weeks.** *Pick:* this week is Review's last; no week ahead is in the run.
- **Q12. A run's end under Reduce Motion.** *Pick:* nothing moves and nothing fades, since there's nothing to show.
- **Q13. The step-back threshold.** 76 doesn't give one. *Pick:* 60 pt or a flick, the same as the way in (75 stops).
- **Q14. A swipe right on a side's first page.** 76 says the side's pages rubber-band "at the ends", and also that a swipe right goes from the full side to the glance. *Pick:* on page 1, a swipe right steps back to the glance (the step-back rule); only the last page rubber-bands. A step back after tapping a facet word goes to the page before in order, not to the page he was on.
- **Q15. Steps back after arriving by a tap.** *Pick:* by stops (full, glance, front), whatever way he came in. "The way you came" means the stops, not his history.
- **Q16. The left edge from a side.** The map says it lands on the front; the step-back paragraph says "the left edge skips all of that and leaves", and 75 stops says it's "back to the page before". *Pick:* the map: from a side, front; from a front, leave.
- **Q17. Tapping the dimmed front.** Not in 76. *Pick:* it returns to the front.
- **Q18. VoiceOver escape and the custom action's stop.** *Pick:* escape steps back one stop at a time (as the swipe); "Show the days" opens the full side, since the glance's facts are all on page 1.
- **Q19. Tess's band on iPhone 17.** 736 is on Design's 393 by 852 canvas, 116 pt from the bottom. *Pick:* measure from the bottom (y 758 on 874).
- **Q20. Axis lock.** *Pick:* the axis with more movement after 10 pt.
- **Q21. The right edge on the live workout.** "The one way in that never changes" versus "live surfaces keep theirs". *Pick:* the right edge opens the same running-order peek as the pull.
- **Q22. The system pop gestures.** The left 24 pt and the system's edge pop must be one gesture. The content pop (iOS 26 and later, `interactiveContentPopGestureRecognizer`; verify with DocumentationSearch) would steal the middle's step back. *Pick:* SideHost owns the left zone through the system pop (as `EdgeSwipeBack`) and disables the content pop wherever it hosts a screen.
- **Q23. A right swipe on a front with no run.** *Pick:* nothing. Only the left edge leaves.
- **Q24. Zones and Dynamic Type.** *Pick:* fixed points, not scaled.

## 7. Swift Testing names (proposed)

- `daysGlanceCountsDaysWithSomethingDone` (DP1, DP2, DP11)
- `daysGlanceFullestDayTieGoesEarlier` (DP3, DP6)
- `daysGlanceToGoOnlyForThisWeek` (DP2, DP4)
- `daysGlanceWithoutBigFactOpensFullSide` (DP4 note, DP5)
- `daysSideNeverNamesATaskOrNote` (DP7)
- `historyGlanceUsesLastTopSetAndBestE1RM` (DP12 to DP14, DP20, DP21)
- `historyGlanceFirstTimeIsNotABest` (DP15)
- `historyGlanceLeavesOutIneligibleE1RM` (DP17, DP18, DP24)
- `runEndRubberBandsAndNeverWraps` (DP26, DP28, DP31, DP32, DP35, DP37)
- `stepBackGoesOneStopAtATime` (DP45 to DP49)
- `edgeZonesJudgeByStartPoint` (DP60, DP63)
- `rightEdgeBeatsRowSwipeOnlyInsideZone` (DP64 to DP66)

## Rulings (Design, depth.md ee1b0d6, "Research BL calls")

All 24 picks stand. Design folded in Q1, Q2 to Q7, Q10, Q12, Q16 and Q22:
- **Q1:** bench numbers come from Epley: "about 102 kg for 1" on the glance and in Tess's line. REP MAXES shows the best logged weight per rep count. A count with no logged set is estimated from that, rounded to 2.5 kg and marked "estimated": 1 rep 102 kg, 3 reps 92.5 kg, 5 reps 87.5 kg; 8 reps 80 kg is logged.
- **Q16:** the left edge follows the map table: from a side it goes to the front, and from a front it leaves.
- **Q22:** SideHost turns off the full-content back swipe and keeps the system's edge back swipe. Core checks the API name.
- **Q2 to Q5:** THE DAYS as written. **Q6, Q7:** any best counts (needs the ExerciseDigest change), and a first session reads "the first time". **Q10, Q12:** no haptic at a run's end, and nothing moves or fades there under Reduce Motion.
- The master gaps (the exercise window's pans, Review's single week) are known until Builder A 0p and Builder B 0y land.

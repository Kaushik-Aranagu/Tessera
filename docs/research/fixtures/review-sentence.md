# Review hero sentence: 30 synthetic weeks

For: App (Review), Core (Training), Design · Board item 20
Date: 2026-10-15 · Research lab · Read with: `year-of-data.md`, `../tess-voice.md`, `../context-packing.md`, and master at `origin/master` as fetched today.

Settings for every week: PPL x2 (Push A, Pull A, Legs A, Push B, Pull B, Legs B; 6 sessions a week, Mon to Sat, Sunday rest), kg, a missed day rolls on (the next routine moves to the next training day). Clock and calendar: Gregorian, Monday first, `America/Los_Angeles` (DST ends 2025-11-02, starts 2026-03-08). Notes written: none in any week, so the counts line only has tasks and workouts.

## 1. What master does

There are two Review surfaces on master, and they compute different things.

**Home's Review page** (`Features/Home/ReviewPage.swift`, `ReviewPage`, the left sibling on Home).
- Window: the last seven calendar days ending today (`WeekReview.lastDays`), oldest first. It is a rolling window, not the Monday-first week, even though the voice line above says "the week so far".
- A day is filled when any training date falls on it (`WeekReview.trainedDays`). Training dates come from `HomeData.trainingDates` (`Features/Home/HomeSpatialView.swift`): a finished workout's `endedAt`, or, only for the workout in `model.session`, its `startedAt`. Tasks do not count here.
- Hero: `WeekReview.headline(count)`: "A quiet week so far" for 0, else "{Count} good day(s) of seven", the number spelled out and capitalised ("Four good days of seven", "One good day of seven").
- Dabs (`DayDabs`): filled sage (`Theme.Colors.health`, sage in every theme) when trained, else an empty ring in ink at 25%. Two states only. VoiceOver says "trained" or "rest" (every untrained day is called "rest", misses included).
- Tess line: `WeekReview.tessLine`: the trained muscle with the fewest sets, if under 10: "{Muscle} is a little behind: {n} sets of 10 this week."

**The full Review screen** (`Features/Review/ReviewView.swift`, `ReviewView`, reached from Home's "The week" link and the `.review` sibling route).
- Same rolling seven days (`ReviewWeek.compute`, start = start of today minus 6 days).
- A day is "good" when a task was marked done on it or a workout finished on it (`let finished = doneDates + workouts.compactMap(\.endedAt)`). A running workout does not count (only `finishedWorkouts`).
- Hero: the same `WeekReview.headline` through `ReviewCopy.headline`.
- Dabs (`WeekDabs`): sage when good, ink ring at 25% otherwise. VoiceOver: "something done" or "quiet".
- Counts line (`ReviewCopy.counts`): "9 tasks done, 3 workouts and 2 notes.", or "Nothing finished yet, and that's fine." when all are zero.
- Then Put away, Workouts (titles and day only, no records), the same Tess line, and Backups.

**What master does not use.** Neither surface calls `TrainingLedger.week(containing:sessionsPerWeek:)` or reads `WeekDay.isRest`. And `isRest` itself is only ever set on today and days ahead: past empty days are `.past`, never rest. So on master a planned rest day, a missed day and a day before the app existed all draw the same faint ring. No red anywhere: the ring colour is ink, the fill is sage. The colour rule holds; the problems are copy and a missing third dab state.

**DST.** Both windows step with `calendar.date(byAdding: .day, ...)` from `startOfDay`, so a 23 or 25 hour day still gives seven dabs that start at local midnight. No week below breaks on DST. The one DST oddity is a workout that ends after midnight (F05), and that is day attribution, not DST.

**Missed day rolls on.** Review counts days, not routines, so rolling the routine forward changes nothing on Review. It only changes Now and `week(containing:)`.

## 2. Notation

- Dab rows read oldest to today, left to right, with the day letters given.
- `●` filled sage. `○` faint ink ring (25%). `–` rest (proposed third state, not on master). `·` no dab (proposed: day before first use).
- Training row: `A` Push A, `B` Pull A, `C` Legs A, `D` Push B, `E` Pull B, `F` Legs B, `.` nothing, `r` running now, `s` started and set aside unfinished, `B+C` two sessions that day.
- Tasks row: tasks marked done that day.
- "Now" is when the screen is read. Unless said, 20:00 on the Sunday that ends a Monday-first week, so the rolling window equals that week.

## 3. The 30 weeks, as master shows them

| ID | Kind | Now (LA) | Days | Training | Tasks | Home hero (master) | Home dabs | Review hero (master) | Review dabs | Review counts line | Flag |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F01 | First open, nothing yet | Wed 2025-10-15 08:00 | T F S S M T W | `. . . . . . .` | 0 0 0 0 0 0 0 | A quiet week so far | ○○○○○○○ | A quiet week so far | ○○○○○○○ | Nothing finished yet, and that's fine. | P1, C1 |
| F02 | Very first week (installed Wed) | Sun 2025-10-19 20:00 | M T W T F S S | `. . A B C D .` | 0 0 3 4 2 5 1 | Four good days of seven | ○○●●●●○ | Five good days of seven | ○○●●●●● | 15 tasks done and 4 workouts. | P1, R1 |
| F03 | Strong, full plan | Sun 2025-10-26 20:00 | M T W T F S S | `A B C D E F .` | 4 3 5 4 2 3 0 | Six good days of seven | ●●●●●●○ | Six good days of seven | ●●●●●●○ | 21 tasks done and 6 workouts. | R1 |
| F04 | Strong, DST ends Sun 11-02 | Sun 2025-11-02 20:00 PST | M T W T F S S | `A B C D E F .` | 3 4 4 5 3 2 2 | Six good days of seven | ●●●●●●○ | Seven good days of seven | ●●●●●●● | 23 tasks done and 6 workouts. | R1 |
| F05 | DST night: Legs B 23:20 Sat to 00:40 Sun PDT, read at 01:30 PST | Sun 2025-11-02 01:30 PST | M T W T F S S | `A B C D E . F` | 3 4 4 5 3 2 0 | Six good days of seven | ●●●●●○● | Six good days of seven | ●●●●●●○ | 21 tasks done and 6 workouts. | none (see Q5) |
| F06 | Strong with PRs (bench, squat, OHP e1RM) | Sun 2025-11-16 20:00 | M T W T F S S | `A B C D E F .` | 4 4 3 5 2 1 0 | Six good days of seven | ●●●●●●○ | Six good days of seven | ●●●●●●○ | 19 tasks done and 6 workouts. | R1 |
| F07 | One miss (Wed), rolls on | Sun 2025-11-23 20:00 | M T W T F S S | `A B . C D E .` | 3 2 3 4 4 1 0 | Five good days of seven | ●●○●●●○ | Six good days of seven | ●●●●●●○ | 17 tasks done and 5 workouts. | none |
| F08 | Two misses | Sun 2025-12-07 20:00 | M T W T F S S | `A . B . C D .` | 2 0 3 0 4 2 0 | Four good days of seven | ●○●○●●○ | Four good days of seven | ●○●○●●○ | 11 tasks done and 4 workouts. | T1 |
| F09 | Miss Wed, caught up Sunday | Sun 2025-12-14 20:00 | M T W T F S S | `A B . C D E F` | 3 3 2 4 3 1 1 | Six good days of seven | ●●○●●●● | Seven good days of seven | ●●●●●●● | 17 tasks done and 6 workouts. | none |
| F10 | Rest week (Christmas, no training) | Sun 2025-12-28 20:00 | M T W T F S S | `. . . . . . .` | 2 1 0 0 0 1 3 | A quiet week so far | ○○○○○○○ | Four good days of seven | ●●○○○●● | 7 tasks done. | none |
| F11 | Back after Christmas, New Year off | Sun 2026-01-04 20:00 | M T W T F S S | `A B C . D E .` | 2 3 1 0 2 2 1 | Five good days of seven | ●●●○●●○ | Six good days of seven | ●●●○●●● | 11 tasks done and 5 workouts. | none |
| F12 | Mid-week look, on plan, before today's session | Tue 2026-07-14 07:00 | W T F S S M T | `C D E F . A .` | 3 4 2 1 0 3 0 | Five good days of seven | ●●●●○●○ | Five good days of seven | ●●●●○●○ | 13 tasks done and 5 workouts. | R1 |
| F13 | Sick week, DST starts Sun 03-08 | Sun 2026-03-08 20:00 PDT | M T W T F S S | `. . . . . . .` | 1 0 0 0 0 0 2 | A quiet week so far | ○○○○○○○ | Two good days of seven | ●○○○○○● | 3 tasks done. | G1 |
| F14 | Back from sick, window crosses DST | Thu 2026-03-12 19:00 PDT | F S S M T W T | `. . . A . B C` | 0 0 2 3 2 4 3 | Three good days of seven | ○○○●○●● | Five good days of seven | ○○●●●●● | 14 tasks done and 3 workouts. | G1, T1 |
| F15 | Thin: one session | Sun 2026-04-19 20:00 | M T W T F S S | `. . A . . . .` | 3 2 1 4 2 0 0 | One good day of seven | ○○●○○○○ | Five good days of seven | ●●●●●○○ | 12 tasks done and 1 workout. | G1, T1 |
| F16 | Thin: two sessions, nothing else | Sun 2026-04-26 20:00 | M T W T F S S | `A . . B . . .` | 0 0 0 0 0 0 0 | Two good days of seven | ●○○●○○○ | Two good days of seven | ●○○●○○○ | 2 workouts. | G1, T1 |
| F17 | Thin: three sessions | Sun 2026-05-10 20:00 | M T W T F S S | `A . B . C . .` | 1 0 0 2 0 0 0 | Three good days of seven | ●○●○●○○ | Four good days of seven | ●○●●●○○ | 3 tasks done and 3 workouts. | G1, T1 |
| F18 | Light week (2 sets per exercise, deload style) | Sun 2026-05-24 20:00 | M T W T F S S | `A B C D E F .` | 2 3 2 2 3 1 0 | Six good days of seven | ●●●●●●○ | Six good days of seven | ●●●●●●○ | 13 tasks done and 6 workouts. | R1, T1 |
| F19 | Double day Mon, plan done by Fri | Sun 2026-06-07 20:00 | M T W T F S S | `A+B C D E F . .` | 3 2 3 2 2 0 0 | Five good days of seven | ●●●●●○○ | Five good days of seven | ●●●●●○○ | 12 tasks done and 6 workouts. | D1, R1 |
| F20 | Rest week (holiday, phone off) | Sun 2026-08-16 20:00 | M T W T F S S | `. . . . . . .` | 0 0 0 0 0 0 0 | A quiet week so far | ○○○○○○○ | A quiet week so far | ○○○○○○○ | Nothing finished yet, and that's fine. | C1 |
| F21 | Back from holiday, mid-week look | Wed 2026-08-19 21:00 | T F S S M T W | `. . . . A B .` | 0 0 0 0 3 2 1 | Two good days of seven | ○○○○●●○ | Three good days of seven | ○○○○●●● | 6 tasks done and 2 workouts. | G1, T1 |
| F22 | Missed today, evening look | Thu 2026-09-10 21:00 | F S S M T W T | `E F . A B C .` | 2 1 0 3 2 4 0 | Five good days of seven | ●●○●●●○ | Five good days of seven | ●●○●●●○ | 12 tasks done and 5 workouts. | none |
| F23 | Unfinished workout: Legs A set aside at set 3 on Wed 09-30 | Sun 2026-10-04 20:00 | M T W T F S S | `A B s C D E F` | 2 3 0 2 3 1 1 | Six good days of seven | ●●○●●●● | Six good days of seven | ●●○●●●● | 12 tasks done and 6 workouts. | H1 |
| F24 | Running workout (Push B since 07:15) | Thu 2026-10-15 07:40 | F S S M T W T | `E F . A B C r` | 2 1 0 3 4 2 0 | Six good days of seven | ●●○●●●● | Five good days of seven | ●●○●●●○ | 12 tasks done and 5 workouts. | H1, R1 |
| F25 | Demo day, Push B finished 08:25 | Thu 2026-10-15 18:10 | F S S M T W T | `E F . A B C D` | 2 1 0 3 4 2 3 | Six good days of seven | ●●○●●●● | Six good days of seven | ●●○●●●● | 15 tasks done and 6 workouts. | R1 |
| F26 | Strong: seven days (extra Push A Sunday) | Sun 2026-06-21 20:00 | M T W T F S S | `A B C D E F A` | 3 3 3 3 3 3 3 | Seven good days of seven | ●●●●●●● | Seven good days of seven | ●●●●●●● | 21 tasks done and 7 workouts. | none |
| F27 | Strong with bench PR, last full week | Sun 2026-10-11 20:00 | M T W T F S S | `A B C D E F .` | 4 3 2 3 4 1 0 | Six good days of seven | ●●●●●●○ | Six good days of seven | ●●●●●●○ | 17 tasks done and 6 workouts. | R1 |
| F28 | Monday morning look after a full week | Mon 2026-10-12 06:30 | T W T F S S M | `B C D E F . .` | 3 2 3 4 1 0 0 | Five good days of seven | ●●●●●○○ | Five good days of seven | ●●●●●○○ | 13 tasks done and 5 workouts. | R1 |
| F29 | Tasks only, no training | Sun 2026-06-14 20:00 | M T W T F S S | `. . . . . . .` | 5 5 5 5 5 5 5 | A quiet week so far | ○○○○○○○ | Seven good days of seven | ●●●●●●● | 35 tasks done. | none |
| F30 | Missed Tue, doubled Wed, plan done | Sun 2026-07-26 20:00 | M T W T F S S | `A . B+C D E F .` | 2 0 3 2 2 1 0 | Five good days of seven | ●○●●●●○ | Five good days of seven | ●○●●●●○ | 10 tasks done and 6 workouts. | D1 |

Assumptions that pin the less obvious rows:
- F05: the workout ending 00:40 Sunday lands on Sunday (`endedAt` decides the day), so Saturday shows a ring although they trained Saturday night.
- F12: Mon 07-06 and Tue 07-07 (before the window) had `A B`, so the Monday-first week that ends Sun 07-12 holds six sessions.
- F23: after relaunch the set-aside workout is not `model.session`, so Home does not count its `startedAt`. If it is still `model.session`, Home fills Wednesday (Q6).
- F24: Home counts the running Push B (it is `model.session`); the full Review does not. The two surfaces disagree at the same moment.
- Tess line: the exact muscle depends on the library's primary muscles. The rows flagged T1 are those where a trained muscle certainly falls under 10 sets (one leg day, one session, or 2 sets per exercise). Full PPL x2 weeks may still produce a line; that is a library question, not a fixture.

## 4. Flags

22 of 30 weeks are flagged: F01, F02, F03, F04, F06, F08, F12, F13, F14, F15, F16, F17, F18, F19, F20, F21, F23, F24, F25, F27, F28, F30. Not flagged: F05, F07, F09, F10, F11, F22, F26, F29. No week shows red; every flag is copy that grades or scolds, or a ring that reads as a miss when there was none.

### Flag kinds and the code spot

| Kind | What reads as guilt | Code spot on master | Fix |
|---|---|---|---|
| R1 Rest drawn as a miss | A planned rest day (or the day after a plan that was kept) draws the same ring as a miss, and the hero says "Six good days of seven" for a week that did everything the plan asked. The empty seventh reads as a failure. | `DayDabs` (`Features/Home/ReviewPage.swift`, struct at line 157, colour choice in `body`); `WeekDabs` (`Features/Review/ReviewView.swift`, line 231); hero in `WeekReview.headline` (`ReviewPage.swift` line 29) | Add a third dab state `rest` and a session-based hero (below). |
| G1 Graded thin week | "One good day of seven", "Two good days of seven", "Three good days of seven". The word "good" makes every other day a bad day, and "of seven" turns it into a score. | `WeekReview.headline(_:of:)` (`ReviewPage.swift` line 29); `ReviewCopy.headline` (`ReviewView.swift` line 100) | Count what happened, no "good", no "of seven". |
| T1 Tess says "behind" | "{Muscle} is a little behind: 3 sets of 10 this week." on a sick, thin, back-from-holiday or light week. "Behind" is a debt. | `WeekReview.tessLine` (`ReviewPage.swift` line 43), used by `ReviewPage` and `ReviewCopy.tess` | Reword to a fact, and stay quiet on thin weeks. |
| P1 Rings before the app existed | Days before first use draw rings, so the first week opens with misses. | `WeekReview.lastDays` callers in `ReviewPage.body`; `ReviewWeek.compute` `days` | No dab for days before first use. |
| H1 Real training drawn as a miss | A set-aside half session (F23), or a running workout on the full Review (F24), shows a ring. | `HomeData.trainingDates` (`HomeSpatialView.swift`, only `model.session` counts when unfinished); `ReviewWeek.compute` (finished only) | A started workout with at least one logged working set counts for its `startedAt` day, on both surfaces. |
| D1 Double day undercounted | Two sessions in one day count once, so a kept plan reads "Five good days of seven" with two rings. | `WeekReview.headline` takes a day count | Hero counts sessions, dabs count days. |
| C1 "and that's fine" | "Nothing finished yet, and that's fine." The reassurance implies it might not be fine; "yet" implies something is owed. | `ReviewCopy.counts` (`ReviewView.swift` line 111) | "Nothing to count this week." (first week: "Nothing to count yet.") |

### Proposed copy (exact)

Home's Review page, `WeekReview.headline` replaced by `WeekReview.headline(sessions:perWeek:firstWeek:)`, counting sessions (finished workouts plus the started one with a logged set) in the window:
- 0 sessions: "A quiet week so far" (unchanged). On the first-use day: "Your first week starts today".
- sessions equal to `perWeek`: "All six sessions in" (number spelled out from `perWeek`).
- otherwise: "{N} sessions this week" ("One session this week", "Seven sessions this week").
- first week (first use inside the window): "{N} sessions in your first week".
- VoiceOver keeps the plain count: `consistencyLine` becomes "Trained on 4 of the last 7 days" (unchanged meaning, kept for the label only).

Full Review, `ReviewCopy.headline` gets its own wording (anything done):
- 0: "A quiet week so far"; 7: "Something done every day"; 1: "Something done on one day"; else "Something done on {n} days".

Dabs, both surfaces: three states. Filled sage when trained (Home) or something done (Review). `rest` when the day is empty and its Monday-first week meets the plan's count: done sessions plus sessions still planned ahead by `week(containing:sessionsPerWeek:)` reach `perWeek`; today also takes `rest` when `ledger.restDay(plan:)` is non-nil. Every other empty day is the faint ring. No dab for days before first use. Design (via `tessera-design`) picks the rest mark; suggestion: a short dry brushstroke at ink 15%, not a ring and never a colour. VoiceOver: "trained", "rest", "open".

Tess, `WeekReview.tessLine`: "{Muscle}: {n} sets this week, toward a usual 10." Return nil when the window holds 3 sessions or fewer.

### Each flagged week with its replacement

| ID | Kinds | Home hero, proposed | Home dabs, proposed | Review hero, proposed | Review dabs, proposed | Other copy |
|---|---|---|---|---|---|---|
| F01 | P1, C1 | Your first week starts today | ······○ | Your first week starts today | ······○ | Counts: "Nothing to count yet." |
| F02 | P1, R1 | Four sessions in your first week | ··●●●●○ | Something done on five days | ··●●●●● | |
| F03 | R1 | All six sessions in | ●●●●●●– | Something done on six days | ●●●●●●– | |
| F04 | R1 | All six sessions in | ●●●●●●– | Something done every day | ●●●●●●● | |
| F06 | R1 | All six sessions in | ●●●●●●– | Something done on six days | ●●●●●●– | See Q8 for records |
| F08 | T1 | Four sessions this week | ●○●○●●○ | Something done on four days | ●○●○●●○ | Tess: "{Muscle}: {n} sets this week, toward a usual 10." |
| F12 | R1 | Five sessions this week | ●●●●–●○ | Something done on five days | ●●●●–●○ | |
| F13 | G1 | A quiet week so far | ○○○○○○○ | Something done on two days | ●○○○○○● | |
| F14 | G1, T1 | Three sessions this week | ○○○●–●● | Something done on five days | ○○●●●●● | Tess: none |
| F15 | G1, T1 | One session this week | ○○●○○○○ | Something done on five days | ●●●●●○○ | Tess: none |
| F16 | G1, T1 | Two sessions this week | ●○○●○○○ | Something done on two days | ●○○●○○○ | Tess: none |
| F17 | G1, T1 | Three sessions this week | ●○●○●○○ | Something done on four days | ●○●●●○○ | Tess: none |
| F18 | R1, T1 | All six sessions in | ●●●●●●– | Something done on six days | ●●●●●●– | Tess: "{Muscle}: {n} sets this week, toward a usual 10." |
| F19 | D1, R1 | All six sessions in | ●●●●●–– | Something done on five days | ●●●●●–– | |
| F20 | C1 | A quiet week so far | ○○○○○○○ | A quiet week so far | ○○○○○○○ | Counts: "Nothing to count this week." |
| F21 | G1, T1 | Two sessions this week | ○○○○●●– | Something done on three days | ○○○○●●● | Tess: none. Today is rest because `week(containing:)` drops today after a trained yesterday. |
| F23 | H1 | Seven sessions this week | ●●●●●●● | Something done every day | ●●●●●●● | |
| F24 | H1, R1 | All six sessions in | ●●–●●●● | Something done on six days | ●●–●●●● | Running Push B counts on both surfaces |
| F25 | R1 | All six sessions in | ●●–●●●● | Something done on six days | ●●–●●●● | |
| F27 | R1 | All six sessions in | ●●●●●●– | Something done on six days | ●●●●●●– | |
| F28 | R1 | Five sessions this week | ●●●●●–○ | Something done on five days | ●●●●●–○ | Today stays a ring: it is a training day not yet trained |
| F30 | D1 | All six sessions in | ●–●●●●– | Something done on five days | ●–●●●●– | The missed Tuesday becomes rest because the week was caught up |

Unflagged weeks under the proposal, for the tests: F07 "Five sessions this week" ●●○●●●○; F09 "All six sessions in" ●●–●●●● (the week meets the count, so the missed Wednesday becomes rest); F10 "A quiet week so far" ○○○○○○○; F11 "Five sessions this week" ●●●○●●○; F22 "Five sessions this week" ●●–●●●– (Sun 09-06 rest if the week before was full; today rest by `week(containing:)`); F26 "Seven sessions this week" ●●●●●●●; F29 "A quiet week so far" ○○○○○○○; F05 "All six sessions in" ●●●●●○● (attribution unchanged, Q5).

Top fix: replace `WeekReview.headline` with a session count against the plan ("All six sessions in", "Two sessions this week"), and give the dabs a rest state. That one change clears R1, G1 and D1, which cover 18 of the 22 flagged weeks.

## 5. Swift Testing stubs

App target (`TesseraTests`, next to `HomeDataTests.swift`, since `WeekReview` and `ReviewCopy` live in the app). Suite `ReviewSentenceFixtureTests`, each fixture built by a small `ReviewFixture(id:)` helper on an in-memory model with `TimeZone(identifier: "America/Los_Angeles")`.

- `@Test(arguments: ReviewFixture.all) func masterHeadlineMatchesFixture(_ fixture: ReviewFixture)` (pins section 3 today, flips to section 4 with the fix)
- `@Test(arguments: ReviewFixture.all) func masterDabsMatchFixture(_ fixture: ReviewFixture)`
- `@Test(arguments: ReviewFixture.all) func headlineNeverSaysGoodMissedOrBehind(_ fixture: ReviewFixture)`
- `@Test func fullPlanWeekReadsAllSixSessionsIn()` (F03, F27)
- `@Test func restDayDrawsRestNotRing()` (F03, F12, F28)
- `@Test func missStaysFaintRingNeverRed()` (F07, F08)
- `@Test func thinWeekHeadlineIsAPlainCount()` (F15, F16, F17)
- `@Test func sickWeekReviewHasNoGrade()` (F13)
- `@Test func daysBeforeFirstUseHaveNoDab()` (F01, F02)
- `@Test func runningWorkoutFillsTodayOnBothSurfaces()` (F24)
- `@Test func setAsideHalfSessionCountsAsTrained()` (F23)
- `@Test func doubleDayCountsTwoSessions()` (F19, F30)
- `@Test func caughtUpMissBecomesRest()` (F30, F09)
- `@Test func tessLineSilentOnThinWeeks()` (F14, F15, F16, F17, F21)
- `@Test func tessLineStatesSetsWithoutBehind()` (F08, F18)
- `@Test func emptyCountsLineNeverSaysFine()` (F01, F20)
- `@Test func dstFallBackWeekHasSevenMidnightDabs()` (F04)
- `@Test func dstSpringForwardWindowHasSevenMidnightDabs()` (F13, F14)
- `@Test func afterMidnightWorkoutLandsOnFinishDay()` (F05, documents master)
- `@Test func homeAndReviewAgreeOnTrainingDays()` (F24, F29 shows they differ on purpose for tasks)

Core (`TesseraCore/Tests/TesseraCoreTests/WeekViewTests.swift`), if the rest rule moves into the ledger:
- `@Test func pastEmptyDayIsRestWhenWeekMeetsCount()`
- `@Test func pastEmptyDayIsNotRestWhenWeekFallsShort()`

## 6. Open questions

1. Which surface owns the hero? Home's page counts training only; the full Review counts anything done. They disagree in F02, F04, F10, F11, F13 to F15, F17, F21, F24 and F29. The proposal keeps both, with different words, but one sentence for both may be simpler.
2. Rolling seven days or the Monday-first week? The voice line says "the week so far", but on a Monday it shows last Tuesday to today (F28). The rest rule above already needs Monday-first weeks.
3. Where does `perWeek` come from? Master has no training setting for "6 a week" or "missed day rolls on"; only the plan's `sessionsPerWeek` field. The fixtures assume the plan carries 6.
4. Past rest days need a rule in Core: `week(containing:)` sets `isRest` only on today and days ahead. Should `TrainingLedger` own "this past day was rest", so Now, Plans and Review agree?
5. A workout that ends after midnight counts for the next day (F05). Should a session belong to its `startedAt` day?
6. Is a set-aside workout still `model.session` after relaunch? If yes, Home fills its day and the full Review does not (F23).
7. Should a running workout already make "All six sessions in" (F24), or wait for Finish?
8. PR weeks (F06, F27) look like any other week. A second voice line such as "Two records this week: Bench Press and Squat." would be a fact worth showing. Out of scope for the guilt rule, but cheap: `WorkoutSummary.records` is already computed.
9. There is no deload marker on master, so a light week (F18) cannot silence Tess on purpose. The reworded line is a fact, so it may be fine to keep.
10. First-use date: earliest op in the op log, or the first object's `createdAt`? Needed for the `·` state.
11. Return after a gap (F14, F21): plain counts are safe; a warmer "Back to it: two sessions" needs a gap rule and Tess-voice review.
12. The rest mark needs a design pass with `tessera-design` (shape, contrast in dark mode, Reduce Motion fill order).

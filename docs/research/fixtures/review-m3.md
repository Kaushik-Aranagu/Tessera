# Review with habits and body weight: 12 fixture weeks (board item 83)

For: Builder B (Review), Core (habit and weight ledgers, week flags). Research lab. Date: 2026-10-16.
Inputs: `../m3-lines.md`, `../habits.md`, `../m3-1-2-brief.md` (sections 2 and 3), `habits-from-logs.md`,
`body-weight.md` (BP1 to BP6), `review-sentence.md` (section 4 hero rules), `../week-one-checkin.md`,
`../../product/decisions.md` (4:58, 5:14, 6:44, 7:34, 7:50 and 7:53 PM PT). Master read at `1183d35` (Merge #220,
15 Oct 20:00 PT) with `git show`; no Swift toolchain, nothing run. Trend values from a Python replay of the brief's
EWMA (alpha 0.1, cap 2 kg) in scratch, matching the brief's table to 0.1 kg.

## 1. What master has

- **Two Review surfaces.** Home's `ReviewPage` is the Monday-first page: it reads `ledger.week(containing:)`
  (`Features/Home/ReviewPage.swift:232-233`), counts sessions for the hero (`:234`, `WeekReview.headline` `:34-47`),
  and draws `DayDabs` (`:346-392`) from `WeekReview.marks` (`:120-142`). The full `ReviewView` is still a rolling
  seven days (`Features/Review/ReviewView.swift:52-54`, `:80`) with the "Something done on N days" hero (`:99-106`)
  and its own `WeekDabs` (`:241-287`). This file targets Home's page; the full Review should take the same week.
- **Day marks** (`DayMarkView`, `ReviewPage.swift:395-421`): trained is a sage `PaintDab`, a second small dab for a
  second session (`:403-411`); rest is `RestMark`, a dry ink stroke at 50% (`:425-450`); open is the faint ring, ink
  at 25% (`:414-416`); planned and none draw nothing (`:417-418`). No red anywhere.
- **Past-day flags from Core** (`TesseraCore/Sources/TesseraCore/Training/WeekView.swift`): `isRest` and `wasDue`
  (`:21-24`), set for past empty days by `wasDue(_:)` (`:69-78`, `:84-87`) using `spread` (`:105-113`). Without a
  rhythm (`pastRhythm` nil, `:67-68`) a past empty day is neither, so it draws nothing. `marks` rings only `wasDue`
  past days (`ReviewPage.swift:140`), never today or ahead (`:131-136`), nothing before first use (`:128-129`).
- **The 4 AM day.** `TesseraDay.day(of:)` puts 00:00 to 03:59 on the day before (`Engine/TesseraDay.swift:22-26`);
  `week(containing:)` runs Monday 04:00 to Monday 04:00 (`:65-73`); `firstWeekday = 2` is forced (`:15-19`).
  A workout's day is its `startedAt` day and it needs `endedAt` (`Training/WorkoutSummary.swift:87-113`, `:99-101`).
- **Body weight and habits: nothing.** No `BodyWeight`, `Habit`, `HabitCheckIn`, `HabitLedger` or
  `BodyWeightLedger` in Swift (`git grep` on `1183d35`). `Format.mass` (`App/AppClock.swift:36-41`) goes through
  `MassUnit.format`, which rounds to 0.25 kg or 0.5 lb and prints `%g` (`TesseraCore/.../Model/Units.swift:25-39`).

## 2. How habits and weight join Review (no cards)

The page keeps its order: voice line "the week so far", hero, dabs. M3 adds three things, all plain type on the
page ground, no boxes, no rules, no colour fills:

1. **A week line** in the voice face (21 pt) under the hero: the habit counts and the weight change in one sentence.
2. **One plain text line per habit, at most 3** under the dabs: the name and count in the label face ("Gym 3 of 3",
   "Gym, paused this week"; set as "GYM · 3 OF 3" in Label 16 `inkSecondary`), and under it Design's painted
   thread (`docs/design/no-dots.md`). No coloured dots. A fourth habit or more stays off this page and shows on the full Review and the Habits page (Product,
   8:07 PM PT Oct 15); the 3 shown follow the week line's order (rule habits first, then manual in creation order).
3. **One weight line** under the habits: the trend in kg, one decimal, and how many weigh-ins this week.

**Lines, not marks on the dabs.** The dab already means one thing (a session), with three states and a second
small dab for a double day. Putting Cook and Read on it needs a colour per habit or a corner glyph, which turns
seven dabs into a legend to decode and makes each dab's VoiceOver label long. A text line per habit keeps one
meaning per mark, fits the 3 habits the page shows, and shows a paused habit as its own quiet line rather than a change to
every dab.

**Per-day habit indicator: one painted thread per habit** (Design, `no-dots.md`, after Kaushik's no coloured dots,
16 Oct). Under each habit label, a 3 pt rough stroke aligned to the seven day columns, in the habit's class pigment
at the rest tint. A ticked day (manual, or a counted log) is painted; consecutive ticked days join into one stroke;
a day with no tick is a gap; future days show nothing. 64 pt per habit, at most 3. A check-in paints today's
stretch on wet from the previous day (500 ms), the count ticks, then it dries. Per `habits.md` a habit is a weekly
target, so the gap carries no extra mark: no ring, no cross, no red. The VoiceOver sentences carry the days.

## 3. The hero and the week line

**Hero: `review-sentence.md` section 4, unchanged** (master's `WeekReview.headline`, `ReviewPage.swift:34-47`).
Sessions, spelled out, never "good", never "of seven":
- 0 sessions: "Your first week starts today" on the first-use day, else "A quiet week so far".
- sessions equal to `perWeek`: "All {three} sessions in".
- else "{Four} sessions this week", or "{Two} sessions in your first week" when first use is inside the week.

**Week line: new.** Built from clauses, joined with ", ", first letter capitalised, ending ".":
1. A habit clause "{Name} {n} of {target}" for each habit that has n of 1 or more this week and is not paused.
   Rule habits first (workout, then cook), then manual ones in creation order. At most 3 habit clauses; others
   stay on their lines only. Past the target it is still "{Name} {n} of {target}" ("Gym 4 of 3"; H4, no "+1").
   A habit created this week reads "{Name} {n}, new this week" (section 5). Its clause goes last, after every
   other clause, and new clauses share one tail (item 109, `../habits-first-use.md` G9): one new, "Gym 2 of 3,
   Read 1, new this week."; two new, "Gym 2 of 3, Read 1 and Meditate 1, both new this week."; every clause new,
   "Train 1, Read 1, Meditate 1, all new this week." (R13). The cap picks the 3 by the order rule first, then
   moves the new ones last.
2. A weight clause, only when all hold: 3 or more weigh-in days this week; a trend point before this week's Monday
   04:00 that is not cut by a reseed; the first weigh-in 7 or more days before the latest. Change = trend at the
   week's latest weigh-in minus the trend at the last weigh-in before Monday 04:00, in full precision, converted to
   the display unit, then rounded to one decimal: "weight down 0.4 kg", "weight up 0.3 kg", or "weight about the
   same" when it rounds to 0.0. Alone, it is capitalised: "Weight down 0.3 kg."
3. No clauses: no week line at all. The hero already says the week is quiet; nothing replaces it.

Never in the week line: a paused habit, a 0 count, "lost", "gained", "missed", "streak", "only". The weight
clause says "weight down" or "weight up" in plain ink, never coloured (Product, 8:07 PM PT Oct 15). So the board's
"Gym 3 of 3, Cook 2 of 4, weight down 0.4 kg." prints exactly so under the hero. It is not the hero itself: `review-sentence.md` keeps the 56 pt hero to the session count,
and four clauses at 56 pt would run to five lines.

**Habit line:** "{Name} {n} of {target}". Paused: "{Name}, paused this week", its ticked days still marked (A7: a check-in
in a paused week marks the day). Created this week: "{Name} {n}, new this week". 0: "{Name} 0 of {target}" (H5).

**One habit, three forms** (item 109, `../habits-first-use.md` G11; R14). Builder B keeps them apart:
- Visible label on the habit line, Label 16 caps: "READ · 4 OF 5". Created this week: "READ · 1, NEW THIS WEEK"
  (G10). Paused: "READ, PAUSED THIS WEEK".
- VoiceOver on that line: "Read, 4 of 5 this week. Monday, Tuesday, Wednesday and Thursday done." Created this week:
  "Read, new this week. Friday done."
- Clause in the week line: "Read 4 of 5" (no comma, no "this week").
A fourth habit gets no line on this page and nothing says it is left off (G10); the full Review and the Habits page
list every habit.

**Weight line:** "Weight {trend} kg, {n} weigh-ins this week." ("1 weigh-in"). With 0 weigh-ins this week there is no
weight line: no "no weigh-ins", no nudge. The trend is the app's one trend (EWMA, alpha 0.1, a half-life of about
a week), never a separate 7-day average, so Review and the Body weight page always print the same number.

**VoiceOver.** The header element (hero plus week line, master's `:261-265` widened): "{hero}. {sessionLine}.
{week line}" with "kg" spoken "kilograms". A habit line: "{Name}, {n} of {target} this week. {Days} done." ("None
done yet" at 0; paused: "{Name}, paused this week. Tuesday done."). Weight line: "Body weight trend {w} kilograms,
{n} weigh-ins this week."

## 4. The 12 weeks

Two fixture worlds. **World A** (Europe/London, the brief's): the 30 weigh-ins of `m3-1-2-brief.md` section 2 and the
habit rows of its section 3: **Train** (3, rule workout) and **Read** (5, manual, week of 5 Oct paused). Assumed:
the plan is created Mon 21 Sep 07:00 with `sessionsPerWeek` 3, so first use is 21 Sep; both habits are created Thu
17 Sep 21:00. **World B** (America/Los_Angeles, `habits-from-logs.md`): **Gym** (3, workout, W2 paused), **Cook** (4,
cook), **Read** (5, manual and "read {n} {unit}" notes), the same 3-a-week plan from before 19 Oct, no weigh-ins
after 14 Oct. Workouts with at least one logged set only (decision 6:44 PM PT).

Notation, Monday to Sunday. Dabs: `●` trained, `◉` two sessions, `–` rest stroke, `○` faint ring, `.` today or
ahead with no mark, `·` nothing (before first use, or a paused week's open day). Habit lines are text plus a
thread, written `thread:` with `▬` a painted day, ` ` a gap and `.` today or ahead with no paint, Monday first; the
days each habit ticked are also in its VoiceOver sentence.

**World A correction (4 AM).** Brief row 6 (Read, Mon 28 Sep 00:05) is Sunday 27 Sep under the 7:53 PM PT rule,
and Sunday already holds row 5, so it adds nothing: Read is 4 of 5 in W1 and **1 of 5** in W2 (the brief has 2).

| ID | Week, read at | Hero | Week line | Dabs | Habit lines | Weight line |
|---|---|---|---|---|---|---|
| R01 | 31 Aug, Sun 6 Sep 20:00 | A quiet week so far | (none: no trend before this week) | `·······` | (no habits) | Weight 79.4 kg, 3 weigh-ins this week. |
| R02 | 7 Sep, Sun 13 Sep 20:00 | A quiet week so far | Weight down 0.2 kg. | `·······` | (no habits) | Weight 79.3 kg, 6 weigh-ins this week. |
| R03 | 14 Sep, Sun 20 Sep 20:00, habits made Thu | A quiet week so far | Weight about the same. | `·······` | Train 0, new this week thread `       `; Read 0, new this week thread `       ` | Weight 79.3 kg, 5 weigh-ins this week. |
| R04 | 21 Sep, Mon 28 Sep 00:10 | All three sessions in | Train 3 of 3, Read 4 of 5, weight down 0.4 kg. | `○●–●–●–` | Train 3 of 3 thread ` ▬ ▬ ▬ `; Read 4 of 5 thread `▬▬ ▬  ▬` | Weight 78.9 kg, 5 weigh-ins this week. |
| R05 | 28 Sep, Sun 4 Oct 20:00 | One session this week | Train 2 of 3, Read 1 of 5, weight down 0.2 kg. | `●–○○○○.` | Train 2 of 3 thread `▬    ▬ `; Read 1 of 5 thread `    ▬  ` | Weight 78.7 kg, 4 weigh-ins this week. |
| R06 | 28 Sep in lb, same moment | One session this week | Train 2 of 3, Read 1 of 5, weight down 0.5 lb. | `●–○○○○.` | as R05 | Weight 173.4 lb, 4 weigh-ins this week. |
| R07 | 5 Oct, Sun 11 Oct 20:00 | A quiet week so far | Weight down 0.3 kg. | `○○○○○○.` | Train 0 of 3 thread `       `; Read, paused this week thread ` ▬     ` | Weight 78.4 kg, 4 weigh-ins this week. |
| R08 | 12 Oct, Thu 15 Oct 18:00 | One session this week | Train 1 of 3, Read 2 of 5. | `○●–....` | Train 1 of 3 thread ` ▬  ...`; Read 2 of 5 thread `▬ ▬ ...` | Weight 78.2 kg, 2 weigh-ins this week. |
| R09 | 19 Oct, Mon 26 Oct 00:40 | Four sessions this week | Gym 3 of 3, Cook 3 of 4, Read 3 of 5. | `●–●–○◉–` | Gym 3 of 3 thread `▬ ▬  ▬ `; Cook 3 of 4 thread ` ▬ ▬  ▬`; Read 3 of 5 thread `▬ ▬   ▬` | (none) |
| R10 | 26 Oct, Mon 2 Nov 03:50 | One session this week | Cook 3 of 4, Read 4 of 5. | `·●–···.` | Gym, paused this week thread ` ▬     `; Cook 3 of 4 thread ` ▬ ▬  ▬`; Read 4 of 5 thread `▬  ▬ ▬▬` | (none) |
| R11 | 2 Nov, Mon 2 Nov 04:05 | A quiet week so far | (none) | `.......` | Gym 0 of 3 thread ` ......`; Cook 0 of 4 thread ` ......`; Read 0 of 5 thread ` ......` | (none) |
| R12 | 2 Nov, Sat 7 Nov 23:00 | Four sessions this week | Gym 4 of 3, Cook 3 of 4, Read 2 of 5. | `●–●–●●.` | Gym 4 of 3 thread `▬ ▬ ▬▬.`; Cook 3 of 4 thread `  ▬ ▬▬.`; Read 2 of 5 thread `    ▬▬.` | (none) |
| R13 | C: 12 Oct, Sun 18 Oct 20:00, four habits made this week | All three sessions in | Train 1, Read 1, Meditate 1, all new this week. | not traced (demo store) | TRAIN · 1, NEW THIS WEEK thread `     ▬.`; READ · 1, NEW THIS WEEK thread `    ▬ .`; MEDITATE · 1, NEW THIS WEEK thread `     ▬.`. Call mom (fourth) has no line here | (none) |
| R14 | C: 19 Oct, Thu 22 Oct 20:00 | All three sessions in | Train 3 of 3, Read 4 of 5, Meditate 1 of 3. | not traced (demo store) | TRAIN · 3 OF 3 thread `▬ ▬▬...`; READ · 4 OF 5 thread `▬▬▬▬...`; MEDITATE · 1 OF 3 thread `▬   ...` | (none) |

**World C** (item 109, America/Los_Angeles): the walk in `../habits-first-use.md`. Read (5, manual) made Fri 16 Oct
20:57, Meditate (3) Sat 09:00, Train (3, rule workout) Sat 09:30, Call mom (1) Sat 12:00 and deleted Thu 22 Oct.
R13: Train counts only Saturday's Push A; Tuesday's and Thursday's finishes came before Train existed (Product
9:04 PM PT, G6). Read's 00:40 Saturday "read 20 pages" is Friday's, already in. R14: Meditate is 1 of 3, Monday only;
the walk's step 42 ("meditated yesterday" on Tuesday) lands on Monday, which step 34 already ticked, so it says
"Meditate is already in for Monday." and adds nothing (the walk's "2 of 3" at steps 42 and 54 is one too many).

Weight sums (trend at the week's last weigh-in, full precision): R02 79.252 minus 79.406 = -0.154; R03 79.276 minus
79.252 = +0.024; R04 78.902 minus 79.276 = -0.374; R05 78.672 minus 78.902 = -0.230; R06 the same in lb: 173.441,
-0.507 (rounding 0.2 kg first would print 0.4 lb, so convert before rounding); R07 78.388 minus 78.672 = -0.283; R08
78.240 (2 weigh-ins, no clause). The 87.4 typo (16 Sep) never reaches Review: the capped trend absorbs it (R03).

VoiceOver, header element:

| ID | Exact sentence |
|---|---|
| R01 | A quiet week so far. 0 sessions this week. |
| R02 | A quiet week so far. 0 sessions this week. Weight down 0.2 kilograms. |
| R03 | A quiet week so far. 0 sessions this week. Weight about the same. |
| R04 | All three sessions in. 3 of 3 sessions this week. Train 3 of 3, Read 4 of 5, weight down 0.4 kilograms. |
| R05 | One session this week. 1 of 3 sessions this week. Train 2 of 3, Read 1 of 5, weight down 0.2 kilograms. |
| R06 | One session this week. 1 of 3 sessions this week. Train 2 of 3, Read 1 of 5, weight down 0.5 pounds. |
| R07 | A quiet week so far. 0 of 3 sessions this week. Weight down 0.3 kilograms. |
| R08 | One session this week. 1 of 3 sessions this week. Train 1 of 3, Read 2 of 5. |
| R09 | Four sessions this week. 4 of 3 sessions this week. Gym 3 of 3, Cook 3 of 4, Read 3 of 5. |
| R10 | One session this week. 1 of 3 sessions this week. Cook 3 of 4, Read 4 of 5. |
| R11 | A quiet week so far. 0 of 3 sessions this week. |
| R12 | Four sessions this week. 4 of 3 sessions this week. Gym 4 of 3, Cook 3 of 4, Read 2 of 5. |
| R13 | All three sessions in. 3 of 3 sessions this week. Train 1, Read 1, Meditate 1, all new this week. |
| R14 | All three sessions in. 3 of 3 sessions this week. Train 3 of 3, Read 4 of 5, Meditate 1 of 3. |

Habit line examples: R04 Read "Read, 4 of 5 this week. Monday, Tuesday, Thursday and Sunday done."; R10 Gym "Gym,
paused this week. Tuesday done."; R11 Cook "Cook, 0 of 4 this week. None done yet."; R03 Train "Train, new this
week. None done yet." Weight line R08: "Body weight trend 78.2 kilograms, 2 weigh-ins this week."

Days done, for each habit line's "{Days} done." (and for the thread): R04 Train Tue, Thu, Sat; Read Mon,
Tue, Thu, Sun. R05 and R06 Train Mon, Sat; Read Fri. R07 Read Tue (paused). R08 Train Tue; Read Mon, Wed. R09 Gym
Mon, Wed, Sat; Cook Tue, Thu, Sun; Read Mon, Wed, Sun. R10 Gym Tue (paused); Cook Tue, Thu, Sun; Read Mon, Thu,
Sat, Sun. R12 Gym Mon, Wed, Fri, Sat; Cook Wed, Fri, Sat; Read Fri, Sat. R03 and R11: none.

Dab notes. R01 to R03: no plan or workout yet (first use is 21 Sep), so no dabs and no `perWeek` although he weighed
in; first use stays training-only.
R04: Monday is a ring because the plan was made that morning and wanted a session; the hero still reads "All three
sessions in". R05: Wednesday's workout was finished and then undone (brief row 18), so its day is a ring, and
Train's 2 comes from Saturday's manual check-in, not a session. R09: Tuesday's 0-set Legs A never counts, so
Tuesday is rest, not trained; Saturday holds two sessions (Legs A, Mobility) but Gym counts the day once. R10: the
`·` days are the paused-week rule (section 5); master would draw rings on Mon, Thu, Fri and Sat.

## 5. Edge cases

- **Habit created mid-week** (R03). The creation week is like a paused week: left out of `lastWeeks` and the H6
  history line, and the line says "{Name} {n}, new this week" with no target. Days before creation draw nothing,
  as any untouched day. The week line names it only with n of 1 or more ("Read 1, new this week").
- **Paused week** (R07 Read, R10 Gym). Out of the week line; the line says "{Name}, paused this week" and its
  ticked days stay marked. When the paused habit is the workout-rule habit, the training dabs drop their rings for that week (`·`):
  a ring in a week he chose to pause reads as a miss. Rest strokes and trained dabs stay. Needs a Core flag (gaps).
- **No weigh-ins this week** (R09 to R12). No weight line and no weight clause. Not "No weigh-ins this week", and
  no Tess line: absence is not news. The Body weight page still says "78.1 on Oct 14" (m3-lines B7).
- **Fewer than 3 weigh-ins** (R08). The weight line shows the trend and the count; the week line has no weight
  clause. Two points a week apart move the EWMA by noise as much as by change.
- **First weigh-ins ever** (R01). The trend exists after 1 (decision 7:34 PM PT), so the weight line shows; no change
  until the first weigh-in is 7 days old and a trend point sits before this Monday.
- **Gap over 30 days**. The reseed cuts the trend (m3-lines B14), so the week with the reseed has no weight clause
  even with 3 weigh-ins; the line shows the new trend.
- **Unit change from lb** (R06). Stored kg never changes. When `Format.unit` is lb, both lines convert the full-
  precision kg trend and delta, then round to 0.1 lb ("173.4 lb", "down 0.5 lb"). Switching mid-week reprints the
  whole week in lb; nothing is mixed. A weigh-in typed in lb ("weight 181 lb", BP3) is converted at write.
- **The 4 AM boundary on Monday** (R04, R09, R10, R11). Monday 00:00 to 03:59 still shows last week: a check-in at
  03:50 (R10) and a cook finished at 00:30 (R09) count there. At 04:00 the page turns (R11): every count goes to 0
  quietly, no summary of last week, no line about it (H9). A weigh-in at 03:30 Monday is Sunday's.
- **Two sessions one day** (R09, R12). The hero counts sessions (decision 4:58 PM PT: two count as two), Gym counts
  days. "Four sessions this week" above "Gym 3 of 3" is the expected pair, not a bug.
- **Target passed** (R12). "Gym 4 of 3" in both places, nothing else.
- **More than 3 habits with ticks**. The first 3 by the order rule go in the week line; every habit has its line.

## 6. Swift Testing

App target, `TesseraTests/ReviewM3FixtureTests.swift` (`WeekReview` lives in the app), each week built by a
`ReviewM3Fixture(id:)` helper on an in-memory model, the calendar passed in (London for A, Los Angeles for B):
- `@Test(arguments: ReviewM3Fixture.all) func heroMatchesFixture`, `weekLineMatchesFixture`, `dabsMatchFixture`,
  `habitLinesMatchFixture`, `weightLineMatchesFixture`, `voiceOverHeaderMatchesFixture`
- `@Test(arguments: ReviewM3Fixture.all) func noLineSaysMissedStreakDownOrLost`
- `weekLineLeavesOutPausedAndZeroHabits` (R07, R10, R11), `weekLineCapsHabitClausesAtThree`
- `weightClauseNeedsThreeWeighInsAndATrendBeforeMonday` (R01, R08), `weightChangeAboutTheSameWhenItRoundsToZero` (R03)
- `poundsConvertBeforeRounding` (R06), `outlierNeverReachesReview` (R03)
- `noWeightLineWithoutWeighInsThisWeek` (R09), `daysBeforeFirstUseHaveNoDabEvenWithWeighIns` (R01 to R03)
- `mondayBefore0400ShowsLastWeek` (R10), `mondayAt0400StartsAtZeroQuietly` (R11)
- `createdMidWeekReadsNewThisWeek` (R03), `pausedWorkoutHabitDropsRings` (R10)
- `newHabitClausesGoLastWithOneTail` (R13), `fourthHabitHasNoLineAndNoMention` (R13),
  `labelVoiceOverAndClauseKeepTheirOwnForms` (R14)
- `doubleDayHeroCountsSessionsHabitCountsDays` (R09), `zeroSetWorkoutNeverFillsADab` (R09)

Core, `TesseraCore/Tests/TesseraCoreTests/`: `BodyWeightLedgerTests.weekChange(from:to:)` (R02 to R08 deltas at
0.001), `HabitLedgerTests.creationWeekLeftOutOfLastWeeks`, `HabitLedgerTests.mondayZeroFiveCountsForSunday` (the
row 6 correction), `WeekViewTests.pausedRuleHabitWeekHasNoWasDue`.

## 7. Open decisions (defaults taken, nothing blocked)

1. **Week line, not hero.** The hero stays `review-sentence.md`'s session count; habits and weight go in the line
   under it. Alternative: one long hero; rejected for length at 56 pt.
2. **Text lines under the dabs, not marks on them** (section 2). Per-day habit indicator: Design's
   painted thread, no coloured dots.
3. **Weight clause needs 3 weigh-ins this week.** Alternative: 2, which R08 would then print as "weight down 0.1 kg".
4. **First use stays training-only**, so weight-only weeks (R01 to R03) draw no dabs rather than six rings.
5. **A paused workout habit drops the week's rings.** Alternative: leave Core's rings (R10 then shows `○●–○○○.`).
6. **Creation week reads "new this week"** with no target and stays out of history. Alternative: a pro-rated target
   (the plan rule "Session 1 of 13"); rejected, a fraction of a week reads as a debt.
7. **Habit clause order**: rule habits first, then creation order; stable each week, never sorted by how close.
8. **Monday morning hero** stays master's "A quiet week so far" (R11). Alternative: "A new week" before anything
   is logged on Monday, echoing H2's "Monday, a new week".
9. **Brief's world A row 6** is read under the 4 AM rule (Read W2 1 of 5); the brief's table should change.

## 8. Gaps on master (`1183d35`)

- No `BodyWeight`, `Habit`, `HabitCheckIn`, `BodyWeightLedger`, `HabitLedger` or `PauseHabitWeek`: every weight and
  habit row here waits on M3 slices 1 and 2 and the "Logs fill habits" slice.
- The full `ReviewView` is a rolling seven days with its own hero and `WeekDabs` (`ReviewView.swift:49-92`,
  `:99-106`, `:241-287`), and keys `WeekDabs` by `Calendar.current.startOfDay` (`:253`) and `TesseraDay()` with the
  default calendar (`:263`). The M3 rows need the Monday-first week from `ledger.week(containing:)`, as Home has.
- `wasDue` knows nothing of habit pauses (`WeekView.swift:69-78`), so R10's rings stay until Core adds a flag.
- `finishedWorkouts(onDay:)` returns a workout with `endedAt` and 0 sets (`WorkoutSummary.swift:98-101`), so R09's
  Tuesday would fill on master; "trained means at least one set" (6:44 PM PT) has no code.
- `Format.mass` rounds to 0.25 kg or 0.5 lb and prints `%g` (`Units.swift:25-39`), so a trend of 78.24 kg would
  print "78.25 kg" and 173.44 lb "173.5 lb". Body weight needs `fromKilograms(_, rounded: false)` and one fixed
  decimal; deltas need the same.
- The header's VoiceOver label is hero plus `sessionLine` only (`ReviewPage.swift:261-265`); the week line must join
  it. `DayDabs` labels say "open" for a ring (`:389`); fine, and no habit or weight wording exists yet.
- No stored zone per log (decision 7:52 PM PT lands it), so world B's fall-back night (31 Oct) relies on the wall clock.

# The week, told, on rules (board item 120)

For: Builder B (Review, #352), Design 46, Core (`WeekFacts`, #348 at fa924c4). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). These are the three plain lines Review shows when Claude is off (AI-11's rules version). They are written only from `WeekFacts` fields, and match the slots and checks in `ai11-week-story-eval.md`. The lines were traced by hand against `WeekFacts.swift` on master, not run.

## 1. The three lines, from WeekFacts

| Slot | Template | Fields |
|---|---|---|
| 1, what happened | "{w} of {p} workouts." When two ran on one day: "{w} of {p} workouts, on {d} days." With bests, add ", {b} new best(s)" before the stop. If nothing was trained: "No workouts this week." In a first week: "… since {weekday}." | `w` = `routinesDone.count`, `p` = `plannedDays`, `d` = `trainedDays`, `b` = distinct `records.exercise` (see R1), first-use weekday = first `days` entry with `!beforeFirstUse` |
| 2, the rest of the week | "{t} tasks done, {c} recipe(s) cooked." Drop a zero part. When both are zero: "Nothing else logged." | `t` = `tasksDone`, `c` = the sum of `days[].cooked.count` (cooks, not distinct recipes; see R3) |
| 3, what's next | "{title} is first up {weekday}." With no day: "{title} is next." With the plan ended: "Nothing planned for Monday yet." With no plan: "No plan yet." | `next.title`, `next.day` |

Every line is one sentence ending in a stop, uses digits, and has no grading words. They pass the AI-11 checks K1 to K7 as written.

## 2. Five weeks

Each is read on **Sunday at 10:00**, the week Monday 04:00 to Monday 04:00, the plan PPL x2 rolling on, Sunday rest unless said.

| # | The week | WeekFacts (the fields that matter) | Line 1 | Line 2 | Line 3 |
|---|---|---|---|---|---|
| R-A | **Full week.** Push A, Pull A, Legs A, Push B, Pull B, Legs B Mon-Sat. Bench e1RM best Mon, Squat 5RM and e1RM best Wed. 14 tasks done, chili Sun | routinesDone 6, plannedDays 6, trainedDays 6, records [Bench e1RM, Squat 5RM, Squat e1RM], tasksDone 14, cooked chili ×1, next (Push A, **nil**) | 6 of 6 workouts, 2 new bests. | 14 tasks done, 1 recipe cooked. | Push A is next. (see R2: should be "first up Monday.") |
| R-B | **Rest-heavy week.** Plan on fixed days Mon, Wed, Fri. Trained Mon and Fri. 5 tasks | routinesDone 2, plannedDays 3 (Wed wasDue), trainedDays 2, records [], tasksDone 5, cooked [], next (Legs A, nil) | 2 of 3 workouts. | 5 tasks done. | Legs A is next. |
| R-C | **A missed day.** Trained Mon, Tue, Thu, Fri, Sat; Wed nothing (rolls on). 9 tasks, tacos Thu | routinesDone 5, plannedDays 6 (Wed wasDue), trainedDays 5, tasksDone 9, cooked tacos ×1, next (Pull B, nil) | 5 of 6 workouts. | 9 tasks done, 1 recipe cooked. | Pull B is next. |
| R-D | **A trip.** Trained Mon and Tue, away Wed-Sat, nothing logged. 2 tasks | routinesDone 2, plannedDays 6 (4 wasDue), trainedDays 2, tasksDone 2, cooked [], next (Legs A, nil) | 2 of 6 workouts. | 2 tasks done. | Legs A is next. |
| R-E | **First week.** First op Wed 8:10 pm. Trained Thu, Fri, Sat. 6 tasks | days Mon-Wed: Mon and Tue `beforeFirstUse`, Wed not (first use at 8:10 pm; Wed's planned day counts, R5). routinesDone 3, plannedDays 4, trainedDays 3, tasksDone 6, next (Legs A, nil) | 3 of 4 workouts since Wednesday. | 6 tasks done. | Legs A is next. |

Two variants:
- **R-A2:** the same week read **Wednesday at 20:00**. plannedDays counts days ahead too (`day.date >= today && planned != nil`), so line 1 reads "3 of 6 workouts." Mid-week that's the plan, not a shortfall, but it can read as one (R4).
- **R-A3:** two sessions on Wed (Push B and Pull B). routinesDone 6, trainedDays 5, plannedDays 6. Line 1: "6 of 6 workouts, on 5 days."

## 3. What WeekFacts needs

| # | Gap | Where | Proposed | Owner |
|---|---|---|---|---|
| R1 | **Bests double-count.** `records` holds one row per record kind, so a squat 5RM and a squat e1RM on the same set are 2 rows. Line 1 would say "3 new bests" in R-A for two lifts | `facts(…)`: `records += summary.records.map { … kind: … }` | Count distinct exercises for the line ("2 new bests: bench and squat"). Keep the kinds for Review's own band | Core (a `bestExercises` field), Builder B |
| R2 | **The next day is missing on Sundays,** which is when the lines are written. `nextDay` is searched only inside this week (`week.first { $0.state != .past && … }`). On Sunday the next routine is Monday's, in the next week, so `next.day` is nil and line 3 can't say "Monday" | `facts(…)`, `nextDay` | Search the next 7 days from today, not just this week. On a rest-day Sunday the answer is Monday | Core |
| R3 | **Cooks vs recipes.** `recipesCooked` is distinct titles, so chili twice reads "1 recipe cooked." | `recipesCooked` | Line 2 counts cooks ("2 cooks"), or words it "cooked chili twice"; Design picks. Rules default: "{c} cooks" from the days | Design 46 copy |
| R4 | **Mid-week denominators.** `plannedDays` includes days ahead, so on a Wednesday "3 of 6" reads like a shortfall | `plannedDays` | Mid-week, line 1 says "3 done, 3 to go." On Sunday after 04:00 it says "{w} of {p}." Or Review only shows the lines from Sunday 04:00, as AI-11 says | Design 46, Builder B |
| R5 | **The first-use day counts in full.** First use at 20:10 Wednesday makes Wednesday's routine count as due, so R-E reads "3 of 4" while he only ever had a real chance at 3 | `firstUse()`, `beforeFirstUse` | Count planned days from the first **day after** first use when first use is after 18:00; otherwise from that day. Or accept "3 of 4" (simplest, Product's call) | Core, Product |
| R6 | **No habits.** The AI-11 fixture's W5 says "Read on 5 of 7 days", but `WeekFacts` has no habit field | `WeekFacts` | Leave out of v1 lines; add when M3 habits ship | Core (later) |
| R7 | **A trip reads like a gap.** "2 of 6 workouts." in R-D is true and ungraded, but four days away look the same as four days skipped | none | No change in v1: the line holds no grading word, and the Review bands show the days. Listed so Design can say no on purpose | Design 46 |

## 4. For the AI-11 eval

R-A to R-E are WeekFacts-shaped, so once R1 and R2 land they can join `week-story-eval.json` as W13 to W17, with these lines as their `rules`. Today's R2 gap would make every Sunday's line 3 read "{title} is next." and fail the eval's own W1 rules line ("Push A is first up Monday.").

# Questions and saved queries eval set (60 phrases)

For: Core engine (query AST, Tess answers), Product lead
Date: 2026-10-15

Eval set for M3 slice 4 (saved queries) and slice 7 (Tess answers from the log). Companion to `tess-routing.md` and `tess-eval-phrases.md`; those cover capture (writes), this file covers reads only. No phrase repeats theirs. Every row must produce no write.

**Assumed state.** Same as `tess-eval-phrases.md`: exercises Bench Press, Incline DB press, Squat, Deadlift, Overhead press (OHP), Barbell row, Pull-ups, Lat pulldown, Curls, Leg press; routines Push Day, Pull Day, Leg Day; recipes Spaghetti carbonara, Chilli con carne, Weeknight dal; lists Groceries, Packing, Films, Books, Hardware. Today is Thursday 15 Oct 2026, units kg. Weeks start Monday 00:00 local (habits default), so `thisWeek` is 12 to 18 Oct and `lastWeek` is 5 to 11 Oct.

## Query AST

`ship-list-m3.md` names the AST (slice 4: "sets where exercise is-a HorizontalPush this week") but does not define it. Proposed minimum:

```
Query {
  from:   [ClassDef]            // one class or a union; always includes subclasses (is-a)
  where:  [Pred]                // field op value; op: = != < <= > >= ~(text contains) isa has none
                                // field may be a path: exercise.pattern, parent.title, workout.routine
  during: DateRange on field?   // today, tomorrow, thisWeek, lastWeek, thisMonth, lastMonth, thisYear,
                                // lastNd, date(..), month(..); field defaults to the class's date field
  group:  field?
  agg:    list | count | sum(f) | avg(f) | min(f) | max(f) | latest(f) | trend(f) | series(f)
  sort:   field asc|desc ;  limit: n
}
```

Compact form used in the table: `Class[pred, pred] @range(field) → group(f) → agg → sort f± → limit n`. `A+B` is a union. `ledger.x(..)` means call the existing `TrainingLedger` function instead of a generic query (records, trend, weeklySetsPerMuscle). `habit.count(week)` is the slice 2 function. A saved query (smart list) is the same AST stored as an object; a question is run once and answered in one line.

Default date fields: `Set.loggedAt`, `Workout.endedAt` (finished only), `Cook.cookedAt`, `Task.due`, `ListItem.checkedAt`, `Note` and `BodyWeight` by record creation date, `HabitCheckIn.date`. Default range when none is said: all time for records ("best", "pr", "ever", "last time"), 90 days for trends (matches `trend(days: 90)`), all time for lists.

Answer shape: one line with tappable handles in brackets, e.g. "92.5 x 5 [Set] on 3 Sep [Push Day]". Smart lists render as a list of handles.

## Eval rows

| # | Phrase | Kind | Expected AST | Answer shape | Notes |
|---|---|---|---|---|---|
| 1 | best bench at 5 | question | `Set[exercise isa Bench Press, reps=5, kind=working] → max(weight)` | "Bench at 5: 92.5 kg, 3 Sep [Set] [Push Day]" | Seed phrase. Same as `ledger.records(Bench Press).bestWeightByReps[5]`; must agree |
| 2 | what did i lift last week | question | `Set[kind=working] @lastWeek → group(exercise) → count` | "4 workouts, 52 sets: Bench 12, Squat 9, ... [Workouts]" | Seed phrase. Warm-ups excluded |
| 3 | how many workouts this month | question | `Workout[endedAt!=nil] @thisMonth(endedAt) → count` | "8 workouts in October [list]" | Seed phrase. Started but unfinished do not count |
| 4 | whats my bench pr | question | `ledger.records(Bench Press).bestE1RM` | "Bench PR: e1RM 104 kg from 95 x 3 [Set]" | "PR" means best e1RM; also show heaviest weight if different set |
| 5 | squat e1rm trend | question | `ledger.trend(Squat, days:90)` | "Squat e1RM 142 → 148 kg over 90 days [chart]" | Sparkline handle opens the exercise overview |
| 6 | heaviest deadlift ever | question | `Set[exercise isa Deadlift, kind!=warmup] → max(weight)` | "160 kg x 2, 22 Aug [Set]" | Raw weight, not e1RM. "ever" = all time |
| 7 | when did i last train legs | question | `Workout[has Set.exercise.primaryMuscles.group=Legs] → sort endedAt- → limit 1` | "Tuesday, Leg Day [Workout]" | Group from `MuscleSeed` group names |
| 8 | sets per muscle this wk | question | `ledger.weeklySetsPerMuscle(thisWeek)` vs `Muscle.weeklySetsMin/Max` | "Chest 8, Back 11, Legs 6 (low) [Muscles]" | Flags muscles under `weeklySetsMin` |
| 9 | am i doing enough chest | question | `ledger.weeklySetsPerMuscle(thisWeek)[Chest]` vs `weeklySetsMin..Max` | "Chest 8 sets this week; aim 10 to 20 [Chest]" | Same source as 8, one muscle |
| 10 | horizontal push sets this week | smart list | `Set[exercise.pattern=horizontalPush, kind=working] @thisWeek → sort loggedAt-` | list of sets | Slice 4 example. `pattern` is a field on Exercise, not a class, so "is-a HorizontalPush" lowers to `exercise.pattern=` |
| 11 | all my pullups | smart list | `Set[exercise isa Pull-ups] → sort loggedAt-` | list of sets | Typo "pullups" resolves via `aliases`. Bodyweight-plus sets show "+10" |
| 12 | how much volume on push day | question | `Set[workout=latest(Workout[routine=Push Day]), kind=working] → sum(volume)` | "Push Day Mon: 8,420 kg [Workout]" | `workout` = ancestor path Set → Exercise Entry → Workout. Most recent Push Day |
| 13 | ohp best e1rm last 3 months | question | `Set[exercise isa Overhead press] @last90d → max(e1rm)` | "OHP 62 kg e1RM, 2 Oct [Set]" | "3 months" = 90 days |
| 14 | how many times did i bench in sept | question | `Workout[has Set.exercise isa Bench Press] @month(2026-09) → count` | "9 sessions in September" | "sept" shorthand. Counts sessions, not sets |
| 15 | sets at rpe 9 or above this week | smart list | `Set[rpe>=9] @thisWeek → sort loggedAt-` | list of sets | Sets with no RPE are excluded |
| 16 | workouts i skipped | smart list | `Workout[scheduledFor<today, startedAt=nil] → sort scheduledFor-` | list of workouts | Planned but never started |
| 17 | avg reps on curls | question | `Set[exercise isa Curls, kind=working] @last90d → avg(reps)` | "Curls: 10.4 reps on average, last 90 days" | Averages use the trend default (90 d); say the range in the answer |
| 18 | bench this month vs last | question | `Set[exercise isa Bench Press] @thisMonth → max(e1rm)` and same `@lastMonth` | "Bench e1RM 101 vs 98 kg (+3)" | Two queries, one line. Comparison is best e1RM |
| 19 | whats my best lift | clarify | none | "Best by what? Bench, Squat or Deadlift PR?" with 3 handles | e1RM across exercises is not comparable. No guess |
| 20 | how fast was my 5k | refuse | none | "Runs aren't tracked yet." | No distance or time logging for runs |
| 21 | what did i cook last week | question | `Cook @lastWeek(cookedAt) → sort cookedAt+` | "Dal Mon, Carbonara Thu [Cooks]" | Seed phrase |
| 22 | when did i last make carbonara | question | `Cook[recipe=Spaghetti carbonara] → sort cookedAt- → limit 1` | "Last Thursday, 8 Oct [Cook]" | |
| 23 | how many times have i made chili | question | `Cook[recipe=Chilli con carne] → count` | "6 times, last on 2 Oct [Recipe]" | Spelling "chili" matches "Chilli" by fuzzy name |
| 24 | recipes i havent cooked in a month | smart list | `Recipe[none(Cook[recipe=self] @last30d)] → sort latest(Cook.cookedAt)+` | list of recipes | Needs `none(..)` anti-join on a backlink |
| 25 | quick dinners under 30 min | smart list | `Recipe[totalMinutes<=30] → sort totalMinutes+` | list of recipes | Recipes with no total time are excluded |
| 26 | whats left on groceries | question | `ListItem[parent=Groceries, isDone=false] → group(section) → list` | "7 left: produce 3, dairy 2, ... [Groceries]" | |
| 27 | recipes w chickpeas | smart list | `Recipe[has RecipeLine.ingredient=Chickpeas]` | list of recipes | Child path Recipe → Recipe Line → Ingredient |
| 28 | what did i buy last shop | question | `ListItem[parent=Groceries, isDone=true] @date(latest(checkedAt))` | "12 items on Sat [list]" | "Last shop" = latest day with checks; a real shop session may exist in `Shopping.swift` |
| 29 | most cooked recipe this yr | question | `Cook @thisYear → group(recipe) → count → sort count- → limit 1` | "Weeknight dal, 14 times [Recipe]" | Ties: list both |
| 30 | how many calories in the dal | refuse | none | "Nutrition isn't tracked." | No nutrition fields |
| 31 | every open item dated this week | smart list | `Task+ListItem[isDone=false] @thisWeek(due)` | list grouped by day | Seed phrase. ListItem has no date field today; see ASSUMED |
| 32 | whats overdue | smart list | `Task[isDone=false, due<today] → sort due+` | list of tasks | |
| 33 | what did i get done today | question | `Task[isDone=true] @today(doneAt) → list` | "5 done: dentist, ... [Tasks]" | Date field is `doneAt`, not `due` |
| 34 | tasks i keep pushing | smart list | `Task[isDone=false, rolls>=3] → sort rolls-` | list of tasks | Uses `rolls` from RollForward |
| 35 | how many tasks did i finish this wk | question | `Task[isDone=true] @thisWeek(doneAt) → count` | "14 tasks this week" | |
| 36 | anything due tmrw | question | `Task[isDone=false] @tomorrow(due) → list` | "2 tomorrow: call mum, bins [Tasks]" | Empty: "Nothing due tomorrow." |
| 37 | undated tasks | smart list | `Task[isDone=false, due=nil, startsAt=nil]` | list of tasks | Same set as `Tasks.later()` |
| 38 | books i havent read | smart list | `ListItem[parent=Books, isDone=false]` | list of items | List order kept |
| 39 | films we watched this month | question | `ListItem[parent=Films, isDone=true] @thisMonth(checkedAt)` | "3 films [list]" | |
| 40 | whats on the packing list | question | `ListItem[parent=Packing] → sort order+` | "9 items, 4 packed [Packing]" | Shows done and open. Better as opening the list |
| 41 | stuff about the dentist | smart list | `Task+Note+ListItem[about has Dentist or title~"dentist"]` | list of handles | If "Dentist" is not an object, fall back to text match only |
| 42 | what should i do next | question | `NowPicker` (not a query) | "Next: call mum, 10 min [Task]" | Route to NowPicker, do not build an AST |
| 43 | bw trend | question | `BodyWeight @last90d → trend(weight)` | "78.6 kg trend, down 0.3 kg a week [chart]" | Seed phrase. EWMA 10% per day from `body-weight-trend.md`; rate hidden before 7 days |
| 44 | what did i weigh monday | question | `BodyWeight @date(2026-10-12) → latest(weight)` | "78.9 kg on Monday (trend 78.7) [entry]" | Raw value asked, trend shown beside it |
| 45 | lightest ive been this year | question | `BodyWeight @thisYear → min(trend)` | "Trend low 77.8 kg, 3 Jun [chart]" | Trend low, not the raw low, per the headline rule |
| 46 | how am i doing on habits | question | `Habit → habit.count(thisWeek)` vs `target` | "Read 3/5, Train 2/3, Stretch 0/4 [Habits]" | Paused habits omitted |
| 47 | did i hit gym 3x this wk | question | `Habit[name~"gym"] → habit.count(thisWeek)` vs 3 | "2 of 3 this week [Train]" | No matching habit: fall back to `Workout @thisWeek → count` and say so |
| 48 | habits i missed last week | smart list | `Habit[habit.count(lastWeek)<target, lastWeek not in pausedWeeks]` | list of habits | |
| 49 | my notes from last wk | smart list | `Note @lastWeek(createdAt) → sort createdAt-` | list of notes | |
| 50 | notes on bench | smart list | `Note[about has Bench Press or body~"bench"]` | list of notes | Link first, text second |
| 51 | whats my reading streak | clarify | `Habit[name~"read"] → habit.count(thisWeek)` | "No streaks here. Read 4 of 5 this week [Read]" | No streaks by design (slice 2); answer with this week |
| 52 | how much did i sleep | refuse | none | "Sleep isn't tracked yet." | Needs HealthKit |
| 53 | everything from tuesday | question | `Thing @date(2026-10-13)` on each class's date field `→ group(class)` | "Leg Day, 2 tasks done, dal cooked, 1 note [day]" | Opens the day log |
| 54 | did i cook on days i trained this wk | question | `Cook @thisWeek` joined to `Workout @thisWeek` on same day | "2 of 3 training days [days]" | Join on calendar day; not in the minimal AST, ASSUMED as two queries plus a client-side join |
| 55 | everything linked to bench press | smart list | `Thing[about has Bench Press]` plus backlinks | list grouped by class | Uses `ObjectLink` backlinks |
| 56 | bw vs bench last 3 months | question | `BodyWeight @last90d → trend(weight)` and `ledger.trend(Bench Press, days:90)` | "Trend −1.2 kg, bench e1RM +4 kg [chart]" | Two series, one line |
| 57 | whats still running | question | `Process[state=running] → sort lastTouchedAt-` | "Cook (dal), Push Day [Processes]" | Same source as the What's running screen |
| 58 | how busy was last week | question | `Workout+Cook+Task[isDone=true] @lastWeek → group(class) → count` | "4 workouts, 5 cooks, 21 tasks" | Each class on its own date field |
| 59 | what did tess log today | question | `OpRecord[actor=tess] @today` | "6 things: 4 sets, 1 task, 1 grocery [receipt]" | Overlaps slice 9; reads the op log, not objects |
| 60 | how much did i spend on groceries | refuse | none | "Money isn't tracked yet." | Money is M5 |

Counts: training 20 (1 to 20), kitchen and groceries 10 (21 to 30), tasks and lists 12 (31 to 42), notes, habits and body weight 10 (43 to 52), cross-class 8 (53 to 60). Refuse or clarify: 19, 20, 30, 51, 52, 60 (6). Pass rule as in `tess-routing.md`: AST and answer value both match; any write is a fail.

## ASSUMED (for Product and Core)

1. The AST shape above; ship-list-m3 names one but does not define it. Ledger functions are allowed as leaves so PRs and e1RM are not reimplemented.
2. "is-a HorizontalPush" lowers to `exercise.pattern = horizontalPush`, since movement pattern is a choice field on Exercise, not a class.
3. `ListItem` gains a date field (Lists ship list mentions item dates; the catalog has only `checkedAt`). Row 31 needs it.
4. `BodyWeight` and `Habit`/check-in classes from slices 1 and 2 exist with a creation-date field and `weight`, `name`, `target`, `pausedWeeks`.
5. Default ranges: all time for records and lists, 90 days for trends and averages, Monday-start weeks.
6. "PR" means best e1RM; "heaviest" means raw weight; "lightest" for body weight means the trend low.
7. Path `workout` from a Set walks parents (Set → Exercise Entry → Workout); joins across classes (row 54) and `OpRecord` actor queries (row 59) may be out of the minimal AST.
8. Fuzzy name match ("chili", "pullups", "ohp") uses titles plus `aliases`, same as capture.

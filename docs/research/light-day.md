# Light day: the on-phone rule

For: Core engine (owner), T4 context packs, Product. Owner: Research lab.
Date: 2026-10-16. Board item 34. Code: origin/master `ca30b08`, traced by hand (no Swift toolchain).
Reads with: `plan-my-day-dryrun.md` (gap G2), `plan-my-day-prompt.md` (pack field `light`, cap), `plan-my-day-scenarios.md` (R6), `tess-model-layer.md` §6, `recovery-line.md` §6, `healthkit-reads.md`, `calendar-health-fixtures.md`, `../product/decisions.md` (5:41 PM PT, Research #164).

## Bottom line

The plan pack carries one bit, `light`. Until now its only proposed source was R6 ("sleep under 6h or energy 2 or less"), which is Health-derived and has no source on master (dryrun G2), so `light` is always false. Product's 5:41 PM PT call says the bit comes from **the plan and the day's load, never Health**. This file is that rule.

Light day means "keep today's plan small": cap 2 ghost lines instead of 3, gentle wording, and the workout's `lineText` left empty (prompt pack). It never says why. The rule reads three things the phone already knows: is today a training day in a squeezed week, how many minutes are booked today, and how many fixed blocks cut the day up.

## 1. The rule

Evaluate for the logical day D that `now` belongs to. The day changes at **04:00**, not midnight: D = `RollForwardTasks.logicalDay(of: now)` (`RollForward.swift:71`, with `dayStartHour = 4` at `RollForward.swift:7`). Everything below is "on D". The window for load is the plan window, **07:00 to 21:00 on D (840 minutes)**, fixed for the whole day so the flag does not drift as the clock moves.

`light = C1 or C2 or C3`. If none fires, `light = false`. Missing data never makes a day light.

**C1. Squeezed training week.** Fires when all three hold:
- Today is a training day: not a planned rest day (`TrainingLedger.restDay(plan:now:sessionsPerWeek:calendar:)` returns nil, `RestDay.swift:20`; the per-day flag is `WeekDay.isRest`, `WeekView.swift:20`), and the plan has a rhythm.
- `due >= daysLeft`, where `perWeek` = the plan's `sessionsPerWeek` (`SystemCatalog.swift:187`, read as in `WeekView.swift:47`), `due = perWeek - sessionsBeforeToday`, `sessionsBeforeToday` = workouts finished this week on days before D (`finishedWorkouts(on:)`, `WorkoutSummary.swift:80`; two on one day count as two, per the Review week decision), and `daysLeft` = days in the week from D to the week's end, D included (`week(containing:)` builds the week at `WeekView.swift:32`).
- `due >= 2`. One session left on the last day is just the last session, not a squeeze.

Plain words: no rest day is left this week, and at least two sessions are still to do. This is the same condition under which `week(containing:)` stops spreading and trains every day ahead (`WeekView.swift:61`), so C1 never disagrees with the "Rest day" line on Now. Missed days still roll on; C1 only notices that the rolling has used up the slack.

**C2. Booked day.** Fires when `booked >= 480` minutes (8 of the 14 hours in the window). `booked` is the sum of:
- every task on D's Today list, done or not (`TaskList.today`, `Tasks.swift:36`), at its `length` (`Tasks.swift:80`, seconds / 60) or 30 minutes when it has none (`TaskList.defaultTaskMinutes`, `DayLoad.swift:20`). Done tasks count so the flag does not flip as he ticks things off;
- 60 minutes for the workout when D is a training day (`TaskList.workoutMinutes`, `DayLoad.swift:21`), whether planned, under way or finished; 0 on a planned rest day (same as `load(restDay:)`, `DayLoad.swift:39`);
- each timed, busy calendar event on D, clipped to the window. All-day events count 0, declined events count 0, tentative ones count (as `busy` in `calendar-health-fixtures.md`). **No `Event` class on master**, so this term is 0 until M4 slice 1.

**C3. Cut-up day.** Fires when D has **5 or more fixed blocks** in the window. A fixed block is a timed event (as above) or a timed task: `startsAt` on D and `rolls == 0` (`SystemCatalog.swift:191`, `Tasks.swift:18`). A rolled task is flexible, never fixed (Product, 5:41 PM PT), even though `TaskList.Item.isCarriedOver` is false after the roll (dryrun G5). The workout is not counted here; C1 and C2 cover it.

**Never an input:** sleep, energy, resting HR, HRV, the W3 `RecoveryReading` or its line, anything under `/health`, `HealthReading`. A running workout only matters through "today is a training day" (`hasWorkoutUnderway`, `RestDay.swift:39`, already makes today a training day in `WeekView.swift:59`).

**Tie-breaks and order.** Check C1, then C2, then C3; the first that fires is the `reason`. The reason is for tests and the debug view only and is never packed. `light` is the only thing T4 sends, and `cap = light ? 2 : 3` replaces R6.

**Edge cases.**
- No plan, or a plan with no `sessionsPerWeek` (and `perWeek <= 0`, QA E4): C1 cannot fire. C2 and C3 still can.
- Planned rest day: C1 cannot fire. A rest day is light only by load (C2, C3), which keeps the existing "Rest day: no workout block, no lighter offer, 3 task lines" scenario.
- Between 00:00 and 03:59 the rule evaluates the day that is ending, not the next one.
- Now's precedence is untouched: running, then an event or timed task within 15 minutes, then the rest-day line, then the ranker (`NowRanker.swift:111` to `:131`). `light` changes only the plan pack.

## 2. Where it lives

Owner: **Core**. New file `TesseraCore/Sources/TesseraCore/Tasks/LightDay.swift`, next to `DayLoad.swift`. Two parts, so the rule is a pure function that cannot see Health by construction:

```swift
public struct LightDayInputs: Sendable, Equatable {
    public var isRestDay: Bool               // TrainingLedger.restDay(...) != nil
    public var isTrainingDay: Bool           // has a rhythm, not rest
    public var sessionsPerWeek: Int?         // nil or <= 0: no rhythm
    public var sessionsBeforeToday: Int
    public var daysLeftInWeek: Int           // D included
    public var taskMinutes: [Double]         // every task on D, default 30 applied
    public var timedTaskCount: Int           // startsAt on D, rolls == 0
    public var events: [DateInterval]        // timed, busy, clipped to 07:00-21:00
}

public struct LightDay: Sendable, Equatable {
    public enum Reason: String, Sendable { case squeezedWeek, bookedDay, cutUpDay }
    public let isLight: Bool
    public let reason: Reason?               // never packed
    public static let bookedMinutes = 480.0, fixedBlocks = 5, windowHours = 7 ... 21
    public static func evaluate(_ inputs: LightDayInputs) -> LightDay
}

@MainActor public extension NowPicker {
    /// Gathers inputs for the logical day of `now` (04:00 boundary) and evaluates.
    func lightDay(plan: ObjectRecord?, at now: Date = .now, sessionsPerWeek: Int? = nil,
                  calendar: Calendar = .current) -> LightDay
}
```

Tests (Swift Testing, `TesseraCoreTests/LightDayTests.swift`): the 20 rows below as a parameterised test on `evaluate`; three store-backed tests for the gatherer (F02, F17 late night, F13 rolled tasks); and `LightDayNeverReadsHealth`, which builds the plan pack for F20 with a fake `HealthReading` that would say "short night" and asserts `light == false`, plus a source check that `LightDay.swift` names no `Health` or `Recovery` type.

## 3. Fixture days

Week starts Monday (open question 2). `perWeek` 6 is PPL x2. "Left" counts D. Booked = tasks + workout 60 (training days) + events. Fixed = timed events + timed tasks with `rolls == 0`. Times are local.

| # | Day, time | perWeek | Before | Left | Due | Today | Tasks (n, min) | Events (n, min) | Timed tasks | Booked | Fixed | Light | Fired |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| F01 | Mon 07:30 | 6 | 0 | 7 | 6 | Train, Push A | 3, 60 | 0, 0 | 1 | 120 | 1 | no | none |
| F02 | Thu 07:20 | 6 | 2 | 4 | 4 | Train, Legs A | 2, 30 | 1, 45 | 0 | 135 | 1 | **yes** | C1 |
| F03 | Thu 08:00 | 6 | 3 | 4 | 3 | Rest | 3, 90 | 0, 0 | 0 | 90 | 0 | no | none (rest, spread has room) |
| F04 | Sat 09:20 | 6 | 4 | 2 | 2 | Train, Pull B | 3, 90 | 0, 0 | 0 | 150 | 0 | **yes** | C1 |
| F05 | Sun 08:30 | 6 | 5 | 1 | 1 | Train, Legs B | 3, 180 | 0, 0 | 0 | 240 | 0 | no | none (due 1) |
| F06 | Sun 08:30 | 6 | 6 | 1 | 0 | Rest (week done) | 4, 120 | 0, 0 | 0 | 120 | 0 | no | none |
| F07 | Wed 07:45 | none | 0 | 5 | n/a | Train (no rhythm) | 4, 120 | 1, 60 | 1 | 240 | 2 | no | none (C1 needs a rhythm) |
| F08 | Tue 08:05 | 6 | 1 | 6 | 5 | Rest | 4, 120 | 3, 300 | 1 | 420 | 4 | no | none (below both lines) |
| F09 | Tue 08:05 | 6 | 1 | 6 | 5 | Rest | 4, 120 | 4, 360 | 0 | 480 | 4 | **yes** | C2 (rest day, by load) |
| F10 | Mon 08:00 | 6 | 0 | 7 | 6 | Train, Push A | 6, 180 | 3, 240 | 1 | 480 | 4 | **yes** | C2 (exactly 480) |
| F11 | Fri 07:10 | 6 | 3 | 3 | 3 | Train, Push B | 4, 200 | 3, 240 | 2 | 500 | 5 | **yes** | C1 (C2 and C3 also true) |
| F12 | Wed 07:45 | 6 | 2 | 5 | 4 | Train, Pull A | 6, 120 | 2, 60 | 4 | 240 | 6 | **yes** | C3 |
| F13 | Wed 07:45 | 5 | 2 | 5 | 3 | Train, Pull A | 7, 210 (3 rolled) | 2, 90 | 2 | 360 | 4 | no | none (rolled tasks are not fixed) |
| F14 | Thu 07:30 | 6 | 3 | 4 | 3 | Train, Legs A | 2, 60 | 1, 60 + all-day "Team offsite" | 0 | 180 | 1 | no | none (all-day counts 0) |
| F15 | Mon 08:00 | 6 | 0 | 7 | 6 | Train, Push A | 6, 180 | 2, 120 + declined 180 | 0 | 360 | 2 | no | none (declined counts 0; 540 if counted) |
| F16 | Thu 18:10 | 6 | 3 | 4 | 3 | Train, workout under way (spread said rest) | 2, 60 | 0, 0 | 1 | 120 | 1 | no | none (running makes it training, not light) |
| F17 | Tue 01:30 (logical Mon) | 6 | 0 | 7 | 6 | Train, Push A done | 4, 120 | 4, 360 | 0 | 540 | 4 | **yes** | C2 (Monday's load; Tuesday's tasks not read) |
| F18 | Fri 04:05 | 6 | 4 (double Wed) | 3 | 2 | Train, Pull B | 2, 60 | 0, 0 | 0 | 120 | 0 | no | none (due 2 < left 3; new day began at 04:00) |
| F19 | Sun 09:00 | 6 | 6 | 1 | 0 | Rest (week done) | 5, 480 (garage 120, clean flat 180, taxes 120, 2 untimed) | 0, 0 | 0 | 480 | 0 | **yes** | C2 |
| F20 | Mon 07:30 | 6 | 0 | 7 | 6 | Train, Push A; Health shows a 5h 10m night | 3, 90 | 0, 0 | 0 | 150 | 0 | no | none (Health is never read) |

**Counts: 8 yes (F02, F04, F09, F10, F11, F12, F17, F19), 12 no.** Every condition fires at least once as the first reason (C1: F02, F04, F11; C2: F09, F10, F17, F19; C3: F12), and each edge has a "no" twin: threshold (F08 vs F09), single last session (F05 vs F04), rest with room (F03), no rhythm (F07), rolled tasks (F13), all-day and declined events (F14, F15), running workout (F16), the 04:00 boundary (F17, F18), Health ignored (F20).

Arithmetic check, F11: due 6 - 3 = 3, left Fri to Sun = 3, so `due >= left` and `due >= 2`. F12: booked 120 + 60 + 60 = 240; fixed 2 + 4 = 6. F13: 210 + 60 + 90 = 360. F17: 120 + 60 + 360 = 540.

## 4. Engine gaps found

| # | Gap | Effect on the rule | Owner and fix |
|---|---|---|---|
| L1 | No `Event` class (dryrun G1) | Events add 0 to C2 and C3, so a calendar-heavy day reads as light only from tasks | Core, M4 slice 1. The rule already takes `[DateInterval]` |
| L2 | Day boundary mismatch: `TaskList.today` (`Tasks.swift:38`), `week(containing:)` (`WeekView.swift:36`), `finishedWorkouts` (`WorkoutSummary.swift:84`) and `DayLoad.load` all use `calendar.startOfDay` (midnight); only `RollForwardTasks` uses 04:00, and `logicalDay` is still internal (`RollForward.swift:71`) although the 4:50 PM PT decision makes it public | Between 00:00 and 03:59 the gatherer would read the next day's tasks and a fresh week (F17 fails) | Core: make `logicalDay` public and pass the logical day into these reads, or give the gatherer its own D-based queries |
| L3 | Starter PPL x2 plan has no `sessionsPerWeek` (dryrun G3), and `week(containing:)` has no fallback (`WeekView.swift:47`) while `monthCounts` falls back to min(routines, 6) (`PlanSchedule.swift:76`) | C1 never fires on the starter plan, and no rest day ever fires either | Core: seed 6 for PPL x2, or share the fallback in one place |
| L4 | `week(containing:)` returns only `[WeekDay]`; `due` and the days left are locals (`WeekView.swift:45`, `:54`) | The gatherer would recount them, and could drift from the rest-day spread | Core: a small `WeekRhythm { perWeek, sessionsBeforeToday, daysLeft }` that both `week(containing:)` and `lightDay` read |
| L5 | Week start follows the locale (`.weekOfYear`, `WeekView.swift:32`; dryrun G4) | `daysLeft` and every C1 row change on a Sunday-start phone | Core: pin Monday (Product to confirm) |
| L6 | Rolled tasks look timed (`isCarriedOver` false after roll; dryrun G5) | C3 would count rolled tasks as fixed unless it reads `rolls == 0` | Core: the shared "carried" test from the 5:41 PM PT audit PR |

## 5. Open questions (each with a recommended default)

1. **Is a planned rest day light by itself?** Default: no. Rest frees the day, and the scenario set expects 3 task lines on a rest day. It can still be light by load (F09, F19).
2. **Week start.** Default: pin Monday, so `daysLeft` and rest days do not move with the phone's region (L5).
3. **Thresholds.** Default: 480 booked minutes and 5 fixed blocks, in a 07:00 to 21:00 window. Revisit after two weeks of his real days by logging `reason` locally (debug only).
4. **C1's `due >= 2`.** Default: keep. One session left on Sunday is the plan working, not a squeeze (F05).
5. **Does a light day still offer `lighterTopSet`?** Default: only when the reason is C1 (a squeezed week is real training load). On a booked or cut-up day the session is unchanged; the plan just has fewer lines.
6. **Freeze the flag for the day, or recompute on each plan open?** Default: recompute. Inputs are whole-day (done tasks count, window fixed), so it moves only when he adds or removes work, which should change it.
7. **A manual "light day" toggle (energy check-in)?** Default: not now. If added later it can only turn the flag on, it stays a plan-and-load input he chose, and it is never a Health value.
8. **Tentative events.** Default: count as busy, matching `calendar-health-fixtures.md`.

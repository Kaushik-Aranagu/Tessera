# QA review 290: the rules plan engine, Plan my day (M4 slice 6, #290)

PR head 344f551 on base f867f50. Three new files: DayPlan.swift, DayPlan+Store.swift and DayPlanTests.swift (+636). No deletions or edits to existing code. Static review; no toolchain here.

The review checks the PR against:
- the rules R1-R8 in `plan-my-day-scenarios.md`, with the changes in `fixtures/plan-my-day-claude.md`, which supersedes it;
- `light-day.md` C1-C3;
- Product's decisions of 11:40 AM, 5:48 PM and 9:45 PM PT.

**Verdict: PASS for the rules, with two should-fixes before the plan reaches Now.**
- S1: the window drifts by an hour on DST days. The next is **Sun Nov 1**.
- B1: on his phone, a planned workout never gets a block.

**Writes: none.**
- `DayPlanner.plan` is a pure function of `PlanInput`. The store builder only reads: `TaskList.today` and `later`, `TrainingLedger.restDay` and `finishedWorkouts`, and field values.
- `fromTheStore` checks that the op history still holds only its two `CreateTask`s.
- Accepting a ghost (`MoveTask` by `.user`) isn't in this PR. Today nothing writes at all, so the "nothing until a tap" rule holds by construction. The accept path needs its own test when it lands: one ghost gives one `MoveTask` with `startsAt` = block start; a skip writes 0 ops.

## The rules
| Rule | Code | Status |
|---|---|---|
| R1 window: now rounded up to 5 min, never before 07:00, to 21:00; none at 21:05 or 01:30 | DayPlan.swift:187-194 | ✓ tested (08:02 → 08:05, 06:40 → 07:00). DST: see S1 |
| R2 fixed blocks: timed, not declined, not all-day events; timed tasks with `rolls == 0`; the workout. Never ghosts | :195-208 | ✓. A rolled timed task is flexible (Product 5:41 PM) |
| R3 workout: at its time; date-only → first free hour from 17:00; an overlapping block wins and it moves after it; finished → no block; running → at its start | :209-214, :266-291 | ✓ d05 (18:00 → 18:30, `movedFrom`), running and finished tested. B1 for the builder |
| R4 order: carried by oldest `rolledFrom`; timed due; date-only due by oldest touched; passed timed tasks (A11); Later by oldest touched; ties by title; no priority | :216-233 | ✓ d01, d02, d04 |
| R5 fill: earliest gap that holds it; default 30; cook 45 from 18:00; noFit skips and the walk goes on | :234-261 | ✓ d06, `aTaskThatFitsNowhere…` |
| R6 cap: 3, or 2 when light. Health is never read | :185 | ✓ d04 |
| R7 day full, offer later | not built (stated) | Open. Until it lands, a full day can show as ghosts the tasks Product wants left out ("On a full day, tasks that would otherwise be offered for Later are left out", 11:40 AM PT). |
| R8 start with: earliest task or workout block | :49-51 | ✓. See L2 |
| Light C1: training day, perWeek > 0, due ≥ daysLeft, due ≥ 2 | :313-325 | ✓ tested, including "one left on the last day" and rest days |
| Light C2: booked ≥ 480 (tasks done or not, default 30, workout 60 on a training day, events clipped to 07:00-21:00) | DayPlan+Store.swift:63-72 | ✓ |
| Light C3: ≥ 5 fixed blocks (timed events + timed tasks with `rolls == 0`) | DayPlan+Store.swift:73-75 | ✓, low L1 |
| All-day: declined and "birthday" titles dropped | DayPlan.swift:184 | ✓ tested. A contact's birthday under another title (d23) needs Contacts; later |

All five fixture days tested (d01, d02, d04, d05, d06) give the expected blocks. I walked each by hand against the code.
- d02 uses the `cal:false` version, with no Standup.
- d06's rolled "Call mum" goes to 08:00-08:20, the garage to 14:30-16:30 and the carbonara to 18:00.

## S1 (should-fix): hours are added to midnight, so DST days shift by an hour
`at(hour)` is `calendar.date(byAdding: .hour, value: hour, to: day)` (DayPlan.swift:183). The same pattern is used for 17:00 (:282) and the builder's C2 window (DayPlan+Store.swift:63-64). On **Sun Nov 1, 2026**, midnight PDT + 7 h is 06:00 PST, so the plan opens at 6 AM and closes at 8 PM. On Mar 14, 2027 it opens at 8 AM and closes at 10 PM. Cook's 18:00 and the 17:00 workout slot shift the same way. The fixtures avoid this because they all fall after Nov 1.
**Fix:** `calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)` in all four places. Add a test on Nov 1 and Mar 14 in Los Angeles: the window is 07:00-21:00 wall clock.

## B1 (should-fix before the plan shows on Now): the builder only sees a workout that is running or has `scheduledFor` today
DayPlan+Store.swift:38-55 picks a Workout object that has started today, or is unstarted with `scheduledFor` on today. On master, only the demo seeder sets `scheduledFor` (DemoData.swift:153, :198). On his phone, today's PPL session exists only in the plan rhythm until he starts it. So a training day gets **no workout block**: no 18:00 slot, no move around a meeting, and "Start with" is never the workout. C2 still counts 60 minutes for it, so the two disagree. `DayLoad` has the same limit, so this isn't new, but the plan is where it shows.
**Fix:** when no Workout object fits and today is a training day (`restDay == nil` with a plan), take today's routine from the rhythm (`TrainingLedger.week(containing:)`) as a date-only workout. It then lands in the first free hour from 17:00 (A6). Add a store test: a plan, no Workout object, and an 18:00 meeting → the workout goes to 17:00-18:00.

## Lows
- **L1:** C3 counts only open timed tasks (`input.today` has the done ones filtered out, DayPlan+Store.swift:75). C2 counts done ones "so the flag does not flip as he ticks things off" (light-day.md). Ticking off one of 5 timed tasks drops C3 and changes the cap mid-morning. Count timed tasks from `tasks.today(...)`, done included, as C2 does.
- **L2:** a planned workout whose time has passed, unstarted, still sits at its old time (R3 has no `now` check). So "Start with" can name a 07:00 workout at 09:00. Treat it like a passed timed task (A11): first free hour from `from`, or from 17:00 if it was date-only.
- **L3:** if no hour after a clash fits before 21:00, the workout gets no block and nothing says so (DayPlan.swift:287-290). That's fine for the rules, but Claude's pack then has no workout. Note it for T4.
- **L4:** R3 moves the workout for any overlapping fixed block, timed tasks included. The spec says events. It's harmless and arguably right, but say so in the R3 comment.

# Plan my day: scenario fixtures (M4 slice 6)

For: Core engine, Product
Date: 2026-10-15

**Purpose.** 20 realistic days with the exact plan the slice 6 rules should produce, as test fixtures for Core's planner (rules only, no model call). Each day has its input, its expected plan, and a one-line "rule being tested".

**Time zone.** All times are local wall clock. Tests pin `TimeZone(identifier: "Europe/London")` (ASSUMED) and use 2 to 21 Nov 2026, a stretch with no DST change, so a fixed zone gives the same answers anywhere.

**Field names** follow master where they exist: `Task` (`startsAt`, `length`, `due`, `isDone`, `rolls`, `rolledFrom`, `about`), `ObjectRecord.updatedAt`, `Workout` (`scheduledFor`, `startedAt`, `endedAt`, `routine`), `TaskList.Item.isCarriedOver`, `DayLoad` (`plannedMinutes`, `freeMinutes`, `couldMove`), `TaskList.defaultTaskMinutes` (30), `TaskList.workoutMinutes` (60). `Event` follows m4-scouting (`title`, `start`, `end`, `allDay`) plus `declined`. `length` is minutes in the fixture (the engine stores seconds). `priority` is not a Task field on master; fixtures carry it only to prove the rules ignore it.

## The rules under test

R1. **Window.** From `now` rounded up to the next 5 minutes (never before 07:00) to 21:00 (ASSUMED A2).
R2. **Fixed blocks first.** Timed events that end after `now` (not all-day, not declined), the day's unfinished workout (60 min), and today's timed tasks that are not carried over. Fixed blocks are never ghost lines.
R3. **Workout slot.** At `scheduledFor`. Date-only (00:00) means the first free 60 min at or after 17:00 (A6). If an event overlaps it, the event wins and the workout moves to the first free 60 min after that event (A7). A finished workout (`endedAt` set) gets no block.
R4. **Task order.** Tier 1 carry-overs (`rolls >= 1`), oldest `rolledFrom` first; tier 2 due today (timed `due` by time, then date-only `due` by oldest `updatedAt`, then today's timed tasks whose time has passed, A11); tier 3 Later tasks by oldest `updatedAt`. Ties break by title. `priority` is ignored.
R5. **Fill.** Walk the order; put each task in the earliest free gap that holds its length (default 30, cook default 45 at or after 18:00, A9/A10). A task that fits nowhere is skipped (`noFit`) and the walk goes on. Stop at the cap.
R6. **Cap.** 3 ghost lines; 2 when sleep is under 6h00 or energy is 2 or less. A low day with a workout sets `lighterTopSet` on it (A5).
R7. **Day full.** Slice 3 load before the plan: planned = today's open tasks (tiers 1 and 2 plus timed tasks) vs free = window minus busy events minus the workout. Over means `dayFull`, with `offerLater` picked like `DayLoad.couldMove` (carried-over or untimed, longest first, until it fits). Offered tasks are left out of the ghost plan (A13).
R8. **Start with.** The earliest non-event block in the plan (a task or the workout). None when the plan is empty.
R9. **Card line.** `Today: [all-day title, ]N meetings, Xh free, slept XhMM` (A14 to A16).

## Fixture format

YAML, one document per day, mapping 1:1 to a `Codable` fixture struct (convert to JSON with `yq -o json` if Core prefers no YAML dependency). Times are `HH:mm` on `date`. Lists that are absent are empty.

```yaml
id: d01            # stable test name
rule: "..."        # the one rule being tested
date: 2026-11-02   # local day
now: "08:00"       # when the card is built
sleep: 445         # minutes asleep last night, null = "no sleep data"
energy: 4          # 1-5, null = not logged
events:   [{title, start, end, allDay?: true, declined?: true}]
workout:  {routine, scheduledFor: "HH:mm" | "date", endedAt?: "HH:mm"}   # null = rest day
tasks:    [{title, startsAt?, due?: "HH:mm" | "date", length?, rolls?, rolledFrom?, updatedAt, about?, priority?}]
later:    [{title, length?, updatedAt}]          # undated tasks
training: {lastFinished, missed}                 # optional context, for the roll-on case only
expect:
  card: "Today: ..."
  cap: 3
  blocks:   [{start, end, kind: event|workout|timedTask|task, title, ghost?: true, moved?: "HH:mm", lighterTopSet?: true}]
  allDay:   [title]
  startWith: title | null
  notPlanned: [{title, why: cap|noFit|offeredLater}]   # today's tasks only; unpicked Later tasks are not listed
  dayFull:  null | {planned, free, offerLater: [title]}
```

`ghost: true` marks the accept/skip lines; they are shown in time order. Accepting one sets the task's `startsAt` to the block start through the op log.

## The 20 days

```yaml
id: d01
rule: "Baseline: tiers 1 then 2, earliest-gap fill, card line"
date: 2026-11-02   # Mon
now: "08:00"
sleep: 445
energy: 4
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Design review, start: "11:00", end: "12:00"}
  - {title: 1:1 Priya, start: "15:00", end: "15:30"}
workout: {routine: Push A, scheduledFor: "18:00"}
tasks:
  - {title: Reply to landlord, length: 15, rolls: 1, rolledFrom: 2026-10-30, updatedAt: 2026-10-30}
  - {title: Book physio, due: date, length: 20, updatedAt: 2026-10-29}
  - {title: Expense report, due: "17:00", length: 45, updatedAt: 2026-10-27}
later:
  - {title: Sort the garage, length: 120, updatedAt: 2026-10-12}
expect:
  card: "Today: 3 meetings, 10h15 free, slept 7h25"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:15", kind: task, title: Reply to landlord, ghost: true}
    - {start: "08:15", end: "09:00", kind: task, title: Expense report, ghost: true}
    - {start: "09:00", end: "09:20", kind: task, title: Book physio, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "11:00", end: "12:00", kind: event, title: Design review}
    - {start: "15:00", end: "15:30", kind: event, title: 1:1 Priya}
    - {start: "18:00", end: "19:00", kind: workout, title: Push A}
  startWith: Reply to landlord
  dayFull: null
---
id: d02
rule: "Tier 3 fills from Later by oldest touched; a long task skips a short gap"
date: 2026-11-03   # Tue
now: "08:00"
sleep: 470
energy: 3
events:
  - {title: Standup, start: "09:30", end: "09:45"}
workout: {routine: Pull A, scheduledFor: "18:00"}
tasks:
  - {title: Call bank, due: date, length: 15, updatedAt: 2026-11-02}
later:
  - {title: Sort the garage, length: 120, updatedAt: 2026-10-12}
  - {title: Renew passport, updatedAt: 2026-10-20}
  - {title: Fix bike light, length: 20, updatedAt: 2026-10-05}
expect:
  card: "Today: 1 meeting, 11h45 free, slept 7h50"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:15", kind: task, title: Call bank, ghost: true}
    - {start: "08:15", end: "08:35", kind: task, title: Fix bike light, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "09:45", end: "11:45", kind: task, title: Sort the garage, ghost: true}
    - {start: "18:00", end: "19:00", kind: workout, title: Pull A}
  startWith: Call bank
  dayFull: null
---
id: d03
rule: "Sleep under 6h caps at 2 tasks and offers the lighter top set"
date: 2026-11-04   # Wed
now: "08:00"
sleep: 335
energy: 4
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Sprint planning, start: "13:00", end: "14:30"}
workout: {routine: Legs A, scheduledFor: "18:00"}
tasks:
  - {title: Email Arjun re lease, length: 15, rolls: 2, rolledFrom: 2026-11-02, updatedAt: 2026-11-02}
  - {title: Submit timesheet, due: date, length: 10, updatedAt: 2026-11-01}
  - {title: Review PR 412, due: "12:00", length: 45, updatedAt: 2026-11-03}
later:
  - {title: Order protein, updatedAt: 2026-10-28}
expect:
  card: "Today: 2 meetings, 10h15 free, slept 5h35"
  cap: 2
  blocks:
    - {start: "08:00", end: "08:15", kind: task, title: Email Arjun re lease, ghost: true}
    - {start: "08:15", end: "09:00", kind: task, title: Review PR 412, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "13:00", end: "14:30", kind: event, title: Sprint planning}
    - {start: "18:00", end: "19:00", kind: workout, title: Legs A, lighterTopSet: true}
  startWith: Email Arjun re lease
  notPlanned: [{title: Submit timesheet, why: cap}]
  dayFull: null
---
id: d04
rule: "Low energy (2) with good sleep caps at 2; date-only dues ordered by oldest touched"
date: 2026-11-05   # Thu
now: "08:00"
sleep: 450
energy: 2
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Client call, start: "10:00", end: "11:00"}
  - {title: Team lunch, start: "12:30", end: "13:30"}
workout: {routine: Push B, scheduledFor: "18:00"}
tasks:
  - {title: Pay council tax, due: date, length: 10, updatedAt: 2026-10-30}
  - {title: Draft Q4 goals, due: "17:00", length: 60, updatedAt: 2026-11-04}
  - {title: Book haircut, due: date, length: 15, updatedAt: 2026-11-02}
later:
  - {title: Call grandma, length: 20, updatedAt: 2026-10-25}
expect:
  card: "Today: 3 meetings, 9h45 free, slept 7h30"
  cap: 2
  blocks:
    - {start: "08:00", end: "09:00", kind: task, title: Draft Q4 goals, ghost: true}
    - {start: "09:00", end: "09:10", kind: task, title: Pay council tax, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "10:00", end: "11:00", kind: event, title: Client call}
    - {start: "12:30", end: "13:30", kind: event, title: Team lunch}
    - {start: "18:00", end: "19:00", kind: workout, title: Push B, lighterTopSet: true}
  startWith: Draft Q4 goals
  notPlanned: [{title: Book haircut, why: cap}]
  dayFull: null
---
id: d05
rule: "A meeting overlapping the gym wins; the workout moves to the next free hour"
date: 2026-11-06   # Fri
now: "08:00"
sleep: 420
energy: 4
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: All-hands, start: "16:00", end: "17:00"}
  - {title: Vendor call, start: "17:30", end: "18:30"}
workout: {routine: Pull B, scheduledFor: "18:00"}
tasks:
  - {title: Fill in visa form, length: 40, rolls: 1, rolledFrom: 2026-11-05, updatedAt: 2026-11-05}
  - {title: Send invoice, due: date, length: 15, updatedAt: 2026-11-04}
later:
  - {title: Clean fridge, updatedAt: 2026-10-15}
expect:
  card: "Today: 3 meetings, 9h45 free, slept 7h"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:40", kind: task, title: Fill in visa form, ghost: true}
    - {start: "08:40", end: "08:55", kind: task, title: Send invoice, ghost: true}
    - {start: "08:55", end: "09:25", kind: task, title: Clean fridge, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "16:00", end: "17:00", kind: event, title: All-hands}
    - {start: "17:30", end: "18:30", kind: event, title: Vendor call}
    - {start: "18:30", end: "19:30", kind: workout, title: Pull B, moved: "18:00"}
  startWith: Fill in visa form
  dayFull: null
---
id: d06
rule: "Weekend wording plus a cook task (no length) placed at dinner time"
date: 2026-11-07   # Sat
now: "08:00"
sleep: 510
energy: null
events:
  - {title: Parkrun, start: "09:00", end: "10:00"}
  - {title: Lunch with Nikhil, start: "13:00", end: "14:30"}
workout: {routine: Legs B, scheduledFor: "11:00"}
tasks:
  - {title: Call mum, startsAt: "09:00", length: 20, rolls: 1, rolledFrom: 2026-11-06, updatedAt: 2026-11-05}
  - {title: Cook carbonara, due: date, about: recipe/Carbonara, updatedAt: 2026-11-06}
later:
  - {title: Sort the garage, length: 120, updatedAt: 2026-10-12}
expect:
  card: "Today: 2 events, 9h30 free, slept 8h30"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:20", kind: task, title: Call mum, ghost: true}
    - {start: "09:00", end: "10:00", kind: event, title: Parkrun}
    - {start: "11:00", end: "12:00", kind: workout, title: Legs B}
    - {start: "13:00", end: "14:30", kind: event, title: Lunch with Nikhil}
    - {start: "14:30", end: "16:30", kind: task, title: Sort the garage, ghost: true}
    - {start: "18:00", end: "18:45", kind: task, title: Cook carbonara, ghost: true}
  startWith: Call mum
  dayFull: null
---
id: d07
rule: "Rest day: no workout block, no lighter offer, 3 task lines"
date: 2026-11-08   # Sun
now: "08:00"
sleep: 480
energy: 3
events:
  - {title: Brunch at Anu's, start: "11:00", end: "13:00"}
workout: null
tasks:
  - {title: Meal prep list, due: date, length: 20, updatedAt: 2026-11-05}
later:
  - {title: Fix bike light, length: 20, updatedAt: 2026-10-05}
  - {title: Back up photos, updatedAt: 2026-10-18}
  - {title: Read lease renewal, length: 30, updatedAt: 2026-10-22}
expect:
  card: "Today: 1 event, 11h free, slept 8h"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:20", kind: task, title: Meal prep list, ghost: true}
    - {start: "08:20", end: "08:40", kind: task, title: Fix bike light, ghost: true}
    - {start: "08:40", end: "09:10", kind: task, title: Back up photos, ghost: true}
    - {start: "11:00", end: "13:00", kind: event, title: Brunch at Anu's}
  startWith: Meal prep list
  dayFull: null
---
id: d08
rule: "No sleep data: card says so, no cap applied"
date: 2026-11-09   # Mon
now: "08:00"
sleep: null
energy: 3
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Quarterly review, start: "14:00", end: "16:00"}
workout: {routine: Push A, scheduledFor: "18:00"}
tasks:
  - {title: Renew car insurance, due: "12:00", length: 30, updatedAt: 2026-11-03}
  - {title: Order new contacts, due: date, length: 10, updatedAt: 2026-11-06}
later:
  - {title: Plan Lisbon trip, length: 60, updatedAt: 2026-10-01}
expect:
  card: "Today: 2 meetings, 9h45 free, no sleep data"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:30", kind: task, title: Renew car insurance, ghost: true}
    - {start: "08:30", end: "08:40", kind: task, title: Order new contacts, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "09:45", end: "10:45", kind: task, title: Plan Lisbon trip, ghost: true}
    - {start: "14:00", end: "16:00", kind: event, title: Quarterly review}
    - {start: "18:00", end: "19:00", kind: workout, title: Push A}
  startWith: Renew car insurance
  dayFull: null
---
id: d09
rule: "Missed workout rolls on: yesterday's Push A is today's only workout, no Pull A, no double"
date: 2026-11-10   # Tue
now: "08:00"
sleep: 455
energy: 4
training: {lastFinished: "Legs B 2026-11-07", missed: "Push A 2026-11-09"}   # nextRoutine = Push A
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Hiring panel, start: "15:00", end: "16:00"}
workout: {routine: Push A, scheduledFor: "18:00"}
tasks:
  - {title: Reply to landlord, length: 15, rolls: 3, rolledFrom: 2026-11-06, updatedAt: 2026-11-06}
later:
  - {title: Clean fridge, updatedAt: 2026-10-15}
expect:
  card: "Today: 2 meetings, 10h45 free, slept 7h35"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:15", kind: task, title: Reply to landlord, ghost: true}
    - {start: "08:15", end: "08:45", kind: task, title: Clean fridge, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "15:00", end: "16:00", kind: event, title: Hiring panel}
    - {start: "18:00", end: "19:00", kind: workout, title: Push A}
  startWith: Reply to landlord
  dayFull: null
---
id: d10
rule: "Overbooked: day full, longest flexible task offered to Later and left out; slides fill the evening"
date: 2026-11-11   # Wed
now: "08:00"
sleep: 400
energy: 3
events:
  - {title: Prep call, start: "08:30", end: "09:00"}
  - {title: Board prep, start: "09:00", end: "10:30"}
  - {title: Roadmap workshop, start: "10:30", end: "12:00"}
  - {title: Lunch 1:1 Dev, start: "12:30", end: "13:00"}
  - {title: Customer workshop, start: "13:00", end: "15:30"}
  - {title: Sync with Lee, start: "15:30", end: "16:00"}
  - {title: Exec review, start: "16:00", end: "17:30"}
  - {title: Wrap-up, start: "17:30", end: "18:00"}
workout: {routine: Pull A, scheduledFor: "18:00"}
tasks:
  - {title: Write board memo, length: 90, rolls: 1, rolledFrom: 2026-11-10, updatedAt: 2026-11-10}
  - {title: Fix expense claim, length: 30, rolls: 2, rolledFrom: 2026-11-06, updatedAt: 2026-11-06}
  - {title: Prepare slides, due: "12:00", length: 60, updatedAt: 2026-11-09}
  - {title: Call plumber, due: date, length: 15, updatedAt: 2026-11-09}
expect:
  card: "Today: 8 meetings, 3h free, slept 6h40"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:30", kind: task, title: Fix expense claim, ghost: true}
    - {start: "08:30", end: "09:00", kind: event, title: Prep call}
    - {start: "09:00", end: "10:30", kind: event, title: Board prep}
    - {start: "10:30", end: "12:00", kind: event, title: Roadmap workshop}
    - {start: "12:00", end: "12:15", kind: task, title: Call plumber, ghost: true}
    - {start: "12:30", end: "13:00", kind: event, title: Lunch 1:1 Dev}
    - {start: "13:00", end: "15:30", kind: event, title: Customer workshop}
    - {start: "15:30", end: "16:00", kind: event, title: Sync with Lee}
    - {start: "16:00", end: "17:30", kind: event, title: Exec review}
    - {start: "17:30", end: "18:00", kind: event, title: Wrap-up}
    - {start: "18:00", end: "19:00", kind: workout, title: Pull A}
    - {start: "19:00", end: "20:00", kind: task, title: Prepare slides, ghost: true}
  startWith: Fix expense claim
  notPlanned: [{title: Write board memo, why: offeredLater}]
  dayFull: {planned: 195, free: 180, offerLater: [Write board memo]}
---
id: d11
rule: "All-day event leads the card but is not busy; a timed task stays fixed and is not a line"
date: 2026-11-12   # Thu
now: "08:00"
sleep: 465
energy: 4
events:
  - {title: Mum's birthday, allDay: true}
  - {title: Standup, start: "09:30", end: "09:45"}
workout: {routine: Legs A, scheduledFor: "18:00"}
tasks:
  - {title: Buy birthday flowers, due: "12:00", length: 20, updatedAt: 2026-11-10}
  - {title: Call mum, startsAt: "19:30", length: 30, updatedAt: 2026-11-10}
later:
  - {title: Back up photos, updatedAt: 2026-10-18}
expect:
  card: "Today: Mum's birthday, 1 meeting, 11h45 free, slept 7h45"
  cap: 3
  allDay: [Mum's birthday]
  blocks:
    - {start: "08:00", end: "08:20", kind: task, title: Buy birthday flowers, ghost: true}
    - {start: "08:20", end: "08:50", kind: task, title: Back up photos, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "18:00", end: "19:00", kind: workout, title: Legs A}
    - {start: "19:30", end: "20:00", kind: timedTask, title: Call mum}
  startWith: Buy birthday flowers
  dayFull: null
---
id: d12
rule: "Late start at 11:07: window from 11:10, past events dropped, a missed timed task becomes flexible"
date: 2026-11-13   # Fri
now: "11:07"
sleep: 520
energy: 4
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Design crit, start: "11:00", end: "11:30"}
  - {title: Retro, start: "16:00", end: "17:00"}
workout: {routine: Push B, scheduledFor: "18:00"}
tasks:
  - {title: Reply to landlord, length: 15, rolls: 4, rolledFrom: 2026-11-06, updatedAt: 2026-11-06}
  - {title: Send invoice, due: date, length: 15, updatedAt: 2026-11-10}
  - {title: Pick up parcel, startsAt: "10:00", length: 15, updatedAt: 2026-11-12}
expect:
  card: "Today: 2 meetings, 7h30 free, slept 8h40"
  cap: 3
  blocks:
    - {start: "11:00", end: "11:30", kind: event, title: Design crit}
    - {start: "11:30", end: "11:45", kind: task, title: Reply to landlord, ghost: true}
    - {start: "11:45", end: "12:00", kind: task, title: Send invoice, ghost: true}
    - {start: "12:00", end: "12:15", kind: task, title: Pick up parcel, ghost: true}
    - {start: "16:00", end: "17:00", kind: event, title: Retro}
    - {start: "18:00", end: "19:00", kind: workout, title: Push B}
  startWith: Reply to landlord
  dayFull: null
---
id: d13
rule: "Tasks with no length take 30 min; a date-only workout takes the first free hour from 17:00"
date: 2026-11-14   # Sat
now: "08:00"
sleep: 495
energy: null
events:
  - {title: Haircut, start: "10:00", end: "10:45"}
workout: {routine: Pull B, scheduledFor: date}
tasks:
  - {title: Return Amazon parcel, due: date, updatedAt: 2026-11-12}
  - {title: Water plants, due: date, updatedAt: 2026-11-10}
later:
  - {title: Call grandma, updatedAt: 2026-10-25}
expect:
  card: "Today: 1 event, 11h15 free, slept 8h15"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:30", kind: task, title: Water plants, ghost: true}
    - {start: "08:30", end: "09:00", kind: task, title: Return Amazon parcel, ghost: true}
    - {start: "09:00", end: "09:30", kind: task, title: Call grandma, ghost: true}
    - {start: "10:00", end: "10:45", kind: event, title: Haircut}
    - {start: "17:00", end: "18:00", kind: workout, title: Pull B}
  startWith: Water plants
  dayFull: null
---
id: d14
rule: "Empty day: card with counts only, no lines, no Start with"
date: 2026-11-15   # Sun
now: "08:00"
sleep: 540
energy: null
events: []
workout: null
tasks: []
later: []
expect:
  card: "Today: no events, 13h free, slept 9h"
  cap: 3
  blocks: []
  startWith: null
  dayFull: null
---
id: d15
rule: "A carried-over task loses its old time; a timed task today stays fixed"
date: 2026-11-16   # Mon
now: "08:00"
sleep: 430
energy: 3
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Planning, start: "10:00", end: "11:00"}
workout: {routine: Legs B, scheduledFor: "18:00"}
tasks:
  - {title: Call GP, startsAt: "09:00", length: 10, rolls: 1, rolledFrom: 2026-11-13, updatedAt: 2026-11-12}
  - {title: Dentist, startsAt: "15:00", length: 45, updatedAt: 2026-11-02}
  - {title: Submit receipts, due: date, length: 20, updatedAt: 2026-11-14}
expect:
  card: "Today: 2 meetings, 10h45 free, slept 7h10"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:10", kind: task, title: Call GP, ghost: true}
    - {start: "08:10", end: "08:30", kind: task, title: Submit receipts, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "10:00", end: "11:00", kind: event, title: Planning}
    - {start: "15:00", end: "15:45", kind: timedTask, title: Dentist}
    - {start: "18:00", end: "19:00", kind: workout, title: Legs B}
  startWith: Call GP
  dayFull: null
---
id: d16
rule: "Priority is ignored and a declined invite is neither busy nor counted"
date: 2026-11-17   # Tue
now: "08:00"
sleep: 410
energy: 4
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Vendor pitch, start: "10:00", end: "11:00", declined: true}
  - {title: Arch review, start: "14:00", end: "15:00"}
workout: {routine: Push A, scheduledFor: "18:00"}
tasks:
  - {title: Update CV, due: date, length: 30, priority: 1, updatedAt: 2026-11-16}
  - {title: Cancel gym trial, due: date, length: 10, priority: 3, updatedAt: 2026-11-03}
  - {title: Book flights, due: "16:00", length: 30, priority: 2, updatedAt: 2026-11-15}
  - {title: Sign NDA, due: date, length: 5, priority: 1, updatedAt: 2026-11-15}
expect:
  card: "Today: 2 meetings, 10h45 free, slept 6h50"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:30", kind: task, title: Book flights, ghost: true}
    - {start: "08:30", end: "08:40", kind: task, title: Cancel gym trial, ghost: true}
    - {start: "08:40", end: "08:45", kind: task, title: Sign NDA, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "14:00", end: "15:00", kind: event, title: Arch review}
    - {start: "18:00", end: "19:00", kind: workout, title: Push A}
  startWith: Book flights
  notPlanned: [{title: Update CV, why: cap}]
  dayFull: null
---
id: d17
rule: "A task longer than any gap is skipped (noFit) without a full warning; the walk continues"
date: 2026-11-18   # Wed
now: "08:00"
sleep: 425
energy: 3
events:
  - {title: Interview 1, start: "08:45", end: "09:30"}
  - {title: Interview 2, start: "10:30", end: "11:30"}
  - {title: Interview 3, start: "12:30", end: "13:30"}
  - {title: Interview 4, start: "14:30", end: "15:30"}
  - {title: Debrief, start: "16:30", end: "17:30"}
workout: {routine: Pull A, scheduledFor: "18:00"}
tasks:
  - {title: Feedback for Ana, length: 45, rolls: 1, rolledFrom: 2026-11-17, updatedAt: 2026-11-17}
  - {title: Write offsite plan, due: "17:00", length: 150, updatedAt: 2026-11-16}
  - {title: Order team lunch, due: date, length: 10, updatedAt: 2026-11-17}
later:
  - {title: Renew passport, updatedAt: 2026-10-20}
expect:
  card: "Today: 5 meetings, 7h15 free, slept 7h05"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:45", kind: task, title: Feedback for Ana, ghost: true}
    - {start: "08:45", end: "09:30", kind: event, title: Interview 1}
    - {start: "09:30", end: "09:40", kind: task, title: Order team lunch, ghost: true}
    - {start: "09:40", end: "10:10", kind: task, title: Renew passport, ghost: true}
    - {start: "10:30", end: "11:30", kind: event, title: Interview 2}
    - {start: "12:30", end: "13:30", kind: event, title: Interview 3}
    - {start: "14:30", end: "15:30", kind: event, title: Interview 4}
    - {start: "16:30", end: "17:30", kind: event, title: Debrief}
    - {start: "18:00", end: "19:00", kind: workout, title: Pull A}
  startWith: Feedback for Ana
  notPlanned: [{title: Write offsite plan, why: noFit}]
  dayFull: null
---
id: d18
rule: "Morning gym is Start with; both sleep and energy low still cap at 2 (not 1)"
date: 2026-11-19   # Thu
now: "08:00"
sleep: 290
energy: 1
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Ops review, start: "11:00", end: "12:00"}
workout: {routine: Legs A, scheduledFor: "08:00"}
tasks:
  - {title: Call insurer, length: 20, rolls: 1, rolledFrom: 2026-11-18, updatedAt: 2026-11-18}
  - {title: Pay electricity bill, due: date, length: 10, updatedAt: 2026-11-17}
later:
  - {title: Clear inbox, length: 45, updatedAt: 2026-11-01}
expect:
  card: "Today: 2 meetings, 10h45 free, slept 4h50"
  cap: 2
  blocks:
    - {start: "08:00", end: "09:00", kind: workout, title: Legs A, lighterTopSet: true}
    - {start: "09:00", end: "09:20", kind: task, title: Call insurer, ghost: true}
    - {start: "09:20", end: "09:30", kind: task, title: Pay electricity bill, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "11:00", end: "12:00", kind: event, title: Ops review}
  startWith: Legs A
  dayFull: null
---
id: d19
rule: "Weekday cook task with its own length goes to the first evening gap after the gym"
date: 2026-11-20   # Fri
now: "08:00"
sleep: 470
energy: 5
events:
  - {title: Standup, start: "09:30", end: "09:45"}
  - {title: Friday demo, start: "16:00", end: "17:00"}
workout: {routine: Push B, scheduledFor: "18:00"}
tasks:
  - {title: Return library book, length: 15, rolls: 1, rolledFrom: 2026-11-19, updatedAt: 2026-11-19}
  - {title: Cook chilli, due: date, length: 90, about: recipe/Chilli, updatedAt: 2026-11-18}
later:
  - {title: Plan Lisbon trip, length: 60, updatedAt: 2026-10-01}
expect:
  card: "Today: 2 meetings, 10h45 free, slept 7h50"
  cap: 3
  blocks:
    - {start: "08:00", end: "08:15", kind: task, title: Return library book, ghost: true}
    - {start: "08:15", end: "09:15", kind: task, title: Plan Lisbon trip, ghost: true}
    - {start: "09:30", end: "09:45", kind: event, title: Standup}
    - {start: "16:00", end: "17:00", kind: event, title: Friday demo}
    - {start: "18:00", end: "19:00", kind: workout, title: Push B}
    - {start: "19:00", end: "20:30", kind: task, title: Cook chilli, ghost: true}
  startWith: Return library book
  dayFull: null
---
id: d20
rule: "Boundaries: sleep exactly 6h00 and energy 3 are not low; a finished workout gets no block"
date: 2026-11-21   # Sat
now: "09:00"
sleep: 360
energy: 3
events:
  - {title: Kids football, start: "10:00", end: "11:30"}
workout: {routine: Legs B, scheduledFor: "07:30", endedAt: "08:35"}
tasks:
  - {title: Car wash, due: date, length: 30, updatedAt: 2026-11-19}
  - {title: Call mum, length: 20, rolls: 1, rolledFrom: 2026-11-20, updatedAt: 2026-11-18}
later:
  - {title: Sort the garage, length: 120, updatedAt: 2026-10-12}
  - {title: Back up photos, updatedAt: 2026-10-18}
expect:
  card: "Today: 1 event, 10h30 free, slept 6h"
  cap: 3
  blocks:
    - {start: "09:00", end: "09:20", kind: task, title: Call mum, ghost: true}
    - {start: "09:20", end: "09:50", kind: task, title: Car wash, ghost: true}
    - {start: "10:00", end: "11:30", kind: event, title: Kids football}
    - {start: "11:30", end: "13:30", kind: task, title: Sort the garage, ghost: true}
  startWith: Call mum
  dayFull: null
```

Edge cases covered: rest day (d07, d14), missed workout rolling on (d09), overbooked (d10), no sleep data (d08), low energy (d04, d18), low sleep (d03, d18), all-day event (d11), late start (d12), no duration (d13), empty day (d14), meeting over the gym (d05), weekend (d06, d07, d13, d14, d20), cook task (d06, d19).

## Assumptions for Product

ASSUMED A1: Tests pin Europe/London and use dates with no DST change. Kaushik's real zone does not change any expectation.
ASSUMED A2: The plan window ends at 21:00 (Shutdown), not 23:00 as in `DayLoad`. Core either passes `dayEndHour: 21` to `load` or Product moves `DayLoad` to 21:00 too.
ASSUMED A3: The window starts at `now` rounded up to 5 minutes, never before 07:00 (DayLoad's start).
ASSUMED A4: The card shows from 08:00 until 21:00 and is built at first open; a late open plans from then (d12).
ASSUMED A5: The 3 ghost lines are tasks only. Events, the workout and timed tasks are fixed blocks, not lines. "Lighter top set" is an accept/skip offer on the workout block (top set about 10% lighter, rounded to loadable), only on low days with a workout.
ASSUMED A6: A workout with a date-only `scheduledFor` (00:00) goes to the first free 60 minutes at or after 17:00, else the earliest free hour.
ASSUMED A7: An event overlapping the workout wins; the workout moves to the first free hour after that event. If none is left before 21:00 it stays put and is flagged `clash` (not in this set).
ASSUMED A8: The planner takes today's routine from the scheduled `Workout` (built from `TrainingLedger.nextRoutine`), so a missed day rolls on and there is never a second session.
ASSUMED A9: Untimed tasks are 30 minutes (`defaultTaskMinutes`), workouts 60 (`workoutMinutes`).
ASSUMED A10: A cook task is a Task whose `about` links a Recipe. With no length it takes 45 minutes; it is placed in the first gap at or after 18:00, else the earliest gap.
ASSUMED A11: Tier 2 order is timed `due` by time, then date-only `due` by oldest `updatedAt`, then today's timed tasks whose time already passed (they become flexible instead of vanishing until the 04:00 roll). Ties break by title.
ASSUMED A12: Carried-over tasks (`rolls >= 1`, post-roll state) lose their old time and are flexible (matches `NowPicker` and `DayLoad`); among them, oldest `rolledFrom` first.
ASSUMED A13: Tier 3 "oldest touched" draws only from Later (no date), by `updatedAt`. Tasks dated after today are never pulled in. Unpicked Later tasks are not reported as deferred.
ASSUMED A14: When the day is full, the tasks offered to Later are left out of the ghost plan, so the plan already fits.
ASSUMED A15: Day full is computed before the plan, on today's open tasks plus the workout against free time (events and workout removed); Later tasks pulled into the plan do not count.
ASSUMED A16: Placement is earliest gap that fits, with no buffer between blocks; a task that fits nowhere is skipped and the walk continues to the cap.
ASSUMED A17: Card wording: "meetings" on weekdays, "events" on Saturday and Sunday; "no meetings" / "no events" at zero; the first all-day event title leads; energy is not shown.
ASSUMED A18: Durations in the card round down to 5 minutes, written "XhMM", with "h" alone on the hour ("7h", "slept 6h").
ASSUMED A19: Free time counts busy time only from `now`; an event already in progress counts from `now` to its end, and still counts as a meeting.
ASSUMED A20: `priority` is not a Task field on master and the slice 6 rules ignore it (d16). If Product wants it, it should be a tie-break inside a tier, which would change d16.
ASSUMED A21: Low is strict: sleep under 360 minutes or energy at or below 2. Both low still caps at 2, not lower (d18, d20). Missing sleep or energy never makes a day low.
ASSUMED A22: "Start with" is the earliest non-event block, which can be the workout (d18).

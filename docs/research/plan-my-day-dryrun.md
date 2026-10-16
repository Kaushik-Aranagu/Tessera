# Plan my day: 7-day dry run of the T4 pack (T6 prep)

For: Core engine (T4 context packs, T6 plan wording), Product. Owner: Research lab.
Date: 2026-10-16. Board item 32. No API key used; every pack and line below was built and checked by hand (plus a small script for character counts).
Inputs: `plan-my-day-prompt.md` (pack format, instructions, V1 to V12), `plan-my-day-scenarios.md` (rules R1 to R9, A1 to A22), `context-packing.md`, `on-device-context-size.md`, `recovery-line.md`, `tess-model-layer.md`, `tess-voice.md`, `fixtures/ranker.md`, `starter-content.md`, `day-log-first.md`. Code: origin/master `15fc404`.

Note on names: the brief says `plan-my-day-prompt-pack.md`; on master the prompt pack is `docs/research/plan-my-day-prompt.md`. `context-packing.md` is the Home ranker doc and has no pack format or token budget of its own, so the format comes from `plan-my-day-prompt.md` section 2 and the budget from `on-device-context-size.md` and `plan-my-day-prompt.md` section 7.

## Bottom line

- **Size: every pack is well under budget.** Master-shaped days run 103 to 180 tokens (chars/4). The heaviest case, Friday with a calendar added (4 events and an all-day event, which master can't hold yet), is 283. Budget is 400 for the pack and about 2,000 for the whole input. Nothing is flagged. JSON packs tighter than prose, so at 3 chars a token the worst case is still 378.
- **Privacy: no Health value and no W3 recovery text reaches any pack.** `light` is the only health-derived bit, and it is a bool. One test problem: a real task title ("Recover files from old laptop") would fail the planned `RecoveryNeverPacked` test, which matches substrings.
- **Worst day: Saturday.** Pull B is running when he opens the plan. The pack has no way to say "under way", R3 has no rule for a started workout, and V8 forces `startWith` onto it. The wording that passes is fine, but a likely one ("Pull B at 08:40") reads wrong.
- **Biggest gaps on master:** no `Event` class, no source at all for `light` (no energy check-in, no HealthKit reads), no weekly rhythm on the seeded plan (so no rest days), no code that makes a scheduled `Workout` from the plan, and rolled tasks that look timed to `TaskList` and `NowRanker` but must be flexible to the planner.

## 1. Setup

**Week.** Mon 19 to Sun 25 Oct 2026, `America/Los_Angeles`. All seven days are PDT (UTC-7); DST ends Sun 1 Nov, so no day in the run changes offset. Packs carry wall-clock `HH:mm` only, no zone and no date, so the zone affects the rules, not the pack.

**Plan.** The seeded `StarterContent` plan "Push Pull Legs" (`starter.plan.ppl2`): routines Push A, Pull A, Legs A, Push B, Pull B, Legs B, in that order. Last finished workout before the run: Legs B on Sat 17 Oct, so `TrainingLedger.nextRoutine` gives Push A on Monday.

**Rhythm (assumed, see gap G3).** On master the seed leaves `sessionsPerWeek` empty, and `WeekView` then gives every day the next routine, so a rest day can never fire. To get rest days the run sets the existing `Plan.sessionsPerWeek` field to 5. I traced `TrainingLedger.week(containing:)` day by day, assuming he trains on every training day and `Calendar.current` starts weeks on Sunday (en_US):

| Day | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|---|---|---|---|---|---|---|---|
| `WeekDay` today | Push A | rest (`isRest`) | Pull A | Legs A | Push B | Pull B | rest (`isRest`) |
| Why | 5 due over 6 days | trained Mon, so today rests and 4 spread over Wed to Sat | spread | spread | spread | spread | new week (Sun 25 to Sat 31); trained Sat, so today rests |

With a Monday-start locale, the same plan gives Mon, Wed, Fri, Sat, Sun training and Tue, Thu rest. The rest days depend on the phone's locale, which nothing pins today.

**Workout block.** Master never creates a scheduled `Workout` from the plan (only `DemoData` sets `scheduledFor`). So the planner must take the routine from `WeekDay.planned` and treat it as date-only: by A6 it gets the first free 60 min at or after 17:00.

**Later pool** (undated tasks, `ObjectRecord.updatedAt` in brackets): Fix bike light 20 min (Oct 5), Review lease renewal 30 min (Oct 9), Sort the garage 120 min (Oct 12), Recover files from old laptop, no length (Oct 13), Back up photos, no length (Oct 15), Call grandma 20 min (Oct 16), Plan Lisbon trip 60 min (Oct 17). Tier 3 takes the oldest first, so a task picked on one day is assumed done that day.

**Groceries.** The built-in list (`Groceries.listID`) has 9 open items on Tuesday and 11 on Saturday. The pack has no field for them, by design. Shop is the ranker's evening offer, not a plan block.

**Budget used.**

| Limit | Source | Value |
|---|---|---|
| Pack (context block) | `on-device-context-size.md`, "Context block ... 400, hard cap" | 400 tokens |
| Pack, expected range | `plan-my-day-prompt.md` §7 | 230 (d01) to 380 (d10) |
| Whole input (instructions 1,892 chars = 473, schema about 300, pack) | `plan-my-day-prompt.md` §7, `tess-model-layer.md` §4 (2,000 in) | about 2,000 tokens |

Plan wording always routes to Claude (`tess-model-layer.md` §5 step 2), so the on-device 2,500 total does not bind. I still hold the pack to the 400 cap so one builder serves both routes.

**Token counts** are UTF-8 characters of the one-line wire JSON divided by 4, rounded. For reference, the d01 example in the prompt pack is 808 chars (202 tokens) and d10 is 1,313 (328), a little under that doc's own estimates.

## 2. Pack fields against master

| Pack field | Master source | Status |
|---|---|---|
| `weekday`, `now`, `window` | `AppClock.now`; R1 window 07:00 floor, 21:00 end | `DayLoad.load` ends at 23:00 by default (A2 open) |
| `light`, `cap` | R6: sleep under 6h or energy 2 or less | **No source.** No energy check-in exists; `App/Health/HealthExporter.swift` only writes workouts, it reads nothing. `light` is always false on master |
| `allDay`, `event` blocks | `Event` (M4 slice 1) | **Not on master.** Every master-shaped pack has `allDay: []` and no `e` blocks |
| `task` blocks: `title`, `min` | `Task.title`, `Task.length` (`.duration`, seconds; `min` = length / 60); none means 30 (`TaskList.defaultTaskMinutes`) | OK |
| `due` | `Task.due` (`.date`) | OK, but date-only and timed dues are both `.date`. "Date-only" can only mean 00:00, a convention nothing writes down |
| Tier 1 "carried" | `Task.rolls`, `Task.rolledFrom` | Exists, but see gap G5: after the roll, `TaskList.Item.isCarriedOver` is false |
| Tier 3 order | `ObjectRecord.updatedAt` | OK |
| `timedTask` blocks | `Task.startsAt` with `rolls == 0` | OK |
| `workout` block | `Workout.scheduledFor`, `startedAt`, `endedAt`, `routine` | No scheduled workout exists outside demo data. A running workout has `startedAt` but no `scheduledFor` |
| Cook task | `Task.about` linking a `Recipe` (A10) | OK; `Recipe.totalMinutes` exists and could replace the flat 45 min |
| Rest day | `WeekDay.isRest`, `RestDay` | Exists, but no pack field carries it |
| Handles `t1`, `k1`, `w1`, `e1` | `PlanPack.handles` (proposed) | Not on master (T4) |

## 3. The seven days

Each day lists its source data in master field names, the rules trace, the exact pack (one line, `JSONEncoder` with `.sortedKeys`, as T4 would send it), the privacy check, the size, and the `proposePlan` reply the prompt pack should produce.

Privacy check applied to every pack: no sleep, energy, HR or HRV values; no card line ("slept 7h25"); no W3 `RecoveryReading` or its line; nothing from `/health`; no `lighterTopSet`, notes, set history, `rolls`, `rolledFrom`, `updatedAt`, `priority`, groceries, or object UUIDs; `light` is a bool. I also grepped each pack for the `RecoveryNeverPacked` strings: Slept, lighter, recover, /health, sleep, heart, 340, 36, 58.

### Mon 19 Oct: training day (Push A), timed and untimed tasks

Source: opened 07:30. Tasks: Renew car registration (`due` 17:00, `length` 1800, updated Oct 14); Pay electricity bill (`due` Oct 19 00:00, `length` 600, Oct 16); Call Priya (`startsAt` 12:30, `length` 1200). `WeekDay.planned` = Push A, date-only.
Rules: window 07:30 to 21:00. Fixed: Call Priya 12:30, Push A 17:00 (A6). Tier 2: Renew (timed due) then Pay. Tier 3: Fix bike light (oldest Later). Cap 3, all fit before 12:30, one run.

```json
{"allDay":[],"blocks":[{"due":"17:00","end":"08:00","id":"t1","kind":"task","min":30,"run":1,"start":"07:30","title":"Renew car registration"},{"end":"08:10","id":"t2","kind":"task","min":10,"run":1,"start":"08:00","title":"Pay electricity bill"},{"end":"08:30","id":"t3","kind":"task","min":20,"run":1,"start":"08:10","title":"Fix bike light"},{"end":"12:50","fixed":true,"id":"k1","kind":"timedTask","min":20,"start":"12:30","title":"Call Priya"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Push A"}],"cap":3,"light":false,"now":"07:30","weekday":"Mon","window":["07:30","21:00"]}
```

Privacy: pass. Size: 627 chars, **157 tokens**, under 400.
Tess (moves the 10-minute bill to the front; the run still ends at 08:30):

```json
{"blocks":[{"id":"t2","start":"07:30","end":"07:40","lineText":""},{"id":"t1","start":"07:40","end":"08:10","lineText":""},{"id":"t3","start":"08:10","end":"08:30","lineText":""},{"id":"k1","start":"12:30","end":"12:50","lineText":""},{"id":"w1","start":"17:00","end":"18:00","lineText":""}],
 "startWith":{"id":"t2","line":"Electricity bill first, then the registration."},
 "ghostLines":[{"id":"t2","line":"10 min. Small, and out of the way."},{"id":"t1","line":"30 min, done well before 17:00."},{"id":"t3","line":"20 min. Bike light sorted by 08:30."}],
 "note":null}
```

V11: 17:00 is t1's `due`, 08:30 is t3's end, 10/30/20 are `min`. Longest line 8 words.

### Tue 20 Oct: rest day, carried task, groceries

Source: opened 08:05. Email landlord re lease: was `startsAt` Mon 19:00, not done; at 04:00 `RollForwardTasks` set `startsAt` Tue 19:00, `rolls` 1, `rolledFrom` Mon 19:00 (`length` 900). Book flu shot (`due` Oct 20 00:00, `length` 900, Oct 17). Haircut (`startsAt` 12:00, `length` 2700). `WeekDay.isRest` true, so no workout. Groceries: 9 open.
Rules: tier 1 Email landlord (`rolls` 1, so A12 drops its 19:00 time and makes it flexible). Tier 2 Book flu shot. Tier 3 Review lease renewal. Haircut fixed.

```json
{"allDay":[],"blocks":[{"end":"08:20","id":"t1","kind":"task","min":15,"run":1,"start":"08:05","title":"Email landlord re lease"},{"end":"08:35","id":"t2","kind":"task","min":15,"run":1,"start":"08:20","title":"Book flu shot"},{"end":"09:05","id":"t3","kind":"task","min":30,"run":1,"start":"08:35","title":"Review lease renewal"},{"end":"12:45","fixed":true,"id":"k1","kind":"timedTask","min":45,"start":"12:00","title":"Haircut"}],"cap":3,"light":false,"now":"08:05","weekday":"Tue","window":["08:05","21:00"]}
```

Privacy: pass. The old 19:00 time, `rolls` and `rolledFrom` are not sent, so Tess can't say "again" or "from yesterday". The 9 groceries are not sent. "Book flu shot" is a health-adjacent title, which policy allows (titles are his words; V12 exempts them). Size: 512 chars, **128 tokens**.
Tess (keeps the order):

```json
{"blocks":[{"id":"t1","start":"08:05","end":"08:20","lineText":""},{"id":"t2","start":"08:20","end":"08:35","lineText":""},{"id":"t3","start":"08:35","end":"09:05","lineText":""},{"id":"k1","start":"12:00","end":"12:45","lineText":""}],
 "startWith":{"id":"t1","line":"Landlord email first, while the morning is quiet."},
 "ghostLines":[{"id":"t1","line":"15 min, first thing."},{"id":"t2","line":"15 min to book the flu shot."},{"id":"t3","line":"30 min on the lease, well before Haircut at 12:00."}],
 "note":null}
```

Tess cannot say "Rest day": nothing in the pack says so, and "invent nothing" forbids reading it from the missing workout. Now already shows the "Rest day" line, so this is fine. Watch: Now and the plan disagree today (gap G5). `NowRanker` reads the rolled task as timed 19:00; the plan puts it at 08:05.

### Wed 21 Oct: training day (Pull A) and a cook

Source: opened 07:45. Send invoice (`due` 12:00, `length` 900). Order contact lenses (`due` Oct 21 00:00, `length` 600, Oct 19). Cook dal tadka (`due` Oct 21 00:00, no `length`, `about` → Recipe "Dal tadka", Oct 18). Pick up parcel (`startsAt` 16:00, `length` 900). Pull A, date-only.
Rules: fixed Pick up parcel 16:00, Pull A 17:00. Tier 2 Send invoice, then Order contact lenses, then the cook. The cook gets 45 min at or after 18:00 (A10), so 18:00 to 18:45, after the workout. Cap 3 is reached, so no tier 3. Two runs.

```json
{"allDay":[],"blocks":[{"due":"12:00","end":"08:00","id":"t1","kind":"task","min":15,"run":1,"start":"07:45","title":"Send invoice"},{"end":"08:10","id":"t2","kind":"task","min":10,"run":1,"start":"08:00","title":"Order contact lenses"},{"end":"16:15","fixed":true,"id":"k1","kind":"timedTask","min":15,"start":"16:00","title":"Pick up parcel"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Pull A"},{"end":"18:45","id":"t3","kind":"task","min":45,"run":2,"start":"18:00","title":"Cook dal tadka"}],"cap":3,"light":false,"now":"07:45","weekday":"Wed","window":["07:45","21:00"]}
```

Privacy: pass. The recipe link (`about`) is not sent, only the title. Size: 621 chars, **155 tokens**.
Tess:

```json
{"blocks":[{"id":"t1","start":"07:45","end":"08:00","lineText":""},{"id":"t2","start":"08:00","end":"08:10","lineText":""},{"id":"k1","start":"16:00","end":"16:15","lineText":""},{"id":"w1","start":"17:00","end":"18:00","lineText":""},{"id":"t3","start":"18:00","end":"18:45","lineText":""}],
 "startWith":{"id":"t1","line":"Invoice first, then the lenses."},
 "ghostLines":[{"id":"t1","line":"15 min, sent well before 12:00."},{"id":"t2","line":"10 min to order the lenses."},{"id":"t3","line":"45 min, straight after Pull A."}],
 "note":null}
```

The useful line ("Dal tadka needs 4 things from Groceries") is out of reach: the pack has no recipe-readiness field, and counts fail V11 anyway.

### Thu 22 Oct: light day, training (Legs A)

Source: opened 07:20. Call insurer (`due` Oct 22 00:00, `length` 1200, Oct 15). Submit timesheet (`due` Oct 22 00:00, `length` 600, Oct 20). Physio (`startsAt` 13:00, `length` 2700). Legs A, date-only. Light: assumed from an energy check-in of 2 (not on master).
Rules: R6 cap 2. Tier 2 by oldest `updatedAt`: insurer, then timesheet. The engine sets `lighterTopSet` on Legs A and does not send it.

```json
{"allDay":[],"blocks":[{"end":"07:40","id":"t1","kind":"task","min":20,"run":1,"start":"07:20","title":"Call insurer"},{"end":"07:50","id":"t2","kind":"task","min":10,"run":1,"start":"07:40","title":"Submit timesheet"},{"end":"13:45","fixed":true,"id":"k1","kind":"timedTask","min":45,"start":"13:00","title":"Physio"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Legs A"}],"cap":2,"light":true,"now":"07:20","weekday":"Thu","window":["07:20","21:00"]}
```

Privacy: pass. `light: true` and `cap: 2` are the only trace of the reason. No energy number, no sleep. If W3 fires today (training day), its line ("Slept 5h 40m. Lighter is fine today") stays on Now and is in no pack. "Physio" is a title, so it is allowed and exempt from V12. Size: 496 chars, **124 tokens**.
Tess (small one first; w1 `lineText` stays empty, as the light rule asks):

```json
{"blocks":[{"id":"t2","start":"07:20","end":"07:30","lineText":""},{"id":"t1","start":"07:30","end":"07:50","lineText":""},{"id":"k1","start":"13:00","end":"13:45","lineText":""},{"id":"w1","start":"17:00","end":"18:00","lineText":""}],
 "startWith":{"id":"t2","line":"Timesheet first, then the insurer."},
 "ghostLines":[{"id":"t2","line":"10 min, then it's off the list."},{"id":"t1","line":"20 min, and the morning is yours."}],
 "note":null}
```

Rejected variants: "Kept it short today." (leaks why), "Go easy at Legs A." (V10).

### Fri 23 Oct: the full day (Push B), carried task, three runs' worth of tasks

Source: opened 07:10. Fill in visa form (rolled from Thu 20:00, `rolls` 1, `length` 2400). Book flights (`due` 16:00, `length` 1800). Sign NDA (`due` Oct 23 00:00, `length` 300, Oct 20). Update CV (`due` Oct 23 00:00, `length` 1800, Oct 22). Pick up dry cleaning (`startsAt` 12:15, 900). Call mom (`startsAt` 19:30, 1800). Push B, date-only.
Rules: tier 1 visa form; tier 2 Book flights (timed due), then Sign NDA (older); cap reached, so Update CV is `notPlanned: cap` and not sent. Not full by R7: planned 210 min (150 of tasks plus the 60-minute workout) against 770 free (07:10 to 21:00, minus the workout).

```json
{"allDay":[],"blocks":[{"end":"07:50","id":"t1","kind":"task","min":40,"run":1,"start":"07:10","title":"Fill in visa form"},{"due":"16:00","end":"08:20","id":"t2","kind":"task","min":30,"run":1,"start":"07:50","title":"Book flights"},{"end":"08:25","id":"t3","kind":"task","min":5,"run":1,"start":"08:20","title":"Sign NDA"},{"end":"12:30","fixed":true,"id":"k1","kind":"timedTask","min":15,"start":"12:15","title":"Pick up dry cleaning"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Push B"},{"end":"20:00","fixed":true,"id":"k2","kind":"timedTask","min":30,"start":"19:30","title":"Call mom"}],"cap":3,"light":false,"now":"07:10","weekday":"Fri","window":["07:10","21:00"]}
```

Privacy: pass. Size: 719 chars, **180 tokens**, the largest master-shaped pack.

**Size variant, Fri with a calendar (post M4 slice 1, not possible on master):** the same tasks plus Standup 09:30 to 09:45, Design review 11:00 to 12:00, 1:1 Priya 15:00 to 15:30, Team demo 16:00 to 17:00, and all-day "Ana's birthday". The plan is unchanged (all tasks end by 08:25, and Push B still starts at 17:00). Pack: 1,133 chars, **283 tokens**, the worst size in the run, still under 400.

Tess (shortest first; the run still ends 08:25):

```json
{"blocks":[{"id":"t3","start":"07:10","end":"07:15","lineText":""},{"id":"t2","start":"07:15","end":"07:45","lineText":""},{"id":"t1","start":"07:45","end":"08:25","lineText":""},{"id":"k1","start":"12:15","end":"12:30","lineText":""},{"id":"w1","start":"17:00","end":"18:00","lineText":""},{"id":"k2","start":"19:30","end":"20:00","lineText":""}],
 "startWith":{"id":"t3","line":"NDA first, then flights, then the visa form."},
 "ghostLines":[{"id":"t3","line":"5 min to sign."},{"id":"t2","line":"30 min. Flights booked well before 16:00."},{"id":"t1","line":"40 min on the visa form, done by 08:25."}],
 "note":null}
```

With the calendar variant, the same output plus `"note":"Meetings from 09:30 to 17:00."` (09:30 is e1's start, 17:00 is e4's end). The tempting note "4 meetings, then Push B." fails V11.

### Sat 24 Oct: workout running when he opens the plan (Pull B), cook, groceries

Source: opened 09:20. Pull B started from the routine at 08:40: `Workout.startedAt` 08:40, no `scheduledFor`, no `endedAt`; `ProcessTable.running()` is that workout. Return library book (rolled from Fri 18:30, `rolls` 1, `length` 900). Car wash (`due` Oct 24 00:00, `length` 1800, Oct 21). Cook carbonara (`due` Oct 24 00:00, no `length`, `about` → Recipe, Oct 23). Groceries: 11 open.
Rules (one assumption added): R3 has no case for a started workout. I place it from `startedAt` for 60 min, 08:40 to 09:40, fixed. Tasks go after it: library book, car wash, then the cook at 18:00 (A10). Cap reached; Call grandma is not picked.

```json
{"allDay":[],"blocks":[{"end":"09:40","fixed":true,"id":"w1","kind":"workout","min":60,"start":"08:40","title":"Pull B"},{"end":"09:55","id":"t1","kind":"task","min":15,"run":1,"start":"09:40","title":"Return library book"},{"end":"10:25","id":"t2","kind":"task","min":30,"run":1,"start":"09:55","title":"Car wash"},{"end":"18:45","id":"t3","kind":"task","min":45,"run":2,"start":"18:00","title":"Cook carbonara"}],"cap":3,"light":false,"now":"09:20","weekday":"Sat","window":["09:20","21:00"]}
```

Privacy: pass. No set history or progress from the running workout is sent. Size: 494 chars, **124 tokens**.
Tess:

```json
{"blocks":[{"id":"w1","start":"08:40","end":"09:40","lineText":""},{"id":"t1","start":"09:40","end":"09:55","lineText":""},{"id":"t2","start":"09:55","end":"10:25","lineText":""},{"id":"t3","start":"18:00","end":"18:45","lineText":""}],
 "startWith":{"id":"w1","line":"Pull B until 09:40, then the library book."},
 "ghostLines":[{"id":"t1","line":"15 min, right after Pull B."},{"id":"t2","line":"30 min, then nothing until the carbonara."},{"id":"t3","line":"45 min at 18:00."}],
 "note":null}
```

Why this is the worst day: V5 exempts w1 even though it starts before the window, which is correct. But V8 forces `startWith` onto a workout that is already half done, and the pack can't say so. The most likely model line, "Pull B at 08:40.", passes every check and reads as if he hasn't started. The 09:40 end is a guess from the 60-minute rule, too. Recommended fix: R8 skips a running workout, and the pack marks it `"running":true` (or leaves it out, since Now already shows it).

### Sun 25 Oct: rest day, near-empty

Source: opened 08:30. Water plants (`due` Oct 25 00:00, no `length`, Oct 22). No timed tasks. `WeekDay.isRest` true (new week; trained Saturday). Later still holds Sort the garage (Oct 12) and Recover files from old laptop (Oct 13).
Rules: tier 2 Water plants (30 min default); tier 3 garage, then laptop files.

```json
{"allDay":[],"blocks":[{"end":"09:00","id":"t1","kind":"task","min":30,"run":1,"start":"08:30","title":"Water plants"},{"end":"11:00","id":"t2","kind":"task","min":120,"run":1,"start":"09:00","title":"Sort the garage"},{"end":"11:30","id":"t3","kind":"task","min":30,"run":1,"start":"11:00","title":"Recover files from old laptop"}],"cap":3,"light":false,"now":"08:30","weekday":"Sun","window":["08:30","21:00"]}
```

Privacy: pass on the rule, **fail on the planned test.** The pack holds no Health data, but "Recover files from old laptop" contains "recover", which `RecoveryNeverPacked` (recovery-line.md §6) asserts no pack contains. As written, that test fails on his own task title. Fix: match the W3 values and the exact line strings, or check only fields the builder fills from Health, not free text in titles. Size: 412 chars, **103 tokens**, the smallest.
Tess (the two short ones first, the garage last):

```json
{"blocks":[{"id":"t1","start":"08:30","end":"09:00","lineText":""},{"id":"t3","start":"09:00","end":"09:30","lineText":""},{"id":"t2","start":"09:30","end":"11:30","lineText":""}],
 "startWith":{"id":"t1","line":"Plants first, then the laptop files, then the garage."},
 "ghostLines":[{"id":"t1","line":"30 min, before anything else."},{"id":"t3","line":"30 min with the old laptop."},{"id":"t2","line":"2 hours in the garage, finished by 11:30."}],
 "note":null}
```

V11: "2 hours" passes only through the hour conversion (120 min). V12: if Tess writes "Recover the laptop files", "recover" is exempt as a title word, so the line passes.

## 4. Size summary

| Day | Kind | Blocks | Chars | Tokens (chars/4) | Pack budget 400 | Input total (473 + about 300 + pack) |
|---|---|---|---|---|---|---|
| Mon | Training, timed + untimed | 5 | 627 | 157 | OK | about 930 |
| Tue | Rest, carried, groceries | 4 | 512 | 128 | OK | about 900 |
| Wed | Training, cook | 5 | 621 | 155 | OK | about 930 |
| Thu | Training, light | 4 | 496 | 124 | OK | about 900 |
| Fri | Training, carried, full | 6 | 719 | 180 | OK | about 950 |
| Fri + calendar | Variant, post M4 | 10 + all-day | 1,133 | 283 | OK | about 1,060 |
| Sat | Running workout, cook | 4 | 494 | 124 | OK | about 900 |
| Sun | Rest, near-empty | 3 | 412 | 103 | OK | about 880 |

No pack is over budget. The cap of 3 ghost lines keeps task blocks small, so pack size grows with events, not tasks. Each event adds about 100 chars (25 tokens), so a Friday-sized task load reaches 400 tokens at about 9 events.

## 5. Privacy summary

| Check | Result |
|---|---|
| Health values (sleep, energy, HR, HRV) in any pack | None. Master reads no Health data at all today |
| `light` is a bool only | Yes; true only on Thu |
| W3 recovery line or `RecoveryReading` in any pack | None. The line lives on Now (training days Mon, Wed, Thu, Fri, Sat) and no pack field can carry it |
| Card line ("slept ...") | Never built into the pack |
| `rolls`, `rolledFrom`, old times of rolled tasks | Not sent (Tue, Fri, Sat) |
| Groceries count, recipe links, set history | Not sent |
| UUIDs | None; handles only |
| `RecoveryNeverPacked` substring test | **Fails on Sun** because of a real title, a false positive |
| Health-adjacent titles ("Book flu shot", "Physio", "Order contact lenses") | Sent as titles, which policy allows. Product may want to know these leave the phone |

One bit to own: `light: true` tells Claude "sleep under 6h or energy 2 or less" (R6). `recovery-line.md` §6 asks that `light` never come from the W3 reading; R6's sleep input comes from the same slice 2 HealthKit night, so the bit is Health-derived either way. It is one bool, which policy allows; the source just needs a test.

## 6. Missing fields and mismatches

| # | Gap | Effect on this run | Suggested owner and fix |
|---|---|---|---|
| G1 | No `Event` class | No master pack has `e` blocks or `allDay`; the calendar day is a variant only | M4 slice 1 |
| G2 | No source for `light` | `light` is always false on master; Thu needed an assumed energy check-in | Core: an energy check-in object, or slice 2 sleep reads; one `PlanSignals.light` with a test that it never reads `RecoveryReading` |
| G3 | Seeded plan has no `sessionsPerWeek` | No rest day ever fires (starter-content M2); the run set it to 5 | Core: seed a value; Product: 5 or 6 |
| G4 | Rest days depend on the locale's first weekday (`Calendar.current`, `.weekOfYear`) | en_US gives Tue and Sun rest; Monday-start gives Tue and Thu | Core: pin the week start, or accept it |
| G5 | After `RollForwardTasks`, a rolled task has `startsAt` today and `isCarriedOver` false | The planner must use `rolls >= 1` (A12); `NowRanker` treats it as timed at the old hour, so Now and the plan disagree (Tue) | Core: one "carried" test shared by `TaskList`, `NowRanker` and the planner |
| G6 | `rolls` never resets | A task rolled once and later given a firm time by hand is still flexible to the planner | Core: reset `rolls` (or mark firm) on a user `moveTask` with a time |
| G7 | Due-only tasks never roll (`RollForwardTasks` reads only `startsAt`) | A task due yesterday stays carried with `rolls` 0: not tier 1, not due today, not Later, so it is in no tier | Core: add it to tier 1, or roll `due` too |
| G8 | No scheduled `Workout` outside demo data | The workout block has to come from `WeekDay.planned` as date-only (17:00) | Core: the planner reads `WeekDay`, or the plan makes the day's workout |
| G9 | A running workout has no rule (R3) and no pack field | Sat: the block is guessed from `startedAt` plus 60, and `startWith` lands on it | Core: R3 and R8 cases; T4: `running` flag or leave it out |
| G10 | No rest-day field in the pack | Tess can't word a rest day; fine while Now says it | Product: leave it out (recommended) |
| G11 | Date-only `due` is only a 00:00 convention | Tier 2 sort depends on it | Core: document it or add a flag |
| G12 | Cook length is a flat 45 min | `Recipe.totalMinutes` exists and is not used | Core: use it when set |
| G13 | Pack shape in `tess-model-layer.md` §6 (object ids, free minutes, up to 8 candidates) differs from `plan-my-day-prompt.md` (handles, no free minutes, cap 3) | Builders could follow the wrong table | Research: update §6 to match the prompt pack |
| G14 | `.sortedKeys` also sorts the keys inside blocks, so `id` is not first as the prompt pack's examples show | Only snapshot tests care | T4: snapshot the sorted form |

## 7. Open questions

1. Rest days: seed `sessionsPerWeek` as 5 or 6? With 6 and Sunday-start weeks, Sunday is the only rest day.
2. Should the week start be pinned (Monday) so rest days don't move with the phone's locale?
3. For a workout already running when he opens the plan: leave it out of the pack, or send it with `"running": true` and skip it in R8?
4. Where does `light` come from before Health reads land: an energy check-in, or nothing (always false)?
5. Should `RecoveryNeverPacked` match exact W3 values and line strings instead of substrings like "recover", so his own titles don't fail it?
6. Is it fine that health-adjacent task titles (Physio, Book flu shot) go to Claude as plain titles?
7. Should a skipped tier 3 ghost line touch `updatedAt`? If not, the same oldest Later task comes back every morning.
8. Should a due-only task from yesterday (G7) count as carried (tier 1)?
9. "A running workout" could also mean a run (cardio). Master has no run or distance class for workouts, so this run used a workout in progress. Is a run planned as a routine in the plan?
10. Should the cook line be able to say the recipe's groceries are ready? That needs a readiness field, and V11 bans counts, so it would be a bool.

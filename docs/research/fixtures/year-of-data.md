# Year of data: a deterministic one-person fixture

For: Core engine, QA
Date: 2026-10-15 · Research lab · Read with: `context-packing.md`, `../product/ship-list-m3.md`, `../product/ship-list-m5-money.md`, `../product/ship-list-m5-upkeep.md`, `docs/research/storage-spike.md`, and master at 0c0bfdb.

## 1. What exists on master (so this builds on it)

- **`ScaleTests`** (`TesseraCore/Tests/TesseraCoreTests/ScaleTests.swift`, run by `scripts/test.sh --scale` with `TESSERA_SCALE=1500`). Training only. In memory it builds N workouts (Bench Press plus 4 made-up lifts, 5 sets each, 25 sets a workout, so about 37,500 sets at 1,500), then times `warmUp`, `sessions`, `records`, `nextTarget`, `trend(days: 90)`, `weeklySets`, `month(containing:)` and log-a-set plus `recordsBeaten`. Budgets: 100 / 50 / 100 / 50 / 250 ms, doubled above 1,000 workouts.
- **`OnDiskTests`** (same file). Writes Bench-only workouts through `ActionEngine` (`AddExercise`, 5 `LogSet`, `FinishWorkout`, one save per workout), reopens SQLite cold, checks records, session count and `history` = workouts × 7 ops. Prints `DISK write+save=… open=…`.
- **`PerformanceProbeTests`** (app). `DemoData` plus `schedule()`, `currentTask()`, `tonightWorkout()` under 50 ms per refresh.
- **`DemoData`** (`Features/Demo/DemoData.swift`, `-demo` / `-resetDemo`). Library exercises, a Push / Pull / Legs plan, six weeks of history ending with Legs yesterday, and today (8 timed tasks, Push Day A at +50 min, bench 82.5 kg).
- **Gaps:** nothing covers tasks, notes, lists, kitchen, processes or link density at scale; nothing times launch, context load, Home, scroll or memory; the scale data is not realistic (no deloads, gaps or real progression).

## 2. The generator

`YearOfData(seed:, end:, domains:)` in a new library target `TesseraFixtures` in `TesseraCore/Package.swift` (depends on `TesseraCore`; linked by `TesseraCoreTests` and by the app in Debug only). It writes **only through `ActionEngine`** with `by: .user`, like `OnDiskTests`, so the op log is real. One `context.save()` per simulated day.

- **Window.** 2025-10-15 to 2026-10-14, 365 days. "Today" is 2026-10-15, and `DemoData.seedToday` runs on top, so `-demoTime 18:10` looks the same as now. Calendar: Gregorian, Monday first, `TimeZone(identifier: "Europe/London")`, so two DST changes (2025-10-26, 2026-03-29) fall inside.
- **Seed scheme.** Base seed `20261015`. Each domain gets its own SplitMix64 stream seeded with `base ^ fnv1a64(domainName)` (not `Hasher`, which is random per process). Each day draws from `stream ^ dayIndex`. So adding a domain, or changing one, never shifts the others.
- **Time.** Ids are UUIDv7 and `createdAt` / `updatedAt` use `.now` on master. After each day the generator stamps `createdAt`, `updatedAt` and op `createdAt` to the simulated time (all are settable). Ids stay random, so determinism is checked by a **content digest**: SHA-256 over sorted (class key, title, values JSON, parent path, link targets by path, op action + payload), ids left out.
- **Reuse.** Routine names, library keys and lift weights come from `DemoData` (Push Day A, Pull Day A, Leg Day A, `benchPress`, `overheadPress`, `inclineDbPress`, …). The last six weeks land where DemoData's do: bench ends at 82.5 kg × 8, Legs on 2026-10-14. Later, DemoData's `seedHistory` can become `YearOfData(weeks: 6)`, not in the first slice.
- **Oracle.** As it generates, the generator records what it meant: every PR per lift, sessions per month, open tasks, the Groceries count today. Tests compare the engine's answers with it.

## 3. What one year contains

- **Training, PPL × 2.** Push A, Pull A, Legs A, Push B, Pull B, Legs B, Mon to Sat, Sunday rest; 07:15 on weekdays or 18:00 (35%). Plan 1 runs Oct to Mar, Plan 2 Apr to Oct (`CreatePlan`, 6 `SwapSlotExercise`). Double progression per slot: reps climb from `repMin` to `repMax`, then +2.5 kg upper or +5 kg lower. Start: bench 70, squat 90, deadlift 120, OHP 42.5 kg. A bad day (10%) loses 1 to 2 reps. Cut Jan to Apr: reps climb half as often. **Deloads** every sixth training week: 60% load, 2 sets, never a PR. **Missed weeks:** 2025-12-22 (Christmas), 2026-03-02 (sick), 2026-08-10 (holiday); back at -5%. Plus 8% single skipped sessions and one workout left suspended at set 3 (2026-09-30). Warm-ups: 2 on the first compound. Expect about 18 e1RM PRs per main lift.
- **Tasks.** 0 to 9 a day, mean 4. 80% done the same day, 12% roll (1 to 5 nights, `rolledFrom`, `rolls`), 5% deleted, 3% still open (about 15 carried into today). 10% link a recipe (`about`). 200 started (`StartTask`), 30 waiting (`WaitOnTask`).
- **Notes.** On 60% of days, 1 to 3; 40 to 1,200 characters; 30% with `@` links (`about`). 150 later edited.
- **Groceries and lists.** The one Groceries list (`Groceries.listID`). Two shops a week, about 14 items each (85% link an `Ingredient`), checked in a `StartShop` / `FinishShop` run, then `ClearDoneItems`. Nine items open today, so the Shop offer gate (≥ 8) fires in the evening. Plus six other lists (packing, gifts) with 20 items each.
- **Recipes and cooks.** 40 recipes (start from `../product/kitchen-seed-recipes.md`), about 9 lines and 6 steps each. 3.5 cooks a week with `GoToCookStep` and 1.5 kitchen timers each; 100 recipes added to Groceries.
- **Habits and check-ins** *(not on master)*. Train 3×/week (rule: counts finished workouts), Read 5×, Meditate 4×, Stretch 3×, Phone out of bed 5×. Manual check-ins about 3.2 a week per habit.
- **Chores and upkeep** *(not on master)*. 12 chores: plants 7 d, laundry 4, bins 7, sheets 14, hoover 7, bathroom 10, fridge 30, car tyres 30, kettle 60, smoke alarm 180, gutters 180, boiler 365. Done at 90% adherence with 30 "fine", 40 snoozes, and `PauseChores` over the August holiday.
- **Spends** *(not on master)*. 2.2 a day, mostly unmarked currency, EUR during the holiday, plus a shop total after 92 of 100 shops (8 skipped).
- **Body weight** *(not on master)*. 85% of days, 07:00. Trend 82.0 to 78.5 kg (cut Jan to Apr), then up to 80.0; noise ±0.6 kg, a few +1 kg salty days, 10 same-day replacements.

## 4. Counts per class (± 3% by seed)

| Class (key on master) | Objects | Links | Op log rows (actions) |
|---|---:|---:|---:|
| `workout`, `exerciseEntry`, `set` | 271 / 1,355 / 4,450 | 2,980 (routine, exercise, slot) | 5,080 (`StartRoutine`, `LogSet`, `LogNextSet`, `EditSet`, `FinishWorkout`) |
| `plan`, `routine`, `slot` | 2 / 6 / 30 | 42 | 50 (`CreatePlan`, `AddSlot`, `EditSlot`, `SwapSlotExercise`) |
| `process` (workout, shop, cook, task) | 720 | 720 (subject) | 400 (`SuspendProcess`, `ResumeProcess`, `EndProcess`) |
| `task` | 1,460 (70 deleted) | 150 (about) | 3,350 (`CreateTask`, `SetTaskDone`, `MoveTask`, `RollForwardTasks`, `StartTask`, `WaitOnTask`, `DeleteObject`) |
| `note` | 350 | 160 (about) | 500 (`CreateNote`, `EditNote`) |
| `list`, `listItem` | 7 / 1,520 | 1,190 (about) | 2,450 (`AddGroceries`, `AddRecipeToGroceries`, `AddListItem`, `CheckListItem`, `StartShop`, `FinishShop`, `ClearDoneItems`, `CreateList`) |
| `ingredient`, `recipe`, `recipeLine`, `recipeStep` | 180 / 40 / 360 / 240 | 720 | 70 (`CreateRecipe`, `EditRecipe`) |
| `cook`, `kitchenTimer` | 180 / 270 | 450 | 1,620 (`StartCooking`, `GoToCookStep`, `StartKitchenTimer`, `StopKitchenTimer`, `FinishCooking`) |
| Library (muscles, equipment, exercise class objects) | about 130 | about 250 | 0 (installed, not logged) |
| **Master subtotal** | **about 11,560** | **about 6,660** | **about 13,520** |
| `Habit` *(not on master, M3 slice 2)* | 5 | 0 | 5 |
| Check-in *(not on master; class name not fixed, habit and chore check-ins)* | 1,005 | 1,005 (habit) | 1,040 (check-in action, name not fixed; `DoChore`, `ChoreFine`) |
| `Chore` *(not on master, M5 upkeep)* | 12 | 0 | 55 (`AddChore`, `SnoozeChore`, `PauseChores`, `ResumeChores`) |
| `Spend` *(not on master, M5 money)* | 900 | 200 (shop, Groceries) | 930 (`LogSpend`, `LogShopTotal`, `SkipShopTotal`, `EditSpend`) |
| `BodyWeight` *(not on master, M3 slice 1)* | 310 | 0 | 320 (log action, name not fixed) |
| **Total** | **about 13,800** | **about 7,870** | **about 15,870** |

For scale: this is 30% of the storage spike's objects (46,500) but twice its links per object and with a real op log. **Expected SQLite size: 12 to 16 MB** after `PRAGMA wal_checkpoint(TRUNCATE)`. Working: the spike's 20.3 MB / 46,500 objects is about 440 B per object with indexes, so 6.1 MB, plus 0.5 MB of note and recipe text, 1.2 MB of links (four indexes), and about 400 B per op row, 6.4 MB. The op row size is a guess: the first run prints `page_count × page_size` per table and replaces it. Fail above 25 MB. `--scale` can run `years: 5` (about 69,000 objects, 79,000 ops, 60 to 80 MB).

## 5. What to measure, targets and how

Device numbers are on an iPhone 17 class phone, Release build. Package numbers are `swift test` on the Mac (Debug, like `ScaleTests`), so they get looser budgets.

| Measure | Target (device) | Package budget (Mac) | How |
|---|---|---|---|
| Cold launch to first frame | ≤ 400 ms p50, ≤ 600 ms p95 | n/a | `XCTApplicationLaunchMetric` in `measure(metrics:)`, 5 runs; `os_signpost` interval `launch` from `TesseraApp.init` to `RootView` first `onAppear`; Instruments App Launch template |
| Load the context (`TesseraContext.load`: snapshot read + build) | ≤ 120 ms | ≤ 150 ms | Signpost `context.load` around `load()`; a package test reopens the fixture file with `ContinuousClock` |
| Home ranker (gather signals + `rank`) | ≤ 2 ms p95, hard cap 5 ms | ≤ 5 ms | Signpost `home.rank`; package test runs 200 ranks at 20 pinned times. Signals must not scan all 1,460 tasks or 15,870 ops: the newest `.user` op is one lookup. Until `rank` lands (context-packing slice 1), time `NowPicker.pick` + `ProcessTable.ledger` + `AppModel.schedule` |
| `TrainingLedger.warmUp` (index build) | ≤ 60 ms, off main | ≤ 100 ms | Existing `ScaleTests` timing, on the fixture |
| PRs: `records`, `recordsBeaten`, `nextTarget` | ≤ 5 ms each | ≤ 20 ms | Same; plus the oracle check |
| Trends: `trend(days: 90)`, `trend(days: 365)`, `weeklySetsPerMuscle` | ≤ 8 ms | ≤ 20 ms | Same |
| Log a set, save, PR hint | ≤ 16 ms | ≤ 50 ms | `LogSet` + save + `recordsBeaten` (the spike's 13.6 ms is the floor) |
| Plans month view (`PlanData.month` + `monthCounts`, then the page) | Data ≤ 4 ms; page in with 0 hitches | ≤ 10 ms data | Signpost `plans.month`; SwiftUI Instruments template (body updates, long view bodies) |
| Scroll: workout history, notes, a month of spends, Groceries | Hitch ratio < 5 ms/s (Apple's "good") at 120 Hz; no frame > 25 ms | n/a | `XCTOSSignpostMetric.scrollingAndDecelerationMetric` on a swipe-up UI test; Instruments Animation Hitches |
| Memory | Home idle ≤ 120 MB footprint; context ≤ 40 MB of it; < 2 MB growth after 10 history open and close cycles | n/a | `XCTMemoryMetric`; `phys_footprint` logged at the `context.load` signpost end; Instruments Allocations and Leaks |
| SQLite size | 12 to 16 MB | same | File size after checkpoint, printed as `YEAR … size=` |

Signposts use one `OSSignposter(subsystem: "com.kaushikaranagu.tessera", category: "perf")`, so the same intervals show in Instruments and in `XCTOSSignpostMetric`. The device rows need a `TesseraUITests` target (XCTest; not on master) in `project.yml`, and a DEBUG launch argument `-yearOfData` that wipes like `-resetDemo`, runs the generator, then `DemoData.seedToday`. It caches the built file in Caches by seed and generator version, so later launches only copy it.

## 6. Smallest Core slice and done-when tests

**Slice:** `TesseraFixtures` with the master domains only (training, plans, processes, tasks, notes, lists and Groceries, recipes, cooks). Each unbuilt domain (habits and check-ins, chores, spends, body weight) is a `FixtureDomain` added in the same PR as its class, with its own stream. New file `YearOfDataTests.swift` beside `ScaleTests`; `scripts/test.sh --scale` adds `YearOfDataTests` to its `--filter` and greps `YEAR`. No app or UI work in this slice.

Done when:
1. **Deterministic.** Two runs with seed 20261015 give the same digest; seed 20261016 gives a different one; removing the notes domain leaves the training digest unchanged.
2. **Counts.** Objects, links and ops per class fall within ± 3% of the master rows in section 4.
3. **PR oracle.** `records(for:)` on bench, squat, deadlift and OHP equals the generator's last PR; no PR falls in a deload week; `recordsBeaten` is empty for every deload set.
4. **Calendar oracle.** `month(containing:)` for March 2026 shows the sick week as empty; weekly sets for the Christmas week are 0; nothing breaks across the two DST changes.
5. **Invariants.** No dangling links; every finished workout has `endedAt`; every rolled task has `rolledFrom` and `rolls` > 0; deleted rows have `deletedAt`; the Groceries list has id `Groceries.listID` and 9 open items; about 15 carried-over tasks today.
6. **Round trip.** Written to SQLite with one save per day, reopened cold: same digest, `history` count equals the op count, and the size line prints and is ≤ 25 MB.
7. **Budgets.** The package budgets in section 5 pass for context load, ranker (or the `NowPicker` stand-in), warm-up, PRs, trends, log a set and the month data, and `YEAR` prints each timing. The existing `ScaleTests` and `OnDiskTests` budgets still pass unchanged.

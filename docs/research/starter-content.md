# Starter content on a fresh install

For: Core, Builder A. Board item 25. 2026-10-16. Research lab.
Checked against `origin/master` at `11f4648`, read by hand (no Swift toolchain here).

## Where seeding happens

One call at launch, `ObjectStore.prepareCatalog()` (`TesseraCore/Sources/TesseraCore/Engine/ObjectStore+Lifecycle.swift:16-22`), from `App/AppModel.swift:85`. It runs four steps, in order:

1. `SystemCatalog.seed` (built-in classes and fields)
2. `ExerciseLibraryInstaller.installIfNeeded` (muscles, equipment objects, exercise classes)
3. `StarterContent.installIfNeeded` (gym kit values and the PPL x2 plan)
4. `Groceries.installIfNeeded` (the one Groceries list)

`resetUserData()` (`:53-69`) runs the same steps again after a wipe, so a reset looks like a fresh install.

Demo data is separate and only runs with a flag: `App/TesseraApp.swift:29-31` calls `DemoData.prepare` only for `-demo` or `-resetDemo`.

## What a fresh install seeds

### 1. SystemCatalog: the system package

`TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift`, package `system` version 3 (`:284`). Ids come from `stableID("system.<key>")`, so every install gets the same ids.

There are 25 classes (`:12-20`, specs `:51-280`):

| Class | Parent | Fields (defaults in brackets) |
|---|---|---|
| Thing | none | notes |
| Muscle | Thing | group, weeklySetsMin (10), weeklySetsMax (20) |
| Equipment | Thing | kind, barWeight (kg), plates, loads, increment (kg) |
| Activity | Thing | none |
| Exercise | Activity | primaryMuscles, secondaryMuscles, equipment, restSeconds (90 s), repMin (8), repMax (12), progression, variantOf, pattern, family, mechanic, logType, aliases |
| Strength Exercise | Exercise | restSeconds override (120 s) |
| Barbell Lift | Strength Exercise | restSeconds override (180 s), progression override `dp(+2.5, 8, 12)` |
| Bench Press | Barbell Lift | none (the library moves it under Horizontal Push) |
| Workout | Activity | scheduledFor, startedAt, endedAt, routine |
| Exercise Entry | Thing | exercise, targetSets, targetReps, targetWeight (kg), slot, skipped |
| Set | Thing | weight (kg), reps, rpe, isWarmup (false), kind (working), source, loggedAt, enteredUnit, e1rm (computed), volume (computed) |
| Routine | Thing | cadence (week) |
| Slot | Thing | exercise, sets (3), repMin, repMax, targetRPE, restSeconds, progression |
| Plan | Thing | routines, startsOn, weeks, sessionsPerWeek |
| Task | Thing | startsAt, length, due, isDone (false), doneAt, rolledFrom, rolls, about |
| Note | Thing | body, about |
| List | Thing | none |
| List Item | Thing | quantity, isDone (false), checkedAt, section, about, shares |
| Ingredient | Thing | aisle, isStaple (false) |
| Recipe | Thing | serves, activeMinutes, totalMinutes, sourceText |
| Recipe Line | Thing | amount, amountMax, unit, prep, toTaste, original, ingredient |
| Recipe Step | Thing | text, timers, about |
| Cook | Thing | recipe, serves, cookedAt, note |
| Kitchen Timer | Thing | startedAt, endsAt, minutes, isStopped, cook |
| Process | Thing | subject, ownerApp, state (running), resumePoint, nextStep, startedAt, lastTouchedAt, waitingOn, checkAt, endedAt, endReason |

Every mass field carries the unit `kg`, and the Set comment (`:156`) says weight is always stored in kg.

**Views:** none. `SystemCatalog` seeds no `ViewDef`. The only `ViewDef(` on master is the legacy reader at `TesseraCore/Sources/TesseraCore/Model/TesseraDatabaseSchema.swift:228`.

### 2. Exercise library

`ExerciseLibraryInstaller.swift`, package `library` version 1, shape `.patternSpine` (`:26`, Kaushik's pick).

- **18 muscles** as Muscle objects (`MuscleLibrary.swift`, `ExerciseSeed.swift:4-38`), in six groups: Chest, Shoulders, Arms, Back, Core and Legs.
- **72 exercise classes** (`ExerciseLibrary.swift`). The docs say 69, so the count has grown since `workouts.md:117`. By pattern they are: horizontal push 10, vertical push 5, horizontal pull 7, vertical pull 6, squat 6, lunge 4, hinge 9, carry 1, isolation 19, core 5.
- **10 pattern classes** (`library.pattern.*`), plus **14 group classes** under them for isolation and core moves (Curl, Lateral Raise, Calf Raise and the rest).
- Each exercise gets a class object holding its rep range, rest, pattern, family, mechanic, logType, aliases, a cue in notes, its muscles and its equipment link (`:77-92`). Variants are linked with `variantOf`.
- The equipment trait goes on the class (`equipment.barbell` and so on, plus `unilateral`).

### 3. Equipment

There are **9 Equipment objects**, one per `EquipmentKind` (`ExerciseLibraryInstaller.swift:132-165`): Barbell, Dumbbells, EZ Bar, Cable Stack, Machine, Smith Machine, Kettlebells, Bodyweight and Bands. No library exercise uses Bands.

`StarterContent.configureEquipment` (`StarterContent.swift:97-114`) then fills in the kit:

| Equipment | Seeded values |
|---|---|
| Barbell, Smith Machine | barWeight 20 kg, plates "25, 20, 15, 10, 5, 2.5, 1.25" |
| EZ Bar | barWeight 10 kg, same plates |
| Dumbbells | loads 2 to 50 kg in 2 kg steps (`:61`) |
| Cable, Machine, Kettlebells, Bodyweight, Bands | nothing. They fall back to `LoadProfile.swift:94-107`: 5 kg steps for cable and machine, the built-in mixed rack for kettlebells, and 2.5 kg steps for the rest |

### 4. The PPL x2 plan

`StarterContent.swift:14-57` and `:69-94`. The plan is called "Push Pull Legs", with id `starter.plan.ppl2`. It links six routines in this order:

| Routine | Slots (sets x reps) |
|---|---|
| Push A | Bench Press 4x5-8, Overhead Press 3x6-10, Incline DB Press 3x8-12, DB Lateral Raise 3x12-15, Rope Pushdown 3x10-15 |
| Pull A | Barbell Row 4x6-10, Lat Pulldown 3x8-12, Seated Cable Row 3x10-12, Face Pull 3x12-15, DB Curl 3x10-12 |
| Legs A | Back Squat 4x5-8, Romanian Deadlift 3x6-10, Leg Press 3x10-12, Lying Leg Curl 3x10-15, Standing Calf Raise 4x10-15 |
| Push B | Overhead Press 4x5-8, DB Bench Press 3x8-12, Dip 3x8-12, Cable Lateral Raise 3x12-15, Overhead Cable Extension 3x10-15 |
| Pull B | Pull-Up 4x5-10, One-Arm DB Row 3x8-12, Chest-Supported Row 3x10-12, Reverse Pec Deck 3x12-15, Hammer Curl 3x10-12 |
| Legs B | Deadlift 3x3-6, Front Squat 3x6-10, Bulgarian Split Squat 3x8-12, Leg Extension 3x12-15, Seated Calf Raise 4x12-15 |

All 30 slot keys exist in the library. The loop at `:79-80` would skip a missing key silently, but none are missing today.

The plan sets only `routines`. It leaves `startsOn`, `weeks` and `sessionsPerWeek` empty, and the slots have no rest, RPE or progression of their own.

### 5. Lists

There is one list: **Groceries**, with id `kitchen.groceries` (`Kitchen/Groceries.swift:24-28`). It starts empty.

### 6. Default settings

Nothing is stored. There are no `@AppStorage` keys, and the only `UserDefaults` use is the backup folder bookmark and a launch note. The defaults live in code:

- Unit: kg. `Format.unit = .kilograms` (`App/AppClock.swift:36`) is a static, not a setting, and its comment says "kg until Kaushik picks". The grammar also falls back to kg (`TessGrammar.swift:229,313`).
- Theme: `ThemeConcept.plein` (`DesignSystem/Theme.swift:240`). It can be changed only with `-theme`.
- Font: Inter Tight, bundled (`DesignSystem/FontRegistry.swift:11`).
- Auto-finish: `wrapUpWorkout = 6 * 3600` (`TesseraCore/.../Processes/ProcessTable.swift:14`).
- Other process timings: suspended work leaves Home after 3 days (`:10`) and goes to Later after 7 days (`:12`).
- Progression by equipment (`Training/Progression.swift:81-83`): barbell +2.5 kg, dumbbell and kettlebell +2 kg, machine and cable +5 kg.
- Backups: no folder until he picks one (`Features/Backup/BackupKeeper.swift`). This matches the decision.

### Seeded only under a flag (never on his phone)

| Flag | What it seeds | Where |
|---|---|---|
| `-demo`, `-resetDemo` | A second Push / Pull / Legs plan (Push Day A, Pull Day A, Leg Day A), six weeks of finished workouts, today's schedule and tonight's workout | `Features/Demo/DemoData.swift:4-5`, `:42-162` |
| `-demoKitchen` (DEBUG) | Carbonara and dal recipes on Groceries, plus milk, 2 lemons, sourdough and kitchen roll | `Features/Groceries/GroceriesView.swift:746-757` |
| `-demoNotes`, `-demoReview` | Demo notes and a demo Review | `Features/Notes/NotesView.swift:33`, `Features/Review/ReviewView.swift:293` |

The starter plan wins over the demo plan, because `AppModel.swift:502` picks `StarterContent.planID` first.

## Check against the decisions

The kit, unit, missed-day and auto-finish rules are not in `product/decisions.md`. They are in `product/morning-questions.md:7-10` (Kaushik, 2026-10-15) and are repeated in `ship-list.md:11` and `workouts.md:3`. `decisions.md:139-142` adds the creation-day count and "the PPL x2 starter plan stays".

| Rule | Source | Master | Verdict |
|---|---|---|---|
| kg is the default | morning-questions 1 | `AppClock.swift:36`, every mass field is in kg | Match |
| 20 kg bar | morning-questions 2 | `StarterContent.swift:102` | Match |
| 1.25 kg smallest plate | morning-questions 2 | `StarterContent.swift:60`, so the smallest jump is 2.5 kg | Match, but see M3 |
| Dumbbells in 2 kg steps | morning-questions 2 | `StarterContent.swift:61`, 2 to 50 kg | Match |
| PPL x2 plan | morning-questions 2, decisions:142 | Six routines, A and B | Match |
| A missed day rolls on | morning-questions 3, decisions:63 | `PlanSchedule.swift:3-21`, the next routine comes after the last finished one, with no dates | Match |
| 6 h auto-finish | morning-questions 4 | `ProcessTable.swift:14` | Match |
| Equipment is a trait on the pattern tree | morning-questions 5 | `ExerciseLibraryInstaller.swift:26,67-73` | Match |
| Plan targets count from the creation day | decisions:139 | Counts use the whole month | **Mismatch, M1** |
| On a planned rest day, rest wins on Now | decisions:63,72 | The seeded plan has no rhythm, so the engine never finds a rest day | **Mismatch, M2** |
| A workout with zero sets is not saved | decisions:138 | Not a seeding item | Out of scope |
| Upkeep starters are never seeded silently | decisions:116, `fixtures/upkeep-starters.md:5` | There is no Upkeep code on master, so nothing is seeded | Match for now, see G2 |

## Mismatches

**M1. "Session 1 of 26" on a mid-October install.** Owners: Builder A for the count, Core for the seed.
- **What master does:** `Features/Plans/MonthPage.swift:17-19` calls `PlanRhythm.perMonth` (`Features/Plans/PlanDigest.swift:127-129`) with every day of the month. The rhythm is 6 a week (`PlanDigest.swift:121-124`, from `PlanData.swift:22`), so a fresh install on 16 October reads "26 sessions planned", then "Session 1 of 26". Research already found this: `research/empty-states.md:96` (Month row) and `:155` (Week "0 of 6"). It is not repeated here.
- **What it should do:** count from the plan's creation day, so a plan made on 16 October reads "Session 1 of 13".
- **The seed's part:** `StarterContent.swift:90-92` never sets `startsOn`, so the UI has nothing to count from except `createdAt`. Core should set `startsOn` to the install day. Builder A should count from `max(month start, startsOn)`.
- **Second copy:** Core's own `TrainingLedger.monthCounts` (`Training/PlanSchedule.swift:69-78`) also counts the whole month. It rounds to the nearest, which gives 27 for October, while the UI rounds down to 26. Only tests call it today. It should get the same rule, or be removed so there is only one count.
- **No old date:** nothing in the seed writes a past date (no `scheduledFor`, no `startsOn`), so that half of the rule holds.

**M2. The seeded plan has no weekly rhythm, so a rest day can never fire.** Owner: Core.
- **What master does:** `StarterContent.swift:90-92` leaves `sessionsPerWeek` empty. `RestDay.swift:17-19` returns nil for a plan without a rhythm. `WeekView.swift:46-48` then gives every day ahead the next routine. Meanwhile the Plans page invents 6 a week from the cycle length (`PlanDigest.swift:121-124`). So the Week page header says "of 6" while the engine's week has 7 training days, and the 3:37 PM rest-day rule has nothing to act on. No app code calls `NowPicker` or `restDay` yet, so this does not show until Now is wired.
- **What it should do:** seed `sessionsPerWeek = 6` on the starter plan. Then the engine and the page agree, and `PlanRhythm.perWeek` is only a fallback.

**M3. The seeded plates cap the barbell at 177.5 kg.** Owner: Core.
- **What master does:** `StarterContent.swift:60` lists each plate once, and `PlateLoad` (`Training/LoadProfile.swift:28-44`) reads that as one pair of each. The heaviest load is 20 + 2 x 78.75 = 177.5 kg (167.5 kg on the EZ bar). Past that, `nearest(to:)` snaps back down, so the dial and double progression on Deadlift stop at 177.5. The built-in default (`LoadProfile.swift:31`) is more generous than the seed, because it has two pairs each of 5, 2.5 and 1.25.
- **What it should do:** list real pairs, for example several 20s and 25s. Or teach `PlateLoad` that a listed plate means "as many as needed". The 1.25 kg step is right either way.

## Content that should be seeded and is not

None of these are in `decisions.md`, but Product docs say they should be seeded.

- **G1. Starter lists.** `product/starter-lists.md` says to install Gym bag, Leaving the house and Packing as reusable lists, deletable and never reinstalled once deleted. Master seeds only Groceries. `git grep "Gym bag"` finds nothing, and Packing exists only in tests. Owner: Core, next to `Groceries.installIfNeeded`.
- **G1b. Ten seed recipes.** `product/kitchen-seed-recipes.md` says to install them "like the PPL plan". Master has only the two DEBUG demo recipes. Owner: Core.

## Seeded silently where a decision wants him to pick

- **G2. Upkeep.** Nothing is seeded today, which is correct. When Upkeep lands, it must offer the 25 starters as a first-run pick list (12 plus "more"), never through `prepareCatalog` (`fixtures/upkeep-starters.md:5`, decisions:116-118). It is worth a test that `prepareCatalog` creates no Chore objects.
- **Unit.** kg is hard-coded, not a choice he made in the app. That is fine, because he chose kg in morning-questions 1. But `AppClock.swift:35` still says "until Kaushik picks", and there is nowhere to change it.
- **The plan, kit and Groceries list** are silent by design (ship-list item 1, decisions:142). This is allowed.

## Open questions

1. Does Kaushik lift more than 177.5 kg on any barbell lift (deadlift, squat)? If so, M3 is a day-one bug, not a later one.
2. For M1, should the count start at `startsOn` (which needs Core to seed it) or at the plan object's `createdAt`? `startsOn` survives an edit or a copy. `createdAt` needs no seed change.
3. M2: should the starter plan say 6 a week? Or should `PlanRhythm.perWeek` move into Core, so that the engine and the Plans page share one fallback?
4. Should the starter lists and the ten seed recipes go in `prepareCatalog` now, or wait for a first-run pick, as Upkeep does? They are written as silent installs, but the Upkeep rule suggests he may want to choose.
5. Cable, machine and kettlebell have no seeded loads, so they use 5 kg steps and a mixed 2 and 2.5 kg rack. Is that close enough to his gym, or should the kit decision cover them?
6. The library now has 72 exercises, while `workouts.md:117` says 69. Should the doc be updated?

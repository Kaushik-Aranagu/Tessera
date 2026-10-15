# M3 slices 1 and 2: body weight and habits, engine brief

For: Core engine. Date: 2026-10-15. Research lab.
Inputs: `../product/ship-list-m3.md` (slices 1, 2), `body-weight-trend.md`, `habits.md`, `grammar-collisions.md`, `fixtures/spoken-normaliser.md`, and repo `origin/master` at `e56c15e`.

## What exists on master today

- **`BodyWeight`: no Swift code.** The name is only in docs (`app-from-a-sentence.md`, `questions-eval.md`, `calendar-health-fixtures.md`, `year-of-data.md`). The "bodyweight" hits in Swift are exercise equipment and `logType: .bodyweightPlus`, not a class.
- **`logBodyWeight`: gone.** It was a name in `TessToolCatalog.allowed` (`TessModelCapture.swift:86`) with no registered action behind it. Commit `e0f476a` (T2 shared tools) removed it. Today's model tools are `logSet`, `createTask`, `completeTask`, `rescheduleTask`, `addGroceries`, `addToList`, `createList`, `createNote`, `createRecipe`, `startShop` and `answerQuery`. `spoken-normaliser.md` note 13 and rows 24 and 25 are stale on this point.
- **`Habit`: no Swift code.** No `habit` or `habitCheckIn` in `SystemCatalog.Key`. Docs only.
- **`TessGrammar` exists** (`TesseraCore/Sources/TesseraTess/TessGrammar.swift`, `+Kitchen.swift`). Order in `parse`: note, pasted recipe, question guard (`isQuestion`), process in front (`parseForProcess`, using `TessContext.process`), relative set (only with an entry in focus), comma sets, lift, kitchen, reschedule, task. It has no body-weight, habit or reading rule. Several `grammar-collisions.md` rows are fixed since its read (question guard, rest timer in a workout, reschedule).
- Useful pieces: `FieldKind` has `.mass` (stored kg), `.date`, `.choice`, `.ref`, `.text`. `ClassTrait` has `.trackable` and `.measurable`. `MassUnit` parses kg and lb. Actions are `EngineAction` structs registered in `ActionRegistry`.

## 1. Data shapes (SystemCatalog style)

Add `bodyWeight, habit, habitCheckIn` to `SystemCatalog.Key`. Habit before habitCheckIn (link targets first).

```swift
ClassSpec(key: .bodyWeight, name: "Body Weight", parent: .thing, symbol: "scalemass", colorRole: "health",
          traits: [.trackable, .measurable], fields: [
              FieldSpec(key: "weight", name: "Weight", kind: .mass, unit: "kg"),
              FieldSpec(key: "loggedAt", name: "Logged", kind: .date),
              FieldSpec(key: "enteredUnit", name: "Entered in", kind: .choice,
                        options: MassUnit.allCases.map(\.rawValue)),
          ]),
// The name is the record's title, like Task and List.
ClassSpec(key: .habit, name: "Habit", parent: .thing, symbol: "circle.dotted", colorRole: "planning", fields: [
    FieldSpec(key: "target", name: "Times a week", kind: .number, defaultValue: .number(3)),
    // Optional: the class whose finished objects count ("workout" or "cook"). Nil means manual only.
    FieldSpec(key: "rule", name: "Counts when finished", kind: .choice, options: ["workout", "cook"]),
    // Monday dates of paused weeks, "2026-10-05, 2026-11-02" (the `plates` text pattern).
    FieldSpec(key: "pausedWeeks", name: "Paused weeks", kind: .text),
]),
ClassSpec(key: .habitCheckIn, name: "Habit Check-in", parent: .thing, symbol: "checkmark", colorRole: "planning",
          fields: [
              FieldSpec(key: "habit", name: "Habit", kind: .ref, target: .habit),
              FieldSpec(key: "date", name: "Date", kind: .date),
          ]),
```

- **Not stored:** the trend, the weekly rate, the day of an entry (derived from `loggedAt` in the local calendar), any count, and rule check-ins. Rule check-ins are a query over `Workout.endedAt` or `Cook.cookedAt`, so a check-in has no `source` field in v1.
- **Actions** (all undoable through the op log): `LogBodyWeight(kg, unit, at)` updates that day's entry if one exists (one op, so undo puts the old value back), else creates one. `CreateHabit(name, target, rule?)`, `CheckInHabit(habit, at)`, `PauseHabitWeek(habit, monday)`, and `DeleteObject` for undo.
- **Ledgers** (computed on read, `TrainingLedger` style): `BodyWeightLedger.trend()`, `rate(perWeek:)`. `HabitLedger.count(week)`, `isMet(week)`, `lastWeeks(n)` (paused weeks left out), `lastDays(7)`. Later: `attachedTo`, HealthKit merge.

## 2. Body-weight fixture (30 rows)

Method from `body-weight-trend.md`: EWMA with alpha 0.1 per day. `g` = days since the last counted day, `a = 1 - 0.9^g`, `T = T_prev + a * clamp(W - T_prev, -2, +2)`, reseed when g > 30, seed = first weight. Last entry of a day wins. Computed in full precision by a Python script outside the shared folder, shown to 1 decimal (no value sits near a rounding edge). Dates are 2026, local time.

| # | Date | Time | kg | Trend | Note |
|---|---|---|---|---|---|
| 1 | 09-03 | 07:05 | 79.4 | 79.4 | seed |
| 2 | 09-04 | 07:10 | 79.8 | 79.4 | |
| 3 | 09-05 | 07:02 | 79.1 | 79.4 | |
| 4 | 09-07 | 07:20 | 79.3 | 79.4 | g=2 |
| 5 | 09-08 | 07:04 | 79.0 | 79.3 | |
| 6 | 09-09 | 07:15 | 79.6 | 79.4 | |
| 7 | 09-10 | 07:01 | 79.2 | 79.4 | |
| 8 | 09-12 | 08:30 | 78.9 | 79.3 | g=2 |
| 9 | 09-13 | 07:00 | 79.1 | 79.3 | |
| 10 | 09-14 | 07:12 | 78.8 | 79.2 | |
| 11 | 09-15 | 07:06 | 79.0 | 79.2 | |
| 12 | 09-16 | 07:03 | 87.4 | 79.4 | typo for 78.4: step capped at +2 |
| 13 | 09-17 | 07:09 | 78.7 | 79.3 | |
| 14 | 09-18 | 07:11 | 78.9 | 79.3 | |
| 15 | 09-21 | 07:05 | 78.6 | 79.1 | g=3 |
| 16 | 09-22 | 07:02 | 78.9 | (none) | replaced by row 17 |
| 17 | 09-22 | 07:40 | 78.5 | 79.0 | |
| 18 | 09-23 | 07:08 | 78.8 | 79.0 | |
| 19 | 09-24 | 07:00 | 78.4 | 78.9 | |
| 20 | 09-26 | 09:10 | 78.7 | 78.9 | g=2 |
| 21 | 09-28 | 07:03 | 78.3 | 78.8 | g=2 |
| 22 | 09-29 | 07:06 | 78.6 | 78.8 | |
| 23 | 09-30 | 07:01 | 78.2 | 78.7 | |
| 24 | 10-02 | 07:14 | 78.5 | 78.7 | g=2 |
| 25 | 10-05 | 07:02 | 78.1 | 78.5 | g=3 |
| 26 | 10-06 | 07:07 | 78.4 | 78.5 | |
| 27 | 10-08 | 07:05 | 78.0 | 78.4 | g=2 |
| 28 | 10-10 | 08:45 | 78.3 | 78.4 | g=2 |
| 29 | 10-13 | 07:04 | 77.9 | 78.3 | g=3 |
| 30 | 10-14 | 07:01 | 78.1 | 78.2 | |

- Row 12 without the cap would give 80.0. The raw 87.4 is kept. At capture the feedback reads "87.4 kg, 8.2 kg above trend" (more than 3 kg off), with no warning colour.
- Rate on 10-14: trend now minus the trend carried on 10-07 is -0.26, shown as "0.3 kg less than last week".
- Deleting row 17 brings back row 16 (78.9) for 09-22, and the series is recomputed from the first day.

## 3. Habit check-in fixture (20 rows)

Habits: **Read** (target 5, manual, week of 10-05 paused) and **Train** (target 3, rule `workout`). Weeks start Monday 00:00 local, Europe/London (BST). Weeks: W1 = 21 to 27 Sep, W2 = 28 Sep to 4 Oct, W3 = 5 to 11 Oct, W4 = 12 Oct to now (Thu 15 Oct 18:00).

| # | Habit | Local time | What happens | Counts for |
|---|---|---|---|---|
| 1 | Read | Mon 21 Sep 07:30 | manual check-in | W1 Mon |
| 2 | Read | Tue 22 Sep 21:00 | manual | W1 Tue |
| 3 | Read | Tue 22 Sep 22:15 | manual, same day | nothing new (one per day) |
| 4 | Read | Thu 24 Sep 20:00 | manual | W1 Thu |
| 5 | Read | Sun 27 Sep 23:50 | manual | W1 Sun |
| 6 | Read | Mon 28 Sep 00:05 | manual (Sun 23:05 in UTC) | W2 Mon, not W1 |
| 7 | Read | Wed 30 Sep 21:00 | manual | (undone by row 8) |
| 8 | Read | Wed 30 Sep 21:01 | undo of row 7 | removes Wed |
| 9 | Read | Fri 2 Oct 21:00 | manual | W2 Fri |
| 10 | Read | Tue 6 Oct 21:00 | manual in a paused week | W3 Tue (week left out of history) |
| 11 | Read | Mon 12 Oct 07:00 | manual | W4 Mon |
| 12 | Read | Wed 14 Oct 21:00 | manual | W4 Wed |
| 13 | Train | Tue 22 Sep 18:40 | Workout "Push day A" finished | W1 Tue (rule) |
| 14 | Train | Thu 24 Sep 19:10 | Workout finished | W1 Thu (rule) |
| 15 | Train | Thu 24 Sep 20:00 | manual, same day as row 14 | nothing new |
| 16 | Train | Sat 26 Sep 11:30 | Workout finished | W1 Sat (rule) |
| 17 | Train | Mon 28 Sep 18:30 | Workout finished | W2 Mon (rule) |
| 18 | Train | Wed 30 Sep 19:00 | Workout finished, then the finish is undone (no `endedAt`) | nothing |
| 19 | Train | Sat 3 Oct 10:00 | manual | W2 Sat |
| 20 | Train | Tue 13 Oct 18:20 | Workout finished | W4 Tue (rule) |

| Habit | W1 | W2 | W3 | W4 (so far) | `lastWeeks(3)` on 15 Oct |
|---|---|---|---|---|---|
| Read (5) | 4 of 5 | 2 of 5 | 1 of 5, paused | 2 of 5 | target met in 0 of 2 (W3 left out) |
| Train (3) | 3 of 3, "Done for the week" | 2 of 3 | 0 of 3 | 1 of 3 | target met in 1 of 3 |

No streak value exists anywhere in the API. W4 starts at 0 with nothing carried over from W3.

## 4. Grammar rows

"Today" is a static read of master. Every row below falls to the model today, and no model tool can log a body weight or a check-in, so at best nothing is written and at worst the model makes a note or task. W = live workout, Bench Press in focus, last set 80 x 8.

| Phrase | Ctx | Today on master | Resolution |
|---|---|---|---|
| `82.4` | idle | not parsed (no entry, no words): model | `LogBodyWeight 82.4 kg` as a ghost that waits for a tap (no 2 s commit), only for 30 to 250 |
| `82.4` | W | not parsed: `parseRelativeSet` takes whole numbers 1 to 100 as reps only, so model | The workout owns it (GC rule 4). Body weight never binds while a workout runs. Add a workout rule: a bare decimal, or a number with kg/lb, sets the next set's weight with the last reps (80 x 8 gives 82.4 x 8) |
| `weighed 82.4` | any | `parseLift`: words ["weighed"], no reps, nil; model | Explicit prefix (`weighed`, `weigh`, `i weigh`, `weight`), checked before relative sets: `LogBodyWeight`, auto-commit |
| `82.4 kg` | idle | `parseLift`: no words, nil; model | `LogBodyWeight`, auto-commit (the unit makes it clear) |
| `82.4 kg` | W | model | Workout weight, as `82.4` in W |
| `bw 82.4` | any | `parseLift`: no reps, nil; model | Explicit prefix: `LogBodyWeight`, also mid-workout. `bw trend` (no number) never logs; it is the slice 7 question |
| `meditated` | idle | no date cue, not explicit: model | Habit rule: the whole phrase is a habit's name or its past or -ing form ("Meditate", "meditated", "meditating"): `CheckInHabit` today. No such habit: fall through. A verb never creates a habit |
| `habit read` | idle | model | Explicit prefix `habit <name>`: `CheckInHabit Read`. Unknown name falls through (GC rule 1) |
| `✓ read` | idle | model | Same as `habit read`. Accept `✓` and `✔` with or without a space |
| `read 20 pages` | idle | `parseLift`: weight 20, no reps, nil; model | Habit name plus a quantity (number with an optional unit word): `CheckInHabit Read`, amount not stored in v1. When Reading (M5) lands, its `read X` must not queue a book called "20 pages", and with a book reading this row turns ambiguous (GC rule 9): habit first, "Dune +20 pages" as the alternative |
| `read` | idle | model | Exact habit name: check-in. Reading's `read X` always needs a title, so it never binds here |
| `read Dune` | idle | model | Not a habit (remainder is not a quantity): falls to the Reading rule later, the model today |

Place the new rules after `parseForProcess` and before `parseRelativeSet`: explicit body-weight prefixes, then `habit`/`✓`, then the habit name rule. The idle bare-number rule runs last, before `parseTask`, and only with no process. Keep guards: `80` in W stays reps, `bench 82.4 x 5` stays a lift, `what did i weigh monday` stays a question.

## 5. Done when (Swift Testing)

1. Catalog: the three classes seed with the fields above. `swift test` stays green on the existing suites.
2. Trend: the 30 rows give the table in section 2 to 0.1 kg (compare at 0.05). Row 12 capped. Row 16 replaced by row 17, and deleting row 17 restores it. A gap over 30 days reseeds. Rate is -0.3 rounded on 10-14 and hidden before 7 days.
3. `LogBodyWeight` twice on one day keeps one record. Undo restores the first value. A value over 3 kg off trend returns the "N kg above trend" feedback.
4. Habits: the 20 rows give the section 3 table. One per day across manual and rule. The Monday boundary uses local time and a calendar with `firstWeekday = 2`, even on an en_US locale. The paused week is left out of `lastWeeks`. Undoing a check-in or a workout's finish drops the count. No count is ever written to the store.
5. Grammar: one parameterized table with every section 4 row (expected kind per context), plus the three guards.
6. `CheckInHabit` and `LogBodyWeight` are registered in `ActionRegistry` with name-only parameters, so the model can call them later.

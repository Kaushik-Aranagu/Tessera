# Grammar misfires: everyday phrases through TessGrammar

For: Core engine. Research lab. Date: 2026-10-15.

**Master read:** `origin/master` at `0950ba7cd957b5176daed56560393a62a971759f` (Merge PR #136, 2026-10-15 16:04 -0700). The grammar files last changed in `ae0d936` (Grammar hotfix, QA on #115).

This is a static read. The container has no Swift toolchain, so every "master parse" below is traced by hand from the code. Nothing was run.

## Files read

All under `TesseraCore/Sources/`:

- `TesseraTess/TessGrammar.swift` ("G:"): rule order (`parse`, G:52-91), question guard (G:94-99), running-process ownership (G:102-131), reschedule (G:133-151), note (G:154-159), relative sets (G:163-186), comma sets (G:202-233), lifts (G:235-347), tasks (G:352-371), the normalise step (G:375-385) and `TessDates` (G:393-484).
- `TesseraTess/TessGrammar+Kitchen.swift` ("K:"): pasted recipe, list, shop, timer, buy/get, comma groceries, cook, `hasDate` (K:160-168).
- `TesseraTess/TessCaptureEngine.swift` ("E:"), `TessCapturing.swift`, `TessModel.swift`: what each parse writes, and that a nil parse goes to the on-device model, else "Didn't catch that".
- `TesseraCore/Kitchen/Quantities.swift` ("Q:", `IngredientLine.parse`), `Kitchen/Aisles.swift` ("A:", the aisle guide), `Kitchen/Groceries.swift`, `Model/Units.swift`, `Processes/ProcessTable.swift`, `Catalog/ExerciseLibrary.swift` (names and aliases).
- Tests: `Tests/TesseraCoreTests/GrammarRulesTests.swift`.

There is no `TessSpokenNormalizer` on master. The only normalise step is `TessGrammar.normalize` (G:375-385). The spoken normaliser in `spoken-normaliser.md` is still a spec.

## Known findings this builds on

- `../grammar-collisions.md` (GC, written at `fcad46c`). Fixed since: GC 1 (whole-word lifts, G:327-331), GC 13 (reschedule, G:83-89), GC 16 to 20 (question guard), GC 22 (`buy sun cream`, K:160-168), GC 34 and 35 (rest timer in a workout, G:113-119), GC 42 (bare noun at the shop, G:120-128), GC 44 (`thu` on a Thursday means today, G:437-446). Still open and seen again here: GC 11 (`done for today`), GC 25 (`bench 80x8 today`), GC 26 (`bench 80 x 8 at 7`), GC 45 (bare `at 7`).
- `upkeep.md` rows 18, 19, 28, 30 and `people.md` rows 6, 7, 18, 33, 35: the past-tense, `get mum a card`, bare `at N` and shop-name rows. Rows 1 to 3 here repeat three of them on purpose, as the task asked, and the rest go wider.
- `money.md`, `reading.md`: no new grammar on master for these. Money and reading phrases are not repeated here.
- `spoken-normaliser.md`: rows 43, 52, 53, 54, 76, 77 already name the time problems. This file shows the same problems in typed text, where no normaliser will help.

## New facts found in this read

1. **The `?` check in the question guard is dead code.** `isQuestion` tests `text.hasSuffix("?")` (G:98), but `text` comes from `normalize`, which trims punctuation from both ends (G:384). `?` is punctuation, so it is always gone. The test `how many workouts this week?` passes only because "how" is a lead word. So `bench 80x8?` logs a set and `dentist thu?` makes a task (rows 175, 176, 210, 211).
2. **`tonight at 9` lands in the past.** `tonight` sets 20:00 only when no time is set yet (G:409), then `at 9` overwrites it with 09:00 (G:417-418). Because a day was said, the passed-time roll (G:429-434) and the next-hour rule (G:447) both skip it. The task is today at 09:00, nine hours ago (rows 106, 107). `today at 5` does the same (row 109).
3. **`move dentist to fri` drops the time the dentist already had.** The reschedule date comes from `TessDates` alone, which defaults to 09:00 (G:435). A dentist at Sat 10:00 moves to Fri 09:00. `move dentist to 3pm` moves it to tomorrow (Fri), not to 15:00 on its own day (rows 125, 126). The test only checks the weekday (GrammarRulesTests:33).
4. **The shop rule runs before every other rule and takes almost anything short.** At the shop (G:120-128), `shop`, `done`, `thanks`, `call mum` and `buy milk` all become grocery lines, the last one with the verb in it. It also uses raw `TessDates`, so `sun cream` at the shop becomes the task "Cream" on Sunday (rows 41, 131, 196 to 204).
5. **`a` counts as an amount, so `get a haircut` is groceries.** `IngredientLine.parse` reads a leading `a`/`an` as amount 1 (Q:128-130), and `looksLikeGroceries` accepts any amount (K:69). Separately, `isGettable` accepts any item of 3 words or fewer (K:155). Together they send people and errands to the groceries list (rows 2, 42 to 58, 132 to 135).
6. **A comma list needs only one food-ish item.** `isShoppingList` needs one item that looks like groceries (K:138), and the aisle guide matches on the last word (A:27-35). `lunch with Olive, Basil` is two grocery lines (rows 136 to 139).
7. **Colon numbers are always clock times.** `plank 2:30` is the task "Plank" tomorrow at 02:30 (rows 119, 120).

## How to read the table

**Clock.** Thu 15 Oct 2026, 18:00 Europe/London (same as GC, upkeep, people). Fri is 16 Oct, Sat 17, Sun 18, Mon 19, Tue 20, Wed 21, Thu next week 22.

**Contexts.**
- **I**: idle. Nothing running.
- **W**: live workout. `context.process` is the workout and `context.entry` is Bench Press, last set 80 x 8.
- **C**: cooking Weeknight dal (the cook is the running process; no entry).
- **S**: a shop run of the Groceries list is running (`context.process` is `Groceries.listID`).

**Fixtures.** Recipes: Spaghetti carbonara, Chilli con carne, Weeknight dal, Salmon rice bowl, Egg fried rice. Open tasks: Dentist (Sat 17 Oct 10:00), Call mum (no date), Clean the oven. Ingredients: those in the recipes. No Person objects (People is not on master). The built-in exercise library.

**Dates in the master column** are what the code computes. "Fri 07:00" means Fri 16 Oct 07:00. "Later" means a task with no date.

**Verdict.**
- **OK**: master does the expected thing, or hands the phrase to the model when the model is the right owner today.
- **MISFIRE**: master writes the wrong object, the wrong fields (date, time, title, list line), or writes something for a phrase that should write nothing.
- **MISFIRE (miss)**: master writes nothing and hands to the model, but its own rules claim this shape (a dated task, a set, a timer), so the grammar should have caught it. With no model on the phone the user sees "Didn't catch that".

The last column names the root cause (RC) from the table further down.

**Expected time rule used in this file.** For a bare hour said with no am or pm (`at 7`, `at 6:30`): today, the next of the two clock readings (07:00 or 19:00); hours 1 to 6 read as pm; an am cue (`wake`, `alarm`, `morning`, `breakfast`) forces am; a pm cue (`tonight`, `evening`, `dinner`, `drinks`, `pub`, `party`) forces pm. On another day, 7 to 11 is am and 1 to 6 is pm unless a cue says otherwise. This is GC rule 7 made precise. It needs a Product yes (see the flags).

## Phrase rows

### Required rows

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 1 | watered plants sat | I | No lift (no numbers). Kitchen sees a date (K:22, `sat` is last), `parseCook` finds no recipe and is not explicit (K:104). Task rule (G:90, G:367-370) with `sat` as a weekday (G:414-416): **task "Watered plants", Sat 17 Oct 09:00** | A past check-in on Sat 10 Oct (Upkeep). On master today: no future task, hand to the model | MISFIRE | RC2 |
| 2 | get mum a card | I | Kitchen `get` (K:39-48). `isGettable("mum a card")` fails `looksLikeGroceries` but passes the "3 words or fewer" fallback (K:155): **groceries ["mum a card"]** | Not groceries. Task "Get mum a card", Later (or the model) | MISFIRE | RC3 |
| 3 | coffee with ravi at 7 | I | Lift fails: one number, no reps (G:245). Kitchen date found, no recipe. Task rule: `at 7` is 07:00 (G:417-418), passed, so +1 day (G:429-434): **task "Coffee with ravi", Fri 07:00** | Task "Coffee with ravi", today 19:00 | MISFIRE | RC1 |

### Past-tense logs with a weekday

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 4 | watered plants thu | I | Task rule; `thu` is today with no time, so the next whole hour (G:439-443): task "Watered plants", today 19:00 | Check-in today. Never a task | MISFIRE | RC2 |
| 5 | called mum thu | I | Task "Called mum", today 19:00 | Complete "Call mum" or log a talk today (model now) | MISFIRE | RC2 |
| 6 | saw mum sat | I | Task "Saw mum", Sat 17 Oct 09:00 | Talk on Sat 10 Oct (model now) | MISFIRE | RC2 |
| 7 | met sam sun | I | Task "Met sam", Sun 18 Oct 09:00 | Talk on Sun 11 Oct | MISFIRE | RC2 |
| 8 | went to the gym mon | I | `mon` is last, so it counts (K:164). Task "Went to the gym", Mon 19 Oct 09:00 | Past log Mon 12 Oct (model) | MISFIRE | RC2 |
| 9 | ran 5k sat | I | `5k` is not a number (G:279), so no lift. Task "Ran 5k", Sat 09:00 | Past log (model) | MISFIRE | RC2 |
| 10 | ran 5 miles sat | I | Lift: weight 5, no reps (G:245). Task "Ran 5 miles", Sat 09:00 | Past log (model) | MISFIRE | RC2 |
| 11 | paid rent fri | I | Task "Paid rent", Fri 09:00 | Check-in Fri 9 Oct (Upkeep) | MISFIRE | RC2 |
| 12 | paid 40 for gas sat | I | Lift: weight 40, no reps. Task "Paid 40 for gas", Sat 09:00 | Spend (Money; model now) | MISFIRE | RC2 |
| 13 | bought milk sat | I | `buy` regex needs `buy`/`get` (K:40). Task "Bought milk", Sat 09:00 | Past log, no task | MISFIRE | RC2 |
| 14 | cleaned the bathroom wed | I | Task "Cleaned the bathroom", Wed 21 Oct 09:00 | Check-in Wed 14 Oct | MISFIRE | RC2 |
| 15 | took the bins out thu | I | Task "Took the bins out", today 19:00 | Check-in today | MISFIRE | RC2 |
| 16 | fed the cat thu | I | Task "Fed the cat", today 19:00 | Past log (model) | MISFIRE | RC2 |
| 17 | washed the car sat | I | Task "Washed the car", Sat 09:00 | Check-in Sat 10 Oct | MISFIRE | RC2 |
| 18 | visited nan sun | I | Task "Visited nan", Sun 09:00 | Talk Sun 11 Oct | MISFIRE | RC2 |
| 19 | had lunch with ravi wed | I | Task "Had lunch with ravi", Wed 21 Oct 09:00 | Talk Wed 14 Oct | MISFIRE | RC2 |
| 20 | cooked chilli sun | I | `parseCook`: not explicit, `recipe(named: "cooked chilli")` needs "cooked" in a title (K:128-131), none. Task "Cooked chilli", Sun 09:00 | Past log (model) | MISFIRE | RC2 |
| 21 | made carbonara thu | I | `parseCook` treats only `make`, not `made`, as explicit (K:98). "made" blocks the recipe match. Task "Made carbonara", today 19:00 | Past log, never a task | MISFIRE | RC2 |
| 22 | finished the report today | I | `today` with no time is the next whole hour (G:447-452). Task "Finished the report", today 19:00 | Complete an open task (model) | MISFIRE | RC2 |
| 23 | watched dune sat | I | Task "Watched dune", Sat 09:00 | Past log (model) | MISFIRE | RC2 |
| 24 | walked 10k steps fri | I | Task "Walked 10k steps", Fri 09:00 | Past log (model) | MISFIRE | RC2 |
| 25 | benched 80x8 mon | I | Lift: scheme 80 x 8, words "benched mon" match no exercise (G:247). Kitchen date, no recipe. Task "Benched 80x8", Mon 19 Oct 09:00 | Set on Mon 12 Oct, or the model. Never a task | MISFIRE | RC2, RC12 |
| 26 | bench 80x8 mon | I | Same path: `mon` is kept as an exercise word, so Bench Press is not found. Task "Bench 80x8", Mon 19 Oct 09:00 | Set dated Mon 12 Oct, or ask | MISFIRE | RC12 |
| 27 | squat 100x5 tue | I | Task "Squat 100x5", Tue 20 Oct 09:00 | Set dated Tue 13 Oct, or ask | MISFIRE | RC12 |
| 28 | ran 5k in 22:15 | I | `22:15` has a colon, so it is a time (G:420). Task "Ran 5k in", today 22:15 | Past log (model) | MISFIRE | RC2 |
| 29 | slept at 11 | I | Lift: weight 11, no reps. Task "Slept", Fri 11:00 | Sleep log (model) | MISFIRE | RC2 |
| 30 | woke up at 6 | I | Task "Woke up", Fri 06:00 | Past log (model) | MISFIRE | RC2 |
| 31 | did laundry tue | I | Question guard: `did` is a lead word (G:97). Nil, so the model | Model now (Upkeep later) | OK | |
| 32 | did legs mon | I | Question guard, model | Model | OK | |
| 33 | need to call mum thu | I | Task "Need to call mum", today 19:00 | Same. Guard row: "need" ends in "ed" but is not past | OK | |
| 34 | feed the cat sat | I | Task "Feed the cat", Sat 09:00 | Same (guard) | OK | |
| 35 | weed the garden sun | I | Task "Weed the garden", Sun 09:00 | Same (guard) | OK | |
| 36 | water plants sun | I | Task "Water plants", Sun 09:00 | Same (guard; upkeep.md row 20) | OK | |
| 37 | read 40 pages sat | I | Lift: weight 40, no reps. Task "Read 40 pages", Sat 09:00 | Same (present tense reads as a plan) | OK | |
| 38 | watered plants sat | W | Relative set and lift both miss (no numbers), then the same path as row 1: task "Watered plants", Sat 09:00 | As row 1 | MISFIRE | RC2 |
| 39 | watered plants sat | C | Cook rule only takes next/done (G:110). Same task as row 1 | As row 1 | MISFIRE | RC2 |
| 40 | called mum thu | S | Shop rule sees a date (G:122-124) and passes. Task "Called mum", today 19:00 | As row 5 | MISFIRE | RC2 |

### "get" and "buy" with people or non-food things

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 41 | get mum a card | S | Shop rule (G:120-128): no date, no number, 4 words: **groceries ["get mum a card"]**, verb included | Not groceries (task or model) | MISFIRE | RC4 |
| 42 | get mum a card | W | Lift misses, kitchen `get` as row 2: groceries ["mum a card"] | Task | MISFIRE | RC3 |
| 43 | get mum a card | C | Groceries ["mum a card"] | Task | MISFIRE | RC3 |
| 44 | get mum flowers | I | `isGettable`: 2 words (K:155). Groceries ["mum flowers"] | Task "Get mum flowers" | MISFIRE | RC3 |
| 45 | get dad a beer | I | Groceries ["dad a beer"] ("beer" is not in the aisle guide; passes on word count) | Task | MISFIRE | RC3 |
| 46 | get her a card | I | `her` is not in the not-things list (K:151). Groceries ["her a card"] | Task | MISFIRE | RC3 |
| 47 | get him flowers | I | Groceries ["him flowers"] | Task | MISFIRE | RC3 |
| 48 | get a haircut | I | `IngredientLine.parse` reads `a` as amount 1 (Q:128-130), so `looksLikeGroceries` is true (K:69). Groceries ["a haircut"] | Task "Get a haircut" | MISFIRE | RC3 |
| 49 | get a plumber in | I | Same `a` amount. Groceries ["a plumber in"] | Task | MISFIRE | RC3 |
| 50 | get a new phone | I | Groceries ["a new phone"] | Task | MISFIRE | RC3 |
| 51 | get passport photos | I | 2 words. Groceries ["passport photos"] | Task | MISFIRE | RC3 |
| 52 | get petrol | I | Groceries ["petrol"] | Task (or model) | MISFIRE | RC3 |
| 53 | get cash out | I | Groceries ["cash out"] | Task | MISFIRE | RC3 |
| 54 | get flights booked | I | Not "done" at the end (K:154). Groceries ["flights booked"] | Task | MISFIRE | RC3 |
| 55 | buy Candy a drink | I | `buy` has no gettable check (K:45 is `get` only). Groceries ["Candy a drink"] | Task | MISFIRE | RC3 |
| 56 | buy present for mum | I | Groceries ["present for mum"] | Task "Buy present for mum" | MISFIRE | RC3 |
| 57 | buy a new phone | I | Groceries ["a new phone"] | Task | MISFIRE | RC3 |
| 58 | buy tickets for the gig | I | Groceries ["tickets for the gig"] | Task | MISFIRE | RC3 |
| 59 | buy milk and bench 80x8 | I | Lift: scheme 80 x 8 read, but "buy milk and bench" is not an exercise. Kitchen `buy`: items "milk", "bench 80x8" (no set check on `buy` items): **groceries ["milk", "bench 80x8"]** | Groceries ["milk"] and set Bench 80 x 8 | MISFIRE | RC6 |
| 60 | get protein and do legs | I | Both items pass the word-count fallback: groceries ["protein", "do legs"] | Groceries ["protein"] (+ model for the rest) | MISFIRE | RC3, RC6 |
| 61 | get mum from the station at 8 | I | Date found, so `get` is skipped. Task "Get mum from the station", Fri 08:00 | Today 20:00 | MISFIRE | RC1 |
| 62 | get tickets for the gig | I | 4 words, no aisle: `isGettable` false, `parseKitchen` returns nil at K:46. No date, so no task. Model | Model | OK | |
| 63 | get the car washed | I | `the` is a not-thing (K:151), nil. Model | Model | OK | |
| 64 | get mum a card sat | I | Date, so `get` is skipped. Task "Get mum a card", Sat 09:00 | Same | OK | |
| 65 | get coffee | I | Groceries ["coffee"] (passes on word count; coffee is not in the guide) | Groceries | OK | |
| 66 | get bin bags | I | Household aisle. Groceries ["bin bags"] | Groceries | OK | |
| 67 | buy milk | I | Groceries ["milk"] | Same | OK | |
| 68 | buy toothpaste | I | Groceries ["toothpaste"] | Same | OK | |
| 69 | buy batteries | I | Groceries ["batteries"] | Same (a supermarket thing) | OK | |
| 70 | buy flowers for mum | I | Groceries ["flowers for mum"] | Same, by People Decision 8 ("buy" keeps its kitchen meaning) | OK | |
| 71 | buy sun cream | I | `hasDate` drops a mid-phrase `sun` (K:162-166). Groceries ["sun cream"] | Same | OK | |
| 72 | buy sun cream sat | I | `hasDate` sees `sat`. `parseCook` and the task rule use raw `TessDates`, which reads `sun` and then `sat` (the last wins). Task "Buy cream", Sat 09:00 | Task "Buy sun cream", Sat 09:00 | MISFIRE | RC10 |
| 73 | buy milk sat morning | I | `hasDate` drops `sat` (not last, `morning` is not a time), so no date. `buy`: groceries ["milk sat morning"] | Task "Buy milk", Sat 09:00 (or groceries ["milk"]) | MISFIRE | RC11 |

### Bare clock times

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 74 | 7 | I | No entry, so no relative set. Lift has no words (G:245). A bare number is not a time without `at` (G:420). Model | Model | OK | |
| 75 | at 7 | I | Date found (Fri 07:00) but the title is empty (G:369). Model | Model | OK | |
| 76 | 7pm | I | Title empty. Model | Model | OK | |
| 77 | 19:00 | I | Title empty. Model | Model | OK | |
| 78 | half 7 | I | Model | Model | OK | |
| 79 | 7 | W | Relative set, reps only (G:168): set 80 x 7 | Same (the workout owns bare numbers) | OK | |
| 80 | at 7 | W | Relative set misses; lift has weight 7, no reps. Model | Model | OK | |
| 81 | 7pm | W | Model | Model | OK | |
| 82 | 19:00 | W | Model | Model | OK | |
| 83 | half 7 | W | Lift: weight 7, word "half", no reps. Model | Model | OK | |
| 84 | 7 | C | Model | Model | OK | |
| 85 | 7 | S | Shop rule: `IngredientLine.parse("7")` is nil (empty name, Q:174), so not groceries. Model | Model | OK | |
| 86 | call mum at 7 | I | Task "Call mum", Fri 07:00 (G:417, G:429-434) | Today 19:00 | MISFIRE | RC1 |
| 87 | call mum 7pm | I | Task "Call mum", today 19:00 | Same | OK | |
| 88 | call mum at 7pm | I | Task "Call mum", today 19:00 | Same | OK | |
| 89 | call mum 19:00 | I | Task "Call mum", today 19:00 | Same | OK | |
| 90 | call mum at 7 pm | I | `at 7` is 07:00; `pm` on its own fails `parseTime` (G:470) and stays in the title. Task "Call mum pm", Fri 07:00 | Task "Call mum", today 19:00 | MISFIRE | RC11, RC1 |
| 91 | call mum 7 pm | I | `7` needs `at`; `pm` is not a time. No date, model | Task "Call mum", today 19:00 | MISFIRE (miss) | RC11 |
| 92 | call mum half 7 | I | No date. Model | Task "Call mum", today 19:30 | MISFIRE (miss) | RC11 |
| 93 | call mum at half 7 | I | `at half` is not a time; no date. Model | Today 19:30 | MISFIRE (miss) | RC11 |
| 94 | dinner at 7.30 | I | `7.30` fails the time regex (G:470). Model | Task "Dinner", today 19:30 | MISFIRE (miss) | RC11 |
| 95 | dinner at 7:30 | I | 07:30 has passed: task "Dinner", Fri 07:30 | Today 19:30 | MISFIRE | RC1 |
| 96 | meet ravi at 6:30 | I | Task "Meet ravi", Fri 06:30 | Today 18:30 | MISFIRE | RC1 |
| 97 | pick up kids at 3 | I | Lift: weight 3, no reps. Task "Pick up kids", Fri 03:00 | Fri 15:00 | MISFIRE | RC1 |
| 98 | drinks at 8 | I | Task "Drinks", Fri 08:00 | Today 20:00 | MISFIRE | RC1 |
| 99 | bins out at 10 | I | Task "Bins out", Fri 10:00 | Today 22:00 (Fri 10:00 as a one-tap alternative) | MISFIRE | RC1 |
| 100 | gym at 7 | I | Task "Gym", Fri 07:00 | Today 19:00, with Fri 07:00 as a one-tap alternative | MISFIRE | RC1 |
| 101 | wake me at 7 | I | Task "Wake me", Fri 07:00 | Same. Guard row for the RC1 fix (am cue) | OK | |
| 102 | call mum at 12 | I | 12:00 has passed: Fri 12:00 | Same | OK | |
| 103 | lunch with ravi at noon | I | `noon` (G:467): Fri 12:00 | Same | OK | |
| 104 | standup tomorrow at 9 | I | Fri 09:00 | Same | OK | |
| 105 | dinner tomorrow at 7 | I | Task "Dinner", Fri 07:00 | Fri 19:00 (meal cue) | MISFIRE | RC1 |
| 106 | call mum tonight at 9 | I | `tonight` sets 20:00 (G:409), `at 9` overwrites with 09:00 (G:418). A day was said, so no roll: **task "Call mum", today 09:00, already past** | Today 21:00 | MISFIRE | RC9 |
| 107 | call mum at 9 tonight | I | `at 9` first, `tonight` keeps it (G:409): today 09:00, past | Today 21:00 | MISFIRE | RC9 |
| 108 | call mum tonight 9pm | I | Today 21:00 | Same | OK | |
| 109 | call mum today at 5 | I | Today 05:00, past (G:447 only fixes a missing time) | Not 05:00. 17:00 has passed too, so ask, or hand to the model | MISFIRE | RC9 |
| 110 | call mum today 3pm | I | Today 15:00, past | Ask ("3 pm has passed") | MISFIRE | RC9 |
| 111 | call mum thu at 8 | I | Today 08:00 has passed, weekday rule adds a week (G:444-445): Thu 22 Oct 08:00 | Today 20:00 | MISFIRE | RC1 |
| 112 | call mum thu 3pm | I | Thu 22 Oct 15:00 | Same, by the Product rule (a passed time on today's weekday is next week) | OK | |
| 113 | call mum thu 8pm | I | Today 20:00 | Same | OK | |
| 114 | dentist sat at 10 | I | Sat 10:00 | Same | OK | |
| 115 | call mum sun afternoon | I | `hasDate` drops `sun`; `parseCook` and the task rule do not. `afternoon` is not a time. Task "Call mum afternoon", Sun 09:00 | Task "Call mum", Sun 14:00 | MISFIRE | RC11 |
| 116 | dentist sat morning | I | Task "Dentist morning", Sat 09:00 | Task "Dentist", Sat 09:00 | MISFIRE | RC11 |
| 117 | table for 4 at 8 sat | I | Lift: weight 4, reps 8, words "table sat" match nothing. Task "Table for 4", Sat 08:00 | Sat 20:00 | MISFIRE | RC1 |
| 118 | call 2 clients at 3 | I | Lift: weight 2, reps 3, "call clients" is no exercise. Task "Call 2 clients", Fri 03:00 | Fri 15:00 | MISFIRE | RC1 |
| 119 | plank 2:30 | I | No lift (`2:30` is not a number). `2:30` is a time (G:420), so the timer is skipped (K:36). Task "Plank", Fri 02:30 | A plank hold (model), never a task at 02:30 | MISFIRE | RC11 |
| 120 | plank 2:30 | W | Relative set misses; same task "Plank", Fri 02:30 | Plank hold (model) | MISFIRE | RC11 |
| 121 | call mum at 7 | W | Task "Call mum", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 122 | call mum at 7 | C | Task "Call mum", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 123 | call mum at 7 | S | Dated, so the shop rule passes (G:122-124). Task "Call mum", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 124 | cook dinner at 7 | I | `parseCook`: explicit `cook`, no recipe "dinner", so task (K:109-110): "Cook dinner", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 125 | move dentist to fri | I | Reschedule (G:137-151): Dentist to Fri 09:00. Its 10:00 is lost (default 09:00, G:435) | Dentist to Fri 10:00 | MISFIRE | RC13 |
| 126 | move dentist to 3pm | I | Reschedule: a time with no day is today, passed, so tomorrow (G:429-434): Dentist to Fri 15:00 | Dentist to Sat 17 Oct 15:00 (its own day) | MISFIRE | RC13 |
| 127 | move dentist to 7 | I | `7` is not a time, so `parseReschedule` is nil; the shape matches, so nil (G:87). Model | Model | OK | |

### Names that are also foods

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 128 | Olive | I | Model | Model | OK | |
| 129 | Olive | S | Groceries ["olive"] | Same (reads as food) | OK | |
| 130 | call Olive thu | I | Task "Call Olive", today 19:00 | Same | OK | |
| 131 | text Olive | S | Shop rule: groceries ["text olive"] | Not groceries (model) | MISFIRE | RC4 |
| 132 | get Olive a present | I | `isGettable`: 3 words. Groceries ["Olive a present"] | Task | MISFIRE | RC3 |
| 133 | get Honey a coffee | I | Groceries ["Honey a coffee"] | Task | MISFIRE | RC3 |
| 134 | get Basil some flowers | I | Groceries ["Basil some flowers"] | Task | MISFIRE | RC3 |
| 135 | get Candy flowers | I | Groceries ["Candy flowers"] | Task | MISFIRE | RC3 |
| 136 | coffee with Pepper, then gym | I | Comma sets fail. Comma groceries: "coffee with Pepper" ends in the aisle word "pepper" (A:33), "then gym" is short: **groceries ["coffee with Pepper", "then gym"]** | Not groceries (model) | MISFIRE | RC8 |
| 137 | lunch with Olive, Basil | I | "olive" is a tins aisle word: groceries ["lunch with Olive", "Basil"] | Not groceries (model) | MISFIRE | RC8 |
| 138 | drinks with Candy, Honey | I | "Honey" is dry goods; one food item is enough (K:138): groceries ["drinks with Candy", "Honey"] | Not groceries | MISFIRE | RC8 |
| 139 | Candy, Honey and Basil are coming | I | `splitItems` splits on "and": groceries ["Candy", "Honey", "Basil are coming"] | Model | MISFIRE | RC8 |
| 140 | Olive, Basil and Ginger | I | Groceries 3 lines | Same (reads as food; People may ask later) | OK | |
| 141 | text Ginger, Basil and Honey | I | Errand verb `text` (K:143) blocks groceries. Model | Model | OK | |
| 142 | Pepper sat | I | No recipe with "pepper". Task "Pepper", Sat 09:00 | Same | OK | |
| 143 | Ginger's birthday sat | I | Task "Ginger's birthday", Sat 09:00 | Same | OK | |
| 144 | dinner with Ginger fri | I | No recipe. Task "Dinner with Ginger", Fri 09:00 | Same (linked once People lands) | OK | |
| 145 | meet Rosemary at 7 | I | Task "Meet Rosemary", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 146 | Basil at 7 | I | Task "Basil", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 147 | Basil 7pm | I | Task "Basil", today 19:00 | Same | OK | |
| 148 | pick up Honey at 4 | I | Task "Pick up Honey", Fri 04:00 | Fri 16:00 | MISFIRE | RC1 |
| 149 | get Ginger from school at 3 | I | Task "Get Ginger from school", Fri 03:00 | Fri 15:00 | MISFIRE | RC1 |
| 150 | get Honey from the station | I | 4 words, no aisle: nil (K:46). Model | Model | OK | |
| 151 | buy rosemary | I | Groceries ["rosemary"] | Same (People eval 9) | OK | |
| 152 | get ginger | I | Produce aisle. Groceries ["ginger"] | Same | OK | |
| 153 | Honey | W | Model | Model (never a set) | OK | |
| 154 | Basil | C | Model | Model | OK | |
| 155 | Pepper | S | Groceries ["pepper"] | Same | OK | |
| 156 | call Pepper | I | Model | Model | OK | |
| 157 | lunch with Basil, sat | I | Comma groceries skipped (date). Task title keeps the comma (G:368 trims only spaces): task "Lunch with Basil,", Sat 09:00 | Task "Lunch with Basil", Sat 09:00 | MISFIRE | RC7 |

### Mixed workout and task phrases

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 158 | bench then call mum | I | No numbers, no date. Model | Model (nothing to log for "bench") | OK | |
| 159 | bench then call mum | W | Model | Model | OK | |
| 160 | bench 80x8 then call mum | I | Lift: "bench then call mum" is no exercise. Model | Set Bench 80 x 8, then task "Call mum" | MISFIRE (miss) | RC6 |
| 161 | bench 80x8, call mum | I | Comma sets: "call mum" is not a lift, and with no entry not a set (G:224-229), nil. Comma groceries blocked by the set shape (K:135). Model | Set + task | MISFIRE (miss) | RC6 |
| 162 | bench 80x8, call mum thu | I | Task "Bench 80x8, call mum", today 19:00 | Set + task "Call mum" today 19:00 | MISFIRE | RC6 |
| 163 | bench 80x8 and call mum thu | I | Task "Bench 80x8 and call mum", today 19:00 | Set + task | MISFIRE | RC6 |
| 164 | squat 100x5 and buy milk | I | `buy` must start the phrase (K:40). Model | Set + groceries ["milk"] | MISFIRE (miss) | RC6 |
| 165 | leg day then dentist at 4 | I | Lift: weight 4, no reps. Task "Leg day then dentist", Fri 04:00 | Task "Dentist" Fri 16:00 (the workout part to the model) | MISFIRE | RC6, RC1 |
| 166 | pull ups then call mum tonight | I | Task "Pull ups then call mum", today 20:00 | Task "Call mum", today 20:00 | MISFIRE | RC6 |
| 167 | bench 3x5 at 80 then call mum at 7 | I | Lift reads "3x5 at 80" (G:238) but the words do not resolve. `at 80` is no time (hour 80). Task "Bench 3x5 at 80 then call mum", Fri 07:00 | Lift Bench 3 x 5 at 80 + task "Call mum" today 19:00 | MISFIRE | RC6, RC1 |
| 168 | 80x8 then call mum | W | The relative regex is anchored (G:178). Lift words do not resolve. Model | Set 80 x 8 + model | MISFIRE (miss) | RC6 |
| 169 | 8 and call mum at 7 | W | Relative set needs a bare number (G:168). Lift: weight 8, reps 7, words "and call mum", no exercise. Task "8 and call mum", Fri 07:00 | Set 80 x 8 + task "Call mum" today 19:00 | MISFIRE | RC6 |
| 170 | same, call mum thu | W | Comma sets: "same" is a set, "call mum thu" is nothing, so nil. Task "Same, call mum", today 19:00 | Set (same) + task "Call mum" | MISFIRE | RC6 |
| 171 | bench 80x8 dentist fri | W | Task "Bench 80x8 dentist", Fri 09:00 | Set + task "Dentist" | MISFIRE | RC6 |
| 172 | call mum then bench | W | Model | Model | OK | |
| 173 | squat 100 5, deadlift 140 3 | I | Comma sets: two lifts | Same | OK | |
| 174 | 80x8, 80x8, 80x6 | W | Comma sets: three sets into Bench | Same | OK | |
| 175 | same? | W | `normalize` trims the `?` (G:384), so the guard never sees it (G:98). Set 80 x 8 (same) | A question. No write | MISFIRE | RC5 |
| 176 | bench 80x8? | I | Lift Bench Press 80 x 8 logged | A question. No write | MISFIRE | RC5 |
| 177 | done for today | W | No workout word for "done" (G:113-119). `today` is a date: task "Done for", today 19:00 | Finish the workout (model now) | MISFIRE | RC14 |
| 178 | timer 90 | W | Process rule (G:117): ignoredInWorkout | Same | OK | |
| 179 | rest timer 90 | W | ignoredInWorkout | Same | OK | |
| 180 | 100 | W | Reps-only accepts up to 100 (G:168): set 80 x 100 | Ask (100 reads as a weight) | MISFIRE | RC12 |
| 181 | pull ups 3x8 | I | Scheme with no other number is weight x reps (G:271-272). Alias "pull ups" finds Pull-Up: lift Pull-Up 3 kg x 8 | 3 sets x 8, bodyweight | MISFIRE | RC12 |
| 182 | curls 15x12 | I | Alias to "curl", no exact name, so the shortest whole-word match wins (G:338-346): Cable Curl 15 x 12 | Dumbbell Curl (or ask) | MISFIRE | RC12 |
| 183 | bench 80x8 today | I | `today` is kept as an exercise word, lift fails. Task "Bench 80x8", today 19:00 (GC 25) | Set Bench 80 x 8 | MISFIRE | RC12 |
| 184 | bench 80x8 at 7 | I | Scheme reads `at 7` as the weight, so 80 sets, which fails (G:245). Task "Bench 80x8", Fri 07:00 (GC 26) | Ask: set now, or planned at 19:00 | MISFIRE | RC12 |
| 185 | bench 3x5 at 80 tomorrow | I | Lift words "bench tomorrow" fail. Task "Bench 3x5 at 80", Fri 09:00 | Same (a plan) | OK | |

### Other context variants: cooking, shop run, questions, titles

| # | Phrase | Ctx | Master parse (rule, object, fields) | Expected | Verdict | RC |
|---|---|---|---|---|---|---|
| 186 | next | C | Process rule (G:110-111): cookStep next | Same | OK | |
| 187 | done | C | FinishCooking | Same | OK | |
| 188 | timer 10 | C | Kitchen timer 10 min, linked to the cook (E:143-145) | Same | OK | |
| 189 | 8 mins | C | No "timer" word (K:75). Model | Timer 8 min | MISFIRE (miss) | RC15 |
| 190 | pasta 10 | C | Model | Timer "Pasta" 10 min | MISFIRE (miss) | RC15 |
| 191 | finished cooking | C | Not in the cook list (G:110). Model | Finish the cook | MISFIRE (miss) | RC15 |
| 192 | buy parmesan | C | Groceries ["parmesan"] | Same | OK | |
| 193 | coffee with ravi at 7 | C | Task "Coffee with ravi", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 194 | parmesan | S | Shop rule: groceries ["parmesan"] | Same | OK | |
| 195 | 2 lemons | S | Groceries ["2 lemons"] | Same | OK | |
| 196 | call mum | S | Shop rule: groceries ["call mum"] | Not groceries (model) | MISFIRE | RC4 |
| 197 | done | S | Groceries ["done"] | End the shop, or no write | MISFIRE | RC4 |
| 198 | shop | S | The shop rule runs before the kitchen's `shop` word (G:66 before K:28): groceries ["shop"] | No write (the shop is already on) | MISFIRE | RC4 |
| 199 | thanks | S | Groceries ["thanks"] | No write | MISFIRE | RC4 |
| 200 | buy milk | S | Groceries ["buy milk"] (the verb is kept) | Groceries ["milk"] | MISFIRE | RC4 |
| 201 | finished shopping | S | Groceries ["finished shopping"] | End the shop | MISFIRE | RC4 |
| 202 | pick up dry cleaning | S | 4 words: groceries ["pick up dry cleaning"] | Model or task | MISFIRE | RC4 |
| 203 | sun cream | S | The shop rule uses raw `TessDates` (G:122), which reads `sun` as Sunday, so it passes. `parseCook` finds no recipe. Task "Cream", Sun 09:00 | Groceries ["sun cream"] | MISFIRE | RC10, RC4 |
| 204 | sat nav charger | S | Task "Nav charger", Sat 09:00 | Groceries or model | MISFIRE | RC10 |
| 205 | coffee with ravi at 7 | S | Task "Coffee with ravi", Fri 07:00 | Today 19:00 | MISFIRE | RC1 |
| 206 | what else | S | Question lead `what`. Model | Model | OK | |
| 207 | mum's birthday sat | S | Dated, so the shop rule passes. Task "Mum's birthday", Sat 09:00 | Same | OK | |
| 208 | bench 80x8 | S | Has a number, and `IngredientLine` finds no amount, so the shop rule passes. Lift Bench 80 x 8 | Same | OK | |
| 209 | is the gym open sat | I | `is` is not a lead (G:96-97). Task "Is the gym open", Sat 09:00 | A question. No write | MISFIRE | RC5 |
| 210 | is the gym open sat? | I | `?` trimmed (G:384). Same task | A question | MISFIRE | RC5 |
| 211 | dentist thu? | I | Task "Dentist", today 19:00 | A question | MISFIRE | RC5 |
| 212 | who's free sat | I | Task "Who's free", Sat 09:00 | A question | MISFIRE | RC5 |
| 213 | do i have anything tomorrow | I | Task "Do i have anything", Fri 09:00 | A question | MISFIRE | RC5 |
| 214 | can i move leg day to fri | I | The reschedule shape must start with the verb (G:133). Task "Can i move leg day to", Fri 09:00 | A question (model) | MISFIRE | RC5 |
| 215 | should i train today | I | Task "Should i train", today 19:00 | A question | MISFIRE | RC5 |
| 216 | any plans sat | I | `any` is not a lead (only `anything`). Task "Any plans", Sat 09:00 | A question | MISFIRE | RC5 |
| 217 | what's on thu | I | Question. Model | Same | OK | |
| 218 | show ravi the flat sat | I | `show` is a lead (G:97): nil, model | Task "Show ravi the flat", Sat 09:00 | MISFIRE (miss) | RC5 |
| 219 | dentist on friday | I | Task "Dentist on", Fri 09:00 | Task "Dentist", Fri 09:00 | MISFIRE | RC7 |
| 220 | report by fri | I | Task "Report by", Fri 09:00 | Task "Report", Fri | MISFIRE | RC7 |
| 221 | gym this sat | I | Task "Gym this", Sat 09:00 | Task "Gym", Sat | MISFIRE | RC7 |
| 222 | dentist next fri | I | Task "Dentist next", Fri 16 Oct 09:00 | Task "Dentist", Fri (16 or 23 Oct is GC open question 4) | MISFIRE | RC7 |
| 223 | packing list for sat | I | Task "Packing list for", Sat 09:00 | Task "Packing list", Sat | MISFIRE | RC7 |
| 224 | remind me tomorrow to call mum | I | `to` is only stripped right after "remind me" (G:363), before the date is taken out. Task "To call mum", Fri 09:00 | Task "Call mum", Fri 09:00 | MISFIRE | RC7 |
| 225 | remind me to call mum | I | Task "Call mum", Later | Same | OK | |
| 226 | todo: renew passport | I | Task "Renew passport", Later | Same | OK | |
| 227 | call mum, thu | I | Task "Call mum,", today 19:00 | Task "Call mum" | MISFIRE | RC7 |
| 228 | fix sat nav | I | `hasDate` drops `sat`, but `parseCook` and the task rule read it. Task "Fix nav", Sat 09:00 | Model, or task "Fix sat nav", Later | MISFIRE | RC10 |
| 229 | sun cream | I | Task "Cream", Sun 09:00 | Model (or groceries) | MISFIRE | RC10 |
| 230 | add sun cream to packing | I | Task "Add cream to packing", Sun 09:00 | Add to Packing (model) | MISFIRE | RC10 |
| 231 | list: packing | I | New list "Packing" | Same | OK | |
| 232 | list the car on ebay sat | I | Task "List the car on ebay", Sat 09:00 | Same | OK | |
| 233 | note: call mum sat | I | Note "call mum sat" | Same | OK | |
| 234 | note to self, eighty felt easy | I | Note "to self, eighty felt easy" (G:156) | Note "eighty felt easy" | MISFIRE | RC16 |
| 235 | carbonara thu | I | Cook task linking Spaghetti carbonara, today 19:00 | Same | OK | |
| 236 | timer 10 | I | Timer 10 min | Same | OK | |
| 237 | call mum | I | Model | Model | OK | |
| 238 | dentist fri 10am | I | Task "Dentist", Fri 10:00 | Same | OK | |

**Count:** 238 rows. **Misfires: 154** (142 wrong writes and 12 misses). 84 rows are OK; many of them are guard rows that a fix must keep passing.

By category: required rows 3 (3 misfires); past-tense logs 37 rows (30); get/buy 33 rows (23); bare clock times 54 rows (30); food names 30 rows (14); mixed workout and task 28 rows (20); other contexts, questions and titles 53 rows (34).

Misfires per root cause (a row can have two): RC2 29, RC1 26, RC3 23, RC6 14, RC5 11, RC4 10, RC11 10, RC12 8, RC7 8, RC10 6, RC9 4, RC8 4, RC15 3, RC13 2, RC14 1, RC16 1.

## Misfires by root cause

Each row gives the smallest change I can see, as a regex or an order change, and the rows it fixes. "Breaks" lists rows or known phrases that the change would turn wrong.

| RC | Root cause | Where | Smallest proposed change | Rows fixed | Breaks / flags |
|---|---|---|---|---|---|
| RC1 | A bare hour with no am/pm is read on a 24-hour clock. At 18:00, `at 7` is 07:00, which has passed, so it becomes tomorrow 07:00 | G:417-419, G:429-434, G:470-482 | In `TessDates.extract`, remember whether the time had `am`/`pm` or an hour of 13 or more. If not, and the hour is 1 to 11: if the phrase has an am cue (`/\b(wake|alarm|morning|breakfast)\b/`) use am; if it has a pm cue (`/\b(tonight|evening|dinner|drinks|pub|party)\b/`) use pm; else for today take the first of H:00 and (H+12):00 after `now` (hours 1 to 6 always pm); for another day use am for 7 to 11 and pm for 1 to 6. Hour 12 stays noon | 3, 61, 86, 95 to 100, 105, 111, 117 (only with a "table" pm cue), 118, 121 to 124, 145, 146, 148, 149, 165, 167, 169, 193, 205 | Row 101 (`wake me at 7`) needs the am cue list. Row 100 (`gym at 7`) is truly ambiguous: show Fri 07:00 as a one-tap alternative (GC rule 9). Row 117 is not fixed unless "table" joins the pm cues. A Product yes is needed on "1 to 6 is pm" |
| RC2 | A past-tense log with a day becomes a future task. `TessDates` has no past mode | G:90, G:352-371, K:96-111 | In `parseTask` and `parseCook`, return nil when the first word is a past verb: `/^(?:did|went|saw|met|ate|had|ran|took|got|bought|made|paid|sent|rang|spoke|slept|woke|fed|drank|swam|rode|left|came|gave|wrote|\p{L}{3,}ed)$/` and not in `[need, feed, seed, weed, bleed, breed, speed, shed, embed, exceed, proceed, succeed]`. The phrase then goes to the model (later to Upkeep and People with a past date) | 1, 4 to 25, 28 to 30, 38 to 40 | "need to call mum thu", "feed the cat sat", "weed the garden sun" stay tasks only through the exception list (rows 33 to 35). Titles that start with an adjective in -ed ("advanced driving lesson sat", "scheduled service fri", "guided run sat", "mixed doubles sat") would go to the model instead of becoming tasks. `did` already hits the question guard first |
| RC3 | `get` takes anything of 3 words or fewer, and `a`/`an` counts as an amount, so people, errands and non-food go on the groceries list. `buy` has no check at all | K:45-46, K:149-156 (fallback K:155), K:64-71, Q:128-130 | (a) In `isGettable`, replace `looksLikeGroceries(item) \|\| item.split(separator: " ").count <= 3` with `looksLikeGroceries(item)`. (b) In `looksLikeGroceries`, count an amount only when the item starts with a digit: `(line.amount != nil && item.first?.isNumber == true)`. (c) Add common drinks and snacks to the aisle guide (A:47-90): coffee, tea, juice, beer, wine, crisps, biscuit, snack, protein. (d) For `buy`, run the same check on each item; on failure return nil (model) | 2, 42 to 54, 60, 132 to 135, and with (d) 55 to 58 | Without (c), row 65 (`get coffee`) and "milk, coffee, tea" stop being groceries. After (a), `get stamps`, `get batteries`, `get quorn` go to the model. (d) changes rows 69 and 70 (`buy batteries`, `buy flowers for mum`) to the model unless batteries and flowers join the guide, and it goes against People Decision 8 ("buy keeps its kitchen meaning"). Product should decide (d) separately |
| RC4 | At the shop, every short phrase becomes a grocery line: errands, control words, `buy` with its verb, and `shop` itself | G:120-128 | In the shop branch, before adding: return nil when `Self.startsWithErrand(text)` (K:142) or the first word is `buy`, `get`, `add` or `pick` (so the kitchen rule handles them without the verb); return nil when `text` matches `/^(done|finished|finished shopping|done shopping|shop|shopping|thanks|thank you|ok|cancel|stop)$/`; and use `Self.hasDate(text, context:)` (K:160) in place of the raw `TessDates.extract` at G:122 | 41, 131, 196 to 202, 203 (with RC10) | `pick` as a first word means `pick up a baguette` at the shop goes to the model, not the list. "done" and "finished shopping" then write nothing until a finish-shop action exists |
| RC5 | The question guard misses typed `?` (always trimmed first), and several common question openers. `show` alone is too broad | G:62, G:94-99, G:384 | (a) Test the raw phrase: `phrase.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")`. (b) Add two-word leads `/^(is|are) (the\|it\|there\|my\|we)\b/`, `/^(do\|does\|can\|could\|should\|have) (i\|we\|you)\b/`, and single words `who`, `who's`, `whos`, `where`, `where's`, `when's`, `whens`, `which`, `any`. (c) Narrow `show` to `/^show (me\|my\|all)\b/` | 175, 176, 209 to 216, 218 | (b) overrides the spec comment at G:96 that "is" phrases stay captures, so Product must agree. Keep `do` alone off the list so "do laundry thu" (GrammarRulesTests:109) stays a task. With (a), a typed `80x8?` in a workout writes nothing; that is the intent |
| RC6 | No split: a set and an errand in one phrase become one task, one grocery list, or nothing | G:73, G:90, K:39-48 | (a) In `parseTask`, return nil when the phrase has a set shape `/\b\d+(?:\.\d+)?\s*(?:kg\|lb)?\s*[x×]\s*\d+\b/`. (b) In the `buy` branch, return nil if any item has that shape. Both stop the wrong write. (c) Follow-up: split on `/\s*(?:,\s*)?(?:and then\|then\|and)\s+\|,\s+/` when the left part parses as a lift or set, and return a new `.batch([Parse])` | (a) and (b): 59, 162, 163, 165, 166, 167, 171 to the model. (c): 160, 161, 164, 168, 169, 170 | (a) also sends "order 2x4 timber sat" to the model. (c) must not split "milk and eggs" (no lift on the left) or `talked to sam and mum` (people.md row 11) |
| RC7 | Words next to a removed date stay in the title: `on`, `by`, `this`, `next`, `for`, a trailing comma, and `to` after a date in a reminder | G:360-370, G:405-426 | In `TessDates.extract`, when a day or time token is used, also drop the word just before it if it is `on`, `by`, `this`, `next` or `for`. In `parseTask`, strip a leading `to` from the remaining words after `extract` (not before), and trim trailing `,;:` from the title | 157, 219 to 224, 227 | Dropping `next` hides "next Friday" when it means 23 Oct (GC open question 4); keep a flag until that is decided. "for" goes even in "rehearsal for sat", which is fine. Spoken text will reach this after the normaliser, so the two must agree |
| RC8 | A comma list is groceries if one item looks like food, and the aisle guide reads the last word, so "lunch with Olive" is a tin | K:51-57, K:134-139, A:27-35 | In `isShoppingList`, change `lines.contains(where: looksLikeGroceries)` to `lines.allSatisfy(looksLikeGroceries)`, and in `looksLikeGroceries` return false for items matching `/\b(with\|for\|are\|is)\b/` | 136 to 139 | "milk, coffee, tea" and "bread, stuff for lunch" stop being groceries unless RC3 (c) adds coffee and tea. "chicken with skin, rice" goes to the model |
| RC9 | `tonight` and `today` with a time can land in the past: `at 9` overwrites tonight's 20:00, and no rule checks a stated time today | G:407-411, G:417-418, G:447-452 | Fold into RC1: `tonight` is a pm cue, so `at 9` with `tonight` is 21:00. Then, after the date is built, if a day word was `today` or `tonight` and the result is before `now`, return nil (the model asks) instead of a past task | 106, 107, 109, 110 | None seen. A deliberate past-time task ("today 3pm" said late) now goes to the model |
| RC10 | Short weekdays (`sun`, `sat`, `wed`, `mon`) are read as days everywhere except the kitchen check, so `sun cream`, `sat nav` lose a word and gain a date | G:414-416, G:122, K:160-168 | Move the filter from `hasDate` (K:162-166) into `TessDates.extract` itself: an ambiguous short weekday counts only when it is the last word, comes before a time or a part-of-day word, or comes after `on`, `this`, `next` or `by`. `hasDate` then just calls `extract` | 72, 203, 204, 228 to 230 | "call mum sun and dad sat" loses `sun` (not last). With RC11, "dentist sat morning" still works only if part-of-day words count as times in the filter |
| RC11 | Common time forms are not read: `half 7`, `7.30`, `7 pm` with a space, `morning`/`afternoon`/`evening`. A colon number is always a time | G:420-421, G:465-483 | In `extract`: read `half H` and `half past H` as H:30 (then RC1); read `H.MM` as a time only after `at`; join a number and a following `am`/`pm` token; add `morning` 09:00, `afternoon` 14:00, `evening` 18:00 as times used only when no clock time is given. In `parseTask`, return nil when the remaining title alone resolves to an exercise (`resolveExercise(title) != nil`) and the time came from `H:MM` with no `at` | 73, 90 to 94, 115, 116, 119, 120 | Read `H.MM` only after `at`: in "paid 12.50 at 12.30" only the second number is a time. Never read `H.MM` without `at`, or money amounts become times. "bench at 7" with the exercise rule goes to the model, not a task |
| RC12 | Lift edge cases: day words block the exercise match, `at N` is always a weight, bodyweight `3x8` is 3 kg, `curls` picks Cable Curl, and reps-only accepts 100 | G:168, G:238-252, G:263-274, G:300-305, G:338-346 | (a) In `parseLift`, drop `today`, `tonight`, `now` from `words`; if a weekday word is in `words`, return nil. (b) Read `at N` after a full `W x R` as a time, not a weight: only take `at N` as the weight when the scheme's first number is 10 or less. (c) In `readScheme`, when there is no other number and the exercise's log type is bodyweight, read N x M as sets x reps with weight 0, and let the guard accept weight 0 for bodyweight. (d) Add `"curl": "dumbbell curl", "curls": "dumbbell curl"` to `aliases` (G:300). (e) Cap reps-only at 50 (G:168) | 26, 27, 183 (a); 184 with RC6 (a) to the model (b); 181 (c); 182 (d); 180 (e) | (e) sends a real 60-rep set to the model. (c) changes `dips 3x10`, `pull ups 3x8` from added kg to sets; `dips 20x10` keeps 20 kg (first number over 10) |
| RC13 | A reschedule replaces the whole date: a day alone resets the time to 09:00, a time alone moves to tomorrow | G:137-151, G:435 | Have `extract` also return which parts were said (day, time). In `parseReschedule`, if only a day was said keep the task's hour and minute; if only a time was said keep the task's day (when it has one) | 125, 126 | None. GrammarRulesTests:33 still passes (it checks the weekday only) |
| RC14 | "done for today" in a workout becomes a task | G:113-119 | In the workout branch of `parseForProcess`, return nil for `/^(done\|finished\|all done\|that's it)(?: for today)?$/` (later a `finishWorkout` parse) | 177 | None |
| RC15 | While cooking, a timer must contain the word "timer"; `finished cooking` is not a step word | G:109-112, K:75 | In the cook branch: `/^(\d+(?:\.\d+)?)\s*(?:m\|min\|mins\|minutes)$/` and `/^(\p{L}+) (\d+)$/` (not `step`) become `.timer`; add `finished cooking`, `done cooking` to the finish words | 189, 190, 191 | "step 3" must be excluded or it becomes a 3-minute timer called "Step". "serves 4" while cooking would become a timer "Serves"; exclude `serves` too |
| RC16 | `note to self` keeps "to self" in the body | G:156 | `/^(?i)note(?:\s+to\s+self)?[:,\s]\s*(.+)$/` | 234 | None |

Proposed changes that conflict with another row or a spec, in one place:

- RC1 against row 101 and row 100: needs the am cue list and an alternative on the ghost row.
- RC2 against rows 33 to 35 (guarded by the exception list) and -ed adjectives at the start of a title.
- RC3 (a) against row 65 unless RC3 (c) lands in the same change. RC3 (d) against People Decision 8 and rows 69, 70.
- RC5 (b) against the spec comment at G:96 ("is" phrases stay captures).
- RC7 dropping `next` against GC open question 4.
- RC8 against "milk, coffee, tea" unless RC3 (c) lands first.
- RC10 against "call mum sun and dad sat".
- RC12 (e) against high-rep sets.
- RC15 against "step 3" and "serves 4" unless excluded.

## Prioritized fix list for Core's batch

Ordered by how often the phrase shape comes up in a normal day, then by how bad the wrong write is.

1. **RC1 + RC9, bare hours.** `at 7` is the most common time form in typed and spoken text, and today it is 12 hours off for every evening plan. 30 rows, two of which create a task in the past (rows 106, 107).
2. **RC7, title leftovers.** `on friday`, `by fri`, `this sat`, `remind me tomorrow to ...` are everyday phrasing; every one leaves a stray word in the title. 8 rows.
3. **RC2, past-tense logs.** Logging what he did with a day is common, and each one makes a wrong future task that then sits on Now. 29 rows.
4. **RC5, the question guard.** Fix the dead `?` check first (one line), then the leads. A question that logs a set (row 176) is the worst case. 11 rows.
5. **RC3 (a) to (c), get.** People, errands and non-food land on the groceries list. 23 rows. Hold (d) for Product.
6. **RC4, the shop run.** Every non-grocery thing said at the shop lands on the list, including "done" and "shop". 10 rows.
7. **RC13, reschedule keeps what was not said.** Every "move X to fri" drops the task's time today. 2 rows, but every reschedule hits row 125's bug.
8. **RC11, time forms.** `half 7`, `7.30`, `7 pm`, `morning`. 10 rows.
9. **RC6 (a) and (b) + RC12 (a), set shapes.** Stop sets ending up inside task titles and grocery lines; log `bench 80x8 today`. About 17 rows sent to the model or fixed; the full split (RC6 (c)) is a follow-up.
10. **RC10, short weekdays in `TessDates`.** `sun cream`, `sat nav`. 6 rows.

After the top 10: RC8 (comma lists with names), RC14 (`done for today`), RC15 (cook timers), RC12 (b) to (e), RC16.

## Swift Testing cases to add

One parameterized table in `GrammarRulesTests`. The clock is Thu 15 Oct 2026 18:00 Europe/London (use `TimeZone(identifier: "Europe/London")`, not `.gmt`, so BST is right). Fixtures as in "How to read the table". `kind` is a short string from the parse, as in GC: `task <Title> <EEE d HH:mm>`, `task <Title> later`, `groceries [a, b]`, `set WxR`, `lift <Exercise> WxR`, `reschedule <Title> <EEE d HH:mm>`, `timer <label> <min>`, `nil`. Rows marked `// guard` pass on master today and must keep passing.

```swift
enum Ctx: Sendable { case idle, workout, cooking, shopping }
struct MisfireRow: Sendable { let phrase: String; let ctx: Ctx; let expect: String }

static let misfireRows: [MisfireRow] = [
    // RC1, RC9: bare hours
    .init("coffee with ravi at 7", .idle, "task Coffee with ravi Thu 15 19:00"),
    .init("call mum at 7", .workout, "task Call mum Thu 15 19:00"),
    .init("meet ravi at 6:30", .idle, "task Meet ravi Thu 15 18:30"),
    .init("pick up kids at 3", .idle, "task Pick up kids Fri 16 15:00"),
    .init("dinner tomorrow at 7", .idle, "task Dinner Fri 16 19:00"),
    .init("call mum thu at 8", .idle, "task Call mum Thu 15 20:00"),
    .init("call mum tonight at 9", .idle, "task Call mum Thu 15 21:00"),
    .init("call mum at 9 tonight", .idle, "task Call mum Thu 15 21:00"),
    .init("wake me at 7", .idle, "task Wake me Fri 16 07:00"), // guard
    .init("call mum thu 3pm", .idle, "task Call mum Thu 22 15:00"), // guard
    .init("call mum 7pm", .idle, "task Call mum Thu 15 19:00"), // guard
    // RC7: title leftovers
    .init("dentist on friday", .idle, "task Dentist Fri 16 09:00"),
    .init("remind me tomorrow to call mum", .idle, "task Call mum Fri 16 09:00"),
    .init("call mum, thu", .idle, "task Call mum Thu 15 19:00"),
    // RC2: past-tense logs
    .init("watered plants sat", .idle, "nil"),
    .init("called mum thu", .idle, "nil"),
    .init("made carbonara thu", .idle, "nil"),
    .init("need to call mum thu", .idle, "task Need to call mum Thu 15 19:00"), // guard
    .init("feed the cat sat", .idle, "task Feed the cat Sat 17 09:00"), // guard
    // RC5: questions
    .init("bench 80x8?", .idle, "nil"),
    .init("same?", .workout, "nil"),
    .init("dentist thu?", .idle, "nil"),
    .init("is the gym open sat", .idle, "nil"),
    .init("do laundry thu", .idle, "task Do laundry Thu 15 19:00"), // guard
    // RC3: get
    .init("get mum a card", .idle, "nil"),
    .init("get a haircut", .idle, "nil"),
    .init("get Olive a present", .idle, "nil"),
    .init("get coffee", .idle, "groceries [coffee]"), // guard
    .init("buy sun cream", .idle, "groceries [sun cream]"), // guard
    // RC4: shop run
    .init("call mum", .shopping, "nil"),
    .init("shop", .shopping, "nil"),
    .init("buy milk", .shopping, "groceries [milk]"),
    .init("parmesan", .shopping, "groceries [parmesan]"), // guard
    .init("sun cream", .shopping, "groceries [sun cream]"),
    // RC13: reschedule
    .init("move dentist to fri", .idle, "reschedule Dentist Fri 16 10:00"),
    .init("move dentist to 3pm", .idle, "reschedule Dentist Sat 17 15:00"),
    // RC11: time forms
    .init("call mum half 7", .idle, "task Call mum Thu 15 19:30"),
    .init("call mum at 7 pm", .idle, "task Call mum Thu 15 19:00"),
    .init("dentist sat morning", .idle, "task Dentist Sat 17 09:00"),
    .init("plank 2:30", .idle, "nil"),
    // RC6, RC12: sets inside other phrases
    .init("bench 80x8 today", .idle, "lift Bench Press 80x8"),
    .init("bench 80x8, call mum thu", .idle, "nil"),
    .init("buy milk and bench 80x8", .idle, "nil"),
    .init("pull ups 3x8", .idle, "lift Pull-Up 3x8 bodyweight"),
    .init("squat 100 5, deadlift 140 3", .idle, "sets 2"), // guard
    // RC10: short weekdays
    .init("buy sun cream sat", .idle, "task Buy sun cream Sat 17 09:00"),
    .init("fix sat nav", .idle, "nil"),
    // RC8: comma lists with names
    .init("lunch with Olive, Basil", .idle, "nil"),
    .init("Olive, Basil and Ginger", .idle, "groceries [Olive, Basil, Ginger]"), // guard
    // RC14, RC15, RC16
    .init("done for today", .workout, "nil"),
    .init("8 mins", .cooking, "timer Timer 8"),
    .init("next", .cooking, "cookStep next"), // guard
    .init("note to self, eighty felt easy", .idle, "note eighty felt easy"),
]

@Test(arguments: misfireRows) func misfires(_ row: MisfireRow) {
    #expect(kind(grammar.parse(row.phrase, context: context(row.ctx))) == row.expect, "\(row.phrase)")
}
```

Also add one plain test that would have caught fact 1: `#expect(TessGrammar.isQuestion(TessGrammar.normalize("dentist thu?")))` fails today, so the guard must read the raw phrase.

## Open questions

1. **Bare hours (RC1).** Is "1 to 6 means pm, 7 to 11 means the next one today" right for him? Should `gym at 7` ask instead of picking?
2. **Past logs before Upkeep and People land (RC2).** Is "send it to the model" enough for now, or should the grammar write a note with a past date?
3. **`buy` for non-food (RC3 d).** Keep People Decision 8 (`buy` is always groceries), or send non-groceries `buy` phrases to tasks?
4. **"is" questions (RC5 b).** The code says "is" phrases stay captures. Is `is the gym open sat` a capture?
5. **Today with a passed time (RC9).** Ask, drop to the model, or keep the past task?

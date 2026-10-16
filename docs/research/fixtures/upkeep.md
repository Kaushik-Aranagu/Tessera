# Upkeep fixtures

For: Core engine (M5 Upkeep slices 1 to 4, `TessGrammar+Upkeep.swift`), Research lab. Date: 2026-10-15.

These are 40 capture phrases for the M5 Upkeep ship list (`../../product/ship-list-m5-upkeep.md`, approved 2026-10-15 19:11). They add to the 15 eval rows in that ship list and repeat only a few of them where a collision needs a pair. Grammar facts come from a static read of `origin/master` at `e56c15e` (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `TessCapturing.swift`, `TessTools.swift`). Nothing was run. Every spoken transcript is a plausible guess, not a recording. Reading (`reading.md`, `ship-list-m5-reading.md`) and Money (`ship-list-m5-money.md`) are only specced, not on master.

## How to read the tables

**Slice ids.** U1 Chore class and actions, U2 Upkeep ledger, U3 The stalest drifts toward Now, U4 Upkeep phrases, U5 Chore page, U6 Upkeep page, U7 A chore on Now. "U4 table" means the phrase is in the slice 4 capture table as written. "U4 rule" means one of the rules under that table. "U4 eval N" is row N of the ship list's eval table. "Decision N" is the ship list's decision N. **Gap** means no slice covers it; the expected column is then a proposal, and the row is an open question. Other domains: "Reading S4" is slice 4 of the Reading ship list, "Money M4" is slice 4 of the Money ship list, "People P5" is slice 5 of the People ship list.

**Line refs.** "G:" is `TessGrammar.swift`, "K:" is `TessGrammar+Kitchen.swift`, "T:" is `TessTools.swift`, all at `e56c15e`. The line numbers match the ones in `reading.md` (written at `5258866`); the grammar files have not changed since. `grammar-collisions.md` ("GC") was written against `fcad46c`, so its line numbers are stale.

**Facts about master that most rows depend on.**
- The dispatch order is note (G:55), pasted recipe (G:58), question guard (G:62), process rule (G:66), relative set (G:70), comma sets (G:73), named lift (G:76), kitchen (G:80), reschedule (G:83), task (G:90). Nil goes to the model.
- The question guard's lead words include `did` (G:97). So every `did <chore>` phrase is treated as a question on master today.
- `TessDates` (G:393-484) knows weekdays, `today`, `tonight`, `tomorrow`, `tmrw`, `at N` and clock times. It has no `yesterday`, no month names and no day numbers. A weekday is always the next one, so a done phrase with `sat` becomes a task for next Saturday.
- A weekday said on that same weekday, with no time, means today at the next whole hour (G:437-443). At 18:00 on a Thursday, `thu` gives today 19:00.
- There is no completion grammar. The model's `completeTask` tool (T:121-127) finds an open task by exact title, then by every word as a substring (T:263-275).
- There is no upkeep, chore, Habit, reading or money code on master.

**Clock.** Thu 15 Oct 2026, 18:00 in the phone's zone (America/Los_Angeles for him; he lives in the US on Pacific time, city unknown). Product, 9:01 PM PT: this file first assumed a London flat; rows now use US bills. Research 107: `upkeep-starters.md` names its starters for a US renter (Take out the trash, Vacuum the apartment, Empty the vacuum, Pay the water bill). This file's "bins" and `hoovered` rows are kept as phrase evidence; the shapes (noun-out, particle-last, verb only) carry over unchanged, and `hoovered` logs a vacuum chore through the S4 verb family there. Row 40's "Pay water bill" is the same chore as the starter Pay the water bill.

**Fixtures.** The U4 eval fixtures: chores Water plants (verb watered, every 7, last done Fri 9 Oct, 6 days), Clean bathroom (cleaned, every 14, last done Thu 24 Sep, 21 days), Laundry (did, no interval), Pay rent (paid, every 30). Added here: Take out the bins (took out, no interval, last done Thu 8 Oct) and Top up the oil (topped up, every 30). No chore for the water filter, kettle, freezer, car or sheets. Open tasks: "Clean the oven", "Call mum", "Finish the report", "Do the ironing". The ingredient Chicken. The book Dune (reading, suspended). The routine Push Day.

**Contexts.**
- **I**: idle. Nothing running.
- **W**: live workout, Bench Press in focus, last set 80 x 8.
- **P**: idle, chores paused until Sun 18 Oct 00:00.

**Spoken column.** Raw transcript, then the text after `TessSpokenNormalizer` as specified in `spoken-normaliser.md`. "Typed only" means nobody says it. "Same" means the normaliser changes nothing but edge punctuation.

## Proposed placement of the upkeep rule

The two ship lists disagree. U4 puts upkeep after comma sets, lifts and kitchen, and after reading and money. P5 puts people after upkeep, but also before comma sets, lifts and kitchen. Both cannot hold: upkeep cannot be after kitchen while people is after upkeep and before kitchen. The rows below assume this order (open question 1):

1. note (G:55), pasted recipe (G:58)
2. question guard (G:62), with `did` narrowed (U4) and `when's` added (`people.md`)
3. process rule (G:66), relative set (G:70)
4. reading (Reading S4), money (Money M4)
5. people (People P5), before comma sets and lifts as P5 needs
6. comma sets (G:73), named lift (G:76), kitchen (G:80)
7. **upkeep (new)**
8. reschedule (G:83), task (G:90)

People and upkeep share no verbs (P5 "Depends on"), so moving people ahead of upkeep changes no row. Upkeep after lifts keeps `did bench 80x8` a lift (row 36). Upkeep after kitchen needs one kitchen guard (row 29).

## Phrase rows

### Done, new and existing chores

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 1 | I | `changed the water filter` | "Changed the water filter." Same | AddChore(name: "Change the water filter", verb: changed, interval: nil), then DoChore at 15 Oct 18:00. One undo removes both | "Changed the water filter. How often?" | No numbers, no date, no prefix, so every rule misses and the model gets it today. No collision. The name is the base form of the verb plus the rest as typed | U4 table (`changed the sheets`), U4 rule (verb list), U1 |
| 2 | I | `descaled kettle` | "Descaled kettle." Same (risk: "de-scaled") | AddChore("Descale kettle", verb descaled), then DoChore | "Descaled kettle. How often?" | Model today. No collision. A hyphen from the transcriber ("de-scaled") misses the verb list. Proposal: the verb match ignores hyphens | U4 rule, U1 |
| 3 | I | `descaled the kettle` (after row 2) | "Descaled the kettle." Same | DoChore on the existing Descale kettle. No second chore | "Descaled kettle." | **Inside U1.** `chore(named:)` needs every word said as a whole word of the name. "the" is not in "Descale kettle", so the match fails and U1 makes a second chore "Descale the kettle". Resolves: drop `the`, `a`, `my`, `our` from the words before matching (the reschedule rule already drops `the`/`my`, G:142) | U1 (`chore(named:)`), U4 table (`watered the plants`) |
| 4 | I | `watered plants` | "Watered the plants." Same | DoChore(Water plants) at 15 Oct. Age 0 | "Watered plants. Was 6 days, usually 7." | Model today. Same article rule as row 3 for the spoken form | U4 eval 1 |
| 5 | I | `cleaned the oven` | "Cleaned the oven." Same | SetTaskDone on the open task "Clean the oven". No new chore | "Done: Clean the oven." | **Done verb vs completeTask.** Model today, which may call `completeTask` "the oven" (T:121). Resolves: an open task beats a new chore (GC rule 5). The upkeep rule checks open tasks by every word after turning the verb into its base form | U4 rule, U4 eval 9, GC rule 5 |
| 6 | I | `cleaned bathroom` | "Cleaned the bathroom." Same | DoChore(Clean bathroom) | "Cleaned bathroom. Was 21 days, usually 14." | Model today. No red, no "overdue" | U4 eval 10 |
| 7 | I | `took out the bins` | "Took out the bins." Same | DoChore(Take out the bins) | "Took out the bins. Was 7 days." | Model today. Two-word verb. No interval, so the line has no "usually" | U4 table, U2 (`ageLine`) |
| 8 | I | `took the bins out` | "Took the bins out." Same | DoChore(Take out the bins) | "Took out the bins. Was 7 days." | Model today. **Gap:** the verb list has `took out` and `topped up` only as a prefix. British word order puts the particle last. Proposal: a two-word verb also matches with its particle at the end ("topped the oil up") | Gap (U4 verb list) |
| 9 | I | `bins out` | "Bins out." Same | Proposal: DoChore(Take out the bins), because the noun names an existing chore and `out` is that chore's particle | "Took out the bins." | **Bare noun vs task.** No date, so not a task on master; model today. A task rule would need a date. Resolves: `<chore noun> out` binds only to an existing chore whose verb ends in that particle. With no such chore it goes to the model, never a new chore and never a task | Gap |
| 10 | I | `hoovered` | "Hoovered." Same (risk: "Hovered") | Proposal: AddChore("Hoover", verb hoovered), then DoChore. If a chore with verb hoovered exists, DoChore on it | "Hoovered. How often?" | Model today. **Gap:** a verb with no object has no name to match. A homophone ("hovered") misses the verb list and stays with the model, which is the safe miss | Gap (U4 verb list) |
| 11 | I | `hoovered and mopped the kitchen` | "Hoovered and mopped the kitchen." Same | Proposal: two check-ins in one ghost batch: AddChore("Hoover the kitchen") and AddChore("Mop the kitchen"), each done | "Hoovered the kitchen, mopped the kitchen." | Model today. **GC rule 3 (split on ` and `)** would give "hoovered" and "mopped the kitchen", and the first part loses its object. Resolves: when both parts start with a verb from the list and only the last has an object, the object is shared | Gap, GC rule 3 |
| 12 | I | `did laundry` | "Did laundry." Same | DoChore(Laundry) | "Did laundry." | **Question guard.** `did` is a lead word (G:97), so master sends it to the model as a question. Resolves: U4 narrows `did` to a lead only before `i`, `you`, `we`, `tess` | U4 eval 12, U4 slice text |
| 13 | I | `did the bins` | "Did the bins." Same | DoChore(Take out the bins). The line uses the chore's own verb | "Took out the bins. Was 7 days." | Question guard as row 12. After the fix, "the bins" matches "Take out the bins" by every word (with row 3's article rule, "bins" alone). `did X` never makes a chore named "Do the bins" when X matches an existing chore | U4 table (`did laundry`), U1 |
| 14 | I | `did 2 loads of laundry` | "Did two loads of laundry." to `Did 2 loads of laundry` | DoChore(Laundry), check-in note "2 loads" | "Did laundry, 2 loads." | Question guard today. After the fix, the lift rule skips "did" and "of" (G:285), reads 2 as the weight and finds no reps, so it fails and upkeep gets it. Proposal: a number plus a count noun after the chore is kept as the note, as `paid rent 650` does | U4 rule (number kept as note), U4 eval 12 |
| 15 | I | `defrosted the freezer` | "Defrosted the freezer." Same | AddChore("Defrost the freezer"), then DoChore | "Defrosted the freezer. How often?" | Model today. No collision | U4 rule (verb list) |
| 16 | I | `defrosted the chicken` | "Defrosted the chicken." Same | Proposal: no chore. Goes to the model | (the model's line) | **Upkeep vs kitchen.** `defrosted` is on the verb list, so U4 would make a chore "Defrost the chicken". Chicken is food, not upkeep. Resolves: when the object resolves to an ingredient (`IngredientBook.find`) and no chore matches, upkeep does not create one | Gap (U4 verb list) |

### Dates on done phrases

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 17 | I | `watered plants yesterday` | "Watered the plants yesterday." Same | DoChore(Water plants, at: Wed 14 Oct) | "Watered plants, Wed 14 Oct." | `yesterday` is not a `TessDates` word, so model today. The upkeep rule needs its own `yesterday`. The same word is needed by People (`met sam yesterday`), so it belongs in `TessDates` with a past flag | U4 eval 3 |
| 18 | I | `watered plants sat` | "Watered the plants on Saturday." to `Watered the plants on Saturday` | DoChore(Water plants, at: Sat 10 Oct) | "Watered plants, Sat 10 Oct." | **Done verb vs task.** Master: task "Watered plants", Sat 17 Oct 09:00 (G:414, G:90). Resolves: upkeep runs before the task rule, and a day cue after a done verb is the most recent past day. Spoken: "on" stays in the text, so upkeep must drop `on` before a day cue | U4 rule, U4 eval 4 |
| 19 | I | `watered plants thu` | "Watered the plants Thursday." Same | DoChore(Water plants, at: Thu 15 Oct) | "Watered plants." | Master: task "Watered plants", today 19:00 (G:437-443). **"thu" on a Thursday.** For a done verb, the most recent past Thursday must include today, or it lands on Thu 8 Oct. Same rule as Money's spend dates | U4 rule, `decisions.md` (a weekday that is today means today) |
| 20 | I | `water plants sun` | "Water the plants Sunday." Same | Task "Water plants", Sun 18 Oct 09:00. No check-in | "Water plants, Sun." | Correct on master today. Guard row: the plain verb never logs | U4 rule, U4 eval 5 |
| 21 | I | `bins out thu` | "Bins out Thursday." Same | Task "Bins out", today 19:00. No check-in | "Bins out, today 7 pm." | Master gives the same. **Bare noun vs task.** With a date the phrase is a plan, not a log, even though row 9 logs `bins out` with no date. Resolves: upkeep's noun form (row 9) never binds when `TessDates` finds a day or time | U4 rule, Decision 3, U4 eval 11 |
| 22 | I | `washed the car tomorrow` | "Washed the car tomorrow." Same | No check-in. Falls through to the task rule as Money does: task "Washed the car", Fri 16 Oct 09:00 | "Washed the car, Fri." | Master gives the same task. A done check-in is never in the future, so upkeep yields. The title keeps the past tense, which reads wrong. See open question 6 | U4 rule ("never in the future") |
| 23 | I | `car service due march` | "Car service due March." Same | Proposal: task "Car service", Mon 1 Mar 2027 09:00. Not a chore | "Car service, Mon 1 Mar." | Model today: no numbers, and `TessDates` has no months. **Gap:** a month with no day needs a date rule. People needs month names for birthdays (P5), so one month parser should serve both. `due` is dropped from the title. Without the month rule it stays with the model, never a chore | Gap (no slice dates a task by month) |

### Fine, interval, snooze and pause

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 24 | I | `plants fine` | "Plants are fine." to `Plants are fine` | ChoreFine(Water plants). Age 0, week count unchanged | "Plants: looked, fine. Counting from today." | Model today. Spoken: "are" must be skipped between the chore noun and `fine` | U4 table, U4 eval 6 |
| 25 | I | `checked the oil, fine` | "Checked the oil, fine." Same | ChoreFine(Top up the oil) | "Oil: looked, fine. Counting from today." | **Upkeep vs groceries.** Inferred: the comma list reaches the kitchen rule (K:51-57). "checked the oil" ends in the aisle word "oil", so it looks like groceries, and `checked` is not in the errand list (K:143). Master adds two grocery lines, "checked the oil" and "fine". Resolves: a comma list whose last item is `fine` or `ok` is never shopping, and `checked` joins the errand verbs | U4 table (`checked plants, fine`) |
| 26 | I | `plants every 10d` | "Plants every ten days." to `Plants every 10 days` | SetChoreInterval(Water plants, 10) | "Plants, every 10 days." | Model today ("10d" is not a number, so no lift). No collision | U4 table, U4 eval 7 |
| 27 | I | `water filter every 6 months` | "Water filter every six months." to `Water filter every 6 months` | Proposal: SetChoreInterval(Change the water filter, 180) once row 1 exists | "Water filter, every 6 months." | Model today (the lift reads 6 as a weight with no reps). **Gap:** the U4 table has days, `weekly` and weeks only. Proposal: `months` is 30 days each | Gap (U4 table) |
| 28 | I | `bins every thursday` | "Bins every Thursday." Same | Task, per Decision 3. Proposal: title "Bins every Thursday", today 19:00 | "Bins every Thursday, today 7 pm." | **Weekday interval vs task.** Master: task "Bins every", today 19:00. The weekday is lifted out of the title, which leaves "every" dangling. Resolves: keep the task (Decision 3), but `every <weekday>` stays in the title until recurring tasks land | Decision 3, U4 rule |
| 29 | I | `snooze plants` | "Snooze plants." Same | SnoozeChore(Water plants) until Fri 16 Oct 00:00 | "Plants tomorrow." | Model today. No collision | U4 table |
| 30 | I | `pause chores till sun` | "Pause chores till Sunday." Same | PauseChores(until: Sun 18 Oct 00:00) | "Chores paused till Sun. Ages hold." | **Pause vs task.** Master: task "Pause chores till", Sun 18 Oct 09:00. `pause` is not a reschedule verb (G:133), so that shape does not catch it. Resolves: upkeep runs before the task rule | U4 table, U4 eval 15 |
| 31 | P | `home` | "Home." Same | ResumeChores | "Chores back on." | Model today. In context I (nothing paused) `home` binds nothing and goes to the model. Guard: the kitchen shop words (K:28) do not include `home` | U4 table |

### Other domains

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 32 | I | `note descaled the kettle, took ages` | "Note, descaled the kettle, took ages." to `note: descaled the kettle, took ages` | Note "descaled the kettle, took ages". No check-in | "Noted." | **Note vs upkeep.** Note runs first (G:55) and keeps the text. Correct today. Guard row | U4 rule, U4 eval 2 |
| 33 | I | `did i water the plants` | "Did I water the plants?" to `Did I water the plants` | Question, no write. The answer comes from `UpkeepLedger` | "Watered 6 days ago." | Question today because of `did`. Must stay one after U4 narrows `did`: `i` follows it | U4 eval 13, GC rule 2 |
| 34 | I | `paid rent 650` | "Paid rent six fifty." to `Paid rent 6.50` | DoChore(Pay rent), check-in note "650". No spend, no set | "Paid rent, 650." | Typed: the lift reads 650 as a weight with no reps and fails, so model today. **Normaliser trap:** `paid` is a money cue (normaliser rule 8), so "six fifty" becomes 6.50 and the note is wrong. Resolves: rule 8 reads "N fifty" as N.50 only after `spent`, `cost` or a currency word, not after `paid` | U4 rule, U4 eval 14, Money M4 rule (`spent` only) |
| 35 | I | `spent 40 on a new water filter` | "Spent forty on a new water filter." to `Spent 40 on a new water filter` | LogSpend 40, no currency, note "a new water filter". No check-in | "Logged 40, new water filter." | **Upkeep vs Money.** Model today. Money runs first and takes `spent`. Money's category is the note's first word, which here is "a". Resolves on the Money side: drop leading articles before the category word, giving "new". Linking the spend to the chore is Later | Money M4 table, U4 Later |
| 36 | I | `did bench 80x8` | "Did bench eighty for eight." to `Did bench 80 x 8` | Lift Bench Press 80 x 8 | "Bench 80 x 8." | **Upkeep vs sets.** Master sends it to the model because `did` leads a question. After U4 narrows `did`, the lift rule runs before upkeep and skips "did" (G:285). Guard: upkeep must never see a phrase with a set shape | U4 slice text (order), GC rule 6 |
| 37 | W | `8` | "Eight." to `8` | Set 80 x 8 into Bench Press | "80 x 8." | Correct today (G:168). Relative sets run first, so no chore phrase ever sees it | U4 rule (live workout) |
| 38 | I | `read the gas meter` | "Read the gas meter." Same | Not a book, not a chore. Goes to the model | (the model's line) | **Reading vs upkeep.** Model today. The Reading S4 table queues a new book named "The gas meter" from `read X`. Resolves: `reading.md` open question 1 (`read X` creates a book only when nothing else matches and the phrase looks like a title). `read` is not on the upkeep verb list | Reading S4 table, GC rule 5 |
| 39 | I | `finished the ironing` | "Finished the ironing." Same | SetTaskDone on "Do the ironing" (the model today; a completion grammar later) | "Done: Do the ironing." | **Reading and completeTask.** Reading S4 binds `finished X` only to a book, so it passes. `finished` is not an upkeep verb, so no chore. The model calls `completeTask` "ironing", which matches by substring (T:263-275). Proposal: also add `ironed` handling for a later "ironing" chore | Reading S4 rule, U4 rule (fixed verb list) |
| 40 | I | `paid water bill 42.50` | "Paid water bill forty-two fifty." to `Paid water bill 42.50` | AddChore("Pay water bill", verb paid), DoChore, note "42.50". No spend | "Paid water bill. How often?" | Model today (weight 42.5, no reps). **Upkeep vs Money.** Money's bare-amount rule takes a two-decimal amount as a money shape. If that check scans the whole phrase, Money would log a spend here. Resolves: Money's bare form binds only when the amount comes first (`12.40 lunch`); `spent` is the only other way in | U4 rule (`paid rent 650`), Money M4 rule, Money Decision 2 |

Count: 40 rows. Slice cover: 33 rows cite a U4 table phrase, rule, eval row or decision (some also U1, U2, Reading S4 or Money M4); 7 are gaps (rows 8, 9, 10, 11, 16, 23, 27). Row 35 also proposes a fix on the Money side. Master already gives the expected result for 6 rows (20, 21, 22, 32, 33, 37), writes the wrong thing for 5 (18, 19, 25, 28, 30) and sends the other 29 to the model.

## Collisions with master's grammar and the specced domains

| Existing rule | Phrase that meets it | Today on master | Proposed rule |
|---|---|---|---|
| Question guard, `did` (G:97) | `did laundry`, `did the bins`, `did 2 loads of laundry`, `did bench 80x8` | All four go to the model as questions | `did` is a question lead only before `i`, `you`, `we`, `tess` (U4). `did i water the plants` stays a question (rows 12 to 14, 33, 36) |
| Task rule with a weekday (G:90, G:414) | `watered plants sat`, `watered plants thu` | Tasks for next Saturday and today 19:00 | Upkeep runs before tasks. A day cue after a done verb is the most recent past day, today included (rows 18, 19) |
| Task rule with a weekday (G:90) | `pause chores till sun` | Task "Pause chores till", Sun | Upkeep claims `pause chores` and `away till` before the task rule (row 30) |
| Task rule, plain verb | `water plants sun`, `bins out thu`, `washed the car tomorrow` | Tasks | Keep. A plain verb or a bare noun with a date is a task. A done verb with a future date yields to the task rule (rows 20 to 22) |
| Task rule, `every <weekday>` | `bins every thursday` | Task "Bins every", today 19:00 | Keep it a task (Decision 3); keep `every thursday` in the title (row 28) |
| completeTask, a model tool (T:121) | `cleaned the oven`, `finished the ironing` | Model, which may mark a task done | An open task that matches beats a new chore (GC rule 5). The grammar does it for upkeep verbs; other past tenses stay with the model (rows 5, 39) |
| Kitchen comma list (K:51-57) | `checked the oil, fine` | Groceries, 2 lines (inferred) | A trailing `fine` or `ok` item means not shopping; add `checked` to the errand verbs (K:143) (row 25) |
| Kitchen ingredients | `defrosted the chicken` | Model | Upkeep never creates a chore whose object is an ingredient (row 16) |
| Named lift (G:76) | `did bench 80x8`, `did 2 loads of laundry`, `paid rent 650` | Model (via the question guard, or no reps) | Lifts run before upkeep. A lone number after a chore with no reps is the check-in note (rows 14, 34, 36) |
| Relative set (G:70) | `8` in a workout | Set | Keep. Upkeep never sees bare numbers (row 37) |
| Note (G:55) | `note descaled the kettle, took ages` | Note | Keep (row 32) |
| Reading S4 (`read X`) | `read the gas meter` | Model | `read X` does not create a book from a non-title (reading.md open question 1) (row 38) |
| Money M4 (`spent`, bare amounts) | `spent 40 on a new water filter`, `paid water bill 42.50` | Model | `spent` always wins over upkeep. A bare two-decimal amount is a spend only when it leads the phrase. Money drops a leading article before picking the category (rows 35, 40) |
| Normaliser rule 8 | "Paid rent six fifty" | Would give `Paid rent 6.50` | `paid` is not a money cue for "N fifty" (row 34) |
| GC rule 3 (split on ` and `) | `hoovered and mopped the kitchen` | Model | Share the last object when both parts start with an upkeep verb (row 11) |
| U1 `chore(named:)` | `descaled the kettle` after `descaled kettle` | Would make a second chore | Ignore articles when matching (row 3) |

## Open questions

1. **Order of the new rules.** U4 says upkeep runs after comma sets, lifts and kitchen. P5 says people runs after upkeep but before comma sets, lifts and kitchen. Both cannot hold. Suggestion: reading, money, people, then comma sets, lifts and kitchen, then upkeep, then reschedule and tasks. People and upkeep share no verbs, so the order between them changes no row here.
2. **Particle at the end.** Accept `took the bins out` and `topped the oil up` (row 8)?
3. **Noun plus `out` or `done`.** Should `bins out` log the bins chore when it exists (row 9)? It must stay a task with a date (row 21).
4. **A verb with no object.** Should `hoovered` make a chore "Hoover" (row 10)? And should `hoovered and mopped the kitchen` share "the kitchen" (row 11)?
5. **Ingredients after a done verb.** Should `defrosted the chicken` stay with the model so no food chore is made (row 16)? A cooking follow-up (defrost for a meal) is a kitchen feature, not upkeep.
6. **Done verb with a future day.** `washed the car tomorrow` becomes a task titled in the past tense (row 22). Keep that, turn the title into the base form ("Wash the car"), or send it to the model?
7. **Months.** `car service due march` and `water filter every 6 months` need month words (rows 23, 27). Should a month with no day date the task on the 1st, or land in Later with the month shown? Is a month 30 days for intervals? One month parser should also serve People's birthdays.
8. **`yesterday` and past days in `TessDates`.** Upkeep, Money and People all need `yesterday` and "most recent past weekday, today included" (rows 17 to 19). Add a past mode to `TessDates` once instead of three copies?
9. **`every <weekday>` titles.** Keep "Bins every Thursday" as the task title until recurring tasks land (row 28)?
10. **Kitchen guard for `fine`.** Is a trailing `fine`/`ok` item enough to stop a comma list being groceries, or should upkeep's fine form run before the kitchen rule (row 25)?
11. **Normaliser money cue.** Drop `paid` from rule 8's "N fifty" cue (row 34)? `paid` stays a money cue for currency words ("paid 20 quid").
12. **Money's bare amount position.** Confirm that a two-decimal amount is a spend only at the start of the phrase, so `paid water bill 42.50` stays a chore with a note (row 40).
13. **Verb list gaps.** Words he may use that are not on the fixed list: serviced, replaced, tested, bled (radiators), cleared (gutters), sharpened, charged, renewed. Add any of these, or leave them to the model (Decision 6)?
14. **Spoken homophones.** "Hoovered" may come back as "hovered" and "descaled" as "de-scaled" (rows 2, 10). Measure on device before adding fuzzy matches.

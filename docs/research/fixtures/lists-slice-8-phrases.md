# Lists slice 8: Tess phrases for lists

For: Core (Lists slice 8, to turn into grammar tests), Kitchen lead, Product. Research lab, Product item T, 2026-10-16.

**Master traced:** `origin/master` at `40af0f1` (Merge #478). No file under `TesseraCore/Sources/TesseraTess/` or `TesseraCore/Sources/TesseraCore/Lists/` changed since `68c9a19`, the base of `lists-day-one.md`. Hand trace, nothing run. TG is `TessGrammar.swift`, K `TessGrammar+Kitchen.swift`, CE `TessCaptureEngine.swift`, TT `TessTools.swift`, TC `TessCapturing.swift`, SW `SecretWords.swift`, SL `Features/Command/SpeechListener.swift`, L `Lists/Lists.swift`.

**Sources.** `lists-day-one.md` (R17 to R25, top gap 4), `kitchen-phrases.md` rows 41 to 48, `ship-list-lists.md` slice 8, `lists-acceptance.md` block 8, `lists-screens-acceptance.md` (G6, G7, G9, 10.8 to 10.11), `starter-lists.md`, `lists-copy.md` (S1 to S8, D8 to D14), `decisions.md` (12:27 PM PT Oct 16, 7:17 PM PT Oct 15), and the row style of `grammar-regression.md` and `grammar-regression-group-n.md`. Rows already in the suite are named in the cell (A230, A231, A285).

**Rulings applied.** Receipts are thing first: "Charger, on Packing."; two things "Sunglasses and swimsuit, on Packing." (10.8); three or more "3 things on Packing." (copy D9). New list: "Films, new list." (copy S1). Day-one context line: "4 lists, nothing running". "done" on a reusable list finishes the run with the strikes kept and asks "Gym bag, done. Reset it for next time?" with RESET (0.7 s hold) or NOT NOW; nothing resets until RESET. The word is "put away", never "archive"; a plain list that finishes with nothing open is put away: "Packing, Lisbon put away." UNDO 10 s. A named list wins over Groceries; bare food items go to Groceries, and a Groceries receipt names Groceries once other lists exist ("Milk, on Groceries.", copy S8 and D10). UNDO 4 s for a capture, 10 s for a remove or a change. Rule 3 still holds: the process in front decides bare input, so a live workout or a cook wins over a waiting list.

**Context.** Clock Fri 16 Oct 2026 5:30 pm PT; Sat 17, Sun 18. Store: Groceries (14 open), the three starters from `starter-lists.md` (Gym bag, 10 items, reusable; Leaving the house, 6, reusable; Packing, 11, reusable: socks, t-shirts, underwear, pants, sweater, phone charger, adapter, headphones, passport, tickets, cards), Films (dune, heat, alien) and "Packing, Lisbon" (a copy of Packing, plain, not reusable). Contexts:
- **none**: Home, nothing running.
- **day one**: the store before he makes anything (Groceries plus the 3 starters).
- **page X**: list X's page is open, nothing running.
- **run X**: X is the running process (its page open). Master has no `StartListRun`, so Core's test sets `TessContext.process` to the list's id (TC:21); TG:224-269 has no branch for a list other than Groceries.
- **live workout**: Bench Press in focus, last set 80 x 8; Gym bag's run waits in the ledger.
- **cook**: Weeknight dal running; Packing's run waits in the ledger.
- **+Costco**: the store also has a plain list called Costco.

**Verdicts.** **pass**: master does what the row expects (for a guard row, it stays off lists). **wrong**: the grammar claims the phrase and writes something else, or the receipt line is wrong. **miss**: the grammar returns nil and the phrase goes to the model (on-device or Claude), which has `addToList` and `createList` but no run, reset, put away, remove or pick tool (TT:36), and whose list lookup is exact or prefix only (TT:285-291). `grammar-regression.md` counts "target [Lists 8] · now: nil" as pass; here a miss is measured against slice 8's target.

| id | phrase | context | expected parse | expected line | master today | verdict |
|---|---|---|---|---|---|---|
| L8-1 | `add charger to packing` | none | listAdd Packing [charger] (kitchen-phrases 42) | "Charger, on Packing." UNDO 4 s | nil: K:43-48 only takes Groceries targets; model `addToList` (TT:159-165); engine summary "Added charger" (L:143) | miss |
| L8-2 | `add charger to my packing list` | none | listAdd Packing [charger]; "my" and "list" dropped from the name | "Charger, on Packing." | nil; the model must strip "my … list" itself or TT:288 finds no list | miss |
| L8-3 | `put charger on the packing list` | none | listAdd Packing [charger] | "Charger, on Packing." | nil: TG:272 reschedule shape needs to/till/until, so it doesn't claim it | miss |
| L8-4 | `charger to packing` | none, spoken | listAdd Packing [charger] | "Charger, on Packing." | nil (K:43 has an optional verb but only Groceries targets) | miss |
| L8-5 | `packing: charger` | none | listAdd Packing [charger] (A285) | "Charger, on Packing." | nil: no rule for "name:" except groceries/shopping (K:49-50) | miss |
| L8-6 | `packing: charger, socks` | none | listAdd Packing [charger, socks] (kitchen-phrases 41); socks is already open on Packing, so one new row [Q3] | "Charger, on Packing." [Q3] | nil: neither item is in the aisle guide, so the comma rule (K:68-74) declines; model. `lists-day-one.md` R18 and `grammar-trace.md:19` (groceries) predate the shopping check | miss |
| L8-7 | `add sunglasses and swimsuit to packing` | none | listAdd Packing [sunglasses, swimsuit] | "Sunglasses and swimsuit, on Packing." | nil | miss |
| L8-8 | `add toothbrush, sunglasses and swimsuit to my packing list` | none | listAdd Packing [toothbrush, sunglasses, swimsuit] | "3 things on Packing." | nil: comma rule's last part "swimsuit to my packing list" is 5 words (K:163) | miss |
| L8-9 | `add socks to packing` | none | listAdd Packing [socks]; already open there, nothing new | "Socks, already on Packing." (as CE:335 for Groceries) | nil | miss |
| L8-10 | `add charger to packing tomorrow` | none | listAdd Packing [charger] dated Sat 17 [Lists 2], as A286 for Errands | "Charger, on Packing, tomorrow." [Q8] | task "Add charger to packing" Sat 17 9:00 am (K:22 date, then TG:513-543) | wrong |
| L8-11 | `add sun cream to packing` | none | listAdd Packing [sun cream] (A230) | "Sun cream, on Packing." | task "Add cream to packing" Sun 18 9:00 am: TG:528 reads "sun" as Sunday; K:206-214's short-weekday filter guards only the kitchen rules | wrong |
| L8-12 | `packing: charger, sun cream` | none | listAdd Packing [charger, sun cream] | "Charger and sun cream, on Packing." | groceries ["packing: charger", "sun cream"] ("cream" alone is Dairy, Aisles.swift:50-57), "2 things on the list." (CE:337) | wrong |
| L8-13 | `packing: bobby pins` | none | listAdd Packing [bobby pins]; no secret value, so a list shape wins (P1204, as N939) | "Bobby pins, on Packing." | privateNote "Packing: bobby pins" (SW:11 "pins"; TG:505-508 lets only a lead verb through) | wrong |
| L8-14 | `charger` | page Packing | listAdd Packing [charger] (G6) | "Charger, on Packing." UNDO 4 s | nil: `TessContext` has no page (TC:12-21) | miss |
| L8-15 | `sunglasses, swimsuit` | page Packing | listAdd Packing [sunglasses, swimsuit] (G6) | "Sunglasses and swimsuit, on Packing." | nil (comma rule finds no shopping item) | miss |
| L8-16 | `add charger` | page Packing | listAdd Packing [charger] (the page names the list) | "Charger, on Packing." | nil (K:50 takes only "add to groceries") | miss |
| L8-17 | `buy plasters` | page Packing | groceries [plasters] ("buy" still means Groceries, G7) | "Plasters, on Groceries." (copy D10) | groceries [plasters], "Plasters, on the list." (CE:337) | wrong |
| L8-18 | `milk` | page Packing | listAdd Packing [milk] under G6; Groceries under "bare food goes to Groceries" [Q1] | "Milk, on Packing." or "Milk, on Groceries." [Q1] | nil (a bare word with nothing running has no rule) | miss |
| L8-19 | `new list films` | none | list "Films" (A231 shape) | "Films, new list." (copy S1) | list "Films", "New list: Films." (K:24-26, CE:355) | wrong |
| L8-20 | `list: lisbon` | none | list "Lisbon" | "Lisbon, new list." | list "Lisbon", "New list: Lisbon." (CE:355) | wrong |
| L8-21 | `make a list for lisbon` | none | list "Lisbon" | "Lisbon, new list." | nil: K:123-137 reads "make" as cook, finds no recipe, and only "cook X" becomes a task; model `createList` | miss |
| L8-22 | `copy packing for lisbon` | none | CopyList Packing as "Packing, Lisbon", every item open [Lists 4] | "Packing, Lisbon, new list." [Q6] | nil; no copy op or tool | miss |
| L8-23 | `new list lisbon fri` | none | list "Lisbon"; the day has no home on a list [Q4] | "Lisbon, new list." | list "Lisbon fri": K:24-26 runs before any date check | wrong |
| L8-24 | `run gym bag` | none | StartListRun Gym bag; the page opens running (G2) | "Gym bag, 10 left." (as the shop's "Shopping, 9 left.") | nil; no run op (only `StartShop`, K:28-31) | miss |
| L8-25 | `start the gym bag` | none | StartListRun Gym bag | "Gym bag, 10 left." | nil | miss |
| L8-26 | `pack` | none | run the only list starting "pack" (kitchen-phrases 45); with Packing and "Packing, Lisbon" both there, ask [Q5] | "Packing, or Packing, Lisbon?" [Q5] | nil | miss |
| L8-27 | `run errands sat` | none | task "Run errands" Sat 17, no time [N1]; never a list run (no list called Errands) | "Run errands, Saturday." | task "Run errands" Sat 17 9:00 am | pass |
| L8-28 | `got socks` | run Gym bag | CheckListItem Gym bag "socks" | "Socks, done." (copy S3) | nil: "got" is a past verb but TG:322-331 needs a day; K:50 knows "get", not "got" | miss |
| L8-29 | `socks done` | run Gym bag | CheckListItem Gym bag "socks" | "Socks, done." | nil | miss |
| L8-30 | `packed passport` | run Packing, Lisbon | CheckListItem "passport" on Packing, Lisbon | "Passport, done." | nil (past log needs a day) | miss |
| L8-31 | `done` | run Gym bag (reusable, 2 open) | FinishListRun Gym bag, strikes kept; asks, writes no reset (10.11) | "Gym bag, done. Reset it for next time?" RESET (0.7 s hold) or NOT NOW | nil: TG:224-269 has no list branch; "done" means something only in a cook (TG:232) or a shop (TG:248) | miss |
| L8-32 | `done` | run Packing, Lisbon (nothing open) | FinishListRun, then put away (G9) | "Packing, Lisbon put away." UNDO 10 s | nil | miss |
| L8-33 | `done` | run Packing, Lisbon (3 open) | FinishListRun; stays on the shelf, not put away | not given [Q7] | nil | miss |
| L8-34 | `done` | none | nil; nothing runs, so no list action | none (model) | nil | pass |
| L8-35 | `done` | live workout | nil (the workout's, as G586); Gym bag's run stays in the ledger untouched | none | nil: TG:235-241 claims only rest/timer; `parseLive` reads no "done" | pass |
| L8-36 | `done` | cook | cookStep finish (A187); Packing stays in the ledger | the cook's line | cookStep finish (TG:231-233) | pass |
| L8-37 | `reset gym bag` | none | UncheckAll Gym bag (kitchen-phrases 46), one op; never `ClearDoneItems` (L:256-277 deletes) | "Gym bag, reset." UNDO 10 s [Q2] | nil; no reset op or tool | miss |
| L8-38 | `reset` | page Gym bag | UncheckAll Gym bag | "Gym bag, reset." UNDO 10 s | nil | miss |
| L8-39 | `reset the oven timer` | none | nil; never a list reset (no list called "the oven timer") | none | nil: K:101-102 needs a number | pass |
| L8-40 | `put away lisbon` | none | PutAway "Packing, Lisbon" (engine `archive`) | "Packing, Lisbon put away." UNDO 10 s | nil (TG:272 needs "to") | miss |
| L8-41 | `archive films` | none | PutAway Films; the line never says "archive" | "Films put away." UNDO 10 s | nil | miss |
| L8-42 | `put away groceries` | none | nil: the chore, never a list action (Groceries can't be put away, `lists-acceptance.md` 1) | none | nil | pass |
| L8-43 | `lists` | day one | open the shelf (G1), no write | shelf context line "4 lists, nothing running" | nil, model (`lists-day-one.md` R4) | miss |
| L8-44 | `show lists` | run Gym bag | open the shelf | context line "6 lists, Gym bag running" [Q9] | nil ("show" asks only as "show me/my/all", TG:220) | miss |
| L8-45 | `show my lists` | none | open the shelf | "6 lists, nothing running" | nil: question guard (TG:82, TG:220), model's read-only answer | miss |
| L8-46 | `add charger to holiday` | none | no write, no list made (lists-acceptance 8) | "No list called holiday." | nil; TT:290 throws "no list called holiday" to the model, which may make the list | miss |
| L8-47 | `add sunglasses to lisbon` | none | listAdd "Packing, Lisbon" [sunglasses]: the only list with the word Lisbon [Q6] | "Sunglasses, on Packing, Lisbon." [Q6] | nil; TT:288-289 matches exact or prefix only, so "lisbon" finds no list | miss |
| L8-48 | `gym bag: banana, hair ties` | none | listAdd Gym bag [banana, hair ties]: the named list wins over the food word | "Banana and hair ties, on Gym bag." | groceries ["gym bag: banana", "hair ties"] (banana is Produce) | wrong |
| L8-49 | `add hair ties to gym bag` | live workout | listAdd Gym bag [hair ties]; never a set; the workout keeps Now | "Hair ties, on Gym bag." | nil: `parseInFocus` (TG:161-209) declines with no number; model | miss |
| L8-50 | `gym bag 7pm` | none | task "Gym bag" Fri 16 7:00 pm; never a run | "Gym bag, 7:00 pm." | task "Gym bag" Fri 16 7:00 pm | pass |
| L8-51 | `costco: paper towels, eggs` | none, +Costco | listAdd Costco [paper towels, eggs]: a named list wins | "Paper towels and eggs, on Costco." | groceries ["costco: paper towels", "eggs"] (egg is Dairy) | wrong |
| L8-52 | `add eggs to costco` | none (no Costco list) | no write: "No list called costco." under slice 8; Groceries if a shop name means Groceries [Q10] | "No list called costco." [Q10] | nil, model | miss |
| L8-53 | `add milk` | none | groceries [milk] (bare food goes to Groceries) | "Milk, on Groceries." | nil: K:50 takes only "add to groceries"; model `addGroceries` | miss |
| L8-54 | `add milk to packing` | none | listAdd Packing [milk]: a named list wins | "Milk, on Packing." | nil | miss |
| L8-55 | `add milk to groceries` | none | groceries [milk] (kitchen-phrases 43) | "Milk, on Groceries." | groceries [milk] (K:43-48), "Milk, on the list." (CE:337) | wrong |
| L8-56 | `milk, eggs, socks` | none | groceries [milk, eggs, socks]; one list per phrase, "move to packing" fixes it (G7) | "3 things on Groceries." | groceries [milk, eggs, socks], "3 things on the list." (CE:337) | wrong |
| L8-57 | `shopping list: rice, beans` | none | groceries [rice, beans] (decisions.md: "adds two grocery rows") | "Rice and beans, on Groceries." | groceries ["shopping list: rice", "beans"]: K:50 knows "shopping:" but not "shopping list:", so the comma rule keeps the label in the first item | wrong |
| L8-58 | `undo` | none, spoken, just after L8-1 | UNDO on the add, inside its 4 s | "Charger taken back." (copy D9) | SL:243-246 hears "undo" and taps UNDO | pass |
| L8-59 | `undo` | none, typed, just after L8-1 | UNDO, the same as the spoken word | "Charger taken back." | nil: the typed word reaches the grammar and the model, which has no undo tool | miss |
| L8-60 | `undo that` | none, spoken, just after L8-1 | UNDO | "Charger taken back." | nil: SL:245 matches only "undo" and "take that back" whole | miss |
| L8-61 | `take socks off packing` | none | removeListItem Packing "socks" (10.10) | "Socks, removed." UNDO 10 s; UNDO "Socks, back on Packing." | nil; no remove tool | miss |
| L8-62 | `pick from films` | none | pick one open item from Films (kitchen-phrases 47); never checks it | not given [Q11] | nil | miss |
| L8-63 | `pack for lisbon friday` | none | task "Pack for lisbon" Fri 16, no time [N1]; never a run of Packing or a list | "Pack for lisbon, Friday." | task "Pack for lisbon" Fri 16 6:00 pm (TG:680-684, the next whole hour) | pass |
| L8-64 | `pay 40 for socks` | none | money [MU2]; never a list add or groceries | ask "$40 for socks?" [MU2] | nil, walled (TG:116-121, `isMoney` K:81-86) | pass |

**Counts (64 rows):** 10 pass (L8-27, 34, 35, 36, 39, 42, 50, 58, 63, 64), 13 wrong (L8-10, 11, 12, 13, 17, 19, 20, 23, 48, 51, 55, 56, 57), 41 miss. Of the 13 wrong, 8 write the wrong thing (L8-10, 11, 12, 13, 23, 48, 51, 57) and 5 write the right thing with the wrong line (L8-17, 19, 20, 55, 56). Most of the passes are guard rows that must stay green once the list rules land.

## Top misses

1. **No "add X to <list>" or "<list>: X" rule for any list but Groceries** (K:43-50). Every add row misses or goes wrong (L8-1 to L8-16). One rule should read verb (add, put, optional), items (comma and "and" split, K:217), a joiner (to, on, onto), an optional "the" or "my", the list name, and an optional "list"; plus the colon form. Resolve the name against `ListContents.lists()` before the Groceries and comma rules, so a named list wins (L8-48, L8-51, L8-54), and say "No list called X." when nothing matches instead of handing the model a phrase it may answer by making a list (L8-46).
2. **The colon form loses to food words, secret words and dates.** "packing: charger, sun cream", "gym bag: banana, hair ties" and "costco: paper towels, eggs" become Groceries with the label glued to the first item (L8-12, L8-48, L8-51; also "shopping list: rice, beans", L8-57); "packing: bobby pins" becomes a private note (L8-13); "add sun cream to packing" becomes a Sunday task (L8-11, A230, RC10). A list-name match must run before `parseSecret`'s no-value fall-through, the comma rule and `parseTask`, and `parseTask` needs K:206-214's short-weekday filter.
3. **No page or run context in `TessContext`** (TC:12-21). G6's bare-phrase rule (L8-14 to L8-16), check-off by phrase (L8-28 to L8-30), "reset" alone (L8-38) and every "done" on a list (L8-31 to L8-33) need the open page and a list run as the process; TG:224-269 needs a list branch after cook and workout, so the live workout and the cook keep winning (L8-35, L8-36 pass today and must stay green).
4. **No run, reset, put-away, remove or pick ops or phrases** (L8-24 to L8-26, L8-37, L8-40, L8-41, L8-61, L8-62). The model has no tool for any of them (TT:36), so today these reach Claude or the on-device model and come back "Didn't catch that." or a guess. Reset must be its own uncheck-all op, never `ClearDoneItems` (`lists-day-one.md` gap 2).
5. **Receipts are verb or label first.** "New list: Films." (CE:355) and "Milk, on the list." (CE:337) need "Films, new list." and "Milk, on Groceries."; the engine's "Added charger" (L:143) needs "Charger, on Packing." (L8-17, L8-19, L8-20, L8-55, L8-56).
6. **"new list lisbon fri" keeps the day in the name** (L8-23, K:24-26). Until lists can carry a day, strip a trailing day word or send the phrase to a task; Product's call (Q4).
7. **Typed "undo" and spoken "undo that" don't undo** (L8-59, L8-60). Small, general, and the first thing he'll say after a wrong list.

## Questions for Product

1. **G6 against "bare food goes to Groceries" (L8-18).** On the Packing page, does a bare "milk" go to Packing (G6: a bare item on a list page goes to that list) or to Groceries? Research's default: G6 wins on a list page (he chose the page), and "buy milk" is how he reaches Groceries from there (L8-17).
2. **Reset by phrase (L8-37).** "reset gym bag" is explicit: does it reset at once with UNDO 10 s, or ask with the RESET hold like "done" does? Default: at once with UNDO 10 s, since he said the word; the hold exists because "done" didn't.
3. **An item already open (L8-6, L8-9).** Starter Packing already has socks. Default: nothing new, "Socks, already on Packing." as Groceries does (CE:335); with several, only the new ones land and the line counts those. And "charger" when "phone charger" is open: a new row (default), or the same thing?
4. **A day on a new list (L8-23, `lists-day-one.md` Q4).** "new list lisbon fri": drop the day, keep it in the name, or make a task? Default: list "Lisbon" and the day dropped, until lists can carry one.
5. **"pack" with two lists starting "pack" (L8-26).** Kitchen-phrases row 45 assumed one. Default: ask "Packing, or Packing, Lisbon?" with the two names as ink words.
6. **Matching a copied list's name (L8-22, L8-47).** Should "lisbon" find "Packing, Lisbon" (any whole word, when only one list has it)? Default yes. And the copy's receipt: "Packing, Lisbon, new list." reads awkwardly with the comma in the name; is "Lisbon, copied from Packing." better?
7. **"done" on a plain list with items still open (L8-33).** The run ends and the list stays. Line? Copy D14 proposed "Packing, done. 9 of 9." Default: "Packing, Lisbon, done. 3 left."
8. **A dated add (L8-10).** "add charger to packing tomorrow" adds a dated item (slice 2), as A286 does for Errands. Line: "Charger, on Packing, tomorrow."?
9. **Context line with a running list (L8-44).** "6 lists, Gym bag running" (names keep their case, copy D1) or "gym bag running" (Design's sheet)? Open since `lists-day-one.md` Q1.
10. **Shop names (L8-52).** With no Costco list, "add eggs to costco" says "No list called costco." (slice 8), or do shop names (Costco, Target, Trader Joe's) mean Groceries? Default: the slice 8 line; he can make a Costco list.
11. **"pick from films" by phrase (L8-62).** Does Tess say the pick ("Heat, from Films.") or open the pick moment (screen 12)? Default: open the moment when Films is on screen, else the line.

# Kitchen sides (Design 75): rulings and acceptance

*Kitchen lead, 2026-10-16, on Design's sheet 75 `every-side.md` (25b385e) after Kaushik's 2:20 PM house principle (every screen has a side; decisions 2:24 and 2:41 PM). Five calls were the Kitchen lead's. Each ruling below is the rule Design folds into 75 and the row the Kitchen lead checks when the screen lands. A side holds facts and links and at most one key; nothing on a side goes to Claude except the one fill ask in section 2. Product can overrule any line.*

## 1. Groceries, and at the shop: FOR WHAT (LINKS)

Accepted. The side groups the open rows under the cook each is for, in short names by day ("TACOS, THURSDAY", "DAL, FRIDAY": a comma, since " · " is for a pack size only, copy-pass rule 8, Design sheet 77), soonest cook first; rows with no share sit last under "Just because", and USUALLY rows under "Usually". A row with two shares shows once, under the soonest cook, with the other cook as a label ("also dal"). Checked rows stay in their group, struck, until the shop clears them. The context-line word is FOR WHAT; the way back is GROCERIES. At the shop (a live surface) the same content is a peek over the column, never a page. REMOVE (Design 65) stays the row's own swipe on the front and on the side. Tess's line: "7 for 2 cooks, 3 just because." (counts only, from the shares).

| # | Pass when |
|---|---|
| 1.1 | With tacos (Thu) and dal (Fri) planned and 3 plain rows, the side shows TACOS, THURSDAY first, DAL, FRIDAY, then JUST BECAUSE with 3; the counts match the front's "14 to buy" |
| 1.2 | A row shared by both cooks appears once under Tacos with "also dal" |
| 1.3 | At the shop the side is a peek; DONE and the basket stay under it |
| 1.4 | A left swipe on a row still removes; a swipe past 60 pt on the context line or an empty area opens the side; the word always works |

## 2. An ingredient: PER 100 G (FACTS), and where it's used

**The table.** The phone carries no food table today, and nutrition was "only if he asks" with licensing first (`kitchen-v2-backlog.md`). His 2:20 example ("a grocery item shows calorie info") is the ask. The source is **USDA FoodData Central** (Foundation Foods and SR Legacy), a US government work in the public domain, so it ships inside the app with no licence text to carry; Research confirms the licence line and picks the subset before Core bundles it. The bundle is small: one row per ingredient key the app already knows (the aisle and alias list, a few hundred), with energy (kcal), protein, carbohydrate, fat and fibre per 100 g, and the source shown on the side as "USDA FoodData Central". No per-serving maths, no totals per recipe, no daily totals anywhere: a food's facts are public facts about the food, and the moment the app adds them up it becomes a body fact (intake is walled, `private-health-words.md` BW88), so the app never adds them up.

**The build (Research `food-table-usda.md`, `fixtures/food-table-20.json`).** Licence: CC0 1.0, public domain, FDC asks only to be listed as the source; the suggested citation goes on the app's licences page, the side shows "USDA FoodData Central". The subset is master's 271 keys (`AisleGuide.guide`), one whole record per key: a Foundation record only when it publishes kcal under nutrient 1008 and the other four; otherwise that key's SR Legacy record, whole, never a mix of two records. Energy is 1008 only; 2047 and 2048 (Atwater) are never used, silently or otherwise. A key with no usable record is absent and the side is complete without it. Core re-checks the 20 fixture rows against the FDC CSV before bundling, since Research read them through a summarising fetch; each bundled row keeps its FDC id and data type.

**Claude may fill a missing row** only as sheet 75 §3 says, with these Kitchen limits: only for a named food with no table row, asked once per ingredient key, the ask carries the ingredient's key and nothing else (no note, no recipe, no amount), the answer lands wet with "From Claude, Oct 16" and dries, and the row is kept on the Ingredient object. Never for an ingredient on a private recipe or one that holds a secret word, never when "Tess asks Claude" is off (the side is complete without the row), and never re-asked after NOT NOW.

**Where it's used** lists the recipes that hold the ingredient (short names), then USUALLY's sentence when it has one. Tess's line: "You buy it about every 9 days." when USUALLY knows, else the count of recipes, else empty.

| # | Pass when |
|---|---|
| 2.1 | Chicken thigh shows "121 kcal", "19.7 g protein", "0 g carbohydrate", "4.1 g fat", "0 g fibre" per 100 g with "USDA FoodData Central" under them (fixture row, FDC 173627, stored fat 4.12); the other 19 fixture keys match their rows |
| 2.1c | The side rounds for display only: kcal as a whole number, grams to one decimal ("4.1 g fat", "0 g fibre", never "0.0 g"); the bundled row keeps the FDC value unrounded and tests compare the stored value, not the shown one. The side shows one ingredient's values, never a sum (Research SA-P100, `drawn-sides-acceptance.md`) |
| 2.1b | No bundled row carries energy from 2047 or 2048; every row's FDC id resolves to a record of the stated data type |
| 2.2 | An ingredient with no row and Claude off shows only where it's used; nothing says the row is missing |
| 2.3 | With Claude on, the first open of a rowless ingredient asks once; KEEP writes the row with "From Claude, Oct 16"; NOT NOW is remembered; the request body holds the key only |
| 2.4 | No screen anywhere sums these numbers for a recipe, a day or a shop; Review and Home never mention calories |
| 2.5 | An ingredient on a private recipe never asks Claude and shows the table row if there is one |

## 3. Recipe original: COOKS (BEFORE)

Accepted. One line per cook, newest first: the day in words, how long (from the cook's start to DONE; "left open" when it was never finished), the serves it was cooked for when scaled, and the cook note when one exists. A skipped plan is not a cook and does not appear. Tess's line: "Cooked 4 times, about 45 min." (the median of finished cooks; empty under 2 cooks).

| # | Pass when |
|---|---|
| 3.1 | D1 cooked Thursday in 46 min, then Saturday for 6 in 52 min: the side lists Saturday first, "for 6", both durations |
| 3.2 | An abandoned cook reads "left open"; a skipped plan is absent |
| 3.3 | Tess's line is empty at 1 cook and "Cooked 2 times, about 49 min." at 2 |

## 4. A recipe: INGREDIENTS (PARTS), Design 69

Accepted as decided at 2:41 (b): the ingredient column's send-to-Groceries swipe moves to the side, whose one key is ADD N TO GROCERIES with N from the dry run (#419 ruling 2), the receipt "Chicken, 7 added." and UNDO 10 s; at 0 the key is absent. During a cook the side is the peek over the clock (sheet 75 rule 7, 69's peek), with used rows at 42%. Tess's line on the side: "7 to buy, 3 at home." once Pantry knows; until then "7 to buy." or empty at 0.

| # | Pass when |
|---|---|
| 4.1 | The column no longer swipes; the side opens by swipe or INGREDIENTS and its key reads ADD 7 TO GROCERIES for D1 on an empty list |
| 4.2 | During a cook the side is a peek over the clock and the bead keeps walking |

## 5. The Kitchen tab's side

THE WEEK'S COOKS (AHEAD, sheet 74) now, and it stays that way when Pantry arrives. Pantry is an area of his own (his 9:47 AM pick: a place that knows what a recipe needs against what he has), so it gets a front of its own and its own side, not a slot behind the Kitchen tab; "PANTRY later" comes out of row 13. Pantry's own side is Design's to draw after a week of v1 (the natural one is OUT AND LOW, the pantry's AHEAD). THE WEEK'S COOKS lists the planned cooks by day with each one's "N to buy", and Tess's line counts them: "3 cooks this week, 8 to buy."

| # | Pass when |
|---|---|
| 5.1 | The Kitchen tab's side lists the week's planned cooks by day with "N to buy" each; a day with no cook is absent |
| 5.2 | Nothing on the Kitchen tab's side changes when Pantry ships |


## Glances (Kaushik 2:33 PM: every side opens on a half-screen glance as stop 1)

| Side | Glance | Why |
|---|---|---|
| FOR WHAT | "7 for 2 cooks", then "Tacos and chili" and "3 just because" (sheet 77); foot ALL LINKS | Drawn in sheet 77: the cooks named, the leftovers counted, so the three lines add up to the front |
| PER 100 G | kcal big, then protein and fat; carbohydrate and fibre wait for the full side; the source line sits under the glance | Design's draft, with the source always visible since the number came from somewhere |
| COOKS | The last cook with its day and duration: "Thursday, 46 min" | Design's draft, with the duration so the glance says something the front does not |
| INGREDIENTS | "7 to buy" with the key ADD 7 TO GROCERIES; at 0, "Nothing to buy." and no key | Changed from "12 things": the glance's number and the key's number must be the same number, and the thing-count is already on the front |
| THE WEEK'S COOKS | The next cook in Home's own words: "Tacos tonight, 2 to buy." | Changed from "the next cook" alone: Tess's line and Home never disagree, so the glance is Home's line for that cook |

**Everywhere:** the way back is the front's name; sides never carry controls beyond the one key named above; Reduce Motion is a 150 ms crossfade (sheet 78); Dynamic Type at AX sizes keeps one column. Each Kitchen side lands in its own PR with a recording that starts on the front and turns it over.

## 6. Pantry: its front and its side (draft; Design's sheet 77 draws it)

*Pantry is an area of his own. The front is `pantry-acceptance.md` (counts line, out / low / in groups by aisle, swipe left adds to Groceries). This is the side, drafted from decisions 2:36 so Design can draw against it. The pass rows stay valid whatever the drawing looks like.*

**The Pantry side is OUT AND LOW.** What the phone thinks he is out of or low on, as a plain list for a shop, with when each was last bought. Glance (sheet 78): "4 out", "2 low" and "6 to buy", foot ALL OF THEM, kind AHEAD, the one key ADD 6 TO GROCERIES (the same dry-run count as the recipe peek key; at 0, "Nothing out." and no key). Nutrition never appears here (`never-sums-audit.md` N6).

| # | Pass when |
|---|---|
| 6.1 | The front's counts line ("4 out, 2 low") and the side's glance ("4 out", "2 low") give the same numbers, and "6 to buy" equals the key's number |
| 6.2 | The side lists out lines first, then low, each as one line: name and "bought Sat" when known; unknown ingredients are never listed |
| 6.3 | The key adds every listed line to Groceries in one op and gives the receipt "Pantry, 6 added." with one UNDO (4 s, a new add; the state-word tap "Limes, in." is a change and gets 10 s); a line already on Groceries is not added twice, and the key's number counts only new rows |
| 6.4 | With nothing known, the side opens on "Nothing known yet." and no key; no empty-state art |
| 6.5 | The side holds no per-line controls; tapping a line opens its Ingredient page, where the state word cycles in, low, out |
| 6.6 | Pantry's side is its own: the Kitchen tab's side stays THE WEEK'S COOKS before and after Pantry ships (row 5.2) |
| 6.7 | Nothing in Pantry or its side is sent to Claude; the AI-12 pack snapshot carries no state and no bought date (`pantry-acceptance.md` Core 7) |
| 6.8 | Reduce Motion is a 150 ms crossfade (sheet 78, `pantry-acceptance.md` S16, K26.7); Dynamic Type at AX sizes keeps one column; no pill, card or badge anywhere, and no notification (`pantry-acceptance.md`, Defaults taken) |

## 7. Sheet 77 rows: Groceries FOR WHAT, Recipe COOKS, Paste WHAT I READ

*From Design `sides-77.md`. Tess's line sits in her band at the glance and the full side, the same line at both stops. Digits, "and N more" from four, no controls, Reduce Motion a 150 ms crossfade.*

| # | Pass when |
|---|---|
| 7.1 | FOR WHAT groups name the cook and the day in capitals with a comma: "TACOS, SUNDAY", "CHILI, TUESDAY", soonest first, then JUST BECAUSE and one USUALLY line; " · " appears only in a pack size |
| 7.2 | A row for two cooks shows once, under the sooner cook, with "also chili" on it; the glance counts it once ("7 for 2 cooks" never counts a shared row twice) |
| 7.3 | Tess says "7 for 2 cooks, 3 just because." at both stops; with no just-because rows she says "7 for 2 cooks."; with no plan she says nothing and the side opens on JUST BECAUSE alone |
| 7.4 | Recipe COOKS lists each cook newest first with how long it took ("46 min", "1 h 1 min"); the glance reads "N times", the last cook's day and duration, and "about N min" |
| 7.5 | The "about" figure and Tess's "Cooked 4 times, about 45 min." use the median of the recorded durations; with fewer than 2 cooks Tess says nothing and the glance shows no "about" line |
| 7.6 | A cook with no recorded duration is listed by day only and left out of the median |
| 7.7 | Paste WHAT I READ lists all lines in order: kept lines plain, a plain ignored line with its words dim and "ignored"; a private or secret-looking line shows only a bar and "ignored", never its words (the wall also stops it reaching Claude); the glance counts kept and ignored ("14 lines kept", "3 ignored") and Tess says "14 of 17 lines kept." |
| 7.8 | None of these sides shows nutrition or any total of food values (`never-sums-audit.md`) |


**COOKS median and long cooks (Kitchen ruling, from Research `docs/ai/side-line-helpers.md` §4).** The helper drops any cook longer than 6 hours from the median because a cook set aside and resumed includes its pause. An overnight recipe (overnight oats, a 6 h 55 min cook) is legitimately long, so the cutoff cannot be a flat 6 hours for those.

| # | Pass when |
|---|---|
| 7.9 | The COOKS list shows every finished cook with its duration, long ones included ("6 h 55 min"); only the median skips cooks it judges implausible |
| 7.10 | The cutoff is 6 hours, except for a recipe whose own total time (`totalMinutes`) is 6 hours or more, where the cutoff is twice that total; overnight oats with three cooks of 6 h 55 min, 7 h 10 min and 6 h 40 min gives a median of 6 h 55 min, not nil |
| 7.11 | A planned-cook "to buy" count sums distinct rows, so a row two cooks share counts once, matching row 7.2 and the Groceries front |

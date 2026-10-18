# Kitchen K87: code-read walk of the merged Groceries screen

*Kitchen lead helper, 2026-10-17, against `master` a4f1d98 (read-only; the app was not run and no tests were run, so nothing here is a recording, a screenshot or a test result). Format follows `kitchen-pantry-screen-walk-oct17.md`. Rows walked: `groceries-side-acceptance.md` (GS1 to GS16), `groceries-ai-acceptance.md` (AI-12: sections 2 to 7, Core done-when, Builder B beats), `meal-plan-groceries-acceptance.md` (engine script, Kitchen week rulings, MP-F1 to MP-F7), `kitchen-refill6-lane1-acceptance.md` (K34.7, K34.8, K36.1 to K36.22, K37.6; K35 is cook-mode timers and holds no Groceries row, so it is not walked), `kitchen-refill9-lane1-acceptance.md` (K63), `kitchen-error-states-acceptance.md` (the Groceries rows ER9 to ER12, ER25) and 17 sampled rows of `kitchen-misfire-rows.md`. Verdicts: **PASS** (the code does what the row says), **FAIL** (built, but it deviates or part of the row is missing), **NOT BUILT** (the thing the row tests does not exist), **NOT PROVABLE** (cannot be settled by reading; named in each note). "Asserted by test" means a test in the tree asserts it; I read the assertion and did not run it.*

**The headline.** What is merged is the pre-Design-47 Groceries page: aisles in walk order, an Add line, strike-and-sink into a basket fold, a hold-the-title shop mode with a private-row mask, and a sage dab with a long-press "for tacos". The AI-12 layer (planning lands rows, the link ask, USUALLY, the FOR WHAT side, the wall on the Add line) and the K36 aisle drag are not in the tree.

## What is merged

| File | What it is |
|---|---|
| `Features/Groceries/GroceriesView.swift` (802 lines; 751 to 802 is the DEBUG-only `KitchenDemo`) | The page: context line (`:66`, `GroceriesCopy.context` `:736-743`), hold-the-title hero (`ShopTitle` `:339-387`), Add line (`:390-420`, `add()` `:220-229`), `AisleSection` (`:423-451`), `GroceryRow` with sage dab and long-press "for tacos" (`:455-510`), `AtTheShop` (`:514-565`), fold and rise transitions (`:570-609`), `BasketFold` (`:613-668`), `TessNoteLine` (`:672-703`), `GroceriesEmpty` (`:705-718`) |
| `Features/Groceries/ShopTrip.swift` (68 lines) | Private-row mask: "Private item" until the first tap, strike on the second, masked again on leaving (`:23-48`, `:57-59`; superseded by G102, Oct 17: no reveal, first tap strikes); `walkOrder` (`:62-67`, no view calls it) |
| `TesseraCore/.../Kitchen/Groceries.swift` (512 lines) | The one list: `aisles()` in walk order (`:87-103`), `isOn` (open rows only, `:106-112`), `toBuy(for:)` (`:115-121`), `share(of:)` (`:135-140`), `GroceryShare` merge and `quantity` (`:150-238`), `addGroceryShare` (`:261-310`), `AddRecipeToGroceries` (`:327-420`), `RemoveRecipeFromGroceries` (`:423-455`), `AddGroceries` (`:459-512`) |
| `TesseraCore/.../Kitchen/Shopping.swift` (86), `Aisles.swift` (119), `GroceryLines.swift` (39), `BuyCadence.swift` (57) | Shop process (`StartShop`, `FinishShop` `:27-72`), fixed aisle enum and guide, the "and" splitter, and a buy-gap helper (`:7-57`, no USUALLY surface) |
| `TesseraCore/.../Lists/Lists.swift` (359) | `CheckListItem` (`:192-230`), `MoveListItem` with aisle teaching (`:232-277`), `RenameListSection` (`:279-312`), `ClearDoneItems` and `clearDone` (`:316-359`), `AddListItem.kept` price strip (`:153-159`, used by the list tool only) |
| `TesseraCore/.../TesseraTess/TessGrammar+Kitchen.swift` (220), `TessCaptureEngine.swift:355-373` (483 lines in all) | Bar grammar for "buy", "get", comma lists and `groceries:`; the receipts "Milk, on Groceries.", "Milk, already on Groceries.", "Private item, on Groceries." |
| `Features/Recipes/RecipePage.swift` (423) | Grocery link parts only: "N to buy, on Groceries" (`:99-105`), swipe column to Groceries (`:177-211`), `SentLine` (`:220-236`) |
| `Features/Home/NowPage.swift:236,260-263`, `HomeLines.swift:225,267-278,400-405,565-576` | The planned cook's "Tacos tonight, 2 to buy." and the GROCERIES key |
| `Features/Kitchen/*` | Holds nothing of Groceries: `PantryFront.swift:36-41` reads `Groceries.isOn`; `CookModeCopy.swift` is cook mode |
| Tests read | `TesseraCore/Tests/TesseraCoreTests/GroceriesWeekTests.swift` (248), `GrammarMisfireTests.swift`, `KitchenHotfixTests.swift`, `KitchenGaps2Tests.swift:170-190`, `HomeLinesTests.swift:161-167`; app target `TesseraTests/GroceriesKeyTests.swift` (15). No Groceries case in `ScaleTests` |

**Not in the tree at all** (grep over `App`, `Features`, `TesseraCore/Sources`): `usuallyOutOf`, `linkItems`, any FOR WHAT side, ALL LINKS, JUST BECAUSE, a link-ask KEEP or NOT NOW, `groceriesAddedAt` or any code that puts a planned meal's rows on the list, a drag or `onMove` on a grocery row, "Move to aisle", a stored aisle order, a skip word for a planned meal, any "out of ..." or "need ..." grammar, a pack size drawn on a row (`Groceries.packSize(of:)` has no caller in `Features`), a "Didn't save. Try again." line in `Features/Groceries`, a Groceries case in `ScaleTests`, `docs/fixtures/recipe-link-prices.html`. No file under `Features/Groceries` or `TesseraCore/.../Kitchen` mentions Claude, a network type or a notification.

---

## 1. groceries-side-acceptance.md, GS1 to GS16 (FOR WHAT side)

No side exists: the context line has no FOR WHAT word, no glance, no group by cook (`GroceriesView.swift:66-70`; nothing else on the page opens). Two rows describe something the front does and deviate.

| # | Verdict | Evidence and gap |
|---|---|---|
| GS1 No planned recipes | NOT BUILT | No groups, no JUST BECAUSE or USUALLY |
| GS2 One cook | NOT BUILT | No cook group; Tess's "4 for 1 cook, 3 just because." not written |
| GS3 Shared ingredient, "also chili" | NOT BUILT | A shared row carries both shares (`Groceries.swift:301-308`), but no surface shows "also" |
| GS4 Two cooks shown once | NOT BUILT | The merge keeps one row per ingredient (`Groceries.swift:277-290`), so the data would count once; nothing reads it |
| GS5 Ordering by cook date | NOT BUILT | |
| GS6 A private item | NOT BUILT | Front half: it reads "Private item" in its own aisle (`GroceriesView.swift:234-236`, `ShopTrip.swift:23-26`) and counts in the context line (`:59`); ink is full, not 66%, and there is no side group |
| GS7 Private item, nothing behind it | FAIL | First tap reveals its words, the second strikes it (`ShopTrip.swift:42-48`, `GroceriesView.swift:244-249`); the row says tapping does nothing. No Check off or Remove swipe, so the receipts "Private item, removed." and "Private item, back on Groceries." do not exist on this page. Resolved: G102 (Product, Oct 17) rules no reveal; the build must keep "Private item" and strike on the first tap (superseded by G102) |
| GS8 A checked row | FAIL | A checked row leaves its aisle and sinks into the basket fold (`Groceries.swift:98`, `GroceriesView.swift:60,158-167`); GS8 wants it to stay in its group, struck, until the shop clears. The count half holds: the context line counts open rows only (`:59`) |
| GS9 Empty list | NOT BUILT | Front says "Nothing to get" (`:740`) and "Nothing to get." / "All in the basket." (`:710`); the side's "Nothing to buy." does not exist. Tess is silent on the empty list: true by absence |
| GS10 More than 4 groups, "and 2 more" | NOT BUILT | |
| GS11 The glance | NOT BUILT | |
| GS12 Tess's counts line | NOT BUILT | |
| GS13 No controls on the side | NOT BUILT | |
| GS14 Side word and Reduce Motion | NOT BUILT | |
| GS15 VoiceOver and Dynamic Type for groups | NOT BUILT | Front is walked at K36.13, K36.17 and K36.19 |
| GS16 Nothing sent to Claude | NOT BUILT | No side to open. The negative holds today: no Claude, network or log-upload reference in `Features/Groceries` or `Groceries.swift` |

**GS counts: 0 PASS, 2 FAIL (GS7, GS8), 14 NOT BUILT.**

## 2. groceries-ai-acceptance.md (AI-12)

### 2a. Sections 3, 2, 4, 5 (rules)

| # | Verdict | Evidence and gap |
|---|---|---|
| 3 When: rows land the moment a cook task is captured | NOT BUILT | `AddRecipeToGroceries` has two callers: the recipe page swipe (`RecipePage.swift:192`) and the DEBUG demo (`GroceriesView.swift:794`). Bar capture of "carbonara thursday" only makes the task, `about: [recipe]` (`TessCaptureEngine.swift:380-384`); no tidy pass, no `groceriesAddedAt` |
| 3 What: staples, to-taste, optional skipped; covered rules | PASS | Skips `Groceries.swift:377-382`; a same-key checked row covers `:383-390`; his typed amount stands, share flagged `counts = false` `:303-306`; pack sizes stay apart `:275-290`. Asserted by `GroceriesWeekTests.swift:151-213` (not run). Driven only from the recipe page today |
| 3 How it shows: ghost rows, "Tacos, 2 added." with UNDO 10 s, short name | FAIL | Short name PASS (`Recipes.swift:38-54`, clash rule `:43-46`; op summary `Groceries.swift:415-419`). But the recipe page shows "N to buy, on Groceries" (`RecipePage.swift:227`), not the receipt, and its line leaves after a fixed 4 s (`:197-201`) where a change gets 10 s. No ghost rows. Rows carry "for tacos" only after a long press, as 18 pt health-colour text beside a sage dab (`GroceryRow` `:478-488`), where the row says a permanent line at 16 pt `inkSecondary` and no dab. No flight, no drying |
| 3 Nothing to add: "Tacos, nothing to add.", no UNDO | NOT PROVABLE | Engine returns before any write and words it (`Groceries.swift:357-371,418`). What `RecipePage.swift:192-201` prints when `perform` returns no ops depends on the engine's empty-write behavior, which I did not trace; if it returns a result it would print "0 to buy, on Groceries" |
| 3 Several meals in one capture | NOT BUILT | Follows from the first row |
| 3 Count line "9 to get, for tacos and 2 more" | FAIL | Built: "9 to buy across 4 aisles" / "9 to buy across one aisle" (`GroceriesView.swift:736-743`). No meals named; "to get" absent |
| 2 Same key links silently on the phone | PASS | `addGroceryShare` joins the first open same-ingredient row (`Groceries.swift:261-290`); key folds whole milk to milk and yellow onion to onion (`GroceriesWeekTests.swift:135-136`, asserted). "7 cloves + 1 head" joins (`:191`, asserted) |
| 2 Claude only on his tap; gates (not while shopping, offline, cap, demo) | NOT BUILT | No Claude call exists in the Groceries path |
| 2 Pack (handles, titles, shop-name filter) | NOT BUILT | |
| 2 `linkItems` result shape (handle enums, at most 6 pairs) | NOT BUILT | |
| 2 The five checks on a pair | NOT BUILT | |
| 2 How it shows: one ask, KEEP then NOT NOW | NOT BUILT | The one-ask slot exists only for the dated-lift ask (`BottomChrome.swift:45,156`) |
| 2 KEEP: one undoable op, "Scallions, for the tacos." | NOT BUILT | |
| 2 NOT NOW: this week's memory, silent | NOT BUILT | |
| 4 USUALLY: `usuallyOutOf`, cap 4, 0.85 U to 2 U, tap flies to aisle, long-press history | NOT BUILT | `BuyCadence` computes a mean gap of at least three buy days from the op log (`BuyCadence.swift:9-26`) and its line is "You buy it about every N days."; no due window, no cap, no surface on Groceries |
| 5 Home reminder: "2 to buy" over "Tacos tonight", GROCERIES key opens Groceries | PASS | "Tacos tonight, 2 to buy." (`HomeLines.swift:225`), context "2 to buy" and hero "Tacos tonight" asserted (`HomeLinesTests.swift:161-167`); count is open, unchecked rows carrying that cook's share (`Groceries.swift:115-121`); key opens Groceries (`NowPage.swift:260-263`); no notification, badge, dot or Live Activity for groceries |
| 5 At zero: context returns to the day word and the key becomes COOK | FAIL | At zero the line reads "nothing to buy" (`HomeLines.swift:402`) and the key is hidden (`NowPage.swift:236-238`, asserted by `GroceriesKeyTests.swift`); there is no COOK key |

### 2b. Section 6, the wall on the Add line (W1 to W6)

The price strip and the secret check run only on the list tool's path (`TessTools.swift:345-349` calls `AddListItem.kept`, `Lists.swift:153-159`; asserted by `KitchenGaps2Tests.swift:170-190`). The Add line (`GroceriesView.swift:220-229`) and the Bar's grammar (`TessCaptureEngine.swift:356`) pass raw text to `AddGroceries`, which parses and writes it with no wall (`Groceries.swift:471-484`). `EngineWall.withoutPrice` has no caller in `Kitchen/`.

| # | Verdict | Evidence and gap |
|---|---|---|
| W1 "milk $4" gives row "milk", receipt "Milk, on Groceries." | FAIL | Add line keeps the price in the row name (no strip, above). Bar: "milk $4" has no buy verb or comma, so the grammar returns nothing for it (`TessGrammar+Kitchen.swift:49-52,68-76`; the private-log branch needs a past verb, `TessGrammar.swift:142-148`, `:333-337`); "buy milk 4.99" lands `["milk 4.99"]` |
| W2 A line that is only a sum never lands as a row; "Private note, kept." | FAIL | Add line writes it as a row. Bar: "$40 at costco" and "rent 2100 fri" are held back from rows by the sum branch (`TessGrammar.swift:122-135`), and a past-tense one becomes a private note ("Private note, kept." `TessCaptureEngine.swift:332`); a bare one gets the miss line, not the note. The Add line is the gap |
| W3 A pasted secret never lands as a row | FAIL | Bar PASS (secret check runs first, `TessGrammar.swift:73-75`). The Add line has no check |
| W4 "2 lb chicken", "14 oz can tomatoes", "6 eggs", "2 for 1 crackers" keep their numbers | PASS | Nothing strips anywhere on the grocery path; `withoutPrice` (`EngineWall.swift:71-75`) needs a currency sign or the words dollars, bucks, usd, quid |
| W5 Pasted block runs the check per line; "Tacos, 9 added. 1 private note, kept." | FAIL | `GroceryLines.split` splits per line (`GroceryLines.swift:17-38`) but nothing checks each; the combined receipt form is not written |
| W6 UNDO after W1, W2, W3; nothing walled is written then deleted | FAIL | A walled line is written as a row on the Add line, which is the thing W6 forbids |

### 2c. Core done-when, match eval, Builder B beats, section 7

| # | Verdict | Evidence and gap |
|---|---|---|
| C1 Planning "tacos tuesday" adds rows at once; again adds nothing; UNDO exact; "tacos tue, dal wed" | NOT BUILT | See section 3 When |
| C2 Typed "spring onions" links silently; "scallions" is a pack candidate | NOT BUILT | First half works (same-key); no pack |
| C3 KEEP moves share, removes ghost, keeps amount, sets learned aisle, UNDO reverses | NOT BUILT | |
| C4 Five checks drop bad pairs | NOT BUILT | |
| C5 Pack snapshot test (no amounts, typed text, prices, shops, notes, `checkedAt`; key-shaped refusal) | NOT BUILT | No pack |
| C6 No call during shop, live workout, switch off, offline, cap, demo | NOT BUILT | No call to gate |
| C7 `usuallyOutOf()` on the 20-week fixture, cap 4 | NOT BUILT | |
| C8 `HomeLines`: "2 to buy" / "Tacos today" before 17:00, "Tacos tonight" after, the time when set; at zero day word and COOK | FAIL | Day word and time PASS (`HomeLines.swift:267-278`, evening set `:275-276`); zero case as in section 5 |
| C9 Five-meal week: rows, "Tacos, 10 added.", "Frittata, 3 added."; 13 `linkItems` probes | PASS | The pre-ask state the row itself allows: 37 rows, tomato cans apart, kosher salt and optional lines absent, both receipts (`GroceriesWeekTests.swift:151-213`, asserted, not run). The 36-row state after KEEP and the 13 probes need the link ask (C2, C3) |
| Match eval gate (25 rows, 3 runs) | NOT BUILT | `scripts/ai/groceries_link_eval.py` and the fixture exist; the call they test does not |
| Shared ingredient across two planned recipes in one handle | NOT BUILT | |
| B1 Back word, Title 44, count line, aisle window fading over its last 50 pt | FAIL | Count line differs (section 3). No fade over the aisle window: the only gradient is behind Tess's note (`GroceriesView.swift:175-181`). Title size and back word NOT PROVABLE by reading (tokens) |
| B2 "for tacos" at 16 `inkSecondary` under every recipe row; no dab | FAIL | Long-press only, 18 pt, health colour, dab present (`GroceriesView.swift:478-488`) |
| B3 Planning flies rows in from Tess's corner, 60 ms apart | NOT BUILT | |
| B4 The ask with KEEP then NOT NOW | NOT BUILT | |
| B5 USUALLY label and words, tap flies to aisle in 520 ms | NOT BUILT | |
| B6 Home "2 to buy" over "Tacos tonight", GROCERIES key; "tonight" and COOK once all in | FAIL | First half PASS (C8, section 5); the COOK half is not built |
| B7 UI bar: nothing under 16 pt, no pills or buttons, Inter Tight, cobalt only for Tess, Reduce Motion crossfades, Dynamic Type wraps the count line | NOT PROVABLE | Sizes and face come from `Theme` tokens I did not trace; Reduce Motion handoff is a 180 ms fade, not 150 (see K36.18); count-line wrap not checked |
| M1 Fixture page with prices: the text handed to Claude holds none | NOT PROVABLE | A line-level cut exists (`RecipeLinkReader.swift:368-375`, call at `:439`); `docs/fixtures/recipe-link-prices.html` does not exist, so nothing proves it |
| M2 Every quantity and step survives the strip | FAIL | The cut drops whole lines that are price-shaped (`:372-374`), not the span, so an ingredient line carrying a price is lost (ingredient count falls) |
| M3 A price span inside the recipe body is cut and the recipe still parses | FAIL | Same: the line goes, not the span |
| M4 The strip runs before the call | PASS | `sendable` is applied before `trimmed` and the send (`:439`). A stub-model test was not found |
| M5 A page that is mostly prices returns "No recipe found." | NOT BUILT | The string is in no source file |
| M6 `asksClaude` off or a secret word: nothing sent | NOT PROVABLE | The gate is in `ClaudeRecipeReader`'s caller; not read in full |
| M7 No price span stored from a fetch | NOT PROVABLE | Not traced into the saved recipe's notes and source fields |

**AI-12 counts (48 rows: section 3 six, section 2 eight, USUALLY one, reminder two, W six, Core nine, eval and shared two, Builder B seven, M seven): 6 PASS, 14 FAIL, 23 NOT BUILT, 5 NOT PROVABLE.**

## 3. meal-plan-groceries-acceptance.md

| # | Verdict | Evidence and gap |
|---|---|---|
| E1 Planned Thursday, rows land on the evening before or at capture (as changed by AI-12) | NOT BUILT | Section 2 When. Nothing adds rows on capture or on a foreground tidy |
| E2 Running the pass again adds nothing | NOT BUILT | No pass. The recipe-level add is idempotent: it takes its own share out first (`Groceries.swift:372`) |
| E3 "dal tonight" adds at once | NOT BUILT | |
| E4 Undoing the capture removes only rows carrying that share; checked rows stay | NOT BUILT | `RemoveRecipeFromGroceries` is built and keeps checked rows (`Groceries.swift:439-448`); only deleting a recipe calls it (`TrainingActions.swift:582`), not undoing or deleting a plan task |
| E5 Task moved from Thursday to Saturday | NOT BUILT | |
| E6 Recipe deleted, the pass skips the task | NOT BUILT | |
| KW20 Skip a planned meal, "Dal, skipped." | NOT BUILT | No skip word; "skip" is an errand verb (`TessGrammar+Kitchen.swift:170`) |
| KW22 Meal planned on a day away: rows land, Tess silent about the trip | NOT BUILT | Rows do not land (E1) |
| KW25 No Sunday reset: the basket clears only on DONE | PASS | The only clears are `FinishShop` (`Shopping.swift:60-67`) and `ClearDoneItems` (`Lists.swift:316-345`); no weekday logic in the Kitchen files |
| KW30 "cook chili" with a plan starts that plan's cook, linked to the task | FAIL | `StartCooking(recipe:)` takes only the recipe (`TessCaptureEngine.swift:383-388`); no link. The plan task is closed at finish by a same-day lookup (`Cooking.swift:293-308`) |
| MP-F1 DONE ends the cook and completes the plan task in one operation; Home "Tacos done."; receipt "Tacos, done." | FAIL | One operation PASS (`Cooking.swift:272-288`, `closePlanTask` `:293-308`); Home line PASS (`HomeLines.swift:226`). Receipt: `FinishCooking` has only a summary, "Cooked ..." (`:312`), no "Tacos, done." |
| MP-F2 UNDO inside 10 s restores both | PASS | Cook and task writes share one transaction (`:272-288`); not run |
| MP-F3 A cook on another day leaves tomorrow's task open | PASS | Same house day only (`:303`, `TesseraDay.isSameDay`) |
| MP-F4 Two tasks for one recipe on one day: earliest only | PASS | `candidates.min(by:)` `:306` |
| MP-F5 No plan task: nothing else changes | PASS | Guard returns `:306` |
| MP-F6 Private recipe: task completes, surfaces read "Private recipe done." | PASS | `cookTitle` masks (`HomeLines.swift:560-561`), line `:226`; the close itself does not look at the title |
| MP-F7 Skip then finish the same day | NOT BUILT | No skip |

**Counts: 6 PASS, 2 FAIL, 9 NOT BUILT (17 rows).**

## 4. kitchen-refill6-lane1-acceptance.md (Groceries rows)

### K34 and K37 receipts

| Row | Verdict | Evidence and gap |
|---|---|---|
| K34.7 Scale Tacos to 2x, swipe to Groceries: "Tacos, 20 added." UNDO 10 s, "for tacos" under rows | FAIL | Scaled amounts and rule set are right (`Groceries.swift:348-351`). The page shows "20 to buy, on Groceries" (`RecipePage.swift:227`), hold 4 s (`:197-201`), no line under rows (K34.7 and AI-12 B2) |
| K34.8 Scale back to 4, add again: "Tacos, nothing to add." list not halved | FAIL | A second add removes this recipe's share and re-adds at the new size (`Groceries.swift:372`, `wanted` counts only checked-row cover `:357-366`), so the list is replaced at the new scale, not left alone |
| K37.6 Add the pasted chili: "Chili, 4 added." UNDO 10 s; "Milk, on Groceries." for a typed line | FAIL | Op summary is right (`Groceries.swift:415-419`); the screen line is the "N to buy" form with a 4 s hold. "Milk, on Groceries." from the Bar PASS (`TessCaptureEngine.swift:373`); the Groceries Add line gives no receipt at all |

K37.5 is recipe parsing and is not a Groceries row; not walked.

### K36 aisle grouping and reorder

| Row | Verdict | Evidence and gap |
|---|---|---|
| K36.1 Open: aisles in walk order, empty aisle undrawn, "7 to get" | FAIL | Order and empty filter PASS (`Groceries.swift:101-102`, enum order `Aisles.swift:7-25`). Count line reads "7 to buy across 3 aisles" (`GroceriesView.swift:736-743`). The 200 to 736 window: NOT PROVABLE |
| K36.2 Add by voice: lands in Dairy and eggs; "Milk, on Groceries." UNDO 4 s; "Milk, taken back." | FAIL | Bar receipt and aisle PASS (`TessCaptureEngine.swift:373`, `Aisles.swift:84-88`); the 4 s plain / 10 s undo hold is `HomeQueue.swift:33-49`. The typed Add line says nothing (`GroceriesView.swift:220-229`). "taken back" wording for a Groceries add: NOT PROVABLE |
| K36.3 Long-press and drag a row across aisles; teaches the aisle; "Chicken, moved to Produce." | NOT BUILT | No drag in `GroceriesView.swift`. Engine half exists: `MoveListItem` writes the ingredient's aisle on Groceries (`Lists.swift:254-258`); its receipt is "Chicken, moved to Produce" (`:272-276`) |
| K36.4 UNDO restores the row and the learned aisle | NOT BUILT | Engine writes both in one transaction (`:248-258`), so one UNDO would revert both; no UI to trigger |
| K36.5 Only the same key learns; "chicken thighs" uses the guide | NOT BUILT | Engine half: aisle by ingredient key (`Groceries.swift:251-256`) |
| K36.6 One move teaches the item | NOT BUILT | Engine half as above |
| K36.7 Drag an aisle title to reorder aisles; "Dairy and eggs, moved." | NOT BUILT | Order is the fixed enum (`Aisles.swift:23-25`); no stored order |
| K36.8 Finished aisle folds by collapsing its height under a clip; "then X" at 35% ink | FAIL | "then X" at 35% ink, body size PASS (`GroceriesView.swift:547-549`). The fold is a 3D tilt and fade (`:591-597`), not a height collapse under a clip. Custom aisle order missing (K36.7) |
| K36.9 Drag a Private item; "Private item, moved." | NOT BUILT | |
| K36.10 Drop outside the list cancels | NOT BUILT | |
| K36.11 A quantity change then a drag: one slot | NOT BUILT | One slot exists (`HomeQueue.swift:29-38`); neither action is built |
| K36.12 Dragged recipe row keeps "for tacos" | NOT BUILT | |
| K36.13 VoiceOver: "Chicken, 1 lb, Meat and seafood, for tacos"; actions Move to aisle, Check off, Remove | FAIL | One combined element (`:506`) reads amount and name; no aisle word, "for tacos" only when long-press opened it (`:483`), no "checked". Only custom action is "Which recipes" (`:508`) |
| K36.14 "Move to aisle" picker | NOT BUILT | |
| K36.15 UNDO stays 10 s after a VoiceOver move | NOT BUILT | The flat 10 s under VoiceOver is built (`HomeQueue.swift:44-49`); the move is not |
| K36.16 VoiceOver add by voice: slot 10 s, announced once | NOT PROVABLE | The 10 s half is `HomeQueue.swift:44-49`; high-priority announcement not found by reading |
| K36.17 Rotor: "Produce, 2 things"; Private item reads "Private item" | FAIL | Heading trait set (`:438`) but the label is the bare aisle word; Private item PASS (`:234-236`) |
| K36.18 Reduce Motion: 150 ms crossfade, haptics stay | FAIL | Handoff is `.opacity` over 0.18 s (`:572`); the dab flight is skipped (`:257`) and haptics stay (`:209`); reorder not built |
| K36.19 Dynamic Type AX3: one column, rows 44 pt or more, names wrap in full | FAIL | Rows 48 pt and one column PASS (`:442,447`); names are `lineLimit(1)` with tail truncation (`:474-475`) |
| K36.20 100-item list, scroll while dragging | NOT BUILT | |
| K36.21 Quiet hours: a reorder raises nothing | PASS | No notification or sound code in the Groceries files (grep) |
| K36.22 Copy sweep | PASS | No "Archive", no "Tins and jars", "Meat and fish", "Dry goods" or "Dairy" alone as a shown name (`Aisle.shown` maps former names, `Aisles.swift:13-20`); no " · " or clock text in `Features/Groceries` (grep) |

**Counts (K34.7, K34.8, K37.6 plus K36.1 to K36.22 = 25 rows): 2 PASS, 10 FAIL, 12 NOT BUILT, 1 NOT PROVABLE.**

## 5. kitchen-refill9-lane1-acceptance.md, K63 (USUALLY and the Private item mask)

There is no USUALLY surface (section 2a), so every row is NOT BUILT. The only code nearby is `BuyCadence` and `ShopTrip`'s "Private item" label, which USUALLY does not read.

| Rows | Verdict | Note |
|---|---|---|
| K63.1 to K63.15 (due private item, alone, two, four, fifth in "and 1 more", tap, left swipe skip, long-press, editing the words, trip mode, VoiceOver, Pantry versus Groceries, nothing sent to Claude, log dump, copy sweep) | NOT BUILT (all 15) | K63.12 needs Pantry's USUALLY line too (Pantry K26.17 note). K63.13 holds vacuously: nothing sends. The "Private item, not now." and "Private item, taken back." lines are proposed copy awaiting Product (REFILL 9 flags F4) |

**K63 counts: 0 PASS, 0 FAIL, 15 NOT BUILT.**

## 6. kitchen-error-states-acceptance.md (Groceries rows)

| Row | Verdict | Evidence and gap |
|---|---|---|
| ER9 Claude times out on a Groceries link ask | NOT BUILT | No ask |
| ER10 No key, switch off, cap, bad key on a Groceries job | NOT BUILT | No Claude job on Groceries |
| ER11 Check, add, remove or clear fails: "Didn't save. Try again." | FAIL | Every write is `try?` and silent: add `GroceriesView.swift:224` (the draft stays, which is the one right part), check `:272`, uncheck `:286`, clear `:295`, shop start `:307`, finish `:317`. No line, no retry, no `.warning` haptic |
| ER12 Offline: nothing shown | PASS | No network type in Groceries or the grocery actions; all on-device |
| ER25 Meal plan write fails or link ask times out | NOT BUILT | Neither path exists |

(ER23, the Pantry swipe failure, is `PantryView.swift:115`: "Didn't save that. Try again." The sheet words ER11, ER23 and ER25 as "Didn't save. Try again."; Product ruled "Didn't save that. Try again." on Oct 17, 4:35, so ER11 and ER23 should be aligned in the sheet.)

**Counts: 1 PASS, 1 FAIL, 3 NOT BUILT.**

## 7. kitchen-misfire-rows.md, 17 sampled rows

Each phrase was followed through `TessGrammar.parse` (`TessGrammar.swift:64-160`) and `parseKitchen` (`TessGrammar+Kitchen.swift:17-77`). "Asserted" is a `GrammarMisfireTests` or `KitchenHotfixTests` row (not run).

| Row | Verdict | Evidence |
|---|---|---|
| A1 "buy milk" | PASS | Buy regex `:49-52` gives `["milk"]`; asserted in idle, workout and shopping contexts |
| A6 "get 6 eggs and butter" | PASS | `splitItems` makes 2 lines; "get" gate `isGettable` `:195-202`; asserted |
| A10 "buy bench scraper" | PASS | Asserted as `groceries [bench scraper]`; the lift rules run first but the row is asserted, so I rely on the assertion |
| A19 "buy sat nav charger" | PASS | A short weekday counts only at the end or before a time (`hasDate` `:206-214`); asserted |
| A20 "buy cake candles wed" | PASS | A trailing weekday is a date, so the buy branch is skipped (`!hasDate` `:49`) and it becomes a task; asserted |
| A35 "out of milk" | FAIL | No "out of" pattern in `parseKitchen`; the only "out of milk" row is the question form, asserted to nil (`GrammarMisfireTests.swift:60`). Expected `groceries ["milk"]` is not produced (also no Pantry state, per the Pantry walk) |
| A37 "we're out of coffee" | FAIL | Same: no path. "need eggs" (A36) has none either |
| A39 "buy milk" during a live workout | PASS | Asserted `groceries [milk]` with an exercise in focus. "3 lemons" in a workout (A40): NOT PROVABLE here (no assertion read) |
| B1 "get mum a card" | PASS | People and gift shape in `notGroceries` `:177-192`; asserted as a task |
| B8 "get milk on the way home tomorrow" | PASS | "tomorrow" is a date, so the buy branch is skipped and it falls to the task rule; same mechanism as the asserted "buy milk tomorrow" (`KitchenHotfixTests.swift:35`) |
| B9 "gifts: mug for anu" | NOT PROVABLE | The grammar has no named-list prefix (only `list:` and `new list`, `:24-27`), so it falls past `parseKitchen`; whether the model path then files it to a Gifts list through `addToList` (`TessTools.swift:197-200`) was not traced |
| B12 "get back to Sam" | PASS | "back" is in `notThings` (`:197`), so the buy branch returns nil and the task rule takes it; not asserted |
| B14 "buy time with the landlord" | FAIL | None of the people, gift, service or errand tests match (`:177-192`), and the code says unclear stays Groceries, so this becomes `groceries ["time with the landlord"]`; the row expects a task |
| B19 "note buy milk" | PASS | The note rule runs second, before every kitchen rule (`TessGrammar.swift:76`, `:353`) |
| C1 "milk $4" | FAIL | No buy verb, so no grocery parse (W1); not the asserted expectation `groceries ["milk"]` |
| C2 "buy milk 4.99" | FAIL | Lands `["milk 4.99"]`; nothing strips a price on this path |
| C4 "buy 2 lb chicken" | PASS | Number kept; nothing strips it |

**Counts (17 rows): 11 PASS, 5 FAIL, 0 NOT BUILT, 1 NOT PROVABLE (B9).** A40 is noted under A39 and is not counted.

## 8. Gaps G40 to G50 (status on master a4f1d98)

Source: `kitchen-gap-hunt-7.md`, owners from `kitchen-gap-status-oct17.md`. Every one is **still open**; no later commit touched the cited lines.

| Gap | Still open? | Code evidence on master | Owner |
|---|---|---|---|
| G40 A list name matching two lists writes to the oldest | Open | `TessTools.swift:323-330`: exact title else first prefix match, no refusal | Core (resolver), Builder B (create refuses a repeat) |
| G41 Check and move receipts print a private item's words | Open | `Lists.swift:224-228` (check receipt and summary print the title), `:272-276` (move); the add side masks, `:162-164,170-176` | Core |
| G42 Renaming a Groceries section strands the learned aisles | Open | `RenameListSection` has no Groceries guard (`Lists.swift:279-312`); `aisle(of:)` reads the learned aisle first (`Groceries.swift:251-254`) | Core |
| G43 Done shopping has no UNDO and swallows a failed write | Open | `GroceriesView.swift:315-322` (`try?`, no `TessVoice` line); contrast `clearBasket` `:292-302` | Builder B (UNDO, failure line), Core (words) |
| G44 A shop never goes stale | Open | `ProcessTable.swift:85-90`: only workouts go idle | Core (idle rule), Builder B (Home read) |
| G45 A deleted checked row counts as a shop clear for Pantry | Open | `PantryLedger.swift:139-148` reads any deleted, done row | Core |
| G46 A recipe edit rewrites what a past cook used | Open | `PantryLedger.swift:152-167` re-reads the recipe's current lines | Core, Builder B |
| G47 A checked basket row does not count as "already on Groceries" | Open | `Groceries.swift:106-112` counts open rows only; `PantryFront.swift:36-41` calls it | Builder B |
| G48 Groceries re-sorts every tombstone on each call | Open, cost unmeasured | `Models.swift:359-362` sorts all children; no Groceries or Pantry case in `ScaleTests` | Core (tombstones), Builder B (one read per render) |
| G49 Lists says "1 list" instead of "Just Groceries" | Open | `ListsCopy.swift:7-10` | Builder B |
| G50 Pantry's Tess line uses the full recipe title | Open | `PantryLedger.swift:97-100` uses `displayTitle`, not `RecipeBook.shortName` | Builder B |

## 9. Gaps this walk found beyond G40 to G50

Numbered for the Kitchen lead; none is in a gap-hunt file yet.

1. **The Add line and the Bar's grocery path have no wall or price strip.** "buy milk 4.99" stores "milk 4.99"; a secret pasted into the Add line becomes a row (W1 to W3, W5, W6, C1, C2). The wall exists only on the list tool path. Owner Core (`AddGroceries` applies `AddListItem.kept` per line, or the Bar and Add line call it), Builder B wires the Add line.
2. **Planning does not put a meal's rows on the list** (AI-12 section 3, E1 to E6, C1, KW20, KW22). Owner Core (the add on capture, `groceriesAddedAt`, the tidy pass, skip), Builder B for the ghost-row landing.
3. **The FOR WHAT side is absent** (GS1 to GS16), and GS7 and GS8 describe behavior the front contradicts today. Owner Builder B for the screen, Core for the cook-date grouping model.
4. **Aisle drag and VoiceOver actions are absent** (K36.3 to K36.15, K36.20). The engine teaches the aisle on a move (`Lists.swift:254-258`); there is no gesture, no picker, no "Move to aisle", no stored aisle order. Owner Builder B (gesture, picker, actions), Core (aisle order storage, K36.7).
5. **The link ask and USUALLY are absent** (AI-12 sections 2 and 4, K63, ER9, ER10). Owner Core (`linkItems` tool, pack, five checks, `usuallyOutOf`), then Builder B (ask slot, USUALLY line).
6. **Groceries gives no receipt for the Add line, and every write fails silently** (K36.2, ER11). Typing "eggs, milk" prints nothing; a failed check, clear or finish says nothing and gives no retry. Owner Builder B.
7. **The recipe page line is not the receipt** (K34.7, K37.6, AI-12 3 How it shows): "N to buy, on Groceries" with a fixed 4 s hold instead of "Tacos, N added." with UNDO 10 s. Owner Builder B (Builder A if the recipe page is theirs).
8. **A second recipe add replaces rather than reports "nothing to add"** (K34.8). Owner Core.
9. **Rows show the recipe as a sage dab with a long-press line** (B2); the ruled form is a permanent 16 pt line, no dab. Owner Builder B.
10. **Context line wording** "9 to buy across 4 aisles" against the ruled "9 to get, for tacos and 2 more" (3f, K36.1). Owner Builder B.
11. **Pack size is never drawn** (`packSize(of:)` has no caller; "for chili · 28 oz" form). Owner Builder B.
12. **Row names truncate** (`lineLimit(1)`, `GroceryRow` `:474-475`) against K36.19 and the AX rule. Owner Builder B.
13. **Home at zero to buy** says "nothing to buy" and drops the key where the ruling wants the day word and COOK (section 5, C8, B6). Owner Builder A (Home) with Core for the line.
14. **"out of milk", "need eggs" and "we're out of ..."** route nowhere (A35, A37); "buy time with the landlord" becomes a grocery row (B14). Owner Core (grammar).
15. **Planned cook is not linked to the cook that starts** (KW30); no finish receipt "Tacos, done." (MP-F1). Owner Core.
16. **Recipe link strip cuts lines, not spans** (M2, M3), and its fixture does not exist. Owner Core (strip), Research or Builder B (fixture).

## Summary

| Section | Rows | PASS | FAIL | NOT BUILT | NOT PROVABLE |
|---|---|---|---|---|---|
| 1. GS1 to GS16 | 16 | 0 | 2 | 14 | 0 |
| 2. AI-12 | 48 | 6 | 14 | 23 | 5 |
| 3. Meal plan | 17 | 6 | 2 | 9 | 0 |
| 4. K34, K36, K37 | 25 | 2 | 10 | 12 | 1 |
| 5. K63 | 15 | 0 | 0 | 15 | 0 |
| 6. Error states | 5 | 1 | 1 | 3 | 0 |
| 7. Misfire sample | 17 | 11 | 5 | 0 | 1 |
| **Total** | **143** | **26** | **34** | **76** | **7** |

Gaps G40 to G50: all 11 still open on master. Copy rules: receipts are thing first with "on" on every path that exists ("Milk, on Groceries.", "Private item, on Groceries."); no "at" before a clock and no uppercase clock in the Kitchen and Groceries files; one verb-first line breaks the house form, "Cleared N from the basket." (`GroceriesView.swift:299`), which should read thing first.

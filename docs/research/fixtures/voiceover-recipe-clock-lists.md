# VoiceOver lines: the recipe clock and Lists 9 to 12

For: Builder A (cook mode), Builder B (Recipes page, Lists), Kitchen lead, Product, QA. Research item V, 2026-10-16.
Master read at `origin/master` 76be1c0 (Merge #475), by hand, nothing run. Sources: Design 69 `docs/design/recipe-clock.md` at 042c76f; Kitchen rulings in `product/cook-mode-acceptance.md` (#419, #461 rulings 3 to 5) and `product/decisions.md` 12:06 PM PT (a step running over HOLDS); `fixtures/recipe-clock-day-one.md`, `fixtures/recipe-clock-steps.md` (demo D1 Paprika chicken); Design's Lists sheet `docs/design/kitchen/lists-9-12.md` at c4b019f; `fixtures/lists-day-one.md` (R33: back word).

**Rules used.** Thing first. Plain words, sentence case in the label even when the screen shows label caps (an all-caps short word can be spelled out letter by letter). Times as "6:47 pm"; durations as "15 minutes", "12 hours", "30 seconds", never "MIN", "HR", "SEC". Glyphs ‹, ·, × and the bead, stroke, seam, dab and minute column are hidden; what they mean goes into a label or value. Every hold and every swipe has a named custom action (the house already does this: `GroceriesView.swift:346` "Start shopping"). Tess's lines and receipts are posted as `AccessibilityNotification.Announcement`; master posts none anywhere today (no match for `AccessibilityNotification` in any `.swift` file), so a line spoken off focus is never heard. Undo windows (4 s, 10 s) must not close while VoiceOver focus is on the Undo word. Reduce Motion changes nothing VoiceOver says. At accessibility text sizes, labels stay whole and are never truncated.

Verdicts: **pass** (master sets it as expected), **fail** (master sets something else or nothing on a built element), **not built**.

## Recipe clock (D1 Paprika chicken, serves 4, 45 minutes)

| id | Element | Expected label / value / hint / traits / actions | Master today | Verdict | Owner |
|---|---|---|---|---|---|
| VO1 | Back word "‹ RECIPES" | Label "Back to Recipes"; button; no hint. Source "‹ Recipes", uppercase by text case, as `RoutinesPage.swift:34-41` | Text "Recipes", no ‹; label read "Recipes", hint "Back to the recipes" (`RecipePage.swift:46-53`) | fail | B |
| VO2 | Name "Paprika chicken" | Label "Paprika chicken"; header, button; hint "Opens the original text and cook history" | Header and hint set (`RecipePage.swift:56-68`) | pass | B |
| VO3 | Context line "serves 4, 45 min, cooked 12 days ago" | Label "45 minutes, cooked 12 days ago" (serves is the drum, VO4); "1.5 h" spoken "1 and a half hours" | Plain text from `RecipeCopy.context` with "min" and "h" (`RecipePage.swift:71-75, 359-371`); serves is read twice | fail | B |
| VO4 | Portion drum (the serves word) | Label "Serves"; value "4"; adjustable, swipe up and down | `PortionDrum.swift:46-56` | pass | B |
| VO5 | A step at its minute, at rest | One element per step. Label the step text ("Roast the potatoes for 15 minutes."); value "Step 2 of 6, at minute 2"; untimed steps carry no minutes; static text | No clock; steps are only a count, "6 steps" (`RecipePage.swift:109-112`) | not built | B |
| VO6 | Minute column, stroke, wet and dry spans | Hidden; minutes live in VO5's value; done or ahead lives in VO10 and VO12 | none | not built | B |
| VO7 | A wait over 3 hours ("12 HR", fixed width) | Value "Step 2 of 4, 12 hours, no timer" | none | not built | B |
| VO8 | COOK key with "45 MIN" | Label "Cook"; value "45 minutes"; button; hint "Starts the clock at 4 servings" | `PaintKey` combines "Cook", button (`Paint.swift:304-307`), hint "Starts cooking at this size" (`RecipePage.swift:115-121`); no total beside it | fail (value) | B |
| VO9 | COOK pressed: the clock starts | Announce "Heat the oven to 425 degrees. Step 1 of 6."; focus stays on the key, now VO11. Check that "425°F" is spoken "425 degrees Fahrenheit", else the label spells it out | Key turns "Cooking" with a separate "Step 1 of 6" text (`RecipePage.swift:118-127`); nothing announced | fail | A |
| VO10 | The running (lit) step | Value "Now, 14 minutes left" (timed) or "Now" (untimed); value changes once a minute, never each second (no `updatesFrequently`); last minute "40 seconds left" | none | not built | A |
| VO11 | Key row STOP "33 MIN LEFT" | Label "Stop"; value "33 minutes left"; button; hint "Ends the cook"; action "Pause" | Key reads "Cooking", hint "It's cooking now" (`RecipePage.swift:118-121`) | fail | A |
| VO12 | Steps done and steps ahead | Done: value "Done". Ahead: value "Step 5 of 6, at minute 39" as at rest | none | not built | A |
| VO13 | A new step lights (bead reaches it) | Announce Tess's step line, thing first: "Chicken in, on the pan." One announcement for two steps that start together | none | not built | A |
| VO14 | A step running over (holds, decisions 12:06 PM) | Announce once "Roast the potatoes, time's up."; step value "Time's up, waiting for you"; actions on the step and on the key row: "Next step", "5 more minutes". Never relit or re-announced each minute | none | not built | A |
| VO15 | The bead that waits for him | Hidden; its place is the held step's value (VO14). Reduce Motion: no breath, no ring, nothing new spoken | none | not built | A |
| VO16 | Step timer flare "Roast, done." in the app | Announce "Roast, done."; the flare: label "Roast timer", value "Done", button, hint "Stops the alarm" | Steps start no timers (`recipe-clock-day-one.md` W5) | not built | A |
| VO17 | Spoken timer line "Bread · 8 MIN" | Label "Bread timer"; value "8 minutes left, ends 6:52 pm"; dot hidden; action "Stop" | Timer stored, no line on the page | not built | A |
| VO18 | Paused cook | Key: label "Paused", value "20 minutes left", button, hint "Resumes the cook". Lit step value "Paused, 5 minutes left". Announce "Paprika chicken, paused." (Kitchen to confirm the line) | Pause is slice 12b; Tess says "Pause comes later." | not built | A |
| VO19 | DONE with HOLD at the last step | Label "Done"; value "4 minutes left"; button; hint "Finishes the cook" (a double tap fires `complete()` already, so the hint must not say hold); action "Finish the cook" | `PaintKey` hint is "Touch and hold" for every hold key while its default action completes on a double tap (`Paint.swift:306-307`) | fail (shared key) | A |
| VO20 | Done receipt | Announce "Paprika chicken, cooked."; Undo: label "Undo", button, 10 s that pauses while focused; context line then reads "cooked today" | Only Tess "done" ends a cook, line "Paprika chicken, done." (`recipe-clock-day-one.md` W21) | fail | A |
| VO21 | INGREDIENTS word / STEPS word (the peek) | Label "Ingredients" / "Steps"; button; hint "Shows the ingredient list" / "Shows the steps". Page actions "Show ingredients" and "Show steps" stand in for the swipe | Column is labeled "Ingredients" with hint "Swipe left to add them to groceries", a swipe with no action (`RecipePage.swift:273-275`) | fail | B |
| VO22 | Ingredient row "1½ lb chicken thighs" | One element. Label "Chicken thighs, 1 and a half pounds"; button; hint "Opens the ingredient"; action "Show in metric"; during a cook value "Used" | Amount and name are two elements; the metric flip is a tap gesture with no action (`RecipePage.swift:245-267`) | fail | B |
| VO23 | Key "ADD 7 TO GROCERIES" | Label "Add 7 to Groceries"; button; absent at 0. Announce "Chicken, 7 added."; Undo as VO20 | No key; swipe only; "7 to buy, in Groceries" with Undo appears but is not announced (`RecipePage.swift:171-229`) | fail | B |
| VO24 | Back word during a cook | As VO1; leaving keeps the cook; announce nothing | as VO1 | fail | B |

## Lists 9 to 12 (screens not on master: no `Features/Lists/`)

| id | Element | Expected label / value / hint / traits / actions | Master today | Verdict | Owner |
|---|---|---|---|---|---|
| VO25 | Kitchen door "Lists" with "PACKING · 9 LEFT" | Label "Lists"; value "Packing, 9 left"; button | `HomeSpatialView.swift:337` has no Lists case | not built | B |
| VO26 | Shelf back word | Source "‹ Kitchen", uppercase by text case; label "Back to Kitchen"; button | none | not built | B |
| VO27 | "LISTS" | Label "Lists"; header | none | not built | B |
| VO28 | Context line "4 lists, nothing running" | Label as shown; button; hint "Shows list options" (tap unfolds the option words) | none | not built | B |
| VO29 | A name on the shelf with its state word | Label "Packing"; value from the state word: "Running, 9 left", "3 of 7", "Reusable", "Pick one", "Empty", "14 to buy"; button. On a Pick one name, action "Pick one" | none | not built | B |
| VO30 | Seam, dabs, the 14% dim and blur | Hidden | none | not built | B |
| VO31 | "Put away" at the foot | Label "Put away"; button; hint "Shows the lists you put away"; absent until one exists | none | not built | B |
| VO32 | Empty shelf line | "Paste a list anywhere to make one." as text; shelf action "Paste a list" (paste anywhere is a hidden gesture) | none | not built | B |
| VO33 | Pasted block, the ghost list | Announce "Twelve things, two sections."; label "New list"; value "12 things, 2 sections" | none | not built | B |
| VO34 | List page back word | Source "‹ Lists"; label "Back to Lists"; on an opened item, "‹ Packing", label "Back to Packing" | none | not built | B |
| VO35 | Hero and context line | Hero: label "Packing", header; action "Pick one" when on. Context: "nothing on it yet", "Packing, running" | none | not built | B |
| VO36 | Section word "Toiletries" | Header | none | not built | B |
| VO37 | Item row "2 phone chargers" | Label "Phone chargers, 2"; button; hint "Checks it off"; struck: value "Done"; actions "Remove" (the left swipe), "Open" | `CheckListItem` engine only (`Lists.swift:167-173`) | not built | B |
| VO38 | Fold, plain list | Label "4 done"; button; hint "Shows the done items"; action "Clear done" (the 0.7 s hold) | `ClearDoneItems` engine only (`Lists.swift:256-277`) | not built | B |
| VO39 | Fold, reusable "4 done. Hold to reset." | Label "4 done"; button; hint "Shows the done items"; action "Reset" (never the words "Hold to reset" as the only way in) | none | not built | B |
| VO40 | Done ask after "done" on a reusable list | Announce "Packing, done. Reset it for next time?"; RESET: label "Reset", button, hint "Unchecks all 12", default action resets; NOT NOW: label "Not now", button. The 10 s timeout waits while focus is on either word | none | not built | B |
| VO41 | Reset receipt | Announce "Packing, reset."; Undo 10 s; context line "12 to pack" | none | not built | B |
| VO42 | EMPTY state | Shelf value "Empty"; page context "nothing on it yet"; no placeholder rows to read | none | not built | B |
| VO43 | Receipts | Announce "Charger, on Packing.", "Packing, Lisbon put away." with Undo; never verb first ("Added charger", `Lists.swift:143`) | Engine summaries are verb first | not built | B |
| VO44 | Paging between lists, the name rail | Rail names: buttons, current one `.isSelected`; page actions "Next list", "Previous list" | none | not built | B |
| VO45 | Option words "Sections · Reusable · Run it · Pick one · Put away" | Each a button, dots hidden; Reusable and Pick one: toggle trait, value "On" or "Off" | none | not built | B |
| VO46 | Item page | Hero: label "Phone charger", header, action "Check off" (the right swipe). Note: text field label "Note", empty prompt "Add a note". Day: label "Day", value "Thursday" or "None", adjustable over the day lane. "LINKED FROM": header, names as buttons | none | not built | B |
| VO47 | Pick one landed | The pick is modal (`.isModal`), others hidden. Announce "Dune."; label "Dune", button, hint "Opens it"; action "Pick again" (the left swipe). Last skip: announce "That's all of them." | none | not built | B |

**Counts (47 rows):** 2 pass (VO2, VO4), 11 fail (VO1, VO3, VO8, VO9, VO11, VO19 to VO24), 34 not built (recipe clock 11, Lists 23).

## Top fails
1. **No announcements anywhere.** Tess's step lines, receipts and the done ask are only text on screen. Post `AccessibilityNotification.Announcement` from one place (`HomeQueue.say` and the page receipts). Core of VO9, VO13, VO14, VO20, VO23 and every Lists receipt. Builder A and B.
2. **Hold keys tell VoiceOver to hold** (`Paint.swift:306`), while the double tap already completes. Change the hint for every hold key once, in `PaintKey`. Builder A (it fixes DONE, FINISH and the Lists RESET word with it).
3. **Hidden gestures with no action** on the Recipes page: the swipe to Groceries and the metric flip (`RecipePage.swift:245-275`). Builder B.
4. **Back word reads "Recipes"** with a hint, not "Back to Recipes" (`RecipePage.swift:46-53`). Builder B.
5. **Units read as letters**: "45 min", "1.5 h", "1½ lb" in labels. Give spoken labels. Builder B.

## Questions for Product
1. Does "425°F" in a step need a spoken label, or is VoiceOver's own reading accepted? It was not checked on a phone.
2. A lit step: value "Now", or the `.isSelected` trait ("selected")? Research proposes the value.
3. Should a step timer ending while VoiceOver is on also announce when the screen is unlocked but the app is open behind another app (the banner covers it), or the banner alone?
4. VO18's announced line on pause has no copy yet; "Paprika chicken, paused." is Research's placeholder.
5. When a running list folds a finished section away, is anything announced ("Toiletries, done.") or is it silent?
6. Should the 4 s and 10 s undo windows stretch for everyone while VoiceOver runs, not only while focus is on Undo?

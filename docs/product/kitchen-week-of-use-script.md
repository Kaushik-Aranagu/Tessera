# Kitchen week of use: one script that runs every acceptance file once

*Kitchen lead, board K80, 2026-10-17. Docs only, no code. A runnable walk of 7 days (Monday 19 to Sunday 25 October 2026) on the demo store. Every Kitchen acceptance file in `docs/product/` is run once, in an order that follows how the data builds up: empty screens first, then paste, then lists and phrases, then links and Claude, then cooking, then the pantry and the shop, then the private things, then backups, settings and export. It does not restate copy: every "Expect" cites a row id and the row holds the exact words. For the 28-day walk see `kitchen-first-month-script.md`; this one is the shorter pass that proves the files. Ids: `K` rows are in the `kitchen-refill5` to `kitchen-refill9` files, `kitchen-overnight-acceptance.md` (K6), `kitchen-week-leaves-acceptance.md` (K11) and `kitchen-widget-wash-acceptance.md` (K24); `P`/`W`/`G1` to `G5` are `kitchen-v2-acceptance.md`; `WK` is `kitchen-week-one-rows.md`; `PF` is `kitchen-week-one-private-filter.md`; `KC` is `kitchen-counts-vs-claude-acceptance.md`; `ER` is `kitchen-error-states-acceptance.md`; `A`/`B`/`C` are `kitchen-misfire-rows.md`; `S` is `pantry-acceptance.md`; `O` is `cook-mode-acceptance.md`; `N` is `never-sums-audit.md`; `G6` and up are the gap hunts (`kitchen-gap-hunt-2` to `-6`). Where a number is not in a row it is marked "derived". Anything marked "proposed" is not a ruling.*

**House rules.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks lowercase ("8:30 pm", "12 pm", never "noon"). Digits for counts. US English. "Private item", "Private recipe", "Private note"; "Private recipe, 7 pm." on the widget and in Siri. On-screen counts keep private things and hide their names; anything sent to Claude drops them (KC). No daily cap on grocery asks. Link and reader asks fire only on his tap, and "Tess asks Claude: no" covers that tap. The JSON export masks private words. There is no Kitchen switch in Settings. Timers he started ring in quiet hours (23:00 to 07:00). The day starts at 4 am. Nutrition is never summed. No fixture, log or row holds a key or key-shaped text.

## 0. Setup, and what master cannot yet do

- **Store.** Simulator, Debug. Day 1 launches with `-demo -resetDemo -demoTime 08:30`. Every later launch uses only `-demoTime HH:mm` (no `-demo`, no `-resetDemo`, so the week's data survives). `-demoTime` fixes the hour of day only and **does not move the date**.
- **Moving the date.** In the simulator open Settings, General, Date & Time, turn Set Automatically off, and set the date by hand (default taken, no found rule; there is no launch flag for a date). Move it forward at each "Date" line below, then relaunch with the day's `-demoTime`. Never move it backward: a cook, a shop and a copy would sit in the future. Before day 1 write down the real date and set it back after day 7.
- **The demo store has no Kitchen data** (`Features/Demo/DemoData.swift` seeds training and tasks only). Day 1 pastes the fixtures from `kitchen-seed-recipes.md`: Tacos (10 non-staple lines), Weeknight dal, Overnight oats (8 h rest), Chili. Day 3 adds one recipe by link, day 6 adds "Passcode stew" (the PF4 default for Private). Build target: a Kitchen demo seed so the week can start on day 3.
- **Take a copy.** On days 1, 4, 6 and 7 copy `tessera.sqlite` (to a file named with the day) before any counts script (PF12). The counts script only ever runs on a copy.
- **On master today** (rechecked Oct 17, `kitchen-first-week-gap-recheck-oct17.md`). The Pantry page and front exist (#724, #727), Home draws planned, running and done cook lines (`HomeLines.swift:218-231`), and the EXPORT row exists but stays hidden (`ExportRow.swift:12`). Still missing: Lists screens, a Kitchen widget, the PER 100 G table, a mark-Private control (G21). Rows that need them say "build target" and are skipped, not failed; they come back in the table at the end.
- **Planning rule.** Tacos, Weeknight dal, Chili and the stew are planned the evening before with "cook <recipe> <day>". Overnight oats is never planned.
- **Rulings since Oct 17, 4 pm PDT (applied below; only the rows they change were touched).** G102 (no reveal anywhere: a masked private row never opens and one tap strikes it); G105 (one widest private-text function, so "Dentist cake" reads "Private recipe" on screens too, after the 4:22, 4:35 and 4:50 pm trims); the G94 quantity rule for a recipe's first line; Pantry v2 R1 to R20 (4:30 pm) and the PE group as an eighth acceptance group (`kitchen-pantry-v2-acceptance-pe.md`, id `PE`; PE09, PE18 and PE20 ruled 7:38 pm); the capture-miss cap of 600 characters and its line; the cook-phrase gate (3:38 pm, N21 to N26); sticky Pantry masks and their undo (6:10 pm and 6:44 pm). `decisions.md` in the repo stops at 6:39 pm; the entries from 6:44 pm on are read from the mirror in `/mnt/project-files/tessera/product/decisions.md`. Rows that need code not on master say "build target".
- **Marking.** For each row write pass, fail or skip. A fail that is already a G row is not a new finding: tick it in the table at the end. A fail with no G row is a new gap: note the file, the row id and the screen, and hand it to Product for G40 and up.

## 1. Monday 19 October: empty, then paste

*Launch: `-demo -resetDemo -demoTime 08:30`. Date: Monday 19 October (set it before launching).*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 8:30 am | `kitchen-first-use-empty-states.md`, sections 1 to 9, before anything is pasted (section 9 is the Settings Claude section; there is no Kitchen switch to look for) | Fresh demo store, no Kitchen data, no key | Each screen is its empty line (rows 1 to 9). Nothing says 0, no count, no guilt. G33 passes (empty Kitchen page) |
| 9:00 am | `kitchen-acceptance.md`, the "Screen needs" and "Passed as written" lists | Same | The six engine fixes hold (a re-run of the list, not new rows). Slice 15 is superseded, skip it |
| 9:30 am | Paste Tacos, Weeknight dal, Overnight oats, Chili from `kitchen-seed-recipes.md` | Paste a recipe, no key | Receipts "Tacos, on Recipes." and the same for each (K37.19). Home's Kitchen page lists Groceries, Pantry and Recipes, with "Paste a recipe" at the foot (`HomeSpatialView.swift:374-386`). No Lists word yet (FG6, open, Builder B). **Title rule (G94, 4:20, 5:59 and 6:00 pm, 6:44 pm item 3):** also paste on a copy a recipe whose first line is "2 large eggs" or "500 g plain flour": it has no title, saves as "Untitled recipe", and that line is ingredient 1 (not step 1). "3 eggs benedict", "7 Up Cake" and "30-Minute Dal" stay titles; a lone number is not a title either |
| 10:00 am | `kitchen-v2-acceptance.md`: P (recipe page, Ingredient page, Telling Tess) and W (CAN COOK), then G1 to G5 | The 4 recipes | P1 to W-last as written; G1 to G5 are ruled rows (Add-line splitting, no-ingredient paste, recipe gone, never-cooked original, serves missing) |
| 8:00 pm | Copy the store as "day1". Run `kitchen-week-one-rows.md` WK10 only | Same | `Recipes saved: 4`, no cook, timer or shop clause (WK10). Never "cooked 0 times" |

**End of day 1.** Home draws no Kitchen line (G33). Tess says nothing (WK19, WK20). Gaps this day can meet: G1 to G5, G33, G21 (no way to mark a recipe Private yet).

## 2. Tuesday 20 October: phrases, lists, the first typed asks

*Date: move to Tuesday 20 October. Launch: `-demoTime 09:00`.*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 9:00 am | `kitchen-phrases.md`, rows 1 to 50 | The 4 recipes, Groceries empty | Each phrase gives the receipt in its row ("Milk, on Groceries."). Walled phrases give "Private item, on Groceries." |
| 9:40 am | `kitchen-misfire-rows.md`: A1 to A40 (must stay Kitchen), B (look like groceries, are not), C1 to C16 (prices, walls, receipts) | Same | A rows land on Groceries; B rows stay tasks, notes or sets; C rows strip money and show the walled receipts (C). No row writes a price |
| 11:00 am | `lists-screens-acceptance.md`, the acceptance rows (G1 to 12.5 of that file's own numbering) and "On the phone, after merge" | Groceries with 6 to 10 rows | There is still no Lists screen on master, so that file's screen rows cannot run: skip them. G6, G15 and G16 are fixed (`6b62b51`, `725e24f`, `502b426`), so those rows pass (run G6 on a copy: do not delete the fixed list on the working store) |
| 2:00 pm | `meal-plan-groceries-acceptance.md`: the acceptance script and the Kitchen week rulings | Tacos, Dal, Chili on the shelf | Plan "cook tacos thursday", "cook dal friday", "cook chili sunday": receipts "Tacos, 10 added.", "Weeknight dal, N added." and "Chili, N added." (K38.6, K38.8; short name is the first noun phrase, ruled Oct 17 4:57, so a long title like "Chili con carne" reads "Chili con carne, 10 added."). **Open gap FG1 (Core):** master's `shortName(ofTitle:)` (`Recipes.swift:49-54`) still returns the last word, so the dal plan reads "Dal, N added." and Overnight oats "Oats, N added." Tacos and Chili are unaffected. The count line names "for tacos and 2 more" when 3 plans are in |
| 4:00 pm | `kitchen-refill5-acceptance.md`: K29 to K31 (grocery asks, the miss path, step-asides) | No key typed yet | Offline and no-key rows only (K29.x with no key). With no key nothing leaves the phone; the sent log is empty (K29.5 form) |
| 8:00 pm | `kitchen-refill6-lane1-acceptance.md`: K36 (price strip and the Groceries lines) | Same | Money is stripped before storage (K36 and K28.20 form). The medicine example stores as "Private item" and its name is on no row |

**End of day 2.** Gaps this day can meet: G6, G7 (delete a recipe on a copy, then look at its grocery share), G11 (rename onto an existing ingredient), G15, G16. Take no copy today.

## 3. Wednesday 21 October: links, Claude, errors, then the oats start

*Date: move to Wednesday 21 October. Launch: `-demoTime 09:00`. Type a Claude key at the first row for this day only (a test key from the person's own store, never written in any file); remove it at 6:00 pm.*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 9:05 am | Claude section: type the key. `kitchen-first-use-empty-states.md` section 9 again (with a key) | Key typed | The key line reads as the section says; "Tess asks Claude: yes" is the default (`TesseraSettings`). Receipts read "Nothing has gone to Claude yet." |
| 9:30 am | `kitchen-refill5-acceptance.md`: K33 (the recipe link reader) | Key typed, online | Reader fires only on his tap (K33.2). One page GET. The ask is in WHAT WAS SENT. Offline version "Recipe link, kept for later." (K33.1). **Open gap FG7 (Core, then Builder B):** master says "You're offline. I'll read it when you're back." (`RecipeLinkReader.swift:14`), a self-retry the ruling removes; the accepted line is not built, so this row fails today |
| 10:30 am | Flip "Tess asks Claude" to "no", tap READ on a second link, flip back | Same | The READ tap does not go to Claude (ruled; G32 rows and K73). Receipts show no new ask. Fixed: G32 (`d67565b`) and G39 (`484697e`, `afe20f6`; the clock reads "Thu Oct 16, 12 pm"). G31 is half fixed ("Recipe link" is a job name; a typed grocery miss still lists as "A capture"). |
| 11:30 am | `kitchen-week-leaves-acceptance.md` (K11.1 to K11.20): what leaves the phone, per job | Same | Each job sends only what its row lists. No daily cap anywhere |
| 1:00 pm | `kitchen-refill6-lane2-acceptance.md`: K39 (grocery wording failure rows: Claude down, the $40 step-aside and $50 cap, offline). K40 is the Pantry sides reading order: skip until day 5 | Same | Each failure row's exact line (K39.x). No grocery ask is capped by the day |
| 2:30 pm | `kitchen-error-states-acceptance.md`: ER1 to ER27 | Same | Each error line as written; ER6 line "Tess asks Claude: no" is the same ruling as above. ER5, ER8 and ER9 keep their tap-only wording |
| 2:45 pm | With the key typed, type one capture line of 601 characters (a repeated filler word, never real text) | Same | Nothing is sent. Tess says "That's too long to send. Say it shorter." once: no question, no offer to keep it as a note, no haptic (4:14 and 4:16 pm; #884). The sent log gains nothing. A line of exactly 600 characters is allowed to send |
| 6:00 pm | Remove the key (K32 in `kitchen-refill5-acceptance.md` is held to day 6) | Key typed | Removal stops every Claude call at once (G10: still open, 10 s window). After removal, Receipts keep their lines |
| 8:00 pm | Say "cook tacos thursday" (the plan for day 4) | Tacos on the shelf | Plan receipt "Tacos, 10 added." with UNDO 10 s (K38.6) |
| 9:20 pm | Start Overnight oats (8 h rest, **no timer**: cook-mode ruling 1, K86.3, gives a wait over 3 hours no timer). Leave the app open on step 1. Do not finish | Oats on the shelf | A running cook, nothing set to ring. This is the precondition for day 4's overnight rows |

**End of day 3.** Gaps this day can meet: G10 (open), G31 (half fixed); G32 and G39 are fixed. Nothing is planned for the oats.

## 4. Thursday 22 October: overnight finish, cook mode, the 4 am day

*Date: leave Wednesday's date on until the oats row, then move to Thursday 22 October and relaunch for 4:30 am. Launch: `-demoTime 04:30`, then relaunch `-demoTime 06:00` for the evening.*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 4:30 am | `kitchen-overnight-acceptance.md` (K6.1 to K6.19) | Oats started Wednesday 9:20 pm (no timer, see day 3) | Note: K6.9 ("the timer rang") has nothing to ring now, so skip it and read the other rows as written; Product to confirm that K6 needs a rewrite for the no-timer ruling. The finish is filed on Thursday, not Wednesday, because it is after 4 am (K6.16). Boundary clocks 22:59, 23:00, 6:59, 7:00 (K6.12). Row "4:30 am Cooked overnight oats" in the form of O2 |
| 9:30 am | `cook-mode-acceptance.md`: the acceptance script (1 to O4) and "The recipe clock" rulings | Oats finished; Tacos on the shelf | A timer's bead holds at the step's end and the step stays lit (ruled). The finish line has the right ordinal (G8 for 21st, 22nd, 23rd). A 48 h timer (G9, G22; both fixed) is the plain refusal, not a silent fail |
| 11:00 am | `kitchen-sides-acceptance.md`: sections 1 to 5 (FOR WHAT, PER 100 G, COOKS, INGREDIENTS, the Kitchen tab's side) and the Glances rule | Same | Each side opens on a half-screen glance first. Build target: PER 100 G on master (section 2 rows are skipped, not failed) |
| 1:00 pm | `kitchen-refill6-lane1-acceptance.md`: K34 (nutrition), K35 (timers), K38 (the meal plan) | Same | Nothing is summed (N1 to N7). Timers as K35.x. The plan rows K38.x hold: "No dal planned." only on the right 4 am day |
| 3:00 pm | `never-sums-audit.md` (N1 to N10) | Tacos open at serves 8 and 2x | No kcal, "per serving", "total" or "balance" anywhere (N1 to N7). Ask Tess "how many calories is this week": the plain refusal (N8) |
| 6:20 pm | Cook Tacos (about 46 min, Rice 8 min and Simmer 20 min timers) | Tacos planned on day 3 (8:00 pm row) | Plan receipt on day 3, then "Tacos, done." on finish (`Cooking.swift:314-322`; "Cooked Tacos" is only the log text). The finish closes the same-day plan task in the same write (`c43b2a2`, `38e4748`), so the Thursday plan task shows done with no second tap. COOKS shows nothing at 1 cook (3.3). **Cook-phrase gate (3:38 pm, N21 to N26; `kitchen-cook-gate-rows-oct17.md`):** while the cook runs, type the six phrases "8 mins", "pasta 10", "how long left", "stop the rice", "step 3" and (last) "finished cooking". Each is done on the phone and none is sent to Claude, key or no key (4:10 pm); nothing reaches the miss log. A cook phrase the route drops reads "Didn't catch that." (no new copy, no retry, no haptic). One unrelated line ("call mom half 7") goes the normal route |
| 8:00 pm | `kitchen-refill9-lane1-acceptance.md`: K62 (Home cook line) and K64 (4 pm boundary, "Dinner" for DST and midnight) and K65 (the 24 h timer cap) | Same | Home draws the cook lines as K62.x says, in house copy, with no "at" before a time (G19 and G20 are fixed: `1bea347`, `5ec9062`; the month count follows his 4 am day, `Cooking.swift:63-70`). "Dinner" is the tagged slot, else the last cook after 4 pm (K64.x). "Timers run up to 24 h." (K65) |

**End of day 4.** Copy the store as "day4". Gaps this day can meet: G8 (`e1b5437`), G9 (`45abadc`), G19, G20, G22 (`39d9bbc`) and G23 (`88e43f9`) are all fixed, so these rows pass.

## 5. Friday 23 October: the pantry and the first shop

*Date: move to Friday 23 October. Launch: `-demoTime 09:00`.*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 9:00 am | `pantry-acceptance.md`: Engine (S1 to S17 where an engine row), Done when, Screen rows | Tacos cooked on Thursday | The Pantry page exists (`Features/Kitchen/PantryView.swift`), so the screen rows run now. State is derived in the app (`PantryLedger.swift`), not in Core. G17, G18 and G24 live here |
| 10:00 am | `kitchen-refill5-pantry-acceptance.md`: K26 (pantry state), K27 (private rows), K28 (price strip and handoff) | Same | These run against the built Pantry: OUT and LOW only, digits hero, "since Saturday's shop", a private row opens nothing, has no tap target and no reveal, and reads "Private item" (`c0de5d9`, `edcffab`; R12 follows G102). State rows as written. K28.29: no widget, Spotlight, intent, export or backup carries a nutrition number. K28.20 repeats on the pantry side: no price in any log |
| 10:45 am | `kitchen-pantry-v2-acceptance-pe.md`: PE01 to PE24, run after the seven earlier groups (G177). Walk order in `kitchen-pantry-v2-walk-script-oct18.md` | Same | Build target until Core's Pantry v2 PR lands; skip, do not fail. Once built, R1 to R20 hold as ruled (4:30 pm): one backfill, "low on X" writes state only, "got" or "bought" sets the bought day, exact "what do i have" opens Pantry, state fields stay out of the shared export. A tie goes to the surer state (out over low over in) and an older stamp never overwrites a newer one (4:32 pm); a tie that changes nothing writes nothing and shows no receipt (G178). PE09: a phrase naming two items is one op and one UNDO slot, state per item, receipt names the items that changed. PE18: renaming an ingredient keeps its state. PE20: UNDO restores only fields that still hold what the op wrote |
| 11:30 am | `kitchen-refill6-lane2-acceptance.md`: K40 (Pantry sides reading order) and K41 (widget and Live Activity "Private recipe" mask) | Same | VoiceOver order as K40.x. Build target: the widget and Live Activity (G25) |
| 12 pm | `kitchen-widget-wash-acceptance.md` (K24 and its "Open, defaults taken") | Same | Build target on master (no Kitchen widget). Read the defaults and skip the rest |
| 1:00 pm | `kitchen-refill7-acceptance.md`: K43 (photo import), K44 (usual items), K47 (recipe delete, undo and restore) | Recipes on the shelf; a photo from the simulator's library | Every failure row has its line (blurry, non-recipe, price-heavy). USUALLY never sums and masks private. Delete is final after 10 s, no restore (K47.6). G7 (shares left after a recipe delete) is fixed (`b68cda2`) |
| 5:30 pm | `kitchen-refill7-acceptance.md`: K46 (shopping-trip mode) and `kitchen-refill8-acceptance.md`: K51 (private rows always read "Private item" on the trip; one tap strikes them, G102) | Groceries with 8 or more rows, 1 of them walled | One hand, offline, undo slots (K46.x). Private rows never reveal; a tap strikes them (K51.x, G102) |
| 6:30 pm | Cook Weeknight dal (about 40 min) | Planned Thursday evening | "Weeknight dal, first time." (ruled: first ever is "first time."; first in a month is "first time this month."). **Open gap FG11 (Core):** master's `finishLine` (`Cooking.swift:63-70`) prints the "this month" form every time and the raw title |
| 7:30 pm | Hold DONE on the trip | Same | The basket clears; Pantry records the bought day by the 4 am day (G24): "bought Sat" (`PantryDayWord.swift`, `edcffab`) |

**End of day 5.** Gaps this day can meet: G7 is fixed; G17, G18 and G24 now have a Pantry to run against; only G25 (widget) is still a build target. Tess is silent about the shop (WK20).

## 6. Saturday 24 October: private things, Siri reads, counts

*Date: move to Saturday 24 October. Launch: `-demoTime 09:00`. The recipe is pasted first so every row runs on a real Private recipe.*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 9:00 am | Paste "Passcode stew" (3 lines). `kitchen-refill9-lane1-acceptance.md`: K61 (mark a recipe Private: toggle, label, wall, undo, Backups, widget, Siri) | Stew pasted | Title shows as "Private recipe" everywhere (PF4), with no tap that shows it (G102; the hero reveal is fixed in #912, pending merge). Also paste a recipe called "Dentist cake" on a copy: it reads "Private recipe" on screens too (G105, one widest function), while "Blood orange", "Dr Pepper" and "Energy drink" stay raw (4:22, 4:35 and 4:50 pm trims; lands with #890). Its own page shows each ingredient as "Private item" and its "As pasted" screen shows no body, only "Private recipe" (7:40 pm; build target, G182 and G183). Build target: the toggle is not on master (G21); run the title-rule default and skip the toggle rows |
| 10:00 am | `kitchen-refill5-acceptance.md`: K32 (private recipes and items) | Stew planned for Saturday 7 pm | Planning receipt, 3 Groceries rows read "Private item" (K32.14). No Claude call carries its name (K32.15) |
| 11:00 am | `kitchen-refill9-lane1-acceptance.md`: K63 (Groceries USUALLY HAVE mask) | Same | The mask rows as written; no word of the stew's lines in USUALLY |
| 12 pm | `kitchen-refill8-acceptance.md`: K52 (locked-phone Siri reads), K53 ("Dinner" definition), K54 (the 10 s recipe-delete window across Week, Lists, widget), K55 (photo-import read failure, no image leaves the phone), K58 (Pantry USUALLY 4-name rows) | Stew private, Tacos planned | Locked reads say "Private recipe, 7 pm." and "a private item" in a sentence (K52.2, K52.5, K52.14). Dinner is the tagged slot, else the last cook after 4 pm |
| 1:30 pm | `kitchen-refill7-acceptance.md`: K45 (Siri phrases and Face ID) | Same | "add milk": "Milk, on Groceries." Locked: Face ID asked (K45.2). Failed twice: nothing written (K45.3). The private-grocery read-back: G34 (fails today: "Saved.") |
| 3:00 pm | `kitchen-counts-vs-claude-acceptance.md` (KC1 to KC32) | Stew, the walled item, the fixture on the first-month fixture of that file | On-screen counts keep private; anything to Claude drops them (A, B, C, F). Never sums (D). Money and body never go (E) |
| 6:30 pm | Cook the stew from 7 pm to 8:00 pm | Stew planned | Home, widget and Siri read "Private recipe, 7 pm." (K32.5, K32.8); Home does today (`HomeLines.swift:554-563`). Build target for widget. **Then open Pantry: Tess is silent** after a Private cook (K86.9, ruled Oct 17 5:05, FG9): no K26.27 line, no count. Master still reads "Private recipe took the ..." (`PantryLedger.swift:97-103`): wrong, open gap, owner Core / Builder B. The hero and lists change as normal. **Sticky mask (6:10 pm, G139; 6:44 pm items 4 and 5):** every ingredient that cook used reads "Private item" under OUT and LOW, even one a non-private recipe also uses, and is counted in the hero, never named (open on master, G184). Then undo that cook inside its window on a copy: the exact earlier state returns and the mask that cook added clears; a mask from another private cook stays. In Groceries the same ingredient reads "Private item" only if every recipe using it is private |
| 9:00 pm | Copy the store as "day6". `kitchen-week-one-private-filter.md` (PF1 to PF13) on that copy | Same | The filter drops every private name in every output (PF2, PF3, PF4, PF13). Grep the rendered strings, the ops log, the sent log and every request body for the stew title and the walled word: none |

**End of day 6.** Gaps this day can meet: G28 and G36 are fixed (#707, #710, `5d7cef0`, `3162b54`); G37 is half done; G34 is open (`Intents.swift:208` still returns "Saved."); G21's title-rule mask is fixed (`4e9c059`) but the toggle is not built; FG9 (Pantry Tess line) is open. Run the grep checks of PF13 on the copy, never on the live file.

## 7. Sunday 25 October: backups, Settings, export, the week's counts

*Date: move to Sunday 25 October. Launch: `-demoTime 09:00`. Cook Chili in the afternoon so the week has 5 finished cooks.*

| Time | Run | Preconditions | Expect |
|---|---|---|---|
| 9:00 am | Settings walk: the Claude section, Receipts, the "Tess asks Claude" switch, Backups. There is no Kitchen switch to find (ruled); confirm Settings has none | The week's data | The Claude section's lines as `kitchen-first-use-empty-states.md` section 9 describes. Receipts list this week's asks: job names G31 (half fixed), clock form G39 (fixed) |
| 9:45 am | Backups walk: make a copy now (SAVE A COPY asks Face ID first, before the share sheet, #730), then restore Tuesday's copy-like state using "day4" | Copies "day1", "day4", "day6" made | With no passcode set, SAVE A COPY says "Set a passcode first, this copy has your private words." and runs nothing (`BackupKeeper.swift:173-187`). The restore walk's lines. G26 (`1d9a11d`), G27 (`5837291`) and G29 (`2c378fa`, `881caf0`, receipt "Groceries lists, merged.") are fixed, so those rows pass |
| 11:00 am | Shortcuts and Siri: Shortcuts app, Tell Tess, the Tell Tess description; say "Tell Tessera" and stay silent, then give "add milk" | Same | G35 (no Kitchen words in the description; stock prompt). "Milk, on Groceries." for the phrase. Face ID on the write (K45.2) |
| 11:45 am | JSON export (build target; no screen on master): run the engine path in the package tests and read the file | The stew, the walled item | Masked titles and values (G28, K74 rows). Pantry state fields are left out of the shared export (R18). G36 (operations) is fixed; G37 (deleted and shared ingredients) is half done; G38: the EXPORT row exists but stays hidden (`ExportRow.swift:12`, `ready = false`), so the screen and a masked restore are still a build target |
| 1:00 pm | Cook Chili, about 46 min | Planned on Saturday evening | "Chili, first time." (first Chili cook ever; same open gap FG11 as day 5) |
| 4:00 pm | `kitchen-week-one-rows.md` (WK1 to WK25) on a copy ("day7") | All of the week | Derived: recipes saved 6 (4 pasted, 1 link, 1 stew counted with no title, WK1), cooks 5 started and 5 finished (Oats, Tacos, Dal, Stew, Chili, WK4), plans 4 made and 4 cooked and 0 skipped (the Oats cook was never planned), shops 2 started and 2 finished (day 5 and a quick top-up today, WK7). Timers and grocery item counts are read from the script and not asserted. WK13 and WK25: no title in the message. WK23: no "$" anywhere |
| 5:30 pm | Copy sweeps: `kitchen-copy-recheck-oct17.md` and `kitchen-stale-recheck-oct17.md` (re-run their greps over the files you ran) | Same | No "at" before a time, no "noon", no lowercase-start receipts, no "Private item" mid-sentence in capitals, no stale row ids. Any hit is a copy gap for Product |
| 6:00 pm | Set the simulator date back to automatic | Done | The store keeps the week; the next launch with `-resetDemo` wipes it |

**End of day 7.** The week is done. File every fail by id in the table below.

## 8. Every file, once

| File | Day | Rows |
|---|---|---|
| `kitchen-first-use-empty-states.md` | 1 (and 3 for section 9 with a key) | sections 1 to 9 |
| `kitchen-acceptance.md` | 1 | Fix list (landed #70), Screen needs, Passed as written |
| `kitchen-v2-acceptance.md` | 1 | P rows, W rows, G1 to G5 |
| `kitchen-phrases.md` | 2 | 1 to 50 |
| `kitchen-misfire-rows.md` | 2 | A, B, C1 to C16 |
| `lists-screens-acceptance.md` | 2 | acceptance rows and "On the phone" |
| `meal-plan-groceries-acceptance.md` | 2 | defaults, acceptance script, Kitchen week rulings |
| `kitchen-refill5-acceptance.md` | 2 (K29 to K31), 3 (K33), 6 (K32) | K29 to K33 |
| `kitchen-refill6-lane1-acceptance.md` | 2 (K36), 3 or 4 (K34, K35, K37, K38) | K34 to K38 |
| `kitchen-week-leaves-acceptance.md` | 3 | K11.1 to K11.20 |
| `kitchen-refill6-lane2-acceptance.md` | 3 (K39), 5 (K40, K41) | K39 to K41 |
| `kitchen-error-states-acceptance.md` | 3 | ER1 to ER27 |
| `kitchen-overnight-acceptance.md` | 4 | K6.1 to K6.19 |
| `cook-mode-acceptance.md` | 4 | acceptance script, recipe clock |
| `kitchen-sides-acceptance.md` | 4 (sections 1 to 5), 5 (sections 6, 7) | sections 1 to 7 |
| `never-sums-audit.md` | 4 | N1 to N10 |
| `kitchen-refill9-lane1-acceptance.md` | 4 (K62, K64, K65), 6 (K61, K63) | K61 to K65 |
| `pantry-acceptance.md` | 5 | S1 to S17, screen rows |
| `kitchen-refill5-pantry-acceptance.md` | 5 | K26 to K28 |
| `kitchen-pantry-v2-acceptance-pe.md` | 5 | PE01 to PE24 (build target) |
| `kitchen-widget-wash-acceptance.md` | 5 | K24 and its defaults |
| `kitchen-refill7-acceptance.md` | 5 (K43, K44, K46, K47), 6 (K45) | K43 to K47 |
| `kitchen-refill8-acceptance.md` | 5 (K51), 6 (K52 to K55, K58) | K51 to K58 |
| `kitchen-counts-vs-claude-acceptance.md` | 6 | KC1 to KC32 |
| `kitchen-week-one-private-filter.md` | 6 | PF1 to PF13 |
| `kitchen-week-one-rows.md` | 1 (WK10), 7 | WK1 to WK25 |
| `kitchen-copy-recheck-oct17.md`, `kitchen-stale-recheck-oct17.md` | 7 | the greps they list |

Not run as files: `kitchen-v2-scope.md`, `kitchen-v2-backlog.md`, `kitchen-release-map.md`, `kitchen-seed-recipes.md` (fixtures, day 1), `kitchen-week-one.md` and `kitchen-first-month-script.md` (the other scripts).

## 9. Gaps found so far

Statuses: **fails today** (read from code, a fix is owed), **build target** (the thing is not built; the row says what it must do), **ruled** (a ruling closes or decides it; a build or a check may still be owed, noted). Owners are from the triage tables in each gap-hunt file; G34 to G39 are suggested and wait for Product.

| # | What | Owner | Status | Day |
|---|---|---|---|---|
| G1 | Add line splits "mac and cheese" | per `kitchen-v2-acceptance.md` | ruled | 1 |
| G2 | Paste with no ingredient line | per `kitchen-v2-acceptance.md` | ruled | 1 |
| G3 | Recipe gone while its page is open | per `kitchen-v2-acceptance.md` | fixed on master | 1 |
| G4 | Never-cooked original text | per `kitchen-v2-acceptance.md` | fixed on master | 1 |
| G5 | Serves missing on the drum | per `kitchen-v2-acceptance.md` | ruled | 1 |
| G6 | Groceries list deleted, second list made | Core | fixed on master | 2 |
| G7 | Recipe delete leaves its grocery share | Core | fixed on master | 2, 5 |
| G8 | Finish-line ordinals "21th" | Core | fixed on master | 4 |
| G9 | Timer over 24 h offered, then refused | Core, then Builder B | fixed on master | 4 |
| G10 | Key removal lags 10 s | Core, then Builder B | open | 3 |
| G11 | Rename onto an existing ingredient | Core | ruled (refuse) | 2 |
| G12 | Week ignores the weekly rhythm | Builder A | fails today (training, not run) | n/a |
| G13 | Rest days drawn as open | Builder A | fails today (training, not run) | n/a |
| G14 | Sessions counted as days | Builder A | fails today (training, not run) | n/a |
| G15 | Empty clear logs a full receipt | Builder B | fixed on master | 2 |
| G16 | List tool makes plain Groceries rows | Core | fixed on master | 2 |
| G17 | Pantry merge order | Builder B, Core | Pantry built, run it | 5 |
| G18 | Pantry staple exception | Builder B, Core | Pantry built, run it | 5 |
| G19 | Home cook lines unwired | Builder B | fixed on master | 4 |
| G20 | "at" before a time on Home | Builder B | fixed on master | 4 |
| G21 | Nothing marks a recipe Private | Core, Builder B | title-rule mask fixed; toggle not built | 1, 6 |
| G22 | Spoken timer over 24 h | Core | fixed on master | 4 |
| G23 | Month count by calendar date, not the 4 am day | Core | fixed on master | 4 |
| G24 | Pantry bought-day by the 4 am day | Builder B, Core | Pantry built, run it | 5 |
| G25 | Kitchen widget while cooking and after DONE | Builder A | build target | 5 |
| G26 | Restore confirm line says only a date | Core, Builder B | fixed on master | 7 |
| G27 | Stale running cook after a restore | Core, Builder B | fixed on master | 7 |
| G28 | Backup and export show private words | Core | fixed on master (export and iCloud copy) | 6, 7 |
| G29 | Groceries list after a restore | Core | fixed on master | 7 |
| G30 | Kitchen switch in Settings | Builder B | ruled (no switch; closed) | 7 |
| G31 | Claude receipts name no Kitchen job | Core | half fixed | 3, 7 |
| G32 | Link read ignores "Tess asks Claude" | Core | fixed on master | 3 |
| G33 | Empty Kitchen page on Home | Builder B | passes today (kept as a row) | 1 |
| G34 | Siri reads "Saved." for a private grocery | Core | open (still "Saved.") | 6, 7 |
| G35 | Shortcuts description and prompt omit Groceries | Core | fails today | 7 |
| G36 | Export operation log keeps private words | Core | fixed on master | 7 |
| G37 | Export keeps deleted and shared private words | Core | half done | 7 |
| G38 | Export screen and masked restore | Core, Builder B | EXPORT row built but hidden; screen is a build target | 7 |
| G39 | Receipt clock "12:00 pm" and 24-hour phones | Builder B | fixed on master | 3, 7 |

**Counts (Oct 17 recheck).** The old count of "26 fails today, 5 build targets" no longer holds. Fixed on master: G3, G4, G6, G7, G8, G9, G15, G16, G19, G20, G22, G23, G26, G27, G28 (export and iCloud copy), G29, G32, G36, G39 (19). Half done: G31, G37. Open: G10, G34, G35, G21's toggle, and the recheck's FG1, FG7, FG9 and FG11. Pantry built, so G17, G18 and G24 run; G38 has a hidden EXPORT row; G25 (widget) is still a build target. `kitchen-gap-status-oct17.md` (K81) is the better count and is itself behind by #710, #724, #727 and #730. A fail with no id in this table goes to Product as G40 and up.

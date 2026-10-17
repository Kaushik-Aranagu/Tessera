# Kitchen first month: a day-by-day script on the demo store

*Kitchen lead, board K60, 2026-10-17. Docs only, no code. A runnable walk of 28 days (week 1 to week 4), then one empty week, with checkpoints. It does not restate copy: every "Expect" cites a row id and the row holds the exact words. Ids: `WK` = `kitchen-week-one-rows.md`; `PF` = `kitchen-week-one-private-filter.md`; `K` = the `kitchen-refill5` to `kitchen-refill8` files, `kitchen-overnight-acceptance.md` (K6) and `kitchen-refill6-lane1-acceptance.md`; `P`/`W` = `kitchen-v2-acceptance.md`; `O` = `cook-mode-acceptance.md`; `N` = `never-sums-audit.md`; `G` = the gap hunts (`kitchen-gap-hunt-2` to `-4`). Where the walk needs a number that no row gives, the number is derived from the fixture below and marked "derived". Anything marked "proposed" or "default taken" is not a ruling.*

**House rules.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks lowercase ("8:30 pm"). Digits for counts. US English. "Private item", "Private recipe", "Private note"; "Private recipe, 7 pm." on the widget and in Siri. No daily cap on grocery asks. Link and reader asks fire only on his tap. Timers he started ring in quiet hours (23:00 to 07:00). The day starts at 4 AM. Nutrition is never summed (PER 100 G, one ingredient only). No fixture, log or row holds a key or key-shaped text.

## 0. Setup, and what master cannot yet do

- **Store.** Simulator, Debug: launch with `-demo -resetDemo`. `-demoTime HH:mm` fixes the hour of day only; **it does not move the date**. For a multi-day walk move the simulator date forward one day at a time (default taken, no found rule), and keep `-demoTime` for the clock within a day. Run the counts script only on a **copy** of `tessera.sqlite` (PF12).
- **The demo store has no Kitchen data** (`Features/Demo/DemoData.swift` seeds training and tasks only; no starter recipes are installed, `StarterContent.swift`). Day 1 therefore pastes the 4 recipes below. Build target: a Kitchen demo seed so the walk can start at day 8.
- **Fixture recipes.** Tacos (10 non-staple lines, so "Tacos, 10 added.", K38.6). Weeknight dal (3 new rows when Tacos is planned, "Dal, 3 added."). Chili (shares onions and cumin with Tacos, so 2 new rows, K38.8). Overnight oats (8 h rest, `kitchen-seed-recipes.md`). One recipe with a secret word in its title, "Passcode stew" (the PF4 default for Private; G21: nothing marks a recipe Private on master).
- **Planning rule for the walk.** Tacos, Weeknight dal, Chili and the stew are each planned the evening before with "cook <recipe> <day>" (receipts as K38.6). Overnight oats is never planned. So plans and unplanned cooks add up the same way every week.
- **Fixture figures are derived** from the table in section 6; change a duration and only the checkpoint math moves, not the rule.
- **On master today** (gap hunt 4): Home does not draw a planned or finished cook (G19) and writes "at" before a time (G20); there is no Pantry, no Kitchen widget, no PER 100 G table. Those checkpoints say "build target".

## 1. Week 1 (Mon day 1 to Sun day 7): save, cook, first shop

| Day | Do | Expect |
|---|---|---|
| 1 Mon | Paste Tacos and Weeknight dal (Paste a recipe) | Receipts "Tacos, on Recipes." / "Weeknight dal, on Recipes." (K37.19). Kitchen shows the shelf and Groceries only; no week count, no Tess line (WK19, WK20) |
| 2 Tue | Paste Overnight oats and Chili. Copy the store; run the counts script | **WK10**: `Recipes saved: 4 (0 ghost row, 4 pasted or from a link)`, no cook, timer or shop clause. Message form "you saved 4 recipes (4 pasted)." Never "cooked 0 times" |
| 3 Wed | Overnight oats: started 2:10 am, finished 9:05 am (6 h 55 min). Timer for the 8 h rest rang while he slept | Day-log row "9:05 am Cooked overnight oats, 6 h 55 min" (O1 to O3). The timer rang in quiet hours (K6.9, K35.10). Tess's finish line "Overnight oats, first time this month." (cook-mode `finishLine`) |
| 4 Thu | Wednesday evening say "cook tacos thursday". Thursday cook it 6:20 pm to 7:06 pm (46 min) with Rice 8 min and Simmer 20 min | Plan receipt "Tacos, 10 added." with UNDO 10 s (K38.6). Cook done: "Tacos, cooked." (decisions line 281). Tess's COOKS line is empty at 1 cook (3.3). Home: build target (G19, G20) |
| 6 Sat | Plan Friday evening; cook Weeknight dal, 52 min. Type "milk and eggs" on the Groceries Add line, then "out of my metformin $40" | "Weeknight dal, first time this month." Typed lines: `kitchen-phrases.md`; walled one: **"Private item, on Groceries."** (K29.4), price gone (K28.20). The medicine name is on no row, receipt or log |
| 7 Sun | Shop: hold the title, check everything, hold DONE | Trip rows K51. DONE: "Cleared N from the basket." (K44.6 wording of the clear). Pantry (build target): checked items are in (pantry-acceptance P); "In since Saturday's shop." (P8, G24 for a check after midnight) |

**Week-1 checkpoint (day 7 night, the Oct 22 message).** Run the script on a copy. WK1 saved 4; WK3 typed 0 (all pasted); WK4 cooked **3** (finished); WK5 timers 4 (derived: Tacos 2, oats 1, dal 1), WK6 stopped early 0; plans 2 made, 2 cooked, 0 skipped (Tacos, Dal); WK7 shops 1 started, 1 finished; WK8 the Groceries items counted include the private item and print no name (PF6). WK13 and WK25: no recipe, item or note title in the message. WK23: no "$" anywhere (the "$40" was stripped before it was stored). Tess says nothing about the week (WK20, WK21).

## 2. Week 2 (days 8 to 14): link, pantry, first long cook

| Day | Do | Expect |
|---|---|---|
| 8 Mon | Open Pantry (build target) | Hero "Nothing out" (K26.9); no list of in things. Tess silent. No notification, badge or Live Activity, ever (pantry-acceptance "Notifications") |
| 9 Tue | Plan Monday evening; Dal cook 40 min; stop its Simmer timer by dragging it left after 12 min | "Simmer stopped." with UNDO 10 s (K35.15); WK6 counts it as stopped early. Dal's "Weeknight dal, second time this month." |
| 10 Wed | Paste a recipe **link**, tap READ | Reader runs only on his tap, one page GET (K33.2, K11.1); the ask is in WHAT WAS SENT. Offline version: "Recipe link, kept for later." (K33.1). No daily cap, no limit line |
| 11 Thu | Tacos (48 min), planned Wednesday evening | Pantry (build target): cilantro and limes out, chicken, onion, tortillas low; staples untouched (pantry-acceptance Core 1). Hero "2 out" and counts "2 out, 3 low" (derived from K26.6 and the defaults) |
| 13 Sat | Oats (never planned), 1:50 am start to 9:00 am (7 h 10 min) | Row "9:00 am Cooked overnight oats, 7 h 10 min" (O2). Oats median still skips nothing (7.10) |
| 14 Sun | Plan Saturday evening; cook Chili, 52 min | "Chili, first time this month." COOKS for Chili: one cook, Tess empty (3.3) |

**Week-2 checkpoint.** WK4 cooked 4 (Dal, Tacos, Oats, Chili); cooks per week so far 3, 4. WK1 saved 1 ("pasted or from a link", WK2; no split). WK5 timers 5, WK6 1. Plans: 3 made (Dal Tue, Tacos Thu, Chili Sun), 3 cooked, 0 skipped.

## 3. Week 3 (days 15 to 21): the 4 AM day, a skipped night

| Day | Do | Expect |
|---|---|---|
| 16 Tue to 17 Wed | Oats started 9:20 pm Tuesday, **finished 4:00 am** Wednesday (6 h 40 min) | Filed on **Wednesday** (K6.16; a 3:59 am finish would file on Tuesday, K6.15). Row "4:00 am Cooked overnight oats, 6 h 40 min". The timer rang at 4:00 am (K6.9). Oats COOKS median: 6 h 40, 6 h 55, 7 h 10 gives **6 h 55 min** (7.10) |
| 18 Thu | Tacos, 44 min | Tacos COOKS: 3 cooks (46, 48, 44) median 46 |
| 19 Fri night to 20 Sat | Dal is planned for Saturday. At **2:30 am Saturday** say "skip dal"; again at 4:05 am | 2:30 am: Saturday's plan is still Friday's day, so **"No dal planned."**, nothing changes (K38.15). 4:05 am: **"Dal, skipped."** UNDO 10 s (K38.9). Rows that carried only Dal's share leave Groceries; the count line drops its "for dal" clause. The task closes as skipped; it does not roll forward (K38.12) |
| 21 Sun | Shop; DONE | Basket clears. Pantry: bought-date by the 4 AM day (G24) |

**Week-3 checkpoint.** WK4 cooked 2 (Tacos, Oats), started 2. Plans 2: Tacos cooked, Dal skipped. Review's week line counts the miss in its own format ("Cook 1 of 2", format K38.12; the denominator is the week's plans, default taken). Week side: Saturday reads "Dal, skipped" at 66% ink (K38.12). Nothing red, no "overdue", no "missed" (K38.24).

## 4. Week 4 (days 22 to 28): plan the week, private things, nothing summed

| Day | Do | Expect |
|---|---|---|
| 22 Mon | Type "milk, eggs" (2 rows). Then "cook tacos thursday", "cook dal saturday", "cook chili sunday" | Receipts "Tacos, 10 added." / "Dal, 3 added." / "Chili, 2 added." (K38.6, meal-plan doc, K38.8). Count lines in order: "12 to get, for tacos", "14 to get, for tacos and chili", **"17 to get, for tacos and 2 more"** (K38.8). Tess on the week side: **"3 cooks this week, 15 to buy."** (derived: 15 rows carry a share; the 2 typed are not for a cook) |
| 23 Tue | Paste "Passcode stew" (3 lines), plan it for Friday 7 pm | Recipe counted, title shown as **"Private recipe"** everywhere (PF4, K32.3). Planning receipt "Private recipe, Friday 7 pm." (proposed, G21). Its 3 Groceries rows are "Private item" (K32.14). Week side: "4 cooks this week, 18 to buy." (derived) No Claude call carries its name or lines (K32.15) |
| 24 Wed | 11:30 pm: type "bread" on Groceries | Row lands with its receipt on screen; **no notification, no sound** (K29.11). Sent-log time "11:30 pm" |
| 25 Thu | Tacos, 42 min | Tacos COOKS: 4 cooks (42, 44, 46, 48), median 45: Tess "Cooked 4 times, about 45 min." (7.5 example, exact) |
| 26 Fri | Passcode stew cook at 7 pm. At 9:30 pm start Overnight oats and walk away | Home, widget and Siri: **"Private recipe, 7 pm."** (K32.5, K32.8, K52.2, KW-W8). The oats cook is left open: COOKS reads "left open" for it, and it is left out of the median (3.2, 7.6) |
| 27 Sat | Dal, 38 min. Shop; DONE | Overnight oats timer rang 5:30 am (K6.9). Dal COOKS: 52, 40, 38, median 40 |
| 28 Sun | Chili, 46 min | Chili COOKS: 52, 46 gives "Cooked 2 times, about 49 min." (3.3 exact). Then run the never-sums pass (section 7) |

## 5. Week 5 (days 29 to 35): the empty week

Plan nothing; cook nothing; do not shop. Run each at 9 am Monday and again after 4:00 am Tuesday.

| Surface | Expect (row) |
|---|---|
| Home | No planned-cook line, no "Tacos tonight" (K38.1); no count, no guilt. An uncooked, unskipped plan from week 4 would roll forward as a task, never "overdue" (K38.13) |
| Recipes shelf, week side | "Nothing planned." at 66% ink, no "Plan a meal" button (K38.2) |
| Groceries | Count line has no "for ..." clause (K38.3); FOR WHAT shows JUST BECAUSE and USUALLY only |
| Kitchen widget (build target) | Plain ground, no wash, one line "Nothing planned" (KW-W7, K38.4); a skipped cook never shows (K38.14) |
| Siri "What's for dinner?" | "Nothing planned." (K38.5, K45.16) |
| Tess | Says nothing unprompted (K38.1, WK20) |
| Counts script on the week's window | **WK9**: `Recipes saved: 0 (none)`, `Cooks: 0 started, 0 finished`, `Timers: 0`, `Shops: 0 started`, `Grocery items: 0`. The message reads "Kitchen week one: nothing saved, cooked or shopped yet." Never "saved 0 recipes" |
| Pantry (build target) | Known ingredients stay as they were; state never changes with time passing (pantry-acceptance P) |

## 6. Week-4 counts and the month, derived from the fixture

| Count | Week 4 (days 22 to 28) | Month (days 1 to 28) |
|---|---|---|
| Recipes saved (WK1) | 1 (the stew, counted, title never printed; WK13, PF4) | 6 (4 on days 1 to 2, 1 link on day 10, 1 stew) |
| Cooks started / finished (WK4) | 5 / 4 (Tacos, Stew, Dal, Chili; Oats left open) | 14 / 13 |
| Cooks per week, finished | Week 1: 3. Week 2: 4. Week 3: 2. Week 4: 4 | 13 |
| Timers / stopped early (WK5, WK6) | 6 / 1 (derived: Tacos 2, Stew 1, Dal 1, Chili 1, Oats 1) | 18 / 2 (derived: 4 + 5 + 3 + 6) |
| Shops started / finished (WK7) | 1 / 1 | 4 / 4 |
| Grocery items (WK8) | 21 (18 from recipes incl. the stew's 3 "Private item" rows, 3 typed: milk, eggs, bread; Z typed staples is read from the script, not asserted) | not asserted |
| Plans made / cooked / skipped | 4 / 4 / 0 (Tacos, Dal, Chili, Stew) | 11 / 10 / 1 (the 3 Oats cooks are unplanned) |
| COOKS median, per recipe (7.5, 7.10) | Tacos 45 min (4 cooks). Dal 40 min (3). Chili 49 min (2). Oats 6 h 55 min (3 finished, the open one is left out) | same |

Cooks per week, finished: 3 + 4 + 2 + 4 = 13. Cooks started per week: 3, 4, 2, 5 = 14.

## 7. Checkpoints that run every week

**Private things dropped.** Run after day 28 and after week 5.
1. **Names** (PF2, PF3, PF4, PF13, K32.7, K32.11, K27.19): grep the rendered strings, the accessibility tree, the widget timeline, the shared container, the ops log, `capture-misses.jsonl`, the sent log, the pack snapshot and every request body for the medicine, the stew's title and its ingredient names. None appears. The only words are "Private item", "Private recipe", "Private note".
2. **Counts: an open ruling.** Existing rows **keep** private things in numbers while hiding the names (WK13, PF4, PF6, PF8, K26.25, K32.1: "Counts include them"). The brief for this script asked for them to be **dropped from counts too**. Both readings are written: under the existing rows the table in section 6 stands; under "dropped from counts", week 4 recipes saved is 0 (month 5), grocery items 18 (15 from recipes, 3 typed), plans 3 / 3 / 0 (month 10 / 9 / 1), finished cooks 3 (month 12), and the week side stays "3 cooks this week, 15 to buy." at day 23. Proposed, Product to rule; default taken is the existing rows.
3. **Surfaces.** Home, widget, Siri, Spotlight, Tess, notifications, Live Activity, Pantry, the week side, FOR WHAT and the day log show nothing from the private recipe or item beyond the masks above (K32.1 to K32.16).

**Quiet hours 23:00 to 07:00.** Day 3, 16 to 17, 26 to 27: a cook timer he started rings (K6.9, K35.10, K35.12). Day 24: the 11:30 pm grocery add shows on screen with no notification (K29.11). An app-raised follow-up due inside the window holds to 7:00 am (K35.11, K6.10, K32.12). Boundary clocks 22:59 / 23:00 / 6:59 / 7:00 (K6.12). Groceries never notifies (K44.12).

**Day starts at 4 AM.** Day 16 to 17: a 4:00 am finish files on the new day (K6.16). Day 19 to 20: "skip dal" at 2:30 am is still Friday (K38.15). A cook at 1 am today belongs to yesterday, so "What's for dinner?" does not name it (K53.12). Month counts follow his day, not the calendar date (G23, proposed).

**Never-sums.** Day 28, once: open Tacos at serves 8 and 2x (K34.10), Chicken breast's Ingredient page (K34.11, PER 100 G, one ingredient, 4 values, "0 g fibre" never "0.0 g"), the chicken line on the recipe (K34.12), finish a cook (K34.13: no intake written). Read Groceries, Pantry, the week side, the widget and Home through the accessibility tree: no kcal, "per serving", "total" or "balance" (N1 to N7). Ask Tess "how many calories is this week": the plain refusal, no number (N8). The pack snapshot, the fill call and the backup hold no nutrition field (N9, N10, K11.10). Build target: no PER 100 G table on master; the numbers are fixtures.

## Gaps this walk meets, by id

G19 and G20 (Home, planned and finished cook, and "at" before a time); G21 (nothing marks a recipe Private; task title and receipt carry the name); G22 (a spoken timer over 24 h); G23 and G24 (month and bought-day by the 4 AM day); G25 (widget while cooking and after DONE). G6 and G7 (delete Groceries or a recipe) and G17 and G18 (Pantry merge and staple) are outside the 28-day path but break its counts if hit.

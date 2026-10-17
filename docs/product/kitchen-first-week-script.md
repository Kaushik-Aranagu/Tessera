# Kitchen first week: one person, one iPhone, from an empty app (Sat to Fri)

*Kitchen lead, board K85, 2026-10-17. Docs only, no code. A runnable walk of 7 days (Saturday 24 to Friday 30 October 2026) that starts on a fresh install with no Kitchen data and no Claude key, and follows what a first-time user does with Recipes, Groceries, Lists, Pantry, the meal plan and cook mode. It is the first-use path. It does not repeat `kitchen-first-month-script.md` (Monday start on the demo store, 28 days, counts) or `kitchen-week-of-use-script.md` (runs every acceptance file once, in file order); this one runs in the order a person would live it, so each step uses what the step before left behind (a shop clear makes Pantry things "in", a finished cook makes them "low" or "out", a plan reads Pantry).*

*Every "On screen" cell is copied from a ruled or proposed row; the row id is in "Proves". Nothing is invented. Where a title is swapped into a template row ("Tacos, done." read for Chili con carne) the cell says "template". Where a number is not in a row it is marked "derived" and the fixture below is the working. Anything marked "proposed" is not a ruling.*

**Ids.** `K` rows are in `kitchen-refill5` to `kitchen-refill10-acceptance.md`, `kitchen-refill5-pantry-acceptance.md` (K26 to K28) and `kitchen-overnight-acceptance.md` (K6). `S` is `pantry-acceptance.md` (screen rows S1 to S17, and its "P. State" and "Feeds"). `MP-F` is `meal-plan-groceries-acceptance.md`. `O` is `cook-mode-acceptance.md` (O1 to O4, the cook script steps 1 to 8, recipe clock rulings 1 to 5). `K84` is `kitchen-cook-mode-accessibility-acceptance.md`. `P#` is the phrase number in `kitchen-phrases.md` (`P#25` = phrase 25); `C1` to `C10` are the groups in `kitchen-phrases-2.md`. `FU` is `kitchen-first-use-empty-states.md` (section number). `WK` is `kitchen-week-one-rows.md`. `LA` is `lists-acceptance.md` (section 13). `KW-` is `kitchen-widget-wash-acceptance.md`. Steps here are `FW1` to `FW68`; new gaps are `FG1` and up.

**House rules.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a clock time. Clocks lowercase ("8:30 pm"). Digits for counts. US English. "Private item", "Private recipe", "Private note". Cobalt is Tess's voice only: every line marked Tess is her band (including the receipt and UNDO slot); screen words are ink. UNDO is 4 s for a new capture and 10 s for a change or a remove, and a flat 10 s under VoiceOver. The day starts at 4 am. Nutrition is never summed (nothing in this week shows a nutrition figure). No fixture, log or row holds a key or key-shaped text.

## 0. Setup

- **Store.** Simulator, Debug, a fresh install: delete the app first, then launch with `-demoTime 09:00` only. No `-demo`, no `-resetDemo` (they seed training data and would hide the empty states). `-demoTime` fixes the hour of day, not the date. Move the simulator date by hand to each day below (Settings, General, Date & Time, Set Automatically off), forward only, and set it back to automatic after Friday.
- **No Claude key all week.** Nothing is typed in Settings. "Tess asks Claude" is never touched. Every step runs on the on-phone grammar and reader.
- **Recipes pasted** (text from `kitchen-seed-recipes.md`, pasted whole): Chili con carne (serves 4, 10 ingredient lines, 5 steps), Shakshuka (serves 2, 9 lines, 5 steps), Overnight oats (serves 1, 5 lines, 3 steps), and Lentil soup (pasted once and taken back, FW9).
- **Working for the derived numbers.** Staples skipped on a recipe add are only the `AisleGuide.staples` set (salt, black pepper, oils, water and forms of them); none of the three recipes has one, so a recipe adds one row per line unless a row already covers it. Aisles (`Kitchen/Aisles.swift`): onion, garlic, red pepper, blueberries and parsley are Produce; beef mince is Meat and seafood; milk, eggs, feta and yogurt are Dairy and eggs; bread is Bakery. Pantry rule P: a shop clear sets every checked item's ingredient to in; a finished cook sets each non-staple ingredient it used to low and each Produce one to out; a recipe plan skips a line whose ingredient is in and still adds low and unknown ones (`pantry-acceptance.md` "Feeds" and Core 4).
- **State at each stop (derived).**
  - After Sunday's shop (FW17): in = eggs, bread, milk, one Private item, and Chili's 10 lines. Nothing out or low.
  - After Monday's oats: out = blueberries; low = oats, milk, greek yogurt, honey. Hero "1 out, 4 low".
  - After Tuesday's Chili: out = blueberries, onion, garlic, red pepper; low = the 4 above plus beef mince, chilli powder, cumin, chopped tomatoes, kidney beans, tomato puree, beef stock. Hero "4 out, 11 low".
  - After Thursday's shop: in = onion, garlic, red pepper, smoked paprika, cumin, chopped tomatoes, feta, parsley, milk. Out = blueberries; low = oats, greek yogurt, honey, beef mince, chilli powder, kidney beans, tomato puree, beef stock. Hero "1 out, 8 low".
  - After Friday's Shakshuka: out = blueberries, onion, red pepper, garlic, parsley; low = the 8 above plus smoked paprika, cumin, chopped tomatoes, eggs, feta. Hero "5 out, 13 low".
- **On master today** (read from the other scripts, not re-checked here): no Pantry, no Kitchen widget, no mark-Private control (G21), no Home cook lines (G19, G20). Those steps are "build target": run the engine row, skip the screen, and carry the step to the table in section 9 as skipped, not failed.

## 1. Saturday 24 October: empty, paste, first rows

*Launch `-demoTime 09:00`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW1 | 9:00 am. Opens Home, then the Kitchen page | "What we eat, and what we need." then the words Groceries, Recipes and, in the footer line, Paste a recipe. No count. The day shows no Kitchen line | FU 8, K38.1, G33 |
| FW2 | 9:02 am. Opens Recipes | Context `None yet`. Row area `No recipes yet.` at 66% ink. Tess: `Paste a link or a page and I'll read it.` No art, no count | K30.1, FU 1 |
| FW3 | 9:04 am. Opens Groceries | Title `Nothing to get.` Tess: `Tell me “milk, eggs”, or swipe a recipe's ingredients here.` The Add line is open with the prompt `eggs, milk, 2 lemons` | FU 2 |
| FW4 | 9:06 am. Opens Pantry from the KITCHEN index, then its side OUT AND LOW | Hero `Nothing yet`; under it at 55% `Clear a shop or finish a cook and this fills in.` Tess: `Say "out of milk" and I'll keep it.` Index line and Home's Pantry line read `Nothing yet`. The side opens on `Nothing known yet.` with no key. VoiceOver reads `Pantry. Nothing yet. Clear a shop or finish a cook and this fills in.` | K26.1, K26.2, K26.3, K26.4, K26.8, S12, FU 3 |
| FW5 | 9:10 am. Opens Lists, then its side | Context `Just Groceries`. Groceries at hero size with `NOTHING TO GET`. One quiet line `No other lists yet.` Tess: `Say "new list: packing" and I'll start it.` The side opens on `Nothing else to show yet.` | K31.1, K31.2, LA 13.1, FU 4 |
| FW6 | 9:14 am. Opens the week side on Recipes, then asks Siri "What's for dinner?" | Week side: `Nothing planned.` at 66% ink, no Plan a meal button. Siri: `Nothing planned.` The Kitchen widget, if added, reads `Nothing planned` | K38.2, K38.5, K45.16, K53.4, KW-W7 (widget: build target) |
| FW7 | 9:18 am. Opens Settings, then the Claude section | `Tess thinks on this phone only.` and the word `Add a Claude key`. Receipts, empty: `Nothing has gone to Claude yet.` He adds nothing. There is no Kitchen switch to look for | FU 9 |
| FW8 | 9:30 am. Pastes the Chili con carne text, taps Keep | The ghost recipe paints over the text (title, serves 4, 10 ingredient lines, 5 steps), wet cobalt drying to ink. Tess: `Chili con carne, on Recipes.` The Recipes first-use line is gone and stays gone. VoiceOver reads the same line once | K37.1, K37.19, FU 1 ("After one action") |
| FW9 | 9:40 am. Pastes Shakshuka and Overnight oats the same way, then pastes Lentil soup and taps UNDO inside 4 s | Tess: `Shakshuka, on Recipes.` / `Overnight oats, on Recipes.` Then for the soup (template): `Lentil soup, taken back.` and the recipe, its source text and any photo leave. The shelf holds 3 recipes | K37.19, K37.18 |
| FW10 | 10:15 am. In the Add line types `buy eggs`, then `get bread` | Tess: `Eggs, on Groceries.` then `Bread, on Groceries.` (template of the K44.4 form), UNDO 4 s each, one slot (the second replaces the first). Count line `2 to get`. Eggs lands in Dairy and eggs, bread in Bakery | P#1, P#3, C1, K44.4, K31.13 |
| FW11 | 10:20 am. Types `out of my metformin $40` | The row reads `Private item`. Tess: `Private item, on Groceries.` The $40 is on no row, receipt or log; the medicine name is on none either. Count line `3 to get` | K29.4, K28.20, C1, C7, WK23 |
| FW12 | 4:00 pm. Says to Tess "out of milk" on Pantry | Tess: `Milk, out. On Groceries.` Hero changes in place from `Nothing yet` to `1 out`. Group OUT appears with one line, Milk, and the word out in ochre with the faint ring | K26.6, S3, S2 |
| FW13 | 4:00 pm plus 3 s. Taps UNDO | Both are restored: the page returns to `Nothing yet` and Tess's line returns. He says "out of milk" again and lets the 4 s pass; the row stays. Count line `4 to get` | K26.6 (UNDO inside 4 s) |
| FW14 | 8:00 pm. Types `cook chili tuesday 7pm` | Chili con carne lands on Tuesday, 7 pm. Ghost rows fly in from Tess's corner, drying to ink. Tess: `Chili con carne, 10 added.` UNDO 10 s (the title's first noun phrase, US spelling, Product Oct 17 4:57). Rows carry `for chili con carne` under them. Count line `14 to get, for chili con carne` (derived: 4 typed plus 10). Tess says nothing about the week | P#14, P#15, P#16, K38.6, MP defaults ("Tess" row), WK20 |

## 2. Sunday 25 October: the first shop, the first long cook

*Date: Sunday. Launch `-demoTime 10:30`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW15 | 10:30 am. Holds the Groceries title | The page becomes the trip, one `.impact` haptic. Hero is the first aisle with open rows (Produce), lit seam beneath. Count line `14 to get`. Line under the hero reads `then` plus the next aisle with open rows. Tess says nothing | K46.1, K46.2 |
| FW16 | 10:40 am. Checks the Produce rows one by one | Each strikes in ink and sinks; no receipt per strike. When Produce has no open row the hero advances with a 380 ms slide and one `.success` haptic | K46.3, K46.17 |
| FW17 | 10:55 am. Types `foil` on the trip's Add line, then taps UNDO inside 4 s | Tess: `Foil, on Groceries.` UNDO 4 s; the row lands in Household and does not take the hero. UNDO line: `Foil, taken back.` | K46.18 |
| FW18 | 11:05 am. Reaches the Private item row; taps it once, then moves on | The row reads `Private item` until the tap; the tap shows its words for that row only; it masks again when he leaves it. The hero, count line and VoiceOver say `Private item` until that tap. Other private rows stay masked | K46.24 |
| FW19 | 11:30 am. All 14 rows struck. Holds DONE | Tess: `Cleared 14 from the basket.` UNDO 10 s | K46.20 |
| FW20 | 11:30 am plus 6 s. Taps UNDO, then holds DONE again | UNDO line: `Cleared 14, taken back.` and the rows return struck. Holding DONE again clears them again. Open rows: none | K46.20, K46.22 |
| FW21 | 11:45 am. Opens Pantry | Hero `Nothing out` (everything he checked is in; none is out or low). Context line `since Sunday's shop` (template of "since Saturday's shop"). Groups OUT and LOW are not drawn. The in things are not listed on the front. The side reads `Nothing out.` with no key. The Private item is never named | S11, S1, S8, K26.9, S15 (state words written by the shop clear: pantry-acceptance P) |
| FW22 | 9:20 pm. Opens Overnight oats, taps Cook, goes to step 2 "Cover and chill overnight." and puts the phone down | Home row: `Overnight oats, on step 2.` (template of "Tacos, on step 2."). The step is untimed (no number in its words) and the wait has no timer; nothing is scheduled. The cook is not planned | K62.11, O recipe clock ruling 1 ("untimed step"), cook-mode idle rule (default 7), FG10 |

## 3. Monday 26 October: finishing an overnight cook

*Date: Monday. Launch `-demoTime 07:00`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW23 | 7:10 am. Opens the cook, goes to step 3, holds DONE | Tess: `Overnight oats, cooked.` (template of "Weeknight dal, cooked.") UNDO 10 s. The log row sits on Monday, the finish day (after 4 am): `7:10 am Cooked overnight oats, 9 h 50 min` (started 9:20 pm: derived). No plan task exists, so nothing else changes | K84.27, MP-F5, O1, O2, O3, O4, K6.16 |
| FW24 | 7:12 am. Reads Tess's line after the window, then Home | Tess: `Overnight oats, first time.` Home: `Overnight oats done.` with the time `7:10 am` in the context slot. It leaves Home when the day turns over, 4:00 am | cook-mode script step 8, K62.15, MP-F5, FG11 |
| FW25 | 7:15 am. Opens Pantry | Hero `1 out, 4 low` (derived: blueberries out; oats, milk, greek yogurt, honey low). Tess's line is the phone's fact: `Overnight oats took 5 things.` (more than 3 names, so the count form) | K26.27, S13, S2, S4, S3 |

## 4. Tuesday 27 October: the planned cook, with timers

*Date: Tuesday. Launch `-demoTime 18:00`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW26 | 6:00 pm. Opens Home, then locks the phone and asks Siri "What's for dinner?" | Home hero `Chili con carne, 7 pm`; row line `Chili con carne, 7 pm, nothing to buy.`; context slot `nothing to buy`. Siri (locked, no Face ID for a read): `Chili con carne, 7 pm.` Tess's line and Home never disagree. Fails today on master (G19, G20) | K62.1 (template), K62.5, K45.11, K45.13, K53.2, K53.14 |
| FW27 | 6:55 pm. Opens Chili con carne, taps Cook | A dark full-screen cover rises with step 1 at the Title tier and its scaled amounts under it. Home row: `Chili con carne, cooking.` (one line, the plan and the cook are the same object) | cook-mode script step 1, K62.10, MP defaults item 4 (KW30) |
| FW28 | 6:57 pm. Holds the cadmium "8 MIN" key on step 1 | A horizon line appears at the top and burns down. Label is the verb nearest the duration (Brown) | cook-mode script step 3, O ASSUMED 2, K35.1 |
| FW29 | 6:58 pm. Swipes up, then on step 2 taps NEXT with his thumb | Step 2 arrives and step 1 stays as a dim line above it; one touch, one step. The NEXT bar is full width, at least 64 pt, at the bottom; the hold-to-start key is above it | cook-mode script step 2, K84.9, K84.10, K84.13 |
| FW30 | 7:00 pm. Says "timer rice 12" | A second labelled line stacks under the first, soonest first (`Rice · 12 MIN`, template of "Bread · 8 MIN"). It is his, not a step of the recipe | P#25, K35.1, O recipe clock ruling 5, K84.4 |
| FW31 | 7:05 pm. With Reduce Motion on, the Brown timer ends | Its line turns cadmium and the step slides back as a 150 ms fade, the haptic still given; no pulse. The resume point does not move. He taps the flared stack to stop it | cook-mode script steps 5 and 7b, K35.2, K84.17, K84.18 |
| FW32 | 7:10 pm. On step 4 holds the "30 MIN" key (Simmer), then drags that line left | The line fades. Tess: `Simmer stopped.` UNDO 10 s, in the bottom band within thumb reach | K35.15, K84.15, K35.20 |
| FW33 | 7:10 pm plus 5 s. Taps UNDO | The timer is back with its remaining time kept, same id; the notification is rescheduled. Lock Screen Live Activity shows the soonest timer large with `+1` for the other | K35.15, K35.5, cook-mode script step 6 |
| FW34 | 7:12 pm. Locks the phone; Rice ends | Notification title `Rice`, body `Rice is done.`, with sound; the Activity flips to its Done face on its own. Tapping it opens `tessera://cook` with Rice flared and Simmer still counting | K35.6, K35.7, cook-mode script step 6 |
| FW35 | 7:25 pm. Backgrounds the app 15 min, returns | The cook is still running and still Now; timers reconciled from their end time, none doubled | cook-mode script step 7, K35.17 |
| FW36 | 8:08 pm. On the last step taps the bar once, then holds it | A single tap gives a short haptic and the hint `Hold to finish`; it never finishes by accident. The label changes from NEXT to DONE with no layout shift; the hold fills left to right | K84.14 |
| FW37 | 8:10 pm. The hold completes | The cover closes; this cook's timers stop with no confirm. Tess: `Chili con carne, done.` UNDO 10 s (a plan task existed, so "done", template of "Tacos, done."). Home: `Chili con carne done.` with `8:10 pm`. The plan task leaves Tasks in the same operation | MP-F1, K35.16, K62.15, K84.28 |
| FW38 | 8:10 pm plus 4 s. Taps UNDO, then holds DONE again | UNDO line (template): `Chili con carne, taken back.` The cook is running again and the plan task is open again; Home reads as before the first DONE. The second DONE closes both again | MP-F2, K84.28, FG14 |
| FW39 | 8:12 pm. Reads Tess's finish line after the window, then opens Pantry | Tess: `Chili con carne, first time.` Pantry hero `4 out, 11 low` (derived). Tess's line there: `Chili con carne took 10 things.` OUT: blueberries, onion, garlic, red pepper; staples untouched | cook-mode script step 8, K26.27, S13, S2 |
| FW40 | 8:20 pm. Opens the recipe's COOKS side | One cook listed with its length (`1 h 15 min`, derived from 6:55 pm to 8:10 pm); Tess's line is empty at 1 cook; no "about" figure under 2 cooks | sides 3.1, 3.3, 7.4, 7.5 |

## 5. Wednesday 28 October: pantry, a list, the second plan

*Date: Wednesday. Launch `-demoTime 08:30`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW41 | 8:30 am. Opens Pantry | Hero `4 out, 11 low`; context `since Sunday's shop`; groups OUT then LOW, inside each by aisle in the shop's walk order; nothing red, nothing under 16 pt | S1, S2, S3, S4 |
| FW42 | 8:32 am. Taps the word low on the Kidney beans line | One `.selection`. Tess (UNDO slot): `Kidney beans, out.` UNDO 10 s. Hero `5 out, 10 low` (derived), the line moves to OUT with the ring | S7, K26.14 (form) |
| FW43 | 8:32 am plus 3 s. Taps UNDO | The row returns to low and Tess's line (`Chili con carne took 10 things.`) returns. Hero back to `4 out, 11 low` | S7, S13 |
| FW44 | 8:35 am. Swipes left on the Onion line | A ghost row joins Groceries. Tess: `Onion, on Groceries.` UNDO 4 s. The line stays on the page | S10, K26.13 |
| FW45 | 8:35 am plus 2 s. Taps UNDO | UNDO line (template): `Onion, taken back.` The Groceries row leaves; the hero still reads `4 out, 11 low` (adding to Groceries never changes state) | K44.4, K26.13 |
| FW46 | 12:30 pm. Says "new list: packing" | A list Packing is made. Tess: `Packing, new list.` UNDO 4 s (a proposal in LA 13.2; FU 4 proposes `Packing, on Lists.` instead, see FG5) | LA 13.2, P#33, P#34 |
| FW47 | 12:32 pm. Says "packing: charger, socks" | Two items land on Packing (the receipt for two items is not written anywhere, FG4) | P#41 |
| FW48 | 12:34 pm. Says "run packing". Checks charger. Swipes socks left | State word `RUNNING, 2 LEFT` (comma, never a dot); Tess: `Packing has 2 left.` The count rolls to `1 left` on the check. Socks: Tess `Socks, removed.` UNDO 10 s; he taps UNDO: `Socks, back on Packing.` | P#44, K31.3, K31.6, K31.8, K31.9, LA 13.6 |
| FW49 | 6:00 pm. Says "cook shakshuka friday 7pm" | Pantry reads in the plan: eggs is in, so skipped; the other 8 lines land (onion, red pepper and garlic out; cumin and chopped tomatoes low; smoked paprika, feta, parsley unknown). Tess: `Shakshuka, 8 added.` UNDO 10 s (derived). Count line `8 to get, for shakshuka` | pantry-acceptance Core 4 and "Feeds", K38.6, P#15, P#16 |
| FW50 | 6:02 pm. Says "skip shakshuka", then taps UNDO inside 10 s | Tess: `Shakshuka, skipped.` UNDO 10 s; rows carrying only its share leave Groceries and the count line drops its clause. After UNDO (template): `Shakshuka, taken back.` and the task and its 8 rows are back as they were | K38.9, K38.10, K38.11 |

## 6. Thursday 29 October: Siri, a Private recipe, a link, the second shop

*Date: Thursday. Launch `-demoTime 08:00`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW51 | 8:00 am. Says to Siri "add milk", unlocked; then locked, "add milk" | Siri: `Milk, on Groceries.` One new row in Dairy and eggs. Locked: Face ID is asked, on success the same words and the row lands | K45.1, K45.2 |
| FW52 | 8:10 am. Opens Shakshuka, turns on the Private recipe row, taps UNDO at 9 s, turns it on again and waits 10 s | Tess: `Private recipe, kept.` UNDO 10 s. Title, shelf row, Week, Tess and index read `Private recipe`. At 9 s UNDO: the switch returns, every surface reads `Shakshuka` again, line `Private recipe, taken back.` Second time the slot closes silently and the change stands. The plan task's title reads `Private recipe`. Groceries rows read as themselves, none says `for Private recipe` | K61.1, K61.2, K61.3, K61.4, K61.5, K46.25, K32.16 |
| FW53 | 8:20 am. Asks Siri "What's for dinner Friday?", then locked; searches Spotlight for Shakshuka | Siri: `Private recipe, 7 pm.` Locked: the same words and nothing on the lock screen. Spotlight: no result for the name. Widget (build target): `Private recipe, 7 pm.` | K32.8, K45.12, K45.14, K32.11, K32.5 (widget: build target) |
| FW54 | 12:10 pm. In airplane mode pastes a recipe link on the Paste screen; later goes online with the app open | Tess (UNDO slot): `Recipe link, kept for later.` Never the URL; no UNDO, no error colour. Online: `Read 1 waiting. 1 to check.` and a ghost recipe that never commits alone | K33.1, K33.2 (see FG7) |
| FW55 | 6:30 pm. Holds the Groceries title for the second shop | Count line `9 to get` (derived: 8 plus milk). The 8 recipe rows read as themselves, none names the Private recipe | K46.1, K46.25 |
| FW56 | 7:00 pm. Checks all rows and holds DONE | Tess: `Cleared 9 from the basket.` UNDO 10 s | K46.20 |
| FW57 | 7:02 pm. Opens Pantry and its side | Hero `1 out, 8 low` (derived); context `since Thursday's shop`. Side glance `1 out`, `8 low`, `9 to buy`, foot ALL OF THEM; out line before low lines; key `ADD 9 TO GROCERIES` | pantry-acceptance P, S1, S2, S8, K26.22 (form), sides 6.1 to 6.3 |

## 7. Friday 30 October: the Private recipe cook, with VoiceOver and the largest text

*Date: Friday. Launch `-demoTime 18:30`.*

| Step | Time and he does | On screen and Tess say | Proves |
|---|---|---|---|
| FW58 | 6:00 pm. A reminder for the cook is delivered | Title `Private recipe`, body `7 pm`; no name | K32.12 |
| FW59 | 6:30 pm. Opens Home | Hero `Private recipe, 7 pm`; row line `Private recipe, 7 pm, nothing to buy.` (derived, see FG8). The widget, Siri and notifications read `Private recipe, 7 pm.` with no count | K62.19, K62.24, K32.5, K32.8 |
| FW60 | 6:55 pm. Turns on VoiceOver and Dynamic Type AX5. Opens the recipe and taps Cook | Heading reads `Private recipe, cooking`; the step words wrap in full at AX5; amounts go to one column; the bottom key stays on screen. No scaled path shows the name | K84.8, K84.1, K84.2, K84.29, K62.20 |
| FW61 | 6:57 pm. Swipes right through the screen on step 2 | Reading order: heading, `Step 2 of 5` (template of "Step 2 of 6"), the step's words, one stop per amount line, the timer, Tess's line if showing, `Next`, button, hint `Next step`. Nothing decorative is a stop. A double-tap on Next advances and focus lands on `Step 3 of 5`, announced once | K84.20, K84.21 |
| FW62 | 7:00 pm. Opens the ingredient peek on step 1 | The peek reads need against have per line in state words only (`have` at 42%, `low`, `out`); the key is absent because the planned recipe is already on the list (its dry run reads 0) | pantry-acceptance Core 4 and "Feeds", O recipe clock ruling 2, K84.25 (key absent at 0) |
| FW63 | 7:05 pm. On step 3 holds the Simmer key (10 minutes in the method); he locks the phone, 7:07 pm, | Lock Screen reads `Private recipe. Simmer, 8 minutes left.` (VoiceOver, the Stop button reads `Stop`, hint `Ends the cook`). Never the name, an ingredient or a step's words | K84.30, K35.14, K32.12 |
| FW64 | 7:15 pm. The timer ends while focus is elsewhere | One high-priority announcement, focus does not move: `Simmer is done.` The line reads `Simmer, done. Stop.` with the Stop action. No second announcement | K84.22, K35.18 |
| FW65 | 7:48 pm. On the last step moves focus to the bar and double-taps | It reads `Done`, button, hint `Hold to finish`; a plain double-tap says `Hold to finish` and does not finish. He uses the named action `Finish` instead | K84.26, K84.14 |
| FW66 | 7:48 pm plus 1 s. The cook completes | One announcement, high priority: `Private recipe, done.` The plan task closes silently. UNDO held 10 s. Home: `Private recipe done.` with `7:48 pm`. It leaves Home when the day turns over, 4:00 am | K84.28, MP-F6, K62.21 |
| FW67 | 7:50 pm. Opens Pantry | Hero `5 out, 13 low` (derived). OUT: blueberries, onion, red pepper, garlic, parsley. Tess's line: the Private recipe's cook has no row for what to say about what it took (FG9); until ruled she says nothing | S13, S2, S15 (for the walls), FG9 |
| FW68 | 9:00 pm. Copies the store and runs the week-one counts on the copy | Derived: recipes saved 3 (Lentil soup was taken back), cooks 3 started and 3 finished (Oats, Chili, Shakshuka), plans 2 made, 2 cooked, 0 skipped (FW50 was taken back), shops 2 started and 2 finished, Groceries items 23 (18 from recipes, 5 typed). The Private recipe is counted and no title is printed; no "$" anywhere; Tess says nothing about the week | WK1, WK4, WK7, WK8, WK13, WK20, WK23, WK25 |

## 8. Read-through: the week by surface

| Day | Home Kitchen line | Pantry hero | Groceries count line |
|---|---|---|---|
| Sat | none | `Nothing yet`, then `1 out` | `2 to get`, `3 to get`, `4 to get`, then `14 to get, for chili con carne` |
| Sun | `Overnight oats, on step 2.` (night) | `Nothing out` | `14 to get`, cleared by DONE |
| Mon | `Overnight oats done.` | `1 out, 4 low` | none |
| Tue | `Chili con carne, 7 pm, nothing to buy.`, then cooking, then `Chili con carne done.` | `4 out, 11 low` | none |
| Wed | none | `4 out, 11 low` | `8 to get, for shakshuka` |
| Thu | none | `1 out, 8 low` (after the shop) | `9 to get`, cleared by DONE |
| Fri | `Private recipe, 7 pm, nothing to buy.`, then `Private recipe done.` | `5 out, 13 low` | none |

Siri "What's for dinner": Sat `Nothing planned.`; Tue `Chili con carne, 7 pm.`; Fri `Private recipe, 7 pm.` (asked on Thu).


## 9. Gaps: steps no existing row covers, and rows this script never exercises

### 9a. Steps no existing row covers (new gaps, for Product as FG1 and up)

| # | Step | What no row says | Default taken in the script |
|---|---|---|---|
| FG1 | FW14, FW49 | The short name in a plan receipt for a three-word title ("Chili con carne, 10 added."). Rows use "Tacos" for "Sheet-pan chicken fajita tacos", "Chili" for "Weeknight turkey chili" and "Chicken" for a paprika chicken recipe, with no rule for how the short name is made. **Ruled (Product, Oct 17 4:57): the title's first noun phrase, US spelling.** | "Chili con carne, 10 added." |
| FG2 | FW10 | The receipt for one typed line holding two items ("buy eggs and bread", P#2). K45.4 gives "Milk and eggs, on Groceries." for Siri only, and marks it proposed | Two single-item lines were typed instead |
| FG3 | FW22, FW23 | An overnight cook with no timer. O ruling 1 gives a wait over 3 hours no timer, while the idle rule (default 7) suspends a cook 45 min after its last step change. No row says how DONE the next morning reaches a suspended cook. Other scripts assume an 8 h timer that ruling 1 removes | Cook left open; finished 7:10 am as O1 shows |
| FG4 | FW47 | The receipt for "packing: charger, socks" (P#41, two items on a list). C1 has only the one-item form "Rice, on Packing." | No receipt quoted |
| FG5 | FW46 | A conflict between two proposals: LA 13.2 says `Packing, new list.` with UNDO 4 s; FU 4 says `Packing, on Lists.` with UNDO 10 s | LA 13.2 |
| FG6 | FW4, FW5, FW46 | How a first-week user reaches Lists and Pantry from Home's Kitchen page. FU 8 lists only Groceries, Recipes and Paste a recipe; S14 gives the five-row index; no row says which word on Home opens the index | Opened from the index |
| FG7 | FW54 | K33.2 says an online link "reads itself once", while the Kitchen house rule is that link and reader asks fire only on his tap | Followed K33.2 as written |
| FG8 | FW59 | Home's line for a Private recipe with nothing left to buy. K62.19 gives `Private recipe, 7 pm, 2 to buy.` (proposed) and K62.5 gives `nothing to buy` for an ordinary cook; no row joins the two | Joined by hand (derived) |
| FG9 | FW67 | What Pantry's Tess line says after a Private recipe's cook. K26.27 names the recipe first ("Tacos took 5 things."), and a Private recipe may not be named | Silent until ruled |
| FG10 | FW22 | Home's line while an unplanned overnight cook sits on step 2 for hours. K62.11 is written for a planned cook, K62.14 for one that suspends | `Overnight oats, on step 2.` |
| FG11 | FW24, FW39 | The Tess line for a first-ever cook has three forms: `Weeknight dal, first time.` (cook-mode script step 8, K84.19), `first time this month` (FU 6, Cooking.swift) and Home's `Tacos done.`. **Ruled (Product, Oct 17 4:57): the finish line must be true.** `Weeknight dal, first time.` when it is the first cook ever; `Weeknight dal, first time this month.` when it is the first in a month; Cooking.swift picks by fact. Home's `Tacos done.` is a different surface | `first time.` for a first-ever cook |
| FG12 | FW48 | Tess's words when "run packing" starts a run: only the state afterwards is written (K31.3) | `Packing has 2 left.` from K31.3 |
| FG13 | FW46, FW47 | The Lists front when Packing exists but is not running. K31.3 and LA 13.3 give "2 lists, Packing running" only | Not asserted |
| FG14 | FW38 | The sighted UNDO line after a cook's DONE. `taken back` is written for VoiceOver (K84.28) and the hint for K84.27, not for the visible slot | Template of K84.28 |

**Gap count: 14** (FG5 is a wording conflict between two proposals and FG11 a three-way wording conflict, not missing rows; the other 12 are steps with no row).

### 9b. Rows never exercised by the script

*Computed by listing every row id in the source files and removing every id named in a "Proves" cell of sections 1 to 7. "All" means no row of that group is run. The first week cannot reach some of it by design, noted in the last column.*

| File | Group | Not exercised | Why |
|---|---|---|---|
| `kitchen-refill5-acceptance.md` | K29 | All but K29.4 (11 of 12) | Cook-mode grocery speech and the sent log need a spoken ask in a cook and a Claude key |
| | K30 | All but K30.1 (14 of 15) | Plate, wash and photo rows need a link recipe with an image |
| | K31 | K31.4, 5, 7, 10, 11, 12, 14, 15, 16 | 100-item list, VoiceOver and Reduce Motion variants |
| | K32 | K32.1 to 4, 6, 7, 9, 10, 13 to 15 | Week side, small widget, Siri week, Claude with a Private recipe |
| | K33 | K33.3 to K33.17 | Link queue edge cases; the script runs K33.1 and K33.2 |
| `kitchen-refill5-pantry-acceptance.md` | K26 | K26.5, 7, 10, 11, 12, 15 to 21, 23 to 26, 28 | One-line, 100-line and private fixtures, scale |
| | K27 | All 23 | Private rows on Pantry |
| | K28 | 28 of 29 (K28.20 is run in FW11) | Hand-off rows and the rest of the strip rows |
| `kitchen-refill6-lane1-acceptance.md` | K34 | All 19 | Nutrition; nothing shows or sums nutrition this week |
| | K35 | K35.3, 4, 8 to 13, 19 | Two-timer collisions, Focus, quiet-hour timers, AX3 |
| | K36 | All 22 | Strip rows on Groceries lines |
| | K37 | K37.2 to 17, 20 | Paste edge cases; the script runs K37.1, K37.18, K37.19 |
| | K38 | K38.3, 4, 7, 8, 12 to 24 | Second plan counts, widget, 4 am skip, leftovers |
| `kitchen-refill6-lane2-acceptance.md` | K39, K40, K41 | All 64 | Claude failure rows, Pantry side reading order, widget and Live Activity mask |
| `kitchen-refill7-acceptance.md` | K43 | All 24 | Photo import |
| | K44 | 15 of 16 (K44.4 is run in FW44 and FW45) | USUALLY needs 3 or more buys at a steady gap; no first week reaches it |
| | K45 | K45.3 to 10, 15, 17 to 22 | Siri write edge cases and Dinner rows |
| | K46 | K46.4 to 16, 19, 21, 23, 26 | Trip edge cases, offline, one-hand reach, Home while the trip is open |
| | K47 | All 24 | Recipe delete, undo and restore |
| `kitchen-refill8-acceptance.md` | K51, K52, K54, K55, K58 | All | Trip reveal rows, locked Siri reads, delete window, photo failure, USUALLY rows |
| | K53 | 14 of 17 (K53.2, K53.4 and K53.14 are run) | Dinner definition |
| `kitchen-refill9-lane1-acceptance.md` | K61 | K61.6 to K61.34 | Turning Private off, backups, widget, Siri variants |
| | K62 | K62.2 to 4, 6 to 9, 12 to 14, 16 to 18, 22, 23, 25 to 32 | Half-hour and tomorrow plans, pause, two cooks, delete, quiet hours |
| | K63, K64, K65 | All 57 | USUALLY mask, Dinner 4 pm boundary, 24 h timer cap |
| `kitchen-refill10-acceptance.md` | K71, K72, K73, K74, K75, K79 | All 114 | Aisle changes, error variants and the rest of that file |
| `kitchen-overnight-acceptance.md` | K6 | 18 of 19 (K6.16 is run) | No timer rings overnight in this script (FG3) |
| `kitchen-week-leaves-acceptance.md` | K11 | All 20 | What leaves the phone; with no key, nothing leaves |
| `kitchen-widget-wash-acceptance.md` | KW-W1 to KW-W18 | All but KW-W7 (read in FW6) | The widget is a build target; its Private words are read through K32.5 |
| `kitchen-cook-mode-accessibility-acceptance.md` | K84 | K84.3, 5, 6, 7, 11, 12, 16, 19, 23, 24 | AX timer wrap, thumb-zone audit, Reduce Motion cover, VoiceOver stop |
| `cook-mode-acceptance.md` | Rulings | Rulings 3 (pause) and 4 ("5 more minutes") | Pause is slice 12b; no step ran over |
| `meal-plan-groceries-acceptance.md` | MP-F and engine | MP-F3, MP-F4, MP-F7, the six engine rows, Kitchen week rulings 2, 3, 5 | Same-day-only close, two plans one recipe, skip then cook |
| `pantry-acceptance.md` | S | S5, S6, S9, S14, S16 | USUALLY HAVE needs repeat buys; index and accessibility rows |
| `kitchen-week-one-rows.md` | WK | WK2, 3, 5, 6, 9, 10, 11, 12, 14, 18, 19, 21, 24 | States for empty, thin and partial weeks; this week is full |
| `kitchen-phrases.md` | P# | 40 of 50 (P#1, 3, 14, 15, 16, 25, 33, 34, 41, 44 are run) | Grammar rows run in `KitchenCaptureTests` |
| `kitchen-phrases-2.md` | C | C2, C3, C4, C5, C6, C8, C9, C10 (C1 and C7 are cited) | Aisle change, Private forms other than FW52, errors, refusals, Claude clock, timer cap |
| Not run as rows | | `never-sums-audit.md` N1 to N10; `kitchen-error-states-acceptance.md` ER1 to ER27; `kitchen-misfire-rows.md`; `kitchen-counts-vs-claude-acceptance.md` KC1 to KC32; `kitchen-week-one-private-filter.md` PF1 to PF13; the Oct 17 copy rechecks | Nutrition, error, Claude and counts-filter files belong to the longer scripts |


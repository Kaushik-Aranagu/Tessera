# Kitchen REFILL 5, Lane 1: Pantry acceptance rows K26 to K28

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 52, "2:45 AM REFILL 5", Lane 1, which waits on the Pantry screen). Docs only, no code. Sources read: `pantry-acceptance.md` (S1 to S17 and Core 1 to 7; where it and Design sheet 78 differ, sheet 78 wins, as that file says), Design `/mnt/project-files/tessera/design/pantry.md` (sheet 78), `kitchen-sides-acceptance.md` section 6 (rows 6.1 to 6.8), `groceries-side-acceptance.md` (GS), `never-sums-audit.md` (N1 to N10), `kitchen-acceptance.md`, and the format of `kitchen-refill5-acceptance.md` (K29 to K33). Numbering: K26.n, K27.n, K28.n. Each row is runnable: an action, then the expected result with the exact copy. These rows add to S1 to S17 and 6.1 to 6.8 and do not repeat them; where a row leans on one, it names it.*

**House rules used by every row.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks are lowercase ("8:30 pm"). Digits for counts. US English and units. A walled thing reads "Private item", "Private recipe" or "Private note". Cobalt is Tess's voice only; Pantry's ochre appears only on state words and the index row (S17). Quiet hours 23:00 to 07:00; the day starts at 4 AM. Money appears only with an amount or a currency sign. Nutrition appears in exactly one place, the PER 100 G side of one ingredient, and is never summed (`never-sums-audit.md`). No row, fixture or log in this file contains a key or a key-shaped string; tests that need a fake build it with `ClaudeSection.fakeKey`. No row runs a live Claude call: Claude is a stub in every test, and Pantry sends nothing (Core 7, 6.7).

**Fixture names.** "Seed pantry" = the demo history with `-resetDemo -demoTime 18:10` (Friday, since Saturday's shop). States are set through `ObjectStore` ops, never raw `valuesData`. "N known" means N ingredients whose `state` is in, low or out; unknown ingredients are never listed (Defaults table) and never counted.

---

## K26. Pantry empty state, one-item state and 200-item state

Layout from sheet 78: PANTRY at 52, weekday at 138, context line at 186 with the side word OUT AND LOW at its right, hero at 212, groups from 296, one Body 21 line per thing at a 40 pt pitch, Tess's line the only thing in 736 to 820. No title, no back word (tab-level area), no card, pill or badge, nothing under 16 pt, nothing red.

### K26 A. Empty (nothing known)

| # | Action | Expected |
|---|---|---|
| K26.1 | Fresh install, no demo (zero known ingredients); open Pantry from KITCHEN's index | Frame in place: "PANTRY" at 52, "Friday" at 138. The context line at 186 is empty (there has been no shop, so no "since Saturday's shop") and the side word OUT AND LOW still sits at its right. Hero reads "Nothing yet". Under it, at 55% ink: "Clear a shop or finish a cook and this fills in." No groups, no group labels, no art, no icon, no count |
| K26.2 | Same state; read every string on the page | "0 out, 0 low", "0 out", "0 low", "Empty", "No items", "Get started" and "Add" appear nowhere. Tess's line, cobalt, in 736 to 820: `Say "out of milk" and I'll keep it.` |
| K26.3 | Same state; open the index | PANTRY row line reads "Nothing yet" (the hero verbatim). Home's Pantry line reads "Nothing yet" too; Tess's line and Home never disagree (S13) |
| K26.4 | Same state; open the side (tap OUT AND LOW) | Side opens on "Nothing known yet." (row 6.4) with no key and no list. No "ADD 0 TO GROCERIES" is drawn or exists in the accessibility tree. (Known but none out reads "Nothing out.", K26.9) |
| K26.5 | Same state; try to scroll the front | The page does not scroll (content is shorter than the screen); no scroll indicator drawn |
| K26.6 | Same state; say "out of milk" to Tess | One op: milk becomes out and "Milk" lands on Groceries. Hero changes in place from "Nothing yet" to "1 out" (digits; "1 out", never "1 outs"); group OUT appears with one line "Milk" and the state word "out" in ochre at 700 with the faint ring. Receipt "Milk, out. On Groceries." in the UNDO slot. UNDO inside 4 s (a new add; 10 s under VoiceOver) restores both, the page returns to "Nothing yet" and Tess's line returns |
| K26.7 | Reduce Motion on; do K26.6 | The change between "Nothing yet" and "1 out" is a 150 ms crossfade through MotionPolicy, no spring, no slide |
| K26.8 | Dynamic Type at AX5; VoiceOver on | One column, "Nothing yet" wraps, nothing clipped. VoiceOver reads "Pantry. Nothing yet. Clear a shop or finish a cook and this fills in." |

### K26 B. Known, nothing out or low

| # | Action | Expected |
|---|---|---|
| K26.9 | Seed 12 ingredients as in, none low or out; open Pantry | Hero "Nothing out". Groups OUT and LOW are not drawn, labels included. USUALLY HAVE shows if it has names (S11). The side reads "Nothing out." with no key. The 12 in things are not listed on the front (the long tail) |

### K26 C. One item

| # | Action | Expected |
|---|---|---|
| K26.10 | Seed exactly 1 known ingredient: limes, out; open Pantry | Hero "1 out" (a zero count is not written: never "1 out, 0 low"). Context line "since Saturday's shop" if a shop cleared, otherwise empty. One group label OUT at 13/700 and one line: "Limes" in ink, "out" at the right in ochre mixed 72% with ink at 700, the faint ring (11 pt, 1.3 pt stroke, ink 42%) at x 6. No LOW label |
| K26.11 | Same; read the index and Home | Both read "1 out", the hero verbatim |
| K26.12 | Same; open the side | Glance: big fact "1" with unit "out", then "1 to buy", foot word ALL OF THEM; "0 low" is not drawn (zero lines are dropped). Key "ADD 1 TO GROCERIES". Full side: context "1 to buy", one line "Limes" with the value "bought Tue" if `lastBoughtAt` is a Tuesday, or no value if never bought |
| K26.13 | Same; tap the key | Receipt "Pantry, 1 added." with UNDO 4 s (a new add; 10 s under VoiceOver). Limes is on Groceries once. The hero still reads "1 out" (adding to Groceries does not change the state; only a shop clear does) |
| K26.14 | Same; tap "out" on the Limes line | out to in, one `.selection`, receipt "Limes, in." UNDO 10 s (a change); the line closes up in 320 ms; hero becomes "Nothing out". Open the Limes Ingredient page and tap its state word: in to low, receipt "Limes, low."; the line joins LOW and the hero reads "1 low", never "1 lows" |
| K26.15 | One item, low only: lemons low | Hero "1 low". The OUT label is not drawn. The LOW line has no ring (S4). Key "ADD 1 TO GROCERIES" |
| K26.16 | One item, private: one out ingredient with a walled name | Hero "1 out". The line reads "Private item" at 66% ink with the state word and ring; tapping it opens nothing (S15). Side line "Private item"; key "ADD 1 TO GROCERIES"; receipt "Private item, on Groceries." No word of the real name appears in any string, VoiceOver label or log |

### K26 D. 200 items

Fixture A: 200 known ingredients, 40 out, 60 low, 100 in (100 lines on the front, 100 hidden), spread over all aisles. Fixture B: 200 known, all 200 out. Fixture C: fixture A with 3 walled names among the out lines.

| # | Action | Expected |
|---|---|---|
| K26.17 | Open Pantry with fixture A | Hero "40 out, 60 low". OUT holds 40 lines, then LOW 60 lines, each at the 40 pt pitch, ordered inside a state by aisle in the shop's walk order. The 100 in things are not drawn (S8). USUALLY HAVE at the foot, capped at 4 names (from four, "Rice, coffee and 2 more"). 100 lines drawn |
| K26.18 | Same; scroll top to bottom | The page scrolls as a whole; the hero count and the lines never disagree. At the bottom USUALLY HAVE is reachable and sits clear of Tess's band at 736 (bottom inset equals the band; the Groceries basket-bar lesson in `kitchen-acceptance.md`). Group labels do not stick (assumption 5) |
| K26.19 | Same; scroll to line 57, tap it, press back | Back lands on the same scroll position (S9), within 1 pt |
| K26.20 | Same; fling-scroll top to bottom 3 times | No blank rows, no popping, lines are built lazily. **120 Hz check, a test choice:** on a ProMotion iPhone (the simulator cannot prove 120 Hz; its run is informational), record the same fling with Instruments' Animation Hitches template; pass is no hitch and no frame over 8.3 ms budget misses reported in the scroll. The result is attached to the review (there is no CI) |
| K26.21 | Same; tap "out" on the 12th OUT line while scrolled to it | The line closes up in 320 ms and lines below slide up; the hero changes from "40 out, 60 low" to "39 out, 60 low" with no count-up; the scroll offset does not jump and content above does not move |
| K26.22 | Same; open the side | Glance "40 out", "60 low", "100 to buy", foot ALL OF THEM. Key "ADD 100 TO GROCERIES". Out lines before low lines, each with "bought Sat" or "bought Tue" from `lastBoughtAt` (6.2); the side scrolls at the same pitch |
| K26.23 | Same; tap the key | One op adds 100 (fewer if some are already on Groceries; the key's number counts only new rows, 6.3). Receipt "Pantry, 100 added." with UNDO 4 s. UNDO takes all 100 back in one op. Groceries count rises by exactly the key's number |
| K26.24 | Fixture B | Hero "200 out", digits. LOW label not drawn. Key "ADD 200 TO GROCERIES". At AX5 the hero wraps to one column |
| K26.25 | Fixture C | The 3 private lines read "Private item" in their aisle position, count in the hero and in "to buy", and open nothing. A grep of the accessibility tree and rendered strings for the real names finds none |
| K26.26 | Counts agree | On fixture A the hero "40 out, 60 low", the glance "40 out", "60 low", "100 to buy", the index line and Home's line are the same numbers (S2, 6.1). Changing one state updates all of them on the same frame |
| K26.27 | After a cook that set 3 things low or out | Tess's line is the phone's fact, "Tacos took the cilantro and limes." (names, as `FinishCooking` set them). With more than 3 names the line gives the count instead: "Tacos took 5 things." (digit). Never a forecast, never "running out" |
| K26.28 | Scale: the 5-year history fixture (`scripts/test.sh --scale`) with fixture A | Pantry opens from the in-memory graph, not the database; memory does not grow with each open |

---

## K27. Pantry expiry and low-stock wording

Pantry knows state and a bought date; it has **no expiry**: `pantry-acceptance.md` Open question 1 sets "in does not expire", and sheet 78 forbids due dates, stock counts and forecasts. So "expiry wording" here means the dated words the phone does print ("bought Sat") and the proof that no expiry or forecast wording exists.

### K27 A. State, date and low-stock words

| # | Action | Expected |
|---|---|---|
| K27.1 | Read the state words | "out" (700) and "low" (600) on the front; "in" and "unknown" only on the Ingredient page. Lowercase, no icon, ochre mixed 72% with ink, nothing red |
| K27.2 | Side lines for an ingredient last bought on a Saturday, a Tuesday, and never | "bought Sat", "bought Tue", and no value at all. Three-letter US weekday, no period. Never "Sat 10/11", never "3 days ago", never a clock |
| K27.3 | A bought date older than 7 days (3 weeks ago) | "bought Sep 26" (month abbreviation, digit, no year, no comma). Never "3 weeks ago", "stale", "old" or "expired". The state is unchanged by time (Engine P) |
| K27.4 | Day starts at 4 AM: a shop clears at 2:00 am Saturday | The side says "bought Fri"; a clear at 4:00 am says "bought Sat" |
| K27.5 | Search the front, side, Ingredient page, Tess strings, receipts and widgets for "expire", "expires", "expired", "use by", "best before", "spoil", "going off", "due", "stale", "fresh until", "running out", "about to run out" | None found. Tess never forecasts; the only rhythm line is K27.7 |
| K27.6 | Ingredient page state sentence: out and bought Sat; out and never bought; low after a cook; unknown | "Out. Bought Sat." / "Out." / "Low. Tacos used it." / "Not known." Capital first letter, period, no "at" |
| K27.7 | Milk bought 4 times, about every 7 days; then bought once | Tess (cobalt), the same words on both side stops: "You buy milk about every 7 days." Under 3 buys: empty. Digits; never "weekly" or "a week" |
| K27.8 | After a cook that finished at 6:40 pm | Tess's line has no clock. Anywhere a clock is shown it is lowercase "6:40 pm", never "6:40 PM" and never "at 6:40 pm" |
| K27.9 | KITCHEN's index line with a cook planned for 7 pm; then 7:30 pm | "Tacos, 7 pm"; "Tacos, 7:30 pm". Never "Tacos at 7 pm" (S14) |

### K27 B. Counts, digits and receipts

| # | Action | Expected |
|---|---|---|
| K27.10 | Hero for 4 out and 2 low; 1 out and 1 low; 0 out and 3 low; 5 out and 0 low | "4 out, 2 low"; "1 out, 1 low"; "3 low"; "5 out". Digits, never "four", never "0 out, 3 low", no trailing comma |
| K27.11 | Side context line for 6 lines; for 1 | "6 to buy"; "1 to buy". Never "6 items" |
| K27.12 | Key label for 6; for 1; for 0 | "ADD 6 TO GROCERIES"; "ADD 1 TO GROCERIES"; no key at 0 |
| K27.13 | USUALLY HAVE with 1, 3, 4 and 6 names | "Rice"; "Rice, coffee, eggs"; "Rice, coffee and 2 more"; "Rice, coffee and 2 more" (cap 4 holds). "and 2 more" at 55% ink. Digits, never "and two more" |
| K27.14 | Group labels | "OUT", "LOW", "USUALLY HAVE", uppercase at 13/700. Never "LOW STOCK", "RUNNING LOW", "NEED", "OUT OF STOCK" |
| K27.15 | State-word tap receipts | The thing first, the new state, a period: "Limes, in." / "Limes, low." / "Limes, out." No "marked", "set to" or list name |
| K27.16 | Receipts that join a list | "Milk, on Groceries." (swipe or name tap); "Milk, already on Groceries." with no UNDO when it was there; "Pantry, 6 added." (the key); "Milk, out. On Groceries." (the phrase "out of milk"). Always "on", never "in Groceries", "to Groceries" or "added to" |
| K27.17 | "out of milk" when milk is already out and on Groceries | "Milk, already on Groceries." No UNDO, no second row, no state change |
| K27.18 | "have rice" and "got milk" | "Rice, in." and "Milk, in." One op each; UNDO 10 s (a change). A Groceries row added earlier stays (have never removes a row) |

### K27 C. Private item masking

| # | Action | Expected |
|---|---|---|
| K27.19 | Mark an ingredient with a walled name (medicine or supplement) out | Front line, side line, USUALLY HAVE, Tess's line, index, Home, widget and Spotlight show "Private item"; the front line at 66% ink with its state word and ring. In USUALLY HAVE it reads "Private item" in the name's place and counts toward "and N more" |
| K27.20 | Tap the private line; left-swipe it; tap its state word | Tap opens nothing (S15). Swipe adds "Private item" to Groceries: "Private item, on Groceries." UNDO 4 s. State word: "Private item, in." UNDO 10 s |
| K27.21 | VoiceOver on a private line | "Private item, out". Cycle is the default action, "Add to Groceries" the custom action. The real name is never spoken |
| K27.22 | A private ingredient in the side | A normal fact for the date ("bought Sat"), the name masked; counts in "to buy" and the key's N; sits in its true aisle position, which is not shown |
| K27.23 | Search logs, the receipts rows, the AI-12 pack snapshot and every request body after K27.19 to K27.22 | The real name appears in none; no Pantry state or `lastBoughtAt` appears in any pack (Core 7, 6.7) |

---

## K28. Pantry to Groceries handoff, price drop, never-sums proof

The handoff, "add what's low": the key sends out and low lines to Groceries; in and unknown lines never go (the side lists out then low only, 6.2). The key is the dry run of the same add the recipe peek uses (`kitchen-sides-acceptance.md` line 48): the key's N is computed before the tap and equals the rows the tap adds.

### K28 A. The handoff and the dry-run key

| # | Action | Expected |
|---|---|---|
| K28.1 | Seed milk, eggs, limes out; rice, lemons, yogurt low; Groceries empty. Open the side | Glance "3 out", "3 low", "6 to buy", foot ALL OF THEM; key "ADD 6 TO GROCERIES". The glance's 6 and the key's 6 are one number |
| K28.2 | Tap the key | One op. Receipt "Pantry, 6 added." with UNDO 4 s (a new add; 10 s under VoiceOver). Groceries gains 6 rows named as the ingredients ("Milk", "Eggs", "Limes", "Rice", "Lemons", "Yogurt") in the shop's walk order |
| K28.3 | Dry-run proof | A test reads the shared dry-run count before the tap and gets 6; after the tap Groceries holds 6 more open rows. Pre-seed Groceries with milk and eggs: the key reads "ADD 4 TO GROCERIES", the receipt "Pantry, 4 added.", Groceries gains exactly 4 |
| K28.4 | Everything already on Groceries | The key is not drawn (never "ADD 0 TO GROCERIES"); the lines still show and the context still reads "6 to buy". A name tap reports "Milk, already on Groceries." with no UNDO |
| K28.5 | UNDO inside 4 s; then after 4 s | Inside: all 6 rows leave Groceries in one op, Pantry states unchanged, Tess's line returns. After: the slot is gone and a tap does nothing |
| K28.6 | UNDO slot timing | New add (key, swipe, name tap, "out of milk"): 4 s. Change (state-word tap, Ingredient page cycle, "have rice"): 10 s. VoiceOver running: 10 s for both. One app-wide slot; a new receipt replaces the old one and the old UNDO is gone |
| K28.7 | Tap the key, then within the window tap a state word | "Limes, in." replaces "Pantry, 6 added." with UNDO 10 s; the earlier add can no longer be undone from the slot; its rows stay on Groceries |
| K28.8 | After the handoff, open Groceries and FOR WHAT | The 6 rows carry no recipe dab and no price; they sit under JUST BECAUSE counted once each (GS4). A shop clear then sets each ingredient to in with `lastBoughtAt` (Engine P) and Pantry loses those lines |
| K28.9 | Left swipe on the "Milk" out line | "Milk, on Groceries." UNDO 4 s; the Pantry line stays (the area is a view); the next key count drops by 1 |
| K28.10 | Planned recipe against pantry, fixture D1 Paprika chicken (chicken thighs in, lemon low, Greek yogurt out, the rest unknown) | The peek reads "have", "low", "out" on those lines and the recipe key reads "ADD 6 TO GROCERIES" (every line but the chicken, Core 4). Pantry's key is unaffected |
| K28.11 | Tap the Pantry key, then the recipe key for overlapping lines | The second adds only the remainder and never doubles a row; Groceries holds one row per ingredient |
| K28.12 | Quiet hours: tap the key at 23:30 | The add and the on-screen receipt happen as normal; no notification, badge, Home offer or Live Activity is created, and nothing is scheduled for 07:00 |
| K28.13 | Tap the key with "Tess asks Claude" on and a stubbed Claude | Zero Claude requests; WHAT WAS SENT gains no row; the pack snapshot holds no state and no bought date |

### K28 B. The price drop

Rule: money in a typed or spoken phrase is stripped once, before anything leaves the engine, and never reaches the row, note, receipt or any log (`grocery-capture-miss-acceptance.md`; voice path in K29). Money shows only with an amount or a currency sign.

| # | Action | Expected |
|---|---|---|
| K28.14 | Type to Tess "out of milk $4" | Milk becomes out and "Milk" lands on Groceries in one op. Receipt "Milk, out. On Groceries." No 4 and no $ on the row, note, receipt, Tess's line, Pantry line or side. UNDO 4 s restores both |
| K28.15 | Type "we're out of eggs 3.49" | A bare "3.49" has no sign or currency word, so it is not money by the house rule: "Eggs" lands with no amount and no price, receipt "Eggs, out. On Groceries." No "3.49" appears anywhere (assumption 4) |
| K28.16 | Type "no more rice, 2 lbs $9" | Rice out and on Groceries with quantity "2 lbs"; the "$9" is dropped. Receipt "Rice, out. On Groceries." |
| K28.17 | Say "out of milk $4" in cook mode (voice) | Same as K28.14. If the grammar misses and the stub is called, the text it receives is "out of milk" with no "$" and no digit with a currency sign (K29.1 to K29.6) |
| K28.18 | Type "out of milk 4 dollars" and "out of milk €4" | Both are money: dropped; row "Milk" only; same receipt. Signs and words: $, €, £, "dollars", "bucks", "USD" |
| K28.19 | Type "have rice $2" | "Rice, in." No price kept, nothing joins Groceries |
| K28.20 | Search rows, notes, receipts, `capture-misses.jsonl`, the ops log, the pack snapshot and every request body after K28.14 to K28.19 | No `\$\d`, no `\d+\.\d{2}` tied to a currency sign, none of the dropped amounts. A walled phrase ("out of my metformin $40") gives "Private item, out. On Groceries." and no miss-log line (K29.4) |
| K28.21 | Pantry key or swipe on an ingredient whose old Groceries row carried a price | The new row has no price field; nothing is copied and nothing shows on the side |

### K28 C. Never-sums proof

| # | Action | Expected |
|---|---|---|
| K28.22 | Read every string on the Pantry front and side with fixture A | No kcal, protein, carbohydrate, fat, fibre, "calories", "per serving" or "per 100 g". Only counts and dates (N6) |
| K28.23 | After the handoff, read Groceries and FOR WHAT | No nutrition on a row, the count line, the receipt or Tess's line; nothing totals the 6 ingredients (N1) |
| K28.24 | Open the Chicken thigh Ingredient page, then its PER 100 G side | One ingredient only: "121 kcal", "19.7 g protein", "0 g carbohydrate", "4.1 g fat", "0 g fibre" with "USDA FoodData Central" under them (row 2.1). Rounded for display only: "0 g", never "0.0 g" (2.1c). No sum, average, rank or comparison |
| K28.25 | On that side look for the other 5 handed-off ingredients | None. No second ingredient, no "used in N recipes" nutrition; a recipe that holds chicken is a name (N5) |
| K28.26 | Ask Tess "how many calories are in what I'm buying" and "how many calories is this week" | Tess says plainly she doesn't add food up and offers the one ingredient's side. No number (N8). Wording: `I don't add food up. Ask me about one ingredient.` (assumption 8) |
| K28.27 | After the handoff, inspect the AI-12 pack snapshot | Grocery names as before, no nutrition number, no total, no Pantry state, no `lastBoughtAt` (N9, Core 7). A test asserts no nutrition field name is in the pack |
| K28.28 | Static check | A test searches the Pantry, Groceries and handoff sources for any sum, average or `reduce` over nutrition values and finds none; exactly one function reads the nutrition columns, and only for a single ingredient (`never-sums-audit.md` "How it's proved") |
| K28.29 | Widgets, Live Activity, Spotlight, App Intents, exports and backups after the handoff | None carries a nutrition number; exports hold the bundled table rows only, never a figure for a shop or a day (N7, N10) |

---

## Assumptions and flags

1. **Sheet 78 wins over older text.** Two conflicts remain between sheet 78 and `kitchen-sides-acceptance.md`: row 6.4 says the nothing-known side opens on "Nothing known yet." while sheet 78 and S11 say "Nothing out."; row 6.8 gives Reduce Motion as 200 ms while S16 and sheet 78 say 150 ms. K26.4 keeps "Nothing known yet." for nothing known and "Nothing out." for known-but-none; K26.7 uses 150 ms. Design/Product to confirm and fix 6.4 and 6.8.
2. **Pantry has no expiry.** K27 treats expiry wording as bought dates plus a grep proof that no expiry or forecast word exists (Open question 1, sheet 78). Real expiry needs a new decision and new rows.
3. **Key at zero new rows.** K28.4 hides the key when everything is already on Groceries (6.3 counts only new rows). No copy exists for that case and none is added without Design.
4. **Bare decimals are not money.** K28.15 follows the house rule (money only with an amount or currency sign). If Product wants any trailing decimal dropped, only the log changes, not the receipt.
5. **Layout facts not in the sheet:** whether group labels stick and whether the frame scrolls away at 200 items. Default taken: the page scrolls as a whole, labels do not stick. Design to confirm.
6. **Budgets are test choices.** The 120 Hz hitch check (K26.20) runs on a ProMotion iPhone; the simulator cannot prove it. No frame-time budget is set by the board or sheet.
7. **"Add what's low" read as out and low,** as the key does (sheet 78); in and unknown lines never go.
8. **Unconfirmed strings:** Tess's calorie reply (K28.26) and the state sentences (K27.6) are my proposals; Design confirms the words. "Dry run" is the shared count behind the recipe peek and key; Core names the function. Sheet 80 and decision 2:40 are cited as in K29 and not re-read; no 2:40 AM Oct 17 entry exists in `decisions.md`.
9. No key, key prefix or key-shaped string appears in this file.

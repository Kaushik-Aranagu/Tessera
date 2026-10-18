# Kitchen REFILL 6, Lane 2: acceptance rows K39 to K41 (K42 is in `kitchen-v2-acceptance.md`)

*Kitchen lead, 2026-10-17 (board `kitchen.md` line 54, "2:55 AM REFILL 6", Lane 2, Pantry/AI). Docs only, no code. Format and numbering follow `kitchen-refill5-acceptance.md` (K29 to K33) and `kitchen-refill6-lane1-acceptance.md` (K34 to K38). Each row is runnable: an action, then the expected result with the exact copy. Read and checked against: `groceries-ai-acceptance.md` (sections 2 and 6), `groceries-ai-runnable-rows.md` (A to D, row D5), `kitchen-error-states-acceptance.md` (ER8 to ER12), `kitchen-refill5-pantry-acceptance.md` (K26 to K28), `kitchen-refill5-acceptance.md` (K32), `kitchen-sides-acceptance.md`, `kitchen-widget-wash-acceptance.md` (KW-W7, KW-W8), `pantry-acceptance.md` (S16), Design sheets 77 (`sides-77.md`), 78 (`pantry.md`) and the builder briefs (`builder-briefs-77-78.md`), plus `docs/ai/` (`claude-client.md`, `spend-projection.md`, `stepaside-cap-tests.md`, `job-trigger-table.md`, `offline-retry-table.md`). Where a row already exists, this file points at it and adds only what is missing.*

**House rules used by every row.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks are lowercase ("8:30 pm"). Digits for counts. US English and US units. A walled thing reads "Private item", "Private recipe" or "Private note". Cobalt is Tess's voice only. Money appears only with an amount or a currency sign. The in-app Claude cap is $50 a month, a hard stop, resetting on the 1st at 4 AM; Home lines, the week story and living colour step aside at $40, and the groceries link job does not (see K39 and "Assumptions and flags"). Claude is never sent money or body facts. No row, fixture or log here contains a key or a key-shaped string; tests build any needed fake with `ClaudeSection.fakeKey`. No row runs a live Claude call: Claude is a stub (a fake `linkItems` reply, or a stub that throws) in every test.

---

## K39. AI-12 grocery wording: failure rows (Claude down, $40 step-aside, $50 cap, offline)

AI-12 is the groceries link ask: the phone matches what it can by key and asks Claude (`linkItems`, Haiku, 8 s) only about the leftovers; Claude returns handle pairs only and the words of the ask, "{Row}, for the {recipe}?" with KEEP and NOT NOW, come from the phone (`groceries-ai-acceptance.md` section 2). So "grocery wording" has two halves, and each row checks both: **what the phone says** (the notice) and **the plain fallback** (what the list does without the ask). Trigger (ruled, decisions 3:00 Oct 17; `job-trigger-table.md` wins over `groceries-ai-acceptance.md`): the link ask fires only when he taps it. Planning a meal and typing a row never send it. In the rows below, "plan tacos" means the rows land and he then taps the link ask (8 s wait; on timeout the rows land anyway).

**The one rule behind every row.** Rows always land; the phone's key match (`IngredientLine.key`) always runs; a failed ask costs at most one duplicate row he can delete (the eval's own trade, section 2). No failure writes a row, a pair or an ask. The notice is the Kitchen error rule from `kitchen-error-states-acceptance.md`: one line in the UNDO slot at Tess's band, ink, Body 19, replacing her line; never red, amber, URL, key or private words (ER8 to ER10, ER27). Failures are silent on any automatic trigger (ER10: "Jobs with a fallback use it silently") and spoken only on his tap (ruled).

Setup for every row: a planned week as `groceries-link-eval.md` fixture W (4 recipes, 25 typed rows, 5 phone-linked rows), "Tess asks Claude" on unless the row says otherwise, a stub model, a clean `TessCall` ledger, a clean sent log. Assertions on the request body use the pack in A1 to A5 of `groceries-ai-runnable-rows.md` (handles and titles only).

### Claude down (busy, 5xx, timeout)

| # | Action | Expected |
|---|---|---|
| K39.1 | Plan tacos for Thursday; the stub answers HTTP 529 (busy) | The missing recipe rows land at once in their aisles ("Tacos, 7 added." with UNDO 10 s, thing first, `groceries-ai-acceptance.md` section 1). No ask appears. The notice, in the UNDO slot after the receipt's window or in place of Tess's line: "Claude is busy. Kept it for later." (ER8). Nothing is red; no `.warning` haptic (kept-for-later is silent). The list reads the same as before the call plus the 7 rows |
| K39.2 | Same, the stub answers 500, then 503 | Same line, same rows. One request each, no retry loop inside the call (the job table says "No job retries today"); a row of the ledger is written only if the call settled with a cost, never for a refused or failed-before-send call |
| K39.3 | Plan tacos; the stub never answers (8 s) | At 8 s the rows have landed (the 8 s wait is the ceiling). Notice: "Claude didn't answer in time. Kept it for later." (ER9). If the stub answers at 11 s with a valid pair, the ask appears then, as "Scallions, for the tacos?" with KEEP and NOT NOW; the rows are not redrawn |
| K39.4 | After K39.1, add the typed row "scallions" while the week is planned | The typed row lands at once. Typing never sends the ask, so no call is made and nothing is said. The next ask is his next tap; nothing was queued from K39.1 |
| K39.5 | After K39.1, open Groceries and read every string and the accessibility tree | The context line is unchanged by the failure ("9 to buy across 4 aisles"). No "failed", "error", "offline", "retry" or "Claude" appears on the list. Only the notice in K39.1 or K39.3 ever names Claude |
| K39.6 | Inspect the request body of K39.1 and K39.3 | Handles and titles only; no amount, no `$`, no digit-with-currency, no note, no shop, no `checkedAt`, no body fact, no private row (A1 to A5, W2). The text "Claude" never carries a row's typed words. A grep for `\$\d` finds nothing |
| K39.7 | VoiceOver on; run K39.1 | The notice is announced once, polite, focus does not move: "Claude is busy. Kept it for later." The rows' own receipt is announced first ("Tacos, 7 added.") |

### No daily cap on grocery asks

Ruled (decisions 3:00 Oct 17): there is no daily cap on AI-12 grocery asks. The limits are the $50/month in-app cap and the $40 step-aside rule. The 40-a-day limit in `docs/ai/` belongs to Home lines only (`offline-retry-table.md`: "Max 1 call per 10 min, 40 a day (docs only)"); asking Claude about a subject is 20 a day. `linkItems` has no day limit (about 60 calls a month, typical).

| # | Action | Expected |
|---|---|---|
| K39.8 | Make 41 `linkItems` calls in one 4 AM day (a stub, the 10 minute debounce lifted for the test) | All 41 are sent. There is no day cap on this job; no notice about a day limit appears; the ledger holds 41 rows for "linkItems" |
| K39.9 | Home lines have made 40 calls today; plan tacos | Home lines show rules lines for the rest of the day (their own cap, `offline-retry-table.md`). The groceries ask is sent anyway: the two jobs count separately. No line about a daily limit on Groceries |
| K39.10 | Conditional: only if a per-day cap ever pauses a job (none does today, and none applies to `linkItems`): his tap on a capped job | The rows land, no request is made, no ledger row is written (a refused call writes none). The line, in the cap voice: "Claude paused until tomorrow." ("tomorrow" is the 4 AM day). The 4 AM rollover lifts it. Not run for grocery asks |

### The $40 step-aside and the $50 cap

Settled in the docs: at 80% ($40) only Home lines, the week story and living colour step aside before the reserve; capture, plan, recipe, questions and `linkItems` run to $50 (Product 8:16 and 8:21; `stepaside-cap-tests.md` test 6 `planRecipeAskSubjectLinkItemsRunAt40`; `job-trigger-table.md`). At $50 every job is refused with "Claude paused until <date>." and no row (`claude-client.md`, `spend-projection.md`).

| # | Action | Expected |
|---|---|---|
| K39.11 | Month total $40.00 exactly; plan tacos | The groceries ask is **sent** (it does not step aside at $40). Rows land, the ask comes as normal, no step-aside notice. The Settings spend line shows its existing amber line at 80% (not changed by this job) |
| K39.12 | Month total $40.00; Home lines ask | Home lines step aside (rules lines, no request, no row). This proves K39.11 is a choice by job, not an accident. Pairs with `stepaside-cap-tests.md` tests 2 to 4 and 6; no new engine row |
| K39.13 | Month total $49.99 and an estimate that would pass $50; plan tacos | Refused before the reserve (`reserve` returns nil a little before $50 exactly): no request, no ledger row. Rows land. Plain fallback: the phone's key match only. He tapped, so the line speaks: "Claude paused until Nov 1." (ruled: failures are spoken only on his tap) |
| K39.14 | Month total $50.00; he taps a Claude-only ask (for example the Ingredient page's fill ask) in the same session | The line: "Claude paused until Nov 1." (the house date; the cap resets on the 1st at 4 AM). Tap opens CLAUDE in Settings (ER10). No haptic. No request, no row |
| K39.15 | Month total $50 on Oct 31; read the line | "Claude paused until Nov 1." (`stepaside-cap-tests.md` test 20). At 4:00 am Nov 1 the cap lifts; his next tap asks again |
| K39.16 | Stub the month total at $50; plan tacos, add 3 typed rows, check 2 rows | Every on-device action works with nothing said: "Tacos, 7 added.", the typed rows, the checks. No "paused" line appears from any of them (ER12: only work that needed the connection speaks) |
| K39.17 | Read the cap and the step-aside numbers in every string, log and request | "$40" and "$50" appear only on the Settings spend line, with the currency sign, and in tests. Money never appears in a request body (K39.6), in Tess's line, in a receipt or in the sent log (the sent log holds counts and times, never amounts; sheet 80) |

### Offline

| # | Action | Expected |
|---|---|---|
| K39.18 | Airplane mode; plan tacos | Nothing is shown about being offline (ER12). The rows land, "Tacos, 7 added." The ask is not tried (`NWPathMonitor` unsatisfied) and nothing is queued for later; `groceriesLinkSendsNothingWhileShoppingOrWorkoutOrOfflineOrCapOrDemo` (D5) holds with a stub that counts 0 calls |
| K39.19 | Airplane mode on mid-call (after the request starts, before the reply) | `notConnectedToInternet` or a timeout: the same as K39.3. The line: "Claude didn't answer in time. Kept it for later." Rows are in place; no duplicate rows from a retry |
| K39.20 | Back online, open Groceries | No catch-up burst. His next tap asks once. The ask for K39.18's plan does not appear unless he taps it (nothing was queued) |
| K39.21 | Offline, the ledger and the sent log | Neither gains a row for an offline attempt. The WHAT WAS SENT count (30 days) is unchanged and still equals the sum of the job counts |
| K39.22 | "Tess asks Claude" off (the switch), online | Nothing is sent, nothing is queued. If he tapped a Claude-only ask, the line is "Claude is off." and the tap opens CLAUDE in Settings (ER10). Rows land; the list is complete without asks |
| K39.23 | No key yet, online | Same as K39.22 with "No Claude key yet." on his tap; an automatic trigger never asks and says nothing. A key-shaped string typed into a grocery row is refused on the phone before any send (CM11) and never reaches a log |

### Cross-cutting

| # | Action | Expected |
|---|---|---|
| K39.24 | Run K39.1, K39.3, K39.13, K39.18 and K39.22 in a row, then count the list | The same 9 rows, nowhere a duplicate that a key match would have joined; the plain fallback is the engine of the list, Claude only adds links |
| K39.25 | A failure during an open ask (the first ask is on screen, the second call fails) | The open ask stays until answered or left (section 2); the failure writes nothing and says nothing over it. KEEP and NOT NOW behave as before |
| K39.26 | A private row ("Private item" in the list) in any of the rows above | It is never in the pack (W3), the failure paths and the sent log hold no word of it, and the fallback treats it like any other row on the phone |

---

## K40. Pantry sides (sheets 77 and 78): VoiceOver reading order

Sheet 78: Pantry is an area with a front and a side (OUT AND LOW, kind AHEAD). Sheet 77 adds the Kitchen sides (Groceries FOR WHAT, Recipe original COOKS, class page ITS OBJECTS, Paste WHAT I READ). Existing VoiceOver rows: `pantry-acceptance.md` S16 (state-word label, cycle as the default action, "Add to Groceries" as a custom action), K26.8, K27.21; `drawn-sides-acceptance.md` SA-EX-15 (escape steps back one stop). This block fixes the **order** of the elements, which none of them does. Rules from `voiceover-recipe-clock-lists.md`: thing first, sentence case (an all-caps short word can be spelled out), durations in words, glyphs and rings hidden, a decorative layer hidden, the back stop is the escape gesture. The front at 30% behind a glance is hidden from VoiceOver (it is not interactive there).

Setup: fixture of K28.1 (milk, eggs, limes out; rice, lemons, yogurt low; coffee, rice, eggs, butter usually have; milk bought Saturday, limes Tuesday), Groceries empty, VoiceOver on, Porcelain.

### The Pantry front, top to bottom

| # | Action | Expected (focus order, one swipe right each) |
|---|---|---|
| K40.1 | Open Pantry from KITCHEN's index; swipe right from the first element, 14 times | 1 "Pantry", header. 2 "Friday". 3 "Since Saturday's shop". 4 "Out and low", button, hint "Opens the side". 5 hero "3 out, 3 low". 6 "Out", header. 7 to 9 "Milk, out" / "Eggs, out" / "Limes, out". 10 "Low", header. 11 to 13 "Rice, low" / "Lemons, low" / "Yogurt, low". 14 "Usually have", header. Then the usually-have names (K40.5), then Tess's line last. The ring, group labels' case and the ochre colour are not spoken; a group with no lines has no header (S8) |
| K40.2 | Read element 5, the hero | One element: "3 out, 3 low", digits, one stop. It is not a button. Quiet forms read "Nothing out" and "Nothing yet" as written; "Nothing yet" is followed by "Clear a shop or finish a cook and this fills in." as the second line of the same element (K26.8) |
| K40.3 | Focus "Milk, out"; read hint and actions; open the actions rotor | Label "Milk, out". Default action (double-tap): cycle. The hint names the next state in the cycle in, low, out, in: for an out line "Cycles to in", for a low line "Cycles to out". Custom actions in this order: "Add to Groceries", "Open Milk". Name and state word are one element, never two stops |
| K40.4 | Double-tap Milk's state ("out" to "in") | The receipt "Milk, in." is announced once, high priority; the line leaves (320 ms), focus lands on the next line in the group ("Eggs, out") or, if the group is gone, on the next header. The UNDO slot holds the receipt 10 s under VoiceOver; the hero reads "2 out, 3 low" with no count-up announcement. UNDO is reachable as the last stop before Tess's line, label "Undo", button, hint "Puts Milk back" |
| K40.5 | Swipe through USUALLY HAVE with 4 names, then with 6 | After the header, each named name is one button: label "Coffee", hint "Adds to Groceries", custom action "Skip until next gap". Then one static element "and 2 more" (digits; from four, two named and the count, S6). Names past the cap are not stops. A tap announces "Coffee, on Groceries." with UNDO 4 s extended to 10 s under VoiceOver |
| K40.6 | After the last stop, check Tess's line | The last element, not interactive: "Tacos took the cilantro and limes." (or `Say "out of milk" and I'll keep it.` on an empty Pantry). Spoken as is; cobalt is not mentioned. Nothing in 736 to 820 comes before the lines |
| K40.7 | Private line: an out ingredient with a walled name | "Private item, out" (K27.21). Default action cycle; custom action "Add to Groceries"; no "Open" action (nothing opens, S15). The real name is spoken nowhere, including hints and the custom-action list |

### The side: glance, then full

| # | Action | Expected |
|---|---|---|
| K40.8 | On the front, run the custom action "Out and low" (rotor Actions on element 4), then swipe right through the glance | The screen-changed sound; focus on 1 "Out and low", header. 2 "3 out". 3 "3 low". 4 "6 to buy". 5 "All of them", button, hint "Opens the full side". 6 Tess's line "You buy milk about every 7 days." (only after 3 buys; otherwise the glance has 5 stops and ends on the button). Zero facts are dropped, as drawn (K26.12: "0 low" is not a stop). The 30% front behind the glance is not a stop |
| K40.9 | Activate "All of them" | One `.selection`; screen-changed to the full side; focus on 1 "6 to buy", the context line. 2 "Pantry", button, hint "Back to the front". 3 "Out", header. 4 and 5 "Milk, out, bought Sat" and "Eggs, out, bought Sat". 6 "Limes, out, bought Tue". 7 "Low", header. 8 to 10 the low lines with their value. 11 "Add 6 to Groceries", button. 12 Tess's line, the same words as at the glance. Out lines before low lines. Lines are static text: the side has no state words and no cycle (sheet 78), so none has a button trait |
| K40.10 | On the full side, the value of an ingredient never bought | Spoken as the name and the state alone, "Rice, low", with no value (K27.2). Never "bought never" or "unknown" |
| K40.11 | Press the key "Add 6 to Groceries" | "Pantry, 6 added." announced once, high priority, UNDO held 10 s under VoiceOver (4 s for a new add otherwise); the key leaves the tree (K28.4, never "Add 0 to Groceries") and focus moves to Tess's line. The context line reads "6 to buy" still (adding does not change state) |
| K40.12 | Pantry with nothing out ("Nothing out.") | The full side has: 1 "Nothing out.", 2 "Pantry", button, then Tess's line. No key, no header for a group with no lines; the accessibility tree holds no "Add 0 to Groceries" (K26.4) |
| K40.13 | Escape gesture (two-finger Z) on the full side, then on the glance, then on the front | Full side to glance (focus on "All of them"), glance to front (focus on "Out and low", the word that opened it), front leaves the area back to the index (focus on the PANTRY row). Each stop is one escape; it never skips a stop. Matches SA-EX-15 |
| K40.14 | Swipe-based paths are VoiceOver-safe | Everything done by an edge or middle pan has a named action: on the front "Out and low" opens the side, on the glance "All of them" opens the full side, on the full side "Pantry" goes back. Nothing needs a pan. The left-edge swipe is not offered as an action |
| K40.15 | Reduce Motion on, Dynamic Type AX5, VoiceOver on; open the side | The reading order is the same as K40.8 and K40.9 at every size; Reduce Motion changes only the crossfade (150 ms), never the order. No stop is dropped when text wraps; the key stays the last stop before Tess's line |

### The other sheet 77 Kitchen sides

| # | Action | Expected |
|---|---|---|
| K40.16 | Groceries, side FOR WHAT with tacos (Sunday), chili (Tuesday), 3 plain rows and a USUALLY line | Order: "For what", header; "Tacos, Sunday" header; its rows (a row for two cooks reads once, "Sour cream, also chili"); "Chili, Tuesday" header and rows; "Just because" header and its 3 rows; "Usually" header with "Rice and butter" as one static line; "All links" button; Tess's line "7 for 2 cooks, 3 just because." Group headers carry the header trait; the comma in the group name is spoken as a pause, never "dot". Row-level actions stay: "Remove" (no swipe is needed) |
| K40.17 | Recipe original, side COOKS with 4 cooks | "Cooks", header; each cook newest first as one element, "Thursday, 46 minutes", with the serves when scaled ("Saturday, for 6, 6 hours 55 minutes" from 60 minutes is spoken in words, not "6 h 55 min"); "The whole story" button; Tess's line "Cooked 4 times, about 45 minutes." (spoken in words even though the line prints "min"). "Left open" cooks read "Wednesday, left open" |
| K40.18 | Paste screen, side WHAT I READ with 17 lines, 14 kept, 3 ignored (one private) | "What I read" header; 17 lines in their written order, each one element. A plain ignored line: its words then "ignored". A private or secret-looking line: **only** "Ignored line" (never its words, never the bar as a drawing). Counts line "14 of 17 lines kept." last; "All of it" button before it. A secret never reaches the label (SA test in `builder-briefs-77-78.md`) |
| K40.19 | Recipes class page, side ITS OBJECTS (38 recipes) | "Its objects", header; "Newest", header, 3 named, "and 35 more" as one static stop; "Most used", header, 3 named; "Fields every one has" header and its list; "All links" button; Tess's line "Chili is the one you cook most." A Private recipe reads "Private recipe" with nothing opening behind it (K32.3) |
| K40.20 | Every side above, the context line | Never more than 6 words (sheet 77 rule); spoken with the digit, "7 for 2 cooks", never as a symbol. Cobalt, rings, the bar and the faint front are never spoken |

---

## K41. Kitchen widget and Live Activity "Private recipe" masking on the lock screen

Ruled copy (Design, Oct 17; `kitchen-widget-wash-acceptance.md` KW-W8, `kitchen-refill5-acceptance.md` K32.5 to K32.8, K32.12, `kitchen-refill6-lane1-acceptance.md` K35.14): the only words are **"Private recipe, 7 pm."** (lowercase time, no "at"); with no time, "Private recipe, today." or "Private recipe, tonight."; a running cook reads "Private recipe" and the soonest timer's verb label, never the recipe name, an ingredient or a step's words. Decision 12:26 PM Oct 16: titles that trip the secret-word or money/body checks are hidden from Spotlight, Siri replies and the Live Activity; every free-text field on a widget gets `.privacySensitive`; Live Activity buttons stay usable on a locked phone. Code check on master: `Widgets/` holds only the rest Live Activity (`RestLiveActivity.swift`); no Kitchen widget and no cook Live Activity exists yet, so every row is a build target. This block adds the lock screen surfaces and the mid-cook change; it does not repeat K32.5 to K32.7 (home-screen widget copy, cache) or K35.14.

Setup: a recipe named in test code "Sunday secret stew" marked Private, planned for tonight, 7 pm; an ordinary "Tacos" planned for tomorrow, 7 pm; a locked iPhone 17 (iOS 27), Porcelain and Obsidian. The stew's name is never typed in expected copy; every row asserts its absence.

### Lock Screen widgets (accessory families) and StandBy

| # | Action | Expected |
|---|---|---|
| K41.1 | Add the Kitchen inline accessory widget to the Lock Screen with the private cook next | One line: "Private recipe, 7 pm." Ordinary next cook reads "Tacos, 7 pm." (with `.privacySensitive` on the title, so the system may redact an ordinary title while locked; the private string is fixed text and needs none) |
| K41.2 | Add the rectangular accessory widget; private cook next | The same string, "Private recipe, 7 pm.", wrapping at most to 2 lines, no second fact, no wash, no ingredient count, no "N to buy". Text at least 16 pt in the widget's own scale. Nothing else in the widget |
| K41.3 | Add the circular accessory widget; private cook next | No title and no initials; the time only ("7 pm") or the plain Kitchen mark. Its VoiceOver label is "Private recipe, 7 pm." (K41.12). It never shows a letter of the recipe's name |
| K41.4 | The private cook has a day but no time | "Private recipe, today." or "Private recipe, tonight." (KW-W8). Which of the two the day-part picks is not in the docs (flag F3); the row passes if the choice is stable and never shows the weekday word for a cook on this day |
| K41.5 | No planned cook | Inline and rectangular: "Nothing planned" (KW-W7, ruled), plain, no button, no wash. Never "Private recipe" when nothing is private |
| K41.6 | Lock the phone; wait for the widget timeline to reload; unlock; lock again | Identical words in every state, locked, unlocked, Always-On dimmed and StandBy. The mask is never tied to the lock state; it is tied to the recipe being Private. An ordinary recipe may redact while locked; the private one never shows more than the fixed string |
| K41.7 | StandBy (charging, landscape) with the medium widget, private cook next | The same fixed copy; plain ground, no wash, no pigment (KW-W8); Night mode (red tint) keeps the words readable. No photo ever, from the extension (KW-W12) |
| K41.8 | Tinted and clear Home Screen modes and the Smart Stack | Same words in every rendering mode and family (K32.5, K32.6). The Smart Stack's relevance may promote the widget at 6 pm; its title in the stack's header is "Kitchen", never the recipe |

### The cook Live Activity on the Lock Screen and in the Dynamic Island

| # | Action | Expected |
|---|---|---|
| K41.9 | Cook the private stew; start two timers; lock the phone | One cook Live Activity (K35.5). Its lead line is "Private recipe". The soonest timer is large and counts down on its own; the label is the verb ("Simmer", "Rice" as a step label, K35.14) and never the recipe name, an ingredient, a quantity or a sentence of the step. If a timer's label would hold words from the stew's title or steps, it falls back to "Timer". The context "Step 2 of 6" is allowed (a count, not a word of the recipe) |
| K41.10 | Dynamic Island, compact and minimal; expanded by long press | Compact: the Kitchen mark on the left, the soonest countdown on the right. Minimal: the mark. Expanded: "Private recipe", the soonest timer, "Stop" (K35.5). No name, no photo, no wash, no step text in any presentation (P12 of `recipe-plate-acceptance.md`: no Lock Screen or Live Activity carries a wash) |
| K41.11 | Make the stew Private **while** a cook is running (it was public) | Within one Live Activity update the Lock Screen lead line becomes "Private recipe"; the name is never shown after that update. The recipe's name must not live in the activity's static attributes: they cannot be changed after the request (flag F4). Test: after the change a dump of `ActivityAttributes` and `ContentState` holds no recipe name. Making it public again restores the name on the next update (K32.16); the photo does not return until a re-save |
| K41.12 | VoiceOver on the Lock Screen: swipe through the widget and the activity | Widget: "Private recipe, 7 pm." Activity: "Private recipe. Simmer, 8 minutes left." Durations in words ("8 minutes", "40 seconds"), the value updating once a minute, never each second (`voiceover-recipe-clock-lists.md` VO10). The Stop button: "Stop", hint "Ends the cook". No stop speaks the recipe's name |
| K41.13 | A timer ends while locked; the notification arrives | Per K35.6 and K35.14 the banner title is "Timer" and the body "Simmer is done."; the stew's name is absent from both, and the body reads "Timer is done." when the label would carry a word of the recipe or is empty or number-only (Design ruling for #940, Oct 17: the timer notification title is always "Timer"; the body is "<label> is done.", or "Timer is done." for a private, empty or number-only label, supersedes the verb-label title). The Activity flips to its Done face on its own; the Done face reads "Private recipe" and the verb, no name. No sound in quiet hours unless user-started (K35.10 to K35.12) |
| K41.14 | Tap Stop on the Lock Screen without unlocking | Per decision 12:26 the Live Activity buttons work locked: the timer stops, the Activity returns to the next timer or ends. No Face ID prompt, no app launch. The Activity still reads "Private recipe" afterward |
| K41.15 | Hold Finish on the last step in the app, then lock | The Activity ends at once (K35.16); nothing about the private cook stays on the Lock Screen: no "cooked" final state, no name, no "Private recipe" leftover. An ordinary cook ends the same way |
| K41.16 | Reboot the phone mid-cook (the activity is gone), then reopen Tessera | The cook resumes (K35.17 and `cook-mode-script.md` row 8); one Activity is restarted, still "Private recipe" and without the name. No duplicate activity |
| K41.17 | Dump the widget's timeline entries, the App Group container, the Live Activity's push payload or local state, the crash-free logs and the sent log after K41.1 to K41.15 | The stew's name, ingredients, steps, notes and photo appear nowhere; only the strings "Private recipe", the verb labels and times. This extends K32.7 to the activity and its payload. Claude is not involved (K32.15) |
| K41.18 | Control: the same flow with an ordinary recipe ("Tacos") | Lock Screen shows "Tacos, 7 pm." and the real title in the Activity (cook-mode-script row 5: "The Lock Screen shows Weeknight dal with the soonest timer"). A recipe whose title merely contains a word that trips the secret, money or body checks is masked exactly like a Private recipe (decision 12:26) |

---

## Assumptions and flags

- **F1. Who sees the failure line (ruled, decisions 3:00 Oct 17).** `job-trigger-table.md` wins over `groceries-ai-acceptance.md`: link asks fire only when he taps. Failures are silent on automatic triggers and spoken only on his tap: "Claude is busy. Kept it for later.", "Claude didn't answer in time. Kept it for later.", "Claude is off.", "No Claude key yet." and "Claude paused until Nov 1."
- **F2. No daily cap on grocery asks (ruled, decisions 3:00 Oct 17).** The limits are the $50/month in-app cap (hard stop, resets on the 1st) and the $40 step-aside rule. The 40-a-day limit belongs to Home lines only (1 call per 10 minutes, 40 a day, docs only); asking Claude about a subject is 20 a day; `linkItems` has no day limit (about 60 calls a month). K39.8 and K39.9 fix that. "Claude paused until tomorrow." (K39.10) is used only if a per-day cap pauses a job.
- **F3. "today" versus "tonight".** The docs give both words for a private cook with no time (KW-W8) but no rule for choosing; K41.4 asks only for a stable choice. Needs a Design line (for example "tonight" from 5 pm).
- **F4. Live Activity attributes are static.** To mask a recipe made Private mid-cook (K41.11), the title cannot sit in `ActivityAttributes`; it must be in `ContentState` (or the activity must be ended and restarted). Builder A to confirm when the cook Live Activity is built; `Widgets/` has only the rest activity today.
- **F5. Ruled (decisions 3:00 Oct 17).** "Nothing planned" (KW-W7) and the circular widget's time-only face (K41.3) are accepted and have no code to match yet. The VoiceOver stops in K40 (the order of the side word, hero and context on the front; "Out and low" as the front's custom action; the hint wording "Cycles to low", "Cycles to out", "Cycles to in") are accepted, in the voice of S16 and `voiceover-recipe-clock-lists.md`; `pantry-acceptance.md` S16 marks its own wording "proposed"; this file's wording is ruled. Reading order on the front follows the drawing top to bottom, with the side word after the context line it sits beside, so the hero is the fifth stop.
- **F6. Not built.** Master has no Pantry, Lists, Kitchen widget or cook Live Activity code (`Features/` holds Groceries and Recipes only); K40 and K41 are build targets for Builder B (Pantry, Kitchen) and Builder A (timers, Live Activity). K39 runs on the stub model once AI-12 lands (D5 in `groceries-ai-runnable-rows.md`).
- **F7. Receipts and dates.** House date for the cap is the 4 AM day; "Nov 1" is the first of next month from Oct 17, 2026. The sent-log rows hold times and counts only; no row here puts an amount in any log or request.

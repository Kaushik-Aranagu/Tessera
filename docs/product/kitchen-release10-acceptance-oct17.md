# Kitchen acceptance of release 10 (f8bb516e): static read

Read-only, from `git show` and `git diff` against f8bb516e. Docs are the copies in /mnt/project-files/tessera/product/. Nothing was run, so no row here is a phone result.

## Relationship

- `git merge-base --is-ancestor e149e66 f8bb516e` exits 0: release 8 (e149e66) is an ancestor of release 10 (f8bb516e). A straight forward update, no divergence. 60 commits between them, 37 Swift files changed.
- Almost all of that diff is Home, Training and rest-weekday work, walls and Claude-call hardening. Kitchen code is small.

## What changed (Kitchen only, e149e66 to f8bb516e)

| # | Change | Where (at f8bb516e) |
|---|---|---|
| K-a | A list add now speaks the thing first, but with "added to": summary and plain receipt read "Rice, added to Packing"; the private branch still reads "Private item, on Packing" | `TesseraCore/Sources/TesseraCore/Lists/Lists.swift:168-185` (PR #638; only the summary at :170-174 is new in this range, the receipt at :185 was already "added to") |
| K-b | The recipe-link Claude call refuses every redirect (shared `NoRedirects` delegate); the page download keeps its own `RedirectGuard` | `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift:401`, `NoRedirects.swift:6-13`, guard at `RecipeLinkReader.swift:441-460`; test `RecipeLinkTests.swift` `claudesRedirectIsNeverFollowed` |
| K-c | Typed "rest day Sunday" is a setting, ahead of every task and grocery rule, so it can never become a grocery or task | `TessGrammar.swift:88-90`, `TessCaptureEngine.swift:236-241`; `KitchenHotfixTests.swift:203` only adds the case to the trace switch |
| K-d | Home done pack and line check (C1 to C15) read cook items ("steps" is a cook's own word, C12) | `Home/HomeDonePack.swift:69`, `Home/TessLineCheck.swift:244-246` |
| K-e | Wall change: a medicine is a private task with or without a time; the Lists wall (`AddListItem.kept`) is untouched | `Tess/EngineWall.swift:58-61` |
| none | No change to `Features/Kitchen`, `Features/Groceries`, `Features/Recipes`, `Features/Lists` (none exist for Lists), `Kitchen/*.swift`, `Cooking.swift`, or Home kitchen lines (`HomeLines.swift` untouched). Pantry, parallel steps, the food table and cook slices 12/12b have no code at f8bb516e (only docs). | `git diff --stat e149e66 f8bb516e -- Features` shows only `Features/Home/ReviewWeek.swift` |

## Rows

Result is judged on the code at f8bb516e. FAIL means the code contradicts the ruled copy or behaviour; NOT BUILT means the code for it does not exist.

| Row | What it needs | Result | Evidence |
|---|---|---|---|
| lists-acceptance 13.8 (add receipt) | "Private item, on <list>." when a private item lands | PASS | `Lists.swift:183` |
| lists-acceptance 13.8 (summary, Siri) | Same words in the summary Siri reads | FAIL | `Lists.swift:174` returns "Private item, added to <list>" for a private item; the receipt says "on" and the summary says "added to" |
| lists-screens G6 / 10.8, lists-acceptance copy ruling (line 121) | A plain add reads "Rice, on Packing." | FAIL | `Lists.swift:185` still returns "Rice, added to Packing"; the 10:06 ruling in decisions and the Lists docs say "on". Release 10 adds a second "added to" line at `:174` |
| kitchen-misfire-rows line 79 | Says a list receipt is "<Thing>, added to <List>" | Docs disagree | Contradicts lists-acceptance 13.8 and lists-screens G6 (both "on"). The code matches this one doc and fails the other two; Product needs to pick one (lists-copy-sweep-oct17 asked the same) |
| kitchen-misfire-rows C13, C14 (Private item on Errands / Packing) | Private line shows "Private item, on <list>." and no number appears | PASS (receipt only) | `Lists.swift:63-64` mask, `:183`; wall `kept` at `:115-123` unchanged. Number never in text: not checked past the receipt |
| kitchen-misfire-rows C1, groceries-side GS7 (Tess typed add) | "Milk, on Groceries." from a typed add | FAIL | `TessCaptureEngine.swift:369` says "Milk, on the list." and "3 things on the list."; the "already" path at `:248` and `:367` is right. The engine's own `AddGroceries.receipt` is right (`Groceries.swift:442`) but the typed path does not use it. Not changed in this range |
| lists-acceptance 13.6 / 13.8 (remove, "Rice, removed.", UNDO 10 s, "back on") | Remove with UNDO | NOT BUILT | No remove action in `Lists.swift` or `GroceriesView.swift`; unchanged since release 8 |
| decisions 9:53 pm (2), key handling | Every Claude call refuses redirects, a 301 test each | PASS for the recipe reader | `RecipeLinkReader.swift:401` passes `NoRedirects.shared`; test builds a 301 from the API host and expects no second request. Same delegate on `ClaudeKey.swift:302`, `ClaudeTessModel.swift:231`, `PlanWording.swift:605` |
| kitchen-error-states ER2, kitchen-refill5 K33.5 (too big or odd) | Page link refused over 5 redirects, non-https, private host | PASS | `RedirectGuard` allows 5 hops, https and safe host only (`RecipeLinkReader.swift:450-460`); failing line `RecipeLinkLine.tooBig` at `:211` |
| recipe-plate P18, kitchen-refill5 K33.2 | Link guard allows at most 3 redirects | FAIL (docs conflict) | Code allows 5. ER2 and kitchen-v2-backlog say 5; P18 and K33.2 say 3. The guard is shared, so one number is stale in the docs |
| kitchen-misfire-rows part A (kitchen phrases stay kitchen) vs "rest day Sunday" | New rule must not catch kitchen phrases | PASS by read | `TessGrammar.swift:88` runs first but matches only the rest-weekday form (`TessGrammar+RestDay.swift`); not a grocery or timer phrase. No kitchen trace test was added; the KitchenHotfixTests trace maps it to "nothing" |
| cook-mode, pantry-acceptance, parallel-steps, kitchen-v2, recipe-plate P1 to P17, recipe-clock-dst, week-leaves, food-table, overnight O1 to O4, US shop | Whole new screens and engines | NOT BUILT | No Pantry, parallel-step, USDA-table or plate code in `git ls-tree f8bb516e`; docs only. Same state as release 8 |
| meal-plan-groceries, groceries-ai (AI-12) | Meal plan feeding Groceries; Groceries that know recipes | PASS unchanged (meal plan) / NOT BUILT (AI-12) | `Groceries.swift` untouched in this range |

## Copy rules check on the touched Kitchen code

- Receipts name the thing first in every changed line. The "on" form is missing in `Lists.swift:174` and `:185` (FAIL above) and `TessCaptureEngine.swift:369`.
- No "at" before a clock, no uppercase "AM/PM", no "record" and no standalone "pin" in the changed Kitchen lines. No key-shaped string in the Kitchen diff (the redirect test builds its host from parts).

## Phone only

| Check | How |
|---|---|
| Typed "milk" on Tess reads "Milk, on Groceries." | Type "milk" in the Bar on a clean list and read the line (static read says it prints "on the list.") |
| A list add by Siri reads "Rice, on Packing." | Say "add rice to packing" and listen; compare the spoken line with the written one |
| Private item receipt and VoiceOver | Add "ibuprofen" to Errands with VoiceOver on; it must read "Private item" only |
| UNDO windows (4 s add, 10 s remove) | Time the UNDO bar with a stopwatch on screen recording |
| Haptics on check, UNDO and cook steps | Hold the phone, run each, note the tap strength and that Reduce Motion drops motion but not the tap |
| Dynamic Type AX3 on Groceries, Lists, Recipe page | Settings, Accessibility, Larger Text to the top; screenshot each, look for clipping under 44 pt rows |
| Recipe link behind a redirect | Paste a short link that redirects (https to https) and expect it to read; a link that bounces to http must give "That page is too big or odd to read safely. Paste the text instead." |
| Claude-read link on a bad redirect | Needs a test host; cannot be made on the phone alone, covered by the stub test only |
| Cook timers and overnight finish time on 8:30 pm style lines | Start a cook, read the finish line, check clocks are lowercase and have no "at" |
| First launch writes Sunday as rest day, Kitchen unaffected | Fresh install, open Groceries and Recipes, confirm nothing else changed |
| Recordings (kitchen walk) | Screen-record Groceries, Paste, Recipe page, Lists on the phone and attach |

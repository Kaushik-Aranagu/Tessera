# Kitchen first-use empty states: one per screen, as a new user

*Kitchen lead, board K70, 2026-10-17. Docs only, no code. For each Kitchen screen, what a user with no Kitchen data sees on first open: the exact words, the one action, and how it reads aloud and at the largest type. Standing principle: no stock screens, no cards, no illustrations of emptiness, no "Get started" button, no "No items" label, no count of zero. An empty screen is the screen with the words it will later have, said quietly, plus one line from Tess in her cobalt that shows the one thing to do. This file extends, and does not replace, K26 (Pantry), K30 (Recipes), K31 (Lists), K38 (Week), KW-W7 (widget) and the Home rows; where those already hold the exact words they are cited, not rewritten.*

**Status key.** **Master** = the words are in the app today (file and line cited, read not run). **Build target** = the words are ruled in an acceptance file or proposed here, and no code draws them yet. **Proposed** = the words are mine, Product to rule.

**House rules.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks lowercase. Digits for counts, and a zero count is never written. US English. "Private item", "Private recipe", "Private note". Link and reader asks fire only on his tap. Nutrition is never summed. No daily cap on grocery asks. Animate only through `MotionPolicy`; Reduce Motion turns every entrance into a 150 ms crossfade. Tess speaks in cobalt and only in her band; she says nothing unprompted except the one first-use line below, and each first-use line is said once per screen, per install, then stays quiet (it is not repeated on later empty opens). No row, fixture or log holds a key or key-shaped text.

**What every empty state shares.**

- The screen frame is the same one it will have when full. Titles, back word and the aisle window sit at the same coordinates (K38.21); filling the screen moves nothing.
- The first-use line is a sentence he could say out loud to Tess. It teaches a phrase, not a button.
- One action. If a second way exists it lives in the footer link line (small ink words with a dot between), never as a second button.
- Nothing red, amber or ochre. Nothing pulses or bounces. No arrow points at anything.
- VoiceOver reads the title, then the quiet line, then Tess's line as its own stop; no stop for a decorative layer. The back stop is first (`voiceover-recipe-clock-lists.md`).
- Dynamic Type through AX5: one column, every line wraps in full, Tess's line at most 3 lines (K31.5), tap targets at least 44 pt.

---

## 1. Recipes (the shelf)

| | |
|---|---|
| **Status** | **Build target.** K30.1 holds the words; a search of `Features/Recipes/` (`RecipesEntry.swift`, `RecipePage.swift`) finds no "No recipes yet." The Home Kitchen page already links to Recipes and "Paste a recipe" (`HomeSpatialView.swift:362-383`, master). |
| **Words** | Context line "None yet". Row area, one line at 66% ink: "No recipes yet." Tess: "Paste a link or a page and I'll read it." |
| **The one action** | Paste. The footer link line carries "Paste a recipe" (the Home word, same destination). The Tess line is also the key: tapping it opens the paste screen (Tess's line is a plain text button, no fill). |
| **Not there** | No plate, no wash, no placeholder icon, no "add a photo", no count, no "Get started". |
| **VoiceOver** | "Recipes. None yet. No recipes yet. Paste a link or a page and I'll read it." The Tess line is a button with hint "Opens Paste a recipe". |
| **Dynamic Type** | AX5: the four lines stack in the frame order; "None yet" never truncates; the footer link line wraps below the Tess line. |
| **After one action** | Pasting a recipe (receipt "Tacos, on Recipes.") replaces the row area with the one row; Tess's first-use line goes and stays gone. |

## 2. Groceries

| | |
|---|---|
| **Status** | **Master** (`Features/Groceries/GroceriesView.swift:658-669`, `GroceriesEmpty`), with one wording question. |
| **Words on master** | Title line "Nothing to get." (Title role, ink; "All in the basket." when the basket holds rows). Tess line: "Tell me “milk, eggs”, or swipe a recipe's ingredients here." The Add line is open below with the prompt "eggs, milk, 2 lemons" (`GroceriesView.swift:365`). |
| **The one action** | Type or say a row. The Add line takes the focus on first open, no keyboard trap (it closes with the swipe down). Receipt after the first row: "Milk, on Groceries." with UNDO 4 s. |
| **Wording question (proposed, Product to rule)** | A new user has no recipe, so "swipe a recipe's ingredients here" points at something that is not there. Default taken: until the first recipe exists the Tess line reads "Tell me “milk, eggs” and I'll keep the list." and the swipe half returns when Recipes has one. |
| **Not there** | No "0 to get", no empty-cart picture, no "Add" button as a second action (the Add word on the line is the same action as the field). |
| **VoiceOver** | "Groceries. Nothing to get. Tell me milk, eggs and I'll keep the list." The Add field has the label "Add to Groceries" and the prompt read as its placeholder. The curly quotes are not read as "quote". |
| **Dynamic Type** | AX5: the Title wraps to 2 lines; the Add line grows with the text and stays above the keyboard. |

## 3. Pantry

| | |
|---|---|
| **Status** | **Build target.** There is no Pantry code on master. Words are ruled in K26.1 to K26.8. |
| **Words** | Hero "Nothing yet" (never "0 out, 0 low", "Empty" or "No items"). Context line empty (no shop yet, so no "since Saturday's shop"). The side word OUT AND LOW is in place. Tess: `Say "out of milk" and I'll keep it.` The index row and Home's Pantry line read "Nothing yet" too, so none disagree (K26.3). |
| **The one action** | Say or type "out of milk" to Tess. One op: milk becomes out and "Milk" lands on Groceries ("Milk, on Groceries."); the hero changes in place to "1 out" (K26.6), 150 ms crossfade under Reduce Motion. |
| **Side** | Opening OUT AND LOW on the empty page reads "Nothing known yet." (K26.4); no key is drawn. A known-but-none state is a different line, "Nothing out." (K26.9). |
| **VoiceOver** | "Pantry. Nothing yet. Clear a shop or finish a cook and this fills in." (K26.8). Tess's line is a second stop. |
| **Dynamic Type** | AX5: "Nothing yet" wraps; nothing clips (K26.8). |

## 4. Lists

| | |
|---|---|
| **Status** | **Build target.** Master has the list engine (`TesseraCore/.../Lists/Lists.swift`) and Groceries, and no Lists shelf screen. Words are ruled in K31.1 and K31.2. |
| **Words** | Context "Just Groceries". Groceries at hero size with its state word "NOTHING TO GET" (the Groceries empty state, section 2). One quiet line: "No other lists yet." Tess: `Say "new list: packing" and I'll start it.` The side opens on "Nothing else to show yet." (K31.2); the left edge returns. |
| **The one action** | Say "new list: packing". The receipt names the thing first: "Packing, on Lists." with UNDO 10 s (proposed, Product to rule; the receipt on Lists is not in K31). |
| **Not there** | No dotted outline, no illustration, no count, no button (K31.1). |
| **VoiceOver** | "Lists. Just Groceries. Groceries, nothing to get. No other lists yet. Say new list packing and I'll start it." |
| **Dynamic Type** | AX5: Groceries' state word wraps under its title; the quiet line and Tess's stay in order. |

## 5. Week and Plan (the meal week)

| | |
|---|---|
| **Status** | **Build target.** The Kitchen week side is not on master (`Features/Plans/WeekPage.swift` is the training week). Words are ruled in K38.1 to K38.5. |
| **Words** | Week side: "Nothing planned." as one quiet line at 66% ink. No "Plan a meal" button. The Kitchen front shows the usual shelf and Groceries; Tess says nothing unprompted (K38.1). Siri: "Nothing planned." (K38.5). |
| **The one action** | Say "cook chili thursday" to Tess, or the PLAN THURSDAY word on a recipe (K38.2). The receipt is "Chili, 7 added." with UNDO 10 s when the recipe adds rows (K38.6), or "Chili, nothing to add." with no UNDO. |
| **Count line** | With nothing planned the Groceries count line has no "for ..." clause ("5 to get", K38.3). |
| **VoiceOver** | "The week. Nothing planned." The week side is reached by the same swipe as every side; the left edge steps back. |
| **Dynamic Type** | AX5: the line wraps; days stack one per line when planned. |

## 6. Cook mode

| | |
|---|---|
| **Status** | **Master** for the engine (`Kitchen/Cooking.swift`: step, timers, finish line), **build target** for the first-cook coaching line and the no-steps state. |
| **Words (first cook ever)** | The step view is the screen. No coaching card, no spotlight, no "Swipe to continue" overlay. Tess, once, after the first step is shown, in her band: `Say "timer 8 minutes" and I'll keep it.` (proposed, Product to rule). It goes when the first timer is made or the cook ends, and is never repeated. |
| **No timers** | The timer line under the key row is not drawn when no timer runs (W7). No "0 timers". |
| **A recipe with no steps** | The cook key is not drawn and no empty step view opens. On the recipe page, one quiet line under the ingredients: "No steps yet. Paste them below." (proposed, Product to rule; matches the paste family "Paste the text instead."). |
| **The one action** | Move to the next step by the key or by saying "next". Finish by holding DONE; the finish line for the first cook is "Tacos, first time this month." (`Cooking.swift:63-67`) and the receipt "Tacos, cooked." |
| **VoiceOver** | Step "Step 1 of 6" then the step's words, then "Next", a button. A timer, when it exists, reads "Rice, 8 minutes." (durations in words). Tess's first-cook line is her own stop after the step. |
| **Dynamic Type** | AX5: the step words wrap in full at the largest size; the key stays at least 44 pt tall and never scrolls away. |

## 7. Kitchen widget

| | |
|---|---|
| **Status** | **Build target.** `Widgets/` holds only the rest Live Activity. Words are ruled in KW-W7 and K38.4. |
| **Words** | Medium widget, empty: plain ground, no wash, one quiet line "Nothing planned". No button, no drawing of emptiness. Not "Add a meal". |
| **The one action** | None on the widget. Tapping anywhere opens Kitchen (the widget's only tap). Planning happens by phrase or on the recipe. |
| **Private** | A planned private cook reads "Private recipe, 7 pm." (KW-W8). The empty line never changes because something private is planned. |
| **VoiceOver** | "Kitchen. Nothing planned." One element. |
| **Dynamic Type** | The widget caps at its own system size; the line wraps to 2 lines on the small family. |
| **Install (proposed)** | The widget appears in the gallery with the same line as a preview, so a new user sees the true empty state before adding it. |

## 8. Home Kitchen lines (Home, the Kitchen page and the day lines)

| | |
|---|---|
| **Status** | **Master** for the Kitchen page (`Features/Home/HomeSpatialView.swift:362-383`); **build target** for cook lines on Home (G19). |
| **Words** | Kitchen page: "What we eat, and what we need." then the words Groceries, Recipes and, in the footer line, "Paste a recipe". No count, no "0 to buy", no "Nothing yet". With nothing planned, running or finished, **Home's day shows no Kitchen line at all** (K38.1). |
| **The one action** | Open Groceries (the first word). A new user's likeliest first act is a row, and Groceries is the screen that takes it at once. |
| **Not there** | No Kitchen tile on the day page, no "Plan dinner" prompt, no count of recipes. A Kitchen line appears only after a cook is planned, running or done: "Tacos tonight, 2 to buy." / "Tacos, on step 2." / "Tacos done." (`HomeLines.swift`; G19 for the call). |
| **VoiceOver** | "What we eat, and what we need. Groceries, button. Recipes, button. Paste a recipe, button." |
| **Dynamic Type** | AX5: the three words stay as large type; the footer link line wraps. |

## 9. Settings, the Claude section

| | |
|---|---|
| **Status** | **Master** (`Features/Settings/ClaudeSection.swift:131-156`, `noKey`; receipts at `:472`). |
| **Words on master** | With no key and no past calls: "Tess thinks **on this phone** only." then the word "Add a Claude key". After a reinstall (past calls exist): "No Claude key on this phone. Paste one here." Receipts, empty: "Nothing has gone to Claude yet." |
| **The one action** | Add a key. The word opens a single line prompt "Paste a key from the Claude Console". Nothing Kitchen-specific is asked, and no Kitchen job runs before he adds one. |
| **Kitchen wording (proposed, Product to rule)** | Under "Tess thinks on this phone only.", one quiet line for a user with Kitchen data: "Recipe links and grocery matches stay on this phone." It is shown while no key exists and goes the moment a key is added. With a key, the section's own words stay as they are, and the receipts name the job (gap hunt 5, G31). |
| **Not there** | No "Connect to Claude" call to action, no "recommended", no spend meter before a key, no `$` figure before a call. |
| **VoiceOver** | "Claude. Tess thinks on this phone only. Add a Claude key, button." The receipts empty line is read as written. |
| **Dynamic Type** | AX5: the sentence wraps; "Add a Claude key" is at least 44 pt tall (it is, `frame(minHeight: 44)`). |

---

## What is on master and what is not

| Screen | On master | Build target |
|---|---|---|
| 1 Recipes | Home links only | Empty shelf words (K30.1) |
| 2 Groceries | Yes, with a wording question | The no-recipe Tess line (proposed) |
| 3 Pantry | No | Whole screen (K26) |
| 4 Lists | Engine and Groceries only | Shelf and its empty state (K31) |
| 5 Week and Plan | Training week only | Kitchen week side (K38) |
| 6 Cook mode | Engine | First-cook line, no-steps state (proposed) |
| 7 Widget | No | Whole widget (KW) |
| 8 Home Kitchen lines | Kitchen page | Cook lines (G19, G20) |
| 9 Settings, Claude | Yes | Kitchen sentence (proposed) |

## Notes for Product and Builder

1. **Only 2 of the 9 are on master and correct** (Groceries and the Settings section); Recipes is the one most users meet first, so its empty state (section 1) is the first build.
2. **New copy in this file, all proposed**: "Tell me “milk, eggs” and I'll keep the list."; "Packing, on Lists."; `Say "timer 8 minutes" and I'll keep it.`; "No steps yet. Paste them below."; "Recipe links and grocery matches stay on this phone.". Everything else is cited from a ruled row.
3. **Oct 17 (decisions 3:55): no Kitchen switch exists in Settings** (gap hunt 5, G30 is a non-goal), so no first-use line here depends on one. The Kitchen wording line in section 9 stays proposed.
4. **First-use lines run once.** The rule "once per screen, per install" needs one flag per screen, kept in the settings object so a restore does not teach a new phone the same lesson twice. Product to say whether a restore resets them (default taken: it does not).
5. **No card, no coach mark, no illustration anywhere.** If a screen needs more than one quiet line and one Tess line to explain itself, the screen's own words are wrong.

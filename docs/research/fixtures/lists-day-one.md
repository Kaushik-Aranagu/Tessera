# Lists day one: what Kaushik meets the first day (screens 9 to 12)

For: Builder B (screens), Core (engine and grammar), Kitchen lead, Product
Research item R, 2026-10-16. Master read at `origin/master` 68c9a19 (Merge #471), read only, nothing run.
Sources: Design's `docs/design/kitchen/lists-9-12.md` at c4b019f (it is only on the Design branch `claude/project-thread-b3tu3f`, not on master; there is no `docs/design/lists-9-12.md` anywhere), `docs/product/lists-screens-acceptance.md`, `lists-acceptance.md`, `starter-lists.md`, `ship-list-lists.md`, `docs/research/lists-copy.md`, and `docs/ops/board/ios-b.md:33` (the 9 to 12 refresh).

**What master has.** No `Features/Lists/` folder. The engine is Lists slice 0 only: `ListContents` plus `CreateList`, `AddListItem`, `CheckListItem`, `MoveListItem`, `RenameListSection`, `ClearDoneItems` (`TesseraCore/Sources/TesseraCore/Lists/Lists.swift`). The `List` class has no fields at all (`Catalog/SystemCatalog.swift:268`), so there is nothing to store reusable, put away, pick one, a note or a date. Grammar knows "list: X" / "new list X" and the Groceries phrases; the model route has `addToList` and `createList` tools.

**The day.** Friday Oct 16. He opens Kitchen at 8:10 am, makes Films by phrase, a Lisbon list for the Oct 26 trip by copying Packing, packs some, runs the gym bag at 5:30 pm and says "done", then tidies. Verdicts: **pass** (master does what the sheet says), **wrong** (master does something else), **miss** (the sheet or acceptance is silent or contradicts itself), **not built**.

| id | He does | Sheet / acceptance expects | Master's code | Verdict |
|---|---|---|---|---|
| R1 | First launch | Gym bag, Leaving the house, Packing installed once, reusable, never reinstalled once deleted (starter-lists.md) | `StarterContent.swift:3-4,67` installs the gym kit and the plan only | not built (Core) |
| R2 | Reads the starter Packing | US words throughout | starter-lists.md:44 "adaptor", also "trousers", "jumper" | wrong (Kitchen lead): "adapter", "pants", "sweater" |
| R3 | Opens Home's Kitchen page | "Lists" at Title 34 under Groceries, Recipes down one (G1, 9.7) | `HomeSpatialView.swift:328` has no `.lists`; `KitchenPage` shows Groceries and Recipes only (`:366`) | not built (B) |
| R4 | Types "lists" in the ghost row | Opens the shelf (G1) | No rule; undated, so `parseTask` returns nil (`TessGrammar.swift:141,537`) and it goes to the model | not built (Core) |
| R5 | Shelf arrives | "‹ KITCHEN", LISTS, context line, names settle with a 25 ms stagger (9.1, 9.4) | No shelf view | not built (B) |
| R6 | Reads the context line | Sheet's example "6 lists, packing running"; day one has Groceries plus 3 starters | No day-one form given | miss: "4 lists" with nothing running? |
| R7 | Reads the order and sizes | Last touched, newest at 56 (9.2) | `ListContents.lists()` sorts oldest first by `createdAt` (`Lists.swift:26-30`); no touched date | wrong (Core) |
| R8 | Reads state words | "REUSABLE" under each starter, "14 TO BUY" under Groceries, at most two words (9.3, copy D6) | No `progress(of:)`, no reusable flag | not built (Core, then B) |
| R9 | Taps Groceries on the shelf | Appears once, opens `GroceriesView()` (9.6) | Groceries is a `List`, so `lists()` returns it with the others; the view exists | pass for the engine, screen not built |
| R10 | Looks for "Put away" at the foot | Absent until something is put away (10.12) | Nothing to put away yet | not built (B) |
| R11 | 8:14 am, says "new list films" | Ghost row makes Films, UNDO 4 s; copy S1 wants "Films, new list." | `TessGrammar+Kitchen.swift:24-27` reads it; line "New list: Films." (`TessCaptureEngine.swift:355`); undo 4 s (`AppModel.swift:276`) | wrong (Core, copy only) |
| R12 | Opens Films, empty | Hero "Films", context "nothing on it yet", empty window, EMPTY on the shelf (addendum, 10.12) | No list page | not built (B) |
| R13 | Types "dune, heat, alien" on the Films page | "3 things, added to Films." UNDO 4 s (G6, 10.8) | No page context: the comma rule tries Groceries (`TessGrammar+Kitchen.swift:68-74`), else the model | not built (Core) |
| R14 | Pastes a 12-line block on the shelf | Ghost list "12 THINGS · 2 SECTIONS", "Twelve things, two sections." (9.5) | No paste parser or `AddListItems`; a block without an Ingredients heading has no rule (`TessGrammar+Kitchen.swift:10-15`) | not built (Core) |
| R15 | Makes "Lisbon" by hand: "copy packing for lisbon" | `CopyList` makes "Packing, Lisbon", all open (starter-lists.md, slice 4) | No `CopyList`; the phrase becomes a model guess | not built (Core) |
| R16 | Wants the list tied to Oct 26 | Nothing gives a list a date; only items get one (slice 2) | `List Item` has no `date` or `note` field (`SystemCatalog.swift:269-278`) | miss (Product) |
| R17 | Says "add charger to packing" (row 42) | Adds to Packing; receipt "Charger, added to Packing." | Kitchen rule matches only Groceries targets (`TessGrammar+Kitchen.swift:43-44`); model `addToList` (`TessTools.swift:159-165`); engine line "Added charger" (`Lists.swift:143`) | wrong (Core) |
| R18 | Says "packing: charger, socks" (row 41) | Two items on Packing | QA's trace reads it as groceries "packing: charger", "socks" (`docs/qa/grammar-trace.md:19`) | wrong (Core) |
| R19 | On the Packing page, says "buy plasters" | Goes to Groceries and Tess names it: "Plasters, on Groceries." (G7, copy D10) | `TessCaptureEngine.swift:337` says "Plasters, on the list." | wrong (Core) |
| R20 | Says "add charger to holiday" | "No list called holiday." and no list made (slice 8) | `TessTools.swift:290` throws "no list called holiday" to the model; what he sees depends on the model | wrong (Core) |
| R21 | Taps "passport" on Lisbon | Strikes and sinks; fold "1 done"; silent | `CheckListItem` works (`Lists.swift:167-173`); its summary "Got passport" (`:177`) shows wherever summaries do | wrong copy (Core); screen not built (B) |
| R22 | Opens "phone charger" | Zoom, "‹ PACKING", "Add a note", "Add a day" (11.1 to 11.3) | No item page; no note or date fields | not built (Core slice 2, then B) |
| R23 | Removes "tickets" with a left swipe | "Tickets, removed." UNDO 10 s (10.9) | No `removeListItem` | not built (Core, then B) |
| R24 | 5:30 pm, "run gym bag" | Page opens running, seam, Now "Gym bag, 10 left" (10.7) | Only `StartShop` for Groceries (`TessGrammar+Kitchen.swift:28-31`); no `StartListRun` | not built (Core) |
| R25 | Says "done" on Gym bag | Run ends, strikes stay, "Gym bag, done. Reset it for next time?" RESET (0.7 s hold) or NOT NOW (10.11) | "done" only means something while cooking or shopping (`TessGrammar.swift:232,248`); elsewhere it goes to the model | not built (Core, then B) |
| R26 | Holds RESET | Paint drains, "Gym bag, reset." UNDO 10 s, context "10 to pack" | No reset op. The only clear is `ClearDoneItems`, which deletes checked items (`Lists.swift:268-272`), so wiring the fold to it on a reusable list loses them | not built; risk (Core) |
| R27 | Taps NOT NOW, or waits 10 s | Line goes, nothing changes, fold still "10 done. Hold to reset." | n/a | not built (B) |
| R28 | Holds the fold on Films (plain list) | Clears done, a line, UNDO 10 s | `ClearDoneItems` with undo; summary "Cleared Films" (`Lists.swift:280`); Groceries says "Cleared 3 from the basket." (`GroceriesView.swift:260`) | engine pass, copy miss (no line given for a plain list) |
| R29 | Finishes Lisbon early (last item struck) | Zooms to the shelf, "Packing, Lisbon put away." UNDO 10 s (G9) | No put-away field or op | not built (Core) |
| R30 | Puts Films away from the option words | The word is "Put away", never "Archive" | No option words; `ship-list-lists.md:32,34` still says "Archived" and "Archive" | not built; stale doc (Kitchen lead) |
| R31 | Undo windows | 4 s for a capture, 10 s for a remove or a change | Capture 4 s (`AppModel.swift:276`); `say(_:undo:)` keeps 10 s when it has an undo (`HomeQueue.swift:34`) | pass (infrastructure ready) |
| R32 | Deletes all 3 starters, then Films | Shelf: Groceries at 56, "Paste a list anywhere to make one.", no Put away (addendum) | No shelf; starters must stay deleted (R1) | not built (B) |
| R33 | Back from the shelf | Source string "‹ Kitchen" with the label role and uppercase text case, so it renders "‹ KITCHEN" like `RoutinesPage.swift:34`; accessibility label "Back to Kitchen" (Design, 12:27 pm) | No shelf yet | not built (B) |
| R34 | Asks "what should I watch" | Grammar writes nothing (row 48) | Question guard declines (`TessGrammar.swift:82`) | pass |

**Counts (34 steps):** 3 pass (R9 engine side, R31, R34), 8 wrong (R2, R7, R11, R17 to R21), 3 miss (R6, R16, R28), 20 not built.

## Top gaps
1. **The `List` class has no fields** (`SystemCatalog.swift:268`): reusable, put away, last touched, run state and `pickedAt` all need a home before any of screens 9, 10 or 12 can show a state word. Core, Lists slices 1, 4, 5, 7.
2. **Reset must not reuse `ClearDoneItems`** (`Lists.swift:256-277` deletes). RESET and the fold's hold on a reusable list need an "uncheck all" op with one undo. Core, slice 4; Builder B must not wire the fold before it lands.
3. **Starter lists are not installed** (`StarterContent.swift:67`), so day one is the empty shelf, not the three reusable lists the screens were drawn for; and their words are British (`starter-lists.md:44`). Core, plus the Kitchen lead for the words.
4. **List phrases miss** (rows 41, 42, "run X", "done", "lists"): `TessGrammar+Kitchen.swift:24-74` only knows Groceries targets and "list:"; "packing: charger, socks" lands in Groceries. Core, slice 8.
5. **Receipts are verb first** (`Lists.swift:93,143,177,219,251,280`; `TessCaptureEngine.swift:337,355`). Core, copy rows S1 to S8.
6. **No door and no folder**: `HomeLink` has no `.lists` (`HomeSpatialView.swift:328`); `Features/Lists/` does not exist. Builder B, after Core's slices 1 and 3.
7. **Design's sheet is not on master** (c4b019f lives only on `claude/project-thread-b3tu3f`), while `ios-b.md:91` and the acceptance file point Builder B at it. Design, to merge.

## Questions for Product
1. Day one's context line (R6): settled by Product at 12:27 pm as "4 lists, nothing running". Still open: with Packing named in it, is it "Packing" (copy D1) or "packing" (sheet)?
2. Starter Packing has 11 items, but the addendum's reset example reads "12 to pack" and "12 done". Is the example loose, or does Packing gain a 12th item?
3. Bare-words receipt: settled by Product at 12:27 pm as "Rice, on Packing.", and the acceptance's "added to Packing" changes to match. The copy file also still proposes "Packing, done. Reset for next time." (D14) and "Nothing on it yet" with a window line (D26), both overruled by the addendum; should Research refresh it?
4. A trip list's day (R16): does "Lisbon" carry Oct 26 anywhere (shelf, Now, Today), or only its items?
5. Back words: settled by Design at 12:27 pm. The source string is "‹ Kitchen", which renders uppercase as "‹ KITCHEN" through the label role, and the accessibility label is "Back to Kitchen".
6. Fold hold on a plain list (R28): what is Tess's line? Copy D11 proposes "4 done cleared."
7. `lists-acceptance.md:77` still reads "N done · hold to reset" with a dot; the screens file and sheet drop the dot. Confirm the screens file wins.

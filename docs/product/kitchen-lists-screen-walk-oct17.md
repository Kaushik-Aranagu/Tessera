# Kitchen K88: code-read walk of the merged Lists screens

*Kitchen lead helper, 2026-10-17; read of `master` a4f1d98 (after #738 and #739). Read-only: the app was not run, so nothing here is a recording or a screenshot. Format follows `kitchen-pantry-screen-walk-oct17.md`. Rows walked: `lists-screens-acceptance.md` (9.1 to 12.5), `lists-acceptance.md` (sections 1 to 13), `ship-list-lists.md` (done-when, slices 1 to 12), `starter-lists.md`, `lists-copy-sweep-oct17.md`, `kitchen-refill5-acceptance.md` K31, and the Lists rows of `kitchen-refill7-acceptance.md` and `kitchen-refill8-acceptance.md`. Verdicts: **PASS** (the code does what the row says), **FAIL** (built, but it deviates or part is missing), **NOT BUILT** (the thing the row tests does not exist), **NOT PROVABLE** (needs a run, a timing or a measurement; said where it applies). A row whose subject is a screen that does not exist is NOT BUILT even where the engine half is right; the note says which half.*

## What is merged

Lists on `master` is an engine block and one copy formatter. There is **no Lists screen**: no shelf, no list page, no item page, no pick moment, no door on Home.

| File | Lines | What it is |
|---|---|---|
| `TesseraCore/Sources/TesseraCore/Lists/Lists.swift` | 359 | `ListContents` (lists oldest first, `items`, `open`, `done`, `sections`), and the actions `CreateList`, `AddListItem` (with the wall), `CheckListItem`, `MoveListItem`, `RenameListSection`, `ClearDoneItems` |
| `Features/Lists/ListsCopy.swift` | 22 | Pure formatter: context line "2 lists, 1 running", state word "RUNNING, 2 LEFT", Tess line "Packing has 2 left." / "Packing, nothing left." **Used by no view** (tests only) |
| `TesseraTests/ListsCopyTests.swift` | 27 | Swift Testing on the formatter |
| `TesseraCore/Tests/TesseraCoreTests/ListTests.swift` | 52 | One test: add, check, move, rename section, clear done with undo, empty text refused |
| `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:268-278` | n/a | `List` class (no fields) and `List Item` class: quantity, isDone, checkedAt, section, about, shares |
| `TesseraCore/Sources/TesseraTess/TessGrammar+Kitchen.swift:23-26` | n/a | "list: packing" / "new list films" parses to a new list |
| `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:394-396` | n/a | Receipt for that parse: "New list: Packing." |
| `TesseraCore/Sources/TesseraTess/TessTools.swift:196-203,208-219,323-331` | n/a | Claude-path tools `addToList` and `createList`; `list(named:)` resolver |
| `Features/Groceries/GroceriesView.swift`, `ShopTrip.swift` | n/a | The only screen that draws a `List`: Groceries, with its own aisles, basket and "Private item" mask (`ShopTrip.swift:8-33`) |

**Not in the tree at all** (grep over `Features`, `App`, `Widgets`, `TesseraCore/Sources`): a `.lists` case on `HomeLink` (`HomeSpatialView.swift:333` lists groceries, pantry, recipes, pasteRecipe, notes, review only), `StartListRun`, `CopyList`, `AddListItems`, `RemoveListItem`, `pickedAt`, `pick(from:)`, `progress(of:)`, a reusable flag, a note or date field on `List Item`, a put-away (archive) action for lists, list paste parsing, any Packing / Gym bag / Leaving the house seed, any "Nothing else to show yet." or "No other lists yet." string. `ListsCopy` has no caller outside its own test.

### Lists engine slices (ship list 1 to 9) on master or not

| # | Slice | On master? | Evidence |
|---|---|---|---|
| 1 | List housekeeping | **No** (rename only through generic `RenameObject`, `TrainingActions.swift:521`) | No put-away, remove-item, edit, uncheck-all, progress or last-touched sort in `Lists.swift` |
| 2 | Items open into a paragraph | **No** | `List Item` has no note, date or marker field (`SystemCatalog.swift:269-278`) |
| 3 | Lists from text | **No** | No parser, no `AddListItems`; `TessTools.addItems` loops `AddListItem` one op per item (`TessTools.swift:343-349`) |
| 4 | Reusable lists | **No** | No flag, no reset, no `CopyList` |
| 5 | Run a list on Now | **No** (Groceries `StartShop` / `FinishShop` only, `Shopping.swift`) | No `StartListRun` |
| 6 | Dated items reach Today | **No** | No item date |
| 7 | Pick one | **No** | No `pick(from:)`, no `pickedAt` |
| 8 | List phrases | **Partial** | "list: packing" (grammar) and `addToList` (Claude tool path) only; no "run packing", "pick from films", "reset packing", "packing: charger, socks" |
| 9 | Lists shelf | **No** | No `Features/Lists/` view |

Slices 10 to 12 (list page, item page, pick moment) are also not built. What master has is the pre-slice base ("kitchen slice 1" in the file header: add, check, move, rename section, clear done) plus the #735/#738 pieces (Private item mask on Groceries, the copy formatter).

---

## 1. lists-screens-acceptance.md, rows 9.1 to 12.5

All 29 rows are **NOT BUILT**: no view exists, so each row's subject is absent. Row-level notes where part of the row is built:

| Rows | Verdict | Evidence and gap |
|---|---|---|
| 9.1 Back word, LISTS label, context line | NOT BUILT | The words exist in `ListsCopy.context` (`ListsCopy.swift:6-9`) but read "2 lists, 1 running" (Product, Oct 17), not the row's "6 lists, packing running"; the row text is the stale side. No screen calls it |
| 9.2 Sizes by last touched; 9.3 state words; 9.4 stagger; 9.5 ghost list from paste; 9.6 Groceries once, put away word | NOT BUILT | No shelf. `lists()` sorts oldest first (`Lists.swift:27-30`), so even the data order is wrong. `RUNNING, N LEFT` exists as a string (`ListsCopy.swift:12-14`); "3 OF 7", "REUSABLE", "PICK ONE", "EMPTY", "14 TO BUY", "12 THINGS" exist nowhere |
| 9.7 Door | NOT BUILT | No `.lists` case on `HomeLink` (`HomeSpatialView.swift:333`); KITCHEN shows Groceries, Pantry, Recipes (`:363-382`) |
| 10.1 to 10.7 Page, rows, fold, options, paging, run | NOT BUILT | No view. No run (`StartListRun`), no reusable, no sections toggle |
| 10.8 Ghost row adds to this list | NOT BUILT | The receipt half is right and thing first: "Rice, on Packing" (`Lists.swift:185`) and "Private item, on Packing" (`:183`); no ghost row on a list page and no 4 s UNDO wiring for it |
| 10.9 Remove by swipe | NOT BUILT | No `RemoveListItem`, no swipe, no "Ground beef, removed." anywhere |
| 10.10 Remove by phrase | NOT BUILT | No phrase, no "No rice on Groceries." |
| 10.11 "done" on a reusable list | NOT BUILT | No reusable, no RESET hold, no put-away |
| 10.12 Empty states | NOT BUILT | No strings |
| 11.1 to 11.5 Item opened | NOT BUILT | No item page, no note, date, backlink list or strike swipe |
| 12.1 to 12.5 Pick one | NOT BUILT | No pick engine or moment |

**Counts: 0 PASS, 0 FAIL, 29 NOT BUILT.**

## 2. lists-acceptance.md, engine sections 1 to 8b

| Row | Verdict | Evidence and gap |
|---|---|---|
| 1a Rename list, undo; Groceries keeps id | NOT PROVABLE | Generic `RenameObject` exists (`TrainingActions.swift:521`); no Lists test renames a list; the fixed Groceries id is `Groceries.listID` but rename-keeps-id is untested |
| 1b Put away / bring back | NOT BUILT | No such action |
| 1c Remove one item with undo | NOT BUILT | No `removeListItem`; generic `DeleteObject` (`TrainingActions.swift:557`) is not what the row names and has no `checkedAt` rule |
| 1d Edit text and quantity | NOT BUILT | No edit action for list items |
| 1e Uncheck all, one op | NOT BUILT | None |
| 1f `progress(of:)` | NOT BUILT | `ListContents` has `open` and `done` (`Lists.swift:37-44`), no progress |
| 1g Sort by last touched | NOT BUILT | `lists()` is oldest first (`:27-30`) |
| 2a to 2d Notes, @links, date, `hasNote` / `date` | NOT BUILT | No fields (`SystemCatalog.swift:269-278`) |
| 3a Paste gives list with sections and a done item | NOT BUILT | No parser |
| 3b Quantities read as in groceries | NOT BUILT | |
| 3c `AddListItems`, one op, one undo | NOT BUILT | Only singular `AddListItem` (`Lists.swift:102`) |
| 3d Blank paste refused | NOT BUILT | |
| 3e Change preview before write | NOT BUILT | |
| 4a to 4d Reusable flag, reset, `CopyList`, Groceries cannot be reusable | NOT BUILT | |
| 5a `StartListRun` and Now's line | NOT BUILT | |
| 5b Suspend into ledger | NOT BUILT | |
| 5c Finish; reset is its own op | NOT BUILT | |
| 5d `StartShop` / `FinishShop` still pass | NOT PROVABLE | Both exist (`Shopping.swift:60-67` for `FinishShop`); tests were not run |
| 6a to 6c Dated items reach Today | NOT BUILT | |
| 7a to 7d Pick one | NOT BUILT | |
| 8a Lists phrase rows 41 to 48 | FAIL | Only "list: packing" (`TessGrammar+Kitchen.swift:23-26`) and the Claude-path `addToList` (`TessTools.swift:196-203`) exist. No deterministic "add charger to packing", "packing: charger, socks", run, pick or reset |
| 8b Rows 1 to 40 still pass | NOT PROVABLE | Kitchen grammar was read, not run |
| 8c Unknown list: "No list called holiday." | FAIL | Code throws lowercase `"no list called \(name)"` (`TessTools.swift:329-330`); not the Tess line in the row |
| 8b.1 Wall on add: secret or money line becomes a private note, list unchanged | PASS | `AddListItem.apply` (`Lists.swift:134-136`): `kept` returns nil for empty-after-price, secret list line or money shape, then `CreateNote(isPrivate: true)`. Receipt "Private note, kept" has no trailing period (`:180`), while the Tess path has one (`TessCaptureEngine.swift:311`); which surface shows the op receipt is not provable by reading |
| 8b.2 Price stripped, item stays | PASS | `EngineWall.withoutPrice` (`Lists.swift:154`) |
| 8b.3 Paste runs the wall per line; "1 private note, kept." | NOT BUILT | No paste |
| 8b.4 Body and health lines stay as typed | PASS | `kept` tests secret, money and bare weight only (`:156-157`), not `isHealth`; `isPrivateItem` (`:162-164`) changes only the label spoken |

Sections 9 to 12 of `lists-acceptance.md` repeat the screens above: **4 blocks, all NOT BUILT** (same evidence as section 1 of this walk).

## 3. lists-acceptance.md section 13 (sheet 87)

| Row | Verdict | Evidence and gap |
|---|---|---|
| 13.1 Empty shelf: "Just Groceries", "NOTHING TO GET", "No other lists yet." | NOT BUILT | No shelf, no strings |
| 13.2 "new list: packing" gives "Packing, new list." with UNDO 4 s; existing name opens that list | FAIL | Grammar exists (`TessGrammar+Kitchen.swift:23-26`), but the Tess receipt is "New list: Packing." (`TessCaptureEngine.swift:396`) and the op receipt "Packing, made" (`Lists.swift:97`); `CreateList` checks only for an empty name (`:84-90`), so a repeat makes a second list (FG5, G40) |
| 13.3 One other list: "2 lists, Packing running"; Tess "Packing has 9 left."; long shelf | NOT BUILT | Formatter only; Tess line matches (`ListsCopy.swift:19-21`); context reads "2 lists, 1 running" by the later Oct 17 ruling |
| 13.4 State word "RUNNING, 9 LEFT" in the live colour | FAIL | Comma form is right and tested (`ListsCopyTests.swift:16-19`); no surface and no colour use |
| 13.5 ON THEM side | NOT BUILT | |
| 13.6 Swipe remove, count rolls, "Rice, removed." UNDO 10 s | NOT BUILT | No action, no swipe |
| 13.7 Shelf and recipe rows have no swipe | NOT BUILT | No shelf |
| 13.8 Private item at 66% ink; receipts "Private item, on Groceries." / "removed" / "back on" | FAIL | Add receipt right (`Lists.swift:183`, `TessCaptureEngine.swift:371`); Groceries shows "Private item" until tapped (`ShopTrip.swift:8-33`) with no 66% value read; no remove, so "Private item, removed." and "back on" are absent; no other list screen |
| 13.9 KEPT PRIVATE count on the side | NOT BUILT | |
| 13.10 Body and health items show as typed on his phone | NOT BUILT | Engine keeps them (`Lists.swift:156-157`, see 8b.4); no list screen shows them. Groceries masks them as "Private item" until tapped, which is the 13.8 rule |
| 13.11 to 13.13 Recipes front, empty and one states, Recipes side | Not walked | Recipes, not Lists; the Pantry walk covers `RecipePage`. Excluded from counts |
| 13.14 Reduce Motion, haptic, AX3 on both fronts | NOT BUILT | |
| 13.15 Copy sweep: no "at" before a time, no "…", cobalt only Tess, digits | PASS | Over `ListsCopy.swift` and `Lists.swift`: none present; counts are digits |

**lists-acceptance.md totals (sections 1 to 13, 54 rows walked): 4 PASS (8b.1, 8b.2, 8b.4, 13.15), 5 FAIL (8a, 8c, 13.2, 13.4, 13.8), 42 NOT BUILT, 3 NOT PROVABLE (1a, 5d, 8b rows 1 to 40).**

## 4. ship-list-lists.md, done-when per slice

| Slice | Verdict | Evidence |
|---|---|---|
| 1 Housekeeping | NOT BUILT | See slice table above |
| 2 Items open into a paragraph | NOT BUILT | |
| 3 Lists from text | NOT BUILT | |
| 4 Reusable lists | NOT BUILT | |
| 5 Run a list on Now | NOT BUILT | Groceries shop only |
| 6 Dated items reach Today | NOT BUILT | |
| 7 Pick one | NOT BUILT | |
| 8 List phrases | FAIL | Partial: new list and add by name; the other four phrases absent |
| 9 Shelf | NOT BUILT | |
| 10 List page | NOT BUILT | |
| 11 Item opened | NOT BUILT | |
| 12 Pick moment | NOT BUILT | |

**Counts: 0 PASS, 1 FAIL, 11 NOT BUILT.** The `Features/Lists/` folder holds one copy file; no recording under `docs/recordings/` is possible.

## 5. starter-lists.md

| Row | Verdict | Evidence |
|---|---|---|
| Gym bag installed, user-deletable, never reinstalled | NOT BUILT | No seed: grep for "Gym bag" finds only unrelated test notes (`ObjectPrivacyTests.swift:55`, `SideFactsTests.swift:28`); `StarterContent` seeds the plan only |
| Leaving the house | NOT BUILT | No hit |
| Packing with CLOTHES, TECH, PAPERS; "copy packing for lisbon" | NOT BUILT | No seed, no `CopyList`; "Packing" appears only as an example in action descriptors (`Lists.swift:75`) and a tool hint (`TessTools.swift:200`) |

**Counts: 0 PASS, 0 FAIL, 3 NOT BUILT.** All three need slices 3 and 4 first (Core).

## 6. lists-copy-sweep-oct17.md, code rows

| Row | Verdict | Evidence |
|---|---|---|
| `Lists.swift:185` receipt form "added to" vs "on" | PASS | Now "Rice, on Packing" (`Lists.swift:185`) |
| `Lists.swift:170-174` summary matches receipt | PASS | `"\(thing), on \(listTitle)"` (`:174`) |
| `Lists.swift:182` "Private item, on <list>" | PASS | `:183` |
| `Groceries.swift:431` "Added ..." | PASS | Not present; the summary reads "Tacos, 10 added." (`Groceries.swift:415-418`) |
| `TessCaptureEngine.swift:369` "on the list." | PASS | Now "Chickpeas, on Groceries." / "3 things on Groceries." (`:371`) |
| `Lists.swift:180` "Private note, kept" lacks the period | FAIL | Still `"\(SecretWords.title), kept"` (`:180`); the Tess path has the period (`TessCaptureEngine.swift:311,332`) |

Doc rows (`ship-list-lists.md:32` "Twelve things", `:13` "archive it") are text in docs, not code: not walked. The sweep's "no Packing seed in TesseraCore/Sources" still holds (section 5).

**Counts: 5 PASS, 1 FAIL.**

## 7. kitchen-refill5-acceptance.md, K31 (Lists empty, 100-item)

Groceries is the only screen that draws a list, so rows that name "a list" are walked against the Lists page (NOT BUILT) except where Groceries shares the code.

| Row | Verdict | Evidence and gap |
|---|---|---|
| K31.1 Only Groceries: "Just Groceries", "NOTHING TO GET", line, Tess line | NOT BUILT | No shelf. "Just Groceries" is ruled (G49) but is in no Swift file |
| K31.2 Side opens on "Nothing else to show yet." | NOT BUILT | |
| K31.3 Packing running: context, "RUNNING, 6 LEFT", Tess "Packing has 6 left." | NOT BUILT | Strings built in `ListsCopy`; no run, no screen. Row says "2 lists, Packing running"; formatter says "2 lists, 1 running" |
| K31.4 100-item list as one sheet, fade over 40 pt | NOT BUILT | No list page |
| K31.5 120 Hz scroll, AX3 | NOT PROVABLE | No page to run; Groceries is a different screen |
| K31.6 Check item 57; "Uncheck all" one op | FAIL | Check is one op (`CheckListItem`, `Lists.swift:192-229`); no uncheck-all op. Count roll not read |
| K31.7 Add by voice: "Rice, on Groceries." UNDO 4 s | NOT PROVABLE | Receipt text right (`TessCaptureEngine.swift:371`); `HomeQueue.hold` gives 10 s to any line with UNDO unless the caller passes `holds` (`HomeQueue.swift:44-49`), and the capture caller was not traced; "Rice, taken back." not found |
| K31.8 Swipe remove past 96 pt | NOT BUILT | |
| K31.9 UNDO at 9 s returns row with `checkedAt` | NOT BUILT | |
| K31.10 Quantity change: "Rice, 2 lbs." UNDO 10 s | NOT BUILT | No edit action |
| K31.11 VoiceOver Remove action; slot stays 10 s | NOT BUILT | Slot rule exists (`HomeQueue.swift:44-46`); no Remove |
| K31.12 VoiceOver add: 10 s | NOT PROVABLE | Rule exists for UNDO lines (`HomeQueue.swift:44-46`); caller not traced |
| K31.13 Second change replaces the one slot | PASS | One `note` replaced on each `say` (`HomeQueue.swift:28,31-34`) |
| K31.14 Private item among 100: remove and UNDO lines | FAIL | Mask on Groceries right (`ShopTrip.swift:8-33`); removal lines do not exist |
| K31.15 Reduce Motion 150 ms crossfade | NOT PROVABLE | No Lists surface; not run |
| K31.16 Copy sweep on Lists screens | PASS | Nothing to sweep beyond `ListsCopy.swift` and `Lists.swift`: no "at" before a time, no "…", no " · ", no "Archive" |

**Counts: 2 PASS, 2 FAIL, 8 NOT BUILT, 4 NOT PROVABLE (16 rows).**

## 8. Lists rows in kitchen-refill7 and kitchen-refill8

| Row | Verdict | Evidence and gap |
|---|---|---|
| K44.8 Walled item reads "Private item" where lists show it; receipt "Private item, on Groceries." | PASS | `privateItemLabel` (`Lists.swift:188`), receipt (`:183`), Tess (`TessCaptureEngine.swift:371`). USUALLY half not walked here |
| K45.8 "add milk to packing" gives "Milk, on Packing."; then "add milk" goes to Groceries | FAIL | Receipt form is right once an item lands (`Lists.swift:185`); no grammar rule for "add X to <list>", only the `addToList` tool (`TessTools.swift:196-203`); the bare-add half is the Groceries rule (`TessGrammar+Kitchen.swift:56-65`, read, not run) |
| K47.13 / K47.17 List item "@Tacos": plain ink, not tappable after delete | NOT BUILT | No item note or @link on list items |
| K54.2 Lists: delete Tacos while a list item links it | NOT BUILT | Same |

**Counts: 1 PASS, 1 FAIL, 3 NOT BUILT.**

## 9. Known gaps G40, G43, G44, G48 against the code

| Gap | Still open on a4f1d98? | Evidence |
|---|---|---|
| G40 `list(named:)` is silent on two matches | **Open** | `TessTools.swift:323-331`: exact title else first prefix match, oldest first, no ambiguity refusal; `task(named:)` just above it does refuse ("more than one task like", `:313-318`). `CreateList` has no duplicate check (`Lists.swift:84-90`). A one-letter prefix still matches. Receipt names the list, so a wrong landing is visible |
| G43 Done shopping: no UNDO, no line, failed write swallowed | **Open** | `GroceriesView.swift:315-322`: `_ = try? model.engine.perform(FinishShop(), by: .user)`, no `TessVoice` line, no undo; `clearBasket` at `:292-302` speaks with undo |
| G44 A shop never goes idle | **Open** | `ProcessTable.swift:87-88`: only workouts are suspended by idle ("a shop, a cook or a task" never); the 7-day put-away applies to already-suspended processes (`:109-118`). `HomeLines.swift:335-353` was not re-read in this pass |
| G48 Tombstones re-sorted on every read | **Open** | `Models.swift:360-362`: `orderedChildren` filters and sorts on each call; no Groceries or Pantry case in `ScaleTests.swift` (grep finds none). Cost still unmeasured, so **not provable by reading** |

## Summary

| Section | Rows | PASS | FAIL | NOT BUILT | NOT PROVABLE |
|---|---|---|---|---|---|
| lists-screens 9.1 to 12.5 | 29 | 0 | 0 | 29 | 0 |
| lists-acceptance sections 1 to 13 | 54 | 4 | 5 | 42 | 3 |
| ship-list done-when (12 slices) | 12 | 0 | 1 | 11 | 0 |
| starter-lists | 3 | 0 | 0 | 3 | 0 |
| copy sweep, code rows | 6 | 5 | 1 | 0 | 0 |
| K31 | 16 | 2 | 2 | 8 | 4 |
| refill7 and refill8 Lists rows | 5 | 1 | 1 | 3 | 0 |
| **Total** | **125** | **12** | **10** | **96** | **7** |

Engine slices on master: **0 of 9 complete**; slice 8 partial (new list, add by name). Slices 10 to 12 and every Lists screen: not built. G40, G43, G44, G48: all four still open.

## Need, by owner

**Core**
1. Engine slices 1 to 7: housekeeping (put away, remove-item with `checkedAt` rule, edit, uncheck all, progress, last-touched sort), item note / date / marker fields, paste parser with `AddListItems`, reusable flag with reset and `CopyList`, `StartListRun`, dated items on Today, `pick(from:)` with `pickedAt`.
2. Slice 8 phrases: "add X to <list>", "packing: a, b", run, pick, reset; "No list called holiday." in the row's words (8c).
3. G40 resolver: refuse a name that matches two lists ("More than one list like trip." is proposed, Product to rule); an exact name wins only when it is one list; a one- or two-letter prefix never matches. `CreateList` opens the existing list on a repeat name (13.2, FG5).
4. G44: an idle rule for a shop that was never finished, with the basket kept for Pantry.
5. G48: compact or prune soft-deleted Groceries rows, or add a cleared-by-shop marker; add Groceries and Pantry cases to `ScaleTests`.
6. Starter lists (Gym bag, Leaving the house, Packing) once slices 3 and 4 land; "Packing, new list." receipt form (13.2); trailing period on "Private note, kept." at `Lists.swift:180` if the op receipt is shown.

**Builder B** (Lists screens, Features/Lists/)
1. Shelf, list page, item page and pick moment (rows 9.1 to 12.5), starting from `ListsCopy`, which has no caller yet.
2. Swipe remove with REMOVE at 60 pt, commit past 96, "Rice, removed." UNDO 10 s (10.9, 13.6, K31.8 to K31.11); needs Core's remove op.
3. Empty and one-list states with "Just Groceries" (K31.1 to K31.3, G49), the ON THEM side (13.5), 66% ink on a Private item row (13.8).
4. G43: UNDO 10 s and a failure line on Done shopping; G48: one read per render.

**Builder A** (Home)
1. `.lists` case on `HomeLink`, the "Lists" word under Groceries with "PACKING, 9 LEFT" in the live colour, zoom 0.94 to 1 over 420 ms (9.7, G1).
2. Home's read of a paused or stale shop (G44, with Core).

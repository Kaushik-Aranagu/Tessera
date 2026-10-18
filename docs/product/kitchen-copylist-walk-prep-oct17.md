# CopyList (#866) walk prep under the new masks

*Kitchen lead, prepared Sun Oct 18 (PDT) for the walk of CopyList on the phone. Docs only, nothing built or run (no Swift toolchain here). Every file:line below was read with `git grep` on origin/master at 8af1c1b (merge of #925). CopyList is PR #866 (merge dd3697a, fix 88e1395). Rulings used: G102 (no reveal anywhere, 5:40 pm and 4:25 pm Oct 17), the "Private list" label (4:33 pm O3), the copy rulings of 3:50 pm and 4:00 pm Oct 17, the 4:20 pm amendment (the op log keeps the raw title; anything he reads masks), G105 (one widest private-text function, lands with #890). Where master and a ruling disagree the line says "open", with the owner. Fuller static grading: `kitchen-gap-hunt-10-copylist-pantry-oct17.md`; the acceptance fixtures are in the Research CopyList files.*

## 0. Before you start

- A copy is made by the engine action `CopyList` and, today, only in code: no screen has a Copy word (`git grep CopyList -- Features App` finds nothing) and the phrase "copy packing for lisbon" is not built (`TesseraCore/Sources/TesseraIntents/TesseraRuntime.swift:73` says "in-app only for now ... lists slice 8"; no `copy` rule in `TessGrammar*.swift`). So the walk of the screen and phrase rows is a build target; the engine rows run in the package tests (`swift test` inside `TesseraCore/`, on the Mac).
- Use a copy of the store for anything that deletes. Fixtures only: a list "Packing" with charger, socks, and one item that the walls call private (a medicine line such as "ibuprofen 400 mg", as `ListReuseTests.swift:332-342` uses). Never real words.

## 1. A Private list: the title

| Check | Expect | file:line on origin/master |
|---|---|---|
| A list whose name the walls call private is masked on the Lists shelf, its page and the run lines | Reads "Private list", never the raw name | `Features/Lists/ListsShelf.swift:95-98` (`shownName`), `Features/Lists/ListsView.swift:165` and `:801`; the engine side `TesseraCore/Sources/TesseraCore/Lists/ListRuns.swift:15-21` (`privateListLabel`, `shownName`) |
| Now ledger step for a running private list | "Private list, N left" | `Features/Home/NowPage.swift:586`; `ListRuns.swift:10-13` |
| A copy made under a private new name | Receipt "Private list, ..." and summary "Copied <source> to Private list"; the typed name appears in neither | `ListReuse.swift:199-203` (`shown`), `:208-212` (`summary`), `:214-217` (`receipt`); test `ListReuseTests.swift:344-351` |
| Receipt wording for the copy | Ruled 4:00 pm: "Private list, new list." (thing first, like "Private item, on Groceries."). **Open:** master prints "<name>, copied from <source>" (`ListReuse.swift:216`, `:222`) and the test pins it (`ListReuseTests.swift:348`). The 3:50 pm ruling also says "copy packing for lisbon" makes a list named "Packing, Lisbon" with receipt "Packing, Lisbon, new list."; master names the copy exactly as typed. Owner Core | |
| Day log line for a copy | "New list: <title>". **Open (G75):** `DayStory.swift:319-325` writes `lookup.title(of:)`, and `title(of:)` at `:474-482` masks only cooks and recipes, so a private list copy shows its raw name in the Day log. Ruled: "Private list" (3:50 pm; the 4:20 pm amendment keeps the raw title only in the op payload). Owner Core | `DayStory.swift:91`, `:319-325`, `:474-482`; test for the public case `DayStoryTests.swift:289-292` |
| A private source's name in the copy receipt | Reads "Private list" | `ListReuse.swift:205-207` (`sourceName` uses `ListContents.shownName`); no test uses a private source |

## 2. Items on a Private list

| Check | Expect | file:line |
|---|---|---|
| The copied rows keep their text; a walled row reads "Private item" in the copy | "Private item", the typed words nowhere on screen, in a receipt or in VoiceOver | Copy loop `ListReuse.swift:184-195`; label `Lists/Lists.swift:307-312` (`privateItemLabel`, `shownTitle`); test `ListReuseTests.swift:332-342` |
| Receipt for a row added to a list | "Private item, on Packing" (thing first, "on") | `Lists/Lists.swift:300-304` |
| Taking a row off | "Private item" in the removal line and in the UNDO line | `Features/Lists/ListsView.swift:368-372` (`remove`) |
| Checking a row off | Receipt does not contain the words | `ListReuseTests.swift:339-341` |
| Quantity, section and notes copy with the row; all rows open; the flags #pick-one and "picked:" do not | As written | `ListReuse.swift:153-160`, `:179-195` |

## 3. No reveal (G102)

Ruled: a masked private row on Groceries, Lists, the shop trip and the recipe pages never reveals; one tap strikes it. Drop `revealed` and the "Shows it" hint.

**On master today it still reveals, so this walk fails until the reveal-removal PR lands** (the hero half for recipes is #912, pending merge; the Lists and Groceries half is not on master):

- `Features/Groceries/ShopTrip.swift:15` (`revealed` set), `:24` (`label` returns the words once revealed), `:42-48` (`tap` returns `.reveal` on the first tap), `:58` (cleared on leaving).
- `Features/Lists/ListsView.swift:156` (`rows = ShopTrip()`, comment "until tapped"), `:386-387` (`tap` ignores `.reveal`), `:364` (hint "Shows it").
- `Features/Groceries/GroceriesView.swift:251` (`case .reveal: break`) and `:526` (hint "Shows it").

What to check once it lands: tap a "Private item" row on a copied Private list: the row strikes at once and the words never show; no "Shows it" in the accessibility tree; the basket and the list read the same. `ShopTripTests` are rewritten (4:20 pm).

## 4. The copy phrase

| Check | Expect | file:line |
|---|---|---|
| "copy packing for lisbon" makes a list | **Not built.** The ruled result: a list named "Packing, Lisbon", receipt "Packing, Lisbon, new list." (3:50 pm). A private list's copy: "Private list, new list." (4:00 pm). A copy of a copy: "Packing, Lisbon, Porto" (4:00 pm) | `TesseraRuntime.swift:73`; no grammar rule |
| Two lists could match "pack" | "More than one list like pack." (the G40 line, no pick-from-two sentence) | Wording exists for the other route at `TesseraCore/Sources/TesseraTess/TessTools.swift:394` |
| A name that is already a list opens that list and makes nothing | Receipt "<existing name>, already a list" | `ListReuse.swift:172-176`, `:220-223`; test `ListReuseTests.swift:294-309` |
| The phrase is never offered to Claude | Hidden as a tool | `ListReuse.swift:130` (`isOfferedToModel: false`) |
| A private name typed in the phrase never leaves the phone | Nothing in the capture pack, the op summary or the receipt | `ListReuse.swift:199-217` |

## 5. Groceries cannot be copied

| Check | Expect | file:line |
|---|---|---|
| Copy Groceries under any name | Refused: "Groceries can't be copied" | `ListReuse.swift:169-171` (guard on `Groceries.listID`) |
| Copy any list under the name "Groceries" (any case) | Refused, same guard | `ListReuse.swift:169-171`; test `ListReuseTests.swift:303-306` |
| Blank name | Refused: "the copy needs a name" | `ListReuse.swift:166-168`; test `ListReuseTests.swift:308` |
| The phrase route when Groceries is the source | **Open, not built.** The refusal needs a Tess line; none is boarded. Owner Product (copy) and Core | `TesseraRuntime.swift:73` |

## 6. Walk order on the phone (when the screens exist)

1. Make "Packing" with charger, socks and one walled medicine line.
2. Copy it under a plain name. Receipt, shelf, page, Day log: all plain, the walled row "Private item" everywhere.
3. Copy it under a name the walls call private. Receipt "Private list, ..."; the shelf row, run line, Now line, Day log and Siri read "Private list"; the op log keeps the raw name by ruling (4:20 pm), and "What was sent" and exports show it masked.
4. Tap the walled row: it strikes, nothing reveals.
5. Try Groceries as the source and as the name.
6. Undo the copy inside its window: the copy goes, the original stays untouched.

## What could not be grounded

- Nothing here was run; every verdict is a read of the code.
- The Day log mask (G75) and the receipt wording ("new list" against "copied from") are open on master; the walk will fail those rows until Core changes them.
- The reveal removal for Lists and Groceries is ruled but not on master; the hero half is #912 and I did not confirm its merge state.

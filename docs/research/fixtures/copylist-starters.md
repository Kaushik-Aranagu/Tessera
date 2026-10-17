# CopyList and the starter lists: fixture rows

For: Core (engine), Builder B (screens), Kitchen lead (words and rulings). Docs only; nothing run (no Swift toolchain here). Read on the checked-out master in /home/user/Tessera.
Format follows `docs/research/fixtures/lists-fixtures.md` and `docs/research/fixtures/engine-wall.md`: one table per topic, a row id, the expected outcome, a Swift Testing name Core can paste, whether master already does it, and an owner for every gap.

Sources read: `TesseraCore/Sources/TesseraCore/Lists/ListReuse.swift` (CopyList, lines 120-224), `ListRuns.swift`, `Lists.swift` (CreateList, AddListItem), `Actions/ActionRegistry.swift`, `Actions/Transaction.swift`, `TesseraTess/TessTools.swift` (`list(named:)`, `ListLookupLine`), `TesseraTess/TessCaptureEngine.swift`, `DayLog/DayStory.swift`, tests `ListReuseTests.swift` (`CopyListTests`), `ListLookupTests.swift`, `DayStoryTests.swift`; docs `product/kitchen-v2-scope.md`, `product/ship-list-kitchen.md` (neither says anything about copying or starters; the Lists slices are in `ship-list-lists.md`, `lists-acceptance.md` 4c, `starter-lists.md`), `research/fixtures/lists-fixtures.md`, `lists-slice-8-phrases.md` (L8-22), `lists-day-one.md` (R1, R15), `product/decisions.md` (UNDO slot 1:35 PM Oct 16, copied-list line 12:38 PM Oct 16, G40 refusal 8:40 AM Oct 17), `product/kitchen-test-specs-wall-g40-g43-g44-oct17.md`.

## Rulings applied (Product, decisions 3:50 PM Oct 17)

These replace the earlier open questions; every row below is read with them.
1. **The copy's name** is "<source>, <typed name>": copying Packing as Lisbon makes "Packing, Lisbon". The old receipt "Lisbon, copied from Packing." is retired. The receipt is "Packing, Lisbon, new list." A copy of that copy typed Porto is "Packing, Lisbon, Porto" (receipt "Packing, Lisbon, Porto, new list."; confirm with Kitchen lead that names do not collapse).
2. **Ambiguity** wording is the engine line "More than one list like pack." The Bar question "Packing, or Packing, Lisbon?" is retired (closes G4003).
3. **Op log payload and `DayStory.title(of:)` mask a private list**: both show "Private list". This turns PV11 and PV13 from open questions into **Core build items**, with tests `copy_opLogPayloadMasksPrivateTitle` and `dayStory_privateListTitleIsMasked`. The op payload for a copied private row follows the same mask.
4. **Starters** install with Core's next Lists PR (closes the "not installed" gap on ST01 to ST05; the rows stay as acceptance for that PR).
5. Receipt and summary strings in the rows and the Swift skeleton were updated by search to these rulings. Rows where a name is private (PV07 to PV09) read "Private list, new list." and need the Kitchen lead to confirm the exact private form.

## How to read the status column

- **traced**: I read the code path (and the test, where one exists) and master does this today. "traced, test" means a test on master already pins it; "traced, code" means the code does it but no test asserts it.
- **inferred**: reasoned from neighbouring code or a doc ruling; I did not find the line that does it, or found nothing that contradicts it.
- **gap**: master does not behave this way. Every gap row names an owner: Core, Builder B or Kitchen lead.

## What exists on master (the facts every row rests on)

1. `CopyList(list: UUID, name: String)` is registered (`ActionRegistry.swift:20` and decoder `:80`), `isOfferedToModel: false`, so Tess's model and Claude cannot call it. No grammar case calls it (`copy packing for lisbon` is row L8-22 "miss" in `lists-slice-8-phrases.md`), and `TesseraRuntime.swift:73` lists it as "in-app only for now". No screen calls it either. Today only tests and `perform(named:)` reach it.
2. It takes the source by id (`transaction.object(list, is: .list)`), so the engine itself never has a name ambiguity. A deleted or non-list id throws.
3. Order of checks in `apply`: empty trimmed name throws "the copy needs a name"; source is Groceries or name lowercases to "groceries" throws "Groceries can't be copied"; then `CreateList.existing(named:)` (trim, lowercase, live lists only, oldest first, built-in Groceries counts); a hit returns that list with nothing written ("already a list"); otherwise create the list, copy the reusable flag only when the source has it, then each child in order with `quantity` and `section` (only values the item owns) and its notes with the `#reusable`, `#pick-one` and `picked:` lines removed.
4. Not copied: checked state and `checkedAt` (the new rows are open), links such as `about`, the source's run state or process, the pick stamp, the source's own other note lines (they are not copied at all, only flags decide `reusable`; the list-level notes are never copied).
5. Words: summary "Copied Packing to Packing, Lisbon"; receipt "Packing, Lisbon, new list."; repeat receipt "Lisbon, already a list". The typed name is shown as "Private list" when `ObjectPrivacy.isPrivateWord` says so; the source name goes through `ListContents.shownName` ("Private list" for a walled source). The voice layer adds the period (Bar lines in `TessCaptureEngine` end with one). `decisions.md` 12:38 PM Oct 16 rules "Packing, Lisbon, new list.."
6. Item titles are stored in the user's words. The mask is applied when a line is printed (`AddListItem.shownTitle` gives "Private item" for a medicine or body fact). Money and secret lines never become items (they reroute to a private note at `AddListItem.apply`), so the only private rows a source can hold are medicine and body-fact items.
7. The op log: `Transaction.create` appends `.create(object:classID:parent:title:)` with the raw title (`Transaction.swift:34-38`), for the new list and for every copied row. `OpRecord.summary` and `.receipt` are separate strings and are masked.
8. The Day log: `copyList` has the line "New list:" and `DayStory.title(of:)` returns `object.title` for a list (no list mask; only cook and recipe titles are masked).
9. The starter lists (Gym bag 10 items, Leaving the house 6, Packing 11) exist only in `docs/product/starter-lists.md`. `StarterContent.swift` installs the plan, routines and kit only. No "Gym bag" seed exists in `TesseraCore/Sources` (the string appears only in test fixtures). `lists-day-one.md` R1 and `kitchen-lists-screen-walk-oct17.md` section 5 say the same: not built.
10. UNDO window (`decisions.md` 1:35 PM Oct 16): one UNDO slot; 4 s for a new thing, 10 s for a change, 10 s for everything under VoiceOver, paused in the background; the undo receipt is "Thing, taken back." The `UndoWindow` type (Core 0s) and `UndoSlot` (Builder B 0i) are not in the tree (`Features/Home/HomeQueue.swift:44` only mentions the VoiceOver rule in a comment). The engine's `undo(_:)` and `redo(_:)` work on records.

## A. The plain copy

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| CP01 | Copy Packing (two items, one checked, one with quantity, one with section) to a new name | Same items in the same order, all open, quantity and section kept; the source untouched (checked item still checked) | traced, test (`aCopyHasTheSameItemsAllOpenAndTheOriginalStays`) | `copy_keepsItemsOpenAndSourceUntouched` (exists; keep) | none |
| CP02 | Copy is one op record | `engine.history` grows by exactly 1 | traced, code (one `perform`, one record); no test counts it | `copy_isOneOpRecord` | Core adds test |
| CP03 | Undo the copy | The new list and all its rows are gone; the source is unchanged | traced, test (same test, `engine.undo`, asserts the title is gone; does not assert the rows) | `copy_undoRemovesListAndRows` | Core adds the row assertion |
| CP04 | Redo after undo | The copy comes back with its rows, all open | inferred (redo exists for other actions; nothing runs it for a copy) | `copy_redoBringsItBack` | Core adds test |
| CP05 | Source is a reusable list | The copy is reusable (`#reusable` line only); `#pick-one` and `picked:` do not copy; the source's other note lines on the list are not copied | traced, test (`flagsDoNotCopyExceptReusable`) | `copy_reusableFlagCopiesPickStampDoesNot` (exists) | none |
| CP06 | Source is a plain list | The copy is plain | traced, test (same test, `Errands 2`) | same | none |
| CP07 | Source item has a note with a user line plus `#pick-one` and a `picked:` stamp | The copy keeps only the user line | traced, test (same test; note equals "the blue one") | same | none |
| CP08 | Source has an item with `about` links (a recipe or a dated item) | Links and dates do not carry to the copy; the copy's rows are plain | traced, code (only `quantity`, `section`, `notes` are copied) | `copy_doesNotCarryLinksOrDates` | Kitchen lead to confirm that a dated item's date should not copy (rule not found in docs) |
| CP09 | Copy an empty list (no rows) | A new empty list is made, receipt "Y, X, new list." | inferred (loop runs zero times; no guard) | `copy_ofEmptyListMakesEmptyList` | Core adds test; Kitchen lead to say if "copied" is right for an empty one |
| CP10 | Section names with no rows left | Sections exist only as an item field, so a section with no item has nothing to copy | traced, code | `copy_sectionsFollowItems` | none |
| CP11 | Copy keeps the source's row order after items were moved or reordered | Same visible order | traced, code (`orderedChildren`, `setSortIndex` from 0) | `copy_preservesOrderAfterMoves` | Core adds test |
| CP12 | Copy a list that holds a checked-and-cleared history | Cleared rows (deleted) are not copied | traced, code (`orderedChildren` skips deleted) | `copy_skipsDeletedRows` | Core adds test |
| CP13 | Tool call by name `copyList` with JSON arguments | Decodes and runs | inferred (decoder is registered; `theActionsDecodeFromAToolCall` covers two other list actions only) | `copy_decodesFromToolCall` | Core adds test |
| CP14 | Model or Claude asks for `copyList` | Not offered; the tool list omits it | traced, code (`isOfferedToModel: false`) | `copy_isNotOfferedToTheModel` | none (guard test only) |

## B. Private items and private names

Test inputs here are described in words so no private text sits in this file. Where a test needs one, use the same medicine-name-with-a-dose input that `aPrivateRowStillReadsPrivateItemInTheCopy` already uses (`ListReuseTests.swift:336`) and a list name that holds a rent amount (as `everyListLineMasksAPrivateListName` uses).

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| PV01 | Source has one medicine-with-dose item; copy it | The copy has that row; `AddListItem.shownTitle` gives "Private item" | traced, test (`aPrivateRowStillReadsPrivateItemInTheCopy`) | `copy_privateRowReadsPrivateItem` (exists) | none |
| PV02 | Check the copied private row | The check receipt does not contain the medicine word | traced, test (same test) | same | none |
| PV03 | Uncheck the copied private row | Receipt "Private item, back on Lisbon" with no medicine word | inferred (`CheckListItem` masks through `shownTitle` per `aPrivateItemsWordsNeverReachAResetLine` and G41; the copy path is the same class of row) | `copy_privateRowUncheckReceiptIsMasked` | Core adds test |
| PV04 | Copy receipt and summary for a source that holds a private item | "Packing, Lisbon, new list." and "Copied Packing to Packing, Lisbon"; no item word anywhere in either (they never print items) | traced, code (neither string reads children) | `copy_receiptAndSummaryNameNoItems` | Core adds test |
| PV05 | Reset or clear-done on the copy | Receipt says "Lisbon, reset" or "Lisbon, done items cleared", no item word | traced, test for the source path (`aPrivateItemsWordsNeverReachAResetLine`); the copy is an ordinary list | `copy_thenResetNamesNoItems` | Core adds test |
| PV06 | Run the copy (StartListRun) | Now line is "Lisbon, 3 left" (counts only) | traced, code (`runLine` prints counts) | `copy_runLineHasNoItemWords` | none |
| PV07 | Source list is itself private-named; copy to a plain name | Receipt "Private list, Lisbon, new list."; summary "Copied Private list to Private list, Lisbon" | traced, code (`sourceName` uses `shownName`); no test | `copy_privateSourceNameIsMaskedInReceipt` | Core adds test |
| PV08 | Typed copy name is private (a medicine or a rent amount in the name) | Receipt "Private list, new list."; summary has no walled word | traced, test (`aPrivateNameIsNeverInTheLine`) | `copy_privateNameIsNeverInTheLine` (exists) | none |
| PV09 | Both source and typed name private | "Private list, new list." | inferred (both go through the same two masks) | `copy_bothNamesPrivateBothMasked` | Core adds test |
| PV10 | Repeat of a private-named existing list | "Private list, already a list", from the existing list's title, not the typed one | traced, code (`receipt(in:output:)` uses `shownName(of: output)`) | `copy_repeatOfPrivateListIsMasked` | Core adds test |
| PV11 | Op log payload: `.create(title:)` for the copied private row and for a private-named copy | The raw words appear in the op payload, as they already do for the original `AddListItem` | traced, code (`Transaction.create` stores the raw title). Whether this counts as a leak is not ruled: the words are on the phone either way | `copy_opPayloadHoldsRawTitleAsTheSourceDoes` (assert the current truth; `.disabled("op-log payload ruling")` for the strict version) | Kitchen lead to rule: "op log" means summary and receipt only, or also the payload; Core builds whichever is ruled |
| PV12 | Op record strings (`summary`, `receipt`) never hold a private row title or a private name | Pass for item words; pass for names via masks | traced, test for names (PV08), traced, code for items | `copy_opRecordStringsAreClean` (loop `engine.history` and assert no walled word, as `everyListLineMasksAPrivateListName` does) | Core adds test |
| PV13 | Day log line for a copy with a private typed name | Must read "New list: Private list" | gap, traced: `DayStory.title(of:)` returns the raw list title (`DayStory.swift:474-482`); only cook and recipe titles are masked, and `aCopiedListIsANewListLine` uses a plain name. The same hole exists for `createList` | `dayStory_copiedPrivateListReadsPrivateList` | Core (also fixes `createList`) |
| PV14 | Section name that holds a private word on a copied row | Section is copied verbatim, as on the source; no receipt prints it | inferred (receipts never print sections) | `copy_sectionWordsNeverReachReceipt` | Core adds test; Kitchen lead to say whether section labels need a mask |
| PV15 | Copy of a list with a private item, then Tess is asked "what's on Lisbon" or the count | Count may be said ("3 things"); words never | inferred (the Tess reading path is outside CopyList; `decisions.md` 6:06 AM Oct 17 allows counts and hides names) | `copy_tessCountsPrivateRowsHidesWords` | Core adds test |

## C. Name collisions

`CreateList.existing(named:)` is the one rule: trim, lowercase, live lists only, oldest first, built-in Groceries counts as a list.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| NC01 | Copy named exactly like an existing list | Nothing copied, the existing list returned, no ops, receipt "Lisbon, already a list" | traced, test (`aTakenNameOpensThatListAndGroceriesCannotBeCopied`) | `copy_takenNameOpensThatList` (exists) | none |
| NC02 | Same name, different case ("lisbon" vs "Lisbon") | Same as NC01 | traced, test (the test types "lisbon") | same | none |
| NC03 | Same name with leading and trailing spaces or newlines | Same as NC01 | traced, code (`trimmingCharacters(.whitespacesAndNewlines)`) | `copy_takenNameIgnoresOuterWhitespace` | Core adds test |
| NC04 | Same name but double space inside ("Gym  bag" vs "Gym bag") | Master treats it as a different name and makes a second list | traced, code (only outer whitespace is trimmed; no inner collapse). Not ruled in docs | `copy_innerWhitespaceIsADifferentName` (current truth) | Kitchen lead to rule collapse or not; Core builds the same rule in `CreateList` |
| NC05 | Same name with a non-breaking space (U+00A0) at the end | Treated as whitespace and trimmed | traced, code (U+00A0 is in `.whitespacesAndNewlines`) | `copy_nonBreakingSpaceIsTrimmed` | Core adds test |
| NC06 | Accented or width variants ("Cafe" vs a name with an accent) | Different names today (lowercased only, no folding) | traced, code | `copy_accentIsADifferentName` (current truth) | Kitchen lead to rule |
| NC07 | Empty name | Throws "the copy needs a name"; nothing written | traced, test (`"  "` in `aTakenName...`) | `copy_emptyNameRefuses` | none |
| NC08 | Whitespace-only name, and a newline-only name | Same as NC07 | traced, code | `copy_blankNamesRefuse` | Core adds test for the newline |
| NC09 | Copy named "Groceries" in any case or spacing ("  GROCERIES ") | Throws "Groceries can't be copied"; nothing written | traced, test for exact case; traced, code for the rest | `copy_groceriesNameRefusesInAnyCase` | Core adds test |
| NC10 | Source is Groceries | Throws; nothing written | traced, test | `copy_groceriesSourceRefuses` (exists) | none |
| NC11 | Copy of a copy (Packing to Lisbon, then Lisbon to Porto) | Porto has Lisbon's rows, all open; source chain untouched; receipt "Packing, Lisbon, Porto, new list." | inferred (a copy is an ordinary list; nothing records parentage) | `copy_ofACopyIsAnOrdinaryCopy` | Core adds test |
| NC12 | Copy named like its own source | "Packing, already a list"; no new list | traced, code (the source is found by `existing`) | `copy_namedLikeSourceReturnsSource` | Core adds test |
| NC13 | Name matches a deleted list | A new list is made; the deleted one does not count | traced, test for CreateList (`deletedListNameCanBeMadeAgain`); traced, code for CopyList (same lookup) | `copy_deletedListNameIsFree` | Core adds test |
| NC14 | Two live lists already share a title (older data, or a rename) and a copy is named like them | The oldest is returned, "already a list" | traced, code (`first` on oldest-first) | `copy_duplicateTitlesReturnTheOldest` | Kitchen lead: is the oldest right, or should it refuse like `list(named:)`? Core builds the ruling |
| NC15 | Rename a list into a taken name | Not part of CopyList. I did not find a guard in `RenameObject` for list names | could not trace | `renameList_intoTakenNameRefuses` | Core to check; Kitchen lead to rule |
| NC16 | Copy whose name differs from an existing one only by a trailing period or comma | Different names | inferred (no punctuation stripping) | `copy_punctuationIsADifferentName` | none |
| NC17 | "Packing, Lisbon" style name (a comma in it) | Stored as typed; both receipt and Now line print it whole | inferred (no parsing of names) | `copy_nameWithCommaIsKeptWhole` | Core adds test |

## D. The G40 ambiguity: what "the source" means

G40 (`kitchen-gap-hunt-7.md`, `kitchen-lists-screen-walk-oct17.md` section 9, `decisions.md` 8:40 AM Oct 17 item 5): a name that matches two lists writes nothing and Tess says "More than one list like trip." An exact name wins only when exactly one list has it; a prefix needs 3 or more letters and exactly one match; a one- or two-letter prefix never matches. The resolver is `TessTools.Call.list(named:)` (`TessTools.swift:330-349`); `ListLookupLine.moreThanOne` is the shared wording; `ListLookupTests.swift` pins it for add-to-list. `CopyList` itself never sees a name for the source, so G40 is a resolver question for the future phrase "copy packing for lisbon", not an engine one.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| G4001 | Two lists titled "Packing"; "copy packing for lisbon" | Refuse: "More than one list like packing."; nothing copied; no new list | resolver traced, test for add (`twoListsWithTheSameNameRefuse`); the copy phrase does not exist | `copyPhrase_twoSameNameSourcesRefuse` | Core (grammar case + resolver call); Builder B has no part |
| G4002 | Exact title matches exactly one list but another list starts with the same words ("Trip", "Trip 2025") | The exact one is the source | resolver traced, test (`exactNameWinsWhenItIsOneList`) | `copyPhrase_exactNameWinsWhenOne` | Core |
| G4003 | "pack" with "Packing" and "Packing, Lisbon" | Ask which. Two wordings are in the docs: the engine line "More than one list like pack." (ruled 8:40 AM) and the Bar question "Packing, or Packing, Lisbon?" (ruled 12:38 PM Oct 16, L8-26). They conflict | resolver gives the first wording (traced, test `twoPrefixMatchesRefuse`) | `copyPhrase_prefixTwoMatchesAsks` | Kitchen lead to pick one wording and say it in `decisions.md`; Core builds |
| G4004 | One- or two-letter source name ("p", "pa") | "no list called p"; nothing copied | resolver traced, test (`shortPrefixNeverMatches`) | `copyPhrase_shortPrefixNeverMatches` | Core |
| G4005 | The source is the running list (a process is open) | It is a valid source; the copy is plain, not running; the source's Now line is unchanged and no ops touch the source | traced, code (`CopyList` reads no process and writes only to new objects) | `copy_ofRunningListLeavesRunUntouched` | Core adds test |
| G4006 | The source is paused (suspended into the ledger, rows kept) | Valid source; the copy has no process; the source stays suspended | traced, code | `copy_ofPausedListLeavesLedgerUntouched` | Core adds test |
| G4007 | The source is put away (finished plain list, process in Later, rows all checked) | Valid source; all rows copy as open; the source stays put away and its rows stay checked | traced, code (put away is a process state; the list object is live) | `copy_ofPutAwayListCopiesRowsOpen` | Core adds test; Kitchen lead to say whether "copy a put-away list" is the main trip-list use (it reads that way in G9) |
| G4008 | Two lists share a name and one is running, one paused, one put away | The resolver does not prefer by state; it asks (G40). A rule "the running one wins" is not in any doc | resolver traced, code (`list(named:)` ignores state) | `copyPhrase_stateNeverBreaksATie` | Kitchen lead to rule: should the running list win a tie? Default: no, ask |
| G4009 | A put-away list is the only prefix match | It matches (put-away lists are live lists) | traced, code (`lists()` returns all live lists) | `copyPhrase_putAwayListCanBeTheSource` | Kitchen lead to confirm |
| G4010 | A deleted list with the same name | Not a candidate | resolver traced, code (`lists()` skips deleted) | `copyPhrase_deletedListIsNotASource` | Core adds test |
| G4011 | Source resolves to Groceries ("copy groceries for party") | "Groceries can't be copied" from the engine; the resolver returns the built-in for the word groceries | traced, code on both halves | `copyPhrase_groceriesSourceSaysCannotCopy` | Core; Kitchen lead to word the line (no ruled words found) |
| G4012 | Typed source name is a private word | The refusal never echoes it ("that") | resolver traced, test (`refusalNamesNoPrivateWord`) | `copyPhrase_refusalEchoesNoPrivateWord` | Core |
| G4013 | Source id of a deleted list (a stale screen) | Throws `objectNotFound`; nothing written | traced, code (`Transaction.object` checks `isDeleted`) | `copy_staleSourceIdRefuses` | Core adds test |
| G4014 | Source id of a non-list object | Throws `wrongClass` | traced, code | `copy_nonListSourceRefuses` | Core adds test |
| G4015 | Naming of the copy from "copy packing for lisbon": "Lisbon" or "Packing, Lisbon" | Not decided in code. `decisions.md` 12:38 PM says the receipt is "Packing, Lisbon, new list.."; `lists-slice-8-phrases.md` L8-22 and `lists-day-one.md` R15 expect the new list to be named "Packing, Lisbon". These disagree | gap: no grammar | `copyPhrase_namesTheCopyPerRuling` (disabled until ruled) | Kitchen lead to rule; Core builds |

## E. The three starter lists

Starter content per `starter-lists.md`: Gym bag (three sections, 10 items), Leaving the house (6 items, no sections), Packing (three sections, 11 items). All three are reusable, user-deletable and never reinstalled once deleted. `lists-day-one.md` R2 asks for US words (adapter, pants, sweater), which the doc now uses.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| ST01 | First launch | Groceries plus the 3 starters exist; the three are flagged reusable; counts 10, 6, 11 | gap: `StarterContent.installIfNeeded` seeds the plan, routines and kit only (`StarterContent.swift`) | `starters_installOnFirstLaunch` | Core |
| ST02 | Install twice (relaunch) | Nothing added; still 3 | gap (not built); the plan install already has this shape (`firstLaunchHasHisPlanAndKit` ends with a second `installIfNeeded == false`) | `starters_installOnce` | Core |
| ST03 | Delete a starter, relaunch | It stays deleted | gap (not built) | `starters_deletedStayDeleted` | Core (needs a marker that survives the delete, as the plan does with its stable id) |
| ST04 | Delete all three, then make Films | Shelf shows Groceries and Films; starters do not return | gap (not built; R32) | `starters_allDeletedThenNewListKeepsThemGone` | Core |
| ST05 | Starter ids are stable | Same ids on every device and run (`SystemCatalog.stableID("starter.list.packing")` style), so a restore does not duplicate | gap; the plan uses `stableID("starter.plan.ppl2")` | `starters_haveStableIDs` | Core |
| ST06 | Copy Packing twice with different names ("Lisbon", then "Porto") | Two independent lists, each with 11 open rows; Packing untouched | inferred (a copy is an ordinary list); blocked on ST01 | `starters_copyPackingTwiceWithTwoNames` | Core |
| ST07 | Copy Packing twice with the same name | The second copy returns the first copy, "Lisbon, already a list"; no third list; 11 rows, not 22 | traced, code (NC01 path) | `starters_copyPackingTwiceSameNameDoesNotDouble` | Core |
| ST08 | Copy Packing to the name "Packing" (its own name) | "Packing, already a list" | traced, code (NC12) | `starters_copyPackingToItsOwnName` | none |
| ST09 | Copy a starter after the user checked some rows | The copy is all open; the starter keeps its checks (reusable: reset is separate) | traced, code | `starters_copyIsOpenWhateverTheSourceChecked` | Core adds test |
| ST10 | Copy Packing keeps the section words | Copy has CLOTHES, TECH, PAPERS as sections on the same rows; `sections(of:)` order is Clothes, Tech, Papers | traced, code (`section` field copies when the item owns one) | `starters_copyKeepsSectionOrder` | Core adds test (needs ST01 first) |
| ST11 | Copy a starter then edit the copy (add, check, reset) | The starter is never changed | traced, code (no link between copy and source) | `starters_editingACopyNeverTouchesTheStarter` | Core adds test |
| ST12 | Copy of a starter is not reusable-by-accident when the user switched the starter to plain | Copy follows the source's flag at copy time | traced, test for the rule (`flagsDoNotCopyExceptReusable`) | `starters_copyFollowsTheFlagAtCopyTime` | none |
| ST13 | A user-made list with a starter's name ("Packing") made before the install lands | The install must not make a second "Packing" (CreateList rule: the name is taken); the starter is skipped or merged | gap (not built; install must use `CreateList.existing`) | `starters_skipWhenNameAlreadyTaken` | Kitchen lead to rule skip or merge; Core builds |
| ST14 | Starter item "headphones" appears on both Gym bag and Packing | Both stay (separate lists) | traced, code (no cross-list de-dup) | `starters_sameItemOnTwoListsIsFine` | none |
| ST15 | Starter words are US (adapter, pants, sweater) | The seed uses them | gap (not built); `lists-day-one.md` R2 asks for it and `starter-lists.md` now holds them | `starters_useUSWords` | Core |
| ST16 | The starters contain no private-shaped text | Wall check passes on every seed line | inferred (the seed text has no medicine, money or secret word) | `starters_seedLinesPassTheWall` | Core adds test |
| ST17 | Backup then restore with a deleted starter | The deleted starter stays deleted | inferred (depends on how the marker is stored, ST03) | `starters_restoreKeepsDeletedStartersDeleted` | Core |
| ST18 | Day log on first launch | No "New list:" lines for the seeds | inferred (the plan seed writes no op record; a list seed must do the same) | `starters_writeNoDayLogLines` | Core |

## F. The UNDO window for a copy

Rules from `decisions.md` 1:35 PM Oct 16: new thing 4 s, change 10 s, VoiceOver 10 s flat, paused in the background; one slot, a newer claim closes the older; receipt "Thing, taken back." (1:48 PM). A copy makes a new list, so it is a "new thing": 4 s. A repeat name writes nothing, so there is no UNDO.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| UN01 | Copy made | The record has ops, so an UNDO key can exist; window 4 s | engine half traced, test (`engine.undo(copied.record)`); the window itself is not built (no `UndoWindow`, no `UndoSlot` in the tree) | `copy_isANewThingWindowIs4s` (pure `UndoWindow` test, once it exists) | Core (`UndoWindow`, 0s); Builder B (slot, 0i) |
| UN02 | VoiceOver on | 10 s | gap (not built) | `copy_undoWindowIs10sUnderVoiceOver` | Core, Builder B |
| UN03 | App backgrounded mid-window | Window pauses | gap (not built) | `copy_undoWindowPausesInBackground` | Builder B |
| UN04 | Repeat name ("already a list") | No ops, so no UNDO key; the line still shows | traced, test (`again.record.ops.isEmpty`) | `copy_repeatShowsNoUndo` | none; Builder B to read `ops.isEmpty` or `CopyList` outcome when it wires the slot |
| UN05 | Undo receipt wording | "Lisbon, taken back." (new thing) | gap: no code makes a "taken back" line for list actions (K36.2 is the open board item) | `copy_undoSaysTakenBack` | Core (words), Builder B (show) |
| UN06 | A second action inside the window (check an item, add an item) | The copy's UNDO closes; the newer claim owns the slot. The copy stays | gap (slot not built); engine side is independent | `copy_newerClaimClosesCopyUndo` | Builder B |
| UN07 | Undo after the window has closed, from the Day log or history | Not offered on the line; `engine.undo` on the record still works if called | traced, code (engine undo has no time limit) | `copy_engineUndoHasNoClock` | Kitchen lead to say if history-level undo is wanted |
| UN08 | Undo after the user edited the copy (added a row, checked one) | Undo removes the copy and its rows, including the user's later edits, or refuses | could not trace (depends on how `engine.undo` treats later ops on the same objects) | `copy_undoAfterEditsIsSafe` | Core to check and pin |
| UN09 | Undo a copy while a run is started on the copy | Run ends or is orphaned? Not ruled | could not trace | `copy_undoWhileCopyIsRunning` | Core and Kitchen lead |

## G. Thing-first receipt wording

Only literals found in source or in rulings are quoted. Periods are added by the voice layer (the Bar), not by the op receipt.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| RW01 | Made | Thing first: the new list, then "new list." ("Packing, Lisbon, new list.") | traced, test | `copy_receiptIsThingFirst` (exists, same test as CP01) | none |
| RW02 | Summary string (the history and Day log feed) | "Copied Packing to Packing, Lisbon" (verb first; the summary is the one non-thing-first form) | traced, test | same | Kitchen lead to confirm summary may stay verb first like "Reset Gym bag" |
| RW03 | Repeat | "<existing title>, already a list" | traced, test | `copy_repeatReceipt` (exists as part of NC01) | none |
| RW04 | Repeat prints the existing list's own title, not the typed one ("lisbon" typed, "Lisbon" shown) | Existing title (Design on #866) | traced, code (`receipt(in:output:)`) | `copy_repeatPrintsTheExistingTitle` | Core adds test (current test uses the typed-case path for the id and the receipt via `record`) |
| RW05 | Bar line for a copy | The Bar prints "X, new list." for create and "X, already a list." for a repeat; a copy has no Bar wiring | gap: no grammar case, no `TessCaptureEngine` branch for copy | `bar_copyLineIsThingFirst` | Core (grammar), Kitchen lead (words for the copy line) |
| RW06 | Day log line for a copy | "New list: Lisbon" (`ownLines["copyList"]`) | traced, test (`aCopiedListIsANewListLine`) | exists | Kitchen lead: this one is verb-first; decide whether the Day log keeps "New list:" for copies |
| RW07 | A copy receipt never says "template" | No string in `CopyList` contains it | traced, code (`lists-acceptance.md` 4c rule) | `copy_nothingSaysTemplate` | Core adds a grep-style test |
| RW08 | Context line after a copy | "N lists" counts the copy; no new "copied" state word | could not trace (the Lists screen is not built) | `listsContextLine_countsCopies` | Builder B |
| RW09 | Receipt when the source was renamed after the copy | The old text in the history stays as written at the time | inferred (history strings are stored at record time) | `copy_receiptIsStoredAtRecordTime` | none |

## H. Where this fixture does not reach

- The Lists screens (copy gesture, shelf, context line, the UNDO key on screen) are not built, so every on-screen expectation is a Builder B gap that cannot be pinned yet.
- No phrase reaches `CopyList` today, so Section D rows about phrases wait for a grammar case.
- `kitchen-v2-scope.md` and `ship-list-kitchen.md` contain no copy or starter rule; they are listed in the sources only because they were asked for. Slice 1 of `ship-list-kitchen.md` says the List class is the one M3's template instantiates, and slice 9 has "list: packing" only.

## Fixture skeleton Core can paste

```swift
import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct CopyListFixtureTests {
    let store = ObjectStore.open(inMemory: true)

    func setUp() throws -> (engine: ActionEngine, lists: ListContents, packing: ObjectRecord) {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let packing = try engine.perform(CreateList(name: "Packing"), by: .user).output
        for text in ["Socks", "Charger", "Passport"] {
            try engine.perform(AddListItem(list: packing.id, text: text), by: .user)
        }
        return (engine, ListContents(store: store, classes: classes), packing)
    }

    @Test func copy_ofACopyIsAnOrdinaryCopy() throws {
        let (engine, lists, packing) = try setUp()
        let lisbon = try engine.perform(CopyList(list: packing.id, name: "Lisbon"), by: .user).output
        let porto = try engine.perform(CopyList(list: lisbon.id, name: "Porto"), by: .user)
        #expect(lists.items(of: porto.output).map(\.text) == ["Socks", "Charger", "Passport"])
        #expect(porto.record.receipt == "Packing, Lisbon, Porto, new list.")
    }

    @Test func starters_copyPackingTwiceSameNameDoesNotDouble() throws {
        let (engine, lists, packing) = try setUp()
        let first = try engine.perform(CopyList(list: packing.id, name: "Lisbon"), by: .user).output
        let again = try engine.perform(CopyList(list: packing.id, name: " LISBON "), by: .user)
        #expect(again.output.id == first.id && again.record.ops.isEmpty)
        #expect(lists.items(of: first).count == 3)
    }
}
```

## Gaps by owner

- **Core**: the starter seed and its stable ids (ST01 to ST05, ST13, ST15, ST17, ST18); the copy phrase and its resolver call (G4001 to G4004, G4008 to G4012, RW05); the Day log mask for list titles (PV13); `UndoWindow` (UN01, UN02); missing tests marked "Core adds test"; NC15 and UN08/UN09 checks.
- **Builder B**: the UNDO slot and its clock (UN01 to UN03, UN06), the copy gesture and context line (RW08), reading "no ops means no UNDO" (UN04).
- **Kitchen lead** (rulings first, because Core cannot build around them): the op-log payload question (PV11); inner-whitespace and accent folding for list names (NC04, NC06); how to word the copy ambiguity (G4003); whether the running list wins a tie (G4008); the copy's name from "copy packing for lisbon" (G4015); skip or merge when a starter name is taken (ST13); the Day log verb for copies (RW06); whether a dated item's date copies (CP08); whether a section label needs a mask (PV14).

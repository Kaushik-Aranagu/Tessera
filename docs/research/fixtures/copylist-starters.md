# CopyList and the starter lists: fixture rows

For: Core (engine), Builder B (screens), Kitchen lead (words and rulings). Docs only; nothing run (no Swift toolchain here). Read on the checked-out master in /home/user/Tessera, then re-traced Oct 18 against master `962aa6cb` with #871 merged (`4a265e0e`). Nothing run.
Format follows `docs/research/fixtures/lists-fixtures.md` and `docs/research/fixtures/engine-wall.md`: one table per topic, a row id, the expected outcome, a Swift Testing name Core can paste, whether master already does it, and an owner for every gap.

Sources read: `TesseraCore/Sources/TesseraCore/Lists/ListReuse.swift` (CopyList, lines 120-224), `ListRuns.swift`, `Lists.swift` (CreateList, AddListItem), `Actions/ActionRegistry.swift`, `Actions/Transaction.swift`, `TesseraTess/TessTools.swift` (`list(named:)`, `ListLookupLine`), `TesseraTess/TessCaptureEngine.swift`, `DayLog/DayStory.swift`, tests `ListReuseTests.swift` (`CopyListTests`), `ListLookupTests.swift`, `DayStoryTests.swift`; docs `product/kitchen-v2-scope.md`, `product/ship-list-kitchen.md` (neither says anything about copying or starters; the Lists slices are in `ship-list-lists.md`, `lists-acceptance.md` 4c, `starter-lists.md`), `research/fixtures/lists-fixtures.md`, `lists-slice-8-phrases.md` (L8-22), `lists-day-one.md` (R1, R15), `product/decisions.md` (UNDO slot 1:35 PM Oct 16, copied-list line 12:38 PM Oct 16, G40 refusal 8:40 AM Oct 17), `product/kitchen-test-specs-wall-g40-g43-g44-oct17.md`.

## Rulings applied (Product, decisions 3:50 PM Oct 17)

These replace the earlier open questions; every row below is read with them.
1. **The copy's name** is "<source>, <typed name>": copying Packing as Lisbon makes "Packing, Lisbon". The old receipt "Lisbon, copied from Packing." is retired. The receipt is "Packing, Lisbon, new list." A copy of that copy typed Porto is "Packing, Lisbon, Porto" (receipt "Packing, Lisbon, Porto, new list."; ruled at decisions 4:00 PM: source title plus the word, no special case).
2. **Ambiguity** wording is the engine line "More than one list like pack." The Bar question "Packing, or Packing, Lisbon?" is retired (closes G4003).
3. **`DayStory.title(of:)` and summaries mask a private list ("Private list"); the op payload keeps the raw name** (Product, decisions 4:20 PM Oct 17, amends the 3:50 PM line: masking the log would break undo and restore). PV13 stays a Core build item (`dayStory_privateListTitleIsMasked`). PV11 is now ruled: the payload holds the raw title, anything the log shows him masks.
4. **Starters** install with Core's next Lists PR (closes the "not installed" gap on ST01 to ST05; the rows stay as acceptance for that PR).
5. Receipt and summary strings in the rows and the Swift skeleton are written to these rulings, not to what master prints. The 3:50 composition rule is built in #871 (merged), but in the Bar path, not in `CopyList`: `TessCaptureEngine.swift:431-436` passes "<source title>, <word>" to `CopyList`, which names the copy exactly as given. Rows say "via the phrase" or "engine alone" where the two differ. Rows where a name is private (PV07 to PV09) read "Private list, new list." and the private form is ruled (decisions 4:00 PM).

## How to read the status column

- **traced**: I read the code path (and the test, where one exists) and master does this today. "traced, test" means a test on master already pins it; "traced, code" means the code does it but no test asserts it.
- **inferred**: reasoned from neighbouring code or a doc ruling; I did not find the line that does it, or found nothing that contradicts it.
- **gap**: master does not behave this way. Every gap row names an owner: Core, Builder B or Kitchen lead.

## What exists on master (the facts every row rests on)

1. `CopyList(list: UUID, name: String)` is registered (`ActionRegistry.swift:20` and decoder `:80`), `isOfferedToModel: false` (`ListReuse.swift:131`), so Tess's model and Claude cannot call it. The Bar phrase reaches it: grammar case `TessGrammar+Kitchen.swift:40-52` (only when the source names a list, never from Siri or Shortcuts via `commitImmediately`), run at `TessCaptureEngine.swift:431-437`. `TesseraRuntime.swift:73` still lists it as "in-app only for now". No screen calls it. Tests and `perform(named:)` also reach it.
2. It takes the source by id (`transaction.object(list, is: .list)`), so the engine itself never has a name ambiguity. A deleted or non-list id throws.
3. Order of checks in `apply`: empty trimmed name throws "the copy needs a name"; source is Groceries or name lowercases to "groceries" throws "Groceries can't be copied"; then a name with a secret word or a key throws "that can't be a list name" (`ListReuse.swift:184-187`); then `CreateList.existing(named:)` (trim, lowercase, live lists only, oldest first, built-in Groceries counts); a hit returns that list with nothing written ("already a list"); otherwise create the list, copy the reusable flag only when the source has it, then each child in order with `quantity` and `section` (only values the item owns) and its notes with the `#reusable`, `#pick-one` and `picked:` lines removed.
4. Not copied: checked state and `checkedAt` (the new rows are open), links such as `about`, the source's run state or process, the pick stamp, the source's own other note lines (they are not copied at all, only flags decide `reusable`; the list-level notes are never copied).
5. Words: `CopyList` names the copy exactly as given (no composition in the engine) and prints receipt "<name>, new list" (`ListReuse.swift:237-247`) and summary "Copied <source> to <name>" (`:228-231`), asserted by `aCopyHasTheSameItemsAllOpenAndTheOriginalStays` (`ListReuseTests.swift:290-291`: "Lisbon, new list", "Copied Packing to Lisbon"). "Lisbon, copied from Packing" is gone. A repeat prints "<existing title>, already a list" and summary "Opened <title>" (`:233-235`). The typed name is shown as "Private list" when `ObjectPrivacy.isPrivateWord` says so; the source name goes through `ListContents.shownName` (`ListRuns.swift:19-21`). The phrase composes the name first (`TessCaptureEngine.swift:435`), so via the phrase the copy is "Packing, Lisbon", receipt "Packing, Lisbon, new list" with the period added by the Bar (`:437`), and the collision check in item 3 runs on the composed name.
6. Item titles are stored in the user's words. The mask is applied when a line is printed (`AddListItem.shownTitle` gives "Private item" for a medicine or body fact). Money and secret lines never become items (they reroute to a private note at `AddListItem.apply`), so the only private rows a source can hold are medicine and body-fact items.
7. The op log: `Transaction.create` appends `.create(object:classID:parent:title:)` with the raw title (`Transaction.swift:34-38`), for the new list and for every copied row. `OpRecord.summary` and `.receipt` are separate strings and are masked.
8. The Day log: `copyList` has the line "New list:" (`DayStory.swift:91`) and `DayStory.title(of:)` masks a list with a walled name as "Private list" (`DayStory.swift:481-483`).
9. The starter lists (Gym bag 10 items, Leaving the house 6, Packing 11) are built: `StarterLists.swift:16-35` (data) and `:36-70` (`installIfNeeded`, once by stable id, a deleted one stays gone, a list he already named is skipped and marked handled). The app seeds them at launch only (`AppModel.swift:190-191`, `TesseraApp.swift:27`); a test store has none until it asks. Item text is installed lowercase as in `starter-lists.md` (no capitalization step), asserted by `StarterListsTests.swift:21`.
10. UNDO window (`decisions.md` 1:35 PM Oct 16): one UNDO slot; 4 s for a new thing, 10 s for a change, 10 s for everything under VoiceOver, paused in the background; the undo receipt is "Thing, taken back." The `UndoWindow` type (Core 0s) and `UndoSlot` (Builder B 0i) are not in the tree (`Features/Home/HomeQueue.swift:44` only mentions the VoiceOver rule in a comment). The engine's `undo(_:)` and `redo(_:)` work on records.

## A. The plain copy

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| CP01 | Copy Packing (two items, one checked, one with quantity, one with section) to a new name | Same items in the same order, all open, quantity and section kept; the source untouched (checked item still checked). Items and source part: traced, test. The copy is named "Packing, Lisbon" with receipt "Packing, Lisbon, new list." and summary "Copied Packing to Packing, Lisbon" (3:50) | items part traced, test (`aCopyHasTheSameItemsAllOpenAndTheOriginalStays`); name, receipt and summary: matches via the phrase (`copyPackingForLisbonMakesTheTripList`, `StarterListsTests.swift:42-46`: "Packing, Lisbon, new list.", 11 open items); drifted for the engine alone: `CopyList(name: "Lisbon")` names it "Lisbon" and prints "Lisbon, new list" / "Copied Packing to Lisbon" (`ListReuseTests.swift:290-291`) | `copy_keepsItemsOpenAndSourceUntouched` (exists, engine form); `copyPackingForLisbonMakesTheTripList` (exists, phrase form) | none |
| CP02 | Copy is one op record | `engine.history` grows by exactly 1 | traced, code (one `perform`, one record); no test counts it | `copy_isOneOpRecord` | Core adds test |
| CP03 | Undo the copy | The new list and all its rows are gone; the source is unchanged | traced, test (same test, `engine.undo`, asserts the title is gone; does not assert the rows) | `copy_undoRemovesListAndRows` | Core adds the row assertion |
| CP04 | Redo after undo | The copy comes back with its rows, all open | inferred (redo exists for other actions; nothing runs it for a copy) | `copy_redoBringsItBack` | Core adds test |
| CP05 | Source is a reusable list | The copy is reusable (`#reusable` line only); `#pick-one` and `picked:` do not copy; the source's other note lines on the list are not copied | traced, test (`flagsDoNotCopyExceptReusable`) | `copy_reusableFlagCopiesPickStampDoesNot` (exists) | none |
| CP06 | Source is a plain list | The copy is plain | traced, test (same test, `Errands 2`) | same | none |
| CP07 | Source item has a note with a user line plus `#pick-one` and a `picked:` stamp | The copy keeps only the user line | traced, test (same test; note equals "the blue one") | same | none |
| CP08 | Source has an item with `about` links (a recipe or a dated item) | Links and dates do not carry to the copy; the copy's rows are plain | traced, code (only `quantity`, `section`, `notes` are copied) | `copy_doesNotCarryLinksOrDates` | Kitchen lead to confirm that a dated item's date should not copy (rule not found in docs) |
| CP09 | Copy an empty list (no rows) | A new empty list is made, receipt "<source>, <word>, new list." | inferred (loop runs zero times; no guard) | `copy_ofEmptyListMakesEmptyList` | Core adds test; Kitchen lead to say if "copied" is right for an empty one |
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
| PV07 | Source list is itself private-named; copy to a plain name | Receipt "Private list, new list." (decisions 4:00 PM: the composed title holds the private word, so the whole name reads "Private list", thing first like "Private item, on Groceries."); summary "Copied Private list to Private list"; no walled word in either | matches via the phrase (`copyingAPrivateListIsMaskedInTheLogAndTheDay`, `StarterListsTests.swift:81-87`: "Private list, new list."; the composed title holds the private word). Engine alone with a plain word prints "Lisbon, new list" and "Copied Private list to Lisbon" (`sourceName`, `ListReuse.swift:223-226`) | `copy_privateSourceNameIsMaskedInReceipt` (phrase form exists) | none |
| PV08 | Typed copy name is private (a medicine or a rent amount in the name) | Receipt "Private list, new list."; summary has no walled word | traced, test (`aPrivateNameIsNeverInTheLine`) | `copy_privateNameIsNeverInTheLine` (exists) | none |
| PV09 | Both source and typed name private | "Private list, new list." | inferred (both go through the same two masks) | `copy_bothNamesPrivateBothMasked` | Core adds test |
| PV10 | Repeat of a private-named existing list | "Private list, already a list", from the existing list's title, not the typed one | traced, code (`receipt(in:output:)` uses `shownName(of: output)`) | `copy_repeatOfPrivateListIsMasked` | Core adds test |
| PV11 | Op log payload: `.create(title:)` for the copied private row and for a private-named copy | Payload keeps the raw title (ruled 4:20 PM Oct 17: masking it would break undo and restore); summary, receipt and Day log read "Private list" / "Private item" | traced, code (`Transaction.create` stores the raw title) | `copy_opPayloadKeepsRawTitleWhileSummaryAndReceiptMask` | Core adds test |
| PV12 | Op record strings (`summary`, `receipt`) never hold a private row title or a private name | Pass for item words; pass for names via masks | traced, test for names (PV08), traced, code for items | `copy_opRecordStringsAreClean` (loop `engine.history` and assert no walled word, as `everyListLineMasksAPrivateListName` does) | Core adds test |
| PV13 | Day log line for a copy with a private typed name | Must read "New list: Private list" | matches: `DayStory.title(of:)` masks a walled list name (`DayStory.swift:481-483`), pinned by `aCopiedPrivateListIsPrivateInTheDay` (`DayStoryTests.swift:295-302`: "New list: Private list") | `aCopiedPrivateListIsPrivateInTheDay` (exists) | none |
| PV14 | Section name that holds a private word on a copied row | Section is copied verbatim, as on the source; no receipt prints it | inferred (receipts never print sections) | `copy_sectionWordsNeverReachReceipt` | Core adds test; Kitchen lead to say whether section labels need a mask |
| PV15 | Copy of a list with a private item, then Tess is asked "what's on Lisbon" or the count | Count may be said ("3 things"); words never | inferred (the Tess reading path is outside CopyList; `decisions.md` 6:06 AM Oct 17 allows counts and hides names) | `copy_tessCountsPrivateRowsHidesWords` | Core adds test |

## C. Name collisions

`CreateList.existing(named:)` is the one rule: trim, lowercase, live lists only, oldest first, built-in Groceries counts as a list.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| NC01 | Composed name equals an existing list (Packing and "Packing, Lisbon" exist; copy Packing as "Lisbon") | Nothing copied, the existing "Packing, Lisbon" returned, no ops, receipt "Packing, Lisbon, already a list". The check is on the composed name, not the typed word | matches via the phrase: the engine checks the name it is given (`ListReuse.swift:191`) and the phrase gives it the composed name (`TessCaptureEngine.swift:435`), pinned by `StarterListsTests.swift:48-50` ("Packing, Lisbon, already a list."; one such list). The engine-alone test still checks the typed word (`ListReuseTests.swift:301-306`: "lisbon" opens a list "Lisbon") | `copy_takenComposedNameOpensThatList` (phrase form exists) | none |
| NC02 | Same composed name, different case (word "lisbon" vs existing "Packing, Lisbon") | Same as NC01 | matches via the phrase (`existing` lowercases, `ListReuse.swift:191`; the repeat test uses "lisbon" against "Lisbon" for the engine alone, `ListReuseTests.swift:301-306`); no phrase test with a different case | same | none |
| NC03 | Word with leading and trailing spaces or newlines (" Lisbon\n") | Trimmed before composing, so the composed name is "Packing, Lisbon" and it repeats as NC01 | traced, code for the trim (`ListReuse.swift:178`; the grammar also trims the word, `TessGrammar+Kitchen.swift:46-47`); the composed check is matches via the phrase (NC01); no test | `copy_takenNameIgnoresOuterWhitespace` | Core adds test |
| NC04 | Same name but double space inside ("Gym  bag" vs "Gym bag") | Master treats it as a different name and makes a second list | traced, code (only outer whitespace is trimmed; no inner collapse). Not ruled in docs | `copy_innerWhitespaceIsADifferentName` (current truth) | Kitchen lead to rule collapse or not; Core builds the same rule in `CreateList` |
| NC05 | Same name with a non-breaking space (U+00A0) at the end | Treated as whitespace and trimmed | traced, code (U+00A0 is in `.whitespacesAndNewlines`) | `copy_nonBreakingSpaceIsTrimmed` | Core adds test |
| NC06 | Accented or width variants ("Cafe" vs a name with an accent) | Different names today (lowercased only, no folding) | traced, code | `copy_accentIsADifferentName` (current truth) | Kitchen lead to rule |
| NC07 | Empty name | Throws "the copy needs a name"; nothing written | traced, test (`"  "` in `aTakenName...`) | `copy_emptyNameRefuses` | none |
| NC08 | Whitespace-only name, and a newline-only name | Same as NC07 | traced, code | `copy_blankNamesRefuse` | Core adds test for the newline |
| NC09 | Copy of the source "Groceries" (any case or spacing) | Throws "Groceries can't be copied"; nothing written. Ruled (Product, Oct 17): the guard bites on the SOURCE only (Groceries has its own shop and recurring items) | traced, test for exact case; traced, code for the rest | `copy_groceriesSourceRefusesInAnyCase` | Core adds test |
| NC09b | Copy of Packing with the typed word "Groceries" | Allowed: the name is "Packing, Groceries", a normal list; receipt "Packing, Groceries, new list." | inferred (composed name, ruled) | `copy_typedWordGroceriesIsAllowed` | Core adds test |
| NC10 | Source is Groceries | Throws; nothing written | traced, test | `copy_groceriesSourceRefuses` (exists) | none |
| NC11 | Copy of a copy (Packing to Lisbon, then "Packing, Lisbon" to Porto) | The new list is "Packing, Lisbon, Porto" with Lisbon's rows, all open; source chain untouched; receipt "Packing, Lisbon, Porto, new list." (4:00 PM: source title plus the word, no special case) | traced, code via the phrase (`TessCaptureEngine.swift:433-435` composes from the source's full title, so "Packing, Lisbon, Porto"; an exact title wins when exactly one list has it, `TessTools.swift:386-388`); engine alone prints "Porto, new list"; no test; rows part inferred (a copy is an ordinary list; nothing records parentage) | `copy_ofACopyIsAnOrdinaryCopy` | Core adds test |
| NC12 | Copy whose word equals its source's name (Packing copied as "Packing") | Not a repeat: the composed name is "Packing, Packing", a new list with Packing's rows, receipt "Packing, Packing, new list." | matches via the phrase, traced, code (composed "Packing, Packing" is not an existing title); drifted for the engine alone: `CopyList(name: "Packing")` returns the source with "Packing, already a list" and writes nothing (`ListReuse.swift:191`); no test | `copy_wordEqualToSourceMakesPackingPacking` | Core adds test |
| NC13 | Name matches a deleted list | A new list is made; the deleted one does not count | traced, test for CreateList (`deletedListNameCanBeMadeAgain`); traced, code for CopyList (same lookup) | `copy_deletedListNameIsFree` | Core adds test |
| NC14 | Two live lists already share a title (older data, or a rename) and a copy is named like them | The oldest is returned, "already a list" | traced, code (`first` on oldest-first) | `copy_duplicateTitlesReturnTheOldest` | Kitchen lead: is the oldest right, or should it refuse like `list(named:)`? Core builds the ruling |
| NC15 | Rename a list into a taken name | Not part of CopyList. I did not find a guard in `RenameObject` for list names | could not trace | `renameList_intoTakenNameRefuses` | Core to check; Kitchen lead to rule |
| NC16 | Copy whose name differs from an existing one only by a trailing period or comma | Different names | inferred (no punctuation stripping) | `copy_punctuationIsADifferentName` | none |
| NC17 | "Packing, Lisbon" style name (a comma in it) | Stored as typed; both receipt and Now line print it whole | inferred (no parsing of names) | `copy_nameWithCommaIsKeptWhole` | Core adds test |

## D. The G40 ambiguity: what "the source" means

G40 (`kitchen-gap-hunt-7.md`, `kitchen-lists-screen-walk-oct17.md` section 9, `decisions.md` 8:40 AM Oct 17 item 5): a name that matches two lists writes nothing and Tess says "More than one list like trip." An exact name wins only when exactly one list has it; a prefix needs 3 or more letters and exactly one match; a one- or two-letter prefix never matches. The resolver is `TessTools.Call.list(named:)` (`TessTools.swift:330-349`); `ListLookupLine.moreThanOne` is the shared wording; `ListLookupTests.swift` pins it for add-to-list. `CopyList` itself never sees a name for the source, so G40 is a resolver question for the phrase "copy packing for lisbon", which is wired (`TessGrammar+Kitchen.swift:18-27` lets a two-match source through, `TessCaptureEngine.swift:433` resolves it), not an engine one.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| G4001 | Two lists titled "Packing"; "copy packing for lisbon" | Refuse: "More than one list like packing."; nothing copied; no new list | matches: resolver traced, test for add (`twoListsWithTheSameNameRefuse`); the copy phrase is wired (`TessTools.swift:389-391`, `TessCaptureEngine.swift:433`); the phrase test uses two prefix matches, not two same-name lists (`StarterListsTests.swift:53-61`) | `copyPhrase_twoSameNameSourcesRefuse` | Core adds the same-name phrase test |
| G4002 | Exact title matches exactly one list but another list starts with the same words ("Trip", "Trip 2025") | The exact one is the source | matches: resolver traced, test (`exactNameWinsWhenItIsOneList`); phrase wired | `copyPhrase_exactNameWinsWhenOne` | none |
| G4003 | "pack" with "Packing" and "Packing, Lisbon" | Refuse with the engine line "More than one list like pack."; nothing copied. CLOSED, ruled at decisions 3:50 PM Oct 17: the G40 line is the wording and the Bar question "Packing, or Packing, Lisbon?" (L8-26) is retired, with no pick-from-two sentence | matches: resolver (`twoPrefixMatchesRefuse`) and the phrase (`aSourceThatMatchesTwoListsWritesNothing`, `StarterListsTests.swift:60-61`: "More than one list like trip.", no records) | `copyPhrase_prefixTwoMatchesAsks` (exists) | none |
| G4004 | One- or two-letter source name ("p", "pa") | Not a list phrase: read as before (a task or a miss), never "no list called p"; nothing copied | drifted from the old expected line: `namesAList` is false for a no-match (`TessGrammar+Kitchen.swift:18-27`), so the phrase falls through (`StarterListsTests.swift:62-64` pins that for "costco"); resolver itself traced, test (`shortPrefixNeverMatches`) | `copyPhrase_shortPrefixNeverMatches` | Core |
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
| G4015 | Naming of the copy from "copy packing for lisbon" | The new list is named "Packing, Lisbon" (source, then the word he gave) with receipt "Packing, Lisbon, new list.". CLOSED, ruled at decisions 3:50 PM Oct 17; matches L8-22 and R15, and the old "Lisbon, copied from Packing." is retired | matches: grammar case `TessGrammar+Kitchen.swift:44-51`, composition at `TessCaptureEngine.swift:435`, pinned by `StarterListsTests.swift:42-43` | `copyPackingForLisbonMakesTheTripList` (exists) | none |

## E. The three starter lists

Starter content per `starter-lists.md`: Gym bag (three sections, 10 items), Leaving the house (6 items, no sections), Packing (three sections, 11 items). All three are reusable, user-deletable and never reinstalled once deleted. `lists-day-one.md` R2 asks for US words (adapter, pants, sweater), which the doc now uses.

| Row | Case | Expected | On master | Swift Testing name | Gap owner |
|---|---|---|---|---|---|
| ST01 | First launch | Groceries plus the 3 starters exist; the three are flagged reusable; counts 10, 6, 11 | matches, test (`StarterLists.swift:16-35`, `theThreeStartersInstallOnceAndStayDeleted`) | `theThreeStartersInstallOnceAndStayDeleted` (exists, `StarterListsTests.swift:11-30`) | none |
| ST02 | Install twice (relaunch) | Nothing added; still 3 | matches, test (`StarterListsTests.swift:25`: second call returns 0) | same | none |
| ST03 | Delete a starter, relaunch | It stays deleted | matches, test (`StarterListsTests.swift:26-29`; a deleted starter is still found by id, `StarterLists.swift:44`) | same | none |
| ST04 | Delete all three, then make Films | Shelf shows Groceries and Films; starters do not return | traced, code (same marker as ST03); no all-three test | `starters_allDeletedThenNewListKeepsThemGone` | Core adds test |
| ST05 | Starter ids are stable | Same ids on every device and run (`SystemCatalog.stableID("starter.list.packing")` style), so a restore does not duplicate | matches, traced, code (`StarterLists.swift:32-34`, `stableID("starter.list.<key>")`); no test compares ids | `starters_haveStableIDs` | Core adds test |
| ST06 | Copy Packing twice with different names ("Lisbon", then "Porto") | Two independent lists, each with 11 open rows; Packing untouched | inferred (a copy is an ordinary list); ST01 is built; no test | `starters_copyPackingTwiceWithTwoNames` | Core adds test |
| ST07 | Copy Packing twice with the same word | The second copy returns the first copy "Packing, Lisbon", receipt "Packing, Lisbon, already a list"; no third list; 11 rows, not 22 | matches via the phrase (`StarterListsTests.swift:47-50`: "Packing, Lisbon, already a list.", one such list; 11 rows asserted on the first copy, `:46`) | `copyPackingForLisbonMakesTheTripList` (exists); skeleton test below is engine form | none |
| ST08 | Copy Packing with the word "Packing" (its own name) | A new list "Packing, Packing" with 11 open rows, receipt "Packing, Packing, new list."; not a repeat, and Packing itself is untouched | matches via the phrase, traced, code (NC12); no test | `starters_copyPackingToItsOwnName` | Core adds test |
| ST09 | Copy a starter after the user checked some rows | The copy is all open; the starter keeps its checks (reusable: reset is separate) | traced, code | `starters_copyIsOpenWhateverTheSourceChecked` | Core adds test |
| ST10 | Copy Packing keeps the section words | Copy has CLOTHES, TECH, PAPERS as sections on the same rows; `sections(of:)` order is Clothes, Tech, Papers | traced, code (`section` field copies when the item owns one, `ListReuse.swift:204-208`); ST01 is built, no copy test | `starters_copyKeepsSectionOrder` | Core adds test |
| ST11 | Copy a starter then edit the copy (add, check, reset) | The starter is never changed | traced, code (no link between copy and source) | `starters_editingACopyNeverTouchesTheStarter` | Core adds test |
| ST12 | Copy of a starter is not reusable-by-accident when the user switched the starter to plain | Copy follows the source's flag at copy time | traced, test for the rule (`flagsDoNotCopyExceptReusable`) | `starters_copyFollowsTheFlagAtCopyTime` | none |
| ST13 | A user-made list with a starter's name ("Packing") made before the install lands | The install must not make a second "Packing" (CreateList rule: the name is taken); the starter is skipped or merged | matches, test: skipped and marked handled (`StarterLists.swift:45-52`, `aListHeAlreadyMadeIsNotDoubledAndIsNotRetried`, `StarterListsTests.swift:105-122`); built as skip, not merge | `aListHeAlreadyMadeIsNotDoubledAndIsNotRetried` (exists) | none (Kitchen lead may confirm skip) |
| ST14 | Starter item "headphones" appears on both Gym bag and Packing | Both stay (separate lists) | traced, code (no cross-list de-dup) | `starters_sameItemOnTwoListsIsFine` | none |
| ST15 | Starter words are US (adapter, pants, sweater) | The seed uses them | matches, traced, code (`StarterLists.swift:16-35`: pants, adapter, sweater) | `starters_useUSWords` | Core adds test |
| ST16 | The starters contain no private-shaped text | Wall check passes on every seed line | inferred (the seed text has no medicine, money or secret word) | `starters_seedLinesPassTheWall` | Core adds test |
| ST17 | Backup then restore with a deleted starter | The deleted starter stays deleted | inferred (depends on how the marker is stored, ST03) | `starters_restoreKeepsDeletedStartersDeleted` | Core |
| ST18 | Day log on first launch | No "New list:" lines for the seeds | traced, code (`installIfNeeded` writes through `store.create`, not `engine.perform`, so no op records, `StarterLists.swift:53-68`); no test | `starters_writeNoDayLogLines` | Core adds test |

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
| RW01 | Made | Thing first: the new list, then "new list." ("Packing, Lisbon, new list.") | matches via the phrase (`StarterListsTests.swift:43`); drifted for the engine alone: "Lisbon, new list" (`ListReuseTests.swift:290`) | `copyPackingForLisbonMakesTheTripList` (exists) | none |
| RW02 | Summary string (the history and Day log feed) | "Copied Packing to Packing, Lisbon" (verb first; the summary is the one non-thing-first form) | traced, code via the phrase (`ListReuse.swift:228-231` with the composed name; no test asserts it); engine alone prints "Copied Packing to Lisbon" (`ListReuseTests.swift:291`) | same | none; Kitchen lead to confirm summary may stay verb first like "Reset Gym bag" |
| RW03 | Repeat | "<existing title>, already a list" | traced, test | `copy_repeatReceipt` (exists as part of NC01) | none |
| RW04 | Repeat prints the existing list's own title, not the typed one ("lisbon" typed, "Lisbon" shown) | Existing title (Design on #866) | traced, code (`receipt(in:output:)`) | `copy_repeatPrintsTheExistingTitle` | Core adds test (current test uses the typed-case path for the id and the receipt via `record`) |
| RW05 | Bar line for a copy | The Bar prints "X, new list." for create and "X, already a list." for a repeat; a copy has no Bar wiring | matches, test (`TessCaptureEngine.swift:431-437`; `StarterListsTests.swift:43,49`: "Packing, Lisbon, new list." and "..., already a list.") | `copyPackingForLisbonMakesTheTripList` (exists) | none |
| RW06 | Day log line for a copy | "New list: Lisbon" (`ownLines["copyList"]`) | traced, test (`aCopiedListIsANewListLine`) | exists | Kitchen lead: this one is verb-first; decide whether the Day log keeps "New list:" for copies |
| RW07 | A copy receipt never says "template" | No string in `CopyList` contains it | traced, code (`lists-acceptance.md` 4c rule) | `copy_nothingSaysTemplate` | Core adds a grep-style test |
| RW08 | Context line after a copy | "N lists" counts the copy; no new "copied" state word | could not trace (the Lists screen is not built) | `listsContextLine_countsCopies` | Builder B |
| RW09 | Receipt when the source was renamed after the copy | The old text in the history stays as written at the time | inferred (history strings are stored at record time) | `copy_receiptIsStoredAtRecordTime` | none |

## H. Where this fixture does not reach

- The Lists screens (copy gesture, shelf, context line, the UNDO key on screen) are not built, so every on-screen expectation is a Builder B gap that cannot be pinned yet.
- The phrase reaches `CopyList` through the Bar (#871); Siri and Shortcuts never copy a list (`commitImmediately` guard, `StarterListsTests.swift:132-135`).
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
        let lisbon = try engine.perform(CopyList(list: packing.id, name: "Packing, Lisbon"), by: .user).output
        let porto = try engine.perform(CopyList(list: lisbon.id, name: "\(lisbon.title), Porto"), by: .user)
        #expect(lists.items(of: porto.output).map(\.text) == ["Socks", "Charger", "Passport"])
        // The engine does not compose (the Bar path does, TessCaptureEngine.swift:435), so the test passes the
        // composed name the phrase would: porto is "Packing, Lisbon, Porto".
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

- **Core**: the starter-list tests still missing (ST04, ST05, ST06, ST08 to ST11, ST15, ST16, ST18); the 3:50 PM composition and the copy phrase are built in the Bar path (#871), so their rows are matches; tests still missing for the same-name source (G4001), NC03, NC11, NC12 and the engine-alone forms; `UndoWindow` (UN01, UN02); missing tests marked "Core adds test"; NC15 and UN08/UN09 checks.
- **Builder B**: the UNDO slot and its clock (UN01 to UN03, UN06), the copy gesture and context line (RW08), reading "no ops means no UNDO" (UN04).
- **Kitchen lead** (rulings first, because Core cannot build around them): inner-whitespace and accent folding for list names (NC04, NC06); whether the running list wins a tie (G4008); skip or merge when a starter name is taken (ST13); the Day log verb for copies (RW06); whether a dated item's date copies (CP08); whether a section label needs a mask (PV14).

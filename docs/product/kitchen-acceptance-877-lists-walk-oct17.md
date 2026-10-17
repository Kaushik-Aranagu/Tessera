# Acceptance: #877 CopyList fixtures, and the Lists shelf plus a running list on Home and Now

Static read of origin/master (tip 3e8e270, merge of #883), Oct 17. No Swift toolchain, nothing run, no repo file edited. Paths are repo-relative; "LV" = Features/Lists/ListsView.swift. Inferred means I reasoned from neighbouring code and did not see the line do it.

Verdict key: PASS, FAIL, NOT BUILT, NOT PROVABLE (needs a phone or a run), WAITS ON FOLLOW-UP (depends on #871: copy phrase, "source, word" naming, starters).

## Task A. #877 fixtures (docs/research/fixtures/copylist-starters.md) against master

What master does for CopyList (TesseraCore/Sources/TesseraCore/Lists/ListReuse.swift:122-224): names the copy exactly as typed (:177), receipt "<name>, copied from <source>" (:216, :222), summary "Copied <source> to <name>" (:211), repeat receipt "<existing>, already a list" (:216). So every fixture row that quotes the 3:50 PM ruling ("Packing, Lisbon", "Packing, Lisbon, new list.") describes #871, not master. The fixture says so itself (rulings item 5); I confirm it from the code.

### A1. The six rulings asked about

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Copy of Packing typed "Lisbon" is named "Packing, Lisbon" (CP01, RW01) | WAITS ON FOLLOW-UP | ListReuse.swift:177 creates with the typed name; no composition | No test of the new name. `aCopyHasTheSameItemsAllOpenAndTheOriginalStays` (ListReuseTests.swift:274-292) asserts the OLD name/receipt ("Lisbon, copied from Packing", :286) and will have to change with #871 |
| Receipt "Packing, Lisbon, new list." (CP01, RW01) and summary "Copied Packing to Packing, Lisbon" (RW02) | WAITS ON FOLLOW-UP | ListReuse.swift:211, :216, :222 print the old forms | Same test, asserts old strings (:286-287) |
| Copy of a copy: "Packing, Lisbon, Porto" (NC11) | WAITS ON FOLLOW-UP | Not composed (:177). Rows part works (a copy is an ordinary list, :183-195, inferred) | No test |
| "More than one list like pack." (G4003) when "Packing" and "Packing, Lisbon" both exist | WAITS ON FOLLOW-UP (phrase). The wording itself PASS in the resolver | Resolver `TessTools.Call.list(named:)` and `ListLookupLine.moreThanOne` (per the fixture, TessTools.swift:330-349; I did not reopen it). No grammar case calls CopyList; `TesseraRuntime.swift:73` lists it "in-app only" and ActionRegistry.swift:20 registers it with `isOfferedToModel: false` (ListReuse.swift:130) | Wording pinned for add-to-list: `twoPrefixMatchesRefuse`, `twoListsWithTheSameNameRefuse` (ListLookupTests.swift). Nothing for a copy phrase |
| Private list: "Private list, new list." (PV07 to PV09) | FAIL on master as written; the mask itself PASS | Typed name masked by `shown(_:)` (ListReuse.swift:201-203), source name by `sourceName` (:206-208), but the receipt prints "Private list, copied from Packing" (:216) | `aPrivateNameIsNeverInTheLine` (ListReuseTests.swift:344-351) asserts "Private list, copied from Packing" (:349), so it pins the old tail. Needs the new tail with #871. Reads "Private list", never its words: PASS (:350 checks no "lexapro") |
| Capitalized starter names like "Shorts" | NOT BUILT (seed). Receipt capital PASS in the Lists screen only | No starter list seed exists: `StarterContent.swift` installs plan, routines and kit only (git grep finds no `starter.list`). The seed file `docs/product/starter-lists.md` stores "shorts" lowercase. Receipt capital is done by `ListsCopy.leading` (Features/Lists/ListsCopy.swift:45-51), so a stored "shorts" reads "Shorts, removed." there; the engine's own receipts for copy never print item words (ListReuse.swift:211-222), so "Shorts" never appears in a copy receipt | `ListsRemoveTests`/`ListsCopyTests` cover `leading` (inferred from docs/product/kitchen-acceptance-782-793-oct17.md:119-150 which reports the earlier FAIL and its fix); no test for a seeded "shorts" because no seed |
| Groceries cannot be copied | PASS | Source: `source.id != Groceries.listID` (ListReuse.swift:169); typed word "groceries" also throws (:169) | `aTakenNameOpensThatListAndGroceriesCannotBeCopied` (ListReuseTests.swift:302-307) covers both and the blank name (:308). Mixed case "GROCERIES" as typed word: code lowercases (:169), no test |
| Ruling twist: the fixture's NC09b says typed word "Groceries" on Packing should become allowed ("Packing, Groceries") | WAITS ON FOLLOW-UP | Master still throws on the typed word (:169) and the existing test pins the throw (:302-304); #871 must drop `name.lowercased() != "groceries"` from the guard and rewrite that assertion | Needs `copy_typedWordGroceriesIsAllowed` |

### A2. Remaining fixture rows, condensed (counts in the summary)

| Rows | Claim | Verdict | file:line | Test |
|---|---|---|---|---|
| CP01 items part | Same items in order, all open, quantity and section kept, source untouched | PASS | ListReuse.swift:182-195 | ListReuseTests.swift:274-292 |
| CP02 | One op row | PASS (inferred, one `perform`) | ListReuse.swift:161 | no test |
| CP03 | Undo removes the list | PASS for the title; row removal not asserted | ListReuseTests.swift:290-291 | partial |
| CP04 | Redo | NOT PROVABLE | engine redo, not run for a copy | no test |
| CP05, CP06, CP07 | Reusable flag only, plain stays plain, notes lose #pick-one and picked: | PASS | ListReuse.swift:153-159, :179-181, :192-194 | `flagsDoNotCopyExceptReusable` (ListReuseTests.swift:311-330) |
| CP08 | Links and dates do not carry | PASS (code copies only quantity, section, notes: :187) | ListReuse.swift:187 | no test; Kitchen ruling on dated items open |
| CP09 to CP12 | Empty list, sections follow items, order kept, deleted rows skipped | PASS (inferred, loop :183) | ListReuse.swift:183-195 | no test |
| CP13 | Decodes from a tool call | PASS (inferred) | ActionRegistry.swift:80 | no test |
| CP14 | Not offered to the model | PASS | ListReuse.swift:130 | no guard test |
| PV01, PV02 | Private row reads "Private item" in the copy and its check receipt | PASS | ListReuse.swift:184 copies the title; shown at print time | `aPrivateRowStillReadsPrivateItemInTheCopy` (ListReuseTests.swift:332-342) |
| PV03 to PV06, PV09, PV10, PV12, PV14, PV15 | Masked uncheck/reset/run lines, both-names-private, repeat of private name | PASS (inferred / traced code per fixture) | ListReuse.swift:201-222 | no test |
| PV11 | Op payload keeps raw title (ruled 4:20 PM) | PASS (code) | Transaction.create stores raw title (per fixture, Transaction.swift:34-38) | no test |
| PV13 | Day log must read "New list: Private list" | FAIL | DayStory.swift:474-482: `title(of:)` returns `object.title` for a list; only cook/recipe masked. Line label at DayStory.swift:91 | `aCopiedListIsANewListLine` (DayStoryTests.swift:289-293) uses a plain name, so the hole is unseen |
| NC01 to NC03, NC12 | Collision check on the COMPOSED name; copy with its own source name makes "Packing, Packing" | WAITS ON FOLLOW-UP | ListReuse.swift:173 checks the typed name; typing "Packing" returns Packing itself, nothing written | Existing test pins old rule (ListReuseTests.swift:299-301) |
| NC04, NC06 | Inner whitespace, accents are different names | PASS as current truth; ruling open | ListReuse.swift:164 trims outer only | no test |
| NC05, NC07, NC08 | NBSP trimmed, empty and whitespace-only throw | PASS (NC07 tested) | ListReuse.swift:164-168 | ListReuseTests.swift:308 (blank); NBSP and newline no test |
| NC10 | Source Groceries throws | PASS | ListReuse.swift:169 | ListReuseTests.swift:305-307 |
| NC13, NC14, NC16, NC17 | Deleted name free, duplicates return oldest, punctuation differs, comma kept | PASS (inferred) | ListReuse.swift:173 via `CreateList.existing` | no test |
| NC15 | Rename into a taken name refuses | NOT PROVABLE | `RenameObject` guard not found | no test |
| G4001 to G4004, G4008 to G4012, G4015, RW05 | Copy phrase and resolver rows | NOT BUILT / WAITS ON FOLLOW-UP | no grammar case; `list-named` resolver exists for add | add-to-list tests only |
| G4005 to G4007, G4013, G4014 | Copy of running, paused, put-away, stale, non-list source | PASS (inferred); stale and wrong class throw via `transaction.object(list, is: .list)` (ListReuse.swift:163) | ListReuse.swift:163 | no test |
| ST01 to ST05, ST13, ST15, ST17, ST18 | Starter seed, install once, stable ids, deleted stay deleted, US words | NOT BUILT (WAITS ON FOLLOW-UP) | none in `TesseraCore/Sources` | no test |
| ST06, ST07, ST08, ST10, ST11 | Copy Packing twice, same word, own name, sections, edits isolated | WAITS ON FOLLOW-UP (needs seed and composition) | | |
| ST09, ST12, ST14 | Copy opens everything; flag at copy time; same item on two lists | PASS (code) | ListReuse.swift:179-195 | ST12 via `flagsDoNotCopyExceptReusable` |
| ST16 | Seed lines pass the wall | NOT PROVABLE (no seed) | | |
| UN01 to UN03, UN05, UN06 | 4 s new-thing window, 10 s VoiceOver, pause in background, "taken back" line, newer claim closes | NOT BUILT per fixture (no `UndoWindow`, no `UndoSlot`); I did not re-search the tree beyond HomeQueue.swift:44 | | |
| UN04 | Repeat shows no UNDO | PASS (engine side) | ListReuse.swift:173-176 returns with no ops | ListReuseTests.swift:300 (`ops.isEmpty`) |
| UN07 to UN09 | History undo with no clock, undo after edits, undo while running | NOT PROVABLE | | no test |
| RW03, RW04 | Repeat receipt prints existing title | PASS | ListReuse.swift:219-222 | ListReuseTests.swift:301 |
| RW06 | Day log "New list: Lisbon" for a copy | PASS | DayStory.swift:91 | DayStoryTests.swift:289-293 |
| RW07 | Nothing says "template" | PASS (header comment at ListReuse.swift:120-121 even states the rule) | | no test |
| RW08 | Context line counts the copy | PASS in `ListsShelf` (counts every live list, ListsShelf.swift:69-72) | | `theNewestTouched...` (ListsShelfTests.swift:27-36) |
| RW09 | History strings frozen at op time | PASS (inferred) | | no test |

### A3. Gaps found while reading (Task A)

| Id | Severity | Gap | One-line fix | Owner |
|---|---|---|---|---|
| G123 | important | The three old assertions that #871 will break are the only tests of the copy name and receipt (ListReuseTests.swift:286-287, :299-304, :349); until #871 lands they hold the retired wording "Lisbon, copied from Packing" | Land #871 with the three assertions rewritten to "Packing, Lisbon, new list." and the composed-name repeat; keep the Groceries source test | Core engine |
| G124 | important | The guard `name.lowercased() != "groceries"` (ListReuse.swift:169) contradicts ruling NC09b (typed word Groceries is allowed once names compose) | Drop the typed-word half of the guard in #871, keep `source.id != Groceries.listID` | Core engine |
| G125 | important | The Day log shows a private list's raw title (DayStory.swift:482), also for createList (:90); PV13 | Route list titles through `ListContents.shownName` in `title(of:)` | Core engine |
| G126 | low | Several "PASS (inferred)" rows (CP02, CP09 to CP12, PV03 to PV06, NC13, G4013, G4014) have no test; the fixture's own skeleton (end of copylist-starters.md) only covers two | Paste the fixture's Swift Testing names for the cheap ones in the #871 PR | Core engine |
| G127 | low | Seeded item names are lowercase ("shorts", starter-lists.md:8) and engine receipts store as typed; the capital is added only by the screen (`ListsCopy.leading`, ListsCopy.swift:45) | Keep it screen-side; add one test that a seeded "shorts" reads "Shorts, removed." | Builder B screen |
| G128 | low | The copy phrase "copy packing for lisbon" has no grammar case, so "More than one list like pack." cannot be reached for a copy | Add the case in the same PR that composes the name | Core engine |

## Task B. Shelf and a running list on Home and Now

Sources: docs/product/lists-screens-acceptance.md (rows 9.x to 12.x), docs/product/lists-acceptance.md (sections 5, 9, 10, 13), kitchen-gap-hunt-10 G78.

### B1. The shelf (screen 9, 13.1 to 13.5)

| Clause | Verdict | file:line | Test |
|---|---|---|---|
| 9.1 context line reads "6 lists, packing running" | FAIL as written, superseded: code prints "2 lists, 1 running" (K86.12, Product Oct 17). 13.3 still says "2 lists, Packing running". Doc drift, not a code bug | ListsCopy.swift:8-11; ListsShelf.swift:71-72 | `theNewestTouched...` (ListsShelfTests.swift:35), `aRunningListLeadsTheShelf` (:84, suffix ", 1 running") |
| 9.1 back word "‹ KITCHEN"; LISTS label dropped by 13 header | PASS | LV:33 (BackWord "Kitchen"), LV:35 (Title "Lists") | no test; NOT PROVABLE for the glyph |
| 9.2 sizes 56, two at 34, rest 21 at 75%; running first and largest; two runs newer first | PASS (code); two-runs order untested | ListsShelf.swift:45-53 (order), :62 (tier), LV:99-101 (roles, 0.75 opacity) | `aRunningListLeadsTheShelf` covers one run only |
| 9.3 state words "3 OF 7", "RUNNING, 9 LEFT" in vermilion, "REUSABLE", "PICK ONE", "EMPTY" | PASS | ListsShelf.swift:63-66, :85-93; ListsCopy.swift:117-119; LV:106 (live colour) | `stateWords`, `aReusableListReadsReusable`, `pickOneReads...`, `aRunningListLeadsTheShelf` |
| 9.3 "14 TO BUY" under Groceries | FAIL vs doc, code says "14 TO GET" (doc drift; later copy rulings use "get") | ListsShelf.swift:87 | `stateWords` pins "14 TO GET" (:23) |
| 9.4 names settle with a stagger | PASS (code), NOT PROVABLE (feel) | LV:49 `.entrance(2 + min(index, 4))` | no test |
| 9.5 paste makes a wet cobalt ghost list, "12 things, 2 sections." with UNDO 4 s | NOT BUILT on the shelf (no ghost or paste code in Features/Lists) | none | none |
| 9.6 Groceries once; "Put away" foot at 45%, never "Archived" | PASS (once is inferred from `contents.shelf()`) | LV:60-71; ListsShelf.swift:37-39 | `aFinishedTripListIsPutAway` (ListsShelfTests.swift:110-122) |
| 9.7 door: "Lists" under Groceries on Home with "PACKING, 9 LEFT" in vermilion labels | FAIL (the word is there, the running label is not) | HomeSpatialView.swift:377-388 draws `Text(link.title)` only | no test |
| 9.7 zoom 0.94 to 1 over 420 ms | NOT PROVABLE | HomeSpatialView.swift:387, 429 (matched transition) | no test |
| 13.1 empty shelf: "Just Groceries", "NOTHING TO GET" at 56, "No other lists yet." | PASS | ListsShelf.swift:71; LV:53-58; state :87 | `stateWords` covers the word; context and line untested |
| 13.1 Tess says `Say "new list: packing" and I'll start it.` on the empty shelf | FAIL (shelf `tess` is nil unless something runs) | ListsShelf.swift:73-75; LV:79-83 | none |
| 10.12 "Paste a list anywhere to make one." vs 13.1 "No other lists yet." | Doc conflict; 13.1 wins and matches code | LV:54 | none |
| 13.3 Tess "Packing has 9 left." once per visit | PASS | ListsCopy.swift:123-125; LV:78-83 | `aRunningListLeadsTheShelf` (:85) |
| 13.3 long shelf (9 lists) fade into Tess's band | NOT PROVABLE | | |
| 13.4 "RUNNING, 9 LEFT" never with a dot | PASS | ListsCopy.swift:117-119 | `aRunningListLeadsTheShelf` (:83) |
| 13.5 Lists side "ON THEM" with glance and full side | NOT BUILT (no "ON THEM" in Features or Core); doc marks it a Design proposal | none | none |
| Private list name on the shelf reads "Private list" | PASS, with a risk: the shelf masks with `isPrivateRecipeTitle(title, lastWeightKg:)` (ListsShelf.swift:97) while Home, Now and the ledger mask with `ObjectPrivacy.isPrivateWord` (ListRuns.swift:19-21). Two functions can disagree for the same name (inferred) | ListsShelf.swift:96-98 | `aWalledListNameReadsPrivateList` (ListsShelfTests.swift:38-41) |
| Paused private run never shows its name on the ledger | PASS | NowPage.swift:580-590 | `aPausedPrivateRunNeverShowsItsName` (ListsShelfTests.swift:94-107) |
| 10.7 running page: lit seam, "Packing, running", 64 pt rows | PASS (code), NOT PROVABLE (look) | LV:177, :307-308, :360 | no test |
| 10.7 / G3 a task or workout that @links a list shows it as an ink word on Now 60 min before | NOT BUILT (no code in Features/Home or Core Home reads a linked list) | none | none |

### B2. A running list on Home (HomeLines, lists-acceptance section 5)

Rules read at TesseraCore/Sources/TesseraCore/Home/HomeLines.swift. Caps: context at most 6 words and 32 characters, no stop (:185, :189-193); detail at most 14 words and 80 characters, with its stop (:186, :196-201).

| Clause | Verdict | file:line | Test |
|---|---|---|---|
| Fact for a running list that is not Groceries: kind .list, title through the privacy mask, step = open rows | PASS | HomeLines.swift:544-550 | `aRunningListReachesHomeWithItsNameAndCount` (HomeLinesTests.swift:273-286) |
| Hero "Packing, 6 left"; "Packing, all done" at zero | PASS | HomeLines.swift:310-311 | HomeLinesTests.swift:286 |
| Row line "Packing: 6 left." | PASS (code); the colon is a different shape from the hero's comma, same as shop (:236) | HomeLines.swift:237-242 | HomeLinesTests.swift:286 |
| Context within the caps | PASS: the title if it fits (<= 6 words, <= 32 characters), else nothing, never cut | HomeLines.swift:339-342; caps :189-193 | Only "Packing" is tested; a 33-character or 7-word name has no test |
| Detail within the caps | PASS: "6 left." or "All done." (<= 2 words) | HomeLines.swift:396-397 | HomeLinesTests.swift:286 |
| No repeats between hero, context and detail (the stated rule at HomeLines.swift:348) | FAIL (low, inferred ruling gap): hero "Packing, 6 left", context "Packing" and detail "6 left." say the same thing three times. The code comment (:340-341) says this is deliberate | HomeLines.swift:310, 342, 397 | test pins it (HomeLinesTests.swift:286) |
| Paused list: hero "Packing, paused"; context "paused N min ago"; row "Packing: paused, 4 left." | PASS | HomeLines.swift:309, 336-338, 239-241 | HomeLinesTests.swift:291-296 |
| Private list reads "Private list" in hero, context, detail | PASS | HomeLines.swift:547 via ListRuns.swift:19-21 | HomeLinesTests.swift:299-304 |
| Detail count wording matches shop ("4 items left.") | FAIL (low): list says "6 left.", shop says "4 items left." (:395) | HomeLines.swift:395-397 | none |
| Widget/Lock line for a list | PASS (inferred): hero then a context that is not a time word joins after a comma, but context "Packing" repeats the hero, so `repeatsState` drops it | HomeLines.swift:119-139 | no test for the list kind |
| Home door shows the running list under "Lists" | FAIL, see 9.7 | HomeSpatialView.swift:377-388 | none |
| Dates on Home use lowercase clocks, no "at" | PASS for this kind (no clock in list lines) | | |

### B3. A running list on Now (G78 and lists-acceptance section 5)

| Clause | Verdict | file:line | Test |
|---|---|---|---|
| G78: a running list is Now's hero ("Packing, 6 left" while running) | FAIL, still open on master. Branch 1 needs the workout session and its own id (NowPage.swift:46-48); branch 2 reads `ledger.first`, which excludes the running process (ProcessTable.swift:53-60); no branch calls `facts.fact(process:)` for a running list. A running list therefore falls through to the rest/plan/task hero (:64-95) | NowPage.swift:44-96; ProcessTable.swift:39-42, 55-60 | none |
| Queue never repeats the hero | PASS in code for the running id, but the running list is not drawn as a hero, so nothing hides it either | NowPage.swift:112-113 | none |
| Starting another process suspends the list into the ledger "Packing, 4 left" (lists-acceptance 5) | PASS with a wording drift: the hero for the ledger's first row reads "Packing, paused" with Resume (HomeLines.swift:309; NowPage.swift:56-63); the count shows in the row ("4 left", NowPage.swift:589) | NowPage.swift:56-63, 100-104, 580-590 | `aPausedPrivateRunNeverShowsItsName` (ListsShelfTests.swift:94-107) |
| Ledger row for a list never shows a walled name; step does not repeat the name | PASS | NowPage.swift:578-590 | ListsShelfTests.swift:94-107 |
| Raw list title reaches NowPicker for a running list (G79) | FAIL (inferred, latent) until G78 is fixed: `title: store.displayTitle(of: subject)` per the gap-hunt, unmasked | NowPicker.swift:63 (per kitchen-gap-hunt-10; I did not reopen the file) | none |
| G2: Now's "X, N left" opens the list page already running | NOT PROVABLE: `LineHero(... opens: .object(fact.id))` (NowPage.swift:57); whether `.object` of a list id lands on `ListPage` was not traced | NowPage.swift:57 | none |
| Idle suspension of a list run (checking a row resets the clock) | PASS (inferred from doc comment) | ProcessTable.swift:85-90 | not read |
| A shop or list run survives locking the phone (10.7) | NOT PROVABLE | | |

### B4. New gaps (G123 to G128 are in A3; Task B continues)

| Id | Severity | Gap | One-line fix | Owner |
|---|---|---|---|---|
| G129 | important | G78 stands: a running list is not Now's hero; lists-acceptance 5 "Now's line reads Packing, 6 left" shows only after the run is suspended | Add a branch before the rest/plan branches that renders `HomeLines.line(for: facts.fact(process: running))` with Resume or the page key | Builder B screen |
| G130 | important | Home door has no running-list label (9.7 "PACKING, 9 LEFT" in vermilion labels) | Read `ListsShelf.rows.first(where: \.isRunning)` in `KitchenPage` and draw its state word under "Lists" | Builder B screen |
| G131 | important | Two privacy masks for a list name: `ListsShelf.shownName` (isPrivateRecipeTitle with last weight) vs `ListContents.shownName` (isPrivateWord). They can disagree, so the shelf could print a name Home masks, or the reverse | Make the shelf call `ListContents.shownName` and delete `ListsShelf.shownName` | Core engine |
| G132 | important | Ghost list from a paste (9.5) and the empty-shelf Tess line (13.1) are not built | Build the paste ghost and a `tess` line for the empty shelf | Builder B screen |
| G133 | low | Context line and state word drift: docs say "6 lists, packing running" (9.1) and "14 TO BUY" (9.3); code and tests say "2 lists, 1 running" and "14 TO GET" | Update lists-screens-acceptance.md 9.1, 9.3 and 13.3 to the accepted wording | Product ruling |
| G134 | low | Home line for a running list says the same thing three times: hero "Packing, 6 left", context "Packing", detail "6 left." | Rule whether the context should be "running" or a time (for example "started 12 min ago") instead of the name; today a test pins the name | Product ruling |
| G135 | low | List detail "6 left." vs shop detail "4 items left." | Align the two nouns | Product ruling |
| G136 | low | No test for a list name over 32 characters or 6 words on Home (context must be nil, never cut) | Add `runningListWithALongNameHasNoContext` | Core engine |
| G137 | low | Two running lists on the shelf (G11) and the 60-minute @link word on Now (G3, 10.7) are untested/unbuilt | Add a shelf test for two runs newest first; build or defer the G3 word with a ruling | Builder B screen |
| G138 | low | ON THEM side for Lists (13.5) and the 9-list fade (13.3) are not built; both are Design proposals | Keep out of v1 or schedule | Product ruling |

## Counts

Task A: 48 grouped rows (A1 7, A2 41). PASS 27, FAIL 2 (private-copy receipt tail on master, PV13 Day log), WAITS ON FOLLOW-UP 8, NOT BUILT 4, NOT PROVABLE 7. All tallies are by grouped row and partly inferred; the fixture itself has about 120 ids.
Task B: 46 clauses. PASS 19, FAIL 9, NOT BUILT 4, NOT PROVABLE 8, PASS-with-drift 6.
New gaps G123 to G138 (16): 0 blockers, 7 important (G123, G124, G125, G129, G130, G131, G132), 9 low (G126, G127, G128, G133 to G138).

## Still open

- Whether #871 lands the composed name, the Groceries typed-word change (G124), the copy phrase and the starter seed in one PR or four.
- Whether G78 is fixed by a Now branch or by making the running list the Now ranker's top pick; the 10.7 / G3 ink word has no owner.
- Product: context line for a running list on Home (G134), "TO BUY" vs "TO GET" (G133), whether ON THEM ships in v1.
- Rows I marked inferred (Task A "PASS (inferred)", the NowPicker raw title, the `.object` route to ListPage, "Groceries once") were not run.

## Phone only

- Every motion and feel clause: 9.4 stagger, 9.7 zoom 0.94 to 1 over 420 ms, 10.7 seam and locking the phone, 12.x pick moment, Reduce Motion crossfades.
- Whether a running list really is missing on Now with no workout (G78 was found by reading code; confirm on the phone).
- Dynamic Type at AX sizes on the shelf and the 9-list fade; VoiceOver reading of "Private list".
- Undo windows (4 s new thing, 10 s change, 10 s VoiceOver) once `UndoWindow` and the slot exist.

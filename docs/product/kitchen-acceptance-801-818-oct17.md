# Kitchen acceptance of #801, #811, #813, #814, #817, #818: static read

Static only, against origin/master b1f0f0b (nothing built or run). #802 (pick one) was not on master at this read. Part A is Lists (#801, #814); Part B is Recipes (#811, #813, #817, #818).

# Part A: Lists

# Lists: acceptance of #801 and #814 (K88 3 of 4 and the run screens)

Static read only, against origin/master b1f0f0b (nothing built or run; no Swift toolchain). Merges read with `git diff <merge>^1 <merge>`: #801 ec4e65d, #814 830c18e. Line numbers are on b1f0f0b. "PASS" means the code does what the clause says at the line given; every test named was read, none was run.

Specs: `docs/product/kitchen-lists-screen-walk-oct17.md` (K88; its put-away rows are 1b, 9.6, 10.11, and the Core slice list at its end), `docs/product/lists-screens-acceptance.md` (G9, 9.6, 10.5, 10.7, 10.11, 10.12), and the open rows of `docs/product/kitchen-acceptance-k88-799-809-oct17.md`.

Refs: LU = `TesseraCore/Sources/TesseraCore/Lists/ListRuns.swift`, LR = `.../Lists/ListReuse.swift`, PT = `.../Processes/ProcessTable.swift`, HL = `.../Home/HomeLines.swift`, PA = `TesseraCore/Tests/TesseraCoreTests/ListPutAwayTests.swift`, UT = `.../ListRunTests.swift`, LV = `Features/Lists/ListsView.swift`, LS = `Features/Lists/ListsShelf.swift`, LC = `Features/Lists/ListsCopy.swift`, NP = `Features/Home/NowPage.swift`, LST = `TesseraTests/ListsShelfTests.swift`, LCT = `TesseraTests/ListsCopyTests.swift`.

Not on master: #802 (pick one). Every K88 row it owns (7a to 7d, 12.1 to 12.5, the "Pick one" option word, the PICK ONE state word) reads "not on master".

Product's rulings of Oct 17 9:45 am, as asked of each row:
1. Reset with nothing checked says "Packing, nothing to reset."
2. Done when not running says "Packing isn't running."
3. A put-away basket counts as bought.

Neither PR builds ruling 1 or 2. Ruling 3 is half built (the basket is kept and counted; nothing reads it as bought). Details in the rows.

---

## 1. PR #801 (ec4e65d): Core, put away a list run (K88 3 of 4)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| `PutAwayListRun` ends the list's open run as put away, to Later; the list keeps its items and its strikes | PASS | LU:191-222 (the end call at LU:220) | `puttingARunAwayKeepsTheBasketAndShowsItsCount`, PA:42 |
| The basket (checked items) is counted and returned; rows are never dropped, each `checkedAt` kept | PASS | LU:221, LU:238-240 | PA:42 (3 of 4 done, all rows alive, 3 `checkedAt`) |
| Receipt thing first, no "at": "Packing, Lisbon put away. 3 in the basket"; summary "Put Packing, Lisbon away" | PASS | LU:224-233 | PA:42; `everyReceiptIsThingFirstAndNeverSaysAt`, PA:277 |
| Empty basket reads "Packing, Lisbon put away" with no count | PASS | LU:231-232 | `anEmptyBasketIsNotCounted`, PA:57 |
| A run waiting in the ledger can be put away; Now keeps what is running | PASS | LU:217-220 (any open process) | `aRunWaitingInTheLedgerCanBePutAway`, PA:65 |
| One UNDO returns the run to what it was (running, line "Packing, Lisbon, 2 left", strikes) | PASS | engine undo of the end call, LU:220 | `oneUndoPutsTheRunBackWhereItWas`, PA:75 |
| UNDO from the ledger leaves it suspended, not running | PASS | same | `undoingFromTheLedgerLeavesItSuspendedNotRunning`, PA:89 |
| Groceries cannot be put away by hand (the shop is put away only by the idle rule) | PASS | LU:213-215 | PA:100 (second expectation, throw type only) |
| Put away on a list that is not running: nothing written, no op | PASS (engine half) | LU:216-219 | `aListThatIsNotRunningCannotBePutAwayAndNothingIsWritten`, PA:100 |
| Ruling 2: that refusal says "Packing isn't running." | FAIL | LU:218 throws the developer string "Packing, Lisbon isn't running" (list title, no full stop, not spoken); LU:116 (FinishListRun) the same | PA:100 asserts the old string; UT:211 asserts "Packing isn't running"; both will change with the ruling |
| The shelf is the lists not put away; the put-away list leaves it and waits in `putAway()`, newest first, never Groceries | PASS | LU:243-264 | `aPutAwayListLeavesTheShelfAndWaitsInPutAway`, PA:117; `putAwayListsComeNewestFirstAndNeverIncludeGroceries`, PA:143 |
| Running a put-away list again brings back the same run (never a second), rows and all, line refreshed | PASS | LU:55-62, LU:155-161 (`putAwayProcess`) | `runningAPutAwayListBringsTheSameRunBackWithItsItems`, PA:128 |
| G9 Finishing a plain list with items and nothing open puts it away whole (rows kept, `cleared` 0, `putAway` true); receipt "Packing, Lisbon put away" | PASS | LU:119-123, LU:131-134, LU:143-148 | `finishingAPlainListWithNothingOpenPutsItAwayWhole`, PA:160 |
| G9 UNDO of that finish brings the run and the list back to the shelf | PASS | same | `undoingAFinishedTripBringsTheRunAndTheListBack`, PA:173 |
| G9 Finishing with items open keeps the list on the shelf (cleared, "done. 1 left") | PASS | LU:124-127 | `finishingWithItemsOpenKeepsTheListOnTheShelf`, PA:184 |
| G9 A reusable list is never put away by finishing; an empty list is not either | PASS | LU:131-134 | PA:194, PA:204; UT:181 `finishingAReusableListWithNothingOpenSaysJustDone` (the old plain-list test was rewritten as reusable, UT diff in the merge) |
| G9 "Removing the last open row does not put a list away; only finishing does" | NOT PROVABLE | the remove action is not in this diff; no caller of `putsAway` outside `FinishListRun` | no test of a remove |
| G9 "Packing, Lisbon put away." spoken with UNDO 10 s | NOT BUILT (screen half; see #814 row "Finish says put away") | Core receipt is right (LU:143-148); no caller speaks it | no test |
| Idle rule, 7 days suspended: a list run is put away as the system; the note names the list and counts the basket: "Packing, Lisbon moved to Later. 3 in the basket." | PASS | PT:126-137, PT:150-158 | `aRunLeftSevenDaysIsPutAwayWithItsBasketCounted`, PA:214 |
| Idle run with nothing checked keeps the generic "One thing moved to Later." | PASS | PT:135-143 | `anIdleRunWithNothingCheckedKeepsTheGenericNote`, PA:227 |
| A shop and a list run put away together each get their own line | PASS | PT:131-140 | `aShopAndARunPutAwayTogetherGetTheirOwnLines`, PA:235 |
| A walled list name reads "Private list" in that overnight note | PASS | PT:156 (`ObjectPrivacy.isPrivateWord`) | `aWalledListNameReadsPrivateListInTheOvernightNote`, PA:268 |
| A "Private item" never reaches a put-away line | PASS | LU:224-233 (counts only) | `aPrivateItemsWordsNeverReachAPutAwayLine`, PA:254 |
| "Private list" masking on `PutAwayListRun` and `FinishListRun` receipts and summaries (the day log and history read them) | FAIL (latent) | LU:225, LU:230-232, LU:138-148 print the raw `object.title` | no test; PA:268 covers the overnight note only |
| Ruling 3: a put-away basket counts as bought | NOT BUILT | the basket is kept and counted (LU:238-240, PT:150-158) but no reader credits it: no Pantry or buy-cadence code reads checked rows of a put-away list (`BuyCadence.swift`, Pantry were not touched) | no test of a reader |
| Action is in the registry, decodes from a tool call, dropped from the day log, marked in-app only | PASS | `ActionRegistry.swift:22,88`, `DayStory.swift:93`, `TesseraRuntime.swift:80` | `theActionDecodesFromAToolCall`, PA:289 |

Verdict: not accepted on one row, ruling 2 ("Packing isn't running." is still the developer string at LU:116 and LU:218). Ruling 3 has only its engine half. The Core half of G9 is accepted.

Previously open rows this PR closes: "A put-away list run with checked items counts the basket as bought" in its note-and-count half (the overnight note, PT:150-158); K88 1b put away and bring back (engine); G9 (engine). K88 "Put away" option word and 9.6 put-away word: still not built (screen).

---

## 2. PR #814 (830c18e): Builder B, run a list, the shelf's RUNNING state, Tess's line

This is the app wiring of `StartListRun` and `FinishListRun`.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 10.5 The option words open with "Run it" (and "Done" while a run is open); the first of the words | PASS | LV:346-361 | no view test |
| Run it starts the run; line "Packing, 6 left." with UNDO 4 s | PASS | LV:381-398, LC:79-81 | `runLinesUseTheShownName`, LCT:79 (text only) |
| A workout running refuses: "Workout running.", nothing starts | PASS (by reuse of the cook refusal) | LV:383-388 | no test |
| A started run is a thing landing (the "made" feel), not the finish feel | PASS | LV:394, LV:217 | no test |
| Done finishes the run; "Packing, done." / "Packing, done. 3 left." with UNDO 10 s (default hold) | PASS | LV:403-414, LC:84-86 | LCT:79 (text only) |
| Finish failure says "Didn't save that. Try again." | PASS | LV:405-409 | no test |
| G9 Finish of a plain list with nothing open says "Packing, Lisbon put away." | FAIL | LV:414 always speaks `runDone` ("Packing, done.") and never reads `result.output.putAway` (true in exactly this case, LU:122); the Core receipt that says "put away" (LU:143-148) is not spoken | no test |
| Done on a reusable list asks "Packing, done. Reset it for next time?" with RESET and NOT NOW (10.11) | NOT BUILT | no RESET or NOT NOW in LV; a reusable finish speaks only "Packing, done." | no test |
| 10.7 A running page reads "Packing, running" as its context line | PASS | LV:149, LC:74-76 | LCT:79 |
| 10.7 A run lights the page: the live seam at the top; rows grow to 64 pt | PASS | LV:209-214, LV:262 | no view test |
| 9.2 Running lists lead the shelf, newer run first (G11), then by last touched | PASS | LS:30-45 | `aRunningListLeadsTheShelf`, LST:75 |
| 9.3 State word "RUNNING, 9 LEFT" in the live colour; "REUSABLE" for a reusable list | PASS (RUNNING, REUSABLE); PICK ONE not built (#802) | LS:59-62, LV:92 | LST:75; `aReusableListReadsReusable`, LST:90 |
| 9.1 Context line counts a running list: "2 lists, 1 running" | PASS | LS:65-67 | LST:75 (`hasSuffix(", 1 running")`) |
| 13.3 Tess says "Packing has 9 left." once per visit to the shelf, never an item's words | PASS | LS:68-70, LV:63-68, LC:94 | LST:75 (`shelf.tess`); the once-only is by read |
| The shelf reads the process table once, not once per list | PASS | LS:31-33 | no test |
| Put-away lists leave the shelf and the put-away word sits at the foot (9.6, 10.12) | NOT BUILT | LS:35 still reads `contents.lists()`, not the new `shelf()` (LU:259-262); no caller of `shelf()`, `putAway()` or `PutAwayListRun` in `Features/` | no test |
| 10.5 "Put away" option word | NOT BUILT | LV:346-380 has Run it and Reusable only | no test |
| 10.5 "Sections", "Pick one" option words | NOT BUILT | not in LV | no test |
| Closes #800 open row: "Private list" masking on Now's ledger row (LU:114 into NP:545, NP:573) | PASS for the ledger row | NP:545-589 now build the title and the step from the shown name and the live open count, never the stored `nextStep` | `aPausedPrivateRunNeverShowsItsName`, LST:105 (the walled title is "Rent 1200 stuff") |
| Same masking for a run that is Now itself (running, not paused) | NOT PROVABLE | `HomeLines.fact(process:)` (HL:495-523) returns nil for a list, so a running list gets no hero line from there; NP:112 only hides it from Next. Whether another surface draws it was not found | no test |
| The stored run line stays raw (`runLine` writes the list title; `NowPicker.swift:66` returns it) | FAIL (low, latent) | LU:9-12; `NowPicker.swift:66` | no test; fixed only at the one display site |
| Reset with nothing checked says "Packing, nothing to reset." (ruling 1) | NOT BUILT | no screen path: the fold needs done items; LR:84-86 still throws "nothing checked on Packing"; LV:360 would say "Didn't save that. Try again." | no test (PA and RT:117 unchanged) |
| Done when not running says "Packing isn't running." (ruling 2) | NOT BUILT | LV shows "Done" only while a run is open (LV:346-361), so the screen cannot reach it; LU:116 still the developer string | UT:211 asserts the old string |
| Ruling 3: a put-away basket counts as bought | NOT BUILT | nothing in #814 touches it | no test |
| Exact labels "Private list" and "Private item"; receipts thing first, no "at" before a time | PASS | LS:91, NP:586, LC:79-86 | LCT:79, LST:105 |

Verdict: not accepted on one row, G9 on the screen: finishing a plain list with nothing open says "Packing, done." and not "Packing, Lisbon put away." (LV:414). The rest of the run wiring is accepted.

Previously open rows this PR closes: #800 "Private list" masking on Now, for the ledger row; K88 and #806 "No screen calls `StartListRun` or `FinishListRun`" (the run door, Done, the page context line, the seam); #806 "10.5 option word Run it"; #806 "RUNNING and REUSABLE state words" and "2 lists, 1 running"; 9.2 running first; 13.3 and 10.7; Tess's run line (formatter now has a caller).

---

## Still open

1. Ruling 1 ("Packing, nothing to reset."): not built anywhere. LR:84-86 and RT:117 (reset), plus the screen path at LV:360.
2. Ruling 2 ("Packing isn't running."): not built. LU:116, LU:218; tests UT:211 and PA:100 assert the old string.
3. Ruling 3 (a put-away basket counts as bought): the basket is kept and counted, but no reader (Pantry, buy cadence) credits it. Needs an owner.
4. G9 on the screen: `FinishRun` must speak "Packing, Lisbon put away." when `output.putAway` is true (LV:414), and the shelf must use `shelf()` (LS:35) so a put-away list leaves it.
5. The put-away word at the foot (9.6, 10.12), the "Put away" option word (10.5), and any way to put a list away by hand: no screen calls `PutAwayListRun`.
6. "Private list" masking on `PutAwayListRun` and `FinishListRun` receipts and summaries (LU:138-148, LU:225-233); the stored run line (LU:9-12) and `NowPicker.swift:66`. Latent until a surface prints them.
7. A running list as Now itself: `HomeLines.fact(process:)` returns nil for it (HL:495-523). Confirm on the phone what Now shows.
8. 10.11 "done" ask on a reusable list with RESET and NOT NOW: not built.
9. #806 carried: 10.5 tapping outside folds the words (LV, option row only), Sections, Pick one, labels line under the hero (10.1), right-to-left un-paint (10.4).
10. #802 pick one: not on master (7a to 7d, 12.1 to 12.5, PICK ONE).
11. `CopyList` (4c), the three starter lists, and the carried rows from earlier acceptance docs (Lists side 13.5 and 13.9, bare phrase to a list G6, multi-item Add 10.8, list phrases slice 8, dated items on Today, remove-by-phrase 10.10, paging 10.6, item page 11.x).
12. #809 low: a typed line starting "picked: " is hidden on object pages (OP:543).

## Phone only

1. Run it on a list: the page reads "Packing, running", the live seam shows at the top, rows grow to 64 pt, "Packing, 6 left." shows UNDO for 4 s; UNDO gives the page back.
2. Done on a plain list with items open: "Packing, done. 3 left." with UNDO for 10 s; checked rows leave. Then finish a list with everything checked: confirm it says "put away" (today it will say "done", the G9 miss).
3. Shelf: the running list leads, its state word is vermilion "RUNNING, 9 LEFT", the context line reads "2 lists, 1 running", and Tess says "Packing has 9 left." once per visit.
4. Put-away list on the shelf: after finishing a fully checked plain list, confirm whether it still sits on the shelf (the code says it does).
5. Name a list so the wall calls it private (for example with an amount in the name), start a run, start another so it pauses: Now's ledger row reads "Private list, 2 left", never the name. Then leave it running on its own and look at Now for the name.
6. Leave a paused list run 7 days (or move the clock): the note reads "Packing moved to Later. N in the basket." and a walled name reads "Private list".
7. Start a workout, then try Run it: "Workout running." and nothing starts.
8. Haptics: Run it plays the landing feel, Done plays the finish tap. VoiceOver reads the Run it and Done hints.

# Part B: Recipes

# Acceptance: #811, #813, #817, #818 (static read, master b1f0f0b)

Read only. Nothing was built or run, so "covering test" means a test in the tree asserts it and I read the assertion; I did not run it. Diffs read with `git diff <merge>^1 <merge>`. Checked against `kitchen-gap-hunt-9-recipes-link-oct17.md` (G62 to G72), `kitchen-gap-hunt-8-recipes-oct17.md` (G51 to G61), `kitchen-groceries-screen-walk-oct17.md` (K34.8, K87) and `kitchen-error-states-acceptance.md` (ER1, ER5). Paths are under `/home/user/Tessera`. Core = `TesseraCore/Sources/TesseraCore`, Tess = `TesseraCore/Sources/TesseraTess`.

Verdict key: PASS, FAIL, NOT BUILT, NOT PROVABLE (needs a run or the phone).

## 1. PR #817 (71148bd): recipe page no longer crashes on huge serves or time (G62 page half)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Drum range clamps the written size before doubling, so no overflow trap (Int.max gives 1...48, Int.min gives 1...12) | PASS | Features/Recipes/PortionDrum.swift:13-17 | `RecipeContextTests.absurdValuesNeverCrash` (TesseraTests/RecipeContextTests.swift:55-57) |
| Old range behavior kept (G57: 24 gives 1...48, 14 gives 1...28, 2 and nil give 1...12, 5000 gives 1...48) | PASS | Features/Recipes/PortionDrum.swift:13-17 (same result as the old `min(48, max(12, 2*w))` for every input from 0 up) | RecipeContextTests.swift:10-14 (existing range test) |
| Drum binding stays inside 1 to 48 whatever the page holds | PASS | Features/Recipes/RecipePage.swift:97 | no test (view code) |
| Duration never traps on NaN, infinity, a huge or a negative value ("0 min", "99 h 59 min", "0 min") | PASS | Features/Recipes/RecipePage.swift:585-590 | `absurdValuesNeverCrash` (RecipeContextTests.swift:58-61) |
| Normal durations unchanged ("1 h 35 min", "45 min") | PASS | Features/Recipes/RecipePage.swift:585-595 | `durationsAreHoursAndMinutes` (RecipeContextTests.swift:17-22) |
| Page reads serves through the clamped Core reader | PASS (arrives with #818) | Features/Recipes/RecipePage.swift:46 calls `book.serves`, Core/Kitchen/Recipes.swift:61-63 | `RecipeLimitsTests.aStoredHugeValueReadsInsideTheLimits` |
| Context line reads the clamped total time | FAIL | Features/Recipes/RecipePage.swift:553 reads `model.store.number("totalMinutes", ...)` raw, not `book.totalMinutes` (added in #818, Recipes.swift:66-68). A stored 5000 shows "83 h 20 min" while the engine reads 1440. No crash, but two caps disagree. | no test |
| Page limits come from the one shared constant (the ask: single, shared by page, engine and Claude's reply limits) | FAIL | Page uses its own literals: 24 and 48 (PortionDrum.swift:14-16), 48 (RecipePage.swift:97), 5999 (RecipePage.swift:588). With Core moving to 4320 the page's 5999 cap and 48 drum cap stay separate numbers. | no test |
| Drum can show the written size of a large recipe (G57 intent) | NOT PROVABLE | A recipe that serves 100 reads `own` 100 (RecipePage.swift:46-47) while the drum range and binding stop at 48 (PortionDrum.swift:13-17, RecipePage.swift:97). The lines scale to 100 and the drum shows 48. Inferred; needs a run. | no test |

PR verdict: accepted for the crash (G62 page half). Two rows miss: the raw read at RecipePage.swift:553 and the page's own literals.

## 2. PR #818 (b1f0f0b): caps on recipe serves and time (G62 engine half)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| One home for the limits: serves 1 to 100, minutes 1 to 1440 (Core raises minutes to 4320 next) | PASS | Core/Kitchen/RecipeLimits.swift:7-8 | `RecipeLimitsTests.theLimitsClampAndNeverTrap` |
| That constant is the single one used by the engine | PASS | RecipeLimits.swift:7-8; used at Recipes.swift:62, 67, 72, 190, 193, 197, 296, 309; Cooking.swift:46, 144, 153; RecipeImport.swift:184-187; RecipeMath.swift:84 | `RecipeLimitsTests` (all four tests) |
| That constant is also the one Claude's reply limits use | FAIL | Tess/RecipeLinkReader.swift:459-460 hardcodes `(1 ... 100)` and `(1 ... 1440)`. When Core moves the time cap to 4320, a Claude reply of 1441 to 4320 minutes is still refused as unsafe (outputIsUnsafe, RecipeLinkReader.swift:436). Fix: use `RecipeLimits.serves` and `RecipeLimits.minutes` there. | no test ties the two |
| Cap lives in two more places as literals | FAIL | RecipeLimitsTests.swift:12, 14, 28, 59 and RecipeContextTests.swift:60 hardcode 100, 1440 and "99 h 59 min"; raising to 4320 will break those, and nothing reads the constant. | n/a |
| Serves clamps at read and write: NaN, infinity, zero, negative give nothing; 1e300 and Int.max give 100 | PASS | RecipeLimits.swift:11-19 | `theLimitsClampAndNeverTrap` (RecipeLimitsTests.swift:11-13) |
| Minutes clamp at read and write: NaN, infinity, non-positive give nothing; 0.2 gives 1; 1e300 gives the cap | PASS | RecipeLimits.swift:22-25 | `theLimitsClampAndNeverTrap` (RecipeLimitsTests.swift:14-15) |
| Every Double to Int goes through a non-trapping helper | PASS | RecipeLimits.swift:28-31; RecipeMath.swift:84; Recipes.swift:131 (`RecipeTimers.format`); RecipeImport.swift:187. A grep for `Int(` over Core/Kitchen, Features/Recipes and Features/Kitchen finds no other unguarded Double conversion (BuyCadence.swift:21 and CookModeCopy.swift:54 are bounded: timers offered are capped at 24 hours). | `theLimitsClampAndNeverTrap` (RecipeLimitsTests.swift:16-17) |
| Paste source capped ("Serves 999999999999", "Serves 100000", "Total time: 99999999 min", "Prep 9999999 min") | PASS | Recipes.swift:190-198 | `aPastedHugeSizeIsCapped` (RecipeLimitsTests.swift:21-30, four arguments) |
| Link source capped (Int.max serves, 1e300 minutes give "Serves 100" and "Total time: 1440 min") | PASS | RecipeImport.swift:184-188 | `aLinkWithAHugeTimeReadsAsText` (RecipeLimitsTests.swift:55-61) |
| Claude source capped | PARTLY | Reply over the limits is refused outright (RecipeLinkReader.swift:459-461); anything that passes is also capped on save (Recipes.swift:190-198). Literals, see above. | no test (G72 notes no timeout or huge-time case in RecipePasteLinkTests) |
| Edit and cook at a huge size capped (Int.max gives 100) | PASS | Recipes.swift:296; Cooking.swift:144-154 | `aStoredHugeValueReadsInsideTheLimits` (RecipeLimitsTests.swift:32-53) |
| Stored huge, NaN, infinite or negative value reads inside the limits; scaling at Int.max does not trap | PASS | Recipes.swift:61-72, 309; Cooking.swift:46 | `aStoredHugeValueReadsInsideTheLimits` |
| Total and active time are read through the book, not raw | PARTLY | Reader added (Recipes.swift:66-72), but the page does not call it (RecipePage.swift:553). Active time has no reader on the page. | `aStoredHugeValueReadsInsideTheLimits` |
| Stored out-of-range values are rewritten | NOT BUILT | Read-time clamp only; the stored number stays as written. Acceptable for G62 (no crash), noted. | no test |

PR verdict: accepted for the crash (G62 engine half). The row that misses is the shared constant: Claude's reply limits at Tess/RecipeLinkReader.swift:459-460 are literals, and the page has its own (see #817).

## 3. PR #813 (78ef13f): K34.8 ruling A and the Private recipe add line

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Re-add at the same or a smaller size says "<name>, nothing to add." and writes nothing | PASS | Core/Kitchen/Groceries.swift:393-399 (`alreadyOn > 0` and every wanted line covered by a share at least as big), helper at :438-453, summary at :462-471 | `GroceriesWeekTests.theWeekOnTheList` r4 (GroceriesWeekTests.swift:185-191, "Pasta, nothing to add."), and :202 (same size again gives no output) |
| A smaller size leaves the list unchanged, no halving (r4 now expects no halving) | PASS | Groceries.swift:393-399 | GroceriesWeekTests.swift:192-201: orecchiette "12 oz", sausage "1 lb", red pepper flakes ¼ tsp, parmesan ½ cup, garlic "7 cloves + 1 head", spinach "1 bag + 4 cups", beans "1 can". Values match the 4-serve source text (GroceriesWeekTests.swift:69-84). NOT PROVABLE here: whether the engine prints "1 lb" for 16 oz and the other joined sums; needs a run. |
| No write means no UNDO | PASS | Groceries.swift:397-398 returns an empty list | GroceriesWeekTests.swift:191 (asserts the result has no ops) |
| A bigger size replaces the share (24 oz, never 36 oz) and a return to 4 adds nothing | PASS | Groceries.swift:393-405 (falls through to remove and re-add when any line is not covered) | `GroceriesWeekTests.aBiggerSizeReplacesTheShare` (:256-266) |
| The list is never doubled | PASS | Groceries.swift:400-405 (old share removed first) | :256-266 (24 oz asserted) |
| Private-recipe add line: "Private recipe, N added." and "Private recipe, nothing to add." with no word of the title | PASS | Groceries.swift:462-471 (uses `ObjectPrivacy.recipeLabel`, Core/Tess/ObjectPrivacy.swift:13, value "Private recipe") | `GroceriesWeekTests.aPrivateRecipeIsNeverNamedInItsAddLine` (:268-278, also checks "pasta" absent) |
| Privacy test matches the page's own test (flag or title rule) | PASS | Groceries.swift:464-467 (`isPrivate` field or `isPrivateRecipeTitle`) | :268-278 (title route only; the flagged route has no Core test) |
| Recipe page shows the same line and no UNDO for "nothing" | PASS | Features/Recipes/RecipePage.swift:473-481 (count 0 gives `.nothing`, private form built from the count) | `RecipeSendTests.onlyStaplesSaysNothingToAdd`, `aPrivateRecipeSaysPrivateRecipe` (TesseraTests/RecipeSendTests.swift:36, 56) |
| Groceries screen's own recipe add shows the new line | NOT PROVABLE | Features/Groceries/GroceriesView.swift:848 calls the action and discards the result (`_ = try?`); no line is read there. | no test |
| K34.8 walk row (Scale back to 4, add again: "Tacos, nothing to add.", list not halved) | PASS | Groceries.swift:393-399 | GroceriesWeekTests.swift:185-202 |
| Receipt count when a bigger size replaces rows (G66 residual) | FAIL | `before` is taken after the old share is removed (Groceries.swift:401-402), so rebuilt rows count as new; a bigger size says "N added." for rows that existed. Inferred. | `aBiggerSizeReplacesTheShare` asserts ops and quantity, not the line |
| Edge: staples-only recipe already on the list adds nothing and removes nothing | PASS | Groceries.swift:396 (empty `wanted` satisfies "all covered") | no test |

PR verdict: accepted. K34.8 is closed; the only row that misses is the bigger-size receipt count (G66 residual, below).

## 4. PR #811 (2ea306a): link reading wired on Paste (G54)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| A bare link shows Tess's link line, not "Paste a recipe..." and not the link | PASS | Features/Recipes/PasteRecipe.swift:42-43, 491-498 ("A link. Tap Read it and I'll read the page.") | `PasteCycleTests.aBareLinkIsALinkNotATitle` (TesseraTests/PasteCycleTests.swift:27-37, also asserts the host is absent) |
| Text that contains a link still reads as a recipe | PASS | Tess/RecipePasteLink.swift:15-28 (only one whitespace-free token counts) | PasteCycleTests.swift:30 and RecipePasteLinkTests.swift:21-31 |
| Read it key in place of Save on a bare link, on his tap only, never self-retry (K86.7) | PASS | PasteRecipe.swift:112-114, 329-340; read runs only from the key (:206-232) | no view test; Core: `RecipePasteLinkTests.offlineKeepsTheLinkUntilHisTap` (:46) |
| Save is never drawn for a link (canSave false when nothing read) | PASS | PasteRecipe.swift:111, 329-340, 503 | `PasteCycleTests` canSave rows (PasteCycleTests.swift:17-24) |
| Key shows "Reading" and is disabled while the read runs; one read at a time | PASS | PasteRecipe.swift:207, 335-338 | no test |
| Reading line names the host, no ellipsis | PASS | PasteRecipe.swift:209, Tess/RecipeLinkReader.swift:30-32 | `RecipeLinkTests` (RecipeLinkTests.swift:279) |
| A read recipe's text lands in the box and the brush paints it | PASS | PasteRecipe.swift:221-226 | no view test; `RecipePasteLinkTests.aPastedLinkReadsAsARecipe` (:38) covers the Core result |
| Offline: "Recipe link, kept for later."; link kept on the shelf; box cleared (ER1) | PASS | PasteRecipe.swift:227-230; Tess/RecipePasteLink.swift:50-61; line at RecipeLinkReader.swift:14 | `offlineKeepsTheLinkUntilHisTap` (RecipePasteLinkTests.swift:46-64) |
| ER1 says typed text stays; here the box is emptied | FAIL | PasteRecipe.swift:229 (`text = ""`). With no screen listing the shelf (below), the link is gone from his sight after the line fades. | no test |
| Claude (L3) runs only while "Tess asks Claude" is on; off gives "Claude is off. Paste the text instead." | PASS | PasteRecipe.swift:211-215, 217-218; Tess/RecipePasteLink.swift:47-49 | `claudeOffNeverAsksClaude` (RecipePasteLinkTests.swift:66) |
| Line never contains the link | PASS | PasteRecipe.swift:209, 491-498 (host only) | PasteCycleTests.swift:34 |
| A link with a name or password gets "That link has a password in it..." | FAIL | `isSecretLink` and `RecipeLinkLine.secretLink` have no caller in Features or App. Such a paste is not a bare link (PasteRecipe.swift:42, `bareLink` returns nil), so Tess says the idle line, no Read it key, no secret-link line. Nothing is read or kept, so no leak, but the ruled line is not shown. | Core only: RecipePasteLinkTests.swift:84-89 |
| Failure keeps the link in the box so Read it can be tapped again | PASS | PasteRecipe.swift:221-231 (text untouched on failure) | no test |
| Timeout, DNS failure and no-route are worded as "kept for later" and the link kept (G63, ER5) | FAIL | Tess/RecipeLinkReader.swift:217-220: only notConnectedToInternet, networkConnectionLost, dataNotAllowed are offline; timedOut, cannotFindHost, dnsLookupFailed, cannotConnectToHost fall to `default` and say "That site won't let me read it..." (:219); the link then leaves the shelf (RecipePasteLink.swift:54-58). | RecipePasteLinkTests.swift:103-104 still pins `.cannotFindHost` as NOT offline |
| 15 s deadline reads as "Too big" (G63) | FAIL | RecipeLinkReader.swift:245 (`Task.isCancelled ? tooBig`) | no test |
| Saved or kept link loses its fragment and sensitive-looking query items (G64) | FAIL | RecipeLinkReader.swift:312-326: `secretQueryItems` unchanged (no `secret`, `signature`, `code`, `jwt`, `id_token`, `sid`, `email`, `passwd`); `fragment` never cleared. Shelf keep uses the same strip (RecipePasteLink.swift:90, 97). | RecipePasteLinkTests.swift:84-97 tests only user and password |
| Shelf has a door: list waiting links, read on his tap, remove one, erase all (G65) | NOT BUILT | `RecipeLinkShelf` is used in Features only to keep and remove (PasteRecipe.swift:218). `waiting()` and `erase()` (RecipePasteLink.swift:87-89, 105-108) have no caller in Features, App or the erase-everything path. | Core only: `theShelfHoldsFiftyAndErases` (RecipePasteLinkTests.swift:107) |
| Whole-view behavior of the wire (tap, outcome, line, paint) | NOT PROVABLE | PasteRecipe.swift:206-233 is view code with no test; the Task, the animation and the paint need a run. | no test |

PR verdict: accepted for G54 (the wire: Read it on his tap, link line, offline keep, Claude switch, Save never on a link). Rows that miss: the secret-link line is unwired, the box is emptied against ER1, and G63, G64, G65 are untouched by this PR.

## Gap status (G62 to G72, G54)

| Gap | State | Why |
|---|---|---|
| G54 link on Paste | Partly closed | Wire, link line, Read it key, offline keep and the Claude switch are built (#811). Open inside it: the secret-link line has no caller, and a kept link has no door (G65). |
| G62 huge serves or time crashes the page | Closed for the crash | #817 and #818 clamp every conversion on the page, the engine and all sources. Open: no single shared constant (Tess/RecipeLinkReader.swift:459-460 and the page literals), and the page's raw total-time read (RecipePage.swift:553). |
| G63 timeout and DNS wording, 15 s "Too big" | Still open | RecipeLinkReader.swift:217-220, 245; the pinned test at RecipePasteLinkTests.swift:103-104 is unchanged. |
| G64 fragment and sensitive query items | Still open | RecipeLinkReader.swift:312-326 unchanged. |
| G65 shelf door and eraser | Still open | `waiting()` and `erase()` have no caller. Worse after #811: the link now leaves the box and only the file holds it. |
| G66 re-add says "7 added." | Partly closed | Same-size and smaller re-adds now say "<name>, nothing to add." with no write (#813). Bigger-size replacement still counts rebuilt rows as added (Groceries.swift:401-402). |
| G67 UNDO lives in page state | Still open | RecipePage.swift unchanged by these PRs. |
| G68 per-row "Add to Groceries" adds the whole recipe | Still open | RecipePage.swift:341-351 unchanged. |
| G69 Dynamic Type | Still open | Fixed 92 pt column and fixed drum unchanged. |
| G70 failed send: no haptic, no retry, not the ruled private form | Still open | RecipePage.swift:476 unchanged. (The private "nothing to add" and "added" lines are right.) |
| G71 link read drops a private title line silently | Still open | Tess/RecipeLinkReader.swift cut logic unchanged. |
| G72 small residuals | Still open | "12 months ago" (RecipePage.swift:605), raw animations (PortionDrum.swift:77, RecipePage.swift:250, 318), untested view clauses, no timeout or fragment test. |
| Hunt 8 touched by these PRs | Holds | G57 range behavior preserved (PortionDrum.swift:13-17); G53 Private recipe line extended to Groceries (#813); G58 swipe path unaffected apart from the nothing line. |

## Still open

1. One shared limits constant: make Tess/RecipeLinkReader.swift:459-460, PortionDrum.swift:14-16, RecipePage.swift:97 and :588 read `RecipeLimits`, and change the tests that hardcode 100, 1440 and "99 h 59 min" to read it too, before Core sets 4320.
2. RecipePage.swift:553: read the total time through `book.totalMinutes`.
3. G63: treat timedOut, cannotFindHost, dnsLookupFailed, cannotConnectToHost and the 15 s cancel as offline (keep, "Recipe link, kept for later."); flip the pinned test.
4. G64: drop the fragment and widen the secret list; add a fragment test and an `email=` test.
5. G65: a door for waiting links (read on his tap, remove) and `erase()` wired into the erase-everything path. Decide the ER1 clause on whether the box keeps the link after an offline keep.
6. Wire `isSecretLink` to `RecipeLinkLine.secretLink` on Paste.
7. G66 residual: count new rows against the list before the old share is removed; assert the line in `aBiggerSizeReplacesTheShare`.
8. G67 to G72 as listed above.
9. Drum for a recipe that serves 49 to 100.

## Phone only

- Pasting a real link, tapping Read it online, and watching the brush paint the read recipe.
- Offline, Wi-Fi with no internet (timeout and DNS wording), and a slow page hitting the 15 s cut.
- Tess's line changing from the link nudge to "Reading <host>." to the result, with Reduce Motion on and off.
- The drum and page on a recipe that serves 100, and on one with a stored huge serves or time (opens without a crash).
- Swiping a recipe to Groceries at the same size, a smaller size and a bigger size, and the lines and UNDO that show.
- Exact printed quantities in r4 ("1 lb", ¼ tsp, ½ cup, "7 cloves + 1 head", "1 bag + 4 cups"), which only a test run settles.
- VoiceOver and Dynamic Type passes on the recipe page and the Paste screen.

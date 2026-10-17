# K88 Lists: acceptance of #799, #800, #806, #809

Static read only, against origin/master 3c0f80a (nothing built or run; no Swift toolchain). Merges read with `git diff <merge>^1 <merge>`: #799 c397d8f, #800 abaf552, #806 c6f924e, #809 91cf703. "PASS" means the code does what the clause says at the line given; every test named was read, none was run.

Specs: `docs/product/kitchen-lists-screen-walk-oct17.md` (K88), `docs/product/lists-screens-acceptance.md` (rows 9 to 12), `docs/product/kitchen-test-specs-wall-g40-g43-g44-oct17.md` (B3 for the idle rule), and the Lists rows left open in `kitchen-acceptance-760-761-763-764-oct17.md`, `-774-776-779-oct17.md`, `-782-793-oct17.md`.

Refs: LR = `TesseraCore/Sources/TesseraCore/Lists/ListReuse.swift`, LU = `.../Lists/ListRuns.swift`, LN = `.../Lists/ListNoteTags.swift`, L = `.../Lists/Lists.swift`, PT = `.../Processes/ProcessTable.swift`, RT = `TesseraCore/Tests/TesseraCoreTests/ListReuseTests.swift`, UT = `.../ListRunTests.swift`, LV = `Features/Lists/ListsView.swift`, LC = `Features/Lists/ListsCopy.swift`, LS = `Features/Lists/ListsShelf.swift`, OP = `Features/Objects/ObjectPage.swift`, NP = `Features/Home/NowPage.swift`, LCT = `TesseraTests/ListsCopyTests.swift`, LRT = `TesseraTests/ListsReuseTests.swift`, ONT = `TesseraTests/ObjectNotesTests.swift`.

Not on master, so every K88 row they own reads "not on master": #801 (put away) and #802 (pick one). Both are listed in their own section below.

Product's rulings of Oct 17 9:45 am are not in `docs/product/decisions.md` on this tree (it has no Oct 17 entries; the file's last Lists line is at 640). They are taken from the request and land in a Core follow-up PR that is not built. Every row that waits on it is marked WAITS ON FOLLOW-UP:

1. Reset with nothing checked says "Packing, nothing to reset."
2. Done when not running says "Packing isn't running."
3. A put-away basket counts as bought.

Verdict words: PASS, FAIL, NOT BUILT, NOT PROVABLE, WAITS ON FOLLOW-UP (plus "not on master" for #801 and #802).

---

## 1. PR #799 (c397d8f): Core, reusable lists and reset (K88 1 of 4)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 4a Reusable is a flag on the list, off by default, the word is "reusable" | PASS | LN:260, LN:264-266, LR:8-10 | `theFlagIsOffByDefault`, RT:30 |
| Flag lives on the existing notes line; his other note lines are untouched | PASS | LN:272-283, LR:46-47 | `theFlagLeavesAListsOtherNotesAlone`, RT:52 |
| `SetListReusable` on and off is one op and one UNDO | PASS | LR:33-48 | `turningReusableOnAndOffIsUndoable`, RT:35 |
| Receipt thing first: "Gym bag, reusable" / "Gym bag, not reusable"; summary "Made Gym bag reusable" | PASS | LR:50-56 | RT:39-40, RT:47 |
| 4d Groceries cannot be reusable; error thrown, nothing written | PASS | LR:35-37 | `groceriesCannotBeReusableAndNothingIsWritten`, RT:62 |
| Setting a value that is already set writes nothing | PASS | LR:40-45 | `turningOnWhatIsAlreadyOnWritesNothing`, RT:71 |
| 4b `ResetList` unchecks every item, keeps every item in order, clears `checkedAt` | PASS | LR:81-93 | `resetUnchecksEverythingAndKeepsEveryItemInOrder`, RT:83 |
| Reset is its own action, one op, one UNDO that restores the checks | PASS | LR:62-93 | `resetIsOneActionAndOneUndoBringsBackTheChecks`, RT:96 |
| Reset works on a list that is not reusable (uncheck all) | PASS | LR:59-61, LR:82 (no reusable guard) | `resetWorksOnAListThatIsNotReusable`, RT:110 |
| Reset touches only its own list | PASS | LR:82-83 | `resetOnlyTouchesItsOwnList`, RT:124 |
| Reset receipt thing first with no "at": "Gym bag, reset" | PASS | LR:100-102 | RT:92 (receipt), RT:93 (summary "Reset Gym bag") |
| Clear done on a reusable list resets instead of deleting; receipt "Gym bag, reset"; UNDO restores | PASS | L:453-455, L:469-475 | `clearDoneOnAReusableListUnchecksInsteadOfDeleting`, RT:134 |
| Clear done on a plain list still deletes; receipt "Gym bag, done items cleared" | PASS | L:476 | `clearDoneOnAPlainListStillDeletes`, RT:147 |
| A "Private item" never reaches a reset line (receipt or summary) | PASS | LR:96, LR:101 (list title only, no item words) | `aPrivateItemsWordsNeverReachAResetLine`, RT:155 (uses a medicine name) |
| "Private list" masking on the engine's reset and reusable receipts | NOT PROVABLE | LR:55, LR:101, L:472-474 use the raw list title; the screen masks it itself (LV:353, LV:368 pass the shown name) | no test with a walled list title |
| Reset on Groceries keeps the shop line current | PASS | LU:244-248 (via `refreshRunLine`) | `resetOnGroceriesKeepsTheShopLineCurrent`, RT:164 |
| Both actions decode from a Claude-path tool call and are in the registry | PASS | `ActionRegistry.swift` (descriptors line 21, decoders lines 84-85) | `theActionsDecodeFromAToolCall`, RT:177 |
| Both actions are dropped from the day log; marked in-app only for Shortcuts | PASS | `DayStory.swift:93`, `TesseraRuntime.swift:79-80` | no test |
| Reset with nothing checked: nothing written, no op | PASS (engine half) | LR:84-86 throws `invalidArguments`, so `perform` rolls back | `resetWithNothingCheckedWritesNothing`, RT:117 (asserts the throw type and an unchanged op count, not the words) |
| Reset with nothing checked says "Packing, nothing to reset." | WAITS ON FOLLOW-UP | LR:85 today throws the developer string "nothing checked on Packing"; no spoken line exists | RT:117 will need the new words |
| 4c `CopyList` ("copy packing for lisbon", "Lisbon, copied from Packing.") | NOT BUILT | grep finds no `CopyList` in `TesseraCore/Sources` | no test |
| 4 UNDO windows: reset and reusable change carry 10 s | PASS (screen sets it, see section 4) | LV:353, LV:368 default hold | `HomeQueue.hold` rule, no new test |

Verdict: accepted for its engine clauses. One row waits on the follow-up (reset with nothing checked). `CopyList` (4c) is not in this PR and has no owner PR yet.

---

## 2. PR #800 (abaf552): Core, list runs (K88 2 of 4)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 5a `StartListRun` makes the list the running process; Now's line reads "Packing, 6 left" | PASS | LU:130-160, LU:112-115 | `startingARunMakesTheListTheRunningProcess`, UT:43 |
| Start receipt is thing first and equals Now's line | PASS | LU:166-169 | UT:292 `everyReceiptIsThingFirstAndNeverSaysAt` (prefix, no " at ") |
| The line drops as items are checked and "Packing, nothing left" at none | PASS | LU:112-115, L:335 | `theLineDropsAsItemsAreChecked`, UT:55 |
| Add, uncheck and reset while running keep the line current | PASS | L:199-201, LR:91, LU:244-252 | `addingAndUncheckingWhileRunningKeepsTheLineCurrent`, UT:66; `resettingWhileRunningBringsTheCountBack`, UT:240 |
| 5b Starting another run suspends the first into the ledger (G11, newer first) | PASS | LU:159 via `StartProcess` | `startingAnotherRunSuspendsTheFirstIntoTheLedger`, UT:76 |
| A shop and a list run take Now from each other | PASS | LU:159 | `aShopAndAListRunTakeNowFromEachOther`, UT:89 |
| Starting again resumes the same run, never a second | PASS | LU:159 | `startingAgainResumesTheSameRunNeverASecond`, UT:100 |
| UNDO of a start gives Now back to what was running | PASS | LU:159 | `undoingAStartGivesNowBackToWhatWasRunning`, UT:112 |
| Groceries is refused (runs as the shop); nothing written | PASS | LU:152-154 | `groceriesAreRefusedAndNothingIsWritten`, UT:122 |
| A running workout is never suspended by a run | PASS | LU:155-157, LU:233-240 | `aRunningWorkoutIsNeverSuspendedByARun`, UT:135 |
| Only a list can run | PASS | LU:151 (`object(_, is: .list)`) | `onlyAListCanRun`, UT:147 |
| The run can be found wherever it waits (running, ledger, past it) | PASS | LU:122-124 | `findsTheRunWhereverItWaits`, UT:154 |
| 5c Finish a plain list: clears what was checked, ends the run; receipt "Packing, done. 3 left" | PASS | LU:204-217, LU:224-228 | `finishingAPlainListClearsWhatWasCheckedAndEndsTheRun`, UT:166 |
| Finish with nothing open reads "Packing, done" | PASS | LU:227 | `finishingWithNothingOpenSaysJustDone`, UT:181 |
| Finish a reusable list keeps every strike; reset is its own op, never done here (10.11 first half) | PASS | LU:212-214 | `finishingAReusableListKeepsEveryStrikeAndDoesNotReset`, UT:190 |
| One UNDO brings back the cleared rows, the run and each `checkedAt` | PASS | LU:213-214 | `oneUndoBringsBackTheClearedRowsAndTheRun`, UT:215; reusable case UT:229 |
| 5d Groceries shop still finishes as the shop (`FinishShop` untouched) | NOT PROVABLE | the shop files are not in the diff | no new test; ShoppingTests not run |
| Idle rule: a run untouched past 12 hours is suspended as the system, basket kept, last touch kept | PASS | PT:86-100, PT:153-156, LU:244-252 | `aRunUntouchedOvernightIsSuspendedAsTheSystemWithItsBasket`, UT:251 |
| Checking a row resets the run's idle clock | PASS | L:335, LU:250 | `checkingARowResetsTheRunsIdleClock`, UT:268 |
| A "Private item" never reaches a run line, receipt, summary or next step | PASS | LU:113-114 (counts only) | `aPrivateItemsWordsNeverReachARunLine`, UT:278 ("Private item, got") |
| Thing-first receipts with no "at" before a time | PASS | LU:167-169, LU:224-228 | UT:292 |
| Actions decode from a tool call, are in the registry, dropped from the day log | PASS | `ActionRegistry.swift:22,86-87`, `DayStory.swift:93` | `theActionsDecodeFromAToolCall`, UT:304 |
| "Private list" masking on Now: a list whose title the wall calls private reads "Private list" | FAIL (latent: nothing in the app starts a run yet) | LU:114 writes the raw list title into the process's next step; NP:545 and NP:573 print the subject title and the next step as stored, with no mask | no test; UT:278 covers item words only |
| Done when not running says "Packing isn't running." | WAITS ON FOLLOW-UP | LU:209-211 throws the developer string "Packing isn't running" (no stop, not spoken) | UT:206 `finishingAListThatIsNotRunningWritesNothing` asserts that string and an unchanged op count; it will change with the ruling |
| A put-away list run with checked items counts the basket as bought | WAITS ON FOLLOW-UP | PT:122-137: the basket note and its count exist for Groceries only (PT:147-152); a list run falls to the generic "One thing moved to Later." | no test for a put-away run |
| Run line, "Packing, 6 left", appears on Now as a ledger row (G2) | PASS (generic row) | NP:545-573 prints subject title plus next step | no test |
| A door to start or finish a run in the app ("Run it", "done" on a list page, Now's "X, N left" opening the list page) | NOT BUILT | grep finds no caller of `StartListRun` or `FinishListRun` under `Features/` | no test |
| Phrase rows "run packing", "done" | NOT BUILT | not in `TessGrammar+Kitchen.swift` | no test |

Verdict: not accepted on one row: "Private list" masking of the run line (LU:114 into NP:573). It is latent today and Core owns the fix (store a masked line, or have Now mask the list title). The two ruled lines wait on the follow-up.

---

## 3. PR #806 (c6f924e): Builder B, option words, reusable lists, hold to reset

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 10.5 Tapping the context line unfolds the option words in place; no sheet | PASS | LV:131-153 | no view test |
| 10.5 Option words: Sections, Reusable, Run it, Pick one, Put away | NOT BUILT (only Reusable) | LV:318-340; LV:318 says the rest arrive with their actions; Run it has an engine action now (#800) but no word | no test |
| 10.5 Tapping outside folds them | FAIL | LV:339 puts the fold-away tap on the option row only; a tap elsewhere on the page does nothing | no test |
| 10.1 Option words, once used, form one labels line under the hero | NOT BUILT | the words show only while unfolded (LV:151) | no test |
| Reusable is on the list's page only; absent on Groceries | PASS | LV:151 | no test |
| Reusable toggle: "Packing, reusable." / "Packing, not reusable." with UNDO 10 s | PASS | LV:343-354, LC:54-56 | `reusableAndResetReadThingFirst`, LCT:70 (text); UNDO hold is the app's rule, `HomeQueue.hold` |
| Private list name reads "Private list" in the toggle and reset lines | PASS | LV:127 (shown name), LV:353, LV:368 | LCT:76 `ListsCopy.reset("Private list")` |
| 10.4 Fold on a reusable list reads "4 done. Hold to reset." | PASS | LV:393-394 | no test of the view |
| 10.4 Hold 0.7 s resets; items come back unchecked and in order | PASS | LV:401, LV:357-369 | `aReusableListResetsAndUndoChecksThemAgain`, LRT:15 (engine through the model, not the hold) |
| 10.4 / 10.11 "Packing, reset." with UNDO 10 s; UNDO checks them again | PASS | LV:368 (`say(_, undo:)`, default hold 10 s) | LRT:15 (undo), LCT:70 (text) |
| 10.11 Reset is a hold, never a tap; accessibility action "Reset the list" | PASS | LV:401-406 | no test |
| 10.4 The strikes un-paint right to left, then the items rise back | NOT BUILT | LV:364-367 only closes the fold with a 0.48 s smooth animation; done rows live in the fold, not struck in the page | no test |
| Reduce Motion: a crossfade instead of the smooth animation | PASS | LV:364 | no test |
| Reset failure says "Didn't save that. Try again." and changes nothing | PASS | LV:358-362 | no test |
| Reset with nothing checked says "Packing, nothing to reset." | WAITS ON FOLLOW-UP | the fold shows only with done items (LV:188-192), so the screen cannot reach it; the failure line at LV:360 would speak instead | no test |
| Plain list: fold reads "4 done", hold clears, "4 done, cleared." UNDO 10 s | PASS (unchanged) | LV:394, LV:415-422, LC:68-70 | `theAddReceiptNamesTheThingFirst`, LCT:29 (asserts `cleared(3)`) |
| 10.11 "done" on a reusable list asks "Packing, done. Reset it for next time?" with RESET and NOT NOW | NOT BUILT | no caller of `FinishListRun`; no RESET or NOT NOW anywhere in LV | no test |
| 10.11 "Packing, nothing left." / "Packing has 2 left." Tess run lines | NOT BUILT (formatter only) | LC:73-81 have no caller | `tessSaysWhatsLeft`, LCT:23 (formatter) |
| 9.3 State words under shelf names: RUNNING, REUSABLE, PICK ONE | NOT BUILT | LS:53-61 returns "TO GET", "EMPTY" and "N OF M" only | `stateWords` is not extended |
| 9.1 Context line counts a running list ("2 lists, 1 running") | NOT BUILT | LS:42-43 never passes `running:` | LCT:14 (formatter) |
| Add line receipts stay thing first with "on"; UNDO 4 s | PASS (unchanged) | LV:298-315, LC:14-23 | LCT:29 |
| Receipts mask a "Private list" name and keep "Private item" | PASS | LV:309-313, LC:20-23 | no direct test of `spoken` |

Verdict: accepted for reusable and hold to reset. Two rows miss: 10.5 tapping outside does not fold the words (FAIL, LV:339), and the 10.4 right-to-left un-paint is NOT BUILT. The run, "done" ask and shelf state words have no screen yet.

---

## 4. PR #809 (91cf703): Builder B, object page hides list flags; Lists reusable lows; AppModel lint

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Object page never prints the list engine's lines ("#reusable", "#pick-one", "picked: ...") on an instance | PASS | OP:268-274, OP:538-549 | `flagLinesAreHidden`, ONT:6 |
| Same on a class page's prototype notes | PASS | OP:112 | ONT:6 (function level) |
| Only flag lines go; his own words stay as written, blank lines between them kept | PASS | OP:540-548 | `flagLinesAreHidden`, ONT:6 (the "Bring the blue one" case) |
| His own hash word ("#tbt photo") stays | PASS | OP:543 compares whole lines | `hisOwnHashWordsStay`, ONT:14 |
| A line he typed that starts with "picked: " is hidden too, on every object page | FAIL (low) | OP:543 uses `hasPrefix("picked: ")`, not a date check | no test; the stamp parser is stricter (LN:286-289) |
| A private object's notes still read "Note kept private" (the flag filter does not widen what shows) | PASS | OP:268 keeps `privateLabel == nil` first | no test |
| Option word reads with its state, "Reusable, on" / "Reusable, off", never colour alone | PASS | LV:326, LC:59-61, accessibility value LV:335 | `reusableAndResetReadThingFirst`, LCT:72-73 |
| A fast double tap on Reusable does not say "Didn't save" | PASS | LV:343-346 | no test |
| A refused Clear done says "Didn't save that. Try again." and keeps the fold | PASS | LV:414-418 | no test |
| Reset plays the cleared-run haptic, not the finish haptic | NOT PROVABLE | LV:198 | no test (haptic wiring) |
| Context line shows a turning mark that it opens (Design on #806) | PASS by read | LV:136-148 | no test |
| AppModel split is a move only (44 lines added in `AppModel+Training.swift`, 39 removed from `AppModel.swift`; the only new lines are a doc comment, the import lines and the extension braces) | PASS by read | `App/AppModel+Training.swift`; compile not provable here | no test |
| Receipts thing first with "on"; "Private item" and "Private list" labels exact | PASS (no change, re-read) | LC:14-23, LV:127, LS:64-66 | LCT:29, LCT:76 |

Verdict: accepted, with one low: a line he typed that begins "picked: " disappears from object pages (OP:543). The AppModel move is lint-only.

---

## 5. #801 (put away) and #802 (pick one): not on master

| K88 row | Verdict |
|---|---|
| 1b Put away and bring back a list; the put-away word at the foot (9.6) | not on master (#801) |
| G9 A finished non-reusable list is put away: "Packing, Lisbon put away." with UNDO 10 s | not on master (#801) |
| "Put away" option word (10.5) | not on master (#801) |
| 7a to 7d Pick one: `pick(from:)`, `pickedAt`, a skip writes nothing | not on master (#802) |
| 12.1 to 12.5 The pick moment; "That's all of them." | not on master (#802) |
| "Pick one" option word (10.5) and PICK ONE state word (9.3) | not on master (#802) |

`ListNoteTags` in #799 already carries the `#pick-one` flag and a `picked: ` stamp (LN:261-262, LN:286-298) with no caller; that is groundwork, not the feature.

---

## 6. Rows that wait on the Core follow-up (Product, Oct 17 9:45 am)

| Row | Verdict | Where it lands |
|---|---|---|
| Reset with nothing checked says "Packing, nothing to reset." | WAITS ON FOLLOW-UP | LR:84-86; tests RT:117 and the screen at LV:358-362 |
| Done when not running says "Packing isn't running." | WAITS ON FOLLOW-UP | LU:209-211; test UT:206 |
| A put-away basket counts as bought | WAITS ON FOLLOW-UP | PT:122-137, PT:147-152; Pantry's read of checked rows |

---

## Still open

1. #800: "Private list" masking on Now (LU:114 into NP:545, NP:573). Core, before any door starts a run.
2. #806: 10.5 tapping outside folds the option words (LV:339). Builder B.
3. #806 and #809: the other four option words (Sections, Run it, Pick one, Put away), the labels line under the hero (10.1), and the 10.4 right-to-left un-paint.
4. No screen calls `StartListRun` or `FinishListRun`: the run door, the "done" ask on a reusable list (RESET and NOT NOW), RUNNING and REUSABLE state words, "2 lists, 1 running", and Tess's run line are all unreached (9.1, 9.2 running first, 9.3, 9.7, 10.7, 10.11).
5. 4c `CopyList` and the three starter lists (Gym bag, Leaving the house, Packing): not built, no PR named.
6. #809: a line he typed starting "picked: " is hidden on object pages (OP:543). Low.
7. Carried from earlier acceptance docs and untouched by these four PRs: Lists side (13.5, 13.9), bare phrase to a list (G6), multi-item Add (10.8), list phrases (slice 8), dated items on Today, remove-by-phrase (10.10), paging between lists (10.6), item page (11.x).
8. The three follow-up rulings in section 6.

## Phone only

1. Hold the fold on a reusable list for 0.7 s: items come back unchecked, "Packing, reset." shows UNDO for 10 s; tap UNDO and the checks return.
2. Open a list, tap the context line, toggle Reusable on and off twice fast: "Packing, reusable." then "Packing, not reusable."; no "Didn't save that." on the second tap.
3. Name a list so the wall calls it private, then toggle Reusable and reset: every line says "Private list", never the name.
4. Open a reusable list's object page: no "#reusable" line shows; type your own note line and confirm it shows as written.
5. Reset haptic: the cleared-run feel, not the finish tap (LV:198).
6. Reduce Motion on: reset crossfades, no smooth slide.
7. VoiceOver: UNDO after a reset stays 10 s; the fold offers "Reset the list" as an action on a reusable list and "Clear them" on a plain one.
8. A run left overnight (12 hours): Now shows it as paused with its count. Only reachable once a door starts a run.

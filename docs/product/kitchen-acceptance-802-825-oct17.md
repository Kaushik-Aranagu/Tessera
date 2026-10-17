# Kitchen acceptance of #802, #819, #821, #823, #825: static read

Static only, against origin/master 6ca9ea8 (nothing built or run). Part A is Lists (#802, #823); Part B is Recipes and the object page (#819, #821, #825). Correction to the earlier #813 read: GroceriesView.swift:848 is the DEBUG demo seed, not the screen; the screen path is RecipePage.swift send(recipe:serves:) and it does use the result.

# Part A: Lists

# Lists acceptance: #802 and #823 (static read, origin/master 6ca9ea8)

Static read only. Nothing built or run (no Swift toolchain). Merges read with `git diff <merge>^1 <merge>`: #802 is 6029076, #823 is 3b6b9ac. Line numbers are on 6ca9ea8. PASS means the code does what the clause says at the line given. Every test named was read, none was run.

Specs: `docs/product/kitchen-lists-screen-walk-oct17.md` (K88), `docs/product/lists-screens-acceptance.md` (rows 9 to 12), `docs/product/lists-acceptance.md` section 7, and the open rows of `kitchen-acceptance-801-818-oct17.md` Part A and `kitchen-acceptance-k88-799-809-oct17.md`.

Refs: LP = `TesseraCore/Sources/TesseraCore/Lists/ListPick.swift`, LN = `.../Lists/ListNoteTags.swift`, LU = `.../Lists/ListRuns.swift`, LR = `.../Lists/ListReuse.swift`, PT = `.../Processes/ProcessTable.swift`, PK = `TesseraCore/Tests/TesseraCoreTests/ListPickTests.swift`, UT = `.../ListRunTests.swift`, PA = `.../ListPutAwayTests.swift`, RT = `.../ListReuseTests.swift`, LV = `Features/Lists/ListsView.swift`, LC = `Features/Lists/ListsCopy.swift`, LS = `Features/Lists/ListsShelf.swift`, NP = `Features/Home/NowPage.swift`, LCT = `TesseraTests/ListsCopyTests.swift`, LST = `TesseraTests/ListsShelfTests.swift`, ONT = `TesseraTests/ObjectNotesTests.swift`, OP = `Features/Objects/ObjectPage.swift`.

Product rulings of Oct 17, as asked of each section:
1. Reset with nothing checked says "Packing, nothing to reset."
2. Done when not running says "Packing isn't running."
3. A put-away basket counts as bought.
4. K36.2 says "Tacos, taken back."

Check of the four lines on 6ca9ea8 (none is built; detail in each section and in "Still open"):

| Line | Built now? | file:line | Covering test |
|---|---|---|---|
| "Packing, nothing to reset." | NOT BUILT | LR:85 throws the developer string "nothing checked on Packing"; the same in `ClearDoneItems` (`Lists.swift:460`); no spoken line anywhere in `Features/` | RT:117 asserts the throw type only |
| "Packing isn't running." | NOT BUILT | LU:116 and LU:218 throw "Packing, Lisbon isn't running" style strings built from the list title, no full stop, not spoken | UT:211 asserts "Packing isn't running" (no stop); PA:105 asserts "Packing, Lisbon isn't running" |
| Put-away basket counts as bought | NOT BUILT | the basket is kept and counted (LU:238-240, PT:150-158); no reader credits it (`PantryLedger.swift:117-143` reads only shop clears, `BuyCadence.swift` untouched) | no test |
| "Tacos, taken back." (K36.2) | NOT BUILT | grep for "taken back" finds it only in Plans and Workout; `BottomChrome.swift:739-748` runs UNDO and clears the line with no follow-up words; Lists says "back on" for a remove only (LV:303) | no test |

---

## 1. PR #802 (6029076): Core, pick one (K88 4 of 4)

Five files: `ListPick.swift` (new), `ListPickTests.swift` (new), registry, day-log drop list, intents catalog. No screen. `Features/` has no caller of `pick(from:)`, `AcceptPick` or `SetListPickOne`.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 7a `pick(from:)` returns only open items | PASS | LP:26 (`open(in:)`) | `pickReturnsOnlyOpenItems`, PK:56 |
| 7a Nil for an empty or finished list | PASS | LP:26-30 | `anEmptyOrFinishedListGivesNil`, PK:63 |
| 7b An item picked in the last 7 days is never chosen while others exist | PASS | LP:6, LP:27-30 | `anItemPickedInTheLastSevenDaysIsNeverChosenWhileOthersExist`, PK:107 |
| 7b The window is 7 days to the second | PASS | LP:28 (`>= pickWindow`) | `theWindowIsSevenDaysToTheSecond`, PK:113 |
| 7b When every open item was picked lately, one still comes up | PASS | LP:30 | `whenEveryOpenItemWasPickedRecentlyOneStillComesUp`, PK:121 |
| 7b A recently picked item that is done does not matter | PASS | LP:26 | `aRecentlyPickedItemThatIsDoneDoesNotMatter`, PK:128 |
| 7b Every open item can come up (no item starved) | PASS | LP:30 | `everyOpenItemCanComeUp`, PK:102 |
| 7b Fixed seed gives the same pick every time | PASS | LP:23-24 (generator passed in) | `aFixedSeedGivesTheSamePickEveryTime`, PK:93 |
| 7c Picking is a read: writes nothing, never checks an item, stamps nothing | PASS | LP:23-37 (no transaction) | `pickingWritesNothingAndNeverChecksAnItem`, PK:80 |
| 7c A skip writes no stamp and no op; the next pick leaves the skipped one out | PASS | LP:26 (`excluding`) | `aSkipWritesNoStampAndPicksAgainWithoutIt`, PK:137 |
| 12.3 / 12.4 Skipping every item ends in nil, not a repeat ("That's all of them." is the screen's) | PASS (engine half) | LP:26, LP:30 | `skippingEveryItemEndsInNilNotInARepeat`, PK:148; `aSkippedItemRecentlyPickedStillCountsAsSkipped`, PK:155 |
| 7c Accepting a pick (opening it) stamps `pickedAt`; never checks the item | PASS | LP:93-100 (`AcceptPick.apply`), LP:10-14 | `acceptingAPickStampsItAndNeverChecksIt`, PK:164 |
| 7c Accept is undoable and undo restores the stamp it had | PASS | engine undo of the `notes` write, LP:98-99 | `undoingAnAcceptRestoresTheStampItHad`, PK:174 |
| 7c Accept leaves the item's own notes alone | PASS | LN:39-44 (drops only the `picked: ` line), LP:98 | `acceptingLeavesTheItemsOtherNotesAlone`, PK:187 |
| 7c Shows in "What Tess did" only if Tess did it | PASS | `DayStory.swift:93` drops it from the day log; history keeps the actor | `tessDoingItShowsAsTessAndHisOwnDoesNot`, PK:212 |
| Accept refuses anything that is not a list item, writes nothing | PASS | LP:97 (`is: .listItem`) | `onlyAListItemCanBeAccepted`, PK:205 |
| "Pick one" is an option on the list: off by default, on and off with one UNDO | PASS | LP:40-80, LP:10-12 | `pickOneIsOffByDefaultAndTurnsOnAndOffWithUndo`, PK:223 |
| Pick one and Reusable are independent flags on the one notes line | PASS | LN:8, LN:24-30 | `pickOneAndReusableAreIndependentOptions`, PK:238 |
| Turning it on twice writes nothing | PASS (engine half; throws the developer string "Pick one is already on for Films", not spoken) | LP:68-73 | `turningItOnTwiceWritesNothing`, PK:246 |
| Receipts thing first, no "at": "Films, pick one on", "Paris, Texas, from Films" | PASS | LP:84-86, LP:110-114 | `everyReceiptIsThingFirstAndNeverSaysAt`, PK:256 |
| "Private item" masking: an accepted medicine item reads "Private item, from Films", receipt and summary | PASS | LP:105-114 (`AddListItem.shownTitle`) | `aPrivateItemsWordsNeverPrintWhenItIsAccepted`, PK:196 |
| "Private list" masking on the pick receipts and summaries (list name printed raw: `Films` title in LP:84-86, LP:107, LP:113) | FAIL (latent; no screen prints them yet) | LP:77, LP:84-86, LP:107, LP:113 use the raw list title | no test; PK:196 covers item words only |
| Same raw list title in the refusal strings | NOT PROVABLE (developer text, not spoken) | LP:71 | no test |
| Both actions decode from a tool call, are in the registry, dropped from the day log, marked in-app only | PASS | `ActionRegistry.swift:23`, `:90-91`; `DayStory.swift:93`; `TesseraRuntime.swift:83-84` | `theActionsDecodeFromAToolCall`, PK:266 |
| The stamp is hidden on object pages (exact ISO stamp only; a typed "picked: the blue one" stays) | PASS | OP:538-549 (via #825 ac1fe78) | `flagLinesAreHidden`, ONT:8; the typed-line case ONT:19-20 |
| `AcceptPick` drops a note line he typed that starts "picked: " when it stamps | FAIL (low, latent) | LN:40 filters every `hasPrefix("picked: ")` line, not only a dated stamp, so the stamp write erases his line; undo restores it | no test; PK:187 uses "Seen it once" |
| Groceries cannot take Pick one (parallel to 4d for Reusable) | NOT PROVABLE (no clause asks for it) | LP:66-67 has no Groceries guard, unlike `SetListReusable` (LR:35-37) | no test |
| 7d / slice 8 phrase "pick from films" | NOT BUILT | no rule in `TessGrammar+Kitchen.swift`; the registry marks it "Lists slice 8" | no test |
| 12.1 to 12.5 the pick moment (hold 0.6 s, dim to 14%, lift, grow in 520 ms, tap opens, swipe skips, "That's all of them.", Reduce Motion crossfade) | NOT BUILT | no view; no caller of `pick(from:)` in `Features/` | no test |
| 10.5 "Pick one" option word (LV:364-397 has Run it and Reusable only; LV:362 says it arrives later) and 9.3 PICK ONE state word (`ListsShelf.swift` state words stop at TO GET, EMPTY, N OF M, RUNNING, REUSABLE) | NOT BUILT | LV:362-397, LS:59-62 | no test |
| UNDO windows for a pick (accept or option change) | NOT PROVABLE | the ops are undoable (PK:174, PK:223); no screen speaks them, so no hold is set | no view test |
| Thing-first receipts for Core's other lines (no "at" before a clock) | PASS | LP:84-86, LP:110-114 | PK:256 |

Verdict for #802: accepted for the Core half (7a to 7c, the option, the receipts). Rows it still leaves: the pick moment 12.1 to 12.5, the "Pick one" option word and PICK ONE state word, the phrase, and the screen UNDO. One latent miss: "Private list" is not masked on the pick receipts and summaries (LP:84-86, LP:107, LP:113). One low miss: `AcceptPick` erases a typed "picked: ..." note line (LN:40).

---

## 2. PR #823 (3b6b9ac): Builder B, reusable done ask (RESET hold, NOT NOW), sections that fold

Five files: `ListsView.swift`, `ListsCopy.swift`, `NowPage.swift`, `ListsCopyTests.swift`, `ListsShelfTests.swift`.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| 10.11 "Done" on a reusable list with items checked finishes the run, keeps the strikes and asks | PASS | LV:423-449; keep-strikes is Core, LU:130-131 | strikes kept in Core: `finishingAReusableListKeepsEveryStrikeAndDoesNotReset`, UT:190; no view test |
| The ask reads "Packing, done. Reset it for next time?" | PASS | LV:456, LC:63-66 | `theResetAskNamesTheListFirst`, LCT:86-89 |
| The ask sits under the hero, above the Add line, in Tess's voice colour, with a move/opacity entrance | PASS by read | LV:178-182, LV:456-459 | no view test |
| RESET is a 0.7 s hold with the ink line filling; never a tap | PASS by read | LV:461-465 (`PaintKey`, `duration: 0.7`, hold key; `DesignSystem/Paint.swift:233` fires after the hold) | no view test |
| Holding RESET resets: "Packing, reset." with UNDO 10 s | PASS | LV:462-464 into `reset(name:)` LV:493-505, say at LV:504 (default UNDO hold is 10 s, `HomeQueue.swift:45-52`) | engine: `resetIsOneActionAndOneUndoBringsBackTheChecks`, RT:96; through the model: `aReusableListResetsAndUndoChecksThemAgain`, `ListsReuseTests.swift` (#806); the hold itself no test |
| NOT NOW closes the ask and changes nothing | PASS | LV:467-471 (only clears `resetAsk` and plays the haptic) | no view test |
| 10 s of silence changes nothing, the ask goes away | PASS | LV:442-447 (`TessVoice.hold(undo: true, holds: .seconds(10))`; VoiceOver is also 10 s) | no test |
| NOT NOW has its own haptic trigger | PASS | LV:131, LV:237, LV:469 | no test |
| Reduce Motion on the ask | PASS by read (animation goes through `withTesseraAnimation`) | LV:441, LV:445, LV:463, LV:468 | no test |
| Labels read RESET and NOT NOW in capitals | NOT PROVABLE | LV:465 `Text("Reset").textRole(.labelStrong)` has no `.textCase(.uppercase)`; LV:467 `Button("Not now")` uses `.labelWord`; whether either style uppercases needs a run | no test |
| Ask names a walled list as "Private list" | PASS | LV:141-142 (shown name) into LV:456 | `theResetAskNamesTheListFirst`, LCT:89 (string only) |
| "Private item" never reaches the ask | PASS | the ask prints the list name only | no test |
| A plain list still says its receipt: "Packing, done." / "Packing, done. 3 left." with UNDO 10 s | PASS | LV:450, LC:89 | `runLinesUseTheShownName`, LCT:79-84 |
| A reusable list finished with nothing checked says "Packing, done." with UNDO | PASS (no ask to give) | LV:439 (`checked > 0`), LV:450 | no test |
| The finish that opens the ask has no UNDO of its own (the op's UNDO is dropped when the ask shows) | FAIL (low) | LV:439-448 returns before the `say(..., undo:)` with the finish op at LV:450 | no test |
| Ruling 1 on the ask's path: if every strike is unchecked from the fold while the ask is open, RESET has nothing to reset | FAIL | LV:496-498 says "Didn't save that. Try again." (Core throws at LR:85); the ruling wants "Packing, nothing to reset." | no test |
| Ruling 1 anywhere: "Packing, nothing to reset." | NOT BUILT | LR:85, LV:496 | RT:117 asserts the throw type only |
| 10.7 Sections fold away as they finish (the list is keyed by section name, a section with nothing open leaves) | PASS (structure) | LV:186-211 (`ForEach(sections(open), id: \.name)`, `.transition` with a scale-and-fade removal, opacity only for Reduce Motion) | no test |
| 10.7 The fold animates when the last open row of a section is checked | FAIL (by read) | the check path runs `CheckListItem` and `model.touch()` with no animation transaction (LV:310-316); a transition only plays inside an animation, so the section vanishes at once on a check. The remove path is wrapped (LV:297) and does animate | no test |
| 10.7 A removed last row finishes its section the same way | PASS | LV:297 (`withTesseraAnimation` around `model.touch()`), LV:201 | no test |
| Keying by name does not re-key later sections when one folds | PASS by read | LV:187-191 (comment; names are unique because `sections()` groups by name, LV:257-267) | no test |
| Ledger row step no longer repeats the name: "1 left" / "nothing left" under the title | PASS | NP:585-589 | `aPausedPrivateRunNeverShowsItsName`, LST:105 (`shown.nextStep == "1 left"`, no "Rent") |
| "Private list" still holds on Now's ledger row after the NP change | PASS | NP:585-589 builds the title and step from the shown name and the live count | LST:105-108 |
| #806 miss: tapping outside folds the option words | FAIL (not fixed) | LV:395-396 still puts the tap on the option row only; nothing else on the page folds them | no test |
| #806 miss: 10.4 right-to-left un-paint of the strikes on reset, then the items rise back | NOT BUILT (not fixed) | LV:499-502 only closes the fold with a 0.48 s smooth animation (crossfade under Reduce Motion); no un-paint; done rows live in the fold, not struck in the page | no test |
| Reset haptic is the cleared-run feel | PASS by read | LV:241, LV:503 | no test (haptic wiring) |
| Reset hold on the fold of a reusable list still works beside the ask | PASS (unchanged) | LV:507 onward, LV:393-406 (as #806) | as #806 |
| 10.11 Plain list "done" with nothing open is put away: "Packing, Lisbon put away." with UNDO 10 s (G9) | FAIL (still the #814 miss) | LV:450 always speaks `runDone`; `result.output.putAway` (LU:122) is never read | no test |
| 10.5 other option words (Sections, Pick one, Put away), 10.1 labels line under the hero | NOT BUILT (untouched) | LV:362-397 | no test |
| Receipts thing first, no "at" before a clock; exact labels "Private list" and "Private item" | PASS | LC:63-66, LV:141-142, LS:91-93 | LCT:79-89, LST:105 |

Verdict for #823: not accepted on these rows. (1) 10.7 the fold animation does not run on a check (LV:310-316). (2) Ruling 1 is reachable and wrong on the ask path (LV:496). (3) The two #806 misses, tap outside folds the option words (LV:396) and the right-to-left un-paint (LV:499-502), are untouched. (4) Low: the finish that opens the ask has no UNDO (LV:439-448). The ask itself (copy, RESET hold, NOT NOW, 10 s quiet, masking) is built and matches 10.11.

---

## Still open

1. Ruling 1, "Packing, nothing to reset.": LR:85 (Core), `Lists.swift:460` (clear done, same pattern), LV:496 (screen, and reachable via the ask path), test RT:117.
2. Ruling 2, "Packing isn't running.": LU:116 and LU:218 (developer strings built from the list title); tests UT:211 and PA:105 assert the old strings. The screen shows Done only while a run is open (LV:366-376), so it needs Core to speak.
3. Ruling 3, a put-away basket counts as bought: the basket is kept and counted (LU:238-240, PT:150-158) but no reader credits it (`PantryLedger.swift:117-143`, `BuyCadence.swift`). Needs an owner.
4. Ruling 4, K36.2 "Tacos, taken back.": not built for Lists or Groceries; UNDO only clears the line (`BottomChrome.swift:739-748`).
5. #823: 10.7 sections fold on a check (wrap LV:310-316 in the house animation); the reset ask's finish has no UNDO (LV:439-448).
6. #806 carried, still open after #823: tap outside folds the option words (LV:396); right-to-left un-paint (LV:499-502); labels line under the hero (10.1); Sections, Pick one and Put away option words.
7. G9 on the screen: finishing a plain list with nothing open must speak "Packing, Lisbon put away." (LV:450 ignores `putAway`); the shelf must use `shelf()` (LS:35); put-away word at the foot (9.6, 10.12); "Put away" option word; no screen calls `PutAwayListRun`.
8. #802 screen half: pick moment 12.1 to 12.5, "Pick one" option word, PICK ONE state word, "pick from films" phrase, screen UNDO for pick changes.
9. "Private list" masking on Core receipts and summaries: pick (LP:84-86, LP:107, LP:113), put away and finish (LU:138-148, LU:225-233), reset and reusable (LR:55, LR:101), and the stored run line (LU:9-12, `NowPicker.swift:66`). Latent until a surface prints them.
10. `AcceptPick` removes a typed "picked: ..." line when it stamps (LN:40). Low.
11. `CopyList` (4c) and the three starter lists; Lists side 13.5 and 13.9; bare phrase to a list (G6); multi-item Add (10.8); list phrases (slice 8); dated items on Today; remove-by-phrase (10.10); paging between lists (10.6); item page (11.x).
12. A running list as Now itself: `HomeLines.fact(process:)` returns nil for it (`HomeLines.swift:495-523`).

## Phone only

1. Reusable list with items checked: tap Run it, then Done. The ask "Packing, done. Reset it for next time?" shows under the hero with RESET and NOT NOW. Check the words read in capitals, and that the strikes are kept.
2. Hold RESET for 0.7 s: the ink line fills, items come back unchecked, "Packing, reset." shows UNDO for 10 s; UNDO checks them again. Release early: nothing changes.
3. Tap NOT NOW: the ask goes, the soft haptic plays, nothing changes. Wait 10 s without touching: the ask goes, nothing changes. With VoiceOver on, confirm RESET completes on a double tap and the ask stays 10 s.
4. With the ask open, open the fold and uncheck every item, then hold RESET: today it says "Didn't save that. Try again." (the ruling 1 miss).
5. Check the last open item of a section on a running list: confirm whether the section folds away with the scale-and-fade or just vanishes (the code says it vanishes). Then swipe-remove the last row of another section: it should fold. Reduce Motion on: a fade only.
6. Name a list so the wall calls it private, run it, finish it: the ask and every line say "Private list", never the name.
7. Tap an empty part of the page while the option words are open: today nothing happens (the #806 miss). Reset a reusable list and watch for a right-to-left un-paint: today the fold just closes.
8. Pick one has no screen: nothing to try on the phone until the pick moment lands.
9. Ledger row for a paused list run on Now: the title reads the list name (or "Private list") and the step under it reads "2 left", not "Packing, 2 left".

# Part B: Recipes and object page

# Acceptance: #819, #821, #825 (static read, master 6ca9ea8)

Read only. Nothing was built or run. "Covering test" means a test in the tree asserts it and I read the assertion; I did not run it. Diffs read with `git diff <merge>^1 <merge>`. Checked against `docs/product/kitchen-gap-hunt-9-recipes-link-oct17.md` (G54, G65 to G69), `kitchen-acceptance-801-818-oct17.md` Part B (open rows) and `kitchen-groceries-screen-walk-oct17.md`. Paths are under `/home/user/Tessera`. Core = `TesseraCore/Sources/TesseraCore`, Tess = `TesseraCore/Sources/TesseraTess`.

Correction applied: `Features/Groceries/GroceriesView.swift:848` is the DEBUG demo seed, not the add path. The real add path is `Features/Recipes/RecipePage.swift` `send(recipe:serves:)` (line 244), reached from the swipe (`sendGesture`, line 224) and from VoiceOver's action on the Ingredients container (line 360).

Verdict key: PASS, FAIL, NOT BUILT, NOT PROVABLE (needs a run or the phone).

## 1. PR #819 (5481c07): the recipe add's UNDO follows him (G67); one "Add all to Groceries" action (G68)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Leaving the page inside the 10 s window hands the receipt and its UNDO to the shared Tess line | PASS | Features/Recipes/RecipePage.swift:158-167 (`onDisappear` calls `TessVoice.shared.say(sent.line, undo: the sent op)`) | no test (view code) |
| The page's own copy is cleared on hand-off, so the line is never drawn twice and the old 10 s task stands down | PASS | RecipePage.swift:164-165 (`sent = nil`, `away = false`), guard at :268 (`sent?` no longer matches) | no test |
| The UNDO lives in `TessVoice.shared` (Features/Home/HomeQueue.swift:15-42), not in page state, so it survives Close and "Recipes" | PASS | HomeQueue.swift:32-41 (note held, UNDO 10 s, VoiceOver flat 10 s at :45-52) | no test |
| That shared line is drawn somewhere he can reach after leaving the recipe | NOT PROVABLE | Readers of `TessVoice.shared.note`: Features/Command/BottomChrome.swift:148, 731-739, Features/Groceries/GroceriesView.swift:698, Features/Kitchen/PantryView.swift:93. Whether the bottom chrome is on screen over Recipes and the Recipe shelf needs a run. The nothing and failed lines already rely on the same route (RecipePage.swift:252-256). | no test |
| UNDO from the shared line reverses the add | PASS | Same op handed over (the sent receipt's op); BottomChrome.swift:739 draws UNDO when `note.undo != nil` | `RecipeSendTests.anAddSaysHowMany` covers the op and line (TesseraTests/RecipeSendTests.swift:22); the hand-off itself has no test |
| The window restarts on hand-off: UNDO holds a full 10 s from leaving, not the time left | PASS (note) | HomeQueue.swift:35-37 | no test; harmless, longer not shorter |
| Same hand-off fires when he pushes ingredient depth from the same page (not only on leaving the recipe) | NOT PROVABLE | RecipePage.swift:150-153 (`navigationDestination`) and :158; on return the on-page line is gone and the UNDO sits on the shared line instead. Inferred; needs a run. | no test |
| Announcement spoken once on add | PASS | RecipePage.swift:265 (unchanged); not repeated on hand-off | no test |
| The row-level VoiceOver action "Add to Groceries" is gone from every ingredient row | PASS | RecipePage.swift:348-356 (rows now offer only "Show in metric", and only when the line has a metric form) | no test |
| One action on the Ingredients container as a whole, named "Add all to Groceries" | PASS | RecipePage.swift:357-360 (`accessibilityAction(named: Text(RecipeCopy.addAllAction), onAdd)`), label constant at :463 | `RecipeSendTests.theVoiceOverActionSaysAll` (TesseraTests/RecipeSendTests.swift:74-76) |
| The label is read from the same constant the view uses (test cannot drift from the screen) | PASS | RecipePage.swift:360 and :463 | RecipeSendTests.swift:75 |
| Container still announces as "Ingredients" and rows stay one stop each | PASS | RecipePage.swift:343-346, 357-359 | `RecipeSendTests.eachRowIsOneSpokenStop` (:49) |
| The VoiceOver add reaches the same `send(recipe:serves:)` as the swipe (so private, nothing and failed forms hold) | PASS | RecipePage.swift:90 (`onAdd` closure), :244-259 | `aPrivateRecipeSaysPrivateRecipe` (:56), `onlyStaplesSaysNothingToAdd` (:36), `aRefusalSaysDidntSave` (:42) |
| VoiceOver path refuses a second send while a receipt is up (a second add replaces the first UNDO) | FAIL | The swipe has `sent == nil` guards (RecipePage.swift:227, 233); `send` itself and the VoiceOver action do not. This is the G72 residual, unchanged by #819. | no test |

PR verdict: accepted. G67 and G68 close in code. The one residual is the VoiceOver path with no `sent == nil` guard (G72), and the drawn location of the shared line is a phone check.

## 2. PR #821 (53f62c7): Paste refuses password links; the secret-link line is wired (G54 rows)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| A pasted bare link with a name or password is refused whole the moment it lands | PASS | Features/Recipes/PasteRecipe.swift:133-139 (`RecipePasteLink.isSecretLink(new)` first in `onChange(of: text)`) | `PasteCycleTests.aLinkWithAPasswordIsNeverKept` (TesseraTests/PasteCycleTests.swift:40-46) asserts `isSecretLink` |
| The ruled line shows: "That link has a password in it. Paste the text instead." | PASS | PasteRecipe.swift:135 sets `linkLine`; text drawn at :41-43; string at Tess/RecipeLinkReader.swift:18 | PasteCycleTests.swift:45 asserts the string |
| The line reads in ink, not Tess's colour | PASS | PasteRecipe.swift:44-46 | no test (view code) |
| The box is emptied, so the link is never read, kept, saved or printed back | PASS | PasteRecipe.swift:136-138 (`reading = false`, `text = ""`, return before any reader); Tess/RecipeLinkReader.swift:122-123 and :287 also refuse in Core | RecipePasteLinkTests (Core, TesseraCore tests) from #807 cover the Core refusal; the Paste wiring has no test |
| The link is not echoed in the line | PASS | PasteRecipe.swift:135 uses the fixed string | PasteCycleTests.swift:45 |
| The refusal line goes away once he pastes something else | FAIL | `linkLine` is cleared only in `readLink` (PasteRecipe.swift:229-230) and `edit()` (:249). After the refusal, pasting a normal recipe leaves `linkLine` set, and line 42 shows `linkLine` before the idle or count line, so the password message keeps standing over the recipe he pasted next, in ink. Inferred; needs a run. Same stale-line shape already existed for the offline keep line. | no test |
| A longer paste that holds a password link anywhere never reaches the miss log | PASS | PasteRecipe.swift:274 (`!PasteCopy.hasSecretLink(text)`), helper at :504-506 splits on whitespace and tests each word | PasteCycleTests.swift:43-44 (secret case true, clean case false) |
| A longer paste that holds a password link is itself refused, kept out of the box, the brush and the saved recipe | NOT BUILT | `isSecretLink` needs a whitespace-free link (Tess/RecipePasteLink.swift:23-30), so a link inside a recipe paste is painted, can be saved as a step or source, and shows on screen. Only the miss log is protected. | no test |
| A read that finishes after he edited the box drops its result (his edit wins) | PASS | PasteRecipe.swift:227-232 (`guard RecipePasteLink.bareLink(text) == link`, then `linkLine = nil`) | no test |
| That dropped read leaves nothing behind | NOT PROVABLE | `RecipePasteLink.read` runs the shelf keep before the view's guard (PasteRecipe.swift:223-226 then :229), so an offline read that he then edits away still left the link on the shelf. Needs a run and a look at the shelf file. | no test |
| Secret link no longer unwired (open row in the 801-818 acceptance, Still open 6) | PASS | PasteRecipe.swift:133-139, 504-506 | PasteCycleTests.swift:40-46 |
| Offline keep: box emptied against ER1 (Still open, "offline keep empties the box") | FAIL | PasteRecipe.swift:240-243 (`text = ""` when `outcome.kept`). Unchanged by #821. | no test |
| Shelf has a door: list waiting links, read on his tap, remove one, erase all (G65) | NOT BUILT | `RecipeLinkShelf.waiting()` (Tess/RecipePasteLink.swift:87) and `erase()` (:105) have no caller in Features or App; Features only call `beside` and read. | Core only: `theShelfHoldsFiftyAndErases` |
| Timeout and DNS wording (G63), fragment and query items (G64) | FAIL | Tess/RecipeLinkReader.swift:312-326 and the offline switch near :217-220 not touched by this PR; RecipePasteLinkTests.swift:103-104 still pins `cannotFindHost` as not offline. | still pinned the old way |

PR verdict: accepted for the bare password link. Rows that miss: the refusal line stays up after a later paste (stale `linkLine`), and a password link inside a longer paste is still painted and saveable (only the miss log is guarded).

## 3. PR #825 (6ca9ea8): the "picked:" stamp hides on an exact match only (#809 low, ObjectPage.swift:543)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| A line is hidden only when it is "picked: " followed by an ISO 8601 date | PASS | Features/Objects/ObjectPage.swift:545-548 (`isPickedStamp`) | `ObjectNotesTests.onlyTheExactPickedStampIsHidden` (TesseraTests/ObjectNotesTests.swift:18-21) |
| The engine's own stamp ("picked: 2026-10-17T18:00:00Z") is still hidden | PASS | ObjectPage.swift:545-548; stamp is written by `date.formatted(.iso8601)` in TesseraCore/Sources/TesseraCore/Lists/ListNoteTags.swift:~46 and parsed back with the same strategy at :~37 | ObjectNotesTests.swift:19 |
| A line he typed that starts "picked: " ("picked: the blue one") is shown | PASS | ObjectPage.swift:546-547 (date parse fails, returns false) | ObjectNotesTests.swift:20 |
| `#reusable` and `#pick-one` still hidden; his own `#tbt photo` stays | PASS | ObjectPage.swift:553 | `ObjectNotesTests` existing rows (ObjectNotesTests.swift:~8-15) |
| Both object-page callers get it (item notes and prototype notes) | PASS | ObjectPage.swift:112, 269 both go through `ObjectNotes.shown` | no test at the call sites |
| Leading or trailing space on the stamp line | PASS | ObjectPage.swift:552 trims before the test | no test |
| Comment claim "as Core matches it" | FAIL | Core matches by prefix only: `ListNoteTags.stamp` takes the last "picked: " line and `setting(stamp:)` drops every "picked: " line before re-stamping (ListNoteTags.swift: `lines.filter { !$0.hasPrefix(prefix) }`). So the page now shows his typed line, but the next pick in Core still deletes it, and a typed line placed last makes the stamp read as nil. The data side of the #809 low is open. | no test |
| Mixed notes (stamp plus typed lines, typed "picked: " line plus real stamp) | NOT PROVABLE | Logic reads correct line by line (ObjectPage.swift:550-554); the test has only single-line inputs. | no test |

PR verdict: accepted for the page (the #809 low at ObjectPage.swift:543 is closed). The row that misses is the comment's claim: Core's prefix match in ListNoteTags.swift can still erase or hide a typed "picked: " line on the next pick.

## Gap status

| Gap | State | Why |
|---|---|---|
| G54 link on Paste | Partly closed | Wire, link line, Read it key, offline keep, Claude switch (#811) and now the password refusal (#821 for a bare link) are built. Open: the refusal line goes stale, a password link inside a longer paste is not refused, the offline keep empties the box against ER1 (PasteRecipe.swift:240-243), G63 and G64 untouched, G65 below. |
| G65 shelf door and eraser | Open | `waiting()` and `erase()` have no caller in Features or App; the link leaves the box on an offline keep and no screen lists it. |
| G67 UNDO lives in page state | Closed in code | RecipePage.swift:158-167 hands the receipt and UNDO to `TessVoice.shared` on leaving. Phone check: that line is drawn where he lands. |
| G68 per-row "Add to Groceries" adds the whole recipe | Closed | Row actions removed (RecipePage.swift:348-356); one container action "Add all to Groceries" (:360, :463) with a test. |
| Related, not in this set | Open | G66 bigger-size receipt count, G69 Dynamic Type, G70 failed-send form, G72 residuals (including the VoiceOver `sent == nil` guard). |

## Still open

1. Clear `linkLine` when the box changes to anything that is not a refused link (PasteRecipe.swift:133-139 and :42), so the password line does not stand over the next paste; add a test.
2. Refuse or cut a password link inside a longer paste before the brush paints it and before save, not only at the miss log (PasteRecipe.swift:274, 504-506).
3. G65: a door for waiting links (read on his tap, remove) and `erase()` wired into the erase-everything path; decide the ER1 clause on whether the box keeps the link after an offline keep (PasteRecipe.swift:240-243).
4. G63 and G64 in Tess/RecipeLinkReader.swift (timeout and DNS wording kept for later, 15 s cut, fragment and wider query list); flip the pinned test at RecipePasteLinkTests.swift:103-104.
5. ListNoteTags: make `setting(stamp:)` and `stamp` match the exact stamp too, so a typed "picked: " line is never dropped or shadowed.
6. Guard the VoiceOver add with `sent == nil` (RecipePage.swift:244) so a second add does not replace the first UNDO.
7. A short test that the hand-off fires (the `onDisappear` branch has none), and a read-dropped-by-edit test.
8. Carried from the 801-818 acceptance: one shared limits constant, RecipePage.swift:553 raw total time, G66 residual, G69 to G72, the drum for a recipe that serves 49 to 100.

## Phone only

1. Swipe Tacos to Groceries, then tap Close or "Recipes" inside 10 s: "Tacos, 7 added." with UNDO is visible on the screen he lands on, UNDO removes the rows, and the line leaves after about 10 s (VoiceOver: flat 10 s).
2. Push an ingredient from the recipe right after an add, come back: confirm the on-page line is gone and the UNDO is on the shared line (the hand-off also fires on a push).
3. VoiceOver on the recipe page: the Ingredients actions list "Add all to Groceries" once; no ingredient row offers an add; "Show in metric" stays on rows that have one; the add announces the line once.
4. Paste a link with a name and password: the ink line appears, the box empties, nothing is read or kept; then paste a normal recipe and see whether the password line stays up.
5. Paste a recipe whose body holds a password link on one line: see whether it is painted and saved.
6. Read a link, edit the box while it reads: the result is dropped; offline, check whether the shelf file kept the link anyway.
7. On an object with a note "picked: the blue one" the line shows; after the list engine stamps a pick on the same object, check whether his line survives.

# Kitchen acceptance of #826, #831, #832: static read

Static only, against origin/master c29d1e2 (nothing built or run). All three PRs are engine-only: nothing under Features/ or App/ changed, so none of the new lines is spoken on the phone yet.

# Acceptance: #826 (2f426c9), #832 (6ed565a), #831 (31f11ad), static read on master c29d1e2

Read only. Nothing built or run; "covering test" means I read the assertion, I did not run it. Diffs read with `git diff <merge>^1 <merge>`. Checked against `kitchen-acceptance-801-818-oct17.md` (A), `kitchen-acceptance-802-825-oct17.md` (B), `kitchen-acceptance-820-829-oct17.md` (C). Paths under `/home/user/Tessera`. Core = `TesseraCore/Sources/TesseraCore`. LR = Lists/ListReuse.swift, LU = Lists/ListRuns.swift, LP = Lists/ListPick.swift, LN = Lists/ListNoteTags.swift, LL = Lists/Lists.swift, LV = Features/Lists/ListsView.swift. Line numbers are on c29d1e2, so they differ from the older docs.

Headline: all three PRs are engine-only. No file under Features/ or App/ changed in any of them, and the Lists screen builds its own wording in `ListsCopy.swift`, so none of the new lines is spoken on the phone yet.

## PR #826 (lists wording rulings, K36.2 in the engine, put-away basket)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| "Packing, nothing to reset." Reset with nothing checked is a quiet no-op: no throw, no write, no UNDO (A "Still open 1", B "Still open 1", old row LR:85) | PASS (engine) | LR:86 returns 0; receipt LR:109-116; summary LR:99-102 | `resetWithNothingCheckedIsAQuietNoOp` (ListReuseTests; also asserts `ops.isEmpty` and the next real reset says "Gym bag, reset") |
| Same line on `ClearDoneItems` for a reusable list, from this run's own count (B "Lists.swift:460") | PASS (engine) | LL:485-492 calls `ResetList.receipt(for:unchecked:)`; LL:469 still throws for a plain list with nothing checked ("nothing checked on <shown name>"), developer text, not spoken | `aRealClearAfterANoOpResetSaysReset` |
| Count carried per op, never through shared state (QA on #826) | PASS | EngineAction.swift new `summary(in:output:)` and `receipt(in:output:)` defaults; ActionEngine.swift:58 and :62 pass `output` | `aRealClearAfterANoOpResetSaysReset` |
| "Packing isn't running." (full stop, list name masked) for Done and Put away on a list that is not running (A "Still open 2", old rows LU:116 and LU:218) | PASS (engine) | LU:155-158 `notRunningLine`; used at LU:135 and LU:246 | `finishingAListThatIsNotRunningWritesNothing` (ListRunTests, new string); ListPutAwayTests (string with full stop, as the diff shows) |
| "Private list" in every list receipt and summary: add, check/un-check, clear, reset, reusable, pick one, pick, create, start, finish, put away | PASS (engine) | LL:143-153, LL:290, LL:297, LL:356, LL:476, LL:489; LR:51-56, LR:96, LR:115; LP:68, :77, :81, :116, :124; LU:85, :163-175, :253-260 | `everyListLineMasksAPrivateListName`, `aPrivateListIsNeverNamedInAResetOrFlag`, `acceptingAPickKeepsHisPickedNoteAndMasksAPrivateList`, `aPrivateListRunShowsOnlyItsLabel` |
| Pick receipts and summaries (old leaks LP:84-86, :107, :113, B) | PASS | LP:116 and :124 (accept), LP:77 and :81 (pick-one flag) | `acceptingAPickKeepsHisPickedNoteAndMasksAPrivateList` ("Heat, from Private list", "Private list, pick one on") |
| Pick-one refusal string (old LP:71) | PASS (developer text) | LP:68 | no test (not spoken) |
| Stored run line masked (old LU:9-12, `NowPicker.swift:66` returns it) | PASS | LU:9-14 `runLine` uses `shownName`; `NowPicker` reads the stored line so it inherits the mask | `aPrivateListRunShowsOnlyItsLabel` (`running()?.nextStep == "Private list, 6 left"`) |
| Ledger row (the process title) masked at start, including a put-away list that comes back | PASS | LU:75-80 `setTitle(shown, on: process)` | `aPrivateListRunShowsOnlyItsLabel` (`object.title == "Private list"`; start path only, the resumed-from-Later branch shares the same lines) |
| One shared label | PASS | LU:17 `privateListLabel = "Private list"` | `aPrivateListRunShowsOnlyItsLabel` |
| Remaining raw list title in a refusal: `SetListReusable` "already reusable" | OPEN (low, developer text) | LR:43 `"\(list.title) is already ..."` | no test |
| Masking test used by the engine vs the screen: engine `ObjectPrivacy.isPrivateWord(title, in: store)`, shelf `ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg:)` | NOT PROVABLE (same wall, two entry points) | LU:20 vs Features/Lists/ListsShelf.swift:96 | no test ties the two |
| "Tacos, taken back." (K36.2) in the engine: recipe-link line | PASS | Tess/RecipeLinkReader.swift:62 `takenBack` | `theLinesAreTheTable` (RecipeLinkTests, "Chili mac, taken back.") |
| "Set 2, taken back." for the Siri/Shortcuts undo | PASS | TesseraIntents/Intents.swift:85 | no test |
| K36.2 UNDO on the shared line says "Tacos, taken back." for Lists and Groceries (B "Still open 4", `BottomChrome.swift:739-748`) | NOT BUILT | Features/Command/BottomChrome.swift:739-748 unchanged: `undo()` runs the engine undo then `voice.clear()`, no follow-up words. `RecipeLinkLine.takenBack` has no caller in Features. Plans already says it (Features/Plans/Receipts.swift:9) | no test |
| A put-away basket counts as bought: engine reader | PASS (engine only) | Kitchen/Groceries.swift:135-153 `putAwayBasket()` (checked rows of the shop's latest process, only while that process is in Later, on the day each was checked) | `aPutAwayBasketCountsAsBought` (ShoppingIdleTests: empty while running, empty while idle, 12 after Later, empty again after `StartShop`) |
| That reader is used by Pantry and the buy cadence (A "Still open 3", B "Still open 3", C row "A put-away list run counts as bought") | NOT BUILT | grep for `putAwayBasket` finds only its definition: no caller in `Features/Kitchen/PantryLedger.swift`, `PantryView.swift`, `Kitchen/BuyCadence.swift` or anywhere else | no test of a reader |
| Flags are exact whole lines: " #reusable", "#reusable!", "pack #reusable bags", "#Reusable" are his note (ruling 1 in the diff comment) | PASS | LN:19-23 `has`, LN:25-31 `setting` | `flagsAreExactWholeLines` |
| Stamp is exact: "picked: " then an ISO date and nothing else; "picked: up at 5" is his note and survives | PASS | LN:34-46 `stamp` and `stampDate`, LN:49-55 `setting(stamp:)` filters only real stamps | `onlyAnExactStampIsAPick` |
| `AcceptPick` no longer erases a typed "picked: " line (B "Still open 10", old LN:40) | PASS | LN:49-55 | `acceptingAPickKeepsHisPickedNoteAndMasksAPrivateList` (notes keep "picked: up at 5" and a real stamp is added) |
| Page hides only the stamp, not his typed line (OP:543, A "Still open 12") | NOT PROVABLE | Features/Objects/ObjectPage.swift near :543, not touched here; the shape agrees with Core now, needs a read of the page or a run | no test |
| Screen speaks "Packing, nothing to reset." (A "reset" row, B row "Ruling 1 on the ask's path") | NOT BUILT | LV:540-549 `reset(name:)` ignores the engine receipt and always says `ListsCopy.reset(name)` ("Packing, reset.") with UNDO on the returned op. New danger: the engine no longer throws, so the old "Didn't save that. Try again." path is gone and an empty reset now says "reset" with an UNDO that undoes nothing | no test |
| Screen speaks "Packing isn't running." | NOT BUILT (unreachable) | Done shows only while a run is open (LV:449 path); the string is only reachable from Tess or a Shortcut | no test |
| Screen speaks the ledger/Now mask for a list that is Now itself | NOT PROVABLE | Features/Home/NowPage.swift:586 masks through `ListsShelf.shownName`; whether a running list draws as the hero is the A "Still open 7" question | no test |
| Screen Done speaks "put away" (G9) | PASS (closed by #823 and #820, not by this PR) | LV:476-478 | see C |

## PR #832 (recipe times up to 4320 minutes through one shared constant)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| Time cap is 3 days, 1 to 4320 minutes, one constant | PASS | Kitchen/RecipeLimits.swift:9 | `aTwoDayFermentKeepsItsTime` (`RecipeLimits.minutes == 1 ... 4320`, 2880 reads 2880, 5000 reads 4320) |
| Engine reads go through the constant | PASS | Kitchen/Recipes.swift:66-72 (`totalMinutes`, `activeMinutes` call `RecipeLimits.minutes`) | `aStoredHugeValueReadsInsideTheLimits`, `aTwoDayFermentKeepsItsTime` (stored 2880 reads 2880) |
| Paste import clamps to the constant | PASS | RecipeImport.text writes "Total time: 4320 min" for 1e300 | RecipeLimitsTests line 60 now expects 4320 |
| A 48 hour ferment typed as text keeps its time | PARTLY | Kitchen/RecipeImport.swift:119 sums days, hours, minutes; the test accepts `minutes == nil || minutes == 2880` (`minutes == nil` would also pass), so the parse of "Total time: 48 hours" is not proven | `aTwoDayFermentKeepsItsTime` (weak on that line; the stored-value half is solid) |
| Claude reply limits use the constant (C row, old RecipeLinkReader.swift:459-460) | PASS | Tess/RecipeLinkReader.swift:482-485 `RecipeLimits.serves.contains`, `RecipeLimits.minutes.contains` | no test ties it (a reply of 2000 minutes accepted, 5000 refused is not asserted) |
| Tests no longer hardcode 1440 in RecipeLimitsTests (old :12, :14, :28, :59) | PASS | RecipeLimitsTests lines 14, 29-30, 60 now read the constant or 4320 | the file itself |
| Hardcoded 100 in RecipeLimitsTests | PARTLY | serves assertions still literal 100 (lines 11-14); the serves cap did not move, so they still pass; nothing reads `RecipeLimits.serves` | n/a |
| `RecipeContextTests` hardcoded "99 h 59 min" (C row) | OPEN | TesseraTests/RecipeContextTests.swift:60 unchanged, matches page cap below | `RecipeCopy.duration(1e300)` assertion, still literal |
| Page: context line reads the clamped total (old RecipePage.swift:553) | OPEN | Features/Recipes/RecipePage.swift:585 still `model.store.number("totalMinutes", ...)`, not `RecipeBook.totalMinutes`. A stored 5000 shows "83 h 20 min" while the engine reads 4320 | no test |
| Page duration cap 5999 (old :588) | OPEN | RecipePage.swift:620 `min(max(minutes, 0), 5999)`; 5999 is a separate number, not 4320; a 4320 minute recipe prints "72 h" fine, so no crash, but two caps | `RecipeCopy.duration(1e300)` expects "99 h 59 min" |
| Page serves ceiling 48 (old RecipePage.swift:97) | OPEN | RecipePage.swift:99 `min(max(size ?? 2, 1), 48)` | no test |
| Drum literals 24 and 48 (old PortionDrum.swift:14-16) | OPEN | Features/Recipes/PortionDrum.swift:12 comment, :15 `min(max(written ?? 0, 0), 24)`, `max(12, 2 * size)` | no test |
| Drum can show the written size of a large recipe | NOT PROVABLE | a recipe that serves 100 scales lines to 100 while the drum stops at 48 | needs a run |

## PR #831 (G66: a bigger re-add counts only new rows)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| A bigger size rebuilds rows it already had; they are not counted as new (old Groceries.swift:401-402) | PASS (engine) | Kitchen/Groceries.swift:420-422 captures `known` (the ingredients of the recipe's existing share) before `RemoveRecipeFromGroceries`; :456-458 `made` excludes them | `aBiggerSizeReplacesTheShare` (GroceriesWeekTests: `bigger.output.isEmpty` and summary ends "nothing to add.") |
| Summary and receipt agree | PASS | Groceries.swift:459 sets `lastAdded`, :495-496 reads it | same test |
| A new ingredient appearing at the bigger size still counts | NOT PROVABLE | logic reads right (`known` is by ingredient, so a line new to the recipe counts) | no test: the fixture only covers the all-known case |
| Rows that joined an existing different-recipe row still do not count | PASS (unchanged) | the `before` set at :424 still filters them | earlier G-R14 tests |
| Product's "N updated." ruling for a bigger size | NOT BUILT (awaiting ruling) | the line today is "nothing to add." because `summary(in:)` has two forms only (Groceries.swift:495-496) | the new assertion pins "nothing to add." and will change with the ruling |
| Screen shows the line (Features/Groceries/GroceriesView.swift:848 discards the result) | NOT PROVABLE | unchanged | no test |
| `lastAdded` is static shared state (the pattern #826 removed for resets) | OPEN (low) | Groceries.swift:482 `nonisolated(unsafe) static var lastAdded`, written at :411, :417, :459, read at :495 | no test; works only because the summary is read right after `apply` |

## Still open

1. K36.2 on the phone: UNDO on the shared line only clears the line (BottomChrome.swift:739-748). The words exist for recipe links (RecipeLinkReader.swift:62) and Plans, none for Lists or Groceries.
2. Put-away basket as bought: `Groceries.putAwayBasket()` (Groceries.swift:135) has no reader. Needs `PantryLedger` and `BuyCadence` (or whoever owns "bought") to call it.
3. Screen wording for the new engine lines: reset (LV:540-549) always says "Packing, reset." and now has no failure path for an empty reset, so an UNDO with nothing behind it can show. Builder B should read the returned receipt, or say "Packing, nothing to reset." and set no UNDO when the returned op has no ops.
4. Recipe page literals: RecipePage.swift:99 (48), :585 (raw total), :620 (5999), PortionDrum.swift:15 (24, and the 48 note); RecipeContextTests.swift:60 pins "99 h 59 min". Move all to `RecipeLimits`, or decide the page cap on purpose (a 3 day recipe is 72 h, well inside 5999).
5. No test proves Claude's reply limits follow the constant, and the 48 hour text parse is weak (`minutes == nil ||` passes).
6. `SetListReusable` refusal prints the raw list title (LR:43). Developer text only.
7. G66 "N updated." wording and a test for a recipe whose bigger size adds a new ingredient.
8. Carried, untouched by these PRs: the 801-818, 802-825 and 820-829 "Still open" lists for the link shelf (G63 to G65), Dynamic Type on the recipe page, `lastAdded` shared state, and the A/B/C screen rows not named above.

## Phone only

1. Reusable list, check two items, open the fold, un-check both, then hold RESET: confirm what it says (code says "Packing, reset." with an UNDO that restores nothing; the ruling wants "Packing, nothing to reset." and no UNDO).
2. Name a list so the wall calls it private, then add, check, un-check, clear, make it reusable, run it, finish it, put it away: every line on screen says "Private list". Compare Now, Home, the ledger row and the Live Activity.
3. Type "picked: up at 5" in an item's notes, accept a pick of that item: the note still shows his line; the stamp is added after it.
4. Undo a Lists or Groceries action from the shared line: confirm it clears with no words (K36.2 not built).
5. A recipe with a stored total of 4320 or more minutes: the context line, the page and the Tess reply all agree (page reads the raw number today).
6. Groceries: add a recipe, then add it again at a bigger size: the line says "nothing to add." today; Product's "N updated." is not wired.
7. Shop, put it away with items in the basket, return after the put-away window: Pantry and the buy cadence should count the basket as bought (today nothing reads it).

# Kitchen acceptance of #766 and #765: static read

Read against origin/master, fetched Oct 17. Static only: nothing built, nothing run.

**Scope.** #766 is merged (79c5ecb; files `Features/Groceries/GroceriesView.swift`, new `Features/Groceries/GroceriesWall.swift`, new `TesseraTests/GroceriesWallTests.swift`). **#765 (the Recipes shelf) is NOT on origin/master** (`git log --merges -30 origin/master` shows 766 and 753 only). So only #766 is accepted here; every #765 row is listed as unchanged at the end.

Short refs: GV = `Features/Groceries/GroceriesView.swift`, GW = `Features/Groceries/GroceriesWall.swift`, GT = `TesseraTests/GroceriesWallTests.swift` (struct `GroceriesAddWallTests`), Core = `TesseraCore/Sources/TesseraCore`.

## 1. Spec tables A3 and A4 (kitchen-test-specs-wall-g40-g43-g44-oct17.md)

| Clause | Verdict | Evidence | Covering test |
|---|---|---|---|
| A3 walled line writes nothing (no note) from the Add line | PASS | `add()` GV:223-238 sends only `split.kept` to `AddGroceries`; walled lines never reach an action. Core also walls inside `AddGroceries.apply` via `kept` (Core Kitchen/Groceries.swift:478, :500) | `aMixedBatchKeepsTheWalledLinesWithTheirReason` (split level). No test that the object count is unchanged (spec `addLineWritesNothingWalled`): no test |
| A3 sum-only says "That stays on this phone." | PASS | GW:42-43 `.money`; spoken GV:235-236 | `linesSayWhyAndNeverEchoTheValue` (string only; not that `add()` speaks it) |
| A3 secret says "That one stays out of Groceries." | PASS | GW:44; reason test GW:34-35 (`isSecretListLine` or `SecretWords.mentions`) | same test; split reason `.secret` in the mixed-batch test ("wifi password hunter2") |
| A3 key uses `claudeKeyLine` | PASS | GW:34-36 key checked first; GW:45 returns `claudeKeyLine` (Core Diagnostics/ClaudeKeyGuard.swift:4, "That looks like a Claude key. It goes in Review, under Claude.") | `aKeyShapedLineIsTheKeyLine` (key built at run time by concatenation) |
| A3 draft kept in the field | PASS | GV:231 `draft = split.walled.map(\.line).joined(", ")` | none on `add()` itself (the view function is still private, spec asked for a testable outcome enum): no test |
| A3 no UNDO on the wall line | PASS | GV:236 `say(text)` with no `undo:`; `HomeQueue.swift:32` default is nil; plain line holds 4 s | no test |
| A3 never a silent clear | PASS | the draft is only rewritten to the walled lines; an all-walled draft is never emptied; a throw returns before the draft is touched (GV:228) | no test |
| A3 price stripped | PASS | kept line keeps its raw text through `split`, then `AddGroceries` strips (`EngineWall.withoutPrice`, Core Tess/EngineWall.swift:71-78, bare two-place decimal included) | `aPriceComesOffButTheThingGoesOn` (asserts only that "milk 4.99" is kept, not walled); strip itself is `withoutPriceTakesABareTwoPlaceDecimal` in Core `GroceriesWallTests.swift:85` |
| A4 `addLineStripsThePrice`: row "milk", receipt "Milk, on Groceries.", `TessVoice` carries the record, undo empties the list | NOT BUILT (row part PASS) | row strips (above). `add()` speaks nothing for a kept line and offers no UNDO: the only `say` is inside `if let reason = split.walled.first?.reason` (GV:234-236). Core receipt exists (Core Kitchen/Groceries.swift:517-527, no stop; the Bar adds the stop) | no test |
| A4 `addLineBlockOfLinesWallsEachLine`: kept lines go on, walled line stays in field, "Milk and eggs, on Groceries.", one undo removes both | PARTIAL: kept and walled split PASS, receipt and UNDO NOT BUILT | split GW:19-30; field GV:231; no receipt, no UNDO for the kept lines | `aMixedBatchKeepsTheWalledLinesWithTheirReason` covers the split only |
| A4 `addLineHoldsASumOnlyLine` / `addLineHoldsAKey` (draft unchanged, no UNDO, line) | PASS by read | as the A3 rows | split-level tests only |
| A4 `addLinePrivateItemShowsPrivateItem` ("Private item, on Groceries.") | NOT BUILT on the Add line | no spoken line for any kept item; row label comes from `ShopTrip.label` (unchanged) | no test |
| A4 as a whole: tests call a testable outcome (`GroceriesCopy.submit` / enum) | NOT BUILT | `add()` is still a private View method; the four tests exercise `GroceriesWall.split` and `line` only | n/a |
| Mixed reasons in one block | PASS with a limit | only `walled.first.reason` is spoken (GV:234); a block with a secret and a sum-only line says one line, for the first | no test |

## 2. Groceries walk section 2b (W1-W6) and gaps

| Row | Verdict | Evidence | Test |
|---|---|---|---|
| W1 "milk $4" row "milk" | PASS | strip in Core as above | Core `withoutPriceTakesABareTwoPlaceDecimal`, GT price test |
| W1 receipt "Milk, on Groceries." with UNDO | NOT BUILT | see A4 row; this is the K87 / K36.2 Add-line receipt gap, still open | no test |
| W2 sum-only never lands; "That stays on this phone." | PASS | `AddListItem.kept` `isSumOnly` (Core Lists/Lists.swift:153-166, :168+); GW; GV | `aMixedBatchKeepsTheWalledLinesWithTheirReason` (money case "rent $1200"). "$40 at costco" itself: NOT PROVABLE by test (only by read of `isSumOnly`) |
| W2 old wording "Private note, kept." | superseded | Product ruled no note for the Groceries Add line (A3); nothing is written | n/a |
| W3 pasted secret never lands | PASS | GW:34-39 | same test |
| W4 "2 lb chicken", "6 eggs" keep numbers | PASS (unchanged) | `withoutPrice` needs a currency sign, a currency word, or a bare two-place trailing decimal ("2 for 1 crackers" and "6 eggs" unaffected) | `withoutPrice` cases in Core `WallsBypassTests.swift:478-480` |
| W5 block paste checks per line; walled line stays, rest go on | PASS | GW:19-30 per line; GV:231 | `aMixedBatchKeepsTheWalledLinesWithTheirReason` |
| W5 combined receipt "Tacos, 9 added. 1 private note, kept." | superseded and NOT BUILT | the ruling dropped notes; there is no combined receipt, only the wall line | none |
| W5 walled lines in the field are joined with ", " | PASS, note | GV:231; a re-submit re-splits on commas (`GroceryLines.split`), so a walled line that held a comma comes back as two pieces; harmless | no test |
| W6 UNDO after a kept line | NOT BUILT on the Add line (PASS in Core) | `engine.undo` works; the Add line never offers it | no test |
| W6 nothing walled is written then deleted | PASS | walled lines never reach `perform` | none |
| ER11 add fails: "Didn't save that. Try again." | STILL OPEN (FAIL) | GV:228 `guard (try? ...) != nil else { return }` silent; the draft stays (the one right part). If every kept line fails to parse, `AddGroceries` throws "nothing to add" and the user hears nothing, and the wall line for any walled sibling is also skipped (return precedes GV:234) | no test |
| ER11 check / uncheck / clear / shop start / finish silent | STILL OPEN | untouched by #766 | no test |
| Earlier acceptance (760-764) Add-line rows: W1 "milk $4" row; W2/A3 wordings; key line; W5 clears the whole draft | now closed | the wording rows, key line, W2, W3 and the W5 draft-clearing finding are closed by GV:219-238 and GW | split-level tests |
| Earlier acceptance: Add-line receipt and UNDO ("Milk, on Groceries.") | still open | as above | no test |

## 3. Copy rules (strings in this PR)

- "That stays on this phone." and "That one stays out of Groceries.": no clock, no "at", no "record". PASS.
- Key line is Core's string, unchanged. PASS.
- Receipts "name the thing first with on": no new receipt is spoken, so nothing to check beyond Core's existing "..., on Groceries".
- Source comments carry "8:40 AM PT" (GV:220, GW:4); comments only, never shown. Note only.

## 4. #765 (Recipes shelf)

Not on origin/master, so not accepted. Rows unchanged from kitchen-acceptance-760-761-763-764-oct17.md: K87.1 shelf (newest first), Recipes top-left returns to the shelf, Close to Home, "Recipe gone." with Back to the list returning to the shelf (still `dismiss()` to Home, `RecipePage.swift:168`), and K30.1 recipes empty-state rows: all NOT BUILT / unverified. Recipe-plate rows: untouched by #766.

## 5. Gap rows

**Closed by #766:** W1 row strip on the Add line; W2 sum-only held with its line; W3 secret held with its line; the key line on the Add line; A3 wording; W5 draft handling (the block no longer clears; walled lines stay); W6 "nothing walled is written".

**Still open:** Add-line receipt and UNDO for kept lines (K87, K36.2, A4 `addLineStripsThePrice`, `addLinePrivateItemShowsPrivateItem`); ER11 silent failures, including add; testable `add()` outcome (A4 file `GroceriesAddLineTests.swift` not written; view logic and the draft, voice and no-UNDO behaviours have no test); mixed-reason block says only the first reason; W5 combined receipt (dropped by the ruling, spec sheet should be updated); K87.1 shelf, "Back to the list", K30.1 (all #765).

## Phone only

- Wall line: in Groceries type "$40 at costco", press Done: the field keeps it and the line reads "That stays on this phone." with no UNDO.
- Secret: type "wifi password hunter2": the field keeps it; line "That one stays out of Groceries."
- Key: paste a Claude key: field keeps it; line is the Claude key line. (Clear the field afterwards.)
- Block: paste "milk $4", "eggs", "rent 2100 fri" on three lines: milk and eggs land, only the rent line stays in the field; confirm no receipt and no UNDO (expected open gap).
- Failure: with Airplane mode irrelevant, hard to force; leave ER11 for a test.
- Voice line holds about 4 s; with VoiceOver on, check it is still announced.

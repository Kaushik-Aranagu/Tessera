# Kitchen test specs: Add-line wall, G40, G43, G44

*Kitchen lead helper, Oct 17. Docs only. Read from origin/master; nothing run (no Swift toolchain here). Style follows section 2 of `kitchen-fg9-g48-followups-oct17.md`. Sources: `kitchen-groceries-screen-walk-oct17.md` 2b (W1 to W6), `kitchen-gap-hunt-7.md` and `kitchen-lists-screen-walk-oct17.md` (G40, G43, G44).*

Copy rules held throughout: thing first with "on"; no "at" before a clock; lowercase clocks; "best" not "record"; no standalone "pin"; no key-shaped literal in any file.

---

## A. The wall on the Add line and the Bar's groceries path

### A0. What the code does today (so the tests fail first)

- Shared pieces that already exist, all in TesseraCore: `EngineWall.withoutPrice(_:)` (`Tess/EngineWall.swift:71`), `SecretWords.isSecretListLine(_:)` / `SecretWords.hasValue(_:)` / `SecretWords.title` ("Private note") (`Notes/SecretWords.swift`), `looksLikeClaudeKey(_:)`, `withoutClaudeKeys(_:)` and `claudeKeyLine` (`Diagnostics/ClaudeKeyGuard.swift`; there is no type named `ClaudeKeyGuard`, the file holds free functions), `PrivateFacts.isMoneyShaped`, `EngineWall.isHealth`, and the one composed gate `AddListItem.kept(_:store:)` (`Lists/Lists.swift:153`, returns the stripped text, or nil when the line should become a private note).
- Only `TessTools.addItems` (`TessTools.swift:345`) calls `kept`. `AddGroceries.apply` (`Kitchen/Groceries.swift:471`) parses each line with `IngredientLine.parse` and writes it. The Add line (`Features/Groceries/GroceriesView.swift` `add()`, `GroceriesCopy.lines(in:)`) and the Bar (`TessCaptureEngine.performKitchen`, `case .groceries`) both hand raw lines to it.
- **Fix point (Core).** Put the wall inside `AddGroceries.apply` so every caller gets it: per line, run `AddListItem.kept(line, store:)`; nil means skip the row (and see A3 for the note); otherwise parse `kept`. Then `summary` and `receipt` use the same kept text (they currently print `lines` raw). Because the wall is inside the action, Add line, Bar, Siri and the tool all pass the same tests, and Builder B only wires the outcome text.
- **Two gaps in `kept` itself that the table below will hit** (confirm on the Mac, then fix in `kept`, not in the callers):
  1. `withoutPrice` strips only a currency sign or the words dollars, bucks, usd, quid. "milk 4.99" has neither, so it stays "milk 4.99". RULED (Product 8:40 AM): a trailing bare decimal with exactly two places (`\s\d+\.\d{2}$`) is a price. "6 eggs", "2 lb chicken", "14 oz can tomatoes", "2 for 1 crackers", "1.5 kg rice" (one place) keep their numbers.
  2. "$40 at costco" strips to "at costco" (not empty), and `isMoneyShaped(bare)` is false for it. The sum-only test must also run on `given` (before the strip): `isMoneyShaped(given)` with nothing else that is a thing. If `isMoneyShaped("$40 at costco")` is false today, extend the sum-only check, do not special-case the string.

### A1. TesseraCore unit tests (Swift Testing)

File: `TesseraCore/Tests/TesseraCoreTests/GroceriesWallTests.swift` (new). Struct `GroceriesWallTests`, `@MainActor`, `import TesseraTess`, same fixture as `KitchenGaps2Tests`: `ObjectStore.open(inMemory: true)`, `store.prepareCatalog()`, `ActionEngine`. Helper `rows()` returns `Groceries(store:classes:).aisles().flatMap(\.items).map(\.text)`. Helper `noteTitles()` returns titles of all non-deleted `.note` objects. Each case also records `store.context.objects.count` and the op count before and after, to prove "nothing written".

| Test name | Input to `AddGroceries(lines:)` by `.user` | Rows after | Receipt (`record.receipt`) | Summary | Notes written |
|---|---|---|---|---|---|
| `priceComesOffAndTheThingStays` | `["milk $4"]` | `["milk"]` | "Milk, on Groceries." | "Milk, on Groceries" | none |
| `priceWordsComeOff` | `["eggs 3 dollars"]` | `["eggs"]` | "Eggs, on Groceries." | | none |
| `bareDecimalPriceComesOff` | `["milk 4.99"]` | `["milk"]` | "Milk, on Groceries." | | none (needs A0 gap 1) |
| `numbersThatAreAmountsStay` | `["2 lb chicken"]`, `["14 oz can tomatoes"]`, `["6 eggs"]`, `["2 for 1 crackers"]` (four cases, `@Test(arguments:)`) | the parsed name of each, amount kept on the share (assert `GroceryShare.amount`/`unit` equal what `IngredientLine.parse(line)` gives) | thing first, e.g. "Chicken, on Groceries." | | none |
| `sumOnlyNeverLandsAsARow` | `["$40 at costco"]`, `["rent 2100 fri"]`, `["$40"]` (arguments) | unchanged (empty) | the engine throws `ActionError.invalidArguments` ("nothing to add"), same as today's empty case | | none written by `AddGroceries`; see A3 for who writes a note |
| `secretWithAValueNeverLandsAsARow` | `["wifi password is tacocat12"]`, `["reset the garage code 4471"]` (arguments; made-up values) | unchanged | throws as above | | none by this action |
| `claudeKeyNeverLandsAsARow` | `[keyLine]` where `keyLine` is a key-shaped string **built at run time from parts**, the way the existing key-guard tests build theirs (no key-shaped literal in any file) | unchanged | throws as above | | none; also assert `looksLikeClaudeKey(keyLine)` so the fixture can never rot into a non-key |
| `privateItemRowShowsPrivateItem` | `["lexapro"]` (a medicine word, in `PrivateFacts.medicines`) | one row, stored in his words, hidden by the label | "Private item, on Groceries." | "Private item, on Groceries" | none |
| `mixedBatchKeepsTheCleanLinesOnly` | `["milk $4", "wifi password is tacocat12", "eggs"]` | `["milk", "eggs"]` | "Milk and eggs, on Groceries." (the receipt names only kept lines; no word of the walled line appears) | | none by this action |
| `wallIsOnTheActionNotTheCaller` | run `milk $4` through `AddGroceries`, `TessTools.run("addToList", {"list":"groceries","items":[{"text":"milk $4"}]})` and the Bar (A2); assert identical rows | one `["milk"]` each (use three fresh stores) | | | |

Assertions common to every row: `summary(in:)` and `receipt(in:)` contain none of "$", "4.99", "tacocat", "costco" (sum-only), the key; the op record's `ops` carries no `.create` whose title contains them; `UNDO` (`engine.undo(record)`) after a kept line removes exactly that row and returns the store to its before state (`rows()` empty, object count equal to before). A walled line has no op to undo, so there is no UNDO and nothing was written then deleted (W6): assert `engine.history` has no create for the walled text and no soft-deleted object carries it (`store.context.objects.values.filter { $0.title.contains(...) }` is empty, deleted ones included).

Also add one assertion next to `WallsBypassTests.swift:478` for gap 1: `EngineWall.withoutPrice("milk 4.99") == "milk"` and `withoutPrice("1.5 kg rice") == "1.5 kg rice"`.

### A2. TesseraCore tests for the Bar path

File: `TesseraCore/Tests/TesseraCoreTests/GroceriesWallTests.swift` (same struct, second section), `import TesseraTess`. Use `TessCaptureEngine` the way `KitchenGaps2Tests` / the grammar misfire tests do (parse then perform), asserting `parse` and the returned line.

| Test name | Bar phrase | Parse | Row | Tess line | UNDO | Not written |
|---|---|---|---|---|---|---|
| `barBuyMilkWithPrice` | "buy milk $4" | `.groceries(["milk $4"])` (grammar may keep raw; the action strips) | "milk" | "Milk, on Groceries." | one undo removes the row | no "$4" anywhere |
| `barBuyMilkBareDecimal` | "buy milk 4.99" | groceries | "milk" | "Milk, on Groceries." | removes the row | no "4.99" |
| `barBareMilkPrice` | "milk $4" | RULED (Product Oct 17 8:40 AM, C1): the price strips, "milk" lands, the price stays on the phone. Groceries `["milk"]` (today nil: build it). No `.disabled` | "milk" | "Milk, on Groceries." | | no "$4" anywhere |
| `barSumOnlyIsNotARow` | "$40 at costco"; "rent 2100 fri" | not `.groceries`; miss line, not a note (bare, not past tense) | none | the existing miss line | none | no row, no note |
| `barPastTenseSumIsAPrivateNote` | "spent $40 at costco"; "paid rent 2100" | `.privateNote` | none | "Private note, kept." | one undo removes the note | no row; the note body is never repeated in the line |
| `barSecretIsRefusedBeforeAnything` | "buy wifi password is tacocat12" | secret check runs first (`TessGrammar.swift:73-75`) | none | "Private note, kept. I don't keep passwords." when remembered, else "Private note, kept." | note undoable | no row |
| `barKeyIsRefused` | `"buy " + key` (key built at run time as in A1) | refused | none | `claudeKeyLine` exactly | none (nothing written) | no row, no note, no miss-log entry (assert `CaptureMissLog` store has no line containing the key) |
| `barPrivateItem` | "buy lexapro" | groceries | one row, label hidden | "Private item, on Groceries." (already built, `TessCaptureEngine.swift` below the `.groceries` case; keep it) | removes the row | no medicine word in the line |
| `barAlreadyOnStillWorks` | "buy milk" twice | | one row | second: "Milk, already on Groceries." | | regression guard: the `made` check must still see a `.create` op after the wall moves into the action |

### A3. Who writes the note when a line is walled (needs Product's yes, default given)

`AddListItem` writes a private note for a walled line (`CreateNote(isPrivate: true)`); `AddGroceries` has no such branch. Default for this spec: `AddGroceries` writes nothing for a walled line (matches W2, W3, W6: "nothing walled is written"). The Bar already turns a past-tense sum into a note through `.privateNote`. The Add line, for a sum-only or secret line, keeps the draft in the field and says one line through `TessVoice` (no UNDO, nothing to undo). RULED wording (Product 8:40 AM): a sum-only line says "That stays on this phone."; a secret says "That one stays out of Groceries."; the key case uses `claudeKeyLine`. No note is kept and nothing is written. The tests in A1 hold under either answer because they assert only the `AddGroceries` outcome.

### A4. App tests (TesseraTests, `@testable import Tessera`)

File: `TesseraTests/GroceriesAddLineTests.swift` (new). Fixture: `TesseraSchema.makeContainer(inMemory: true)` and `AppModel`, as `PantryLedgerTests`. The `add()` function is private in a View, so first move its body to `GroceriesCopy.submit(draft:model:)` (or an `@MainActor enum GroceriesAdd`) returning an outcome enum `.added(OpRecord)`, `.held(String)`, `.failed`, which `add()` calls; test that.

| Test name | Draft typed | Outcome | Draft after | Row | Voice line | UNDO |
|---|---|---|---|---|---|---|
| `addLineStripsThePrice` | "milk $4" | `.added` | cleared | "milk" | "Milk, on Groceries." | `TessVoice` carries the record; undo empties the list |
| `addLineBlockOfLinesWallsEachLine` | "milk $4\neggs\nwifi password is tacocat12" | `.added` (2 kept) | cleared of kept; the walled line stays in the field | "milk", "eggs" | "Milk and eggs, on Groceries." | one undo removes both rows |
| `addLineHoldsASumOnlyLine` | "$40 at costco" | `.held` | unchanged | none | per A3 | none |
| `addLineHoldsAKey` | key built at run time | `.held` | unchanged | none | `claudeKeyLine` | none |
| `addLineWritesNothingWalled` | each walled draft above | | | `store.context.objects` count unchanged | | |
| `addLinePrivateItemShowsPrivateItem` | "lexapro" | `.added` | cleared | row label via `ShopTrip.label(for:name:lastWeightKg:)` is "Private item" | "Private item, on Groceries." | undo removes it |
| `privateRecipeIngredientNeverNamesTheRecipe` | `CreateRecipe` with a private-shaped title (a medicine word, e.g. "Lexapro taper" with two ingredients), then `AddRecipeToGroceries` | | | rows are the ingredient names; `ShopTrip.recipeNames(...)` for each row is `["Private recipe"]` | the receipt/summary of `AddRecipeToGroceries` contains neither the title words nor "Lexapro"; the accessibility label of each row (via `ShopTrip.label`) contains no title word | undo removes the shares |

Done when: every test in A1, A2 and A4 is green on the Mac, `scripts/test.sh` ends "All green", and W1, W2, W3, W5, W6, C1 (or its ruling) and C2 are re-walked from FAIL to PASS in the groceries walk. W5's combined receipt ("Tacos, 9 added. 1 private note, kept.") stays out of scope here; it needs the A3 ruling first.

---

## B. Lists gaps

### B1. G40, list lookup and repeat name (Core resolver, Builder B for create)

Intent (hunt 7 row G40, ruling in the walk section 9 and "next steps" 3): a name that matches two lists writes nothing and Tess asks which: "More than one list like trip." (RULED, Product 8:40 AM; it follows `task(named:)`'s "more than one task like ..."). An exact name wins only when it is one list. A one- or two-letter prefix never matches. The receipt names the list so a wrong landing is visible. `CreateList` on a repeat name opens the existing list instead of making a second.

Code today: `TessTools.Call.list(named:)` (`TessTools.swift:324`) takes the first exact title, else the first prefix match, oldest first. `CreateList.apply` (`Lists/Lists.swift:84`) checks only an empty name.

File: `TesseraCore/Tests/TesseraCoreTests/ListLookupTests.swift` (new), `@MainActor`, `import TesseraTess`, fixture as `KitchenGaps2Tests`. Helper `add(_ list: String, _ text: String)` runs `TessTools.run("addToList", arguments: Data(json.utf8), engine:)` and commits pending records as `KitchenGaps2Tests.listToolAddsGroceriesThroughTheAddLine` does. Fixture lists are made with `CreateList` for single names; for two equal names, build the second with `engine.perform(CreateList...)` after Core lands the repeat rule, or directly with `Transaction.create` in the test (a Shortcut-made duplicate), so the resolver test does not depend on the create rule.

| Test name | Fixture | Call | Expect | Not written |
|---|---|---|---|---|
| `twoListsWithTheSameNameRefuse` | two lists titled "Packing" | add "sunscreen" to "packing" | throws `TessToolError` with message "More than one list like packing." | no list item anywhere; op count and object count unchanged |
| `twoPrefixMatchesRefuse` | "Trip 2025", "Trip to Lisbon" | add "adapter" to "trip" | throws "More than one list like trip." | no item on either |
| `exactNameWinsWhenItIsOneList` | "Trip", "Trip 2025", "Trip to Lisbon" | add "adapter" to "trip" | item lands on "Trip"; receipt "Adapter, on Trip." | none on the others |
| `onePrefixMatchLands` | "Packing" only | add "socks" to "pack" | lands on "Packing"; receipt "Socks, on Packing." | |
| `shortPrefixNeverMatches` | "Packing" | add to "p" and to "pa" | throws "no list called p" / "no list called pa" | no item |
| `uniqueThreeLetterPrefixStillMatches` | "Packing" | add to "pac" | lands | |
| `groceriesWordKeepsMeaningBuiltIn` | built-in Groceries only | add "milk" to "groceries" | goes through `AddGroceries` (G16 path) | regression guard |
| `hisOwnGroceriesList` | built-in plus a user list titled "Groceries" | add "soap" to "groceries" | per ruling an exact name wins only when it is one list, so this refuses with "More than one list like groceries."; Product to confirm the built-in should not win here. Mark `.disabled("G29 vs G40 not ruled")` if Product wants the built-in to win | |
| `refusalNamesNoPrivateWord` | two lists titled with a private word (medicine word) | add to it | the refusal line uses `ObjectPrivacy` label rules, no title word in the message | |

CreateList repeat name (same file, second section):

| Test name | Fixture | Action | Expect |
|---|---|---|---|
| `repeatListNameOpensTheExistingList` | "Packing" with 2 items | `CreateList(name: "packing ")` (case and spaces differ) | returns the existing record (same id); `lists().count` unchanged; the 2 items intact; no `.create` op in the new `OpRecord` |
| `repeatListReceiptIsNotMade` | as above | `receipt(in:)` | not "Packing, made." Proposed line: "Packing, already a list." (Product to rule; mirrors "already on Groceries"). A new name keeps "Packing, made." and the Bar's "Packing, new list." (walk 13.2 expects that wording; today the Bar prints "New list: Packing.", `TessCaptureEngine.swift:396`, fix with it) |
| `deletedListNameCanBeMadeAgain` | "Packing" soft-deleted | `CreateList(name: "Packing")` | a new list is made (deleted lists do not count) |
| `groceriesNameOpensTheBuiltIn` | built-in | `CreateList(name: "Groceries")` | returns the built-in, `Groceries.listID` |
| `barNewListRepeatOpensIt` | "Packing" exists | Bar "new list: packing" | no second list; line is the repeat receipt; UNDO is nil (nothing was made) |

App test (Builder B): in `TesseraTests/ListsCopyTests.swift` add `repeatListLineNamesTheList`, asserting the copy helper's line for the repeat case and that no UNDO is offered.

Done when: all of the above green; G40 row in `kitchen-gap-status-oct17.md` closed (the refusal line is ruled; the repeat-list line is still unruled and stays marked); the walk's 13.2 row re-run.

### B2. G43, Done shopping has no UNDO and no failure line (Builder B, words from Core)

Intent (hunt 7 row G43; ios-b D10; `undo-lines.md` row 31): a change gets UNDO for 10 seconds with "Shopping, finished." (proposed, not ruled). One UNDO brings the checked rows back, the shop running again, and Pantry's states return with them. A failed write says "Didn't save that. Try again." (ruled Oct 17, 4:35).

Code today: `GroceriesView.finishShop()` (`:315`) does `_ = try? model.engine.perform(FinishShop(), by: .user)`, says nothing, and bumps `finished` even when the write failed. `FinishShop.apply` returns the cleared count and ends the process (`Shopping.swift:60`). `clearBasket` (`:292`) is the pattern: it reads `result.record` and calls `TessVoice.shared.say(_, undo:)`.

Core tests, in `TesseraCore/Tests/TesseraCoreTests/ShoppingTests.swift` (existing file, add cases):

| Test name | Fixture | Steps | Assertions |
|---|---|---|---|
| `finishShopUndoBringsBackTheBasketAndTheShop` | 14 rows, `StartShop`, check all 14 | `let done = try engine.perform(FinishShop(), by: .user)`; `engine.undo(done.record)` | outcome is `.applied` (not skipped); the 14 rows are back, checked (`isDone` true, `checkedAt` as before); `Groceries.shop(in:)` is running again, same process id; `table.running()?.nextStep` is "Shopping, all in the basket" |
| `finishShopUndoRestoresPantryStates` | Fixture of `PantryLedgerTests` is app-side; so here assert the data it reads: soft-deleted rows return to not deleted (`isDeleted == false`) | as above | no row with `isDeleted` remains from the clear |
| `finishShopReceiptNamesTheShopFirst` | | `done.record.receipt` | "Shopping, finished." (add `receipt(in:)` to `FinishShop`; today it has only `summary` "Finished shopping") |
| `finishShopWithNothingCheckedStillFinishes` | shop running, nothing checked | `FinishShop` | process ended; receipt "Shopping, finished."; Builder B may choose silence for zero cleared, then the test pins that choice |
| `finishShopFailureWritesNothing` | store set up so `perform` throws (no groceries list: delete the list object soft in the fixture, or a forced failing engine as the existing tests that assert `ActionError` do) | `#expect(throws:)` | no process ended, no rows cleared |

App tests (Builder B), `TesseraTests/GroceriesFinishTests.swift` (new), fixture as `PantryLedgerTests`. As with A4, move the body of `finishShop()` to `GroceriesCopy.finish(model:) -> FinishOutcome` (`.finished(OpRecord)`, `.failed`) so it can be tested without a View:

| Test name | Assertions |
|---|---|
| `finishSaysShoppingFinishedWithUndo` | outcome `.finished`; the line is "Shopping, finished."; the record handed to `TessVoice` is the one that undoes it (call `model.engine.undo(record)`, rows return); hold is 10 s |
| `finishFailureSaysDidntSaveAndKeepsTheBasket` | outcome `.failed`; the line is "Didn't save that. Try again."; `basketOpen` stays true (return value tells the View not to close it); `finished` counter does not increase (so the finish haptic does not fire); rows and the running shop unchanged |
| `undoAfterFinishPutsPantryBack` | using `PantryLedger` as in `PantryLedgerTests`: after finish, states for the 14 ingredients read "in"; after `undo`, `PantryLedger(...).entries()` reads them as they were before the shop (assert on a before snapshot) |
| `finishLineNamesNoItem` | with a Private item in the basket, the line and the accessibility label contain none of its words |

Done when: the Core and app tests above are green; the Finish key on Groceries shows the line and UNDO on the simulator (screenshot); the G43 row is closed and ios-b D10's done-when gains "Pantry returns with UNDO".

### B3. G44, a shop never goes idle (Core idle rule, Builder B Home read)

Intent (hunt 7 row G44): a shop untouched overnight stops saying "at the store": it pauses as the system and Home reads "paused" with the day. If a paused shop is put away with a basket in it, the note says so (ruled, Product 8:40 AM: "Shopping moved to Later. 12 in the basket."), and the checked rows stay Pantry's to learn from, not dropped. Idle length and the note are Product's to rule (hunt 7 section, owner table line 43); this spec takes the idle length as a named constant, `ProcessTable.Limits.idleShop`, ruled 12 hours (Product 8:40 AM), so the tests assert against the constant, not a literal.

Code today: `ProcessTable.suspendIfIdle` (`ProcessTable.swift:87`) returns nil unless the subject is a workout. `tidyNotes` (`:109`) puts away any suspended process idle for `Limits.putAway` (7 days) with the generic note "One thing moved to Later." and never mentions the basket. `HomeLines.swift:335-353` reads a running shop as "at the store" and a paused one as "him at home".

Core tests, `TesseraCore/Tests/TesseraCoreTests/ShoppingIdleTests.swift` (new), fixture as `ShoppingTests`. Use `StartShop(time:)` and pass `now:` explicitly; never read the wall clock.

| Test name | Fixture | Steps | Assertions |
|---|---|---|---|
| `runningShopGoesIdleOvernight` | 12 rows, `StartShop(time: t0)`, check 12 at `t0` plus 1 h | `suspendIfIdle(now: t0 + Limits.idleShop + 60, idleLimit: Limits.idleShop)` | returns the shop snapshot; `shop.state == .suspended`; `table.running() == nil`; the suspend op's actor is `.system`; `lastTouchedAt` is the last real touch (checks time), not `now` |
| `shopTouchedRecentlyStaysRunning` | as above | `now` = last check + `Limits.idleShop` minus 60 s | returns nil; still running |
| `checkingARowResetsTheShopIdleClock` | | check one more row after 11 h; call at 13 h | still running |
| `idleShopKeepsItsBasket` | | after suspend | the 12 rows are still checked and not deleted (`isDeleted == false`); `shoppingLine()` unchanged |
| `idleShopResumesWithStartShop` | | `StartShop()` after suspend | same process id running again (existing behaviour, `ShoppingTests`) |
| `workoutIdleRuleUnchanged` | a running workout past `idleLimit` | | still suspended exactly as before (regression) |
| `putAwayShopNoteCountsTheBasket` | suspended shop with 12 checked rows, idle 7 days | `tidyNotes(now:)` | one note whose `line` is "Shopping moved to Later. 12 in the basket." (ruled); with 0 checked the generic "One thing moved to Later." stays; the line contains no item name |
| `putAwayShopKeepsRowsForPantry` | as above | after the tidy | the 12 rows are not deleted; they are still checked; `PantryLedger` input (rows carrying `checkedAt`) is intact. Ruling needed on whether a put-away basket counts as bought; the spec asserts only "not dropped" |
| `putAwayShopNoteHasUndoOrIsSilentByRule` | | the note's `undo` field | Product rules; default nil as for other put-aways, test pins it |

App tests, `TesseraTests/HomeDataTests.swift` (existing file, add):

| Test name | Assertions |
|---|---|
| `idleShopReadsPausedNotAtTheStore` | after `suspendIfIdle`, Home's line for the shop contains "paused" and the weekday word, and not "at the store" (`HomeLines` context for `.paused`); lowercase clocks if one appears ("paused 9:40 pm"); never "at" before a clock |
| `runningShopStillReadsAtTheStore` | within the idle limit, "at the store" holds (regression) |
| `idleShopLineNamesNoPrivateItem` | with a Private item in the basket, no item word in the hero, context or accessibility label |
| `idleCheckRunsOnForegroundAndLaunch` | the foreground/launch hook that already calls `tidy` also calls `suspendIfIdle` with the shop limit (assert in `ProcessWiringTests.swift` that the caller passes the shop limit, not the rest-based workout limit) |

Done when: all green; the idle length (12 h) and the put-away note are ruled (Product 8:40 AM); the G44 row records the constant and the line; Home on the simulator with `-demoTime` shifted past the limit shows the paused read.

---

## C. Which suite owns what

- **TesseraCore unit tests (run with `swift test` in `TesseraCore/`):** all of A1, A2, B1 (both tables), B2 Core table, B3 Core table, plus the `withoutPrice` assertion in `WallsBypassTests.swift`.
- **App tests (TesseraTests, simulator):** A4, B1 app test, B2 app table, B3 app table.
- **Owners:** Core builds the wall inside `AddGroceries`, the two `kept` gaps, `CreateList` repeat rule, the `list(named:)` refusal, `FinishShop.receipt`, the shop idle rule and constant, and the put-away basket note. Builder B moves `add()` and `finishShop()` bodies into testable functions, wires the lines and UNDO, and does the Home read.
- **Rulings (Product, decisions.md Oct 17 8:40 AM), folded in:** a bare two-place decimal is a price (strips, never stored); A3: `AddGroceries` writes nothing for a walled line, the Add line keeps the draft with no UNDO, a sum-only line says "That stays on this phone.", a secret says "That one stays out of Groceries.", a key uses `claudeKeyLine`; G40 "More than one list like trip."; shop idle 12 h and the put-away note "Shopping moved to Later. 12 in the basket."; bare "milk $4" in the Bar lands "milk" (C1). **Still not ruled:** the repeat-list line ("Packing, already a list."), whether his own "Groceries" can be reached by name, and "Shopping, finished." for G43.

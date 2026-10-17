# Kitchen K82: code-read walk of the merged Pantry screen, plus the K9 never-sums audit

*Kitchen lead, 2026-10-17; revised against `master` 0626534 (adds #739, Pantry front model B12, and Lists' ruled forms), see "Re-check against #739" below. Docs only. A read of `master` after #722 (PantryLedger), #724 (pantry page), #727 (pantry front) and #739; the app was not run, so nothing here is a recording or a screenshot. Rows walked: `pantry-acceptance.md` (Screen rows S1 to S17, Builder B done-when 1 to 4, Core 1 to 7 as the app-side ledger covers them) and `kitchen-refill5-pantry-acceptance.md` (K26, K27, K28). Verdicts: **PASS** (the code does what the row says), **FAIL** (built, but it deviates or part of the row is missing), **NOT BUILT** (the thing the row tests does not exist). Where a PASS rests on something I could not prove by reading (a pixel pitch, a timing, VoiceOver), the note says so.*

## What is merged

All of Pantry is app-side. Five files and no Core type:

| File | What it is |
|---|---|
| `Features/Kitchen/PantryLedger.swift` (187 lines) | Derives each ingredient's state from shop clears (in) and finished cooks (low; Produce out). Nothing stored. `hero`, `entries`, `lastShop`, `lastCookUsedUp` |
| `Features/Kitchen/PantryView.swift` (211 lines) | The page: Title, context line, hero, OUT then LOW lines, swipe to Groceries, Tess's band. Reads everything through `PantryFront` since #739 |
| `Features/Kitchen/PantryFront.swift` (42 lines, #739) | The front as data: `hero`, `context`, `out`, `low`, `isEmpty`, `tess`, and `swipe` (add, or already on Groceries) |
| `Features/Kitchen/PantryCopy.swift` (50 lines) | Context line, Tess's cook line, the empty strings, the swipe receipt |
| `Features/Kitchen/PantryDayWord.swift` (35 lines) | "bought Sat" / "bought Oct 3" words. **Used by no view** (tests only) |
| `Features/Home/HomeSpatialView.swift:333,354,374` | `HomeLink.pantry` and the word PANTRY under Groceries on the KITCHEN page |
| `TesseraTests/PantryLedgerTests.swift`, `PantryCopyTests.swift`, `PantryDayWordTests.swift`, `PantryFrontTests.swift` (#739) | Swift Testing, app target |

**Not in the tree at all** (checked by grep over `Features`, `App`, `TesseraCore/Sources`): a stored `Ingredient.state` or `lastBoughtAt` field (`SystemCatalog.swift:280` Ingredient class has neither), any "out of milk" or "have rice" grammar, `RecipeMath.missing`, CAN COOK, the peek's have/low/out words, the OUT AND LOW side (`SideHost`), USUALLY HAVE, the state-word cycle, the five-row KITCHEN index, Home's Pantry line, the PER 100 G side and any food table reader, a pantry colour token, `docs/recordings/pantry.mp4`.

Two consequences that touch many rows. (1) Every K26/K27/K28 row that says "seed N ingredients as in, low or out through `ObjectStore` ops" cannot run as written: state exists only as a fact inferred from shop clears and cooks, so there is nothing to set. (2) The empty page says `Say "out of milk" and I'll keep it.` (`PantryCopy.swift:34`), a promise nothing keeps yet.

---

## 1. pantry-acceptance.md, Screen rows S1 to S17

| # | Verdict | Evidence and gap |
|---|---|---|
| S1 Front, things known | FAIL | Page draws a Title "Pantry" (`PantryView.swift:36`) where the sheet has PANTRY at 52 and **no title**; no weekday at 138; no side word OUT AND LOW at the right of the context line (`:41-47`); no USUALLY HAVE group (only OUT and LOW, `:62-63`). Labels use `.labelStrong` (`:66`); no card, pill or badge, nothing red. Pixel positions (52/138/186/212/296) not checkable by reading; the file's own header (`:6-12`) says "the page frame … until Product rules the area entry" |
| S2 Hero | PASS | `PantryLedger.hero` (`PantryLedger.swift:72-79`): digits, zero parts dropped, "1 out" never "1 outs"; in never counted. "Same string on the index and Home" is not built (S12/S14), tracked there |
| S3 Out line | FAIL | Ring is right: 11 pt, 1.3 pt, ink 42%, leading 6 (`PantryView.swift:199-207`); Body line, 40 pt min height (`:208`); name in ink; "out" at 700 (`:195`). Missing: state word is plain ink (`:196`), not pantry colour at 72% with ink (no token exists, see S17); the recipe page's out line carries no ring (`RecipePage.swift` has no state or ring code) |
| S4 Low line | PASS | "low" at 600 (`PantryView.swift:195`), no ring (`:200`). Colour tracked under S17 |
| S5 USUALLY HAVE, 1 to 4 | NOT BUILT | No USUALLY line on the page; header `:11-12` lists it as waiting on Core. `BuyCadence` exists (`Kitchen/BuyCadence.swift`) but nothing on Pantry reads it |
| S6 USUALLY HAVE, 4 or more | NOT BUILT | As S5. The list helper "a, b and 2 more" (`PantryCopy.swift:45-52`) is built for Tess's line, not this |
| S7 State-word tap | NOT BUILT | State word is inert text (`PantryView.swift:193-196`); no cycle, no op, no UNDO 10 s. Needs a stored state (Core) |
| S8 Row leaves and joins | PASS | In lines are filtered off (`PantryFront.swift:24-25`, `PantryView.swift:62`); an empty group is not drawn, label included (`PantryView.swift:63`); lines animate through MotionPolicy on id change (`:81`). The 320 ms close is not provable by reading |
| S9 Tap a name | PASS | `NavigationLink(value: Route.object(...))` (`PantryView.swift:143`) into the Ingredient page; native stack keeps the scroll offset (1 pt not verified). The state sentence, cycle and PER 100 G side that page should carry are not built (K27.6, K28.24) |
| S10 Left swipe | PASS | Fixed by #739. Swipe at -72 pt (`PantryView.swift:162-177`) first asks `PantryFront.swipe` (`PantryFront.swift:36-41`): a line already open on Groceries says "Milk, already on Groceries." with no second row and no UNDO (`PantryView.swift:107-112`; test `PantryFrontTests.swift`, "aThingAlreadyOnGroceriesIsNotAddedTwice"); otherwise `AddGroceries` and "Milk, on Groceries." with `holds: .seconds(4)` (`:113-119`); VoiceOver gets "Add to Groceries" (`:152`). Caveats, not Pantry's row: the check counts open rows only (`Groceries.swift:106-112`), so a checked row in the basket does not count as "already on" (gap hunt 7, G47); the -72 pt pitch is not checkable by reading |
| S11 Nothing out | PASS | Hero "Nothing out" when known and none out or low (`PantryLedger.swift:78`); both groups undrawn. The side ("Nothing out.", no key) and USUALLY HAVE are not built, tracked at K26.9 |
| S12 Nothing known | FAIL | Hero "Nothing yet" (`PantryLedger.swift:78`), body line (`PantryCopy.swift:34`, `PantryView.swift:54-61`), no art, never "0 out, 0 low", Tess line `Say "out of milk" and I'll keep it.` all match. Body is `inkSecondary`, not checked against 55%. Fails on: index line "Nothing yet" absent (no index), and the phrase Tess is told to offer does nothing (no grammar, Core 2) |
| S13 Tess's line | FAIL | RULED by Product (decisions 5:12): over three names the line is "Tacos took 5 things." and names no ingredient. After a cook up to three names read "Tacos took the cilantro and limes." (`PantryFront.swift:27` through `PantryCopy.swift:29-31`, shown by `PantryView.swift:97-98`; tests `PantryCopyTests.swift:27`, `PantryFrontTests.swift`); skipped while an UNDO is open (`PantryView.swift:93-95`); private names left out (`PantryLedger.swift:102`). **FAIL, Builder B:** over three names the code still reads "a, b and 2 more" (`PantryCopy.swift:47`), which names two ingredients. Missing: Home's Pantry line (hero verbatim) does not exist, so "Tess and Home never disagree" cannot hold. After a Private cook Tess must say nothing (FG9, section 6), which the code does not do |
| S14 Index, five rows | NOT BUILT | KITCHEN is three words (Groceries, Pantry, Recipes) at title size in a plain stack (`HomeSpatialView.swift:363-382`). No REVIEW/TODAY/TRAINING/KITCHEN/PANTRY index, no 104 pt pitch, no glass, no 1.06 scale. Separately, Home's cook line does print "Tacos, 7 pm" through `HouseTime` (`HomeLines.swift:267-273`) |
| S15 Walls | PASS | A walled ingredient reads "Private item" (`PantryLedger.swift:169-175`, full wall incl. money, body, medicine); a private row opens nothing (`PantryView.swift:134-136,142-148`); private names stay out of Tess's line (`PantryLedger.swift:102`); (the ingredient wall only; a Private recipe's cook line is FG9, a FAIL in section 6). Nothing from Pantry reaches Claude (section 5). Caveat: the swipe adds the real name to Groceries (`PantryView.swift:113`), only the receipt is masked |
| S16 Reduce Motion, Type, VoiceOver | FAIL | VoiceOver label "Name, out" and the "Add to Groceries" custom action are right (`PantryView.swift:151-152`). AX layout is now built (#739): at accessibility sizes the state word sits under the name in one column (`:180-197`; Dynamic Type read from code, not run). Still missing: the cycle as default action (no cycle); no side or index to crossfade |
| S17 Pantry colour | FAIL | No ochre token anywhere in `DesignSystem`; state words are `Theme.Colors.ink` (`PantryView.swift:196`). The "cobalt only for Tess" half holds (Pantry uses no cobalt). A theme-token test does not exist |

**S counts: 6 PASS (S2, S4, S8, S9, S11, S15), 7 FAIL (S1, S3, S10, S12, S13, S16, S17), 4 NOT BUILT (S5, S6, S7, S14).**

## 2. pantry-acceptance.md, Builder B done-when and Core items

| # | Verdict | Evidence and gap |
|---|---|---|
| B1 Opens from KITCHEN and from "pantry" to Tess; counts line and grouped lines; nothing under 16 pt, no cards or pills | FAIL | KITCHEN opens it (`HomeSpatialView.swift:354,374`) and the counts and groups render. Asking Tess "pantry" or "what do I have" has no route: `TessMemory.swift:713` only files the word under the kitchen area for told notes, no grammar opens a screen |
| B2 Shop clear and finished cook change the counts and move lines | PASS | Live from the store on `model.revision` (`PantryView.swift:32`, then `PantryFront`, `:33`); test `PantryLedgerTests.swift:48` walks shop, cook, "1 out, 2 low", and `:73` the next shop returning everything to in ("Nothing out") |
| B3 Peek on three seed recipes reads have / low / out; key count matches | NOT BUILT | No peek state words, no dry-run count (`RecipePage.swift` shows only "N to buy, on Groceries" at `:102,227`) |
| B4 "nothing known yet"; Reduce Motion crossfade; Dynamic Type one column | PASS | Empty state as S12; one VStack column; motion through `tesseraAnimation`/`withTesseraAnimation` (`PantryView.swift:81,175`). Not run, so no recording and the AX5 wrap is unproven. `docs/recordings/pantry.mp4` does not exist |
| Core 1 Shop clear sets in with `lastBoughtAt`; cook sets low and Produce out; staples untouched | PASS | Derived, not stored: `shopClears()` (`PantryLedger.swift:139-149`), `cookUses()` (`:152-167`, staples `:161-163,178-181`, optional and to-taste skipped). Tests `PantryLedgerTests.swift:48,73,97`. The fixture is the tacos in the test (limes out; tortillas and beef low), not the doc's chicken/onion/cilantro set |
| Core 2 "out of milk" / "have rice" one op, one UNDO | NOT BUILT | No grammar, no action (grep for "out of", "have rice", "got milk" in `TesseraTess` finds nothing relevant) |
| Core 3 Ingredient page cycle, one op per tap | NOT BUILT | No stored state to write |
| Core 4 Planning skips an in line; peek dry-run matches rows added | NOT BUILT | `Groceries` has no state rule; no dry-run function |
| Core 5 `RecipeMath.missing`, CAN COOK | NOT BUILT | `RecipeMath.swift` holds `scaled` only |
| Core 6 20-week fixture with cap 4 (R unchanged) | NOT BUILT | No USUALLY surface; `BuyCadence` untouched by Pantry. Fixture not run |
| Core 7 Pack snapshot holds no state and no `lastBoughtAt` | PASS | The words exist only in `PantryLedger` (app target); no Core or `TesseraTess` file mentions them (section 5) |

## 3. kitchen-refill5-pantry-acceptance.md, K26 to K28

Seeded-state rows are marked NOT BUILT where the row's subject is the key, the side, the state tap or a stored state; a row that exercises only the built front is walked on the front.

### K26 empty, one-item, 200-item

| Row | Verdict | Evidence and gap |
|---|---|---|
| K26.1 Fresh install | FAIL | No shop gives no context line (`PantryCopy.swift:8-9`), hero "Nothing yet", the body line, no groups: all right. Missing: weekday at 138, side word, and a Title is drawn that the sheet drops |
| K26.2 Banned strings; Tess line | PASS | None of "0 out", "Empty", "No items", "Get started" in the Pantry files; Tess line `PantryCopy.swift:34` |
| K26.3 Index and Home read "Nothing yet" | NOT BUILT | No index row, no Home line |
| K26.4 Side opens on "Nothing known yet." | NOT BUILT | No side |
| K26.5 Front does not scroll when short | PASS | `ScrollView` with indicators hidden (`PantryView.swift:34,83`); short content does not scroll. Not run |
| K26.6 "out of milk" to Tess | NOT BUILT | Core 2 |
| K26.7 Reduce Motion crossfade of the hero | NOT BUILT | Hero uses `.contentTransition(.identity)` (`:51`), so it just changes; the 150 ms crossfade is not written, and depends on K26.6 |
| K26.8 AX5 and VoiceOver | PASS | One column, body `fixedSize` (`:58`), the name `fixedSize` and the state word under it at accessibility sizes (`:189`, `:182-184`), reading order Pantry, hero, body line. Not run |
| K26.9 12 in, none low or out | NOT BUILT | Cannot seed in without a shop clear; the front half ("Nothing out", groups undrawn, in not listed) PASS by `PantryLedger.swift:78`, `PantryFront.swift:24-25`; side and USUALLY absent |
| K26.10 One out: limes | FAIL | "1 out", one OUT label, ring, no LOW label right; state word not ochre, no side |
| K26.11 Index and Home read "1 out" | NOT BUILT | |
| K26.12 Side glance and key | NOT BUILT | |
| K26.13 Key receipt "Pantry, 1 added." | NOT BUILT | No key |
| K26.14 State-word tap, then Ingredient-page cycle | NOT BUILT | |
| K26.15 One low: lemons | FAIL | "1 low", no OUT label, no ring right; key "ADD 1 TO GROCERIES" absent |
| K26.16 One private item | FAIL | Hero "1 out", reads "Private item", state word and ring, opens nothing, all right. Missing: 66% ink on the line; side line, key and "Private item, on Groceries." from the key |
| K26.17 Fixture A, 200 known | FAIL | Order out then low, aisle walk order inside a state, in hidden (`PantryLedger.swift:52-62`) all right; USUALLY HAVE absent |
| K26.18 Scroll whole, clear of Tess's band | FAIL | Only `.padding(.vertical, Theme.Spacing.l)` (`PantryView.swift:80`): no bottom inset for Tess's band at 736, and USUALLY HAVE has nothing to reach |
| K26.19 Back lands on the same offset | PASS | Native `NavigationStack` and `ScrollView`; 1 pt not measured |
| K26.20 Fling, lazy build | FAIL | Lines sit in a plain `VStack` and nested `ForEach` (`PantryView.swift:35,62-77`), not a lazy stack, so all 100+ lines are built at once. No Instruments run |
| K26.21 Tap "out" on the 12th line | NOT BUILT | No tap |
| K26.22 Side at 200 | NOT BUILT | |
| K26.23 Key adds 100, one op | NOT BUILT | |
| K26.24 Fixture B, 200 out | FAIL | "200 out", LOW label undrawn right; key absent |
| K26.25 Fixture C, 3 walled names | PASS | "Private item" in aisle position, counted in the hero, opens nothing (`PantryLedger.swift:169-175`; test `PantryLedgerTests.swift:85`). "to buy" count not built |
| K26.26 Counts agree across hero, glance, index, Home | NOT BUILT | Only the hero exists |
| K26.27 Tess line after a cook | FAIL | RULED by Product (decisions 5:12): "Tacos took 5 things." wins and names no ingredient. Up to 3 names the code is right; over 3 it says "a, b and N more" (`PantryCopy.swift:47`, reached by `PantryFront.swift:27`), which names two. FAIL, Builder B: over three names print "<Recipe> took N things." Default taken, Product to confirm: N counts every thing the cook used up, private ones included (on-screen counts keep private things and hide their names, decisions 3:25 #1), so the count is not `names.count` (`PantryLedger.swift:102` drops private names first). A Private recipe prints nothing at all (FG9) |
| K26.28 Scale | FAIL | `facts()` runs a full pass over every grocery child and every cook's lines (`PantryLedger.swift:115-136`). #739 cut `PantryPage.body` from three `entries()` calls to `PantryFront.init`'s two fact passes (`PantryFront.swift:21`, and `:27` through `lastCookUsedUp`, `PantryLedger.swift:102`) plus one `shopClears` pass for `lastShop()` (`:23`), once per render (`PantryView.swift:33`); still no cache, no Pantry case in `ScaleTests` or `scripts/test.sh`. Reads the in-memory graph, not the database. Soft-deleted shop rows are never pruned, so the walk grows for years (gap hunt 7, G48; unmeasured) |

### K27 state, date, low-stock wording

| Row | Verdict | Evidence and gap |
|---|---|---|
| K27.1 State words | FAIL | "out" 700 and "low" 600, lowercase, no icon, nothing red; not ochre mix. "in" and "unknown" on the Ingredient page not built |
| K27.2 "bought Sat" / "bought Tue" / nothing | NOT BUILT | `PantryDayWord.bought` is built and tested (`PantryDayWord.swift:5-9`; `PantryDayWordTests.swift:26`) but no view calls it; the side that shows it does not exist |
| K27.3 Older than 7 days: "bought Sep 26" | NOT BUILT | Helper returns "MMM d" with no year (`PantryDayWord.swift:30-36`); no surface |
| K27.4 4 AM day boundary | NOT BUILT | Helper uses `TesseraDay` (`:17-18`), test `PantryDayWordTests.swift:18` covers a 1:20 am check; no surface |
| K27.5 No expiry or forecast words | PASS | Grep of `Features` and `TesseraCore/Sources` for expire, use by, best before, spoil, going off, stale, fresh until, running out, low stock: no Kitchen or Pantry hit (the only "stale" hits are Live Activity and Backup code). Context line "since Saturday's shop" is a fact |
| K27.6 Ingredient page state sentence | NOT BUILT | `ObjectPage` is generic; no "Out. Bought Sat." |
| K27.7 "You buy milk about every 7 days." | NOT BUILT | `BuyCadence.swift:26` returns "You buy it about every N days." with no name and no surface on Pantry |
| K27.8 Cook finished 6:40 pm: no clock, lowercase | PASS | Tess's cook line carries no clock (`PantryCopy.swift:29`); `HouseTime.clock` is lowercase "6:40 pm" (`Format/HouseTime.swift:7-14`) |
| K27.9 "Tacos, 7 pm" / "7:30 pm" | PASS | `HomeLines.swift:267-273` via `HouseTime`; no "at". The KITCHEN index line itself is not built (S14) |
| K27.10 Hero combinations | PASS | `PantryLedger.swift:72-79`: "4 out, 2 low", "1 out, 1 low", "3 low", "5 out" |
| K27.11 "6 to buy" | NOT BUILT | No side |
| K27.12 Key label for 6, 1, 0 | NOT BUILT | |
| K27.13 USUALLY HAVE forms | NOT BUILT | |
| K27.14 Group labels | PASS | "OUT" and "LOW" uppercase from the state word (`PantryView.swift:65-66`); none of the banned labels. USUALLY HAVE tracked at S5 |
| K27.15 State-word tap receipts | NOT BUILT | |
| K27.16 Receipts that join a list | FAIL | Swipe receipt "Milk, on Groceries." is right (`PantryCopy.swift:40-42`), always "on"; "Milk, already on Groceries." now exists for the swipe (`PantryFront.swift:38`, #739); name tap does not join, key and "out of milk" receipts absent |
| K27.17 "out of milk" when already out and on Groceries | NOT BUILT | |
| K27.18 "have rice" / "got milk" | NOT BUILT | |
| K27.19 Walled name out, on every surface | FAIL | Front line and Tess line mask (`PantryLedger.swift:98-100,102,174`); line at 66% ink missing; side, USUALLY, index, Home, widget, Spotlight absent |
| K27.20 Tap, swipe, state tap on a private line | FAIL | Tap opens nothing and swipe receipt is "Private item, on Groceries." (`PantryView.swift:120` through `PantryCopy.added(entry.label)` at `:119`; opens nothing, `:134-136`); the state-word tap does not exist |
| K27.21 VoiceOver on a private line | FAIL | "Private item, out" and "Add to Groceries" right (`PantryView.swift:151-152`); cycle as default action missing |
| K27.22 Private ingredient in the side | NOT BUILT | |
| K27.23 Logs, pack snapshot, request bodies after K27.19 to .22 | PASS | No Pantry path to Claude or a log (section 5); the swipe's Groceries row follows the existing Groceries wall |

### K28 handoff, price drop, never-sums

| Row | Verdict | Evidence and gap |
|---|---|---|
| K28.1 Side glance and key "ADD 6 TO GROCERIES" | NOT BUILT | |
| K28.2 Key adds 6, one op | NOT BUILT | |
| K28.3 Dry-run proof | NOT BUILT | No shared dry-run count |
| K28.4 Everything already on Groceries: key hidden | NOT BUILT | |
| K28.5 UNDO inside and after 4 s | NOT BUILT | Slot exists (`HomeQueue.swift:32-50`), key does not |
| K28.6 UNDO slot timing | PASS | New add 4 s through `holds` (`PantryView.swift:119`); a change defaults to 10 s; VoiceOver forces 10 s (`HomeQueue.swift:46-52`); one shared slot. The change-type taps are not built |
| K28.7 Key then state tap replaces the receipt | NOT BUILT | |
| K28.8 Groceries rows after the handoff; shop clear returns them to in | PASS | A shop clear turns checked items into in with the check date (`PantryLedger.swift:139-149`; test `PantryLedgerTests.swift:73`). The handoff itself (key) is absent, so this half runs through the swipe |
| K28.9 Swipe on "Milk": line stays, receipt | PASS | Line stays (`PantryView.swift:106-121` writes only to Groceries), receipt "Milk, on Groceries." with UNDO 4 s; a second swipe says "Milk, already on Groceries." with no UNDO (`:107-112`, #739). "Next key count drops" needs the key |
| K28.10 Planned recipe against pantry (D1 Paprika chicken) | NOT BUILT | |
| K28.11 Key then recipe key, no doubling | NOT BUILT | |
| K28.12 Quiet hours: nothing scheduled | PASS | Pantry creates no notification, badge, Home offer or Live Activity (no such calls in the four files) |
| K28.13 Zero Claude requests from the Pantry action | PASS | Swipe calls `engine.perform(AddGroceries ...)` only (`PantryView.swift:113-114`) |
| K28.14 "out of milk $4" | NOT BUILT | Core 2 |
| K28.15 "we're out of eggs 3.49" | NOT BUILT | |
| K28.16 "no more rice, 2 lbs $9" | NOT BUILT | |
| K28.17 Voice "out of milk $4" in cook mode | NOT BUILT | |
| K28.18 "4 dollars", "€4" | NOT BUILT | The money strip itself exists for grocery lines (`EngineWall.swift:69`) but no phrase reaches it from Pantry |
| K28.19 "have rice $2" | NOT BUILT | |
| K28.20 Search of logs and bodies after K28.14 to .19 | NOT BUILT | |
| K28.21 Swipe on an ingredient whose old row had a price | PASS | The swipe passes the name only (`AddGroceries(lines: [name])`, `PantryView.swift:113-114`); nothing is copied |
| K28.22 Front and side strings carry no nutrition | PASS | Pantry files hold no nutrition word (section 4) |
| K28.23 Groceries and FOR WHAT carry no nutrition | PASS | `GroceriesView.swift` holds none (section 4) |
| K28.24 Chicken thigh PER 100 G side, one ingredient | NOT BUILT | No food table reader, no side (grep for kcal, USDA, per 100 g, food table: no code) |
| K28.25 No second ingredient on that side | NOT BUILT | |
| K28.26 Tess refuses to add calories | NOT BUILT | `I don't add food up. Ask me about one ingredient.` appears in no Swift file |
| K28.27 AI-12 snapshot holds no nutrition, state, `lastBoughtAt`; a test asserts it | FAIL | Snapshot is clean (section 5), but the asserting test does not exist |
| K28.28 Static check test for sums over nutrition | NOT BUILT | No test; no nutrition reader to guard |
| K28.29 Widgets, Live Activity, Spotlight, Intents, exports: no nutrition | PASS | None carries a nutrition number; exports hold no food rows because no food table is bundled yet |

---

## 4. K9: never-sums and PER 100 G audit on every Kitchen screen

Method: grep over `Features`, `App`, `TesseraCore/Sources` for kcal, protein, carb, fat, fibre/fiber, calorie, nutrition, "per 100", USDA, food table, and for `reduce`, `sum`, `total` near ingredients, recipes, cooks or groceries. Result: **there is no nutrition code of any kind** (the only Swift hits are the words "protein" in a recipe-name example, `PrivateFacts.swift`/`TessMemory.swift` health-word walls, and a US-spelling list), so nothing can sum it. The PER 100 G side itself is not built.

| Kitchen screen | Files | Sums or totals found | Nutrition shown | Verdict |
|---|---|---|---|---|
| KITCHEN page (Groceries, Pantry, Recipes words) | `HomeSpatialView.swift:363-382` | none | none | PASS |
| Pantry front | `Features/Kitchen/Pantry*.swift` | counts of out and low only (`PantryLedger.swift:73`) | none | PASS |
| Groceries list, basket, aisles, shop mode | `Features/Groceries/GroceriesView.swift` | `:56` sums open-item counts per aisle (a count, not food values) | none | PASS |
| Recipes entry | `Features/Recipes/RecipesEntry.swift` | none | none | PASS |
| Recipe page, ingredient list, "to buy" send | `Features/Recipes/RecipePage.swift` | `:102,227` counts of rows on Groceries | none | PASS |
| Portion drum (servings) | `Features/Recipes/PortionDrum.swift`, `RecipeMath.scaled` | scales amounts only; never a nutrition figure | none | PASS |
| Paste recipe | `Features/Recipes/PasteRecipe.swift` | none | none | PASS |
| Cook mode, cook line, timers | `RecipePage.swift:391-429`, `Kitchen/Cooking.swift` | `Recipes.swift:186` sums timer minutes (a duration), `RecipeLinkReader.swift:33` counts timers | none; `FinishCooking` records a date and duration | PASS |
| Ingredient page (generic object page) | `Features/Objects/ObjectPage.swift` | `:502` sums row heights (layout) | none: **no PER 100 G side exists** | PASS for never-sums; PER 100 G side NOT BUILT |
| Review week, "Cooked" band | `Home/ReviewPage.swift:290`, `ReviewWeek.swift:58` | sums the count of cooks per week (a count of events, N4 allows "the cooks") | none | PASS |
| Home and Now cook lines | `HomeLines.swift:223-302` | none | none ("Tacos, 7 pm", to-buy counts) | PASS |
| Tess kitchen grammar and tools | `TessGrammar+Kitchen.swift`, `TessTools.swift` | `:251` "Total time" is minutes of a recipe | none; the refusal line for calorie questions is not written | PASS for sums; N8 refusal NOT BUILT |
| Backup and export of kitchen data | `TesseraExport.swift`, `BackupView.swift` | none | none | PASS |

K9 summary: 13 Kitchen surfaces checked, 0 nutrition sums, 0 nutrition values shown. "Per 100 g on one ingredient only" cannot be checked because the one place it belongs is not built; when it lands, the one-reader test in `never-sums-audit.md` ("How it's proved" 1) must land with it, since today nothing guards against a later total.

## 5. Nothing from Pantry reaches Claude

- Pantry state exists only in `PantryLedger` (app target). Grep for `pantry`, `PantryLedger`, `lastBought` across `TesseraCore/Sources` finds only the aisle name "Pantry" in `Aisles.swift` (a shop aisle, not the screen) and the kitchen-area word list in `TessMemory.swift:713`.
- The pack and prompt paths (`ClaudeTessModel.swift`, `HomeDonePack.swift`, `PrivateFacts.swift`, `EngineWall.swift`, `TessTools.swift`) contain no ingredient state, bought date or Pantry string. `PrivateFacts` and `ObjectPrivacy` are used by Pantry as a wall only (`PantryLedger.swift:98,172`), never as a feed.
- The one write Pantry makes is `AddGroceries(lines: [name])` by the user (`PantryView.swift:113-114`). The row then sits under the existing Groceries wall. Risk to note, not a Pantry leak: the real name of a walled ingredient is written to Groceries unmasked (`PantryView.swift:113`); only the receipt says "Private item".
- Result: PASS. No test asserts it (Need, Core).

## 6. Private recipe lines and copy

- Private recipe lines: **FAIL** (FG9, ruled by Product, decisions Oct 17 5:12): Tess is silent on Pantry after a Private cook. The code still speaks: `PantryLedger.swift:97-100` turns the title into "Private recipe" and `PantryView.swift:97-98` says `PantryCopy.tess` (`PantryCopy.swift:29-31`) "Private recipe took the ..." (held by test `PantryLedgerTests.swift:111`, which must change). Owner Core / Builder B: `lastCookUsedUp` returns nil for a Private recipe (Core) and the test flips to "no line" (Builder B). Names of walled ingredients are dropped from the line of an ordinary recipe (`PantryLedger.swift:102`), which stays right, and K26.27's count keeps them in N.
- Receipts name the thing first with "on": "Milk, on Groceries." (`PantryCopy.swift:40-42`); across Kitchen: "Tacos, 10 added." (`Groceries.swift:418`), "Chickpeas, already on Groceries." (`TessCaptureEngine.swift:248,367`), "Private item, on Groceries." (`:371`), "N to buy, on Groceries" (`RecipePage.swift:102,227`). No "in Groceries", "to Groceries" or "added to" in Kitchen strings (the one "Added to today." at `TessCaptureEngine.swift:280` is a workout line). PASS.
- Clocks lowercase, no "at" before a clock: `HouseTime.clock` (`Format/HouseTime.swift`) is the only formatter in Kitchen paths; no `PM`, `AM` or "at <time>" strings in `Features/Groceries`, `Features/Recipes`, `Features/Kitchen`, `HomeLines.swift` cook lines. The only "at" strings are "paused at <exercise>" and "<set> at <load>", neither a clock. PASS.
- Pantry copy to align: "Tacos took 5 things." is RULED (decisions 5:12), so the code's "and N more" is a FAIL (K26.27, S13, Builder B). "Nothing known yet." (side) against "Nothing yet" (front) is already ruled in the acceptance file. The lists line shipped in #739 (`ListsCopy.swift:17`) is thing first ("Packing, nothing left.") and passes the house rules; the count form of the context line is G49.

---

## Re-check against #739

*`git show 0626534 --stat`: `Features/Kitchen/PantryFront.swift` (new, 42 lines), `PantryView.swift` (+42/-19), `Features/Lists/ListsCopy.swift` (4 lines), `TesseraTests/PantryFrontTests.swift` (new), `ListsCopyTests.swift` (+1). `PantryLedger.swift` and `PantryCopy.swift` are unchanged, so their cites above stand; every `PantryView.swift` cite in this file was moved to the 0626534 line numbers.*

| Row | Was | Now | What #739 changed (file:line) |
|---|---|---|---|
| S10 Left swipe | FAIL | **PASS** | "Milk, already on Groceries." with no second row and no UNDO: `PantryFront.swift:36-41`, `PantryView.swift:107-112` |
| S16 Reduce Motion, Type, VoiceOver | FAIL | FAIL (smaller) | AX layout (state word under the name) built, `PantryView.swift:180-197`; the cycle as default action and the crossfade remain |
| K27.16 Receipts that join a list | FAIL | FAIL (smaller) | "already on" now exists for the swipe (`PantryFront.swift:38`) |
| K26.8 AX5 and VoiceOver | PASS | PASS | Same verdict, new cites (`PantryView.swift:58,182-189`); not run |
| K26.28 Scale | FAIL | FAIL | Three `entries()` calls became two fact passes plus one clear pass per render (`PantryFront.swift:21,23,27`) |
| S13 Tess's line, K26.27 | FAIL | FAIL (now ruled) | `PantryFront.tess` (`:27`) still calls `PantryCopy.tess`; ruling below |
| S1, S3, S4, S7, S12, S15, S17, K26.5, K26.9, K26.18, K26.20, K27.14, K27.20, K27.21, K28.6, K28.9, K28.13, K28.21 | unchanged | unchanged | Verdict stands; `PantryView.swift` cites moved only |

**Counts moved:** S 6/7/4 to 7/6/4 (PASS/FAIL/NOT BUILT); total 30/24/54 to 31/23/54 (108 rows). The Private recipe line (section 6) moves from PASS to FAIL; it is not a numbered row, so the table does not change for it.

**Rulings applied (Product, decisions 5:12):** (1) K26.27 and S13: "Tacos took 5 things." wins over "a, b and N more" because it names no ingredient; the code's form is a FAIL to fix, Builder B. (2) FG9: Tess is silent on Pantry after a Private cook; the previous PASS for "Private recipe took the ..." is a FAIL, owner Core / Builder B. New gaps found in this pass are in `kitchen-gap-hunt-7.md` (G40 to G50; G45 to G48 and G50 touch Pantry).

---

## Summary

| Section | Rows | PASS | FAIL | NOT BUILT |
|---|---|---|---|---|
| pantry-acceptance S1 to S17 | 17 | 7 | 6 | 4 |
| Builder B done-when 1 to 4 | 4 | 2 | 1 | 1 |
| Core 1 to 7 (as the app ledger covers) | 7 | 2 | 0 | 5 |
| K26 (empty, one item, 200 items) | 28 | 5 | 10 | 13 |
| K27 (state, dates, wording, private) | 23 | 6 | 5 | 12 |
| K28 (handoff, price drop, never-sums) | 29 | 9 | 1 | 19 |
| **Total** | **108** | **31** | **23** | **54** |

K9 (never-sums, per 100 g): 13 Kitchen surfaces, 0 sums, 0 nutrition values; the PER 100 G side is NOT BUILT. Claude wall: PASS. Private recipe line: FAIL (FG9 ruled). House-rule copy: one FAIL (K26.27 and S13 ruled "Tacos took 5 things."); the rest PASS.

## Need, by owner

**Core**
1. Stored ingredient state and `lastBoughtAt` (in, low, out, unknown) written by ops, so states can be set, cycled and undone; lift `PantryLedger` into `TesseraCore` (S7, Core 3, every seeded K26/K27/K28 row).
2. "out of milk", "no more rice", "have rice", "got milk" grammar with the price strip, one op, "Milk, out. On Groceries." (Core 2, K28.14 to K28.20, S12's promise).
3. `RecipeMath.missing` and CAN COOK, the shared dry-run count, planning that skips in lines (Core 4, 5, K28.3, K28.10, B3).
4. USUALLY HAVE feed at cap 4 and the 20-week fixture (S5, S6, Core 6); a buy-rhythm line with the name ("You buy milk about every 7 days.").
5. The food table reader behind one Ingredient (PER 100 G side), plus the tests the audit asks for: one reader only, no nutrition field in the pack, no Pantry state in the pack (K28.24 to K28.28, Core 7).
6. Tess route for "pantry" / "what do I have", and the calorie refusal line (B1, K28.26).
7. `lastCookUsedUp` returns nil for a Private recipe (FG9, with Builder B), and counts the used-up things for the "N things" form (K26.27).

**Builder A** (Kitchen and Home surfaces outside the Pantry page)
1. The five-row KITCHEN index with Pantry's hero line, and Home's Pantry line verbatim (S12, S14, K26.3, K26.11, K26.26).
2. The recipe peek's have / low / out words and the out-line ring on the recipe page (S3, B3, K28.10).
3. Ingredient page state sentence and cycle (K27.6, K26.14).

**Builder B** (the Pantry screen)
1. Frame per sheet 78: drop the Title, add the weekday and the OUT AND LOW side word (S1, K26.1).
2. Ochre token and state-word colour; 66% ink on a private line (S3, S17, K27.1, K26.16).
3. The OUT AND LOW side and the key (glance, full side, "bought Sat" via the already-written `PantryDayWord`), USUALLY HAVE, state-word tap with UNDO 10 s (S5 to S7, K26.12 to K26.23, K27.2 to K27.4).
4. ~~Swipe: detect "already on Groceries"~~ done in #739 (S10); still to do: the name tap and the "out of milk" paths for K27.16 and K27.17, and count a checked basket row as covering the swipe (G47).
5. Lazy stack for the lines, bottom inset for Tess's band, read the ledger once per render (two fact passes and a clear pass remain after #739), and a Pantry scale case (K26.18, K26.20, K26.28).
6. ~~AX layout (state word under the name)~~ done in #739; still to do: default VoiceOver action as the cycle, Reduce Motion crossfade for hero changes (S16, K26.7).
7. Over three names print "Tacos took N things." (ruled 5:12; K26.27, S13), and say nothing after a Private cook (FG9 ruled; with Core), then record `docs/recordings/pantry.mp4` (B4).

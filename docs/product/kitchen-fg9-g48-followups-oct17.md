# Kitchen follow-ups: FG9 sharpened, and the G48 scale-case spec for Core

*Kitchen lead, Oct 17. Docs only; read from master 70288fa, nothing run. Asked by Product after the G1-G50 re-check (`kitchen-gap-recheck-g26-g50-oct17.md`).*

## 1. FG9 sharpened (Builder B)

K86.9 already says Tess says nothing on Pantry after a finished cook of a Private recipe. The re-check found master still prints "Private recipe took the ...". This section gives the fix point and the row to test.

- **Where it goes wrong.** `PantryLedger.lastCookUsedUp()` (`Features/Kitchen/PantryLedger.swift`, the block that sets `title`) maps a private recipe to `ObjectPrivacy.recipeLabel` ("Private recipe") and then still returns `(title, names)`. `PantryFront` (`tess = ledger.lastCookUsedUp().map { PantryCopy.tess(...) }`) turns that into "Private recipe took the cilantro and limes." The recipe name is masked, but the line still tells him that a Private cook used up named ingredients, and the names are the cook's ingredient words (K86.9 forbids those in the Tess slot and the accessibility tree).
- **Fix.** `lastCookUsedUp()` returns nil when the recipe title is a private one (the same `isPrivateRecipeTitle` test that picks the label). The hero and the OUT and LOW lists still change as normal; only the Tess line goes. Names on the lists stay under the ingredient wall as today.
- **Row K89.1 (FG9).** *Given* a Private recipe cooked to DONE that used limes and tortillas, with limes now out. *When* Pantry opens. *Then* the hero and the OUT line change ("1 out"), the Tess slot is empty, and no string in the view or its accessibility tree contains the recipe's words or "Private recipe took". *Given* an ordinary recipe cooked the same way. *Then* the line is unchanged: "Tacos took the cilantro and limes.", and "Tacos took 5 things." over three names.
- **Test.** One Swift Testing case in `PantryFrontTests`: build the ledger from a private-titled recipe's cook and assert `front.tess == nil` while `front.hero` still counts the out line. Owner: Builder B (`PantryLedger` is app-side).
- **Not ruled, not needed.** A nameless count line ("5 things used up.") for a Private cook stays unwritten; K86.9's default is silence and Product has not asked for more.

## 2. G48 scale case (Core runs it on the Mac)

This container has no Swift toolchain and no store copy, so the cost in G48 is still unmeasured. This is the exact case for Core to add and run, so the row gets a number.

- **Case.** Add `groceriesAndPantryStayFast` to `TesseraCore/Tests/TesseraCoreTests/ScaleTests.swift` (in-memory container, `SystemCatalog.seed`, same pattern as `historyQueriesStayFast`). Build five years from `docs/research/fixtures/year-of-data.md`: 104 weeks x 2 shops, about 14 rows each (85% linked to an Ingredient), each shop run `StartShop`, check every row, `FinishShop`, `ClearDoneItems`. That leaves about 7,000 soft-deleted rows under Groceries. Add 40 recipes and 3.5 cooks a week (about 900 cooks).
- **Measure, with `ContinuousClock`, 5 runs each, report the median and worst:**
  1. `Groceries.open`, `sections`, `isOn`, `toBuy(for:)` and one `done` on the loaded list.
  2. `PantryLedger.entries()` once, then `lastShop()`, then `lastCookUsedUp()` (the three reads `PantryFront.init` makes per render).
  3. The same with the tombstones removed (a control: the same data without the 7,000 deleted rows), so the share due to tombstones is a number.
- **Budget.** The same one the other 5-year screens hold in `scripts/test.sh --scale`; if none is stated for these, Core proposes one from the control run and Product rules it. A render that re-runs on every `model.revision` tick should stay well inside a frame.
- **Also check** (from the re-check): hunt 7 named `orderedChildren` as sorting deleted rows; the re-check found it filters deleted rows before sorting, so the cost is in the tombstone walk and the double `entries()` read, not in a sort. The case should say which it is.
- **Done when** the three timings are written into the G48 row (median, worst, control) and Core or Builder B has a fix or a ruling that none is needed.

# Review #722 at 9035a164 (Builder B, B1 PantryLedger)

Static. Merges clean; two new files only (Features/Kitchen/PantryLedger.swift, TesseraTests/PantryLedgerTests.swift).

- Read-only: only ObjectStore reads (object(id:), value, linkedObjects, objects(of:), Groceries.ingredient(of:), RecipeBook.lines). No engine, transaction, perform, save or defaults. Nothing stored, no migration, no launch path.
- Facts: shop clears = soft-deleted + isDone + checkedAt (an UNDO of the clear un-deletes and drops the fact); cooks = objects(of: cook) excludes deleted, and only cookedAt set by FinishCooking counts (stale-closed cooks never set it, so they add nothing). Latest wins; tie sorts out > low > in via the max comparator (lhs.state > rhs.state on the tie keeps the lower raw value). Cook never moves lastBoughtAt (tested). Staples skipped by the line flag, the ingredient flag and AisleGuide. Time passing never changes a state.
- Test trace matches: tacos shopped, cooked 2 days later gives Limes out (produce), tortillas and beef low; salt (staple) never appears; a later shop makes all in.
- Walls: pantry-acceptance S15 and K27 keep a walled ingredient IN the data and mask it at display ("Private item", not tappable, no Claude). The ledger does that: it holds the fact and nothing leaves it. M1 (for the page PR, not a blocker here): Entry has no walled flag or label, so every consumer (page, Tess line, widget, Home, Spotlight, Claude) must remember to call EngineWall.isHealth / ObjectPrivacy on displayTitle. Suggest adding `var label: String` ("Private item" when walled) or `isWalled` to Entry so there is one place. A private recipe's cook still makes plain ingredients low; no recipe title is carried, which is right.
- Lows: L1 optional recipe lines (line.optional) and toTaste lines count as used; L2 a deleted recipe linked from a cook still yields lines (linkedObjects); L3 the test needs the simulator, ported package run 2 of 2 per Builder B.

PASS. M1 must be closed before any view reads entries().

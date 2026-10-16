# QA review: #380 Kitchen slice (Core, core/kitchen-week)

Head `79475ed`, rebased on master `0bff60b`. The trial merge is clean.
8 files, +314 / -29, all inside TesseraCore. This is a static review: I have no Swift toolchain here, so
"package 431 green" is Core's run.

## Verdict: FIX FIRST

There are three small fixes, all in the parser and the join rule. Two of them are regressions this PR introduces.

**F1: "plus more to serve" drops the whole line.** `Quantities.swift:146-153`.
- Take "1/2 cup grated parmesan, plus more to serve".
- The first regex (`:140`) strips " to serve", which leaves ", plus more".
- The new optional regex then matches `plus more`, so `optional = true` and AddRecipeToGroceries skips parmesan.
- Research's r4 row (groceries-recipes.md:153) expects **¼ cup parmesan** on the list, and says the line "still
  adds, which is right here".
- "plus more for serving" goes wrong the same way. G-R4 only names optional, for serving and for garnish.
- r4 isn't in GroceriesWeekTests (it traces r1, r2, r3 and r5), so nothing caught this.
- Fix: drop the `plus more…` alternative, or strip "plus more …" as a note without setting `optional`. Then add
  r4's parmesan line to the test.

**F2: "extra virgin olive oil" becomes "virgin olive oil" and lands on the list.** `Quantities.swift:216`.
- `sizeWords` now holds a bare "extra", so the first-word loop strips it.
- The new staple entry "extra virgin olive oil" (`Aisles.swift:32`) is therefore never reached.
- The line becomes the ingredient "virgin olive oil" with no aisle, so it goes in Other.
- The old regex only stripped `extra[- ]large`. This is a regression, and the unhyphenated spelling is the common
  one on US recipe sites.
- Fix: take "extra" out of `sizeWords` and strip "extra large" / "extra-large" as one word. Then add a test with
  "2 tbsp extra virgin olive oil" that expects the line to stay off the list.

**F3: a sized can now joins an unsized can, depending on the order.** `Groceries.swift:216-227`.
- With `share.packSize` set, `sizes.isEmpty` is true for a row that holds only "1 can coconut milk" (no size).
- So "1 can coconut milk" followed by "1 (13.5 oz) can coconut milk" makes one row, "2 cans". U5 says a sized can
  never joins an unsized one.
- The old `allSatisfy { $0.packSize == share.packSize }` refused this. USKitchenTests.swift:81 only tests the
  other order.
- Fix: a sized share joins when `sizes == [size]`, or when `sizes.isEmpty` and no share on the row is an
  unsized pack. That keeps G-R8's "1 can + 15 oz". Then add the reverse-order case to the U5 test.

## What passes

- **Catalog v8**
  - It adds two fields to Recipe Ingredient: `packSize` (text) and `optional` (bool). There are no renames, no
    removals and no SQL.
  - Seeding adds them the same way v6 and v7 did.
  - Stored recipes keep a nil pack size, because pack size was parsed but never stored before. So nothing changes
    for his existing lines.
  - `settingsAreReal` and `migrateAtLaunch` aren't touched.
- **Data safety**: no launch flags, no ProcessInfo, no UI tests, no backup format change.
- **Research traces**
  - **r1:** tacos, "Tacos, 10 added."
  - **r2:** the 28 oz can is its own row.
  - **r3:** the 14.5 oz can never joins r2's can. Optional bagel seasoning is not listed.
  - **r5:** the frittata gives "3 added.", and eggs, milk and spinach join existing rows.
  - These match groceries-recipes.md as far as the code reads; GroceriesWeekTests asserts each one.
  - G-R3 (staples joined by and/&), G-R5 (prep words, but pack contents keep "diced tomatoes"), G-R6 (aliases,
    red onion stays), G-R7 (US aisle words), G-R8 (packs first) and G-R16 (⅛ tsp floor) are all in.
- **Receipt**
  - `summary(in:)` runs right after apply (ActionEngine.swift:58), so the 60-second window does what it says today.
  - The wording "Tacos, 10 added." matches decisions.md.
  - The fallback "nothing new to buy" is new wording. That's Product's call, flagged below.

## Lows

- **L1.** `summary` counts rows by `Date.now - createdAt < 60` (Groceries.swift:328).
  - Re-adding the same recipe at a new size within a minute counts its first add's rows again.
  - It also reads the wall clock inside the engine, while the rest of the engine takes `time`.
  - Counting from what `apply` returned is exact. One way: stash the count on the transaction, or compare
    `before` against the list.
- **L2.** "nothing new to buy" is a string Product hasn't ruled on. W12 only gives "Tacos, N added." Ask Product
  for the zero case.
- **L3.** The "covered" check (Groceries.swift:300-304) skips a line whenever a checked row for that ingredient
  is still on the list. Rows only clear at FinishShop. If he checks off milk on Monday and never taps finish, every
  later recipe's milk is skipped until he does. That follows Kitchen lead's G-R2 ruling as written, so I'm noting
  it for Kitchen to confirm, not for Core.
- **L4.** Prep words are stripped for non-pack units, so "14 oz diced tomatoes" (no can word) becomes tomato and
  goes in Produce. That's rare in pastes, so it's only a note.

## Acceptance

- GroceriesWeekTests with r4 added (F1), plus the F2 and F3 tests.
- Next-build script row **M4 (catalog v8)**, added in this round. The migration gate now spans v5 to v8.

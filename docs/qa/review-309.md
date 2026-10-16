# Review: PR #309, US shop units (head 10bede5)

QA thread, Oct 15 PT. Static review (no Swift toolchain here). Base 7c01d35, which is current master. Files: `TesseraCore/Sources/TesseraCore/Kitchen/{Aisles,Groceries,Quantities,RecipeMath}.swift` and the tests `USKitchenTests` (new), `GroceryTests` and `ShoppingTests`. Checked against Research's U1-U7 (`research/fixtures/recipe-paste-corpus.md`, "Design's answers") and Design's `kitchen/us-shop.md` and `us-kitchen-pages.md` §6.

**Verdict: FIX FIRST (two small fixes).** Parsing, merging and M12 are right, and nothing changes on launch. But old aisle names can split one aisle into two sections on his phone (S1), and the pack size is parsed and then never reaches the screen (S2).

## 1. U1-U7: parsing PASS, display partial

| # | Line | Parse at 10bede5 | Grocery row | Status |
|---|---|---|---|---|
| U1 | 1 bag spinach (6 oz) | 1, bag, "6 oz", spinach (`sizeInBrackets`, Quantities.swift:175-179) | "1 bag", size not shown | parse PASS, display S2 |
| U2 | 1 jar marinara (24 oz) | 1, jar, "24 oz", marinara | "1 jar" | parse PASS, display S2 |
| U3 | 1 carton chicken broth (32 fl oz) | 1, carton, "32 fl oz", chicken broth | "1 carton" | parse PASS, display S2 |
| U4 | 2 (15 oz) cans + 1 (15 oz) can chickpeas | 2 and 1, can, "15 oz" (`sizeBeforePack`, :160-163) | one row, "3 cans" | merge PASS, display S2 |
| U5 | 1 (14.5 oz) + 1 (28 oz) can diced tomatoes | the sizes differ | two rows, both reading "diced tomatoes · 1 can" | merge PASS (no wrong sum), display S2 |
| U6 | 1 can (14.5 oz) diced tomatoes ×2 | can, "14.5 oz" | "2 cans", in Cans and jars | merge PASS, display S2 |
| U7 | 1 pint cherry tomatoes | 1, pint, cherry tomatoes | "1 pint" (pint sits with the other units, never ml) | PASS |

More cases that pass: "1 (15-ounce) can", "1 14.5 oz can", "1 (6 oz) bag", "4 fl oz" and "4 fl. oz" (two-word unit tried first, :165), and "16oz pasta". The lookahead keeps "canned", "bagels" and "jarred" from reading as pack words.

Merge rows match Design:
- 8+8 oz → "1 lb"; 12+12 oz → "1½ lb"; 9+9 oz → "18 oz".
- "1 lb + 2 cups"; "500 g + 1 lb" (never converted); "4 oz + 4 fl oz".
- The walk order and the four new aisle names match us-shop.md rows 8-9.
- A can, jar, carton or bottle never lands in Produce (Groceries.swift:176-179), while a bag of spinach stays in Produce.
- ⅓, ⅔ and ⅛ show as glyphs.
- Resizing rounds oz and fl oz to whole numbers, lb to a quarter, and pint or quart to a half.

## 2. S1: old aisle names split one aisle into two sections (must fix)

- `Aisle.shown` only renames a section when it's read (Groceries.swift:35). The stored `section` on existing list items stays "Tins and jars", while every new add stores "Cans and jars", because `aisle(of:)` returns the shown name (:156).
- `ListContents.sections(of:)` (Lists.swift:47-56) groups by the stored string, so an existing list gets two groups. `aisles()` then shows both as "Cans and jars". The same happens for Dairy, Meat and fish, and Dry goods.
- GroceriesView.swift:92 uses `ForEach(..., id: \.element.aisle)`, so two entries share one id. That gives two "Cans and jars" headers at best, and SwiftUI's duplicate-id behaviour (rows drawn wrong, animation glitches) at worst. Shop mode can also say "then Cans and jars" while he's standing in Cans and jars.
- Fix (no migration, nothing destructive): in `aisles()`, group by the shown name after mapping, joining the items in order. Test: one item stored under "Tins and jars" plus a new can, then expect `aisles()` to hold a single "Cans and jars" entry.

## 3. S2: the pack size never reaches the screen (must fix, or hand it to Builder B by name)

- `packSize` lives only inside `GroceryShare` (Groceries.swift:62-67), which is internal. `quantity()` never prints it, and `ListContents.Item` has no field for it. Design wants "**1 can** diced tomatoes · 14.5 oz" (us-shop.md:19, us-kitchen-pages.md §6), but Builder B has nothing public to read.
- Today U5 shows two identical rows, "diced tomatoes · 1 can" and "diced tomatoes · 1 can". That reads as a duplicate bug, and he can't tell which can to pick off the shelf, which is the whole point of U5.
- Fix: expose the size per row, for example a public `Groceries.packSize(of: item) -> String?` read from the shares, which are all the same size by the new merge key. The tests in `packSizesMergeOnlyWhenTheSizeMatches` should then expect "14.5 oz" and "28 oz" on the two U5 rows. Builder B draws the dot.

## 4. Old items and the merge key: PASS (nothing changes on launch)

- Nothing runs at launch. There's no migration, and stored shares, sections and learned aisles are never rewritten.
- Old shares have no `packSize` key and decode as nil (a synthesized optional), so they still merge with new unsized shares of the same ingredient. The merge key is only checked when a new share is added (Groceries.swift:170-174). Existing rows can't split or duplicate on launch.
- A new sized can next to an old unsized row of the same ingredient makes a second row, by design ("a size-less can never merges with a sized one").
- L1: old items that were saved under the old parse ("cans chickpeas", "bag spinach") won't merge with new adds ("chickpeas"), which makes two rows. Rare, and nothing is lost.
- L2: on a rollback, an old build can't decode a share whose unit is "oz", "lb", "bag" and so on. That item's shares decode as empty, so its quantity can be rebuilt wrong on the next add. That's acceptable under the existing rollback rule.

## 5. M12: PASS

- `isMoney` (TessGrammar+Kitchen.swift) isn't touched by this PR. It still strips a unit price before looking for a currency sign.
- The SetLossTests row US3, "chicken $1.29/lb, rice" → groceries, still stands. US1 and US2 (spends) still return nil.
- The new unit words don't change routing: `looksLikeGroceries` and the single-item path only ask whether an amount is present, and that was true before for "2 lb chicken".

## Lows (not blocking)
- L3: the new words can capture a name. "1 pound cake" reads as 1 lb of cake, and "1 bottle gourd" as a bottle of gourd. Rare.
- L4: a bare "chickpeas" added after "1 (15 oz) can chickpeas" makes a second row, because a nil size doesn't match "15 oz". Arguably the bare line should join any row of that ingredient. Design call.
- Core's stated follow-ups are out of scope here: plural names, amount spans in step text, "bucks" and the US demoKitchen seed.

## Must fix before merge
1. S1: merge sections by their shown name in `Groceries.aisles()`, plus a test.
2. S2: a public read of a row's pack size, plus the U5 test expecting both sizes.

## Addendum: head c99cb0f (GitHub head confirmed), PASS

This is one commit on top of 10bede5. A trial merge onto current master (f1bf709) is clean.
- **S1, closed.** `aisles()` (Groceries.swift:31-46) now groups by the shown name, keeping first-seen order. It drops done items, then sorts by walk order, so an old "Tins and jars" item and a new can share one "Cans and jars" entry. The `ForEach` id in GroceriesView is unique again. `shoppingOrder()` (Shopping.swift:8-10) and the shop line read `aisles()`, so shop mode is fixed too. Test: `anOldAisleNameAndANewOneAreOneSection` (one entry, 2 items).
- **S2, closed.** The public `Groceries.packSize(of:)` returns the first share's size. Every share on a row has the same size, because of the merge key. The U5 test now expects "14.5 oz" and "28 oz". Builder B draws the "· 14.5 oz".
- The lows L1-L4 stand and are not blocking. Nothing writes on launch.

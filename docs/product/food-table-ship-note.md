# K14: USDA food-table bundle, ship or hold

*Kitchen lead, 2026-10-17*

**Recommendation: SHIP**, with two Core gates (below). Nothing found blocks it.

## Licence and terms
- Checked: `fdc.nal.usda.gov` was **unreachable today** (DNS failure on /api-guide and /faq), so I re-checked nothing live. **Unverified today.**
- Last verified by Research on 2026-10-16 (`docs/research/food-table-usda.md` s1, page https://fdc.nal.usda.gov/api-guide): "public domain ... not copyrighted ... CC0 1.0 Universal. No permission is needed ... we request that users list FoodData Central as the source". data.gov record (https://catalog.data.gov/dataset/fooddata-central, read 2026-10-16) gives the US public domain label. The usa.gov label page was not fetched: unverified.
- Attribution wording: "Food facts: USDA FoodData Central (public domain, CC0 1.0). Source: U.S. Department of Agriculture, Agricultural Research Service, FoodData Central." No licence text has to ship.
- Where: the PER 100 G side shows "USDA FoodData Central" under the numbers (row 2.1); the full line goes on the licences/credits page in Settings. The two USDA pages word the citation differently (API guide: "FoodData Central, 2019"; home page: "Beltsville Human Nutrition Research Center"). Use the home-page form and pick one.
- No USDA name, seal or logo as endorsement. The "notify us" request is optional; Kaushik decides.

## Size and shipping
- 271 food keys (285 guide keys less 14 household), fewer once no-match rows drop out.
- Compact JSON, about 100 bytes a row: **25-30 KB**, under 10 KB gzipped. With FDC descriptions about 45 KB. Negligible.
- Ships as one generated JSON resource in the app bundle (or TesseraCore resources), read by one reader behind the Ingredient side. Per 100 g only; `foodPortions` dropped at build; each row keeps fdcId and dataType.

## Update check
- No network at runtime. The app never calls FDC.
- A refresh is a build-time script over the FDC Foundation and SR Legacy CSV downloads, filtered to the key list, output committed as one file and reviewed in a PR.
- Who: Core, run by hand. How often: when the key list changes, or once a year. SR Legacy is frozen. Foundation is updated by USDA a few times a year (unverified here; data.gov showed a last update of 2025-11-21).
- Each refresh re-runs the 20-key fixture test and rows 2.1b (no 2047/2048 energy) and 2.1c (stored unrounded).

## Walls
- Nothing sent to Claude by the table. The only Claude path is the existing sheet 75 s3 ask for a rowless key: key only, once, off for private recipes, off when "Tess asks Claude" is off.
- Nothing summed: no per-serving field, no totals (rows 2.1c, 2.4, `never-sums-audit.md` N5). One reader of the table, with a build-failing import test.

## Open items
1. Core re-checks the 20 fixture values against the FDC CSV: Research read them through a summarising fetch.
2. Foundation records may lack energy 1008 (only Atwater 2047/2048). Fall back to that key's SR Legacy record, whole.
3. Core asserts the 271 count from code (Research counted by a re-implementation).
4. Re-read the licence page when the network is back, and fetch the usa.gov label.
5. Kaushik: notify FDC, yes or no.

## What would flip it to HOLD
- The live FDC page no longer says public domain / CC0.
- The CSV re-check shows fixture mismatches that cannot be fixed.
- More than a few rows mix energy methods.

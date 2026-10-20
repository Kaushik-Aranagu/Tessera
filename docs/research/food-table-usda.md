# Food table: USDA FoodData Central for the PER 100 G side

Asked by: Kitchen lead (Design sheet 75). The ruling is `kitchen-sides-acceptance.md` §2. It is not on origin/master
(a438262), so this note read it from `/mnt/project-files/tessera/product/kitchen-sides-acceptance.md`.
Read and written: 2026-10-16. Docs only, no app code.

Fixture: `docs/research/fixtures/food-table-20.json` (20 rows, every value read from FDC on 2026-10-16).

## 1. Licence line

Primary source read: **https://fdc.nal.usda.gov/api-guide** (and the FDC home page, https://fdc.nal.usda.gov/index.html),
read 2026-10-16. The text, as published:

> "USDA FoodData Central data are in the public domain and they are not copyrighted. They are published under CC0 1.0
> Universal (CC0 1.0). No permission is needed for their use, but we request that users list FoodData Central as the
> source of the data, and when possible, notify us of the product that uses the data so we may better track how FDC is
> being used."

Suggested citation. The two pages give it differently:
- API guide: "U.S. Department of Agriculture, Agricultural Research Service. FoodData Central, 2019. fdc.nal.usda.gov."
- Home page: "U.S. Department of Agriculture, Agricultural Research Service, Beltsville Human Nutrition Research Center.
  FoodData Central."

data.gov catalog, **https://catalog.data.gov/dataset/fooddata-central**, read 2026-10-16: License
`https://www.usa.gov/publicdomain/label/1.0/` (US public domain label), Access Level "public", publisher Agricultural
Research Service (Department of Agriculture), dataset last updated November 21, 2025.

Endorsement: no "do not imply endorsement" sentence was on the FDC pages I read (api-guide, home, download-datasets,
data-documentation, faq). It is still the house rule for any US government work: the side must not use the USDA name,
seal or logo in a way that suggests USDA backs Tessera. The side's source line "USDA FoodData Central" names the data
source only, which is exactly what FDC asks for. I could not fetch the usa.gov public domain label page.

**Line for the app and the ship list:** "Food facts: USDA FoodData Central (public domain, CC0 1.0). Source: U.S.
Department of Agriculture, Agricultural Research Service, FoodData Central." No licence text has to ship. The source
line on the side (§2) satisfies the attribution request. The optional "notify us" request is for Kaushik to decide.

## 2. Subset: one row per known ingredient key

### The keys on master (a438262)

- The list: `TesseraCore/Sources/TesseraCore/Kitchen/Aisles.swift:63` (`AisleGuide.guide`), with one `add(...)` per
  aisle at lines 70 (produce), 78 (bakery), 79 (meat and seafood), 84 (dairy), 89 (pantry), 97 (cans and jars),
  105 (spices), 112 (frozen) and 113 (household).
- Every name goes through `IngredientLine.key(for:)` (`Kitchen/Quantities.swift:283`): lowercased, plurals made
  singular, then folded by `aliases` (`Quantities.swift:292`: whole/2%/skim milk to "milk", yellow/brown/white onion
  to "onion", all-purpose/plain flour to "flour").
- Staples: `Aisles.swift:30` (`AisleGuide.staples`) adds 10 more names not in the guide (water, extra-virgin olive oil
  twice, canola oil, avocado oil, cooking spray, two black-pepper spellings, table salt, flaky salt).

**Count:** 285 distinct keys in the guide after `key(for:)`. 14 are household (foil, soap...), so **271 food keys**.
By aisle: produce 66, pantry 55, cans and jars 49, spices 34, meat and seafood 26, dairy and eggs 23, bakery 12,
frozen 6. (Counted with a re-implementation of `key(for:)` and `singular`; Core should assert the same number from
the code.) The table also covers keys that users teach the app later only through Claude's ask in §2, never by a
bigger bundle.

### What each row holds

Five values per 100 g, all from FDC nutrient ids (the record's legacy "number" in brackets):

| Field | FDC id (number) | FDC name | Unit |
|---|---|---|---|
| kcal | 1008 (208) | Energy | kcal |
| protein_g | 1003 (203) | Protein | g |
| carbohydrate_g | 1005 (205) | Carbohydrate, by difference | g |
| fat_g | 1004 (204) | Total lipid (fat) | g |
| fiber_g | 1079 (291) | Fiber, total dietary | g |

Plus: `key`, `fdcId`, `dataType` ("Foundation" or "SR Legacy"), and the FDC description as published, so anyone can
check a row on fdc.nal.usda.gov.

### Which FDC record

1. **Foundation Foods first**, when a Foundation record names the same food in its raw, as-bought form *and* publishes
   all five values. Caution found while reading: in the Foundation records I opened (790646 "Onions, yellow, raw",
   747447 "Broccoli, raw") no energy entry under id 1008 appeared in the part of the record I could read. Foundation
   often states energy only as Atwater factors (ids 2047 and 2048). The build script must check this in the download
   and not swap in 2047 silently: if a Foundation record lacks 1008, use SR Legacy for that key, or record which id
   the energy came from. Mixing energy methods across rows is a decision for Core, not something to paper over.
2. **SR Legacy otherwise.** Every SR Legacy record I read has all five under the ids above. All 20 fixture rows are
   SR Legacy for this reason, marked per row.
3. **Raw and as bought.** "Onions, raw", not cooked. Dry pasta, rice, oats and lentils, because that is what the
   list and the pantry hold. Meat as sold (chicken thigh: meat only, raw, 173627; the skin-on record is 172385 at
   221 kcal, if Kitchen prefers that).
4. **Synonyms share a row.** chili/chilli, cilantro/coriander (the leaf), zucchini/courgette, eggplant/aubergine,
   yogurt/yoghurt, pita/pitta, scallion/green onion/spring onion, shrimp/prawn, all point at
   the same fdcId.
5. **No good match: leave the row out. Never guess, never average two foods.** Leave out any key whose food is a
   category or a mix: nut, oil, pepper (bell or black?), cheese, stock, stock cube, broth, cereal, curry paste,
   mixed herb, taco seasoning, italian seasoning, everything bagel seasoning, salsa, pesto, wrap, roll, bun, ice,
   household. Also leave out any key where the only FDC records are a brand or a cooked dish. A missing row
   is fine by §2.2 (the side shows only where it's used) and is the case Claude's single ask in §2.3 covers.
6. Salt and water may have rows if FDC has a plain record for them; Kitchen may also leave them out. Either
   is honest.

## 3. Fixture: 20 keys

`docs/research/fixtures/food-table-20.json`. All 20 values came from FDC directly, read on 2026-10-16 from
`https://fdc.nal.usda.gov/portal-data/external/<fdcId>` (the JSON behind the fdc.nal.usda.gov food pages). The API
host (`api.nal.usda.gov`, with DEMO_KEY) was not reachable from this network, so no value came from the API and none
was recalled from memory. Each row keeps the published string (`published`, by nutrient id) next to the number.

| Key | Aisle | fdcId | kcal | Protein | Carb | Fat | Fiber |
|---|---|---|---|---|---|---|---|
| chicken thigh | meat | 173627 | 121 | 19.7 | 0.00 | 4.12 | 0.0 |
| salmon | meat | 175167 | 208 | 20.4 | 0.00 | 13.4 | 0.0 |
| onion | produce | 170000 | 40 | 1.10 | 9.34 | 0.10 | 1.7 |
| carrot | produce | 170393 | 41 | 0.93 | 9.58 | 0.24 | 2.8 |
| spinach | produce | 168462 | 23 | 2.86 | 3.63 | 0.39 | 2.2 |
| tomato | produce | 170457 | 18 | 0.88 | 3.89 | 0.20 | 1.2 |
| avocado | produce | 171705 | 160 | 2.00 | 8.53 | 14.7 | 6.7 |
| broccoli | produce | 170379 | 34 | 2.82 | 6.64 | 0.37 | 2.6 |
| egg | dairy | 171287 | 143 | 12.6 | 0.72 | 9.51 | 0.0 |
| milk | dairy | 171265 | 61 | 3.15 | 4.80 | 3.25 | 0.0 |
| cheddar | dairy | 173414 | 403 | 22.9 | 3.37 | 33.3 | 0.0 |
| greek yogurt | dairy | 170903 | 73 | 9.95 | 3.94 | 1.92 | 0.0 |
| rice | pantry | 169756 | 365 | 7.13 | 80.0 | 0.66 | 1.3 |
| pasta | pantry | 169736 | 371 | 13.0 | 74.7 | 1.51 | 3.2 |
| oat | pantry | 173904 | 379 | 13.2 | 67.7 | 6.52 | 10.1 |
| lentil | pantry | 172420 | 352 | 24.6 | 63.4 | 1.06 | 10.7 |
| chickpea | cans | 173756 | 378 | 20.5 | 63.0 | 6.04 | 12.2 |
| olive oil | cans | 171413 | 884 | 0.00 | 0.00 | 100 | 0.0 |
| honey | pantry | 169640 | 304 | 0.30 | 82.4 | 0.00 | 0.2 |
| peanut butter | cans | 172470 | 598 | 22.2 | 22.3 | 51.4 | 5.0 |

Grams, per 100 g. All SR Legacy. Also read and usable for the full table: garlic 169230 (149, 6.36, 33.1, 0.50,
2.1), banana 173944 (89, 1.09, 22.8, 0.33, 2.6), potato 170026 (77, 2.05, 17.5, 0.09, 2.1), butter 173430 "without
salt" (717, 0.85, 0.06, 81.1, 0.0).

Choices Kitchen may revisit (each is a different FDC row, not a different number for the same row): "milk" is
whole milk because the alias folds every milk into one key; "rice" is the unenriched long-grain record (an enriched
one exists); "greek yogurt" is lowfat plain. Values were read through a fetch tool that summarizes the page; Core
should re-check the 20 against the FDC CSV download when it builds the bundle, and the test below catches any slip.

## 4. Rules

- **Per 100 g only.** No per-serving fields, no serving sizes, no portion weights (`foodPortions` is dropped at
  build time), no totals per recipe, per day or per shop (§2, §2.4). The bundle has no field a sum could start from.
- **Where values come from:** the FDC download (Foundation and SR Legacy CSVs), filtered to the key list by a build
  script, checked in as one generated file. The app never calls FDC at runtime.
- **Size:** about 271 rows at most (fewer after the no-match rows are dropped). A compact JSON row (key, fdcId, type
  flag, five numbers) is about 90 to 110 bytes, so **about 25 to 30 KB**, under 10 KB gzipped. Keeping the FDC
  description adds about 60 bytes a row (about 45 KB). Either is negligible in the app bundle.
- **Rounding:** store the number exactly as FDC publishes it. The side may show it rounded (kcal whole, grams to one
  decimal), but tests compare against the stored value.

### Swift Testing names for Core/Kitchen

In `TesseraCore/Tests/TesseraCoreTests/FoodTableTests.swift`, reading the bundle and this fixture:

- `@Test func everyFixtureKeyMatchesTheBundleWithinRounding()`: for each of the 20 keys, the bundled row exists and
  each of the five values equals the fixture within 0.005 (kcal within 0.5).
- `@Test func everyBundledRowHasAnFDCId()`: every row has a positive `fdcId` and a `dataType` of "Foundation" or
  "SR Legacy".
- `@Test func noRowHasPerServingFields()`: decoding each row into a dictionary finds no key containing "serving",
  "portion", "total" or "household".
- `@Test func everyBundledKeyIsAKnownIngredientKey()`: every row's key is `IngredientLine.key(for:)` of itself and is
  in `AisleGuide.guide` (no stray rows).
- `@Test func noHouseholdKeyHasARow()`: no row for the household aisle.
- `@Test func chickenThighShowsTheBundledRow()`: the §2.1 case, key "chicken thigh" reads fdcId 173627.

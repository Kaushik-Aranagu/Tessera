# Tessera reference library: candidate sources (DRAFT)

Date: 2026-10-19. Scope: bundled, read-only, offline data inside a closed-source app.

## Research limits (read first)
The sandbox could only fetch github.com pages. fdc.nal.usda.gov, openfoodfacts.org, canada.ca, wger.de and
openfoodfacts.github.io all failed DNS (getaddrinfo ENOTFOUND). Licence text below is therefore quoted only where
it came from a fetched GitHub page; everything from search excerpts is labelled "search excerpt" and is NOT a
primary confirmation. Per the rule, anything not confirmed from the source's own page is UNVERIFIED and SKIP until
re-checked from a networked machine. Sizes and version dates were not retrievable and are marked "not checked".

## Verdict rule
BUNDLE only for public domain/CC0, CC-BY (attribution), Unlicense/MIT-style. SKIP share-alike (CC-BY-SA, ODbL),
GPL/AGPL, non-commercial, unclear or unverified.

## 1. Nutrition

### USDA FoodData Central (FDC) - Foundation Foods, SR Legacy, FNDDS, Branded
- Publisher: USDA Agricultural Research Service. URL: https://fdc.nal.usda.gov/ (downloads: /download-datasets/)
- Contents: per-100 g nutrient values (about 150+ nutrients keyed by nutrient id), food descriptions, food
  categories, portion tables (food_portion: gram_weight, amount, modifier, e.g. "1 cup", "1 medium") which give
  household measures and implicit densities. Foundation = few hundred richly analysed foods; SR Legacy = about
  7,800 generic foods (frozen since 2018 release per a secondary blog, unconfirmed); FNDDS = survey foods with
  portions and recipes; Branded = several hundred thousand label products.
- Size / version: not checked (fetch blocked). Check CSV zips on the download page.
- Licence check (Core, Oct 19, read on a networked Mac; plain reading, not legal advice): page https://fdc.nal.usda.gov/ says
  "USDA FoodData Central data are in the public domain and they are not copyrighted." Licence CC0 1.0. Citing FDC is a
  request, not a condition. Also read as primary in `docs/research/food-table-usda.md` (Oct 16).
- Verdict: BUNDLE for Foundation, SR Legacy, FNDDS (confirmed from the publisher's page, relayed by Core; Research
  did not read it itself). Branded: licence-eligible but likely too large and noisy; consider a trimmed top-N subset later.

### Open Food Facts
- Publisher: Open Food Facts association. URL: https://world.openfoodfacts.org/terms-of-use
- Contents: crowd-sourced packaged products, barcodes, nutrition per 100 g, Nutri-Score, ingredients, images.
- Licence (search excerpt of OFF support/docs, not primary): database under the Open Database License (ODbL),
  contents under the Database Contents License (DbCL), images under CC-BY-SA. Conditions stated: attribution and
  share-alike; combined databases must be released as open data.
- Verdict: SKIP. ODbL and CC-BY-SA are share-alike. (Live lookup by barcode over the network is a different
  question and out of scope for the bundled library.)

### Canadian Nutrient File (CNF) 2015
- Publisher: Health Canada. URL: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/nutrient-data/canadian-nutrient-file-2015-download-files.html
- Contents: CSV/Excel/Access: foods, nutrient amounts, measures/conversion factors, food groups.
- Licence: UNVERIFIED for the 2015 files. Core read the official page (Oct 19): it names no licence, only "Refer to Crown
  Copyright for more information." A different open.canada.ca dataset, the 2008 "Nutrient Value of Some Common Foods",
  states "Licence: Open Government Licence - Canada" (commercial use allowed, no share-alike; requires the line
  "Contains information licensed under the Open Government Licence - Canada."). That is not the 2015 file set.
  An archived guideline page reportedly forbids modifying nutrient values. Health Canada notes a CNF 2026 is being prepared.
- Verdict: pending, SKIP until the Crown Copyright terms for CNF 2015 are read; expected OK only if OGL-Canada is confirmed for that set.

### Other nutrition candidates (not researched this pass)
- UK CoFID (OGL v3), Australian AFCD (check licence), NCCDB (non-commercial, SKIP), EFSA/FAO INFOODS tables
  (per-source licences). All UNVERIFIED, SKIP until checked.

### Household portions and densities
Best source is the FDC food_portion table (gram_weight per measure), covered by the FDC verdict above.

## 2. Training / exercises

### free-exercise-db (yuhonas)
- URL: https://github.com/yuhonas/free-exercise-db
- Contents: "over 800 exercises" (README "800+"), JSON with fields id, name, force, level, mechanic, equipment,
  primaryMuscles, secondaryMuscles, instructions, category, images. README notes force, mechanic, equipment may be null.
- Licence (fetched from repo page): "License: Unlicense" (https://unlicense.org). Public-domain dedication.
- Size / version: not checked. Images are in the repo; check image provenance before bundling photos.
- Verdict: BUNDLE (data). Images: BUNDLE only after confirming they are covered by the same Unlicense.

### wger exercise database
- URL: https://github.com/wger-project/wger
- Fetched: "Application Code: AGPL-3.0-or-later"; "Exercise/Ingredient Data: Creative Commons (see individual entries)."
- Search excerpt: older releases cite CC-BY-SA 3.0 for initial data.
- Verdict: SKIP. Code is AGPL; data licence is per entry, with share-alike variants likely.

### ExerciseDB (ExerciseDB/exercisedb-api)
- URL: https://github.com/ExerciseDB/exercisedb-api
- Fetched: "AGPL-3.0 license"; "11,000+ structured exercises"; 5,000+ GIFs; terms of use linked, text not seen.
  Search excerpt hints media is credited to a third party with its own licence.
- Verdict: SKIP (AGPL, media terms unclear).

### Liftosaur
- AGPL. Verdict: SKIP (per brief).

## 3. Groceries
One source read this pass (FoodKeeper, via its data.gov record); the rest are candidates to check, UNVERIFIED/SKIP for now:
- Shelf life/storage: USDA FoodKeeper (USDA/FSIS). Core read https://catalog.data.gov/dataset/fsis-foodkeeper-data (Oct 19): the page has no licence sentence; its License field links https://creativecommons.org/publicdomain/zero/1.0/ (CC0 1.0). Verdict: pending, SKIP until FSIS's own page is read; expected BUNDLE then (CC0 per the data.gov record, relayed by Core).
- Units/conversions: FDC food_portion plus a hand-written SI/US table (our own, no licence issue).
- Categories/aisles: derive from FDC food categories or write our own taxonomy.
- Substitutions: no clean open dataset known; likely author our own.

## 4. Other domains (one line each, UNVERIFIED)
- Sleep/steps norms: CDC/NIH/WHO public guidance (US gov works are public domain; WHO is CC BY-NC-SA, SKIP).
- Holidays: Unicode CLDR / date-nager (check licence); or compute locally. Time zones: IANA tz database (public domain).
- Units: UCUM / NIST SI tables (US gov public domain). Foundation Models can handle conversion, no data needed.

## Recommended 8 nutrition fields (per 100 g)
1. energy_kcal  2. protein_g  3. fat_total_g  4. carbohydrate_g  5. fibre_g  6. sugars_g  7. sodium_mg  8. saturated_fat_g
(Next tier micronutrients: potassium, calcium, iron, vitamin C, vitamin D.) Plus portion table: measure label + gram_weight.

## Open questions
1. Licence checks: USDA FDC is read from the publisher's page (Core, Oct 19). Still open: FoodKeeper (read FSIS's own page), CNF 2015 Crown Copyright terms, OFF terms, wger.
2. Is attribution inside the app acceptable (Settings > Sources) for CC-BY or OGL sources?
3. Bundle size budget? Foundation + SR Legacy trimmed to the 8 fields is small; Branded is not.
4. free-exercise-db: confirm provenance of the data (not only the images) before anything ships.
5. Do we want our own curated exercise list layered over the data for muscle/equipment taxonomy?

## Which feature uses which set (Research, Oct 19)
- USDA FDC Foundation, SR Legacy, FNDDS (CC0 per the publisher's page, relayed by Core; nutrition per 100 g and portions): Kitchen ingredient pages, recipe totals, pantry and groceries quantities. Fields recommended: energy kcal, protein, fat, carbohydrate, fibre, sugars, sodium, saturated fat, plus the portion table (measure and gram weight). To agree with Kitchen.
- free-exercise-db (exercises, muscles, equipment): Training exercise pages, muscle figure, swap alternatives. Images need a provenance check before anything ships.
- Grocery packs, aisles, swaps, shelf life: Groceries and Pantry. Shelf life (FoodKeeper) is pending; the other candidates are UNVERIFIED; nothing chosen yet.

## Next steps
1. Re-run every licence check from a machine that can reach fdc.nal.usda.gov and the other publishers (this sandbox could not).
2. Agree the nutrition fields with Kitchen.
3. Step 2, the spec for how the library sits on the phone: read-only objects, no runtime calls, refreshed by app updates, never mixed with his own data, privacy rules unchanged.

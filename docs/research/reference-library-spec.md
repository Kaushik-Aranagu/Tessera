# Reference library on the phone: spec (step 2)

Date: 2026-10-19. For: Core, Builder B, Kitchen, Product. Docs only: nothing was built, run, downloaded or tested.
Step 1 is `docs/research/reference-library-inventory.md` (frozen, not edited here). This file says how that library
sits on the phone. Product's requirements: read-only objects; no network calls at runtime; refreshed only by app
updates; never mixed with Kaushik's own data; privacy rules unchanged.

**Citations.** Every file:line is from this branch (master plus the inventory). `Core/` is short for
`TesseraCore/Sources/TesseraCore/` and `Tess/` for `TesseraCore/Sources/TesseraTess/`. "Not built" marks anything
that does not exist yet. Status of a claim: "master" (read in code) or "proposed" (this spec).

## 0. What master has today (the ground this stands on)

| Area | Master today | Evidence |
|---|---|---|
| One store, all in memory | One SQLite file through GRDB; the whole graph is read into memory at open (a snapshot of every table) and written back as rows change. | `CLAUDE.md:16`; `Core/Model/TesseraContext.swift:52-62, 272-276` |
| Opening runs migrations | Every open of a `TesseraContext` runs the migrator, which writes. So a read-only file cannot be opened as a context. | `Core/Model/TesseraContext.swift:61`; `Core/Model/TesseraDatabaseSchema.swift:34-81` |
| Read-only open exists | `isNewer(at:)` already opens a file with `configuration.readonly = true` through GRDB. | `Core/Model/TesseraDatabaseSchema.swift:24-31` |
| Links point at loaded models | `ObjectLink` holds `toObject` or `toClass`, live models in the same context; the row stores their ids. `setLinks` refuses a target whose class is not the field's target class. | `Core/Model/Models.swift:399-416`; `Core/Model/TesseraDatabaseSchema.swift:53-55`; `Core/Engine/ObjectStore.swift:225-244` |
| Inheritance of values | A value reads own value, else the class object's, else the default. | `Core/Engine/ObjectStore.swift:153-158`, `:259-268` |
| Packages carry source and licence | `CatalogPackage` has `id`, `version`, `source`, `license`; classes record `packageID`, `packageVersion`, `isUserModified`. | `Core/Catalog/CatalogPackage.swift:3-12`; `Core/Model/Models.swift:94-106` |
| Package id "library" is taken | The in-store exercise library (about 70 lifts "written in our own words") uses package id `library`, version 1, and class ids `stableID("library.<key>")`. | `Core/Catalog/ExerciseLibrary.swift:3`; the seeder file beside it (the one named for setting the library up), lines 22-23 and 58-63 |
| Stable ids | `SystemCatalog.stableID` hashes a name (salted "tessera:") into a UUID. | `Core/Catalog/SystemCatalog.swift:483-493` |
| Ingredients | `Ingredient` has only `aisle` and `isStaple`; found by name; created by name when new. | `Core/Catalog/SystemCatalog.swift:289-293`; `Core/Kitchen/Ingredients.swift:20-24, 29-38` |
| Exercises and muscles | `Exercise` fields include muscles, equipment, `pattern`, `aliases`; 18 muscles are objects matched by name. | `Core/Catalog/SystemCatalog.swift:83-108`; `Core/Catalog/MuscleLibrary.swift:3, 14-21` |
| Op log | Every action through `ActionEngine` writes one `OpRecord` with its ops into the store. | `Core/Actions/ActionEngine.swift:55-69`; `Core/Model/Models.swift:493-494` |
| Backups and export | The daily copy is `context.database.backup(to:)` of the store file. The JSON export walks `context.all(...)` of every table. | `Core/Export/TesseraBackup.swift:73-74, 91`; `Core/Export/TesseraExport.swift:106-110`; gap hunt 27, `docs/research/fixtures/gap-hunt-27-backups-export.md:26, 29` |
| Privacy | One private-text check; `ObjectPrivacy.label(of:)` masks notes, memories, tasks, recipes and ingredients; secret words never reach a model; walled text is held back from Claude. | `Core/Tess/ObjectPrivacy.swift:26-62, 69-88`; `Core/Notes/SecretWords.swift:3-5`; `Tess/TessModel.swift:97-116` |
| Nutrition rulings | The app never sums nutrition; the PER 100 G side shows one ingredient's values. Food-table research: five values, per 100 g only, no portions. | `docs/product/decisions.md:183`; `docs/research/food-table-usda.md:58-66, 136-139` |
| Sources page | Not built (no Sources or licence screen under `Features/Settings`). | `ls Features/Settings`: `ClaudeSection.swift`, `RestDaySentence.swift` |

## 1. Storage: where the library lives

| | A. Separate read-only SQLite file in the app bundle | B. Rows in `tessera.sqlite` as objects |
|---|---|---|
| Open | GRDB `DatabaseQueue` with `readonly = true` (URI `mode=ro`, `immutable=1`), the pattern of `TesseraDatabaseSchema.swift:27-29`. | Already open; rows load with everything else. |
| Memory | Paged in on demand: one row per page you open (vision "virtual memory", `docs/PRODUCT_VISION.md:35`). | About 8,000 foods plus 800 exercises join the whole-graph snapshot at every launch (`TesseraContext.swift:272-276`). |
| Daily copy, iCloud copy, Save a copy | Not in them: the copy is a backup of the store file only (`TesseraBackup.swift:91`). Nothing to filter. | Every copy grows by megabytes of public facts; the iCloud writer and the private filter must learn to skip them. |
| Restore | Nothing to restore: the bundle on the phone is the truth. An older copy simply links to ids this bundle knows or retired (section 2.4). | A restored older copy brings back older library rows, which then fight the newer bundle's rows. |
| Export | Not in it: the export walks the context (`TesseraExport.swift:107-110`). | Every export carries the library, and a masked export must judge thousands of public titles. |
| Op log | Never touches it: reads do not go through `ActionEngine`. | Seeding writes rows; if it goes through actions it floods the log, if not it is a second write path. |
| Updates | Replace the file: a new app build carries a new file. Atomic, no migration of his data. | A seeder pass per version, diffing thousands of rows under his edits, like the catalog refresh (`SystemCatalog.swift:394-421`) but large. |
| Never mixed | Physically apart: different file, different read API, no write path. | Same tables; kept apart only by a flag every query must remember. |
| Cost | A second reader, a link kind that can point outside the context (section 2.2), a merge in search. | None up front. |

**Recommended: A.** Reason: every Product requirement holds by construction instead of by a filter. Backups,
restore, export and the op log already copy or walk only the store, so the library is out of all four with zero new
exclusion code; updates are a file swap; memory stays flat. The cost (a cross-file link and a search merge) is small
and is the same cost any later dataset pays.

Rules for A (proposed):
- The file ships at `Resources/Reference/tessera-reference.sqlite` in the app bundle (the `Resources` folder is
  already a resources build phase, `project.yml:53-54`). It is never copied to Application Support or Documents, so
  it is in no device backup and not visible in Files.
- Core opens it once, lazily, through a new `ReferenceLibrary` type in `Core/Reference/` (not built). It is the only
  reader. No `TesseraContext` is made from it (a context migrates on open, `TesseraContext.swift:61`).
- Open flags: read-only plus immutable; no WAL, no journal. A write attempt throws. If the file is missing or fails
  its checksum, the library reads as empty and the app works (Kitchen and Training already run without it today).

## 2. Library items as linkable objects

### 2.1 Shape inside the bundle
- Tables (proposed): `dataset` (one row per dataset, section 6), `refClass`, `refItem`, `refField`, `refValue`,
  `refLink`, `portion`, `retired`, `searchIndex` (FTS5 over title and aliases).
- `refItem` columns: `refID` (text, primary key), `classKey`, `title`, `aliases`, `datasetID`, `sourceID`,
  `sinceVersion`. Values are typed columns per class where the field set is fixed (nutrition), or `refValue` rows
  keyed by field key otherwise.
- Classes (proposed names, all under a root `Reference`, never in the store's `classDef` table): `Reference Food`,
  `Reference Exercise`, `Reference Muscle`, `Reference Equipment`, later `Grocery Pack`, `Aisle Hint`, `Swap`.
  On a page they read as their plain noun ("Food", "Exercise") with the library mark (2.3).

### 2.2 Stable ids
- `refID` = `<dataset>:<source id>`, e.g. `fdc:173627` (the FDC record id), `fedb:<free-exercise-db id>`. Readable,
  survives rebuilds, and the same on every phone. Where a UUID is needed (a list cell id), use
  `SystemCatalog.stableID("ref.<refID>")` (`SystemCatalog.swift:483-493`), which is deterministic.
- Package ids use the prefix `ref.` (`ref.fdc`, `ref.fedb`). They must never be `library`: that id already names the
  in-store exercise library (seeder file `ExerciseLibraryInstaller.swift`, beside `ExerciseLibrary.swift`, line 22).

### 2.3 The source flag
- In the app a library item is a value type `ReferenceItem` (not built) with `source == .library`, never an
  `ObjectRecord`. His objects are `ObjectRecord`s with `source == .mine` (derived, not stored). Every object page,
  row and search hit reads the flag; a library page shows a quiet "Library" mark and its dataset line, and has no
  edit controls (editing means 3, copy-on-edit).
- Read API: `ReferenceLibrary.item(_ refID)`, `search(_ text, classKey:)`, `items(classKey:)`, `portions(of:)`,
  `datasets()`. All synchronous reads on a background queue, results handed to the main actor.

### 2.4 How his object links to a library item without copying it
- New field kind `libraryRef` (proposed). Its value lives in his object's `values` JSON as `{ "ref": "fdc:173627",
  "title": "Chicken, thigh, raw", "seenVersion": 3 }`. It is not an `ObjectLink` row, because `ObjectLink` needs a
  live target in the same context (`Models.swift:399-416`). The title is a display snapshot only; facts are never
  copied.
- First uses: `Ingredient.food` (libraryRef to a `Reference Food`); `Exercise.reference` on a library exercise's
  class object (libraryRef to a `Reference Exercise`), next to the existing `pattern` and `aliases`
  (`SystemCatalog.swift:99-107`). Muscles stay his 18 objects; the bundle carries a muscle map from the
  dataset's names to his 18 keys (`MuscleLibrary.swift:14-21`), built by the builder, not linked per item.
- Reads: `ObjectStore.value(key, of:)` for a field the object does not own falls through to the linked library item,
  after his own value and before the class default (extends `ObjectStore.swift:153-158`). So an ingredient with no
  own kcal shows the library's.
- Backlinks: "used in 3 recipes" on a library page is a lookup in an in-memory index (refID to his object ids),
  built at launch from his `libraryRef` values and kept current on write. The bundle never stores his ids.
- Setting the link is an ordinary action on his object (one op, his data). Choosing a match is suggested by name
  (`Ingredients.swift:20-24` key match) and confirmed by him; never auto-linked silently.

### 2.5 When a library item changes or goes away in an app update
- Changed values: his object shows the new values on next open. Nothing is written to his store, no op, no note
  (his data did not change). `seenVersion` is not bumped by reading.
- Changed title: the page shows the bundle's title; the snapshot is refreshed the next time he edits that object.
- Retired item: the builder must keep every refID ever shipped either live or in `retired` (`refID`, `replacedBy`
  or null, `retiredInVersion`). A replaced id resolves to its replacement silently. A dropped id shows his snapshot
  title with one quiet line, "No longer in the library.", and no numbers. His object and link stay untouched.
- Unknown id (a copy restored from a newer build's phone): same as dropped, line "Not in this version's library."
- His own copied values (section 3) are never touched by an update.

## 3. User-edited copies (copy-on-edit)

- A library item is never edited. A tap on edit for a library value (or on a value his object inherits from one)
  copies into his data first, then edits the copy.
- Proposed default (CALL 2): copy the whole item's facts into his object's own fields in one action
  (`copyFromLibrary`, one op), then apply his edit as a second op. From then his object reads its own values only;
  library updates no longer reach those fields.
- Provenance on his object: `copiedFrom` (refID), `copiedVersion` (dataset version), `copiedAt` (date). Shown as one
  line on his page: "From USDA FoodData Central, Dec 2025. Edited by you." The `libraryRef` link stays, so "Compare
  with library" and "Go back to library values" (clears his own fields, one op, UNDO as usual) are possible.
- A copy is fully his: it rides in every backup and export, follows every privacy rule of its class
  (`ObjectPrivacy.swift:56-60` masks an ingredient by the one title check), and is in the op log.
- Exercises: the in-store library classes are already his objects with `isUserModified` (`Models.swift:103-106`);
  facts copied from a `Reference Exercise` (instructions, muscle roles) land on the class object the same way.

## 4. Nutrition field set (to agree with Kitchen)

Per 100 g of the food as described by the source record. Stored exactly as published; rounding is the screen's
(`food-table-usda.md:143-144`). Nutrient ids are FDC's.

| Field key | FDC nutrient id | Unit | In food-table research |
|---|---|---|---|
| `energyKcal` | 1008 | kcal | yes |
| `protein` | 1003 | g | yes |
| `fat` | 1004 (total lipid) | g | yes |
| `carbohydrate` | 1005 (by difference) | g | yes |
| `fiber` | 1079 (total dietary) | g | yes |
| `sugars` | 2000 (total sugars) | g | new, to agree |
| `sodium` | 1093 | mg | new, to agree |
| `saturatedFat` | 1258 | g | new, to agree |

Plus per row: `fdcID`, `dataType` (Foundation or SR Legacy), the FDC description as published.

Portions (subject to CALL 1): table `portion` with `refID`, `label` (the FDC measure and modifier, "1 cup, chopped"),
`amount`, `gramWeight` (g), `sortIndex`. Used only to turn "1 cup" on a recipe line into grams for the PER 100 G
side; never multiplied into a total. Units: mass in g and mg as above; energy kcal only (no kJ in v1); no per-serving
values anywhere. Missing nutrient = no value (null), never 0. **Agreed with Kitchen (Oct 19):** the 8 fields, units and FDC ids; null never 0; per 100 g stored as published; the stored key is `fiber_g` in the research tables and fixtures (`food-table-usda.md`, `fixtures/food-table-20.json`) and `fiber` in the app's field list above (US spelling; the earlier `fibre_g` is renamed everywhere in this PR). Portions ship as ruled in CALL 1 B.
Portion choice: when a food has several portions, pick the one whose label matches the recipe line's unit; if none matches, show no grams. Never guess.

## 5. Exclusions (what the library is never part of)

1. **Op log.** Reading, searching or showing a library item writes no op. Only actions on his objects do
   (`ActionEngine.swift:55-69`).
2. **Backups.** Daily iPhone copy, iCloud folder copy, Save a copy: none holds library rows, because they copy only
   the store file (`TesseraBackup.swift:91`). His `libraryRef` values and copies ride as his data.
3. **Shared export.** The JSON export walks the store only (`TesseraExport.swift:107-110`) and so has no library
   rows; a reader rebuilds facts from the bundle by refID. The export's `libraryRef` values carry refID and title.
4. **Claude.** Library facts are never packed as "his data" in anything sent to Claude. A Claude job that needs a
   public fact names it as reference context with its source line, or does not send it. His private objects keep
   every wall (`TessModel.swift:104-116`); a library lookup never lifts one.
5. **Tess and search stay on the phone.** "How much protein in lentils" is answered from the bundle by the grammar or
   the on-device model; it never routes to Claude for the fact. Search is a local FTS query. Secret-word and
   key-shaped text is refused before any lookup, as today (`TessModel.swift:97-100`, `SecretWords.swift:3-5`).
6. **Widgets and the Live Activity.** They read only through the normal masked path: the app builds their state with
   `ObjectPrivacy` labels (`ObjectPrivacy.swift:20-24`; `Shared/RestActivityAttributes.swift:10-22`). A widget never
   opens the reference file itself and never shows a library value of a masked object of his.
7. **Spotlight and Shortcuts.** Library items are not donated to Spotlight (they are not his). App Intents may answer
   a library lookup on the phone through the same read API.
8. **Mixing.** No code path writes a library row into the store or a store row into the bundle. His search results
   and library results are separate groups (CALL 5).

Privacy rules are unchanged: masking keys off his object (`ObjectPrivacy.label(of:)`, `ObjectPrivacy.swift:26-62`).
A library item is public and has no private state; a link from his private recipe to a library food is masked with
the recipe, and the library page's "used in" count shows "Private recipe" for it, never its title.

## 6. Licence and attribution

- Only datasets marked BUNDLE in the inventory (`reference-library-inventory.md:12-15`) can ship, and only after the
  licence is confirmed from the publisher's own page (the inventory's UNVERIFIED label blocks it, `:5-11`). Today that
  means: USDA FDC Foundation and SR Legacy (CC0, confirmed from the publisher page by Core on Oct 19, and in `food-table-usda.md:10-16`), free-exercise-db data once its data provenance is checked
  (Unlicense, `reference-library-inventory.md:63-69`). USDA FoodKeeper is pending (CC0 per its data.gov record; FSIS's own page still to be read). Everything SKIP, pending or UNVERIFIED is refused by the builder.
- Each dataset row in the bundle records: `datasetID`, `name`, `publisher`, `sourceURL`, `licence` (SPDX-style id,
  e.g. CC0-1.0, Unlicense), `licenceCheckedOn`, `sourceVersion` (the publisher's release, e.g. FDC Dec 2025),
  `downloadSHA256`, `rowCount`, `attributionLine`.
- In-app **Sources** page (Builder B, not built): under Settings, one row per dataset with name, publisher,
  licence, version and row count; the attribution line verbatim (for FDC, the line in `food-table-usda.md:33-35`).
  No publisher name, seal or logo is used as an endorsement. Each library page's dataset line links to its row.
- Images: none ship (free-exercise-db image provenance is undocumented, `docs/research/exercise-catalog.md:10, 18`).

## 7. Size budget and build pipeline

Budget (proposed, uncompressed file in the bundle): **8 MB total**, checked by a test.
- Nutrition: FDC Foundation plus SR Legacy, about 8,000 rows x (8 numbers + description) plus portions plus FTS:
  estimate 3 to 4 MB. Cap 4.5 MB. FNDDS and Branded are out of v1 (CALL 3).
- Exercises: free-exercise-db, about 800 rows with text: estimate 1 MB. Cap 1.5 MB.
- Groceries (packs, aisles, swaps): nothing chosen; cap 0.5 MB. Headroom 1.5 MB.

Builder (Builder B with Core; proposed `scripts/reference/build_library.py`):
1. Inputs are downloaded by hand on a networked Mac into a gitignored folder outside the build
   (`tools/reference-sources/<datasetID>/`). The app build never downloads anything; nothing at runtime does.
2. A checked-in manifest `scripts/reference/sources.json` lists each dataset: id, verdict (BUNDLE, SKIP,
   UNVERIFIED), licence fields of section 6, expected `downloadSHA256`. The script refuses to run if a download's hash
   differs or a verdict is not BUNDLE with a `licenceCheckedOn` date.
3. Deterministic output: rows sorted by refID, fixed page size, no build timestamps (the version comes from the
   manifest), `VACUUM` at the end. Two runs on the same inputs give byte-identical files.
4. Outputs: `Resources/Reference/tessera-reference.sqlite` and `tessera-reference.sha256`, both committed (like the
   food table's "one generated file", `food-table-usda.md:138-139`). The app checks the hash at first open.
5. The script also writes the `retired` table by diffing against the previous committed file, and fails if any old
   refID would vanish from both live and retired.
6. Run with `python3 -I`, reading downloads by path only (the downloads are untrusted data).

## 8. Testable rules

Owners: **Core** (engine, `ReferenceLibrary`, field kind, tests in `TesseraCore/Tests`), **Builder B** (builder
script, Sources page, library pages), **Kitchen** (nutrition fields, ingredient linking, PER 100 G side).

| # | Rule | Proposed test | Owner |
|---|---|---|---|
| R1 | The reference file opens read-only; any write throws. | `referenceFileOpensReadOnlyAndRefusesWrites` | Core |
| R2 | No `TesseraContext` is ever created from the reference file. | `referenceFileIsNeverOpenedAsAContext` | Core |
| R3 | Opening, searching and reading library items adds no `OpRecord`. | `libraryReadsWriteNoOps` | Core |
| R4 | A daily copy, iCloud copy and Save a copy contain no reference tables or refItem rows. | `backupCopiesHoldNoLibraryRows` | Core |
| R5 | The JSON export holds no library rows; a `libraryRef` exports as refID and title only. | `exportCarriesRefIDsNotLibraryFacts` | Core |
| R6 | Restoring an older copy leaves the bundle untouched and its links resolve. | `restoreLeavesTheLibraryUntouched` | Core |
| R7 | No library id equals or starts with package id `library`; all start with `ref.`. | `referencePackagesNeverUseTheLibraryID` | Core |
| R8 | Every refID is `<dataset>:<sourceID>` and identical across two builds. | `refIDsAreStableAcrossBuilds` | Builder B |
| R9 | A `libraryRef` read falls through: own value, then library value, then class default. | `libraryValueFillsOnlyMissingOwnValues` | Core |
| R10 | Linking an ingredient to a food is one op on his object and copies no nutrient values. | `linkingAFoodCopiesNoFacts` | Kitchen |
| R11 | A first edit of a library value runs `copyFromLibrary` then the edit, with provenance set. | `firstEditCopiesWithProvenance` | Core |
| R12 | "Go back to library values" clears his own fields in one op and can be undone. | `backToLibraryValuesIsOneUndoableOp` | Core |
| R13 | A library update never changes a copied object's own values. | `libraryUpdateLeavesCopiesAlone` | Core |
| R14 | A retired id with `replacedBy` resolves to the new item; a dropped id shows the snapshot title and "No longer in the library." | `retiredRefIDsResolveOrSayGone` | Core |
| R15 | Every refID in the previous file is live or retired in the new one. | `noRefIDVanishesBetweenVersions` | Builder B |
| R16 | Each food row has the 8 fields of section 4 in their units; a missing nutrient is null, never 0. | `foodRowsHaveTheAgreedFieldsAndUnits` | Kitchen |
| R17 | No row or portion carries a per-serving or total field (`decisions.md:183`). | `noFoodRowHasPerServingOrTotalFields` | Kitchen |
| R17b | No code multiplies a portion's `gramWeight` by a nutrient value, and the PER 100 G side shows only the per-100 g figures plus the gram conversion of the line (intake is a walled body fact, `decisions.md:183`). | `noCodeMultipliesPortionGramsByNutrients` | Kitchen |
| R17c | A food with several portions uses the one whose label matches the recipe line's unit; with no match it shows no grams. | `portionPickedByUnitMatchElseNoGrams` | Kitchen |
| R18 | The 20 fixture keys match the bundle (`docs/research/fixtures/food-table-20.json`). | `foodFixtureKeysMatchTheBundle` | Kitchen |
| R19 | Every dataset row has licence, version, source URL, checked date and attribution line. | `everyDatasetRecordsLicenceAndVersion` | Builder B |
| R20 | The builder refuses a dataset whose verdict is not BUNDLE or whose download hash differs. | `builderRefusesUnverifiedOrChangedSources` | Builder B |
| R21 | Two builder runs on the same inputs give byte-identical files and the committed checksum. | `builderOutputIsDeterministic` | Builder B |
| R22 | The reference file is at most 8 MB and each dataset within its cap. | `referenceFileFitsTheSizeBudget` | Builder B |
| R23 | The Sources page lists every bundled dataset with its attribution line verbatim. | `sourcesPageListsEveryDataset` | Builder B |
| R24 | A missing or bad-checksum file reads as an empty library; Kitchen and Training still open. | `missingLibraryReadsEmptyAndAppRuns` | Core |
| R25 | Ruled by Product (Oct 19): an unreadable phrase follows the capture-miss route (it goes whole to Claude; only the key and key-shaped text never leave); secret words are refused first. Grammar-read library lookups staying on the phone are a later Core option. | `libraryLookupsStayOnThePhone` | Core |
| R26 | Nothing sent to Claude includes library rows labelled as his data. | `claudePayloadNeverPacksLibraryAsHis` | Core |
| R27 | A widget or Live Activity state never holds a library value for a masked object of his. | `widgetStateNeverShowsLibraryValuesOfMasked` | Core |
| R28 | A library page's "used in" list shows a private recipe as "Private recipe". | `libraryBacklinksMaskPrivateObjects` | Kitchen |
| R29 | Library items are never donated to Spotlight. | `libraryItemsAreNotIndexedInSpotlight` | Builder B |
| R30 | No image file is in the reference bundle. | `referenceBundleHoldsNoImages` | Builder B |
| R31 | A private ingredient shows no library title and gets no name-match suggestion; the `libraryRef` title snapshot masks with the ingredient (`ObjectPrivacy.isPrivateTitle` on the ingredient name). | `privateIngredientShowsNoLibraryTitleOrSuggestion` | Kitchen |
| R32 | Pantry and Groceries show no library facts on a masked item. | `maskedPantryAndGroceryItemsShowNoLibraryFacts` | Builder B |

## 9. PRODUCT CALLS

Each call: the question, options with their consequence, a recommendation and its reason, and an owner.

### CALL 1 (R16, R17): Do portion weights ship?

| Option | Consequence |
|---|---|
| A. No portions; per 100 g only, as `food-table-usda.md:136-137` says | Smallest; "1 cup flour" on a recipe line cannot reach the PER 100 G side. |
| B. Portions ship as a gram conversion only (measure to grams), never multiplied into a total | "1 cup" becomes grams on the side; about 1 MB more; must still honour `decisions.md:183` (no sums). |
| C. Portions plus per-portion nutrition | Easiest for a reader; it is a per-serving figure, against ruling 183. |

Recommended: B. Reason: the inventory and Product asked for portions, and a conversion to grams is not a sum; rule
R17 keeps every total out. Owner: Kitchen, Core.

### CALL 2 (R11, R13): How much copies on the first edit?

| Option | Consequence |
|---|---|
| A. The whole item's facts copy into his object | His copy is consistent and frozen; later library fixes do not reach it (shown by "Compare with library"). |
| B. Only the edited field copies; the rest keeps reading the library | Less data; his object can mix a corrected library value with his own number from an older version. |

Recommended: A. Reason: one consistent record with one provenance line is easier to trust and to test. Owner: Core.

### CALL 3 (R22): Which FDC data types ship in v1?

| Option | Consequence |
|---|---|
| A. Foundation plus SR Legacy | About 8,000 generic foods, within the 8 MB budget. |
| B. A plus FNDDS (survey foods) | More cooked and mixed dishes; several MB more; overlaps with recipes he writes. |
| C. A plus a trimmed Branded subset | Packaged products; large and noisy, needs a choice rule. |

Recommended: A. Reason: it covers ingredients, which is what Kitchen links; the others can come in a later build
without any change to his data. Owner: Kitchen, Builder B.

### CALL 4 (R30): What ships from free-exercise-db?

| Option | Consequence |
|---|---|
| A. Names, aliases, muscles, equipment, force, mechanic, level, and instruction text; no images | Full exercise pages; the instruction text's origin is undocumented (`exercise-catalog.md:10`). |
| B. Vocabularies and muscle maps only, as a cross-check for our own library | Our pages keep our own words (`exercise-catalog.md:18`); fewer exercises searchable. |

Recommended: A for this private app, images never. Reason: the data is Unlicense and BUNDLE in the inventory; the
risk noted in `exercise-catalog.md:10` is for a future public app, which would revisit this call. Owner: Builder B.

### CALL 5 (R25, R29): Where library results show in search and the Ask bar

| Option | Consequence |
|---|---|
| A. A separate "Library" group below his results | Never mixed; his things come first; one more group to design. |
| B. Mixed in one list with a library mark | Faster to scan; his objects and public facts share one ranking. |
| C. Library only behind an explicit scope | Cleanest; he must know to switch scope. |

Recommended: A. Reason: it meets "never mixed" on screen as well as on disk, and keeps his own objects first.
Owner: Builder B, Design.

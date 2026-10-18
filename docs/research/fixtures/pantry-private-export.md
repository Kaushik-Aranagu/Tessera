# Pantry private flag and shared export fixtures (G198, G196/R18)

For: Core (engine, privacy, export), Builder B (Pantry, Groceries, Recipes screens), QA, Product (questions at the end). Docs only; nothing was built or run (no Swift toolchain). Written Sun Oct 18 PDT from REFILL item 9 (research.md, 9:15 PM PT Oct 17), the decisions entry "8:39 PM PT Oct 17 (Product, recording Core's G198 and G196/R18 on core/pantry-1 at 1c12b728, 949 package tests pass, no PR yet)" (decisions.md line 1005), the 6:10 pm and 6:44 pm PDT Oct 17 rulings it cites (sticky mask G139, per-cook undo), and origin/master at `bed4ea3b` (read in the worktree). Per the CLOCK CORRECTION (decisions.md line 937) stamps from 1:41 PM onward ran 1 to 2 hours ahead of Pacific time; the 8:39 PM entry is cited by its stamp.

**Where the code is.** Everything this file grades is a build target. `core/pantry-1` (1c12b728) holds the flag and the export filter but is not a PR and not on master; master has no `pantryPrivate`, no pantry field, no `pantryBackfill` op. Rows therefore read **gap** on master unless the line they rest on exists today. Pieces that exist only on unmerged PRs are named per row:

| PR | What it carries that these rows touch | State on Oct 18 |
|---|---|---|
| #890 (core/g105) | `ObjectPrivacy.isPrivateTitle`, the one private-text check; the export delegates to it. Decides WHICH cooks and ingredients are private, so it decides what sets the flag. | open, not merged |
| #917 (ios/pantry-no-ochre) | deletes `PantryColour`; state words in ink. Touches the Pantry line only, not the mask. | open, not merged |
| #884 (core/miss-lows) | `PrivateFacts.isMoneyShaped` and `isBodyShaped`, "Eleven stone four" walled. Widens what a private recipe title is, so which cooks set the flag. | open, not merged |
| core/pantry-1 | the flag, the export filter, the backfill | branch only, no PR |

Status words as in `pantry-v2.md`: **traced** means I read the master line and it does what the row says; **inferred** means the row follows from a ruling or from code I did not read in full; **gap** means master has nothing for it or contradicts it. Owners: **Core** (engine, privacy, export), **Builder B** (Pantry, Groceries, Recipes screens), **QA**, **Product**. All names and dates are made up. No key-shaped value appears; where a secret tail is needed the row says "a Claude-key-shaped tail" and the test builds it at run time.

## 0. What the rows rest on

| Fact | Evidence |
|---|---|
| Ingredient has only `aisle` and `isStaple`; the catalog is version 9. The pantry fields, `pantryPrivate` included, ride the bump after #407's v10. A test must not hard-code the number. | `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:280-284`, `:350`; decisions.md:957, :1005 |
| Today the Pantry mask is computed live from titles: a cook line is walled when the RECIPE title is private, and the line label is walled when the INGREDIENT title is private. A cook of a deleted recipe is skipped, so deleting the recipe unmasks its ingredients. | `Features/Kitchen/PantryLedger.swift:97-100`, `:151`, `:163-168` |
| The mask already flows into the export for ingredients used only by private recipes or items (G37), but by object label, not by a stored flag. | `TesseraCore/Sources/TesseraCore/Export/PrivateWords.swift:141`, `:193-196`, `:205-207` |
| `FinishCooking` writes `cookedAt`, ends the process, stops timers and closes the plan task. It writes nothing on ingredients, so no op carries a pantry field or a flag yet. | `TesseraCore/Sources/TesseraCore/Kitchen/Cooking.swift:287-303` |
| UNDO replays the record's ops reversed and inverted with `guarded: true`, so each `setValue` reverts only if the current value still equals the op's "after". That is the mechanism "UNDO clears only what the cook set" rests on; there is no per-field ownership counter. | `TesseraCore/Sources/TesseraCore/Actions/ActionEngine.swift:143-149`, `:244-262` |
| The shared export is `TesseraExport(context:maskingPrivate:)` with `maskingPrivate` defaulting to true. It copies every object value whole, copies every op whole, THEN masks only objects and ops tied to private labels. There is no field filter and no op filter by field. | `Export/TesseraExport.swift:105`, `:129-136`, `:141-145`, `:146-149`, `:153-185` |
| The full backup is the unmasked path (`maskingPrivate: false`); `restore(into:merging:)` writes back whatever objects and ops the file holds. | `Export/TesseraExport.swift:105`, `:208`, `:255-298`; `TesseraBackup.swift` |
| The backfill is `.system` (an `Actor` case); `undoLatest` with no actor named skips `.system` records. | `TesseraCore/Sources/TesseraCore/Actions/Op.swift:12`; `ActionEngine.swift:161-173` |

Cross-references (not repeated here). `pantry-v2.md`: PB04 to PB11 (backfill), PB16 and PP16 and PR18 (the original, narrower export row), PP01 to PP17 (the Private item line, which this flag feeds), PD14 (a private cook writes state and says nothing), PE18 (rename keeps state). `docs/product/kitchen-pantry-v2-acceptance-pe.md`: PE25 to PE29 grade this same ruling as acceptance rows; this file adds the engine-level cases PE25 to PE29 do not split out. `decisions-328-332-338.md` (the G105 one-function ruling) and `private-title-sweep` style rows for G105 and private titles: this file only asks which titles set the flag and defers to those rows for what a private title IS. Rows below say "see" instead of copying.

Row-id prefixes: **PF** the stored flag (G198), **PX** the shared export (G196/R18), **PM** import and restore, **PU** UNDO and ops, **PQ** cross-checks with other private rules.

Columns: id | input | expected | master today (file:line) | status | owner | Swift Testing name.

## 1. The stored flag (G198)

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| PF01 | Finish a cook of a private recipe (title walled, e.g. a made-up "Dentist cake") whose lines are limes (Produce) and ground beef | each ingredient the cook used gets `pantryPrivate = true` in the SAME op as its state; Pantry reads `Private item`; Tess says nothing | no flag, no write: `Cooking.swift:287-303`; mask is live: `PantryLedger.swift:97-100` | gap | Core | `aPrivateCookSetsPantryPrivate` (acceptance name PE27) |
| PF02 | Finish a cook of a plain recipe ("Weeknight dal") | `pantryPrivate` stays unset on its ingredients (nil, not false written); no extra field in the op | no flag | gap | Core | `aPlainCookLeavesPantryPrivateUnset` |
| PF03 | Rename the masked ingredient (Limes to Lime wedges), then open Pantry | flag stays; line reads `Private item`; the new name appears nowhere on Pantry | rename is `setTitle` on the object (`TesseraExport.swift:157-158` shows the op); flag does not exist | gap | Core | `renamingAMaskedIngredientKeepsTheMask` (PE28) |
| PF04 | Rename a masked ingredient to a plain word and back | flag unchanged both times; the title is never used to re-derive it | live derivation reads the title: `PantryLedger.swift:163-168` | gap | Core | `theFlagIsNeverRederivedFromTheTitle` |
| PF05 | Delete the private recipe after its cook | flag stays, sticky (G139): deleting a recipe never unmasks a flagged ingredient; ingredients still read `Private item` (G184 closed one layer down) | today the cook is skipped and the mask goes: `PantryLedger.swift:151` | gap | Core | `deletingAPrivateRecipeKeepsTheMask` |
| PF06 | Edit the private recipe's title to a plain word after the cook | flag stays (sticky, G139); the cook is not re-judged | live derivation: `PantryLedger.swift:97-100` | gap | Core | `retitlingThePrivateRecipeKeepsTheMask` |
| PF07 | Backfill on a store whose history has a private cook (first launch of the build that has the flag) | backfill sets `pantryPrivate` on that cook's ingredients, as PF01; first Pantry open lists no name | no backfill, no flag | gap | Core | `theBackfillMasksIngredientsOfAPrivateCook` |
| PF08 | Backfill after the recipe of that cook was already deleted | the cook is masked by the ingredient's own title only (the one check); no blanket masking | `PantryLedger.swift:151` | gap | Core | `theBackfillOfADeletedRecipeMasksByIngredientTitleOnly` |
| PF09 | After the backfill finishes | the ledger derivation is deleted; nothing reads cook history or recipe titles to decide the mask any more | derivation is live today | gap | Core | `thePantryMaskReadsOnlyTheStoredFlag` |
| PF10 | A cook that touches an ingredient already `pantryPrivate` from an earlier private cook, now a plain cook | flag stays set (a plain cook never clears it) | no flag | gap | Core | `aPlainCookNeverClearsThePantryPrivateFlag` |
| PF11 | An ingredient whose own title is private ("Advil") but no private cook touched it | masks by title as before (PP01, PP15); no flag is needed or written | `PantryLedger.swift:166` | traced (read); flag only for cook-derived privacy | Core | `aMedicineIngredientMasksWithoutTheFlag` |
| PF12 | Which cooks are private, once #890 and #884 land | the same single check (`ObjectPrivacy.isPrivateTitle` plus the PrivateFacts shapes) decides; "Dentist cake" and "Eleven stone four stew" both set the flag; "blood orange" and "Rent car" do not (see decisions-328-332-338.md and the title-trim rows, not copied) | master check is `isPrivateRecipeTitle` at `PantryLedger.swift:166`; #890 and #884 are open | gap (waits on #890, #884; no rerun: the backfill runs once per store and later changes apply forward only) | Core | `thePantryFlagUsesTheOnePrivateTitleCheck` |
| PF13 | The flag on the Pantry screen | `Private item`, `out` or `low` still shown (state is not private, the name is); no tap target, no reveal (R12, G102) | `PantryLine.opens` false for private: `PantryView.swift:134`; see pantry-v2.md PP01, PP02 | traced (screen, today's live mask) | Builder B | `aFlaggedIngredientReadsPrivateItemWithNoReveal` |
| PF14 | Swipe a flagged line to add it to Groceries | receipt `Private item, on Groceries.`; the Groceries row is a private row (`Private item`) | see pantry-v2.md PP03 | traced (today's mask) | Core | `aFlaggedIngredientSwipeMakesAPrivateRow` |
| PF15 | Recipe page for a plain recipe that uses a flagged ingredient | the ingredient line on the recipe page reads `Private item` too (one mask, G141); the recipe stays plain | object-page mask is #912's `ObjectMask.label(of:)`, not merged; recipe page reads titles | gap (waits on #912) | Builder B | `aFlaggedIngredientIsMaskedOnOtherRecipes` |
| PF16 | Object page and class page of a flagged ingredient | heading, class line, fields and Linked from all read `Private item`; `pantryPrivate` itself is not printed as a field | generic page prints every field (`ObjectPage.swift:342-360` per decisions.md:171); #912 not merged | gap (waits on #912) | Builder B | `theObjectPageHidesAFlaggedIngredient` |

## 2. UNDO and the op log

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| PU01 | One private cook sets the flag; UNDO that cook | the flag clears together with the state the cook wrote (the cook set it) | UNDO is guarded per field: `ActionEngine.swift:143-149`, `:253` | gap (no flag) / mechanism traced | Core | `undoingAPrivateCookClearsTheFlagItSet` |
| PU02 | Two private cooks A then B both set limes private; UNDO B | the flag stays (A also set it); only what B set and nothing newer changed is reverted | op "before" for B holds the flag already true, so its inverse writes true back: inferred from `ActionEngine.swift:253-262` | inferred | Core | `undoingTheLaterCookKeepsTheFlagAnotherCookSet` (PE29) |
| PU03 | Same two cooks; UNDO A (the earlier) while B stands | the flag stays (B still holds it); no clobbering of B's newer state | guarded replay skips a field whose current value is not A's "after" | inferred | Core | `undoingTheEarlierCookKeepsTheFlagALaterCookHolds` |
| PU04 | One private cook, then a plain cook of the same ingredient, then UNDO the private cook | the flag clears only if nothing else set it; the plain cook never set it, so it clears; the plain cook's state is not clobbered (an older op does not overwrite a newer field, PD32 rule) | guarded replay | inferred | Core | `undoingThePrivateCookClearsOnlyItsOwnFlag` |
| PU05 | UNDO a cook, then redo it | the flag returns with the state | `redo`: `ActionEngine.swift:151-157` | inferred | Core | `redoingAPrivateCookSetsTheFlagAgain` |
| PU06 | UNDO a cook after the recipe was deleted | the flag state follows the op only; deleting the recipe did not clear it (PF05) | n/a | inferred | Core | `undoAfterDeletingTheRecipeStillClearsOnlyThatCooksFlag` |
| PU07 | UNDO the backfill | there is no UNDO (`.system`, no receipt, no slot); `undoLatest()` skips it | `ActionEngine.swift:161-173`, `Actor.system` at `Op.swift:12`; see pantry-v2.md PB08 | traced (skip rule) / gap (op) | Core | `theBackfillCannotBeUndoneAndFlagsStay` |
| PU08 | A cook op, read from the op log summary | the summary names no ingredient and no private recipe title (it reads `Private recipe` or the plain title as today); the op's `setValue` entries for the flag carry the ingredient id, not a word | summaries are masked by label: `TesseraExport.swift:165-185` | gap | Core | `aCookOpSummaryHoldsNoPrivateWord` |

## 3. Shared export (G196, R18)

The shared file is the one Kaushik can send elsewhere (`maskingPrivate: true`). The full backup (`maskingPrivate: false`) is untouched by every row here and keeps all pantry data.

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| PX01 | Shared export of a store that has run the backfill and holds told states (a private cook and a plain one) | (Kitchen's PE25 does not list `lastUsedAt`; this row keeps it, and Kitchen was told) no Ingredient pantry field in `objects[].values`: `state`, `stateAt`, `lastBoughtAt`, `lastUsedAt`, `usualSkippedAt`, `pantryPrivate`; private and plain ingredients alike | values copied whole: `TesseraExport.swift:129-136`; no field exists on master to leak | gap | Core | `theSharedExportHoldsNoPantryFieldsOrOps` (PE25) |
| PX02 | Same export, the `operations` list | no op that wrote any of those fields (any `setValue` whose field is one of the six), and no `pantryBackfill` op (the single `.system` op that set a value for every ingredient) | ops copied whole, masked only by touched private objects: `TesseraExport.swift:141-145`, `:165-185`; no such op exists | gap | Core | `theSharedExportHoldsNoPantryOps` |
| PX03 | An op that holds BOTH a pantry field and a non-pantry field (a cook that sets `cookedAt` on the Cook and pantry state on ingredients, if Core writes them as one op) | the export keeps the Cook part and drops the pantry part: no pantry `setValue` survives and the Cook's `cookedAt` is still in the file | n/a | gap | Core | `aMixedCookOpKeepsItsCookPartAndLosesItsPantryPart` |
| PX04 | A private ingredient (flagged) | still masked as an object (title `Private item`, values filtered to structural ones) AND its pantry fields gone; no double handling that re-adds a field | mask keeps only `PrivateWords.structural` values: `TesseraExport.swift:156-163` | gap | Core | `aFlaggedIngredientExportsAsPrivateItemWithNoPantryFields` |
| PX05 | Shared export on a store that ran the backfill vs one that never did | the export bytes for the non-pantry parts are identical in structure; only pantry fields and ops differ (no leftover empty `pantryBackfill` shell, no op count gap noticed as a hole) | n/a | gap | Core | `thePantryFilterLeavesEveryOtherFieldAndOpAlone` |
| PX06 | The field-key map in the export (`fieldKeys`, field id to key) | the pantry field ids may stay in the schema (`classes[].fields`) or go; a file with the schema but no values must still decode | `fieldKeys` built from every class field: `TesseraExport.swift:128-129` | gap | Core | `aSharedExportWithPantryFieldsInTheSchemaButNoValuesDecodes` (accepted: the pantry fields stay in the shared schema) |
| PX07 | The Settings key `pantryBackfilled` | the marker does not travel in the shared export | settings ride every export per #407's note; marker accessor not named (decisions.md G202 in kitchen-gap-hunt-15) | gap | Core | `theBackfillMarkerIsNotInTheSharedExport` |
| PX08 | The full backup of the same store | keeps every pantry field, the `pantryPrivate` flag and every pantry op, including the backfill op; a restore from it brings Pantry back whole | `maskingPrivate: false` copies all: `TesseraExport.swift:105`, `:129-145` | gap (no data) / path traced | Core | `theBackupKeepsPantryStateAndTheFlag` (acceptance echo of `theBackupKeepsPantryState`, pantry-v2.md PR18) |
| PX09 | Export twice in a row, no change between | identical bytes; the filter adds no time-dependent or random content | export is "stable JSON" (`TesseraExport.swift:187`) | inferred | Core | `thePantryFilterKeepsTheExportDeterministic` |
| PX10 | Words: no private ingredient name in any shared byte after a flagged cook | the file holds no occurrence of the flagged ingredient's raw name in titles, values or op summaries (a search of the encoded bytes for the made-up name) | label mask: `TesseraExport.swift:153-185`, `PrivateWords.swift:193-196` | traced (for objects today) / gap (ops with the new fields) | Core | `noFlaggedIngredientNameIsInTheSharedBytes` |
| PX11 | Import the shared file's op list into the op log and ask "what did I do Saturday" | day log shows no pantry line from the file; no `lastUsedAt` or state appears as an event | day log reads ops | gap | Core | `aSharedExportCarriesNoPantryEventsForTheDayLog` |
| PX12 | Backward compatibility: a shared file written by the old build (no pantry fields) restored into the new build | restores cleanly; no field added; Pantry empty | `restore` copies the file's values: `TesseraExport.swift:255-286` | traced (restore tolerates absent fields) | Core | `anOldSharedFileRestoresIntoThePantryBuild` |

## 4. Import: an empty Pantry

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| PM01 | Import a shared export into a fresh store (new phone, restore) | Pantry shows the empty front, hero `Nothing yet`; no ingredient has a state, `lastBoughtAt`, `lastUsedAt` or `pantryPrivate`; `hasAnyState` false; CAN COOK greyed | holds today only because no field exists: `restore` at `TesseraExport.swift:208`; empty hero `PantryLedger.swift:78` | traced (today by absence) / gap (after fields land) | Core | `aFreshImportOfASharedExportShowsAnEmptyPantry` (PE26) |
| PM02 | Same import, then relaunch | the backfill does NOT run against the imported history (the file holds no cooks or clears that carry pantry meaning) OR it runs and finds nothing; either way Pantry stays empty and no private flag appears from the file | no backfill | gap | Core | `importingASharedFileDoesNotInventPantryState` |
| PM03 | Same import: groceries, recipes and cooks DO come across | Groceries rows and Recipes are there; the cooks (the Cook objects with `cookedAt`) are there; only Pantry is empty, so the Recipes shelf shows cooks but not CAN COOK counts | objects and ops restored: `TesseraExport.swift:255-298` | traced | Core | `anImportKeepsGroceriesAndCooksButNotPantry` |
| PM04 | Import, then the backfill marker | backfill is keyed to the store's own history; an import sets `pantryBackfilled` itself, so it never rebuilds from imported cooks and Pantry stays empty (consistent with PM01) | n/a | gap | Core | `theBackfillDoesNotRebuildPantryFromAnImport` |
| PM05 | Import into a store that already has pantry state (`merging: true`, launch seeding case) | existing state is kept (`merging` keeps anything whose id is already there); the shared file adds none | `restore(merging:)`: `TesseraExport.swift:208-212`, `:247-253` | traced | Core | `mergingASharedFileKeepsTheStoresOwnPantry` |
| PM06 | Restore from the full BACKUP (not the shared file) | Pantry comes back whole, flags included, and the marker travels so the backfill does not rerun | `restore` copies values: `TesseraExport.swift:255-286` | gap (no fields) | Core | `aBackupRestoreBringsPantryAndTheFlagBack` |
| PM07 | Pantry screen on an imported store | empty front wording is the same `Nothing yet` / its context line; no `Private item` line appears | `PantryFront.swift:26` (`isEmpty`), `PantryView.swift:54-61`; see pantry-v2.md PD20 | traced (empty path) | Builder B | `thePantryFrontIsEmptyAfterAnImport` |

## 5. Cross-checks

| Id | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| PQ01 | The AI packs (Kitchen, Capture, Home) with a flagged ingredient | carry no pantry field, no flag, no ingredient name that is flagged | see pantry-v2.md PB17 (traced today: no pack mentions Pantry) | traced (today) | Core | `thePackSnapshotsCarryNoPantryFlag` |
| PQ02 | Receipts and Tess lines after a flagged cook (G105 one function) | no flagged name in any receipt, UNDO line or Tess line; `Private item` where a name would go | see pantry-v2.md PP10, PP11, PP12 | partial | Core | `noPantrySurfaceCarriesAFlaggedName` (as PP12) |
| PQ03 | Widgets and Live Activities | no flag, no pantry state read from the shared file; nothing new to widget payloads | none read Pantry today (grep of `Features/Home/HomeSpatialView.swift` is the only Home hit) | inferred | Core | `noWidgetOrActivityReadsPantryPrivate` |
| PQ04 | The flag versus the swipe-lean rows | the lean fixtures colour the line, not the flag; no row there changes | `gaps-92-swipe-lean.md`, `arealean-tokens.md` | inferred | Builder B | n/a (cross-reference only) |

## Counts

PF01 to PF16 (16), PU01 to PU08 (8), PX01 to PX12 (12), PM01 to PM07 (7), PQ01 to PQ04 (4): 47 rows.

| Status (first word of the row's status) | Rows |
|---|---|
| traced | 11 |
| inferred | 8 |
| partial | 1 |
| gap | 27 |

Rows with a split status (for example "gap (no flag) / mechanism traced": PU01, PU07, PX08, PX10, PM01) count under their first word. Of the 27 gaps, PF12, PF15 and PF16 also wait on unmerged PRs (#890, #884, #912).

## Product answers folded in

Product's 9:19 PM PT Oct 17 answers (decisions.md line 1013, defaults, reversible) are folded into the rows above, and no question stays open. Q1, Q4 and Q7 were accepted as drafted: the flag is only for cook-derived privacy, the pantry fields stay in the shared schema (PX06), and value-guarded replay is the UNDO mechanism (PU02, PU03). Q2, Q3, Q5, Q6 and Q8 changed rows PF08, PX03, PX07, PM04 and PF12.

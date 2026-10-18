# Gap hunt 12: Pantry v2 spec for Core, and the recipe paste/scale edge cases

Static read only, repo /home/user/Tessera at origin/master 3e8e2703 (fetched Oct 17). No Swift toolchain, nothing was run. Every claim has a file:line I read; "(inferred)" marks a reading I did not see executed. All fixtures are made up. No Claude key was printed or stored. Abbreviations for paths: `Q` = TesseraCore/Sources/TesseraCore/Kitchen/Quantities.swift, `RM` = .../Kitchen/RecipeMath.swift, `RP` = .../Kitchen/RecipeParser.swift, `RL` = .../Kitchen/RecipeLimits.swift, `Rc` = .../Kitchen/Recipes.swift, `Gr` = .../Kitchen/Groceries.swift, `PL` = Features/Kitchen/PantryLedger.swift, `PV` = Features/Kitchen/PantryView.swift, `PC` = Features/Kitchen/PantryCopy.swift, `PA` = docs/product/pantry-acceptance.md, `KV2` = docs/product/kitchen-v2-acceptance.md, `GH10` = docs/product/kitchen-gap-hunt-10-copylist-pantry-oct17.md.

---

# PART 1. Pantry v2, a spec ready for Core

## 0. What is on master today (so the spec starts from facts)

- No stored pantry state. `Ingredient` has only `aisle` and `isStaple` (SystemCatalog.swift:280-284). The catalog package is version 9 (SystemCatalog.swift:349). The "v10" that core.md:328 calls "#407's" is not on master (grep of Sources finds no version 10), so the Pantry bump is the next number after whatever is on master when Core branches: 10 today (inferred), 11 if #407 lands first.
- `PantryLedger` (PL:11) is app-side, read-only: it re-derives state from shop clears (`Groceries.shopClears()` plus `putAwayBasket()`, PL:140-143) and from every finished cook (PL:146-161), latest event wins, ties go to the surer state (PL:131-133). Its header says "the shape Core lifts into TesseraCore later" (PL:9).
- No "out of milk" or "have rice" rule: `TessGrammar+Kitchen.swift` has buy/get/for-groceries/list/shop/timer/cook rules only (lines 17-76). No `RecipeMath.missing`, no CAN COOK. Also no recipe-shelf filters at all: grep of Features/Recipes for quick, lately, filter, basket finds none, so KV2 W1 ("QUICK, NOT LATELY, CAN COOK in place of FROM THE BASKET") describes a shelf that is not built yet (inferred); CAN COOK would be the first filter, and "not cooked lately" has no helper.
- The one app-wide UNDO slot is `TessVoice.shared` over `HomeQueue.Note` (HomeQueue.swift:20-52): one note at a time, a new `say` replaces the old one, and the timer only clears its own note (`note.id` check, :35-38). `hold(undo:holds:voiceOver:)` (:43-50): a note with UNDO holds 10 s by default, a plain line 4 s, `holds` overrides, and under VoiceOver any UNDO is a flat 10 s. Pantry's swipe passes `holds: .seconds(4)` (PV:119). UNDO's follow-up line is `UndoCopy.takenBack` (BottomChrome.swift:760-768), which cuts the receipt at the first ", ".
- Staples have three definitions today (see F1 below).

### Found while reading (spec-level problems; these are P-F numbers, not G numbers)

- **P-F1 (important)** Staple drift. `RecipeBook.Line.isStaple` reads only the ingredient's `isStaple` field (Rc:96). `AddRecipeToGroceries` and the ledger read the field OR `AisleGuide.isStaple` (Gr:456-457, 487-488; PL:172-175). I found no code that ever sets the field (grep of Core, Features, App), so on the recipe page salt and oil are not dimmed (RecipePage.swift:370 uses `line.isStaple`) while Groceries skips them (inferred). `missing` must call one helper (clause M2).
- **P-F2 (low)** The Pantry hero counts a private "Private item" line while the line itself is not tappable (PL:49-51 filters only unknown and deleted; PL:163-169). A count reveals nothing, so default keep; GH10 G90 already asked.
- **P-F3 (low)** Tess's cook line uses the full recipe title (PL:99, PC:30) while every other recipe receipt uses `RecipeCopy.shortName` (RecipePage.swift:605). A 12-word title makes a 12-word line. Fix: shortName.
- **P-F4 (important, doc conflict)** KV2 W3 says missing counts "out or unknown"; W2 drops a recipe "missing two or more"; W7 says with no state at all CAN COOK shows every recipe as "N to check" AND the word is greyed. On a day-one phone every non-staple line is unknown, so every recipe with 2 or more lines would drop, which is why W7 exists; but "shows every recipe as N to check" and "greyed rather than a dead end" cannot both hold. Ruling R6.
- **P-F5 (low, doc conflict)** PA S5 says USUALLY HAVE shows "1 to 4 names" as is; S6 says "4 or more" reads "Rice, coffee and 2 more". Exactly 4 is in both. Ruling R14.
- **P-F6 (low)** KV2 P8: unknown ingredients have no sentence at all, so the Ingredient page has no state word to tap, yet P9/S7 cycle "in, low, out, in" from the word. There is no way from the screen to set the first state of an unknown ingredient. Ruling R15.
- **P-F7 (low)** PA P10's rhythm line ("Bought 4 times, about every 12 days.") needs buy history; `lastBoughtAt` holds only the latest. The rhythm must keep reading the shop-clear ops (`Groceries.shopClears()`, Gr:168-182), not the field (clause S12).
- **P-F8 (important)** `ClearDoneItems` is a generic Lists action (Lists.swift:446) that Groceries also uses, and `FinishShop` clears too (Gr:191). Writing pantry state from them must be conditional on the list being Groceries (a Packing list clear sets nothing).

---

## (a) Stored state

### Fields on Ingredient (additive)

| Key | Kind | Meaning |
|---|---|---|
| `state` | choice, options `in`, `low`, `out` | Absent means unknown. Unknown is never written, so there is no row to migrate and no "unknown" option to seed. Swift side: `PantryState { unknown, inStock, low, out }` (name `in` is a keyword; the stored string stays `in`; the word on screen is "in"). |
| `lastBoughtAt` | date | The check date of the latest shop clear (or "got/bought" phrase) that had it. Never cleared by a state change. |
| `stateAt` | date | When `state` was last set, by event time (the check date for a clear, `cookedAt` for a cook, now for a phrase or tap). Needed so "latest event wins" survives after the derivation is gone. RULING NEEDED R2, recommended default: add. |
| `usualSkippedAt` | date | The R slice's quiet rule (PA R: "stays the quiet rule"); it is not on master (grep finds none). RULING NEEDED R2, recommended default: add in the same bump so there is only one catalog number. |

### Migration (additive)

- No GRDB migration. Values are JSON in `valuesData` and the catalog seeder already adds missing fields to existing classes ("Adds fields introduced in later versions", SystemCatalog.swift:~395-420) with stable ids `stableID("system.ingredient.state")`. `TesseraDatabaseSchema.migrator` (v1, v2, v3, TesseraDatabaseSchema.swift:34-80) is untouched.
- Bump `SystemCatalog.package.version` from 9 to the next number (see section 0). A store written by this build is then "newer" to an older build and is refused rather than opened (TesseraDatabaseSchema.swift:10-23; the check reads `MAX(packageVersion)`), so a downgrade can never drop the new fields. Backup restore follows the same check (BackupTests.swift:83 pattern).
- Backfill (RULING NEEDED R1, recommended default: yes, once). On first launch after the bump, write the state the ledger would have shown, so the Pantry does not go blank for someone with a week of real shops. One `.system` op, no UNDO, guarded by a marker (a Settings key, or "any ingredient already has `state`") so it runs once and never overwrites a later change. The lifted ledger (G88) is the code that computes it; after the backfill the derivation is deleted, so history edits can no longer rewrite Pantry (this fixes G46 from the earlier Pantry gap hunt). Alternative: start unknown; costs a blank Pantry and a "nothing yet" screen for a phone that already knows things.
- Shared export (the masked one): pantry state is a body-adjacent fact about what he eats; RULING NEEDED R18, recommended default: leave `state`, `stateAt`, `lastBoughtAt` out of the shared export and keep them in the full backup.

### Who writes state (all inside the op that causes it, so one UNDO takes both)

| Event | Writes | Notes |
|---|---|---|
| Shop clear / Done shopping on Groceries only | each checked item's ingredient: `lastBoughtAt = max(old, checkedAt)`; `state = in`, `stateAt = checkedAt` only when `stateAt` is nil or earlier than `checkedAt` | A newer cook or phrase already said otherwise and stays (latest event wins, as the ledger does at PL:131-133). Put-away basket to Later counts as bought, as today (PL:138-139, Product 9:45 ruling 5). |
| `FinishCooking` | each line's ingredient that is not a staple (shared helper), not optional, not to-taste: Produce aisle `out`, else `low`; `stateAt = cookedAt` | Staples untouched. A private recipe still writes (the Tess line stays silent, FG9). Same latest-wins test. |
| "out of milk" and the like | `out`, `stateAt = now`; plus a Groceries row (clause V6) | One op. |
| "have rice" | `in`, `stateAt = now` | `lastBoughtAt` untouched. |
| "got milk", "bought milk", "picked up milk" | `in`, `stateAt = now`, `lastBoughtAt = now` | RULING NEEDED R10, recommended default as written. |
| State-word tap on the Ingredient page | next of in, low, out, in | One op per tap. |
| Time passing | nothing | PA open question 1. |

---

## (b) The "out of milk" grammar rule

Where it sits: `TessGrammar+Kitchen.swift` `parseKitchen`, after the `todo/task/remind` guard (line 34, so "remind me we're out of milk" stays a task) and before the "for groceries" rule (line 43) and the buy/get rule (line 49). The walls run first (P16 / `product-decisions-walls.md`). A phrase with a day or time (`hasDate`, line 22) is not ours ("we'll be out of milk thu" stays a task).

### Phrases (case-insensitive; `X` = one or more items)

| Meaning | Shapes |
|---|---|
| out (state + row) | `out of X`, `we're out of X`, `we are out of X`, `i'm out of X`, `i am out of X`, `all out of X`, `just out of X`, `ran out of X`, `we ran out of X`, `we've run out of X`, `no more X`, `no X left`, `X is out`, `X's out`, `X are out`, `X is gone`, `X's gone`, `X are gone` |
| low (state only) | `low on X`, `running low on X`, `X is low`, `X's low`. RULING NEEDED R9, recommended default: include; no Groceries row (the Pantry swipe adds). Receipt "Rice, low." |
| in | `have X`, `i have X`, `we have X`, `got X`, `bought X`, `picked up X`, `restocked X`, each with optional "some" or "more". Not with "a" or "an", and not with a count. |
| open Pantry | `pantry`, `open pantry`, `show pantry`, `what's out`, `what am i out of`, `what do i have` (exact; with a day word it is the schedule, "what do i have tomorrow"). RULING NEEDED R11, recommended default: exact `what do i have` opens Pantry as `PA` Defaults says. |

Subjects in the `X is out` forms must be bare ("milk is out"): "the milk is out" or "my milk is out" is not claimed (it can mean left on the counter).

### Item-name matching (M-rules)

1. Normalize: lowercase, trim, drop final punctuation. Strip leading "some", "any", "more", "the", "my", "our", "enough", "a bit of", "all the", and trailing "again", "now", "today", "too", "as well", "already", "right now".
2. Match an existing Ingredient by `IngredientLine.key(for:)` equality only (Q283-297: lowercase, per-word singular, aliases). So "eggs" finds Eggs, "2% milk", "whole milk" and "skim milk" find Milk, "yellow onion" finds Onion, "red onion" stays red onion. Never a substring: "out of milk chocolate" must not make Milk out; "out of oat milk" must not make Milk out (key "oat milk" is not "milk").
3. No match: create the Ingredient with `Transaction.ingredient(named:)` (Ingredients.swift:~33-45: title as typed, first letter capital), only if the name is admitted (next rule).
4. Admission for OUT phrases (RULING NEEDED R8, recommended default): the name has 1 to 4 words, no digit (except `\d+%` as in "2% milk"), and either an existing Ingredient or `AisleGuide.aisle(for:)` knows it (that function already tries the last word and last two words, "oat milk" finds milk's aisle, Aisles.swift:~44-50). Anything else is not a pantry phrase: it is not claimed, and the rest of the grammar decides ("out of chalk" stays a Gym bag matter). IN phrases are stricter: the whole name must already be a known Ingredient or a name in the aisle guide's table, no head-noun admission.
5. Any other digit in the phrase means not ours (R17): "out of 5", "no more 2", "have 2 lemons". The pantry never counts.
6. Several items: split with `GroceryLines.split` ("milk, eggs and rice" is three; "mac and cheese" and "salt and pepper" stay one). One op for all.
7. The Groceries row for an OUT item: text is the Ingredient's title lowercased (as `addGroceryShare` does, Gr:~506), quantity is the last amount he typed for that ingredient (the newest Groceries row for it that he typed, open, cleared or deleted; shares from recipes do not count), or none. Never a guessed amount. No second row if one is open or in the basket (see receipts).

### Must NOT be claimed (the G92 holes, with the guard that handles each)

| Phrase | Guard |
|---|---|
| out of breath, bed, time, range, town, office, ideas, luck, order, touch, shape, energy, control, reach, sight, practice | name not known (rule 4). "Range" is also the kit-range word at TessGrammar.swift:112; this rule never fires on it. |
| out of stock | "stock" alone is on a stoplist; "chicken stock" is allowed. |
| no more reps, sets, meetings, emails, excuses | name not known. |
| have a call at 3, have a lemon, have 2 lemons | article, count, time. |
| got a haircut sat, bought milk sat | day word (the dated-note rule, PrivateFacts.swift:7-10, keeps it). "bought milk" with no day is ours. |
| the milk is out | non-bare subject. |
| remind me we're out of milk, todo out of milk | guard at line 34. |
| out of milk $4 | price tail stripped with `EngineWall.withoutPrice`; the rule proceeds; no amount stored or spoken. |
| spent $4 on milk | not this rule (`isMoney`, line 81). |
| out of a string starting with the Claude key prefix or a "password is hunter2" tail | refused by the secret check, no state written, the existing wall line. |

### Receipts (thing first, "on", digits for counts)

| Case | Line | UNDO |
|---|---|---|
| out, new state, row added | `Milk, out. On Groceries.` | 4 s (it adds a row) |
| out, new state, row already open | `Milk, out. Already on Groceries.` | 10 s (a change) |
| already out, row already open | `Milk, already on Groceries.` | none, no write (S10, P15) |
| already out, row gone | `Milk, on Groceries.` | 4 s |
| out said, the item is checked in the basket | `Milk, in the basket.` no write | none (R20, same as the swipe, PantryFront.swift:49-52) |
| in | `Rice, in.` | 10 s |
| low | `Rice, low.` | 10 s |
| two items | `Milk and eggs, out. On Groceries.` | per the row above |
| three or more | `Milk and 2 more, out. On Groceries.` (first name, then the count; no inner commas, so `UndoCopy.takenBack` reads "Milk and 2 more, taken back." and never cuts a list in half; compare GH-11 G108) | |
| walled name | `Private item, out. On Groceries.` | per the row above |
| a secret or price refusal | the existing wall line, nothing written | none |

Names in receipts are the stored title ("Oat milk", not "oat milk"). The first item of several names the receipt; a private item reads "Private item" wherever it falls.

### UNDO slot (one app-wide UNDO)

- The only place a receipt with UNDO lives is `TessVoice.shared.say(_, undo:, holds:)`. A new say replaces the old note, including its UNDO: the older op stays done (it is still in the op log and "What Tess did"), but its UNDO is gone. This is the "one UNDO" rule; clause U3 tests it.
- 4 s for any op that adds a Groceries row (a new capture); 10 s for a pure state change; VoiceOver forces 10 s on both (HomeQueue.swift:43-50). A no-write line is a plain 4 s line with no UNDO.
- UNDO reverses the whole op: the state, `stateAt`, `lastBoughtAt` and the added rows. After it, Tess says the `takenBack` line, then her own line returns (PA S7).
- Pantry's `speak` never overwrites an open UNDO (PV:92-95); keep it.

---

## (c) `RecipeMath.missing` and CAN COOK

Sketch (Core shapes the types): `RecipeMath.missing(lines: [RecipeBook.Line], state: (ObjectRecord) -> PantryState, isPrivateIngredient: (ObjectRecord) -> Bool) -> RecipeNeed`, with `RecipeNeed { out: [NeedLine]; unknown: [NeedLine]; low: [NeedLine] }`, `score = out.count + unknown.count`. It is pure over lines and a state lookup; it never reads amounts, never reads serves (a size change cannot change presence).

| Line kind | Behavior | Why / source |
|---|---|---|
| No linked ingredient | skipped | Groceries does the same (`guard let ingredient`, Gr:454). |
| Same ingredient on two lines | counted once | "butter" in sauce and topping. |
| Staple (shared helper, field OR `AisleGuide.isStaple`) | skipped, even when out | KV2 P2/W3. RULING NEEDED R3: recommended default keep P2/W3 as ruled. Alternative C: a staple counts as missing only when he told us it is out (cooks never make a staple low or out, PL:149-153), which removes the "Pantry lists salt OUT but CAN COOK says 0 missing" mismatch (G89.1). |
| `toTaste` | skipped | Gr:462, PL:155. |
| `optional` ("for serving", "for garnish") | skipped, so "1 missing: parsley" can never name a garnish | G89.2. RULING NEEDED R4, recommended default skip; and parser reads "as needed" as to-taste (G113). |
| state `in` | not counted | |
| state `low` | not counted | W3 (never low). |
| state `out` | `out` (missing) | |
| state unknown, or ingredient deleted | `unknown` ("to check") | W3/W5. Opens the Ingredient page; adds nothing. |
| Private ingredient | counted like any other, but its label is "Private item" in every string | uses the one shared rule "used only by private recipes" (core.md decision 5:16) plus the word wall (`ObjectPrivacy.isPrivateRecipeTitle`, PL:166), same label as the ledger (PL:163-169). |
| Private recipe (title wall) | the shelf row still reads "Private recipe"; `RecipeNeed` hands the shelf counts only, `names` is empty, and the line reads the count form without a name and has no tap-to-add | K89.1 (even "took the limes" names what was in it). RULING NEEDED R13, recommended default as written; it still takes part in the "N you can cook now" count (a number only). |
| Recipe with no ingredient lines | not judged: listed after the rest, never counted as cookable | R16. |

### CAN COOK ordering and lines

- Sort key: (score, out.count, longest since last cooked). So a recipe with one unknown ("might be fine") sorts above one with one out. "Not cooked lately": never cooked first, then the oldest cook. There is no such helper on master (section 0); add `RecipeBook.lastCooked(_:)` over `cookedAt`.
- "N you can cook now" counts score 0 only.
- Drop rule (W2): score 2 or more fades down. RULING NEEDED R5, recommended default: W3/W2 as written. Alternative worth a ruling: only `out.count >= 2` drops and unknown only orders and words the line, because "unknown" is not a claim that something is gone and, a month in, most of his pantry is still unknown.
- Day one: no ingredient has a state anywhere (`PantryBook.hasAnyState == false`): the CAN COOK word is greyed (42%), a tap says Tess's empty line ("Clear a shop or finish a cook and this fills in.", 4 s, no UNDO) and the shelf does not re-sort. The per-row "N to check" appears only once something is known. This amends KV2 W7 (R6).
- Adding from the "1 missing" line: the same add as the swipe (one Groceries row), receipt `Lemons, on Groceries.` UNDO 4 s; an out item already on Groceries reads `Lemons, already on Groceries.`

---

## (d) Strings and caps

"Cap" means the length or count limit the string must respect. Names wrap and are never cut (lists-acceptance 13.11); nothing is under 16 pt; counts are digits; no "at" before a time; no ellipsis.

### Pantry screen

| Where | String | Cap / rule |
|---|---|---|
| Title | `Pantry` | tab-level area; KITCHEN's index word "Pantry" |
| Context | `since today's shop`, `since yesterday's shop`, `since Saturday's shop`, `since the Oct 3 shop` | PC:8-25; weekday within 6 days, then "MMM d"; hidden before any shop. At most 22 characters. |
| Side word | `OUT AND LOW` | caps label, 13/700 |
| Hero | `4 out, 2 low`, `1 out`, `2 low`, `Nothing out`, `Nothing yet` | digits; "out" and "low" never take an s; never "0 out"; the same string is Home's and the index's. Counts include walled lines (a number only). |
| Group labels | `OUT`, `LOW`, `USUALLY HAVE` | 13/700 caps; an empty group is not drawn, not even its label |
| Line | `Milk` + `out` / `low` | state word at the right (out 700, low 600); a walled name reads `Private item` |
| USUALLY HAVE | `Rice, coffee, eggs`; from the cap `Rice, coffee and 2 more` | cap 4 names total (Research rules 1-9); R14 for exactly 4; "and N more" at 55% |
| Empty | hero `Nothing yet`, under it `Clear a shop or finish a cook and this fills in.` | 51 characters, 55% ink; no art |
| Tess, empty | `Say "out of milk" and I'll keep it.` | 36 characters, only once the phrase ships (G91; PV:96) |
| Tess, after a cook | `Tacos took the cilantro and limes.`; 4 or more names: `Tacos took 5 things.` | up to 3 names then the count (PC:28-31); recipe by `shortName` (P-F3); silent after a private cook |
| Swipe receipts | `Milk, on Groceries.` / `Milk, already on Groceries.` / `Milk, in the basket.` | 4 s on the first, none on the others |
| Write failure | `Didn't save that. Try again.` | PV:115 |
| State-word tap | `Limes, in.` / `Limes, low.` / `Limes, out.` | UNDO 10 s |
| Ingredient page | `Out since you cooked dal on Tuesday.`, `Low, after dal on Tuesday.`, `In since Saturday's shop.`, `In, as of now.` (KV2 P8). Proposed for told states, marked proposed: `Out, since you said so on Tuesday.`, `In, since you got it on Tuesday.` | unknown: no sentence at all; weekday names on the 4 am house day |
| Rhythm | `Bought 4 times, about every 12 days.` | only from 3 buys, read from the shop-clear ops (P-F7) |
| VoiceOver | label `Limes, out`; custom action `Add to Groceries`; hint `Opens Limes` | PV:151-152; a walled line reads `Private item, out` |

### Recipes screen

| Where | String | Cap / rule |
|---|---|---|
| Recipe page, ingredient peek (state words only) | `have` (42% ink), `low`, `out` (ink), `used` (during a cook); nothing for unknown | no value on unknown rows; staples show nothing |
| Peek key | `ADD 6 TO GROCERIES` | caps; digits; absent when 0 (research D3 "key word absent"); N = rows that would be added, equal to the dry run |
| Peek receipt | `Chicken, 6 added.` | shortName; private recipe: `Private recipe, 6 added.`; UNDO 4 s |
| Recipe page, out line | amount 400 weight, 55% ink, faint ring | low and unknown: nothing |
| Shelf filter word | `CAN COOK` | caps; off by default; greyed with no state (R6) |
| Shelf context, on | `3 you can cook now`, `1 you can cook now`, `Nothing without a shop` | digits; the last only when every recipe has missing or to-check lines |
| Shelf sub-line | `1 missing: lemons`, `1 to check: lemons` | one name, 30 characters then wraps; walled name `Private item`; private recipe: no name (count form only, R13) |
| Sub-line tap | missing: `Lemons, on Groceries.` UNDO 4 s; to check: opens the Ingredient page, adds nothing | |
| Day one | no per-row line | amended W7 |

---

## (e) Clauses and the tests Core should write

Test files: `PantryStateTests`, `PantryEventTests`, `PantryGrammarTests`, `PantryUndoTests`, `RecipeMissingTests`, `PantryWallTests` (Swift Testing, in TesseraCore/Tests/TesseraCoreTests). Names follow the repo's sentence style.

**S. Stored state**
- S1. Ingredient gains `state`, `lastBoughtAt`, `stateAt` (and `usualSkippedAt`); the catalog version is bumped to the next number; no GRDB migration is added. Tests: `theCatalogBumpAddsThePantryFieldsToAnOldStore`, `theBumpKeepsEveryOldIngredientValueAndId`, `noGRDBMigrationIsAddedForPantry`.
- S2. Every ingredient is unknown until an event; unknown is stored as no value. Tests: `anUntouchedIngredientIsUnknown`, `unknownIsNeverWritten`.
- S3. An older build refuses a store at the new catalog number. Tests: `anOlderBuildRefusesTheNewCatalog` (BackupTests.swift:83 pattern).
- S4. Backfill (if R1 = yes) runs once, as `.system`, from the same facts the ledger gave, and never overwrites a later change. Tests: `theBackfillMatchesTheLedgerOnTheTacosFixture`, `theBackfillRunsOnce`, `theBackfillKeepsALaterStateIntact`, `theBackfillIsNotUndoable`.
- S5. State never changes with the clock. Tests: `nothingChangesNinetyDaysLater`.
- S6. A deleted ingredient is not listed and reads unknown to `missing`. Tests: `aDeletedIngredientIsNotListed`, `aDeletedIngredientIsUnknownToMissing`.
- S7. The pantry fields are not in the shared export (R18) and are in the full backup. Tests: `theSharedExportHoldsNoPantryState`, `theBackupKeepsPantryState`.
- S8. The AI packs hold no state, no `lastBoughtAt`, no ingredient names from Pantry. Tests: `thePackSnapshotsCarryNoPantryFields` (Kitchen, Capture, Home packs; PA Core 7).
- S9. A pantry-shaped phrase the rule cannot place never goes to Claude. Tests: `aPantryShapedMissStaysOnThePhone` (GH10 G84).
- S10. Ingredient fields are in the lifted ledger's one reader `PantryBook`; the app-side `PantryLedger` is deleted or a thin wrapper. Tests: `theLiftedLedgerGivesTheAppLedgersAnswers` (parity on a fixture).
- S11. `isStaple` has one definition used by the recipe page, Groceries, the ledger and `missing`. Tests: `saltIsAStapleOnTheRecipePageToo` (P-F1), `groceriesAndMissingAgreeOnStaples`.
- S12. The rhythm line reads shop-clear ops, not the field. Tests: `theRhythmReadsTheShopClears`.

**E. Events**
- E1. A shop clear with 3 checked items sets their ingredients in with `lastBoughtAt`. Tests: `aShopClearSetsEachCheckedIngredientIn` (PA Core 1).
- E2. A clear on any list but Groceries sets nothing (P-F8). Tests: `clearingPackingSetsNoPantryState`.
- E3. A clear never overrides a newer cook or phrase but still updates `lastBoughtAt`. Tests: `aClearKeepsANewerCookState`, `aClearStillUpdatesLastBoughtAt`.
- E4. UNDO of a shop clear restores the previous state and `lastBoughtAt`. Tests: `undoingAClearRestoresPantryState`, `undoingDoneShoppingRestoresPantryState`.
- E5. The put-away basket counts as bought, as today. Tests: `aPutAwayBasketSetsTheItemsIn`.
- E6. `FinishCooking` on the tacos: chicken, onion, tortillas low; cilantro, limes out; staples, optional and to-taste untouched. Tests: `finishingTheTacosSetsLowAndOut` (PA Core 1), `aStapleIsNeverMadeLowByCooking`, `anOptionalLineIsNotUsedUp`.
- E7. Editing or deleting a recipe later does not change the stored state. Tests: `editingARecipeDoesNotRewritePantry`.
- E8. A private recipe still writes state and Tess says nothing. Tests: `aPrivateCookWritesStateAndSaysNothing`.
- E9. The Ingredient cycle goes in, low, out, in; one op per tap; UNDO reverses. Tests: `theStateWordCyclesInLowOutIn`, `eachCycleTapIsOneOpWithItsUndo`.

**V. Voice**
- V1. The OUT shapes in the table set out and add one row, one op. Tests: `outOfMilkSetsOutAndAddsARow`, `weAreOutOfEggsAndRanOutOfRiceAreRead`, `milkIsGoneIsRead`, `noMoreRiceIsRead`.
- V2. Matching is by key equality, never substring. Tests: `outOfOatMilkLeavesMilkAlone`, `outOfTwoPercentMilkFindsMilk`, `outOfMilkChocolateLeavesMilkAlone`, `eggsFindsEgg`.
- V3. Several items are one op. Tests: `outOfMilkAndEggsIsOneOp`, `macAndCheeseIsOneItem`.
- V4. The not-ours list. Tests: `outOfBreathBedAndTimeAreNotClaimed`, `noMoreRepsIsNotClaimed`, `haveACallAt3IsNotClaimed`, `gotAHaircutSatIsNotClaimed`, `theMilkIsOutIsNotClaimed`, `remindMeWeAreOutOfMilkStaysATask`, `outOfMilkThursdayStaysATask`, `outOfFiveIsNotClaimed`, `outOfChalkIsNotClaimed`.
- V5. "have rice" sets in; "got milk" sets in and `lastBoughtAt` (R10). Tests: `haveRiceSetsIn`, `gotMilkSetsInAndTheBoughtDay`, `haveRiceDoesNotTouchTheBoughtDay`.
- V6. The row carries the last typed amount, or none. Tests: `theRowCarriesTheLastTypedAmount`, `aRecipeShareIsNotATypedAmount`, `noTypedAmountMeansNoAmount`.
- V7. Already-there cases. Tests: `alreadyOutAndOnGroceriesAddsNoSecondRow`, `alreadyOutButGoneFromGroceriesAddsTheRow`, `anItemInTheBasketIsLeftAlone`.
- V8. Receipts, exact strings. Tests: `theReceiptNamesTheThingFirstWithOn`, `twoItemsReadMilkAndEggs`, `threeItemsReadMilkAnd2More`, `anAlreadyOnLineReadsAlreadyOnGroceries`.
- V9. Low phrases (R9). Tests: `lowOnRiceSetsLowAndAddsNoRow`.
- V10. "pantry" and "what do i have" open Pantry; with a day word they do not. Tests: `pantryOpensPantry`, `whatDoIHaveOpensPantry`, `whatDoIHaveTomorrowIsTheSchedule`.
- V11. Walls. Tests: `aKeyShapedTailWritesNothing`, `aSecretValueWritesNothing`, `aPriceTailIsStrippedAndNeverSpoken`, `aMedicineOutPhraseReadsPrivateItem` (R7), `aSpendingPhraseIsNotThisRule`.

**U. UNDO**
- U1. 4 s when a row is added, 10 s for a pure state change, 10 s under VoiceOver for both. Tests: `aNewRowReceiptHolds4Seconds`, `aStateChangeHolds10Seconds`, `voiceOverMakesBothTenSeconds` (extends UndoHoldTests.swift).
- U2. UNDO restores state, `stateAt`, `lastBoughtAt` and removes the added row, together. Tests: `undoTakesBackTheStateAndTheRowTogether`.
- U3. One slot: a second receipt replaces the first note and its UNDO; the first op stays done. Tests: `aSecondReceiptReplacesTheFirstUndo`, `theFirstOpStaysInTheLog`.
- U4. The takenBack line for the new receipts. Tests: `takenBackReadsMilkTakenBack`, `takenBackForThreeItemsReadsMilkAnd2MoreTakenBack`, `takenBackForAPrivateItem` (extends UndoCopyTests.swift).
- U5. A no-write line carries no UNDO. Tests: `alreadyOnGroceriesHasNoUndo`.

**M. Missing**
- M1. 0, 1 and "1 to check" for the three seed cases. Tests: `missingGivesZeroOneAndOneToCheck` (PA Core 5).
- M2. Staples never count; one helper. Tests: `aStapleOutDoesNotCount`, `aStapleOnlyRecipeIsCookable`, `anAisleGuideStapleIsAStapleOnTheRecipePage`.
- M3. Optional and to-taste skipped; "as needed" too once parsed. Tests: `anOptionalLineNeverMakesAMissing`, `aToTasteLineNeverMakesAMissing`, `asNeededReadsAsToTaste`.
- M4. Unknown is "to check", low and in are not counted. Tests: `unknownIsToCheckNotMissing`, `lowIsNeverMissing`.
- M5. A line with no ingredient is skipped; one ingredient on two lines counts once. Tests: `aLineWithNoIngredientIsSkipped`, `aRepeatedIngredientCountsOnce`.
- M6. Serves and amounts never change the result. Tests: `scalingNeverChangesWhatIsMissing`.
- M7. Private ingredient label. Tests: `aPrivateIngredientReadsPrivateItemInMissing`, `anIngredientUsedOnlyByPrivateRecipesIsPrivate` (G37).
- M8. Private recipe: counts, no names. Tests: `aPrivateRecipeGivesCountsAndNoNames`.

**C. CAN COOK**
- C1. Ranking: score, then out count, then oldest cook. Tests: `canCookRanksByMissingThenNotCookedLately`, `oneUnknownOutranksOneOut`, `neverCookedComesFirstInATie`.
- C2. "N you can cook now" counts score 0 only. Tests: `theCanCookCountIsScoreZero`.
- C3. Day one: no state anywhere. Tests: `withNoStateTheFilterIsGreyedAndNothingResorts` (Builder B drives; Core exposes `hasAnyState`).
- C4. Recipe with no lines. Tests: `aRecipeWithNoLinesIsNeverCookable`.
- C5. The filter keeps no state beyond the session. Tests: `theFilterIsNotStored`.

**F. Feeds**
- F1. Planning a recipe skips an in line and adds low and unknown ones; the peek count equals the rows added. Tests: `planningSkipsInLinesAndAddsLowAndUnknown`, `theKeyCountEqualsTheRowsAdded`, `paprikaChickenWithThreeKnownStatesGivesAdd6` (D1: chicken in, lemon low, yogurt out, rest unknown; the 7 wanted lines minus chicken = 6; docs/research/fixtures/recipe-clock-steps.md:140-154).
- F2. The new in-cover rule sits after the covered row and the checked row. Tests: `theInRuleComesAfterTheCheckedRowRule`. Re-adding at a bigger size still skips in lines (R19). Tests: `aBiggerSizeStillSkipsInLines`.
- F3. A staple or to-taste line is never offered, whatever its state. Tests: `outStaplesAreNeverAdded`.
- F4. 20-week fixture with the cap at 4 still passes (R unchanged). Tests: existing `usually` 20-week test, re-run.

**P. Privacy**
- P1. No receipt, line, widget or log summary carries a walled name, a price or a body word. Tests: `noPantrySurfaceCarriesAWalledName` (receipts, Tess lines, hero, VoiceOver labels).
- P2. Op summaries for pantry ops are thing-first and masked (GH-11 G106). Tests: `pantryOpSummariesAreMasked`.

### RULING NEEDED, in one list (recommended default first)

| # | Question | Recommended default |
|---|---|---|
| R1 | Backfill the stored state from history on first launch? | Yes, once, `.system`, no UNDO. |
| R2 | Add `stateAt` and `usualSkippedAt` in the same catalog bump? | Yes, both. |
| R3 | Do staples count in missing? | No (KV2 P2/W3); alternative C: only a told-out staple counts. |
| R4 | Optional and "as needed" lines in missing? | Skipped; "as needed" reads as to-taste. |
| R5 | Does unknown count toward the drop in W2? | Yes (W3 as written); alternative: only out drops. |
| R6 | CAN COOK with no state anywhere? | Greyed, no per-row "N to check", tap shows Tess's empty line. |
| R7 | Medicine or body ingredient said as out (P16 says walls first, G92 says state plus a "Private item" row)? | Write state and row, receipt "Private item, out. On Groceries."; secret or price refuse. |
| R8 | Unknown name in "out of X"? | Create only if a known ingredient or the aisle guide knows its head noun; else not ours. |
| R9 | "low on X" phrases? | Include; state only, no row. |
| R10 | Does "got/bought" set `lastBoughtAt`? | Yes; "have" does not. |
| R11 | "what do i have" opens Pantry? | Yes, exact; a day word means the schedule. |
| R12 | Private line tappable (S15 says no; decision 5:16 says tap-to-reveal; G102)? | Not tappable; follows G102 (ruled Oct 17 4:30 PM). |
| R13 | Private recipe in CAN COOK? | Counted, no names, no add. |
| R14 | USUALLY HAVE with exactly 4 names? | All four if they fit one line, else the "and 2 more" form. |
| R15 | First state for an unknown ingredient from the screen? | No tap target (P8); first state comes from Tess, a clear or a cook. |
| R16 | Recipe with no ingredient lines in CAN COOK? | Listed last, never cookable. |
| R17 | A digit in a pantry phrase? | Not ours (except `2%`). |
| R18 | Pantry state in the shared export? | Left out. |
| R19 | In-cover on a bigger-size re-add? | Still skipped (we never compare amounts). |
| R20 | "out of milk" while milk is checked in the basket? | No write, line "Milk, in the basket." |

---

# PART 2. Recipes Next-up: scale and units edge cases in the paste parser

`IngredientLine.parse` is Q135-257; `RecipeMath.scaled` and rounding RM7-44; `quantityText` RM57-69; `kitchenNumber` RM71-87; serves/time/title parsing RP41-206; limits RL7-32. Expected is my reading of the rule stated for the task; where it is a judgment, it says so.

## Case table

| # | Case | Current behavior (read) | Expected | Gap |
|---|---|---|---|---|
| 1 | "1 1/2 cups flour", "1½ cups", "½ cup" | amount 1.5 via mixed-number branch (Q164-166), unicode fractions become " 1/2" first (Q325-337); prints "1½ cups" (RM77, 60-68) | same | PASS |
| 2 | "1-1/2 cups flour" (hyphen mixed number, common in US prints) | group 1 takes "1", the range takes "1/2": amount 1, amountMax 0.5 (Q164); page prints "1–½ cups"; Groceries uses `amountMax ?? amount` = 0.5 | amount 1.5, no range | G109 |
| 3 | "⅕", "⅙", "⅚", "⅐", fraction slash "1⁄2", "1/0" | map has only 9 glyphs (Q325-328); the rest stay as text in the name and the amount is nil; "1⁄2" likewise; "1/0 cup" returns nil from `number` (Q347) but the text is already consumed (Q166-168) so unit is lost and name reads "cup flour"; "1,000 g" reads 1 g (Q342 turns every comma into a point); display of ⅙ prints "0.17" (RM75-86) | read all vulgar fractions and U+2044; a comma followed by exactly 3 digits is thousands; a zero denominator leaves the text alone; add ⅙ ⅕ glyphs or round to the nearest shown | G110 |
| 4 | "2-3 cloves", "2 – 3", "2 to 3" | range read (Q164, `-`, `–`, `to`) | same | PASS |
| 5 | "2 or 3 cloves garlic", "2—3" (em dash), "2-3 inch piece ginger" | "or" and em dash are not range words: amount 2, name "or 3 cloves garlic" (Q164, 173); "inch" is not a unit, so "2–3 inch piece ginger" scales the inches (Q164, 186) | "or" and em dash read as ranges; inch/cm sizes stay in the name | G111 |
| 6 | "a pinch of salt" | `a` + unit word reads amount 1 unit pinch (Q160-162, 186-190), name salt | same | PASS |
| 7 | "pinch of salt", "a pinch", "a dash of hot sauce", "a splash", "one onion", "two eggs", "half an onion", "a couple of eggs", "a few sprigs thyme" | no amount means no unit read (Q186 needs `amount != nil`): "pinch of salt" is a line named "pinch of salt"; "a pinch" alone returns nil (Q249) and the line is dropped; "a dash of ..." reads amount 1 name "dash of hot sauce" (Q169-171); the comment at Q159 says "one" but the code has no number words; "a few sprigs" gives "few sprigs thyme" | "pinch", "dash", "splash", "knob" read as units with amount 1 (or none, kept as written); number words one to twelve, "half", "a couple of" read as amounts | G112 |
| 8 | "salt, to taste", "salt to taste" | toTaste true, name salt (Q142-145); scaling skips it (RM11) | same | PASS |
| 9 | "salt (to taste)", "season to taste", "olive oil, as needed", "salt and pepper, or to taste" | "(to taste)" is deleted by the parenthetical strip (Q205) with `toTaste` false, so it scales and lists; "season to taste" gives name "season"; "as needed" is removed but sets neither flag (Q143: only the exact words "to taste" set it), so Groceries adds it (Gr:462) and CAN COOK would count it | parenthesized, "or to taste" and "as needed" are to-taste | G113 |
| 10 | "1 can (14 oz) diced tomatoes", "1 (14 oz) can ...", "1 14-ounce can" | pack size 14 oz, unit can, name "diced tomatoes" (Q178-197, 261-267) | same | PASS |
| 11 | "1 can (14 oz)" with no name; "1 can (14 oz / 400 g) beans"; "2 cans (14 oz each)" | nameless line returns nil (Q249) and is dropped; "14 oz / 400 g" and "14 oz each" do not match the bracket pattern (Q266 needs the closing parenthesis straight after the unit), so pack size is lost and the parenthetical is deleted (Q205) | keep the first size; a nameless pack line keeps its words as the name | G114 |
| 12 | metric attached or spaced: "200g", "250 ml", "1.5kg", "1 lb", "1½cups" | parsed (Q163-190); `metricText` converts kept-as-written units on tap (Q126-130) | same | PASS |
| 13 | metric text precision | tap shows "28.4 g" for 1 oz and "453.6 g" for 1 lb (`format` allows 1 decimal, Q358-360) | whole grams over 10 (28 g, 454 g) | G115 |
| 14 | mixed units: "1 lb 2 oz potatoes", "1 cup plus 2 tbsp flour", "2 x 400 g tins tomatoes" | first amount and unit win; the rest stays in the name: "2 oz potatoes", "plus 2 tbsp flour", "x 400 g tins tomatoes" (Q186-213). `Transaction.ingredient(named:)` then creates an Ingredient with those words, which pollutes Groceries and the Pantry with junk names (Ingredients.swift:~33-45) | name is the food; the second amount stays in `original`/prep | G116 |
| 15 | "1 cup (240 ml) milk" | cup kept, "(240 ml)" deleted (Q205) | same (page can show original on tap) | PASS (inferred) |
| 16 | unit plurals in `quantityText` | plural when `amountMax ?? amount > 1`: "1 cup", "1½ cups", "½ cup", "2 cloves", "1–2 cloves", "2 bunches", "2 pinches", "2 boxes", invariant "2 tbsp", "2 oz", "2 dozen" (RM57-69) | same | PASS |
| 17 | scale 4 to 2, "8 oz cheese" | whole ounces, floor 1 (RM33-34): 4 oz | same | PASS |
| 18 | scale "1 oz", "3 oz" down by half (also fl oz) | ounces round to whole with a floor of 1: 1 oz stays 1 oz (should be ½), 3 oz becomes 2 oz (should be 1½) (RM33-34) | half-ounce steps under 4 oz, glyph ½ exists | G117 |
| 19 | scale "½ onion", "½ can", "¼ cabbage", "½ dozen" down (unit nil or count unit) | `max(1, value.rounded())` (RM39-42): ½ onion at 4 to 2 serves is 0.25 and becomes "1 onion", four times too many; same for ½ can; Groceries uses these scaled lines (Rc:328-335, Gr:448) | amounts under 1 round to quarter steps with floor ¼ | G118 |
| 20 | scale "⅓ cup" up by 2 | cups round to quarters (RM31-32): 0.667 becomes ¾ though `kitchenNumber` has the ⅔ glyph (RM77-80) | cups also snap to ⅓ and ⅔ | G119 |
| 21 | scale ranges "2–3 cloves", "1–2 tbsp" | each end rounded alone (RM13-14); a collapsed range prints as one number (RM52) | same | PASS |
| 22 | scale a to-taste or no-amount line | unchanged (RM11) | same | PASS |
| 23 | scale by serves 0, or stored serves 0 or nil | `RecipeBook.serves` gives nil (RL12-15, Rc:69), `scaledLines` returns the written lines (Rc:330); `RecipeMath.scaled` also returns them unchanged for 0 or equal sizes (RM8); the drum shows "–" when disabled (PortionDrum.swift:~35) | same | PASS |
| 24 | scale to 1 | factor target/serves, rounded per unit (RM9-16) | same | PASS |
| 25 | scale to a huge size, "Serves 5000" | `RecipeLimits.serves` clamps 1 to 100 (RL8, 14, 19); the drum caps at 100 (PortionDrum.swift:16-19); direct `RecipeMath.scaled` with a huge target does no clamp, but nothing traps (kitchenNumber guards `whole`, RM84, RL29-32) | same | PASS |
| 26 | "Serves 4", "Serves: 2-3", "For 4 people", "Makes 12", "Yield: 4 servings" | meta line, first number wins (RP136-143): 2 for "2-3" | same (low end is the safe choice) | PASS |
| 27 | "Makes 24 cookies", "Makes 2 loaves", "Yields 4", "Feeds 4", "Portions: 6", "Serves 99999999999999999999" | the pattern allows only people/persons/portions/servings after the number and has no "yields", "feeds" (RP139): "Makes 24 cookies" is not meta and falls to ingredient or step; the overflowing number makes `Int(...)` nil (RP142) so the line is junk too | accept a trailing noun up to 3 words; add yields, feeds, portions; an overflow reads as nothing but stays a meta line | G120 |
| 28 | times: "1 hr 15 min", "1.5 hours", "10-12 min", "2 to 3 hours" | parsed (RP196-203) | same | PASS |
| 29 | times: "1 1/2 hours", "1½ hours", "half an hour", "an hour", "3 days", "1 hr 30" | "1 1/2 hours" reads 2 hours (the scan starts at "2", RP196) instead of 90 min; "1½ hours" and "½ hour" read nothing (½ is not a digit); "half an hour", "an hour", "3 days" read nothing (`d` is not a unit); "1 hr 30" reads 60 (the second number needs a unit) | read mixed numbers and fractions, "half an hour", "an hour", days; a bare number after "hr" is minutes | G121 |
| 30 | 48 hours, "100 hours", the 4320 cap | 48 h = 2880 min is kept; anything over 4320 clamps to 4320 (RL9, 25), and over 24 h is read for the clock but never offered as a timer (RP185-190) | same | PASS |
| 31 | first line "2 Eggs", "7 Up Cake", "7 Layer Dip", "30-Minute Dal", "5-Ingredient Chili", "3 bean chili" | any first line whose first character is a digit is "an amount" (`startsWithAmount`, RP171-175), so it is not a title; in unknown mode it becomes an ingredient (RP162-164). All six become "Untitled recipe" plus an ingredient line (e.g. amount 7, name "Layer Dip"; "30-Minute Dal" reads amount 30 and a name beginning "-Minute"). Only "2 Eggs" is right, by luck. Table of the rule below | see the rule below | G122 |
| 32 | a non-first line "7 Up soda" | stays a quantity (IngredientLine.parse) | same | PASS |

### The title-versus-quantity rule (G122; refines GH-11 G94; Product ruling)

On the first line only, and only when no earlier line exists:

1. A digit (or fraction, or mixed number) glued to a word by a hyphen ("30-Minute", "5-Ingredient") is a title.
2. A number followed by a unit word (`KitchenUnit.words`, any case: "2 Tbsp", "1 Cup", "200 g") is a quantity.
3. A number followed by a lowercase word ("2 eggs", "3 large eggs", "3 bean chili") is a quantity. ("3 bean chili" then reads as an ingredient; if Product wants it a title, it needs rule 5.)
4. A number followed by a capitalized word is a quantity only when that word is a known ingredient (`IngredientBook.find` or `AisleGuide.aisle(for:)`, any case): "2 Eggs" is a quantity; "7 Up Cake", "7 Layer Dip", "100 Layer Cake" are titles (inferred: this is how I read "2 Eggs vs 7 Up Cake" in the task).
5. If the paste has an Ingredients heading later and no other title candidate, an ambiguous first line is a title (RULING NEEDED, recommended default: yes).

| First line | Current | Rule |
|---|---|---|
| 2 Eggs | ingredient (right) | quantity (rule 4) |
| 7 Up Cake | ingredient "Up Cake" | title (rule 4) |
| 7 Layer Dip | ingredient "Layer Dip" | title (rule 4) |
| 30-Minute Dal | ingredient | title (rule 1) |
| 5-Ingredient Chili | ingredient | title (rule 1) |
| 3 bean chili | ingredient | quantity (rule 3), title with rule 5 when a heading follows |
| 2 tbsp olive oil | ingredient (right) | quantity (rule 2) |

Tests to write with the fix: `aGluedNumberIsATitle`, `twoEggsIsAQuantity`, `sevenUpCakeIsATitle`, `sevenLayerDipIsATitle`, `aUnitAfterANumberIsAQuantity`, `aLowercaseNounAfterANumberIsAQuantity`.

## Gap list (G109 onward)

- **G109 (important)** Hyphen mixed number "1-1/2 cups" reads as the range 1 to ½ (Q164 regex: the range tail accepts a bare fraction). Page prints "1–½ cups" and Groceries sums ½. Fix: when the right side is a proper fraction smaller than the left and the left is whole, add them. Owner: Core engine.
- **G110 (low)** Fraction coverage: only 9 vulgar fractions (Q325-328; ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ ⅐ ⅑ ⅒ and U+2044 missing), "1/0" eats the text, "1,000 g" reads 1 g, ⅙ prints 0.17 (RM75-86). Fix: complete the map, thousands rule, zero-denominator guard, extra glyphs. Owner: Core engine.
- **G111 (low)** "2 or 3", em dash ranges, and inch/cm sizes inside the amount (Q164, 186). Fix: add `or` and `—` to range words, treat inch and cm as part of the name. Owner: Core engine.
- **G112 (important)** "pinch of salt" with no article, "a pinch" alone (line dropped), "dash/splash/knob", number words, "half", "a couple of" (Q159-172, 186, 249). Fix: unit words readable without an amount, number-word table. Owner: Core engine; Product ruling on whether "a dash" gets a unit (default: a dash/splash unit kept as written, never scaled).
- **G113 (important)** To-taste variants: "(to taste)" silently dropped as a parenthetical and left unflagged, "season to taste" names "season", "as needed" sets no flag (Q142-145, 205). Effects reach Groceries (Gr:462), the ledger (PL:155) and `missing` (clause M3). Fix: flag all three forms; Product ruling that "as needed" equals to-taste. Owner: Core engine.
- **G114 (low)** Pack lines: nameless "1 can (14 oz)" dropped, "14 oz / 400 g" and "14 oz each" lose the size (Q249, 266, 205). Fix: keep first size; fall back to the original words as the name. Owner: Core engine.
- **G115 (low)** Metric tap shows "28.4 g" and "453.6 g" (Q126-130, 358-360). Fix: whole grams above 10, one decimal below. Owner: Builder B screen (text) or Core engine (`format`).
- **G116 (important)** Compound amounts ("1 lb 2 oz", "1 cup plus 2 tbsp", "2 x 400 g") put the second amount in the name and create junk Ingredients (Q186-213; `Transaction.ingredient(named:)`). The junk then appears in Groceries and the Pantry. Fix: strip a leading second amount (and "plus", "+", "x") from the name; keep it in `original`. Owner: Core engine; Product ruling on keeping a second amount (default: no, first amount only).
- **G117 (important)** Ounce and fluid-ounce scaling: whole ounces with a floor of 1 (RM33-34): 1 oz never halves; 3 oz halved is 2 oz (33% over). Fix: half-ounce steps below 4 oz. Owner: Core engine.
- **G118 (important)** A fractional count scales UP: "½ onion", "½ can", "¼ cabbage", "½ dozen" at half the size read "1" (RM39-42; `max(1, value.rounded())`). The scaled lines feed Groceries (Rc:328-335, Gr:448), so the list is wrong too. Fix: for unit nil and count units, an original amount under 1 rounds to quarters with a floor of ¼; test `halfAnOnionAtHalfSizeIsAQuarter`. Owner: Core engine.
- **G119 (low)** Cups snap to quarters only, so ⅓ cup doubled reads ¾, not ⅔ (RM31-32 vs 77-80). Fix: nearest of ¼ ⅓ ½ ⅔ ¾ under 1 cup. Owner: Core engine.
- **G120 (important)** Meta lines: "Makes 24 cookies", "Yields 4", "Feeds 4", "Portions: 6" are not read, and an overflowing number makes the line junk (RP136-143). Fix: allow up to three trailing words, add the keywords, treat overflow as no number. Owner: Core engine.
- **G121 (important)** Durations: "1 1/2 hours" reads 2 hours, "1½ hours" and "½ hour" read nothing, "half an hour", "an hour", "3 days" read nothing, "1 hr 30" loses the 30 (RP196-203). These feed timers and the recipe clock. Fix: mixed-number and fraction support, word numbers, `d` for days (clamped by RL25), bare trailing minutes. Owner: Core engine.
- **G122 (important; refines G94, Product ruling)** The first-line title versus quantity rule above (RP53, 162, 171-175). Owner: Product ruling on rules 3 to 5, then Core engine.

## Counts

Part 1: 8 spec problems (P-F1 to P-F8: 3 important, 5 low), 20 RULING NEEDED items (R1-R20), 124 named tests in 8 clause groups (S, E, V, U, M, C, F, P).
Part 2: 32 cases checked (18 PASS, 14 map to a gap or a rule), 14 gaps G109-G122: 0 blocker, 9 important (G109, G112, G113, G116, G117, G118, G120, G121, G122), 5 low (G110, G111, G114, G115, G119).

## Top 5

1. G118: "½ onion" (and any fractional count) scales UP when the recipe shrinks, and the wrong amount reaches Groceries.
2. P-F1 plus M2: three staple definitions; the recipe page does not dim salt and oil, so CAN COOK and Groceries would disagree with what he sees.
3. R1, R3, R5, R6: four rulings decide whether CAN COOK is useful on a week-old phone (backfill, staples, unknown weight, day one).
4. G122 (with G94): numeric titles ("30-Minute Dal", "7 Layer Dip") lose the title; one agreed rule fixes six cases.
5. G113 and G116: "(to taste)" and "as needed" lines, and compound amounts ("1 lb 2 oz"), write wrong lines and junk Ingredients that would pollute Pantry and CAN COOK.

## Still open

- All of R1-R20 above (Product).
- Whether #407 lands first (the catalog number) and whether a Pantry bump should also carry `usualSkippedAt`.
- The shelf has no filters on master (QUICK, NOT LATELY, CAN COOK); who builds the filter row and the "last cooked" helper.
- Whether a rhythm line ("about every 12 days") needs a kept history beyond the shop-clear ops.
- Exact name of the put-away-basket action and whether it can carry the state write (inferred, I read only `putAwayBasket()` on `Groceries`).
- Tess wording for told states on the Ingredient page ("Out, since you said so on Tuesday.") is proposed, not ruled.

## Phone only

- Haptics on the state-word tap and the swipe; the 4 s versus 10 s UNDO windows and VoiceOver's flat 10 s with real timing.
- Dynamic Type AX sizes: the state word under the name, the sub-line "1 missing: lemons" wrapping, a long Ingredient name.
- Reduce Motion crossfades for the side, the index and the CAN COOK re-sort.
- Whether "out of milk" by voice lands as the same text (speech engine spellings: "out of milk." with the stop, "oat milk" heard as "old milk").
- The recipe page ring and weight on a real recipe, and the greyed CAN COOK word on a fresh install.

# Fixtures: rulings since 4:30 PM PT Oct 17

Source: `product/decisions.md`, entries from 4:30 PM PT on (stamps from 1:41 PM run 1 to 2 hours ahead of PT; see its CLOCK CORRECTION, 3:30 PM entry; every stamp quoted here is as written in the file). Traced against master `b2048d91` (merge of #910). Nothing was built or run; every trace is a read of the source at the file:line shown.

Paths: `RP` = `TesseraCore/Sources/TesseraCore/Kitchen/RecipeParser.swift`, `OP` = `TesseraCore/Sources/TesseraCore/Tess/ObjectPrivacy.swift`, `PF` = `TesseraCore/Sources/TesseraCore/Tess/PrivateFacts.swift`, `PW` = `TesseraCore/Sources/TesseraCore/Export/PrivateWords.swift`, `TM` = `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift`, `PL` = `Features/Kitchen/PantryLedger.swift`.

Status: **traced** = master code gives the expected output (a guard against regression). **gap** = master gives a different output (the row is a failing test until the ruling is built). **inferred** = expected output follows from the ruling by reading, with no master code or no single line to trace; flagged where the ruling itself is unclear.

Owner is the lane named in the ruling, else the lane that owns the file. Test names are proposals in Swift Testing style (`@Test func name`), grouped in the suites named in each section header.

## Which rulings are covered

| Stamp (PT, Oct 17) | Ruling | Section |
|---|---|---|
| 4:30 PM | Pantry v2 R1-R20 accepted; paste edge (ambiguous first line) | A (paste edge), D |
| 4:32 PM | Pantry tie rule, backfill marker, Egg/Eggs fold | D |
| 4:33 PM | Home hero masks O1, O3, PlanWording labels | E |
| 4:35 PM | Core #890 second trim (kg, lb, lbs, kcal, calories, pain, recovery, weight) | C |
| 4:50 PM | titleWords trim answers 1-7 (slept, sleepy, drained; plural; Dr; unit amounts) | C, F |
| 5:57 PM | Pantry front states, "Private item" no reveal | D |
| 5:58 PM | Notes private only when flagged | F |
| 5:59 PM | #886 title rule (two words = amount; unit word at any length = amount; 3+ words no unit = title) | A |
| 6:00 PM | Size words count as unit words | A |
| 6:10 PM | G139 sticky; Dr Pepper raw; "180 pounds today" private | B, C, D |
| 6:39 PM | G177 PE group, G178 no-change tie writes nothing, lastUsedAt | D |

Earlier entries are cited only where a later ruling says "plus the 4:22 rows" (the 4:35 trim) or amends them. The 4:30 PM entries higher in the file (Day log v1, "buy" non-food) sit in an older block of the file and are not in scope.

## A. #886 first-line title rule (suite `RecipeTitleRuleTests`, Core)

Rule as ruled (5:59, 6:00, amending 3:43 and 4:20 PM): a recipe's first line that starts with a number or fraction is an AMOUNT when it is exactly two words, or when a unit word or size word (small, medium, large, extra-large, whole, half) follows the number at any length. Three or more words with no unit or size word are a TITLE. A hyphen joining a number to a letter word ("30-Minute Dal", "5-Spice") stays a title; a digit range ("2-3 eggs") or a mixed number with a unit ("1 14.5 oz can") is an amount (4:25).

Master: `RP:171-175` `startsWithAmount` is true for ANY line whose first character is a number, and `RP:53` then refuses the title. So every "number first" line is an amount on master. Rows that expect a title disagree.

| Id | Input (first line) | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| A1 | `2 eggs` | amount, title "Untitled recipe" | traced | RP:173, RP:53 | Core | `twoWordNumberLineIsAmount` |
| A2 | `2 Eggs` | amount (capitalised second word) | traced | RP:173 | Core | `twoWordCapitalisedIsAmount` |
| A3 | `5 Spice` | amount, "Untitled recipe" (3:43 accepted trade) | traced | RP:173 | Core | `fiveSpiceIsAmount` |
| A4 | `7 Up` | amount, "Untitled recipe" | traced | RP:173 | Core | `sevenUpIsAmount` |
| A5 | `2 large eggs` | amount (size word, 6:00) | traced | RP:173; fragile: becomes a gap if the 3-word title rule lands without the size list | Core | `sizeWordKeepsThreeWordLineAmount` |
| A6 | `500 g plain flour` | amount (unit word, 5:59) | traced | RP:173; same fragility | Core | `unitWordKeepsLongLineAmount` |
| A7 | `2 cups flour` | amount | traced | RP:173 | Core | `cupsFlourIsAmount` |
| A8 | `2 extra-large eggs` | amount (size word with its own hyphen; the hyphen exemption is number-to-letter only) | traced | RP:173; fragile | Core | `extraLargeIsSizeWord` |
| A9 | `1 whole chicken` | amount (size word "whole") | traced | RP:173; fragile | Core | `wholeIsSizeWord` |
| A10 | `6 small potatoes` | amount | traced | RP:173; fragile | Core | `smallIsSizeWord` |
| A11 | `1 egg` | amount | traced | RP:173 | Core | `oneEggIsAmount` |
| A12 | `100 g` | amount (two words) | traced | RP:173 | Core | `gramsLineIsAmount` |
| A13 | `2 tbsp olive oil` | amount (unit word) | traced | RP:173; fragile | Core | `tbspOilIsAmount` |
| A14 | `2-3 eggs` | amount (digit range, 4:25) | traced | RP:173; fragile | Core | `digitRangeIsAmount` |
| A15 | `1 14.5 oz can tomatoes` | amount (mixed number with unit, 4:25) | traced | RP:173; fragile | Core | `mixedNumberUnitIsAmount` |
| A16 | `1/2 cup sugar` | amount (fraction) | traced | RP:173 | Core | `fractionIsAmount` |
| A17 | `A pinch of salt` | amount (existing "a pinch" rule) | traced | RP:174 | Core | `pinchIsAmount` |
| A18 | `3 eggs benedict` | TITLE "3 eggs benedict" | **gap** | master: RP:173 true, so RP:53 skips the title and the recipe is "Untitled recipe" | Core | `threeWordNoUnitIsTitle` |
| A19 | `7 Up Cake` | TITLE | **gap** | RP:173 | Core | `sevenUpCakeIsTitle` |
| A20 | `3 Bean Chili` | TITLE (3 words, "bean" is not a unit or size word) | **gap** (inferred from the rule, not named in a ruling) | RP:173 | Core | `threeBeanChiliIsTitle` |
| A21 | `12 Angry Men Chili` | TITLE (4 words, no unit) | **gap** (inferred) | RP:173 | Core | `fourWordNoUnitIsTitle` |
| A22 | `30-Minute Dal` | TITLE (hyphen joins number to a letter word) | **gap** | RP:173 (first char is a digit) | Core | `hyphenNumberWordIsTitle` |
| A23 | `5-Spice` | TITLE (4:25, 5:59: hyphen stays a title) | **gap** | RP:173 | Core | `fiveHyphenSpiceIsTitle` |
| A24 | `5 Spice` then `Ingredients` heading later, no other title candidate | TITLE "5 Spice" (4:30 paste edge: an ambiguous first line is a title when an Ingredients heading comes later and no other title candidate exists) | **gap**, and the ruling is ambiguous (see Q1) | RP:53 has no look-ahead; `RP:48` sees headings only line by line | Core | `ambiguousFirstLineBecomesTitleBeforeHeading` |
| A25 | `2 Eggs` then `Ingredients` heading later | same question as A24 | **gap**, see Q1 | RP:53 | Core | `twoEggsBeforeHeadingQuestion` |
| A26 | `5 Spice` with NO heading anywhere | amount, "Untitled recipe" (A3 still holds without a heading) | traced | RP:173 | Core | `noHeadingKeepsAmount` |

Where the amount line goes. The 3:43 entry says "Untitled recipe with the line kept as step 1". Master classifies a non-title first line by shape (`RP:56-61`): mode unknown and `looksLikeIngredient` (`RP:162-163`, at most 10 words) makes `2 Eggs` an INGREDIENT, not step 1. The 5:59 and 4:20 entries call it an "amount". Row A27 pins master's behaviour so the question is visible.

| Id | Input | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| A27 | `5 Spice` then `Toast the seeds.` | title "Untitled recipe"; the first line reads as an ingredient (master) or as step 1 (3:43 wording) | **gap or wording gap**, see Q2 | RP:56-61, RP:162-163 | Core | `amountFirstLineKind` |

## B. Dr Pepper and Dr. Patel (suite `PrivateTitleWordsTests`, Core)

Ruled: 4:22 and 4:50 (5), kept at 6:10: "Dr. Pepper" and "Dr Pepper" stay raw. "Dr. Patel" and "Dr Patel" mask by the phrase rule (a "dr" token with a period, or followed by a capitalised name other than Pepper). Bare "dr" is removed from titleWords.

Master has TWO checks. The recipe and Pantry path (`OP:59-63` `isPrivateRecipeTitle`, used by `PL:166`) does not use titleWords. The export, routine-title, list-item and Siri path (`PW:35` `isPrivateTitle`) does, and `PW:29` lists bare "dr".

| Id | Input | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| B1 | recipe title `Dr Pepper` | raw | traced | OP:59-63 (no "dr" rule, no secret/money/body hit) | Core | `drPepperRecipeStaysRaw` |
| B2 | Pantry ingredient `Dr Pepper` | label "Dr Pepper", isPrivate false | traced | PL:166-168 | Core | `drPepperPantryRowStaysRaw` |
| B3 | routine, list item or export title `Dr Pepper` | raw | **gap** | PW:29 has "dr", PW:35 masks it, so the export reads "Private item" and a routine reads "Private workout" (OP:23, WorkoutSummary.swift:45) | Core | `drPepperExportStaysRaw` |
| B4 | the same with a period: `Dr. Pepper` | raw | **gap** | PF `words` (PF:195-199) trims the trailing period, so "dr" matches PW:35 | Core | `drDotPepperStaysRaw` |
| B5 | `Dr. Patel` | masks (list item, routine, export) | traced for the export path only | PW:29, PW:35 (by the bare "dr" token, which the ruling removes; needs the phrase rule once "dr" goes) | Core | `drDotPatelMasks` |
| B6 | `Dr Patel` | masks | traced as B5 | PW:29, PW:35 | Core | `drPatelMasks` |
| B7 | recipe title `Dr Patel` | masks via the one widest check (G140) | **gap** | OP:59-63 has no health-title words | Core | `drPatelRecipeMasks` |
| B8 | `Dr Pepper Cake` | raw (name after "Dr" is Pepper) | **gap** | PW:29 | Core | `drPepperCakeStaysRaw` |
| B9 | `Dr Lee appointment` | masks (capitalised name other than Pepper) | traced (export path) | PW:29 | Core | `drLeeAppointmentMasks` |

## C. titleWords trims (suite `TitleWordsTrimTests`, Core)

Ruled: 4:22 (before the window, quoted because 4:35 says "plus the 4:22 rows"), 4:35, 4:50. Remove from titleWords: blood, heart, energy, sleep, tight, tip, pepper, bare dr, all money words (4:22); kg, lb, lbs, kcal, calories, pain, recovery, weight (4:35); slept, sleepy, drained (4:50 2). Keep: bpm, sore, hurt, sick, tired, burnout, dentist, therapy, rehab, physio, surgery, doctor, clinic, hospital. Plural of a kept word masks; joined words do not (4:50 3). "sick" masks even as slang (4:50 4).

Master: `PW:28-30` unions ALL of `PrivateFacts.moneyWords` (PF:26-31, includes rent, tip, pay, cost, balance, checking, savings) and ALL of `TessMemoryScreen.healthWords` (TM:101-105, includes blood, heart, energy, sleep, tight, pain, recovery, weight, kg, lb, lbs, kcal, calories, slept, sleepy, drained). The matching is exact token equality (PW:35). So the trims have not landed on master, and the export, routine-title, list-item and Siri paths mask all of these. The recipe and Pantry path (OP:59-63) never used titleWords, so it is already raw. Expected output below is for the path that uses titleWords (call it the title check).

| Id | Input title | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| C1 | `blood orange` | raw | **gap** | "blood" in TM:105, PW:35 | Core | `bloodOrangeStaysRaw` |
| C2 | `hearts of palm` | raw | traced | token "hearts" is not "heart" (exact match), PW:35 | Core | `heartsOfPalmStaysRaw` |
| C3 | `heart rate day` | masks (heart rate is a vital, not titleWords) | traced | PF:96 | Core | `heartRateStillMasks` |
| C4 | `energy drink` | raw | **gap** | "energy" in TM:101, PW:35 | Core | `energyDrinkStaysRaw` |
| C5 | `sleep tea` | raw | **gap** | "sleep" in TM:101 | Core | `sleepTeaStaysRaw` |
| C6 | `Rent car` | raw (money masks only with an amount or sign) | **gap** on the title check; traced on OP | "rent" in PF:30, PW:28; OP path raw (PF:48 needs an amount) | Core | `rentCarStaysRaw` |
| C7 | `Rent 1850` | masks (money with an amount) | traced | PF:48 | Core | `rentWithAmountMasks` |
| C8 | `flour 5 kg` | raw | **gap** on the title check | "kg" in TM:104, PW:35; OP path raw (PF:132-135 rest is not day words) | Core | `flourKgStaysRaw` |
| C9 | `ground beef 2 lb` | raw | **gap** on the title check | "lb" in TM:104 | Core | `groundBeefLbStaysRaw` |
| C10 | `pain au chocolat` | raw | **gap** | "pain" in TM:104 | Core | `painAuChocolatStaysRaw` |
| C11 | `recovery shake` | raw | **gap** | "recovery" in TM:102 | Core | `recoveryShakeStaysRaw` |
| C12 | `Weight Watchers chili` | raw | **gap** | "weight" in TM:104 (no number, so PF:128 does not fire) | Core | `weightWatchersChiliStaysRaw` |
| C13 | `drained tuna` | raw | **gap** | "drained" in TM:103 | Core | `drainedTunaStaysRaw` |
| C14 | `sleepy time tea` | raw | **gap** | "sleepy" in TM:101 | Core | `sleepyTimeTeaStaysRaw` |
| C15 | `kcal 200 snack`, `calories` alone as a title | raw (units removed; body-fact rule still catches a real number on a body line) | **gap** | "kcal", "calories" in TM:105 | Core | `kcalCaloriesTitleStaysRaw` |
| C16 | `tired` | masks (kept) | traced | TM:101 | Core | `tiredStillMasks` |
| C17 | `burnout` | masks (kept) | traced | TM:103 | Core | `burnoutStillMasks` |
| C18 | `sick day` | masks (kept) | traced | TM:102, PF:87 | Core | `sickStillMasks` |
| C19 | `sick beat` (slang) | masks anyway (4:50 4, the safe side) | traced for the title check; the body check treats it as slang | TM:102 (title check masks); PF:57-61 (body check skips slang) | Core | `sickSlangStillMasksTitle` |
| C20 | `sore legs` | masks (kept) | traced | TM:102, PF:86 | Core | `soreStillMasks` |
| C21 | `bpm` | masks (kept) | traced | TM:105 | Core | `bpmStillMasks` |
| C22 | `dentist` | masks | traced | PW:29 | Core | `dentistMasks` |
| C23 | `dentists` | masks (plural tolerated, 4:50 3) | **gap** | exact token match, PW:35; "dentists" is not in the set | Core | `pluralDentistMasks` |
| C24 | `dentist-appt` | raw (joined words are one token) | traced | PF `words` keeps the hyphen inside a token (PF:195-199) | Core | `joinedDentistApptStaysRaw` |
| C25 | `therapy`, `rehab`, `physio`, `surgery`, `doctor`, `clinic`, `hospital` (one row each) | masks | traced | PW:29-30 | Core | `keptHealthWordsMask` (parameterised) |
| C26 | note `dentist friday` (unflagged) | see F1 | | | | |

C-rows marked "gap on the title check" mean: raw on the recipe and Pantry path today, masked on the export, routine, list-item and Siri path today. The 4:50 (7) ruling puts Siri read-backs (`Intents.swift:180,205`) on the one check, so they follow the same expected output.

## D. Pantry (suites `PantryPrivacyTests`, `PantryLedgerTests`, `PantryStoredStateTests`; Core with Builder B for the app-side type)

### D1. G139 sticky mask (6:10; blocker text in `ops/board/core.md:407`, pre-review in `qa/prereview-g105b.md:12,18`)

Ruled: a finished cook of a private recipe makes each ingredient it used read "Private item" in Pantry (OUT, LOW and every other place Pantry shows it), with no reveal and no tap target (R12, G102). Sticky: it stays "Private item" even when public recipes also use that ingredient (the safer side), including a later public cook.

Master: `PL:146-161` `cookUses` never looks at the recipe's privacy, and `PL:163-169` `make` masks only when the INGREDIENT'S OWN title is walled. Only `lastCookUsedUp` (`PL:97-100`) refuses a private recipe, and it only withholds the cook line.

| Id | Setup | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| D1.1 | Private recipe "Lexapro curry" (title walled), uses flour and onion; finish the cook | Pantry rows for flour and onion read "Private item"; no names in OUT or LOW | **gap** | PL:146-161 ignores the recipe; PL:166 tests the ingredient title ("flour" is not walled) | Core | `privateCookMasksItsIngredients` |
| D1.2 | As D1.1, then finish a PUBLIC cook that also uses flour | flour still reads "Private item" (sticky) | **gap** | PL:163-169 | Core | `maskIsStickyAfterPublicCook` |
| D1.3 | Public cook only, ingredient flour | flour reads "flour" | traced | PL:166-168 | Core | `publicCookKeepsName` |
| D1.4 | Public cook, then a private-recipe cook | flour reads "Private item" (order does not matter) | **gap** | PL:163-169 | Core | `maskIsOrderIndependent` |
| D1.5 | Private cook used flour, then the cook is deleted (Undo of finish) | inferred: mask clears with the cook (the ruling says "once a private recipe is cooked"; an undone cook never happened). QA flag: pre-review asks if a deleted cook counts | **inferred**, see Q3 | PL:150 reads `store.objects(of: cookClass)`; deleted cooks are not filtered there | Core | `undoneCookClearsMask` |
| D1.6 | Private recipe never cooked, only saved | ingredients read raw (no cook, no mask) | traced | PL:146-161 (no cook, no row) | Core | `uncookedPrivateRecipeLeavesNamesRaw` |
| D1.7 | Ingredient whose own name is walled (a medicine) cooked in a public recipe | "Private item" | traced | PL:166 via OP:59-63 and EngineWall | Core | `walledIngredientNameMasks` |
| D1.8 | Private cook of a recipe with a staple and an optional line | masked rows only for the non-staple, non-optional lines that become low or out (staples and optional lines are skipped, R3, R4) | traced for the skip, **gap** for the mask | PL:155 (skips staple, optional, toTaste) | Core | `privateCookRespectsStaplesAndOptional` |
| D1.9 | Masked row | no reveal path, no tap target (R12, G102) | **inferred** (PantryView.swift:7 says a private name "opens nothing") | Features/Kitchen/PantryView.swift:7 | Builder B | `privateRowHasNoTapTarget` |
| D1.10 | Masked row in the hero count | counted, with no name (R13: a private recipe counted with no names) | traced for a walled name (entries include private rows) | PL:49-51, PL:72-79 | Core | `privateRowStillCounts` |
| D1.11 | Groceries row for flour after a private cook | not specified by the ruling: QA notes Pantry reads "Private item" while Groceries reads "flour" | **inferred**, see Q4 | prereview-g105b.md:18 | Product | `groceriesRowAfterPrivateCook` |
| D1.12 | Tess cook line after a private cook | none; even "Private recipe took ..." is withheld | traced | PL:97-100 | Core | `privateCookGetsNoTessLine` |
| D1.13 | Tap-to-reveal survivor: list shelf private row | no reveal (G102: dropped on all four surfaces) | **gap** | Features/Lists/ListsView.swift:364 still sets the hint "Shows it" | Builder A | `listsShelfHasNoReveal` |

### D2. Pantry v2 state rules (4:30 R1-R20, 4:32, 5:57, 6:39). Master derives state from ops (`PL:115-136`); the stored fields wait for the catalog bump after v10.

| Id | Case | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| D2.1 | Equal timestamp: out vs low vs in | surer wins: out over low over in | traced | PL:132 (`lhs.state > rhs.state` picks the surer) | Core | `tieSurerStateWins` |
| D2.2 | Older timestamp vs newer | newer wins, older never overwrites | traced | PL:131-133 | Core | `olderNeverOverwritesNewer` |
| D2.3 | Egg and Eggs as two ingredient objects | fold to one key through the Groceries normalizer; latest wins, ties by D2.1 | **gap** | PL:115-136 keys by object id; the normalizer is `IngredientLine.key(for:)`, `Quantities.swift:283-290` ("eggs" to "egg") | Core | `duplicateKeysFold` |
| D2.4 | Backfill finishes | Settings key `pantryBackfilled` is set; never inferred from "any ingredient has state" | **gap** | no `pantryBackfilled` anywhere in the repo | Core | `backfillMarkerIsSettingsKey` |
| D2.5 | Backfill with an empty Pantry | runs once, marker set, does not rerun | **gap** | as D2.4 | Core | `emptyPantryBackfillRunsOnce` |
| D2.6 | Staples after a cook | skipped (R3) | traced | PL:155, PL:172-175 | Core | `cookSkipsStaples` |
| D2.7 | Optional or to-taste line in a cook | skipped (R4) | traced | PL:155 | Core | `cookSkipsOptionalLines` |
| D2.8 | "as needed" amount | skipped like optional (R4) | **inferred** (depends on whether the parser sets `toTaste` for "as needed") | PL:155 | Core | `asNeededIsSkipped` |
| D2.9 | "got milk" or "bought milk" | sets lastBoughtAt (R10) | **gap** | PL:81-84, PL:138-143 read only grocery clears and a put-away basket | Core | `gotBoughtSetsLastBoughtAt` |
| D2.10 | "low on eggs" | writes the low state only (R9) | **gap** | no free-text write path in PL | Core | `lowOnWritesStateOnly` |
| D2.11 | Fresh Produce cook | out, not low | traced | PL:158 | Core | `produceCookIsOut` |
| D2.12 | State and lastBoughtAt fields | `stateAt` and `usualSkippedAt` ride the v11 catalog bump with the Habit work, one bump, no renumber (4:30) | **gap** (by design, waits on the bump) | no such fields in SystemCatalog | Core | `pantryFieldsRideV11` |
| D2.13 | Pantry state in the shared export | left out (R18) | **inferred** | export is PW.swift; no Pantry field exists yet so nothing leaks today | Core | `exportOmitsPantryState` |
| D2.14 | Tie that changes nothing (PD31, PE15, PW19) | writes nothing, no receipt, no haptic (6:39 G178) | **gap** (no write path yet) | PL has no writes | Core | `noChangeTieWritesNothing` |
| D2.15 | Peek word "used" | reads the last time a cook finish used the ingredient (`lastUsedAt`, written at cook finish) | **gap** | `lastUsedAt` exists only on TessMemory (SystemCatalog.swift:262), not on ingredients | Core | `usedPeekReadsLastUsedAt` |
| D2.16 | "what do i have" (exact) | opens Pantry (R11) | **inferred** | not traced into the router | Core | `whatDoIHaveOpensPantry` |
| D2.17 | Existing tests to rewrite for stored state | `PantryLedgerTests`, `PantryFrontTests`, `GroceriesFinishTests.undoAfterFinishPutsPantryBack`; hard-code no catalog number | **inferred** | TesseraTests/ | Core | n/a |

## E. Home hero masks (4:33 PM, Research #898) (suite `HomeMaskTests`, Core and Builder A)

| Id | Case | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| E1 | HomeDonePack.build for a private routine or workout (title equals the label or any wall hit) | refuses; no Claude call is ever made; rules wording used | **inferred** (build's refusal is by wall hit) | Home/HomeDonePack.swift:85-107 | Core | `privateRoutineMakesNoClaudeCall` |
| E2 | Private recipe row on Home | "Private recipe, 7 pm." (no count; context at most 6 words and 32 chars) | **gap** | no such string in Home code; "Private recipe, N added." exists for receipts only (RecipePage.swift:545) | Core | `privateRecipeRowDropsCount` |
| E3 | Claude-reworded context over 32 chars | falls back to the rules context | **inferred** | not traced | Core | `longClaudeContextFallsBack` |
| E4 | `PlanWording.privateLabels` | includes "Private workout" and "Private list" | **gap** | PlanWording.swift:39-42 lists note, task, item, recipe, memory only | Core | `privateLabelsGainWorkoutAndList` |
| E5 | NowPage Resume and Start keys and accessibility labels (:52,:54,:74,:75,:86,:88,:299,:300) | read the masked twin (`shownTitle`), never the raw title | **inferred**, not traced here (UI file) | Features/Now | Builder A | `nowPageUsesShownTitle` |

## F. Body words, units, notes, Siri

| Id | Input | Expected | Status | Trace | Owner | Test |
|---|---|---|---|---|---|---|
| F1 | `180 pounds today` (any private-text surface) | PRIVATE, even with the new grocery unit words (6:10) | traced | money-shaped: "180" is an amount and "pounds" is a money word (PF:27, PF:48); also a bare weight: pounds convert at PF:170 and "today" is a day word (PF:67, PF:135) | Core | `bodyWeightPoundsTodayStaysPrivate` |
| F2 | `180 lb today`, `82 kg this morning` | private | traced | PF:134-135, PF:66 | Core | `bodyWeightUnitsStayPrivate` |
| F3 | `1 pound butter` (grocery item or recipe line) | raw (4:50 6: a unit amount never masks a grocery item or recipe) | **gap, top finding** | PF:48: "1" is an amount and "pound" is in moneyWords, so the line is money-shaped and masks | Core | `onePoundButterStaysRaw` |
| F4 | `2 pounds ground beef` | raw | **gap** | PF:27, PF:48 | Core | `poundsBeefStaysRaw` |
| F5 | `1 pound cake` (item) | raw | **gap** | PF:48 | Core | `poundCakeStaysRaw` |
| F6 | `5 kg flour` | raw | traced on the OP path (PF:132-135, rest "flour" is not day words); **gap** on the title check (kg in TM:104) | | Core | `fiveKgFlourStaysRaw` |
| F7 | `2.25 kg rice` (decimal kg) | raw | **gap** | PF:51 treats a two-decimal number as money | Core | `decimalKgStaysRaw` |
| F8 | `1.5 kg potatoes` | raw | traced | one decimal; PF:51 needs exactly two | Core | `oneDecimalKgStaysRaw` |
| F9 | `flour 500 g` | raw | traced | PF:73-75 other units | Core | `gramsStayRaw` |
| F10 | `weigh the flour 500 g` | raw (kitchen, not body) | traced | PF:88-89, PF:129 | Core | `weighFlourIsKitchen` |
| F11 | `my weight 82.4` | private | traced | PF:128-130 | Core | `myWeightIsPrivate` |
| F12 | note, unflagged, `dentist friday` | raw note (no secret/money/body word; titleWords are not applied to notes, 4:50 1) | traced | OP:44-47 | Core | `unflaggedDentistNoteIsRaw` |
| F13 | note, unflagged, `paid 20 for lunch` | 4:50 (1): private (holds money words). 5:58: "only when flagged" | traced to the 4:50 reading; **conflicts with the literal 5:58 wording**, see Q5 | OP:44-47 | Product | `noteWithMoneyWords` |
| F14 | note, flagged | "Private note" | traced | OP:45 | Core | `flaggedNoteIsPrivate` |
| F15 | Siri task read-back for a list, routine or workout name | goes through the one check (4:50 7); tasks keep their own rules | **inferred** | Intents.swift:180,205 | Core | `siriReadbackUsesOneCheck` |

## Questions raised by tracing (for Product)

- Q1. The 4:30 paste edge says "an ambiguous first line is a title when an Ingredients heading comes later and no other title candidate exists". It does not say which lines are ambiguous. If it covers `5 Spice` and `2 Eggs`, then the 3:43 trade ("5 Spice becomes Untitled recipe") only holds for pastes with no heading. Rows A24 to A26 assume "ambiguous" means a two-word number-led line.
- Q2. Is an amount first line kept as step 1 (3:43) or read as an ingredient (master, `RP:56-61`)? The 5:59 and 4:20 wording says "amount".
- Q3. Does an undone or deleted private cook still mask its ingredients (sticky) or clear them (D1.5)?
- Q4. After a private cook, does Groceries keep reading "flour" while Pantry reads "Private item"? The pre-review raised it as a question, and 6:10 says "everywhere in Pantry" only.
- Q5. Notes: 5:58 says "Private note only when flagged" and cites the 4:50 correction, which says flagged or holding secret, money or body words. Master follows 4:50. Which one stands for an unflagged `paid 20 for lunch` note?

## Row counts

| Section | Rows | traced | gap | inferred |
|---|---|---|---|---|
| A. Title rule | 27 | 18 | 9 | 0 |
| B. Dr Pepper | 9 | 5 | 4 | 0 |
| C. titleWords trims | 26 (C26 is a pointer to F12) | 12 | 13 | 0 |
| D1. G139 | 13 | 5 | 5 | 3 |
| D2. Pantry v2 | 17 | 5 | 8 | 4 |
| E. Home masks | 5 | 0 | 2 | 3 |
| F. Body, units, notes | 15 | 9 | 5 | 1 |
| Total | 112 | 54 | 46 | 11 |

Counts treat mixed rows (traced on one path, gap on another) as gap; see each row. Rows are fixtures only; no Swift test is written by this file.

# titleWords after the two trims (4:22 PM PT and 4:35 PM PT): fixture rows

For: Core (engine), Builder B (screens), Product (open questions at the end). Research lab. Docs only; nothing was built or run (no Swift toolchain here). Date: 2026-10-17.

Read on: `origin/master` at `0d81f1a3` (PrivateWords.swift unchanged by #890 there) and PR #890's head `cb360086` (fetched as `refs/pull/890/head`; the GitHub MCP is limited to this repo's slug, so I read the head with `git fetch`). #890 holds ONLY the first trim; the 4:35 PM second trim is not in it. Rows cite `master:file:line` or `pr890:file:line`.

Rulings, in `/mnt/project-files/tessera/product/decisions.md` (stamps are already Pacific): 4:20 PM PT line 951, 4:22 PM PT line 953, 4:25 PM PT line 955, 4:33 PM PT line 959, 4:35 PM PT line 961. QA: `/mnt/project-files/tessera/qa/review-890.md` (verdict at `5052707f`, re-verdict at `cb360086`, whose last paragraph lists the unit/pain/recovery/weight collisions that the 4:35 PM trim then removed).

This file does NOT repeat `decisions-328-332-338.md` (branch `origin/claude/research-decfix`) rows P01 to P28. It EXTENDS P24 to P28: P24 has the six 4:22 phrases, P26 the money words as a group, P27 the kept words as a group, P28 "Dr. Patel". Here: the exact sets, one row per removed word, one per kept word, spelling variants, the surface matrix and the 4:35 rows P24 does not have. Where I disagree with a P row I say so (see T05 and T33).

Row format follows `decisions-328-332-338.md` and `engine-wall.md`: id, plain-words input, exact expected output, Swift Testing name, status, owner. Statuses: **traced** (I read the code path and it does this today; "test" if a test pins it), **inferred** (reasoned from neighbouring code), **gap** (the code does not do this; owner named). "Today" means master and #890 head unless a row says which. Inputs are made-up words; no secret-shaped text appears.

---

## (a) The exact sets

### a1. Before any trim (master)

`PrivateWords.titleWords` = `PrivateFacts.moneyWords` UNION `TessMemoryScreen.healthWords` UNION {rehab, physio, physiotherapy, therapy, therapist, surgery, doctor, dr, dentist, clinic, hospital}. `master:TesseraCore/Sources/TesseraCore/Export/PrivateWords.swift:28-30`; the lookup is `PrivateWords.swift:33-38` (`PrivateFacts.words(title.lowercased()).contains(where: titleWords.contains)`).

- `healthWords` (33 words), `master:TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:101-105`: sleep, slept, sleepy, tired, exhausted, fatigue, energy, rested, recovery, recover, heart, hrv, sore, sick, unwell, drained, burnout, hurts, hurt, ache, aches, pain, tight, weigh, weighed, weight, kg, lb, lbs, bpm, calories, kcal, bmi, blood.
- `moneyWords` (`master:TesseraCore/Sources/TesseraCore/Tess/PrivateFacts.swift:26-31`, which unions `TessMemoryScreen.moneyWords`, `TessMemory.swift:109-111`): $, £, €, dollar, dollars, bucks, paid, spent, cost, price, rent, salary, venmo, paypal, invoice, refund (the memory screen's) plus usd, dollar(s), bucks, buck, gbp, pound, pounds, quid, tenner, fiver, eur, euro, euros, inr, rs, rupee, rupees, cad, aud, chf, jpy, yen, spend, paid, pay, cost, costs, refund, refunded, tip, tipped, venmo, venmoed, zelle, zelled, paypal, owe, owes, balance, checking, savings, salary, paycheck, copay, rent.

### a2. After trim 1 (4:22 PM, line 953) as #890 builds it

`pr890:TesseraCore/Sources/TesseraCore/Tess/ObjectPrivacy.swift:76-79`: `TessMemoryScreen.healthWords.subtracting([blood, heart, energy, sleep, tight, tip, pepper, dr]).union([rehab, physio, physiotherapy, therapy, therapist, surgery, doctor, dentist, clinic, hospital])`. `PrivateWords.titleWords` now forwards to it (`pr890:PrivateWords.swift:28`). Money words are gone entirely (no `moneyWords` union).

Note the subtraction list has two no-ops: "tip" is a money word and "pepper" and "dr" were never in `healthWords`, so `.subtracting` does nothing for them; they leave simply because the union no longer includes `moneyWords` or the explicit "dr" (confirmed by `qa/review-890.md` re-verdict, first bullet). Harmless.

### a3. After trim 2 (4:35 PM, line 961): REMOVE also kg, lb, lbs, kcal, calories, pain, recovery, weight

KEEP per the ruling text: "bpm, sore, hurt, sick, plus dentist, therapy, rehab, physio, surgery, doctor, clinic, hospital and the non-food health words." The ruling names only 4 of the remaining health words explicitly; the rest follow from "non-food health words" and from "REMOVE ... also" naming eight words only. So the kept set is the a2 set minus those eight.

**Kept set after both trims (derived, 31 words):**

| Group | Words |
|---|---|
| Added care words (`ObjectPrivacy.swift:78-79` on #890) | rehab, physio, physiotherapy, therapy, therapist, surgery, doctor, dentist, clinic, hospital |
| Health words still in `healthWords` (`TessMemory.swift:101-105` minus the 13 removed) | slept, sleepy, tired, exhausted, fatigue, rested, recover, hrv, sore, sick, unwell, drained, burnout, hurts, hurt, ache, aches, weigh, weighed, bpm, bmi |

**Removed set, 21 health/everyday words across both trims, plus all money words:**

| Trim | Words (source set) |
|---|---|
| 4:22 | blood, heart, energy, sleep, tight (all `healthWords`); tip (money), pepper (never in a set), dr (was explicit at `master:PrivateWords.swift:29`) |
| 4:22 | all money words: pay, cost, price, balance, checking, savings, rent named by the ruling; "ALL money words" also covers the other 60-odd in a1 (pound, pounds, dollar, dollars, bucks, euro, yen, owe, spend, paid, refund, venmo, salary and so on) |
| 4:35 | kg, lb, lbs, kcal, calories, pain, recovery, weight |

What does NOT change: the other three layers of the one check. `isPrivateTitle` still ORs the title-word lookup with the secret and body-fact wall and `EngineWall.isHealth` (`pr890:ObjectPrivacy.swift:64-69`; `master:PrivateWords.swift:33-38`). So a number plus a unit on a body line, a weigh-in, a medicine and money with an amount all still mask (T20 to T24).

Current state to compare: master = a1. #890 head = a2 (kg, lb, lbs, kcal, calories, pain, recovery, weight are STILL title words there). The second trim is a Core gap on #890 (T10 to T17).

### a4. Scope (4:20 (3), 4:22, 4:25 N2/N3, 4:33)

Apply `titleWords`: list items, list NAMES (N2), recipes, workouts/routines. Do NOT apply: tasks (`pr890:ObjectPrivacy.swift:49-52` calls `PrivateFacts.isPrivateTitle`, no title words), notes (always "Private note", N3), memory (its own wall). "Dr. Patel" stays private (4:22), but see T33: the code has no path that does it once bare "dr" leaves.

---

## (b) Removed words: examples that must now stay raw

Expected for every row: not private on any title-word surface (T-matrix in (e)); shows raw. "Raw" also means no "Private item", "Private recipe", "Private list" or "Private workout" label anywhere (receipts, UNDO, Tess lines, export, Home). Status is split: **#890 head** (first trim) and **second trim** (4:35).

First-trim words (4:22). P24 already holds the six phrases; this is one row per WORD with a second example so a test cannot pass on one phrase.

| Id | Word | Input A (P24 phrase) | Input B (extra) | Why it is a real risk | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|---|
| T01 | blood | "blood orange" | "Blood sausage" (recipe title) | food; `blood` was a title word on master (`TessMemory.swift:105`) | `titleWords_bloodStaysRaw` | traced, test (`pr890:PrivacyParityTests.swift:15`, "blood orange"); B not tested | Core |
| T02 | heart | "hearts of palm" | "Heart of romaine" | "hearts" is NOT a token match for "heart" (exact word lookup), so A passes even on master; B has the exact word "heart" and is the real test | `titleWords_heartStaysRaw` | traced, test for A; B inferred (no heart in `ObjectPrivacy.swift:76-79`). NOTE: P24's "hearts of palm" would have stayed raw on master too (plural). Add B. | Core |
| T03 | energy | "energy drink" | "Energy bar" (list item) | everyday word | `titleWords_energyStaysRaw` | traced, test (`PrivacyParityTests.swift:15`) | Core |
| T04 | sleep | "sleep tea" | "Sleep playlist" (list name) | everyday word | `titleWords_sleepStaysRaw` | traced, test (`PrivacyParityTests.swift:15`) | Core |
| T05 | tight | "Tight shoes" | "Tight hips stretch" (routine) | everyday word. Caution: a routine "Tight hips stretch" is a stretch routine, not a symptom; ruling says never mask on the word alone | `titleWords_tightStaysRaw` | traced (removed from the set at `ObjectPrivacy.swift:77`); no test | Core |
| T06 | tip | "Tip jar" | "Tip calculator" (list name) | `tip` was a money word (`PrivateFacts.swift:29`) | `titleWords_tipStaysRaw` | traced (money words not unioned, `ObjectPrivacy.swift:76`); no test | Core |
| T07 | pepper | "Pepper" (grocery) | "Stuffed pepper" (recipe) | never in a set; guard against someone adding it | `titleWords_pepperStaysRaw` | traced (not in any set) | Core |
| T08 | dr | "Dr Pepper" | "Dr Oetker pizza" | bare "dr" gone | `titleWords_bareDrStaysRaw` | traced, test (`PrivacyParityTests.swift:16`) for A | Core |
| T09 | pay, cost, price, balance, checking, savings, rent (one row each in the test via arguments) | "Pay phone list", "Cost plus", "Price check", "Balance bike", "Checking account", "Savings bonds", "Rent car" | same word with another noun | money masks only with an amount or sign (4:22) | `titleWords_moneyWordAloneStaysRaw` (`@Test(arguments:)` over the seven) | traced for "Rent car" only (`PrivacyParityTests.swift:16`); the other six inferred | Core |

Second-trim words (4:35). The ruling's five rows plus one per word.

| Id | Word | Input (must stay raw) | Why it would mask on #890 head | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T10 | kg | "flour 5 kg" (ruling row), "5 kg rice" | `kg` in `healthWords` (`TessMemory.swift:104`) so the title lookup hits | `titleWords_kgStaysRaw` | gap on #890 head (word still in set). After the trim: traced, see T20 for why the body-fact rule does not catch it (integer, no decimal) | Core |
| T11 | lb | "ground beef 2 lb" (ruling row), "2 lb bag of rice" | `lb` in set (`TessMemory.swift:104`) | `titleWords_lbStaysRaw` | gap on #890 head; raw after trim (T21) | Core |
| T12 | lbs | "10 lbs potatoes" | `lbs` in set (`:104`) | `titleWords_lbsStaysRaw` | gap on #890 head | Core |
| T13 | kcal | "500 kcal bowl" | `kcal` in set (`:105`). Body path already ignores it: `kcal` is in `otherUnits` (`master:PrivateFacts.swift:73-75`) | `titleWords_kcalStaysRaw` | gap on #890 head | Core |
| T14 | calories | "Low calories soup" | `calories` in set (`:105`) | `titleWords_caloriesStaysRaw` | gap on #890 head | Core |
| T15 | pain | "pain au chocolat" (ruling row) | `pain` in set (`:104`) | `titleWords_painStaysRaw` | gap on #890 head. `pain` is not in `symptoms` (`PrivateFacts.swift:84-87`), so nothing else catches it | Core |
| T16 | recovery | "recovery shake" (ruling row) | `recovery` in set (`:102`) | `titleWords_recoveryStaysRaw` | gap on #890 head | Core |
| T17 | weight | "Weight Watchers chili" (ruling row), "Weight Watchers" | `weight` in set (`:104`). Body path needs a number (`PrivateFacts.swift:121` `guard hasNumber`) so no number means raw | `titleWords_weightStaysRaw` | gap on #890 head | Core |

Looks-alikes decided per ruling:

| Id | Input | Decision | Reason | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T18 | "Rent car", "Rent a bike" | raw | "rent" is out; no amount | in T09 | traced, test for "Rent car" | Core |
| T19 | "Rent 2100", "rent car 40" | PRIVATE (money with an amount) | `isMoneyShaped`: amount plus a money word (`PrivateFacts.swift:47-50`). The re-verdict says "rent 2100 stays walled via the amount rule (tested)" (`qa/review-890.md`, re-verdict) | `titleWords_rentWithAmountStaysPrivate` | traced (code); test existence cited by QA, not read | Core |

---

## (c) Kept words: examples that must mask

Expected for every row on the surfaces in the "Masks on" column: the surface's private label ("Private item" for a list or grocery item, "Private list" for a list name, "Private recipe" for a recipe, "Private workout" for a routine or workout title). NOT on tasks (the task keeps its own rules) and NOT per-word on notes. Verify the surface list against (e).

Surfaces for the first column of every row below: **list item, list name, recipe, workout/routine**. Not task, not note path.

| Id | Kept word | Input (must mask) | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|
| T40 | dentist | "dentist", "Dentist cake" | `titleWords_dentistMasks` | traced, test (`pr890:PrivacyParityTests.swift:11`) | Core |
| T41 | therapy | "therapy ideas" | `titleWords_therapyMasks` | traced, test (`PrivacyParityTests.swift:11`) | Core |
| T42 | therapist | "Pay the therapist" (still a health title word per `qa/review-890.md` re-verdict, third bullet) | `titleWords_therapistMasks` | traced (set `ObjectPrivacy.swift:78`) | Core |
| T43 | rehab | "Rehab plan" | `titleWords_rehabMasks` | traced (set); no test | Core |
| T44 | physio, physiotherapy | "Physio exercises", "Physiotherapy" | `titleWords_physioMasks` | traced (set); no test | Core |
| T45 | surgery | "Surgery prep list" | `titleWords_surgeryMasks` | traced (set); no test | Core |
| T46 | doctor | "doctor visit", "Doctor notes" | `titleWords_doctorMasks` | traced (set) | Core |
| T47 | clinic | "clinic run" | `titleWords_clinicMasks` | traced (set) | Core |
| T48 | hospital | "hospital bag" | `titleWords_hospitalMasks` | traced (set) | Core |
| T49 | bpm | "bpm zones" | `titleWords_bpmMasks` | traced (kept in `healthWords`, `TessMemory.swift:105`) | Core |
| T50 | sore | "sore throat lozenges" | `titleWords_soreMasks` | traced | Core |
| T51 | hurt, hurts | "hurt locker" (a film; accepted over-mask) | `titleWords_hurtMasks` | traced | Core |
| T52 | sick | "sick day soup" (see T66: slang is not exempted on this path) | `titleWords_sickMasks` | traced | Core |
| T53 | the other non-food health words (not named by the ruling, kept by derivation): slept, sleepy, tired, exhausted, fatigue, rested, recover, hrv, unwell, burnout, ache, aches, weigh, weighed, bmi | one input each, e.g. "bmi chart", "tired legs stretch" | `titleWords_remainingHealthWordsMask` (`@Test(arguments:)`) | traced (set) / inferred as the ruling's intent; Product to confirm (Q1) | Core |

Reach rows (the NOT paths), all must hold after the change:

| Id | Input | Expected | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|
| T60 | A task "dentist" (via `CreateTask` and the label) | task label path unchanged: reads "Dentist" on Home and receipts, no title-word check. QA already measured this: `qa/review-890.md` section 1, NOT CHANGED, first bullet | `task_titleWordDoesNotMask` | traced (`pr890:ObjectPrivacy.swift:49-52` uses `PrivateFacts.isPrivateTitle`) | Core |
| T61 | A note "dentist friday" | 4:25 N3: "a note is always 'Private note' regardless of words ('dentist friday' is a note, no per-word check)". On code today a plain note is NOT always private: `label(of:)` returns the label only when flagged, titled so, or `isPrivateText` (secret, money, body) (`pr890:ObjectPrivacy.swift:40-44`). So "dentist friday" shows its words | `note_titleWordIsNotACheck` | traced for "no per-word check"; the "always Private note" half is **unclear, see Q2** | Product, Core |
| T62 | Memory with "dentist" | memory keeps its own wall (4:22): `isPrivateText` only (`ObjectPrivacy.swift:45-48`) | `memory_titleWordDoesNotMask` | traced | Core |

---

## (d) Variants (T7 style)

How the lookup tokenises, once, so the rows are checkable. Callers lowercase the text and call `PrivateFacts.words` (`master:PrivateFacts.swift:195-199`): split on anything that is not a letter or digit, except "." "," "-" which stay inside a token; then trim "." "," "-" from each token's ends; empty tokens dropped. Matching is EXACT token equality with the set. So: case folded; surrounding space and punctuation ignored; apostrophe, slash, parenthesis, colon, underscore and non-breaking space split tokens; a hyphen or comma between letters does NOT split; plurals do not match unless listed.

Rows use "dentist" (kept) and "rent" or "blood" (removed). Expected is for a list item; same for the other three surfaces.

| Id | Input | Expected | Why | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T70 | "Dentist", "DENTIST", "dEnTiSt" | mask | lowercase before lookup (`pr890:ObjectPrivacy.swift:66`) | `titleWordVariants_caseFolds` | traced | Core |
| T71 | "  dentist  ", "dentist\n" | mask | `words` drops empties | `titleWordVariants_spacingIgnored` | traced | Core |
| T72 | "dentist.", "dentist!", "(dentist)", "dentist:" | mask | trailing punctuation trimmed or split | `titleWordVariants_punctuationIgnored` | traced | Core |
| T73 | "dentist's cake", "dentist’s cake" (curly) | mask | apostrophe is not a letter, splits to "dentist" and "s" | `titleWordVariants_possessiveMasks` | traced | Core |
| T74 | "dentist/pharmacy", "dentist_appt", "dentist\u{00A0}cake" | mask | slash, underscore, nbsp split | `titleWordVariants_separatorsSplit` | traced (inferred for nbsp: `isLetter` false) | Core |
| T75 | "dentist-appt", "dentist,flowers" | stays raw (no mask) | hyphen and comma stay inside the token, so the token is "dentist-appt" | `titleWordVariants_hyphenAndCommaJoin` | traced; **likely unwanted**, see Q3 | Core, Product |
| T76 | "dentists", "doctors", "surgeries", "therapies", "clinics", "hospitals" | stays raw today | no plural stemming; set holds singular forms only (a few exceptions: hurts, aches, physiotherapy) | `titleWordVariants_pluralsDecided` | traced; Product to decide, see Q3 | Core, Product |
| T77 | "Dentist" as a second item in "Milk, dentist" (a pasted comma line) | per the AddGroceries splitter, each item is judged alone. Not traced here | `titleWordVariants_commaSplitItems` | inferred | Core |
| T78 | "dent ist", "dentistry" | raw | not the word | `titleWordVariants_notTheWord` | traced | Core |
| T79 | Removed words in every variant: "BLOOD ORANGE", "Blood-orange", "blood orange.", "Rent car!", "  rent car " | raw | removed words are not tokens of the set, so no variant can hit | `titleWordVariants_removedWordsStayRaw` | traced after trim | Core |
| T80 | Removed word with a kept word: "blood test at the clinic" | mask (clinic kept) | any kept token masks, whatever else is in the title | `titleWordVariants_oneKeptWordWins` | traced | Core |
| T81 | Digits next to a removed word: "5kg rice", "5 kg rice", "10lbs sugar" | raw | not a title word and not body-shaped (T20, T21) | `titleWordVariants_unitGluedToNumber` | inferred (the body path has a glued-unit regex `PrivateFacts.swift:134`, used only for a bare number with day words) | Core |

---

## (e) Surface matrix

Columns follow the ask: **Groceries**, **Lists**, **Recipes**, **Routines/workouts**, **Home line**, **Siri/Spotlight label**. "mask" = a kept word masks it, "raw" = never masks it, "n/a" = no such object there, "gap" = should mask per ruling but the code path does not ask the one check. Each cell is for a kept word ("Dentist") and, after the slash, a removed word ("Blood orange").

| Surface | Object | Kept word | Removed word | Code path on #890 head | Status | Owner |
|---|---|---|---|---|---|---|
| Groceries | item (typed or recipe-added) | mask "Private item" | raw | `Kitchen/Groceries.swift:645` `ObjectPrivacy.isPrivateWord`; recipe-added at `:561` `isPrivateRecipeTitle`; screen row `Features/Groceries/ShopTrip.swift:18-20` and `:53` | traced (receipt/echo and ShopTrip); the visible Groceries row is `GroceriesView` and I did not trace its text call (inferred) | Core, Builder B |
| Groceries | recipe added to shop | mask "Private recipe" | raw | `Groceries.swift:561` | traced | Core |
| Lists | item | mask "Private item" | raw | `Lists/Lists.swift:281-283` `isPrivateItem` -> `isPrivateWord`; `shownTitle` `:310-312` | traced | Core |
| Lists | list NAME | mask "Private list" | raw | `Lists.swift:145`, `Lists/ListRuns.swift:20`, `Lists/ListReuse.swift:202`, `Processes/ProcessTable.swift:156`, shelf `Features/Lists/ListsShelf.swift:97` (calls the recipe check, which is the one check) | traced (N2 satisfied) | Core |
| Recipes | title on shelf, page, cook, paste | mask "Private recipe" | raw | `ObjectPrivacy.isPrivateRecipeTitle` `ObjectPrivacy.swift:82-84`; `Features/Recipes/RecipesShelf.swift:39`, `RecipePage.swift:584`; `Kitchen/Cooking.swift:96,333` | traced | Core |
| Routines/workouts | routine title | mask "Private workout" | raw | `ObjectPrivacy.routineTitle` `pr890:ObjectPrivacy.swift:22-24` -> `PrivateWords.isPrivateTitle` -> the one check; `Features/Workout/WorkoutSession.swift:31` | traced | Core |
| Routines/workouts | Done hero / summary | mask "Private workout" | raw | `Training/WorkoutSummary.swift:45` | traced | Core |
| Home line | cook line | mask "Private recipe" | raw | `Home/HomeLines.swift:593-600` `cookTitle` -> `ObjectPrivacy.isPrivateTitle` | traced | Core |
| Home line | routine / workout line | mask "Private workout" | raw | `WorkoutSummary.swift:45`; the 4:33 ruling (line 959) says NowPage Resume/Start keys read the masked twin (`shownTitle`); not in #890 | inferred (Builder B scope, #898) | Builder B |
| Home line | task line | raw (task keeps its rules) | raw | `ObjectPrivacy.swift:49-52` | traced | Core |
| Siri / Spotlight label | Siri task read-back | raw (tasks do not use title words) | raw | `TesseraIntents/Intents.swift:180,205` use `PrivateFacts.isPrivateTitle`, no title words | traced | Core |
| Siri / Spotlight label | Siri add-to-list or grocery read-back | **ruling is silent**; the echo goes through `TessCaptureEngine` `:244,:384` (`isPrivateWord`, masks) but the Intents file's own checks at `Intents.swift:180,205` do not | gap / question (Q4) | Core, Product |
| Siri / Spotlight label | Spotlight index entry for a list item or recipe | no `CSSearchable` code found in `*.swift` outside tests, so there is nothing to mask today. The pantry doc comment says "what any view, Tess line, widget or Spotlight shows: the name, or 'Private item'" (`Features/Kitchen/PantryLedger.swift:41`) | gap (not built); expected "Private item" | Core |
| Export | all of the above | mask (same function) | raw | `PrivateWords.swift:33-35`, `:104`, `:170` | traced | Core |

---

## (f) Rows that tie the sets to the body, money and medicine walls

These pin what must STILL mask once the eight 4:35 words leave. The ruling says "the body-fact rule still catches real weigh-ins and numbers with units on body lines."

| Id | Input | Expected | Trace | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T20 | "flour 5 kg" with a last weight of 78.0 kg | raw | `isBareWeight`: number 5 not within 10% of 78; `bodyWord` (kg) true but needs a decimal `\d[.,]\d` (`PrivateFacts.swift:188-189`), none. Words path: no weigh word; `rest` = ["flour"] is not all day words (`:135`) so false | `bodyWall_integerKgGroceryStaysRaw` | traced (code) | Core |
| T21 | "ground beef 2 lb" | raw | same as T20 (no decimal, rest not day words) | `bodyWall_integerLbGroceryStaysRaw` | traced (code) | Core |
| T22 | "rice 2.5 kg", "chicken 1.5 lb" | **masks** today (after the trim too) | `bodyWord` true plus decimal (`PrivateFacts.swift:188-189`); the title-word trim does not touch it. This is a real grocery. The ruling's test rows use integers; decimals are untested | `bodyWall_decimalKgGroceryDecision` | traced (code); **Q5** | Core, Product |
| T23 | "my weight is 82.4", "weighed 82.4 kg this morning" | mask | `weighWords` branch (`PrivateFacts.swift:128-130`) | `bodyWall_realWeighInStillMasks` | traced | Core |
| T24 | "log weight 78" with a last weight near 78 | mask | within 10% of the last weight (`:185`) | `bodyWall_bareWeightInBandStillMasks` | traced | Core |
| T25 | "weighed flour 500 g" | raw | kitchen unit exemption (`:129`) | `bodyWall_kitchenWeighStaysRaw` | traced | Core |
| T26 | "bmi 24", "bpm 60" | mask | `bmi` in `bodyWords` (`:70`), `bpm` in vitals (`:76-77`) with a number | `bodyWall_vitalsStillMask` | traced | Core |
| T27 | "advil", "take melatonin" | mask | `EngineWall.isHealth` (`EngineWall.swift:48-56`) | `bodyWall_medicineStillMasks` | traced, test (`PrivacyParityTests.swift:11`) | Core |
| T28 | "rent 2100", "paid 40 for gas", "coffee 6.25" | mask | money with an amount (`PrivateFacts.swift:36-52`) | `moneyWall_amountStillMasks` | traced, test for first two (`PrivacyParityTests.swift:11-12`) | Core |
| T29 | "500 kcal bowl" with an amount | raw | `kcal` in `otherUnits` (`PrivateFacts.swift:73-75`); not a money word | `bodyWall_kcalBowlStaysRaw` | traced | Core |

### Money-word collisions that remain outside titleWords

`isMoneyShaped` (`PrivateFacts.swift:47-50`) masks an amount beside a money word. Money words stay in that wall by ruling, but several are food and shop words:

| Id | Input | Expected today | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|
| T30 | "1 pound butter", "2 pounds apples", "pound cake 2" | masks (amount 1 plus money word "pound") | `moneyWall_poundGroceryDecision` | traced (code); the 4:22/4:35 rulings do not mention it; **Q6** | Core, Product |
| T31 | "2 tip jars", "3 balance bikes" | masks (amount plus "tip"/"balance") | `moneyWall_amountPlusEverydayWord` | traced (code); same question | Core, Product |
| T32 | "Euro trip 2" | masks | same | traced | Core, Product |

### Dr. as a title prefix

| Id | Input | Expected per 4:22 | Trace | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T33 | "Dr. Patel" | PRIVATE ("still masks via the doctor/clinic phrases") | `PrivateFacts.words("dr. patel")` gives ["dr","patel"]; "dr" is not in the new set (`ObjectPrivacy.swift:77`); no other part of the one check reads "dr". I found no "phrase" code in `ObjectPrivacy.swift` or `PrivateWords.swift`; the only other "dr" in `TesseraCore/Sources` is in `Home/HomeDonePack.swift:118` (a Claude-bound off-limits list, not the screen wall). So today "Dr. Patel" is **raw** on #890 head, and master masked it only because bare "dr" was a title word (`master:PrivateWords.swift:29`). P28 in `decisions-328-332-338.md` calls this "inferred"; I trace it as a **gap** | `drPrefix_drDotPatelMasks` | gap | Core (needs a phrase rule: "dr" token followed by a name, not "dr pepper" and not "dr oetker") |
| T34 | "Dr Patel" (no dot) | private, same ruling intent | same trace | `drPrefix_drPatelMasks` | gap | Core |
| T35 | "Dr Pepper", "Dr Oetker" | raw | no rule | `drPrefix_drPepperStaysRaw` | traced, test for "Dr Pepper" | Core |
| T36 | "Dr. Patel" as a list name | private | same as T33 | `drPrefix_listNameMasks` | gap | Core |

---

## Status summary

| Bucket | Rows |
|---|---|
| Traced, with a test on #890 head | T01 (A), T02 (A), T03, T04, T08 (A), T09 ("Rent car"), T40, T41, T27, T28 (two of three) |
| Traced in code, no test | T05, T06, T07, T09 (six other words), T42 to T52, T60, T62, T70 to T76, T78 to T80, T20, T21, T25 to T26, T29, T29, matrix rows |
| Inferred | T02 (B), T53 (Product intent), T77, T81, Groceries screen row, Home routine line |
| Gap | T10 to T17 (second trim not in #890), T33, T34, T36 (Dr prefix), Siri add-to-list read-back, Spotlight index (not built) |

## Gaps by owner

**Core**
1. Land the 4:35 PM second trim in `ObjectPrivacy.titleWords` (`pr890:ObjectPrivacy.swift:76-79`): subtract kg, lb, lbs, kcal, calories, pain, recovery, weight. T10 to T17. Add the five test rows from the ruling ("flour 5 kg", "ground beef 2 lb", "pain au chocolat", "recovery shake", "Weight Watchers chili") to `PrivacyParityTests.plain` (`:14-17`), plus "500 kcal bowl".
2. The two no-ops in the subtraction list ("pepper", "dr", and "tip" which only left because the money union left) are harmless, but a test per word (T05 to T09) is what actually keeps them out. Add them; `PrivacyParityTests` has only 6 of the 22 removed words as rows.
3. "Dr. Patel" has no masking path now that bare "dr" is gone (T33 to T36). 4:22 says it "still masks via the doctor/clinic phrases"; no such phrase code exists. Needs a small rule (a "dr" token followed by a capitalised name, not Pepper/Oetker) or a Product change to the ruling.
4. T22 and T30 to T32: decimal-weight groceries ("2.5 kg rice") and "pound"-as-unit groceries ("1 pound butter") still mask through the body and money walls, which the title-word trims do not touch.
5. `Intents.swift:180,205` use `PrivateFacts.isPrivateTitle` (no title words). Decide with Product whether Siri read-backs for list items and recipes go through the one check (Q4).
6. T61: note "always Private note" vs the code (Q2).
7. Tests for the surfaces not covered: list NAME shelf (`ListsShelf.swift:97`), routine title (`ObjectPrivacy.routineTitle`), Home cook line (`HomeLines.swift:599`).

**Builder B**
1. Screens: the ShopTrip/Lists/RecipePage/Groceries calls already go through the core function (`ShopTrip.swift:18-20`, `ListsShelf.swift:97`, `RecipePage.swift:584`, `RecipesShelf.swift:39`). Verify the visible `GroceriesView` row text and the Done/Resume keys (4:33) on a phone check after Core lands: one grocery row ("Blood orange" raw), one list name ("Dentist" private), one routine. `qa/review-890.md` also asks for this phone check.

**Product** (see below)

## Open questions for Product

- **Q1.** The 4:35 PM ruling names only bpm, sore, hurt, sick as kept health words. After both trims 15 more `healthWords` remain by derivation: slept, sleepy, tired, exhausted, fatigue, rested, recover, hrv, unwell, drained, burnout, ache, aches, weigh, weighed, bmi (16 counting both ache forms). Some collide with food or everyday titles: "drained" ("Drained tuna", "Drained chickpeas"), "rested" ("Rested dough"), "tired" ("Tired legs stretch"), "burnout" (a game or playlist list), "sleepy" ("Sleepy time tea", sibling of the removed "sleep tea"). Keep all, or trim "drained", "rested", "sleepy", "tired", "burnout" too?
- **Q2.** 4:20 (3) and 4:25 N3 say "notes are always 'Private note'" and also "no per-word check". On code a note shows its words unless flagged or it has a secret, money or a body fact (`ObjectPrivacy.swift:40-44`). Does "always" mean every note displays as "Private note" (a bigger change than any trim), or only that titleWords never decide a note?
- **Q3.** Variants: should "dentists", "doctors", "therapies", "hospitals" (plurals) and "dentist-appt" or "dentist,flowers" mask? Today they do not, because matching is exact-token (T75, T76).
- **Q4.** Siri and Spotlight: should a Siri add to a list or recipe read back "Private item" for a kept title word? `Intents.swift:180,205` do not ask the one check, and no Spotlight index exists yet. 4:20 (3) names only items, recipes, workouts, and list names.
- **Q5.** "rice 2.5 kg" and "chicken 1.5 lb": a grocery with a decimal weight masks through the body-fact rule even after the 4:35 trim. The ruling said the body rule "still catches real weigh-ins and numbers with units on body lines", but a grocery line is not a body line. Exempt grocery items (or list items with a food word) from the decimal-plus-unit path, or accept?
- **Q6.** "1 pound butter", "2 pounds apples": the money wall (not titleWords) masks an amount beside "pound" (T30). "All money words leave titleWords" does not reach `isMoneyShaped`. Should `pound(s)` count as money only beside a currency sign, "gbp" or "quid"?
- **Q7.** "sick": the body wall exempts slang ("sick of rice", "sick beat", `PrivateFacts.swift:57-61`) but the title-word lookup does not, so "sick beat" playlist or "Sick day soup" masks. Intended?
- **Q8.** "Dr. Patel" (T33): Product wrote "still masks via the doctor/clinic phrases" but no such phrase rule exists. Is a new rule wanted, or should the ruling read "Dr Patel stays raw unless a doctor/clinic word is also in the title"?

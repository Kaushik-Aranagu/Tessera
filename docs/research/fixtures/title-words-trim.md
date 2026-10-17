# titleWords after the three trims (4:22, 4:35 and 4:50 PM PT): fixture rows

For: Core (engine), Builder B (screens), Product (open questions at the end). Research lab. Docs only; nothing was built or run (no Swift toolchain here). Date: 2026-10-17. Updated for the 4:50 PM PT answers (decisions.md line 963); every changed row carries the stamp "4:50 PM PT".

Read on: `origin/master` at `0d81f1a3` (PrivateWords.swift unchanged by #890 there) and PR #890's head `cb360086` (fetched as `refs/pull/890/head`; the GitHub MCP is limited to this repo's slug, so I read the head with `git fetch`). #890 (head `398090688939`, in the Release 14 queue, not yet merged) already has the 4:35 PM second trim; only the 4:50 PM third trim (slept, sleepy, drained) is not in it. Rows cite `master:file:line` or `pr890:file:line`.

Rulings, in `/mnt/project-files/tessera/product/decisions.md` (stamps are already Pacific): 4:20 PM PT line 951, 4:22 PM PT line 953, 4:25 PM PT line 955, 4:33 PM PT line 959, 4:35 PM PT line 961, 4:50 PM PT line 963 ("Research #899 title-words-trim, answers; corrects 4:20 #3"). QA: `/mnt/project-files/tessera/qa/review-890.md` (verdict at `5052707f`, re-verdict at `cb360086`, whose last paragraph lists the unit/pain/recovery/weight collisions that the 4:35 PM trim then removed).

This file does NOT repeat `decisions-328-332-338.md` (branch `origin/claude/research-decfix`) rows P01 to P28. It EXTENDS P24 to P28: P24 has the six 4:22 phrases, P26 the money words as a group, P27 the kept words as a group, P28 "Dr. Patel". Here: the exact sets, one row per removed word, one per kept word, spelling variants, the surface matrix and the 4:35 rows P24 does not have. Where I disagree with a P row I say so (see T05). 4:50 PM PT corrects P16 (notes) and settles P28 ("Dr. Patel": a phrase rule, Core builds it) in the `research-decfix` branch; this file carries the same answers.

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

### a3. After trim 2 (4:35 PM, line 961): REMOVE also kg, lb, lbs, kcal, calories, pain, recovery, weight. After trim 3 (4:50 PM, line 963): REMOVE also slept, sleepy, drained (keep tired, burnout)

KEEP per the ruling text: "bpm, sore, hurt, sick, plus dentist, therapy, rehab, physio, surgery, doctor, clinic, hospital and the non-food health words." The ruling names only 4 of the remaining health words explicitly; the rest follow from "non-food health words" and from "REMOVE ... also" naming eight words only. So the kept set is the a2 set minus those eight. 4:50 PM PT (2) names three more to remove (slept, sleepy, drained) and two to keep (tired, burnout), so the kept set below is minus eleven.

**Kept set after all three trims (derived, 28 words; 4:50 PM PT):**

| Group | Words |
|---|---|
| Added care words (`ObjectPrivacy.swift:78-79` on #890) | rehab, physio, physiotherapy, therapy, therapist, surgery, doctor, dentist, clinic, hospital |
| Health words still in `healthWords` (`TessMemory.swift:101-105` minus the 16 removed: 5 + 8 + 3) | tired, exhausted, fatigue, rested, recover, hrv, sore, sick, unwell, burnout, hurts, hurt, ache, aches, weigh, weighed, bpm, bmi (18) |

**Removed set across the three trims, plus all money words:**

| Trim | Words (source set) |
|---|---|
| 4:22 | blood, heart, energy, sleep, tight (all `healthWords`); tip (money), pepper (never in a set), dr (was explicit at `master:PrivateWords.swift:29`) |
| 4:22 | all money words: pay, cost, price, balance, checking, savings, rent named by the ruling; "ALL money words" also covers the other 60-odd in a1 (pound, pounds, dollar, dollars, bucks, euro, yen, owe, spend, paid, refund, venmo, salary and so on) |
| 4:35 | kg, lb, lbs, kcal, calories, pain, recovery, weight |
| 4:50 PM PT | slept, sleepy, drained ("drained tuna", "sleepy time tea" stay raw); tired and burnout are KEPT |

What does NOT change: the other three layers of the one check. `isPrivateTitle` still ORs the title-word lookup with the secret and body-fact wall and `EngineWall.isHealth` (`pr890:ObjectPrivacy.swift:64-69`; `master:PrivateWords.swift:33-38`). So a number plus a unit on a body line, a weigh-in, a medicine and money with an amount all still mask (T20 to T24).

Current state to compare: master = a1. #890 head `398090688939` = a2 plus the 4:35 PM second trim (kg, lb, lbs, kcal, calories, pain, recovery, weight are already subtracted there; slept, sleepy, drained are still title words). The 4:50 PM PT third trim (T17a to T17c) is a Core gap on both.

### a4. Scope (4:20 (3), 4:22, 4:25 N2/N3, 4:33)

Apply `titleWords`: list items, list NAMES (N2), recipes, workouts/routines. Do NOT apply: tasks (`pr890:ObjectPrivacy.swift:49-52` calls `PrivateFacts.isPrivateTitle`, no title words), notes (4:50 PM PT corrects 4:20 (3) and 4:25 N3: a note is "Private note" only when flagged private or it holds secret, money or body words, NOT always, and never by a title word), memory (its own wall). "Dr. Patel" and "Dr Patel" mask through a phrase rule that Core builds (4:50 PM PT (5)); see T33 to T36.

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
| T08 | dr | "Dr Pepper" | "Dr Oetker pizza" (4:50 PM PT: ruled only for Pepper; the phrase rule masks "dr" plus a capitalized name other than Pepper, so Oetker is an open edge, see Q3) | bare "dr" gone | `titleWords_bareDrStaysRaw` | traced, test (`PrivacyParityTests.swift:16`) for A | Core |
| T09 | pay, cost, price, balance, checking, savings, rent (one row each in the test via arguments) | "Pay phone list", "Cost plus", "Price check", "Balance bike", "Checking account", "Savings bonds", "Rent car" | same word with another noun | money masks only with an amount or sign (4:22) | `titleWords_moneyWordAloneStaysRaw` (`@Test(arguments:)` over the seven) | traced for "Rent car" only (`PrivacyParityTests.swift:16`); the other six inferred | Core |

Second-trim words (4:35). The ruling's five rows plus one per word.

| Id | Word | Input (must stay raw) | Why it would mask on #890 head | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T10 | kg | "flour 5 kg" (ruling row), "5 kg rice" | `kg` in `healthWords` (`TessMemory.swift:104`) so the title lookup hits | `titleWords_kgStaysRaw` | traced on #890 head `398090688939` (4:35 trim already there; on master the word is still in the set). See T20 for why the body-fact rule does not catch it (integer, no decimal) | Core |
| T11 | lb | "ground beef 2 lb" (ruling row), "2 lb bag of rice" | `lb` in set (`TessMemory.swift:104`) | `titleWords_lbStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there; T21) | Core |
| T12 | lbs | "10 lbs potatoes" | `lbs` in set (`:104`) | `titleWords_lbsStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there) | Core |
| T13 | kcal | "500 kcal bowl" | `kcal` in set (`:105`). Body path already ignores it: `kcal` is in `otherUnits` (`master:PrivateFacts.swift:73-75`) | `titleWords_kcalStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there) | Core |
| T14 | calories | "Low calories soup" | `calories` in set (`:105`) | `titleWords_caloriesStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there) | Core |
| T15 | pain | "pain au chocolat" (ruling row) | `pain` in set (`:104`) | `titleWords_painStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there). `pain` is not in `symptoms` (`PrivateFacts.swift:84-87`), so nothing else catches it | Core |
| T16 | recovery | "recovery shake" (ruling row) | `recovery` in set (`:102`) | `titleWords_recoveryStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there) | Core |
| T17 | weight | "Weight Watchers chili" (ruling row), "Weight Watchers" | `weight` in set (`:104`). Body path needs a number (`PrivateFacts.swift:121` `guard hasNumber`) so no number means raw | `titleWords_weightStaysRaw` | raw on #890 head `398090688939` (4:35 trim already there) | Core |

Third-trim words (4:50 PM PT (2)). Ruled: REMOVE slept, sleepy, drained; keep tired, burnout.

| Id | Word | Input (must stay raw) | Why it would mask on #890 head | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T17a | slept | "Slept-in brunch list", "slept" as a list name | `slept` in `healthWords` (`TessMemory.swift:101`) | `titleWords_sleptStaysRaw` | gap on #890 head and master (word still in set); 4:50 PM PT | Core |
| T17b | sleepy | "Sleepy time tea" (ruling row), "Sleepy Joe's pizza" | `sleepy` in set (`:101`) | `titleWords_sleepyStaysRaw` | gap on #890 head and master; 4:50 PM PT | Core |
| T17c | drained | "Drained tuna" (ruling row), "Drained chickpeas" | `drained` in set (`:103`) | `titleWords_drainedStaysRaw` | gap on #890 head and master; 4:50 PM PT | Core |
| T17d | tired, burnout (KEPT, must still mask) | "Tired legs stretch" (routine), "Burnout playlist" (list name) | kept by ruling | `titleWords_tiredAndBurnoutStillMask` | traced (stay in set); 4:50 PM PT | Core |

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
| T52 | sick | "sick day soup", "Sick beat" (playlist). 4:50 PM PT (4): "sick" keeps masking, slang included (no exemption in titleWords; the safe side) | `titleWords_sickMasksIncludingSlang` | traced (set has no slang exemption; the body wall exempts slang at `PrivateFacts.swift:57-61` but titleWords does not use it); 4:50 PM PT | Core |
| T53 | the other non-food health words (kept by derivation, and by the 4:50 PM PT ruling for tired and burnout): tired, exhausted, fatigue, rested, recover, hrv, unwell, burnout, ache, aches, weigh, weighed, bmi. slept, sleepy and drained are NOT here any more (T17a to T17c) | one input each, e.g. "bmi chart", "tired legs stretch", "burnout playlist" | `titleWords_remainingHealthWordsMask` (`@Test(arguments:)`) | traced (set); tired and burnout ruled 4:50 PM PT; "rested" still open (Q1) | Core |

Reach rows (the NOT paths), all must hold after the change:

| Id | Input | Expected | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|
| T60 | A task "dentist" (via `CreateTask` and the label) | task label path unchanged: reads "Dentist" on Home and receipts, no title-word check. QA already measured this: `qa/review-890.md` section 1, NOT CHANGED, first bullet | `task_titleWordDoesNotMask` | traced (`pr890:ObjectPrivacy.swift:49-52` uses `PrivateFacts.isPrivateTitle`) | Core |
| T61 | A note "dentist friday" (4:50 PM PT (1), CORRECTION of 4:20 (3) and 4:25 N3 "always Private note") | A note reads "Private note" only when flagged private, or when its text holds secret, money or body words (the standing decision). It is NOT always private, and no title word is ever checked on a note. So "dentist friday" shows its words; a flagged note, a note with a money amount and a note with a body fact read "Private note" | `note_privateOnlyWhenFlaggedOrWalledNeverByTitleWord` | traced: `label(of:)` returns the label only when flagged, titled so, or `isPrivateText` (`pr890:ObjectPrivacy.swift:40-44`). Risk after Core composes the one function: the note branch must NOT call the title-word version. 4:50 PM PT | Core |
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
| T75 | "dentist-appt", "dentist,flowers" | stays raw (no mask). 4:50 PM PT (3): joined words are NOT matched ("dentist-appt" stays raw). The comma case is the same class by the same tokenizer rule (my reading) | hyphen and comma stay inside the token, so the token is "dentist-appt" | `titleWordVariants_joinedWordsStayRaw` | traced (exact-token match does this today); ruled 4:50 PM PT, so no longer "likely unwanted"; Core must keep it when it adds plural tolerance | Core |
| T76 | "dentists" (ruling row), "doctors", "surgeries", "therapies", "clinics", "hospitals" | MASK. 4:50 PM PT (3): matching tolerates a plural. Plural tolerance applies to KEPT words only, so "hearts of palm" and "bloods" stay raw because the word is out of the set (T02) | today no plural stemming; set holds singular forms only (a few exceptions: hurts, aches, physiotherapy) | `titleWordVariants_pluralMasks` | gap (today these stay raw); Core adds s / es / ies tolerance (the ruling says "a plural"; the y to ies pair "surgeries", "therapies" is my reading of it). 4:50 PM PT | Core |
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
| Siri / Spotlight label | Siri task read-back | raw (tasks keep their own rules; 4:50 PM PT (7) does not change them) | raw | `TesseraIntents/Intents.swift:180,205` use `PrivateFacts.isPrivateTitle`, no title words | traced | Core |
| Siri / Spotlight label | Siri read-back of a routine, workout or list NAME (and a list item or recipe where Siri reads one) | 4:50 PM PT (7): Siri read-backs at `TesseraIntents/Intents.swift:180,205` go through the one check too. Tasks keep their own rules, so for tasks nothing changes; the new work is the title mask ("Private workout", "Private list", "Private item", "Private recipe") for a kept title word. The capture echo already masks (`TessCaptureEngine` `:244,:384`, `isPrivateWord`); the Intents file's own checks do not | gap (Intents call `PrivateFacts.isPrivateTitle`, no title words); ruled 4:50 PM PT, no longer a question | Core |
| Siri / Spotlight label | Spotlight index entry for a list item or recipe | no `CSSearchable` code found in `*.swift` outside tests, so there is nothing to mask today. The pantry doc comment says "what any view, Tess line, widget or Spotlight shows: the name, or 'Private item'" (`Features/Kitchen/PantryLedger.swift:41`) | gap (not built); expected "Private item" | Core |
| Export | all of the above | mask (same function) | raw | `PrivateWords.swift:33-35`, `:104`, `:170` | traced | Core |

---

## (f) Rows that tie the sets to the body, money and medicine walls

These pin what must STILL mask once the eight 4:35 words leave. The ruling says "the body-fact rule still catches real weigh-ins and numbers with units on body lines."

| Id | Input | Expected | Trace | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T20 | "flour 5 kg" with a last weight of 78.0 kg | raw | `isBareWeight`: number 5 not within 10% of 78; `bodyWord` (kg) true but needs a decimal `\d[.,]\d` (`PrivateFacts.swift:188-189`), none. Words path: no weigh word; `rest` = ["flour"] is not all day words (`:135`) so false | `bodyWall_integerKgGroceryStaysRaw` | traced (code) | Core |
| T21 | "ground beef 2 lb" | raw | same as T20 (no decimal, rest not day words) | `bodyWall_integerLbGroceryStaysRaw` | traced (code) | Core |
| T22 | "rice 2.5 kg", "chicken 1.5 lb" as a grocery or list item, or a recipe line | RAW. 4:50 PM PT (6): body-fact and money rules never mask a grocery item or recipe because of a unit amount (decimal kg included); they apply to body/money lines only. The one-check words and secret words still apply | `bodyWord` true plus decimal (`PrivateFacts.swift:188-189`) masks it today; the title-word trim does not touch that | `bodyWall_decimalKgGroceryStaysRaw` | gap (masks today, even after both trims); ruled 4:50 PM PT, Q5 deleted. Core: skip the body-shaped and money-shaped tests on the grocery, list-item and recipe surfaces when the text is an amount of a thing | Core |
| T22a | "weighed 82.4 kg this morning" typed as a NOTE or a task | still masks (a body line) | `weighWords` branch | `bodyWall_decimalKgOnABodyLineStillMasks` | traced; 4:50 PM PT guard row so the grocery exemption is not too wide | Core |
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
| T30 | "1 pound butter", "2 pounds apples" as a grocery or list item | RAW. 4:50 PM PT (6): the money rule never masks a grocery item for a unit amount ("1 pound butter") | `moneyWall_poundUnitGroceryStaysRaw` | gap (masks today: amount 1 plus money word "pound", `PrivateFacts.swift:47-50`); ruled 4:50 PM PT | Core |
| T31 | "2 tip jars", "3 balance bikes", "pound cake 2" | masks today (amount plus "tip"/"balance"/"pound"). These are not unit amounts, so 4:50 PM PT (6) does not reach them | `moneyWall_amountPlusEverydayWord` | traced (code); still open, see Q2 | Core, Product |
| T32 | "Euro trip 2" | masks | same | traced; still open, see Q2 | Core, Product |

### Dr. as a title prefix

| Id | Input | Expected per 4:22 | Trace | Swift Testing name | Status | Owner |
|---|---|---|---|---|---|---|
| T33 | "Dr. Patel" | PRIVATE. 4:50 PM PT (5): a "dr" token with a period, or a "dr" token followed by a capitalized name other than Pepper, masks. It is a phrase rule and Core builds it. (Product's 4:22 wording "via the doctor/clinic phrases" is replaced by this) | `PrivateFacts.words("dr. patel")` gives ["dr","patel"]; "dr" is not in the new set (`ObjectPrivacy.swift:77`); no other part of the one check reads "dr". I found no "phrase" code in `ObjectPrivacy.swift` or `PrivateWords.swift`; the only other "dr" in `TesseraCore/Sources` is in `Home/HomeDonePack.swift:118` (a Claude-bound off-limits list, not the screen wall). So today "Dr. Patel" is **raw** on #890 head, and master masked it only because bare "dr" was a title word (`master:PrivateWords.swift:29`). P28 in `decisions-328-332-338.md` called this "inferred"; I trace it as a **gap**, now ruled | `drPrefix_drDotPatelMasks` | gap, ruled 4:50 PM PT | Core builds the phrase rule. The lookup lowercases first (`ObjectPrivacy.swift:66`), so the rule must read the original-case title to see a capitalized name |
| T34 | "Dr Patel" (no dot) | PRIVATE (a "dr" token followed by a capitalized name other than Pepper), 4:50 PM PT (5) | same trace | `drPrefix_drPatelMasks` | gap, ruled 4:50 PM PT | Core |
| T35 | "Dr Pepper" | raw. 4:50 PM PT (5): the phrase rule excludes Pepper. ("Dr Oetker" and "Dr. Pepper" with a period are not ruled, see Q3.) | no rule yet; must stay raw once the phrase rule lands | `drPrefix_drPepperStaysRaw` | traced today, test (`PrivacyParityTests.swift:16`); keeps holding after the phrase rule | Core |
| T36 | "Dr. Patel" as a list name, a recipe title and a routine title | private on every title-word surface ("Private list", "Private recipe", "Private workout"); not on tasks or notes | same as T33 | `drPrefix_listNameMasks` | gap, ruled 4:50 PM PT | Core |

---

## Status summary

| Bucket | Rows |
|---|---|
| Traced, with a test on #890 head | T01 (A), T02 (A), T03, T04, T08 (A), T09 ("Rent car"), T40, T41, T27, T28 (two of three) |
| Traced in code, no test | T05, T06, T07, T09 (six other words), T42 to T52, T60, T62, T70 to T75, T78 to T80, T20, T21, T25 to T26, T29, T22a, T35, T17d, matrix rows |
| Inferred | T02 (B), T77, T81, Groceries screen row, Home routine line |
| Gap | T17a to T17c (third trim, 4:50 PM PT), T22 and T30 (grocery unit amounts, 4:50 PM PT), T76 (plurals, 4:50 PM PT), T33, T34, T36 (Dr phrase rule, ruled 4:50 PM PT), Siri read-backs (Intents, 4:50 PM PT (7)), Spotlight index (not built) |

## Gaps by owner

**Core**
1. Land the 4:35 PM second trim in `ObjectPrivacy.titleWords` (`pr890:ObjectPrivacy.swift:76-79`): subtract kg, lb, lbs, kcal, calories, pain, recovery, weight (T10 to T17; #890 head `398090688939` already has it, so this lands with #890). Add the five test rows from the ruling ("flour 5 kg", "ground beef 2 lb", "pain au chocolat", "recovery shake", "Weight Watchers chili") to `PrivacyParityTests.plain` (`:14-17`), plus "500 kcal bowl".
2. 4:50 PM PT third trim: also subtract slept, sleepy, drained; keep tired and burnout (T17a to T17d). Rows "Drained tuna" and "Sleepy time tea" stay raw.
3. 4:50 PM PT matching: tolerate a plural of a KEPT word ("dentists" masks, T76); do not match joined words ("dentist-appt" stays raw, T75); "sick" keeps masking including slang (T52).
4. 4:50 PM PT phrase rule: "Dr. Patel" and "Dr Patel" mask (a "dr" token with a period, or followed by a capitalized name other than Pepper); "Dr Pepper" stays raw (T33 to T36). Needs the original-case title, not the lowercased one.
5. 4:50 PM PT (6): body-fact and money rules never mask a grocery item, list item or recipe because of a unit amount: "5 kg flour", "1 pound butter", "rice 2.5 kg", "chicken 1.5 lb" stay raw (T20 to T22, T30). Body and money lines (notes, "weighed 82.4 kg") still mask (T22a, T23, T28).
6. 4:50 PM PT (7): Siri read-backs at `Intents.swift:180,205` go through the one check for routine, workout and list names (and items, recipes); tasks keep their own rules.
7. 4:50 PM PT (1): notes are NOT always "Private note"; only flagged, or secret, money or body words, and no title-word check (T61). Make sure the composed one function is not called from the note branch.
8. The two no-ops in the subtraction list ("pepper", "dr", and "tip" which only left because the money union left) are harmless, but a test per word (T05 to T09) is what actually keeps them out. Add them; `PrivacyParityTests` has only 6 of the removed words as rows.
9. Tests for the surfaces not covered: list NAME shelf (`ListsShelf.swift:97`), routine title (`ObjectPrivacy.routineTitle`), Home cook line (`HomeLines.swift:599`).

**Builder B**
1. Screens: the ShopTrip/Lists/RecipePage/Groceries calls already go through the core function (`ShopTrip.swift:18-20`, `ListsShelf.swift:97`, `RecipePage.swift:584`, `RecipesShelf.swift:39`). Verify the visible `GroceriesView` row text and the Done/Resume keys (4:33) on a phone check after Core lands: one grocery row ("Blood orange" raw), one list name ("Dentist" private), one routine. `qa/review-890.md` also asks for this phone check.

**Product** (see below)

## Open questions for Product

Answered at 4:50 PM PT (line 963) and deleted: notes "always Private note" (corrected, T61), plurals and joined words (T75, T76), the Siri and Spotlight read-back question for Siri (T-matrix; Spotlight has no index yet), decimal-weight groceries, "pound" as a unit, "sick" slang, "Dr. Patel", and the drained, sleepy, slept, tired, burnout part of the old Q1. Still open:

- **Q1.** "rested" ("Rested dough") and the other kept words the 4:50 PM PT ruling did not name (exhausted, fatigue, recover, unwell, ache, aches, weigh, weighed, hrv, bmi): keep all (this file's reading), or trim "rested" too?
- **Q2.** Money wall beside everyday words that are NOT unit amounts: "2 tip jars", "3 balance bikes", "pound cake 2", "Euro trip 2" mask through the money wall (T31, T32). 4:50 PM PT (6) covers only unit amounts. Accept?
- **Q3.** The "Dr" phrase rule as worded (a "dr" token with a period, or followed by a capitalized name other than Pepper) also masks "Dr Oetker pizza" and "Dr. Pepper" with a period. Intended, or add Oetker and "Dr. Pepper" to the exclusions? (T08, T35.)

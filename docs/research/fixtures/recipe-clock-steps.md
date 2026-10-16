# Recipe clock: step-timing vectors and demo recipes (Design 69)

*Kitchen lead, 2026-10-16. The fixture behind the two rulings in `docs/product/cook-mode-acceptance.md` ("The recipe clock"): which steps count as timed, and the peek key's count. Core's 69 slice (a start and end minute per step, one timer per timed step, the used set per minute) and Builder B's `RecipeClockView` both test against it. Lanes are later; the lane column says what the overlap rule in `kitchen-v2-backlog.md` will give when they come, so nothing has to be re-derived then.*

## The rules in one place

- **Timed** = `RecipeParser.durations(in:)` finds a duration in the step's own text. Minutes = the sum of the lower bounds. "a side", "per side", "each side" double that duration (new parser work, Core). "overnight" counts as 8 hours (one word added to the parser, Core). Nothing else times a step.
- **Untimed** = 2 minutes on the clock, a short span, no minutes shown, no timer.
- **Under 1 minute** (seconds) = timed, a timer, the countdown in seconds; drawn at the 2-minute floor.
- **Over 3 hours** = timed, drawn at a fixed 10-minute width with its minutes in hours ("12 HR"), no countdown, no timer. The cook is not running through it; whether the cook stays live over it is cook mode's idle rule (45 min).
- **Start minute** (this build, one lane) = the end of the previous step; the first step starts at 0. The key row's "N MIN LEFT" = remaining timed minutes + untimed floors ahead, the fixed-width waits excluded.
- **Lane later** = a step opening with a cue ("meanwhile", "while the", "while that", "as the", "in the meantime", "at the same time", "during this time") starts at its host's start minute on lane 2 when the host has a wait of 5 minutes or more; a cue-less step starts at the join of the live lanes.
- **Used** (for the peek's dimming and skip) = an ingredient is used from the start minute of the first step whose text names it.
- **Peek count** = the new-row count `AddRecipeToGroceries` would return, as a dry run against the list as it stands: staples, "to taste", optional / for serving / for garnish lines and covered lines skipped; during a cook, used lines skipped too.

## Single-step vectors

| # | Step text | `durations` (min) | Minutes | Timed | Shown | Timer |
|---|---|---|---|---|---|---|
| s1 | Simmer 20 min. | [20] | 20 | yes | 20 MIN | yes |
| s2 | Simmer for 10-15 minutes. | [10...15] | 10 | yes | 10 MIN | yes |
| s3 | Cook until golden. | [] | 2 (floor) | no | nothing | no |
| s4 | Preheat the oven to 425°F. | [] (no unit after 425) | 2 (floor) | no | nothing | no |
| s5 | Sear 3 min a side. | [3], doubled | 6 | yes | 6 MIN | yes |
| s6 | Sear 3 min a side, then 10 min in the oven. | [3, 10], first doubled | 16 | yes | 16 MIN | yes |
| s7 | Braise 1 hr 15 min. | [75] | 75 | yes | 1 HR 15 MIN | yes |
| s8 | Bake covered for 30 minutes, then uncovered for 15 minutes, until deep brown. | [30, 15] | 45 | yes | 45 MIN | yes |
| s9 | Chill for 2 hours. | [120] | 120 | yes | 2 HR | yes |
| s10 | Chill for 4 hours. | [240] | over 3 h | yes | 4 HR, fixed width | no |
| s11 | Rest overnight. | [480] (new word) | over 3 h | yes | 8 HR, fixed width | no |
| s12 | Cover and let it rise overnight, 12 to 18 hours. | [480, 720...1080] | over 3 h | yes | 12 HR, fixed width (the written range wins over the word) | no |
| s13 | Microwave 30 seconds. | [0.5] | 0.5 (drawn at 2) | yes | 30 SEC | yes |
| s14 | Let stand 5 minutes. | [5] | 5 | yes | 5 MIN | yes |
| s15 | Step 3. Simmer 20 min | [20] (numbering stripped) | 20 | yes | 20 MIN | yes |
| s16 | Cook time: 20 min | not a step (a time line) | | | | |
| s17 | Meanwhile, chop the herbs. | [] | 2 (floor) | no | nothing | no (lane 2 later) |

Display forms (MIN, HR, SEC) are Design's; the numbers are the rule.

## Demo recipe D1: Paprika chicken (the clip's recipe, 45 MIN)

Paste text (Builder B seeds it or pastes it; the counts below are what the engine must give):

```
Paprika chicken
Serves 4
1½ lb chicken thighs
1 tbsp smoked paprika
1 lemon
3 cloves garlic
1 lb baby potatoes
1 red onion
½ cup Greek yogurt
2 tbsp olive oil
Kosher salt and black pepper, to taste
Fresh parsley, for serving
Method
1. Heat the oven to 425°F. Halve the potatoes and toss with oil and salt.
2. Roast the potatoes for 15 minutes.
3. Meanwhile, rub the chicken with paprika, garlic and lemon zest.
4. Add the chicken and onion to the pan and roast for 20 minutes, until the skin is crisp.
5. Stir the yogurt with lemon juice and a pinch of salt.
6. Rest the chicken for 4 minutes, then serve with the yogurt.
```

| Step | Minutes | Timed | Start (one lane) | End | Lane later |
|---|---|---|---|---|---|
| 1 Heat the oven, halve the potatoes | 2 | no | 0 | 2 | 1 |
| 2 Roast the potatoes 15 min | 15 | yes | 2 | 17 | 1 |
| 3 Meanwhile, rub the chicken | 2 | no | 17 | 19 | 2, start 2 (host: step 2) |
| 4 Chicken and onion in, roast 20 min | 20 | yes | 19 | 39 | 1 |
| 5 Stir the yogurt | 2 | no | 39 | 41 | 1 (no cue; the model may pair it with step 4) |
| 6 Rest 4 min | 4 | yes | 41 | 45 | 1 |

Key row at rest: "45 MIN". At 12 minutes in: step 2 lit with "5 MIN", key row "33 MIN LEFT" (sheet 69's numbers). At 20 minutes in: step 4 lit with "19 MIN", "25 MIN LEFT". Short name "Chicken". Done: "Paprika chicken, cooked."

Used from: potatoes 0; olive oil, salt 0 (staples); chicken, paprika, garlic, lemon 17; onion 19; yogurt 39; parsley never (optional line, not on the list).

## Demo recipe D2: Garlic butter shrimp pasta (ranges, "until", per side; 16 MIN)

```
Garlic butter shrimp pasta
Serves 2
8 oz spaghetti
1 lb shrimp, peeled
4 cloves garlic
4 tbsp butter
1 lemon
¼ cup parsley, chopped
Red pepper flakes, to taste
Parmesan, for serving
Salt
Method
1. Bring a large pot of salted water to the boil.
2. Cook the spaghetti for 8-10 minutes, until al dente.
3. While the pasta cooks, melt the butter and cook the garlic until golden, about 2 minutes.
4. Add the shrimp and sear 1 minute a side.
5. Toss in the drained pasta with the parsley and lemon juice and cook until glossy.
```

| Step | Minutes | Timed | Start (one lane) | End | Lane later |
|---|---|---|---|---|---|
| 1 Water to the boil | 2 | no | 0 | 2 | 1 |
| 2 Spaghetti 8-10 min | 8 | yes (lower bound) | 2 | 10 | 1 |
| 3 While the pasta cooks, garlic, about 2 minutes | 2 | yes (the number, not the "until") | 10 | 12 | 2, start 2 (host: step 2) |
| 4 Shrimp 1 minute a side | 2 | yes (doubled) | 12 | 14 | 1 |
| 5 Toss, until glossy | 2 | no | 14 | 16 | 1 |

Key row "16 MIN". Short name "Pasta". Done: "Garlic butter shrimp pasta, cooked."

## Demo recipe D3: No-knead bread (an overnight wait; 2 HR 47 MIN of running time)

```
No-knead bread
Serves 8
3 cups bread flour
¼ tsp instant yeast
1½ tsp salt
1½ cups water
Method
1. Stir the flour, yeast, salt and water into a shaggy dough.
2. Cover and let it rise overnight, 12 to 18 hours.
3. Heat the oven to 450°F with the pot inside for 30 minutes.
4. Shape the dough and let it rest 30 minutes.
5. Bake covered for 30 minutes, then uncovered for 15 minutes, until deep brown.
6. Cool for 1 hour before slicing.
```

| Step | Minutes | Timed | Drawn start | Drawn end | Countdown | Lane later |
|---|---|---|---|---|---|---|
| 1 Stir the dough | 2 | no | 0 | 2 | no | 1 |
| 2 Rise overnight, 12 to 18 hours | 720 (over 3 h) | yes | 2 | 12 (fixed 10) | no, "12 HR" | 1 |
| 3 Oven with the pot, 30 min | 30 | yes | 12 | 42 | yes | 1 |
| 4 Shape, rest 30 min | 30 | yes | 42 | 72 | yes | 1 (no cue; the model may pair it with step 3) |
| 5 Bake 30 + 15 | 45 | yes | 72 | 117 | yes | 1 |
| 6 Cool 1 hour | 60 | yes | 117 | 177 | yes | 1 |

Key row at rest: the running minutes without the fixed wait, 167 ("2 HR 47 MIN"); the wait shows only on its own step. Short name "Bread". Done: "No-knead bread, cooked."

## Peek counts (dry runs of the same add)

List state A: Groceries empty. State B: typed bare rows "lemon" and "garlic" open, a "butter" row checked. State C: state A during a cook of D1 at 20 minutes in.

| Recipe | State | Skipped (never counted) | Covered or used (not new) | Key word | Receipt |
|---|---|---|---|---|---|
| D1 | A | olive oil, kosher salt and black pepper (staples, to taste), parsley (for serving) | none | ADD 7 TO GROCERIES | Chicken, 7 added. |
| D1 | B | same | lemon and garlic join the open rows (they get "for chicken" under them, no new row) | ADD 5 TO GROCERIES | Chicken, 5 added. |
| D1 | C | same | potatoes, chicken, paprika, garlic, lemon, onion used by minute 20 | ADD 1 TO GROCERIES (Greek yogurt) | Chicken, 1 added. |
| D2 | A | red pepper flakes (to taste), parmesan (for serving), salt (staple) | none | ADD 6 TO GROCERIES | Pasta, 6 added. |
| D2 | B | same | lemon and garlic join; the checked butter covers | ADD 3 TO GROCERIES (spaghetti, shrimp, parsley) | Pasta, 3 added. |
| D3 | A | salt, water (staples) | none | ADD 2 TO GROCERIES | Bread, 2 added. |
| D3 | after planning D3 | same | both rows already on the list for it (covered) | key word absent | nothing said |

The key word and the receipt come from the same dry run, never from two counts. UNDO on the receipt removes exactly the new rows (`RemoveRecipeFromGroceries`); joined rows keep their recipe line removal as today.

## Done when

- Core: `swift test` gives every row of the single-step table and the three recipes' start and end minutes; "per side" doubling and "overnight" are in the parser; the used set at D1 minute 20 is the six lines above; the three peek dry runs give 7, 5, 1, 6, 3, 2 and absent.
- Builder B: the clip (`docs/recordings/recipe-clock.mp4`) is D1: COOK, step 2 lit with its countdown, "33 MIN LEFT" at 12 minutes (use `-demoTime` or a shortened fixture), the peek in and out with "ADD 7 TO GROCERIES" and "Chicken, 7 added.", the last step, hold DONE, "Paprika chicken, cooked."

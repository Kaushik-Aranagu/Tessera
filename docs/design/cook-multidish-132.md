# Item 132: Cook with several dishes, one merged queue (Oct 22)

Design sheet for Builder A (cook screens), after landing v2. Engine: Core's
product/kitchen-multidish-money-pools-engine-spec-oct22.md part A (CookSession, CookDish,
backward plan from serve time, handsCap 1, holdMax 15 min). Ideas: Kitchen app page
HCTX67y4CsoKPjvpybH63D, "Cooking several dishes". Lives inside landing v2 (sheet 131,
Kitchen: A's time spine moves into Cook) and app character (sheet 127, Kitchen ochre
#E0A458 dark / #A8701F light, the level line). Where this sheet and the engine spec
differ on words, this sheet wins; on numbers, the spec wins.

Review switches (default Off, from the spec): multiDishCook, serveTimeAlign. With both Off,
Cook is exactly today's single-recipe Cook.

## 1. What he sees, in one line
One pair of hands gets one next thing. Several dishes run as one queue on one clock,
backward from the serve time, so they finish together. The page never shows a column
per dish.

## 2. Cook page, running (the merged queue)
```
 < Kitchen                                   step 7 of 14
 ________________ __ ____________________________________   <- progress strip, one
                                                               segment per step, all dishes
 Rice                                                       <- dish word, small, ink 2
 Rinse the rice                                             <- the step, large (title weight)
 until the water runs clear

 On the stove
 12:10   Chicken, oven                                      <- soonest timer, ochre
  6:00   Beans, blanch
 Rice starts in 3 min.                                      <- the one warning, plain ink 2

 Then
 Rice, add water and cover
 Beans, trim and saute                                      <- fainter

 Done                                         I am behind
 ----                                                       <- ochre underline, the action
```
- The step is the largest thing. The dish word sits above it, small, so he always knows
  which pot he is at. Dish words are plain ink, never colour-coded per dish.
- Progress strip: one segment per step across every dish, done in ink, current in ochre,
  left in ink 3. It is the level line (Kitchen's one line kind) used as progress.
- On the stove: at most three timers, soonest first, then "2 more" (spec A4.9). The soonest
  is ochre and rolls digit by digit; the rest are ink. Each names its dish and vessel.
- Then: the next two hands steps only, dish word first. Waits are not listed here; they
  live on the stove.
- One warning line at most, ink 2, from the spec's sentences: "Rice starts in 3 min.",
  "Serving about 7:02.", "Rice will wait 6 min.". Never red, never two lines.
- Done (ochre underline) advances; "I am behind" is an ink word on the right.

## 3. The plan before starting (the time spine)
A's time spine from the landing picks lives here, as the first screen of a multi-dish cook,
and again one swipe left from the running page as a peek.
```
 < Kitchen                                      Tonight
 Serve at 7:00                                  <- Outfit numerals, the serve time
 Start chicken at 6:17.                         <- spec serve line, ink

 6:17  Chicken      ====------------------------..     <- hands = ink, wait = ink 3,
 6:40  Rice                 ==------------..              hold = dotted
 6:46  Beans                        ===  ==
                                                 | 7:00
 Beans start 6 min early so your hands are free.       <- moved line, ink 2
 Rice will wait 6 min.                                  <- held line, ink 2

 Start                                   Change the plan
 -----
```
- One row per dish: start time, dish word, its bar. Hands spans are thick ink, waits are
  thin ink 3, a hold is a dotted tail into the serve line. These are level lines, not bars
  in boxes; no fills, no lane backgrounds.
- The serve time is one thin vertical rule at the right with "7:00" above it.
- The spec's moved and held sentences sit under the spine, one each, ink 2.
- Over hold (spec A4.5): "Rice would wait 22 min." and the ink word "Start later", which
  tries the next fit. Nothing is dropped.
- No serve time set: the top reads "Ready about 7:12" and the spine starts at now.
- Start (ochre underline) begins the session; the first step opens the running page.

## 4. Change the plan (a sheet, not a new page)
Opened by "Change the plan" or a long press on the serve time.
- Serve at: the serve time is a number instrument. Swipe up or down to step 5 min, tap to
  type (sheet 131 section 2b: numbers are instruments). Earlier and Later as ink words.
- Each dish: dish word on the left, how it finishes on the right as a word he can swipe
  through: "on time", "holds warm 15", "last, no waiting". (B from the ideas page; the
  engine uses holdMax per session today, so per-dish finish is a Core ask, Off until then.)
- Add a dish: the ink word "Add a dish" opens Recipes in pick mode. Mid-cook it follows spec
  A4.7 and may show "Serving about 7:10."
- Every change shows its one consequence first, ink 2: "Rice now starts 6:35, 5 min
  earlier." Then Keep (ochre underline) or Not now.
- Receipts in the Tess corner with 10 s Undo, spec words: "Serve at 7:15." "Beans, added."

## 5. "I am behind"
One ink word on the running page. Tapping it opens three lines, each with its consequence,
and he taps one:
- "Serve at 7:10" (moves the serve time, replans unstarted steps)
- "Rice holds warm 10 more" (only when a dish can hold)
- "5 more minutes on this step" (spec A4.6, moves later steps by 5)
Nothing shames: no "late", no counts, no red. A running timer is never moved. After a pick,
the warning line updates and a receipt with Undo appears.

## 6. Landing hooks (sheet 131, Kitchen)
- Planned, not started: the Kitchen sentence uses the spec template: "Tacos and rice
  tonight, start at 6:05." Recipes' today row shows both dishes.
- Running: the one line above both doors: "Cooking tacos and rice, 8 min left. Go on",
  Go on opens the running page on the current step. n is the soonest timer.
- Private recipe: "Private recipe" in place of its title, everywhere, Live Activity and
  Lock Screen included.

## 7. Live Activity and Lock Screen
- One cook at a time. The next hands step ("Rice, rinse") and the soonest timer with "+2"
  for the others. Ochre only on the soonest timer. Private recipes masked.

## 8. Motion and haptics (MotionPolicy only)
- Advance: the step slides up and out, the next rises in, settle spring; Reduce Motion is a
  crossfade.
- A timer ending: one ochre pulse on its numerals, one haptic; same-second ends share one
  haptic (spec A4.9).
- Replan: start times roll digit by digit; the spine bars glide to their new place.

## 9. Keep every element feature (sheet 131 section 2b)
Single-recipe Cook today has (Builder A lists the full set before replacing): step swipe and
Done, timers with pause, "5 more minutes", servings drum, unit swipe in amounts, Live
Activity, haptics, screen kept on, Reduce Motion, AX5. All stay. At AX5 the stove lines
stack the dish word under the numerals and Then shows one line.

## 10. Words
Serve at, Start, Done, Then, On the stove, I am behind, Change the plan, Keep, Not now,
Start later, Add a dish, Go on. Sentence case. Time as "1 hr 35 min". No "record". No food
drawings. No per-dish colours.
Grammar: the spec template "{Dish} starts {n} min early" needs plural agreement for plural
dish words ("Beans start ..."); Core adds a plural flag on the dish word or the template
rewords to "{Dish}: start {n} min early so your hands are free."

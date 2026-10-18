# The recipe clock (Design item 69)

**Kaushik's principle, in one line:** C is the base, the recipe laid on time; the step he is on is lit, steps that happen at once are drawn side by side, and B's whole ingredient list is one swipe away.

His pick of sheet 45 (Oct 16, 9:47 AM PT): "definitely not A"; C as the overall idea; the current step or steps highlighted with an accent and some weight; the moving mark a little cooler; B's list folded in as a peek; steps that run in parallel. This sheet replaces sheet 10's recipe page and sheet 12's cook mode: the recipe page is the cook, running. Sheet 45 C stands except where this says otherwise.
- **This build:** one lane, lit steps, the bead, the peek. The second lane and Pantry's rows are drawn so the page has room for them; both are later.
- Board: `mockups/recipe-clock.png` (source `studies/recipe-clock.html`). Porcelain and Obsidian: at rest, 12 min in, 32 min in with two steps live, the ingredient peek, the peek with Pantry (a later state), the last step, done.
- Recording: `recordings/recipe-clock.mp4` (17 s, Porcelain): the peek in and out, COOK, each step lighting as the bead reaches it, the sauce forking off the roast at 30 min, the last step, hold DONE, the receipt.

## The page
| y | Element |
|---|---|
| 58 | ‹ RECIPES |
| 84 | The name, Title 44, two lines when it needs them |
| 196 | One line, Body 21 `inkSecondary`: "serves **4**, 45 min, cooked 12 days ago". Commas, no " · " (41 rule 3). The serves word is the portion drum, as built |
| 256 on | **The clock.** The minute column (Label 16, right-aligned to x 52), the stroke at x 66, steps from x 96. y is time with a floor: each step gets the room its lines need, and a long span (the roast) takes what is left |
| 664 | The key row: COOK on the ink line with "45 MIN" beside it; **INGREDIENTS** at the right as a plain word, ink 60%, no line |
| 686 to 736 | The page fades above Tess's band, as every page one tap down |

## Lit steps
- **The step he is on is lit:** its title goes to weight 600 in full ink, its ingredient lines to ink 80%, and its minute turns `context`. Steps done dim to `inkSecondary` at 42%. Steps ahead stay as at rest. No wash, no box, no colour on the words at rest.
- **A step lights wet.** When the bead reaches a step, the title lands in `now` and dries to ink over 2 s (the house moment). Tess says the step, thing first: "Chicken in, on the pan." One `.impact(.soft)` per new step. The haptic is the step's, so two steps starting together give one.
- **A timed step counts down at its right:** "33 MIN" in `now`, Label 16/700, on the title's line. Only steps with a duration of their own (the recipe says "35 min", or the step runs alongside another) count. A prep step ("Oven 425°F, potatoes on") doesn't, because its minutes are a guess and a countdown on it would be false.
- The key row says the whole cook: STOP with "33 MIN LEFT". At the last step it reads DONE with HOLD, a 0.7 s hold.

## The bead and the stroke
- **The bead** is a 14 pt `now` dot with a soft glow. It breathes (×1.14 over 2.4 s) and sends one ring out per breath (to ×2.6 at 35%, fading). It walks the stroke at real time.
- **The stroke wets behind it.** The current step's span is `now` at 3.6 pt; when the step ends, that span dries to ink at 55%, 3 pt. So the stroke above the bead is a record of what is done, and the bit in colour is only the step he is on.
- Ahead of the bead the stroke is the 20% guide, as at rest.
- **Reduce Motion:** the bead sits still with no breath and no ring; it moves in 1-minute steps with a 200 ms crossfade. A step still lights, without the wet landing.

## Steps that run at once (later, not this build)
This build is C with lit steps, the bead and the ingredient peek, one lane. He called parallel steps secondary, so the second lane waits. When it comes back, it is reconciled with the Kitchen lead's rule in #414 (cue words open a track; at most two live tracks and two timers; the model's pairs show as a faint bracket until he taps once per recipe), and that rule wins where the two differ.
- **A step that overlaps another forks into a second lane:** the stroke curves out to x 88 over 12 pt at the step's start minute, runs beside the main stroke, and curves back in at its end. Its text sits at x 108, under the step it runs alongside. At rest the fork reads as "meanwhile" without the word.
- **While both run, both are lit**, each with a bead and its own minutes ("13 MIN", "3 MIN"), so he sees which ends first. Tess names the new one with the old: "Sauce now, while it roasts."
- Two lanes at most on the page. A third overlapping step goes in the second lane after the first one there ends; if they truly overlap three ways, the third sits in the second lane's text under the other with its own minute (Kitchen lead to rule how often that happens).
- **Where overlaps come from:** the recipe's own words ("meanwhile", "while it roasts", "in another pan") and the durations the parser reads. Claude can propose overlaps when a pasted recipe doesn't say them; they arrive as a ghost fork (the lane drawn at 30%) with KEEP / NOT NOW under Tess's line, never applied on their own.

## The ingredient peek (B, one swipe away)
- **Swipe the page left anywhere above Tess's band, or tap INGREDIENTS.** A pan that starts in the band (736 to 820) is always hers (stroking her, motion lab 18b), never the page's. The clock slides 44 pt left and fades; its stroke stays at the left edge as a spine, with the bead on it, so he keeps his place in time. B's list slides in from the right over 320 ms on the house curve, at Body 21 (B's 16 pt was the hard-to-read part): "SERVES **4**" as a label word at 236, then one ingredient per row from 268 at 40 pt pitch, the amount as a value word ("**1½ lb** chicken thighs"). Swipe right, or tap STEPS at the right of the key row, to go back.
- **During a cook, used ingredients dim** to 42%, so the list also says what is still to come.
- **The key in the peek** sends the list to Groceries: "ADD 7 TO GROCERIES" (staples skipped, as Groceries already rules). The receipt is "Chicken, 7 added." with UNDO (the short-name rule from sheet 67). This replaces sheet 45's swipe-left-to-Groceries, which the peek now owns.
- **With Pantry (later, not this build):** each row says what he has at the right, Label 16/600: "on hand" at 42%, or "to buy" in ink. Used rows say "used". The key adds only what is missing: "ADD 2 TO GROCERIES", receipt "Chicken, 2 added." Until Pantry exists, the rows carry no value.

## Swipe for more, as a house rule
His ask was wider than recipes: a little more of a page, a swipe away. So:
- **A page one tap down may have one side page:** the detail behind it, revealed by a left swipe from anywhere on the page above Tess's band (a pan that starts in the band is hers), with the page's own spine (its time stroke, its strip, its key column) left in view at the edge so he never loses where he is. A plain word at the right of the key row (INGREDIENTS here) opens it too, for anyone who doesn't know the gesture.
- The side page shares the page's ground. No card, no sheet edge: the main page fades under a ground gradient.
- **Never on the tab pages.** Sideways on Home, Training, Review and Kitchen is the glass tabs (42). Never on a live workout, where sideways is the next exercise.
- Candidates for the next pages to use it: a routine (its sets as a list beside the plan), a Day log day (the raw lines beside the story), a Review week (the numbers beside the bands). Each needs its own sheet line before it is built.

## Done
Hold DONE: the line fills over 0.7 s, the last span dries, every step returns to its resting ink, and the stroke stays dry ink as the record of tonight's cook. Tess: "**Paprika chicken, cooked.**" with UNDO for 10 s (it takes back the cook log entry). Done's own `.success`. The page then reads as at rest, with "cooked today" in the line at 196.

## Lock Screen and the island
The cook Live Activity stays as built (Design 54): the current step's title and its minutes left; with two lanes live it shows the one that ends first, then the other. Nothing new here for Builder A.

## For the builders
- **Builder B:** the page as one view with a `cook` state (`RecipeClockView`); the minute map from Core's step starts with each step's line floor; lit, wet, dry and dim; the bead (`TimelineView`, 30 fps when the screen is still, the ring as an overlay); the peek as an offset pager with the spine pinned; INGREDIENTS / STEPS words; the receipt lines. Cook mode's screen (sheet 12) folds into this page; its timers come from the stroke.
- **Core:** a start and end minute per step from the parser; one timer per timed step; the used set per minute for the peek. Later, with lanes: a lane per step, more than one live step, and the model's pairs as #414 rules them.
- **Kitchen lead:** ruled in #419 (cook-mode-acceptance.md, b0b54f1), PASS on this sheet. A step is timed only when its own text carries a duration (lower bounds summed; "a side" doubles); an untimed step is a 2-minute span on the clock; a wait over 3 hours (marinate, overnight) is drawn at a fixed 10-minute span with its hours ("8 HR") and no countdown or timer. The peek's key follows Groceries' add rules exactly, its number a dry run of that add; at 0 the key word is absent. The lane rules are #414's, for when lanes come back.
- **Later, Product:** Pantry (his idea: a stock of what he has, feeding Groceries, Recipes and the peek's on hand / to buy). This sheet only reserves the peek's right column for it.

## VoiceOver, finish keys and targets on the clock page (G228, G229; Oct 17, 9:07 PM PT rulings)
The clock page IS the cook. Sheet 12's cover is gone, and so is its reading order.
**One reading order (replaces K84.20 and the cover order; VO5 to VO24 govern).** Top to bottom, one stop each:
1. The back word ("Recipes").
2. The name (a heading; a private recipe reads "Private recipe").
3. The context line ("serves 4, 45 minutes, cooked 12 days ago").
4. The steps in time order, one element per step: done steps with value "Done", the lit step "Now, 14 minutes left" (or "Now"), steps ahead "Step 5 of 6, at minute 39". Untimed steps carry no minutes. The minute column, stroke, bead and wet/dry spans are hidden (VO6, VO15).
5. The key row: STOP with "33 minutes left", or DONE at the last step.
6. The INGREDIENTS word (STEPS when the peek is open).
- **Not on this page:** a "Next" bar (K84.20 does not apply), a cover heading ("Weeknight dal, cooking"), a "Step N of M" line apart from each step's value. The step moves on by the bead, or by "Next step" as an action on the held step (VO14).
- **Focus** stays where it was when a step lights or a timer ends; the news is announced, once, not focused (VO13, K84.22).
**Finish key (G229, VO19 amended).** DONE is named-action-only for VoiceOver: label "Done", value "4 minutes left", button, hint "Hold to finish", and one named action "Finish". There is no default action, so a double tap speaks the hint and does not finish; the named action finishes, with the same receipt and 10 s UNDO as a real hold. Voice Control and Switch Control reach Finish by its name, since a tap on DONE alone must not end a cook. A timer-start key (a tap key) keeps double-tap start. Other hold keys are unchanged.
- **For Builder A:** give `PaintKey` an opt-out of the default action and the default hint for these keys (a parameter such as `finishAction: String?`: when set, the key adds that named action, no default action, and the hint reads "Hold to finish"). This is the only exception to the hint rule "the hint names the effect, never the gesture", and it applies to the finish and clear keys only.
**Targets (K84 carries over).** The key row, the INGREDIENTS word, the lit step's actions and Tess's UNDO use the cook-mode targets on the clock page: at least 64 pt, and 88 pt from the first accessibility text size up (AX1). The page is where he cooks with wet hands, so the sizes follow the screen, not the old cover. Everything else on the page, such as back, rows in the peek and the portion drum, stays at 44 pt. The key row grows to 64 pt in place without moving the bead's column.

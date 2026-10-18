# Cook mode (kitchen slice 12): cut, defaults and acceptance script

*Kitchen lead, 2026-10-15. Design's build sheet `docs/design/kitchen/12-cook-mode.md` matches this file (Finish has no confirm and no note field, and stopping is a drag left with UNDO). This reads with the slice 12 steer in `ship-list-kitchen.md` and Research's `docs/research/fixtures/cook-mode-scenarios.md` (S01-S15, ASSUMED 1-12). It settles the open points so Core can build without waiting. Product can overrule any line; until then these are the defaults.*

## Which rows apply to which screen (Product ruling, Oct 17 9:07 pm, G228)

The clock page (Design 69) is the cook and replaces the cover. VO5 to VO24 (`docs/research/fixtures/voiceover-recipe-clock-lists.md`) govern the reading order of the cook screen. K84 rows carry over only where the clock page has the same thing: K84.14 and K84.26 (Done), K84.22 (timer end), K84.25 (ingredient peek key), K84.27 (Finish receipt). K84.20's reading order and its Next bar do not apply to the clock page, so K84.20 and K84.29 (the cover's reading order) are read as history unless the cover returns. Inferred, not ruled: the Dynamic Type, thumb-reach and Reduce Motion rows stay as targets for the clock page's own keys; Product to confirm per row. Where a K84 row and a VO row disagree, the newer ruling wins (K84.26 over VO19, see G229).

## The cut: what slice 12 must have

**In slice 12:**
- The screen from the steer.
- Step timers (hold-to-start keys) and horizon lines.
- A local notification for each timer.
- One cook Live Activity.
- Reconciling timers on launch, foreground and time change.
- The idle rule.
- Finish.

**Moved to a follow-up slice (12b):**
- Pause and Extend actions (ASSUMED-6), including the Lock Screen +1. Lock Screen Stop stays in 12.
- A suspended cook's ledger row showing its timer (ASSUMED-9).
- Hours copy over 90 min (ASSUMED-11). Minutes are fine for v1.

These wait because the scenarios that need them (S08, S09) are edge cases in a first week of cooking. Stop covers "I'm done with this timer".

## Defaults for the open points

| ASSUMED | Default |
|---|---|
| 1 Cook face | A sibling `CookTimerAttributes`, drawn in the rest activity's language (horizon line, countdown, Done face). There is one cook activity for all kitchen timers: the soonest leads and the rest show as "+N". `RestActivityController.end()` keeps ending only rest activities. |
| 2 Timers know their step | Yes. `Kitchen Timer.step`; the minutes are the lower bound of the step's range ("20-25 min" gives 20). The label is the verb nearest the duration ("Roast" for "Add the chicken and roast 20 min"), else "Step 3" (ruled Oct 16 after Research's day-one walk, W12 and G6; the first-verb rule gave "Add"). |
| 3 Alerts | The local notification is the only alert: id `kitchen-timer.<id>`, `.active`, thread `tessera.kitchen`. Activity updates are silent. While cook mode is open, the in-app flare replaces the banner for this cook's timers. |
| 4 Timer end and the resume point | A finished timer does not move the resume point. Its step slides back in as an overlay with a haptic. The Next key is the way to move on; there is no step swipe in cook mode (Product, Oct 17, 4:52). |
| 5 Deep link | `tessera://cook` opens cook mode on the activity's cook. A tap on the notification goes there too. |
| 7 Idle rule | Product's rule (19:06): never suspended while a timer runs or within 45 min of the last step change. Otherwise 45 min. The limit is per owner app in `ProcessTable`. |
| 8 Reconcile | As Research wrote it. An ended timer that isn't stopped stays flared until he stops it. |
| 10 Finish | Stops this cook's timers without a confirm. Timers that belong to no cook survive. |
| 12 Fixture zone | Europe/London, as written. |

## Acceptance script (what I'll check)

**Engine (`swift test`).** The fixtures must pass: S01-S07, S10, S11, S12, S13, S14 and S15. S08 and S09 belong to 12b.

**On the simulator, in the recording (`docs/recordings/NN-cook-mode.mp4`, starting on the page with no blank lead-in).** The recording must show each of these steps:
1. Tap Cook on the Weeknight dal recipe page. A dark full-screen cover rises, showing step 1 at the Title tier with its scaled amounts under it.
2. Press Next. Step 2 arrives, and step 1 stays as a dim line above it.
3. Hold the cadmium "8 minutes" key. A horizon line appears at the top and starts burning down.
4. Start a second timer. Two stacked lines appear, each labelled. For the recording, shorten a timer with `-demoTime` or a short fixture recipe, so the end shows within the clip.
5. A timer ends. Its line flares cadmium and its step slides back in, with a haptic.
6. Lock the phone. The cook Live Activity shows the soonest timer and "+1". When it ends, the Done face flips on its own and the notification arrives.
7. Background the app for more than 13 min with a timer running (fixture or clock shift), then return. The cook is still running and still Now.
7b. Drag a running timer's line left. It fades, and Tess says "Simmer stopped." with UNDO. Tapping the flared stack stops a finished timer.
8. Hold Finish on the last step. The cover closes, the Cook entry is written, and Tess's line appears. The line is true to the history (Product, Oct 17 4:57): "Weeknight dal, first time." when it is the first cook ever; "Weeknight dal, first time this month." when it is the first in a month; "Weeknight dal, second time this month." from the second. Cooking.swift picks the form by fact.

**UI bar.**
- Every target is at least 64 pt.
- No text is under 16 pt.
- There are no cards, pills or modals.
- The screen stays awake only while the cook page is visible, the scene is active, and (a timer runs or the last step change was under 45 min ago). It releases on idle, Finish, leaving and backgrounding, and re-arms on touch (Product, Oct 17 9:07 pm, G218). Low Power does not extend the window.
- Reduce Motion swaps the slides for fades.
- Cobalt is used only for Tess's line, and vermilion only for "running".

## Next on the same pattern

The meal plan feeding groceries ("cook carbonara thursday" puts its ingredients on the list) gets the same kind of script once Product schedules it. The engine check will be that a dated task linking a recipe adds that recipe's share to groceries once, and that undoing the task removes the share.

## The recipe clock (Design 69): the rulings Design and Research asked for

*Kitchen lead, 2026-10-16. Sheet 69 (`docs/design/recipe-clock.md`) folds cook mode into the recipe page: one lane, lit steps, the bead, the ingredient peek. Lanes and Pantry wait; when lanes come back, the overlap rule in `kitchen-v2-backlog.md` wins.*

**1. Which steps count as timed.** A step is timed when `RecipeParser.durations(in:)` finds a duration in the step's own text; nothing else makes a step timed, so a prep step with no number ("Oven 425°F, potatoes on") shows no minutes and gets no timer, as the sheet says. The step's minutes are the sum of its durations' lower bounds ("8-10 min" counts 8; "sear 3 min a side, then 10 min in the oven" counts 16, because "a side", "per side" and "each side" double that duration). A timed step owns one timer, started when the bead reaches it; only timed steps count down at the right. An untimed step is 2 minutes on the clock (the backlog's constant), drawn as a short span, and the key row's "33 MIN LEFT" is the remaining timed minutes plus the untimed floors ahead. A wait over 3 hours (marinate, rise, chill overnight) is timed but drawn at a fixed 10-minute width with its minutes in hours ("8 HR") and no countdown or timer: the cook is not running through it. Recipe time lines ("Cook time: 20 min") are not steps and never time one.

**2. The staples skip for the peek's key.** The key uses Groceries' rules exactly, no second list: it skips staples (`AisleGuide.isStaple`), "to taste" lines, optional / for serving / for garnish lines (G-R4), and covered lines (a same-key open row joins and shows the recipe line, a checked row covers, G-R2); during a cook it also skips rows already dimmed as used. The number in "ADD 7 TO GROCERIES" is the new-row count `AddRecipeToGroceries` would return, computed on the phone as a dry run of the same function, so the key word, the receipt "Chicken, 7 added." (short name, UNDO 10 s) and the list never disagree. At 0 the key word is absent and nothing is said; a planned recipe is already on the list, so its key reads 0 by the covered rule. Done's "Paprika chicken, cooked." keeps the full title: it is the cook log's line about the dish, not a line about rows for it.

**3. Pause (day-one walk W15, W16).** "pause" holds the bead and this cook's step timers together: the key row reads "PAUSED" with the step's minutes kept ("20 MIN LEFT"), the pending notification for the step's timer is removed, and the Lock Screen shows the cook paused. A spoken timer in the cook ("timer bread 8") is not a step's and keeps running: the oven does not know about the doorbell. "go on", "resume" or a tap on PAUSED walks the bead again, reschedules the step's timer under the same id, and every later minute on the clock shifts by the paused length. Pause is slice 12b; until it lands, Tess says "Pause comes later." and the clock keeps walking.

**4. Running over and "5 more minutes" (W18, G7, Research's star).** When a timed step's timer ends, the bead holds at the step's end and the step stays lit until he moves on (the Next key, or the flare's stop); the clock never lights the next step on its own, because an oven step is done when he says so. "5 more minutes", "5 more" or "give it 5" while a step is held stretches that step by 5 and restarts its own timer under the same id (KT7), never a second timer; the minutes ahead shift by the same 5 and the key row follows ("11 MIN LEFT"). With no step held, "5 more" on the current timed step extends its running timer the same way. Product can overrule the hold; the shift rule stands either way.

**5. A spoken extra timer during a cook (W7, G8).** It sits on one labelled line under the key row, outside the stroke ("Bread · 8 MIN"), never as a step on the clock, because the clock is the recipe and the timer is his. Several stack by end time, soonest first. It ends with the same flare as a step's timer, on its own line, and it survives pause, done and leaving the page (Finish keeps timers that belong to no step, ASSUMED-10). Builder A draws it with Design; Design's words win on size and placement.

Day-one walk numbers accepted as written in `docs/research/fixtures/recipe-clock-day-one.md`, including W23's "2 HR 45 MIN LEFT" (10:32 pm; step 1's 2 minutes are spent; the rest figure in `recipe-clock-steps.md` stays 2 HR 47 MIN).


## Overnight cook's row time (decision 2:38 PM Oct 16, Core #552)

Found by the release walk as shipped without acceptance rows. A cook filed on its finish day (decision 1:40) is the row.

| # | Pass when |
|---|---|
| O1 | Overnight oats started at 2:10 am the day before and finished at 9:05 am: the log row sits on the finish day and reads "9:05 am Cooked overnight oats, 6 h 55 min" (the finish time, not the start) |
| O2 | Durations of 60 minutes or more read in hours and minutes ("6 h 55 min", "1 h"); under an hour stays in minutes ("45 min"); never "415 min" or "1 h 0 min" |
| O3 | Clocks are lowercase ("9:05 am"), and the row sorts with the finish day's other rows by that time |
| O4 | A cook that starts and finishes the same day shows its finish time the same way, so one rule serves both |

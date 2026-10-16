# Cook mode (kitchen slice 12): cut, defaults and acceptance script

*Kitchen lead, 2026-10-15. Design's build sheet `docs/design/kitchen/12-cook-mode.md` matches this file (Finish has no confirm and no note field, and stopping is a drag left with UNDO). This reads with the slice 12 steer in `ship-list-kitchen.md` and Research's `docs/research/fixtures/cook-mode-scenarios.md` (S01-S15, ASSUMED 1-12). It settles the open points so Core can build without waiting. Product can overrule any line; until then these are the defaults.*

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
| 2 Timers know their step | Yes. `Kitchen Timer.step`; the minutes are the lower bound of the step's range ("20-25 min" gives 20). The label is the step's first verb ("Simmer"), else "Step 3". |
| 3 Alerts | The local notification is the only alert: id `kitchen-timer.<id>`, `.active`, thread `tessera.kitchen`. Activity updates are silent. While cook mode is open, the in-app flare replaces the banner for this cook's timers. |
| 4 Timer end and the resume point | A finished timer does not move the resume point. Its step slides back in as an overlay with a haptic. Swiping is the only way to change step. |
| 5 Deep link | `tessera://cook` opens cook mode on the activity's cook. A tap on the notification goes there too. |
| 7 Idle rule | Product's rule (19:06): never suspended while a timer runs or within 45 min of the last step change. Otherwise 45 min. The limit is per owner app in `ProcessTable`. |
| 8 Reconcile | As Research wrote it. An ended timer that isn't stopped stays flared until he stops it. |
| 10 Finish | Stops this cook's timers without a confirm. Timers that belong to no cook survive. |
| 12 Fixture zone | Europe/London, as written. |

## Acceptance script (what I'll check)

**Engine (`swift test`).** The fixtures must pass: S01-S07, S10, S11, S12, S13, S14 and S15. S08 and S09 belong to 12b.

**On the simulator, in the recording (`docs/recordings/NN-cook-mode.mp4`, starting on the page with no blank lead-in).** The recording must show each of these steps:
1. Tap Cook on the Weeknight dal recipe page. A dark full-screen cover rises, showing step 1 at the Title tier with its scaled amounts under it.
2. Swipe up. Step 2 arrives, and step 1 stays as a dim line above it.
3. Hold the cadmium "8 minutes" key. A horizon line appears at the top and starts burning down.
4. Start a second timer. Two stacked lines appear, each labelled. For the recording, shorten a timer with `-demoTime` or a short fixture recipe, so the end shows within the clip.
5. A timer ends. Its line flares cadmium and its step slides back in, with a haptic.
6. Lock the phone. The cook Live Activity shows the soonest timer and "+1". When it ends, the Done face flips on its own and the notification arrives.
7. Background the app for more than 13 min with a timer running (fixture or clock shift), then return. The cook is still running and still Now.
7b. Drag a running timer's line left. It fades, and Tess says "Simmer stopped." with UNDO. Tapping the flared stack stops a finished timer.
8. Hold Finish on the last step. The cover closes, the Cook entry is written, and Tess's line appears ("Weeknight dal, first time.").

**UI bar.**
- Every target is at least 64 pt.
- No text is under 16 pt.
- There are no cards, pills or modals.
- The screen stays awake.
- Reduce Motion swaps the slides for fades.
- Cobalt is used only for Tess's line, and vermilion only for "running".

## Next on the same pattern

The meal plan feeding groceries ("cook carbonara thursday" puts its ingredients on the list) gets the same kind of script once Product schedules it. The engine check will be that a dated task linking a recipe adds that recipe's share to groceries once, and that undoing the task removes the share.

## The recipe clock (Design 69): the two rulings Design asked for

*Kitchen lead, 2026-10-16. Sheet 69 (`docs/design/recipe-clock.md`) folds cook mode into the recipe page: one lane, lit steps, the bead, the ingredient peek. Lanes and Pantry wait; when lanes come back, the overlap rule in `kitchen-v2-backlog.md` wins.*

**1. Which steps count as timed.** A step is timed when `RecipeParser.durations(in:)` finds a duration in the step's own text; nothing else makes a step timed, so a prep step with no number ("Oven 425°F, potatoes on") shows no minutes and gets no timer, as the sheet says. The step's minutes are the sum of its durations' lower bounds ("8-10 min" counts 8; "sear 3 min a side, then 10 min in the oven" counts 16, because "a side", "per side" and "each side" double that duration). A timed step owns one timer, started when the bead reaches it; only timed steps count down at the right. An untimed step is 2 minutes on the clock (the backlog's constant), drawn as a short span, and the key row's "33 MIN LEFT" is the remaining timed minutes plus the untimed floors ahead. A wait over 3 hours (marinate, rise, chill overnight) is timed but drawn at a fixed 10-minute width with its minutes in hours ("8 HR") and no countdown or timer: the cook is not running through it. Recipe time lines ("Cook time: 20 min") are not steps and never time one.

**2. The staples skip for the peek's key.** The key uses Groceries' rules exactly, no second list: it skips staples (`AisleGuide.isStaple`), "to taste" lines, optional / for serving / for garnish lines (G-R4), and covered lines (a same-key open row joins and shows the recipe line, a checked row covers, G-R2); during a cook it also skips rows already dimmed as used. The number in "ADD 7 TO GROCERIES" is the new-row count `AddRecipeToGroceries` would return, computed on the phone as a dry run of the same function, so the key word, the receipt "Chicken, 7 added." (short name, UNDO 10 s) and the list never disagree. At 0 the key word is absent and nothing is said; a planned recipe is already on the list, so its key reads 0 by the covered rule. Done's "Paprika chicken, cooked." keeps the full title: it is the cook log's line about the dish, not a line about rows for it.

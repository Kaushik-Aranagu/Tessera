# 12 · Cook mode (build sheet)

Just enough to build. Product steer: `docs/product/ship-list-kitchen.md` §12. Engine: slice 5 (cooking as a process, timers, the Cook log). Folder: `Features/Cooking/`.

A full-screen cover, like the workout: **dark ground** (the workout's `WorkoutPalette` ground with the same washes), cream ink. It's a running process: the lit `ProcessSeam` sits on the top edge, Now on Home reads "Cooking carbonara, step 3 of 6", and leaving suspends it into the ledger. **The screen stays awake. Every target is at least 64pt** (wet hands); holds are 0.6s.

## Layout
| y | Element |
|---|---|
| 0 | **Timer horizons** (see Timers): one hairline per running timer, stacked down from the top edge, 10pt apart |
| 56 | "Carbonara, for 2" (21/400, secondary) on the left; "3 / 6" in labels on the right |
| 100 | **The previous step,** dim: one line at 21/400 at 35%, truncated. Tap it to step back |
| 150 | **This step** at the Title tier: **34/500**, line height 1.15, up to 6 lines. Ingredient mentions are cream at 100%; the rest of the sentence is at 85% |
| below step, +20 | **This step's ingredients, already scaled:** one per line at 21 (amount in 600, name in 400), at 70% |
| 600 | **The step's timer key**, when the step has a duration (see Timers) |
| 690 | **Next step peek:** "then: whisk the eggs with the pecorino" at 21/400, 30%, one line |
| bottom | Tess bar on dark glass, as in the workout |

## Moving through steps (y is sequence)
- **Swipe up** for the next step. This step shrinks into the dim line above (34 → 21, opacity to 35%, 380ms, house spring), and the next rises from the peek into place (blur 4→0). Swipe down to go back. Tapping the step also advances (the one-tap twin).
- Medium impact haptic per step.
- Reduce Motion: crossfade the step text; no size morph.

## Timers
- **The timer key:** when the step has a duration ("simmer 20 min"), a cadmium `PaintKey` reads "**20 min**, hold to start" (64pt tall, 240 wide). Hold 0.6s; the cadmium paint spreads through it. A range ("20–25 min") starts the low end, and the key's label shows the range.
- **A running timer is a horizon line** across the top of the screen (the rest Live Activity's language): a 2.5pt cream stroke with a soft wet tip, over a 1.5pt guide at 14%, burning down **left to right** as time passes. Its label sits under its left end in labels at 16 ("PASTA 7:42", tabular). Several timers stack as hairlines 10pt apart, soonest on top.
- **Tap a horizon** for +1 min (the one-tap twin of dragging it right). Drag it left to cancel it, with Undo in the Tess bar.
- **When a timer ends, the one living moment:** its line **flares cadmium** (the whole stroke brightens and blooms to 6pt, then holds glowing), one alert haptic plays, and if you've moved on, **the step it belongs to slides back into view** from above with its text in cadmium for a moment: "Pasta's done." Tap anywhere to dismiss the flare.
- **Lock Screen:** timers run through the same rest Live Activity (`docs/design/live-activity.md`): the countdown is the soonest timer, and the right column is the timer's label ("Pasta"). +1 min replaces +15, and Done is "Stop".

## Finishing
- On the last step, the key at y 600 becomes "Hold to finish" (an ink `PaintKey`, cream on dark, 0.6s).
- Finishing writes the Cook entry. The step text lifts away, "Carbonara, done" enters at Hero 56/500, Tess plays `done`, and she says one line: "Carbonara, third time this month." Swipe down to close; the recipe page now says "cooked today".
- An optional note field is one line under the hero ("Anything to remember?"), 21/400 at 50%, typed or dictated; it's saved into the Cook entry.

## States
- **A step with no duration:** no timer key; the ingredients block moves down to fill.
- **Timers still running at finish:** they keep running, and the finish line says so ("Pasta still has 2 min").
- **Long steps (over 6 lines at 34):** step down to 28.
- **Suspended:** resuming lands on the step at eye level with one glint across it, and any running timers keep their real end times.

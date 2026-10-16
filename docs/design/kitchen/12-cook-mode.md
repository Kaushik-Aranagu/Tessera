# 12 · Cook mode (build sheet)

> **US kitchen pages (item 28):** the recipe page and cook mode in US units, with today's page top, Tess beside the soul and cook mode on the look's ground, are in `us-kitchen-pages.md`, which wins over this sheet.

> **US shop (item 25):** aisle names, amounts, fractions, pack sizes and merging for a US kitchen are in `us-shop.md`, which wins over this sheet's metric and UK examples.

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

Just enough to build. Product steer: `docs/product/ship-list-kitchen.md` §12. The Kitchen lead's cut and defaults: `docs/product/cook-mode-acceptance.md`, checked on the phone with `cook-mode-script.md`. Engine: slice 5 (cooking as a process, timers, the Cook log). Folder: `Features/Cooking/`. Builder A builds it.

Recording: `../recordings/cook-mode.mp4` (source `../studies/cook-mode.html`; timers run a minute per second). It follows the acceptance script with the seed recipe Weeknight dal and starts on its recipe page:
1. Cook raises the dark cover.
2. Swipe up to step 2 and hold "8 minutes".
3. Swipe to step 3 and hold "20 minutes". Two horizons stack.
4. Soften ends: its line flares and step 2 slides back over the page. Tap to put the step away, then tap the flared line to stop it.
5. Step 4: hold Finish. The cover lowers and Tess says "Weeknight dal, first time."

A full-screen cover, like the workout: **dark ground** (the workout's `WorkoutPalette` ground with the same washes), cream ink. It rises from the bottom (460ms, house curve); a process rises, it never zooms. It's a running process: the lit `ProcessSeam` sits on the top edge and Now on Home reads "**Weeknight dal**". **The screen stays awake. Every target is at least 64pt** (wet hands), the dim previous line included. Holds are 0.6s.

**The idle rule:** cook mode is never suspended into the ledger while a timer runs or within 45 min of the last step change; otherwise after 45 min. The limit is per owner app in `ProcessTable`.

## Layout
| y | Element |
|---|---|
| 0 | **Timer horizons** (see Timers): one hairline per running timer, stacked down from the top edge, 30pt apart |
| 56 | "Weeknight dal, for 2" (21/400, secondary) on the left; "3 / 4" in labels on the right |
| 100 | **The previous step,** dim: one line at 21/400 at 35%, truncated. Tap it to step back (its hit area is 64pt tall) |
| 150 | **This step** at the Title tier: **34/500**, line height 1.15, up to 6 lines. Ingredient mentions are cream at 100%; the rest of the sentence is at 85% |
| 430 | **This step's ingredients, already scaled:** one per line at 21 (amount in 600, name in 400), at 70% |
| 590 | **The step's key** when it has one: a timer key, or Finish on the last step (see below) |
| 690 | **Next step peek:** "then: fry the cumin seeds and pour the tadka over" at 21/400, 30%, one line |
| corner | **Tess's soul** in its corner (346, 788), in screen blend on the dark ground, as in the workout. No Tess bar |

## Moving through steps (y is sequence)
- **Swipe up** for the next step. This step shrinks into the dim line above (34 → 21, opacity to 35%, 380ms, house curve), and the next rises from the peek into place (blur 4→0, 420ms). Swipe down to go back. Swiping is the only way to change step.
- Medium impact haptic per step.
- Reduce Motion: crossfade the step text; no size morph and no rise.

## Timers
- **The timer key is a cadmium stroke word** (`PaintKey`, `no-buttons.md`): the step's duration in words, "**8 minutes**", with the meta beside it in labels: "HOLD · SOFTEN". A range starts at its low end and the meta says so: "**20 minutes**", "HOLD · UP TO 25". The stroke fits the word; the meta sits 22pt after it.
- **Hold 0.6s,** as every hold in the app: on touch the stroke empties to a 20% trace (140ms), repaints left to right under the thumb, and the tip blooms as a blot (×1.3, settle spring) with `.impact(.medium, intensity: 0.8)`. Letting go early drains it back.
- **A running timer is a horizon line** across the top of the screen (the rest Live Activity's language): a 2.5pt cream stroke with a soft wet tip, over a 1.5pt guide at 14%, burning down **left to right** as time passes. Its label sits under its left end in labels at 16, tabular: the step's first verb and the time left ("SOFTEN 7:42"), else "STEP 3 7:42".
- **Several timers** stack 30pt apart, the soonest on top, and the page content moves down 30pt per extra timer (house curve, 320ms) so nothing overlaps.
- **Stopping a running timer:** drag its line left. It fades, and Tess says "Stopped simmer." with **UNDO**. Pause and +1 minute wait for slice 12b.

### When a timer ends (the one living moment)
1. **Its line flares cadmium:** the whole stroke brightens to 6pt and blooms (420ms), then holds glowing. Its label reads "SOFTEN · DONE" in cadmium. One `.notificationOccurred(.success)` haptic.
2. **Its step slides back over the page** from above (24pt, blur 4→0, 420ms) in cadmium: "SOFTEN IS DONE · STEP 2" in labels at y 110, the step's text at Title 34 under it. The step text beneath fades out while it's there (200ms), so the two never overlap. **The resume point doesn't change:** the count still reads "3 / 4".
3. **Tap anywhere on the page** to put the overlay away (it lifts 16pt and fades, 300ms); the current step fades back.
4. **The flared line stays flared until he stops it:** tap the horizon stack (the whole stack is one target, at least 64pt tall; a tap stops the flared line) or Stop on the Lock Screen. The line fades and the page moves back up.
- If cook mode is closed when a timer ends, the flare and the overlay play when he opens it from the notification.
- Reduce Motion: the flare is a colour change with no bloom; the overlay crossfades.

## Lock Screen and alerts
- **One cook Live Activity** for all kitchen timers: a sibling `CookTimerAttributes` drawn in the rest activity's language (`docs/design/live-activity.md`): horizon line, countdown, the dark ground. The soonest timer leads with its label ("Soften"), and other timers show as "**+1**" (or +N) beside it. Its key is **Stop**. When the lead timer ends, the activity flips to the Done face on its own, and the next timer takes the lead.
- **The local notification is the only alert:** "Soften is done", id `kitchen-timer.<id>`, `.active`, thread `tessera.kitchen`. Activity updates are silent. While cook mode is open, the in-app flare replaces the banner for this cook's timers.
- Tapping the activity or the notification opens `tessera://cook` on this cook.

## Finishing
- **On the last step, the key is Finish:** a vermilion stroke word, "**Finish**", with the meta "HOLD". Same hold as the timer key.
- At the end of the hold the cover lowers (440ms, house curve) to the recipe page. **Any timer of this cook still running stops silently, with no confirm**; timers that belong to no cook keep running. The recipe's context line gains "cooked today" (it crossfades), the Cook entry is written, Tess plays `done`, and she says one line beside the soul: "**Weeknight dal, first time.**" with **UNDO**, which reopens the cook on its last step with its timers.
- The note line ("Anything to remember?") waits for a later slice.

## States
- **A step with no duration:** no key; the peek stays at y 690.
- **Long steps (over 6 lines at 34):** step down to 28.
- **Suspended** (only after the idle rule): resuming lands on the step at eye level with one glint across it, and timers keep their real end times. The ledger row showing its timer is 12b.
- **Never:** pills or rounded keys, cards, a modal confirm, red, text under 16pt. Cobalt is Tess's line only; vermilion is the seam, Finish and UNDO.

# The quiet versions of Tess (motion lab, board item 13, picks and sides folded in)

One page for Builder A: for every soul state and every pick event, what she does under **Reduce Motion** and under **Low Power Mode**, what stays, and the one haptic. It restates nothing that two sheets disagree on and adds nothing to Done, which never changes.

Already specified (not redone here): `tess-motion.md` §13 has the state-by-state table for idle, eyes, roam, drag, working, thinking, listening, a one-ask wait, Done, the reward beat, repaint, look flood and outside the app, plus the four Low Power rules. `tess-picks.md` has a Reduce Motion and Low Power line for wake, stroke, wear, the mouth, sleep, held, clock, nudge, typing, peek and tilt. `tess-sides-motion.md` has them for every side. This sheet gathers those into one table and fills the gaps: Low Power for held, clock and peek (the picks left it blank), the haptic for each row, the switch rules, and the tests. Gap values are lab defaults for Design to overrule.

## The table
Reduce Motion (RM) is his accessibility setting: motion is the problem. Low Power (LP) is the battery: cost is the problem. With both on, RM wins. "Same" means the same as the column to its left.

| State or pick | Reduce Motion | Low Power | What stays | Haptic |
|---|---|---|---|---|
| Idle | Still frame; breath is opacity only, 0.85 to 1 over 3.2 s | Same motion at 20 fps; halo breath held at its mean | Blink, the dab lift order, the mode shown by size and grade | None |
| Roam | No travel; she stays home, the line names the row | No roam; she stays at the dock, the work runs there | The line, the work, Done | None (Done's own `.success`) |
| Listening | Blooms in the corner, no travel; eyes hold | Travel stays; mic level smoothed at 30 fps | The bloom size following the level, the words | None |
| Asking (one-ask wait) | No lean; breath still | Lean stays; 20 fps | The question, the two ink words | None |
| Working | 200 ms crossfade to the faded grade, mains loosened 1.5x, satellites 40% | Six lights, no readers, 30 fps; fade and gather as built | The "Planning your day." line, the gather, colour back | None until Done |
| Reward / Done | Done: its still frame, 1.8 s. Beat: 200 ms crossfade, no gather, no glance | Done as built; beat unchanged (940 ms, six fills) | Done's pour timing as a still, the blink | One `.success` (Done's own), none for the beat |
| Colour change | One 600 ms crossfade of the pigments, no wet swell | No repaint starts; one in flight finishes at 30 fps; the palette waits for the next idle | The new colours | None |
| Wake | No stretch; eyes open with a 200 ms crossfade | Same | The open eyes, the day's first line | None |
| Stroke | No ripple; one blink 50 ms after the finger leaves | Ripple at 30 fps | The blink, the tick | `.soulStroke`, once |
| Wear | Same (colour is not motion); the beat's gather is dropped | Same | The +0.10 saturation steps, capped at +0.40 | None |
| Sleep | Same values, no clock slow-down (already paused), crossfades instead of eye opens | Same | Closed eyes, muted colour, the opacity breath | None |
| Held | No glance; nothing | Normal (an offset, not a redraw) | Her place, the row's own lift | The row's own `.selection`; hers none |
| Clock | Nothing | Normal (eyes only) | The timer owns the moment | The timer's own; hers none |
| Nudge | Eyes only, no lean; eyes off too, nothing | Same as RM | The line that names the timed row | None |
| Typing | No pulse; nothing | At most one pulse per 400 ms | The words he types | None |
| Peek | Nothing | Normal (a 5 pt offset, 350 ms in, 500 ms out) | The last row | None |
| Tilt | Off; no motion manager | Off; no motion manager | Her still idle | None |
| Side | `sideTurned` plays nothing; 150 ms crossfade for the page, no 1:1 settle (the drag follows the thumb while down) | `sideTurned` nothing; settle as RM, the drag keeps its spring; idle tick 30 fps | Her line (150 ms crossfade, no blur in RM), the facet word | One `.selection` on landing on the full side |

## Switch rules
1. **What applies.** RM is `UIAccessibility.isReduceMotionEnabled`; LP is `ProcessInfo.isLowPowerModeEnabled`, kept current by `NSProcessInfoPowerStateDidChange`. Both are read once per frame from a cached flag. RM wins when both are on.
2. **Mid-animation.** A change never lands mid-move. A running state finishes in the version it started in; the new version applies at the next mode change. A constellation never halves its lights mid-split. Exception: turning RM on stops anything that travels at the next frame boundary, and she completes the move as a 200 ms crossfade to where the move was going.
3. **The soul's fade.** When the version changes at rest (the Settings toggle, Control Centre, a charger), the soul crossfades between the two frames over 200 ms (§13), never a cut. A repeated toggle inside 200 ms restarts the fade from the current blend.
4. **Side and screens.** Anything MotionPolicy owns (sides, pages, lines, receipts, the facet word) uses a 150 ms crossfade under RM, and the same under LP for the settle only.
5. **Done.** Never changes, under either switch: 1.8 s, `.success`, one tap.
6. **One haptic per moment.** No quiet version adds, removes or moves a haptic. A beat that loses its motion keeps its tap, if it had one.
7. **Eyes.** The blink stays under both (160 ms, 5 frames at 30 fps, 3 at 20). Glance, lean, stretch and ripple are the first things to go.
8. **Nothing new in Low Power.** Anything that only beautifies does not start (repaint, tilt, roam). Anything that answers him keeps its timing.

## Tests
- RM on: no `CMMotionManager`; stroke starts no ripple but sounds its tick and blinks once; wake opens eyes in a 200 ms crossfade with no width change; a roam request leaves her at home and the line names the row.
- LP on: working shows six lights and no readers; the idle tick is 20 fps and every other mode 30; no repaint starts; Done lasts 1.8 s with one `.success`.
- Both on: the RM result, for every row above.
- Switch while working: toggling LP mid-split leaves the light count unchanged until Done; toggling RM mid-roam ends with her at home through a 200 ms crossfade.
- Switch at rest: a toggle produces one 200 ms crossfade and no cut; two toggles inside 200 ms produce no jump.
- Every row: the haptic count per moment equals the table, in each of the four combinations (none, RM, LP, both).

## Recordings
`recordings/picks/tess-quiet-wake.mp4`, `tess-quiet-stroke.mp4`, `tess-quiet-nudge.mp4`: the three picks under Reduce Motion, made with `RM=1 node record.mjs pick-<name> obsidian <out.mp4> 1` (the prototype's new `?rm=1` flag shows idle's still frame with the opacity breath and the blink, and drops the glance, ripple, lean and stretch; the flag is off by default and changes no other output). Low Power for working is `recordings/tess-motion-low-power.mp4`. The simulator cannot set Low Power, so QA checks the rest on the phone.

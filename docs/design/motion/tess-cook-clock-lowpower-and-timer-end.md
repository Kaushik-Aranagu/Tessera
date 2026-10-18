# Cook clock in Low Power, working under Reduce Motion, and the timer-end moment (board items 56, 57, 58)

For: Builder A (clock, soul, notification), Builder B (clock view, Home DrainBar), Kitchen lead (rows), Design (numbers), QA. Written Oct 17, PM (Pacific). Sources: kitchen gap hunt 16 (G217, G220, G223, G225, G226, G233, `docs/product/`), decisions D4/D5 (7:39 PM Oct 17) and 8:20 PM A, `recipe-clock.md` (bead, stroke), `12-cook-mode.md` (horizons, flare, Lock Screen), `kitchen-cook-mode-accessibility-acceptance.md` K84.17 to K84.24, `research/fixtures/kitchen-timer-alerts.md` KT1 to KT19. Product's 8:3x to 9:xx PM rulings were not in the master copy of decisions.md when this was written; the rules below follow Product's board message and the gap hunt's proposed rules. Where a ruling lands differently, only the named row changes.

Low Power (LP) = Reduce Motion (RM) for the cook cover and the clock (D5): the soul alone keeps her own LP form (30 fps, six lights, no readers, full opacity and pigment). Done never changes. One haptic per moment.

## 56. Cook clock: Low Power columns, ticks and the spoken value

**The rule that makes it cheap: nothing counts, everything is derived.** Every figure comes from the absolute `endsAt`. No running tick count anywhere. The page body never holds a clock; each moving thing is a leaf view. The one timeline is paused when the scene is not active.

| Thing | Normal | RM and LP (same) |
|---|---|---|
| Step advance (Next, or "next") | slide as built | 150 ms crossfade in place, dim line above still shows (K84.17) |
| Cover open and close | rises 460 ms | fades, no rise (K84.19) |
| Horizon line (cook cover) | burns down continuously (30 fps while the screen is still) | steps once at each whole-minute boundary of `endsAt` (rem = k x 60 s), each step a 150 ms fade of the fill edge; in the last minute every 10 s (six steps) so a short timer still moves. Lab default, Design to confirm the 10 s |
| Seconds drawn in the label ("SOFTEN 7:42") | `Text(timerInterval:)`, drawn by the system, not by our tick | same: the system draws it; it costs us no redraw in LP |
| Key figure ("33 MIN LEFT") | changes at each minute boundary of `endsAt` (never a 60 s period from view appear: that lags by up to 59 s); house numeric roll | same boundary, 150 ms crossfade, no roll. Figure = ceil(rem / 60), so it changes when rem crosses k x 60 s |
| Recipe-clock bead | breathes (x1.14, 2.4 s), one ring per breath, walks the stroke at 30 fps | sits still: no breath, no ring; moves in 1-minute steps with a **150 ms** fade (this sets recipe-clock.md:30's 200 ms to the house RM crossfade) |
| Stroke behind the bead | wet `now` span, dries to ink 55% at step end | same colours; the span steps with the bead; drying is a 150 ms crossfade |
| A step lights | title lands wet, dries over 2 s; Tess says the step | title lands dry (no wet landing); line and haptic as normal |
| Home DrainBar (G226) | a step every 5 s (not 1 s), 400 ms ease per step; the line under it ("Pasta, 6 min") on the minute | one step per minute boundary, 150 ms fade of the fill edge; the line on the minute, 150 ms crossfade |
| Soul on the cook screen | as built | her LP form; when he asks "how long left" she works by position and size only (item 57) |

**Haptics are not part of the motion switch:** see the matrix in item 58.

**Spoken value (G233, VoiceOver).** The accessibility value is a separate string from the drawn seconds, and the drawn seconds are `accessibilityHidden`.
- Updates only at whole-minute boundaries of `endsAt`: "Simmer, 8 minutes left." (K84.20), then "1 minute left", then at rem < 60 s "Simmer, under a minute left." once, then at zero the done line "Simmer, done." (K84.22). No `updatesFrequently`. No per-second change: a 10-minute timer changes the spoken value 11 times and speaks nothing else.
- `CookModeCopy.timeLeft` at 0 s must return the done line, never "0 minutes left".
- The announcement of the end is the one high-priority "Simmer is done." (K84.22); the key's value then says "Simmer, done. Stop."

Checks (names for the builders' tests): `spokenTimerValueChangesOnlyAtMinuteBoundaries`, `timerDoneAtZeroSaysDoneNotZeroMinutes`, `minuteFigureFiresAtEndsAtBoundary` (a view appearing 20 s past a boundary still flips at the next boundary of `endsAt`), `drainBarRedrawsAtMostOncePerFiveSeconds`, `clockTimelinePausedWhenSceneInactive`, `cookPageBodyDoesNotRebuildOnTick`. Device check (the simulator can't set Low Power; `-lowPower` flag on the simulator, a real toggle on the phone): with Low Power on, a 3-minute timer shows three horizon steps and the key figure flipping at 3:00, 2:00, 1:00 of remaining, never mid-minute.

## 57. Reduce Motion keeps Tess whole while she works (G225, D4)

"Working" shows by **position and size only**. Amended in `tess-motion.md` (section 13 intro, the Working row, the Reduce Motion list), `tess-quiet-versions.md` (Working row) and `tess-never-diffused-audit.md` (fix 1 and the acceptance line), and in the prototype (`tess-motion.html`, the `reduced` ramp: the x0.6 opacity, the x0.5 saturation, the halo-off `fade` and the satellite alpha fade are gone).
- Reduce Motion, Working: 200 ms crossfade to the loosened pose (the three mains 1.5x from the centre; the satellites hold their idle places), 200 ms back. Group opacity 1. Colour grade and halo exactly as at rest. Done its still frame.
- LP and RM together: RM wins, same pose.
- The full version's live working fade (500 ms to the faded grade) is his own ask and unchanged; it is not a Reduce Motion form.
- Test: `reduceMotionWorkingKeepsFullOpacity` (a frame of RM Working has the same alpha on the mains and the same halo as Idle; a pixel check with `prototype/check-pigment.sh` on the clip).
- Reference clip `recordings/tess-motion-reduce-motion.mp4` re-rendered from the amended scene. Checked with `prototype/check-pigment.sh` on the soul box (`crop=150:150:615:1480`, idle at 1.0 s against Working at 4.0 s): the new clip passes (average R/G/B 35/25/24 at rest, 36/26/23 working, 0% difference); the old clip failed (35/25/24 against 15/11/10, 5 to 7%). `research/fixtures/soul-ask-claude.md` L1 still says "faded grade, satellites 40%": Research's file, flagged to Product.

## 58. Timer end: the ring, the haptic, the alert (G217, G223)

**Rules that hold in every mode.** The notification is the only alert (KT2, KT18, 12-cook-mode "Lock Screen and alerts"); it rings at any hour, quiet hours included. The Live Activity is silent: no `AlertConfiguration`, no haptic from it; its face flips to Done through `staleDate`, with the system's default content transition and nothing of ours. His own touches and the timer-end haptic stay in Low Power and in Reduce Motion.

**Timeline, app in front with cook mode open (T0 = the end):**

| t (ms) | Normal | RM and LP |
|---|---|---|
| T0 | one `.notificationOccurred(.success)` on the first frame of the flare; the high-priority "Simmer is done." announcement posted (VoiceOver); notification shows no banner, `willPresent` returns `[.sound, .list]` | same haptic, same announcement |
| T0 to T0+420 | the line's whole stroke brightens to 6 pt and blooms; the label crossfades to "SOFTEN · DONE" in cadmium (150 ms) | the line turns cadmium, 150 ms, no bloom (K84.18) |
| T0 to T0+600 | **the timer-end ring:** one ring leaves the line's wet tip (to x2.6, 35% opacity at start, fading to 0), played once, never looped | no ring |
| T0 to T0+420 | the step slides back over the page (24 pt, blur 4 to 0); the step beneath fades out in 200 ms | the overlay crossfades, 150 ms, no travel |
| T0+420 onward | the line holds flared until he stops it (tap the stack, or Stop on the Lock Screen); no pulse, no loop | same |

**Other places:**
- **Phone locked or app away:** nothing of ours moves or buzzes (the app is suspended). The notification's sound and vibration are the alert; the Live Activity flips to Done silently.
- **He opens it later (from the notification or the app):** the flare and overlay play on open as built, **with no haptic**. A haptic only plays when the app saw the end live, within 2 s of T0; a 20-minute-late buzz would be a second alert for the same event. Lab default.
- **Past the end, not stopped (KT17):** already flared; no ring, no haptic, never rescheduled.
- **Two timers ending inside 600 ms:** both lines flare, one haptic, one ring per line, one overlay (the soonest); the other waits behind a "+1". Further than 600 ms apart: a new moment, a new haptic.
- **Stop (drag left or the Stop action):** the line fades (150 ms), "Simmer stopped." with UNDO; no haptic on a stop; the pending notification is removed.

**Haptic matrix for the cook (G223).** Rule in one line: his touches and the timer-end success stay everywhere; Tess's own landings follow quiet hours.

| Haptic | Whose | Normal | RM | LP | Quiet hours (11 pm to 7 am) |
|---|---|---|---|---|---|
| Next step, medium impact | his touch | yes | yes | yes | yes |
| Hold start, medium 0.8 | his touch | yes | yes | yes | yes |
| Timer end, `.success` | the timer, his (KT2) | yes | yes | **yes** | yes |
| Bead lights a step, soft impact | Tess's | yes | yes | yes | no |
| Done (Finish), `.success` | his hold | yes | yes | yes | yes |

Notes: a step that starts within 600 ms of his Next gives only the medium impact (one haptic per moment; two steps starting together give one). If Product wants Tess's landings dropped in LP, only the bead row changes (the Research fixture's "zero haptics in Low Power" should be corrected either way, per the gap hunt). Tests: `lowPowerKeepsTimerEndHaptic`, `lowPowerKeepsHoldAndNextHaptics`, `beadStepHapticFollowsQuietHours`, `nextAndBeadStepGiveOneHaptic`, `lateOpenFlareHasNoHaptic`, `twoTimersEndingTogetherGiveOneHaptic`, `liveActivityUpdateCarriesNoAlert`, `timerStartedThenLockedRingsWithLowPowerOn` (the cook gate for G217).

## Open (none block the build)
1. 10 s steps in a timer's last minute: Design confirms.
2. Bead soft impact in LP: kept here (D5), Product may drop.
3. No clip yet for the timer end; the prototype has no cook scene. One 8 s clip (flare, ring, overlay, normal and RM) is cheap if Design wants to see it before Builder A builds.

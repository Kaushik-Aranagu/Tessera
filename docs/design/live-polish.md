# Live mode polish (v1 slice 13): exact values

For iOS Builder A. This is the premium moment, so these values are exact rather than "rough". All motion goes through `MotionPolicy` (`withTesseraAnimation` / `.tesseraAnimation`); all haptics follow **one haptic per meaning** (Research, instrument-robustness). Layout and behaviour are in `workout-v1.md`; this file only adds timing, curves, haptics and Reduce Motion.

## 1 · Stamp: the set seats into the stack
Fires when hold to log completes (0.8s), from the lock screen's Done, or from Tess.

| t (ms) | What happens | Values |
|---|---|---|
| 0 | The hold key's paint reaches full and the label flips to "Logged" | label crossfade 120ms |
| 0–140 | **Press:** the weight numeral and the reps centre compress, as if stamped | scale 1 → 0.94, y +6pt; `.spring(response: 0.18, dampingFraction: 0.7)` |
| 140–520 | **Carry:** a copy of the numeral (matched geometry) shrinks and travels to the set's stroke slot at y 176, then dissolves into it | x/y on separate curves: x `cubic(.55,0,.15,1)`, y `cubic(.3,0,.25,1)`; scale 1 → 0.2; opacity 1 → 0 over the last 160ms; blur 0 → 3 |
| 380 | **Seat:** the stroke starts painting left to right in its slot. **The one haptic:** `.impact(weight: .heavy, intensity: 0.9)`, the "clunk" | stroke 700ms `cubic(.3,.7,.2,1)` |
| 380 | Tess plays `done` | unchanged |
| 420 | **Rest begins in place:** the numeral rolls from the weight into the countdown (`numericText(countsDown: true)`), and turns cadmium | colour crossfade 320ms |
| 520 | The original numeral springs back to scale 1 (now showing rest) | same spring as the press |

- Remove the extra `.success` that currently follows the rigid impact (`WorkoutModeView` `lockHaptic`): one haptic per logged set.
- Undo (Tess bar or lock screen) plays the reverse: the stroke un-paints right to left (420ms) and `.sensoryFeedback(.decrease)`. Keep the current undo haptic.

## 2 · Rest on the dial
- **Entering rest:** the dial dims to 35% over 300ms (`easeOut`). The cadmium fill appears at its full width with a 2pt cadmium edge.
- **Draining:** the fill shrinks continuously toward the left, driven by a `TimelineView(.animation(minimumInterval: 1/30))` from the rest's real end date. Never step it once a second. The countdown digits roll once a second (`Tick`, `numericText`).
- **Last 10 seconds:** the fill's edge brightens from cadmium 70% to 100%, and a 14pt wet tip (blurred, 3 → 5pt) breathes on it at 1Hz. No haptic.
- **+15 drag:** past the needle by 24pt, the fill grows by 15s with `.spring(response: 0.3, dampingFraction: 0.8)`, and `.sensoryFeedback(.selection)` fires once per +15. The "+15" label rises 10pt and fades out over 900ms.
- **Skip fling:** a left fling over 600pt/s empties the fill in 420ms `cubic(.5,0,.2,1)` with `.impact(weight: .light)`.
- **Rest ends on its own:** `.impact(weight: .medium, intensity: 0.7)` (the soft "go"). The fill's last sliver fades in 200ms; the dial returns to 100% over 360ms; the numeral rolls back to the next set's weight; **one glint** crosses the numeral (`Glint`, a single 900ms pass, sheen `#FFE2A8`); and the next set's subline rises in (14pt, blur 4 → 0, 340ms).
- The Live Activity's own alert covers the locked case; don't fire the in-app haptic as well when the app is in the background.

## 3 · PR: the light sweep
Before the set, the glint already runs on the numeral every 3s while the dialled set would beat a record (`GlintIf`). When a record set is **logged**:
- **It replaces the stamp's clunk** with its own haptic pattern (`CHHapticPattern`): two transients 90ms apart (intensity 0.7 then 1.0, sharpness 0.4 then 0.8), then a continuous swell over 320ms (intensity 0.25 → 0.6, sharpness 0.2). It plays only for records.
- **The sweep:** a diagonal band of warm light crosses the whole screen from left to right: 160pt wide, angled 20°, `#FFE2A8` at 35%, blur 30, `.blendMode(.screen)` on the dark ground. It takes 900ms `cubic(.4,0,.2,1)` and starts at the seat moment (380ms).
- **The numeral:** after the sweep passes it, the numeral does one `.bouncy(duration: 0.5, extraBounce: 0.15)` scale 1 → 1.06 → 1. `.bouncy` is allowed only here.
- **The words:** the subline writes itself in with the glyph reveal (`RevealText`, 30ms per glyph): "a new best: e1RM 107.7". Tess blooms twice and says "That one goes on the wall."
- Once per record. If two records land in one session, the second gets the same treatment; there's no escalation and no confetti.

## 4 · Haptic map (live mode)
| Meaning | Haptic |
|---|---|
| Dial detent (2.5 kg) | `.selection` |
| Dial every 10 kg | `.impact(weight: .heavy, intensity: 0.5)` |
| Drum step, RPE stop | `.selection` |
| Set logged (stamp) | `.impact(weight: .heavy, intensity: 0.9)` |
| Record logged | custom pattern above (instead of the stamp) |
| Undo | `.decrease` |
| +15 | `.selection` |
| Skip rest | `.impact(weight: .light)` |
| Rest over | `.impact(weight: .medium, intensity: 0.7)` |
| Workout finished | `.success` (the only success in live mode) |

## 5 · Reduce Motion
- **Stamp:** no press or carry. The stroke appears whole with a 150ms fade, and the numeral crossfades to the countdown. The clunk stays.
- **Rest:** the fill still drains (it's information), but without the wet tip's breathing; the end glint becomes a 200ms brightness pulse on the numeral.
- **PR:** no sweep and no bounce. A static cadmium under-stroke appears under the numeral for 2s; the words appear without the glyph reveal. The haptic pattern stays.
- Every haptic stays under Reduce Motion.

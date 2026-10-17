# Stroke her and she wears the day: pre-check of the WIP branch

Spec: `tess-picks.md` sheet 18b (idea 3 stroke her, idea 4 she wears the day) and `tess-motion.md` §6 (her beat).
Checked: `git diff origin/master...origin/ios/tess-stroke2` (15 files, +559/-14). Read from the diff only; nothing was
built or recorded. Re-run this table against the PR when it lands.

Legend: MATCH = same value; DIFFERS = built, but not as spec'd; NOT FOUND = nothing in the diff.

## Idea 3: stroke her

| Spec'd value | WIP diff | Verdict |
|---|---|---|
| Hit area 64 pt; stroke starts outside it | `SoulStrokeTracker.hitSize = 64`, `began` rejects a start inside it | MATCH |
| Start inside the band 736 to 820 (dock 779) | `bandAbove 43`, `bandBelow 41` = 736 to 820 at y 779 | MATCH |
| Within 700 ms | `maxDuration = 0.7` | MATCH |
| Travel at least 40 pt | `minTravel = 40` on x only; spec does not say x-only | MATCH (x-only, note) |
| Crosses her and leaves the other side | `ended` needs entered, finger ends outside her, sign of x flips | MATCH |
| Page swipes start above 736 so no peek opens | band gate only; no peek test seen, gesture is `simultaneousGesture` on `BottomChrome` | NOT FOUND (no test) |
| Ripple 4 pt x e^(-2.6k) x sin(0.25 x - 16k), 1.6 s | `amp = 4 * exp(-t*2.6)`, `sin(x*0.25 - t*16)`, `duration 1.6` | MATCH |
| y = 0.6 of that, on a cosine | `0.6 * amp * cos(x*0.2 - t*14)`: different phase terms (0.2, 14) from the x term (0.25, 16) | DIFFERS (spec is ambiguous; confirm against the clip) |
| One blink 50 ms after the finger leaves | `strokeBlink = now + 0.05` on `strokeEnded`, drawn via `SoulBlink.once` | MATCH |
| Eyes look along the stroke (1, 0) while it crosses | `SoulGaze.alongStroke` offset (3, 0) at soul scale 1; the other gazes use pt offsets, so (1, 0) x 3 pt | MATCH |
| Mouth +0.5 curve for 900 ms | no mouth in the diff (sheet 18c is a separate PR) | NOT FOUND (expected until 18c) |
| Haptic: soft tick, `.impact(flexibility: .soft, intensity: 0.3)`, new case `.soulStroke` | `Haptic.soulStroke` with exactly that feedback | MATCH |
| Tick when the finger enters her | `strokeEntered` bumps `strokeTicks`; `.tesseraFeedback(.soulStroke, trigger:)` | MATCH |
| Second stroke within 1.6 s restarts ripple, no second tick | `if stroke == nil { strokeTicks += 1 }`, `stroke = .now`, timer restarted | MATCH |
| Refused while working, listening, carried, ask waiting | `refusesStroke`: `isWorking`, `mode == .listening`, `isAskWaiting`, `isPinned` | MATCH (carried read as isPinned, check) |
| Works on the recipe page (band pan 380 to 270 is a stroke, no peek) | `refusesStroke` also has `page != .home`, so no stroke off Home | DIFFERS |
| Eyes off: no ripple, no tick | no `tessHasEyes` check in `stroked()` or the gesture | NOT FOUND |
| `.live`: not a stroke target | gesture is on `BottomChrome` only; `LiveTessCorner` gets no stroke args | MATCH |
| Reduce Motion: no ripple, one blink and the tick | `baseFrame` returns before the ripple; blink and tick unchanged | MATCH |
| Low Power: ripple at 30 fps | ripple kept; frame rate is the existing slow-timeline path | MATCH (unverified) |
| Stroke while asleep answers his touch (board G8 default) | no resting gate in `refusesStroke` | MATCH |

## Idea 4: she wears the day (and §6 beat)

| Spec'd value | WIP diff | Verdict |
|---|---|---|
| +0.10 saturation per done | `wearStep = 0.10`, `wear(dones)` | MATCH |
| Cap +0.40 (four dones) | `wearCap = 0.40`; `min(dones * 0.10, 0.40)` | MATCH |
| Applied at the done's beat, 520 ms | `taskDone` -> `beat(landingIn: 0.52, wears: 1)`; `setWear` inside the landing task | MATCH |
| Done from elsewhere: beat at 0 | `doneElsewhere` -> `beat(landingIn: 0, wears: 1)` | MATCH |
| Extra beat saturation, dries away | `+0.25 x gather` (picks 18b says +0.25; §6 says +0.3 and 1.45 to 1.75 to 1.45) | DIFFERS (§6 vs 18b disagree; the build follows 18b) |
| Beat 940 ms | `duration = 0.94` | MATCH |
| Gather: satellites to 55% over 180 ms, release over 320 ms | `ramp(0, 0.18, .easeOut) * (1 - ramp(0.18, 0.32, house curve))`; pull 0.55 | MATCH (§6 says settle spring; build uses the house curve bezier .3,0,.2,1) |
| Brighten 1 to 1.12 | `scale *= 1 + 0.1 * amount` (1.10) | DIFFERS (1.10 vs 1.12) |
| One blink at the landing (160 ms) | `SoulBlink.once(since:)` from `beat`; duration is the existing `SoulBlink.duration` | MATCH (check 160 ms) |
| Two beats inside 940 ms merge | `abs(landing - last) < duration` merges, wear still counts | MATCH |
| Done while she listens waits | `beatAfterListening` | MATCH |
| Undone within UNDO: does not count | `taskUndone` -> `setWear(wearDones - 1)`; a done that had not landed is counted at landing only | MATCH (check UNDO-before-520 ms) |
| Quiet-hours swell guard (board G7: no swell in quiet hours) | `swells: mode != .resting`; the colour still lifts | DIFFERS: keyed on `.resting`, which the diff still ends at 06:00, not 07:00 (23:00 to 07:00 is quiet hours) |
| Resets at 04:00 over the first idle minute, never a step | `rollWearDay`, `wearFade` from yesterday's value over `wearReset = 60` s | MATCH (the "idle" part is not gated: the fade starts at the first roll) |
| Counted per day from 04:00 | `wearDayKey` / `wearDonesKey` in the wake store, persisted across launches | MATCH |
| Everywhere she is drawn, `.live` included | wear is read in `baseFrame` for every TessSoul; only `BottomChrome` was seen passing `wear:` (also edits to `LiveTessCorner` and `WorkoutModeView`, 4 lines each) | MATCH (confirm the corner passes `wear`) |
| Reduce Motion / Low Power: same colour | `wear(date)` applied before the `reduceMotion` return; gather (motion) is 0 under Reduce Motion | MATCH |
| Eyes off: same | no eye gate on wear | MATCH |
| Multiplies the day's palette (§7), does not replace | adds to `look.saturation` | MATCH (confirm it is a multiplier of the palette's own saturation) |
| Lab script: five dones at 0.8, 2.0, 3.2, 4.4, 5.6 s | `-soulScript wear`: sleep 2.4 + 0.8, then five `taskDone`, 1.2 s apart. Each lands 0.52 s later, i.e. beats at 1.32, 2.52, 3.72, 4.92, 6.12 s | MATCH |
| Done rows leave holes (prototype only, do not copy) | not built | MATCH |
| Test: five dones = +0.40, undone = +0.00, 04:00 = +0.00 | `SoulBeatTests` (75 lines) added; not read in detail | NOT FOUND (read the tests when the PR lands) |

## Commands once the PR lands

Record the candidate with the lab recipe (`-soulScript wear` for the wear clip; the stroke pan is the UI-automation
drag from (296, 792) to (396, 770) over 350 ms, starting at 1.4 s), then, from the repo root:

```bash
docs/design/motion/prototype/check-pick.sh stroke <stroke-candidate.mp4>
docs/design/motion/prototype/check-pick.sh wear <wear-candidate.mp4>
```

Pass bar: mean SSIM 0.90 or more and no beat frame under 0.80. Beats checked: stroke 1.4 / 1.75 / 1.8 / 3.0 s, wear
1.32 / 2.52 / 3.72 / 4.92 / 6.12 s. Read timing by eye from the `beats.png` each run names (default out dir
`/tmp/check-stroke`, `/tmp/check-wear`).

## Fix before recording

1. Allow strokes off Home (drop `page != .home`), or get Product to confirm the recipe-page clause is out.
2. Decide the brighten (1.10 vs 1.12) and the beat saturation (+0.25 vs +0.3).
3. Make the quiet-hours swell guard follow quiet hours (23:00 to 07:00), not `.resting`, and move her wake to 07:00.
4. Gate the ripple and tick on "Tess has eyes".
5. Add the recipe-page band-pan test (no peek).

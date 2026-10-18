# Tess in motion: the build check kit (board item 10)

For Builder A (before the PR) and QA (the review): how to tell whether the built soul matches the lab's recordings, frame by frame, and whether it holds 60 fps and the battery budget. The references are `recordings/tess-motion-*.mp4` (60 fps, 393 × 852 pt at 2×, a 64 pt caption strip under the phone that the kit cuts off). The values they were made from are in `tess-motion.md`; the tests are in `tess-motion-build.md`.

## 1. Record the build the same way
- Simulator iPhone 17, `-demoTime 07:42 -theme obsidian` (then `porcelain` for the light pass), Reduce Motion off, 60 fps capture (`MobileBuildMCP` video, or `xcrun simctl io booted recordVideo --codec h264 --force out.mp4`).
- One clip per scene, started 1 s before the first beat, same gestures as the reference: the caption strip under each reference names the beats, and the table below gives their times.
- Drag and the hold are driven by the UI automation script (`MobileBuildMCP` tap/drag at the points in the table), not by hand, so the timing is the same every run.

| Scene | Reference | Beats to compare (s) | Gesture |
|---|---|---|---|
| Eyes | `tess-motion-eyes.mp4` | 1.15 (blink), 2.2 (glance to the line), 5.2 (listening), 8.0 (Done starts, eyes gone), 9.9 (eyes back) | none; the setting on |
| Working | `tess-motion-work.mp4` | 1.8 (fade), 2.5 (split), 4.5 (readers under row 2), 9.1 (gather), 9.7 (Done) | a Plan my day ask |
| Think | `tess-motion-think.mp4` | 1.4, 2.8, 6.6, 7.3 | a Claude miss with nothing on the page |
| Drag | `tess-motion-drag.mp4` | 1.62 (pick-up), 2.4 (carry), 3.5 (drop, bottom-left), 5.85 (flick), 6.4 (home) | press at (346, 779), move after 120 ms along the recording's path, release; then from (47, 779) a flick toward (230, 780) |
| Roam | `tess-motion-roam.mp4` | 1.6 (leaves), 2.4 (arrives), 3.1 (works), 5.5 (Done in place), 7.4 (home), 10.4 (rides the scroll), 11.6 (lets go) | a change to row 2; then a 330 pt scroll over 1.6 s |
| Reward | `tess-motion-reward.mp4` | 1.62 (armed), 2.12 (let go), 2.64 (bloom, her beat), 3.06 (dry) | swipe right on row 1 to 140 pt, hold 500 ms, release |
| Listen and ask | `tess-motion-ask.mp4` | 2.1 (bloom), 5.7 (pause), 9.1 (gather back), 12.9 (hold swells), 15.9 (Claude: split), 25.8 (ask wait, the lean), 29.2 (tap) | tap her, tap Speak; hold 400 ms; a set ask |
| Pages | `tess-motion-pages.mp4` | per page: 1.5 (leaves), 2.5 (works), 5.3 (Done), 7.2 (home); Review: 2.7 (readers) | one change on each tab |
| Colour | `tess-motion-colour.mp4` (and the four looks) | 1.2 / 1.32 / 1.44 (the three pools start), 2.1 (wet), 4.0 (dry), 17.0 (the cut: work wins) | a repaint, then a capture 600 ms into the last |
| Reduce Motion | `tess-motion-reduce-motion.mp4` | 1.6 (crossfade to working), 6.2 (crossfade back) | Reduce Motion on |
| Outside | `tess-motion-outside.mp4` | 4.0 (Go pushes in, the washes warm), 7.0 (tap), 7.75 (the return line; her glance), 8.2 (eyes back) | a rest Live Activity on the Lock Screen at 0:04; tap it; the soul crop is the dock, the face is the eye's check against `lockscreen.md` (nothing of her on it) |
| Minute | `tess-motion-minute.mp4` | none by frame: count and cadence (7 to 15 blinks, gaps 3 to 8 s, one double, 160 ms each); soul-crop SSIM over any 10 s window ≥ 0.92; nothing outside the crop changes | Home at rest, eyes on, 60 s, no touch |
| Low Power | `tess-motion-low-power.mp4` | 1.8 (fade), 2.5 (split: six lights), 5.6 (gather), 6.4 (Done) | the same Plan my day ask with Low Power on (device) or `-lowPower` (simulator); no readers in any frame |
| Lens | `tess-motion-lens.mp4` | 0.8 (hold: lens forms, pages shrink), 2.2 (the tick), 3.4 (release), 7.0 (hold while reading: readers home by 7.36) | hold the tab row on TODAY 260 ms, slide one word right over 800 ms, let go; then a Plan my day ask and the same hold at 1.4 s into the scan |
| Pick 1, lights follow the page (18a) | `picks/tess-pick-wander.mp4` | 0.6 (split), 1.7 (readers on Push A), 2.42 (12:15 pm), 3.14 (Call the bank), 5.2 (gather), 5.98 (Done) | an ask whose `touched` is [Push A, 12:15 pm, Call the bank, 9:30 am, Book the dentist]; the dock lights are seeded, so compare the readers, not the dock |
| Pick 2, she wakes with you (18a) | `picks/tess-pick-wake.mp4` | 1.0 (eyes start opening), 1.4 (open), 1.5 (stretch), 2.1 (widest, back), 3.4 (blink) | the first foreground after 04:00 (`-demoTime 07:42`, fresh day) |
| Pick 3, stroke her (18b) | `picks/tess-pick-stroke.mp4` | 1.4 (finger enters, the tick), 1.75 (leaves), 1.8 (blink), 3.0 (still) | a pan from (296, 792) to (396, 770) over 350 ms, starting at 1.4 s |
| Pick 4, she wears the day (18b) | `picks/tess-pick-wear.mp4` | 1.32 / 2.52 / 3.72 / 4.92 (beats, +0.10 each), 6.12 (fifth beat, still +0.40) | five `taskDone`s at 0.8, 2.0, 3.2, 4.4, 5.6 s; the eye checks the saturation steps, the cap and that the rows stay as built |
| Mouth (18c) | `picks/tess-pick-mouth.mp4` (with a 5× magnifier over the page) | 1.0 (soft o), 2.5 (thinking: right corner up), 4.0 (smile with her line), 6.6 (beat smile), 8.0 (ask waiting), 10.0 (her miss: −0.35), 12.4 (face out 120 ms), 14.4 (back 200 ms) | a tap, a Speak, a local capture, a `taskDone`, a set ask, a failed Claude call, then a Done; the magnifier crop is 140 × 140 px at (622, 1488) of the 2× frame, also in `picks/*-beats.png` |
| Pick 5, she sleeps at night (18d) | `picks/tess-pick-sleep.mp4` | 1.0 (asleep: lids shut, slow), 2.85 (right eye opens), 3.8 (her clock back to 1×), 5.0 (left eye follows) | open the app at 23:30 (`-demoTime 23:30`) at 2.6 s |
| Pick 6, she watches what you hold (18d) | `picks/tess-pick-held.mp4` | 1.0 (eyes to the row), 2.4 (following it up), 3.6 (drop), 3.8 (blink, eyes back) | lift row 3 at 1.0 s, move it to the top, drop at 3.6 s |
| Pick 10, the rest clock (18d) | `picks/tess-pick-clock.mp4` | 1.8 (eyes to the timer; no lean), 4.2 (Go: eyes back), 4.3 (blink) | a 6 s rest in the live workout; check nothing but the eyes moves |
| Pick 7, the nudge (18e) | `picks/tess-pick-nudge.mp4` | 1.6 (4 pt lean, eyes on the row), 2.9 (back), 3.3 (blink) | an item timed 10 min after `-demoTime` |
| Pick 8, she hears you type (18e) | `picks/tess-pick-typing.mp4` | 0.96, 1.33, 1.6, 1.96 (one pulse per word) | type "call mom at six" at 11 characters a second; the beat strip's crop is at (312, 1316) px |
| Pick 9, the peek (18e) | `picks/tess-pick-peek.mp4` | 2.2 (rise 5 pt), 3.6 (blink at the top), 3.9 (back down) | scroll 140 pt to the last row over 1.5 s from 0.8 s |
| Pick 11, under the glass (18f) | `picks/tess-pick-tilt.mp4` | none by frame: ±2 pt mains, satellites 1.7×, eyes ±0.6 / ±0.4 | the prototype tilts on a sine; on the simulator, drive the attitude from a test hook; on the device, tilt by hand and check only the bounds |
| Side turn, every screen (sheet 75) | `picks/tess-pick-side.mp4` | 1.0 eyes 0.4 right (380 ms); 1.42 her line; 2.8 stop 2, she's still; 4.6 back to stop 1, still; 6.2 eyes 0.4 left; 6.88 ahead | swipe left above 736 to stop 1, pull on to stop 2, swipe right twice; her centre and the band never move with the body (compare the soul crop over the whole clip) |
| Area index (sheet 73 A) | `picks/tess-pick-index.mp4` | 1.0 (pull starts), 1.31 (20 pt, index forms), 1.78 (90 pt, held, first pick, `.selection`), 2.47 (TODAY under the finger), 3.07 (back on TRAINING), 3.6 (let go, word flies 460 ms), 4.06 (lands, `.impact(.soft)`), 5.45 (tap the name, index opens), 6.75 (tap TODAY), 6.9 (flies 460 ms), 7.36 (lands) | pull a tab page down at offset 0 (finger 300 to 400 pt), cross TODAY and back, let go; then tap the name and a row; Tess stays at HOME and never moves; values the sheet omits are in the note below |
| Title accent (sheet 72, round 2) | `picks/tess-pick-accent.mp4` | 1.0 / 2.2 / 3.4 (sets 1 to 3: p 0.21 / 0.43 / 0.64, 600 ms tweens), 4.6 (done, 3 pt strike 420 ms), 5.02 (250 ms lift), 5.5 (dry starts, 2 s), 7.5 (dried, strike stays) | four sets, one every 1.2 s from 1.0 s; the word that matters ("12:15 pm") is in the area colour from set 1 |

**One command per picks PR:** `docs/design/motion/prototype/check-pick.sh <pick> <candidate.mp4> [out-dir]` (picks: wander, wake, stroke, wear, mouth, sleep, held, clock, nudge, typing, peek, tilt, side, index, accent). It runs `compare.sh` at that pick's beat times against `recordings/picks/tess-pick-<pick>.mp4` and prints the mean SSIM, the worst beat frame and PASS or FIX FIRST. Timing is still read by eye from the `beats.png` it names.

## 2. Compare frame by frame
`docs/design/motion/prototype/compare.sh <reference> <candidate> <out-dir> "<beats>" [crop]` (needs ffmpeg). It brings both clips to 393 × 852 pt at 60 fps, crops the soul (default the bottom-right 160 × 160 pt; pass `x:y:w:h` in points for roam, drag and the pages), and writes:
- `ssim.txt`: the mean SSIM of the soul crop over the whole clip, and `worst.txt`: the ten frames with the lowest SSIM, as times.
- `beats.png`: at each beat, the reference beside the build, one row per beat, for the eye.

**Pass:** mean SSIM ≥ 0.90 and no beat frame under 0.80; and in `beats.png` every beat sits within 2 frames (33 ms) of the reference. The soul's paint can't match pixel for pixel (Canvas blur vs. the browser's), so SSIM is the measure, not a pixel diff; a build that fails the number but passes the eye at every beat is a Design call, not a fail. The whole page is not compared: only the soul crop, so a page's own differences (fonts, rows) never fail the soul.

What the eye checks that SSIM can't: the order of the lights leaving and landing (satellites out first, readers home first), the eyes' blink shape (closed for 2 frames at the middle), the lean's direction (toward her line), and that nothing on the page moved for her.

## 3. Frame rate
- Instruments › Core Animation FPS (or the Xcode FPS gauge) on the device, Release build, during `work` with Home scrolling under her, and during `drag`. **Pass:** 60 fps held with no frame over 16.7 ms outside the first 2 frames of a mode change; any frame over 33 ms is a fail.
- Time Profiler on the same run: `SoulRenderer.draw` plus the readers' canvas under 4 ms a frame on iPhone 17 (the budget in `tess-motion.md`); `TessSoul.body` not re-evaluated more than once a frame (an `@Observable` leak shows here as a body per tick).
- The simulator is not the measure for frame rate; it's for the compare only.

## 4. Battery
- Instruments › Energy Log, 10 minutes on the device, screen on, in three runs: (a) Home at rest (idle at 30 fps, eyes on), (b) ten working states of 15 s each, (c) Home in the background. **Pass:** (a) energy impact Low throughout; (b) no more than Medium during the work and Low within 2 s of each Done; (c) zero: `TimelineView` paused, nothing scheduled.
- A cheaper daily check: Settings › Battery on his phone the morning after, Tessera's share under what Messages uses. If it isn't, the first suspect is a `TimelineView` that didn't pause (off screen, background, Speak layer), the second is the readers' canvas being the page's width.

## 5. The run sheet
1. `scripts/test.sh` green (the new tests in `tess-motion-build.md`).
2. Record the fourteen scenes on the simulator, Obsidian and Porcelain, plus the pick rows for the PR at hand (references in `recordings/picks/`, `-light` for Porcelain; `picks/tess-pick-*-beats.png` holds the soul crop at each beat, for a quick look before `compare.sh`).
3. `compare.sh` on each; attach `beats.png` and `ssim.txt` to the PR, with the worst frames looked at.
4. Frame rate and the three Energy Log runs on the device, numbers in the PR.
5. Design reviews the simulator recordings beat for beat (its item after 58).

## Values the sheets don't give (assumed in the index and accent references; Design to confirm)
- Sheet 73: the flight's curve (the house curve is used), the page's rise and the sheet's close timings (460 ms, as the flight), the timing and curve of a tap-open (460 ms, house curve), the scale anchor of the 0.9 page (screen centre), the glass fill, each row's word and live-line baselines inside its 104 pt slot (word at +36, line at +66), the rows' form-in (a fade over the stagger), and the exact pull-to-finger ratio (1:1 here).
- Sheet 72 round 2: how the 250 ms "lift" is drawn (here the whole title reaches the area's 72% mix, starting when the strike ends), what "quiet ink at 50%" means (here ink at 50% opacity, weight 500), what the dry's 900 ms is measured from (the done), the step values of p (here 0.85 x sets/4 until done), and the font weight axis (Inter Tight variable, 640).

## 6. Never-diffused checks (from tess-never-diffused-audit.md)
1. **Reduce Motion Working keeps full opacity.** In a Reduce Motion recording of Working, the mean alpha of the three mains equals Idle's (same crop, within 2%). Fail on the old x0.6 grade.
2. **Asleep keeps full pigment.** `prototype/check-pigment.sh idle.mp4 sleep.mp4`: crop the soul box, `ffmpeg -vf "crop=W:H:X:Y,scale=1:1" -f rawvideo -pix_fmt rgb24 -` for a frame of each clip, compare the RGB triplets; pass if each channel is within 2% (eyes closed, pigment unchanged). The script ships with the first sleep PR.
3. **No poster frame in the 500 ms working fade.** The poster, thumbnail and contact-sheet times listed in each pick sheet must fall outside the fade window; QA reads the list.

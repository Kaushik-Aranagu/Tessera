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
2. Record the thirteen scenes on the simulator, Obsidian and Porcelain.
3. `compare.sh` on each; attach `beats.png` and `ssim.txt` to the PR, with the worst frames looked at.
4. Frame rate and the three Energy Log runs on the device, numbers in the PR.
5. Design reviews the simulator recordings beat for beat (its item after 58).

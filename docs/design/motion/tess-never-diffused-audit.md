# Tess never diffused: audit of current motion scenes (item 28, Oct 17)

Rule (Kaushik 12:46 PM): never a diffused or faded Tess as imagery ("looks like it died"). Audited
docs/design/motion/prototype/tess-motion.html (at 0b6b824) and tess-*.md. Imagery here means any still, clip frame or
banner where she is the picture; the live soul's own working colour is his 11:58 PM Oct 15 ask and is listed separately.

## Fix (reads as dimmed Tess)
1. Reduce Motion grade: opacity x0.6 over the whole soul (html line 530 `lerp(1,.6,reduced)`), plus satellites at 40% (tess-motion.md section 13, tess-quiet-versions.md Working row). In Reduce Motion she sits at 60% for the whole state. Fix: keep full opacity, loosen the three mains and drop the satellites only; the colour grade may still drain.
2. Sleep (pick d, 23:00 to 07:00): "muted colour" with closed eyes (tess-quiet-versions.md Sleep row). Fix: closed eyes and slower breath carry sleep; keep the pigment at the look's full strength.
3. Reference clips that freeze mid-fade: any poster or contact-sheet frame taken during the 500 ms working fade (saturation .62, opacity x.9, halo gone). Fix: pick poster frames from rest or the gather's last frame, never the fade.

## Watch (small, no change needed)
4. `pulse` keyframes opacity .85/.92 (line 93): a 10 to 15% dip inside a pulse, never held. Fine; do not extend it.
5. Done fades eyes and mouth out in 120 ms, back in 200 ms: only the face, the soul stays whole.
6. Splash ring opacity 0 to 1 to 0 (line 96): a ring, not her.

## Live working colour (his own ask, keep)
7. Working fade to saturation .62 and the split into 12 lights, gather back to full colour. It is motion, not imagery; it always ends whole. Do not use a frame from it as a picture.

## Not applicable
Widgets, Lock Screen card and the Live Activity do not draw her (tess-picks.md, board item 9). The new imagery (sheet 88/91 pockets) must show her crisp and whole or not at all.

## Acceptance list for Builder A (all three must hold)
1. Reduce Motion, Working: the soul's group opacity stays 1.0 (no x0.6). The three mains loosen 1.5x in place, satellites drop, colour may drain to the working grade. Check: a frame of Reduce Motion Working has the same alpha on the mains as Idle.
2. Asleep (23:00 to 07:00): eyes closed and the slow breath carry sleep; pigment strength equals Idle's in every look. Check (named test): `prototype/check-pigment.sh <idle.mp4> <sleep.mp4>` (see tess-motion-check.md section 6) crops the soul, averages it to one RGB with ffmpeg and fails if any channel differs by more than 2%.
3. No poster, thumbnail, contact-sheet or QA still is taken inside the 500 ms working fade; use rest or the gather's last frame. Check: frame.mjs poster times are listed in each sheet and none falls in the fade window.
Each item gets a line in tess-motion-check.md so QA tests it.

## Board items 1-35 pass (item 39, Oct 17, PM)
Only these board items dim or fade her: item 3/5 working fade (his own ask, live motion, ends whole: keep), item 13 quiet versions (fixes 1 and 2 above), M1 error notice (it dims Tess's LINE text to 60% on tap for 150 ms, not the soul and not imagery: keep, never use that frame as a picture), item 22 sleep (fix 2). Items 26-35 so far add no soul dimming; 32 (Low Power = Reduce Motion) must not bring back the x0.6 opacity (fix 1). No new fixes beyond the three.

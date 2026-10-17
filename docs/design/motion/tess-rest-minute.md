# Tess at rest: a full minute of Home, untouched (board item 12)

The clip is `recordings/picks/tess-rest-minute.mp4`: Obsidian, Home on Today at 7:42, 60 s at 60 fps (3600 frames), nobody touching anything. It is the `minute` scene of `prototype/tess-motion.html`, recorded with `node record.mjs minute obsidian out.mp4 2` (no new scene was needed; `tess-motion.md` section 12 describes the same minute in prose and this sheet replaces its estimates with counts measured on this run). Blinks are seeded (seed 7), so the build can be compared by count and cadence, not frame by frame.

## 1. The idle budget: what moves in 60 s

| What | Count in 60 s | Detail from the run |
|---|---|---|
| Blinks | **13** in **10 occasions** | at 3.59, 9.31, 15.67, 23.02, 26.39, 30.44, 38.40, 43.32, 46.68, 54.30 s; three of the ten are doubles (second blink 0.25 s after the first: at 30.69, 38.65, 43.57 s) |
| Gap between blink occasions | 9 gaps | shortest 3.36 s, longest 7.96 s, mean 5.64 s; first one at 3.59 s |
| Eyes closed | 13 x 0.16 s = **2.08 s** | 3.5% of the minute; each blink is a 160 ms close and open |
| Gaze shifts (glances) | **0** | the eyes look straight ahead the whole minute; a glance needs something to appear on the page |
| Drift: mains' lift | 6.7 cycles | 9 s period, delays 0 / -6 / -3 s, one dab at a time |
| Drift: satellites | 5.5 / 8.0 / 6.7 cycles | periods 11 / 7.5 / 9 s |
| Halo breath | 8.6 cycles | 7 s period, scale 0.8 to 1, opacity 0.6 to 1 |
| Chrome breath | 18.75 cycles | 3.2 s period, scale 1 to 1.08 |
| Colour changes (repaint, grade, pigment) | **0** | the palette does not move at rest; a repaint needs idle for 2 h and is at most 3 a day |
| Roam, split, Done, lines, haptics, sound | **0** | nothing owed, nothing performed |

Reading it plainly: in a minute the only events a person could point at are about ten blinks. Everything else is continuous, slow, periodic motion with no start and no end, which the eye stops seeing.

**Measured on the recorded frames** (clip downscaled to 196 x 458 for the measure):
- Outside the soul, the page is identical in every frame. Checked on the source canvas at 59 sample times (every 0.5 s) across the minute: **0 changed pixels** (the small differences seen in the encoded clip are compression noise on thin text, not motion).
- The soul changes in 38% of frame pairs (a changed pixel above a 2 of 255 grey step); the other 62% are exact repeats. Her per-frame mean change is **0.026 of 255 at the median and never above 0.154**; the biggest steps are blinks and are no larger than the drift's.
- The soul's changed area stays inside a box of about 61 x 69 points around her corner; nothing reaches the text.

## 2. The calm test: what "ignorable" means in numbers

She is ignorable if a minute at rest passes all of these. QA runs them on the build the same way they were run on the clip.

1. **Page untouched.** 0 changed pixels outside the soul's box in any frame.
2. **Blinks are rare and irregular.** 7 to 15 blinks in 60 s (the clip has 13); every gap between occasions 3 to 8 s (the clip: 3.36 to 7.96); a double at most one occasion in three (the clip: three of ten); each blink 160 ms, plus or minus one frame at 30 fps; eyes closed under 5% of the minute (the clip: 3.5%).
3. **No gaze moves.** 0 glances, 0 eye drift, 0 pupil motion without an event; the eyes never look at him unprompted.
4. **No colour event.** 0 pigment or grade changes; the soul's mean colour over any 10 s window stays within 2% of its minute mean.
5. **Nothing is fast.** The slowest period in the budget is 11 s and the fastest 3.2 s (the breath); no motion in the minute has a period under 3 s except the 160 ms blink. No frame-to-frame soul change above 0.2 of 255 mean on the 196 x 458 measure (the clip's peak: 0.154).
6. **Nothing arrives from outside.** 0 haptics, 0 sound, 0 lines, 0 Live Activity updates, 0 widget reloads caused by her.
7. **Never still while visible.** A window of 4 s with no change anywhere in the soul fails the other way: a still soul reads as dead. In the clip the longest run of identical soul frames is 0.47 s (on the 2 of 255 threshold).
8. **Cost stays flat.** Same Energy and frame-time lines as `tess-motion.md` section 12 (30 fps, under 2 ms a frame, Energy Low, no layout); the fifth minute costs what the first did.

## 3. Values for Builder A

- **Blinks:** draw a gap uniformly from 3 to 8 s after each occasion; first blink 2.4 to 4.4 s after the page appears; one occasion in five is a double with the second blink 0.25 s after the first (the clip has three in ten, which is chance; the rule is one in five and QA allows up to three in ten occasions). Blink length 160 ms (5 frames at 30 fps, closed on frame 3).
- **Gaze:** straight ahead at rest, always. No random glances, no idle look-around.
- **Drift and breath unchanged from the build:** chrome breath 3.2 s; mains' lift 9 s (delays 0 / -6 / -3); satellite drift 11 / 7.5 / 9 s; halo 7 s. Do not add a new idle motion and do not shorten any period.
- **Colour:** none at rest. The pigments are constant while idle.
- **Tick:** 30 fps for idle, as built; timeline paused when she is off screen.
- **Quiet rule:** no event at rest may be added without an entry in the table in section 1; if a pick adds one (for example the stroke or the hold watcher), it is an event with a cause, never a timer.
- **How to check:** record the device for 60 s with nothing touching it, count blinks and gaps against section 2, then compare the page crop against the first frame; any changed pixel is a fail.

## 4. Re-recording

`cd docs/design/motion/prototype && node record.mjs minute obsidian ../../recordings/picks/tess-rest-minute.mp4 2` takes about 8 minutes (3600 frames); then `ffmpeg -i in.mp4 -c:v libx264 -crf 22 -preset slow out.mp4` if it needs to fit under 3 MB. The recorded clip is 1.2 MB.

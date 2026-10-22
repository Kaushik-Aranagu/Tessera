# Set marks: the ink ring (motion and build sheet, replaces the set circles)

Kaushik, Oct 21 PT (Design and motion lab threads): 4:00 PM "I don't like circles ... or a wave ... or a bar"; 4:27 PM the mark must show the number of sets, and 3, 4 or 5 sets must each be complete in themselves; 5:06 PM no squares, "something cooler, has life, not super complex"; 7:50 PM "something like orbit but better"; 8:04 PM "very mechanical ... like what Claude's things do when it's thinking"; 9:09 PM picked the ring: "move around, orbit around, collapse into and come back from one blob, randomly ... we don't need perfect circles ... the dots themselves can be liquid or ink drops, having little movements within themselves"; 10:29 PM "something like this but better organized and looks a little neater, smaller blob sizes"; 10:50 PM "why are there gaps when they are orbiting ... a little more subtlety than just revolving" (he meant a drop or two looking missing, not a line joining them); 11:10 PM "smaller drops still"; 11:29 PM, after seeing four options, "looks okay, let's go ahead" (the chasing pulse, option D, is the one specified). Design passed the shapes and the gather with its conditions (Oct 21). This sheet replaces the ink drops and brush circles of docs/design/set-marks-tabs-108.md section 1 on the Training rows, the live set and the exercise History tab. Design owns the drawing; the lab owns the rows below. Study: design/mockups/set-marks-even-options-small.png and design/studies/set-marks-even-options-small.html (option D, project files, browser mock at 3x); the gather is still the one in design/clips/set-marks-ink-ring-v2.mp4.

## 1. The mark
- One ring per exercise. One drop per logged set, so the mark shows the number of sets and 1, 2, 3 ... are each a finished shape. There is no frame to fill and nothing stands for "not yet logged".
- Count rule: even spacing on one ring, always (no drop ever looks missing; see check 10) up to 8 sets; from 9 an inner ring at half the radius takes the extras (9 = 8 outside plus 1 inside, 12 = 8 plus 4).
- States: logged = ink; short (fewer reps than planned) = pale ink (ink at 25% live, 42% in the row so it still reads); best = the day's stage colour, never a fixed red. Nothing else ever changes a drop's colour: the swell, the gather and the orbit are shape and position only (Design rule). Say "best", never "record".
- Live set: the ring is 36 pt across beside the 108 pt number; a drop is about 4 pt across (smaller than the first pass), drawn as liquid (a soft wobble of its own outline, drops may merge for a moment and part again). This is the one place a soft edge is allowed, because it is the family of his picked ink drops (sheet 108); nothing here is blurred, glowing or shadowed.
- Row (Training row, History): the same count as a flat, still ring 14 pt tall with 2.5 pt round dots and the same three colours. No liquid, no tail, no swell, no gather. It sits where the circles were, left of the detail line, and the row does not grow (Builder A confirms with one still each of a 4-set and a 5-set row).
- Private workout: plain outline dots in both sizes, nothing lit, no best drop, no ripple, no gather, no values in any label.

## 2. Motion (live mark only; the row never moves)
| Moment | Normal | Reduce Motion | Low Power |
| --- | --- | --- | --- |
| At rest | The drops stay evenly spaced on the ring, which turns slowly (about 0.16 rad/s); the ring is not a perfect circle only in each drop's own wobble, never in spacing. A chasing pulse runs round it: one drop at a time swells (up to 55% larger) and lifts outward (up to 10% of the ring radius), then the next follows, a full lap about every 1.8 s, in the direction of the turn. The pulse never changes a colour. Each drop's outline wobbles on its own (lab default, from the study; Design may tune) | The finished ring, still; no swell, no orbit, no wobble | Same as Reduce Motion |
| A set is logged | The new drop flies in from outside the ring on `Theme.Motion.house` (one spring), the others re-space to the new even spacing with the same spring, and the chasing pulse starts from the new drop (it is the first to swell, about 0.6 s). One haptic as the drop lands: the set-close haptic a logged set plays today, not a new one | The finished ring with the new drop, 150 ms crossfade; the haptic stays | Same as Reduce Motion |
| The gather | Now and then (a random gap of 7 to 10 s, lab default) the drops ease to the centre over 0.55 s, hold as one ink blob for 0.4 s with a slow breath, and burst back to their places over 0.7 s on one spring with a little overshoot. The blob is one clean shape, no halo. A best drop leaves the blob first and joins it last, so there is never a mixed red-brown colour. A gather never starts within 1.5 s of a set landing, so the new drop and the count are always seen first. Never on the row, never in private | No gather | No gather |
| Plan changes (a set added or removed by hand) | Same re-space on one spring, no fly-in, no ripple, no haptic | 150 ms crossfade | Same as Reduce Motion |
| Tap a drop | The tap target is the whole ring and the nearest drop wins, so a moving drop is never missed. Its exact line shows under the row in inkSecondary, 16 ("Set 3: 85 kg x 9"), and the drop lifts 2 pt on `Theme.Motion.snappy`; tap again or elsewhere to clear | Line crossfades, no lift | Same as Reduce Motion |

The soul never plays a haptic of her own here. Only `withTesseraAnimation` and `.tesseraAnimation` animate the mark; the rest-state orbit and wobble run on one `TimelineView` at 60 fps (30 fps after 20 s on screen, as the soul does), paused off screen.

## 3. VoiceOver
- The mark is one element and always says the count, gathered or not: "Bench press, 4 sets logged" (private: the same).
- Each drop: logged "Set 1, 8 reps, 80 kilograms"; short "Set 2, 6 of 8 reps, 85 kilograms"; best adds ", best". A private workout reads "Set 1, logged" with no values.
- Logging a set announces its drop line once; the gather announces nothing.

## 4. Build checks
1. `ringCountMatchesSets`: after every landing and after every gather burst, and in a frame sampled during the blob hold (model and VoiceOver count still equal the sets), the number of drops equals the number of logged sets, counted in code for 1 to 8 sets (and 9 to 12 with the inner ring).
2. `ringStatesDistinct`: ink, pale and stage colour differ in a snapshot at both sizes and at AX5; no fourth colour appears in any frame of a pulse or gather. At row size pale ink (filled) is told apart from a private outline dot (hollow) by shape, not only by tone.
3. `ringRowIsStill`: the row mark never animates, gathers or changes count while the live mark moves; row dots are round, 2.5 pt, no filter.
4. `ringLandingUsesHouseSpring` and `ringReduceMotionCrossfade150`: the fly-in and re-space use the house spring only; Reduce Motion and Low Power show a 150 ms crossfade and no orbit, swell or gather.
5. `ringOneHapticPerSet`: one haptic per logged set, none on plan changes, taps or gathers.
6. `ringGatherNeverAfterLanding`: no gather begins within 1.5 s of a landing.
7. `ringBestUsesStageColour`: the best drop reads the day's stage colour in every look, in both sizes.
8. `ringPrivateNoValues`: a private workout shows outline dots only, no gather, and no label carries a rep count or weight.
9. `ringNoCirclesOrWaves`: the wave and the brush circles are gone from live mode, the Training row and History.
10. `ringSpacingEven`: in any frame outside a landing glide and a gather, the angle between neighbouring drops is within 3% of 360 / n (inner ring likewise), so no drop ever looks missing; no line or thread joins the drops.

## 5. Asks
- Builder A: a `SetRing` view replacing the set circles in live mode, the Training row and History, following sections 1 to 4. No review switch; this is the only mark.
- Design: tune the rest-state numbers against the v2 study if they read too busy on the phone; confirm the 36 pt live ring fits the live page.
- Ships in the release after Oct 21's.

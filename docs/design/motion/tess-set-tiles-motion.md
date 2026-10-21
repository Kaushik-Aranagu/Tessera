# Set tiles: motion and build sheet (replaces the set circles)

Kaushik, Oct 21 4:00 PM PT (Design thread): "I don't like circles ... I would want a better representation than circle or a wave or whatever, or a bar." Design picked the Tesserae tile (the app is called Tessera); Design passed the count layouts and the states at 11 pt (Oct 21). This sheet is the motion and build side. It replaces the ink drops and brush circles of docs/design/set-marks-tabs-108.md section 1 on the Training rows, the live set and the exercise History tab. Design owns the drawing; the lab owns the rows below. Study boards: design/mockups/tesserae-counts-1-to-8.png and design/clips/set-marks-ideas-tesserae-facets-leaf.mp4 (project files; the clip's chips-are-reps reading is wrong, one chip is one planned set).

## 1. The mark
- One tile per exercise. One chip per planned set, flat and crisp: no blur, no glow, no highlight, no shadow, rounded corners at 12% of the chip.
- Layouts by planned count: 1 one chip; 2 two side by side; 3 an L (the empty corner is the shape, never "short"); 4 two by two; 5 three over two; 6 two rows of three; 7 and 8 two rows of four. 9 and 10 two rows of five (lab default, Design to confirm).
- Chip states, told apart at 11 pt: logged = solid ink; short = pale chip (ink at 20%); not logged yet = outline chip (ink at 55%, hairline); best = the day's stage colour, never a fixed red. A set past the plan adds a chip and the layout moves to the next count.
- Sizes: Training row 11 pt tall, flat; live set 28 pt tall beside the 108 pt number. Chip size is the tile height divided by the row count, never more than half the tile height.
- Heavier sets draw a darker ink (lab default: ink at 65% to 100% over the lifter's 70 to 100 kg range); a private workout draws none of this.
- Private workout: every chip is a plain outline, nothing lit, no best chip, no values in any label.
- Say "best", never "record".

## 2. Motion
| Moment | Normal | Reduce Motion | Low Power |
| --- | --- | --- | --- |
| A set is logged: its chip fills | The outline chip becomes its state colour while it seats: scale 0.82 to 1 and a 3 pt rise to rest on `Theme.Motion.house` (one spring, no overshoot beyond the spring's own bounce) | 150 ms crossfade from outline to state, no scale, no rise | Same as Reduce Motion |
| The haptic | One, at the moment the chip seats; it is the set-close haptic a logged set plays today, not a new one | Same | Same |
| Short chip | Seats as above, pale | Crossfade | Crossfade |
| Best chip | Seats as above in the stage colour; no glint, no extra beat (Design: no highlight motion) | Crossfade | Crossfade |
| Plan changes (a set added or removed) | Chips that keep their slot hold still; chips that change slot crossfade over 150 ms, nothing slides | Same | Same |
| Row copy (Training row, History) | Flat, appears when the live chip seats, 150 ms crossfade | Same | Same |
| Tap a chip | Its exact line shows under the row in inkSecondary, 16 ("Set 3: 85 kg x 9"), the chip rises 2 pt on `Theme.Motion.snappy`; tap again or elsewhere to clear | Line crossfades, no rise | Same as Reduce Motion |

The soul never plays a haptic of her own here. Only `withTesseraAnimation` and `.tesseraAnimation` animate the tile.

## 3. VoiceOver
- The tile is one element: "Bench press, 4 sets, 2 logged".
- Each chip: logged "Set 1, 8 reps, 80 kilograms"; short "Set 2, 6 of 8 reps, 85 kilograms"; best adds ", best"; not logged "Set 3, not logged". A private workout reads "Set 1, logged" and "Set 3, not logged" with no values.
- Logging a set announces its chip line once (no other speech).

## 4. Build checks
1. `tileCountLayouts1to8` matches the board for every count from 1 to 8.
2. `tileStatesDistinctAt11pt`: the four states differ in a snapshot at 11 pt and at AX5.
3. `tileSeatUsesHouseSpring` and `tileReduceMotionCrossfade150`: nothing but the house spring animates a seat, and Reduce Motion and Low Power show a 150 ms crossfade only.
4. `tileOneHapticPerSeat`: one haptic per logged set, none on plan changes or taps.
5. `tileFlareUsesStageColour`: the best chip reads the day's stage colour in every look.
6. `tilePrivateNoValues`: a private workout shows outlines only and no label carries a rep count or weight.
7. `tileRowIsFlat`: no blur, shadow or glow on any chip in the row or History.
8. `tileNoCirclesOrWaves`: the wave and the brush circles are gone from live mode, the Training row and History.

## 5. Asks
- Builder A: a `SetTile` view replacing the set circles in live mode, the Training row and History, following sections 1 to 4. No review switch; this is the only mark.
- Design: confirm 9 and 10 sets (two rows of five) and the darker-ink range for heavier sets.
- Ships in the release after Oct 21's.

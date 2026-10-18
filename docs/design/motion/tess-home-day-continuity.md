# Home line to Now to Done: one continuous motion of a day (board 45). Oct 18; (lab) = default for Design to overrule

Stitches values that already exist (today-on-home.md promotion, task-reward.md done, day-strip.md now marker, evening-on-now.md, tess-picks section 20) into one ordered timeline, so nothing is invented and nothing fights. One haptic per moment throughout. Reduce Motion / Low Power: every beat is a 150 ms crossfade (promotion is a 200 ms hero crossfade, no size morph), haptics unchanged.

## The day as one line of beats
| # | Moment | Motion (normal) | Haptic | Soul |
|---|---|---|---|---|
| 1 | Tess's line (resting Home line) | Lines change by the 300 ms blur-in used by every value word; the old line leaves in 150 ms | none | idle |
| 2 | The next thing becomes Now (clock reaches a timed task, or the running item ends) | NowPicker promotion: the first Next row's name rises into the hero with matched geometry, 21/500 to 56/500, 460 ms house curve; the queue moves up and refills at the same time; the day-stroke tip keeps its 600 ms linear minute slide | none | eyes look toward the new hero once (`lookToward`), 380 ms |
| 3 | Now is running (workout live, cook, timer) | the hero stays; live things own their surface; nothing else moves | none | working only if Tess is working; else idle |
| 4 | He finishes the item (swipe past 140 pt) | strike follows the finger; armed: it runs itself out, 160 ms; release plays the strike wet in the row's pigment, dries to ink at 45% | `.success` once (the done haptic) | reward beat 520 ms, no haptic of hers |
| 5 | The fleck | one 520 ms arc from the strike's end to the day stroke at now; the tip blooms and dries (task-reward) | none (the haptic was beat 4) | eyes follow the fleck |
| 6 | Done becomes the resting state | the finished hero stays struck for 4 s or until a tap, then the hero drains to Home's resting line (300 ms crossfade, blur as usual) | none | idle |
| 7 | The next Now | beat 2 again, starting 200 ms after beat 6 begins to drain, so the new hero rises as the old one leaves (matched geometry from the Next row) | none | `lookToward` |
| 8 | Day done (trained, nothing due) | hero stays "Push A"; context line "trained this evening" crossfades 220 ms | none | resting |
| 9 | 21:00 Shutdown / 22:00 closed day | the ground never turns to evening; only the day stroke's vermilion end and the soul's `resting` mode change, 900 ms | none | `resting` |
| 10 | 04:00 | the morning: day label crossfades 220 ms, queue refills, strike clears | none | wake glance |

## Precedence when beats collide (extends tess-picks section 14)
1. A touch beats everything. 2. A done (beat 4) beats a promotion (beat 2): finish the strike and fleck first, then promote, 200 ms after the drain starts. 3. Two promotions inside 460 ms: the second is queued, never interrupts. 4. A line change (beat 1) never plays during beats 2 to 5; it waits for beat 6. 5. A workout finish (sheet 95) has its own hero strike (tess-finish-hero-settings-paging.md) and replaces beat 4 for that item. 6. UNDO owns its slot for 4 s (new) or 10 s (change): no beat uses it.

## Never
Haptic on promotion, on the line change, on the fleck or on the drain; a count-up; Tess dimmed during any beat; the evening re-colouring the ground.

## Acceptance (QA, with -demoTime)
Record 17:55 to 18:05 on the demo day: promotion lands at 460 ms, exactly one `.success` per finished item, the fleck leaves the strike end within one frame, the next hero rises 200 ms after the drain starts, nothing differs in Reduce Motion except the crossfades.

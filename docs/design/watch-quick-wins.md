# Watch quick wins W1 and W2 (Design item 37, redrawn)

For Core and Builder A (`research/apple-watch.md`). This version is redrawn under tonight's rules: Cobalt sky for every Live Activity (`lockscreen.md`), no resting colour (`no-dots.md`), the ink line (`ink-line.md`), and the done moment (`task-reward.md`). It supersedes the first board, `recordings/watch-quick-wins.png`.
- Board: `mockups/watch-w1-w2.png` (source `studies/watch-w1-w2.html`). Watch screens are drawn at 1.8×. It shows W2 resting, rest up with the wrist tap, after Done, then W1 as it lands with the Watch on, and W1 at rest with no Watch.
- Recording: `recordings/watch-w1.mp4` (7s). The finish screen settles, the heart sentence rises, the line draws wet in vermilion and dries to ink, and the mark dries to 16%.

## W2: rest in the Watch Smart Stack (`.supplementalActivityFamilies([.small])`)
This is the phone's rest Live Activity folded to two lines, in **Cobalt sky**: the cobalt wash top left, the violet wash top right, and cream `#F6EFE4` type. The Smart Stack's corners are the system's; we draw no shapes inside them. Nothing on it rests in colour.

| State | Line 1 | The horizon | Line 2 |
|---|---|---|---|
| **Resting** | The countdown at 30 Light, tabular, with the colon at 55%. **+15** as a label word (16/700, cream at 70%) on the right | The cream horizon (2pt) over a 1pt guide at 18%, emptying from the right as rest runs out | "82.5 × 8" at 18/600 on its cream ink line. **This is Done** (`Button(intent: LogSet)`, the whole of line 2). "SET 4" as a label word in cream at 70% on the right, not vermilion |
| **Rest is up** (`staleDate`) | "Go" pushes in from below, and the washes warm to cadmium and vermilion over 1.4s. +15 at 25% | empty | The same |
| **After Done**, until the rest ends | The next rest, full. **UNDO** takes +15's place (16/700 in Obsidian `liveInk` `#FF7A5C`, `Button(intent: UndoLastSet)`), because line 2 has no room beside the receipt | full | "Set 3 logged." at 16 in cream |
| **UNDO tapped** | The rest it came from, with +15 back | as before | "Set 3 taken back." for 2s, then the set again |

- **Rest end:** one wrist tap through the phone's N2 notification ("Set 4 is up", "Bench, 82.5 × 8"), which the Watch mirrors under the app icon (Tess's soul, `app-icon.md`). The activity itself stays silent, and there's no `.success`. In quiet hours it still taps, because it's his own timer.
- **The haptics are the system's:** a tap on Done or UNDO on the Watch plays the Watch's own button feedback, and we add nothing.

## W1: the heart line on the workout finish (phone)
The finish screen is the build's (`WorkoutFinishView`):
- the context line, "Thursday, 18:02 to 19:03", in `context`;
- "Push A, done" in Hero 56;
- the gathered mark;
- "61 MIN, 11,400 KG MOVED";
- "It drops into today on Home.";
- **Back to today** as an ink-line word, replacing the PaintKey.

W1 adds three things under the totals, in the same voice:
- **The sentence:** "Your heart averaged **128**, and peaked at **164** on squats." at Body 21. The peak names the exercise whose time range holds the highest sample.
- **The line:** the session's heart rate, 2pt, 346pt wide, smoothed, with no axes, dots or numbers. It **draws wet in vermilion** (75%) left to right over 900ms, starting 120ms after the sentence rises. It **dries to ink at 55%** over 1.6s.
- **"FROM YOUR WATCH"** as a label word in `inkSecondary` under the line.
- **With no Watch, or fewer than 3 samples,** the sentence, the line and the label are **absent**, and the summary closes up. It never shows "0", "no data" or a placeholder.

**Tonight's rules on the finish screen:**
- **The mark dries.** It lands in the session's colours as the strokes gather (the moment), then dries to 16% over 2.8s, like the set strokes it was gathered from. The finish keeps no resting colour beyond the context line.
- **The finish plays the done pattern** (`task-reward.md`): finishing a workout is finishing a task. It replaces `celebrated`'s soft 0.8. A new best during the session keeps `.success` on its own set.
- Reduce Motion: no gather and no draw. The mark (already dried), the sentence, the line (in ink) and the label appear whole, and the done pattern still plays.

## Owners
- **Builder A:** W2's Cobalt sky family with the UNDO-for-+15 swap and the cream SET label, and W1's sentence, line and label on `WorkoutFinishView`. Also the mark drying, Back to today as an ink-line word, and the done pattern on the finish.
- **Core:** the session's heart samples from HealthKit (average, peak, and the exercise holding the peak), and the absent case under 3 samples.

# Watch quick wins W1 and W2 (steer)

For Core (`research/apple-watch.md`). Board image: `recordings/watch-quick-wins.png` (source `studies/watch-quick-wins.html`). It follows `live-activity.md` and `no-buttons.md`.

## W2 · Rest in the Watch Smart Stack (`.supplementalActivityFamilies([.small])`)
This is the phone's picked rest layout (Gesso + Horizon, cobalt sky) folded to two lines on the dark ground. The system's Smart Stack corners are the system's; we draw no shapes inside them.

**Line 1:**
- The countdown at 30 Light, tabular, left.
- **+15** as a label word (16/700, 70% cream), right.

**The horizon line** sits under line 1 as the timer: a 1pt hairline at 18%, with a 2pt cobalt glow line shrinking from the right as rest runs out.

**Line 2:**
- The planned set "82.5 × 8" at 18/600, left. **This is Done**: `Button(intent: LogSet)` covering the whole line 2.
- "SET 3" as a label in light vermilion (`#F2B8A8`) on the right.

**After Done, until the rest ends:**
- The countdown restarts full, and line 2 reads "Set 3 logged" (16 at 62%) with **UNDO** in light vermilion. That is `Button(intent: UndoLastSet)`, as on the lock screen.
- When the rest ends, UNDO leaves and line 2 shows the next set.

**Rest end:** one wrist tap via the local notification. No sound, and no `.success`.

## W1 · The heart line on the workout summary
Under the summary's best line, in the same voice at 21:
- "Your heart averaged **128**, and peaked at **164** on squats." The peak names the exercise whose time range holds the max sample.
- Under it is **one thin vermilion line** of the session's heart rate (2pt at 75%, 346pt wide, smoothed, no axes, no dots, no numbers). The label "FROM YOUR WATCH" sits under that.
- **With no Watch, or under 3 samples,** the sentence, line and label are **absent** and the summary closes up. It never shows "0", "no data" or a placeholder.
- **Motion:** the line draws left to right over 900ms after the gather's mark settles, and the sentence fades up 120ms before it. Under Reduce Motion it appears whole.

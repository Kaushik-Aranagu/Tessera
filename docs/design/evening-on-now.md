# The evening on Now (Design item 17)

This sheet covers what Now on Home shows once the day is done: the day done, Shutdown and its handoff, the closed day after 22:00, and late night until the 04:00 turn. It matches `widget-states.md` (a370ec6) word for word, and it amends `m4-steers.md` §7 for the one-base rule. It's for Builder B (Home, Now) and Builder A (the widget rows).
- Board: `mockups/evening-on-now.png` (source `studies/evening-on-now.html`), in Obsidian, the night look. Porcelain is the same on white.
- Recording: `recordings/evening-on-now.mp4`. It shows a row kept off tomorrow, the Shutdown hold and handoff, the closed day, then the 04:00 turn.

## One base (amends m4-steers §7)
**The ground never turns to evening.** §7's "the paint washes shift to violet and vermilion" is withdrawn by Kaushik's one-base rule (themes.md, fourth addendum). The evening lives in two places only:
- the day stroke, as it reaches its vermilion end (`daySpectrum`);
- the soul, which goes to `resting` mode after Shutdown.

## Now's order in the evening
These states slot into the order that's already decided: a running item first, then a timed task within 15 min, then a rest day, then the ranker. Nothing here beats a running item. A workout started at 23:40 takes Now, and when it finishes Now goes back to the state it left.

| When | Now reads | Day label |
|---|---|---|
| Trained, and no timed item due within 15 min | **Day done** | "Thursday evening" |
| 21:00, until it's held or until 22:00 | **Shutdown** (§7) | "Thursday evening" |
| After Shutdown is held, or from 22:00 by itself | **The closed day** | "Thursday night" |
| 04:00 | The morning: "first today" | "Friday morning" |

## The states (y in pt; the day stroke is at 182)
**1. Day done** (widget: "trained this evening / Push A / 6 OF 6 · 22 SETS · 1 RECORD")
- "trained this evening" at y 226, Body 21 `inkSecondary`.
- **Hero** "Push A" at y 258, Hero 56/500 `ink`.
- Its label line at y 330, Label 16 `inkSecondary`: "6 OF 6 · 22 SETS · 1 RECORD".
- The queue window stays as it is, with the rest of the evening. On a rest day the hero stays "Rest day".

**2. Shutdown, 21:00** (§7, with three changes)
- "this evening", then the hero.
  - **Change: the hero holds at most two counts** ("Four tasks, one workout"), so it stays within 2 lines.
  - The rest go to its label line at y 390: "COOKED ONCE · 2 NOTES". Never anything that didn't happen.
- At 446, **GOING TO TOMORROW**, then rows 48pt apart: the text in Body 21 `ink` with **TOMORROW** in the time column.
  - Tap a row: an ink-line strike draws across TOMORROW (260ms, house curve), the word dims to 50%, and **LATER** sets in to its left (settle spring).
  - Tap again to undo it.
- At 628, the writing line "**Tomorrow, first:**", with the label part in `inkSecondary` over a 0.5pt hairline.
- At 688, **WHEN YOU'RE DONE**, then "Shutdown complete" (34/500) on the ink line in `context`.
  - The hold is 0.7s.
  - The line empties to a 0.9pt trace at 35%, repaints, then the bead.

**3. The handoff** (recording 2.2 to 7s)
1. The day stroke paints the rest of its length to its vermilion end (700ms, house curve). The dashed guide fades out.
2. Each kept row's **TOMORROW** lifts off toward the stroke's end (620ms, 80ms stagger), shrinking and blurring. LATER rows stay where they are.
3. The rows, the writing line, the action and the label line fade (blur 3pt).
4. The hero crossfades to "**Done for today.**". Tess plays `done`, and `.success` plays (§7's one exception).
5. About 2s later it settles into the closed day:
   - The day label crossfades to "Thursday night".
   - The context line crossfades to "tomorrow, first".
   - The hero becomes his line in `inkSecondary`.
   - The soul goes to `resting`.

**4. The closed day** (widget: "tomorrow, first / Pull A / 07:30")
- "tomorrow, first" at 226 (`inkSecondary`).
- **Hero** in `inkSecondary` (resting, not ink):
  - his "Tomorrow, first:" line if he wrote one ("Reply to landlord");
  - otherwise tomorrow's first timed item ("Pull A").
- The label line:
  - "THEN PULL A · 07:30" under his line;
  - "07:30" alone under a timed item.
- **No queue, no "Nothing else today."** The ground is empty under it, and the x lane still pages tomorrow.
- **From 22:00 without a hold**, Now goes to this state by itself, with no motion beyond a crossfade and no `.success`.
  - Unfinished items roll at 04:00 as usual, with no marker.
  - One label word, **CLOSE THE DAY** (`inkSecondary`, at 390), brings Shutdown back until 04:00. Hold Shutdown and the word goes.
- **The widget follows the same choice.** When the hero is his line, the widget's hero is his line and its meta is "PULL A · 07:30". This adds one row to `widget-states.md`.

**5. Late night, until 04:00**
- It's still Thursday: the day label says "Thursday night" with no "Friday", and no seam at midnight (the Day log agrees, DL3).
- Quiet hours run 23:00 to 07:00: no haptics except under his own finger, and no sounds.
- Anything he logs answers in Tess's line as usual ("Noted. Hotel ideas."), and Now stays on the closed day.

**6. The 04:00 turn** (recording 8 to 10s)
- No sound, no haptic, no line about the hour.
- The day label crossfades to "Friday morning", and the context to "first today".
- The hero dries from `inkSecondary` to `ink` (600ms).
- The painted stroke fades out (420ms), and a fresh dashed guide draws in from the left (500ms).
- Plan my day still waits for 08:00 (it can be pulled from 07:00).

Reduce Motion: crossfades only, so no lift-off, no stroke paint and no bead. VoiceOver reads the closed day as "Tomorrow, first: Reply to landlord. Then Pull A at 7:30."

## Never
A night ground or an evening wash, a count of what didn't happen, a "you missed" line, a streak, red, a midnight seam, a sound after 23:00.

## Owners
- **Builder B:** Now's evening states, Shutdown's rows and handoff, the closed day, CLOSE THE DAY, and the 04:00 crossfade (`Features/Home/`).
- **Core:** Now's order with these states, the 22:00 switch, and the "Tomorrow, first" line (stored for the Day log).
- **Builder A:** the widget's closed-day row when the hero is his line.

# Day log page (build sheet for Builder B)

Just enough to build M4 slice 5, Day log v1. Lines come from Core's `DayStory.lines(for:on:calendar:lookup:)` (`docs/research/day-log-first.md`). This page draws them; it never writes. It supersedes the v1 parts of `m4-steers.md` §5. The headline, count and quiet lines there, "your line", undo from a past day and the paint spine wait for slice 5b, `DayNote` and Health.

Recording: `recordings/day-log-page.mp4` (source `studies/day-log-page.html`), with the research doc's real lines:
1. Review's **Day log** word zooms in onto today, and today's lines arrive bottom up.
2. A drag down reads up the week.
3. "Cooked carbonara, 35 min" opens its recipe, and **‹ DAYS** brings you back.
4. A drag in the margin scrubs back to **OCT 1 TO 4**, with the day under the thumb shown large.

## Entry (the HomeLink word)
- **Review's link line** gains the word: "The week · **Day log** · Notes" (Body 21/600, `HomeLinkLine`), so the page isn't DEBUG-only. Tap: the 1.5pt hairline draws under the word (150ms) with `.selection`. Review lifts away (scale 1.06, blur 3, fade, 380ms), and the log grows in from the word (scale 0.94 → 1 from the word's centre, 420ms, house curve).
- **The day label on Home** ("Thursday afternoon") zooms into the same page, as in `m4-steers.md` §5. It's a second way in, not a replacement.
- The page opens **on today, at the bottom.** Today's lines rise 10pt into place bottom up, 40ms apart (360ms each).

## Layout
| y | Element |
|---|---|
| 58 | Back word **‹ HOME** (`back-word.md`) |
| 92 | **The month** at Title 44/500: "October". It's the month of the day at the top of the window. When that changes, it swaps like a value word (blur crossfade, 220ms) |
| 150 to 768 | **The log window,** scrolling on y, with a 48pt fade at its top edge. Today sits at the bottom and the past is above. Pull down to read back, like reading up a thread |
| corner | Tess's soul in its corner, as everywhere |

**A day** is a block with no frame and 30pt between days:
- **Its date** in labels at x 22: "WED 14", in `inkSecondary`. Today reads "TODAY" in ink.
- **Its lines,** starting 34pt under the date, one row per `DayLine`:
  - **The time** at x 22: 16/600, tabular, `inkSecondary` at 75% ("07:10").
  - **A dab** at x 78: 13×11, the soft paint blob, in the colour of the line's class `colorRole`: training, health (kitchen), planning (tasks and lists) or neutral (notes). A workout that wasn't finished gets its dab at 40%, never a ring and never red.
  - **The text** at x 98 to the right margin: 21/400 ink, line height 28, wrapping to as many lines as it needs. Rows are at least 30pt apart, plus 4pt after a wrapped line.
  - **The "Also:" tail** has no time and no dab. Its text is at 70% ink and wraps: "Also: 3 notes, 5 groceries, ticked 4 on Lisbon packing."
- **Empty days:** only the date, in labels at 45%, with no lines. A run collapses to one row: "OCT 1 TO 4". A single empty day reads "THU 8". There's never a count of empty days.
- **The copy is Core's, word for word,** following the research doc's voice rules: "Push day, 4 sets, not finished". "Pull day, 61 min. Row 70 x 10." "Done: call the bank". The page adds nothing: no totals, no praise, no colour for good or bad days.

## Moving through it
- **Tap a line** to open its object (`objectIDs.first`). The hairline draws under the text (150ms) with `.selection`. Then the object's page reveals out of the line's band (clip from the row to full screen, 440ms, house curve), and its back word reads **‹ DAYS**. Back is the reverse, closing into the same line. "Also:" lines open nothing.
- **The margin scrub** (the left 80pt, the time column): drag on y to travel by day.
  - The lines step back to 30% (200ms).
  - The day under the thumb rises on the right, beside the finger, as a **Numeral 80 Light** with its weekday in labels above it ("SUN" over "11"; "OCT" over "1–4" on a run).
  - Each day passed plays a light `.selection` tick, and each week boundary a firmer `.impact(.light)`.
  - The month word swaps as months pass.
  - On release, the window settles with that day's date at its top (house curve, 320ms), the lines come back to full, and the numeral fades (220ms).
- **Live:** while the page is open, a new record for today (from `ActionEngine.observe`) inks its line in at the bottom (rise 10pt, 360ms). If Tess wrote it, it gets her 2.8s cobalt wash, as everything Tess changes does.

## States
- **An empty today:** "TODAY" alone at the bottom.
- **A brand-new log** (no records at all): "TODAY", and under it one line at 21/400 and 55%: "Your days write themselves here." It goes with the first record.
- **A running workout or cook today:** its line reads "Push day, 4 sets", without "not finished" while it's still the running process (a note for Core's fold). Its dab is training colour at full strength. Nothing on this page glows; running belongs to Now.
- **Reduce Motion:** no zoom and no rise. Lines and pages crossfade, the scrub numeral appears without travel, and haptics are unchanged.
- **Dynamic Type:** times move above their text at the largest accessibility sizes. The text column never shrinks under 21.

## Never
Cards, rows with backgrounds, section headers in boxes, charts, counts of empty days, streaks, red, "only", "missed".

## Owners
| Part | Where | Owner |
|---|---|---|
| `DayStory.lines`, `DayLookup`, the 4 AM day, the fold rules | `TesseraCore/DayLog/` | Core |
| The page, the margin scrub, the line-to-object reveal, the Review link word, the Home day-label zoom | `Features/DayLog/`, `HomeSpatialView` (`HomeLinkLine`) | Builder B |

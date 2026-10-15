# Home v1 (painterly)

Light ground. One screen tall. Sparse: one hero, one action, one short list. Mockup: `mockups/PleinHome.dc.html`.

## The three axes
- **x:** three sibling pages, REVIEW · **TODAY** · TRAINING.
  - They are paged, stop at the edges, and open on TODAY.
  - The sibling rail sits at y 58: three label-style words, with the active one in ink and the others in `#A39AAE`. Under them, a painted vermilion underline glides continuously with the scroll.
- **y:** only inside the bounded "Later" window. The page itself doesn't scroll.
- **z:** tap any name to zoom into its object page.

## TODAY, top to bottom
1. **The day stroke** (y 100, 96pt tall). The day is one watercolour brushstroke, and it is its own bounded x lane: swipe it for yesterday or tomorrow. It opens on today.
   - **Label:** Fraunces italic 21, e.g. "Thursday afternoon", "Wednesday, done", "Friday, three planned".
   - **The stroke:** 20pt wide with round caps, and wet edges from turbulence displacement (scale 7). Its gradient runs through the day: morning sky `#9EC3D6` → sage → violet `#7A5C8E` → amber `#E0A35C` → vermilion evening.
   - **Progress:** the stroke is painted up to now. A dashed ink guide (22%) shows the rest of the day.
   - **Entrance:** the stroke paints in over 700ms.
   - **Today only:** a 26pt wet amber tip sits at now and breathes (scale 1↔1.35, blur 3↔6, 3.6s).
2. **Now line** (y 222): "now, until twenty to four", in Fraunces italic 21, violet.
3. **Hero** (y 252): the current thing's name only, at Fraunces 60 / 0.95, weight 640, tracking −2.5%, with opsz 144, SOFT 100 and WONK 1. Up to 3 lines. Tap it to zoom into the object.
4. **Hold to finish** (y 470): an ink key, 220×58.
   - While you hold, vermilion paint spreads through the key from the left over 900ms, blurred. Releasing drains it in 220ms.
   - The time left sits beside the key in labels: "14 MIN / LEFT".
   - **On completion:** the next item writes itself into the hero, entering from the right (18pt travel, blur 4→0, 340ms). Tess plays `done`, and her bar says "Done. Next one is up."
5. **Later** (y 566): the heading is Fraunces italic 34. Below it, a bounded window 112pt tall shows about two rows and fades out at the bottom, scrolling vertically with a snap per 50pt row.
   - Each row is a paint dab in its area colour, the name at 21pt, and the time in labels.
   - No separators.
6. **The dock** (see below) at the bottom: What's running sits on top of Ask Tess in one glass lens.

## The dock: What's running + Ask Tess
Mockup: `mockups/HomeRunning.dc.html` (the dock, the process list, and the capture flow).

The dock is one glass lens, radius 22, at bottom 18 with 14pt side insets. Light fill is `rgba(250,246,239,.62)` with an 18pt blur, a 0.5pt hairline and a white 90% inner top. From the bottom up, it holds:
- **Ask Tess row,** 74pt tall: the soul at scale 0.5 on the left (centre x 50), then Tess's line in Fraunces italic 21.
- **One process row** per open loop, 64pt tall. Rows are split by a machined seam: a 1px ink line at 12%, then 1px white at 80% below it.
- When anything is running, a **lit 2pt vermilion seam** runs along the dock's top edge (the process seam, with a glint every 4.5s). The screen's own top edge stays clean on Home.

**Process row:** a 16×14 state dab, two lines of text (the name in 21/600, the state in Fraunces italic 18 in `#6E6480`), and **one** control on the right (104×44, radius 12).

| State | Dab | State line | Control |
|---|---|---|---|
| running | vermilion, breathing (scale 1↔1.12 with a soft glow, 3s) | "resting, 1:42" (tick motif) or "set 4 is up" in vermilion | Ink key, "Resume" |
| paused | solid cadmium | "paused at Tuesday", which is the saved context (automatic context save) | Hairline key, "Resume" |
| waiting | hollow cobalt ring | "waiting since Monday" | Hairline key, "Open" |

**v1 behaviour:**
- Collapsed, the dock shows only the most urgent process (the workout always wins), so it is 138pt tall in total. With nothing running, it is just the Ask row with no seam.
- **Tap the process name** to grow the dock upward into the full list (318pt, 440ms, `cubic(.2,.9,.25,1)`). The rows rise in after 80ms under the heading "what's running" (italic 21, violet), and the glass thickens to 94% so the page underneath doesn't show through. Tap the name again, or swipe down, to collapse it.
- **Resume** zooms into the process at its saved place. For the workout, that means the live workout with the cover rising.
- Paused tasks and waiting items are P2 in the feature list. Draw them only once they exist.
- To make room on TODAY, the hold key moves to y 452, Later to y 532, and the Later window to y 584 (92pt tall).

## Tess captures: a ghost row that dries
A capture is wet paint until it is committed.
1. **Heard** (about 1.1s): Ask Tess shows what she heard in quotes, in cobalt italic. The soul blooms (`thinking`).
2. **Ghost:**
   - The proposed row slides into its place in its list (from −10pt, blur 6→0, 420ms).
   - It is drawn wet: everything in cobalt, opacity breathing between 0.5 and 0.66, a blurred cobalt dab, and the name in Fraunces italic.
   - A cobalt brushstroke paints along under the row over exactly **2s**. This is the commit timer, as visible time.
   - The rows below shift down 50pt.
   - The soul hands off: the cobalt dab flies to the row and spreads into a wash.
   - Ask Tess reads "Drying. Swipe to drop it."
3. **Commit**, on tap or when the stroke finishes:
   - The row dries: it becomes a normal row, with its dab taking the area colour.
   - A cobalt wash behind it fades over 2.8s. (Cobalt marks anything Tess changed.)
   - Tess plays `done`, and Ask Tess reads "Added to Later." with **Undo** (vermilion, 21/600) on the right for about 4s. Undo reverses the op through the op log.
4. **Drop:** swiping the ghost sideways throws it away. Nothing is written.

## TRAINING
- **Context line:** "this evening at six".
- **Hero:** "Push Day A".
- **Plan:** five rows of 50pt, e.g. "Bench press" with "4 × 8" in labels.
- **Start workout:** an ink key that raises the workout as a full-screen cover.
- **Tess line:** one line in cobalt italic, e.g. "Bench is ready for 82.5 today."

## REVIEW
- **Context line:** "the week so far".
- **Hero:** a sentence, not a chart: "Four good days of seven".
- **Week:** seven day dabs (34×30) in a row.
  - Done days are filled with their main area's colour. Missed days are an empty ink ring at 25%.
  - Day letters sit under the dabs; today's is in ink.
- **Tess line:** one line in cobalt italic, e.g. "Chest is a little behind. I slipped one more press into Thursday."

## Nested scrolling
- The day stroke and the Later window each own their own axis inside their frames.
- Edge swipes always belong to the page.

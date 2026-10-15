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
4. **Hold to finish** (y 452): an ink key, 220×58.
   - While you hold, vermilion paint spreads through the key from the left over **700ms**, blurred. Releasing drains it in 220ms. (Holds stay between 0.5 and 0.8s; see `workout-v1.md`, Instrument rules.)
   - The time left sits beside the key in labels: "14 MIN / LEFT".
   - **On completion:** the next item writes itself into the hero, entering from the right (18pt travel, blur 4→0, 340ms). Tess plays `done`, and her bar says "Done. Next one is up."
5. **The ledger** (y 536, only when there is a suspended process): see below.
6. **Later** (y 532, or y 616 under a ledger row): the heading is 34. Below it, a bounded window (92pt tall, 70pt under a ledger row) shows about two rows and fades out at the bottom, scrolling vertically with a snap per 50pt row.
   - Each row is a paint dab in its area colour, the name at 21pt, and the time in labels.
   - No separators.
7. **Ask Tess** at the bottom: one glass bar, 74pt tall, radius 20, at bottom 18 with 14pt side insets. Light fill `rgba(250,246,239,.62)`, 18pt blur, 0.5pt hairline, white 90% inner top. The soul sits at scale 0.5 on the left (centre x 50), then Tess's line at 21.

## What's running: Now plus the ledger (replaces the Round 7 dock)
Decided 2026-10-15 to match Product's `whats-running.md` and Research's concept A. **The bottom dock is retired.** Home has no process list above Ask Tess; Ask Tess is a plain bar again. Mockup: `mockups/HomeLedger.dc.html` (tap "DEMO" at the top right to cycle running, paused and none). The mockup is drawn in Inter Tight for the type comparison; the type spec in `type-and-motion.md` is unchanged until Kaushik picks.

**A running process is Now.** Only one process runs at a time, so it takes the Now slot instead of getting a row:
- **Now line:** "running now, Push Day A".
- **Hero:** the resume point, e.g. "Bench press, set 3 of 4".
- **The one control:** a vermilion key, "Resume", 220×58 at y 452, in place of Hold to finish. Beside it in labels: "RESTING / 1:42" (tick motif), or "SET 4 / IS UP" once rest is over.
- **Top edge:** a lit 2pt vermilion seam with light travelling along it (glint every 4.5s), the same seam every other screen shows while something runs. Tapping it resumes.
- There is no ledger row for the running process, so Home never shows the same next thing twice.

**The ledger** holds suspended processes (and, from M2, waiting ones whose check time has passed), most recently touched first, **at most 3 rows**; the rest are one level deeper in the full list. In v1 only workouts are processes, so it shows zero or one row.
- **Row:** full width (22pt insets), 64pt tall. The subject in 21/600 ("Push Day A"); the next step under it in 18 at `#6E6480`, stating time and never judgement ("Bench, set 3 of 4, 40 min ago"). It must fit on one line; shorten the step rather than wrap. On the right, one control: "Resume" in vermilion 21/600, text only, no key.
- **State lives in the seam above the row,** 6pt above it, never in a badge or dab:

| State | Seam |
|---|---|
| suspended | 2pt vermilion, lit and still (glow `0 0 8px rgba(200,69,47,.45)`) |
| waiting (M2) | 1px engraved and unlit: ink at 12%, then white at 80% below it |
| running | never appears in the ledger (it is Now) |

- Rows are joined by the hairline seam of the row below; there are no separators beyond the seams.
- **Entrance:** rows rise in (10pt, 320ms ease-out) and Later slides down to make room (320ms, `cubic(.2,.8,.2,1)`).
- **Tap** zooms from the row straight to the resume point: live mode, set at eye level, the dial preset, one glint sweep across the set (a haptic instead under Reduce Motion).
- **Swipe left** puts it away: the row slides into its track and the gap closes, with Undo in the Ask Tess bar.
- **Pull down** on the row opens the process page with its trail.
- **Leaving Home's layout:** with a ledger row, Later moves to y 616 and its window to y 668 (70pt tall); with none, they stay at 532 and 584.

## Tess captures: a ghost row that dries
A capture is wet paint until it is committed.
1. **Heard** (about 1.1s): Ask Tess shows what she heard in quotes, in cobalt italic. The soul blooms (`thinking`).
2. **Ghost:**
   - The proposed row slides into its place in its list (from −10pt, blur 6→0, 420ms).
   - It is drawn wet: everything in cobalt, opacity breathing between 0.5 and 0.66, a blurred cobalt dab, and the name in Fraunces italic.
   - A cobalt brushstroke paints along under the row over exactly **2s**. This is the commit timer, as visible time.
   - The rows below shift down 50pt (under a ledger row, the ghost lands at y 668).
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

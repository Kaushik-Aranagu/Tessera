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
6. **Ask Tess** glass bar at y 762, with the soul at scale 0.5 on its left.

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

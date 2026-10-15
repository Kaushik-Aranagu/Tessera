# Home v1

Light material. One screen tall. Mockup: `mockups/MachinedHome.dc.html`.

## The three axes
- **x:** three sibling pages, REVIEW · **NOW** · TRAINING. They are paged, stop at the edges and open on NOW. The sibling rail and its carriage sit at the top (see materials.md).
- **y:** only inside bounded wells. The page itself doesn't scroll.
- **z:** tap any name to zoom into its object page.

## NOW, top to bottom
1. **Sibling rail** at y ≈ 56.
2. **Day strip** at y ≈ 104. This is its own bounded x lane, one full-width page per day (yesterday, today, tomorrow and so on), opening on today.
   - Label row: "THU 15 · TODAY" on the left, "15:26" on the right.
   - A 30pt recessed channel with raised blocks (3pt radius) for each event, coloured by area.
   - A 2pt cadmium now-line that breathes (glow 0→10pt over 4s).
   - Hour labels 07 · 11 · 15 · 19 · 23 underneath, with the x ruler below them.
3. **Seam** at y ≈ 236.
4. **Label** "NOW · UNTIL 15:40" in `#8A6A1C`.
5. **Hero:** the object's name only, at 56pt, weight 850, tracking −4.5%, line height 0.92. It zooms into the object page.
6. **Hold key:** raised, 62pt tall, radius 10, with a recessed channel inset 8.
   - While you hold, the channel fills cadmium left to right over 900ms. On release it empties over 220ms.
   - On completion, the next item writes itself into the hero, entering from the right (18pt travel, blur 3→0 on the hero only), and Tess plays her `done` mode.
7. **NEXT label**, then a bounded recessed well: 180pt tall, radius 10, three rows visible.
   - It scrolls vertically and snaps to each 60pt row, with the y ruler inside its right edge.
   - Rows are separated by seams, not boxes. Each row has a 12pt colour inlay, the name at 21pt and a mono time.
8. **Ask Tess** glass lens at the bottom, with the soul on its left.

## TRAINING
- "Push Day A" hero, with the label "TODAY 18:00 · 5 EXERCISES · 55 MIN".
- A recessed list of exercises, separated by seams, each with "4 × 8 · 82.5" in mono.
- A solid ink "Start workout" key (radius 10). It raises the workout as a full-screen cover from the bottom.
- One line from Tess in Fraunces italic, cobalt.

## REVIEW
- "This week" hero.
- A seven-cell consistency strip milled from one block. Today's cell is raised and the others are recessed; done days carry a 14pt colour inlay.
- Sets per muscle: recessed 14pt channels with an ink fill, plus mono counts like "6/14".
- One line from Tess.

## Nested scrolling
- The day strip and the Next well each own their own axis inside their frames.
- Edge swipes always belong to the page.
- When a vertical surface sits inside the horizontally paged screen, give it the opposite axis.

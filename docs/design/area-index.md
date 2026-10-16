# 73. No tab row: the index

**Kaushik's principle, in one line:** moving between areas shouldn't need a row of four words at the top; the way there should show what each area is holding right now.

His ask (Oct 16, 1:51 PM PT): the REVIEW / TODAY / TRAINING / KITCHEN row "looks very generic", the glass lens (42) "is not enough", and "I don't even need it right there maybe… scroll through in other directions… be creative".
- Board: `mockups/area-index.png`. Left to right: the row today, A at rest, A pulled, A in Obsidian, B, C.
- Recording: `recordings/area-index.mp4` (12 s, Porcelain). It shows a swipe to Training with the word rolling, a pull down into the index, a slide to Kitchen and the let-go (the word flies up and becomes the page's name), then a tap on the word, the index, and a tap back to Today.
- Study: `studies/area-index.html`.

## What stays in every option
- **The row goes.** The top of a tab page carries one word, the area's name (Label 15/700, .08em, `ink`), at 52, where the back word sits one page down. So the top-left word always says where you are, or where back goes.
- **x is still the rail.** A left or right swipe moves to the neighbour, 1:1, and the name rolls up or down to the next word over 420 ms on the house curve. Sheet 71's swipe rules are unchanged.
- **The frame below is unchanged.** Home's day label is at 138, the context at 186, the hero at 212. Nothing moves into Tess's band.

## The three options
| | How you jump | What you see while you jump | Cost |
|---|---|---|---|
| **A. The index** (recommended) | Pull a tab page down past its top (80 pt, at scroll offset 0), or tap the name | All four areas as 40 pt words, each with its live line, on one glass sheet. The page stays live under it, at 90% and blurred | None. Pull-down is free on tab pages; the Day log and the workout's seam are pages further down |
| B. The edge spine | Run a thumb down four short strokes on the right edge | Each stroke is its area's colour, filled by how far today got. The names appear beside the thumb | It can't be read at rest, and it's a fiddly target |
| C. Around the soul | Hold Tess; the areas bloom in an arc around her | Glass words, each with a short line | It takes Tess's band, which is hers (motion lab 18b) |

## A in detail
- **The index:** a glass sheet from the top to 580 with 40 pt bottom corners. This is Liquid Glass, the one navigation layer, and it replaces 42's lens. The rows sit from 96, 104 pt apart, in the order REVIEW, TODAY, TRAINING, KITCHEN (the past at the top):
  - the word at 40/600, with -0.02 em tracking;
  - its live line at Body 17, from the same grammar as Home's context line, under the caps (≤ 6 words, 32 characters).
  - The area you're in is `ink`, the others are 42% ink, and the one under the finger takes its area's colour (72% mix, as in 72) and scales to 1.06. Today has no area colour (cobalt is Tess's voice only), so TODAY under the finger is ink at weight 700, scaled to 1.06. The board and clip draw it cobalt; this line wins (Research BJ, Oct 16).
- **Live lines:** REVIEW "This week, 3 of 6 sessions"; TODAY whatever the hero is holding ("Push Day A, 13 sets left"); TRAINING the routine on or next ("Push Day A is on"); KITCHEN tonight's cook ("Tacos at 7 pm"). Every line keeps the context cap of 6 words and 32 characters. With nothing on, it's the area's quiet line ("Nothing cooking tonight").
- **Pull:** the page follows the finger, rubber-banded. From 20 pt to 90 pt the index forms (the page scales to 0.9, blurs to 6 pt and drops 40 pt; the glass comes down 40 pt; the rows stagger 40 ms). Past 90 pt it's held, and the row under the finger is picked, with `.selection` once per row. Let go on a row to open it; let go above the first row or on the one you're in to close.
- **Tap:** a tap on the name opens the same index without a finger; tap a row. The hint at 528 reads "Let go to open" while pulling and "Tap one to open" after a tap.
- **Let go:** the chosen word flies from its row into the name's place, scaling to 0.38 over 460 ms, and becomes the name. The page under it rises to full size and unblurs. One `.impact(.soft)` on arrival.
- **Reduce Motion:** the index crossfades in 150 ms (MotionPolicy), and the word swaps without flying.
- **VoiceOver:** the name is a button, "Today, area. Double tap to show all areas". Each row reads as "Training, Push Day A is on". The rotor's Headings jump between areas.

## For the builders
- **Builder A (the tab strip is his):** remove the row and 42's lens; add `AreaName` (the rolling word) and `AreaIndex` (a pull and tap gesture driving a `progress` of 0 to 1 and a `picked` index). The live lines come from each area's existing context-line source, with no new reads.
- **Core:** none.
- **Not decided here:** a fifth area. The index takes five rows (to 616) without changing.

## His pick (Oct 16, 2:06 PM PT)
- **A, the index, goes ahead.** C is dropped for good. B's edge spine isn't a way between areas; its idea moves into Today's side page (74).
- **x on a tab page is no longer the rail.** The index (pull down, or tap the name) is the one way between areas, so a left swipe on a tab page opens that screen's own side page, under sheet 71's order. This replaces "x is still the rail" above, and 71's row "Tab pages: none". Each tab page's side page is mapped in `today-side.md` (74).
- **Later, with many more areas:** the index will need an order (pinned, recent, grouped by kind) and maybe typing a name. That gets its own sheet when the fifth area is near.

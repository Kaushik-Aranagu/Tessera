# 216 Home top: fixed rows, a colored date, bolder keywords, the board's flip (Oct 23, 2:50 PM PT)

These are Kaushik's 2:43 PM bug notes on release 72. Builder B builds them; they are ON by default. They replace 212's "the date is plain".

## 1 Fixed rows (nothing moves)
- **The top block:** three rows, each 30 pt tall (23 pt type × 1.3), with 3 pt between them, so the block is exactly 96 pt. It is right-aligned, and its top is pinned to the safe area plus 16 pt.
- **One line per row, always:** no wrapping, no "...", and the font size never shrinks.
- **Fitting:**
  - Every notice has a short form as well as its full form, and the row shows the longest that fits in the row width at 23 pt. For example, "Packing, 6 of 14 done." can become "Packing, 6 of 14."
  - Sample and demo text is written to fit at 390 pt width.
  - Later, Tess writes to the width budget through TessDirector, but the row rule stays the same.
- **The mosaic frame:** a fixed 160 pt tall frame, 14 pt below the top block. It never moves when a line changes, flips or loads. Whatever is below the mosaic sits at fixed offsets from it.
- **During a changeover:** each row keeps its height. Only letters change.

## 2 The date has color (row 1)
- **Weight and size:** 500, at the row's 23 pt, with no underline. It is still a door to Today (211).
- **Color: the sky of the hour,** as a left-to-right gradient across the date's letters, drawn like the Sunset word (SkyWordStyle):

| Hours | Name | Light look | Dark and Black looks |
|---|---|---|---|
| 5 to 11 AM | Morning | A9621A → C2507A | E6A97E → E07FA0 |
| 11 AM to 5 PM | Day | 2F6FD0 → 237E92 | 6FA4FF → 5CC6D2 |
| 5 to 8 PM | Evening | sky1 → sky2 (BF6A22 → A33C62) | E8A06A → F286A6 |
| 8 PM to 5 AM | Night | 4B3FA8 → 2D3F7A | A79CF0 → 7E95D8 |

  - On the White look, use the Light values; on Black, use the Dark values.
- **Changing hours:** when the hour band changes, the date does one letter-flip pass and the gradient eases over 600 ms.
- **Checks (measured):** every stop is at least ΔE 10 from Ember. Every stop has at least 3:1 contrast on its ground, the large-text rule since the date is 23 pt: at least 3.6:1 on Paper and at least 7:1 on Black.

## 3 Bolder keywords (rows 2 and 3)
- **App keywords** (Training's "Push day", Groceries, Stretch, Packing): Figtree 700 at 1.12x, in their accent, with a 1 pt underline offset 5 pt. The board's 600 read thin on the phone.
- **Numbers:** stay Outfit 300.
- **Plain words:** stay Figtree 400.
- **Training's accent** is the new crimson: A8203F light, 9E1C3A white, CC4478 dark and black (was D04A6A, moved 4:22 PM for E5341C).

## 4 The departure flip, exactly as on the board (r28 setSentence)
On the phone it looks different because the whole line re-lays out. On the board, each letter is its own fixed cell. Build it like this:
- **Cells:** each character is one cell, laid out once, with monospace-free advances fixed at the target string's layout. A cell whose letter is unchanged does not flip.
- **Letter set, in order:** space, a to z, A to Z, 0 to 9, ":", ",", ".", "'".
- **Walking to the new letter:**
  - A cell walks forward from its old letter to its new one. When the gap is n letters, it moves in steps of ceil(n/9), so at most 9 steps.
  - A character not in the set lands directly.
  - Each step lasts 52 ms.
- **The flap:** each step is a vertical flap, scaleY 0.08 → 1 over 70 ms, cubic-bezier(.3,.7,.4,1), with its origin at 50%, 52%. There is no fade, blur or slide.
- **Stagger:** each cell starts (row × 5 + index) × 14 ms after the first, so rows cascade top to bottom and letters left to right.
- **Width changes:** when the new string is longer or shorter, the added cells flip in from a space and the dropped cells flip to a space, then collapse after the pass. The row never shifts mid-pass.
- **Overlapping changes:** a new change cancels the old one (generation counter), and every cell snaps to its target before the new pass starts.
- **Reduce Motion:** cells swap with no flap.
- **Cadence:** notices advance every 6 s (212).

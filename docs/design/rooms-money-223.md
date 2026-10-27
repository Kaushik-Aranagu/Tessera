# Item 223: The Money room (Oct 23, 4:10 PM PT)

Board: https://claude.ai/artifact/WqsDGCX3gdjG84xK4eG3Wa, Money room. Follows 218 (shared lintel rules) and 131 v2 Money (approved Oct 22).

## Lintel: October as a pixel calendar (168 pt)
- Each day is a 4 x 4 block of whole tiles with 1 tile between blocks. Each week is a row, Sunday first, and the whole calendar is right-aligned 6 columns from the edge, clear of the Back word.
- Past days are sage at 50%. Today is full sage, breathing between 0 and 20% toward the page over about 3 s (still under Reduce Motion). Days ahead show only their bottom row, in ink 3 at 45%.
- A bill sits in its day's top-right 2 x 2: ink at 82% while it waits, full sage once paid. Payday wears a full-sage top row.
- Arrival: day by day, 18 ms apart, each block filling corner to corner in 260 ms.
- No amounts, no heights and no intensity. The tiles mark presence only.
- Touch to read: "Friday, Oct 30, Rent due", "Today", "Thursday, Oct 15, payday". Bill names use shownLabel when private.
- No numeral on this lintel.

## Room body (131 v2 Money, unchanged in order)
- Fact line: "Three bills paid, two to go".
- Sentence (23 pt, left-aligned here): "Nothing is late. Rent is due Friday, and October is running a little under September." The bill word is in sage, weight 600. Trends are clauses, never figures.
- The total rule: 1 pt sage (Money's one allowed line). Under it, "October so far" (16 pt ink 2) with the total on the decimal line: Outfit 300, 34 pt, tabular, cents 22 pt ink 2. Then "about $310 less than this time in September" (15 pt ink 2), money converting with "about".
- Margin lines: "Waiting: Rent, Friday. Power, Tuesday." and "New: Internet went up a little this month. Look at it" (link word underlined in sage, 1 pt).
- Doors: Due, Spending, Bills, Saving, Cash, Owed.

## Privacy (never relax)
- The lintel and the room never put an amount on Home, the Lock Screen, widgets, notices, Tess or Claude lines, backups or the doorway wave.
- Money values and money actions never reach Claude. (Send side superseded by Kaushik's Oct 27 11:59 AM ruling, docs/product/decisions.md; money write tools for Claude stay not offered; the backup, log, widget and screen walls stay.)
- Amounts appear only on Money's own pages.

## Reviewer fixes (4:05 PM, folded in; these win over the sections above)
- Every past day uses the same solid tile, a theme tint precomputed as sage 50% toward the page, with no per-day variation. It never reads as a heatmap. Days ahead show their bottom row in solid ink 3.
- No alpha anywhere. Tints are solid theme colours. Today's breath becomes a whole-tile step: full sage, then sage 18% toward ink, swapping every 1.6 s. Under Reduce Motion it holds full sage and arrival is instant.
- Private bills read normally inside the room. Masking applies on the Lock Screen, widgets, Tess and Claude lines, notices, backups and the doorway wave.
- **Accent check found a collision:** Money sage 3F7A62 / 8DBFA7 was ΔE 8.0 / 7.0 from Lists olive 5E6B1F / B5BE7A. Money moves to sea teal **2A7878** light (11.3 from olive, 17.7 from Routines plum, 24.9 from Training crimson, 4.75:1 on paper) and **7BC0C4** dark (11.1 from olive, 11.2 from Notes, 14.4 from Routines, 28.9 from Training, 10.2:1 on black). Builders: AppAccents.swift.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.

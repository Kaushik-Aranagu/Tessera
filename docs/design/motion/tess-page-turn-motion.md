# Page turn motion: Slide, Turn, Soften, Rotate (board 26, 27, 31). Spec from Design sheet 90; clips to follow

Source of truth for looks and rules: design/pages-90.md. This note adds timelines, the drag model, the Rotate slot model and the Settings preview, so Builder B can build one `PageTurn` with four options. Haptics: none on a user turn (R2); the lead-row auto-turn plays .selection once on landing. Curve: Theme.Motion.pageTurn (.22, .8, .2, 1). Reduce Motion and Low Power: every option is one 150 ms crossfade (R3), no stagger, no blur, no travel.

## Timelines (t = 0 at release or tap on the foot; N = rows on the page, max 6)
| Option | Old page | New page | Total | Stagger order |
|---|---|---|---|---|
| Slide | whole page up 100% of height, 520 ms | whole page in from below, same 520 ms, locked to the old | 520 ms | none |
| Turn | each row lifts 18 pt and fades, 260 ms each, 24 ms apart, top first | each row rises 34 pt into place, 440 ms each, 38 ms apart, first starts at 190 ms | 190 + 38(N-1) + 440 = 820 ms at N = 6 (630 ms at N = 1) | forward top to bottom, back bottom to top |
| Soften | blur out 0 to 14 pt, 340 ms | blur in 14 to 0 pt, 400 ms, starts at 190 ms | 590 ms | none |
| Rotate | slot k leaves at 24k ms: lift 14 pt and fade, 160 ms | slot k arrives at 80 + 24k ms from 40 pt below, 260 ms | 80 + 24(N-1) + 260 = 460 ms at N = 6 (388 ms at N = 3), never padded | forward top to bottom, back bottom to top |
Section word, with every option: crossfades 200 ms centred on the midpoint of the row motion. Title, context line, rail and pinned things never move except the rail's current segment (3 pt ink) sliding to the next segment over 200 ms.
Rotate numbers are Design's (Oct 18): 160 out, 260 in, 24 ms stagger, arrivals start 80 ms after the first leave; the 34 ms stagger is withdrawn; fewer rows shrink the total.

## Drag follows the finger (Slide and Rotate only; Turn and Soften wait for release)
- Slide: page tracks the thumb 1:1. Rotate: progress p = drag / 120 pt clamped to 0..1; slot k shows its leave and arrive at progress p shifted by 24k ms of the table so the ripple is visible while dragging.
- Commit if p >= 0.35 or flick velocity >= 600 pt/s; otherwise spring back on the house spring (380 ms). Commit settles with the same per-row times as the table.
- No rubber band past first or last page; at an end the page does one 6 pt nudge back over 160 ms (no haptic) so he knows it is the end.

## Rotate slots (board 27)
- A screen declares N <= 6 slots up front (slot 0 is the lead position). A page assigns rows to slots; empty slots on a short last page stay empty and keep their space so nothing below jumps.
- Rotation is forward by one page at a time. Rows that stay (the same object on both pages, e.g. a lead that carries over) do not animate, they hold their slot.
- Pinned writing line, add field and Tess's line never join the slots.
- One haptic per moment: none for the turn; the .selection on an automatic lead-change turn only.

## Whose swipe (also board 33)
A vertical swipe is claimed in this order: a focused field (never turns) > a number or dial that steps (its own step, no page turn) > any row's own vertical action > the page turn. A row's horizontal swipe is untouched. The recogniser begins after a 10 pt vertical move with a 2:1 vertical-to-horizontal ratio, so a diagonal side swipe stays a side swipe.

## Settings row preview (board 31)
Picking a word plays that turn once on a two-page preview line ("Groceries, 24 to get." to the next line), 1 s hold at the end, then it settles. Re-picking the same word does not replay (R4). The preview uses the real option, so Reduce Motion shows the crossfade. No haptic beyond the system's picker feedback.

## Clips (to render next, prototype scene `pick-page-turn`): four options x normal and Reduce Motion, 6 rows, Obsidian and Porcelain, with a frame budget note: Turn and Rotate animate at most 6 rows plus the word, well inside 60 fps.

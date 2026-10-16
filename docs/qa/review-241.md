# Review #241: no dots, ink line, Receipts (feb2ba7, head bacec65)

Builder B. 14 files, +269/-85, plus no-dots-ink-line.mp4. Static review (no Swift toolchain here). The merge's diff against fc31605 touches only the 14 announced files, so nothing was reverted.

**Verdict: PASS.** Every no-dots and ink-line row for Builder B is in. One should-fix (N1: the "becoming next" bloom never plays), the two merge-check lows confirmed (one is not a Reduce Motion bug), and three small notes.

## no-dots.md, item 90 rows
| Row | Built | |
|---|---|---|
| B5 | `InkLabelWordStyle` rests in `ink`, colour only on press. `.undo` keeps `liveInk` at rest; used for UNDO in BottomChrome, Groceries, PasteRecipe and RecipePage. | ✓ (weight is `labelStrong` = 700, spec says 600; the type tiers say Label 16/700, so I'd keep 700. Design's call.) |
| B8 | Newest note's time cobalt, then `inkSecondary` on the dry curve. | ✓ |
| B9 | Object page class line `inkSecondary`. | ✓ |
| B10 | Review's WORKOUTS label `inkSecondary` (day words were #234). | ✓ |
| B11 | MarginSection: NoteEditor "Links" and RecipePage "Cooked" in `inkSecondary`. | ✓ |
| B12 | "N to buy" in `ink` with the number semibold (both places); cooking line in `ink`. | ✓ |
| C9 | Suspended seam is the ink hairline at 1 pt, no glow; "Resume" `ink` at semibold (600). The 0x6E6480 hex went in #234. | ✓ |
| Kitchen dabs, queue row dabs, ghost row dab | Removed; words alone. | ✓ |

## ink-line.md, Builder B rows
| Row | Built | |
|---|---|---|
| Day stroke | One pass, `HomeStroke.day` = 6 pt, 60%, no soft pass. | ✓ |
| Now tip | Last 14 pt drawn at 7.5 pt (1.5 thicker) in `now`, breathing opacity 1 ↔ 0.55 and blur 0.4 ↔ 1.2; still under Reduce Motion. | ✓ (see N3) |
| Session marks | 4 pt `live`, glow removed. | ✓; the "lands wet when a session finishes" moment isn't built (N2) |
| Carriage | 40 × 2 `Rectangle`, `ink` at rest, `live` while `progress` is between pages, eased back. | ✓ |
| Drain bar | `ink` at 51% with the last 15% fading into `now`. The bar shrinks from the trailing side, so the amber sits on the moving edge. | ✓ |
| Recipe amount under-stroke | 2 pt, drying to 35%. | ✓ |
| L2 (from #234) | `HomeStroke` checks `look.field == .plein`. | ✓ closed |

All widths sit in one `HomeStroke` enum, which makes Kaushik's "thinner underline" ask a one-line change.

## Merge-check lows
- **NotesView `Theme.Motion.dry(reduceMotion: false)`: not a bug.** It's passed into `.tesseraAnimation`, and `TesseraAnimationModifier` reads the environment's Reduce Motion and swaps in the 0.15 s fade (MotionPolicy.swift:8-20). So Reduce Motion is respected.
- **PasteRecipe IngredientPaint: real, low.** It uses plain `.animation(Theme.Motion.dry(reduceMotion: false), value:)`, which bypasses MotionPolicy. It's only an opacity change (no movement), so it doesn't hurt anyone, but it breaks the "animate only through MotionPolicy" rule. Fix: `.tesseraAnimation(Theme.Motion.dry(reduceMotion: false) ?? .default, value: painted)`, as NotesView does.
- **WetTip doc comment (DayStrip.swift:212):** still says "A 26 pt wet amber tip … scale 1 ↔ 1.35, 3.6 s". Now it's the 14 pt end of the stroke at 7.5 pt, 1.8 s each way. Fix the comment.

## Should-fix
- **N1: the "becoming next" bloom is dead code.** QueueWindow works out `arrives` for a row that has just moved up into Next and passes it to QueueRow (HomeQueue.swift:110). But nothing ever sets `washing` (declared :211, read :345-346), so the wash behind the name never shows. And `seenNext` is refreshed one turn after the change, so `arrives` is only true for that one turn.
  - Fix: in QueueRow, `.onChange(of: arrives) { _, new in if new { bloom } }` (or `.onAppear` when `arrives`). Then animate `washing = true`, and dry it back to false on `Theme.Motion.dry`.
  - Without it, a row that moves up into Next has no colour moment at all, and that's the drama Kaushik asked for in place of the dots.

## Notes
- **N2:** session marks no longer glow, but nothing paints them wet when a session finishes (ink-line.md row: "landing wet when a session finishes"). Fine to follow up.
- **N3:** the Now tip's 14 pt is computed as `14 / size.width` of the trim. BrushPath is longer than the width if it curves, so the tip is a little under 14 pt. Invisible in practice.
- **Receipts** (Line 5, `ClaudeReceipts`):
  - Reads `costNano`, which is Core's field name (SystemCatalog.swift:216).
  - Cents are right: n$ / 1e6 is tenths of a cent, rounded up. So a key check (1,300 n$) shows "0.1¢", and 0 shows "free".
  - Rows show only the time ("6:12 pm"), but the list covers every call ever made. Add the day for rows not from today ("Tue 6:12 pm"). Low.
  - The "Receipts" link rests in `tess` (cobalt), which goes against B5's "colour on press only". Use `ink`, or the label style. Low.
- **GhostRow accept:** the words dry from cobalt into ink left to right, then the time 250 ms later, then it commits. Reduce Motion goes through `withTesseraAnimation` and waits 200 ms. ✓

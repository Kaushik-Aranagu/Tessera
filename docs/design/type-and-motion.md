# Type and motion

> **Inter Tight, app-wide** (Kaushik, 2026-10-15). Fraunces and Hanken Grotesk are retired. **No italics anywhere.** If an older note says "italic", it means the upright cut at the same size and colour.

## Type: four tiers, nothing smaller than 16pt
One family, **Inter Tight** (variable, 100–900), bundled in the app and the widget extension. Tabular figures everywhere a number can change.

| Tier | Size / line height | Weight, tracking | Use |
|---|---|---|---|
| Hero | 56pt / 1.0 (up to 72) | 500, −4% | The object's name, a sentence hero ("Four good days of seven") |
| Numeral | 80pt / 1.0 | 300 (Light), −4%, tabular | The one number that matters: weight, rest, the reps drum's centre |
| Title | 34–44pt / 1.05–1.2 | 500, −3.5% | Exercise names (44), section words like "Later" (34) |
| Body | 21pt / 1.25–1.4 | 400 for context lines and Tess; 500–600 for rows and keys | Rows, keys, context lines ("now, until twenty to four"), everything Tess says (in cobalt) |
| Label | 16pt | 700, uppercase, +8% | Metadata, times, plate maths |

- Secondary lines inside a row may use 18pt (400) where a 21pt line would wrap; never smaller.
- The lock screen keeps its own sizes (48 Light countdown), see `live-activity.md`.
- Hierarchy comes from size and weight steps, never from italics or a second family.
- Fonts sit behind `Theme`.
- Use `Font.custom("InterTight", size:relativeTo:)` with the variable weight axis. Cap the hero at about 80pt.
- **Accessibility text sizes:** switch to a single column.
- **Long hero names:**
  1. Allow up to 3 lines.
  2. Step down a size (56 → 44 → 34).
  3. Demote to Title.
  4. Only then truncate, with the full name in the accessibility label.

## Motion grammar
| Navigation | Motion |
|---|---|
| Deeper (child object) | Native zoom from the tapped row. Dragging to dismiss zooms back into it |
| Sibling | Horizontal paging with 30% parallax on the hero, `.snappy(0.3)` |
| Jump to a non-ancestor | `.crossFade`, scale 0.98→1, 0.25s |
| Process (workout) | Full-screen cover rising from the bottom, `.spring(0.45, bounce 0.1)`; exit 0.32s |
| Page entrance | First 5–6 elements in reading order, 25ms stagger, 12–16pt travel, blur 4→0 on the hero only. Total ≤ 250ms. Only on the first visit in a session; never blocks taps |

- **Paint feel:**
  - Things arrive like paint: strokes draw in, fills spread from where you touch, and nothing wipes linearly.
  - Precision lives in the instruments: the dial and drum snap with detents.
  - The house spring is tight. `.bouncy` is for PRs only.
- **Reduce Motion:** cross-fades of 0.15–0.2s, and opacity-only entrances.

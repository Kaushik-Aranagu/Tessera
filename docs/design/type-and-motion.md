# Type and motion

## Type: four tiers, nothing smaller than 16pt
| Tier | Size / line height | Use |
|---|---|---|
| Hero | 56–72pt / 0.95, Fraunces weight 600–640, tracking −2.5 to −3% | The object's name, or the one number that matters (weight, rest) |
| Title | 34–48pt, Fraunces (italic 34 for section words like "Later") | Exercise names, section heads |
| Body | 21pt / 1.3–1.4, Hanken Grotesk weight 500–600 | Rows, keys |
| Label | 16pt Hanken Grotesk 700, uppercase, +8% tracking | Metadata, times, plate maths |

- **Fonts:**
  - **Fraunces** (variable: opsz 144, SOFT 100, WONK 1 for display) for heroes and numerals. Use tabular lining numerals.
  - **Fraunces italic** for context lines ("now, until twenty to four") and for everything Tess says, in cobalt.
  - **Hanken Grotesk** for the UI.
- Fonts sit behind `Theme`.
- Use `Font.custom(_:size:relativeTo:)`. Cap the hero at about 80pt.
- **Accessibility text sizes:** switch to a single column.
- **Long hero names:**
  1. Allow up to 3 lines.
  2. Step down opsz and size.
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

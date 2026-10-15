# Type and motion

## Type: four tiers, nothing smaller than 16pt
| Tier | Size / line height | Use |
|---|---|---|
| Hero | 56–64pt / 0.92, weight 850, tracking −4.5% | The object's name only |
| Title | 34–40pt, weight 850, tracking −3–4% | Section heads, exercise names |
| Body | 21pt / 1.3, weight 500–600 | Rows, keys |
| Label | 16pt mono, uppercase, +4% tracking | Metadata. Numerals are tabular mono |

- **Fonts for this round:** Schibsted Grotesk for the UI, Martian Mono for numbers and labels.
- **Tess speaks in Fraunces italic**, in cobalt.
- Fonts sit behind `Theme`, because the base theme isn't final.
- Use `Font.custom(_:size:relativeTo:)`. Cap the hero at about 80pt.
- At accessibility text sizes, switch to a single column and turn rotated labels horizontal.
- **Long hero names:**
  1. Allow up to 3 lines.
  2. Step down the width axis.
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

- **Machinery feel:**
  - Parts slide in tracks and seat with a detent; nothing bounces loosely.
  - The house spring is tight. `.bouncy` is for PRs only.
- **Reduce Motion:** cross-fades of 0.15–0.2s, and opacity-only entrances.

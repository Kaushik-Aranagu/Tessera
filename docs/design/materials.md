# Materials: painterly ground, machined edges

The look is Plein air: impressionist washes, paper grain, big serif type, and very little on screen. "Zero tolerance" is a finishing detail on that look, not a material of its own. It shows up as a hairline outline, one lit chamfer, a precise tick ruler, and a lit seam. There are no milled blocks, recesses or seams between rows. Round 5's machined materials are retired.

## Light ground: Home
- **Base:** layered soft radial washes over paper `#F2ECE3`:
  - cadmium `#F7E6B8` at the top right (85%, 6%)
  - lilac `#D8CBE6` at the left (0%, 30%)
  - sky `#BFD8E2` at the right (100%, 70%)
  - sage at the bottom
  - Each fades to clear by 70% of its radius.
- **Drift:** one blush wash (`rgba(233,183,168,.5)`, 260×200) drifts ±12pt over 14s. This is the only ambient motion on the ground.
- **Grain:** fractal noise (base frequency 0.85, 3 octaves), multiply blend at 30%.
- **Ink** `#2B2440`. Secondary violet `#7A5C8E`. Mute `#7A6E86`. Labels `#6E6480`.

## Dark ground: Workout
- **Base** `#1C1828`, with these washes:
  - violet `#3B2D57` at the top left
  - teal `#1E3D4A` at the right (100%, 55%)
  - umber at the bottom left
- **Drift:** one violet wash (`rgba(122,92,142,.35)`) drifts over 16s.
- **Grain:** soft-light blend at 35%.
- **Text:** cream `#F3ECE0`. Secondary `#A79FB5`. Dim: cream at 28–38%.

## Paint: colours that mean something
| Role | Light | Dark |
|---|---|---|
| Live, running, the log key fill, the needle | vermilion `#C8452F` | `#D9563F` |
| Tess's words, and anything she changed | cobalt `#2E6DA4` | `#3F7FC0` (text `#9DBFE6` / `#C9D9EE`) |
| Now, rest, a possible PR | cadmium `#E0B341` (warm tip `#E0A35C`) | `#E8BD4C` |
| Health, recovery, done days | sage `#6E9E6A` | `#7FB07A` |

Small markers are **paint dabs**, not dots:
- About 18×15pt, with an irregular radius like `55% 45% 60% 40% / 50% 60% 40% 50%`.
- Rotated a few degrees each.
- Blurred 0.4–0.6pt.

## Where the precision lives (the zero-tolerance layer)
- **Keys:**
  - Radius 14, never height/2.
  - A 0.5pt hairline outline: ink at 50% on light, black 60% on dark.
  - One lit top chamfer: a 1px inner line, white 18% on an ink key or 70% on a cream key.
  - A soft drop: y 6, blur 18, ink 14% on light; y 10, blur 28, black 35% on dark.
- **Glass (Ask Tess bar only):** radius 18, height 64–66, 16pt blur.
  - Light: fill `rgba(250,246,239,.55)`, inner top white 90%, 0.5pt hairline.
  - Dark: fill white 7%, inner top white 16%, 0.5pt black hairline.
  - Never put glass on glass. Content is never glass.
- **Tick ruler** (weight dial): 1pt minor and 1.5pt major hairlines, with exact pitch. See workout-v1.md.
- **Running process:** a lit 2pt seam along the very top edge of the screen.
  - Vermilion, with a `#FFE2A8` glint sweeping across every 4.5s and a 14pt glow.
  - It replaces every status pill and rest pill.

## Rules
- **No cards, boxes, wells or row separators.** Grouping is done with space and type size alone.
- **No pills or capsules anywhere.** Glass included: always pass `in: .rect(cornerRadius:)`.
- **Paint fills, it doesn't wipe.** Hold-to-act keys fill with a blurred radial blot that grows from the thumb side (origin 12–15% from the left). Never use a linear progress bar.
- **Position indicators are words or paint.** Home's sibling rail is three words with a painted vermilion underline (64×4, uneven radius, 0.5pt blur) that glides continuously with the swipe. The exercise lane shows its position by letting the next name peek in, dimmed.

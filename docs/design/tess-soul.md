# Tess's soul (v2: wet paint)

Tess's living mark is three dabs of paint. How they move says what Tess is doing. In v2, every state has the soft blur and colour mixing that Kaushik liked in Thinking. There are no flat or solid blocks of colour anywhere.

Mockups:
- `mockups/TessSoul3.dc.html` shows every current state (round 3) plus the colour and shape explorations.
- `mockups/TessSoul2.dc.html` shows the v2 material.
- `mockups/TessPlayground.dc.html` shows travel, hand-off and the jump to Home.

`soul.css` inside either file is the exact reference. v1 (solid blobs, 1.5pt blur) is retired.

## Form
- **Three main dabs** of about 76×70pt. Each has its own irregular corner radii:
  - `52% 48% 60% 40% / 55% 45% 55% 45%`
  - `45% 55% 40% 60% / 50% 60% 40% 50%`
  - `60% 40% 55% 45% / 45% 55% 45% 55%`
- **Fill:** each dab is a soft radial wash, not a solid shape. Alpha runs from 0.80 at the centre to 0.60 at 40% of the radius, then fades to 0 at the edge.
- **Live blur:** 3–9pt, animated with the motion (see the table under Modes). The blur is part of the life, not a fixed filter.
- **Three satellite dabs** (46×42pt), one per colour. They sit further out, at (−22, 10), (20, 12) and (4, −20), and run the same mode out of phase. They are what makes the soul read as paint mixing, not three circles.
- **Halo:** a 150×140 blurred radial wash under everything: vermilion at 16%, then violet at 10%, then clear. It breathes between 0.8 and 1.0 over 7s.
- **Group grade:** saturation 1.45 and contrast 1.04 on the whole group, so the overlaps go vivid rather than muddy.

| | vermilion | cobalt | cadmium |
|---|---|---|---|
| Light ground (blend **multiply**) | `#C8452F` | `#2E6DA4` | `#E0B341` |
| Dark ground (blend **screen**) | `#D9563F` | `#3F7FC0` | `#E8BD4C` |
| Main offset (x, y) | (−14, −8) | (14, −8) | (0, 13) |
| Bloom target (x, y) | (18, −10) | (−16, −12) | (0, 18) |

On dark grounds the paint glows instead of staining. The halo there is vermilion 22% then cobalt 14%, and the done ring is cadmium.

**Size:** draw at scale 0.5 in the Ask Tess bar. Idle is deliberately small.

## Modes
Each mode is a set of parameters: offset multiplier, scale, blur, opacity and period. Blend between modes; never cut from one to another.

| Mode | Motion | Scale | Blur | Period |
|---|---|---|---|---|
| idle | Calm "needs you": one main dab at a time lifts (+5, −10), taps once, and settles. The three main dabs take turns (delays 0, −6, −3s), and the satellites drift. No drip. The whole soul draws at 0.62 of the bar size | 0.78–0.92 | 4→5.5 | 9s per dab |
| listening | Bloom (formerly thinking): from near the centre (offset ×0.45, so the dabs never stack into a dark pool) out to the bloom target and back, staggered by thirds. Later, drive the amplitude from the mic level | 0.6→1.15 | 3→6 | 2.4s |
| thinking | Pulse (formerly listening): each dab swells outward (offset ×0.6→1.3) at its own rate. This also covers Tess acting on something | 0.72–1.06 | 3→7 | 0.66–1.1s |
| done | **Kaushik: perfect, keep exactly.** All dabs pour into the centre, swell to 1.35 (blur 9) and relax back out. Satellites lag 80ms each. A soft ring splashes out to 2.6×. Success haptic | 0.8→1.35→1 | 4→9→6 | 1.8s (once) |
| needsYou | The vermilion dab lifts (+12, −16) and taps twice. A small drip falls 34pt and fades. The others stay idle | 0.85–1.06 | 4→7 | 2.4s |
| handOff(target:) | One dab and its satellite fly to the changed thing, spread into a wash (2.8 × 0.75, 45–60% opacity, blur 10–12) behind it, then fade and reform at home | | 4→12 | about 3.4s |
| resting | Saturation 0.35 and brightness 1.06. Very slow drift | 0.62–0.68 | 6→8 | 12–15s |
| present (M4 focus block, the body double) | All three main dabs breathe **together**, in phase, which is unlike idle's turn-taking: in toward the centre (offset ×0.7) on the in-breath, back out on the out-breath. The satellites hold still. Paired with the line "I'm here." It reads as company, not as activity | 0.74→0.84 | 4→5 | 6s (one breath) |
| checkIn (halfway through a focus block) | needsYou made soft: the cobalt dab (not vermilion) lifts (+8, −10) and taps **once**, with no drip and no haptic. Then back to present | 0.84–0.98 | 4→6 | 1.6s (once) |

**Focus block wrap-up** (M4 slice 8): when the block's time ends, play `done` unchanged, at the same moment as the horizon's cadmium flare (`m4-steers.md`, §8). Don't add a new mode for it.

**Working is removed** (Kaushik, 2026-10-15). While Tess is doing something, she shows thinking, then hand-off, then done. Exact keyframes are in `mockups/TessSoul3.dc.html` (`lift`, `bloomS`, `listen`).

**Colour and shape explorations** are on the same board: follows the day, colour chase, borrows the room, drops to strokes, pointillism, wet on wet, catches the light, and one-colour moods. None of these is approved yet; don't build them until Kaushik picks.

## Travel
- Animate position with a different easing on each axis, so the path arcs:
  - x: `cubic(.55,0,.15,1)`
  - y: `cubic(.3,0,.25,1)`
  - About 0.76s.
- Use a shared coordinate space so the soul can fly to any row.

## Tapping the soul opens Home
- A blurred radial paint flood (vermilion → violet → cobalt) scales up from the bar over about 0.5s.
- Home swaps in underneath with its directional entrance, and the paint fades away.
- Tapping again goes back.

## Implementation
- **Recommended route (Research lab idea, welcome):** a single Metal shader for the whole soul. Use domain-warped noise over three colour fields with subtractive (multiply) or additive (screen) mixing, and treat each mode as a parameter set. Animate between parameter sets so modes blend continuously. A `.colorEffect` / `.layerEffect` in a `TimelineView` is enough.
- **Fallback:** six `RadialGradient` ellipses in a `Canvas`, with `.blendMode(.multiply)` or `.screen`, `.blur` per dab, and `.saturation(1.45)` on the group.
- **Cost:** idle must cost almost nothing at 120Hz. Pause the soul when it is off screen, and drop to 30fps while it is in the resting mode.
- **Reduce Motion:** static soft dabs (keep the blur and mixing). Show the mode by scale and opacity only.

## Motifs we reuse, sparingly
- **Glint** (from Mosaic): a light sheen crosses text or an edge about every 3–5s. Use it for a possible PR, the running-process seam, or a fresh note from Tess.
- **Round robin** (from Kernel): five bars with one lit, sweeping every 1.25s. Use it for background jobs: sync, Health import, Tess working through a batch.
- **Tick** (from Kernel): rolling digits using `numericText`. Use it for rest, the workout clock and countdowns.

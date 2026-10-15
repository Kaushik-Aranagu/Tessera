# Tess's soul

Kaushik's pick: Tess's living mark is three dabs of paint. How they move says what Tess is doing. Mockups: `mockups/TessSoul.dc.html` (every state) and `mockups/TessPlayground.dc.html` (travel and the jump to Home).

## Form
- **Three blobs,** each about 64×58pt with slightly different, irregular corner radii.
- **Offsets:** (−13, −7), (13, −7) and (0, 12).
- **Colours:** vermilion `#C8452F`, cobalt `#2E6DA4`, cadmium `#E0B341`.
- **Blend:** **multiply** on light grounds. On dark grounds use **screen**, with the brighter colours `#D9563F`, `#3F7FC0` and `#E8BD4C`.
- **Blur:** 1.5pt.
- **Scale:** 0.62 in the bar.

## Modes
| Mode | Motion |
|---|---|
| idle | A slow breath: scale 0.80↔0.88 and offsets ×1.18 over 6s, each dab a third out of phase |
| listening | Each dab pulses at its own period (0.9 / 0.72 / 1.1s). Later, drive it from the mic level |
| thinking | Bloom: from the centre out to (18, −10), (−16, −12) and (0, 18). Scale 0.55→1.15, blur 2→6, 2.4s, staggered by a third |
| working | The whole soul rotates once every 1.6s while the dabs smear (scale 1 × 0.7, blur 3) |
| done | All three merge to the centre, pop to 1.15, send out one ring splash to 2.8×, then relax. About 1.6s, with a success haptic |
| needsYou | The vermilion dab lifts (+10, −16) and nudges over 2.4s, and a small drip falls. The others stay idle |
| handOff(target:) | One dab flies to the changed row, stretches into a blurred wash (2.6 × 0.7, about 35% opacity) behind it, then fades |
| resting | Desaturate to 0.3, scale 0.66, a 9s breath. For night and focus mode |

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

## Performance and Reduce Motion
- Use `TimelineView` with `Canvas`, or `PhaseAnimator`. Idle must cost almost nothing at 120Hz.
- With Reduce Motion: static dabs, with the mode shown by colour and opacity only.

## Motifs we reuse, sparingly
- **Glint** (from the Mosaic concept): a light sheen crosses text or an edge about every 5s, with a slow breath. Use it for a new PR, the current item, or a fresh note from Tess.
- **Round robin** (from Kernel): five bars with one lit, sweeping every 1.25s. Use it for background jobs: sync, Health import, Tess working through a batch.
- **Tick** (from Kernel): rolling digits using `numericText`. Use it for rest, the workout clock and countdowns.

# 202 Home is the mosaic: the screen's own pixels (supersedes the framed window in 200)
Kaushik 8:45 AM PT Oct 23 (cmsg_01VTPva3JGXrfvetgUvAWE7MFG32RRDd8GME1W31pvtpTm): "you can't tell where the mosaic ends and where the app starts... the pixels of the screen itself or home itself are behaving such way". Most important change. Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp
Ships On (his 8:47 AM rule: approved things are default On).

## Builder A (MosaicView becomes the Home background layer)
- Grid: the whole Home screen, edge to edge, under the safe areas too: 4 pt step, 3.2 pt tiles, square (corner 0).
- Screen pixels: every tile is drawn at rest in the ground ±4 (light: ground −4; dark: ground +5), with ±1.5 hash jitter. It is pre-rendered once per theme or size and redrawn only on change.
- The mood field has no frame:
  - Its core is the living window (sizes per mood from 200), centred at 56% of the width, top at the old block's top.
  - Intensity I is 0.62 → 1.0 inside, rising over the 7 tiles in from its edge.
  - Outside, I = 0.62 × (1 − d/28)^1.35, where d is the tile distance from the core.
  - Outside tiles are drawn only when hash < I × 1.9. This is a dither, never an alpha fade or a blur.
  - Tile colour = mix(screen pixel, scene colour, I); scale = 0.55 + 0.45 I.
  - Scenes are evaluated at their own coordinates beyond the core, so colour keeps going outward.
- Text shield: tiles under the sentence, the caption and the Next rows (1-tile pad) are capped at I × 0.22, so the words always read. Recompute it when the text changes.
- Lean and ripple answer anywhere on Home (radius 36 / 140 pt), not only over the field.
- A new changeover, flip (the departure board in pixels):
  - Each tile flips about its middle, scaleY |cos(πu)| (min 0.08) over 300 ms.
  - Delay = (column + 28) × 14 ms + row × 3 ms + hash × 80 ms, so it sweeps like the board's letters.
  - 30% of the tiles flip twice. On the first half-turn they show an in-between colour (the mix of old and new ±20 jitter), like letters stepping through the alphabet.
  - Defaults: day, golden, rest and night use flip; morning fall, running wave, back gather, done wave, rain fall. Moments keep their own.
- Performance: draw only the core plus 28 tiles around it (about 11k tiles at most) over the cached screen layer, at 60 fps on the iPhone 17 simulator. Use Canvas with a TimelineView, pausing when Home is off screen.
- Reduce Motion: the field is still, changes are a 150 ms crossfade, and there's no lean or ripple.

## Builder B
- The Home layout no longer reserves a framed block. The sentence, caption and Next sit on top of the pixel layer. Keep 64 pt to the sentence and the old block height as the field's core zone.

## Revision (Oct 23 9:08 AM, his 9:03-9:04 AM: "too pixelated... only the space the mosaic uses")
Supersedes "Screen pixels" and the outer field above.
- No screen-pixel layer. The rest of Home is the normal page. Only the mosaic's space is pixels.
- The core is the living window as a rounded rectangle (corner radius min(9 tiles, half the side)). Signed distance sd from that shape: inside, e = −sd; outside, d = sd.
- Inside: I = 0.55 + 0.45 × clamp(e/6).
- The halftone rim, 9 tiles wide: I = 0.55 × (1 − d/9)^1.2. A rim tile is drawn only when hash < 0.15 + 1.5 I. Its size is 3.2 × (0.12 + 0.88 I^0.8), and its colour is mix(page ground, scene, min(1, 1.15 I^0.9)). So the pixels get smaller, sparser and closer to the page colour until there are none: a halftone, not an alpha fade or a blur.
- Rim tiles sample the scene at the nearest core tile, jittered ±4 tiles along the edge so features like stars don't streak outward.
- The text shield stays: tiles under the words are capped at I × 0.22.
- Lean and ripple only touch mosaic tiles.

## Revision 2: the skin edge (Oct 23, 9:30 AM PT)

Supersedes Revision 1's rounded core, wobble and halftone rim (Kaushik 9:09 AM: blend the pixels, not the shapes). Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp, "How the edge meets the page", first choice "Out of its own skin".

- Shape: a plain rectangle, the living size from 200. No rounding, no wobble. Every tile is full size (3.2 pt on a 4 pt step); no shrinking anywhere.
- Rim: F = 12 tiles around the window. Rim tiles sample the scene MIRRORED across the window edge (i < 0 reads -i-1; i > n-1 reads 2n-1-i), never clamped, so stars and texture continue instead of streaking. Changeovers use the mirrored coordinates too.
- Color (seamless clone, Poisson): window tiles keep their own color S. On rim tiles solve C so that C = page ground on the outer ring, C = S at the window edge, and inside C follows the scene's gradients scaled by w = 0.45 + 0.55 x (1 - d/F). Gauss-Seidel, 14 sweeps per frame, warm-started from the last frame, on a grid in screen-tile coordinates so it survives the window breathing. Drawn color = this frame's tile color + (C - S) from the solve. About 3,600 rim tiles x 14 sweeps; 60 fps on the board.
- Scatter: in the outer part a rim tile is drawn only when clamp(2.2 x (1 - d/F)) > Bayer 4x4 threshold at (row & 3, col & 3). Ordered dither, never random flicker; the scatter holds still.
- Kept: the text shield (protected tiles mix 22% toward ground), lean and ripple, flips, melts and all moments. No screen-wide pixel layer.
- Swift: Builder A computes C in MosaicView on the CPU (the grid is tiny) or in a Metal compute pass; same math, same numbers. Device fps check on the phone.
- Alternatives on the board for comparison only: "Takes on the page" (smooth seamless, no scatter, reads soft) and "Steps into the page" (dither to ground, no color match). Ship "Out of its own skin".
- Reviewer guard (9:18 AM): the color climb goes in solid whole-tile steps, each tile one opaque color with no alpha ramp. Under Reduce Motion the scatter and the solve freeze, so the warm start holds the last frame.

## Revision 3: rounded, rising from the page (Oct 23, 9:45 AM PT)

Supersedes Revision 2's shape, scatter and solve. Kaushik asked at 9:36 AM for a blend of the two: not fully round, not sharp, with the surrounding pixels moving from the background color to the mosaic's edge. Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp, first choice "Rounded, rising from the page".
- Shape: a superellipse corner, between a circle and a square. Take q = the distance past the inner rectangle (the window inset by R on each axis), with R = min(6, rows/2, cols/2) tiles. Then sd = cbrt(qx^3 + qy^3) - R. No wobble.
- Rim: F = 12 tiles beyond sd = 0, all tiles full size and solid. Each tile's level is l = smoothstep(1 - d/F), quantised to 1/8 steps with a Bayer 4x4 offset: floor(l x 8 + bayer) / 8. Tile color = mix(page ground, scene color, level). That gives whole-tile steps, no alpha.
- Texture: rim tiles sample the scene mirrored across the edge (from Revision 2). During the announcement, the rim samples the announcement's background (the base mood mixed 55% toward ground), never the text.
- No Poisson solve needed. Kept: text shield, lean, ripple, changeovers, moments, living size. 60 fps on the board.
- Reduce Motion: the rim is static; it only re-tints when the mood changes.
- Revision 3 update (9:50 AM; Kaushik 9:41 AM: "clear distinction between one color and the other", worst on the bright side):
  - The ramp now straddles the edge. It starts 8 tiles inside the window and runs F = 16 tiles out: u = clamp((F - sd) / (F + 8)), where sd is the signed superellipse distance (negative inside). Level = smootherstep(u), quantised to 1/24 steps with the Bayer 4x4 offset.
  - The text shield is feathered over 5 tiles (strength 1 to 0) instead of a hard box, so no hard line appears under the sentence.

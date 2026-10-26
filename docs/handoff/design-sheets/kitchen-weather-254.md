# 254 Sky glass and the pull-apart layer (v1, Oct 25; not yet reviewed)

Board: https://claude.ai/artifact/TQ2mH5kFqJqXZs7jMEoXts (file `kitchen-weather-254/board.html`). From his verdicts on 253.

## Weather
- The sky, closer to real: a gradient from the sun's altitude (night, dawn, day, noon), stars with color and size,
  a sun with a hot core, a wide halo and six glare streaks, a moon with its phase and faint maria, cloud masses of
  seven puffs each with a lit side toward the light source and a dark base, rain as long weighted streaks, snow as
  flakes of mixed size, fog as drifting bands, a storm as a flash every 2.5 to 6.5 s with a glowing bolt. On the
  phone this is a LIBRARY OF REAL PLATES: photographed or filmed skies by condition and hour, a sun and moon
  composited by position, particle rain and snow on top, a grade per look. The drawing is a stand-in.
- KEYSTONE, embossed glass: a 354 x 182 slab in the landing slot (top 196), corner radius 26. It samples the sky
  behind it, blurs 10 pt and lightens (22% on bright skies, 10% on dark), frosts toward its edges (a radial frost plus
  a 16 pt grain band), carries a 1.2 pt highlight along its top-left edge and a 2 pt shadow along the bottom-right,
  and a 40 pt soft shadow under it, so it reads as lifted off the screen. Dragging tilts it up to 6 degrees in
  perspective; the refraction offset and a sheen move with the tilt. His ask: an exception to the no-glass rule.
- Inside the glass: the temperature (Outfit 200 112 pt), the word for now with feels-like and high at the right,
  and three LIVE numbers along the bottom that tick on their own: wind gusting within a range, the time until the
  next change counting down, the sun's height in degrees.
- Below: the one line on what is coming, next hours, CARE rows (swipe right = done), Rain alert, Tess. Text color
  follows the sky's brightness.

## Kitchen, level 1 (Recipes), the pull-apart LAYER
- Dishes as large words (Figtree 900 44 pt), each with its time in Outfit 300 16 pt (wine "feta short" when something
  is missing).
- Tap a dish: the page scales to 97%, blurs 18 pt, saturates slightly and takes a 52% page tint over 0.5 s. A layer
  comes forward: the word's letters start exactly where they were on the page, travel to the layer's headline (top
  150) and spread 34 pt per step over 0.7 s on a spring, turning Kitchen ochre at 52 pt. The body (time and whether
  you have everything, ingredients in two columns with missing ones in wine, numbered steps) rises 24 pt and fades in
  0.3 s behind the letters. Foot becomes "Cook <dish>".
- Close: the back word "Recipes", a tap on the tint, or the edge swipe. Letters gather and fade, the layer leaves,
  the page comes back sharp in 0.4 s. Reduce Motion: no blur, cross-fades.
- The same layer opens a place in Pantry and a thing in Groceries. Never on the landing.

## Kitchen landing keystone: four directions offered (not built)
The fridge door (magnet letters: soon-to-use words lean up, low things lose letters, a thing that ran out drops
off, groceries fly in; Tess can leave a magnet note); The stove (four burners from above, flame size = how ready a
dish is, cook mode takes the slot with flame rings as timers); The pantry light (a cupboard interior where a bulb
warms up, soon-to-go things in the front row in the light, gaps for low things); The kitchen window (a window over
the sink borrowing the Weather sky, the kitchen's life on the sill: kettle steam at breakfast, a timer while
cooking, tonight's dish on a note, the water glass emptying with Drink water).

## v2 (Oct 25, after his notes; same link; v1 kept as `kitchen-weather-254/board-v1.html`)
His notes on v1: the sky still looks generated; the keystone does not blend, it reads as a separate surface. He wants
the whole screen to read as glass with the keystone RAISED out of it, a little, not a panel on top.
- Glass, round two: the sky continues through the slab at 1:1, magnified 3% in the middle (a shallow lens) and
  pulled 9% outward in a 14 pt rim, so only the edge bends the picture. A hairline of caught light on the top-left
  edge, a hairline of shade on the bottom-right, a faint lip gradient inside the rim, a short soft shadow under the
  bottom edge only. NO fill, NO frost, NO tint. Tilt up to 5 degrees on drag; refraction and a faint sheen follow.
- Sky: cloud masses replaced by a noise cloud field (fbm at 101 x 219 cells, thresholded by cover, shaded by the
  difference toward the light source so edges toward the sun or moon are lit), softened 5 pt; horizon haze; film
  grain; a quieter sun (scatter instead of streaks).
- Still a stand-in. The real page needs a LIBRARY OF PLATES: about 30 photographed or filmed skies (clear, thin
  cloud, broken cloud, overcast, rain, storm, fog, snow; dawn, day, dusk, night), the sun and moon composited by
  position, particle rain and snow on top, a grade per look. Waiting on sky photos to start it.

## v3 (Oct 25, after his note "I can't tell the boundary apart at all"; same link; v2 kept as `board-v2.html`)
The glass as a RAISED PLATE with a real bevel, so the edge is unmistakable:
- Flat top: the sky at 1:1 (2% magnified), with a broad faint sheen that follows the tilt.
- Bevel: 22 pt wide, drawn as eleven facets. Each bends the sky more than the one inside it (scale up to 1.42 at the
  outer edge) and is lit by a top-left light: white on the top-left, dark on the bottom-right, stronger toward the
  edge. A crisp 1.5 pt bright line on the outer edge (fading to dark on the bottom-right), a 1 pt reverse line where
  the bevel meets the flat top.
- Cast shadow: a soft shadow (18 pt blur) offset 4 right and 9 down onto the screen under the plate.
- Caustic: a bright line of light (7 pt blur) just outside the lower-right edge, where the bevel focuses the light.
- Tilt up to 5 degrees on drag; the bending, shadow and sheen follow. No fill, frost or tint anywhere.

## v4 (Oct 25, after he saw v3; same link; v3 kept as `board-v3.html`)
He saw the v3 glass once a bug was fixed (v1 to v3 had never drawn: the cloud field used an undeclared variable and
killed the draw loop after the first frame). His notes on v3: too embossed; subtler; the edges should flow outward
into the surface like a plateau whose sides run down to ground level; a little less refraction at the boundary.
- The glass as a PLATEAU: the flat top is the slot (sky at 1:1, 1% magnified, faint sheen). Sides slope 26 pt
  OUTWARD from the slot edge down to the screen, drawn as thirteen rings from the foot inward. Bending follows a
  bell across the slope: none at the foot, none at the top edge, up to 11% in the middle where it is steepest.
  Lighting follows the same bell: up to 20% white on the top-left, 20% dark on the bottom-right. A soft 1.5 pt
  crease where the top meets the slope. A shallow shadow (14 pt blur, 4 pt down) under the whole shape. No outer
  line, no caustic, no fill, frost or tint. Tilt up to about 3.5 degrees on drag.

## v5 (Oct 25, after he saw v4; same link; v4 kept as `board-v4.html`)
His notes on v4: two boundaries visible; the plateau was not what he meant and "too ugly"; he only wanted the edge of
the raised glass to blend into the background.
- One shape, the slot, and no lines. A 24 pt rim inside the edge, sixteen rings so it never bands. Bending and
  lighting follow one soft curve across the rim: nothing at the outer edge, a peak about a third of the way in
  (13% bend, 22% light top-left / dark bottom-right), nothing at the flat middle. The glass therefore has no drawn
  boundary, only a soft band where the sky bends and brightens, fading into the screen. A soft shadow (16 pt blur,
  6 pt down) under it; a faint sheen on top; tilt about 3 degrees on drag. No crease, no outer line, no caustic.

## v6 (Oct 25, after he saw v5; same link; v5 kept as `board-v5.html`)
His notes on v5 (with a screenshot): getting closer; the edges need adjusting; the moon behind the glass was not
rendered properly (it was cut at the glass edge).
- Cause: the rim was magnifying the sky (pushing the picture outward), so anything crossing the edge was cut off.
- Fix: the rim now samples a region 30 pt larger than the slot and scales it DOWN about the slot's center (9% at
  most), pulling the outside picture inward, as a raised glass edge does; the moon and clouds continue into the
  glass, slightly squeezed. Rim 30 pt, eighteen rings; bending and light fade in from nothing at the outer edge, peak
  a quarter of the way in, fade to nothing at the flat middle. Peak light down to 13%, top sheen to about 3%, so the
  inside is no brighter than the sky around it. Soft shadow under it; no lines.

## v7 (Oct 25, after he saw v6; same link; v6 kept as `board-v6.html`)
His notes on v6 (screenshot): still not rendering well (the moon came through the glass as a staircase: each ring
bent it by a different amount); he wants the edge to feel pulled up out of the background glass, slightly raised,
very subtle.
- The glass as a TRUE LENS, computed per pixel: the slot is a smooth bump whose height rises from 0 at the edge to
  flat 34 pt in (smoothstep). At every pixel the slope bends the picture, pulling the sky from outside the edge
  inward (up to about 7 pt where the slope is steepest, bilinear sampling), and catches light from the top-left
  (up to 20% brighter on slopes facing it, darker facing away). Slope is zero at the very edge, so the glass fades
  into the screen with no line; it is continuous, so the moon and clouds pass through without steps. Soft shadow
  under it (16 pt blur, 6 pt down), 3% sheen on top, tilt about 3 degrees on drag.

## v8 (Oct 25, after he saw v7; same link; v7 kept as `board-v7.html`)
His notes on v7 (screenshot): "super bad", the lens band read as a heavy frame; not raised so much; he mentioned a
"brutalist kind of style" (likely soft UI / neumorphism: same material, raised by light and shadow alone).
- SOFT: no refraction, no band, no frost. The sky inside the slot is exactly the sky outside. Two cues only: a soft
  light falling off the top-left edge into the background (14 pt blur, 4 pt offset, 38% white on bright skies, 22%
  on dark) and a soft shadow falling off the bottom-right edge (16 pt blur, 6 pt offset, 18% / 30%), both fading to
  nothing. A 1 pt hairline of the same light and shade just inside the edge. Drag shifts light and shadow slightly.

## v9, SURFACE APPROVED (Kaushik, Oct 25): "this is kind of what I would be looking for... perfect", with a little more shadow.
What is approved is the SURFACE and its place in the layout only. His words after: the keystone is not complete; inside it
still needs life, personality, information worth showing, and reactions to what happens; the page itself still needs
to improve; and the biggest requirement is the background itself (the real sky plates), still to be figured out.
- Same as v8 plus shadow: the bottom-right shadow is 20 pt blur, 8 pt down, 24% (36% on dark skies), and a second
  wider, fainter shadow sits under it (34 pt blur, 14 pt down, 9% / 16%). Light off the top-left edge unchanged.
- THE KEYSTONE SURFACE RULE (for Weather, and any keystone that sits on a photographic ground): the ground shows
  through untouched; raised by light and shadow only; no refraction, frost, fill or tint; edges melt into the ground.

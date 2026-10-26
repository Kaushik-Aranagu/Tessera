# Prompts for generated sky plates (to fill the gaps the photo library has not covered yet)

Use for: storm, starry night, overcast night, snow, heavy rain. Real photographs (Poly Haven, CC0) cover the rest and
should win wherever one exists; generated plates are the fallback, and each must pass the "looks like a photo" test
beside a real one before it ships.

## The frame every prompt shares (paste first)
A photograph of only the sky, shot straight up at about 60 degrees, from an ordinary place on an ordinary day. Vertical
portrait, 9:19.5, very tall. Full-frame camera, 24 mm, natural exposure, no HDR look, no oversaturation, no vignette,
no lens flare unless asked. No ground, no buildings, no trees, no birds, no people, no text, no watermark, no border.
The horizon line, if visible at all, sits in the bottom tenth of the frame. Soft natural grain. The upper two thirds
of the frame are calm enough that white or dark text would read over them.

## The plates to generate (one prompt each; make 4 variants, keep the one that looks least like a render)
1. storm-day: Low, heavy cumulonimbus base, charcoal grey with greenish undersides, ragged scud cloud in front, a
   brighter rim of light at the top edge where the anvil thins. Rain not yet falling. No lightning in the image.
2. storm-dusk: The same storm sky at sunset: the cloud base deep slate, the thin gap at the horizon glowing orange,
   the upper anvil lit pink. No lightning in the image.
3. overcast-night: A featureless overcast night sky lit from below by a town, very dark warm grey grading to near
   black at the top, slightly textured stratus, no stars, no moon.
4. clear-night: A clear moonless night, deep indigo to black, the Milky Way faint and diagonal, a few hundred
   pin-sharp stars of varied brightness and warmth, no horizon glow, no trees.
5. snow-day: A white-grey overcast sky in snowfall seen from below, flat and bright, with a few soft out-of-focus
   flakes very close to the lens and smaller flakes further away. Nothing else.
6. rain-day: A dark grey rain sky seen from below with rain streaking down toward the camera, slightly motion
   blurred, the sky behind it textured nimbostratus.
7. fog-night: Dense fog at night with a single soft warm glow low in the frame as if from a street lamp far away,
   everything else pale grey, no detail.
8. dawn-clear: The ten minutes before sunrise, sky clear: deep blue above grading to pale yellow at the bottom
   edge, Venus as one bright point, no sun in frame yet.

## Negative prompt (if the tool takes one)
illustration, painting, 3D render, CGI, anime, oversaturated, HDR, dramatic, epic, fantasy, aurora, galaxy art, planets,
lens flare, vignette, ground, horizon, mountains, trees, buildings, city, people, birds, text, watermark, frame

## Delivery
Export at the largest size the tool allows, PNG or high-quality JPG, name `<condition>-<time>.jpg`, put them in
`docs/handoff/design-sheets/weather-plates/`. I run them through the same grade as the photographs and show both on
board 255 side by side. If a generated plate reads as a render next to a real one, it goes.

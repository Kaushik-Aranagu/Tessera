# 256 Weather background: the plate library (spec, Oct 25; nothing collected yet)

His words: the whole Weather page carries the real weather like the Apple weather wallpaper; it must look real, not
generated; "if we figure out the background and the skypiece, we are perfect"; costs are accepted.

## What the page needs
A library of real sky PLATES that the page composites live. A plate is a still photograph or a short seamless video
loop of sky only (no buildings, no city, no people), shot or chosen so the horizon sits in the bottom fifth.

Conditions (8): clear, thin cloud, broken cloud, overcast, rain, storm, fog, snow.
Times (4): dawn (the hour around sunrise), day, dusk (the hour around sunset), night.
That is 32 cells. Not every cell needs its own plate: storm and rain share by time; fog and snow need only day and
night. About 24 plates make a full set; 6 (clear and overcast at day, dusk and night) make a working first set.

## Composited on top, from data
- The SUN: placed by the real azimuth and altitude (from sunrise and sunset times), drawn as glare, not a disc, so it
  reads as the plate's own light; hidden behind cloud plates, present as a bright patch behind thin cloud.
- The MOON: rise, set and phase computed on the phone (standard astronomy; Open-Meteo gives only the sun), drawn as a
  lit disc with the correct limb, on its arc.
- Rain and snow as particle layers over the plate, so their rate and wind lean follow the live data; lightning as a
  flash over the storm plate on a random schedule.
- A grade per look: paper lifts the plate's shadows a little; black deepens them and lowers saturation 10%, so the
  page's text (ink or warm white by brightness) always reads.
- Cross-fades between plates over 8 s when the condition or the hour band changes; never a cut.

## Where plates come from (choose one or mix)
1. Shoot them: a fixed phone or camera pointed at open sky, 20 s loops, over a few weeks in different weather. The
   most honest and the most work.
2. Licensed stock video loops of sky (Pexels and Pixabay are free for this use; Artgrid and Shutterstock if we want
   more choice). Fast; the look varies between clips and needs grading to match.
3. Apple's own approach is filmed plates plus compositing; we do the same with 1 or 2.
Recommendation: start with 2 for the six-plate working set this week, then replace with 1 over time.

## Delivery and build
- Files into `docs/handoff/design-sheets/weather-plates/` named `<condition>-<time>.jpg|mp4` (1290 x 2796 or taller,
  sky only). On the phone they ship in the asset catalog, HEVC for loops, about 2 MB each.
- As soon as any plate lands in that folder, I wire it into board 255 (replacing the drawn sky) so the glass, the
  skypiece and the text can be judged on a real sky. The drawn sky stays as the fallback for cells with no plate.
- Open: whether the sky also drives Home's weather face (it should share the plates), and battery (a loop at 24 fps
  is fine; a 60 fps shader sky is not).

## Where the plates are (checked Oct 25)
1. **Poly Haven sky HDRIs** (https://polyhaven.com/hdris/skies, API https://api.polyhaven.com/assets?t=hdris&c=skies):
   several hundred CC0 panoramic sky photographs, 16k+, unclipped, tagged by time (sunrise, midday, dusk, sunset,
   night) and sky (clear, partly cloudy, overcast, fog, storm, snow). Examples: aarfontein_dusk (dusk, overcast),
   bambanani_sunset, bell_park_dawn, clarens_night_01 (night, partly cloudy), bloem_hill_01 (midday, overcast),
   beach_parking (sunrise, fog), approaching_storm. CC0: no attribution, any use. STILLS, not loops: a plate is a
   portrait crop of the upper sky from the panorama; motion comes from a very slow pan across the panorama (it is
   360 degrees wide, so a 60 s drift never runs out) plus our particle rain, snow and lightning on top. The real sun
   is in the plate; we pick the crop so it sits where the real sun is now. This is the best source for dawn, dusk
   and night, which stock video rarely gets right.
2. **ambientCG HDRIs** (https://ambientcg.com/list?type=hdri): CC0, categories Day Sky, Morning Sky, Evening Sky,
   Night Sky (with stars). Fewer than Poly Haven; a second source for night.
3. **Pexels video** (https://www.pexels.com/license/, API https://api.pexels.com/v1/videos/search, free, 200
   requests an hour): real sky loops, commercial app use allowed, no attribution required, may be modified; not to be
   resold as media. Best for MOTION: rain, drifting cloud, storm. Pixabay is the same story
   (https://pixabay.com/service/license-summary/).
4. **Wikimedia Commons**: Category:Time-lapse videos of clouds (269 files), Category:Videos of thunderstorms (48,
   with Videos of lightning 57 and Videos of hail 32), Category:Videos of fog (18). Licenses vary per file (mostly
   CC BY or CC BY-SA, some CC0); check each. Good for storm and lightning reference and some usable loops.
5. **NERC MST sky camera time-lapses** (https://mst.nerc.ac.uk/sky-camera_time-lapse-videos.html, files on Zenodo,
   CC BY 4.0): scientific sky-camera loops of cumulus humilis to congestus with a rain shower, cumulonimbus with
   anvil, cumulonimbus at sunset with crepuscular rays, stratocumulus asperitas, lenticular and undulatus waves, a
   22 degree halo, crepuscular rays. Sky only, no buildings. CC BY needs one credit line in the app's About.
   DOIs: 10.5281/zenodo.7356988 (congestus, rain, rainbow), 7356948 (cumulonimbus anvil), 7357004 (sunset),
   7357283 (humilis), 7357294 (asperitas), 7356986 (halo), 4782318 (crepuscular rays).
Research datasets (SkyFinder, 90k webcam frames with weather labels) exist but are low resolution and for
research; not for plates.

## The plan from these
- Dawn, dusk, night, clear, overcast, fog, snow (static skies): Poly Haven crops with a slow pan. CC0, done today.
- Rain, storm, drifting broken cloud (skies that must move): Pexels loops, picked by hand for sky-only framing;
  NERC loops for cumulus and storm when the framing suits; lightning as our own flash over the storm plate.
- Grade every plate to the two looks; the sun and moon still composited from data when the plate has none.
- First working set (6 plates, this week): clear-day, clear-night, overcast-day, dusk, rain-loop, storm-loop.
- What I can do from here: pull the Poly Haven list through its API and shortlist by tag; list Commons and Zenodo
  files. Pexels and Pixabay need a free API key (a sign-up) or a hand pick in the browser; the downloads themselves
  need to be done where the repo is, since this machine does not reach those hosts for files.

## Poly Haven shortlist by tag (from the API, Oct 25; "_puresky" variants are sky only, no ground: use those)
- Night: kloppenheim_02_puresky, kloppenheim_07_puresky, kloppenheim_04, moonless_golf, moonlit_golf, clarens_night_01.
- Overcast day: kloofendal_overcast_puresky, mud_road_puresky, overcast_soil_puresky, lenong_1, lenong_3, bloem_hill_01.
- Dawn, sunrise, sunset, dusk: kiara_1_dawn, kiara_2_sunrise, kiara_8_sunset, klippad_dawn_1, klippad_sunrise_1,
  industrial_sunset_02_puresky, bambanani_sunset, bell_park_dawn, aarfontein_dusk (overcast dusk).
- Fog and mist: kloofendal_28d_misty_puresky, kloofendal_misty_morning_puresky, misty_farm_road, beach_parking.
- Snow: passendorf_snow. Storm mood: approaching_storm. (Rain and lightning: from loops, not HDRIs.)

## Done Oct 25: first working set in the repo
Seven CC0 plates from Poly Haven are in `weather-plates/` (README there has the slug table): clear-day, broken-day,
overcast-day, clear-dusk, broken-dusk, clear-night (moonlit), fog-day. Made with `crop_plates.py` (portrait crop of
the upper sky centered on the panorama's sun, 1179 x 1600, 1.6x wider than tall for a slow drift). Board 255 now uses
them: plate by condition and hour band (day, dusk, night), 8 s cross-fade on change, darkened by band and weather
(night .55, rain .3, storm .5), our rain, snow, fog bands and lightning drawn on top, text color sampled from the
painted sky. A "Drawn sky" switch keeps the old stand-in for comparison.
Still to collect: a starry clear night and an overcast night (Poly Haven moonless_golf, kloppenheim_02_puresky),
a true storm sky, and real rain and snow LOOPS (Pexels or NERC), which need video rather than stills.

## Decision (Kaushik, Oct 25): generate the moving set
He likes the seven real plates and wants them as the reference. What is missing is MOTION (clouds drifting, rain
in gusts, snow, fog breathing, storm rolling), CONTINUITY with RANDOMNESS (seamless loops, several variants per
condition so the page never repeats), UNIFORMITY (one camera, one grade) and SCALE (8 conditions x 4 times x 3
variants, eventually). Generation is the way to get that uniformly and scalably. First step: give ChatGPT/Sora the
reference plates and screenshots of board 255 with the brief in `weather-plates/BRIEF-for-ChatGPT.md`, and ask for
three stills and three 20 to 30 s seamless clips (two variants each). What comes back goes into the plates folder
and onto board 255 beside the photographs. Lightning stays ours (drawn in the app over the storm plate), so the
timing can be random.

## Oct 25, later: first generated plates accepted
ChatGPT returned four stills from the brief: two clear moonless nights with a low Milky Way, a second broken day that
reads as the same day as the Poly Haven plate, and an overcast dusk. All four passed beside the photographs and are in
the set as numbered variants (board 255 v4 picks a variant at random per set, with switches for photographs only,
generated only, drawn sky, and another variant). The moonlit photo became cloudy-night-1. Next from generation: the
moving clips (broken day drifting, gusting rain, rolling storm), an overcast night, a storm sky.

## His direction for later (Oct 25): Tess requests plates
"Eventually video generation models will be good enough to create whatever we need, and Tess could just request
based on what it needs, if it doesn't already have it." So the plate library is a cache that Tess fills on demand,
with the brief and prompts in this folder as the recipe. He will handle the image and video generation himself for
now. The skypiece itself: "it has so much life, we can use it to do a lot of stuff." Weather is DONE for this round;
next are Kitchen and Training.

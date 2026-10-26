# 214: Mosaic scene gallery (his 12:22 PM PT Oct 23)

Board: https://claude.ai/artifact/PBUKcPYqbmhP4xs9iZrmcK

He asked for scenes instead of stripes: "some skyline or some day or some beach... have a gallery of nice stuff and you could use location as well". Mood stripes stay as one choice; scenes become the default mosaic content.

## Scenes (first eight)
The same Home mosaic grid, the same Bayer-dithered superellipse edge (sheet 202 Rev 3), whole tiles only. Each scene has one small life, slow and quiet:
1. City at dusk: windows light up one by one.
2. Beach: waves roll in and slide back; the shoreline breathes 2 tiles.
3. Mountains and lake: far lilac range with snow, near pines, a mirrored lake with glints drifting across.
4. Woods: fireflies drift between the trees.
5. Desert: heat shimmer over the dunes.
6. Rain on the window: drops gather and slide down.
7. Night sky: stars turn slowly over the hill, a moon.
8. Fields at sunrise: the sun clears the furrows.
Motion: about one tile change per 150 ms at most across the whole scene. Reduce Motion: the scene is still; it only changes when the hour or weather does, as a plain swap. Low Power: still.

## How Tess picks (on the phone only)
- Inputs: the hour (dawn, day, golden hour, night), today's weather, and the kind of place (coast, city, mountains, desert, woods, plains).
- Kind of place: from a coarse location read once per day, mapped on the phone to one of those six words, then the location is dropped. Never stored, logged, backed up, sent to Claude, or paired with any of his data. A city is never named anywhere; it is just "a city".
- No location permission, or WeatherKit not yet entitled: follow the hour only (dusk city at golden hour, night sky at night, fields at dawn, beach or mountains by day, rotating daily).
- He can pin a scene, or ask Tess to change it ("show the beach"); the pick is a plain setting, ON by default as "Tess picks".

## Looks
Each look tints the scene: black mixes 18% toward 14121A (20,18,26) so it sits on pure black without glare; dark looks 30%; paper as drawn; white lightened x1.02. Never a tile within ΔE 10 of Ember (2:26 PM rule).

## With other sheets
- One-thing signs (213) borrow their pixels from whichever scene is showing; lent tiles leave a gap that refills, as specified.
- 209 reactions on open (time away) play on top of the scene; 212 Sunset word washes the scene toward dusk.
- No caption at the mosaic's edge; the scene name shows only in Settings.

## Later
More scenes (snow, harbor, autumn trees, a quiet street), seasonal variants, and Tess composing scenes with on-device AI. Not in this sheet.

## Reviewer conditions (12:29 PM, via coordinator): required
1. The place word is made on the device only, from a small bundled coarse table. Never use CLGeocoder or any network lookup.
2. Use When In Use permission with reduced accuracy. Read it on an app open at most once a day, and drop the coordinate in the same function.
3. The permission prompt appears the first time the gallery opens, with one plain sentence about why. Never at launch.
4. The place word never reaches Claude lines, the op log, widgets or the Lock Screen.

## Round 4, 1:10 PM: three more scenes (board v2)
9. Snow: whole-tile flakes drift slowly over a pale hill with a few pines.
10. Harbor: three boats rock at dusk; lantern reflections wobble on plum-toned water.
11. Autumn trees: warm canopies; now and then a leaf tile falls.
Kind-of-place mapping additions: coast adds Harbor; woods adds Autumn trees in Sep-Nov; Snow when the weather says snow.

## Everything earlier carries over (his 1:07 PM: "I want all the previous features for the mosaic too")
Scenes are new content for the same mosaic. They replace no behavior. Each earlier feature works on top of whichever scene is showing:
- **199** Today is laid in tiles. The mosaic ripples on touch, and each thing finished drops its tile.
- **200** The 9 moods and 5 pixel-art changeovers stay. Scenes join the mood library, and moving between scenes uses the same changeovers. Tess still picks on the phone.
- **201** Moments play over the scene: snow, fog, wind, storm, heat, the announcement crawl, Tess's eyes, timer, finished.
- **202 Rev 3** The edge stays top-right, blended by dither, with softly rounded corners and the wide ramp from the page.
- **204** The switchboard keeps all its cues (clock, Tess, apps, outside), its priority and its quiet hours. Scenes are one more library row.
- **206** Glance motifs for each app, and the pixel doorway when an app opens.
- **207** A tile flies into the mosaic on a Done.
- **209** The mosaic reacts on every open according to time away. Swiping across it turns the one-thing pages (213).
- **210** Inside a room, the mosaic becomes that room's lintel. Training's ridge stays.
- **211** Highlighted words are doors through the doorway. There is no caption at the mosaic's edge.
- **212** Tapping Sunset washes the scene to dusk.
- **213** The scene lends its pixels to the one-thing sign, and the tiles it lends refill.
- **Looks** Every look has its own tint: Black at 18%, dark at 30%.

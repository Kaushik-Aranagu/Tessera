# 236 Home delta (his 9:55 PM, Oct 23)

This sheet changes the Home board (https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp) and sheets 205, 212, 213, 214, 216 and 220. Everything earlier carries over unless a line here replaces it. It comes before the Training set-mark study. ON by default.

Owners: B builds Home, the top lines, the apps list and type (sections 1 to 3). A builds MosaicView and the faces (section 4). Core builds the weather and place sources (section 5).

## 1 Apps list scrolls freely (B; replaces 220's one-row swipes)
- The list moves 1:1 under the finger, then coasts with normal momentum (UIScrollView deceleration .normal). It rubber-bands at both ends.
- When it settles, it snaps to the nearest row (scrollTargetBehavior .viewAligned).
- A selection tick plays per row crossed while the finger is down, and none while coasting.
- Hold-and-scroll from 220 stays.
- The list still sits where 205 put it, with no label.

## 2 Type: bolder, richer Home (B; the phone must match the board)
| Element | Was | Now |
|---|---|---|
| Date (row 1) | Figtree 500, 23 pt | Figtree 600, 23 pt |
| Plain words, rows 2-3 | Figtree 400, ink | Figtree 500, ink |
| Highlighted part, rows 2-3 | 700, accent, underlined | 700, accent, no underline |
| Numbers on Home | Outfit 300 | Outfit 400 |
| Apps list names | 400 | 600, ink |
| Apps fact line | ink3 | 15 pt Figtree 500, ink2 |
| One-thing big tier (213) | 600 | 700 |

- Nothing on Home uses ink3 text. The thinnest text on Home is 500, except the numerals at 400.
- Check the phone against the board side by side in the simulator at 390 pt, on Paper and on Black. If the phone still looks lighter, the sizes are wrong, not the colors.

## 3 Top lines (B)
- **No underlines anywhere on Home.** This replaces 205 and 216 §3 underlines.
- **The date carries meaning.** 216's sky-of-the-hour gradient stays and adds two cues:
  - Weather tilts the second stop: rain or snow eases it 30% toward slate (34506F light, A7BCD6 dark), clear leaves it alone.
  - On a day with something due, the weekday word takes the first stop's color at 700, and the rest stays 600.
  - All stops stay at least ΔE 10 from Ember and at least 3:1 at 23 pt (measured in 216).
- **Every line has one highlighted part, and that part is the door** (211).
  - Row 1: the date opens Today.
  - Rows 2-3: each notice names its door part when it is written, e.g. "**Bench**, 185 for 5 again." → the Training room at that lift. "**Packing**, 6 of 14." → that list. "**Rice** goes out today." → Pantry at Leftovers. "Rain from **4 PM**." → the weather face.
  - The highlight is Figtree 700 in the room's accent. The weather door uses the date's second stop.
  - The door covers the whole row height around the highlight, plus 8 pt on each side.
  - A private item's door text is its shownLabel.
- **Departure flips every 5 to 10 s.**
  - Each of rows 2-3 holds for 7 s ± 3 s (jittered per flip), clamped to 5-10 s.
  - Row 3 is offset by half a hold, so the rows never flip in the same second.
  - An event (a new notice, a timer ending, a set logged) flips its row at once and restarts that row's clock.
  - While a finger is on Home, flips wait until 2 s after release.
  - Reduce Motion: a plain swap every 10 s. Low Power: 10 s fixed. Quiet hours (11 PM-7 AM): 10 s fixed.
  - The 216 §4 cell flip itself is unchanged.
- Rows stay fixed: three 30 pt rows, no wrapping, no shrinking (216 §1).

## 4 The mosaic becomes a widget stack (A)
The same frame (160 pt), the same edge (202 Rev 3), whole tiles. Every earlier feature plays on top of whichever face is showing (200 moods, 201 moments, 204 switchboard, 209 open reactions, 213 lent pixels).

### Faces
1. **Gallery:** the 214 scenes (11 now). Tess picks by hour and weather, and the face moves to a new scene on each turn.
2. **Weather** (always in the stack): a pixel scene of now, e.g. sun, cloud bank, rain lines or snow, plus the temperature and the next change in 218's pixel numerals ("62", then "rain 4 PM" as pixel glyphs). No caption at the edge.
3. **Place:** when he is more than 80 km from home, a pixel skyline by kind of place (coast, mountains, desert, city, small town) and the local time in pixel numerals. The place name appears only when he holds the face, inside the mosaic as pixel letters.
4. **Context faces** go first in the stack while they are live:
   - Workout in progress: the current lift's mark (the Training set-mark pick; Pulse until he picks) and the rest timer in pixels.
   - Cooking: the recipe step number and its timer.
   - Shopping: shown when he is at a store (on-device visit plus MapKit point-of-interest category grocery/supermarket), or when he opens To get. It shows the To get count and the next three things as pixel words.
   - Today: the next thing with its time, only on days with something.

### Turning
- **Auto-turn every 5 to 10 s** on the same jittered clock as the lines, offset so the mosaic never turns in the same second as a line.
- Order: live context faces first, then weather, gallery and place. A live face shows on two of every three turns.
- Each turn uses a 200 changeover, chosen by Tess per face pair.
- **Swipe across the mosaic** to go to the next or previous face, 1:1 with the finger. Release past 35% or on a flick commits with the changeover finishing; anything less springs back. A light impact on commit.
- A touch pauses auto-turn for 30 s.
- No page dots or labels. The first time, the next face peeks 12 pt for 600 ms.
- **Reduce Motion:** turns every 10 s as a plain swap. **Low Power:** no auto-turn; swipe only. **Quiet hours:** the gallery and weather only, every 20 s.
- **Tap a face to open its room:** Training, Kitchen, Pantry To get, Today, or the weather page (later).

## 5 Sources (Core)
- **Location:**
  - CoreLocation, when-in-use, approximate accuracy (reducedAccuracy) for weather and place. The precise one-time prompt is used only for store detection, and only if he turns on "Shopping face".
  - Reverse geocoding uses Apple's CLGeocoder on the phone.
  - Location, place names and store visits never reach backups, logs, widgets outside Home, notices or Claude.
- **Weather:**
  - WeatherKit needs the paid developer account, which he doesn't have yet.
  - Until then, the recommended source is Open-Meteo: free, no key, no account. It is sent coordinates rounded to 0.1° (about 11 km), no identifiers, and results are cached for 30 minutes.
  - THIS SENDS COARSE LOCATION OFF THE PHONE, so it needs his OK. Until he says yes, the weather face shows the on-device sample and is marked "sample" in Settings only.
  - Switch to WeatherKit when the account exists.
- **Gallery:** the 214 scenes only. His own photos are not in this sheet (a privacy call, later).
- **Settings > Home > Mosaic:**
  - Faces: Gallery, Weather, Place, Workout, Cooking, Shopping, Today. All On, except Shopping is On only after the location ask.
  - "Turn by itself" On.

## 236 v2, Oct 23 10:31 PM (his asks): spacing, touch zones, the one thing
Board: https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM (the phone today, from the code, next to v2 at 402 x 874; "Show spacing" and "Show touch zones" overlays).

**Why it looks cramped today** (from the code): `HomeMosaicPage` is one ScrollView VStack with 16 pt gaps and no flexible space. Below it sit an 80 pt `tessRoom` band and a 56 pt RootView bottom inset, about 120 to 136 pt of empty foot, so the content rides high.

### 1 Spacing (B): fixed slots that fill the screen
| Block | 402 x 874 (iPhone 17) | 390 x 844 |
|---|---|---|
| Board, 3 x 30 + 3 | 84-180 | 66-162 |
| Gap | 30 | 26 |
| Mosaic 248 x 160, right | 210-370 | 188-348 |
| Gap | 30 | 26 |
| One thing | 400-612 (212) | 374-578 (204) |
| Gap | 28 | 24 |
| Apps list, 3 x 40 | 640-760 | 602-722 |
| Foot: Undo line left (15 pt, 500, ink2), Tess right | 768-840 | 734-810 |
- Drop the ScrollView on Home (or lock it), the 80 pt Tess band and the 56 pt inset. Tess overlays the foot, bottom right.
- Other sizes: the three gaps and the one-thing height (196 to 232) share the difference evenly.
- The Settings word sits on row 1's line, left.

### 2 Touch zones (A for the mosaic, B for the rest)
- A drag belongs to the zone it starts in, until lift.
- **Mosaic** (its frame + 8 pt): sideways swipes turn its faces (236 §4), and touches lean the pixels.
- **One thing** (its slot): sideways swipes turn the thing, and a hold strikes it.
- **Board**: taps on the highlights only.
- **Apps list**: vertical only.
- The 30 pt between the mosaic and the one thing starts nothing.
- Direction locks after 10 pt (sideways if it leads 1.3x).
- REMOVE the ScrollView simultaneousGesture that turns things from the mosaic (HomeMosaicPage.swift L156-171).
- The touch feed stays simultaneous but only leans.

### 3 The one thing, reworked (B; sign by A)
- **Header:** a small-caps room word in its accent (13 pt, 600, tracked). There is NO "N of M" counter (his 10:39 PM: no counters on any swiper).
- **Big:** one line, in the accent (ink for tasks). Numbers are Outfit 400 at 56 pt; words are Figtree 700 at 38 pt. It fits 1 pt at a time down to 0.75x, then uses the 224 short form. Slot 64 pt.
- **Mid:** Figtree 500, 20 pt, ink, one plain sentence. No keyword and no underline. Slot 28; it cuts at whole words.
- **Small:** Figtree 500, 15 pt, ink2. Slot 22.
- Header and tiers (154 pt) sit centered in the slot. The gaps are 8, 6, 6.
- Drop the "Hold to strike it through" line and show a one-time hint instead.
- Copy:
  - Training: "6:30 pm" / "Push A, bench first" / "Bench best 205 lb, three weeks ago"
  - Kitchen: "4 to get" / "Tortillas, cilantro, limes" / "For tacos tonight, on the way home"
  - Lists: "6 of 14" / "Packing, for Sunday" / "Next: socks, the book, the adapter"
  - Routines: "8 pm" / "Stretch, five minutes" / "Third night this week"
  - Weather: "64°" / "Clear until 4, then rain" / "Sunset at 6:34 pm"
- **Sign (A):**
  - Size and place: 20 x 20 of the mosaic's own tiles (4 pt pitch, 3.2 tile) = 80 pt, centered on big+mid, with the text slots ending 12 pt before it.
  - Woven: edge tiles keep 33% of their source tile's color.
  - Built: bottom row first, 6 ms stagger, 420 ms low arc (lift 18).
  - Alive: every 4-7 s one tile flies to the mosaic and back.
  - Drawings: a loaded barbell (bobs), a bag with greens, a packing case filling to its share, a moon with twinkles, a sun with turning rays.
- **Lens:** the saved glass-lens pattern (237 v3). While a finger is on the one thing, a clear glass slab (radius 22) sits around big+mid+small. On the mosaic, a clear glass rim lifts around the frame while turning faces.

Check: simulator next to the board at 402 pt, Paper and Black, overlays on.

## 236 v2.1 (his 10:51-10:55 PM Oct 23): no lens, blended mosaic, wider, Now + Gallery faces
- NO LENS anywhere (his 10:51 PM). Remove it from the one thing, the mosaic and every swiper. Swipes slide 1:1, nothing over them.
- He likes 236 v2 otherwise and wants the phone to look exactly like the board. Taps on things must open them.
- Mosaic edge back to the departure-mosaic blend: squircle (corner radius 6 tiles), colours climb out of the page over 16 whole 4 pt tiles in Bayer-dithered steps (24 levels, smootherstep from 8 tiles inside to 16 outside; up/down climbs 2.2x faster so it clears the board and the one thing). The rim mirrors the scene's own detail. No frame, fade or blur; tiles always full size.
- It bleeds past its touch zone. The swipe zone stays the core frame (right 24, top 210, 160 tall).
- Width per face, grows left from the right margin, eases between faces, breathes 1 tile: Now 88, Gallery 88, Weather 84, Workout 72 tiles. Extra room shows more: Weather = rain on its way at the left; Workout = the week's 7 days as 3x3 tiles, done lit, today pulsing.
- Faces: Now, Gallery, Weather, Workout (more apps later).
  - Now: plays the board's latest announcement; the mosaic turns top row down as the flap turns. Rain: rain slate sky, falling drops, splashes on the bottom row. Rice: the bag in Kitchen. Bench: barbell in Training. Packing: case filling in Lists. Else the scene of the hour.
  - Gallery: pixel scenes by time of day, weather and place type (never a named place), a scattered tile swap every ~9 s: evening hills, night sky + moon, rain on a window, morning sun.
- Highlights take their meaning's colour (his 10:53 PM): rain = new token rain 557A93 light / 9DBACE dark, not the sunset wash. Weather one-thing accent = rain.
- Board https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM (v2).

## 236 v2.2 (his 11:21-11:22 PM Oct 23)
- One thing swipe: the big and mid lines get a hard clip edge 92 pt from the right (where the sign starts), so swiped text never passes under the sign. The small line runs full width (it sits below the sign). The left edge is the slot edge. No fade on either edge.
- Light looks: the mosaic grade on light pages lifts saturation 30% and deepens 10%. It stays full strength across the whole frame; the dither climb from the page happens only outside the frame (u = (16 - sd)/16). Dark pages are unchanged.
- Weather words act out their weather on a clear layer over the board text. Reduce Motion turns them off. Never pixels or dots.
  - Rain: 7 thin 1 pt strokes fall through the word and stop at its baseline.
  - Snow: 6 small plus strokes drift, swaying.
  - Windy: letters lean and slide 2 pt in a wave, with 3 thin gust strokes.
  - Sunny: a glint sweeps across every 5.5 s.
  - Colors: rain 557A93/9DBACE, snow 6E8296/C9D6E2, wind 5E6E7E/B4C2CC, sun = sky amber.
- Board v4 https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM

## v2.3 (his 11:41 PM Oct 23) board v6
- One thing turns with vertical swipes too: up = next, down = back, 44 pt commit; tiers translateY at depths .9/.72/.54, clipped to the slot (tiers clip inset -57 top, -29 bottom, 92 right). Horizontal unchanged (50 pt).
- Weather words stronger: rain 10 strokes 1.3 pt, 7 pt long, alpha .85; snow 9 six-point flakes alpha .95; Windy letters translate 4 pt, lift 1.2, skew 12°, rotate 2°, five curved gusts alpha .75; Sunny bright sweep (white core) every 4 s plus three 1.2 pt rays riding the sweep; NEW Cloudy (cloud 6B7480 / B9C0C8): three small clouds filled in page color at .55 with a thin cloud-color outline, drifting across the word only. Reduce Motion: none.

## v2.4 every weather word (his 11:51 PM Oct 23) board v7
One effect per Core WeatherCondition case + overlays; word color follows the cloud. New tokens light/dark: pcloud 8A7552/DCCDAA (white-cloud days), moon 4A5788/B3BDE8 (nights), fog 727880/A7ACB2, ice 2F7299/9FD0EE (anything freezing, cold warning, hail), storm 53507A/ABA8DC, warn A23B27/F08F72 (wind and heat warnings), bolt 5B4FD0/FFF1A8 (lightning only).
- Cloud: flat-bottomed cumulus, union of puffs filled once, top-lit gradient hi->mid->lo, soft lit bumps, 1.6 pt soft rim, laid on at one alpha; puffs breathe ±5% over ~1.8 s, clouds drift ±8-16% of word width over 5-7 s. Tones white/grey/rain/storm (hex in the board TONE table).
- clear day: shine only (4 s). clear night: 4 star glints (thin 4+4 arm strokes) grow and shrink. mainlyClear: shine or glints + one small white cloud. partlyCloudy: 2 white clouds at .7-.78 over part of the word (+shine/glints). overcast: 3 grey clouds at .66-.74. fog: 4 page-colored mist bands drift across + 2 wavy fog lines.
- drizzle: rain cloud above, 16 fine 3 pt strokes. rain: 11 strokes 7 pt. heavyRain: 20 slanted 9 pt + splash ticks at baseline. freezingDrizzle/Rain: same in ice + a glaze line under the word with a traveling glint.
- snow: grey cloud, 9 flakes. heavySnow: 17 flakes + a snow cap line on the letters. snowGrains: 22 tiny ticks, fast.
- thunderstorm: storm cloud, light rain, a bolt (2 flickers every 5.2 s) and the word flashes bolt color. thunderstormHail: + 7 ice pellets (stroked squares) that bounce once.
- windy: letters sway 4 pt/12°, 5 gusts. windWarning: 1.8x sway + shiver, 8 longer gusts, warn color. heatWarning: letters waver in a traveling wave, 4 rising heat squiggles. coldWarning: frost crystals grow and fade at letter tops and baseline, ice color.
- Reduce Motion: no effects, word keeps its color. Flash rate well under 3/s.

- v2.5 (his 12:07 AM, board v8): clouds draw on a BACK layer under the text (front veil only 10%), so words stay crisp. Fog: the word is masked where mist is thick (horizontal moving mask, min 30% opacity) + long soft page-colored wisps in front (alpha up to .8) + a fog-tinted haze behind. windWarning sway 1.35x.
- v2.6 (his 12:11 AM, board v9): clouds sit LEVEL with the word (vertically centred on it, height 1.1x the line), behind the text, see-through (white .9, grey/rain/storm .62 of their alpha); front veil 8%. Precipitation starts at mid-word and falls to just under the line.
- v2.7 (his 12:12 AM "dull" on light, board v10): light grade = saturation x1.55 around the mean, then x1.08 brightness + 5% shadow lift; tiles on paper are 3.6 of 4 pt (gap 0.4) so paper does not wash the colour out; dark unchanged (3.2).
- v2.8 (his 12:16 AM, board v11): clouds ONLY on mostly sunny/clear, partly cloudy and cloudy; drawn level with the word, behind it, clipped to the word box (width <= half the word), plus soft fog-style wisps in the cloud tone in front (alpha .3-.4), clipped to the word. Rain, drizzle, freezing, snow, grains, storm, hail: NO cloud, precipitation starts at the word top.

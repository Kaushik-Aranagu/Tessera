# 02 Home and Tess

State as of Oct 24, 2026. Newest sheet wins. The Home spec today is **sheet 236 v2.2 (approved: "exactly like this on the phone") plus v2.3-v2.8**, layered on 199-216 and 220. Everything from 199 onward carries over unless 236 replaced it (his 1:07 PM Oct 23: "I want all the previous features too"; never drop approved Home pieces when the mosaic changes). Tess today is **215-final (Rev 9 cloud + Revs 11-21)**.

Boards (private to Kaushik): Home now https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM (v11). Earlier Home board (200-216) https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp. One thing (213) https://claude.ai/artifact/VgyTXVBnXhMXW1ujG1qE1X. Scene gallery (214) https://claude.ai/artifact/PBUKcPYqbmhP4xs9iZrmcK. Switchboard (204) https://claude.ai/artifact/Lc5mhAxYvDnNdbF18a3rho. Tess (215) https://claude.ai/artifact/7g8r4LzjRV6LeHDxMJ5yiZ (v22). Weather room (243) https://claude.ai/artifact/NyeaiLgka6cPQX3vqWZ1jj.

---

## 1. Home

**Purpose.** The one screen that says what today is and what matters next, in words, with one living picture (the mosaic). Every highlighted part is a door into a room. No money on Home, ever.

### 1.1 Layout (fixed slots, no ScrollView) (236 v2 §1)
No scrolling page. Five fixed slots fill the screen; nothing moves when text changes.

| Block | 402 x 874 (iPhone 17) | 390 x 844 |
|---|---|---|
| Top board, 3 rows x 30 pt + 3 pt gaps | y 84-180 | 66-162 |
| Gap | 30 | 26 |
| Mosaic, core frame 248 x 160, right-aligned (right margin 24) | 210-370 | 188-348 |
| Gap (starts no gesture) | 30 | 26 |
| One thing | 400-612 (212 tall) | 374-578 (204) |
| Gap | 28 | 24 |
| Apps list, 3 rows x 40 | 640-760 | 602-722 |
| Foot: Undo line left (15 pt, Figtree 500, ink2), Tess right | 768-840 | 734-810 |

- Other phone sizes: the three gaps and the one-thing height (196-232) share the difference evenly.
- The word "Settings" sits on row 1's line, at the left (plain word, 44 pt target; 194 §0).
- No 80 pt Tess band and no 56 pt bottom inset: Tess overlays the foot, bottom right.

### 1.2 Type on Home (236 §2)
| Element | Spec |
|---|---|
| Date (row 1) | Figtree 600, 23 pt |
| Rows 2-3 plain words | Figtree 500, ink |
| Rows 2-3 highlighted part | Figtree 700, room accent, **no underline** |
| Numbers | Outfit 400 |
| Apps list names | Figtree 600, ink |
| Apps fact line | Figtree 500, 15 pt, ink2 |
| One-thing big tier | Figtree 700 38 pt (words) / Outfit 400 56 pt (numbers) |

Nothing on Home uses ink3 text. Thinnest text is 500 (numerals 400). If the phone looks lighter than the board, the sizes are wrong, not the colors. No underlines anywhere on Home.

### 1.3 Top board: date + two rows of notices (212, 216, 236 §3)
- **Rows are fixed** (216 §1): 3 rows x 30 pt (23 pt type x 1.3), right-aligned, top pinned to safe area + 16. One line per row always: no wrap, no "...", font never shrinks. Every notice has ordered full/short forms; the row shows the longest that fits (224). Tess may write a shorter form on device; facts (names, digits, days) are never dropped.
- **Row 1, the date**: "Friday, October 23" (US order, weekday first). Door to Today. Colored with the **sky of the hour** as a left-to-right gradient across its letters (216 §2):

| Hours | Light | Dark / Black |
|---|---|---|
| 5-11 AM morning | A9621A -> C2507A | E6A97E -> E07FA0 |
| 11 AM-5 PM day | 2F6FD0 -> 237E92 | 6FA4FF -> 5CC6D2 |
| 5-8 PM evening | BF6A22 -> A33C62 | E8A06A -> F286A6 |
| 8 PM-5 AM night | 4B3FA8 -> 2D3F7A | A79CF0 -> 7E95D8 |

  - Rain or snow eases the second stop 30% toward slate (34506F / A7BCD6). On a day with something due, the weekday word takes the first stop's color at 700. All stops are ΔE >= 10 from Ember and >= 3:1 at 23 pt. When the hour band changes: one letter-flip pass, gradient eases 600 ms.
- **Rows 2-3, notices** (a departure board): one complete notice per row, ending in a stop. Each notice names one highlighted part, which is its door: "**Bench**, 185 for 5 again." -> Training at that lift; "**Packing**, 6 of 14." -> that list; "**Rice** goes out today." -> Pantry at Leftovers; "Rain from **4 PM**." -> Weather. Highlight is Figtree 700 in the meaning's color (weather words use their condition color, e.g. rain 557A93 / 9DBACE; 236 v2.1). Door hit area = full row height around the highlight + 8 pt each side. Private items read by their shownLabel. At most 6 notices in rotation, ranked by Core (soonest/most important first).
- **Flip cadence** (236 §3): each row holds 7 s ± 3 s (jittered, clamped 5-10 s); row 3 offset by half a hold so rows never flip the same second; an event (new notice, timer ends, set logged) flips its row at once; while a finger is on Home, flips wait until 2 s after lift. Reduce Motion: plain swap every 10 s. Low Power and quiet hours (11 PM-7 AM): fixed 10 s. Paused in background and during a doorway.
- **The flip itself** (216 §4, the board's setSentence): each character is a fixed cell laid out once at the target string. Letter set in order: space, a-z, A-Z, 0-9, ":", ",", ".", "'". A cell walks forward old -> new in steps of ceil(n/9) (max 9 steps), 52 ms per step. Each step is a vertical flap scaleY 0.08 -> 1 over 70 ms, cubic-bezier(.3,.7,.4,1), origin 50%/52%. No fade, blur or slide. Stagger (row x 5 + index) x 14 ms. Unchanged cells stay. Added cells flip in from a space, dropped cells flip to a space then collapse. A new change cancels the old (generation counter; cells snap to target first). One soft haptic when the last character lands, only while Home is on screen. VoiceOver reads the final text once. Letter flips live **only** on Home's top lines (never in Tess's conversation).

### 1.4 Weather words and their effects (236 v2.2-v2.8; approved "all good, very glad")
Any weather word on Home (in a notice, the one thing) acts out its weather on a clear layer over the text. Never pixels or dots. Reduce Motion: no effect, the word keeps its color. Flash rate well under 3/s. One effect per Core `WeatherCondition` case.
- **Tokens** (light / dark): rain 557A93/9DBACE; snow 6E8296/C9D6E2; wind 5E6E7E/B4C2CC; cloud 6B7480/B9C0C8; pcloud 8A7552/DCCDAA (white-cloud days); moon 4A5788/B3BDE8 (nights); fog 727880/A7ACB2; ice 2F7299/9FD0EE (freezing, cold warning, hail); storm 53507A/ABA8DC; warn A23B27/F08F72 (wind and heat warnings); bolt 5B4FD0/FFF1A8 (lightning only); sun = sky amber. Word color follows its cloud.
- **Clouds only on** mainlyClear, partlyCloudy and overcast (v2.8): flat-bottomed cumulus (union of puffs, filled once, top-lit gradient, 1.6 pt soft rim), drawn **level with the word, behind it**, clipped to the word box, width <= half the word; soft fog-style wisps in the cloud tone in front at alpha .3-.4. Puffs breathe ±5% over ~1.8 s; drift ±8-16% of word width over 5-7 s.
- clear day: a bright sweep (white core) every 4 s with three 1.2 pt rays riding it ("shine only"). clear night: 4 star glints (thin 4+4 arm strokes) grow and shrink. mainlyClear: shine or glints + one small white cloud. partlyCloudy: 2 white clouds .7-.78. overcast: 3 grey clouds .66-.74.
- fog: the word is masked where mist is thick (horizontal moving mask, min 30% opacity), long soft page-colored wisps in front (alpha up to .8), fog-tinted haze behind. He loves the fog.
- Precipitation has **no cloud**; it starts at the word top and falls to just under the line: drizzle 16 fine 3 pt strokes; rain 11 strokes 7 pt (1.3 pt wide, alpha .85); heavyRain 20 slanted 9 pt + splash ticks at baseline; freezingDrizzle/Rain the same in ice + a glaze line under the word with a traveling glint; snow 9 six-point flakes (alpha .95); heavySnow 17 flakes + a snow-cap line on the letters; snowGrains 22 tiny fast ticks.
- thunderstorm: light rain + a bolt (2 flickers every 5.2 s), the word flashes bolt color. thunderstormHail: + 7 stroked-square ice pellets that bounce once.
- windy: letters sway 4 pt / skew 12° / rotate 2° / lift 1.2 in a wave, 5 curved gusts alpha .75. windWarning: 1.35x sway + shiver, 8 longer gusts, warn color. heatWarning: letters waver in a traveling wave, 4 rising heat squiggles. coldWarning: frost crystals grow and fade at letter tops and baseline, ice color.
- Tapping any weather word opens the Weather room (243) through the doorway, that word's sentence first.

### 1.5 The mosaic (199-214, 236 §4, v2.1, v2.2, v2.7)
A living pixel picture, the only place in the app with pixels/tiles (rooms' pixel lintels 210, 217-225 are superseded).
- **Grid**: 4 pt step, tiles 3.2 pt on dark, **3.6 pt on paper** (gap 0.4) (v2.7), each tile one flat color. Swipe/touch zone = the core frame (right 24, 160 tall) + 8 pt.
- **Width per face** grows left from the right margin, eases between faces, breathes 1 tile: Now 88, Gallery 88, Weather 84, Workout 72 tiles (v2.1). Extra width shows more (Weather: rain on its way at the left; Workout: the week's 7 days as 3x3 tiles, done lit, today pulsing).
- **Edge** (202 Rev 3 + v2.1): squircle (corner radius 6 tiles), colors climb out of the page over 16 whole tiles in Bayer 4x4 dithered steps (24 levels, smootherstep from 8 tiles inside to 16 outside; up/down climbs 2.2x faster so it clears the board and the one thing). Rim tiles sample the scene mirrored across the edge. No frame, no alpha fade, no blur; tiles always full size. On light looks the grade stays full strength across the frame; the climb happens only outside it. Text shield: tiles under words are capped, feathered over 5 tiles.
- **Light grade** (v2.7, not yet confirmed by him): saturation x1.55 around the mean, x1.08 brightness, 5% shadow lift. Dark unchanged.
- **Faces (widget stack)**, current list: **Now, Gallery, Weather, Workout** (v2.1; "more apps later"). Now plays the board's latest announcement, turning top row down as the flap turns (Rain: slate sky, falling drops, splashes on the bottom row; Rice: a bag; Bench: a barbell; Packing: a case filling; else the scene of the hour). Gallery: 214 scenes by hour, weather and kind of place, a scattered tile swap every ~9 s. Weather: pixel scene of now + temperature and next change in pixel numerals. 236 §4 also specs Place (>80 km from home: skyline by kind of place + local time; name only while held, as pixel letters), Cooking, Shopping, Today (unconfirmed whether still planned).
- **Turning**: auto every 5-10 s on the same jittered clock, never the same second as a line flip; live context faces show 2 of every 3 turns. Swipe across: 1:1 with the finger, commit past 35% or on a flick, else spring back; light impact on commit. A touch pauses auto-turn 30 s. No page dots, no labels, no caption at the mosaic's edge (211); first time only, the next face peeks 12 pt for 600 ms. Reduce Motion: plain swap every 10 s. Low Power: swipe only. Quiet hours: gallery + weather every 20 s.
- **Tap a face** opens its room (Training, Kitchen, Pantry To get, Today, Weather).
- **Scenes** (214): city at dusk, beach, mountains and lake, woods, desert, rain on the window, night sky, fields at sunrise, snow, harbor, autumn trees. One small slow life each (max ~1 tile change per 150 ms). Black look mixes 18% toward 14121A, dark 30%, white x1.02. Tess picks on the phone; he can pin one or ask Tess ("show the beach"). Never name a place.
- **Carried behaviors**: 200 moods (morning, day, golden, running, rest, back, done, rain, night) and changeovers (flip, wave, fall, wipe, dissolve, gather, melt); 201 moments (snow, fog, wind, storm, heat, announce crawl, Tess eyes, timer, finished, best, reminder, delivery); 204 switchboard (cue -> effect -> changeover; Tess > apps > clock > weather; moment beats mood; queue max 3; 11 PM-7 AM only timer and reminder); 206 app glance motifs; 207/199 a tile flies in on Done; 209 open reactions by time away (<2 min ripple 0.9 s; 2 min-3 hr tiles flip from last scene row by row 1.4 s; first open after 4 AM night falls away 2.2 s; 2+ days dusty pixels gather 2.4 s; cold launch gather from night 1.8 s; no haptic); 213 lent pixels. Touches lean the tiles (radius 36 pt, up to 5 pt). Reduce Motion: field still, changes are plain swaps, no lean or ripple.
- **Doorway** (206): opening a room, a wave spreads from the touched word/face across the phone at 0.75 ms/pt (+ up to 30 pt jitter); each 4 pt tile turns the room accent, flips 170 ms, lands as page ground. Back = left-edge swipe (0-24 pt), the same wave reversed. No back word in rooms (4:16 PM ruling). Haptics: soft at start, light on land. Reduce Motion: plain swap.

### 1.6 The one thing (213, 220, 236 v2 §3, v2.2, v2.3)
One thing at a time under the mosaic. Replaces the old Next list and the 209 mosaic pages.
- **Header**: small-caps room word in its accent, 13 pt, 600, tracked. No "N of M" counter.
- **Big** (slot 64): one line, accent (ink for tasks); numbers Outfit 400 56 pt, words Figtree 700 38 pt; fits down 1 pt at a time to 0.75x, then the 224 short form. **Mid** (slot 28): Figtree 500 20 pt, ink, one plain sentence, no keyword, cuts at whole words. **Small** (slot 22): Figtree 500 15 pt, ink2. Gaps 8/6/6; block 154 pt centered in the slot.
- **Copy**: Training "6:30 pm" / "Push A, bench first" / "Bench best 205 lb, three weeks ago". Kitchen "4 to get" / "Tortillas, cilantro, limes" / "For tacos tonight, on the way home". Lists "6 of 14" / "Packing, for Sunday" / "Next: socks, the book, the adapter". Routines "8 pm" / "Stretch, five minutes" / "Third night this week". Weather "64°" / "Clear until 4, then rain" / "Sunset at 6:34 pm". Order = Tess's on-device ranking, max 7.
- **Sign** (A): 20 x 20 of the mosaic's own tiles (80 pt), centered on big+mid, text slots end 12 pt before it. Edge tiles keep 33% of their source color. Built bottom row first, 6 ms stagger, 420 ms low arc (lift 18). Its tiles fly out of the mosaic (lent cells gap and refill ~1.1 s). Every 4-7 s one tile flies to the mosaic and back. Drawings: loaded barbell (bobs), bag with greens, packing case filling to its share, moon with twinkles, sun with turning rays.
- **Swipe**: four ways. Left or up = next; right or down = previous. Horizontal commit 50 pt or a 300 pt/s flick; vertical commit 44 pt. Text slides 1:1 under the finger with depth (tiers translate at .9/.72/.54), clipped to the slot (insets -57 top, -29 bottom); big and mid get a hard clip edge 92 pt from the right so text never passes under the sign; small runs full width. No fade on edges, no lens. One light haptic per page.
- **Done** = press and hold on the big line (the only exception to swipe-right-Done): after 180 ms an ink strike (1.5 pt at 55% height) draws over 0.6 s; release when full finishes it, shows Undo (10 s), next thing arrives; early release retracts. One rigid haptic. A one-time hint replaces the old "Hold to strike it through" line. VoiceOver: "Mark done" plus adjustable next/previous.

### 1.7 Apps list (doors to apps) (205, 209, 220, 236 §1)
- Under the one thing, no label. 3 rows visible, 40 pt rows, wraps endlessly. Middle row is the pick: name swells 1.3x in its accent; its one-line fact (15 pt 500 ink2) is revealed from the right by a clip sliding 14 pt (never a fade). Other rows show names only.
- Facts (Core, privacy-masked): "Push A at 6:15 pm, bench first", "Tacos tonight, 4 to get", "Stretch at 8 pm", "3 left today", "Trip packing, edited at noon", "Packing, 6 of 14 done", "Rent is due Friday" (money as words only).
- Scroll: moves 1:1, coasts with normal deceleration, rubber-bands, snaps to the nearest row (.viewAligned). Selection tick per row crossed while the finger is down, none while coasting. Hold-and-scroll (220) stays: hold 180 ms within 6 pt, soft haptic, middle row 1.06x. Tap middle = open via doorway; tap another row = bring it to the middle. When it settles 240 ms on an app, the mosaic plays that app's glance (206). Vertical drags only.

### 1.8 Touch zones (236 v2 §2)
A drag belongs to the zone it starts in until lift; direction locks after 10 pt (sideways if it leads 1.3x). Mosaic: sideways turns faces, touches lean pixels. One thing: four-way swipes + hold. Board: taps on highlights only. Apps list: vertical only. Gap between mosaic and one thing: nothing. No page-level gesture turns things from the mosaic.

### 1.9 States
- Empty day: the one thing falls back to weather / a routine; notices include sunset. Quiet hours: flips at 10 s, mosaic gallery+weather only, no Tess unprompted.
- Private: shownLabel everywhere ("Private workout", "Private, done. Undo"), including inside the doorway and notices.
- Sample: until real data, weather shows the on-device sample; marked "sample" only in Settings (never on the mosaic).
- Never on Home: money amounts, health, body, calories, calendar titles.

### 1.10 Rejected on Home (do not re-offer)
- 194 six app edges / fan; 195-197 day ruler, day line, 270° day ring; 197 write line and mic on Home; 198 widget row with word tabs.
- 208 apps dial with lens (11:16 AM Oct 23) and its simplified Tess.
- 202 screen-wide pixel layer ("too pixelated"); square skin edge; hard bright-side edge.
- 209 captions under the mosaic, mosaic page captions; 211 day phrase as an underlined word.
- 236 v2 glass lens on swipers (10:51 PM: "I don't want that lens effect at all").
- Underlines, "N of M" counters on swipers, ink3 on Home, heavy wide-spaced numerals (release 66 bug).
- 213 parallax/slide was removed at 12:14 PM, then 1:1 slide with depth came back in 236 v2.1-v2.3 (current).

---

## 2. Tess

**What she is.** The in-app assistant, drawn as a small living cloud ("the soul") in the bottom-right corner of every screen. She speaks only when she has something or when touched. All reasoning is on-device first; Claude only when "Tess asks Claude" is on.

### 2.1 Body (215-final)
- A smooth per-pixel cloud, spherical overall, with no boundary, fading into the page. Uniform texture: no noise, streaks, patches. Only the soft edge moves, on slow waves. Drawing scaled 0.7 (Rev 21); visible size small, **touch target 84 pt**.
- Radius R = 0.16 · breath · (1 + 0.1·spread) · (1 + 0.26·bloom − 0.13·gather). Edge reach 1 + 0.045 sin(2θ + 0.42t) + 0.03 sin(3θ − 0.33t + 1.1) + 0.035 sin(θ − 0.19t). Density exp(−r^2.2 · 0.95). Alpha dark 1 − exp(−3.1·dens) − .02 (peak 235); light 1 − exp(−4.6·dens) − .02 (peak 242). Alpha reaches 0 inside her bounds (no ring).
- Breath 0.96 + 0.08 sin(0.98t) (+0.08 voice level); quiet: 0.03 at 0.35x speed.
- **Color: Ember**, [middle, side, side] light FF5A26, E5341C, FFA90F; dark FF6B3D, FF4A33, FFC23D. Three gaussian fields (sigma 0.76R) a third of a turn apart, turning 0.6 + 0.16t, middle at 0.40R weight 1.08, sides at 0.56R. Plain OKLab mix, chroma up to 1.25x. Color lookup is warped by two broad sines (brush-sweep seams). Light grounds: thin parts chroma x(1 + .45(1−a)), L −.025(1−a). Bursts: one field swells from a random inner point, every 2.2-5.7 s (5-11 s quiet).
- **Ember rule**: nothing else on screen within ΔE00 10 of her Ember middle, unless it is the accent of the room cueing her.
- **Face**: eyes at 1.3x, ink rgba(30,24,30,.86) light / rgba(21,21,23,.82) dark, >= 3:1 else #111. Blinks 130 ms every 2.4-6.6 s (18% double). Glances every 0.7-2.8 s (55% small, 27% to a point of interest, 18% to him held 2.6 s); eyes follow the finger. **Mouth** only with meaning: smile (did what was asked), slant rising 0.5 pt right (waiting on his answer), "oh" for 1.4 s (something new arrived beside her). No lip sync, never a frown.
- **Life**: leans after her eyes (0.45x), bobs ±1.1 pt. Reactions are cloud envelopes: open (gather 13%/140 ms then bloom up to 26%, burst from middle), close (bloom .45 over 320 ms), think (colors spin +.045/frame), done (4 pt hop 420 ms, .35 bloom, gold burst 1.6 s, happy eyes 1.1 s), no (2.4 pt nod 360 ms), touch (.6 gather 220 ms, burst toward the finger, eyes 1.2x 320 ms), hearing (his voice level as travelling edge waves, .28 catch per heard word, 1.6 pt lean). Reduce Motion: reactions off, eyes and blinks stay.
- **Ground awareness** (213): samples luminance under her every 0.5 s; light grounds draw normal + 30% multiply pass; dark grounds screen.

### 2.2 How she cues rooms (215 Rev 20 G2-G4)
- In a room with one clear accent, her palette becomes a close palette from it: middle = the accent at L 0.64 (light) / 0.74 (dark), chroma >= 0.15; sides ±18° hue at L −0.05/+0.05. Home, or any screen with several accents, keeps Ember. She never averages accents.
- Change is a 1.2 s smoothstep glide, hue the short way in OKLCH, plus a 0.28 catch. Reduce Motion: instant.
- Decided by `TessDirector.decide(.tessPalette(pageAccent), context)` (RuleDirector now, a model later); it sees only screen kind, accent and her state, never text.

### 2.3 In the corner (212, 215)
- Bottom right, on her own top layer above every layer (mosaic, sheets, doorway); hit-testing only on her. 14 pt from right and bottom (212).
- No standing line. When she has something (on-device rule) or is tapped: one line to her left, right-aligned, up to 2 lines, in Newsreader 18 pt (New York in the app if Newsreader can't ship), words arriving one at a time (62 ms each, +40 ms after punctuation, 3 pt rise over 180 ms, no fade), gone after 6 s. Names in her line are doors. Linked words weight 500, never break. Never speaks unprompted 11 PM-7 AM.

### 2.4 Gestures on her (215)
- **Tap**: opens her layer (below), typing ready.
- **Hold (>= 0.35 s)**: talk. She stays under the finger at 1.3x; his live words show at once (Figtree Light 28); release sends; slide left > 60 pt arms cancel. On-device speech only (SpeechAnalyzer), audio never kept; if the model isn't downloaded she says so and the field opens.
- **Drag onto anything**: ask about this (moves after 10 pt, sits 44 pt above the finger at 0.78 scale; light tick per target; answers in the corner, then springs home). Open in build (builder-a handoff).
- **Swipe up fast** (> 40 pt in < 0.26 s): her room, a circle growing from her corner: "Watching today" + today's log (time column Outfit, names as doors, Undo reading "Reversed" after use). Open in build.
- **Double tap**: quiet for an hour: eyes close, breath slows, top lines stop rolling, "Quiet until 1:30 pm." once. Tap wakes her (two blinks).
- VoiceOver: one button with actions Ask, Talk, Open her room, Quiet for an hour; every object gets "Ask Tess about this".

### 2.5 Her layer (215 Rev 2, 5, 10, 16, 19)
- Opens over Home blurred 18 pt, saturation 1.15, 52% page tint (the one place blur is used besides wheels; Reduce Transparency = page color at 92%). In/out 0.38 s. She moves to (W/2, H − 112) at 1.35x.
- Top to bottom: state line ("Ask me, or hold me to talk"), the conversation, at most 3 plain replies (ink 17 pt, no underlines; a tapped reply flashes for 0.22 s and becomes his line; "That's all" closes), the Type to Tess field (multi-line, grows to 120 pt; on the phone return adds a line and a send arrow sends).
- One running conversation (TessMemory, on device, 7 days, clearable in her room). Her newest line 23 pt Newsreader, older 17 pt; his words Figtree 17. Up to 9 items. Time markers Outfit 200 12 pt ink3, tracked .06 em, only after 20+ min gaps; after a gap she opens under "Now, 1:31 pm". Her opener picks up what changed ("Since then, Push day moved to 6:30. Stretch at 8 may run into it. Move it to 9?"), never repeats or contradicts. Echo: an earlier mention of a word she names again brightens to ink for 0.9 s.
- Close: tap blurred Home, swipe down, tap her, Escape. Unsent drafts clear. Privacy: shownLabel only; money/health/body/calorie/calendar text never stored; never on widgets, Lock Screen or notices.

### 2.6 Speak / Write / Show (history)
`no-buttons.md` (Oct 15) and `calm-capture.md`: tap the soul and three dabs rose into a column of mode words Speak (y 594), Write (664), Show (734); Write smeared a dab into a writing line; Show opened Photo, Video, File; hold = straight to Speak. **Superseded by the 215 layer**: tap = conversation with the typing field, hold = Speak. Show (photo/video/file capture) has no home in 215: unconfirmed whether it returns. Also superseded there: double-tap-soul-goes-to-Today (now Quiet), cobalt lines, vermilion UNDO.

### 2.7 Rejected Tess looks (never re-offer)
Orb/skin/Vegas Sphere (Oct 22 4:47 PM: "tess is ugly"); 208 simplified drawing; six dabs ("two overlaid triangles"); wet-paint marbling ("ugly"); full rainbow ramp; visible blobs; a ring from clipped glow; sun-like solid core; flattened shape; readable body with feather edge; turbulent patchy gas; lip-sync mouth ("what is that?"); tone-by-moment (removed); Lagoon/Dusk/Before palettes; presets and underlined offer rows in the layer; letter flips in conversation.

---

## 3. Weather room (243, first cut, open)
- **Purpose**: a basic Weather app; any weather word on Home opens it through the doorway with that word's sentence first. More creative features later. Data: Open-Meteo (free, on by default, 0.1° rounding, 30 min cache; his 10:28 PM OK), air-quality API. WeatherKit when the paid account exists. Never show a city.
- **Landing (402 x 874)**: y 54 "Weather" 40 pt 600 in sky amber C9772E / E8A06A, time right (Outfit 15 ink2). y 112 temperature Outfit 200 104 pt (degree 52 pt) colored by the current condition; right of it 15 pt ink2 "feels like 55°" / "high 61°, low 49°". y 238 line 1, 26/500: "<Cloudy> now, <Rain> from 4 PM." (weather words with their 236 effects). y 276 line 2 17 pt ink2. y 330 "Next hours"; y 350 hour columns 59 pt wide (time 13 ink2, temp Outfit 300 24, one word 13/600 in its condition color); drag across or up/down pages 3 hours; the strip owns drags that start on it. y 456 "The week"; y 476 one 22/500 sentence (line 34) naming only notable days, each weather word a door (44 pt hit) to that day. y 640 air line 15 pt ink2 ("Air is good, UV 2, wind 9 mph from the west.", good in go green). Foot: action word "Rain alert" in rain color, >= 28 pt from the left; tap toggles, receipt "You'll hear 30 minutes before rain." + Undo 10 s. Tess right.
- **Day page**: day name 40 pt amber; high Outfit 200 88 pt in the day's condition color, low 40 pt ink3; the day's sentence 24 pt; hour columns; "Sunrise 7:25 AM, sunset 6:06 PM." Slides in from the right (spring .42 s); back by edge swipe. Words on a covered screen don't animate.
- **Colors**: amber (room), condition colors by meaning, ink/ink2, go green for good air.
- Build: #1401 room, #1402 adapter (both cloud-written, not compiled). Open: wind direction, CoreLocation wiring, rain-alert notification.

---

## 4. Lock Screen, widgets, Live Activities (as they touch Home)
The newest visual spec is old (Oct 16-23 surface sheets); only the rules below are firm.
- **Firm rules** (142, 177, 190, 191, 215, 236 §5): Figtree words, Outfit numbers, sentence case. Health, body, calories, calendar, location, place names and Tess's conversation never reach widgets, Lock Screen or Live Activities. Money only as due words ("Rent is due Friday"), never an amount. Private things read "Private workout" / "Private routine"; private dishes "Your dish" / "Timer done". Lock Screen setting: Masked/Titles (private and walled stay masked regardless; 203). No badges, no emoji, no counts of what he missed. Notifications are one sentence ("Rice, 2 min left."), actions are plain words "Done", "Not now". Nothing on the Lock Screen asks.
- **Widgets** (142, needs his yes, switch surfacesV2): medium = the day sentence, up to 3 clauses, key words in their accent; small = the first clause; large = sentence + 3 next things. Older (widget-states addendum, Oct 16): each widget is Home's line, one sentence with a stop, no counts, no rings; the one number on a face is a time or timer; words push in from below, numbers `.numericText()`. Tinted mode: ground drops, one accentable element. Unconfirmed: whether widgets now mirror the 236 top board or the mosaic.
- **Lock Screen accessories**: inline = next clause by clock ("Push A at 6:15"); rectangular = clause + start time in Outfit 300; circular = one word or a `Text(timerInterval:)` timer, no gauge. Controls (177): "Log a set", "Start Morning", "Add a task", "Quiet", words only, ink only.
- **Live Activities** (142, 230): one per running process in its room's signature: Training = set marks + rest countdown (Outfit 200); Cook = soonest timer + "+2", next step; Routine = step in words. Rest end updates the activity + one local notification (sound follows the silent switch). Updates are silent. The older lockscreen.md / live-activity.md (Cobalt sky, Inter Tight, cream type, vermilion tick) are superseded in type and color; their structure (one number, one action, tap the set to log without unlocking, Undo) is the base. Unconfirmed: current color treatment.
- **The mosaic's Workout/Cooking faces** mirror the Live Activity content on Home (current lift's mark + rest timer in pixels; recipe step + timer).

---

## Sources
home-v2-elements-194, home-v3-195 (196-199), departure-mosaic-200, mosaic-moments-201, home-blend-202, mosaic-switchboard-204, home-sentence-apps-205, apps-mosaic-door-206, dial-tess-layers-208 (rejected), home-open-swipe-tess-209, home-doors-next-211, home-date-notices-tess-corner-212, home-one-thing-213, home-mosaic-gallery-214, tess-corner-interface-215, tess-215-final, home-top-fixes-216, home-gestures-220, fixed-slots-foot-224, color-roles-241, home-delta-236, weather-room-243, no-buttons, widgets-and-snippets, widget-states, lockscreen, live-activity, round3-141-145, round12-177-180, round15-189-192; docs/handoff/design.md, builder-a.md, builder-b.md, weather.md, gestures.md; memory home-mosaic-design, tess-paint-v2, tess-sphere-direction, dial-208-rejected, swipe-lens-pattern.

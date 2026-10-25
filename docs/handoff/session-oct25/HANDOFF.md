# Design session handoff, Oct 25, 2026 (Claude, remote; local clone only, nothing pushed)

For any agent on any system picking this up. Everything below is in this repo under `docs/handoff/`. Kaushik's own
words are quoted or kept close; "approved" means he said so. Boards are claude.ai artifact pages owned by his account
and may not open for you; every board's full source is in the repo next to its sheet, so open the HTML locally.

## 0. Ground rules learned this session
- He reviews on his phone or a remote MacBook. Give him links and attachments in the chat, never file paths.
- One recommendation per question. He answers by voice, in fragments; a fragment is a full verdict.
- When he says "subtle", go much further than feels right. Four glass rounds were "too much" before one landed.
- Screenshots from him are the fastest debugging there is; ask for one when something "doesn't render".
- A canvas drawing never passes for a photograph with him. Real plates do. Stronger, his rule after four Routines
  rounds: NO DRAWN THINGS THAT AIM AT REALISM. Keystones are real material (plates + live layer) or deliberately
  graphic (pixels, type, chalk, hairlines). Illustrated scenes, characters and objects get rejected on sight.
- Costs are accepted for the Weather effects: "whatever tools we need, we should get it."
- THE KEYSTONE SLOT IS ONE FIXED SIZE EVERYWHERE: 354 x 182 pt at top 196, the Home mosaic's slot, on every landing
  (Home, Notes, Routines, Weather, Kitchen, Training). Never grow it for content; more content means pages (the
  Kitchen tickets flip), not a taller band. His correction after 259 v1.
- THE CENTERPIECE STAYS THROUGH THE WHOLE APP (his rule, end of Oct 25): every keystone stays in its slot on every
  level of its app, live to what the lower part shows, as the Kitchen pass does. Weather and Notes already do.
- Landing status at the end of the session: Home approved; Notes approved; Weather sky + glass surface approved
  (inside open); Training blackboard locked; Kitchen pass decided; Routines woodland pending and "the weakest
  link", redesign next; Lists and Money without a keystone.
- He will not have this agent push to GitHub. Everything here is in a local clone; see section 8 for how to move it.

## 1. What was decided today, in order
1. **Routines, the Sheaf (sheet 249) APPROVED** as the list behind a door, after four rounds. Round four: the open
   section at the top (Outfit 200 38 pt plum with count, a stand line of colored phrases that FILTER the list when
   tapped), rows 48 pt two-sided (name over what it is; time over state word), the list scrolls inside its region
   with the last row always cut in half, the waiting sections stacked vertically at the foot three at a time (swipe
   across to page, pull up or tap to open), sort as a lone roll word ("By grove"). Full spec: `design-sheets/routines-sheaf-249.md`.
   Rejected on the way: hairline "sheaf edges" on closed stacks, a "Sorted by" sentence, a horizontal shelf.
2. **Keystone brainstorms (sheets 251, 252) mostly rejected.** 14 per-app keystones ("charts in costume"), then ten
   living scenes, then a 22-tile effects gallery: nothing clicked except **Pull apart** (a name's letters come apart to
   open what is inside).
3. **Kitchen: Pull apart is the app's opening move for level 1 and 2** (a dish into ingredients, a place into
   things), as a LAYER over a deeply blurred page (18 pt blur, 97% scale, 52% tint), letters travelling from the row
   to the layer headline and spreading 34 pt per step. NOT the landing. The Kitchen landing keystone is still open;
   four written directions on board 254 (fridge door, stove, pantry light, kitchen window). His only hint: "something
   about the refrigerator, something that could help."
4. **Weather: the whole page is the sky**, like Apple's weather wallpaper, and it must look REAL (photographic), with
   the sun where it is, the moon in its phase on its arc, clouds, rain, storms, fog, snow. The keystone slot holds plain
   information. The rest of the page: details and CARE nudges (things to do because of the weather, swipe right = done).
5. **Weather keystone surface APPROVED (sheet 254 v9):** the screen glass softly raised. The sky inside is untouched.
   Only cues: a soft light falling off the top-left edge (14 pt blur, 4 pt offset), a soft shadow off the bottom-right
   (20 pt blur, 8 pt down) with a second wider fainter one (34 pt, 14 pt down), and a 1 pt hairline inside the edge.
   NO refraction, frost, fill, tint or lines. Rejected on the way (all his words): frosted panel ("separate surface"),
   bevel ("too embossed"), plateau ("two boundaries", "ugly"), lens band ("super bad"). Screenshots in `screenshots/`.
6. **THE SKYPIECE (his idea, approved to pursue):** the keystone is an OPEN VESSEL with depth; weather gets in and
   leaves traces. Rain beads and water collects at the bottom (ripples where drops land, sloshes with tilt,
   evaporates in sun); snow piles in drifts; lightning leaves scorch marks that fade; wind shakes everything inside;
   on special days Tess dresses it (Christmas lights, snowflakes). The numbers live inside, above the water line.
   Built as direction 5 on board 255. "I'm loving how beautiful this is getting."
7. **Inside the glass (sheet 255):** five directions built live: plain numbers alive (wind trembles, humidity sweats,
   UV warms, sunset countdown), Tess says it (one Newsreader line arriving a word at a time, rewritten on events),
   the number is a dial (swipe through the next hours), the sun's day (hairline arc with the sun and moon points),
   and the skypiece. Not yet picked between; recommendation: plain numbers as base + Tess's line when she has
   something + the skypiece effects always.
8. **Sky plates (sheet 256):** real skies are the answer. Seven CC0 Poly Haven panoramas were pulled and cropped to
   portrait plates (`design-sheets/weather-plates/`, README there has the slug table) and wired under the glass on
   board 255 v3: plate by condition and hour band, 8 s cross-fade, graded by band and weather, our rain, snow, fog
   and lightning on top, text color sampled from the painted sky, a "Drawn sky" switch for comparison. He likes them.
9. **Next for plates: GENERATE the moving set** (motion, seamless loops, several variants per condition, one camera
   and grade, scalable). He is running `weather-plates/BRIEF-for-ChatGPT.md` with the seven plates attached, and
   `weather-plates/PROMPTS.md` for single stills. Results come back as attachments or on a branch. Lightning stays
   drawn in the app so its timing is random.
10. Also this session: the **linked prototype** of every screen (`design-sheets/prototype/`, with the woodland scene),
    the Routines woodland verdicts (groves Body, Mind, Home + Across the lake; withering with soft words, protected
    by a planned rest or the Small way), and the republished 248 board.

## 2. Where everything is
| What | Path |
|---|---|
| This document, screenshots, scripts | `docs/handoff/session-oct25/` |
| Design index with today's section | `docs/handoff/design.md` (Oct 25 section at the end) |
| Sheaf, approved | `design-sheets/routines-sheaf-249.md`, `routines-sheaf-249/board.html` (+ `board-v1..v4.html`) |
| Woodland verdicts | `design-sheets/routines-woodland-248.md` (Verdicts section), board copy republished |
| Keystone rounds | `design-sheets/keystones-251.md`, `keystones-251/board.html` (+ `board-v1.html`); `inspiration-252.md`, `inspiration-252/board.html` |
| Kitchen pull apart + Weather page v1 | `design-sheets/kitchen-weather-253.md`, `kitchen-weather-253/board.html` |
| Glass surface (approved v9) + pull-apart layer + Kitchen landing directions | `design-sheets/kitchen-weather-254.md`, `kitchen-weather-254/board.html` (+ `board-v1..v7.html`, one per glass round) |
| Inside the glass, skypiece, real plates under it | `design-sheets/weather-inside-255.md`, `weather-inside-255/board.html` (+ `board-v1.html`) |
| Plates: sources, plan, decision | `design-sheets/weather-plates-256.md` |
| Plates themselves + README + prompts + brief | `design-sheets/weather-plates/` |
| Linked prototype of every screen | `design-sheets/prototype/index.html` + `scene.html` |
| Plate-making script | `session-oct25/scripts/crop_plates.py` |
| JS bracket checker (early boards) | `session-oct25/scripts/check_brackets.py` |
| REAL syntax check: parses every `<script>` block with gjs (SpiderMonkey), and flags an unclosed `<script>`; run it before every publish | `session-oct25/scripts/jscheck.sh <file.html>` |

## 3. How the boards are built (so you can change them)
- Each board is one self-contained HTML file: a review page (board tokens) with one or two 402 x 874 "phones"
  drawn in DOM and canvas. Phones scale to fit with `[data-fit]`. Fonts from Google Fonts (Figtree, Outfit, Newsreader).
  App tokens on `.phone` follow sheet 241 (room accents, done green, needs-care wine, gold, slate), with a Paper/Black
  look switch.
- Weather boards: `#sky` canvas (402 x 874 at 2x) paints the sky every frame in `draw(t)`: plate (if loaded) or the
  drawn fallback (gradient by sun altitude, stars, sun with halo, moon with phase, noise cloud field lit toward the
  light), then rain/snow/fog/lightning, horizon haze, grain. `#glass` canvas (414 x 242 at 2x, 30 pt margin) paints the
  keystone in `glass(t,ink)`: light and shadow outside the slot, the sky 1:1 inside, hairline, then `glassWeather`
  (condensation, frost, flare) and, in direction 5, `vessel()` (water, snow, scorch, lights). `#gl` is the DOM text
  inside the glass; `drawInside()` builds it per direction and `insideTick(t)` animates it. Text color is computed
  from the painted sky's luminance each frame.
- Plates: `PLATES` loads `weather-plates/<name>.jpg`; `plateFor(cond,hour)` picks name and darkening by band (day,
  dusk, night) and condition; cross-fade 8 s; slow drift `sin(t*.012)` across the strip.
- Sheaf board: every section header and every row is one persistent DOM element; `layout()` moves them (so regrouping
  animates); gestures lock an axis after 8 pt; rows scroll inside `.listclip`.
- The prototype (`prototype/index.html`) is a tiny router: `SCREENS[id]={accent, render(el,params)}`, `go()` with a
  doorway tile-wave (206) or a slide, edge-swipe back, Tess as an Ember cloud on a top canvas, a map of every screen
  beside the phone.
- Publishing: the Artifact tool, one file per board, plates as `files`. There is no browser or Node on this machine,
  so boards were bracket-checked and, from the prototype v2 fix on, parsed with gjs (`jscheck.sh`). The prototype was blank for him because of two syntax errors (a cut `reset('home')` and an unclosed `<script>`) that the bracket checker could not see; gjs found both in seconds. Always run jscheck.sh.

## 4. How the plates were made
`scripts/crop_plates.py <raw_dir> <out_dir>`: for each Poly Haven slug, download the tonemapped JPG
(`https://dl.polyhaven.org/file/ph-assets/HDRIs/extra/Tonemapped%20JPG/<slug>.jpg`, 8192 x 4096 equirectangular),
find the brightest column in the upper sky (the sun), crop rows 5% to 52% of the height (about +80 degrees to just
below the horizon) centered on that column, width 1.6 x 0.461 x height (wrapping around the panorama), resize to
1600 tall, save JPEG q82. Pick `_puresky` slugs (sky only). Shortlist by tag is in sheet 256. Needs Python with
Pillow; the Poly Haven API (`https://api.polyhaven.com/assets?t=hdris&c=skies`) lists tags.

## 5. The screenshots (his, in `screenshots/`)
01: the glass and clouds never drew (a dead draw loop; the fix: declare `cfc`, wrap `draw` in try/catch).
02: v5, frosted panel look and the moon cut at the edge (rim magnified outward; fix: pull inward).
03: v6, the moon as a staircase (ring sampling; fix: per-pixel lens, then abandoned for the soft look).
04: v7, the lens band as a heavy frame ("super bad"; fix: soft light and shadow only, approved as v9).

## 5b. Generated plates (later on Oct 25)
He ran the brief with ChatGPT and sent four stills back (in `screenshots/05..08`, saved as plates): two clear moonless
nights, a second broken day, an overcast dusk. All four passed beside the photographs and are in the set as numbered
variants; board 255 v4 picks a variant at random per set and has switches for photographs only, generated only, the
drawn sky, and another variant. The moonlit photo became `cloudy-night-1`. The drawn moon is added over the generated
clear nights. Next from generation: the moving clips, an overcast night, a storm sky.

## 5c. Kitchen and Training landings (end of Oct 25)
Weather was called done for this round ("the skypiece has so much life"; Tess will one day request plates she lacks).
Board 257 proposes the Kitchen landing keystone as THE WINDOW over the sink (the Weather sky outside, steam inside
that Tess writes in: what ran out, the pot's minutes) and the Training landing keystone as THE CHALK SLATE (bests by
hand, a handprint per set, dust, a Monday wipe). Both use the skypiece pattern and the approved surface. Not yet
reviewed. Sheet 257.

## 5d. Verdicts on 257 and board 258
Chalk: "definitely like the chalkboard idea", but it must look like a blackboard and be integrated into the page,
writings included. Window: "super bad". Add Dishes (frequent). Board 258: the blackboard as the page's own ground
gone to slate with a chalk-dust feather edge, everything on it in chalk, three fills (Plan, Record, Coach); two new
Kitchen keystones, the SINK (dishes pile up as you cook, swipe to wash them) and the TICKET RAIL (Tess's tickets on
a pass, spiked when done); Dishes as a foot word, a swipe and a ticket. Not yet reviewed. Sheet 258.

## 5e. TRAINING BLACKBOARD LOCKED (end of Oct 25)
"I'm down with this." The blackboard is the Training landing keystone. Later work he named: haptics, interaction,
texture, integration, the font, what it says, reactions, colors. Board 258 v2 is the first pass: slate texture with
ghosts of wiped chalk, deeper dust feather with dust settled on the page below, five chalk hands to compare, finger
writing on the board, a towel swipe, tap-to-open with a wobble, and a haptics spec. Kitchen (sink vs rail) awaits
his look.

## 5f. KITCHEN KEYSTONE DECIDED: THE PASS (end of Oct 25)
Sink rejected. The ticket rail is "brilliant": his spec (kept in 258) is that the rail is the PERMANENT TOP of the
Kitchen app, live to whatever the lower part shows; tickets are dynamic in number and size (one big for a recipe or
the grocery list); a ticket with more than fits flips up to its next page and down to come back; cook mode runs the
steps on the rail, striking each as it is done, with announcements, and that live, smooth rendering is where the
energy goes. Board 259 builds all of it; v2 fits the rail into the standard slot after his correction (one slot size everywhere).
Open: the finishing gesture (recommend hold-and-tear), the flip animation itself (later), the hand, haptics.

## 5g. Prototype v2 (end of Oct 25)
`design-sheets/prototype/index.html` now carries the new landings: Weather (real plates, the approved glass with plain
numbers, an hour page where the sky and glass stay), Training (the blackboard under the type; Today's workout keeps
the board and strikes lifts as you tap them), Kitchen (the pass on every page: landing, Tonight, Recipes, Groceries,
Pantry, Leftovers, Cooking, with ticket flips and cook-mode strikes). Each app's centerpiece is drawn by every screen
of that app at the same slot, so it reads as staying while pages slide; a true shared layer is the build's job. The
map beside the phone states each app's status. v1 is kept as `index-v1.html`.

## 5h. Routines keystone, round two (end of Oct 25)
He called the woodland the weakest. Board 260 offers three keystones made of repetition itself, each in the standard
slot and able to stay through the app, each kinder to a missed day than withering: WORN PATHS (a field; routines are
paths worn by walking, grass grows back when left), THE SAMPLER (linen embroidered one row a day, a stitch per
routine in its grove's color, bare cloth for a day not done; recommended), THE STRING OF BEADS (today's routines as
beads moved across a knot with a click; a knot per full day). Not yet reviewed. Sheet 260.

## 5i. Routines round three: the cat (end of Oct 25)
Round two (paths, sampler, beads) was rejected ("the sampler is a little bit nice, not enough"). His steer: it can be
anything; life, expressiveness, fun, uniqueness, a personal relation as the cherry on top; Tess or the AI layer runs
how it reacts. Of a list of six creature-or-world directions he said "the animal thing has some potential". Board 261
builds THE CAT: a silhouette with eyes living in the standard slot, with a room (sun patch that moves with the hour,
door, sill, bowl), postures for each part of the day driven by his routines' times, reactions to done, late, not
now, neglect and a full day, a tail on a spring, blinks, purring on a stroke, and Tess's one-line voice as the cat.
Not yet reviewed. Sheet 261.

## 5j. Routines round four: loops as mechanisms (end of Oct 25)
Asked which routines he keeps and where, he defined a routine as a looped procedure with a period (daily, weekly),
physical or digital, sometimes automated. Board 262 builds two mechanisms in the standard slot: THE ORRERY (each
routine a brass body orbiting at its own period, inner track daily, outer weekly, due when it comes to the front;
done turns gold, missed goes dark till the next turn, steps as moons, automated ones ring and chime) and THE MUSIC
BOX (a drum turning once a day, a track per routine with its name engraved, a pin per step that plucks a comb tooth
when its hour comes; skipped pins pass dull; Tess winds the key). Not yet reviewed. Sheet 262.

## 6. Open items, in the order he would want them
1. Generated moving plates: judge what comes back from ChatGPT beside the photographs; grade to one look; wire loops
   (video elements drawn to the sky canvas) with random variant choice and seamless looping.
2. Inside the glass: pick between the five directions (recommendation in sheet 255), then make it real: data-driven
   state for water, snow, scorch; Reduce Motion stills.
3. Weather page beyond the slot: the one line, next hours and care rows are 243 placeholders; redo them on the real sky.
4. Kitchen: his review of the pass as built (259); the finishing gesture; the hand; then the lower pages (the pull-apart layer of 254 stays for opening a dish or a place within the lower part).
4b. Training blackboard finishing: pick the chalk hand and the default fill, colored chalk by split, reactions, haptics in the build.
5. Routines: the cat (261) rejected; round four is the orrery and the music box (262), built from his own definition. Before a fourth: get from him which routines he
   actually keeps and what object or moment they live in; then build from a real material plus Tess's writing plus
   live state, which is the pattern of everything he has approved. Then its finishing (which animal, its name and color, the behavior vocabulary for Tess, how it comes along through the app); then the routine page round (sheet 250, paused): steps first, then a better "how it's going" than strokes; the sampler's column or the path's length may be that answer.
6. Home's weather face should share the plates. Battery: loops at 24 fps, never a 60 fps shader sky.
7. Everything still carries the 248/249/254/255 "not yet reviewed" marks except what section 1 calls approved.

## 7. Boards (his account; sources are in the repo)
248 republished KxUP3btRNCLLRenstEySuJ, 249 JYEiJ5Jk9jWN9f4GLbdFac, prototype 1dH25PYRWRd3TU7LAacNHc,
251 7YWsi9KqwgSUkGQprBBV5S, 252 VdZzZGr35NRtzkSRoyXjqm, 253 2uvUgvTkdYo4Aax3ATYPCR, 254 TQ2mH5kFqJqXZs7jMEoXts,
255 XDNb4wm84nHNguDhFMqesr. All at `https://claude.ai/artifact/<id>`.

## 8. Moving this work
The clone lives on a Linux box this agent cannot push from. The whole `docs/handoff/` delta (18 paths, about 2 MB
with plates) is bundled as `tessera-design-oct25.tar.gz` and was attached in the chat. Unpack it over a checkout of
master `0061df0` (Oct 25) and commit; nothing outside `docs/handoff/` changed. Docs PRs need the premerge check
(`scripts/ops/premerge_check.py`): ASCII only on added lines (this document and the sheets use a few non-ASCII
characters such as degree signs and curly quotes in HTML; run the check and fix what it flags).

## 6. Later on Oct 25: Routines locked, Money locked
- Routines keystone LOCKED: the woodland (routines-garden-268 v4). Rule corrected on the way: not realism, FINISH and
  FUNCTION (see design.md). Headless Chromium now runs here (`scripts/shot.sh`), so boards are screenshotted directly.
- Money keystone LOCKED: the index system with two scrollers (277, 278 v3, 279). Everything tried before it is in
  design-sheets 269-276 with verdicts in each sheet.
- Open: Lists (separate app or shared tool?), Weather inside-glass pick and rest of page, Kitchen finishing gesture,
  Training chalk hand, Notes door pages. Never push to GitHub.

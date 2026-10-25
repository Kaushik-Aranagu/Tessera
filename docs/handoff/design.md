# Design handoff (Design lead, Oct 24, 1 AM PT; updated 4:50 PM PT with the Codex-era work)


## Design bible (`design-bible/`)
The whole design in one place for the next agent: start at `design-bible/00-read-me-first.md` (source order, the keystone and 3-5 s rules, the status of every screen), then `01` system and learnings, `02`-`05` per room, `06` open questions.

This is where design stands at the Codex handoff. The full sheet text for every item below is copied into
`docs/handoff/design-sheets/`. Boards are claude.ai artifact pages. They are only references: the sheets are the spec.

## Standing look rules (Kaushik's, never relax)
- No cards, pills, filled dots, bars, rings-as-gauges, chart furniture, fades on text or "...". No "N of M"
  counters. No decorative underlines. Sentence case. US words; never name a city.
- 3-4 colors per page, each with a meaning (`color-roles-241.md`). The 2-4 biggest words on a page never share one
  color (his 12:07 AM). Every color is 4.5:1 for small text and ΔE ≥ 10 from Ember.
- Pixels, tiles and mosaic belong on the Home mosaic only. No lens or glass on swipers.
- Blur only on wheels: up to 1 pt, never on the focus, none under Reduce Motion.
- Units: every weight or measure shows lb/kg at about half the number's size, min 10 pt, Figtree 400.
- Hit targets 44 pt. The back edge-swipe zone is 0-24 pt. The bottom-left action word starts at 28 pt or more and
  takes tap plus drag options.
- A single swiped element takes both horizontal and vertical swipes, unless the two directions mean different things
  (dials excepted).
- Landings are a summary plus ways into sub-areas, never a list (see "Landings" below for what was rejected).
- Type: Figtree for words, Outfit for numbers, Newsreader for Tess's words.

## Home 236 (`home-delta-236.md`): APPROVED v2.2, with additions v2.3-v2.8
Board: https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM (v11).
- v2.2 is approved: "exactly like this on the phone" (fixed slots, mosaic blend, faces, one thing).
- v2.3: the one thing turns with vertical swipes too.
- v2.4-v2.8 weather words, which he called "all good, very glad":
  - every WeatherCondition case has its own effect, and the word's color follows its cloud;
  - Sunny is shine only;
  - clouds appear only on mostly/partly/cloudy. They sit level with the word, behind it and inside its box, with
    fog-style wisps;
  - rain, snow and storms have no clouds;
  - fog masks the word (he loves the fog).
- v2.7: the light-mode mosaic is brighter. Tiles on paper are 3.6 pt, with saturation x1.55 and brightness x1.08.
  This is open: he hasn't confirmed it.

## Weather room 243 (`weather-room-243.md`): NEW, first cut, open
Board: https://claude.ai/artifact/NyeaiLgka6cPQX3vqWZ1jj.
- He asked for a basic Weather app plus a landing. Tapping any weather word on Home opens it.
- Data comes from Open-Meteo (free).
- He plans more creative weather features in this room later.
- Its landing will follow the landing system once it's picked.

## Training 230 (`training-flow-230.md`): v3.3, board v20
Board: https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp.
- The Library has a color per "what". The big words are split by color: Push clay, Pull teal, Legs plum, the streak
  gold.
- His last word: it was monotone, and the big blue text all looked the same. v20 addresses that; he hasn't reviewed
  it yet.

## Lists 237: board v9, open
Board: https://claude.ai/artifact/9JBnr8TytGTnKtnnyXjdik.
- The kind palette is one family: Shopping ochre, Trips steel, Home teal, People plum, Watch and read lavender.
- He said the earlier v8 colors were "slightly okay, combinations not good". v9 fixes that; he hasn't reviewed it
  yet.

## Color roles 241 (`color-roles-241.md`): app-wide rule, in force
- Room color goes on the title and action word. Each kind has its own color.
- States use the same color in every room: done green, late wine, best/new gold, planned/private slate.
- Big-type rule: the biggest words never share one color.
- Open: Notes violet 5B3FB8 is only ΔE00 6.1 from Ember. Fix it in the Notes round.

## Routines 238 (`routines-page-238.md`)
- v2/v3 rulings stand: kind page, maker, "From another room", receipts.
- REJECTED landings:
  - the doors list (11:39 PM);
  - the big reel headline, v4 (11:45 PM);
  - the summary plus 2-column door grid, v6 (11:52 PM: "sections and sections of lists again").
- The Routines landing is now the woodland (sheet 248, below).

## Routines woodland 248 (`routines-woodland-248.md`): NEW, v1, awaiting his review
Board: https://claude.ai/artifact/KZkqPY2U6VxDMBETRu3CML. Files: `design-sheets/routines-woodland-248/` (the board, the
scene on its own, the untouched Codex prototype and screenshots).
- It came from his Codex chat after the Claude limit ran out (2:45 to 8:35 AM PT Oct 24). He picked a living habit
  woodland as the Routines keystone: plants are habits, they grow from sprout to tree to fruit, and wither or go bare
  when neglected. The caretaker by the lake plants, waters and collects, 5 s at most.
- 248 redraws everything around the scene to our rules: sentence with three big colored phrases, the woodland in the
  Home mosaic's slot, doors on the three-place dial, an inside-a-grove focus wheel with a dimension line, and a routine
  page with the whole life on one hairline. No tabs, pills, legend, percentage or tree icons.
- v2 (his 4:57 PM PT note): the landing is a summary (sentence, woodland, two updates, doors with state lines, no
  list). The routines list behind a door is the open design problem: the board has a lab of five ways (Spoken,
  Skyline, Map, Cloth, Sheaf) and three ways to show one routine (life, weeks, day). Pick with him next.
- Open: which groves (recommend Body, Mind, Home, plus Borrowed across the lake), and how withering fits the older
  no-shame ruling (recommend soft words and Small-way protection). His verdict on 248 is owed.

## Codex chat digest (`../codex-chat-oct24.md`)
Read it for the other things he decided with Codex: Notes door pages (Folio page-curl, fixed band, areas as tags, the
glass areas pane), the keystone idea for every app and his verdicts on three rounds of studies, and the 3 to 5 second
effect limit. Reconcile its Notes changes with 247 v2 before building.
## Landings: OPEN, the main design problem
- REJECTED:
  - `landing-system-240.md`: paragraph doors, a fine-line drawing with doors, a contents page. "Drawings are the
    worst."
  - `landing-living-242.md` round 1: strings, chimes, swarm, jars, heap, ink. Strings and chimes "too bad"; the swarm
    "kind of okay but too much for what it offers".
  - Round 2, kinetic type (https://claude.ai/artifact/24SMi8GxcoMFmMdtHwr99f): tide "doesn't have anything".
- WHAT HE LIKED (12:43-12:53 AM): the WORD WALL.
  - A band or shaped area (like the Home mosaic slot) packed edge to edge with poster words of mixed sizes and colors.
  - A subtitle only when it fits under its word.
  - Careful justified alignment, and live swaps and transitions.
  - Words as bricks of a wall. The wall can be a band, an arch or a half arch, with other info in the remaining
    space.
  - The pile-to-poster transition: words lie jumbled like a garbage pile, then suddenly tidy into the wall (from
    round 2's "A, tossed then tidied").
  - First use: the Notes landing.
  - The key work is the type study: fonts, weights, sizes and colors that look good in light and pure black, plus
    the alignment rules.
- IN PROGRESS at handoff: round 3. It has Notes word-wall variants, wall shapes, the pile-to-tidy transition, a type
  study, and 6-8 more poster ideas. Board: https://claude.ai/artifact/HgDEZfib4Xw9BiafqyVydt (it may still be
  growing). If the round 3 section in `landing-living-242.md` is missing, continue round 3 from this brief.
- Round 4 (his 1:05 AM correction: bricks packed TIGHT, as many colors as possible, packed but legible): https://claude.ai/artifact/M9JKaR55a6rRFdiBcH2sYU. Archivo condensed, justified rows that solve their own height, stacks of small words, 12 colors. The algorithm is in `landing-living-242.md`, "Round 4". This is the current direction.
- Round 5 (capitals, stacked L/J names, mosaic-sized band, tilted packed pile): https://claude.ai/artifact/CTm3h1DfeUV3nUADP8Vf6N.
- APPROVED Oct 24, 1:54 AM: Notes landing 246 (`notes-landing-246.md`), board https://claude.ai/artifact/1mSPKcxhvQB4pFU2tmQZkx. Quarter-screen word wall in sharpened Figtree capitals on the mosaic slot, live moments every 5 s (no pile: he dropped it at 2:02 AM), doors on the 3-place dial with the focused door's newest notes beside it. Rejected on the way: the spine shelf (keep the idea for another place) and plain door rows ("too basic").
- Notes door pages, first cut (not yet reviewed): https://claude.ai/artifact/S4dqsoynjdQMRQsV9EPW5z.
- Next: his verdict on the door pages; then use the wall on other landings.

## Other rooms
- Kitchen 231-234, Notes 235, Lists 237: sheets are copied. All their landings are superseded by the landing work
  above.
- Money 239 was scheduled for 7 AM PT (trigger `trig_01GSBT2cd9MrXh62duwqzbkf`).

## How he reviews
- He reads boards on his phone, so give him links, never file paths.
- One recommendation per question. Never re-ask settled picks.
- His ideas are raw: polish them and push back. He wants inventive, non-stock UI ("UI is 50% of the product").

## Oct 25 (this session, local clone only; nothing pushed)
- Sheaf (249 round four) APPROVED as the list behind a door in Routines.
- Keystone rounds 251/252 rejected except Pull apart, which is the Kitchen app's opening move for level 1 and 2
  pages (a layer over a deeply blurred page). Kitchen landing keystone still open (four directions on 254).
- Weather: the whole page is a real-looking sky (needs a photographic plate library); keystone = the screen glass
  softly raised; the SURFACE is approved at 254 v9 (light and shadow only, no refraction). The inside (life,
  personality, information, reactions) and the rest of the page are still open, and the real sky plates are the
  biggest requirement.
- Linked prototype of everything: https://claude.ai/artifact/1dH25PYRWRd3TU7LAacNHc. Boards: 248 republished
  KxUP3btRNCLLRenstEySuJ, 249 JYEiJ5Jk9jWN9f4GLbdFac, 251 7YWsi9KqwgSUkGQprBBV5S, 252 VdZzZGr35NRtzkSRoyXjqm,
  253 2uvUgvTkdYo4Aax3ATYPCR, 254 TQ2mH5kFqJqXZs7jMEoXts.
  255 XDNb4wm84nHNguDhFMqesr (inside the Weather glass).
- THE SKYPIECE (his idea, Oct 25): the Weather keystone is an open vessel with depth; weather gets in and leaves
  traces (water collecting, snow drifts, lightning scorch, wind shaking the numbers, Tess's seasonal dressing). Approved
  to pursue, costs accepted. Board 255 v2 direction 5; sheet 255. Background plates spec: sheet 256.
- Weather plates: first working set of 7 real CC0 skies (Poly Haven) is in `design-sheets/weather-plates/` and under
  the glass on board 255 v3. Sources and plan: sheet 256. Prompts for generated gap-fillers: weather-plates/PROMPTS.md.

- Session handoff for other agents: `docs/handoff/session-oct25/HANDOFF.md` (decisions in order, where everything is, how the boards and plates are built, open items).
- Kitchen and Training landing keystones (window, chalk slate): sheet 257, `design-sheets/kitchen-training-257/`.
- 258: Training blackboard integrated into the page; Kitchen sink and ticket rail keystones, Dishes as a first-class thing. `design-sheets/kitchen-training-258/`.
- 259: THE KITCHEN PASS. The ticket rail is the Kitchen keystone (his verdict); permanent top of the app, live to every page, dynamic tickets, page flips, cook mode. `design-sheets/kitchen-rail-259/`.
- RULE (Oct 25): the keystone slot is one fixed size on every landing (354 x 182 at top 196). Content pages inside it (flips); the band never grows.
- RULE (Oct 25, his): THE CENTERPIECE STAYS THROUGH THE WHOLE APP. As the Kitchen pass does, every app's keystone
  stays in its slot on level 1, level 2 and deeper pages, live to whatever the lower part of the screen shows. Weather
  (the sky and the glass) and Notes (the word band on door pages) already do; Training (the blackboard) and the rest
  follow. Routines is the weakest keystone right now (woodland, 248); redesign and new ideation next.
- Landing status (Oct 25): Home approved; Notes approved; Weather sky + glass surface approved; Training blackboard
  locked; Kitchen pass decided; Routines woodland pending and to be rethought; Lists and Money have no keystone yet.
- Prototype v2 (Oct 25): Weather (plates + glass), Training (blackboard) and Kitchen (the pass) landings and their level-1 pages, centerpieces persisting through each app. `design-sheets/prototype/index.html` (v1 kept as `index-v1.html`).
- 260: Routines keystone round two, made of repetition: worn paths, the sampler (recommended), the string of beads. `design-sheets/routines-keystone-260/`.
- 261: Routines keystone round three, the CAT: one animal in the slot whose routine is your routines; Tess writes its lines. `design-sheets/routines-cat-261/`.
- 262: Routines round four, loops as MECHANISMS: the orrery (routines orbit at their period) and the music box (steps as pins on a turning drum). From his definition of a routine as a looped procedure. `design-sheets/routines-loops-262/`.
- RULE (Oct 25, his, after four Routines rounds): NO DRAWN THINGS THAT AIM AT REALISM. "If they're drawn things, you
  should not aim too much." A keystone is either REAL MATERIAL (photographed or generated plates, with the live layer
  on top: the sky, the chalk slate's texture) or DELIBERATELY GRAPHIC (pixels, type, chalk marks, hairlines: the
  mosaic, the word wall). A canvas illustration of a brass orrery or a cat is neither, and gets rejected on sight.
- Routines plates brief (real parts of the orrery and music box, separated for animation): `design-sheets/routines-plates/BRIEF.md`.

### Oct 25, later: the rule corrected (his words)
"I don't need realistic images or anything. The garden we previously had works, but a little bit improved, more
finished, smoother. That is all that was needed, not realism." And: "It's not about looking realistic. It's about
making it functionally creative, functionally fun." So the rule is FINISH and FUNCTION, not material: a drawn scene is
fine when it is finished and smooth (the 248 woodland), and the thing that earns a keystone is what it does. Rounds
262 to 267 (mechanisms, plain ideas, photo comps) are closed. Routines keystone = the 248 woodland, polished, with the
tending functions of 267 written into it.

### Oct 25: Routines keystone LOCKED: the woodland (sheet 268, v4)
His words: "Woodland's good. Lock it." The landing keystone for Routines is the 268 woodland: smooth flat-illustration
scene lit by the real hour, bleeding to the phone's full width and dissolving into the page (colour mist + alpha
falloff), eleven tree kinds with distinct colours, wildflowers, lake, caretaker. Functions: hold to water (done), buds
as steps, missed days yellow/sag/drop leaves, rake, plant, planted rest lamp, growth stages, weather from Weather,
dramatic reactions (spring + glow + petals + sparks + ring + birds). Board: routines-garden-268/board.html.
Next keystone: Money (the jar), sheet 269.

### Oct 25: Money keystone LOCKED: the index system with two scrollers (sheets 277, 278 v3, 279)
His words: "Lock the index system with the two scrollers as Money's frame."
- The frame: Money is a set of INDICES. An index = a named rule over the ledger (kind, tag, counterparty, account,
  currency, direction, size, recurring/one-off, text, time; and/or/not) + its own clock + series class + transform +
  baseline + liveness, with optional children and alerts. Built-ins (MONTH, SPEND, kinds, FIXED, SURPRISES, SAVE,
  PORTFOLIO, NET) are rules with defaults; the user's (DEBTS, INDIA, ENTERTAINMENT...) sit beside them as equals; sets
  may nest or overlap. Spec: design-sheets/money-index-system-279.md (classes, transforms, nine renderer rules).
- The slot (354 x 182, same as every app): a three-place dial of categories across the top (This month · Kinds · Saving
  · Investing · Debts · Mine), a scroller of the category's indices down the right (name, number, sparkline vs its
  baseline; one lit, neighbours faded, arrows when more), one chart between (clock, headline number, reading, Tess's
  line). Swipe sideways = category, up/down = index; tap = the same. Doors under the slot = the categories. Tap the
  slot = the full chart, same layout, larger. Board: money-indices-278/board.html.
- The chart is "you are the stock" (277): position line, forecast with bills as drops, promised-to-bills floor, fan,
  last period behind, volume by kind, scrub, hold to defer, what-if ghost, range sum, pinch to year.
- Rules held: no red/green; monotonic series never chart the level; units never silently converted; effects under 5 s.
- Set aside, unreviewed or rejected on the way: jar (269), town (270), tiles (271, keep as an inner page), balance of
  words (272), three ways (273), liquid balance (274), five metaphors (275), charge (276, liked; could be an inner page
  or a widget).
Keystones now: Home mosaic, Notes word wall, Weather skypiece, Training blackboard, Kitchen pass, Routines woodland,
Money indices. Lists: open (likely a shared tool, not its own keystone).

### Oct 25: Lists folded into Notes (sheet 280 verdict)
No Lists app and no Lists keystone. A list is a kind of note whose lines can be checked; the 237 list behaviour carries
over whole; the word wall stays the keystone and shows list titles and open items as words. Shopping stays Kitchen's
"To get" on the pass rail and also appears in the renamed room as a list note (one object, two rooms). Notes is to be
renamed to cover both; proposals in 280. Home mosaic's Lists face merges into Notes'. Keystones now complete for every
remaining app: Home, Notes (renamed), Weather, Training, Kitchen, Routines, Money.

### Oct 25: room names LOCKED: the ship (sheet 281)
Home → **Bridge** · Notes + Lists → **Log** · Weather → **Lookout** · Training → **Deck** · Kitchen → **Galley** ·
Routines → **Watch** · Money → **Purse**. Tessera stays the app's name. Rooms keep their colours and keystones.
To update when building: room titles, Home tile labels, door words that name rooms, Tess's grammar and feedback lines,
specs and handoff text. Older sheets keep the old names; this table is the map.

### Oct 25: Notes landing wall fixed in the prototype
The word wall measured words before Figtree 900 loaded and animated left/top/font-size during layout, so rows overlapped
and clipped. `wall()` now lays out with transitions off (`.wall.measuring`), measures each row's rendered width, shrinks
a row that overflows 354 and justifies the rest, and re-lays when the font finishes loading. Live moments still animate.
Note for screenshots: open a screen with `reset(name)`, not `go()`, or the shot catches the slide-in.

### Oct 25: prototype brought up to the locked design
Kaushik: "this is not what weather is supposed to look like... and the money thing is not even drawn there."
- Lookout: the approved glass was being drawn inside a canvas that also matched an older `.glass` rule (a frosted menu
  with blur, a tinted background, padding and z-index 20), so it rendered as a frosted band over a squeezed glass and
  hid the readout. Renamed to `.wglass`; `.hours` and `.board` had the same problem and are now `.whours` and `.tboard`.
  The sky plates now ship inside `prototype/weather-plates/` so the prototype works offline.
- Purse and Watch: the prototype still had the old pools page and the old woodland. Their landings are now the locked
  boards themselves (278 v3, 268 v4), embedded by `make_embed.py`, so the prototype cannot drift from them.
- Ship names on every room title, the Bridge app list (Lists removed) and the prototype's map.
- Hub 282 images re-shot from the fixed prototype; all seven now carry the ship names.

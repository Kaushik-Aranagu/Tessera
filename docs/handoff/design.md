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

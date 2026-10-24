# Design handoff (Design lead, Oct 24, 1 AM PT)

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
- The Routines landing waits for the landing system.

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
  study, and 6-8 more poster ideas. The board is scratchpad r60, which may not have published before the limit. If
  the round 3 section in `landing-living-242.md` is missing, start round 3 from this brief.
- Don't send landing build text to the builders until he picks.

## Other rooms
- Kitchen 231-234, Notes 235, Lists 237: sheets are copied. All their landings are superseded by the landing work
  above.
- Money 239 was scheduled for 7 AM PT (trigger `trig_01GSBT2cd9MrXh62duwqzbkf`).

## How he reviews
- He reads boards on his phone, so give him links, never file paths.
- One recommendation per question. Never re-ask settled picks.
- His ideas are raw: polish them and push back. He wants inventive, non-stock UI ("UI is 50% of the product").
